:- module(gridtile, [
    gridtile_h_period/2,
    gridtile_w_period/2,
    gridtile_tile_size/3,
    gridtile_is_tiling/3,
    gridtile_extract_tile/4,
    gridtile_tile_to_grid/4,
    gridtile_row_is_periodic/3,
    gridtile_col_is_periodic/3,
    gridtile_tile_count_h/3,
    gridtile_tile_count_w/3,
    gridtile_matches_tile/4,
    gridtile_tile_offset/5,
    gridtile_all_tiles/4,
    gridtile_crop_to_tile/2
]).
% gridtile.pl - Layer 224: Grid Tiling Pattern Analysis (gti_* prefix).
% Fourteen predicates for detecting, extracting, verifying, and constructing
% tiling patterns in raw grids.
% A grid has vertical period P if H mod P = 0 AND row R = row (R mod P) for all R.
% A grid has horizontal period P if W mod P = 0 AND col C = col (C mod P) for all C.
% The minimal tile is the smallest sub-grid that tiles the full grid.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% No cross-pack dependencies.
:- use_module(library(lists), [nth0/3, member/2]).

% --- PRIVATE HELPERS ---

% Grid dimensions.
gridtile_dims_(Grid, H, W) :-
    length(Grid, H),
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Extract column C as a top-to-bottom list.
gridtile_col_(Grid, C, Col) :-
    findall(V, (member(Row, Grid), nth0(C, Row, V)), Col).

% Check if all rows in Grid with index R have Row = Grid[R mod P].
gridtile_rows_have_period_(Grid, P) :-
    length(Grid, H), H1 is H - 1,
    \+ (between(0, H1, R),
        R2 is R mod P,
        nth0(R, Grid, Row), nth0(R2, Grid, Row2),
        Row \= Row2).

% Check if all columns in Grid with index C have Col = col(C mod P).
gridtile_cols_have_period_(Grid, P) :-
    (Grid = [FR|_] -> length(FR, W) ; W = 0),
    W1 is W - 1,
    \+ (between(0, W1, C),
        C2 is C mod P,
        gridtile_col_(Grid, C, Col), gridtile_col_(Grid, C2, Col2),
        Col \= Col2).

% Extract a rectangular sub-grid rows [R0..R1], cols [C0..C1] inclusive.
gridtile_subgrid_(Grid, R0, R1, C0, C1, Sub) :-
    findall(Row,
        (between(R0, R1, R),
         nth0(R, Grid, GRow),
         findall(V, (between(C0, C1, C), nth0(C, GRow, V)), Row)),
        Sub).

% --- PUBLIC PREDICATES ---

% gridtile_h_period(+Grid, -P)
% P is the smallest positive integer dividing H such that every row R
% equals row R mod P. The minimal vertical tiling period.
gridtile_h_period(Grid, P) :-
    length(Grid, H),
    between(1, H, P),
    0 is H mod P,
    gridtile_rows_have_period_(Grid, P),
    !.

% gridtile_w_period(+Grid, -P)
% P is the smallest positive integer dividing W such that every column C
% equals column C mod P. The minimal horizontal tiling period.
gridtile_w_period(Grid, P) :-
    gridtile_dims_(Grid, _, W),
    between(1, W, P),
    0 is W mod P,
    gridtile_cols_have_period_(Grid, P),
    !.

% gridtile_tile_size(+Grid, -HP, -WP)
% HP is the minimal vertical period and WP is the minimal horizontal period.
% The minimal tile is HP rows tall and WP columns wide.
gridtile_tile_size(Grid, HP, WP) :-
    gridtile_h_period(Grid, HP),
    gridtile_w_period(Grid, WP).

% gridtile_is_tiling(+Grid, +TH, +TW)
% Succeeds if Grid is a valid tiling with a tile of height TH and width TW.
% Requires H mod TH = 0, W mod TW = 0, and all rows/cols respect the periods.
gridtile_is_tiling(Grid, TH, TW) :-
    gridtile_dims_(Grid, H, W),
    0 is H mod TH,
    0 is W mod TW,
    gridtile_rows_have_period_(Grid, TH),
    gridtile_cols_have_period_(Grid, TW).

% gridtile_extract_tile(+Grid, +TH, +TW, -Tile)
% Tile is the top-left TH x TW sub-grid of Grid. This is the canonical tile
% for a grid with vertical period TH and horizontal period TW.
gridtile_extract_tile(Grid, TH, TW, Tile) :-
    TH1 is TH - 1, TW1 is TW - 1,
    gridtile_subgrid_(Grid, 0, TH1, 0, TW1, Tile).

% gridtile_tile_to_grid(+Tile, +H, +W, -Grid)
% Grid is the H x W grid built by repeating Tile. Cell (R,C) = Tile[R mod TH][C mod TW].
gridtile_tile_to_grid(Tile, H, W, Grid) :-
    length(Tile, TH), Tile = [TR|_], length(TR, TW),
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        (between(0, H1, R),
         TR2 is R mod TH,
         findall(V,
             (between(0, W1, C),
              TC2 is C mod TW,
              nth0(TR2, Tile, TRow), nth0(TC2, TRow, V)),
             Row)),
        Grid).

% gridtile_row_is_periodic(+Row, +P, +Len)
% Succeeds if Row of length Len has period P: Row[C] = Row[C mod P] for all C.
% Requires Len mod P = 0.
gridtile_row_is_periodic(Row, P, Len) :-
    0 is Len mod P,
    Len1 is Len - 1,
    \+ (between(0, Len1, C),
        C2 is C mod P,
        nth0(C, Row, V), nth0(C2, Row, V2),
        V \= V2).

% gridtile_col_is_periodic(+Grid, +C, +P)
% Succeeds if column C of Grid has vertical period P.
% Requires H mod P = 0.
gridtile_col_is_periodic(Grid, C, P) :-
    length(Grid, H),
    0 is H mod P,
    gridtile_col_(Grid, C, Col),
    H1 is H - 1,
    \+ (between(0, H1, R),
        R2 is R mod P,
        nth0(R, Col, V), nth0(R2, Col, V2),
        V \= V2).

% gridtile_tile_count_h(+Grid, +TH, -Count)
% Count is H div TH: the number of complete tile rows in Grid.
gridtile_tile_count_h(Grid, TH, Count) :-
    length(Grid, H),
    Count is H div TH.

% gridtile_tile_count_w(+Grid, +TW, -Count)
% Count is W div TW: the number of complete tile columns in Grid.
gridtile_tile_count_w(Grid, TW, Count) :-
    gridtile_dims_(Grid, _, W),
    Count is W div TW.

% gridtile_matches_tile(+Grid, +Tile, +R0, +C0)
% Succeeds if the TH x TW sub-grid of Grid starting at (R0, C0) equals Tile.
gridtile_matches_tile(Grid, Tile, R0, C0) :-
    length(Tile, TH), Tile = [TR|_], length(TR, TW),
    R1 is R0 + TH - 1, C1 is C0 + TW - 1,
    gridtile_subgrid_(Grid, R0, R1, C0, C1, Sub),
    Sub = Tile.

% gridtile_tile_offset(+TH, +TW, +R, +C, -Offset)
% Offset is TileR-TileC: the position within the tile for grid cell (R, C).
% TileR = R mod TH, TileC = C mod TW.
gridtile_tile_offset(TH, TW, R, C, TileR-TileC) :-
    TileR is R mod TH,
    TileC is C mod TW.

% gridtile_all_tiles(+Grid, +TH, +TW, -Tiles)
% Tiles is the list of all TH x TW sub-grids when Grid is tiled by (TH,TW).
% Tiles are listed in row-major order: left to right, top to bottom.
% Requires H mod TH = 0 and W mod TW = 0.
gridtile_all_tiles(Grid, TH, TW, Tiles) :-
    gridtile_dims_(Grid, H, W),
    NH is H div TH, NW is W div TW,
    NH1 is NH - 1, NW1 is NW - 1,
    findall(Tile,
        (between(0, NH1, TR),
         between(0, NW1, TC),
         R0 is TR * TH, R1 is R0 + TH - 1,
         C0 is TC * TW, C1 is C0 + TW - 1,
         gridtile_subgrid_(Grid, R0, R1, C0, C1, Tile)),
        Tiles).

% gridtile_crop_to_tile(+Grid, -Tile)
% Tile is the minimal tile of Grid: extract the top-left sub-grid of size
% h_period x w_period. Combines gridtile_tile_size and gridtile_extract_tile.
gridtile_crop_to_tile(Grid, Tile) :-
% Find minimal periods.
    gridtile_h_period(Grid, HP),
    gridtile_w_period(Grid, WP),
% Extract the top-left HP x WP region.
    gridtile_extract_tile(Grid, HP, WP, Tile).
