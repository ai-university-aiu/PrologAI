% Module declaration with all fourteen public predicates.
:- module(grid_color_transform, [
% Detect the consistent color mapping from GridA to GridB; fails if inconsistent.
    grid_color_transform_color_map/3,
% Apply a color map (list of cm(Old,New)) to a grid.
    grid_color_transform_apply_color_map/3,
% List of r(R,C) positions where GridA and GridB differ.
    grid_color_transform_diff_cells/3,
% Count of positions where GridA and GridB differ.
    grid_color_transform_diff_count/3,
% List of r(R,C) positions where GridA and GridB agree (same color).
    grid_color_transform_same_cells/3,
% List of chg(R,C,OldColor,NewColor) for every position that changed from A to B.
    grid_color_transform_changed_colors/3,
% Invert a color map: produce InvMap such that cm(VB,VA) for each cm(VA,VB).
    grid_color_transform_invert_map/2,
% Compose two color maps MapAtoB and MapBtoC into MapAtoC.
    grid_color_transform_compose_maps/3,
% Succeed if every entry in Map has the same source and target color.
    grid_color_transform_is_identity_map/1,
% Apply a list of chg(R,C,_,NewColor) changes to a grid.
    grid_color_transform_apply_changes/3,
% Grid where changed cells show their GridB value; unchanged cells show Bg.
    grid_color_transform_delta_grid/4,
% Paste non-Bg cells of Delta onto BaseGrid.
    grid_color_transform_overlay/4,
% Grid with cells that match in both grids kept; all others replaced with Bg.
    grid_color_transform_common_grid/4,
% Succeed if GridB is a bijective color permutation of GridA (same dimensions).
    grid_color_transform_is_color_permutation/2
]).
% gridtransform.pl - Layer 245: Grid Transformation Detection and Application (gtr_*).
% Fourteen predicates for detecting color mappings, computing differences, and
% applying transformations between pairs of symbolic grids of the same dimensions.
:- use_module(library(lists), [member/2]).

% --- PRIVATE HELPERS ---

% grid_color_transform_dims_/3: (H, W) dimensions of a grid.
grid_color_transform_dims_(Grid, H, W) :-
    length(Grid, H),
    ( H > 0 -> Grid = [Row0|_], length(Row0, W) ; W = 0 ).

% grid_color_transform_cell_/4: value at (R, C) in Grid.
grid_color_transform_cell_(Grid, R, C, V) :-
    nth0(R, Grid, Row), nth0(C, Row, V).

% grid_color_transform_set_cell_/5: produce NewGrid by setting (R,C) in Grid to V.
grid_color_transform_set_cell_(Grid, R, C, V, NewGrid) :-
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

% grid_color_transform_all_pairs_/3: all cm(VA,VB) pairs from corresponding cells of GridA and GridB.
grid_color_transform_all_pairs_(GridA, GridB, Map) :-
    grid_color_transform_dims_(GridA, H, W),
    grid_color_transform_dims_(GridB, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(cm(VA, VB),
        ( between(0, H1, R), between(0, W1, C),
          grid_color_transform_cell_(GridA, R, C, VA),
          grid_color_transform_cell_(GridB, R, C, VB) ),
        Pairs0),
    sort(Pairs0, Map).

% --- PUBLIC PREDICATES ---

% grid_color_transform_color_map(+GridA, +GridB, -Map)
% Map is a sorted list of cm(OldColor,NewColor) for the consistent color mapping
% from GridA to GridB. Fails if any source color maps to more than one target.
% GridA and GridB must have the same dimensions.
grid_color_transform_color_map(GridA, GridB, Map) :-
    grid_color_transform_all_pairs_(GridA, GridB, Map),
    \+ ( member(cm(VA, VB1), Map),
         member(cm(VA, VB2), Map),
         VB1 \= VB2 ).

% grid_color_transform_apply_color_map(+Grid, +Map, -Result)
% Result is Grid with each color replaced according to Map.
% Colors not in Map are left unchanged.
grid_color_transform_apply_color_map(Grid, Map, Result) :-
    grid_color_transform_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        ( between(0, H1, R),
          findall(NV,
              ( between(0, W1, C),
                grid_color_transform_cell_(Grid, R, C, V),
                ( member(cm(V, NV), Map) -> true ; NV = V ) ),
              Row) ),
        Result).

% grid_color_transform_diff_cells(+GridA, +GridB, -Cells)
% Cells is the sorted list of r(R,C) positions where GridA and GridB have different values.
% GridA and GridB must have the same dimensions.
grid_color_transform_diff_cells(GridA, GridB, Cells) :-
    grid_color_transform_dims_(GridA, H, W),
    grid_color_transform_dims_(GridB, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(r(R,C),
        ( between(0, H1, R), between(0, W1, C),
          grid_color_transform_cell_(GridA, R, C, VA),
          grid_color_transform_cell_(GridB, R, C, VB),
          VA \= VB ),
        Cells).

% grid_color_transform_diff_count(+GridA, +GridB, -N)
% N is the number of positions where GridA and GridB have different values.
grid_color_transform_diff_count(GridA, GridB, N) :-
    grid_color_transform_diff_cells(GridA, GridB, Cells),
    length(Cells, N).

% grid_color_transform_same_cells(+GridA, +GridB, -Cells)
% Cells is the sorted list of r(R,C) positions where GridA and GridB agree.
grid_color_transform_same_cells(GridA, GridB, Cells) :-
    grid_color_transform_dims_(GridA, H, W),
    grid_color_transform_dims_(GridB, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(r(R,C),
        ( between(0, H1, R), between(0, W1, C),
          grid_color_transform_cell_(GridA, R, C, V),
          grid_color_transform_cell_(GridB, R, C, V) ),
        Cells).

% grid_color_transform_changed_colors(+GridA, +GridB, -Changes)
% Changes is a list of chg(R,C,OldColor,NewColor) for every position where
% GridA and GridB have different values.
grid_color_transform_changed_colors(GridA, GridB, Changes) :-
    grid_color_transform_dims_(GridA, H, W),
    grid_color_transform_dims_(GridB, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(chg(R,C,VA,VB),
        ( between(0, H1, R), between(0, W1, C),
          grid_color_transform_cell_(GridA, R, C, VA),
          grid_color_transform_cell_(GridB, R, C, VB),
          VA \= VB ),
        Changes).

% grid_color_transform_invert_map(+Map, -InvMap)
% InvMap is the inverse of Map: for each cm(VA,VB) in Map, InvMap has cm(VB,VA).
% Fails if Map is not injective (two sources map to the same target).
grid_color_transform_invert_map(Map, InvMap) :-
    findall(cm(VB, VA), member(cm(VA, VB), Map), Inv0),
    sort(Inv0, InvMap),
    \+ ( member(cm(VB, VA1), InvMap),
         member(cm(VB, VA2), InvMap),
         VA1 \= VA2 ).

% grid_color_transform_compose_maps(+MapAtoB, +MapBtoC, -MapAtoC)
% MapAtoC maps each color from MapAtoB's domain through MapBtoC.
% Only colors present in both maps appear in MapAtoC.
grid_color_transform_compose_maps(MapAtoB, MapBtoC, MapAtoC) :-
    findall(cm(VA, VC),
        ( member(cm(VA, VB), MapAtoB),
          member(cm(VB, VC), MapBtoC) ),
        Composed0),
    sort(Composed0, MapAtoC).

% grid_color_transform_is_identity_map(+Map)
% Succeed if every cm(VA,VB) entry in Map has VA = VB.
grid_color_transform_is_identity_map(Map) :-
    \+ ( member(cm(VA, VB), Map), VA \= VB ).

% grid_color_transform_apply_changes(+Grid, +Changes, -Result)
% Result is Grid with each chg(R,C,_,NewColor) change applied.
% Changes must be a list of chg/4 terms. Later changes overwrite earlier ones
% at the same cell; for consistent use, provide at most one change per cell.
grid_color_transform_apply_changes(Grid, Changes, Result) :-
    grid_color_transform_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        ( between(0, H1, R),
          findall(NV,
              ( between(0, W1, C),
                grid_color_transform_cell_(Grid, R, C, V),
                ( member(chg(R, C, _, NV), Changes) -> true ; NV = V ) ),
              Row) ),
        Result).

% grid_color_transform_delta_grid(+GridA, +GridB, +Bg, -Delta)
% Delta has the same dimensions as GridA and GridB. Cells that differ between
% GridA and GridB take GridB's value; cells that agree are set to Bg.
grid_color_transform_delta_grid(GridA, GridB, Bg, Delta) :-
    grid_color_transform_dims_(GridA, H, W),
    grid_color_transform_dims_(GridB, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        ( between(0, H1, R),
          findall(V,
              ( between(0, W1, C),
                grid_color_transform_cell_(GridA, R, C, VA),
                grid_color_transform_cell_(GridB, R, C, VB),
                ( VA \= VB -> V = VB ; V = Bg ) ),
              Row) ),
        Delta).

% grid_color_transform_overlay(+BaseGrid, +DeltaGrid, +Bg, -Result)
% Result is BaseGrid with every non-Bg cell of DeltaGrid pasted on top.
% DeltaGrid and BaseGrid must have the same dimensions.
grid_color_transform_overlay(BaseGrid, DeltaGrid, Bg, Result) :-
    grid_color_transform_dims_(BaseGrid, H, W),
    grid_color_transform_dims_(DeltaGrid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        ( between(0, H1, R),
          findall(V,
              ( between(0, W1, C),
                grid_color_transform_cell_(DeltaGrid, R, C, DV),
                grid_color_transform_cell_(BaseGrid, R, C, BV),
                ( DV \= Bg -> V = DV ; V = BV ) ),
              Row) ),
        Result).

% grid_color_transform_common_grid(+GridA, +GridB, +Bg, -Common)
% Common has the same dimensions as GridA and GridB. Cells where both grids
% agree keep their shared value; cells that differ are set to Bg.
grid_color_transform_common_grid(GridA, GridB, Bg, Common) :-
    grid_color_transform_dims_(GridA, H, W),
    grid_color_transform_dims_(GridB, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        ( between(0, H1, R),
          findall(V,
              ( between(0, W1, C),
                grid_color_transform_cell_(GridA, R, C, VA),
                grid_color_transform_cell_(GridB, R, C, VB),
                ( VA = VB -> V = VA ; V = Bg ) ),
              Row) ),
        Common).

% grid_color_transform_is_color_permutation(+GridA, +GridB)
% Succeed if GridB is a bijective color permutation of GridA.
% Requires same dimensions. Fails if any color maps to multiple targets or
% multiple source colors map to the same target.
grid_color_transform_is_color_permutation(GridA, GridB) :-
    grid_color_transform_color_map(GridA, GridB, Map),
    \+ ( member(cm(VA1, VB), Map),
         member(cm(VA2, VB), Map),
         VA1 \= VA2 ).
