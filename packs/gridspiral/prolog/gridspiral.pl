:- module(gridspiral, [
    gsp_spiral/2,
    gsp_read_spiral/2,
    gsp_write_spiral/3,
    gsp_spiral_length/2,
    gsp_spiral_index/4,
    gsp_nth_spiral/4,
    gsp_frame_spiral/3,
    gsp_all_frame_spirals/2,
    gsp_spiral_uniform/2,
    gsp_spiral_reversed/2,
    gsp_spiral_count/3,
    gsp_fill_spiral/3,
    gsp_rotate_spiral/3,
    gsp_spiral_slice/4
]).
% gridspiral.pl - Layer 217: Grid Spiral Traversal (gsp_* prefix).
% Provides clockwise spiral cell ordering: starting at top-left, traversing
% right, down, left, up, then repeating for inner frames.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
:- use_module(library(lists), [
    nth0/3, member/2, append/3, reverse/2
]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
gsp_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed).
gsp_cell_(Grid, R, C, V) :-
% Select row R.
    nth0(R, Grid, Row),
% Select column C.
    nth0(C, Row, V).

% Build a new H x W grid using a lambda Goal(R, C, V).
gsp_build_(H, W, Goal, Grid) :-
% Compute last indices.
    H1 is H - 1, W1 is W - 1,
% Collect rows.
    findall(Row,
        (between(0, H1, R),
         findall(V, (between(0, W1, C), call(Goal, R, C, V)), Row)),
        Grid).

% Maximum frame depth for H x W grid.
gsp_max_depth_(H, W, D) :-
    D is (min(H, W) - 1) // 2.

% Clockwise spiral cells for frame D (rows [D..H-1-D], cols [D..W-1-D]).
% Returns R-C pairs in clockwise order: top row, right col, bottom row, left col.
gsp_frame_spiral_(H, W, D, Cells) :-
    RowMin is D,
    RowMax is H - 1 - D,
    ColMin is D,
    ColMax is W - 1 - D,
% Frame must be non-empty.
    RowMin =< RowMax,
    ColMin =< ColMax,
% Top row: left to right.
    findall(RowMin-C, between(ColMin, ColMax, C), Top),
% Right column: top+1 down to bottom.
    RM1 is RowMin + 1,
    (RowMax >= RM1 ->
        findall(R-ColMax, between(RM1, RowMax, R), Right)
    ;   Right = []),
% Bottom row: right-1 down to left (reversed to go left).
    CM1 is ColMax - 1,
    (RowMax > RowMin, CM1 >= ColMin ->
        findall(RowMax-C, between(ColMin, CM1, C), BotFwd),
        reverse(BotFwd, Bot)
    ;   Bot = []),
% Left column: bottom-1 up to top+1 (reversed to go up).
    RM2 is RowMax - 1,
    (RowMax > RowMin, ColMax > ColMin, RM2 >= RM1 ->
        findall(R-ColMin, between(RM1, RM2, R), LeftFwd),
        reverse(LeftFwd, Left)
    ;   Left = []),
% Concatenate all segments.
    append([Top, Right, Bot, Left], Cells).

% Full spiral: concatenate per-frame spirals from depth 0 to max_depth.
gsp_full_spiral_(H, W, Cells) :-
    gsp_max_depth_(H, W, MaxD),
    findall(FrameCells,
        (between(0, MaxD, D),
         gsp_frame_spiral_(H, W, D, FrameCells)),
        Frames),
    append(Frames, Cells).

% --- PUBLIC PREDICATES ---

% gsp_spiral(+Grid, -Cells)
% Cells is the list of R-C pairs in clockwise spiral order, outer to inner.
% Traversal: top row left-to-right, right col top-to-bottom, bottom row
% right-to-left, left col bottom-to-top, then inner frame, and so on.
gsp_spiral(Grid, Cells) :-
% Get dimensions.
    gsp_dims_(Grid, H, W),
% Compute full spiral.
    gsp_full_spiral_(H, W, Cells).

% gsp_read_spiral(+Grid, -Vals)
% Vals is the list of color values read in spiral order.
gsp_read_spiral(Grid, Vals) :-
% Get spiral cell order.
    gsp_spiral(Grid, Cells),
% Read each cell value.
    findall(V, (member(R-C, Cells), gsp_cell_(Grid, R, C, V)), Vals).

% gsp_write_spiral(+Grid, +Vals, -Result)
% Result is Grid with cells overwritten in spiral order by the values in Vals.
% If Vals is shorter than the spiral, remaining cells are unchanged.
gsp_write_spiral(Grid, Vals, Result) :-
% Get spiral ordering.
    gsp_spiral(Grid, Cells),
% Get dimensions.
    gsp_dims_(Grid, H, W),
% Build result: for each cell find its spiral index, fill if Vals has that index.
    gsp_build_(H, W,
        [R, C, V]>>(gsp_cell_(Grid, R, C, Orig),
                    (nth0(Idx, Cells, R-C),
                     nth0(Idx, Vals, NewV) ->
                        V = NewV
                    ;   V = Orig)),
        Result).

% gsp_spiral_length(+Grid, -Len)
% Len is the total number of cells in the spiral (equals H * W).
gsp_spiral_length(Grid, Len) :-
    gsp_dims_(Grid, H, W),
    Len is H * W.

% gsp_spiral_index(+Grid, +R, +C, -Idx)
% Idx is the 0-based position of cell (R,C) in the spiral.
gsp_spiral_index(Grid, R, C, Idx) :-
% Get full spiral.
    gsp_spiral(Grid, Cells),
% Find position of R-C in the list.
    nth0(Idx, Cells, R-C).

% gsp_nth_spiral(+Grid, +N, -R, -C)
% R-C is the cell at 0-based position N in the spiral.
gsp_nth_spiral(Grid, N, R, C) :-
    gsp_spiral(Grid, Cells),
    nth0(N, Cells, R-C).

% gsp_frame_spiral(+Grid, +D, -Cells)
% Cells is the list of R-C pairs in the clockwise spiral for frame D only.
gsp_frame_spiral(Grid, D, Cells) :-
    gsp_dims_(Grid, H, W),
    gsp_frame_spiral_(H, W, D, Cells).

% gsp_all_frame_spirals(+Grid, -Spirals)
% Spirals is the list of frame-spiral cell-lists, ordered from D=0 to max_depth.
gsp_all_frame_spirals(Grid, Spirals) :-
    gsp_dims_(Grid, H, W),
    gsp_max_depth_(H, W, MaxD),
    findall(Cells, (between(0, MaxD, D), gsp_frame_spiral_(H, W, D, Cells)), Spirals).

% gsp_spiral_uniform(+Grid, -Bool)
% Bool is yes if all cells in the grid have the same color; no otherwise.
% (Tests uniformity by reading the spiral and checking all values equal.)
gsp_spiral_uniform(Grid, Bool) :-
    gsp_read_spiral(Grid, Vals),
    Vals \= [],
    (Vals = [H|T], \+ (member(V, T), V \= H) -> Bool = yes ; Bool = no).

% gsp_spiral_reversed(+Grid, -Cells)
% Cells is the list of R-C pairs in reverse spiral order (inner to outer).
gsp_spiral_reversed(Grid, Rev) :-
    gsp_spiral(Grid, Cells),
    reverse(Cells, Rev).

% gsp_spiral_count(+Grid, +Color, -Count)
% Count is the number of cells of Color in the grid (order-independent).
gsp_spiral_count(Grid, Color, Count) :-
    gsp_read_spiral(Grid, Vals),
    findall(1, member(Color, Vals), Ones),
    length(Ones, Count).

% gsp_fill_spiral(+Grid, +Vals, -Result)
% Result is a new grid with cells filled in spiral order from Vals.
% Cells beyond length(Vals) retain their original color.
% Alias for gsp_write_spiral/3.
gsp_fill_spiral(Grid, Vals, Result) :-
    gsp_write_spiral(Grid, Vals, Result).

% gsp_rotate_spiral(+Grid, +N, -Result)
% Result is Grid with all cell values rotated N steps forward along the spiral.
% The value at position I in the spiral moves to position (I+N) mod (H*W).
gsp_rotate_spiral(Grid, N, Result) :-
% Read all values in spiral order.
    gsp_read_spiral(Grid, Vals),
    length(Vals, Len),
% Normalize N to [0, Len).
    (Len > 0 -> Shift is N mod Len ; Shift = 0),
% Split Vals at Shift position.
    length(Head, Shift),
    append(Head, Tail, Vals),
% Rotated order: Tail then Head.
    append(Tail, Head, Rotated),
% Write rotated values back in spiral order.
    gsp_write_spiral(Grid, Rotated, Result).

% gsp_spiral_slice(+Grid, +Start, +End, -Cells)
% Cells is the sublist of spiral cells from 0-based index Start to End inclusive.
gsp_spiral_slice(Grid, Start, End, Slice) :-
    gsp_spiral(Grid, Cells),
% Collect cells in [Start, End] range.
    findall(RC, (nth0(I, Cells, RC), I >= Start, I =< End), Slice).
