% Module declaration: induct pack, Layer 73.
:- module(induct, [
    % induct_delta/3: compute the color-delta between two grids (changed cells).
    induct_delta/3,
    % induct_constant/2: succeed if the output grid is the same as the input (identity rule).
    induct_constant/2,
    % induct_color_map/3: infer a color substitution map from input-output pair.
    induct_color_map/3,
    % induct_color_map_pairs/2: infer a color map consistent across all training pairs.
    induct_color_map_pairs/2,
    % induct_size_change/4: infer how grid dimensions change (DRows, DCols) from a pair.
    induct_size_change/4,
    % induct_size_change_pairs/3: infer consistent DRows, DCols across all pairs.
    induct_size_change_pairs/3,
    % induct_color_palette/3: extract unique colors from Input and Output.
    induct_color_palette/3,
    % induct_palette_pairs/3: union of all input colors and output colors across pairs.
    induct_palette_pairs/3,
    % induct_invariant_cells/3: cells that have the same color in both Input and Output.
    induct_invariant_cells/3,
    % induct_changed_cells/3: cells that differ between Input and Output.
    induct_changed_cells/3,
    % induct_consistent_delta/2: succeed if all pairs share the same cell-change pattern.
    induct_consistent_delta/2,
    % induct_bg_color/2: infer the background color (most frequent) in a grid.
    induct_bg_color/2,
    % induct_bg_color_pairs/2: infer consistent background color across all pairs.
    induct_bg_color_pairs/2,
    % induct_common_keys/3: keys present in both color maps.
    induct_common_keys/3
]).

% Import list utilities; msort/length/forall are built-ins, not imported.
:- use_module(library(lists), [member/2, subtract/3, intersection/3,
                                append/3, max_member/2, numlist/3]).
% Import higher-order apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, foldl/4]).

% induct_delta(+Input, +Output, -Delta).
% Delta is the list of r(R,C)-OldColor-NewColor triples for cells that changed.
induct_delta(Input, Output, Delta) :-
    % Flatten both grids and pair each cell with its row/col index.
    findall(r(R,C)-Old-New,
        (nth0(R, Input, Row),
         nth0(C, Row, Old),
         nth0(R, Output, ORow),
         nth0(C, ORow, New),
         Old \== New),
        Delta).

% induct_constant(+Input, +Output).
% Succeed if Output is structurally identical to Input (identity / no-op rule).
induct_constant(Grid, Grid).

% induct_color_map(+Input, +Output, -Map).
% Map is an association list ColorIn-ColorOut for cells that changed color.
% Uses findall + sort to deduplicate. Fails if conflicting mappings exist.
induct_color_map(Input, Output, Map) :-
    % Collect all Old-New color pairs from changed cells.
    findall(Old-New,
        (nth0(R, Input, Row),
         nth0(C, Row, Old),
         nth0(R, Output, ORow),
         nth0(C, ORow, New),
         Old \== New),
        RawPairs),
    % Deduplicate.
    sort(RawPairs, Pairs),
    % Check consistency: each Old color maps to exactly one New color.
    induct_check_consistent_map_(Pairs),
    Map = Pairs.

% induct_check_consistent_map_(+Pairs): fail if any Old maps to two different New.
induct_check_consistent_map_([]).
induct_check_consistent_map_([Old-New|Rest]) :-
    % If Old appears again, it must map to the same New.
    ( member(Old-New2, Rest), New \== New2 ->
        fail
    ;   induct_check_consistent_map_(Rest)
    ).

% induct_color_map_pairs(+Pairs, -Map).
% Infer a color substitution map consistent across all Input-Output pairs.
% Intersects the per-pair maps to keep only universally consistent mappings.
induct_color_map_pairs([], []).
induct_color_map_pairs([In-Out|Rest], Map) :-
    % Get map for the first pair.
    induct_color_map(In, Out, FirstMap),
    % Fold intersection over remaining pairs.
    foldl(induct_intersect_map_, Rest, FirstMap, Map).

% induct_intersect_map_(+Pair, +AccMap, -Map2): intersect AccMap with pair's map.
induct_intersect_map_(In-Out, AccMap, Map2) :-
    ( induct_color_map(In, Out, PairMap) ->
        intersection(AccMap, PairMap, Map2)
    ;   Map2 = []
    ).

% induct_size_change(+Input, +Output, -DRows, -DCols).
% DRows is Rows(Output) - Rows(Input); DCols is Cols(Output) - Cols(Input).
induct_size_change(Input, Output, DRows, DCols) :-
    % Count rows.
    length(Input, InRows),
    length(Output, OutRows),
    DRows is OutRows - InRows,
    % Count cols from first row.
    ( Input = [IR|_] -> length(IR, InCols) ; InCols = 0 ),
    ( Output = [OR|_] -> length(OR, OutCols) ; OutCols = 0 ),
    DCols is OutCols - InCols.

% induct_size_change_pairs(+Pairs, -DRows, -DCols).
% Infer consistent DRows and DCols across all training pairs.
% Fails if any pair has a different size change.
induct_size_change_pairs([In-Out|Rest], DRows, DCols) :-
    % Compute for the first pair.
    induct_size_change(In, Out, DRows, DCols),
    % Verify all remaining pairs agree.
    forall(member(In2-Out2, Rest),
        (induct_size_change(In2, Out2, DRows, DCols))).

% induct_color_palette(+Input, +Output, -Palette).
% Palette is the sorted list of all unique colors in Input union Output.
induct_color_palette(Input, Output, Palette) :-
    % Flatten both grids.
    findall(V, (member(Row, Input), member(V, Row)), InVals),
    findall(V, (member(Row, Output), member(V, Row)), OutVals),
    append(InVals, OutVals, AllVals),
    sort(AllVals, Palette).

% induct_palette_pairs(+Pairs, -InColors, -OutColors).
% InColors: sorted union of all colors appearing in any input grid.
% OutColors: sorted union of all colors appearing in any output grid.
induct_palette_pairs(Pairs, InColors, OutColors) :-
    % Collect all input and output grid values separately.
    findall(V, (member(In-_, Pairs), member(Row, In), member(V, Row)), InVals),
    findall(V, (member(_-Out, Pairs), member(Row, Out), member(V, Row)), OutVals),
    sort(InVals, InColors),
    sort(OutVals, OutColors).

% induct_invariant_cells(+Input, +Output, -Cells).
% Cells is the list of r(R,C) positions that have the same color in both grids.
induct_invariant_cells(Input, Output, Cells) :-
    findall(r(R,C),
        (nth0(R, Input, Row),
         nth0(C, Row, V),
         nth0(R, Output, ORow),
         nth0(C, ORow, V)),
        Cells).

% induct_changed_cells(+Input, +Output, -Cells).
% Cells is the list of r(R,C) positions where Input and Output differ.
induct_changed_cells(Input, Output, Cells) :-
    findall(r(R,C),
        (nth0(R, Input, Row),
         nth0(C, Row, Old),
         nth0(R, Output, ORow),
         nth0(C, ORow, New),
         Old \== New),
        Cells).

% induct_consistent_delta(+Pairs, -Delta).
% Succeed if all pairs share the same cell-change pattern (same Delta).
% Delta is the change list from the first pair; verified against the rest.
induct_consistent_delta([In-Out|Rest], Delta) :-
    % Compute delta from the first pair.
    induct_delta(In, Out, Delta),
    % All remaining pairs must have the same delta.
    forall(member(In2-Out2, Rest),
        (induct_delta(In2, Out2, Delta))).

% induct_bg_color(+Grid, -BgColor).
% BgColor is the most frequently occurring color in Grid.
induct_bg_color(Grid, BgColor) :-
    % Flatten the grid.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    % Build a list of Count-Color pairs.
    sort(Vals, UniqueVals),
    findall(Count-Color,
        (member(Color, UniqueVals),
         findall(x, member(Color, Vals), Xs),
         length(Xs, Count)),
        Counted),
    % Pick the most frequent.
    max_member(_-BgColor, Counted).

% induct_bg_color_pairs(+Pairs, -BgColor).
% Infer a consistent background color across all input grids.
% The background is the color that is most frequent in every input grid.
induct_bg_color_pairs([In-_|Rest], BgColor) :-
    induct_bg_color(In, BgColor),
    forall(member(In2-_, Rest),
        induct_bg_color(In2, BgColor)).

% induct_common_keys(+Map1, +Map2, -Common).
% Common is the list of Old-New pairs that appear in both Map1 and Map2.
induct_common_keys(Map1, Map2, Common) :-
    intersection(Map1, Map2, Common).
