% Module declaration: context pack, Layer 71.
:- module(context, [
    % ctx_put/4: store a key-value binding in a context map.
    ctx_put/4,
    % ctx_get/3: retrieve a value by key from a context map.
    ctx_get/3,
    % ctx_has/2: test whether a key exists in a context map.
    ctx_has/2,
    % ctx_delete/3: remove a key from a context map.
    ctx_delete/3,
    % ctx_keys/2: extract all keys from a context map.
    ctx_keys/2,
    % ctx_values/2: extract all values from a context map.
    ctx_values/2,
    % ctx_from_pairs/2: build a context map from a list of Key-Value pairs.
    ctx_from_pairs/2,
    % ctx_to_pairs/2: convert a context map to a list of Key-Value pairs.
    ctx_to_pairs/2,
    % ctx_merge/3: merge two context maps; bindings in Map2 override Map1.
    ctx_merge/3,
    % ctx_dispatch/4: look up a key in a context map and call the associated goal.
    ctx_dispatch/4,
    % ctx_select/4: select the value for the first key in a priority list.
    ctx_select/4,
    % ctx_map_values/3: transform all values in a context map via a 2-argument goal.
    ctx_map_values/3,
    % ctx_filter_keys/3: keep only entries whose key satisfies a 1-argument goal.
    ctx_filter_keys/3,
    % ctx_size/2: number of entries in a context map.
    ctx_size/2
]).

% Import list utilities; msort/length/forall are built-ins, not imported.
:- use_module(library(lists), [member/2, subtract/3, append/3]).
% Import higher-order apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% A context map is a list of Key-Value pairs: [Key1-Val1, Key2-Val2, ...].
% Keys are unique. Operations maintain uniqueness.

% ctx_put(+Map, +Key, +Value, -Map2).
% Store Key-Value in Map. Replaces any existing binding for Key.
ctx_put(Map, Key, Value, Map2) :-
    % Remove any existing binding for Key.
    ctx_delete(Map, Key, Cleaned),
    % Prepend the new binding.
    Map2 = [Key-Value|Cleaned].

% ctx_get(+Map, +Key, -Value).
% Retrieve Value for Key from Map. Fails if Key is not present.
ctx_get([Key-Value|_], Key, Value) :- !.
ctx_get([_|Rest], Key, Value) :-
    % Search the rest of the map.
    ctx_get(Rest, Key, Value).

% ctx_has(+Map, +Key).
% Succeed if Key exists in Map.
ctx_has(Map, Key) :-
    % Attempt to retrieve; succeeds iff Key is present.
    ctx_get(Map, Key, _).

% ctx_delete(+Map, +Key, -Map2).
% Remove the binding for Key from Map. Succeeds even if Key is absent.
ctx_delete([], _, []).
ctx_delete([K-V|Rest], Key, Map2) :-
    % Use if-then-else to decide whether to drop or keep this entry.
    ( K == Key ->
        % Drop this entry.
        Map2 = Rest2,
        ctx_delete(Rest, Key, Rest2)
    ;   % Keep this entry.
        Map2 = [K-V|Rest2],
        ctx_delete(Rest, Key, Rest2)
    ).

% ctx_keys(+Map, -Keys).
% Keys is the list of all keys in Map.
ctx_keys(Map, Keys) :-
    % Extract the left part of each K-V pair.
    maplist(ctx_key_, Map, Keys).

% ctx_key_(+Pair, -Key): extract key from K-V pair.
ctx_key_(K-_, K).

% ctx_values(+Map, -Values).
% Values is the list of all values in Map.
ctx_values(Map, Values) :-
    % Extract the right part of each K-V pair.
    maplist(ctx_value_, Map, Values).

% ctx_value_(+Pair, -Value): extract value from K-V pair.
ctx_value_(_-V, V).

% ctx_from_pairs(+Pairs, -Map).
% Build a context map from a list of Key-Value pairs.
% Later pairs with the same key override earlier ones.
ctx_from_pairs(Pairs, Map) :-
    % Fold right so last binding wins for duplicate keys.
    ctx_from_pairs_(Pairs, [], Map).

% ctx_from_pairs_(+Pairs, +Acc, -Map): accumulate pairs, last wins.
ctx_from_pairs_([], Map, Map).
ctx_from_pairs_([K-V|Rest], Acc, Map) :-
    % Insert this pair (ctx_put handles dedup).
    ctx_put(Acc, K, V, Acc2),
    % Continue with remaining pairs.
    ctx_from_pairs_(Rest, Acc2, Map).

% ctx_to_pairs(+Map, -Pairs).
% Convert a context map to a list of Key-Value pairs.
ctx_to_pairs(Map, Map).

% ctx_merge(+Map1, +Map2, -Merged).
% Merge two context maps. Bindings in Map2 override bindings in Map1.
ctx_merge(Map1, Map2, Merged) :-
    % Start from Map1 and apply all Map2 bindings on top.
    ctx_merge_(Map2, Map1, Merged).

% ctx_merge_(+Additions, +Base, -Result): fold Map2 entries into Base.
ctx_merge_([], Base, Base).
ctx_merge_([K-V|Rest], Base, Result) :-
    % Apply this override.
    ctx_put(Base, K, V, Base2),
    % Continue with the rest.
    ctx_merge_(Rest, Base2, Result).

% ctx_dispatch(+Map, +Key, +DefaultGoal, +Args).
% Look up Key in Map; if found, call the associated goal with Args.
% If Key is not found, call DefaultGoal with Args.
% The goal is called as call(Goal, Args).
ctx_dispatch(Map, Key, DefaultGoal, Args) :-
    % Attempt key lookup.
    ( ctx_get(Map, Key, Goal) ->
        call(Goal, Args)
    ;   call(DefaultGoal, Args)
    ).

% ctx_select(+Map, +Keys, +Default, -Value).
% Find the value for the first key in Keys that exists in Map.
% If none of the keys exist, Value = Default.
ctx_select(_, [], Default, Default) :- !.
ctx_select(Map, [K|Rest], Default, Value) :-
    % Check if this key exists.
    ( ctx_get(Map, K, V) ->
        Value = V
    ;   ctx_select(Map, Rest, Default, Value)
    ).

% ctx_map_values(+Map, +Goal, -Map2).
% Transform all values in Map via Goal(OldValue, NewValue).
% Keys are unchanged.
:- meta_predicate ctx_map_values(+, 2, -).
ctx_map_values(Map, Goal, Map2) :-
    % Apply Goal to each value.
    maplist(ctx_map_entry_(Goal), Map, Map2).

% ctx_map_entry_(+Goal, +KV, -KV2): transform the value in one K-V pair.
ctx_map_entry_(Goal, K-V, K-V2) :-
    % Call Goal with old and new value.
    call(Goal, V, V2).

% ctx_filter_keys(+Map, +Goal, -Map2).
% Keep only entries whose key satisfies Goal(Key).
:- meta_predicate ctx_filter_keys(+, 1, -).
ctx_filter_keys(Map, Goal, Map2) :-
    % Include only entries where Goal(Key) succeeds.
    findall(K-V, (member(K-V, Map), call(Goal, K)), Map2).

% ctx_size(+Map, -N).
% N is the number of entries in the context map.
ctx_size(Map, N) :-
    % Count via length built-in.
    length(Map, N).
