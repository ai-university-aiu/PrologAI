% Module crop: subgrid extraction, padding, splitting, stitching, and embedding.
% Layer 49. Prefix: cr_. Requires: grid.
:- module(crop, [
    % Bounding box of all cells that differ from a background color.
    cr_bbox/3,
    % Extract a rectangular subgrid by inclusive row/col bounds.
    cr_crop_bbox/6,
    % Crop a grid to the tight bounding box of its non-background content.
    cr_crop_content/3,
    % Add a uniform N-cell border of a given color around a grid.
    cr_pad/4,
    % Remove N rows and columns from every side of a grid.
    cr_strip_border/3,
    % Split a grid horizontally: top has R rows, bottom has the rest.
    cr_split_h/4,
    % Split a grid vertically: left has C columns, right has the rest.
    cr_split_v/4,
    % Extract a row band: rows From (inclusive) to To (exclusive), 0-indexed.
    cr_rows/4,
    % Extract a column band: cols From (inclusive) to To (exclusive), 0-indexed.
    cr_cols/4,
    % Join two same-height grids side by side.
    cr_stitch_h/3,
    % Join two same-width grids top to bottom.
    cr_stitch_v/3,
    % Embed a subgrid into a base grid at a given row/col offset.
    cr_embed/5,
    % Extract the centered Rows x Cols subgrid from a larger grid.
    cr_center/4,
    % Split a grid into four quadrants at the midpoint row and column.
    cr_quadrants/5
]).

% Load list utilities.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/2, append/3,
                                last/2, reverse/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% cr_grid_dims_(+Grid, -Rows, -Cols)
% Number of rows and columns in Grid.
cr_grid_dims_(Grid, Rows, Cols) :-
    length(Grid, Rows),
    (Rows =:= 0 -> Cols = 0 ; Grid = [First|_], length(First, Cols)).

% cr_row_(+Grid, +R, -Row)
% Row R (0-indexed) of Grid.
cr_row_(Grid, R, Row) :- nth0(R, Grid, Row).

% cr_col_val_(+Row, +C, -Val)
% Value at column C in a single row.
cr_col_val_(Row, C, Val) :- nth0(C, Row, Val).

% cr_bbox(+Grid, +BG, -Box)
% Box = bbox(MinR, MinC, MaxR, MaxC) is the tight bounding box of all cells
% in Grid whose value differs from BG. Fails if every cell equals BG.
cr_bbox(Grid, BG, bbox(MinR, MinC, MaxR, MaxC)) :-
    Grid = [_|_],
    cr_grid_dims_(Grid, Rows, Cols),
    Rows > 0, Cols > 0,
    Rows1 is Rows - 1, Cols1 is Cols - 1,
    numlist(0, Rows1, RowIds), numlist(0, Cols1, ColIds),
    findall(R-C,
        (member(R, RowIds), member(C, ColIds),
         nth0(R, Grid, Row), nth0(C, Row, V), V \= BG),
        Cells),
    Cells = [_|_],
    pairs_keys(Cells, Rs),
    pairs_values(Cells, Cs),
    min_list(Rs, MinR), max_list(Rs, MaxR),
    min_list(Cs, MinC), max_list(Cs, MaxC).

% cr_crop_bbox(+Grid, +R1, +C1, +R2, +C2, -Sub)
% Sub is the rectangular subgrid with rows R1..R2 and columns C1..C2 inclusive,
% all 0-indexed.
cr_crop_bbox(Grid, R1, C1, R2, C2, Sub) :-
    R1 >= 0, C1 >= 0, R2 >= R1, C2 >= C1,
    Len is R2 - R1 + 1,
    numlist(R1, R2, RowIds),
    length(RowIds, Len),
    maplist(cr_crop_row_(Grid, C1, C2), RowIds, Sub).

% cr_crop_row_(+Grid, +C1, +C2, +R, -Row)
% Extract columns C1..C2 from row R of Grid.
cr_crop_row_(Grid, C1, C2, R, Row) :-
    nth0(R, Grid, FullRow),
    Len is C2 - C1 + 1,
    length(Prefix, C1),
    append(Prefix, Rest, FullRow),
    length(Row, Len),
    append(Row, _, Rest).

% cr_crop_content(+Grid, +BG, -Cropped)
% Cropped is Grid trimmed to the bounding box of cells that differ from BG.
cr_crop_content(Grid, BG, Cropped) :-
    cr_bbox(Grid, BG, bbox(R1, C1, R2, C2)),
    cr_crop_bbox(Grid, R1, C1, R2, C2, Cropped).

% cr_make_row_(+Color, +N, -Row)
% Row is a list of N copies of Color.
cr_make_row_(Color, N, Row) :-
    length(Row, N),
    maplist(=(Color), Row).

% cr_pad(+Grid, +Color, +N, -Padded)
% Padded adds N rows of Color above and below, and N columns of Color left
% and right of Grid.
cr_pad(Grid, Color, N, Padded) :-
    N >= 0,
    cr_grid_dims_(Grid, _Rows, Cols),
    PadCols is Cols + 2 * N,
    cr_make_row_(Color, N, PadSide),
    cr_make_row_(Color, PadCols, FullPadRow),
    length(TopRows, N), maplist(=(FullPadRow), TopRows),
    length(BotRows, N), maplist(=(FullPadRow), BotRows),
    maplist(cr_pad_row_(Color, PadSide), Grid, MidRows),
    append([TopRows, MidRows, BotRows], Padded).

% cr_pad_row_(+Color, +PadSide, +Row, -PaddedRow)
% Prepend and append PadSide to a single row.
cr_pad_row_(_Color, PadSide, Row, PaddedRow) :-
    append(PadSide, Row, Left),
    append(Left, PadSide, PaddedRow).

% cr_strip_border(+Grid, +N, -Inner)
% Inner is Grid with N rows removed from top and bottom and N columns removed
% from left and right.
cr_strip_border(Grid, N, Inner) :-
    N >= 0,
    cr_grid_dims_(Grid, Rows, Cols),
    R1 = N, R2 is Rows - N - 1,
    C1 = N, C2 is Cols - N - 1,
    R2 >= R1, C2 >= C1,
    cr_crop_bbox(Grid, R1, C1, R2, C2, Inner).

% cr_split_h(+Grid, +R, -Top, -Bottom)
% Top contains rows 0..R-1. Bottom contains rows R..end.
% R must be in 1..Rows-1.
cr_split_h(Grid, R, Top, Bottom) :-
    R > 0,
    cr_grid_dims_(Grid, Rows, _),
    R < Rows,
    length(Top, R),
    append(Top, Bottom, Grid).

% cr_split_v(+Grid, +C, -Left, -Right)
% Left contains columns 0..C-1 of every row. Right contains columns C..end.
cr_split_v(Grid, C, Left, Right) :-
    C > 0,
    Grid = [First|_], length(First, Cols), C < Cols,
    maplist(cr_split_row_(C), Grid, Left, Right).

% cr_split_row_(+C, +Row, -L, -R)
% Split a single row at column C.
cr_split_row_(C, Row, L, R) :-
    length(L, C),
    append(L, R, Row).

% cr_rows(+Grid, +From, +To, -Sub)
% Sub is rows From..To-1 (0-indexed, exclusive end). Fails if out of range.
cr_rows(Grid, From, To, Sub) :-
    From >= 0, To > From,
    cr_grid_dims_(Grid, Rows, _),
    To =< Rows,
    Len is To - From,
    length(Prefix, From),
    append(Prefix, Rest, Grid),
    length(Sub, Len),
    append(Sub, _, Rest).

% cr_cols(+Grid, +From, +To, -Sub)
% Sub is a grid containing columns From..To-1 of each row (0-indexed, exclusive end).
cr_cols(Grid, From, To, Sub) :-
    From >= 0, To > From,
    Grid = [First|_], length(First, Cols), To =< Cols,
    maplist(cr_row_cols_(From, To), Grid, Sub).

% cr_row_cols_(+From, +To, +Row, -Sub)
% Extract columns From..To-1 from a single row.
cr_row_cols_(From, To, Row, Sub) :-
    Len is To - From,
    length(Prefix, From),
    append(Prefix, Rest, Row),
    length(Sub, Len),
    append(Sub, _, Rest).

% cr_stitch_h(+Left, +Right, -Joined)
% Joined is Left and Right placed side by side. Both must have the same height.
cr_stitch_h(Left, Right, Joined) :-
    length(Left, H), length(Right, H),
    maplist(append, Left, Right, Joined).

% cr_stitch_v(+Top, +Bottom, -Joined)
% Joined is Top on top of Bottom. Both must have the same width.
cr_stitch_v(Top, Bottom, Joined) :-
    (Top = [TR|_] -> length(TR, W) ; W = 0),
    (Bottom = [BR|_] -> length(BR, W) ; true),
    append(Top, Bottom, Joined).

% cr_embed(+Base, +Sub, +R, +C, -Result)
% Result is Base with Sub embedded starting at row R, column C.
cr_embed(Base, Sub, R, C, Result) :-
    R >= 0, C >= 0,
    length(Sub, SubH),
    R2 is R + SubH - 1,
    cr_grid_dims_(Base, BaseH, _),
    R2 < BaseH,
    length(Pre, R),
    append(Pre, MidBase, Base),
    length(MidBase0, SubH),
    append(MidBase0, Suf, MidBase),
    maplist(cr_embed_row_col_(C), MidBase0, Sub, MidResult),
    append(Pre, MidResult, Temp),
    append(Temp, Suf, Result).

% cr_embed_row_col_(+C, +BaseRow, +SubRow, -ResultRow)
% Overwrite columns starting at C in BaseRow with SubRow values.
cr_embed_row_col_(C, BaseRow, SubRow, ResultRow) :-
    length(SubRow, SubW),
    length(Pre, C),
    append(Pre, Rest, BaseRow),
    length(Skip, SubW),
    append(Skip, Suf, Rest),
    append(Pre, SubRow, Temp),
    append(Temp, Suf, ResultRow).

% cr_center(+Grid, +Rows, +Cols, -Center)
% Center is the central Rows x Cols subgrid of Grid.
% Grid must have height >= Rows and width >= Cols.
cr_center(Grid, Rows, Cols, Center) :-
    cr_grid_dims_(Grid, GH, GW),
    GH >= Rows, GW >= Cols,
    R1 is (GH - Rows) // 2,
    C1 is (GW - Cols) // 2,
    R2 is R1 + Rows - 1,
    C2 is C1 + Cols - 1,
    cr_crop_bbox(Grid, R1, C1, R2, C2, Center).

% cr_quadrants(+Grid, -Q1, -Q2, -Q3, -Q4)
% Split Grid into four quadrants at the midpoint row and column.
% Q1 = top-left, Q2 = top-right, Q3 = bottom-left, Q4 = bottom-right.
% Midpoints: MidR = Rows // 2, MidC = Cols // 2.
cr_quadrants(Grid, Q1, Q2, Q3, Q4) :-
    cr_grid_dims_(Grid, Rows, Cols),
    Rows >= 2, Cols >= 2,
    MidR is Rows // 2,
    MidC is Cols // 2,
    cr_split_h(Grid, MidR, Top, Bottom),
    cr_split_v(Top, MidC, Q1, Q2),
    cr_split_v(Bottom, MidC, Q3, Q4).
