% PLUnit tests for the morph pack (mo_* predicates).
:- use_module(library(plunit)).
:- use_module(library(morph)).

% Test grids.
% grid_cross: 1-colored cross in 5x5 BG=0 grid.
%   0 0 1 0 0
%   0 0 1 0 0
%   1 1 1 1 1
%   0 0 1 0 0
%   0 0 1 0 0
grid_cross([[0,0,1,0,0],[0,0,1,0,0],[1,1,1,1,1],[0,0,1,0,0],[0,0,1,0,0]]).

% grid_dot: single 1 in center of 3x3.
%   0 0 0
%   0 1 0
%   0 0 0
grid_dot([[0,0,0],[0,1,0],[0,0,0]]).

% grid_ring: 3x3 ring of 1s enclosing a 0.
%   1 1 1
%   1 0 1
%   1 1 1
grid_ring([[1,1,1],[1,0,1],[1,1,1]]).

% grid_small: 3x3 uniform 1s.
%   1 1 1
%   1 1 1
%   1 1 1
grid_small([[1,1,1],[1,1,1],[1,1,1]]).

% grid_nw: 1s in top-left 2x2 corner of 4x4.
%   1 1 0 0
%   1 1 0 0
%   0 0 0 0
%   0 0 0 0
grid_nw([[1,1,0,0],[1,1,0,0],[0,0,0,0],[0,0,0,0]]).

:- begin_tests(morph_mo_dilate4).

test(dilate4_dot) :-
    % Single 1 at center of 3x3: after one dilate, cross shape.
    grid_dot(G),
    mo_dilate4(G, 1, 0, G2),
    % Center and 4 cardinal neighbors become 1.
    nth0(0, G2, R0), nth0(1, R0, V01), V01 =:= 1,  % r(0,1) from up-neighbor
    nth0(1, G2, R1), nth0(1, R1, V11), V11 =:= 1,  % center
    nth0(2, G2, R2), nth0(1, R2, V21), V21 =:= 1.  % r(2,1)

test(dilate4_nw_expands) :-
    % 2x2 block in top-left: dilate adds one ring around it.
    grid_nw(G),
    mo_dilate4(G, 1, 0, G2),
    % r(0,2) and r(2,0) should become 1.
    nth0(0, G2, R0), nth0(2, R0, V02), V02 =:= 1,
    nth0(2, G2, R2), nth0(0, R2, V20), V20 =:= 1.

test(dilate4_preserves_other_colors) :-
    % If some cells are color 2 (not BG 0, not target 1), they stay 2.
    G = [[2,0,0],[0,1,0],[0,0,2]],
    mo_dilate4(G, 1, 0, G2),
    nth0(0, G2, R0), nth0(0, R0, V00), V00 =:= 2,
    nth0(2, G2, R2), nth0(2, R2, V22), V22 =:= 2.

:- end_tests(morph_mo_dilate4).

:- begin_tests(morph_mo_dilate8).

test(dilate8_dot) :-
    % Dilate8 from center 1 in 3x3: all 8 neighbors plus center = all 1s.
    grid_dot(G),
    mo_dilate8(G, 1, 0, G2),
    G2 = [[1,1,1],[1,1,1],[1,1,1]].

:- end_tests(morph_mo_dilate8).

:- begin_tests(morph_mo_erode4).

test(erode4_small_all_interior) :-
    % Solid 3x3 of 1s: erode removes all grid-edge cells; only center survives.
    grid_small(G),
    mo_erode4(G, 1, 0, G2),
    % Only center r(1,1) survives.
    nth0(1, G2, R1), nth0(1, R1, V11), V11 =:= 1,
    nth0(0, G2, R0), nth0(0, R0, V00), V00 =:= 0.

test(erode4_dot) :-
    % Single 1 in center: all 4-neighbors are BG -> eroded to BG.
    grid_dot(G),
    mo_erode4(G, 1, 0, G2),
    % All zeros.
    G2 = [[0,0,0],[0,0,0],[0,0,0]].

:- end_tests(morph_mo_erode4).

:- begin_tests(morph_mo_erode8).

test(erode8_small) :-
    % Solid 3x3: erode8 removes edge cells (OOB 8-neighbors), but center survives.
    % Center (1,1) has all 8 in-bounds neighbors = 1, so it is kept.
    grid_small(G),
    mo_erode8(G, 1, 0, G2),
    % Center survives.
    nth0(1, G2, R1), nth0(1, R1, V11), V11 =:= 1,
    % Corner erodes (has OOB 8-neighbors).
    nth0(0, G2, R0), nth0(0, R0, V00), V00 =:= 0.

:- end_tests(morph_mo_erode8).

:- begin_tests(morph_mo_dilate4_n).

test(dilate4_n_zero) :-
    % Zero rounds: unchanged.
    grid_dot(G),
    mo_dilate4_n(G, 1, 0, 0, G2),
    G2 = G.

test(dilate4_n_two) :-
    % Two rounds from center dot in 5x5 BG: diamond of radius 2.
    G = [[0,0,0,0,0],[0,0,0,0,0],[0,0,1,0,0],[0,0,0,0,0],[0,0,0,0,0]],
    mo_dilate4_n(G, 1, 0, 2, G2),
    % r(0,2) should be 1 after 2 dilations.
    nth0(0, G2, R0), nth0(2, R0, V), V =:= 1.

:- end_tests(morph_mo_dilate4_n).

:- begin_tests(morph_mo_erode4_n).

test(erode4_n_zero) :-
    % Zero rounds: unchanged.
    grid_small(G),
    mo_erode4_n(G, 1, 0, 0, G2),
    G2 = G.

test(erode4_n_one) :-
    % One round on small: center only survives.
    grid_small(G),
    mo_erode4_n(G, 1, 0, 1, G2),
    nth0(1, G2, R1), nth0(1, R1, V11), V11 =:= 1.

:- end_tests(morph_mo_erode4_n).

:- begin_tests(morph_mo_open4).

test(open4_dot) :-
    % Single dot: erode removes it, dilate does nothing -> all zeros.
    grid_dot(G),
    mo_open4(G, 1, 0, G2),
    G2 = [[0,0,0],[0,0,0],[0,0,0]].

test(open4_small_unchanged) :-
    % Solid 3x3: erode keeps center, dilate restores -> center only or original?
    % After erode: only r(1,1) = 1. After dilate: cross around center.
    % So result is NOT identical to input (open removes protrusions).
    grid_small(G),
    mo_open4(G, 1, 0, G2),
    % Center survives.
    nth0(1, G2, R1), nth0(1, R1, V11), V11 =:= 1.

:- end_tests(morph_mo_open4).

:- begin_tests(morph_mo_close4).

test(close4_dot) :-
    % Single dot: dilate expands to cross, erode shrinks back to center.
    grid_dot(G),
    mo_close4(G, 1, 0, G2),
    nth0(1, G2, R1), nth0(1, R1, V11), V11 =:= 1.

:- end_tests(morph_mo_close4).

:- begin_tests(morph_mo_boundary4).

test(boundary4_ring) :-
    % Ring of 1s: all 8 cells are boundary (each has a non-1 neighbor).
    grid_ring(G),
    mo_boundary4(G, 1, Cells),
    length(Cells, N), N =:= 8.

test(boundary4_small) :-
    % Solid 3x3: 8 cells are boundary (grid-edge); center (1,1) is not boundary.
    % Center has all 4 in-bounds neighbors = 1, so mo_all4_color_ succeeds.
    grid_small(G),
    mo_boundary4(G, 1, Cells),
    length(Cells, N), N =:= 8.

test(boundary4_none) :-
    % Color not in grid: empty.
    grid_dot(G),
    mo_boundary4(G, 9, Cells),
    Cells = [].

:- end_tests(morph_mo_boundary4).

:- begin_tests(morph_mo_boundary8).

test(boundary8_small) :-
    % Solid 3x3: 8 cells are boundary (grid-edge); center (1,1) is not boundary.
    % Center has all 8 in-bounds neighbors = 1, so mo_all8_color_ succeeds.
    grid_small(G),
    mo_boundary8(G, 1, Cells),
    length(Cells, N), N =:= 8.

:- end_tests(morph_mo_boundary8).

:- begin_tests(morph_mo_ring4).

test(ring4_dot) :-
    % Dot at center of 3x3: ring = 4 cardinal BG cells.
    grid_dot(G),
    mo_ring4(G, 1, 0, Ring),
    length(Ring, N), N =:= 4,
    msort(Ring, S),
    S = [r(0,1), r(1,0), r(1,2), r(2,1)].

test(ring4_none) :-
    % No Color in grid: no ring.
    grid_dot(G),
    mo_ring4(G, 9, 0, Ring),
    Ring = [].

:- end_tests(morph_mo_ring4).

:- begin_tests(morph_mo_fill_holes4).

test(fill_holes4_ring) :-
    % Ring of 1s with enclosed 0 at center: fill hole -> all 1s.
    grid_ring(G),
    mo_fill_holes4(G, 1, 0, G2),
    G2 = [[1,1,1],[1,1,1],[1,1,1]].

test(fill_holes4_no_holes) :-
    % No enclosed BG: unchanged.
    grid_dot(G),
    mo_fill_holes4(G, 1, 0, G2),
    G2 = G.

:- end_tests(morph_mo_fill_holes4).

:- begin_tests(morph_mo_pad).

test(pad_dot) :-
    % Pad 3x3 dot: result is 5x5.
    grid_dot(G),
    mo_pad(G, 0, G2),
    length(G2, Rows), Rows =:= 5,
    G2 = [R0|_], length(R0, Cols), Cols =:= 5.

test(pad_colors) :-
    % Top row all PadColor.
    grid_dot(G),
    mo_pad(G, 9, G2),
    G2 = [TopRow|_],
    maplist(==(9), TopRow).

:- end_tests(morph_mo_pad).

:- begin_tests(morph_mo_unpad).

test(unpad_recovers) :-
    % pad then unpad returns original grid.
    grid_dot(G),
    mo_pad(G, 0, G2),
    mo_unpad(G2, G3),
    G3 = G.

test(unpad_size) :-
    % 5x5 -> unpad -> 3x3.
    G = [[1,1,1,1,1],[1,1,1,1,1],[1,1,1,1,1],[1,1,1,1,1],[1,1,1,1,1]],
    mo_unpad(G, G2),
    length(G2, R), R =:= 3,
    G2 = [Row|_], length(Row, C), C =:= 3.

:- end_tests(morph_mo_unpad).
