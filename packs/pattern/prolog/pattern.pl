% Module declaration: pattern pack, Layer 56.
:- module(pattern, [
    % pt_row_period/2: smallest tiling period of a row (list of values).
    pt_row_period/2,
    % pt_col_period/3: smallest tiling period of column C in Grid.
    pt_col_period/3,
    % pt_grid_period_h/2: smallest column period shared by every row.
    pt_grid_period_h/2,
    % pt_grid_period_v/2: smallest row period shared by every column.
    pt_grid_period_v/2,
    % pt_tile_unit_h/2: extract the minimal horizontal tile unit.
    pt_tile_unit_h/2,
    % pt_tile_unit_v/2: extract the minimal vertical tile unit.
    pt_tile_unit_v/2,
    % pt_tile_unit/2: extract the minimal 2D tile unit.
    pt_tile_unit/2,
    % pt_is_tiling/2: test whether Grid is an exact tiling of Tile.
    pt_is_tiling/2,
    % pt_count_tile/3: count all (possibly overlapping) match positions.
    pt_count_tile/3,
    % pt_find_tile/3: list all r(R,C) top-left positions where Tile matches.
    pt_find_tile/3,
    % pt_extract_tile/5: extract H x W subgrid at top-left r(R,C).
    pt_extract_tile/5,
    % pt_unique_rows/2: number of distinct rows in Grid.
    pt_unique_rows/2,
    % pt_unique_cols/2: number of distinct columns in Grid.
    pt_unique_cols/2,
    % pt_has_uniform_rows/1: true when every row in Grid is identical.
    pt_has_uniform_rows/1
]).

% Import list and apply utilities.
:- use_module(library(lists),  [member/2, nth0/3, numlist/3, append/3]).
:- use_module(library(apply),  [maplist/2, maplist/3]).

% pt_take_(+N, +List, -Prefix): first N elements of List.
pt_take_(0, _, []) :- !.
pt_take_(N, [H|T], [H|Rest]) :-
    N > 0, N1 is N - 1,
    pt_take_(N1, T, Rest).

% pt_period_ok_(+List, +P): every element matches its index-mod-P counterpart.
pt_period_ok_(List, P) :-
    % Get list length for index range.
    length(List, Len),
    Len1 is Len - 1,
    numlist(0, Len1, Idxs),
    % No element violates the period.
    \+ (member(I, Idxs),
        nth0(I, List, V),
        Mod is I mod P,
        nth0(Mod, List, W),
        V \= W).

% pt_list_period_(+List, -P): smallest P >= 1 such that List tiles with period P.
pt_list_period_(List, P) :-
    % Try all periods from 1 upward; cut on first success.
    length(List, Len),
    between(1, Len, P),
    pt_period_ok_(List, P), !.

% pt_row_period(+Row, -P): smallest tiling period of Row.
pt_row_period(Row, P) :-
    % Row is a flat list of color values.
    pt_list_period_(Row, P).

% pt_extract_col_(+Grid, +C, -Col): extract column C as a list.
pt_extract_col_(Grid, C, Col) :-
    maplist(nth0(C), Grid, Col).

% pt_col_period(+Grid, +C, -P): smallest tiling period of column C.
pt_col_period(Grid, C, P) :-
    % Extract the column then find its list period.
    pt_extract_col_(Grid, C, Col),
    pt_list_period_(Col, P).

% pt_grid_period_h(+Grid, -P): smallest column period shared by every row.
pt_grid_period_h(Grid, P) :-
    % Get column count from first row.
    Grid = [Row0|_],
    length(Row0, Cols),
    % Try each candidate period.
    between(1, Cols, P),
    % Fail if any row does not have period P.
    \+ (member(Row, Grid), \+ pt_period_ok_(Row, P)), !.

% pt_grid_period_v(+Grid, -P): smallest row period shared by every column.
pt_grid_period_v(Grid, P) :-
    % Get row count and column count.
    length(Grid, Rows),
    Grid = [Row0|_], length(Row0, Cols),
    % Try each candidate row period.
    between(1, Rows, P),
    % Column index list for checking all columns.
    ( Cols > 0 -> Cols1 is Cols - 1, numlist(0, Cols1, CIds) ; CIds = [] ),
    % Fail if any column does not have period P.
    \+ (member(C, CIds),
        pt_extract_col_(Grid, C, Col),
        \+ pt_period_ok_(Col, P)), !.

% pt_tile_unit_h(+Grid, -Tile): leftmost P-column slice is the horizontal tile.
pt_tile_unit_h(Grid, Tile) :-
    % Find horizontal period.
    pt_grid_period_h(Grid, P),
    % Take first P columns from each row.
    maplist(pt_take_(P), Grid, Tile).

% pt_tile_unit_v(+Grid, -Tile): topmost P rows form the vertical tile.
pt_tile_unit_v(Grid, Tile) :-
    % Find vertical period.
    pt_grid_period_v(Grid, P),
    % Take first P rows.
    pt_take_(P, Grid, Tile).

% pt_tile_unit(+Grid, -Tile): minimal 2D tile (PH wide, PV tall).
pt_tile_unit(Grid, Tile) :-
    % Find both periods.
    pt_grid_period_h(Grid, PH),
    pt_grid_period_v(Grid, PV),
    % Slice top PV rows then leftmost PH columns.
    pt_take_(PV, Grid, VSlice),
    maplist(pt_take_(PH), VSlice, Tile).

% pt_tile_row_ok_(+GridRow, +TileRow, +TileW): every column matches tile-modulo.
pt_tile_row_ok_(GridRow, TileRow, TileW) :-
    % Get grid row length.
    length(GridRow, Len),
    ( Len > 0 -> Len1 is Len - 1, numlist(0, Len1, Idxs) ; Idxs = [] ),
    % No cell violates the tiling.
    \+ (member(C, Idxs),
        nth0(C, GridRow, GV),
        TileC is C mod TileW,
        nth0(TileC, TileRow, TV),
        GV \= TV).

% pt_is_tiling(+Grid, +Tile): true when Grid is an exact tiling of Tile.
pt_is_tiling(Grid, Tile) :-
    % Get tile dimensions.
    length(Tile, TH),
    Tile = [TRow0|_], length(TRow0, TW),
    TH > 0, TW > 0,
    % Check every grid row.
    length(Grid, Rows),
    ( Rows > 0 -> Rows1 is Rows - 1, numlist(0, Rows1, RIds) ; RIds = [] ),
    \+ (member(R, RIds),
        nth0(R, Grid, GRow),
        TR is R mod TH,
        nth0(TR, Tile, TileRow),
        \+ pt_tile_row_ok_(GRow, TileRow, TW)).

% pt_tile_matches_at_(+Grid, +Tile, +R, +C): Tile cells match Grid at offset (R,C).
pt_tile_matches_at_(Grid, Tile, R, C) :-
    % Get tile dimensions.
    length(Tile, TH), Tile = [TR0|_], length(TR0, TW),
    TH1 is TH - 1, TW1 is TW - 1,
    numlist(0, TH1, TRIds),
    numlist(0, TW1, TCIds),
    % No tile cell mismatches its grid counterpart.
    \+ (member(TR, TRIds), member(TC, TCIds),
        GR is R + TR, GC is C + TC,
        nth0(GR, Grid, GRow), nth0(GC, GRow, GV),
        nth0(TR, Tile, TRow), nth0(TC, TRow, TV),
        GV \= TV).

% pt_find_tile(+Grid, +Tile, -Positions): all r(R,C) match top-left positions.
pt_find_tile(Grid, Tile, Positions) :-
    % Compute valid top-left row/col range.
    length(Grid, Rows), Grid = [GRow0|_], length(GRow0, Cols),
    length(Tile, TH), Tile = [TRow0|_], length(TRow0, TW),
    MaxR is Rows - TH, MaxC is Cols - TW,
    ( MaxR >= 0, MaxC >= 0
    -> numlist(0, MaxR, RIds), numlist(0, MaxC, CIds)
    ;  RIds = [], CIds = [] ),
    % Collect all matching positions.
    findall(r(R,C),
        (member(R, RIds), member(C, CIds),
         pt_tile_matches_at_(Grid, Tile, R, C)),
        Positions).

% pt_count_tile(+Grid, +Tile, -N): count all positions where Tile matches.
pt_count_tile(Grid, Tile, N) :-
    % Find positions then count.
    pt_find_tile(Grid, Tile, Positions),
    length(Positions, N).

% pt_extract_tile(+Grid, +r(R,C), +H, +W, -Tile): extract H x W subgrid at (R,C).
pt_extract_tile(Grid, r(R,C), H, W, Tile) :-
    % Build row offset list.
    H1 is H - 1, numlist(0, H1, DRs),
    % For each row offset, extract W cells starting at column C.
    maplist(pt_extract_row_slice_(Grid, R, C, W), DRs, Tile).

% pt_extract_row_slice_(+Grid, +BaseR, +BaseC, +W, +DR, -Row): one tile row.
pt_extract_row_slice_(Grid, BaseR, BaseC, W, DR, Row) :-
    % Compute the grid row index.
    GR is BaseR + DR,
    % Fetch that row.
    nth0(GR, Grid, GRow),
    % Drop first BaseC elements.
    pt_drop_(BaseC, GRow, Suffix),
    % Take W elements.
    pt_take_(W, Suffix, Row).

% pt_drop_(+N, +List, -Suffix): drop first N elements.
pt_drop_(0, List, List) :- !.
pt_drop_(N, [_|T], Suffix) :-
    N > 0, N1 is N - 1,
    pt_drop_(N1, T, Suffix).

% pt_unique_rows(+Grid, -N): count distinct rows.
pt_unique_rows(Grid, N) :-
    % sort/2 removes duplicates.
    sort(Grid, Unique),
    length(Unique, N).

% pt_unique_cols(+Grid, -N): count distinct columns.
pt_unique_cols(Grid, N) :-
    % Extract every column then count distinct.
    Grid = [Row0|_], length(Row0, Cols),
    ( Cols > 0 -> Cols1 is Cols - 1, numlist(0, Cols1, CIds) ; CIds = [] ),
    findall(Col, (member(C, CIds), pt_extract_col_(Grid, C, Col)), AllCols),
    sort(AllCols, Unique),
    length(Unique, N).

% pt_has_uniform_rows(+Grid): true when every row is identical.
pt_has_uniform_rows(Grid) :-
    % After sorting, only one distinct row remains.
    sort(Grid, [_]).
