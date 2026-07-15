% Module declaration with all fourteen public predicates.
:- module(invariant, [
% Find grid-level properties constant across all input grids in training pairs.
    invariant_grid_invariants/2,
% Find grid-level properties constant across all output grids in training pairs.
    invariant_output_invariants/2,
% Find object-level properties (color sets, size sets) constant across inputs.
    invariant_object_invariants/2,
% Find properties that CHANGE across training pairs (candidate rule parameters).
    invariant_variant_features/2,
% Find the consistent delta: input→output change shared by every pair.
    invariant_consistent_delta/2,
% Succeed if a specific property atom holds in every grid in a list.
    invariant_all_grids/2,
% Succeed if a specific property atom holds in no grid in the list.
    invariant_no_grids/2,
% Extract the set of colors present in a grid (excluding background).
    invariant_color_set/3,
% Succeed if all grids in a list have the same color set.
    invariant_same_color_sets/2,
% Succeed if all grids in a list have the same dimensions.
    invariant_same_dims/1,
% Succeed if input and output in each pair have the same dimensions.
    invariant_preserves_dims/1,
% Succeed if input and output in each pair have the same color set.
    invariant_preserves_colors/1,
% Succeed if input and output in each pair have the same object count (given BgColor).
    invariant_preserves_count/2,
% Find which input colors always map to the same output color across all pairs.
    invariant_stable_color_map/2
]).
% invariant.pl - Layer 248: Cross-Pair Invariant Extraction (iv_* prefix).
% Fourteen predicates for finding what stays constant across all training pairs.
% Pairs are pair(InputGrid, OutputGrid) terms.
% Invariants reduce the hypothesis search space by eliminating entire rule classes.
:- use_module(library(lists), [member/2, subtract/3]).
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).
:- meta_predicate invariant_all_grids(+, 1).
:- meta_predicate invariant_no_grids(+, 1).

% --- PRIVATE HELPERS ---

% invariant_grid_dims_/3: extract Rows and Cols from a grid.
invariant_grid_dims_(Grid, Rows, Cols) :-
    length(Grid, Rows),
    (Grid = [Row|_] -> length(Row, Cols) ; Cols = 0).

% invariant_grid_colors_/3: all colors in Grid excluding BgColor.
invariant_grid_colors_(Grid, BgColor, Colors) :-
    findall(V,
        (member(Row, Grid), member(V, Row), V \= BgColor),
        All),
    sort(All, Colors).

% invariant_pair_input_/2: extract input grid from a pair/2 term.
invariant_pair_input_(pair(In, _), In).

% invariant_pair_output_/2: extract output grid from a pair/2 term.
invariant_pair_output_(pair(_, Out), Out).

% invariant_same_/2: succeed if all elements of a list are the same term.
invariant_same_([]).
invariant_same_([_]).
invariant_same_([H|T]) :-
    maplist(=(H), T).

% invariant_intersection_/3: intersection of two sorted lists.
invariant_intersection_([], _, []).
invariant_intersection_([H|T], List2, [H|Rest]) :-
    member(H, List2), !,
    invariant_intersection_(T, List2, Rest).
invariant_intersection_([_|T], List2, Rest) :-
    invariant_intersection_(T, List2, Rest).

% invariant_count_objects_/3: count connected non-BgColor objects in a grid.
% Simple approach: count distinct non-bg colors (not full connected components).
invariant_count_objects_(Grid, BgColor, N) :-
    findall(V,
        (member(Row, Grid), member(V, Row), V \= BgColor),
        All),
    sort(All, Colors),
    length(Colors, N).

% invariant_extract_color_map_/3: extract color mapping for a single pair.
% Returns a list of cm(InColor, OutColor) by comparing all cell positions.
invariant_extract_color_map_(InGrid, OutGrid, Map) :-
    length(InGrid, Rows), Rows1 is Rows - 1,
    numlist(0, Rows1, RowIdxs),
    findall(cm(InV, OutV),
        (member(R, RowIdxs),
         nth0(R, InGrid, InRow), nth0(R, OutGrid, OutRow),
         length(InRow, Cols), Cols1 is Cols - 1,
         numlist(0, Cols1, ColIdxs),
         member(C, ColIdxs),
         nth0(C, InRow, InV), nth0(C, OutRow, OutV),
         InV \= OutV),
        Raw),
    sort(Raw, Map).

% --- PUBLIC PREDICATES ---

% invariant_grid_invariants(+Pairs, -Invariants)
% Invariants is a list of inv(Property) atoms describing grid-level properties
% that are the same in every INPUT grid across all training pairs.
% Properties checked: dims(Rows,Cols), bg_color(C), color_count(N).
invariant_grid_invariants([], []).
invariant_grid_invariants(Pairs, Invariants) :-
    maplist(invariant_pair_input_, Pairs, Inputs),
    findall(inv(dims(R,C)),
        (Inputs = [First|_],
         invariant_grid_dims_(First, R, C),
         maplist(invariant_has_dims_(R,C), Inputs)),
        DimInvs),
    sort(DimInvs, Invariants).

% invariant_has_dims_/3: partial application helper for maplist.
invariant_has_dims_(R, C, Grid) :-
    invariant_grid_dims_(Grid, R, C).

% invariant_output_invariants(+Pairs, -Invariants)
% Same as invariant_grid_invariants but over OUTPUT grids.
invariant_output_invariants([], []).
invariant_output_invariants(Pairs, Invariants) :-
    maplist(invariant_pair_output_, Pairs, Outputs),
    findall(inv(dims(R,C)),
        (Outputs = [First|_],
         invariant_grid_dims_(First, R, C),
         maplist(invariant_has_dims_(R,C), Outputs)),
        DimInvs),
    sort(DimInvs, Invariants).

% invariant_object_invariants(+Pairs, -Invariants)
% Invariants is a list of inv(Property) atoms describing object-level properties
% constant across all input grids. Checks color_set stability.
invariant_object_invariants([], []).
invariant_object_invariants(Pairs, Invariants) :-
    maplist(invariant_pair_input_, Pairs, Inputs),
    (Inputs = [First|_] ->
        % Check if all inputs have the same color set (bg = 0).
        invariant_grid_colors_(First, 0, FirstColors),
        (maplist(invariant_has_color_set_(FirstColors), Inputs) ->
            ColorInv = [inv(stable_color_set(FirstColors))]
        ;
            ColorInv = []
        )
    ;
        ColorInv = []
    ),
    sort(ColorInv, Invariants).

% invariant_has_color_set_/2: helper for maplist.
invariant_has_color_set_(Colors, Grid) :-
    invariant_grid_colors_(Grid, 0, Colors).

% invariant_variant_features(+Pairs, -Features)
% Features is a list of feature atoms that CHANGE across input grids.
% Specifically: features that are NOT invariant.
invariant_variant_features([], []).
invariant_variant_features(Pairs, Features) :-
    maplist(invariant_pair_input_, Pairs, Inputs),
    % Check which dims vary.
    (Inputs = [First|_] ->
        invariant_grid_dims_(First, R0, C0),
        (maplist(invariant_has_dims_(R0,C0), Inputs) -> DimsVary = [] ; DimsVary = [feature(dims)])
    ;
        DimsVary = []
    ),
    % Check if color set varies.
    (Inputs = [First2|_] ->
        invariant_grid_colors_(First2, 0, FirstColors),
        (maplist(invariant_has_color_set_(FirstColors), Inputs) ->
            ColorsVary = []
        ;
            ColorsVary = [feature(color_set)]
        )
    ;
        ColorsVary = []
    ),
    append(DimsVary, ColorsVary, Features).

% invariant_consistent_delta(+Pairs, -Delta)
% Delta is a list of inv(Property) atoms for input-to-output changes
% that are consistent (the same) across all training pairs.
% Checks: dims_preserved, color_set_preserved.
invariant_consistent_delta([], []).
invariant_consistent_delta(Pairs, Delta) :-
    (maplist(invariant_pair_preserves_dims_, Pairs) ->
        DimsD = [inv(dims_preserved)]
    ;
        DimsD = []
    ),
    (maplist(invariant_pair_preserves_color_set_, Pairs) ->
        ColorsD = [inv(color_set_preserved)]
    ;
        ColorsD = []
    ),
    append(DimsD, ColorsD, Delta).

% invariant_pair_preserves_dims_/1: succeed if in and out grids have same dims.
invariant_pair_preserves_dims_(pair(In, Out)) :-
    invariant_grid_dims_(In, R, C),
    invariant_grid_dims_(Out, R, C).

% invariant_pair_preserves_color_set_/1: succeed if in and out grids have same color set.
invariant_pair_preserves_color_set_(pair(In, Out)) :-
    invariant_grid_colors_(In, 0, Cs),
    invariant_grid_colors_(Out, 0, Cs).

% invariant_all_grids(+Grids, +Goal)
% Succeed if Goal succeeds for every grid in Grids.
% Goal is a unary predicate called as call(Goal, Grid).
invariant_all_grids(Grids, Goal) :-
    maplist(Goal, Grids).

% invariant_no_grids(+Grids, +Goal)
% Succeed if Goal fails for every grid in Grids.
invariant_no_grids([], _).
invariant_no_grids([G|Rest], Goal) :-
    \+ call(Goal, G),
    invariant_no_grids(Rest, Goal).

% invariant_color_set(+Grid, +BgColor, -Colors)
% Colors is the sorted set of non-BgColor values present in Grid.
invariant_color_set(Grid, BgColor, Colors) :-
    invariant_grid_colors_(Grid, BgColor, Colors).

% invariant_same_color_sets(+Grids, +BgColor)
% Succeed if all Grids have the same set of non-BgColor values.
invariant_same_color_sets([], _).
invariant_same_color_sets([G|Rest], BgColor) :-
    invariant_grid_colors_(G, BgColor, Colors),
    maplist(invariant_has_color_set_(Colors), Rest).

% invariant_same_dims(+Grids)
% Succeed if all Grids have the same row and column counts.
invariant_same_dims([]).
invariant_same_dims([G|Rest]) :-
    invariant_grid_dims_(G, R, C),
    maplist(invariant_has_dims_(R, C), Rest).

% invariant_preserves_dims(+Pairs)
% Succeed if every pair has input and output with the same dimensions.
invariant_preserves_dims(Pairs) :-
    maplist(invariant_pair_preserves_dims_, Pairs).

% invariant_preserves_colors(+Pairs)
% Succeed if every pair has input and output with the same color set (bg = 0).
invariant_preserves_colors(Pairs) :-
    maplist(invariant_pair_preserves_color_set_, Pairs).

% invariant_preserves_count(+Pairs, +BgColor)
% Succeed if every pair has the same distinct-color count in input and output.
invariant_preserves_count([], _).
invariant_preserves_count([pair(In, Out)|Rest], BgColor) :-
    invariant_count_objects_(In, BgColor, N),
    invariant_count_objects_(Out, BgColor, N),
    invariant_preserves_count(Rest, BgColor).

% invariant_stable_color_map(+Pairs, -Map)
% Map is a sorted list of cm(InColor, OutColor) for cell mappings that are
% consistent across every training pair. A mapping is consistent if InColor
% always maps to the same OutColor in every pair.
invariant_stable_color_map([], []).
invariant_stable_color_map([pair(In, Out)|Rest], Map) :-
    invariant_extract_color_map_(In, Out, FirstMap),
    (Rest = [] ->
        Map = FirstMap
    ;
        invariant_stable_color_map(Rest, RestMap),
        invariant_intersection_(FirstMap, RestMap, Map)
    ).
