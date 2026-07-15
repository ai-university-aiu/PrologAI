% objbound.pl - Layer 171: Object Shape Classification and Bounding Box Analysis (ob_* prefix).
% Provides bounding-box dimension queries, shape type tests (rect, hline, vline,
% single, square bbox, hollow, frame), hole detection, perimeter computation,
% and dense hull generation for obj(Color, Cells) terms.
% Operates directly on obj terms without requiring a grid argument.
% Complements objmorph (morphological dilation/erosion) and objsym (symmetry tests).
:- module(objbound, [
    objbound_bbox_h/2,
    objbound_bbox_w/2,
    objbound_bbox_area/2,
    objbound_is_rect/1,
    objbound_is_hline/1,
    objbound_is_vline/1,
    objbound_is_single/1,
    objbound_is_square_bbox/1,
    objbound_holes/2,
    objbound_n_holes/2,
    objbound_is_hollow/1,
    objbound_is_frame/1,
    objbound_perimeter/2,
    objbound_dense_hull/2
]).
% member/2, memberchk/2, min_list/2, max_list/2, sum_list/2 from library(lists).
:- use_module(library(lists), [member/2, memberchk/2, min_list/2, max_list/2, sum_list/2]).

% objbound_bbox_(+Obj, -MinR, -MinC, -MaxR, -MaxC): private bounding box helper.
% Collects all row and column indices then finds min and max via library predicates.
objbound_bbox_(obj(_, Cells), MinR, MinC, MaxR, MaxC) :-
% Collect all row indices from the cell list.
    findall(R, member(r(R,_), Cells), Rs),
% Collect all column indices from the cell list.
    findall(C, member(r(_,C), Cells), Cs),
% Find minimum and maximum rows.
    min_list(Rs, MinR), max_list(Rs, MaxR),
% Find minimum and maximum columns.
    min_list(Cs, MinC), max_list(Cs, MaxC).

% objbound_bbox_h(+Obj, -H): H is the bounding box height (number of rows spanned by Obj).
% H = MaxR - MinR + 1; minimum is 1 for a single-row object.
objbound_bbox_h(Obj, H) :-
% Compute the bounding box to get the row span.
    objbound_bbox_(Obj, MinR, _, MaxR, _),
% Height = max row - min row + 1.
    H is MaxR - MinR + 1.

% objbound_bbox_w(+Obj, -W): W is the bounding box width (number of columns spanned by Obj).
% W = MaxC - MinC + 1; minimum is 1 for a single-column object.
objbound_bbox_w(Obj, W) :-
% Compute the bounding box to get the column span.
    objbound_bbox_(Obj, _, MinC, _, MaxC),
% Width = max col - min col + 1.
    W is MaxC - MinC + 1.

% objbound_bbox_area(+Obj, -Area): Area is the area of Obj's bounding box (H * W).
% This is the total number of grid positions spanned, including holes.
objbound_bbox_area(Obj, Area) :-
% Get both height and width to compute their product.
    objbound_bbox_h(Obj, H),
    objbound_bbox_w(Obj, W),
% Area = H * W.
    Area is H * W.

% objbound_is_rect(+Obj): true when Obj is a solid rectangle with no holes.
% Every position in the bounding box must be occupied: cell count = bbox area.
objbound_is_rect(Obj) :-
% Count actual cells.
    Obj = obj(_, Cells),
    length(Cells, N),
% Compute the bbox area.
    objbound_bbox_area(Obj, Area),
% A rectangle has exactly as many cells as its bounding box area.
    N =:= Area.

% objbound_is_hline(+Obj): true when all cells of Obj lie in a single row.
% The bounding box height is 1 for a horizontal line.
objbound_is_hline(Obj) :-
% A horizontal line spans exactly one row.
    objbound_bbox_h(Obj, 1).

% objbound_is_vline(+Obj): true when all cells of Obj lie in a single column.
% The bounding box width is 1 for a vertical line.
objbound_is_vline(Obj) :-
% A vertical line spans exactly one column.
    objbound_bbox_w(Obj, 1).

% objbound_is_single(+Obj): true when Obj has exactly one cell (H=1, W=1).
% A single cell is both a horizontal line and a vertical line.
objbound_is_single(Obj) :-
% Both dimensions must be 1 for a single cell.
    objbound_bbox_h(Obj, 1),
    objbound_bbox_w(Obj, 1).

% objbound_is_square_bbox(+Obj): true when the bounding box of Obj is a square (H = W).
% This does NOT require the object itself to fill the square; use objbound_is_rect too.
objbound_is_square_bbox(Obj) :-
% Get both dimensions and verify they are equal.
    objbound_bbox_h(Obj, H),
    objbound_bbox_w(Obj, W),
% Square bounding box: height equals width.
    H =:= W.

% objbound_holes(+Obj, -HoleCells): HoleCells is the list of cells in the bounding box
% of Obj that are NOT part of Obj's cell set. Empty when Obj is a rectangle.
objbound_holes(Obj, HoleCells) :-
% Get the bounding box to enumerate all grid positions within it.
    Obj = obj(_, Cells),
    objbound_bbox_(Obj, MinR, MinC, MaxR, MaxC),
% Collect positions that are in the bbox but missing from Cells.
    findall(r(R,C),
            (between(MinR, MaxR, R), between(MinC, MaxC, C),
             \+ memberchk(r(R,C), Cells)),
            HoleCells).

% objbound_n_holes(+Obj, -N): N is the number of hole cells in Obj's bounding box.
% N = 0 when Obj is a rectangle. N > 0 when the object has gaps.
objbound_n_holes(Obj, N) :-
% Compute hole list and count it.
    objbound_holes(Obj, HoleCells),
    length(HoleCells, N).

% objbound_is_hollow(+Obj): true when Obj has at least one hole in its bounding box.
% An object is hollow iff cell count < bbox area.
objbound_is_hollow(Obj) :-
% There must be at least one hole.
    objbound_n_holes(Obj, N),
    N > 0.

% objbound_is_frame(+Obj): true when Obj is a hollow rectangular frame.
% A frame has: H >= 3 and W >= 3 (non-trivial interior exists),
% all border cells (row=MinR, row=MaxR, col=MinC, col=MaxC) are present,
% and no interior cell (MinR < R < MaxR AND MinC < C < MaxC) is present.
objbound_is_frame(Obj) :-
% Get the bounding box dimensions.
    Obj = obj(_, Cells),
    objbound_bbox_(Obj, MinR, MinC, MaxR, MaxC),
    H is MaxR - MinR + 1, H >= 3,
    W is MaxC - MinC + 1, W >= 3,
% All bbox border cells must be present in Cells.
    forall(
        (between(MinR, MaxR, R), between(MinC, MaxC, C),
         (R =:= MinR ; R =:= MaxR ; C =:= MinC ; C =:= MaxC)),
        memberchk(r(R,C), Cells)
    ),
% No interior cell (strictly inside the border) may be present in Cells.
    \+ (member(r(R,C), Cells), R > MinR, R < MaxR, C > MinC, C < MaxC).

% objbound_cell_exposed_(+r(R,C), +Cells, -N): N exposed edges for cell r(R,C).
% An edge is exposed when the 4-adjacent neighbor is not in Cells.
objbound_cell_exposed_(r(R,C), Cells, N) :-
% Check all four orthogonal neighbors; count those absent from Cells.
    findall(x, (member(d(DR,DC), [d(-1,0),d(1,0),d(0,-1),d(0,1)]),
                NR is R + DR, NC is C + DC,
                \+ memberchk(r(NR,NC), Cells)), Xs),
    length(Xs, N).

% objbound_perimeter(+Obj, -P): P is the total number of exposed cell edges in Obj.
% Each cell contributes the count of its 4-adjacent non-object neighbors.
% A solid 1x1 object has perimeter 4; a 1x3 horizontal bar has perimeter 8.
objbound_perimeter(Obj, P) :-
% Get the cell list to enumerate and to check membership.
    Obj = obj(_, Cells),
% Sum exposed edges across all cells.
    findall(N, (member(Cell, Cells), objbound_cell_exposed_(Cell, Cells, N)), Ns),
    sum_list(Ns, P).

% objbound_dense_hull(+Obj, -HullObj): HullObj is the solid rectangle covering Obj's bounding box.
% HullObj has the same color as Obj and cells at every position in the bbox (including holes).
% HullObj = obj(Color, [r(R,C) for all MinR<=R<=MaxR, MinC<=C<=MaxC]).
objbound_dense_hull(Obj, obj(Color, Hull)) :-
% Get the color and bounding box of Obj.
    Obj = obj(Color, _),
    objbound_bbox_(Obj, MinR, MinC, MaxR, MaxC),
% Generate all cells in the bounding box in row-major order.
    findall(r(R,C), (between(MinR, MaxR, R), between(MinC, MaxC, C)), Hull).
