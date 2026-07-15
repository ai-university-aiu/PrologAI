:- module(gridcrop, [
    gridcrop_bbox/3,
    gridcrop_crop_bbox/3,
    gridcrop_trim/3,
    gridcrop_trim_rows/3,
    gridcrop_trim_cols/3,
    gridcrop_crop/6,
    gridcrop_pad_to/5,
    gridcrop_center_in/5,
    gridcrop_add_border/4,
    gridcrop_remove_border/4,
    gridcrop_expand_down/4,
    gridcrop_expand_right/4,
    gridcrop_content_h/3,
    gridcrop_content_w/3
]).
% gridcrop.pl - Layer 226: Grid Cropping and Padding (gcr_* prefix).
% Fourteen predicates for resizing grids by cropping, trimming, padding, centering,
% and expanding. All operations are non-destructive.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% Bounding box: smallest R0-C0-R1-C1 rectangle enclosing all non-BgColor cells.
% No cross-pack dependencies.
:- use_module(library(lists), [nth0/3, member/2, append/2, append/3,
                                min_list/2, max_list/2]).

% --- PRIVATE HELPERS ---

% Grid dimensions.
gridcrop_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row; zero if empty.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Extract sub-grid rows R0..R1, columns C0..C1.
gridcrop_crop_(Grid, R0, C0, R1, C1, Cropped) :-
% Build each row in the rectangle.
    findall(CroppedRow,
% Iterate target rows.
        (between(R0, R1, R), nth0(R, Grid, Row),
% Collect cells from C0 to C1.
         findall(V, (between(C0, C1, C), nth0(C, Row, V)), CroppedRow)),
        Cropped).

% --- PUBLIC PREDICATES ---

% gridcrop_bbox(+Grid, +BgColor, -Box)
% Box = R0-C0-R1-C1: smallest rectangle enclosing all non-BgColor cells.
% Fails if every cell equals BgColor.
gridcrop_bbox(Grid, BgColor, R0-C0-R1-C1) :-
% Get grid dimensions.
    gridcrop_dims_(Grid, H, W),
% Loop bounds.
    H1 is H - 1, W1 is W - 1,
% Collect all non-background R-C pairs.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         nth0(R, Grid, GRow), nth0(C, GRow, V), V \= BgColor),
        Cells),
% Fail gracefully on all-background grid.
    Cells \= [],
% Separate rows and columns.
    findall(R, member(R-_, Cells), Rs),
    findall(C, member(_-C, Cells), Cs),
% Compute extremes.
    min_list(Rs, R0), max_list(Rs, R1),
    min_list(Cs, C0), max_list(Cs, C1).

% gridcrop_crop_bbox(+Grid, +BgColor, -Cropped)
% Cropped is Grid trimmed to the bounding box of non-BgColor cells.
gridcrop_crop_bbox(Grid, BgColor, Cropped) :-
% Find bounding box.
    gridcrop_bbox(Grid, BgColor, R0-C0-R1-C1),
% Crop to that rectangle.
    gridcrop_crop_(Grid, R0, C0, R1, C1, Cropped).

% gridcrop_trim(+Grid, +BgColor, -Trimmed)
% Trimmed is Grid with all outer uniform-BgColor rows and columns removed.
% Equivalent to gridcrop_crop_bbox/3.
gridcrop_trim(Grid, BgColor, Trimmed) :-
% Bounding box gives the trim region.
    gridcrop_bbox(Grid, BgColor, R0-C0-R1-C1),
% Crop to content region.
    gridcrop_crop_(Grid, R0, C0, R1, C1, Trimmed).

% gridcrop_trim_rows(+Grid, +BgColor, -Trimmed)
% Trimmed is Grid with leading and trailing uniform-BgColor rows removed.
% Column count is unchanged.
gridcrop_trim_rows(Grid, BgColor, Trimmed) :-
% Row bounds from bounding box.
    gridcrop_bbox(Grid, BgColor, R0-_-R1-_),
% Keep full column range.
    gridcrop_dims_(Grid, _, W), W1 is W - 1,
% Crop to trimmed row range.
    gridcrop_crop_(Grid, R0, 0, R1, W1, Trimmed).

% gridcrop_trim_cols(+Grid, +BgColor, -Trimmed)
% Trimmed is Grid with leading and trailing uniform-BgColor columns removed.
% Row count is unchanged.
gridcrop_trim_cols(Grid, BgColor, Trimmed) :-
% Column bounds from bounding box.
    gridcrop_bbox(Grid, BgColor, _-C0-_-C1),
% Keep full row range.
    gridcrop_dims_(Grid, H, _), H1 is H - 1,
% Crop to trimmed column range.
    gridcrop_crop_(Grid, 0, C0, H1, C1, Trimmed).

% gridcrop_crop(+Grid, +R0, +C0, +R1, +C1, -Cropped)
% Cropped is the sub-grid at rows R0..R1 and columns C0..C1 (0-indexed, inclusive).
gridcrop_crop(Grid, R0, C0, R1, C1, Cropped) :-
% Delegate to private helper.
    gridcrop_crop_(Grid, R0, C0, R1, C1, Cropped).

% gridcrop_pad_to(+Grid, +BgColor, +TargetH, +TargetW, -Padded)
% Padded is Grid extended with BgColor to reach at least TargetH rows and TargetW
% columns. Extra rows appear at the bottom; extra columns appear on the right.
% Dimensions already meeting the target are not changed.
gridcrop_pad_to(Grid, BgColor, TargetH, TargetW, Padded) :-
% Current size.
    gridcrop_dims_(Grid, H, W),
% How many cells to add per row and how many rows to add.
    AddW is max(0, TargetW - W),
    AddH is max(0, TargetH - H),
% Build the right-side padding list.
    findall(BgColor, between(1, AddW, _), ExtraRight),
% Extend each existing row.
    findall(PaddedRow,
        (member(Row, Grid), append(Row, ExtraRight, PaddedRow)),
        PaddedRows),
% Width of padded rows.
    (PaddedRows = [FR|_] -> length(FR, PW) ; PW = TargetW),
% Build one full background row of width PW.
    findall(BgColor, between(1, PW, _), BgRow),
% Create AddH background rows.
    findall(BgRow, between(1, AddH, _), ExtraRows),
% Append background rows at the bottom.
    append(PaddedRows, ExtraRows, Padded).

% gridcrop_center_in(+Grid, +BgColor, +TargetH, +TargetW, -Centered)
% Centered is Grid placed in the center of a TargetH x TargetW BgColor frame.
% Vertical offset = floor((TargetH-H)/2); horizontal offset = floor((TargetW-W)/2).
gridcrop_center_in(Grid, BgColor, TargetH, TargetW, Centered) :-
% Current size.
    gridcrop_dims_(Grid, H, W),
% Compute padding on each side.
    TopPad  is (TargetH - H) // 2,
    BotPad  is TargetH - H - TopPad,
    LeftPad is (TargetW - W) // 2,
    RightPad is TargetW - W - LeftPad,
% Build left and right fills.
    findall(BgColor, between(1, LeftPad,  _), LeftFill),
    findall(BgColor, between(1, RightPad, _), RightFill),
% Wrap each row with fills.
    findall(PaddedRow,
        (member(Row, Grid),
         append(LeftFill, Row, Tmp), append(Tmp, RightFill, PaddedRow)),
        MiddleRows),
% Build one full background row.
    findall(BgColor, between(1, TargetW, _), BgRow),
% Top and bottom padding rows.
    findall(BgRow, between(1, TopPad, _), TopRows),
    findall(BgRow, between(1, BotPad, _), BotRows),
% Concatenate all sections.
    append([TopRows, MiddleRows, BotRows], Centered).

% gridcrop_add_border(+Grid, +N, +Color, -Bordered)
% Bordered is Grid with N rows and N columns of Color added on all four sides.
gridcrop_add_border(Grid, N, Color, Bordered) :-
% New column width after adding sides.
    gridcrop_dims_(Grid, _, W), NewW is W + 2 * N,
% Side fill (N cells) and full border row (NewW cells).
    findall(Color, between(1, N, _), SideFill),
    findall(Color, between(1, NewW, _), FullRow),
% Add SideFill on left and right of each existing row.
    findall(PaddedRow,
        (member(Row, Grid),
         append(SideFill, Row, Tmp), append(Tmp, SideFill, PaddedRow)),
        MiddleRows),
% N border rows at top and bottom.
    findall(FullRow, between(1, N, _), TopRows),
    findall(FullRow, between(1, N, _), BotRows),
% Assemble: top + middle + bottom.
    append([TopRows, MiddleRows, BotRows], Bordered).

% gridcrop_remove_border(+Grid, +N, +BgColor, -Inner)
% Inner is Grid with N rows and columns removed from all four sides.
% BgColor is accepted for API symmetry and is not used.
gridcrop_remove_border(Grid, N, _, Inner) :-
% Compute inner rectangle.
    gridcrop_dims_(Grid, H, W),
    R0 = N, R1 is H - N - 1,
    C0 = N, C1 is W - N - 1,
% Crop to inner rectangle.
    gridcrop_crop_(Grid, R0, C0, R1, C1, Inner).

% gridcrop_expand_down(+Grid, +N, +Color, -Expanded)
% Expanded is Grid with N new rows of Color appended at the bottom.
gridcrop_expand_down(Grid, N, Color, Expanded) :-
% Width of a new row equals the grid width.
    gridcrop_dims_(Grid, _, W),
% Build one new row.
    findall(Color, between(1, W, _), NewRow),
% Replicate N times.
    findall(NewRow, between(1, N, _), NewRows),
% Append new rows.
    append(Grid, NewRows, Expanded).

% gridcrop_expand_right(+Grid, +N, +Color, -Expanded)
% Expanded is Grid with N new columns of Color appended on the right of every row.
gridcrop_expand_right(Grid, N, Color, Expanded) :-
% Build N-cell extension.
    findall(Color, between(1, N, _), Extra),
% Extend each row.
    findall(ExpandedRow,
        (member(Row, Grid), append(Row, Extra, ExpandedRow)),
        Expanded).

% gridcrop_content_h(+Grid, +BgColor, -H)
% H is the height of the bounding box of non-BgColor content (MaxR - MinR + 1).
gridcrop_content_h(Grid, BgColor, CH) :-
% Get row bounds from bounding box.
    gridcrop_bbox(Grid, BgColor, R0-_-R1-_),
% Height is inclusive range.
    CH is R1 - R0 + 1.

% gridcrop_content_w(+Grid, +BgColor, -W)
% W is the width of the bounding box of non-BgColor content (MaxC - MinC + 1).
gridcrop_content_w(Grid, BgColor, CW) :-
% Get column bounds from bounding box.
    gridcrop_bbox(Grid, BgColor, _-C0-_-C1),
% Width is inclusive range.
    CW is C1 - C0 + 1.
