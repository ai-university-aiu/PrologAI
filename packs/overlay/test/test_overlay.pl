% PLUnit tests for the overlay pack (ov_* predicates).
:- use_module(library(plunit)).
:- use_module(library(overlay)).

% Helper grids.
ga([[1,0,0],[0,1,0],[0,0,1]]).
gb([[0,2,0],[2,0,2],[0,2,0]]).
gc([[1,2,0],[2,1,2],[0,2,1]]).

:- begin_tests(overlay_over).

test(over_basic) :-
    ga(A), gb(B),
    overlay_over(A, B, 0, Result),
    Result = [[1,2,0],[2,1,2],[0,2,1]].

test(over_fully_transparent) :-
    A = [[1,2],[3,4]],
    B = [[0,0],[0,0]],
    overlay_over(A, B, 0, Result),
    Result = [[1,2],[3,4]].

test(over_fully_opaque) :-
    A = [[1,2],[3,4]],
    B = [[5,6],[7,8]],
    overlay_over(A, B, 0, Result),
    Result = [[5,6],[7,8]].

test(over_single_cell) :-
    A = [[1]], B = [[0]],
    overlay_over(A, B, 0, Result),
    Result = [[1]].

:- end_tests(overlay_over).

:- begin_tests(overlay_blend).

test(blend_alias_for_over) :-
    A = [[1,0],[0,1]],
    B = [[0,2],[2,0]],
    overlay_blend(A, B, 0, R1),
    overlay_over(A, B, 0, R2),
    R1 = R2.

:- end_tests(overlay_blend).

:- begin_tests(overlay_or).

test(or_basic) :-
    A = [[1,0],[0,1]],
    B = [[0,1],[1,0]],
    overlay_or(A, B, Result),
    Result = [[1,1],[1,1]].

test(or_zeros) :-
    A = [[0,0],[0,0]],
    B = [[0,0],[0,0]],
    overlay_or(A, B, Result),
    Result = [[0,0],[0,0]].

test(or_commutative) :-
    A = [[3,5],[7,9]],
    B = [[5,3],[9,7]],
    overlay_or(A, B, R1),
    overlay_or(B, A, R2),
    R1 = R2.

:- end_tests(overlay_or).

:- begin_tests(overlay_and).

test(and_basic) :-
    A = [[3,5],[6,7]],
    B = [[5,3],[7,6]],
    overlay_and(A, B, Result),
    R00 is 3 /\ 5, R01 is 5 /\ 3, R10 is 6 /\ 7, R11 is 7 /\ 6,
    Result = [[R00,R01],[R10,R11]].

test(and_zeros) :-
    A = [[1,1],[1,1]],
    B = [[0,0],[0,0]],
    overlay_and(A, B, Result),
    Result = [[0,0],[0,0]].

:- end_tests(overlay_and).

:- begin_tests(overlay_xor).

test(xor_basic) :-
    A = [[1,0],[0,1]],
    B = [[0,1],[1,0]],
    overlay_xor(A, B, 0, Result),
    Result = [[1,1],[1,1]].

test(xor_both_nonbg) :-
    A = [[1,2],[3,4]],
    B = [[2,1],[4,3]],
    overlay_xor(A, B, 0, Result),
    Result = [[0,0],[0,0]].

test(xor_both_bg) :-
    A = [[0,0]], B = [[0,0]],
    overlay_xor(A, B, 0, Result),
    Result = [[0,0]].

test(xor_one_nonbg) :-
    A = [[1,0]], B = [[0,2]],
    overlay_xor(A, B, 0, Result),
    Result = [[1,2]].

:- end_tests(overlay_xor).

:- begin_tests(overlay_diff).

test(diff_basic) :-
    A = [[1,2],[3,4]],
    B = [[1,0],[3,0]],
    overlay_diff(A, B, 0, Result),
    Result = [[0,2],[0,4]].

test(diff_all_same) :-
    A = [[1,2],[3,4]],
    overlay_diff(A, A, 0, Result),
    Result = [[0,0],[0,0]].

test(diff_all_different) :-
    A = [[1,2]], B = [[3,4]],
    overlay_diff(A, B, 0, Result),
    Result = [[1,2]].

:- end_tests(overlay_diff).

:- begin_tests(overlay_intersect).

test(intersect_basic) :-
    A = [[1,2],[3,4]],
    B = [[1,0],[3,0]],
    overlay_intersect(A, B, 0, Result),
    Result = [[1,0],[3,0]].

test(intersect_all_same) :-
    A = [[1,2],[3,4]],
    overlay_intersect(A, A, 0, Result),
    Result = A.

test(intersect_all_different) :-
    A = [[1,2]], B = [[3,4]],
    overlay_intersect(A, B, 0, Result),
    Result = [[0,0]].

:- end_tests(overlay_intersect).

:- begin_tests(overlay_mask).

test(mask_basic) :-
    Grid = [[1,2,3],[4,5,6]],
    Mask = [[0,1,0],[1,0,1]],
    overlay_mask(Grid, Mask, 0, Result),
    Result = [[0,2,0],[4,0,6]].

test(mask_all_opaque) :-
    Grid = [[1,2],[3,4]],
    Mask = [[1,1],[1,1]],
    overlay_mask(Grid, Mask, 0, Result),
    Result = [[1,2],[3,4]].

test(mask_all_transparent) :-
    Grid = [[1,2],[3,4]],
    Mask = [[0,0],[0,0]],
    overlay_mask(Grid, Mask, 0, Result),
    Result = [[0,0],[0,0]].

:- end_tests(overlay_mask).

:- begin_tests(overlay_mask_inv).

test(mask_inv_basic) :-
    Grid = [[1,2,3],[4,5,6]],
    Mask = [[0,1,0],[1,0,1]],
    overlay_mask_inv(Grid, Mask, 0, Result),
    Result = [[1,0,3],[0,5,0]].

test(mask_inv_complement_of_mask) :-
    Grid = [[1,2],[3,4]],
    Mask = [[1,0],[0,1]],
    overlay_mask(Grid, Mask, 0, R1),
    overlay_mask_inv(Grid, Mask, 0, R2),
    overlay_or(R1, R2, Grid).

:- end_tests(overlay_mask_inv).

:- begin_tests(overlay_priority).

test(priority_basic) :-
    G1 = [[1,0],[0,1]],
    G2 = [[0,2],[2,0]],
    overlay_priority([G1,G2], 0, Result),
    Result = [[1,2],[2,1]].

test(priority_three_layers) :-
    G1 = [[1,0],[0,0]],
    G2 = [[0,2],[0,0]],
    G3 = [[0,0],[3,4]],
    overlay_priority([G1,G2,G3], 0, Result),
    Result = [[1,2],[3,4]].

test(priority_first_wins) :-
    G1 = [[1,1]],
    G2 = [[2,2]],
    overlay_priority([G1,G2], 0, Result),
    Result = [[1,1]].

:- end_tests(overlay_priority).

:- begin_tests(overlay_replace).

test(replace_basic) :-
    Grid = [[1,2,1],[2,1,2]],
    overlay_replace(Grid, 1, 9, Result),
    Result = [[9,2,9],[2,9,2]].

test(replace_not_present) :-
    Grid = [[1,2],[3,4]],
    overlay_replace(Grid, 5, 9, Result),
    Result = [[1,2],[3,4]].

test(replace_all_same) :-
    Grid = [[0,0],[0,0]],
    overlay_replace(Grid, 0, 5, Result),
    Result = [[5,5],[5,5]].

:- end_tests(overlay_replace).

:- begin_tests(overlay_fill_bg).

test(fill_bg_basic) :-
    Grid = [[1,0,0],[0,2,0]],
    overlay_fill_bg(Grid, 0, 9, Result),
    Result = [[1,9,9],[9,2,9]].

test(fill_bg_none) :-
    Grid = [[1,2],[3,4]],
    overlay_fill_bg(Grid, 0, 9, Result),
    Result = [[1,2],[3,4]].

test(fill_bg_all) :-
    Grid = [[0,0],[0,0]],
    overlay_fill_bg(Grid, 0, 5, Result),
    Result = [[5,5],[5,5]].

:- end_tests(overlay_fill_bg).

:- begin_tests(overlay_max).

test(max_basic) :-
    A = [[1,5],[3,2]],
    B = [[4,2],[1,6]],
    overlay_max(A, B, Result),
    Result = [[4,5],[3,6]].

test(max_same) :-
    A = [[1,2],[3,4]],
    overlay_max(A, A, Result),
    Result = A.

:- end_tests(overlay_max).

:- begin_tests(overlay_min).

test(min_basic) :-
    A = [[1,5],[3,2]],
    B = [[4,2],[1,6]],
    overlay_min(A, B, Result),
    Result = [[1,2],[1,2]].

test(min_same) :-
    A = [[1,2],[3,4]],
    overlay_min(A, A, Result),
    Result = A.

:- end_tests(overlay_min).
