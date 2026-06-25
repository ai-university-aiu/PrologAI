% PLUnit tests for the context pack (ctx_* predicates).
:- use_module(library(plunit)).
:- use_module('../prolog/context').

:- begin_tests(ctx_put).

test(put_basic) :-
    % Add a key to an empty map.
    ctx_put([], color, red, Map),
    Map = [color-red].

test(put_second) :-
    % Add a second key to a map.
    ctx_put([a-1], b, 2, Map),
    ctx_get(Map, a, 1),
    ctx_get(Map, b, 2).

test(put_replaces) :-
    % Adding the same key replaces the old value.
    ctx_put([x-1], x, 99, Map),
    ctx_get(Map, x, 99).

test(put_no_duplicate) :-
    % After put, only one binding for the key exists.
    ctx_put([k-1, k-2], k, 3, Map),
    ctx_keys(Map, Keys),
    Keys = [k].

:- end_tests(ctx_put).

:- begin_tests(ctx_get).

test(get_found) :-
    % Retrieve a value that exists.
    ctx_get([a-1, b-2, c-3], b, V),
    V = 2.

test(get_first) :-
    % Retrieve the first key.
    ctx_get([x-hello, y-world], x, V),
    V = hello.

test(get_fail) :-
    % Fail if key absent.
    \+ ctx_get([a-1, b-2], z, _).

:- end_tests(ctx_get).

:- begin_tests(ctx_has).

test(has_present) :-
    % Key that exists: true.
    ctx_has([a-1, b-2], a).

test(has_absent) :-
    % Key that does not exist: false.
    \+ ctx_has([a-1, b-2], c).

test(has_empty) :-
    % Empty map: always false.
    \+ ctx_has([], x).

:- end_tests(ctx_has).

:- begin_tests(ctx_delete).

test(delete_present) :-
    % Remove an existing key.
    ctx_delete([a-1, b-2, c-3], b, Map2),
    \+ ctx_has(Map2, b),
    ctx_get(Map2, a, 1),
    ctx_get(Map2, c, 3).

test(delete_absent) :-
    % Remove a key that does not exist: map unchanged.
    ctx_delete([a-1, b-2], z, Map2),
    ctx_size(Map2, 2).

test(delete_empty) :-
    % Delete from empty map: still empty.
    ctx_delete([], x, Map2),
    Map2 = [].

:- end_tests(ctx_delete).

:- begin_tests(ctx_keys).

test(keys_basic) :-
    % Extract all keys.
    ctx_keys([a-1, b-2, c-3], Keys),
    Keys = [a, b, c].

test(keys_empty) :-
    % Empty map has no keys.
    ctx_keys([], Keys),
    Keys = [].

test(keys_single) :-
    % Single-entry map.
    ctx_keys([x-42], Keys),
    Keys = [x].

:- end_tests(ctx_keys).

:- begin_tests(ctx_values).

test(values_basic) :-
    % Extract all values.
    ctx_values([a-1, b-2, c-3], Vals),
    Vals = [1, 2, 3].

test(values_empty) :-
    % Empty map has no values.
    ctx_values([], Vals),
    Vals = [].

:- end_tests(ctx_values).

:- begin_tests(ctx_from_pairs).

test(from_pairs_basic) :-
    % Build a map from pairs; all keys present.
    ctx_from_pairs([a-1, b-2, c-3], Map),
    ctx_get(Map, a, 1),
    ctx_get(Map, b, 2),
    ctx_get(Map, c, 3).

test(from_pairs_last_wins) :-
    % Duplicate key: last value wins.
    ctx_from_pairs([x-1, x-99], Map),
    ctx_get(Map, x, 99).

test(from_pairs_empty) :-
    % Empty pairs give empty map.
    ctx_from_pairs([], Map),
    Map = [].

:- end_tests(ctx_from_pairs).

:- begin_tests(ctx_to_pairs).

test(to_pairs_basic) :-
    % to_pairs is identity: a map is already a pair list.
    Map = [a-1, b-2],
    ctx_to_pairs(Map, Pairs),
    Pairs = [a-1, b-2].

:- end_tests(ctx_to_pairs).

:- begin_tests(ctx_merge).

test(merge_disjoint) :-
    % Merge two maps with no shared keys.
    ctx_merge([a-1, b-2], [c-3, d-4], Merged),
    ctx_get(Merged, a, 1),
    ctx_get(Merged, b, 2),
    ctx_get(Merged, c, 3),
    ctx_get(Merged, d, 4).

test(merge_override) :-
    % Map2 overrides Map1 for shared keys.
    ctx_merge([x-1, y-2], [x-99], Merged),
    ctx_get(Merged, x, 99),
    ctx_get(Merged, y, 2).

test(merge_empty_right) :-
    % Merging with an empty right map gives the left map.
    ctx_merge([a-1, b-2], [], Merged),
    ctx_get(Merged, a, 1),
    ctx_get(Merged, b, 2).

test(merge_empty_left) :-
    % Merging an empty left map with a right map gives the right map.
    ctx_merge([], [c-3], Merged),
    ctx_get(Merged, c, 3).

:- end_tests(ctx_merge).

:- begin_tests(ctx_dispatch).

% Helper: record which goal was called.
dispatch_result_holder_(nothing).

test(dispatch_found) :-
    % Key present: associated goal is called.
    % Use a side-effect-free test: goal just unifies the result.
    ctx_dispatch([op-[Args]>>(Args = called_op)], op, [_]>>(fail), Res),
    Res = called_op.

test(dispatch_not_found) :-
    % Key absent: default goal is called.
    ctx_dispatch([other-[_]>>(fail)], missing, [Args]>>(Args = called_default), Res),
    Res = called_default.

:- end_tests(ctx_dispatch).

:- begin_tests(ctx_select).

test(select_first_found) :-
    % First key in priority list is present.
    ctx_select([a-1, b-2, c-3], [b, c], none, V),
    V = 2.

test(select_fallback) :-
    % Second key in priority list when first is absent.
    ctx_select([a-1, c-3], [b, c], none, V),
    V = 3.

test(select_default) :-
    % No key in priority list is present: return default.
    ctx_select([a-1, b-2], [x, y, z], default_val, V),
    V = default_val.

test(select_empty_keys) :-
    % Empty key list: return default.
    ctx_select([a-1], [], fallback, V),
    V = fallback.

:- end_tests(ctx_select).

:- begin_tests(ctx_map_values).

test(map_values_basic) :-
    % Double all integer values.
    ctx_map_values([a-1, b-2, c-3], [V, V2]>>(V2 is V * 2), Map2),
    ctx_get(Map2, a, 2),
    ctx_get(Map2, b, 4),
    ctx_get(Map2, c, 6).

test(map_values_empty) :-
    % Empty map stays empty.
    ctx_map_values([], [V, V2]>>(V2 is V + 1), Map2),
    Map2 = [].

test(map_values_keys_unchanged) :-
    % Keys are preserved after value transform.
    ctx_map_values([x-10, y-20], [V, V2]>>(V2 is V // 10), Map2),
    ctx_keys(Map2, Keys),
    Keys = [x, y].

:- end_tests(ctx_map_values).

:- begin_tests(ctx_filter_keys).

test(filter_keys_basic) :-
    % Keep only keys that are atoms starting with 'a'.
    ctx_filter_keys([apple-1, banana-2, avocado-3, cherry-4],
                    [K]>>(atom_chars(K, [a|_])), Map2),
    ctx_size(Map2, 2),
    ctx_has(Map2, apple),
    ctx_has(Map2, avocado).

test(filter_keys_all) :-
    % Keep all keys.
    ctx_filter_keys([a-1, b-2, c-3], [_]>>true, Map2),
    ctx_size(Map2, 3).

test(filter_keys_none) :-
    % Keep no keys.
    ctx_filter_keys([a-1, b-2], [_]>>fail, Map2),
    Map2 = [].

:- end_tests(ctx_filter_keys).

:- begin_tests(ctx_size).

test(size_basic) :-
    % Three-entry map has size 3.
    ctx_size([a-1, b-2, c-3], N),
    N =:= 3.

test(size_empty) :-
    % Empty map has size 0.
    ctx_size([], N),
    N =:= 0.

test(size_one) :-
    % Single-entry map has size 1.
    ctx_size([x-42], N),
    N =:= 1.

:- end_tests(ctx_size).
