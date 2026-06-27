% Module declaration with all fourteen public predicates.
:- module(invariant, [
% Find grid-level properties constant across all input grids in training pairs.
    iv_grid_invariants/2,
% Find grid-level properties constant across all output grids in training pairs.
    iv_output_invariants/2,
% Find object-level properties (color sets, size sets) constant across inputs.
    iv_object_invariants/2,
% Find properties that CHANGE across training pairs (candidate rule parameters).
    iv_variant_features/2,
% Find the consistent delta: input→output change shared by every pair.
    iv_consistent_delta/2,
% Succeed if a specific property atom holds in every grid in a list.
    iv_all_grids/2,
% Succeed if a specific property atom holds in no grid in the list.
    iv_no_grids/2,
% Extract the set of colors present in a grid (excluding background).
    iv_color_set/3,
% Succeed if all grids in a list have the same color set.
    iv_same_color_sets/2,
% Succeed if all grids in a list have the same dimensions.
    iv_same_dims/1,
% Succeed if input and output in each pair have the same dimensions.
    iv_preserves_dims/1,
% Succeed if input and output in each pair have the same color set.
    iv_preserves_colors/1,
% Succeed if input and output in each pair have the same object count (given BgColor).
    iv_preserves_count/2,
% Find which input colors always map to the same output color across all pairs.
    iv_stable_color_map/2
]).
% invariant.pl - Layer 248: Cross-Pair Invariant Extraction (iv_* prefix).
% Fourteen predicates for finding what stays constant across all training pairs.
% Pairs are pair(InputGrid, OutputGrid) terms.
% Invariants reduce the hypothesis search space by eliminating entire rule classes.
:- use_module(library(lists), [member/2, subtract/3]).
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).
:- meta_predicate iv_all_grids(+, 1).
:- meta_predicate iv_no_grids(+, 1).

% --- PRIVATE HELPERS ---

% iv_grid_dims_/3: extract Rows and Cols from a grid.
iv_grid_dims_(Grid, Rows, Cols) :-
    length(Grid, Rows),
    (Grid = [Row|_] -> length(Row, Cols) ; Cols = 0).

% iv_grid_colors_/3: all colors in Grid excluding BgColor.
iv_grid_colors_(Grid, BgColor, Colors) :-
    findall(V,
        (member(Row, Grid), member(V, Row), V \= BgColor),
        All),
    sort(All, Colors).

% iv_pair_input_/2: extract input grid from a pair/2 term.
iv_pair_input_(pair(In, _), In).

% iv_pair_output_/2: extract output grid from a pair/2 term.
iv_pair_output_(pair(_, Out), Out).

% iv_same_/2: succeed if all elements of a list are the same term.
iv_same_([]).
iv_same_([_]).
iv_same_([H|T]) :-
    maplist(=(H), T).

% iv_intersection_/3: intersection of two sorted lists.
iv_intersection_([], _, []).
iv_intersection_([H|T], List2, [H|Rest]) :-
    member(H, List2), !,
    iv_intersection_(T, List2, Rest).
iv_intersection_([_|T], List2, Rest) :-
    iv_intersection_(T, List2, Rest).

% iv_count_objects_/3: count connected non-BgColor objects in a grid.
% Simple approach: count distinct non-bg colors (not full connected components).
iv_count_objects_(Grid, BgColor, N) :-
    findall(V,
        (member(Row, Grid), member(V, Row), V \= BgColor),
        All),
    sort(All, Colors),
    length(Colors, N).

% iv_extract_color_map_/3: extract color mapping for a single pair.
% Returns a list of cm(InColor, OutColor) by comparing all cell positions.
iv_extract_color_map_(InGrid, OutGrid, Map) :-
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

% iv_grid_invariants(+Pairs, -Invariants)
% Invariants is a list of inv(Property) atoms describing grid-level properties
% that are the same in every INPUT grid across all training pairs.
% Properties checked: dims(Rows,Cols), bg_color(C), color_count(N).
iv_grid_invariants([], []).
iv_grid_invariants(Pairs, Invariants) :-
    maplist(iv_pair_input_, Pairs, Inputs),
    findall(inv(dims(R,C)),
        (Inputs = [First|_],
         iv_grid_dims_(First, R, C),
         maplist(iv_has_dims_(R,C), Inputs)),
        DimInvs),
    sort(DimInvs, Invariants).

% iv_has_dims_/3: partial application helper for maplist.
iv_has_dims_(R, C, Grid) :-
    iv_grid_dims_(Grid, R, C).

% iv_output_invariants(+Pairs, -Invariants)
% Same as iv_grid_invariants but over OUTPUT grids.
iv_output_invariants([], []).
iv_output_invariants(Pairs, Invariants) :-
    maplist(iv_pair_output_, Pairs, Outputs),
    findall(inv(dims(R,C)),
        (Outputs = [First|_],
         iv_grid_dims_(First, R, C),
         maplist(iv_has_dims_(R,C), Outputs)),
        DimInvs),
    sort(DimInvs, Invariants).

% iv_object_invariants(+Pairs, -Invariants)
% Invariants is a list of inv(Property) atoms describing object-level properties
% constant across all input grids. Checks color_set stability.
iv_object_invariants([], []).
iv_object_invariants(Pairs, Invariants) :-
    maplist(iv_pair_input_, Pairs, Inputs),
    (Inputs = [First|_] ->
        % Check if all inputs have the same color set (bg = 0).
        iv_grid_colors_(First, 0, FirstColors),
        (maplist(iv_has_color_set_(FirstColors), Inputs) ->
            ColorInv = [inv(stable_color_set(FirstColors))]
        ;
            ColorInv = []
        )
    ;
        ColorInv = []
    ),
    sort(ColorInv, Invariants).

% iv_has_color_set_/2: helper for maplist.
iv_has_color_set_(Colors, Grid) :-
    iv_grid_colors_(Grid, 0, Colors).

% iv_variant_features(+Pairs, -Features)
% Features is a list of feature atoms that CHANGE across input grids.
% Specifically: features that are NOT invariant.
iv_variant_features([], []).
iv_variant_features(Pairs, Features) :-
    maplist(iv_pair_input_, Pairs, Inputs),
    % Check which dims vary.
    (Inputs = [First|_] ->
        iv_grid_dims_(First, R0, C0),
        (maplist(iv_has_dims_(R0,C0), Inputs) -> DimsVary = [] ; DimsVary = [feature(dims)])
    ;
        DimsVary = []
    ),
    % Check if color set varies.
    (Inputs = [First2|_] ->
        iv_grid_colors_(First2, 0, FirstColors),
        (maplist(iv_has_color_set_(FirstColors), Inputs) ->
            ColorsVary = []
        ;
            ColorsVary = [feature(color_set)]
        )
    ;
        ColorsVary = []
    ),
    append(DimsVary, ColorsVary, Features).

% iv_consistent_delta(+Pairs, -Delta)
% Delta is a list of inv(Property) atoms for input-to-output changes
% that are consistent (the same) across all training pairs.
% Checks: dims_preserved, color_set_preserved.
iv_consistent_delta([], []).
iv_consistent_delta(Pairs, Delta) :-
    (maplist(iv_pair_preserves_dims_, Pairs) ->
        DimsD = [inv(dims_preserved)]
    ;
        DimsD = []
    ),
    (maplist(iv_pair_preserves_color_set_, Pairs) ->
        ColorsD = [inv(color_set_preserved)]
    ;
        ColorsD = []
    ),
    append(DimsD, ColorsD, Delta).

% iv_pair_preserves_dims_/1: succeed if in and out grids have same dims.
iv_pair_preserves_dims_(pair(In, Out)) :-
    iv_grid_dims_(In, R, C),
    iv_grid_dims_(Out, R, C).

% iv_pair_preserves_color_set_/1: succeed if in and out grids have same color set.
iv_pair_preserves_color_set_(pair(In, Out)) :-
    iv_grid_colors_(In, 0, Cs),
    iv_grid_colors_(Out, 0, Cs).

% iv_all_grids(+Grids, +Goal)
% Succeed if Goal succeeds for every grid in Grids.
% Goal is a unary predicate called as call(Goal, Grid).
iv_all_grids(Grids, Goal) :-
    maplist(Goal, Grids).

% iv_no_grids(+Grids, +Goal)
% Succeed if Goal fails for every grid in Grids.
iv_no_grids([], _).
iv_no_grids([G|Rest], Goal) :-
    \+ call(Goal, G),
    iv_no_grids(Rest, Goal).

% iv_color_set(+Grid, +BgColor, -Colors)
% Colors is the sorted set of non-BgColor values present in Grid.
iv_color_set(Grid, BgColor, Colors) :-
    iv_grid_colors_(Grid, BgColor, Colors).

% iv_same_color_sets(+Grids, +BgColor)
% Succeed if all Grids have the same set of non-BgColor values.
iv_same_color_sets([], _).
iv_same_color_sets([G|Rest], BgColor) :-
    iv_grid_colors_(G, BgColor, Colors),
    maplist(iv_has_color_set_(Colors), Rest).

% iv_same_dims(+Grids)
% Succeed if all Grids have the same row and column counts.
iv_same_dims([]).
iv_same_dims([G|Rest]) :-
    iv_grid_dims_(G, R, C),
    maplist(iv_has_dims_(R, C), Rest).

% iv_preserves_dims(+Pairs)
% Succeed if every pair has input and output with the same dimensions.
iv_preserves_dims(Pairs) :-
    maplist(iv_pair_preserves_dims_, Pairs).

% iv_preserves_colors(+Pairs)
% Succeed if every pair has input and output with the same color set (bg = 0).
iv_preserves_colors(Pairs) :-
    maplist(iv_pair_preserves_color_set_, Pairs).

% iv_preserves_count(+Pairs, +BgColor)
% Succeed if every pair has the same distinct-color count in input and output.
iv_preserves_count([], _).
iv_preserves_count([pair(In, Out)|Rest], BgColor) :-
    iv_count_objects_(In, BgColor, N),
    iv_count_objects_(Out, BgColor, N),
    iv_preserves_count(Rest, BgColor).

% iv_stable_color_map(+Pairs, -Map)
% Map is a sorted list of cm(InColor, OutColor) for cell mappings that are
% consistent across every training pair. A mapping is consistent if InColor
% always maps to the same OutColor in every pair.
iv_stable_color_map([], []).
iv_stable_color_map([pair(In, Out)|Rest], Map) :-
    iv_extract_color_map_(In, Out, FirstMap),
    (Rest = [] ->
        Map = FirstMap
    ;
        iv_stable_color_map(Rest, RestMap),
        iv_intersection_(FirstMap, RestMap, Map)
    ).
