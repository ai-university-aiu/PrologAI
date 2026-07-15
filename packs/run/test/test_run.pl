% PLUnit tests for the run pack (rn_* predicates).
:- use_module(library(plunit)).
:- use_module(library(run)).

:- begin_tests(run_rn_encode).

test(encode_basic) :-
    % [1,1,2,2,2,1] encodes to [1-2, 2-3, 1-1].
    run_encode([1,1,2,2,2,1], Runs),
    Runs = [1-2, 2-3, 1-1].

test(encode_all_same) :-
    % [3,3,3] encodes to [3-3].
    run_encode([3,3,3], Runs),
    Runs = [3-3].

test(encode_no_runs) :-
    % [1,2,3] has no consecutive pairs; each value is a run of 1.
    run_encode([1,2,3], Runs),
    Runs = [1-1, 2-1, 3-1].

test(encode_empty) :-
    % Empty list encodes to empty.
    run_encode([], Runs),
    Runs = [].

test(encode_single) :-
    % Single element encodes to one run of length 1.
    run_encode([7], Runs),
    Runs = [7-1].

:- end_tests(run_rn_encode).

:- begin_tests(run_rn_decode).

test(decode_basic) :-
    % Decode [1-2, 2-3, 1-1] -> [1,1,2,2,2,1].
    run_decode([1-2, 2-3, 1-1], List),
    List = [1,1,2,2,2,1].

test(decode_empty) :-
    % Empty runs decode to empty list.
    run_decode([], List),
    List = [].

test(decode_single_run) :-
    % Single run of length 4.
    run_decode([5-4], List),
    List = [5,5,5,5].

test(decode_roundtrip) :-
    % Encode then decode should recover the original.
    Original = [1,1,2,3,3,3,1],
    run_encode(Original, Runs),
    run_decode(Runs, Decoded),
    Decoded = Original.

:- end_tests(run_rn_decode).

:- begin_tests(run_rn_row_encode).

test(row_encode_middle) :-
    % Encode row 1 of a 3x4 grid.
    G = [[0,0,0,0],[1,1,2,2],[0,0,0,0]],
    run_row_encode(G, 1, Runs),
    Runs = [1-2, 2-2].

test(row_encode_uniform) :-
    % Encode a uniform row.
    G = [[5,5,5],[0,0,0],[5,5,5]],
    run_row_encode(G, 0, Runs),
    Runs = [5-3].

:- end_tests(run_rn_row_encode).

:- begin_tests(run_rn_col_encode).

test(col_encode_basic) :-
    % Encode column 0 of a 4x3 grid.
    G = [[1,0,0],[1,0,0],[2,0,0],[2,0,0]],
    run_col_encode(G, 0, Runs),
    Runs = [1-2, 2-2].

test(col_encode_uniform) :-
    % All cells in column 1 are the same.
    G = [[0,9,0],[0,9,0],[0,9,0]],
    run_col_encode(G, 1, Runs),
    Runs = [9-3].

:- end_tests(run_rn_col_encode).

:- begin_tests(run_rn_grid_rows).

test(grid_rows_basic) :-
    % Each row gets independently encoded.
    G = [[1,1,2],[3,3,3]],
    run_grid_rows(G, RowRuns),
    RowRuns = [[1-2, 2-1], [3-3]].

test(grid_rows_single_row) :-
    % Single-row grid.
    G = [[0,1,0]],
    run_grid_rows(G, [[0-1, 1-1, 0-1]]).

:- end_tests(run_rn_grid_rows).

:- begin_tests(run_rn_grid_cols).

test(grid_cols_basic) :-
    % 2x3 grid: three columns.
    G = [[1,2,1],[1,2,1]],
    run_grid_cols(G, ColRuns),
    ColRuns = [[1-2], [2-2], [1-2]].

test(grid_cols_varied) :-
    % 3x2 grid with varied columns.
    G = [[1,0],[2,0],[1,0]],
    run_grid_cols(G, ColRuns),
    ColRuns = [[1-1, 2-1, 1-1], [0-3]].

:- end_tests(run_rn_grid_cols).

:- begin_tests(run_rn_length).

test(length_basic) :-
    % [1-2, 2-3, 1-1] represents 2+3+1=6 elements.
    run_length([1-2, 2-3, 1-1], N),
    N =:= 6.

test(length_empty) :-
    % Empty run list has length 0.
    run_length([], N),
    N =:= 0.

test(length_single) :-
    % Single run of length 5.
    run_length([7-5], N),
    N =:= 5.

:- end_tests(run_rn_length).

:- begin_tests(run_rn_at).

test(at_first_run) :-
    % Position 0 is in the first run [1-2, 2-3].
    run_at([1-2, 2-3], 0, V),
    V =:= 1.

test(at_second_run) :-
    % Position 2 is the start of the second run [1-2, 2-3].
    run_at([1-2, 2-3], 2, V),
    V =:= 2.

test(at_last_position) :-
    % Last position in [1-3] is position 2.
    run_at([1-3], 2, V),
    V =:= 1.

:- end_tests(run_rn_at).

:- begin_tests(run_rn_max_run).

test(max_run_basic) :-
    % Longest run of 2 in [1-2, 2-3, 2-1] is 3.
    run_max_run([1-2, 2-3, 2-1], 2, N),
    N =:= 3.

test(max_run_absent) :-
    % Color 9 not present: max run length is 0.
    run_max_run([1-2, 2-3], 9, N),
    N =:= 0.

test(max_run_single) :-
    % Single run of length 4.
    run_max_run([5-4], 5, N),
    N =:= 4.

:- end_tests(run_rn_max_run).

:- begin_tests(run_rn_count_runs).

test(count_runs_basic) :-
    % Color 1 appears in 2 distinct runs in [1-2, 2-3, 1-1].
    run_count_runs([1-2, 2-3, 1-1], 1, N),
    N =:= 2.

test(count_runs_absent) :-
    % Color 9 has 0 runs.
    run_count_runs([1-2, 2-3], 9, N),
    N =:= 0.

test(count_runs_one) :-
    % Color 2 appears in exactly 1 run.
    run_count_runs([1-2, 2-3, 1-1], 2, N),
    N =:= 1.

:- end_tests(run_rn_count_runs).

:- begin_tests(run_rn_uniform).

test(uniform_true) :-
    % All runs have value 5: uniform.
    run_uniform([5-3, 5-2, 5-1]).

test(uniform_single) :-
    % Single run is trivially uniform.
    run_uniform([7-4]).

test(uniform_empty) :-
    % Empty run list is vacuously uniform.
    run_uniform([]).

test(uniform_false) :-
    % Runs have different values: not uniform.
    \+ run_uniform([1-2, 2-3]).

:- end_tests(run_rn_uniform).

:- begin_tests(run_rn_trim).

test(trim_both_ends) :-
    % Remove leading and trailing 0s.
    run_trim([0,0,1,2,0,0], 0, [1,2]).

test(trim_no_leading) :-
    % Only trailing 0s.
    run_trim([1,2,0,0], 0, [1,2]).

test(trim_interior_kept) :-
    % Interior 0 must not be removed.
    run_trim([0,1,0,2,0], 0, [1,0,2]).

test(trim_empty) :-
    % Empty list trims to empty.
    run_trim([], 0, []).

:- end_tests(run_rn_trim).

:- begin_tests(run_rn_repeat).

test(repeat_basic) :-
    % Repeat [1-2, 2-1] twice: [1-2,2-1,1-2,2-1] -> no boundary merges.
    run_repeat([1-2, 2-1], 2, Runs),
    Runs = [1-2, 2-1, 1-2, 2-1].

test(repeat_merge_boundary) :-
    % Repeat [1-3] twice: boundary 1s merge -> [1-6].
    run_repeat([1-3], 2, Runs),
    Runs = [1-6].

test(repeat_once) :-
    % Repeat once returns the same run list.
    run_repeat([2-3, 1-1], 1, Runs),
    Runs = [2-3, 1-1].

:- end_tests(run_rn_repeat).

:- begin_tests(run_rn_positions).

test(positions_basic) :-
    % Positions of color 1 in [1-2, 2-3, 1-1]: positions 0,1,5.
    run_positions([1-2, 2-3, 1-1], 1, Ps),
    Ps = [0, 1, 5].

test(positions_absent) :-
    % Color 9 not present: empty list.
    run_positions([1-2, 2-3], 9, Ps),
    Ps = [].

test(positions_all) :-
    % All positions if only one color.
    run_positions([5-3], 5, Ps),
    Ps = [0, 1, 2].

:- end_tests(run_rn_positions).
