% rect.pl - Layer 101: Rectangle Detection and Drawing Operations (rt_* prefix).
% Provides cell enumeration, grid drawing, containment tests, bounding boxes,
% corner extraction, solid/frame testing, overlap detection, and scaling for
% axis-aligned rectangles in 2D integer-coordinate grids.
:- module(rectangle, [
    rectangle_cells/5,
    rectangle_border/5,
    rectangle_interior/5,
    rectangle_draw/7,
    rectangle_draw_border/7,
    rectangle_draw_interior/7,
    rectangle_area/5,
    rectangle_contains/6,
    rectangle_corners/5,
    rectangle_bbox/5,
    rectangle_is_solid/6,
    rectangle_is_frame/6,
    rectangle_overlap/8,
    rectangle_scale/7
]).
% Import list utilities for index lookup, range generation, and list operations.
:- use_module(library(lists), [nth0/3, numlist/3, append/2, append/3, member/2, min_list/2, max_list/2]).
% Import higher-order utilities for mapping over lists.
:- use_module(library(apply), [maplist/2, maplist/3, maplist/4]).

% rectangle_replace_nth_: replace element at index N in a list with V. Cut on base.
rectangle_replace_nth_(0, [_|T], V, [V|T]) :- !.
rectangle_replace_nth_(N, [H|T], V, [H|T2]) :-
% Decrement index and recurse.
    N1 is N - 1,
    rectangle_replace_nth_(N1, T, V, T2).

% rectangle_set_cell_: return Grid with cell (R,C) set to V.
rectangle_set_cell_(Grid, R, C, V, Result) :-
% Retrieve the row; cut to avoid backtracking into nth0.
    nth0(R, Grid, OldRow), !,
    rectangle_replace_nth_(C, OldRow, V, NewRow),
    rectangle_replace_nth_(R, Grid, NewRow, Result).

% rectangle_fill_cells_: set each cell in Cells to Color. If-then-else for determinism.
rectangle_fill_cells_(Grid, Cells, Color, Result) :-
    (Cells = [] ->
% No more cells to set.
        Result = Grid
    ;
        Cells = [R-C|Rest],
% Set current cell then continue.
        rectangle_set_cell_(Grid, R, C, Color, G2),
        rectangle_fill_cells_(G2, Rest, Color, Result)
    ).

% rectangle_cells(+R1, +C1, +R2, +C2, -Cells): all cells in the solid rectangle from
% (R1,C1) to (R2,C2) in row-major order. Both endpoints are included.
rectangle_cells(R1, C1, R2, C2, Cells) :-
% Generate all row indices.
    numlist(R1, R2, Rows),
% Generate all column indices.
    numlist(C1, C2, Cols),
% For each row, build a row of R-C pairs.
    maplist([R, RowCells]>>(maplist([C, RC]>>(RC = R-C), Cols, RowCells)), Rows, Rows2D),
% Flatten the list-of-row-lists into one flat list.
    append(Rows2D, Cells).

% rectangle_border(+R1, +C1, +R2, +C2, -Cells): cells on the frame of rectangle (R1,C1)-(R2,C2).
% Frame = top row + bottom row + inner left column + inner right column.
% Cells are returned sorted in row-major order.
rectangle_border(R1, C1, R2, C2, Cells) :-
% Top row: row R1, all columns.
    numlist(C1, C2, TopCols),
    maplist([C, RC]>>(RC = R1-C), TopCols, Top),
% Bottom row: row R2, all columns (only if R2 > R1).
    (R2 > R1 ->
        maplist([C, RC]>>(RC = R2-C), TopCols, Bot)
    ;
        Bot = []
    ),
% Inner left column: column C1, rows strictly between R1 and R2.
    (R2 - R1 > 1 ->
        R1i is R1 + 1, R2i is R2 - 1,
        numlist(R1i, R2i, InnerRows),
        maplist([R, RC]>>(RC = R-C1), InnerRows, Left)
    ;
        Left = []
    ),
% Inner right column: column C2, same inner rows (only if C2 > C1).
    (R2 - R1 > 1, C2 > C1 ->
        R1j is R1 + 1, R2j is R2 - 1,
        numlist(R1j, R2j, InnerRowsR),
        maplist([R, RC]>>(RC = R-C2), InnerRowsR, Right)
    ;
        Right = []
    ),
% Combine all four sides and sort into row-major order.
    append([Top, Bot, Left, Right], Unsorted),
    sort(Unsorted, Cells).

% rectangle_interior(+R1, +C1, +R2, +C2, -Cells): cells strictly inside the rectangle.
% Interior requires at least 3 rows and 3 columns; otherwise Cells = [].
rectangle_interior(R1, C1, R2, C2, Cells) :-
    (R2 - R1 > 1, C2 - C1 > 1 ->
% Shrink each dimension by one on each side.
        R1i is R1 + 1, R2i is R2 - 1,
        C1i is C1 + 1, C2i is C2 - 1,
        rectangle_cells(R1i, C1i, R2i, C2i, Cells)
    ;
% No interior for thin rectangles.
        Cells = []
    ).

% rectangle_draw(+Grid, +R1, +C1, +R2, +C2, +Color, -Result): fill solid rectangle with Color.
rectangle_draw(Grid, R1, C1, R2, C2, Color, Result) :-
    rectangle_cells(R1, C1, R2, C2, Cells),
    rectangle_fill_cells_(Grid, Cells, Color, Result).

% rectangle_draw_border(+Grid, +R1, +C1, +R2, +C2, +Color, -Result): draw frame of rectangle.
rectangle_draw_border(Grid, R1, C1, R2, C2, Color, Result) :-
    rectangle_border(R1, C1, R2, C2, Cells),
    rectangle_fill_cells_(Grid, Cells, Color, Result).

% rectangle_draw_interior(+Grid, +R1, +C1, +R2, +C2, +Color, -Result): fill interior only.
rectangle_draw_interior(Grid, R1, C1, R2, C2, Color, Result) :-
    rectangle_interior(R1, C1, R2, C2, Cells),
    rectangle_fill_cells_(Grid, Cells, Color, Result).

% rectangle_area(+R1, +C1, +R2, +C2, -Area): number of cells in the rectangle.
% Area = (R2 - R1 + 1) * (C2 - C1 + 1).
rectangle_area(R1, C1, R2, C2, Area) :-
% Row count times column count.
    Rows is R2 - R1 + 1,
    Cols is C2 - C1 + 1,
    Area is Rows * Cols.

% rectangle_contains(+R1, +C1, +R2, +C2, +R, +C): succeed if (R,C) is inside the rectangle.
% Inclusion is inclusive on all four sides.
rectangle_contains(R1, C1, R2, C2, R, C) :-
    R1 =< R, R =< R2,
    C1 =< C, C =< C2.

% rectangle_corners(+R1, +C1, +R2, +C2, -Corners): four corner cells in order
% [top-left, top-right, bottom-left, bottom-right].
rectangle_corners(R1, C1, R2, C2, [R1-C1, R1-C2, R2-C1, R2-C2]).

% rectangle_bbox(+Cells, -MinR, -MinC, -MaxR, -MaxC): bounding box of a non-empty cell list.
% Cells must be a non-empty list of R-C pairs.
rectangle_bbox(Cells, MinR, MinC, MaxR, MaxC) :-
% Extract row indices from R-C pairs.
    maplist([RC, R]>>(RC = R-_), Cells, Rows),
% Extract column indices from R-C pairs.
    maplist([RC, C]>>(RC = _-C), Cells, Cols),
% Compute bounding box extents.
    min_list(Rows, MinR), max_list(Rows, MaxR),
    min_list(Cols, MinC), max_list(Cols, MaxC).

% rectangle_cell_color_: retrieve the grid value at R-C.
rectangle_cell_color_(Grid, R-C, V) :-
    nth0(R, Grid, Row),
    nth0(C, Row, V).

% rectangle_is_solid(+Grid, +R1, +C1, +R2, +C2, -Color): succeed if every cell in the
% rectangle has value Color.
rectangle_is_solid(Grid, R1, C1, R2, C2, Color) :-
% Enumerate all rectangle cells.
    rectangle_cells(R1, C1, R2, C2, Cells),
% First cell determines the color.
    Cells = [First|_],
    rectangle_cell_color_(Grid, First, Color),
% Every remaining cell must also match Color.
    forall(member(Cell, Cells), rectangle_cell_color_(Grid, Cell, Color)).

% rectangle_is_frame(+Grid, +R1, +C1, +R2, +C2, -Color): succeed if every border cell
% of the rectangle has value Color.
rectangle_is_frame(Grid, R1, C1, R2, C2, Color) :-
% Enumerate border cells.
    rectangle_border(R1, C1, R2, C2, Border),
% First border cell determines the color.
    Border = [First|_],
    rectangle_cell_color_(Grid, First, Color),
% Every border cell must match Color.
    forall(member(Cell, Border), rectangle_cell_color_(Grid, Cell, Color)).

% rectangle_overlap(+R1a, +C1a, +R2a, +C2a, +R1b, +C1b, +R2b, +C2b): succeed if two
% rectangles share at least one cell. Two axis-aligned rectangles overlap iff
% their row intervals and column intervals both overlap.
rectangle_overlap(R1a, C1a, R2a, C2a, R1b, C1b, R2b, C2b) :-
% Row intervals overlap: [R1a..R2a] and [R1b..R2b].
    R1a =< R2b, R2a >= R1b,
% Column intervals overlap: [C1a..C2a] and [C1b..C2b].
    C1a =< C2b, C2a >= C1b.

% rectangle_scale(+R1, +C1, +R2, +C2, +Factor, -R2New, -C2New): scale the rectangle
% by Factor from its top-left corner (R1,C1). The top-left stays fixed; the
% new bottom-right is at (R1 + (R2-R1)*Factor, C1 + (C2-C1)*Factor).
rectangle_scale(R1, C1, R2, C2, Factor, R2New, C2New) :-
% New row extent: row span times Factor.
    R2New is R1 + (R2 - R1) * Factor,
% New column extent: column span times Factor.
    C2New is C1 + (C2 - C1) * Factor.
