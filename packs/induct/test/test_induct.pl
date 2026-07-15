% PLUnit tests for the induct pack (in_* predicates).
:- use_module(library(plunit)).
:- use_module('../prolog/induct').

:- begin_tests(induct_delta).

test(delta_empty) :-
    % Identical grids: no changed cells.
    induct_delta([[1,2],[3,4]], [[1,2],[3,4]], Delta),
    Delta = [].

test(delta_one_cell) :-
    % One cell changed from 1 to 5.
    induct_delta([[1,2],[3,4]], [[5,2],[3,4]], Delta),
    Delta = [r(0,0)-1-5].

test(delta_all_cells) :-
    % All cells changed.
    induct_delta([[1,2],[3,4]], [[5,6],[7,8]], Delta),
    length(Delta, 4).

test(delta_single) :-
    % Single-cell grid; cell changed.
    induct_delta([[3]], [[7]], Delta),
    Delta = [r(0,0)-3-7].

:- end_tests(induct_delta).

:- begin_tests(induct_constant).

test(constant_same) :-
    % Identity: output = input.
    induct_constant([[1,2],[3,4]], [[1,2],[3,4]]).

test(constant_fail) :-
    % Different grid: identity fails.
    \+ induct_constant([[1,2],[3,4]], [[1,2],[3,5]]).

:- end_tests(induct_constant).

:- begin_tests(induct_color_map).

test(color_map_basic) :-
    % Color 1 -> 5 in all changed cells.
    induct_color_map([[1,0],[0,1]], [[5,0],[0,5]], Map),
    Map = [1-5].

test(color_map_two) :-
    % Color 1 -> 5 and color 2 -> 6.
    induct_color_map([[1,2],[1,2]], [[5,6],[5,6]], Map),
    Map = [1-5, 2-6].

test(color_map_identity) :-
    % No changed cells: empty map.
    induct_color_map([[1,2],[3,4]], [[1,2],[3,4]], Map),
    Map = [].

:- end_tests(induct_color_map).

:- begin_tests(induct_color_map_pairs).

test(pairs_map_consistent) :-
    % Both pairs have same 1->5 mapping.
    Pairs = [[[1,0]]-[[5,0]], [[0,1]]-[[0,5]]],
    induct_color_map_pairs(Pairs, Map),
    Map = [1-5].

test(pairs_map_empty_list) :-
    % Empty pairs list returns empty map.
    induct_color_map_pairs([], Map),
    Map = [].

:- end_tests(induct_color_map_pairs).

:- begin_tests(induct_size_change).

test(size_change_same) :-
    % 2x2 -> 2x2: no change.
    induct_size_change([[1,2],[3,4]], [[5,6],[7,8]], DR, DC),
    DR =:= 0,
    DC =:= 0.

test(size_change_grow_rows) :-
    % 1x2 -> 2x2: rows grow by 1.
    induct_size_change([[1,2]], [[1,2],[3,4]], DR, DC),
    DR =:= 1,
    DC =:= 0.

test(size_change_grow_cols) :-
    % 2x1 -> 2x2: cols grow by 1.
    induct_size_change([[1],[2]], [[1,0],[2,0]], DR, DC),
    DR =:= 0,
    DC =:= 1.

test(size_change_shrink) :-
    % 2x2 -> 1x1: shrink.
    induct_size_change([[1,2],[3,4]], [[7]], DR, DC),
    DR =:= -1,
    DC =:= -1.

:- end_tests(induct_size_change).

:- begin_tests(induct_size_change_pairs).

test(pairs_size_consistent) :-
    % All pairs same size change.
    Pairs = [[[1,2]]-[[1,2],[3,4]], [[5,6]]-[[5,6],[7,8]]],
    induct_size_change_pairs(Pairs, DR, DC),
    DR =:= 1,
    DC =:= 0.

test(pairs_size_no_change) :-
    % All pairs no size change.
    Pairs = [[[1,2],[3,4]]-[[5,6],[7,8]]],
    induct_size_change_pairs(Pairs, DR, DC),
    DR =:= 0,
    DC =:= 0.

:- end_tests(induct_size_change_pairs).

:- begin_tests(induct_color_palette).

test(palette_basic) :-
    % Union of all unique colors.
    induct_color_palette([[1,2],[3,0]], [[4,2],[3,5]], Palette),
    sort([0,1,2,3,4,5], Expected),
    Palette = Expected.

test(palette_single) :-
    % Single-cell grids.
    induct_color_palette([[3]], [[7]], Palette),
    Palette = [3,7].

:- end_tests(induct_color_palette).

:- begin_tests(induct_palette_pairs).

test(palette_pairs_basic) :-
    % Input colors: 1,2; Output colors: 5,6.
    Pairs = [[[1,0]]-[[5,0]], [[0,2]]-[[0,6]]],
    induct_palette_pairs(Pairs, InColors, OutColors),
    InColors = [0,1,2],
    OutColors = [0,5,6].

:- end_tests(induct_palette_pairs).

:- begin_tests(induct_invariant_cells).

test(invariant_all) :-
    % All cells invariant.
    induct_invariant_cells([[1,2],[3,4]], [[1,2],[3,4]], Cells),
    length(Cells, 4).

test(invariant_none) :-
    % No cells invariant.
    induct_invariant_cells([[1,2],[3,4]], [[5,6],[7,8]], Cells),
    Cells = [].

test(invariant_some) :-
    % Some cells invariant.
    induct_invariant_cells([[1,2],[3,4]], [[1,9],[3,9]], Cells),
    Cells = [r(0,0), r(1,0)].

:- end_tests(induct_invariant_cells).

:- begin_tests(induct_changed_cells).

test(changed_none) :-
    % No cells changed.
    induct_changed_cells([[1,2],[3,4]], [[1,2],[3,4]], Cells),
    Cells = [].

test(changed_all) :-
    % All cells changed.
    induct_changed_cells([[1,2],[3,4]], [[5,6],[7,8]], Cells),
    length(Cells, 4).

test(changed_some) :-
    % Some cells changed.
    induct_changed_cells([[1,2],[3,4]], [[1,9],[3,9]], Cells),
    Cells = [r(0,1), r(1,1)].

:- end_tests(induct_changed_cells).

:- begin_tests(induct_consistent_delta).

test(consistent_same) :-
    % Both pairs have same delta (no change).
    Pairs = [[[1,2],[3,4]]-[[1,2],[3,4]], [[5,6],[7,8]]-[[5,6],[7,8]]],
    induct_consistent_delta(Pairs, Delta),
    Delta = [].

test(consistent_one_change) :-
    % Both pairs change cell (0,0) from 1 to 5.
    Pairs = [[[1,0]]-[[5,0]], [[1,0]]-[[5,0]]],
    induct_consistent_delta(Pairs, Delta),
    Delta = [r(0,0)-1-5].

:- end_tests(induct_consistent_delta).

:- begin_tests(induct_bg_color).

test(bg_basic) :-
    % 0 is the most frequent color.
    induct_bg_color([[0,0,1],[0,1,1],[0,0,0]], BgColor),
    BgColor =:= 0.

test(bg_single) :-
    % Only one color.
    induct_bg_color([[3,3],[3,3]], BgColor),
    BgColor =:= 3.

test(bg_tie) :-
    % Tie: max_member picks the largest.
    induct_bg_color([[1,2],[2,1]], _BgColor).

:- end_tests(induct_bg_color).

:- begin_tests(induct_bg_color_pairs).

test(bg_pairs_consistent) :-
    % Both grids have 0 as most frequent.
    Pairs = [[[0,0,1]]-[[0,0,1]], [[0,1,0]]-[[0,1,0]]],
    induct_bg_color_pairs(Pairs, BgColor),
    BgColor =:= 0.

:- end_tests(induct_bg_color_pairs).

:- begin_tests(induct_common_keys).

test(common_basic) :-
    % Common mapping: 1-5.
    induct_common_keys([1-5, 2-6], [1-5, 3-7], Common),
    Common = [1-5].

test(common_empty) :-
    % No common mappings.
    induct_common_keys([1-5], [2-6], Common),
    Common = [].

test(common_all) :-
    % All mappings are common.
    induct_common_keys([1-5, 2-6], [1-5, 2-6], Common),
    Common = [1-5, 2-6].

:- end_tests(induct_common_keys).
