:- use_module('../prolog/color_map').

:- begin_tests(color_map).

% --- color_map_apply ---

test(apply_basic) :-
    color_map_apply([1-9, 2-8], [[1,2],[3,1]], G),
    G = [[9,8],[3,9]].

test(apply_no_match) :-
    color_map_apply([1-9], [[3,4],[5,6]], G),
    G = [[3,4],[5,6]].

test(apply_all_match) :-
    color_map_apply([0-1, 1-0], [[0,1],[1,0]], G),
    G = [[1,0],[0,1]].

% --- color_map_apply_default ---

test(apply_default_basic) :-
    color_map_apply_default([1-9, 2-8], 0, [[1,2],[3,1]], G),
    G = [[9,8],[0,9]].

test(apply_default_all_miss) :-
    color_map_apply_default([5-6], 0, [[1,2],[3,4]], G),
    G = [[0,0],[0,0]].

test(apply_default_all_hit) :-
    color_map_apply_default([1-2, 3-4], 0, [[1,3],[1,3]], G),
    G = [[2,4],[2,4]].

% --- color_map_invert ---

test(invert_swap) :-
    color_map_invert([1-9, 2-8], [[9,8],[9,8]], G),
    G = [[1,2],[1,2]].

test(invert_identity) :-
    color_map_invert([1-1, 2-2], [[1,2],[2,1]], G),
    G = [[1,2],[2,1]].

test(invert_no_match) :-
    color_map_invert([1-9], [[3,4],[5,6]], G),
    G = [[3,4],[5,6]].

% --- color_map_compose ---

test(compose_chain) :-
    color_map_compose([1-2, 3-4], [2-9, 4-7], MapAB),
    MapAB = [1-9, 3-7].

test(compose_partial) :-
    color_map_compose([1-2, 3-4], [2-9], MapAB),
    MapAB = [1-9, 3-4].

test(compose_identity) :-
    color_map_compose([1-2, 3-4], [1-1, 2-2, 3-3, 4-4], MapAB),
    MapAB = [1-2, 3-4].

% --- color_map_from_grids ---

test(from_grids_basic) :-
    color_map_from_grids([[1,2],[3,4]], [[5,6],[7,8]], Map),
    Map = [1-5, 2-6, 3-7, 4-8].

test(from_grids_identity) :-
    color_map_from_grids([[1,2],[3,4]], [[1,2],[3,4]], Map),
    Map = [1-1, 2-2, 3-3, 4-4].

test(from_grids_constant) :-
    color_map_from_grids([[1,2]], [[0,0]], Map),
    Map = [1-0, 2-0].

% --- color_map_identity ---

test(identity_two) :-
    color_map_identity([1,2], Map),
    Map = [1-1, 2-2].

test(identity_three) :-
    color_map_identity([0,1,2], Map),
    Map = [0-0, 1-1, 2-2].

test(identity_single) :-
    color_map_identity([5], Map),
    Map = [5-5].

% --- color_map_remap ---

test(remap_basic) :-
    color_map_remap([1,2,3], [9,8,7], Map),
    Map = [1-9, 2-8, 3-7].

test(remap_single) :-
    color_map_remap([0], [1], Map),
    Map = [0-1].

test(remap_two) :-
    color_map_remap([a,b], [x,y], Map),
    Map = [a-x, b-y].

% --- color_map_remap_list ---

test(remap_list_basic) :-
    color_map_remap_list([1-9, 2-8], [1,2,3,1], L),
    L = [9,8,3,9].

test(remap_list_no_match) :-
    color_map_remap_list([5-6], [1,2,3], L),
    L = [1,2,3].

test(remap_list_all_match) :-
    color_map_remap_list([0-1, 1-0], [0,1,0,1], L),
    L = [1,0,1,0].

% --- color_map_palette ---

test(palette_basic) :-
    color_map_palette([1-9, 2-8, 3-7], P),
    P = [1,2,3].

test(palette_single) :-
    color_map_palette([5-0], P),
    P = [5].

test(palette_sorted) :-
    color_map_palette([3-0, 1-0, 2-0], P),
    P = [1,2,3].

% --- color_map_used ---

test(used_basic) :-
    color_map_used([[1,2],[3,2]], U),
    U = [1,2,3].

test(used_all_same) :-
    color_map_used([[0,0],[0,0]], U),
    U = [0].

test(used_sorted) :-
    color_map_used([[3,1],[2,1]], U),
    U = [1,2,3].

% --- color_map_has_key ---

test(has_key_present) :-
    color_map_has_key([1-9, 2-8], 1).

test(has_key_second) :-
    color_map_has_key([1-9, 2-8], 2).

test(has_key_absent, fail) :-
    color_map_has_key([1-9, 2-8], 5).

% --- color_map_lookup ---

test(lookup_first) :-
    color_map_lookup([1-9, 2-8], 1, V),
    V = 9.

test(lookup_second) :-
    color_map_lookup([1-9, 2-8], 2, V),
    V = 8.

test(lookup_absent, fail) :-
    color_map_lookup([1-9, 2-8], 5, _).

% --- color_map_restrict ---

test(restrict_subset) :-
    color_map_restrict([1-9, 2-8, 3-7], [1,3], M),
    M = [1-9, 3-7].

test(restrict_all) :-
    color_map_restrict([1-9, 2-8], [1,2], M),
    M = [1-9, 2-8].

test(restrict_none) :-
    color_map_restrict([1-9, 2-8], [5,6], M),
    M = [].

% --- color_map_expand ---

test(expand_adds_missing) :-
    color_map_expand([1-9], 0, [1,2,3], M),
    M = [1-9, 2-0, 3-0].

test(expand_all_present) :-
    color_map_expand([1-9, 2-8], 0, [1,2], M),
    M = [1-9, 2-8].

test(expand_all_missing) :-
    color_map_expand([], 0, [1,2], M),
    M = [1-0, 2-0].

:- end_tests(color_map).
