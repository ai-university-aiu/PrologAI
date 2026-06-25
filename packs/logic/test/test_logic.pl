% PLUnit tests for the logic pack (lg_* predicates, Layer 78).
:- use_module(library(plunit)).
:- use_module(library(logic)).

:- begin_tests(logic_and).

test(and_both_fg) :-
    lg_and([[1,0],[0,1]], [[1,1],[0,0]], 0, G),
    G = [[1,0],[0,0]].

test(and_no_overlap) :-
    lg_and([[1,0],[0,0]], [[0,1],[0,0]], 0, G),
    G = [[0,0],[0,0]].

test(and_full) :-
    lg_and([[1,1],[1,1]], [[1,1],[1,1]], 0, G),
    G = [[1,1],[1,1]].

:- end_tests(logic_and).

:- begin_tests(logic_or).

test(or_basic) :-
    lg_or([[1,0],[0,0]], [[0,1],[0,0]], 0, G),
    G = [[1,1],[0,0]].

test(or_g1_wins) :-
    lg_or([[2,0],[0,0]], [[3,0],[0,0]], 0, G),
    G = [[2,0],[0,0]].

test(or_all_bg) :-
    lg_or([[0,0],[0,0]], [[0,0],[0,0]], 0, G),
    G = [[0,0],[0,0]].

:- end_tests(logic_or).

:- begin_tests(logic_xor).

test(xor_basic) :-
    lg_xor([[1,0],[0,1]], [[0,1],[0,0]], 0, G),
    G = [[1,1],[0,1]].

test(xor_both_cancel) :-
    lg_xor([[1,0],[0,0]], [[1,0],[0,0]], 0, G),
    G = [[0,0],[0,0]].

test(xor_all_bg) :-
    lg_xor([[0,0],[0,0]], [[0,0],[0,0]], 0, G),
    G = [[0,0],[0,0]].

:- end_tests(logic_xor).

:- begin_tests(logic_not).

test(not_basic) :-
    lg_not([[0,1],[1,0]], 0, 9, G),
    G = [[9,0],[0,9]].

test(not_all_bg) :-
    lg_not([[0,0],[0,0]], 0, 9, G),
    G = [[9,9],[9,9]].

test(not_all_fg) :-
    lg_not([[1,1],[1,1]], 0, 9, G),
    G = [[0,0],[0,0]].

:- end_tests(logic_not).

:- begin_tests(logic_diff).

test(diff_basic) :-
    lg_diff([[1,0],[0,1]], [[0,0],[0,1]], 0, G),
    G = [[1,0],[0,0]].

test(diff_nothing_left) :-
    lg_diff([[1,0],[0,0]], [[1,0],[0,0]], 0, G),
    G = [[0,0],[0,0]].

test(diff_all_left) :-
    lg_diff([[1,1],[1,1]], [[0,0],[0,0]], 0, G),
    G = [[1,1],[1,1]].

:- end_tests(logic_diff).

:- begin_tests(logic_overlay).

test(overlay_basic) :-
    lg_overlay([[1,1],[1,1]], [[2,0],[0,3]], 0, G),
    G = [[2,1],[1,3]].

test(overlay_transparent) :-
    lg_overlay([[1,2],[3,4]], [[0,0],[0,0]], 0, G),
    G = [[1,2],[3,4]].

test(overlay_full) :-
    lg_overlay([[1,1],[1,1]], [[2,2],[2,2]], 0, G),
    G = [[2,2],[2,2]].

:- end_tests(logic_overlay).

:- begin_tests(logic_mask_apply).

test(mask_apply_basic) :-
    lg_mask_apply([[1,0],[0,1]], [[5,6],[7,8]], 0, G),
    G = [[5,0],[0,8]].

test(mask_apply_none) :-
    lg_mask_apply([[0,0],[0,0]], [[5,6],[7,8]], 0, G),
    G = [[0,0],[0,0]].

test(mask_apply_all) :-
    lg_mask_apply([[1,1],[1,1]], [[5,6],[7,8]], 0, G),
    G = [[5,6],[7,8]].

:- end_tests(logic_mask_apply).

:- begin_tests(logic_mask_from).

test(mask_from_basic) :-
    lg_mask_from([[1,0],[0,2]], 0, 1, M),
    M = [[1,0],[0,1]].

test(mask_from_all_bg) :-
    lg_mask_from([[0,0],[0,0]], 0, 1, M),
    M = [[0,0],[0,0]].

test(mask_from_all_fg) :-
    lg_mask_from([[2,3],[4,5]], 0, 1, M),
    M = [[1,1],[1,1]].

:- end_tests(logic_mask_from).

:- begin_tests(logic_any_row).

test(any_row_basic) :-
    lg_any_row([[1,0],[0,0],[0,2]], 0, F),
    F = [1,0,1].

test(any_row_all_bg) :-
    lg_any_row([[0,0],[0,0]], 0, F),
    F = [0,0].

test(any_row_all_fg) :-
    lg_any_row([[1,2],[3,4]], 0, F),
    F = [1,1].

:- end_tests(logic_any_row).

:- begin_tests(logic_any_col).

test(any_col_basic) :-
    lg_any_col([[0,1,0],[0,0,0]], 0, F),
    F = [0,1,0].

test(any_col_all_bg) :-
    lg_any_col([[0,0],[0,0]], 0, F),
    F = [0,0].

test(any_col_all_fg) :-
    lg_any_col([[1,2],[3,4]], 0, F),
    F = [1,1].

:- end_tests(logic_any_col).

:- begin_tests(logic_all_row).

test(all_row_basic) :-
    lg_all_row([[1,2],[1,0],[0,0]], 0, F),
    F = [1,0,0].

test(all_row_all_bg) :-
    lg_all_row([[0,0],[0,0]], 0, F),
    F = [0,0].

test(all_row_all_fg) :-
    lg_all_row([[1,2],[3,4]], 0, F),
    F = [1,1].

:- end_tests(logic_all_row).

:- begin_tests(logic_all_col).

test(all_col_basic) :-
    lg_all_col([[1,0],[1,0]], 0, F),
    F = [1,0].

test(all_col_all_bg) :-
    lg_all_col([[0,0],[0,0]], 0, F),
    F = [0,0].

test(all_col_all_fg) :-
    lg_all_col([[1,2],[3,4]], 0, F),
    F = [1,1].

:- end_tests(logic_all_col).

:- begin_tests(logic_eq).

test(eq_basic) :-
    lg_eq([[1,2],[3,4]], [[1,0],[0,4]], G),
    G = [[1,0],[0,1]].

test(eq_identical) :-
    lg_eq([[1,2],[3,4]], [[1,2],[3,4]], G),
    G = [[1,1],[1,1]].

test(eq_disjoint) :-
    lg_eq([[1,2],[3,4]], [[5,6],[7,8]], G),
    G = [[0,0],[0,0]].

:- end_tests(logic_eq).

:- begin_tests(logic_neq).

test(neq_basic) :-
    lg_neq([[1,2],[3,4]], [[1,0],[0,4]], G),
    G = [[0,1],[1,0]].

test(neq_identical) :-
    lg_neq([[1,2],[3,4]], [[1,2],[3,4]], G),
    G = [[0,0],[0,0]].

test(neq_disjoint) :-
    lg_neq([[1,2],[3,4]], [[5,6],[7,8]], G),
    G = [[1,1],[1,1]].

:- end_tests(logic_neq).
