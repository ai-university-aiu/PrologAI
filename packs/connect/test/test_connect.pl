% PLUnit tests for the connect pack (cc_* predicates).
:- use_module(library(plunit)).
:- use_module(library(connect)).

% Sample grids.
% grid_isolated: four 1s with no 4-connections.
%   1 0 1
%   0 0 0
%   1 0 1
grid_isolated([[1,0,1],[0,0,0],[1,0,1]]).

% grid_blob: one connected blob of 1s top-left, one isolated 1 bottom-right.
%   1 1 0
%   1 0 0
%   0 0 1
grid_blob([[1,1,0],[1,0,0],[0,0,1]]).

% grid_ring: ring of 1s surrounding a 0 interior.
%   1 1 1
%   1 0 1
%   1 1 1
grid_ring([[1,1,1],[1,0,1],[1,1,1]]).

% grid_diagonal: 1s on main diagonal only (8-connected but not 4-connected).
%   1 0 0
%   0 1 0
%   0 0 1
grid_diagonal([[1,0,0],[0,1,0],[0,0,1]]).

% grid_solid5: 5x5 all-1s grid for interior/border testing.
grid_solid5([[1,1,1,1,1],[1,1,1,1,1],[1,1,1,1,1],[1,1,1,1,1],[1,1,1,1,1]]).

:- begin_tests(connect_cc_flood4).

test(flood4_single_cell) :-
    % Isolated 1 at (0,0): only that cell returned.
    grid_isolated(G),
    cc_flood4(G, r(0,0), 1, R),
    msort(R, S), S = [r(0,0)].

test(flood4_blob) :-
    % 3-cell blob in grid_blob starting at (0,0).
    grid_blob(G),
    cc_flood4(G, r(0,0), 1, R),
    msort(R, S), S = [r(0,0), r(0,1), r(1,0)].

test(flood4_wrong_color) :-
    % Seed has wrong color: empty region.
    grid_isolated(G),
    cc_flood4(G, r(1,1), 1, R),
    R = [].

test(flood4_whole_ring) :-
    % Flood fill ring of 1s: all 8 border cells.
    grid_ring(G),
    cc_flood4(G, r(0,0), 1, R),
    msort(R, S),
    S = [r(0,0),r(0,1),r(0,2),r(1,0),r(1,2),r(2,0),r(2,1),r(2,2)].

:- end_tests(connect_cc_flood4).

:- begin_tests(connect_cc_flood8).

test(flood8_diagonal) :-
    % Diagonal 1s are 8-connected: all three found.
    grid_diagonal(G),
    cc_flood8(G, r(0,0), 1, R),
    msort(R, S), S = [r(0,0), r(1,1), r(2,2)].

test(flood8_single_when_not_diagonal) :-
    % Isolated 1 at (0,2) in grid_isolated: only that cell.
    grid_isolated(G),
    cc_flood8(G, r(0,2), 1, R),
    msort(R, S), S = [r(0,2)].

test(flood8_blob) :-
    % 3-cell blob: same result as 4-connected.
    grid_blob(G),
    cc_flood8(G, r(0,0), 1, R),
    msort(R, S), S = [r(0,0), r(0,1), r(1,0)].

:- end_tests(connect_cc_flood8).

:- begin_tests(connect_cc_components4).

test(components4_isolated) :-
    % Four isolated 1s: four components each of size 1.
    grid_isolated(G),
    cc_components4(G, 1, Comps),
    length(Comps, 4),
    maplist(length, Comps, Sizes),
    msort(Sizes, [1,1,1,1]).

test(components4_blob) :-
    % grid_blob: two components (3-cell blob + 1-cell isolated).
    grid_blob(G),
    cc_components4(G, 1, Comps),
    length(Comps, 2),
    maplist(length, Comps, Sizes),
    msort(Sizes, [1,3]).

test(components4_none) :-
    % No 5s in grid_isolated: empty list.
    grid_isolated(G),
    cc_components4(G, 5, Comps),
    Comps = [].

test(components4_ring) :-
    % Ring of 1s: one 4-connected component of 8 cells.
    grid_ring(G),
    cc_components4(G, 1, Comps),
    length(Comps, 1),
    Comps = [C], length(C, 8).

:- end_tests(connect_cc_components4).

:- begin_tests(connect_cc_components8).

test(components8_diagonal) :-
    % Diagonal 1s: one 8-connected component of 3 cells.
    grid_diagonal(G),
    cc_components8(G, 1, Comps),
    length(Comps, 1),
    Comps = [C], length(C, 3).

test(components8_isolated) :-
    % Four isolated 1s with no diagonal neighbors: four components.
    grid_isolated(G),
    cc_components8(G, 1, Comps),
    length(Comps, 4).

:- end_tests(connect_cc_components8).

:- begin_tests(connect_cc_count4).

test(count4_isolated) :-
    grid_isolated(G),
    cc_count4(G, 1, N), N =:= 4.

test(count4_blob) :-
    grid_blob(G),
    cc_count4(G, 1, N), N =:= 2.

test(count4_none) :-
    grid_isolated(G),
    cc_count4(G, 9, N), N =:= 0.

:- end_tests(connect_cc_count4).

:- begin_tests(connect_cc_count8).

test(count8_diagonal) :-
    grid_diagonal(G),
    cc_count8(G, 1, N), N =:= 1.

test(count8_none) :-
    grid_diagonal(G),
    cc_count8(G, 9, N), N =:= 0.

:- end_tests(connect_cc_count8).

:- begin_tests(connect_cc_sizes4).

test(sizes4_isolated) :-
    % Four components each of size 1.
    grid_isolated(G),
    cc_sizes4(G, 1, Sizes),
    Sizes = [1,1,1,1].

test(sizes4_blob) :-
    % Sizes: [1, 3] sorted.
    grid_blob(G),
    cc_sizes4(G, 1, Sizes),
    Sizes = [1,3].

test(sizes4_none) :-
    grid_isolated(G),
    cc_sizes4(G, 9, Sizes),
    Sizes = [].

:- end_tests(connect_cc_sizes4).

:- begin_tests(connect_cc_sizes8).

test(sizes8_diagonal) :-
    % One component of size 3.
    grid_diagonal(G),
    cc_sizes8(G, 1, Sizes),
    Sizes = [3].

:- end_tests(connect_cc_sizes8).

:- begin_tests(connect_cc_largest4).

test(largest4_blob) :-
    % Largest component has 3 cells.
    grid_blob(G),
    cc_largest4(G, 1, Largest),
    msort(Largest, S),
    S = [r(0,0), r(0,1), r(1,0)].

test(largest4_ring) :-
    % Only one component (8 cells): that is the largest.
    grid_ring(G),
    cc_largest4(G, 1, Largest),
    length(Largest, N), N =:= 8.

:- end_tests(connect_cc_largest4).

:- begin_tests(connect_cc_largest8).

test(largest8_diagonal) :-
    % One 8-connected component of 3 cells.
    grid_diagonal(G),
    cc_largest8(G, 1, Largest),
    length(Largest, N), N =:= 3.

:- end_tests(connect_cc_largest8).

:- begin_tests(connect_cc_smallest4).

test(smallest4_blob) :-
    % Smallest component has 1 cell.
    grid_blob(G),
    cc_smallest4(G, 1, Smallest),
    length(Smallest, N), N =:= 1.

test(smallest4_equal_sizes) :-
    % Four components each of size 1: smallest is size 1.
    grid_isolated(G),
    cc_smallest4(G, 1, Smallest),
    length(Smallest, N), N =:= 1.

:- end_tests(connect_cc_smallest4).

:- begin_tests(connect_cc_border_cells).

test(border_cells_ring) :-
    % Ring of 1s: all 8 cells are border (each has at least one non-ring neighbor).
    grid_ring(G),
    cc_components4(G, 1, [Ring]),
    cc_border_cells(G, Ring, Border),
    length(Border, N), N =:= 8.

test(border_cells_solid5) :-
    % Solid 5x5: only outer ring of 16 cells are border.
    grid_solid5(G),
    cc_components4(G, 1, [All]),
    cc_border_cells(G, All, Border),
    length(Border, N), N =:= 16.

:- end_tests(connect_cc_border_cells).

:- begin_tests(connect_cc_interior_cells).

test(interior_cells_solid5) :-
    % Solid 5x5: inner 3x3 = 9 cells are interior.
    grid_solid5(G),
    cc_components4(G, 1, [All]),
    cc_interior_cells(G, All, Interior),
    length(Interior, N), N =:= 9.

test(interior_cells_ring) :-
    % Ring of 1s: no interior cells (each cell has a non-ring neighbor).
    grid_ring(G),
    cc_components4(G, 1, [Ring]),
    cc_interior_cells(G, Ring, Interior),
    Interior = [].

:- end_tests(connect_cc_interior_cells).

:- begin_tests(connect_cc_enclosed).

test(enclosed_ring) :-
    % Center 0 in grid_ring is enclosed.
    grid_ring(G),
    cc_enclosed(G, 0, Enclosed),
    Enclosed = [r(1,1)].

test(enclosed_none) :-
    % Isolated cells: all 0s connect to border.
    grid_isolated(G),
    cc_enclosed(G, 0, Enclosed),
    Enclosed = [].

:- end_tests(connect_cc_enclosed).
