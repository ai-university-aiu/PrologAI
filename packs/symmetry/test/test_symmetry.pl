% PLUnit tests for the symmetry pack (sy_* predicates).
:- use_module(library(plunit)).
:- use_module(library(grid)).
:- use_module(library(symmetry)).

% Grid fixtures.
% A 3x3 grid that is horizontally symmetric (left-right mirror).
hsym_grid(Grid) :-
    Grid = [[1,2,1],
            [3,4,3],
            [5,6,5]].

% A 3x3 grid that is vertically symmetric (top-bottom mirror).
vsym_grid(Grid) :-
    Grid = [[1,2,3],
            [4,5,6],
            [1,2,3]].

% A 3x3 grid with 180-degree rotational symmetry.
rot180_grid(Grid) :-
    Grid = [[1,2,3],
            [4,5,4],
            [3,2,1]].

% A 3x3 fully symmetric grid: all symmetries hold.
full_sym_grid(Grid) :-
    Grid = [[1,1,1],
            [1,2,1],
            [1,1,1]].

% A 3x3 asymmetric grid.
asym_grid(Grid) :-
    Grid = [[1,2,3],
            [4,5,6],
            [7,8,9]].

% A 4x4 grid with only 90-degree rotational symmetry (square, rot90).
rot90_grid(Grid) :-
    Grid = [[1,2,1,0],
            [0,1,0,2],
            [2,0,1,0],
            [0,1,2,1]].

% A 3x3 grid with main-diagonal symmetry.
diag_grid(Grid) :-
    Grid = [[1,2,3],
            [2,5,6],
            [3,6,9]].

% A simple 2x2 uniform grid.
uniform_2x2(Grid) :-
    Grid = [[7,7],[7,7]].

:- begin_tests(symmetry_hsym).

test(hsym_yes) :-
    hsym_grid(G),
    symmetry_is_hsymmetric(G).

test(hsym_full) :-
    full_sym_grid(G),
    symmetry_is_hsymmetric(G).

test(hsym_no, [fail]) :-
    asym_grid(G),
    symmetry_is_hsymmetric(G).

test(vsym_no_is_hsym, [fail]) :-
    vsym_grid(G),
    symmetry_is_hsymmetric(G).

:- end_tests(symmetry_hsym).

:- begin_tests(symmetry_vsym).

test(vsym_yes) :-
    vsym_grid(G),
    symmetry_is_vsymmetric(G).

test(vsym_full) :-
    full_sym_grid(G),
    symmetry_is_vsymmetric(G).

test(vsym_no, [fail]) :-
    asym_grid(G),
    symmetry_is_vsymmetric(G).

:- end_tests(symmetry_vsym).

:- begin_tests(symmetry_rot180).

test(rot180_yes) :-
    rot180_grid(G),
    symmetry_is_rot180(G).

test(rot180_full) :-
    full_sym_grid(G),
    symmetry_is_rot180(G).

test(rot180_no, [fail]) :-
    asym_grid(G),
    symmetry_is_rot180(G).

:- end_tests(symmetry_rot180).

:- begin_tests(symmetry_rot90).

test(rot90_full) :-
    full_sym_grid(G),
    symmetry_is_rot90(G).

test(rot90_uniform) :-
    uniform_2x2(G),
    symmetry_is_rot90(G).

test(rot90_asym_no, [fail]) :-
    asym_grid(G),
    symmetry_is_rot90(G).

:- end_tests(symmetry_rot90).

:- begin_tests(symmetry_diagonal).

test(diag_yes) :-
    diag_grid(G),
    symmetry_is_diagonal(G).

test(diag_full) :-
    full_sym_grid(G),
    symmetry_is_diagonal(G).

test(diag_no, [fail]) :-
    asym_grid(G),
    symmetry_is_diagonal(G).

:- end_tests(symmetry_diagonal).

:- begin_tests(symmetry_antidiagonal).

test(antidiag_full) :-
    full_sym_grid(G),
    symmetry_is_antidiagonal(G).

test(antidiag_uniform) :-
    uniform_2x2(G),
    symmetry_is_antidiagonal(G).

test(antidiag_asym_no, [fail]) :-
    asym_grid(G),
    symmetry_is_antidiagonal(G).

:- end_tests(symmetry_antidiagonal).

:- begin_tests(symmetry_group).

test(group_full, [nondet]) :-
    full_sym_grid(G),
    symmetry_group(G, Group),
    % All 6 symmetries should hold for the fully symmetric grid.
    length(Group, 6).

test(group_hsym, [nondet]) :-
    hsym_grid(G),
    symmetry_group(G, Group),
    member(h, Group),
    \+ member(v, Group).

test(group_asym, [nondet]) :-
    asym_grid(G),
    symmetry_group(G, Group),
    Group = [].

:- end_tests(symmetry_group).

:- begin_tests(symmetry_rotations).

test(rotations_asym, [nondet]) :-
    % Asymmetric grid: all 4 rotations are distinct.
    asym_grid(G),
    symmetry_rotations(G, Rots),
    length(Rots, 4).

test(rotations_rot180, [nondet]) :-
    % rot180 grid: R0=R180, R90=R270, so 2 distinct rotations.
    rot180_grid(G),
    symmetry_rotations(G, Rots),
    length(Rots, 2).

test(rotations_full, [nondet]) :-
    % Fully symmetric: all rotations are the same, so 1 distinct.
    full_sym_grid(G),
    symmetry_rotations(G, Rots),
    length(Rots, 1).

:- end_tests(symmetry_rotations).

:- begin_tests(symmetry_orbit).

test(orbit_asym, [nondet]) :-
    % Asymmetric grid: full 8-element orbit.
    asym_grid(G),
    symmetry_orbit(G, Orbit),
    length(Orbit, 8).

test(orbit_full, [nondet]) :-
    % Fully symmetric: orbit has 1 element.
    full_sym_grid(G),
    symmetry_orbit(G, Orbit),
    length(Orbit, 1).

test(orbit_hsym, [nondet]) :-
    % Horizontally symmetric: orbit has 4 elements (h and v_of_h collapse).
    hsym_grid(G),
    symmetry_orbit(G, Orbit),
    length(Orbit, 4).

:- end_tests(symmetry_orbit).

:- begin_tests(symmetry_canonical).

test(canonical_same_for_equiv, [nondet]) :-
    asym_grid(G),
    grid_rotate90(G, R90),
    symmetry_canonical(G, C1),
    symmetry_canonical(R90, C2),
    grid_equal(C1, C2).

test(canonical_is_in_orbit, [nondet]) :-
    asym_grid(G),
    symmetry_canonical(G, Canon),
    symmetry_orbit(G, Orbit),
    include(symmetry_matches_canon_(Canon), Orbit, Matching),
    Matching = [_].

:- end_tests(symmetry_canonical).

% symmetry_matches_canon_(Canon, Grid) - helper for include.
symmetry_matches_canon_(Canon, Grid) :-
    grid_equal(Canon, Grid).

:- begin_tests(symmetry_equivalent).

test(equiv_rotation, [nondet]) :-
    asym_grid(G),
    grid_rotate90(G, R90),
    symmetry_equivalent(G, R90).

test(equiv_reflection, [nondet]) :-
    asym_grid(G),
    grid_reflect_v(G, Flip),
    symmetry_equivalent(G, Flip).

test(not_equiv, [fail]) :-
    asym_grid(G),
    % A different grid (not in the orbit of asym_grid).
    full_sym_grid(H),
    symmetry_equivalent(G, H).

:- end_tests(symmetry_equivalent).

:- begin_tests(symmetry_order).

test(order_full, [nondet]) :-
    % Fully symmetric: order 8 (all transforms stabilize it).
    full_sym_grid(G),
    symmetry_order(G, N),
    N =:= 8.

test(order_asym, [nondet]) :-
    % Asymmetric: orbit = 8, order = 1.
    asym_grid(G),
    symmetry_order(G, N),
    N =:= 1.

test(order_rot180, [nondet]) :-
    % 180-symmetric only: orbit = 4, order = 2.
    rot180_grid(G),
    symmetry_order(G, N),
    N =:= 2.

:- end_tests(symmetry_order).
