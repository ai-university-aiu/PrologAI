:- use_module('../prolog/mask').

:- begin_tests(mask).

% --- mk_from_val ---

test(from_val_mixed) :-
    mk_from_val([[1,0,1],[0,1,0]], 1, Mask),
    Mask = [[1,0,1],[0,1,0]].

test(from_val_absent) :-
    mk_from_val([[0,0],[0,0]], 1, Mask),
    Mask = [[0,0],[0,0]].

test(from_val_all) :-
    mk_from_val([[5,5,5]], 5, Mask),
    Mask = [[1,1,1]].

% --- mk_from_bg ---

test(from_bg_mixed) :-
    mk_from_bg([[0,1,0],[1,0,1]], 0, Mask),
    Mask = [[0,1,0],[1,0,1]].

test(from_bg_all_bg) :-
    mk_from_bg([[0,0],[0,0]], 0, Mask),
    Mask = [[0,0],[0,0]].

test(from_bg_none_bg) :-
    mk_from_bg([[1,2,3]], 0, Mask),
    Mask = [[1,1,1]].

% --- mk_invert ---

test(invert_mixed) :-
    mk_invert([[1,0],[0,1]], Mask2),
    Mask2 = [[0,1],[1,0]].

test(invert_all_zero) :-
    mk_invert([[0,0],[0,0]], Mask2),
    Mask2 = [[1,1],[1,1]].

test(invert_all_one) :-
    mk_invert([[1,1],[1,1]], Mask2),
    Mask2 = [[0,0],[0,0]].

% --- mk_and ---

test(and_mixed) :-
    mk_and([[1,0],[1,1]], [[1,1],[0,1]], MC),
    MC = [[1,0],[0,1]].

test(and_zeros) :-
    mk_and([[0,0],[0,0]], [[1,1],[1,1]], MC),
    MC = [[0,0],[0,0]].

test(and_all_one) :-
    mk_and([[1,1],[1,1]], [[1,1],[1,1]], MC),
    MC = [[1,1],[1,1]].

% --- mk_or ---

test(or_disjoint) :-
    mk_or([[1,0],[0,0]], [[0,0],[0,1]], MC),
    MC = [[1,0],[0,1]].

test(or_zeros) :-
    mk_or([[0,0],[0,0]], [[0,0],[0,0]], MC),
    MC = [[0,0],[0,0]].

test(or_complement) :-
    mk_or([[1,0],[1,0]], [[0,1],[0,1]], MC),
    MC = [[1,1],[1,1]].

% --- mk_xor ---

test(xor_mixed) :-
    mk_xor([[1,0],[0,1]], [[1,1],[0,0]], MC),
    MC = [[0,1],[0,1]].

test(xor_zeros) :-
    mk_xor([[0,0]], [[0,0]], MC),
    MC = [[0,0]].

test(xor_all_same) :-
    mk_xor([[1,1],[1,1]], [[1,1],[1,1]], MC),
    MC = [[0,0],[0,0]].

% --- mk_apply ---

test(apply_mixed) :-
    mk_apply([[1,2],[3,4]], [[1,0],[0,1]], 0, G),
    G = [[1,0],[0,4]].

test(apply_none) :-
    mk_apply([[5,5],[5,5]], [[0,0],[0,0]], 0, G),
    G = [[0,0],[0,0]].

test(apply_all) :-
    mk_apply([[1,2],[3,4]], [[1,1],[1,1]], 0, G),
    G = [[1,2],[3,4]].

% --- mk_fill ---

test(fill_corners) :-
    mk_fill([[1,2],[3,4]], [[1,0],[0,1]], 9, G),
    G = [[9,2],[3,9]].

test(fill_none) :-
    mk_fill([[5,5]], [[0,0]], 9, G),
    G = [[5,5]].

test(fill_all) :-
    mk_fill([[1,2],[3,4]], [[1,1],[1,1]], 0, G),
    G = [[0,0],[0,0]].

% --- mk_overlay ---

test(overlay_mixed) :-
    mk_overlay([[1,1],[1,1]], [[2,2],[2,2]], [[1,0],[0,1]], G),
    G = [[2,1],[1,2]].

test(overlay_none) :-
    mk_overlay([[1,2],[3,4]], [[5,6],[7,8]], [[0,0],[0,0]], G),
    G = [[1,2],[3,4]].

test(overlay_all) :-
    mk_overlay([[1,2],[3,4]], [[5,6],[7,8]], [[1,1],[1,1]], G),
    G = [[5,6],[7,8]].

% --- mk_where ---

test(where_some) :-
    mk_where([[1,0,1],[0,1,0]], Cells),
    Cells = [0-0,0-2,1-1].

test(where_none) :-
    mk_where([[0,0],[0,0]], Cells),
    Cells = [].

test(where_all) :-
    mk_where([[1,1],[1,1]], Cells),
    Cells = [0-0,0-1,1-0,1-1].

% --- mk_count ---

test(count_some) :-
    mk_count([[1,0,1],[0,1,0]], N),
    N = 3.

test(count_none) :-
    mk_count([[0,0],[0,0]], N),
    N = 0.

test(count_all) :-
    mk_count([[1,1],[1,1]], N),
    N = 4.

% --- mk_any ---

test(any_present) :-
    mk_any([[0,0],[0,1]]).

test(any_absent, fail) :-
    mk_any([[0,0],[0,0]]).

test(any_all) :-
    mk_any([[1,1],[1,1]]).

% --- mk_all ---

test(all_full) :-
    mk_all([[1,1],[1,1]]).

test(all_partial, fail) :-
    mk_all([[1,0],[1,1]]).

test(all_single) :-
    mk_all([[1]]).

% --- mk_extract ---

test(extract_some) :-
    mk_extract([[1,2,3],[4,5,6]], [[1,0,1],[0,1,0]], Vals),
    Vals = [1,3,5].

test(extract_none) :-
    mk_extract([[1,2],[3,4]], [[0,0],[0,0]], Vals),
    Vals = [].

test(extract_dedup) :-
    mk_extract([[1,1],[1,1]], [[1,1],[1,1]], Vals),
    Vals = [1].

:- end_tests(mask).
