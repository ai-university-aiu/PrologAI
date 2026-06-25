% seek - Layer 76: spatial pattern search, sub-grid matching, and transform discovery.
% Module seek exports 14 sk_* predicates covering position finding, sub-pattern
% search, template matching, D4 transform discovery, and grid scaling.
:- module(seek, [
    % Find all (row,col) positions where Grid has a given value.
    sk_positions/3,
    % Find all row indices containing a given value.
    sk_rows_with/3,
    % Find all column indices containing a given value.
    sk_cols_with/3,
    % List all border cell positions of a grid.
    sk_border_cells/2,
    % List all interior (non-border) cell positions of a grid.
    sk_interior_cells/2,
    % Test whether a sub-grid matches exactly at a given position.
    sk_fits/4,
    % Nondeterministically enumerate positions where a sub-grid fits.
    sk_find_sub/4,
    % Collect all positions where a sub-grid fits as a list.
    sk_all_subs/3,
    % Count how many positions a sub-grid fits.
    sk_count_sub/3,
    % Count how many cells match when a sub-grid is placed at a position.
    sk_match_count/5,
    % Find the position that maximises the match count for a sub-grid.
    sk_best_fit/4,
    % Find the D4 transform name mapping one grid to another.
    sk_find_d4/3,
    % Upscale every cell to a Factor x Factor block.
    sk_upscale/3,
    % Find the integer scale factor relating two grids.
    sk_find_scale/3
]).

% Load standard list utilities.
:- use_module(library(lists), [
    member/2, nth0/3, numlist/3, append/3, max_member/2, memberchk/2, reverse/2
]).
% Load apply utilities for maplist and include.
:- use_module(library(apply), [
    maplist/2, maplist/3, include/3
]).

% sk_positions(+Grid, +Val, -Cells)
% Cells is the list of R-C pairs where Grid has value Val (0-indexed, row-major order).
sk_positions(Grid, Val, Cells) :-
    % Collect all (R,C) where the cell at row R, column C equals Val.
    findall(R-C, (nth0(R, Grid, Row), nth0(C, Row, Val)), Cells).

% sk_rows_with(+Grid, +Val, -RowIdxs)
% RowIdxs is the list of 0-indexed row numbers that contain Val at least once.
sk_rows_with(Grid, Val, RowIdxs) :-
    % Collect row indices where Val appears in the row.
    findall(R, (nth0(R, Grid, Row), memberchk(Val, Row)), RowIdxs).

% sk_cols_with(+Grid, +Val, -ColIdxs)
% ColIdxs is the list of 0-indexed column numbers that contain Val at least once.
sk_cols_with(Grid, Val, ColIdxs) :-
    % Get column count from first row.
    Grid = [FirstRow|_],
    % Build full column index list.
    length(FirstRow, NCols),
    % Compute inclusive upper bound for numlist.
    NColsM1 is NCols - 1,
    % Enumerate column indices.
    numlist(0, NColsM1, CIdxs),
    % Keep only those columns that contain Val.
    include(sk_col_has_val_(Grid, Val), CIdxs, ColIdxs).

% sk_col_has_val_(+Grid, +Val, +CI): column CI contains Val in at least one row.
sk_col_has_val_(Grid, Val, CI) :-
    % Find any row that has Val at column CI.
    member(Row, Grid),
    % Check cell value at column CI.
    nth0(CI, Row, Val),
    % Commit on first match.
    !.

% sk_border_cells(+Grid, -Cells)
% Cells is the list of R-C pairs on the outermost ring of Grid.
sk_border_cells(Grid, Cells) :-
    % Get row and column counts.
    length(Grid, NRows),
    % Get first row for column count.
    Grid = [FirstRow|_],
    % Get column count.
    length(FirstRow, NCols),
    % Inclusive upper bounds.
    NRowsM1 is NRows - 1,
    % Inclusive upper bound for columns.
    NColsM1 is NCols - 1,
    % Collect all cells that lie on at least one edge; once/1 prevents duplicates.
    findall(R-C,
        (between(0, NRowsM1, R),
         between(0, NColsM1, C),
         once((R =:= 0 ; R =:= NRowsM1 ; C =:= 0 ; C =:= NColsM1))),
        Cells).

% sk_interior_cells(+Grid, -Cells)
% Cells is the list of R-C pairs strictly inside the border of Grid.
sk_interior_cells(Grid, Cells) :-
    % Get row count.
    length(Grid, NRows),
    % Get column count from first row.
    Grid = [FirstRow|_],
    % Get column count.
    length(FirstRow, NCols),
    % Compute row and column exclusive upper bounds.
    NRowsM1 is NRows - 1,
    % Compute column exclusive upper bound.
    NColsM1 is NCols - 1,
    % Interior row range: 1..NRowsM1-1.
    InteriorRMax is NRowsM1 - 1,
    % Interior column range: 1..NColsM1-1.
    InteriorCMax is NColsM1 - 1,
    % Return empty if grid has no interior rows.
    (   InteriorRMax < 1
    ->  Cells = []
    % Return empty if grid has no interior columns.
    ;   InteriorCMax < 1
    ->  Cells = []
    % Collect all strictly interior positions.
    ;   findall(R-C,
            (between(1, InteriorRMax, R),
             between(1, InteriorCMax, C)),
            Cells)
    ).

% sk_fits(+Grid, +Sub, +R0, +C0)
% Sub exactly matches the region of Grid starting at row R0, column C0 (0-indexed).
sk_fits(Grid, Sub, R0, C0) :-
    % Get sub-grid row count.
    length(Sub, NSubRows),
    % Trivially true for empty sub-grid.
    (   NSubRows =:= 0
    ->  true
    ;   % Get sub-grid column count from first row.
        Sub = [SubRow0|_],
        % Get column count.
        length(SubRow0, NSubCols),
        % Build row offset index list.
        NSubRowsM1 is NSubRows - 1,
        % Build column offset index list.
        NSubColsM1 is NSubCols - 1,
        % Enumerate row offsets.
        numlist(0, NSubRowsM1, DRIdxs),
        % Enumerate column offsets.
        numlist(0, NSubColsM1, DCIdxs),
        % Verify every cell in Sub matches the corresponding cell in Grid.
        forall(
            (member(DR, DRIdxs), member(DC, DCIdxs)),
            (R is R0 + DR, C is C0 + DC,
             nth0(R, Grid, GridRow), nth0(C, GridRow, GVal),
             nth0(DR, Sub, SubRow), nth0(DC, SubRow, GVal))
        )
    ).

% sk_find_sub(+Grid, +Sub, -R0, -C0)
% Nondeterministically produce each (R0,C0) position where Sub fits in Grid.
sk_find_sub(Grid, Sub, R0, C0) :-
    % Get grid dimensions.
    length(Grid, NRows),
    % Get column count from first row.
    Grid = [FirstRow|_],
    % Column count.
    length(FirstRow, NCols),
    % Get sub-grid dimensions.
    length(Sub, NSubRows),
    % Sub-grid column count.
    Sub = [SubRow0|_],
    % Sub column count.
    length(SubRow0, NSubCols),
    % Maximum valid row start.
    MaxR is NRows - NSubRows,
    % Maximum valid column start.
    MaxC is NCols - NSubCols,
    % Guard: sub-grid must fit in at least one position.
    MaxR >= 0, MaxC >= 0,
    % Enumerate candidate row positions.
    between(0, MaxR, R0),
    % Enumerate candidate column positions.
    between(0, MaxC, C0),
    % Check exact match at this position.
    sk_fits(Grid, Sub, R0, C0).

% sk_all_subs(+Grid, +Sub, -Cells)
% Cells is the list of R0-C0 pairs where Sub fits in Grid.
sk_all_subs(Grid, Sub, Cells) :-
    % Collect all positions where Sub fits.
    findall(R0-C0, sk_find_sub(Grid, Sub, R0, C0), Cells).

% sk_count_sub(+Grid, +Sub, -N)
% N is the number of positions where Sub fits in Grid.
sk_count_sub(Grid, Sub, N) :-
    % Collect all fitting positions.
    sk_all_subs(Grid, Sub, Cells),
    % Count them.
    length(Cells, N).

% sk_match_count(+Grid, +Sub, +R0, +C0, -N)
% N is the number of cells that agree when Sub is placed over Grid at (R0,C0).
sk_match_count(Grid, Sub, R0, C0, N) :-
    % Get sub-grid row count.
    length(Sub, NSubRows),
    % Empty sub-grid contributes 0 matches.
    (   NSubRows =:= 0
    ->  N = 0
    ;   % Get sub-grid column count.
        Sub = [SubRow0|_],
        % Column count.
        length(SubRow0, NSubCols),
        % Row offset range.
        NSubRowsM1 is NSubRows - 1,
        % Column offset range.
        NSubColsM1 is NSubCols - 1,
        % Build row offset list.
        numlist(0, NSubRowsM1, DRIdxs),
        % Build column offset list.
        numlist(0, NSubColsM1, DCIdxs),
        % Collect matching (DR,DC) pairs.
        findall(DR-DC,
            (member(DR, DRIdxs), member(DC, DCIdxs),
             R is R0 + DR, C is C0 + DC,
             nth0(R, Grid, GridRow), nth0(C, GridRow, GVal),
             nth0(DR, Sub, SubRow), nth0(DC, SubRow, GVal)),
            Matches),
        % Count matching cells.
        length(Matches, N)
    ).

% sk_best_fit(+Grid, +Sub, -R0, -C0)
% (R0,C0) is the position in Grid that maximises the match count for Sub.
sk_best_fit(Grid, Sub, R0, C0) :-
    % Get grid dimensions.
    length(Grid, NRows),
    % Column count from first row.
    Grid = [FirstRow|_],
    % Column count.
    length(FirstRow, NCols),
    % Sub-grid row count.
    length(Sub, NSubRows),
    % Sub-grid column count from first row.
    Sub = [SubRow0|_],
    % Sub column count.
    length(SubRow0, NSubCols),
    % Valid row range.
    MaxR is NRows - NSubRows,
    % Valid column range.
    MaxC is NCols - NSubCols,
    % Guard: at least one valid position.
    MaxR >= 0, MaxC >= 0,
    % Score every candidate position.
    findall(N-R-C,
        (between(0, MaxR, R), between(0, MaxC, C),
         sk_match_count(Grid, Sub, R, C, N)),
        Scored),
    % Pick the position with the highest match count.
    max_member(_-R0-C0, Scored).

% sk_find_d4(+Grid1, +Grid2, -Name)
% Name is the first D4 transform name (in declaration order) that maps Grid1 to Grid2.
% Fails if no D4 element maps Grid1 to Grid2.
% Names: identity, reflect_h, reflect_v, transpose, rotate90, rotate180, rotate270, anti_diag.
sk_find_d4(Grid1, Grid2, Name) :-
    % Commit to the first matching D4 transform to avoid choicepoints.
    once(sk_d4_pair_(Name, Grid1, Grid2)).

% sk_d4_pair_(+Name, +Grid1, -Grid2): apply the named D4 transform.
sk_d4_pair_(identity, G, G).
% Horizontal reflection: reverse each row.
sk_d4_pair_(reflect_h, G, G2) :- maplist(reverse, G, G2).
% Vertical reflection: reverse row order.
sk_d4_pair_(reflect_v, G, G2) :- reverse(G, G2).
% Transpose: rows become columns.
sk_d4_pair_(transpose, G, G2) :- sk_transpose_(G, G2).
% Rotate 90 degrees clockwise: transpose then reflect_h.
sk_d4_pair_(rotate90, G, G2) :- sk_transpose_(G, T), maplist(reverse, T, G2).
% Rotate 180 degrees: reverse rows, then reverse each row.
sk_d4_pair_(rotate180, G, G2) :- reverse(G, R), maplist(reverse, R, G2).
% Rotate 270 degrees clockwise: reflect_h then transpose.
sk_d4_pair_(rotate270, G, G2) :- maplist(reverse, G, H), sk_transpose_(H, G2).
% Anti-diagonal reflection: rotate90 then reflect_v.
sk_d4_pair_(anti_diag, G, G2) :-
    % Apply rotate90 = transpose then reflect_h.
    sk_transpose_(G, T),
    % Apply reflect_h to transposed grid.
    maplist(reverse, T, R90),
    % Apply reflect_v (reverse row order) to get anti-diagonal reflection.
    reverse(R90, G2).

% sk_transpose_(+Grid, -Transposed): reflect Grid across the main diagonal.
sk_transpose_([], []) :- !.
sk_transpose_(Grid, Transposed) :-
    % Get number of columns from first row.
    Grid = [FirstRow|_],
    % Column count.
    length(FirstRow, NCols),
    % Column index upper bound.
    NColsM1 is NCols - 1,
    % Generate column indices.
    numlist(0, NColsM1, CIdxs),
    % For each column index, build a new row from that column across all original rows.
    maplist([CI, Row]>>(maplist([GRow, Cell]>>(nth0(CI, GRow, Cell)), Grid, Row)), CIdxs, Transposed).

% sk_upscale(+Grid, +Factor, -Scaled)
% Each cell of Grid becomes a Factor x Factor block of the same value in Scaled.
sk_upscale(Grid, Factor, Scaled) :-
    % Tile each row horizontally by Factor.
    maplist(sk_upscale_row_(Factor), Grid, TiledRows),
    % Repeat each tiled row Factor times vertically.
    sk_repeat_rows_(TiledRows, Factor, Scaled).

% sk_upscale_row_(+Factor, +Row, -TiledRow): repeat each cell Factor times.
sk_upscale_row_(Factor, Row, TiledRow) :-
    % For each cell in Row and each repetition index, collect the cell value.
    findall(Cell, (member(Cell, Row), between(1, Factor, _)), TiledRow).

% sk_repeat_rows_(+Rows, +Factor, -Repeated): repeat each row in Rows Factor times.
sk_repeat_rows_([], _Factor, []).
sk_repeat_rows_([Row|Rest], Factor, Result) :-
    % Build Factor copies of this row.
    findall(Row, between(1, Factor, _), Copies),
    % Append rest result to get full repeated tail.
    sk_repeat_rows_(Rest, Factor, RestResult),
    % Prepend the copies for this row.
    append(Copies, RestResult, Result).

% sk_find_scale(+Grid1, +Grid2, -Factor)
% Factor is the positive integer scale Factor such that sk_upscale(Grid1, Factor, Grid2) holds.
sk_find_scale(Grid1, Grid2, Factor) :-
    % Get Grid1 dimensions.
    length(Grid1, NR1),
    % Get Grid1 column count.
    Grid1 = [Row1|_], length(Row1, NC1),
    % Get Grid2 row count.
    length(Grid2, NR2),
    % Guard: Grid1 must be non-empty.
    NR1 > 0, NC1 > 0,
    % Grid2 row count must be a multiple of Grid1 row count.
    NR2 mod NR1 =:= 0,
    % Compute candidate scale factor from rows.
    Factor is NR2 // NR1,
    % Factor must be positive.
    Factor > 0,
    % Get Grid2 column count.
    Grid2 = [Row2|_], length(Row2, NC2),
    % Grid2 column count must be a multiple of Grid1 column count.
    NC2 mod NC1 =:= 0,
    % Column factor must equal row factor.
    Factor =:= NC2 // NC1,
    % Verify that upscaling Grid1 by Factor actually produces Grid2.
    sk_upscale(Grid1, Factor, Grid2).
