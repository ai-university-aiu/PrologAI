% Module frame: rectangular border detection, interior extraction, and frame generation.
% Layer 42. Prefix: fr_. Depends on grid pack only.
:- module(frame, [
    % Test whether a grid has a single-color rectangular border on its outer edge.
    fr_has_border/2,
    % Extract the color of the outer border of a grid.
    fr_border_color/2,
    % Extract the interior of a grid (remove the 1-cell outer border).
    fr_inner/2,
    % Add a single-color border of given thickness around a grid.
    fr_add_border/4,
    % Extract the border cells only (outer ring) as a list of r(R,C)-Color pairs.
    fr_border_cells/2,
    % Test whether a rectangular region of a grid has a uniform border.
    fr_region_has_border/6,
    % Extract the color of a rectangular sub-region's outer border.
    fr_region_border_color/6,
    % Test whether the interior of a bordered grid is uniform.
    fr_interior_uniform/1,
    % Get the interior fill color (assumes interior is uniform).
    fr_interior_color/2,
    % Build a grid that is all Color except a rectangular frame of FrameColor.
    fr_make_framed/5,
    % Extract the bounding box (R0,C0,R1,C1) of the outermost frame in a grid.
    fr_bounding_box/6,
    % Test whether the grid is a nested frame: outer frame of ColorA, inner frame of ColorB.
    fr_is_nested/3,
    % Extract the frame layer count (how many concentric uniform-color rings).
    fr_ring_count/2
]).

% Load list utilities for nth0, numlist, append, last, maplist, include.
:- use_module(library(lists), [nth0/3, numlist/3, append/2, append/3, last/2,
                                member/2]).
% Load apply utilities for maplist, include, foldl.
:- use_module(library(apply), [maplist/2, maplist/3, include/3, foldl/4]).
% Load grid pack for all gd_* operations.
:- use_module(library(grid)).

% fr_border_cells(+Grid, -Pairs)
% Collect all (r(R,C)-Color) pairs on the outer ring of Grid.
% The outer ring is row 0, row Rows-1, column 0, column Cols-1.
fr_border_cells(Grid, Pairs) :-
    % Get grid dimensions.
    gd_size(Grid, Rows, Cols),
    % Collect all (R,C) positions on the outer ring.
    fr_ring_positions_(0, 0, Rows, Cols, Positions),
    % Map each position to a r(R,C)-Color pair.
    maplist(fr_read_cell_(Grid), Positions, Pairs).

% fr_ring_positions_(R0, C0, Rows, Cols, Positions)
% All positions on the border of a Rows x Cols rectangle starting at (R0,C0).
fr_ring_positions_(R0, C0, Rows, Cols, Positions) :-
    % Compute last row and column indices.
    R1 is R0 + Rows - 1,
    C1 is C0 + Cols - 1,
    % Top row.
    numlist(C0, C1, TopCols),
    maplist(fr_pair_r_(R0), TopCols, TopRow),
    % Bottom row (only if distinct from top).
    (R1 > R0 -> numlist(C0, C1, BotCols), maplist(fr_pair_r_(R1), BotCols, BotRow) ; BotRow = []),
    % Left column (inner rows only, skip corners).
    R0i is R0 + 1, R1i is R1 - 1,
    (R1i >= R0i ->
        numlist(R0i, R1i, LeftRows),
        maplist(fr_pair_c_(C0), LeftRows, LeftCol)
    ;
        LeftCol = []
    ),
    % Right column (inner rows only, skip corners).
    (R1i >= R0i, C1 > C0 ->
        numlist(R0i, R1i, RightRows),
        maplist(fr_pair_c_(C1), RightRows, RightCol)
    ;
        RightCol = []
    ),
    % Concatenate all four sides.
    append([TopRow, BotRow, LeftCol, RightCol], Positions).

% fr_pair_r_(R, C, r(R,C)) - helper for maplist.
fr_pair_r_(R, C, r(R, C)).

% fr_pair_c_(C, R, r(R,C)) - helper for maplist.
fr_pair_c_(C, R, r(R, C)).

% fr_read_cell_(Grid, r(R,C), r(R,C)-Color) - read cell color at r(R,C).
fr_read_cell_(Grid, r(R, C), r(R, C)-Color) :-
    gd_cell(Grid, R, C, Color).

% fr_border_color(+Grid, -Color)
% The outer border of Grid is uniform and has the given Color.
fr_border_color(Grid, Color) :-
    % Collect border cell pairs.
    fr_border_cells(Grid, Pairs),
    % Pairs is non-empty.
    Pairs = [_-Color|Rest],
    % All other cells have the same Color.
    maplist(fr_same_color_(Color), Rest).

% fr_same_color_(Color, _-Color) - check that a pair has the expected color.
fr_same_color_(Color, _-Color).

% fr_has_border(+Grid, -Color)
% Succeeds (and binds Color) if the outer border of Grid is a uniform color.
fr_has_border(Grid, Color) :-
    fr_border_color(Grid, Color).

% fr_inner(+Grid, -Inner)
% Remove the single-cell outer border, yielding the interior grid.
% Fails if the grid is too small (less than 3 rows or 3 cols).
fr_inner(Grid, Inner) :-
    % Grid must be at least 3x3 to have a non-empty interior.
    gd_size(Grid, Rows, Cols),
    Rows >= 3,
    Cols >= 3,
    % Extract each interior row.
    R0 is 1,
    R1 is Rows - 2,
    C0 is 1,
    C1 is Cols - 2,
    numlist(R0, R1, InnerRows),
    numlist(C0, C1, InnerCols),
    maplist(fr_extract_row_(Grid, InnerCols), InnerRows, Inner).

% fr_extract_row_(Grid, Cols, R, Row)
% Extract a sub-row of Grid at row R for the given column indices.
fr_extract_row_(Grid, Cols, R, Row) :-
    maplist(gd_cell(Grid, R), Cols, Row).

% fr_add_border(+Grid, +Thickness, +Color, -Grid2)
% Wrap Grid with a border of given Thickness and Color.
% Each added layer increases rows and cols by 2.
fr_add_border(Grid, Thickness, Color, Grid2) :-
    % Compute new dimensions.
    gd_size(Grid, Rows, Cols),
    Rows2 is Rows + 2 * Thickness,
    Cols2 is Cols + 2 * Thickness,
    % Build a uniform grid of Color.
    gd_make(Rows2, Cols2, Color, Base),
    % Paint the interior with the original grid cells.
    fr_paint_inner_(Grid, Thickness, Thickness, Base, Grid2).

% fr_paint_inner_(Src, DR, DC, Acc, Out)
% Paint Src into Acc starting at offset (DR, DC).
fr_paint_inner_(Src, DR, DC, Acc, Out) :-
    gd_size(Src, Rows, Cols),
    numlist(0, Rows, AllRows0), last(AllRows0, _),
    R1 is Rows - 1,
    C1 is Cols - 1,
    numlist(0, R1, SrcRows),
    numlist(0, C1, SrcCols),
    fr_paint_rows_(Src, SrcRows, SrcCols, DR, DC, Acc, Out).

% fr_paint_rows_ - iterate over rows and paint each cell.
fr_paint_rows_(_Src, [], _SrcCols, _DR, _DC, Acc, Acc).
fr_paint_rows_(Src, [R|Rs], SrcCols, DR, DC, Acc, Out) :-
    DestR is R + DR,
    fr_paint_row_cells_(Src, R, SrcCols, DC, DestR, Acc, Acc2),
    fr_paint_rows_(Src, Rs, SrcCols, DR, DC, Acc2, Out).

% fr_paint_row_cells_ - iterate over columns in a row.
fr_paint_row_cells_(_Src, _R, [], _DC, _DestR, Acc, Acc).
fr_paint_row_cells_(Src, R, [C|Cs], DC, DestR, Acc, Out) :-
    gd_cell(Src, R, C, Color),
    DestC is C + DC,
    gd_set_cell(Acc, DestR, DestC, Color, Acc2),
    fr_paint_row_cells_(Src, R, Cs, DC, DestR, Acc2, Out).

% fr_region_has_border(+Grid, +R0, +C0, +R1, +C1, -Color)
% The outer ring of the sub-rectangle (R0,C0)-(R1,C1) in Grid is uniform Color.
fr_region_has_border(Grid, R0, C0, R1, C1, Color) :-
    Rows is R1 - R0 + 1,
    Cols is C1 - C0 + 1,
    fr_ring_positions_(R0, C0, Rows, Cols, Positions),
    Positions = [First|Rest],
    gd_cell(Grid, First, Color),
    maplist(fr_region_cell_color_(Grid, Color), Rest).

% fr_region_cell_color_(Grid, Color, r(R,C)) - check cell color in region.
fr_region_cell_color_(Grid, Color, r(R, C)) :-
    gd_cell(Grid, R, C, Color).

% gd_cell/3 overload: accept r(R,C) term.
gd_cell(Grid, r(R, C), Color) :-
    gd_cell(Grid, R, C, Color).

% fr_region_border_color(+Grid, +R0, +C0, +R1, +C1, -Color)
% Color of the uniform outer ring of sub-rectangle (R0,C0)-(R1,C1).
fr_region_border_color(Grid, R0, C0, R1, C1, Color) :-
    fr_region_has_border(Grid, R0, C0, R1, C1, Color).

% fr_interior_uniform(+Grid)
% Succeeds if the interior of Grid (after removing the outer border) is all one color.
fr_interior_uniform(Grid) :-
    fr_inner(Grid, Inner),
    fr_grid_uniform_(Inner, _Color).

% fr_grid_uniform_(Grid, Color)
% Succeeds if every cell in Grid has the same Color.
fr_grid_uniform_(Grid, Color) :-
    gd_size(Grid, _Rows, Cols),
    C1 is Cols - 1,
    numlist(0, C1, Cs),
    Grid = [FirstRow|_],
    nth0(0, FirstRow, Color),
    maplist(fr_row_uniform_(Cs, Color), Grid).

% fr_row_uniform_(Cols, Color, Row) - all cells in Row equal Color.
fr_row_uniform_(Cols, Color, Row) :-
    maplist(fr_cell_eq_(Row), Cols, Colors),
    maplist(=(Color), Colors).

% fr_cell_eq_(Row, C, V) - get value at column C in Row.
fr_cell_eq_(Row, C, V) :-
    nth0(C, Row, V).

% fr_interior_color(+Grid, -Color)
% The interior of Grid is uniform; Color is that uniform color.
fr_interior_color(Grid, Color) :-
    fr_inner(Grid, Inner),
    fr_grid_uniform_(Inner, Color).

% fr_make_framed(+Rows, +Cols, +FrameColor, +FillColor, -Grid)
% Build a Rows x Cols grid: outer border of FrameColor, interior of FillColor.
fr_make_framed(Rows, Cols, FrameColor, FillColor, Grid) :-
    % Fill entire grid with FrameColor.
    gd_make(Rows, Cols, FrameColor, Base),
    % Fill interior with FillColor.
    InnerR0 is 1,
    InnerR1 is Rows - 2,
    InnerC0 is 1,
    InnerC1 is Cols - 2,
    (InnerR1 >= InnerR0, InnerC1 >= InnerC0 ->
        fr_fill_rect_(Base, InnerR0, InnerC0, InnerR1, InnerC1, FillColor, Grid)
    ;
        Grid = Base
    ).

% fr_fill_rect_(Grid, R0, C0, R1, C1, Color, Grid2)
% Fill the rectangle (R0,C0)-(R1,C1) with Color.
fr_fill_rect_(Grid, R0, C0, R1, C1, Color, Grid2) :-
    numlist(R0, R1, Rows),
    numlist(C0, C1, Cols),
    fr_fill_rows_(Grid, Rows, Cols, Color, Grid2).

% fr_fill_rows_ - paint each row in the rectangle.
fr_fill_rows_(Grid, [], _Cols, _Color, Grid).
fr_fill_rows_(Grid, [R|Rs], Cols, Color, Out) :-
    fr_fill_cols_(Grid, R, Cols, Color, Grid2),
    fr_fill_rows_(Grid2, Rs, Cols, Color, Out).

% fr_fill_cols_ - paint each column in a row.
fr_fill_cols_(Grid, _R, [], _Color, Grid).
fr_fill_cols_(Grid, R, [C|Cs], Color, Out) :-
    gd_set_cell(Grid, R, C, Color, Grid2),
    fr_fill_cols_(Grid2, R, Cs, Color, Out).

% fr_bounding_box(+Grid, +FrameColor, -R0, -C0, -R1, -C1)
% Find the bounding box of the outermost connected ring of FrameColor.
% R0,C0 = top-left corner; R1,C1 = bottom-right corner.
% Uses the rule: find the smallest rectangle whose outer ring is all FrameColor.
fr_bounding_box(Grid, FrameColor, R0, C0, R1, C1) :-
    gd_size(Grid, Rows, Cols),
    MaxR is Rows - 1,
    MaxC is Cols - 1,
    fr_find_bounding_box_(Grid, FrameColor, 0, MaxR, 0, MaxC, R0, R1, C0, C1).

% fr_find_bounding_box_ - shrink from outer edges until we find a uniform-color ring.
fr_find_bounding_box_(Grid, Color, R0, R1, C0, C1, FR0, FR1, FC0, FC1) :-
    fr_region_has_border(Grid, R0, C0, R1, C1, Color),
    FR0 = R0, FR1 = R1, FC0 = C0, FC1 = C1.
fr_find_bounding_box_(Grid, Color, R0, R1, C0, C1, FR0, FR1, FC0, FC1) :-
    % Shrink by 1 from each side.
    R0a is R0 + 1,
    R1a is R1 - 1,
    C0a is C0 + 1,
    C1a is C1 - 1,
    R0a =< R1a,
    C0a =< C1a,
    fr_find_bounding_box_(Grid, Color, R0a, R1a, C0a, C1a, FR0, FR1, FC0, FC1).

% fr_is_nested(+Grid, -ColorA, -ColorB)
% Grid has two concentric rings: outer ring of ColorA, next ring of ColorB.
fr_is_nested(Grid, ColorA, ColorB) :-
    % Outer ring must be uniform.
    fr_border_color(Grid, ColorA),
    % Interior must exist.
    fr_inner(Grid, Inner),
    % Inner grid must also have a uniform border.
    fr_border_color(Inner, ColorB),
    % The two colors must be different.
    ColorA \= ColorB.

% fr_ring_count(+Grid, -N)
% Count how many concentric rings of uniform color surround the core.
% N = 0 means the entire grid is uniform (no border distinction possible).
fr_ring_count(Grid, N) :-
    fr_ring_count_(Grid, 0, N).

% fr_ring_count_(Grid, Acc, N) - recursive helper.
% A ring is counted only when it has a proper interior (fr_inner succeeds).
fr_ring_count_(Grid, Acc, N) :-
    gd_size(Grid, Rows, Cols),
    (Rows < 3 ; Cols < 3),
    !,
    N = Acc.
fr_ring_count_(Grid, Acc, N) :-
    (   fr_border_color(Grid, _Color),
        fr_inner(Grid, Inner)
    ->
        Acc2 is Acc + 1,
        fr_ring_count_(Inner, Acc2, N)
    ;
        N = Acc
    ).
