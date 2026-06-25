% Module declaration: lookup pack, Layer 63.
:- module(lookup, [
    % lk_get/3: look up a key in a Key-Value association list.
    lk_get/3,
    % lk_put/4: add or replace a key-value pair in an association list.
    lk_put/4,
    % lk_keys/2: extract all keys from an association list.
    lk_keys/2,
    % lk_values/2: extract all values from an association list.
    lk_values/2,
    % lk_has_key/2: true if a key exists in an association list.
    lk_has_key/2,
    % lk_delete/3: remove a key-value pair from an association list.
    lk_delete/3,
    % lk_map_values/3: apply a predicate to all values, keeping keys.
    lk_map_values/3,
    % lk_from_pairs/2: build an association list from a list of Key-Value pairs.
    lk_from_pairs/2,
    % lk_grid_row/3: look up a row index in a grid and return that row.
    lk_grid_row/3,
    % lk_grid_col/3: look up a column index in a grid and return that column.
    lk_grid_col/3,
    % lk_grid_cell/4: look up a grid cell value by row and column index.
    lk_grid_cell/4,
    % lk_color_positions/3: build a map from each color to the list of its r(R,C) positions.
    lk_color_positions/3,
    % lk_position_color/3: build a map from each r(R,C) position to its color.
    lk_position_color/3,
    % lk_invert/2: invert an association list (swap keys and values).
    lk_invert/2
]).

% Import list and apply utilities.
:- use_module(library(lists),  [member/2, nth0/3, numlist/3, subtract/3]).
:- use_module(library(apply),  [maplist/2, maplist/3, include/3]).

% Meta-predicate declaration: Pred argument of lk_map_values is a 2-arity callable.
:- meta_predicate lk_map_values(+, 2, -).
% Meta-predicate declaration: Pred argument of lk_apply_val_ is a 2-arity callable.
:- meta_predicate lk_apply_val_(2, +, -).

% lk_get(+Key, +Map, -Value): look up Key in a Key-Value association list.
% Map is a list of Key-Value pairs.
lk_get(Key, [Key-Value|_], Value) :- !.
lk_get(Key, [_|Rest], Value) :-
    lk_get(Key, Rest, Value).

% lk_has_key(+Key, +Map): true if Key is present in Map.
lk_has_key(Key, Map) :-
    member(Key-_, Map), !.

% lk_put(+Key, +Value, +MapIn, -MapOut): add or replace Key->Value in Map.
lk_put(Key, Value, [], [Key-Value]).
lk_put(Key, Value, [Key-_|Rest], [Key-Value|Rest]) :- !.
lk_put(Key, Value, [Other|Rest], [Other|Rest2]) :-
    lk_put(Key, Value, Rest, Rest2).

% lk_delete(+Key, +MapIn, -MapOut): remove Key from Map (no-op if absent).
lk_delete(_, [], []).
lk_delete(Key, [Key-_|Rest], Rest) :- !.
lk_delete(Key, [Other|Rest], [Other|Rest2]) :-
    lk_delete(Key, Rest, Rest2).

% lk_keys(+Map, -Keys): list of all keys in Map.
lk_keys(Map, Keys) :-
    maplist(lk_key_of_, Map, Keys).

% lk_key_of_(+Pair, -Key): extract key from K-V pair.
lk_key_of_(Key-_, Key).

% lk_values(+Map, -Values): list of all values in Map.
lk_values(Map, Values) :-
    maplist(lk_val_of_, Map, Values).

% lk_val_of_(+Pair, -Value): extract value from K-V pair.
lk_val_of_(_-Value, Value).

% lk_map_values(+Map, :Pred, -NewMap): apply Pred(+V, -NewV) to each value.
lk_map_values(Map, Pred, NewMap) :-
    maplist(lk_apply_val_(Pred), Map, NewMap).

% lk_apply_val_(+Pred, +K-V, -K-NV): apply Pred to value.
lk_apply_val_(Pred, K-V, K-NV) :-
    call(Pred, V, NV).

% lk_from_pairs(+Pairs, -Map): identity - Pairs is already in Key-Value format.
lk_from_pairs(Pairs, Map) :-
    Map = Pairs.

% lk_grid_row(+Grid, +R, -Row): return row R of Grid.
lk_grid_row(Grid, R, Row) :-
    nth0(R, Grid, Row).

% lk_grid_col(+Grid, +C, -Col): return column C of Grid as a list.
lk_grid_col(Grid, C, Col) :-
    maplist(lk_nth0_(C), Grid, Col).

% lk_nth0_(+I, +List, -Elem): nth0 with args reordered for maplist.
lk_nth0_(I, List, Elem) :-
    nth0(I, List, Elem).

% lk_grid_cell(+Grid, +R, +C, -Value): value at (R,C) in Grid.
lk_grid_cell(Grid, R, C, Value) :-
    nth0(R, Grid, Row), nth0(C, Row, Value).

% lk_grid_dims_(+Grid, -Rows, -Cols): dimensions of a grid.
lk_grid_dims_(Grid, Rows, Cols) :-
    length(Grid, Rows),
    ( Rows > 0 -> Grid = [R0|_], length(R0, Cols) ; Cols = 0 ).

% lk_color_positions(+Grid, +BG, -Map): Map from Color to [r(R,C)...] positions.
% BG cells are excluded from the map.
lk_color_positions(Grid, BG, Map) :-
    % Flatten grid to (Color, r(R,C)) pairs.
    lk_grid_dims_(Grid, Rows, Cols),
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    findall(Color-r(R,C),
        (member(R, RowIds), member(C, ColIds),
         nth0(R, Grid, Row), nth0(C, Row, Color),
         Color =\= BG),
        Pairs),
    % Group by color.
    lk_group_by_key_(Pairs, Map).

% lk_group_by_key_(+Pairs, -Map): group K-V pairs by key into K-[V...] lists.
lk_group_by_key_(Pairs, Map) :-
    % Get unique keys.
    lk_keys(Pairs, AllKeys),
    sort(AllKeys, UniqueKeys),
    % For each unique key, collect all values.
    findall(K-Vs,
        (member(K, UniqueKeys),
         findall(V, member(K-V, Pairs), Vs)),
        Map).

% lk_position_color(+Grid, +BG, -Map): Map from r(R,C) to Color (non-BG cells).
lk_position_color(Grid, BG, Map) :-
    lk_grid_dims_(Grid, Rows, Cols),
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    findall(r(R,C)-Color,
        (member(R, RowIds), member(C, ColIds),
         nth0(R, Grid, Row), nth0(C, Row, Color),
         Color =\= BG),
        Map).

% lk_invert(+Map, -Inverted): swap keys and values in an association list.
lk_invert(Map, Inverted) :-
    maplist(lk_swap_pair_, Map, Inverted).

% lk_swap_pair_(+K-V, -V-K): swap a pair.
lk_swap_pair_(K-V, V-K).
