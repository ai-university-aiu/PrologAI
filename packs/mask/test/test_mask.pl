:- use_module('../prolog/mask').

:- begin_tests(mask).

% --- mask_from_val ---

test(from_val_mixed) :-
    mask_from_val([[1,0,1],[0,1,0]], 1, Mask),
    Mask = [[1,0,1],[0,1,0]].

test(from_val_absent) :-
    mask_from_val([[0,0],[0,0]], 1, Mask),
    Mask = [[0,0],[0,0]].

test(from_val_all) :-
    mask_from_val([[5,5,5]], 5, Mask),
    Mask = [[1,1,1]].

% --- mask_from_bg ---

test(from_bg_mixed) :-
    mask_from_bg([[0,1,0],[1,0,1]], 0, Mask),
    Mask = [[0,1,0],[1,0,1]].

test(from_bg_all_bg) :-
    mask_from_bg([[0,0],[0,0]], 0, Mask),
    Mask = [[0,0],[0,0]].

test(from_bg_none_bg) :-
    mask_from_bg([[1,2,3]], 0, Mask),
    Mask = [[1,1,1]].

% --- mask_invert ---

test(invert_mixed) :-
    mask_invert([[1,0],[0,1]], Mask2),
    Mask2 = [[0,1],[1,0]].

test(invert_all_zero) :-
    mask_invert([[0,0],[0,0]], Mask2),
    Mask2 = [[1,1],[1,1]].

test(invert_all_one) :-
    mask_invert([[1,1],[1,1]], Mask2),
    Mask2 = [[0,0],[0,0]].

% --- mask_and ---

test(and_mixed) :-
    mask_and([[1,0],[1,1]], [[1,1],[0,1]], MC),
    MC = [[1,0],[0,1]].

test(and_zeros) :-
    mask_and([[0,0],[0,0]], [[1,1],[1,1]], MC),
    MC = [[0,0],[0,0]].

test(and_all_one) :-
    mask_and([[1,1],[1,1]], [[1,1],[1,1]], MC),
    MC = [[1,1],[1,1]].

% --- mask_or ---

test(or_disjoint) :-
    mask_or([[1,0],[0,0]], [[0,0],[0,1]], MC),
    MC = [[1,0],[0,1]].

test(or_zeros) :-
    mask_or([[0,0],[0,0]], [[0,0],[0,0]], MC),
    MC = [[0,0],[0,0]].

test(or_complement) :-
    mask_or([[1,0],[1,0]], [[0,1],[0,1]], MC),
    MC = [[1,1],[1,1]].

% --- mask_xor ---

test(xor_mixed) :-
    mask_xor([[1,0],[0,1]], [[1,1],[0,0]], MC),
    MC = [[0,1],[0,1]].

test(xor_zeros) :-
    mask_xor([[0,0]], [[0,0]], MC),
    MC = [[0,0]].

test(xor_all_same) :-
    mask_xor([[1,1],[1,1]], [[1,1],[1,1]], MC),
    MC = [[0,0],[0,0]].

% --- mask_apply ---

test(apply_mixed) :-
    mask_apply([[1,2],[3,4]], [[1,0],[0,1]], 0, G),
    G = [[1,0],[0,4]].

test(apply_none) :-
    mask_apply([[5,5],[5,5]], [[0,0],[0,0]], 0, G),
    G = [[0,0],[0,0]].

test(apply_all) :-
    mask_apply([[1,2],[3,4]], [[1,1],[1,1]], 0, G),
    G = [[1,2],[3,4]].

% --- mask_fill ---

test(fill_corners) :-
    mask_fill([[1,2],[3,4]], [[1,0],[0,1]], 9, G),
    G = [[9,2],[3,9]].

test(fill_none) :-
    mask_fill([[5,5]], [[0,0]], 9, G),
    G = [[5,5]].

test(fill_all) :-
    mask_fill([[1,2],[3,4]], [[1,1],[1,1]], 0, G),
    G = [[0,0],[0,0]].

% --- mask_overlay ---

test(overlay_mixed) :-
    mask_overlay([[1,1],[1,1]], [[2,2],[2,2]], [[1,0],[0,1]], G),
    G = [[2,1],[1,2]].

test(overlay_none) :-
    mask_overlay([[1,2],[3,4]], [[5,6],[7,8]], [[0,0],[0,0]], G),
    G = [[1,2],[3,4]].

test(overlay_all) :-
    mask_overlay([[1,2],[3,4]], [[5,6],[7,8]], [[1,1],[1,1]], G),
    G = [[5,6],[7,8]].

% --- mask_where ---

test(where_some) :-
    mask_where([[1,0,1],[0,1,0]], Cells),
    Cells = [0-0,0-2,1-1].

test(where_none) :-
    mask_where([[0,0],[0,0]], Cells),
    Cells = [].

test(where_all) :-
    mask_where([[1,1],[1,1]], Cells),
    Cells = [0-0,0-1,1-0,1-1].

% --- mask_count ---

test(count_some) :-
    mask_count([[1,0,1],[0,1,0]], N),
    N = 3.

test(count_none) :-
    mask_count([[0,0],[0,0]], N),
    N = 0.

test(count_all) :-
    mask_count([[1,1],[1,1]], N),
    N = 4.

% --- mask_any ---

test(any_present) :-
    mask_any([[0,0],[0,1]]).

test(any_absent, fail) :-
    mask_any([[0,0],[0,0]]).

test(any_all) :-
    mask_any([[1,1],[1,1]]).

% --- mask_all ---

test(all_full) :-
    mask_all([[1,1],[1,1]]).

test(all_partial, fail) :-
    mask_all([[1,0],[1,1]]).

test(all_single) :-
    mask_all([[1]]).

% --- mask_extract ---

test(extract_some) :-
    mask_extract([[1,2,3],[4,5,6]], [[1,0,1],[0,1,0]], Vals),
    Vals = [1,3,5].

test(extract_none) :-
    mask_extract([[1,2],[3,4]], [[0,0],[0,0]], Vals),
    Vals = [].

test(extract_dedup) :-
    mask_extract([[1,1],[1,1]], [[1,1],[1,1]], Vals),
    Vals = [1].

:- end_tests(mask).
