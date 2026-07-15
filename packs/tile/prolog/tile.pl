% tile.pl - Layer 81: Tiling, Stamping, and Period Detection (ti_* prefix).
% ARC-AGI-2 visual reasoning: tile patterns, stamp motifs, detect periodicity.
:- module(tile, [
    tile_tile_h/3,
    tile_tile_v/3,
    tile_tile/4,
    tile_split_rows/3,
    tile_split_cols/3,
    tile_split/4,
    tile_flatten_tiles/2,
    tile_stamp/5,
    tile_stamp_all/4,
    tile_extract_tile/6,
    tile_is_tiling/3,
    tile_find_period_h/2,
    tile_find_period_v/2,
    tile_checkerboard/5
]).

% Import list operations used throughout this module.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3]).
% Import higher-order operations used throughout this module.
:- use_module(library(apply), [maplist/2, maplist/3, maplist/4, foldl/4]).

% tile_tile_h(+Tile, +N, -Grid): Grid is Tile repeated N times side-by-side.
tile_tile_h(Tile, N, Grid) :-
    % Repeat each row of Tile N times by appending copies.
    maplist(tile_repeat_row_(N), Tile, Grid).

% tile_repeat_row_(+N, +Row, -Rep): Rep is Row concatenated N times.
tile_repeat_row_(N, Row, Rep) :-
    % Drive N fold steps using index list 1..N.
    numlist(1, N, Ns),
    % Start from [] and append Row once per fold step.
    foldl([_, Acc, NAcc]>>(append(Acc, Row, NAcc)), Ns, [], Rep).

% tile_tile_v(+Tile, +N, -Grid): Grid is Tile stacked N times vertically.
tile_tile_v(Tile, N, Grid) :-
    % Drive N fold steps using index list 1..N.
    numlist(1, N, Ns),
    % Start from [] and append all Tile rows once per fold step.
    foldl([_, Acc, NAcc]>>(append(Acc, Tile, NAcc)), Ns, [], Grid).

% tile_tile(+Tile, +NR, +NC, -Grid): Grid is Tile tiled NR rows by NC columns of copies.
tile_tile(Tile, NR, NC, Grid) :-
    % First tile Tile horizontally NC times.
    tile_tile_h(Tile, NC, HGrid),
    % Then tile that horizontally-extended grid NR times vertically.
    tile_tile_v(HGrid, NR, Grid).

% tile_split_rows(+Grid, +TH, -Bands): split Grid into horizontal bands of TH rows each.
tile_split_rows(Grid, TH, Bands) :-
    % Compute number of bands from total row count and band height.
    length(Grid, NRows),
    NTiles is NRows // TH,
    NTilesM1 is NTiles - 1,
    % Build index list 0..NTiles-1 for maplist.
    numlist(0, NTilesM1, TIs),
    % For each tile index collect the TH rows that belong to that band.
    maplist([TI, Band]>>(
        R0 is TI * TH, R1 is R0 + TH - 1,
        numlist(R0, R1, RowIdxs),
        maplist([RI, Row]>>(nth0(RI, Grid, Row)), RowIdxs, Band)
    ), TIs, Bands).

% tile_split_cols(+Grid, +TW, -Stripes): split Grid into vertical stripes of TW cols each.
tile_split_cols(Grid, TW, Stripes) :-
    % Get column count from the first row.
    Grid = [FirstRow|_], length(FirstRow, NCols),
    NTiles is NCols // TW,
    NTilesM1 is NTiles - 1,
    % Build index list 0..NTiles-1 for maplist.
    numlist(0, NTilesM1, TIs),
    % For each stripe index collect the TW columns belonging to that stripe.
    maplist([TI, Stripe]>>(
        C0 is TI * TW, C1 is C0 + TW - 1,
        numlist(C0, C1, ColIdxs),
        maplist([Row, SubRow]>>(
            maplist([CI, Cell]>>(nth0(CI, Row, Cell)), ColIdxs, SubRow)
        ), Grid, Stripe)
    ), TIs, Stripes).

% tile_split(+Grid, +TH, +TW, -TileGrid): split Grid into list-of-tile-rows of TH x TW tiles.
tile_split(Grid, TH, TW, TileGrid) :-
    % First partition rows into horizontal bands.
    tile_split_rows(Grid, TH, Bands),
    % Then partition each band into TW-wide vertical stripes.
    maplist([Band, TileRow]>>(tile_split_cols(Band, TW, TileRow)), Bands, TileGrid).

% tile_join_tile_row_(+TileRow, -Band): horizontally join a list of tiles into one sub-grid.
tile_join_tile_row_(TileRow, Band) :-
    % Read tile height from the first tile in the row.
    TileRow = [FirstTile|_], length(FirstTile, TH), TH1 is TH - 1,
    % Iterate over each row index within the tile height.
    numlist(0, TH1, RowIdxs),
    % For each row index: extract that row from every tile, then concatenate.
    maplist([RI, Row]>>(
        maplist([T, TR]>>(nth0(RI, T, TR)), TileRow, RowParts),
        append(RowParts, Row)
    ), RowIdxs, Band).

% tile_flatten_tiles(+TileGrid, -Grid): reassemble list-of-tile-rows back into one Grid.
tile_flatten_tiles(TileGrid, Grid) :-
    % Horizontally join each tile-row into a band.
    maplist(tile_join_tile_row_, TileGrid, Bands),
    % Vertically stack all bands.
    append(Bands, Grid).

% tile_stamp(+Base, +Motif, +R, +C, -Result): overlay Motif onto Base with top-left at (R,C).
tile_stamp(Base, Motif, R, C, Result) :-
    % Read grid dimensions for full iteration.
    length(Base, NRows), NRowsM1 is NRows - 1,
    Base = [FirstRow|_], length(FirstRow, NCols), NColsM1 is NCols - 1,
    % Build row and column index lists.
    numlist(0, NRowsM1, RowIdxs),
    numlist(0, NColsM1, ColIdxs),
    % For each row: replace with motif row if motif covers it, else keep base row.
    maplist([RI, BRow, RRow]>>(
        MRI is RI - R,
        (MRI >= 0, nth0(MRI, Motif, MRow) ->
            maplist([CI, BC, RC]>>(
                MCI is CI - C,
                (MCI >= 0, nth0(MCI, MRow, MCell) -> RC = MCell ; RC = BC)
            ), ColIdxs, BRow, RRow)
        ;
            RRow = BRow
        )
    ), RowIdxs, Base, Result).

% tile_stamp_all(+Base, +Motif, +Positions, -Result): stamp Motif at each R-C in Positions.
tile_stamp_all(Base, Motif, Positions, Result) :-
    % Fold over R-C pairs, accumulating the grid after each stamp.
    foldl([R-C, Acc, NAcc]>>(tile_stamp(Acc, Motif, R, C, NAcc)), Positions, Base, Result).

% tile_extract_tile(+Grid, +TH, +TW, +TR, +TC, -Tile): extract TH x TW tile at tile-pos (TR,TC).
tile_extract_tile(Grid, TH, TW, TR, TC, Tile) :-
    % Compute the row and column ranges for this tile in the full grid.
    R0 is TR * TH, R1 is R0 + TH - 1,
    C0 is TC * TW, C1 is C0 + TW - 1,
    numlist(R0, R1, RowIdxs),
    numlist(C0, C1, ColIdxs),
    % Collect each row of the tile by extracting the specified columns.
    maplist([RI, TRow]>>(
        nth0(RI, Grid, Row),
        maplist([CI, Cell]>>(nth0(CI, Row, Cell)), ColIdxs, TRow)
    ), RowIdxs, Tile).

% tile_is_tiling(+Grid, +TH, +TW): true if Grid is an exact tiling by a TH x TW tile.
tile_is_tiling(Grid, TH, TW) :-
    % Check that dimensions are exact multiples of the tile size.
    length(Grid, NRows), Grid = [FirstRow|_], length(FirstRow, NCols),
    NRows mod TH =:= 0, NCols mod TW =:= 0,
    % Extract the reference tile at position (0,0).
    tile_extract_tile(Grid, TH, TW, 0, 0, RefTile),
    % Compute tile-grid dimensions.
    NRTiles is NRows // TH, NRTilesM1 is NRTiles - 1,
    NCTiles is NCols // TW, NCTilesM1 is NCTiles - 1,
    numlist(0, NRTilesM1, TRIdxs),
    numlist(0, NCTilesM1, TCIdxs),
    % Every tile must be structurally identical to the reference tile.
    forall(member(TR, TRIdxs),
        forall(member(TC, TCIdxs),
            (tile_extract_tile(Grid, TH, TW, TR, TC, Tile), Tile == RefTile))).

% tile_row_period_(+Row, +P): Row has horizontal period P (repeats every P cells).
tile_row_period_(Row, P) :-
    % Build index list for all cell positions.
    length(Row, N), NM1 is N - 1,
    numlist(0, NM1, Idxs),
    % Every cell must equal the cell at its position modulo P.
    forall(member(I, Idxs), (
        nth0(I, Row, V), I2 is I mod P, nth0(I2, Row, V)
    )).

% tile_find_period_h(+Grid, -PH): smallest horizontal period (in columns) of Grid.
tile_find_period_h(Grid, PH) :-
    % Try candidate periods 1..NCols in ascending order.
    Grid = [FirstRow|_], length(FirstRow, NCols),
    between(1, NCols, PH),
    NCols mod PH =:= 0,
    % All rows must have period PH.
    forall(member(Row, Grid), tile_row_period_(Row, PH)),
    % Cut after the first (smallest) match.
    !.

% tile_col_period_(+Grid, +P): Grid has vertical period P (rows repeat every P rows).
tile_col_period_(Grid, P) :-
    % Build index list for all row positions.
    length(Grid, N), NM1 is N - 1,
    numlist(0, NM1, Idxs),
    % Every row must equal the row at its index modulo P.
    forall(member(I, Idxs), (
        nth0(I, Grid, Row), I2 is I mod P, nth0(I2, Grid, Row2),
        Row == Row2
    )).

% tile_find_period_v(+Grid, -PV): smallest vertical period (in rows) of Grid.
tile_find_period_v(Grid, PV) :-
    % Try candidate periods 1..NRows in ascending order.
    length(Grid, NRows),
    between(1, NRows, PV),
    NRows mod PV =:= 0,
    % Grid must have vertical period PV.
    tile_col_period_(Grid, PV),
    % Cut after the first (smallest) match.
    !.

% tile_checkerboard(+H, +W, +V1, +V2, -Grid): H x W grid with V1 at even (R+C), V2 at odd.
tile_checkerboard(H, W, V1, V2, Grid) :-
    % Build row and column index lists.
    HM1 is H - 1, WM1 is W - 1,
    numlist(0, HM1, RowIdxs),
    numlist(0, WM1, ColIdxs),
    % Assign V1 where (R+C) mod 2 = 0, V2 otherwise.
    maplist([RI, Row]>>(
        maplist([CI, Cell]>>(
            S is (RI + CI) mod 2,
            (S =:= 0 -> Cell = V1 ; Cell = V2)
        ), ColIdxs, Row)
    ), RowIdxs, Grid).
