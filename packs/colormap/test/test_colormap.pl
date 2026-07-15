:- use_module('../prolog/colormap').

:- begin_tests(colormap).

% --- colormap_apply ---

test(apply_basic) :-
    colormap_apply([1-9, 2-8], [[1,2],[3,1]], G),
    G = [[9,8],[3,9]].

test(apply_no_match) :-
    colormap_apply([1-9], [[3,4],[5,6]], G),
    G = [[3,4],[5,6]].

test(apply_all_match) :-
    colormap_apply([0-1, 1-0], [[0,1],[1,0]], G),
    G = [[1,0],[0,1]].

% --- colormap_apply_default ---

test(apply_default_basic) :-
    colormap_apply_default([1-9, 2-8], 0, [[1,2],[3,1]], G),
    G = [[9,8],[0,9]].

test(apply_default_all_miss) :-
    colormap_apply_default([5-6], 0, [[1,2],[3,4]], G),
    G = [[0,0],[0,0]].

test(apply_default_all_hit) :-
    colormap_apply_default([1-2, 3-4], 0, [[1,3],[1,3]], G),
    G = [[2,4],[2,4]].

% --- colormap_invert ---

test(invert_swap) :-
    colormap_invert([1-9, 2-8], [[9,8],[9,8]], G),
    G = [[1,2],[1,2]].

test(invert_identity) :-
    colormap_invert([1-1, 2-2], [[1,2],[2,1]], G),
    G = [[1,2],[2,1]].

test(invert_no_match) :-
    colormap_invert([1-9], [[3,4],[5,6]], G),
    G = [[3,4],[5,6]].

% --- colormap_compose ---

test(compose_chain) :-
    colormap_compose([1-2, 3-4], [2-9, 4-7], MapAB),
    MapAB = [1-9, 3-7].

test(compose_partial) :-
    colormap_compose([1-2, 3-4], [2-9], MapAB),
    MapAB = [1-9, 3-4].

test(compose_identity) :-
    colormap_compose([1-2, 3-4], [1-1, 2-2, 3-3, 4-4], MapAB),
    MapAB = [1-2, 3-4].

% --- colormap_from_grids ---

test(from_grids_basic) :-
    colormap_from_grids([[1,2],[3,4]], [[5,6],[7,8]], Map),
    Map = [1-5, 2-6, 3-7, 4-8].

test(from_grids_identity) :-
    colormap_from_grids([[1,2],[3,4]], [[1,2],[3,4]], Map),
    Map = [1-1, 2-2, 3-3, 4-4].

test(from_grids_constant) :-
    colormap_from_grids([[1,2]], [[0,0]], Map),
    Map = [1-0, 2-0].

% --- colormap_identity ---

test(identity_two) :-
    colormap_identity([1,2], Map),
    Map = [1-1, 2-2].

test(identity_three) :-
    colormap_identity([0,1,2], Map),
    Map = [0-0, 1-1, 2-2].

test(identity_single) :-
    colormap_identity([5], Map),
    Map = [5-5].

% --- colormap_remap ---

test(remap_basic) :-
    colormap_remap([1,2,3], [9,8,7], Map),
    Map = [1-9, 2-8, 3-7].

test(remap_single) :-
    colormap_remap([0], [1], Map),
    Map = [0-1].

test(remap_two) :-
    colormap_remap([a,b], [x,y], Map),
    Map = [a-x, b-y].

% --- colormap_remap_list ---

test(remap_list_basic) :-
    colormap_remap_list([1-9, 2-8], [1,2,3,1], L),
    L = [9,8,3,9].

test(remap_list_no_match) :-
    colormap_remap_list([5-6], [1,2,3], L),
    L = [1,2,3].

test(remap_list_all_match) :-
    colormap_remap_list([0-1, 1-0], [0,1,0,1], L),
    L = [1,0,1,0].

% --- colormap_palette ---

test(palette_basic) :-
    colormap_palette([1-9, 2-8, 3-7], P),
    P = [1,2,3].

test(palette_single) :-
    colormap_palette([5-0], P),
    P = [5].

test(palette_sorted) :-
    colormap_palette([3-0, 1-0, 2-0], P),
    P = [1,2,3].

% --- colormap_used ---

test(used_basic) :-
    colormap_used([[1,2],[3,2]], U),
    U = [1,2,3].

test(used_all_same) :-
    colormap_used([[0,0],[0,0]], U),
    U = [0].

test(used_sorted) :-
    colormap_used([[3,1],[2,1]], U),
    U = [1,2,3].

% --- colormap_has_key ---

test(has_key_present) :-
    colormap_has_key([1-9, 2-8], 1).

test(has_key_second) :-
    colormap_has_key([1-9, 2-8], 2).

test(has_key_absent, fail) :-
    colormap_has_key([1-9, 2-8], 5).

% --- colormap_lookup ---

test(lookup_first) :-
    colormap_lookup([1-9, 2-8], 1, V),
    V = 9.

test(lookup_second) :-
    colormap_lookup([1-9, 2-8], 2, V),
    V = 8.

test(lookup_absent, fail) :-
    colormap_lookup([1-9, 2-8], 5, _).

% --- colormap_restrict ---

test(restrict_subset) :-
    colormap_restrict([1-9, 2-8, 3-7], [1,3], M),
    M = [1-9, 3-7].

test(restrict_all) :-
    colormap_restrict([1-9, 2-8], [1,2], M),
    M = [1-9, 2-8].

test(restrict_none) :-
    colormap_restrict([1-9, 2-8], [5,6], M),
    M = [].

% --- colormap_expand ---

test(expand_adds_missing) :-
    colormap_expand([1-9], 0, [1,2,3], M),
    M = [1-9, 2-0, 3-0].

test(expand_all_present) :-
    colormap_expand([1-9, 2-8], 0, [1,2], M),
    M = [1-9, 2-8].

test(expand_all_missing) :-
    colormap_expand([], 0, [1,2], M),
    M = [1-0, 2-0].

:- end_tests(colormap).
