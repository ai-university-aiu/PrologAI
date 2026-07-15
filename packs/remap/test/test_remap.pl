% PLUnit tests for the remap pack (rm_* predicates, Layer 77).
:- use_module(library(plunit)).
:- use_module(library(remap)).

:- begin_tests(remap_replace).

test(replace_basic) :-
    remap_replace([[1,0],[0,1]], 0, 9, G),
    G = [[1,9],[9,1]].

test(replace_none) :-
    remap_replace([[1,2],[3,4]], 0, 9, G),
    G = [[1,2],[3,4]].

test(replace_all) :-
    remap_replace([[0,0],[0,0]], 0, 5, G),
    G = [[5,5],[5,5]].

:- end_tests(remap_replace).

:- begin_tests(remap_swap).

test(swap_basic) :-
    remap_swap([[1,2],[2,1]], 1, 2, G),
    G = [[2,1],[1,2]].

test(swap_no_b) :-
    remap_swap([[1,3],[3,1]], 1, 2, G),
    G = [[2,3],[3,2]].

test(swap_symmetric) :-
    G = [[1,2],[3,4]],
    remap_swap(G, 1, 2, G2),
    remap_swap(G2, 1, 2, G).

:- end_tests(remap_swap).

:- begin_tests(remap_apply_map).

test(apply_map_basic) :-
    Map = [1-9, 2-8],
    remap_apply_map(Map, [[1,2],[3,4]], G),
    G = [[9,8],[3,4]].

test(apply_map_identity) :-
    remap_apply_map([], [[1,2],[3,4]], G),
    G = [[1,2],[3,4]].

test(apply_map_full) :-
    Map = [0-1, 1-0],
    remap_apply_map(Map, [[0,1],[1,0]], G),
    G = [[1,0],[0,1]].

:- end_tests(remap_apply_map).

:- begin_tests(remap_apply_map_to).

test(apply_map_to_basic) :-
    Map = [1-9],
    remap_apply_map_to(Map, 1, [[1,2],[1,3]], G),
    G = [[9,2],[9,3]].

test(apply_map_to_no_match) :-
    Map = [5-9],
    remap_apply_map_to(Map, 5, [[1,2],[3,4]], G),
    G = [[1,2],[3,4]].

:- end_tests(remap_apply_map_to).

:- begin_tests(remap_invert_map).

test(invert_basic) :-
    remap_invert_map([1-9, 2-8], Inv),
    Inv = [9-1, 8-2].

test(invert_identity) :-
    remap_invert_map([1-1, 2-2], Inv),
    Inv = [1-1, 2-2].

:- end_tests(remap_invert_map).

:- begin_tests(remap_compose_maps).

test(compose_basic) :-
    Map1 = [1-2, 3-4],
    Map2 = [2-9, 4-8],
    remap_compose_maps(Map1, Map2, Composed),
    Composed = [1-9, 3-8].

test(compose_identity_second) :-
    Map1 = [1-2, 3-4],
    remap_compose_maps(Map1, [], Composed),
    Composed = [1-2, 3-4].

test(compose_partial) :-
    Map1 = [1-2, 3-4],
    Map2 = [2-9],
    remap_compose_maps(Map1, Map2, Composed),
    Composed = [1-9, 3-4].

:- end_tests(remap_compose_maps).

:- begin_tests(remap_normalize).

test(normalize_basic) :-
    remap_normalize([[3,1],[5,3]], G),
    G = [[2,1],[3,2]].

test(normalize_already) :-
    remap_normalize([[1,2],[3,4]], G),
    G = [[1,2],[3,4]].

test(normalize_single_val) :-
    remap_normalize([[5,5],[5,5]], G),
    G = [[1,1],[1,1]].

:- end_tests(remap_normalize).

:- begin_tests(remap_shift).

test(shift_positive) :-
    remap_shift([[1,2],[3,4]], 10, G),
    G = [[11,12],[13,14]].

test(shift_zero) :-
    remap_shift([[1,2],[3,4]], 0, G),
    G = [[1,2],[3,4]].

test(shift_negative) :-
    remap_shift([[5,6],[7,8]], -3, G),
    G = [[2,3],[4,5]].

:- end_tests(remap_shift).

:- begin_tests(remap_clamp).

test(clamp_basic) :-
    remap_clamp([[0,5],[10,3]], 1, 8, G),
    G = [[1,5],[8,3]].

test(clamp_no_change) :-
    remap_clamp([[2,3],[4,5]], 1, 8, G),
    G = [[2,3],[4,5]].

test(clamp_all_low) :-
    remap_clamp([[0,0],[0,0]], 1, 9, G),
    G = [[1,1],[1,1]].

:- end_tests(remap_clamp).

:- begin_tests(remap_conditional).

test(conditional_basic) :-
    remap_conditional([X]>>(X =:= 0), [[1,0],[0,1]], 9, G),
    G = [[1,9],[9,1]].

test(conditional_none) :-
    remap_conditional([X]>>(X =:= 5), [[1,2],[3,4]], 9, G),
    G = [[1,2],[3,4]].

:- end_tests(remap_conditional).

:- begin_tests(remap_binarize).

test(binarize_basic) :-
    remap_binarize([[0,1],[2,0]], 0, 1, G),
    G = [[0,1],[1,0]].

test(binarize_all_fg) :-
    remap_binarize([[1,2],[3,4]], 0, 9, G),
    G = [[9,9],[9,9]].

test(binarize_all_bg) :-
    remap_binarize([[0,0],[0,0]], 0, 9, G),
    G = [[0,0],[0,0]].

:- end_tests(remap_binarize).

:- begin_tests(remap_remap_bg).

test(remap_bg_basic) :-
    remap_remap_bg([[0,1],[0,2]], 0, 9, G),
    G = [[9,1],[9,2]].

test(remap_bg_no_match) :-
    remap_remap_bg([[1,2],[3,4]], 0, 9, G),
    G = [[1,2],[3,4]].

:- end_tests(remap_remap_bg).

:- begin_tests(remap_palette).

test(palette_basic) :-
    remap_palette([[1,0],[2,1]], Pal),
    Pal = [0,1,2].

test(palette_single) :-
    remap_palette([[5,5],[5,5]], Pal),
    Pal = [5].

test(palette_sorted) :-
    remap_palette([[3,1,2],[2,3,1]], Pal),
    Pal = [1,2,3].

:- end_tests(remap_palette).

:- begin_tests(remap_reindex).

test(reindex_basic) :-
    remap_reindex([[3,1],[5,3]], [1,3,5], G),
    G = [[2,1],[3,2]].

test(reindex_single) :-
    remap_reindex([[9,9],[9,9]], [9], G),
    G = [[1,1],[1,1]].

test(reindex_identity) :-
    remap_reindex([[1,2],[3,4]], [1,2,3,4], G),
    G = [[1,2],[3,4]].

:- end_tests(remap_reindex).
