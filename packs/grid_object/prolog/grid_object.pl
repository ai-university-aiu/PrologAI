% Module declaration with all fourteen public predicates.
:- module(grid_object, [
% List of r(R,C) cells in the 4-connected component at (R,C).
    grid_object_object_cells/4,
% Color of the connected component at (R,C).
    grid_object_object_color/4,
% Number of cells in the connected component at (R,C).
    grid_object_object_size/4,
% Bounding box r0(R0,C0,R1,C1) of the connected component at (R,C).
    grid_object_object_bbox/4,
% Binary grid mask: component color where object, Bg elsewhere.
    grid_object_object_mask/5,
% Extract bounding-box subgrid of the connected component at (R,C).
    grid_object_extract_object/5,
% List of ob(Color,Cells,BBox) for all non-bg connected components.
    grid_object_all_objects/3,
% Count of distinct non-bg connected components.
    grid_object_object_count/3,
% Cells of the largest (most cells) non-bg connected component.
    grid_object_largest_object/3,
% Cells of the smallest (fewest cells) non-bg connected component.
    grid_object_smallest_object/3,
% Replace the connected component at (R,C) with NewColor.
    grid_object_flood_fill/5,
% Fill all Bg regions fully enclosed by non-Bg cells with FgColor.
    grid_object_fill_enclosed/4,
% Replace all cells of the connected component at (R,C) with Bg.
    grid_object_remove_object/5,
% Move the connected component at (R,C) so its bbox top-left is (NewR,NewC).
    grid_object_move_object/7
]).
% gridobj.pl - Layer 242: Grid Object Operations (gob_* prefix).
% Fourteen predicates for flood-fill-based connected component analysis,
% extraction, manipulation, and placement in symbolic grids.
% Uses 4-connectivity (up, down, left, right). No diagonal connectivity.
:- use_module(library(lists), [member/2, min_list/2, max_list/2,
                                list_to_set/2, append/3]).

% --- PRIVATE HELPERS ---

% grid_object_dims_/3: (H, W) of a grid.
grid_object_dims_(Grid, H, W) :-
    length(Grid, H),
    ( H > 0 -> Grid = [Row0|_], length(Row0, W) ; W = 0 ).

% grid_object_cell_/4: value at (R, C) in Grid.
grid_object_cell_(Grid, R, C, V) :-
    nth0(R, Grid, Row), nth0(C, Row, V).

% grid_object_cells_bbox_/2: bounding box of a non-empty list of r(R,C) cells.
grid_object_cells_bbox_(Cells, r0(R0,C0,R1,C1)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, R0), max_list(Rs, R1),
    min_list(Cs, C0), max_list(Cs, C1).

% grid_object_bfs_/7: BFS from Frontier; return all visited cells of same Color.
% Frontier: list of r(R,C) to expand next.
% Visited: all cells already collected (includes Frontier starting cells).
grid_object_bfs_([], Visited, _, _, _, _, Visited).
grid_object_bfs_([r(R,C)|Rest], Visited, Color, H, W, Grid, Result) :-
    R0 is R - 1, R1 is R + 1, C0 is C - 1, C1 is C + 1,
    findall(r(NR,NC),
        ( member(r(NR,NC), [r(R0,C),r(R1,C),r(R,C0),r(R,C1)]),
          NR >= 0, NR < H, NC >= 0, NC < W,
          \+ member(r(NR,NC), Visited),
          \+ member(r(NR,NC), Rest),
          grid_object_cell_(Grid, NR, NC, Color) ),
        NewCells),
    append(Rest, NewCells, NewFrontier),
    append(Visited, NewCells, NewVisited),
    grid_object_bfs_(NewFrontier, NewVisited, Color, H, W, Grid, Result).

% grid_object_bg_bfs_/7: BFS from Frontier through Bg-colored cells only.
grid_object_bg_bfs_([], Visited, _, _, _, _, Visited).
grid_object_bg_bfs_([r(R,C)|Rest], Visited, Bg, H, W, Grid, Result) :-
    R0 is R - 1, R1 is R + 1, C0 is C - 1, C1 is C + 1,
    findall(r(NR,NC),
        ( member(r(NR,NC), [r(R0,C),r(R1,C),r(R,C0),r(R,C1)]),
          NR >= 0, NR < H, NC >= 0, NC < W,
          \+ member(r(NR,NC), Visited),
          \+ member(r(NR,NC), Rest),
          grid_object_cell_(Grid, NR, NC, Bg) ),
        NewCells),
    append(Rest, NewCells, NewFrontier),
    append(Visited, NewCells, NewVisited),
    grid_object_bg_bfs_(NewFrontier, NewVisited, Bg, H, W, Grid, Result).

% grid_object_collect_objects_/7: collect all non-bg connected components.
% Scans NonBgCells in order; skips cells already in Seen.
grid_object_collect_objects_([], _, _, _, _, _, []).
grid_object_collect_objects_([r(R,C)|Rest], Grid, H, W, Bg, Seen, Objects) :-
    ( member(r(R,C), Seen) ->
        grid_object_collect_objects_(Rest, Grid, H, W, Bg, Seen, Objects)
    ;
        grid_object_cell_(Grid, R, C, Color),
        grid_object_bfs_([r(R,C)], [r(R,C)], Color, H, W, Grid, Cells),
        grid_object_cells_bbox_(Cells, BBox),
        append(Seen, Cells, NewSeen),
        grid_object_collect_objects_(Rest, Grid, H, W, Bg, NewSeen, RestObjs),
        Objects = [ob(Color,Cells,BBox)|RestObjs]
    ).

% --- PUBLIC PREDICATES ---

% grid_object_object_cells(+Grid, +R, +C, -Cells)
% Cells is the list of r(R,C) positions in the 4-connected component at (R,C).
% The component includes (R,C) itself.
grid_object_object_cells(Grid, R, C, Cells) :-
    grid_object_dims_(Grid, H, W),
    grid_object_cell_(Grid, R, C, Color),
    grid_object_bfs_([r(R,C)], [r(R,C)], Color, H, W, Grid, Cells).

% grid_object_object_color(+Grid, +R, +C, -Color)
% Color is the value at (R,C) = the color of the connected component.
grid_object_object_color(Grid, R, C, Color) :-
    grid_object_cell_(Grid, R, C, Color).

% grid_object_object_size(+Grid, +R, +C, -Size)
% Size is the number of cells in the 4-connected component at (R,C).
grid_object_object_size(Grid, R, C, Size) :-
    grid_object_object_cells(Grid, R, C, Cells),
    length(Cells, Size).

% grid_object_object_bbox(+Grid, +R, +C, -BBox)
% BBox is r0(R0,C0,R1,C1): the tight bounding box of the component at (R,C).
grid_object_object_bbox(Grid, R, C, BBox) :-
    grid_object_object_cells(Grid, R, C, Cells),
    grid_object_cells_bbox_(Cells, BBox).

% grid_object_object_mask(+Grid, +R, +C, +Bg, -Mask)
% Mask is a grid with component cells shown in their Color and all other cells Bg.
% Same dimensions as Grid.
grid_object_object_mask(Grid, R, C, Bg, Mask) :-
    grid_object_object_cells(Grid, R, C, Cells),
    grid_object_cell_(Grid, R, C, Color),
    grid_object_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        (between(0, H1, GR),
         findall(V,
             (between(0, W1, GC),
              ( member(r(GR,GC), Cells) -> V = Color ; V = Bg )),
             Row)),
        Mask).

% grid_object_extract_object(+Grid, +R, +C, +Bg, -Extracted)
% Extracted is the bounding-box subgrid of the component at (R,C).
% Non-component cells within the bounding box are filled with Bg.
grid_object_extract_object(Grid, R, C, Bg, Extracted) :-
    grid_object_object_cells(Grid, R, C, Cells),
    grid_object_cell_(Grid, R, C, Color),
    grid_object_cells_bbox_(Cells, r0(R0,C0,R1,C1)),
    H0 is R1 - R0 + 1, W0 is C1 - C0 + 1,
    H1 is H0 - 1, W1 is W0 - 1,
    findall(Row,
        (between(0, H1, DR),
         GR is R0 + DR,
         findall(V,
             (between(0, W1, DC),
              GC is C0 + DC,
              ( member(r(GR,GC), Cells) -> V = Color ; V = Bg )),
             Row)),
        Extracted).

% grid_object_all_objects(+Grid, +Bg, -Objects)
% Objects is a list of ob(Color,Cells,BBox) for every non-Bg connected component.
% Components are returned in scan order (top-to-bottom, left-to-right by seed).
grid_object_all_objects(Grid, Bg, Objects) :-
    grid_object_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(r(R,C),
        ( between(0, H1, R), between(0, W1, C),
          grid_object_cell_(Grid, R, C, V), V \= Bg ),
        NonBgCells),
    grid_object_collect_objects_(NonBgCells, Grid, H, W, Bg, [], Objects).

% grid_object_object_count(+Grid, +Bg, -Count)
% Count is the number of distinct non-Bg connected components.
grid_object_object_count(Grid, Bg, Count) :-
    grid_object_all_objects(Grid, Bg, Objects),
    length(Objects, Count).

% grid_object_largest_object(+Grid, +Bg, -Cells)
% Cells is the cell list of the largest non-Bg connected component.
% Fails if Grid has no non-Bg cells.
grid_object_largest_object(Grid, Bg, Cells) :-
    grid_object_all_objects(Grid, Bg, Objects),
    Objects \= [],
    findall(neg(Neg, Cs),
        (member(ob(_,Cs,_), Objects), length(Cs, Len), Neg is -Len),
        Keyed),
    msort(Keyed, [neg(_,Cells)|_]).

% grid_object_smallest_object(+Grid, +Bg, -Cells)
% Cells is the cell list of the smallest non-Bg connected component.
% Fails if Grid has no non-Bg cells.
grid_object_smallest_object(Grid, Bg, Cells) :-
    grid_object_all_objects(Grid, Bg, Objects),
    Objects \= [],
    findall(pos(Len, Cs),
        (member(ob(_,Cs,_), Objects), length(Cs, Len)),
        Keyed),
    msort(Keyed, [pos(_,Cells)|_]).

% grid_object_flood_fill(+Grid, +R, +C, +NewColor, -Result)
% Replace all cells of the connected component at (R,C) with NewColor.
grid_object_flood_fill(Grid, R, C, NewColor, Result) :-
    grid_object_object_cells(Grid, R, C, Cells),
    grid_object_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        (between(0, H1, GR),
         findall(V,
             (between(0, W1, GC),
              ( member(r(GR,GC), Cells) -> V = NewColor
              ; grid_object_cell_(Grid, GR, GC, V) )),
             Row)),
        Result).

% grid_object_fill_enclosed(+Grid, +Bg, +FgColor, -Result)
% Fill all Bg regions that are fully enclosed by non-Bg cells with FgColor.
% A Bg region is enclosed if it has no 4-connected path to the grid border.
grid_object_fill_enclosed(Grid, Bg, FgColor, Result) :-
    grid_object_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(r(R,C),
        ( between(0, H1, R), between(0, W1, C),
          ( R =:= 0 ; R =:= H1 ; C =:= 0 ; C =:= W1 ),
          grid_object_cell_(Grid, R, C, Bg) ),
        BorderBg0),
    list_to_set(BorderBg0, BorderBg),
    grid_object_bg_bfs_(BorderBg, BorderBg, Bg, H, W, Grid, ReachableBg),
    findall(Row,
        (between(0, H1, GR),
         findall(V,
             (between(0, W1, GC),
              grid_object_cell_(Grid, GR, GC, OV),
              ( OV = Bg ->
                  ( member(r(GR,GC), ReachableBg) -> V = Bg ; V = FgColor )
              ;
                  V = OV
              )),
             Row)),
        Result).

% grid_object_remove_object(+Grid, +R, +C, +Bg, -Result)
% Replace all cells of the connected component at (R,C) with Bg.
grid_object_remove_object(Grid, R, C, Bg, Result) :-
    grid_object_object_cells(Grid, R, C, Cells),
    grid_object_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        (between(0, H1, GR),
         findall(V,
             (between(0, W1, GC),
              ( member(r(GR,GC), Cells) -> V = Bg
              ; grid_object_cell_(Grid, GR, GC, V) )),
             Row)),
        Result).

% grid_object_move_object(+Grid, +R, +C, +NewR, +NewC, +Bg, -Result)
% Move the connected component at (R,C) so its bounding-box top-left is at (NewR,NewC).
% Removes original cells and places component at new position.
% Cells that would move outside the grid bounds are clipped (not placed).
grid_object_move_object(Grid, R, C, NewR, NewC, Bg, Result) :-
    grid_object_object_cells(Grid, R, C, Cells),
    grid_object_cell_(Grid, R, C, Color),
    grid_object_cells_bbox_(Cells, r0(OldR0,OldC0,_,_)),
    DR is NewR - OldR0, DC is NewC - OldC0,
    grid_object_remove_object(Grid, R, C, Bg, Base),
    grid_object_dims_(Base, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(r(GR,GC,Color),
        ( member(r(OR,OC), Cells),
          GR is OR + DR, GC is OC + DC,
          GR >= 0, GR < H, GC >= 0, GC < W ),
        MovedCells),
    findall(Row,
        (between(0, H1, GR),
         findall(V,
             (between(0, W1, GC),
              ( member(r(GR,GC,Color), MovedCells) -> V = Color
              ; grid_object_cell_(Base, GR, GC, V) )),
             Row)),
        Result).
