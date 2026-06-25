% PLUnit tests for the rewrite pack (rw_* predicates).
:- use_module(library(plunit)).
:- use_module(library(rewrite)).

% Helper predicates for rw_conditional tests.
% cond_row_zero_: true if R =:= 0.
cond_row_zero_(R, _C, _V) :- R =:= 0.
% cond_val_one_: true if V =:= 1.
cond_val_one_(_R, _C, V) :- V =:= 1.

:- begin_tests(rewrite_rw_map_color).

test(map_basic) :-
    % Apply a two-entry map: 1->2, 0->3.
    rw_map_color([[1,0],[0,1]], [1-2, 0-3], G2),
    G2 = [[2,3],[3,2]].

test(map_partial) :-
    % Only 1 is in the map; 2 and 0 are unchanged.
    rw_map_color([[1,2,0]], [1-9], G2),
    G2 = [[9,2,0]].

test(map_empty_map) :-
    % Empty map: every cell unchanged.
    rw_map_color([[1,2],[3,4]], [], G2),
    G2 = [[1,2],[3,4]].

test(map_identity) :-
    % Map where Old = New: grid unchanged.
    rw_map_color([[5,5],[5,5]], [5-5], G2),
    G2 = [[5,5],[5,5]].

:- end_tests(rewrite_rw_map_color).

:- begin_tests(rewrite_rw_replace_color).

test(replace_basic) :-
    % Replace all 1s with 5.
    rw_replace_color([[1,0,1],[0,1,0]], 1, 5, G2),
    G2 = [[5,0,5],[0,5,0]].

test(replace_not_present) :-
    % Color 9 not in grid: grid unchanged.
    rw_replace_color([[1,2],[3,4]], 9, 0, G2),
    G2 = [[1,2],[3,4]].

test(replace_all_cells) :-
    % Replace 0 (the only color) with 7.
    rw_replace_color([[0,0],[0,0]], 0, 7, G2),
    G2 = [[7,7],[7,7]].

:- end_tests(rewrite_rw_replace_color).

:- begin_tests(rewrite_rw_swap_colors).

test(swap_basic) :-
    % Swap 1 and 0: every 1 becomes 0 and vice versa.
    rw_swap_colors([[1,0,2]], 1, 0, G2),
    G2 = [[0,1,2]].

test(swap_mixed) :-
    % Multi-row swap with other colors intact.
    rw_swap_colors([[1,1,0],[0,2,1]], 1, 0, G2),
    G2 = [[0,0,1],[1,2,0]].

test(swap_no_match) :-
    % Swapping 0 and 1 when grid has only 2 and 3: unchanged.
    rw_swap_colors([[2,3],[3,2]], 0, 1, G2),
    G2 = [[2,3],[3,2]].

:- end_tests(rewrite_rw_swap_colors).

:- begin_tests(rewrite_rw_set_region).

test(set_region_two_cells) :-
    % Set r(0,0) and r(1,1) to 9 in a 2x2 grid of 1s.
    rw_set_region([[1,1],[1,1]], [r(0,0), r(1,1)], 9, G2),
    G2 = [[9,1],[1,9]].

test(set_region_entire_grid) :-
    % Set all four cells to 5.
    rw_set_region([[0,0],[0,0]], [r(0,0),r(0,1),r(1,0),r(1,1)], 5, G2),
    G2 = [[5,5],[5,5]].

test(set_region_empty) :-
    % Empty region: grid unchanged.
    rw_set_region([[1,2],[3,4]], [], 9, G2),
    G2 = [[1,2],[3,4]].

:- end_tests(rewrite_rw_set_region).

:- begin_tests(rewrite_rw_mask_apply).

test(mask_basic) :-
    % MaskVal=1 selects Fill=9; MaskVal=0 keeps original.
    rw_mask_apply([[1,2],[3,4]], [[1,0],[0,1]], 1, 9, G2),
    G2 = [[9,2],[3,9]].

test(mask_all_zero) :-
    % Mask all zeros with MaskVal=1: nothing selected, grid unchanged.
    rw_mask_apply([[1,2],[3,4]], [[0,0],[0,0]], 1, 9, G2),
    G2 = [[1,2],[3,4]].

test(mask_all_selected) :-
    % All mask cells equal MaskVal: entire grid becomes Fill.
    rw_mask_apply([[1,2],[3,4]], [[1,1],[1,1]], 1, 0, G2),
    G2 = [[0,0],[0,0]].

:- end_tests(rewrite_rw_mask_apply).

:- begin_tests(rewrite_rw_overlay).

test(overlay_basic) :-
    % Non-BG cells in Grid2 overwrite Grid1.
    rw_overlay([[1,1,1]], [[0,9,0]], 0, G3),
    G3 = [[1,9,1]].

test(overlay_all_non_bg) :-
    % All of Grid2 is non-BG: Grid3 = Grid2.
    rw_overlay([[1,2],[3,4]], [[5,6],[7,8]], 0, G3),
    G3 = [[5,6],[7,8]].

test(overlay_all_bg) :-
    % All of Grid2 is BG: Grid3 = Grid1.
    rw_overlay([[1,2],[3,4]], [[0,0],[0,0]], 0, G3),
    G3 = [[1,2],[3,4]].

:- end_tests(rewrite_rw_overlay).

:- begin_tests(rewrite_rw_stamp).

test(stamp_center) :-
    % Stamp [[9]] at (1,1) in 3x3 zeros: center becomes 9.
    rw_stamp([[0,0,0],[0,0,0],[0,0,0]], [[9]], 1, 1, G2),
    nth0(1, G2, R1), nth0(1, R1, V), V =:= 9.

test(stamp_top_left) :-
    % Stamp [[1,2],[3,4]] at (0,0) in 3x3 zeros.
    rw_stamp([[0,0,0],[0,0,0],[0,0,0]], [[1,2],[3,4]], 0, 0, G2),
    G2 = [[1,2,0],[3,4,0],[0,0,0]].

test(stamp_partial_oob) :-
    % Stamp [[1,2],[3,4]] at (2,2) in 3x3 zeros: only (2,2) stays in bounds.
    rw_stamp([[0,0,0],[0,0,0],[0,0,0]], [[1,2],[3,4]], 2, 2, G2),
    nth0(2, G2, R2), nth0(2, R2, V), V =:= 1.

:- end_tests(rewrite_rw_stamp).

:- begin_tests(rewrite_rw_diff_apply).

test(diff_two_cells) :-
    % Apply r(0,0)->9 and r(1,1)->8 to a 2x2 grid of 1s.
    rw_diff_apply([[1,1],[1,1]], [r(0,0)-9, r(1,1)-8], G2),
    G2 = [[9,1],[1,8]].

test(diff_empty) :-
    % Empty diff: grid unchanged.
    rw_diff_apply([[1,2],[3,4]], [], G2),
    G2 = [[1,2],[3,4]].

test(diff_oob_ignored) :-
    % Out-of-bounds r(5,5) in diff: silently ignored.
    rw_diff_apply([[1,0]], [r(5,5)-9], G2),
    G2 = [[1,0]].

:- end_tests(rewrite_rw_diff_apply).

:- begin_tests(rewrite_rw_normalize).

test(normalize_two_colors) :-
    % 3 and 7 are non-BG. 3 appears first, so 3->1, 7->2.
    rw_normalize([[3,0,7],[0,3,7]], 0, G2),
    G2 = [[1,0,2],[0,1,2]].

test(normalize_single_color) :-
    % Only color 5 is non-BG; it maps to 1.
    rw_normalize([[5,0,5]], 0, G2),
    G2 = [[1,0,1]].

test(normalize_bg_unchanged) :-
    % BG cells (0) must remain 0 after normalization.
    rw_normalize([[0,1,0]], 0, G2),
    G2 = [[0,1,0]].

:- end_tests(rewrite_rw_normalize).

:- begin_tests(rewrite_rw_invert_colors).

test(invert_basic) :-
    % Invert with Max=5: each V becomes 5-V.
    rw_invert_colors([[0,1,2],[3,4,5]], 5, G2),
    G2 = [[5,4,3],[2,1,0]].

test(invert_uniform) :-
    % All zeros inverted with Max=9: all become 9.
    rw_invert_colors([[0,0],[0,0]], 9, G2),
    G2 = [[9,9],[9,9]].

test(invert_max_zero) :-
    % Invert with Max=0: all cells become 0.
    rw_invert_colors([[0,0],[0,0]], 0, G2),
    G2 = [[0,0],[0,0]].

:- end_tests(rewrite_rw_invert_colors).

:- begin_tests(rewrite_rw_remap_bg).

test(remap_bg_basic) :-
    % Replace background 0 with 9.
    rw_remap_bg([[0,1,0],[2,0,2]], 0, 9, G2),
    G2 = [[9,1,9],[2,9,2]].

test(remap_bg_to_zero) :-
    % Replace background 5 with 0.
    rw_remap_bg([[5,1,5]], 5, 0, G2),
    G2 = [[0,1,0]].

test(remap_bg_not_present) :-
    % OldBG not in grid: unchanged.
    rw_remap_bg([[1,2],[3,4]], 0, 9, G2),
    G2 = [[1,2],[3,4]].

:- end_tests(rewrite_rw_remap_bg).

:- begin_tests(rewrite_rw_set_border).

test(set_border_3x3_count) :-
    % 3x3 grid: 8 border cells; center stays unchanged.
    G = [[0,0,0],[0,5,0],[0,0,0]],
    rw_set_border(G, 1, G2),
    % All 8 border cells become 1.
    G2 = [[1,1,1],[1,5,1],[1,1,1]].

test(set_border_interior_unchanged) :-
    % Center cell of a 3x3 grid must not change.
    G = [[0,0,0],[0,7,0],[0,0,0]],
    rw_set_border(G, 1, G2),
    nth0(1, G2, R1), nth0(1, R1, V), V =:= 7.

test(set_border_4x4) :-
    % 4x4 all-zero grid: set border to 1; interior 2x2 stays 0.
    G = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],
    rw_set_border(G, 1, G2),
    % Interior cell (1,1) must stay 0.
    nth0(1, G2, R1), nth0(1, R1, V11), V11 =:= 0,
    % Border cell (0,0) must be 1.
    nth0(0, G2, R0), nth0(0, R0, V00), V00 =:= 1.

:- end_tests(rewrite_rw_set_border).

:- begin_tests(rewrite_rw_fill_rect).

test(fill_rect_2x2_in_4x4) :-
    % Fill (1,1)..(2,2) with 7 in 4x4 zeros.
    G = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],
    rw_fill_rect(G, 1, 1, 2, 2, 7, G2),
    % r(1,1) becomes 7.
    nth0(1, G2, R1), nth0(1, R1, V11), V11 =:= 7,
    % r(2,2) becomes 7.
    nth0(2, G2, R2), nth0(2, R2, V22), V22 =:= 7,
    % r(0,0) stays 0.
    nth0(0, G2, R0), nth0(0, R0, V00), V00 =:= 0.

test(fill_rect_full_row) :-
    % Fill row 1 (columns 0 through 3) with 5 in 3x4 zeros.
    G = [[0,0,0,0],[0,0,0,0],[0,0,0,0]],
    rw_fill_rect(G, 1, 0, 1, 3, 5, G2),
    G2 = [[0,0,0,0],[5,5,5,5],[0,0,0,0]].

test(fill_rect_single_cell) :-
    % Fill only r(0,0) with 9.
    rw_fill_rect([[1,1],[1,1]], 0, 0, 0, 0, 9, G2),
    G2 = [[9,1],[1,1]].

:- end_tests(rewrite_rw_fill_rect).

:- begin_tests(rewrite_rw_conditional).

test(conditional_by_row) :-
    % Cells in row 0 get 1; all others get 0.
    G = [[5,5],[5,5]],
    rw_conditional(G, cond_row_zero_, 1, 0, G2),
    G2 = [[1,1],[0,0]].

test(conditional_by_value) :-
    % Cells with V=1 get 9; all others get 0.
    G = [[1,2],[1,3]],
    rw_conditional(G, cond_val_one_, 9, 0, G2),
    G2 = [[9,0],[9,0]].

test(conditional_all_false) :-
    % Goal never holds: all cells become FalseColor.
    G = [[2,3],[4,5]],
    rw_conditional(G, cond_val_one_, 9, 0, G2),
    G2 = [[0,0],[0,0]].

:- end_tests(rewrite_rw_conditional).
