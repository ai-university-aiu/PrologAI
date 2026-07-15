% Module declaration with all fourteen public predicates.
:- module(gridtransform, [
% Detect the consistent color mapping from GridA to GridB; fails if inconsistent.
    gridtransform_color_map/3,
% Apply a color map (list of cm(Old,New)) to a grid.
    gridtransform_apply_color_map/3,
% List of r(R,C) positions where GridA and GridB differ.
    gridtransform_diff_cells/3,
% Count of positions where GridA and GridB differ.
    gridtransform_diff_count/3,
% List of r(R,C) positions where GridA and GridB agree (same color).
    gridtransform_same_cells/3,
% List of chg(R,C,OldColor,NewColor) for every position that changed from A to B.
    gridtransform_changed_colors/3,
% Invert a color map: produce InvMap such that cm(VB,VA) for each cm(VA,VB).
    gridtransform_invert_map/2,
% Compose two color maps MapAtoB and MapBtoC into MapAtoC.
    gridtransform_compose_maps/3,
% Succeed if every entry in Map has the same source and target color.
    gridtransform_is_identity_map/1,
% Apply a list of chg(R,C,_,NewColor) changes to a grid.
    gridtransform_apply_changes/3,
% Grid where changed cells show their GridB value; unchanged cells show Bg.
    gridtransform_delta_grid/4,
% Paste non-Bg cells of Delta onto BaseGrid.
    gridtransform_overlay/4,
% Grid with cells that match in both grids kept; all others replaced with Bg.
    gridtransform_common_grid/4,
% Succeed if GridB is a bijective color permutation of GridA (same dimensions).
    gridtransform_is_color_permutation/2
]).
% gridtransform.pl - Layer 245: Grid Transformation Detection and Application (gtr_*).
% Fourteen predicates for detecting color mappings, computing differences, and
% applying transformations between pairs of symbolic grids of the same dimensions.
:- use_module(library(lists), [member/2]).

% --- PRIVATE HELPERS ---

% gridtransform_dims_/3: (H, W) dimensions of a grid.
gridtransform_dims_(Grid, H, W) :-
    length(Grid, H),
    ( H > 0 -> Grid = [Row0|_], length(Row0, W) ; W = 0 ).

% gridtransform_cell_/4: value at (R, C) in Grid.
gridtransform_cell_(Grid, R, C, V) :-
    nth0(R, Grid, Row), nth0(C, Row, V).

% gridtransform_set_cell_/5: produce NewGrid by setting (R,C) in Grid to V.
gridtransform_set_cell_(Grid, R, C, V, NewGrid) :-
    nth0(R, Grid, OldRow),
    length(OldRow, W), W1 is W - 1,
    findall(NV,
        ( between(0, W1, CC),
          ( CC =:= C -> NV = V ; nth0(CC, OldRow, NV) ) ),
        NewRow),
    length(Grid, H), H1 is H - 1,
    findall(NR,
        ( between(0, H1, RR),
          ( RR =:= R -> NR = NewRow ; nth0(RR, Grid, NR) ) ),
        NewGrid).

% gridtransform_all_pairs_/3: all cm(VA,VB) pairs from corresponding cells of GridA and GridB.
gridtransform_all_pairs_(GridA, GridB, Map) :-
    gridtransform_dims_(GridA, H, W),
    gridtransform_dims_(GridB, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(cm(VA, VB),
        ( between(0, H1, R), between(0, W1, C),
          gridtransform_cell_(GridA, R, C, VA),
          gridtransform_cell_(GridB, R, C, VB) ),
        Pairs0),
    sort(Pairs0, Map).

% --- PUBLIC PREDICATES ---

% gridtransform_color_map(+GridA, +GridB, -Map)
% Map is a sorted list of cm(OldColor,NewColor) for the consistent color mapping
% from GridA to GridB. Fails if any source color maps to more than one target.
% GridA and GridB must have the same dimensions.
gridtransform_color_map(GridA, GridB, Map) :-
    gridtransform_all_pairs_(GridA, GridB, Map),
    \+ ( member(cm(VA, VB1), Map),
         member(cm(VA, VB2), Map),
         VB1 \= VB2 ).

% gridtransform_apply_color_map(+Grid, +Map, -Result)
% Result is Grid with each color replaced according to Map.
% Colors not in Map are left unchanged.
gridtransform_apply_color_map(Grid, Map, Result) :-
    gridtransform_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        ( between(0, H1, R),
          findall(NV,
              ( between(0, W1, C),
                gridtransform_cell_(Grid, R, C, V),
                ( member(cm(V, NV), Map) -> true ; NV = V ) ),
              Row) ),
        Result).

% gridtransform_diff_cells(+GridA, +GridB, -Cells)
% Cells is the sorted list of r(R,C) positions where GridA and GridB have different values.
% GridA and GridB must have the same dimensions.
gridtransform_diff_cells(GridA, GridB, Cells) :-
    gridtransform_dims_(GridA, H, W),
    gridtransform_dims_(GridB, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(r(R,C),
        ( between(0, H1, R), between(0, W1, C),
          gridtransform_cell_(GridA, R, C, VA),
          gridtransform_cell_(GridB, R, C, VB),
          VA \= VB ),
        Cells).

% gridtransform_diff_count(+GridA, +GridB, -N)
% N is the number of positions where GridA and GridB have different values.
gridtransform_diff_count(GridA, GridB, N) :-
    gridtransform_diff_cells(GridA, GridB, Cells),
    length(Cells, N).

% gridtransform_same_cells(+GridA, +GridB, -Cells)
% Cells is the sorted list of r(R,C) positions where GridA and GridB agree.
gridtransform_same_cells(GridA, GridB, Cells) :-
    gridtransform_dims_(GridA, H, W),
    gridtransform_dims_(GridB, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(r(R,C),
        ( between(0, H1, R), between(0, W1, C),
          gridtransform_cell_(GridA, R, C, V),
          gridtransform_cell_(GridB, R, C, V) ),
        Cells).

% gridtransform_changed_colors(+GridA, +GridB, -Changes)
% Changes is a list of chg(R,C,OldColor,NewColor) for every position where
% GridA and GridB have different values.
gridtransform_changed_colors(GridA, GridB, Changes) :-
    gridtransform_dims_(GridA, H, W),
    gridtransform_dims_(GridB, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(chg(R,C,VA,VB),
        ( between(0, H1, R), between(0, W1, C),
          gridtransform_cell_(GridA, R, C, VA),
          gridtransform_cell_(GridB, R, C, VB),
          VA \= VB ),
        Changes).

% gridtransform_invert_map(+Map, -InvMap)
% InvMap is the inverse of Map: for each cm(VA,VB) in Map, InvMap has cm(VB,VA).
% Fails if Map is not injective (two sources map to the same target).
gridtransform_invert_map(Map, InvMap) :-
    findall(cm(VB, VA), member(cm(VA, VB), Map), Inv0),
    sort(Inv0, InvMap),
    \+ ( member(cm(VB, VA1), InvMap),
         member(cm(VB, VA2), InvMap),
         VA1 \= VA2 ).

% gridtransform_compose_maps(+MapAtoB, +MapBtoC, -MapAtoC)
% MapAtoC maps each color from MapAtoB's domain through MapBtoC.
% Only colors present in both maps appear in MapAtoC.
gridtransform_compose_maps(MapAtoB, MapBtoC, MapAtoC) :-
    findall(cm(VA, VC),
        ( member(cm(VA, VB), MapAtoB),
          member(cm(VB, VC), MapBtoC) ),
        Composed0),
    sort(Composed0, MapAtoC).

% gridtransform_is_identity_map(+Map)
% Succeed if every cm(VA,VB) entry in Map has VA = VB.
gridtransform_is_identity_map(Map) :-
    \+ ( member(cm(VA, VB), Map), VA \= VB ).

% gridtransform_apply_changes(+Grid, +Changes, -Result)
% Result is Grid with each chg(R,C,_,NewColor) change applied.
% Changes must be a list of chg/4 terms. Later changes overwrite earlier ones
% at the same cell; for consistent use, provide at most one change per cell.
gridtransform_apply_changes(Grid, Changes, Result) :-
    gridtransform_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        ( between(0, H1, R),
          findall(NV,
              ( between(0, W1, C),
                gridtransform_cell_(Grid, R, C, V),
                ( member(chg(R, C, _, NV), Changes) -> true ; NV = V ) ),
              Row) ),
        Result).

% gridtransform_delta_grid(+GridA, +GridB, +Bg, -Delta)
% Delta has the same dimensions as GridA and GridB. Cells that differ between
% GridA and GridB take GridB's value; cells that agree are set to Bg.
gridtransform_delta_grid(GridA, GridB, Bg, Delta) :-
    gridtransform_dims_(GridA, H, W),
    gridtransform_dims_(GridB, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        ( between(0, H1, R),
          findall(V,
              ( between(0, W1, C),
                gridtransform_cell_(GridA, R, C, VA),
                gridtransform_cell_(GridB, R, C, VB),
                ( VA \= VB -> V = VB ; V = Bg ) ),
              Row) ),
        Delta).

% gridtransform_overlay(+BaseGrid, +DeltaGrid, +Bg, -Result)
% Result is BaseGrid with every non-Bg cell of DeltaGrid pasted on top.
% DeltaGrid and BaseGrid must have the same dimensions.
gridtransform_overlay(BaseGrid, DeltaGrid, Bg, Result) :-
    gridtransform_dims_(BaseGrid, H, W),
    gridtransform_dims_(DeltaGrid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        ( between(0, H1, R),
          findall(V,
              ( between(0, W1, C),
                gridtransform_cell_(DeltaGrid, R, C, DV),
                gridtransform_cell_(BaseGrid, R, C, BV),
                ( DV \= Bg -> V = DV ; V = BV ) ),
              Row) ),
        Result).

% gridtransform_common_grid(+GridA, +GridB, +Bg, -Common)
% Common has the same dimensions as GridA and GridB. Cells where both grids
% agree keep their shared value; cells that differ are set to Bg.
gridtransform_common_grid(GridA, GridB, Bg, Common) :-
    gridtransform_dims_(GridA, H, W),
    gridtransform_dims_(GridB, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        ( between(0, H1, R),
          findall(V,
              ( between(0, W1, C),
                gridtransform_cell_(GridA, R, C, VA),
                gridtransform_cell_(GridB, R, C, VB),
                ( VA = VB -> V = VA ; V = Bg ) ),
              Row) ),
        Common).

% gridtransform_is_color_permutation(+GridA, +GridB)
% Succeed if GridB is a bijective color permutation of GridA.
% Requires same dimensions. Fails if any color maps to multiple targets or
% multiple source colors map to the same target.
gridtransform_is_color_permutation(GridA, GridB) :-
    gridtransform_color_map(GridA, GridB, Map),
    \+ ( member(cm(VA1, VB), Map),
         member(cm(VA2, VB), Map),
         VA1 \= VA2 ).
