% assemble.pl - Layer 91: Grid Assembly, Concatenation, and Composition (as_* prefix).
% Provides 14 predicates for joining grids horizontally and vertically, assembling
% grids from 2D matrices of sub-grids, downscaling, adding borders, centering,
% extracting quadrants, mirror-concatenation, column/row interleaving,
% unconditional paste, mask-based fill, and crop-or-pad to a target size.
:- module(assemble, [
    as_hcat/2,
    as_vcat/2,
    as_grid_of/2,
    as_downscale/3,
    as_border/4,
    as_center_in/5,
    as_quarter/3,
    as_flip_h_cat/2,
    as_flip_v_cat/2,
    as_zip_h/3,
    as_zip_v/3,
    as_paste/5,
    as_mask_fill/4,
    as_crop_to/5
]).
% Import list utilities; length/2, msort/2, between/3 are built-ins, not imported.
:- use_module(library(lists), [nth0/3, numlist/3, append/2, append/3, reverse/2, last/2]).
% Import higher-order utilities.
:- use_module(library(apply), [maplist/2, maplist/3, maplist/4, include/3]).

% as_make_row_: build a row of N copies of Val.
as_make_row_(N, Val, Row) :-
% Create an N-element unbound list.
    length(Row, N),
% Unify every element with Val.
    maplist(=(Val), Row).

% as_make_grid_: build a grid of N rows each equal to Row.
as_make_grid_(N, Row, Grid) :-
% Create an N-element unbound list.
    length(Grid, N),
% Unify every element with Row.
    maplist(=(Row), Grid).

% as_zip_lists_: interleave two lists element by element.
as_zip_lists_([], [], []).
as_zip_lists_([A|As], [B|Bs], [A, B|Rest]) :-
% Recurse on the tails.
    as_zip_lists_(As, Bs, Rest).

% as_crop_: extract the sub-grid from (R0,C0) to (R1,C1) inclusive.
as_crop_(Grid, R0, C0, R1, C1, Sub) :-
% Build the inclusive list of row indices.
    numlist(R0, R1, RowIdxs),
% Build the inclusive list of column indices.
    numlist(C0, C1, ColIdxs),
% For each row index, extract the column slice.
    maplist([R, Row]>>(
        nth0(R, Grid, GRow),
        maplist([C, V]>>(nth0(C, GRow, V)), ColIdxs, Row)
    ), RowIdxs, Sub).

% as_qbounds_: row and column bounds for the four quadrants of an NR x NC grid.
% Q is one of: tl (top-left), tr (top-right), bl (bottom-left), br (bottom-right).
% HR = NR // 2, HC = NC // 2.
as_qbounds_(tl, HR, HC, _NR, _NC, 0,  R1, 0,  C1) :- R1 is HR - 1, C1 is HC - 1.
as_qbounds_(tr, HR, HC, _NR, NC,  0,  R1, HC, C1) :- R1 is HR - 1, C1 is NC - 1.
as_qbounds_(bl, HR, HC, NR,  _NC, HR, R1, 0,  C1) :- R1 is NR - 1, C1 is HC - 1.
as_qbounds_(br, HR, HC, NR,  NC,  HR, R1, HC, C1) :- R1 is NR - 1, C1 is NC - 1.

% as_paste_row_: paste SubRow into BaseRow starting at column SC.
% Cells inside the sub-row range are taken from SubRow; others from BaseRow.
as_paste_row_(BaseRow, SubRow, SC, ResultRow) :-
% Count base row width.
    length(BaseRow, NC),
% Count sub row width.
    length(SubRow, SNC),
% Build column index list.
    NC1 is NC - 1,
    numlist(0, NC1, ColIdxs),
% For each column, take from SubRow if in range, else from BaseRow.
    maplist([CI, V]>>(
        SI is CI - SC,
        (SI >= 0, SI < SNC ->
            nth0(SI, SubRow, V)
        ;
            nth0(CI, BaseRow, V)
        )
    ), ColIdxs, ResultRow).

% as_majority_: most common value in a non-empty list.
% Uses count per unique value then picks the highest count.
as_majority_(List, Val) :-
% Get sorted unique values.
    sort(List, Uniq),
% Pair each unique value with its occurrence count.
    maplist([U, Cnt-U]>>(
        include(==(U), List, Ms),
        length(Ms, Cnt)
    ), Uniq, Keyed),
% Sort pairs ascending by count; the last has the highest count.
    msort(Keyed, Sorted),
    last(Sorted, _-Val).

% as_hcat(+Grids, -Combined): horizontally concatenate a list of same-height grids.
% Each grid contributes its rows side by side. Grids must all have the same row count.
as_hcat([SingleGrid], SingleGrid) :- !.
as_hcat(Grids, Combined) :-
% Get row count from first grid.
    Grids = [G|_],
    length(G, NR),
% Build 0-indexed row list.
    NR1 is NR - 1,
    numlist(0, NR1, RowIdxs),
% For each row index, collect that row from every grid and append all rows.
    maplist([I, CombRow]>>(
        maplist([Grid, Row]>>(nth0(I, Grid, Row)), Grids, Rows),
        append(Rows, CombRow)
    ), RowIdxs, Combined).

% as_vcat(+Grids, -Combined): vertically stack a list of same-width grids.
% A grid is a list of rows, so stacking is list concatenation.
as_vcat(Grids, Combined) :-
% Concatenate all row lists in sequence.
    append(Grids, Combined).

% as_grid_of(+Matrix, -Combined): assemble from a 2D list of grids.
% Matrix is a list of rows; each row is a list of grids with the same height.
% All rows must produce strips of the same total width.
as_grid_of(Matrix, Combined) :-
% Horizontally join each row of grids into a horizontal strip.
    maplist(as_hcat, Matrix, HRows),
% Vertically stack all horizontal strips.
    as_vcat(HRows, Combined).

% as_downscale(+Grid, +K, -Small): reduce each K x K non-overlapping block to one cell.
% The cell value is the most common value in the block (majority vote).
% Grid dimensions must be divisible by K in both directions.
as_downscale(Grid, K, Small) :-
% Count rows and compute output row count.
    length(Grid, NR),
    NR2 is NR // K,
% Count columns and compute output column count.
    Grid = [FirstRow|_],
    length(FirstRow, NC),
    NC2 is NC // K,
% Build output row and column index lists.
    Rlast is NR2 - 1,
    numlist(0, Rlast, RowIdxs),
    Clast is NC2 - 1,
    numlist(0, Clast, ColIdxs),
% For each output cell (I,J), gather the K x K block and take majority value.
    maplist([I, SmallRow]>>(
        maplist([J, Val]>>(
            R0 is I * K, R1 is R0 + K - 1,
            C0 is J * K, C1 is C0 + K - 1,
            findall(V, (
                between(R0, R1, R),
                between(C0, C1, C),
                nth0(R, Grid, GRow),
                nth0(C, GRow, V)
            ), Cells),
            as_majority_(Cells, Val)
        ), ColIdxs, SmallRow)
    ), RowIdxs, Small).

% as_border(+Grid, +W, +Color, -Framed): surround Grid with a W-cell wide frame of Color.
% The output has NR + 2*W rows and NC + 2*W columns.
as_border(Grid, W, Color, Framed) :-
% Compute original grid dimensions.
    length(Grid, NR),
    Grid = [GRow|_],
    length(GRow, NC),
% Compute framed grid dimensions.
    NR2 is NR + 2 * W,
    NC2 is NC + 2 * W,
% Build a full-Color grid of the framed size.
    as_make_row_(NC2, Color, ColorRow),
    as_make_grid_(NR2, ColorRow, ColorGrid),
% Paste the original grid at offset (W, W) into the Color grid.
    as_paste(ColorGrid, Grid, W, W, Framed).

% as_center_in(+Grid, +NR, +NC, +Bg, -Result): embed Grid centered in an NR x NC canvas.
% The canvas is initially filled with Bg. If Grid is larger than the canvas,
% only the top-left portion visible within NR x NC is shown.
as_center_in(Grid, NR, NC, Bg, Result) :-
% Get grid dimensions.
    length(Grid, GNR),
    Grid = [GRow|_],
    length(GRow, GNC),
% Compute start position (integer floor of centering offset).
    SR is (NR - GNR) // 2,
    SC is (NC - GNC) // 2,
% Build background canvas.
    as_make_row_(NC, Bg, BgRow),
    as_make_grid_(NR, BgRow, BgGrid),
% Paste Grid at the computed center offset.
    as_paste(BgGrid, Grid, SR, SC, Result).

% as_quarter(+Grid, +Q, -Sub): extract named quadrant Q from Grid.
% Q is one of: tl (top-left), tr (top-right), bl (bottom-left), br (bottom-right).
% Each quadrant spans half the rows and half the columns (floor division).
as_quarter(Grid, Q, Sub) :-
% Get grid dimensions.
    length(Grid, NR),
    Grid = [FirstRow|_],
    length(FirstRow, NC),
% Compute half-dimensions.
    HR is NR // 2,
    HC is NC // 2,
% Resolve row and column bounds for quadrant Q.
    as_qbounds_(Q, HR, HC, NR, NC, R0, R1, C0, C1),
% Extract the quadrant sub-grid.
    as_crop_(Grid, R0, C0, R1, C1, Sub).

% as_flip_h_cat(+Grid, -Combined): concatenate Grid with its horizontal (left-right) mirror.
% The result has the same row count but twice the column count.
as_flip_h_cat(Grid, Combined) :-
% Reverse each row to produce the left-right mirror.
    maplist([Row, Rev]>>(reverse(Row, Rev)), Grid, Mirrored),
% Place Grid on the left and its mirror on the right.
    as_hcat([Grid, Mirrored], Combined).

% as_flip_v_cat(+Grid, -Combined): stack Grid with its vertical (top-bottom) mirror.
% The result has twice the row count and the same column count.
as_flip_v_cat(Grid, Combined) :-
% Reverse the list of rows to produce the top-bottom mirror.
    reverse(Grid, Mirrored),
% Place Grid on top and its mirror below.
    as_vcat([Grid, Mirrored], Combined).

% as_zip_h(+G1, +G2, -Combined): interleave columns from two same-size grids.
% For each row, columns alternate: G1[R][0], G2[R][0], G1[R][1], G2[R][1], ...
% Combined has the same row count and twice the column count.
as_zip_h(G1, G2, Combined) :-
% For corresponding row pairs, interleave the column values.
    maplist([R1, R2, CombRow]>>(as_zip_lists_(R1, R2, CombRow)), G1, G2, Combined).

% as_zip_v(+G1, +G2, -Combined): interleave rows from two same-size grids.
% Rows alternate: G1[0], G2[0], G1[1], G2[1], ...
% Combined has twice the row count and the same column count.
as_zip_v(G1, G2, Combined) :-
% Interleave the row lists directly.
    as_zip_lists_(G1, G2, Combined).

% as_paste(+Base, +Sub, +SR, +SC, -Result): paste Sub into Base starting at row SR, col SC.
% Cells within Sub's bounds unconditionally overwrite Base; others are kept.
% Sub may extend beyond Base boundaries; out-of-bounds sub cells are ignored.
as_paste(Base, Sub, SR, SC, Result) :-
% Count base grid rows.
    length(Base, NR),
% Count sub grid rows.
    length(Sub, SNR),
% Build row index list.
    NR1 is NR - 1,
    numlist(0, NR1, RowIdxs),
% For each base row, either paste the corresponding sub row or copy the base row.
    maplist([RI, ResultRow]>>(
        nth0(RI, Base, BaseRow),
        SI is RI - SR,
        (SI >= 0, SI < SNR ->
            nth0(SI, Sub, SubRow),
            as_paste_row_(BaseRow, SubRow, SC, ResultRow)
        ;
            ResultRow = BaseRow
        )
    ), RowIdxs, Result).

% as_mask_fill(+Grid, +Mask, +Fill, -Result): replace Grid cells with Fill where Mask is non-zero.
% Grid, Mask, and Result all have the same dimensions.
as_mask_fill(Grid, Mask, Fill, Result) :-
% Process corresponding row pairs from Grid and Mask.
    maplist([GRow, MRow, RRow]>>(
        maplist([GV, MV, RV]>>(
            (MV \= 0 -> RV = Fill ; RV = GV)
        ), GRow, MRow, RRow)
    ), Grid, Mask, Result).

% as_crop_to(+Grid, +NR, +NC, +Bg, -Result): crop or pad Grid to exactly NR rows and NC cols.
% Rows and columns beyond the input Grid are filled with Bg.
% Input rows and columns beyond NR or NC are discarded.
as_crop_to(Grid, NR, NC, Bg, Result) :-
% Count input grid rows.
    length(Grid, GNR),
% Count input grid columns (from first row, or 0 if empty).
    (Grid = [GR|_] -> length(GR, GNC) ; GNC = 0),
% Rows and cols to copy from Grid (the minimum of input and target).
    TR is min(GNR, NR),
    TC is min(GNC, NC),
% Build output row and column index lists.
    NR1 is NR - 1,
    numlist(0, NR1, RowIdxs),
    NC1 is NC - 1,
    numlist(0, NC1, ColIdxs),
% For each output cell, copy from Grid or use Bg.
    maplist([RI, Row]>>(
        maplist([CI, V]>>(
            (RI < TR, CI < TC ->
                nth0(RI, Grid, GRow),
                nth0(CI, GRow, V)
            ;
                V = Bg
            )
        ), ColIdxs, Row)
    ), RowIdxs, Result).
