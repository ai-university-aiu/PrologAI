:- use_module('../prolog/gridtile.pl').

% Tiled grids used throughout.
% G44: 4x4, tile [a,b]/[c,d] (2x2)
%   Row0: [a,b,a,b]
%   Row1: [c,d,c,d]
%   Row2: [a,b,a,b]
%   Row3: [c,d,c,d]
g44([[a,b,a,b],[c,d,c,d],[a,b,a,b],[c,d,c,d]]).

% G22: 2x2 (is its own minimal tile)
g22([[a,b],[c,d]]).

% G33: 3x3, trivial: only period is 3 (not a tiling by smaller)
g33([[a,b,c],[d,e,f],[g,h,i]]).

% G36: 3x6, horizontal period 2 but vertical period 3
%   Row0: [a,b,a,b,a,b]
%   Row1: [c,d,c,d,c,d]
%   Row2: [e,f,e,f,e,f]
g36([[a,b,a,b,a,b],[c,d,c,d,c,d],[e,f,e,f,e,f]]).

% G11: 1x1 trivial tile
g11([[z]]).

:- begin_tests(gridtile).

% --- gti_h_period ---

% AC-GTI-001: 4x4 tiled grid has vertical period 2
test(h_period_4x4) :-
    g44(G), gti_h_period(G, P), P = 2.

% AC-GTI-002: 2x2 has vertical period 1 (all rows differ)
test(h_period_2x2) :-
    g22(G), gti_h_period(G, P), P = 2.

% AC-GTI-003: 1x1 has vertical period 1
test(h_period_1x1) :-
    g11(G), gti_h_period(G, P), P = 1.

% --- gti_w_period ---

% AC-GTI-004: 4x4 tiled grid has horizontal period 2
test(w_period_4x4) :-
    g44(G), gti_w_period(G, P), P = 2.

% AC-GTI-005: 3x6 has horizontal period 2
test(w_period_3x6) :-
    g36(G), gti_w_period(G, P), P = 2.

% AC-GTI-006: 3x3 non-tiling has horizontal period 3
test(w_period_3x3) :-
    g33(G), gti_w_period(G, P), P = 3.

% --- gti_tile_size ---

% AC-GTI-007: 4x4 tile is 2x2
test(tile_size_4x4) :-
    g44(G), gti_tile_size(G, HP, WP),
    HP = 2, WP = 2.

% AC-GTI-008: 3x6 tile is 3x2
test(tile_size_3x6) :-
    g36(G), gti_tile_size(G, HP, WP),
    HP = 3, WP = 2.

% AC-GTI-009: 1x1 tile is 1x1
test(tile_size_1x1) :-
    g11(G), gti_tile_size(G, HP, WP),
    HP = 1, WP = 1.

% --- gti_is_tiling ---

% AC-GTI-010: 4x4 is a valid tiling with tile 2x2
test(is_tiling_4x4_2x2) :-
    g44(G), gti_is_tiling(G, 2, 2).

% AC-GTI-011: 4x4 is NOT a valid tiling with tile 3x3
test(is_tiling_4x4_3x3_false) :-
    g44(G), \+ gti_is_tiling(G, 3, 3).

% AC-GTI-012: 4x4 is a valid tiling with tile 4x4 (trivially)
test(is_tiling_trivial) :-
    g44(G), gti_is_tiling(G, 4, 4).

% --- gti_extract_tile ---

% AC-GTI-013: extract 2x2 tile from 4x4 gives top-left 2x2
test(extract_tile_4x4) :-
    g44(G), gti_extract_tile(G, 2, 2, T),
    T = [[a,b],[c,d]].

% AC-GTI-014: extract 1x1 tile from 4x4 gives [[a]]
test(extract_tile_1x1) :-
    g44(G), gti_extract_tile(G, 1, 1, T),
    T = [[a]].

% AC-GTI-015: extract full tile from 3x3 gives whole grid
test(extract_tile_full) :-
    g33(G), gti_extract_tile(G, 3, 3, T),
    T = [[a,b,c],[d,e,f],[g,h,i]].

% --- gti_tile_to_grid ---

% AC-GTI-016: tile [[a,b],[c,d]] to 4x4 gives g44
test(tile_to_grid_4x4) :-
    Tile = [[a,b],[c,d]],
    gti_tile_to_grid(Tile, 4, 4, G),
    g44(Expected), G = Expected.

% AC-GTI-017: tile [[z]] to 3x3 gives uniform grid
test(tile_to_grid_1x1) :-
    gti_tile_to_grid([[z]], 3, 3, G),
    G = [[z,z,z],[z,z,z],[z,z,z]].

% AC-GTI-018: tile_to_grid followed by crop_to_tile recovers original tile
test(tile_to_grid_then_crop) :-
    Tile = [[a,b],[c,d]],
    gti_tile_to_grid(Tile, 4, 6, G),
    gti_crop_to_tile(G, Recovered),
    Recovered = Tile.

% --- gti_row_is_periodic ---

% AC-GTI-019: row [a,b,a,b] has period 2 with length 4
test(row_is_periodic_2) :-
    gti_row_is_periodic([a,b,a,b], 2, 4).

% AC-GTI-020: row [a,b,a,b] does not have period 1 (a != b)
test(row_not_period_1) :-
    \+ gti_row_is_periodic([a,b,a,b], 1, 4).

% AC-GTI-021: uniform row [a,a,a,a] has period 1
test(row_is_periodic_uniform) :-
    gti_row_is_periodic([a,a,a,a], 1, 4).

% --- gti_col_is_periodic ---

% AC-GTI-022: column 0 of g44 has period 2
test(col_is_periodic_4x4) :-
    g44(G), gti_col_is_periodic(G, 0, 2).

% AC-GTI-023: column 0 of g44 does not have period 1
test(col_not_period_1) :-
    g44(G), \+ gti_col_is_periodic(G, 0, 1).

% AC-GTI-024: column of uniform grid has period 1
test(col_is_periodic_uniform) :-
    G = [[a,b],[a,b],[a,b],[a,b]],
    gti_col_is_periodic(G, 0, 1).

% --- gti_tile_count_h ---

% AC-GTI-025: 4-row grid with TH=2 has 2 tile rows
test(tile_count_h_2) :-
    g44(G), gti_tile_count_h(G, 2, C), C = 2.

% AC-GTI-026: 3-row grid with TH=3 has 1 tile row
test(tile_count_h_1) :-
    g36(G), gti_tile_count_h(G, 3, C), C = 1.

% AC-GTI-027: 1-row grid with TH=1 has 1 tile row
test(tile_count_h_1x1) :-
    g11(G), gti_tile_count_h(G, 1, C), C = 1.

% --- gti_tile_count_w ---

% AC-GTI-028: 4-col grid with TW=2 has 2 tile cols
test(tile_count_w_2) :-
    g44(G), gti_tile_count_w(G, 2, C), C = 2.

% AC-GTI-029: 6-col grid with TW=2 has 3 tile cols
test(tile_count_w_3) :-
    g36(G), gti_tile_count_w(G, 2, C), C = 3.

% AC-GTI-030: 1-col grid with TW=1 has 1 tile col
test(tile_count_w_1x1) :-
    g11(G), gti_tile_count_w(G, 1, C), C = 1.

% --- gti_matches_tile ---

% AC-GTI-031: top-left 2x2 of g44 matches [[a,b],[c,d]]
test(matches_tile_tl) :-
    g44(G), gti_matches_tile(G, [[a,b],[c,d]], 0, 0).

% AC-GTI-032: second tile (R0=0, C0=2) also matches [[a,b],[c,d]]
test(matches_tile_second) :-
    g44(G), gti_matches_tile(G, [[a,b],[c,d]], 0, 2).

% AC-GTI-033: wrong tile does not match
test(matches_tile_false) :-
    g44(G), \+ gti_matches_tile(G, [[x,y],[z,w]], 0, 0).

% --- gti_tile_offset ---

% AC-GTI-034: cell (0,0) with tile 2x2 has offset 0-0
test(tile_offset_00) :-
    gti_tile_offset(2, 2, 0, 0, O), O = 0-0.

% AC-GTI-035: cell (3,3) with tile 2x2 has offset 1-1
test(tile_offset_33) :-
    gti_tile_offset(2, 2, 3, 3, O), O = 1-1.

% AC-GTI-036: cell (2,5) with tile 3x2 has offset 2-1
test(tile_offset_253x2) :-
    gti_tile_offset(3, 2, 2, 5, O), O = 2-1.

% --- gti_all_tiles ---

% AC-GTI-037: g44 with tile 2x2 has 4 tiles
test(all_tiles_count) :-
    g44(G), gti_all_tiles(G, 2, 2, Tiles),
    length(Tiles, 4).

% AC-GTI-038: all tiles of g44 equal [[a,b],[c,d]]
test(all_tiles_equal) :-
    g44(G), gti_all_tiles(G, 2, 2, Tiles),
    Tile = [[a,b],[c,d]],
    \+ (member(T, Tiles), T \= Tile).

% AC-GTI-039: 1x1 grid with tile 1x1 has 1 tile
test(all_tiles_1x1) :-
    g11(G), gti_all_tiles(G, 1, 1, Tiles),
    Tiles = [[[z]]].

% --- gti_crop_to_tile ---

% AC-GTI-040: crop g44 gives [[a,b],[c,d]]
test(crop_to_tile_4x4) :-
    g44(G), gti_crop_to_tile(G, Tile),
    Tile = [[a,b],[c,d]].

% AC-GTI-041: crop g33 gives the full 3x3 (no smaller tile)
test(crop_to_tile_3x3) :-
    g33(G), gti_crop_to_tile(G, Tile),
    Tile = [[a,b,c],[d,e,f],[g,h,i]].

% AC-GTI-042: crop g11 gives [[z]]
test(crop_to_tile_1x1) :-
    g11(G), gti_crop_to_tile(G, Tile),
    Tile = [[z]].

% AC-GTI-043: crop g36 gives [[a,b],[c,d],[e,f]] (3x2 tile)
test(crop_to_tile_3x6) :-
    g36(G), gti_crop_to_tile(G, Tile),
    Tile = [[a,b],[c,d],[e,f]].

% AC-GTI-044: tiling a tile and cropping back recovers the tile
test(tile_and_crop_roundtrip) :-
    Tile = [[p,q],[r,s]],
    gti_tile_to_grid(Tile, 6, 4, G),
    gti_crop_to_tile(G, Recovered),
    Recovered = Tile.

:- end_tests(gridtile).
