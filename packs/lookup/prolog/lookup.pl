% Module declaration: lookup pack, Layer 63.
:- module(lookup, [
    % lookup_get/3: look up a key in a Key-Value association list.
    lookup_get/3,
    % lookup_put/4: add or replace a key-value pair in an association list.
    lookup_put/4,
    % lookup_keys/2: extract all keys from an association list.
    lookup_keys/2,
    % lookup_values/2: extract all values from an association list.
    lookup_values/2,
    % lookup_has_key/2: true if a key exists in an association list.
    lookup_has_key/2,
    % lookup_delete/3: remove a key-value pair from an association list.
    lookup_delete/3,
    % lookup_map_values/3: apply a predicate to all values, keeping keys.
    lookup_map_values/3,
    % lookup_from_pairs/2: build an association list from a list of Key-Value pairs.
    lookup_from_pairs/2,
    % lookup_grid_row/3: look up a row index in a grid and return that row.
    lookup_grid_row/3,
    % lookup_grid_col/3: look up a column index in a grid and return that column.
    lookup_grid_col/3,
    % lookup_grid_cell/4: look up a grid cell value by row and column index.
    lookup_grid_cell/4,
    % lookup_color_positions/3: build a map from each color to the list of its r(R,C) positions.
    lookup_color_positions/3,
    % lookup_position_color/3: build a map from each r(R,C) position to its color.
    lookup_position_color/3,
    % lookup_invert/2: invert an association list (swap keys and values).
    lookup_invert/2
]).

% Import list and apply utilities.
:- use_module(library(lists),  [member/2, nth0/3, numlist/3, subtract/3]).
:- use_module(library(apply),  [maplist/2, maplist/3, include/3]).

% Meta-predicate declaration: Pred argument of lookup_map_values is a 2-arity callable.
:- meta_predicate lookup_map_values(+, 2, -).
% Meta-predicate declaration: Pred argument of lookup_apply_val_ is a 2-arity callable.
:- meta_predicate lookup_apply_val_(2, +, -).

% lookup_get(+Key, +Map, -Value): look up Key in a Key-Value association list.
% Map is a list of Key-Value pairs.
lookup_get(Key, [Key-Value|_], Value) :- !.
lookup_get(Key, [_|Rest], Value) :-
    lookup_get(Key, Rest, Value).

% lookup_has_key(+Key, +Map): true if Key is present in Map.
lookup_has_key(Key, Map) :-
    member(Key-_, Map), !.

% lookup_put(+Key, +Value, +MapIn, -MapOut): add or replace Key->Value in Map.
lookup_put(Key, Value, [], [Key-Value]).
lookup_put(Key, Value, [Key-_|Rest], [Key-Value|Rest]) :- !.
lookup_put(Key, Value, [Other|Rest], [Other|Rest2]) :-
    lookup_put(Key, Value, Rest, Rest2).

% lookup_delete(+Key, +MapIn, -MapOut): remove Key from Map (no-op if absent).
lookup_delete(_, [], []).
lookup_delete(Key, [Key-_|Rest], Rest) :- !.
lookup_delete(Key, [Other|Rest], [Other|Rest2]) :-
    lookup_delete(Key, Rest, Rest2).

% lookup_keys(+Map, -Keys): list of all keys in Map.
lookup_keys(Map, Keys) :-
    maplist(lookup_key_of_, Map, Keys).

% lookup_key_of_(+Pair, -Key): extract key from K-V pair.
lookup_key_of_(Key-_, Key).

% lookup_values(+Map, -Values): list of all values in Map.
lookup_values(Map, Values) :-
    maplist(lookup_val_of_, Map, Values).

% lookup_val_of_(+Pair, -Value): extract value from K-V pair.
lookup_val_of_(_-Value, Value).

% lookup_map_values(+Map, :Pred, -NewMap): apply Pred(+V, -NewV) to each value.
lookup_map_values(Map, Pred, NewMap) :-
    maplist(lookup_apply_val_(Pred), Map, NewMap).

% lookup_apply_val_(+Pred, +K-V, -K-NV): apply Pred to value.
lookup_apply_val_(Pred, K-V, K-NV) :-
    call(Pred, V, NV).

% lookup_from_pairs(+Pairs, -Map): identity - Pairs is already in Key-Value format.
lookup_from_pairs(Pairs, Map) :-
    Map = Pairs.

% lookup_grid_row(+Grid, +R, -Row): return row R of Grid.
lookup_grid_row(Grid, R, Row) :-
    nth0(R, Grid, Row).

% lookup_grid_col(+Grid, +C, -Col): return column C of Grid as a list.
lookup_grid_col(Grid, C, Col) :-
    maplist(lookup_nth0_(C), Grid, Col).

% lookup_nth0_(+I, +List, -Elem): nth0 with args reordered for maplist.
lookup_nth0_(I, List, Elem) :-
    nth0(I, List, Elem).

% lookup_grid_cell(+Grid, +R, +C, -Value): value at (R,C) in Grid.
lookup_grid_cell(Grid, R, C, Value) :-
    nth0(R, Grid, Row), nth0(C, Row, Value).

% lookup_grid_dims_(+Grid, -Rows, -Cols): dimensions of a grid.
lookup_grid_dims_(Grid, Rows, Cols) :-
    length(Grid, Rows),
    ( Rows > 0 -> Grid = [R0|_], length(R0, Cols) ; Cols = 0 ).

% lookup_color_positions(+Grid, +BG, -Map): Map from Color to [r(R,C)...] positions.
% BG cells are excluded from the map.
lookup_color_positions(Grid, BG, Map) :-
    % Flatten grid to (Color, r(R,C)) pairs.
    lookup_grid_dims_(Grid, Rows, Cols),
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    findall(Color-r(R,C),
        (member(R, RowIds), member(C, ColIds),
         nth0(R, Grid, Row), nth0(C, Row, Color),
         Color =\= BG),
        Pairs),
    % Group by color.
    lookup_group_by_key_(Pairs, Map).

% lookup_group_by_key_(+Pairs, -Map): group K-V pairs by key into K-[V...] lists.
lookup_group_by_key_(Pairs, Map) :-
    % Get unique keys.
    lookup_keys(Pairs, AllKeys),
    sort(AllKeys, UniqueKeys),
    % For each unique key, collect all values.
    findall(K-Vs,
        (member(K, UniqueKeys),
         findall(V, member(K-V, Pairs), Vs)),
        Map).

% lookup_position_color(+Grid, +BG, -Map): Map from r(R,C) to Color (non-BG cells).
lookup_position_color(Grid, BG, Map) :-
    lookup_grid_dims_(Grid, Rows, Cols),
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    findall(r(R,C)-Color,
        (member(R, RowIds), member(C, ColIds),
         nth0(R, Grid, Row), nth0(C, Row, Color),
         Color =\= BG),
        Map).

% lookup_invert(+Map, -Inverted): swap keys and values in an association list.
lookup_invert(Map, Inverted) :-
    maplist(lookup_swap_pair_, Map, Inverted).

% lookup_swap_pair_(+K-V, -V-K): swap a pair.
lookup_swap_pair_(K-V, V-K).
