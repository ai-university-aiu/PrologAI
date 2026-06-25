% PLUnit tests for the lookup pack (lk_* predicates).
:- use_module(library(plunit)).
:- use_module(library(lookup)).

% Helper data.
sample_map([a-1, b-2, c-3]).
color_grid([[0,1,0],[2,0,1],[0,2,0]]).

:- begin_tests(lookup_lk_get).

test(get_first) :-
    sample_map(M), lk_get(a, M, V), V =:= 1.

test(get_middle) :-
    sample_map(M), lk_get(b, M, V), V =:= 2.

test(get_last) :-
    sample_map(M), lk_get(c, M, V), V =:= 3.

test(get_integer_key) :-
    lk_get(0, [0-red, 1-blue], V), V = red.

:- end_tests(lookup_lk_get).

:- begin_tests(lookup_lk_has_key).

test(has_key_present) :-
    sample_map(M), lk_has_key(a, M).

test(has_key_absent) :-
    sample_map(M), \+ lk_has_key(z, M).

:- end_tests(lookup_lk_has_key).

:- begin_tests(lookup_lk_put).

test(put_new_key) :-
    sample_map(M), lk_put(d, 4, M, M2),
    lk_get(d, M2, V), V =:= 4.

test(put_existing_key) :-
    sample_map(M), lk_put(b, 99, M, M2),
    lk_get(b, M2, V), V =:= 99.

test(put_first_key) :-
    lk_put(x, 7, [], M), M = [x-7].

:- end_tests(lookup_lk_put).

:- begin_tests(lookup_lk_delete).

test(delete_existing) :-
    sample_map(M), lk_delete(b, M, M2),
    \+ lk_has_key(b, M2),
    lk_has_key(a, M2), lk_has_key(c, M2).

test(delete_absent) :-
    % Deleting a key that doesn't exist: map unchanged.
    sample_map(M), lk_delete(z, M, M2),
    M2 = M.

test(delete_from_empty) :-
    lk_delete(a, [], M2), M2 = [].

:- end_tests(lookup_lk_delete).

:- begin_tests(lookup_lk_keys).

test(keys_basic) :-
    sample_map(M), lk_keys(M, Ks), Ks = [a, b, c].

test(keys_empty) :-
    lk_keys([], Ks), Ks = [].

:- end_tests(lookup_lk_keys).

:- begin_tests(lookup_lk_values).

test(values_basic) :-
    sample_map(M), lk_values(M, Vs), Vs = [1, 2, 3].

test(values_empty) :-
    lk_values([], Vs), Vs = [].

:- end_tests(lookup_lk_values).

:- begin_tests(lookup_lk_map_values).

test(map_values_double) :-
    M = [a-2, b-4, c-6],
    lk_map_values(M, lk_half_, NewM),
    NewM = [a-1, b-2, c-3].

% Helper predicate for test.
lk_half_(V, H) :- H is V // 2.

:- end_tests(lookup_lk_map_values).

:- begin_tests(lookup_lk_from_pairs).

test(from_pairs_identity) :-
    Pairs = [x-1, y-2],
    lk_from_pairs(Pairs, Map),
    Map = Pairs.

:- end_tests(lookup_lk_from_pairs).

:- begin_tests(lookup_lk_grid_row).

test(row_0) :-
    color_grid(G), lk_grid_row(G, 0, R), R = [0,1,0].

test(row_1) :-
    color_grid(G), lk_grid_row(G, 1, R), R = [2,0,1].

:- end_tests(lookup_lk_grid_row).

:- begin_tests(lookup_lk_grid_col).

test(col_0) :-
    color_grid(G), lk_grid_col(G, 0, C), C = [0,2,0].

test(col_1) :-
    color_grid(G), lk_grid_col(G, 1, C), C = [1,0,2].

:- end_tests(lookup_lk_grid_col).

:- begin_tests(lookup_lk_grid_cell).

test(cell_0_1) :-
    color_grid(G), lk_grid_cell(G, 0, 1, V), V =:= 1.

test(cell_1_0) :-
    color_grid(G), lk_grid_cell(G, 1, 0, V), V =:= 2.

:- end_tests(lookup_lk_grid_cell).

:- begin_tests(lookup_lk_color_positions).

test(color_positions_basic) :-
    % color_grid = [[0,1,0],[2,0,1],[0,2,0]]
    % BG = 0; color 1 at (0,1),(1,2); color 2 at (1,0),(2,1).
    color_grid(G),
    lk_color_positions(G, 0, Map),
    % Map should have 1->[r(0,1),r(1,2)] and 2->[r(1,0),r(2,1)].
    lk_get(1, Map, Pos1), msort(Pos1, SP1), SP1 = [r(0,1), r(1,2)],
    lk_get(2, Map, Pos2), msort(Pos2, SP2), SP2 = [r(1,0), r(2,1)].

test(color_positions_empty) :-
    % All background: empty map.
    lk_color_positions([[0,0],[0,0]], 0, Map),
    Map = [].

:- end_tests(lookup_lk_color_positions).

:- begin_tests(lookup_lk_position_color).

test(position_color_basic) :-
    color_grid(G),
    lk_position_color(G, 0, Map),
    % Non-bg cells: (0,1)->1, (1,0)->2, (1,2)->1, (2,1)->2.
    length(Map, L), L =:= 4,
    lk_get(r(0,1), Map, V01), V01 =:= 1,
    lk_get(r(1,0), Map, V10), V10 =:= 2.

test(position_color_empty) :-
    lk_position_color([[0,0]], 0, Map), Map = [].

:- end_tests(lookup_lk_position_color).

:- begin_tests(lookup_lk_invert).

test(invert_basic) :-
    sample_map(M), lk_invert(M, Inv),
    Inv = [1-a, 2-b, 3-c].

test(invert_twice) :-
    sample_map(M), lk_invert(M, Inv), lk_invert(Inv, M2),
    M2 = M.

:- end_tests(lookup_lk_invert).
