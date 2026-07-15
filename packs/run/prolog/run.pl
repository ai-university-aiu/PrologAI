% Module declaration: run pack, Layer 67.
:- module(run, [
    % run_encode/2: run-length encode a flat list to Value-Count pairs.
    run_encode/2,
    % run_decode/2: run-length decode Value-Count pairs to a flat list.
    run_decode/2,
    % run_row_encode/3: run-length encode a single grid row.
    run_row_encode/3,
    % run_col_encode/3: run-length encode a single grid column.
    run_col_encode/3,
    % run_grid_rows/2: run-length encode every row of a grid.
    run_grid_rows/2,
    % run_grid_cols/2: run-length encode every column of a grid.
    run_grid_cols/2,
    % run_length/2: total number of elements represented by a run list.
    run_length/2,
    % run_at/3: value at a 0-indexed position within a run list.
    run_at/3,
    % run_max_run/3: length of the longest run of a given value.
    run_max_run/3,
    % run_count_runs/3: number of distinct runs of a given value.
    run_count_runs/3,
    % run_uniform/1: true when all values in a run list are the same.
    run_uniform/1,
    % run_trim/3: remove leading and trailing occurrences of a value.
    run_trim/3,
    % run_repeat/3: repeat the encoded pattern N times and merge adjacent runs.
    run_repeat/3,
    % run_positions/3: 0-indexed positions of all cells with a given value.
    run_positions/3
]).

% Import list utilities; msort/length/forall are built-ins, not imported.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, reverse/2,
                                append/3, max_list/2]).
% Import higher-order apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% run_encode(+List, -Runs).
% Run-length encode a flat list of values into a list of Value-Count pairs.
% Consecutive equal values are collapsed: [1,1,2,1] -> [1-2, 2-1, 1-1].
run_encode([], []).
run_encode([V|Vs], [V-N|Runs]) :-
    % Count how many consecutive values equal V starting from the head.
    run_take_same_(V, Vs, N1, Tail),
    % The head contributes 1, plus the count from run_take_same_.
    N is N1 + 1,
    % Encode the remainder of the list.
    run_encode(Tail, Runs).

% run_take_same_(+V, +List, -Count, -Tail).
% Count how many leading elements of List equal V; Tail is the remainder.
run_take_same_(_, [], 0, []) :- !.
run_take_same_(V, [H|T], N, Tail) :-
    % Use if-then-else to avoid choicepoint on integer comparison.
    ( V =:= H ->
        run_take_same_(V, T, N1, Tail),
        N is N1 + 1
    ;   N = 0, Tail = [H|T]
    ).

% run_decode(+Runs, -List).
% Run-length decode a list of Value-Count pairs into a flat list.
% [1-2, 2-3] -> [1,1,2,2,2].
run_decode([], []).
run_decode([V-N|Rest], List) :-
    % Build a segment of N copies of V.
    length(Segment, N),
    maplist(=(V), Segment),
    % Decode the remaining runs.
    run_decode(Rest, Tail),
    % Concatenate this segment with the decoded tail.
    append(Segment, Tail, List).

% run_row_encode(+Grid, +R, -Runs).
% Run-length encode row R (0-indexed) of Grid.
run_row_encode(Grid, R, Runs) :-
    % Extract row R by 0-indexed lookup.
    nth0(R, Grid, Row),
    % Encode the row as a run-length list.
    run_encode(Row, Runs).

% run_col_encode(+Grid, +C, -Runs).
% Run-length encode column C (0-indexed) of Grid.
run_col_encode(Grid, C, Runs) :-
    % Extract the C-th element from each row to form the column list.
    maplist(nth0(C), Grid, Col),
    % Encode the column as a run-length list.
    run_encode(Col, Runs).

% run_grid_rows(+Grid, -RowRuns).
% Produce the run-length encoding of every row in Grid.
% RowRuns[i] is the run-length encoding of row i.
run_grid_rows(Grid, RowRuns) :-
    % Map run_encode over each row.
    maplist(run_encode, Grid, RowRuns).

% run_grid_cols(+Grid, -ColRuns).
% Produce the run-length encoding of every column in Grid.
% ColRuns[j] is the run-length encoding of column j.
run_grid_cols(Grid, ColRuns) :-
    % Compute the number of columns from the first row.
    ( Grid = [FR|_] -> length(FR, Cols) ; Cols = 0 ),
    Cols1 is Cols - 1,
    % Build the list of column indices.
    numlist(0, Cols1, Cs),
    % Encode each column.
    maplist(run_col_encode(Grid), Cs, ColRuns).

% run_length(+Runs, -N).
% N is the total number of elements represented by Runs.
run_length([], 0).
run_length([_-N|Rest], Total) :-
    % Recurse on the tail and add this run's count.
    run_length(Rest, RestTotal),
    Total is RestTotal + N.

% run_at(+Runs, +I, -V).
% V is the value at 0-indexed position I in the run-length sequence.
run_at([Val-N|Rest], I, V) :-
    % Use if-then-else to avoid choicepoint on integer comparison.
    ( I < N ->
        V = Val
    ;   I2 is I - N,
        run_at(Rest, I2, V)
    ).

% run_max_run(+Runs, +Color, -MaxLen).
% MaxLen is the length of the longest single run of Color in Runs.
% MaxLen = 0 if Color does not appear.
run_max_run(Runs, Color, MaxLen) :-
    % Collect all run lengths for Color.
    findall(N, member(Color-N, Runs), Ns),
    % Take the maximum; 0 if empty.
    ( Ns = [] -> MaxLen = 0 ; max_list(Ns, MaxLen) ).

% run_count_runs(+Runs, +Color, -N).
% N is the number of distinct runs of Color in Runs.
run_count_runs(Runs, Color, N) :-
    % Count all entries in Runs whose value equals Color.
    findall(L, member(Color-L, Runs), Ls),
    length(Ls, N).

% run_uniform(+Runs).
% True when every run in Runs has the same value (the sequence is all one color).
% Succeeds vacuously for an empty run list.
run_uniform([]).
run_uniform([_-_]) :- !.
run_uniform([V-_, V-N2|Rest]) :-
    % Both the first and second run must share the same value V.
    run_uniform([V-N2|Rest]).

% run_trim(+List, +BG, -Trimmed).
% Remove all leading and trailing occurrences of BG from List.
% Interior BG values are left unchanged.
run_trim(List, BG, Trimmed) :-
    % Drop leading BG values.
    run_drop_while_(List, BG, Middle),
    % Reverse, drop leading BG values again (= trailing from original), reverse back.
    reverse(Middle, Rev),
    run_drop_while_(Rev, BG, RevTrimmed),
    reverse(RevTrimmed, Trimmed).

% run_drop_while_(+List, +V, -Rest).
% Drop elements equal to V from the front of List; Rest is what remains.
run_drop_while_([], _, []) :- !.
run_drop_while_([H|T], V, Rest) :-
    % Use if-then-else on integer comparison to avoid choicepoint.
    ( H =:= V ->
        run_drop_while_(T, V, Rest)
    ;   Rest = [H|T]
    ).

% run_repeat(+Runs, +N, -Runs2).
% Repeat the encoded sequence N times.
% Adjacent same-value runs at repetition boundaries are merged.
% Example: run_repeat([1-2,2-1], 2, [1-2,2-1,1-2,2-1]).
run_repeat(Runs, N, Runs2) :-
    % Build a flat list of all run pairs repeated N times.
    findall(V-C, (between(1, N, _), member(V-C, Runs)), AllRuns),
    % Merge adjacent runs that share the same value.
    run_merge_adjacent_(AllRuns, Runs2).

% run_merge_adjacent_(+Runs, -Merged).
% Merge consecutive runs with the same value into a single run.
run_merge_adjacent_([], []) :- !.
run_merge_adjacent_([Run], [Run]) :- !.
run_merge_adjacent_([V-N1, W-N2|Rest], Merged) :-
    % Use if-then-else on integer comparison to avoid choicepoint.
    ( V =:= W ->
        N12 is N1 + N2,
        run_merge_adjacent_([V-N12|Rest], Merged)
    ;   run_merge_adjacent_([W-N2|Rest], RestMerged),
        Merged = [V-N1|RestMerged]
    ).

% run_positions(+Runs, +Color, -Positions).
% Positions is the sorted list of 0-indexed positions where Color appears.
run_positions(Runs, Color, Positions) :-
    % Accumulate positions by scanning runs from offset 0.
    run_positions_(Runs, Color, 0, Positions).

% run_positions_(+Runs, +Color, +Offset, -Positions).
% Internal: enumerate positions starting at Offset.
run_positions_([], _, _, []).
run_positions_([V-N|Rest], Color, Offset, Positions) :-
    % Compute the offset for the next run.
    Next is Offset + N,
    ( V =:= Color ->
        % This run contributes positions Offset, Offset+1, ..., Offset+N-1.
        Last is Offset + N - 1,
        numlist(Offset, Last, Ps),
        run_positions_(Rest, Color, Next, RestPs),
        append(Ps, RestPs, Positions)
    ;   % This run contributes no positions for Color.
        run_positions_(Rest, Color, Next, Positions)
    ).
