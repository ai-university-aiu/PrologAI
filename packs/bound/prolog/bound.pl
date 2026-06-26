% bound.pl - Layer 116: Bounding Box Extraction and Placement (bd_* prefix).
% Provides predicates for computing the tight bounding box of a color in a grid,
% querying bounding box dimensions and center, cropping to a bounding box,
% removing all-background border rows/columns, padding with background cells,
% placing a sub-grid at a target position, filling a rectangular region with a
% color, and testing bounding box overlap and computing union.
% Module declaration naming this file bound with its 14 exported predicates.
:- module(bound, [
    % Compute the tight bounding box (inclusive) of all cells of Color in Grid.
    bd_bbox/6,
    % Compute the height (number of rows) of a bounding box.
    bd_bbox_h/3,
    % Compute the width (number of columns) of a bounding box.
    bd_bbox_w/3,
    % Crop Grid to the inclusive rectangle [R0..R1, C0..C1].
    bd_crop_bbox/6,
    % Crop Grid to the tight bounding box of all cells of Color.
    bd_crop_color/3,
    % Remove all all-Bg border rows and columns to produce the tightest crop.
    bd_trim/3,
    % Add N background rows and columns on all four sides of a grid.
    bd_pad/4,
    % Place Patch into Canvas at top-left position (R0, C0).
    bd_place/6,
    % Compute the integer center row and column of the bounding box of Color.
    bd_center/4,
    % Succeed if cell (R, C) lies within the inclusive bounding box.
    bd_bbox_contains/6,
    % Succeed if two inclusive bounding boxes overlap.
    bd_bbox_overlap/8,
    % Compute the smallest bounding box enclosing two inclusive bounding boxes.
    bd_bbox_union/12,
    % Expand an inclusive bounding box outward by N cells on all sides.
    bd_expand/9,
    % Fill every cell within an inclusive bounding box with a given color.
    bd_fill_bbox/7
]).
% Import member/2, nth0/3, min_list/2, max_list/2, append/2, append/3 from lists.
:- use_module(library(lists), [member/2, nth0/3, min_list/2, max_list/2,
                                append/2, append/3]).
% Import maplist/3 for row-level bulk operations.
:- use_module(library(apply), [maplist/3]).

% bd_bbox(+Grid, +Color, -R0, -C0, -R1, -C1): tight bounding box of Color in Grid.
% R0 and C0 are the minimum row and column; R1 and C1 are the maximum.
% All bounds are 0-based and inclusive. Fails if Color is absent from Grid.
bd_bbox(Grid, Color, R0, C0, R1, C1) :-
% Get the grid dimensions.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Collect all R-C pairs where the cell value equals Color.
    findall(R-C, (
% Enumerate row and column indices.
        between(0, H1, R), between(0, W1, C),
% Retrieve the row.
        nth0(R, Grid, Row),
% Keep only cells where the value unifies with Color.
        nth0(C, Row, Color)
    ), Cells),
% Fail if Color does not appear in the grid.
    Cells = [_|_],
% Extract all row indices from the cell list.
    findall(R, member(R-_, Cells), Rs),
% Extract all column indices from the cell list.
    findall(C, member(_-C, Cells), Cs),
% Compute bounding box from min and max row/column values.
    min_list(Rs, R0), max_list(Rs, R1),
    min_list(Cs, C0), max_list(Cs, C1).

% bd_bbox_h(+R0, +R1, -H): height of the inclusive bounding box [R0, R1].
bd_bbox_h(R0, R1, H) :-
% Add 1 because both endpoints are inclusive.
    H is R1 - R0 + 1.

% bd_bbox_w(+C0, +C1, -W): width of the inclusive bounding box [C0, C1].
bd_bbox_w(C0, C1, W) :-
% Add 1 because both endpoints are inclusive.
    W is C1 - C0 + 1.

% bd_crop_bbox(+Grid, +R0, +C0, +R1, +C1, -Sub): crop Grid to [R0..R1, C0..C1].
% All bounds are 0-based and inclusive. Returns the sub-grid as a list of rows.
bd_crop_bbox(Grid, R0, C0, R1, C1, Sub) :-
% Collect each row in the row range, sliced to the column range.
    findall(SubRow, (
% Enumerate row indices R0 to R1.
        between(R0, R1, R),
% Retrieve the full row.
        nth0(R, Grid, Row),
% Extract the column slice [C0, C1] inclusive.
        bd_slice_row_(C0, C1, Row, SubRow)
    ), Sub).

% bd_slice_row_(+C0, +C1, +Row, -Sub): extract elements at columns [C0, C1] inclusive.
% Skips the first C0 elements then takes C1-C0+1 elements using length/append.
bd_slice_row_(C0, C1, Row, Sub) :-
% Build a list of C0 anonymous variables to skip the first C0 elements.
    length(Skip, C0),
% Split Row into Skip and Suffix.
    append(Skip, Suffix, Row),
% Compute the number of elements to keep (inclusive range).
    Len is C1 - C0 + 1,
% Build a result list of exactly Len variables.
    length(Sub, Len),
% Unify Sub with the first Len elements of Suffix.
    append(Sub, _, Suffix).

% bd_crop_color(+Grid, +Color, -Sub): crop to the tight bounding box of Color.
% Combines bd_bbox and bd_crop_bbox. Fails if Color is absent.
bd_crop_color(Grid, Color, Sub) :-
% Find the tight bounding box of Color.
    bd_bbox(Grid, Color, R0, C0, R1, C1),
% Crop the grid to that box.
    bd_crop_bbox(Grid, R0, C0, R1, C1, Sub).

% bd_trim(+Grid, +Bg, -Trimmed): remove all all-Bg border rows and columns.
% Finds the tight bounding box of all non-Bg cells and returns that sub-grid.
% Returns [[]] for a grid where every cell is Bg.
bd_trim(Grid, Bg, Trimmed) :-
% Get grid dimensions.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Collect R-C positions of all non-Bg cells.
    findall(R-C, (
% Enumerate row and column indices.
        between(0, H1, R), between(0, W1, C),
% Retrieve the row.
        nth0(R, Grid, Row),
% Retrieve the cell value.
        nth0(C, Row, V),
% Keep only cells that differ from Bg.
        V \== Bg
    ), Cells),
% If no non-Bg cells exist, return a 1x0 grid; otherwise crop to their bounding box.
    (   Cells = []
    ->  Trimmed = [[]]
    ;
% Extract all row indices.
        findall(R, member(R-_, Cells), Rs),
% Extract all column indices.
        findall(C, member(_-C, Cells), Cs),
% Compute the bounding box of non-Bg cells.
        min_list(Rs, R0), max_list(Rs, R1),
        min_list(Cs, C0), max_list(Cs, C1),
% Crop to that box.
        bd_crop_bbox(Grid, R0, C0, R1, C1, Trimmed)
    ).

% bd_pad(+Grid, +N, +Bg, -Padded): add N background cells on all four sides.
% The result has H+2*N rows and W+2*N columns where H and W are the original dims.
bd_pad(Grid, N, Bg, Padded) :-
% Get the original grid width.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0),
% Compute the padded row width.
    PadW is W + 2*N,
% Build one full-width background row.
    findall(Bg, between(1, PadW, _), BgRow),
% Build N background rows for the top and bottom padding.
    findall(BgRow, between(1, N, _), Padding),
% Pad each original row with N background cells on each side.
    maplist(bd_pad_row_(N, Bg), Grid, PaddedRows),
% Prepend the top padding.
    append(Padding, PaddedRows, Tmp),
% Append the bottom padding.
    append(Tmp, Padding, Padded).

% bd_pad_row_(+N, +Bg, +Row, -Padded): add N Bg elements on each side of Row.
bd_pad_row_(N, Bg, Row, Padded) :-
% Build N left-side background elements.
    findall(Bg, between(1, N, _), LeftPad),
% Build N right-side background elements.
    findall(Bg, between(1, N, _), RightPad),
% Prepend the left padding.
    append(LeftPad, Row, Tmp),
% Append the right padding.
    append(Tmp, RightPad, Padded).

% bd_place(+Canvas, +Patch, +R0, +C0, +Bg, -New): place Patch at (R0, C0) in Canvas.
% Each Canvas cell (R,C) that falls within the Patch bounds [R0..R0+PH-1, C0..C0+PW-1]
% is overwritten by the corresponding Patch cell. All other cells are unchanged.
% Bg is not used for overwriting: only Patch cells overwrite Canvas cells.
bd_place(Canvas, Patch, R0, C0, _Bg, New) :-
% Get Canvas dimensions.
    length(Canvas, H), H1 is H - 1,
    (Canvas = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Get Patch dimensions.
    length(Patch, PH), PH1 is PH - 1,
    (Patch = [PFr|_] -> length(PFr, PW) ; PW = 0), PW1 is PW - 1,
% Build each row of the result.
    findall(NewRow, (
% Enumerate Canvas row indices.
        between(0, H1, R),
% Build each cell of the result row.
        findall(NV, (
% Enumerate Canvas column indices.
            between(0, W1, C),
% Retrieve the original Canvas cell value.
            nth0(R, Canvas, CRow), nth0(C, CRow, OV),
% Compute the Patch row and column for this Canvas position.
            PR is R - R0, PC is C - C0,
% Use the Patch value if within Patch bounds; otherwise keep the Canvas value.
            (   PR >= 0, PR =< PH1, PC >= 0, PC =< PW1
            ->  nth0(PR, Patch, PRow), nth0(PC, PRow, NV)
            ;   NV = OV
            )
        ), NewRow)
    ), New).

% bd_center(+Grid, +Color, -CR, -CC): integer center of Color's bounding box.
% CR = (R0 + R1) // 2, CC = (C0 + C1) // 2.
bd_center(Grid, Color, CR, CC) :-
% Find the bounding box.
    bd_bbox(Grid, Color, R0, C0, R1, C1),
% Compute integer midpoints using floor division.
    CR is (R0 + R1) // 2,
    CC is (C0 + C1) // 2.

% bd_bbox_contains(+R0, +C0, +R1, +C1, +R, +C): succeed if (R,C) is in [R0..R1, C0..C1].
bd_bbox_contains(R0, C0, R1, C1, R, C) :-
% Test all four inclusive bounds.
    R >= R0, R =< R1, C >= C0, C =< C1.

% bd_bbox_overlap(+R0A, +C0A, +R1A, +C1A, +R0B, +C0B, +R1B, +C1B): two boxes overlap.
% Fails if the boxes are disjoint.
% Overlap iff: R1A >= R0B, R0A =< R1B, C1A >= C0B, C0A =< C1B.
bd_bbox_overlap(R0A, C0A, R1A, C1A, R0B, C0B, R1B, C1B) :-
% Row ranges must overlap.
    R1A >= R0B, R0A =< R1B,
% Column ranges must overlap.
    C1A >= C0B, C0A =< C1B.

% bd_bbox_union(+R0A,+C0A,+R1A,+C1A,+R0B,+C0B,+R1B,+C1B,-R0,-C0,-R1,-C1):
% Smallest bounding box enclosing both input boxes.
bd_bbox_union(R0A, C0A, R1A, C1A, R0B, C0B, R1B, C1B, R0, C0, R1, C1) :-
% Take the minimum of the top-left corners.
    R0 is min(R0A, R0B), C0 is min(C0A, C0B),
% Take the maximum of the bottom-right corners.
    R1 is max(R1A, R1B), C1 is max(C1A, C1B).

% bd_expand(+R0, +C0, +R1, +C1, +N, -ER0, -EC0, -ER1, -EC1): expand bbox by N.
% Moves the top-left corner N cells up and left, the bottom-right N cells down and right.
% The result may extend outside the original grid bounds.
bd_expand(R0, C0, R1, C1, N, ER0, EC0, ER1, EC1) :-
% Shrink top-left by N.
    ER0 is R0 - N, EC0 is C0 - N,
% Grow bottom-right by N.
    ER1 is R1 + N, EC1 is C1 + N.

% bd_fill_bbox(+Grid, +R0, +C0, +R1, +C1, +Color, -New): fill [R0..R1, C0..C1] with Color.
% All cells within the inclusive bounding box are set to Color; others are unchanged.
bd_fill_bbox(Grid, R0, C0, R1, C1, Color, New) :-
% Get grid dimensions.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Build each row of the result.
    findall(NewRow, (
% Enumerate row indices.
        between(0, H1, R),
% Build each cell of the result row.
        findall(NV, (
% Enumerate column indices.
            between(0, W1, C),
% Retrieve the original cell value.
            nth0(R, Grid, Row), nth0(C, Row, OV),
% Use Color if within bbox bounds; otherwise keep original.
            (   R >= R0, R =< R1, C >= C0, C =< C1
            ->  NV = Color
            ;   NV = OV
            )
        ), NewRow)
    ), New).
