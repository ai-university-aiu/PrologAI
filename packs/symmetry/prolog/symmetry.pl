% Module symmetry: grid symmetry testing, canonical orientation, and orbit generation.
% Layer 44. Prefix: sy_. Depends on grid pack only.
:- module(symmetry, [
    % Test horizontal reflection symmetry (left-right mirror).
    symmetry_is_hsymmetric/1,
    % Test vertical reflection symmetry (top-bottom mirror).
    symmetry_is_vsymmetric/1,
    % Test 180-degree rotational symmetry.
    symmetry_is_rot180/1,
    % Test 90-degree rotational symmetry (square grids only).
    symmetry_is_rot90/1,
    % Test diagonal symmetry (transpose = self, square grids only).
    symmetry_is_diagonal/1,
    % Test anti-diagonal symmetry (anti-transpose = self, square grids only).
    symmetry_is_antidiagonal/1,
    % Return the symmetry group: list of symmetry atoms that hold.
    symmetry_group/2,
    % Compute all distinct rotations of a grid (1, 2, or 4 variants).
    symmetry_rotations/2,
    % Compute all distinct reflections and rotations (the full dihedral orbit).
    symmetry_orbit/2,
    % Return the canonical (lexicographically smallest) orientation of a grid.
    symmetry_canonical/2,
    % Test whether two grids are equivalent under any rotation or reflection.
    symmetry_equivalent/2,
    % Count the symmetry order (size of the stabilizer = number of transforms
    % that map the grid to itself).
    symmetry_order/2
]).

% Load list utilities.
:- use_module(library(lists), [member/2, append/2, append/3, numlist/3, last/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, include/3, foldl/4]).
% Load grid pack.
:- use_module(library(grid)).

% symmetry_is_hsymmetric(+Grid)
% Grid is horizontally symmetric (left-right mirror): Grid = grid_reflect_v(Grid).
% grid_reflect_v reverses each row (left-right reflection).
symmetry_is_hsymmetric(Grid) :-
    grid_reflect_v(Grid, Grid2),
    grid_equal(Grid, Grid2).

% symmetry_is_vsymmetric(+Grid)
% Grid is vertically symmetric (top-bottom mirror): Grid = grid_reflect_h(Grid).
% grid_reflect_h reverses the row order (top-bottom reflection).
symmetry_is_vsymmetric(Grid) :-
    grid_reflect_h(Grid, Grid2),
    grid_equal(Grid, Grid2).

% symmetry_is_rot180(+Grid)
% Grid is invariant under 180-degree rotation.
symmetry_is_rot180(Grid) :-
    grid_rotate90(Grid, R90),
    grid_rotate90(R90, R180),
    grid_equal(Grid, R180).

% symmetry_is_rot90(+Grid)
% Grid is invariant under 90-degree clockwise rotation.
% Only possible for square grids.
symmetry_is_rot90(Grid) :-
    grid_size(Grid, Rows, Cols),
    Rows =:= Cols,
    grid_rotate90(Grid, Grid2),
    grid_equal(Grid, Grid2).

% symmetry_is_diagonal(+Grid)
% Grid equals its main-diagonal reflection (grid_reflect_d1 = transpose).
symmetry_is_diagonal(Grid) :-
    grid_size(Grid, Rows, Cols),
    Rows =:= Cols,
    grid_reflect_d1(Grid, Grid2),
    grid_equal(Grid, Grid2).

% symmetry_is_antidiagonal(+Grid)
% Grid equals its anti-diagonal reflection (grid_reflect_d2).
symmetry_is_antidiagonal(Grid) :-
    grid_size(Grid, Rows, Cols),
    Rows =:= Cols,
    grid_reflect_d2(Grid, Grid2),
    grid_equal(Grid, Grid2).

% symmetry_group(+Grid, -Group)
% Group is the list of symmetry atoms that hold for Grid.
% Atoms: h (horizontal), v (vertical), rot180, rot90, diag, antidiag.
symmetry_group(Grid, Group) :-
    findall(Sym,
        (   member(Sym, [h, v, rot180, rot90, diag, antidiag]),
            symmetry_test_sym_(Grid, Sym)
        ),
        Group).

% symmetry_test_sym_(Grid, Sym) - dispatch to the appropriate test predicate.
symmetry_test_sym_(Grid, h)        :- symmetry_is_hsymmetric(Grid).
symmetry_test_sym_(Grid, v)        :- symmetry_is_vsymmetric(Grid).
symmetry_test_sym_(Grid, rot180)   :- symmetry_is_rot180(Grid).
symmetry_test_sym_(Grid, rot90)    :- symmetry_is_rot90(Grid).
symmetry_test_sym_(Grid, diag)     :- symmetry_is_diagonal(Grid).
symmetry_test_sym_(Grid, antidiag) :- symmetry_is_antidiagonal(Grid).

% symmetry_rotations(+Grid, -Rotations)
% All distinct rotations of Grid: R0 (identity), R90, R180, R270.
% Distinct means equal rotations are included only once.
symmetry_rotations(Grid, Rotations) :-
    grid_rotate90(Grid, R90),
    grid_rotate90(R90, R180),
    grid_rotate90(R180, R270),
    symmetry_unique_grids_([Grid, R90, R180, R270], Rotations).

% symmetry_orbit(+Grid, -Orbit)
% The dihedral orbit: all distinct grids reachable by rotations and reflections.
% Maximum 8 elements (4 rotations x 2 for reflection).
symmetry_orbit(Grid, Orbit) :-
    grid_reflect_v(Grid, HFlip),
    symmetry_rotations(Grid, Rots),
    symmetry_rotations(HFlip, FlipRots),
    append(Rots, FlipRots, All),
    symmetry_unique_grids_(All, Orbit).

% symmetry_unique_grids_(+Grids, -Unique)
% Remove duplicate grids (by grid equality) from a list, preserving order.
symmetry_unique_grids_([], []).
symmetry_unique_grids_([G|Gs], [G|Unique]) :-
    include(symmetry_not_equal_(G), Gs, Gs2),
    symmetry_unique_grids_(Gs2, Unique).

% symmetry_not_equal_(A, B) - true if A and B are NOT grid-equal.
symmetry_not_equal_(A, B) :-
    \+ grid_equal(A, B).

% symmetry_canonical(+Grid, -Canon)
% The lexicographically smallest element of symmetry_orbit(Grid).
symmetry_canonical(Grid, Canon) :-
    symmetry_orbit(Grid, Orbit),
    foldl(symmetry_lex_min_, Orbit, none, Canon0),
    Canon0 \= none,
    Canon = Canon0.

% symmetry_lex_min_(Grid, Acc, NewAcc) - keep the lex-smaller of Grid and Acc.
symmetry_lex_min_(Grid, none, Grid) :- !.
symmetry_lex_min_(Grid, Best, NewBest) :-
    (Grid @< Best -> NewBest = Grid ; NewBest = Best).

% symmetry_equivalent(+GridA, +GridB)
% Succeed if GridA and GridB are in the same dihedral orbit.
symmetry_equivalent(GridA, GridB) :-
    symmetry_canonical(GridA, Canon),
    symmetry_canonical(GridB, Canon2),
    grid_equal(Canon, Canon2).

% symmetry_order(+Grid, -N)
% N is the number of distinct transforms (from the 8-element dihedral group)
% that map Grid to itself. Values: 1, 2, 4, or 8.
symmetry_order(Grid, N) :-
    symmetry_orbit(Grid, Orbit),
    length(Orbit, OrbitSize),
    N is 8 // OrbitSize.
