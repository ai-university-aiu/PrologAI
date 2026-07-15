% Module declaration: fill pack, Layer 55.
:- module(fill, [
    % fill_fill_region/4: fill all cells in a region with a color.
    fill_fill_region/4,
    % fill_fill_bbox/4: fill all cells within a bounding box with a color.
    fill_fill_bbox/4,
    % fill_fill_row/4: fill an entire grid row with a color.
    fill_fill_row/4,
    % fill_fill_col/4: fill an entire grid column with a color.
    fill_fill_col/4,
    % fill_fill_cells/4: fill a specified list of cells with a color.
    fill_fill_cells/4,
    % fill_fill_border/3: fill the outermost ring of grid cells with a color.
    fill_fill_border/3,
    % fill_outline_region/4: fill only the border cells of a region with a color.
    fill_outline_region/4,
    % fill_fill_interior/4: fill only the interior cells of a region with a color.
    fill_fill_interior/4,
    % fill_solid_rect/4: create a new grid of given size filled with one color.
    fill_solid_rect/4,
    % fill_checkerboard/5: create a new grid with alternating two colors.
    fill_checkerboard/5,
    % fill_draw_hline/6: fill a horizontal segment of a row with a color.
    fill_draw_hline/6,
    % fill_draw_vline/6: fill a vertical segment of a column with a color.
    fill_draw_vline/6,
    % fill_fill_main_diag/3: fill cells where row index equals column index.
    fill_fill_main_diag/3,
    % fill_stamp/6: overlay a subgrid onto a base grid, treating BG as transparent.
    fill_stamp/6
]).

% Import list and apply utilities; length/2, numlist/3 are used below.
:- use_module(library(lists),  [member/2, nth0/3, numlist/3]).
:- use_module(library(apply),  [maplist/2, maplist/3, maplist/4]).

% fill_grid_dims_(+Grid, -Rows, -Cols): measure grid dimensions.
fill_grid_dims_(Grid, Rows, Cols) :-
    % Count rows.
    length(Grid, Rows),
    % Count columns from the first row.
    ( Rows > 0 -> Grid = [R1|_], length(R1, Cols) ; Cols = 0 ).

% fill_set_nth0_(+Idx, +List, +Val, -NewList): replace element at index Idx with Val.
fill_set_nth0_(0, [_|T], V, [V|T]) :- !.
fill_set_nth0_(N, [H|T], V, [H|T2]) :-
    % Recurse with decremented index.
    N > 0, N1 is N - 1,
    fill_set_nth0_(N1, T, V, T2).

% fill_fill_cell_(+R, +C, +Color, +Grid, -Result): set one cell to Color.
fill_fill_cell_(R, C, Color, Grid, Result) :-
    % Extract the target row.
    nth0(R, Grid, Row),
    % Update the column within that row.
    fill_set_nth0_(C, Row, Color, NewRow),
    % Replace the row in the grid.
    fill_set_nth0_(R, Grid, NewRow, Result).

% fill_in_region_(+Cell, +Region): test cell membership.
fill_in_region_(Cell, Region) :- member(Cell, Region).

% fill_fill_row_cell_(+TargetR, +Color, +R, +OldV, -NewV): fill cell if in target row.
fill_fill_row_cell_(TargetR, Color, R, _Old, Color) :- R =:= TargetR, !.
fill_fill_row_cell_(_TargetR, _Color, _R, Old, Old).

% fill_fill_region_cell_(+Region, +Color, +R, +C, +Old, -New): fill if in region.
fill_fill_region_cell_(Region, Color, R, C, _Old, Color) :-
    member(r(R,C), Region), !.
fill_fill_region_cell_(_Region, _Color, _R, _C, Old, Old).

% fill_fill_region_row_(+Region, +Color, +ColIds, +R, +OldRow, -NewRow): fill row cells.
fill_fill_region_row_(Region, Color, ColIds, R, OldRow, NewRow) :-
    maplist(fill_fill_region_cell_(Region, Color, R), ColIds, OldRow, NewRow).

% fill_fill_region(+Grid, +Region, +Color, -Result): fill all Region cells with Color.
fill_fill_region(Grid, Region, Color, Result) :-
    % Get grid dimensions.
    fill_grid_dims_(Grid, Rows, Cols),
    % Build index lists.
    ( Rows > 0 -> Rows1 is Rows - 1, numlist(0, Rows1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> Cols1 is Cols - 1, numlist(0, Cols1, ColIds) ; ColIds = [] ),
    % Fill each row.
    maplist(fill_fill_region_row_(Region, Color, ColIds), RowIds, Grid, Result).

% fill_fill_bbox_cell_(+R1,+C1,+R2,+C2,+Color,+R,+C,+Old,-New): fill if in bbox.
fill_fill_bbox_cell_(R1,C1,R2,C2, Color, R, C, _Old, Color) :-
    R >= R1, R =< R2, C >= C1, C =< C2, !.
fill_fill_bbox_cell_(_,_,_,_, _Color, _R, _C, Old, Old).

% fill_fill_bbox_row_(+R1,+C1,+R2,+C2,+Color,+ColIds,+R,+OldRow,-NewRow).
fill_fill_bbox_row_(R1,C1,R2,C2, Color, ColIds, R, OldRow, NewRow) :-
    maplist(fill_fill_bbox_cell_(R1,C1,R2,C2, Color, R), ColIds, OldRow, NewRow).

% fill_fill_bbox(+Grid, +bbox(R1,C1,R2,C2), +Color, -Result): fill bbox cells.
fill_fill_bbox(Grid, bbox(R1,C1,R2,C2), Color, Result) :-
    % Get grid dimensions.
    fill_grid_dims_(Grid, Rows, Cols),
    ( Rows > 0 -> Rows1 is Rows - 1, numlist(0, Rows1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> Cols1 is Cols - 1, numlist(0, Cols1, ColIds) ; ColIds = [] ),
    % Fill each row using bbox membership test.
    maplist(fill_fill_bbox_row_(R1,C1,R2,C2, Color, ColIds), RowIds, Grid, Result).

% fill_fill_row_idx_(+TargetR, +Color, +R, +Row, -NewRow): replace full row if matches.
fill_fill_row_idx_(TargetR, Color, R, Row, NewRow) :-
    % Replace entire row when R = TargetR.
    ( R =:= TargetR
    -> length(Row, Len), length(NewRow, Len), maplist(=(Color), NewRow)
    ;  NewRow = Row ).

% fill_fill_row(+Grid, +R, +Color, -Result): fill entire row R with Color.
fill_fill_row(Grid, R, Color, Result) :-
    % Build row indices.
    fill_grid_dims_(Grid, Rows, _),
    Rows1 is Rows - 1, numlist(0, Rows1, RowIds),
    maplist(fill_fill_row_idx_(R, Color), RowIds, Grid, Result).

% fill_fill_col_in_row_(+C, +Color, +Row, -NewRow): replace cell at column C.
fill_fill_col_in_row_(C, Color, Row, NewRow) :-
    fill_set_nth0_(C, Row, Color, NewRow).

% fill_fill_col(+Grid, +C, +Color, -Result): fill entire column C with Color.
fill_fill_col(Grid, C, Color, Result) :-
    maplist(fill_fill_col_in_row_(C, Color), Grid, Result).

% fill_fill_cells(+Grid, +Cells, +Color, -Result): fill specific r(R,C) cells.
fill_fill_cells(Grid, Cells, Color, Result) :-
    % Delegate to fill_fill_region since Cells is a list of r(R,C).
    fill_fill_region(Grid, Cells, Color, Result).

% fill_fill_border(+Grid, +Color, -Result): fill the four outermost rows/cols.
fill_fill_border(Grid, Color, Result) :-
    % Get max row and column indices.
    fill_grid_dims_(Grid, Rows, Cols),
    MaxR is Rows - 1, MaxC is Cols - 1,
    % Fill each border edge sequentially.
    fill_fill_row(Grid, 0, Color, G1),
    fill_fill_row(G1, MaxR, Color, G2),
    fill_fill_col(G2, 0, Color, G3),
    fill_fill_col(G3, MaxC, Color, Result).

% fill_neighbor4_(+Cell, -Neighbor): one 4-connected neighbor.
fill_neighbor4_(r(R,C), r(N,C)) :- N is R - 1.
fill_neighbor4_(r(R,C), r(N,C)) :- N is R + 1.
fill_neighbor4_(r(R,C), r(R,N)) :- N is C - 1.
fill_neighbor4_(r(R,C), r(R,N)) :- N is C + 1.

% fill_all_neighbors_in_(+Cell, +Region): all 4 neighbors of Cell are in Region.
fill_all_neighbors_in_(Cell, Region) :-
    % Fail if any neighbor is not in the region.
    \+ (fill_neighbor4_(Cell, Nb), \+ member(Nb, Region)).

% fill_outline_region(+Grid, +Region, +Color, -Result): fill border cells of Region.
fill_outline_region(Grid, Region, Color, Result) :-
    % Collect cells with at least one non-region neighbor.
    findall(Cell,
        (member(Cell, Region), \+ fill_all_neighbors_in_(Cell, Region)),
        Border),
    % Fill those cells with Color.
    fill_fill_cells(Grid, Border, Color, Result).

% fill_fill_interior(+Grid, +Region, +Color, -Result): fill interior cells of Region.
fill_fill_interior(Grid, Region, Color, Result) :-
    % Collect cells whose 4 neighbors are all inside the region.
    findall(Cell,
        (member(Cell, Region), fill_all_neighbors_in_(Cell, Region)),
        Interior),
    % Fill those cells with Color.
    fill_fill_cells(Grid, Interior, Color, Result).

% fill_solid_rect(+Rows, +Cols, +Color, -Grid): new grid filled uniformly with Color.
fill_solid_rect(Rows, Cols, Color, Grid) :-
    % Create one row of Cols copies of Color.
    length(Row, Cols), maplist(=(Color), Row),
    % Repeat that row Rows times.
    length(Grid, Rows), maplist(=(Row), Grid).

% fill_checker_cell_(+C1, +C2, +R, +C, -V): alternate colors based on (R+C) parity.
fill_checker_cell_(C1, C2, R, C, V) :-
    ( (R + C) mod 2 =:= 0 -> V = C1 ; V = C2 ).

% fill_checker_row_(+C1, +C2, +Cols, +RowIdx, -Row): one checkerboard row.
fill_checker_row_(C1, C2, Cols, R, Row) :-
    % Build column index list.
    Cols1 is Cols - 1, numlist(0, Cols1, ColIds),
    % Map each column to its checkerboard color.
    maplist(fill_checker_cell_(C1, C2, R), ColIds, Row).

% fill_checkerboard(+Rows, +Cols, +C1, +C2, -Grid): new checkerboard grid.
fill_checkerboard(Rows, Cols, C1, C2, Grid) :-
    % Build row index list.
    Rows > 0, Cols > 0,
    Rows1 is Rows - 1, numlist(0, Rows1, RowIds),
    % Build each row.
    maplist(fill_checker_row_(C1, C2, Cols), RowIds, Grid).

% fill_draw_hline(+Grid, +R, +C1, +C2, +Color, -Result): horizontal line segment.
fill_draw_hline(Grid, R, C1, C2, Color, Result) :-
    % Delegate to bbox fill on a single row range.
    fill_fill_bbox(Grid, bbox(R,C1,R,C2), Color, Result).

% fill_draw_vline(+Grid, +C, +R1, +R2, +Color, -Result): vertical line segment.
fill_draw_vline(Grid, C, R1, R2, Color, Result) :-
    % Delegate to bbox fill on a single column range.
    fill_fill_bbox(Grid, bbox(R1,C,R2,C), Color, Result).

% fill_diag_cells_(+Rows, -DiagCells): collect r(I,I) cells for 0 <= I < Rows.
fill_diag_cells_(Rows, DiagCells) :-
    % Build indices.
    Rows1 is Rows - 1, numlist(0, Rows1, Ids),
    % Map each index to its diagonal cell.
    maplist([I, r(I,I)]>>(true), Ids, DiagCells).

% fill_fill_main_diag(+Grid, +Color, -Result): fill cells where row index = col index.
fill_fill_main_diag(Grid, Color, Result) :-
    % Collect the diagonal cell coordinates.
    fill_grid_dims_(Grid, Rows, _),
    fill_diag_cells_(Rows, DiagCells),
    % Fill those cells.
    fill_fill_cells(Grid, DiagCells, Color, Result).

% fill_stamp_cell_(+Stamp, +SR, +SC, +BG, +R, +C, +BaseV, -ResultV):
%   overlay Stamp cell if within bounds and non-transparent.
fill_stamp_cell_(Stamp, SR, SC, BG, R, C, BaseV, ResultV) :-
    % Compute position within the stamp.
    StampR is R - SR, StampC is C - SC,
    % Get stamp dimensions.
    length(Stamp, SH),
    ( Stamp = [SR0|_] -> length(SR0, SW) ; SW = 0 ),
    % Use stamp value if in bounds and not BG; else keep base.
    ( StampR >= 0, StampR < SH, StampC >= 0, StampC < SW
    -> nth0(StampR, Stamp, StampRow), nth0(StampC, StampRow, StampV),
       ( StampV \= BG -> ResultV = StampV ; ResultV = BaseV )
    ;  ResultV = BaseV ).

% fill_stamp_row_(+Stamp, +SR, +SC, +BG, +ColIds, +R, +BaseRow, -ResultRow).
fill_stamp_row_(Stamp, SR, SC, BG, ColIds, R, BaseRow, ResultRow) :-
    maplist(fill_stamp_cell_(Stamp, SR, SC, BG, R), ColIds, BaseRow, ResultRow).

% fill_stamp(+Base, +Stamp, +SR, +SC, +BG, -Result):
%   overlay Stamp at row SR, col SC; Stamp cells equal to BG are transparent.
fill_stamp(Base, Stamp, SR, SC, BG, Result) :-
    % Get base grid dimensions.
    fill_grid_dims_(Base, Rows, Cols),
    ( Rows > 0 -> Rows1 is Rows - 1, numlist(0, Rows1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> Cols1 is Cols - 1, numlist(0, Cols1, ColIds) ; ColIds = [] ),
    % Process each row of the base grid.
    maplist(fill_stamp_row_(Stamp, SR, SC, BG, ColIds), RowIds, Base, Result).
