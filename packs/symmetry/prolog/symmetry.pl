% Module symmetry: grid symmetry testing, canonical orientation, and orbit generation.
% Layer 44. Prefix: sy_. Depends on grid pack only.
:- module(symmetry, [
    % Test horizontal reflection symmetry (left-right mirror).
    sy_is_hsymmetric/1,
    % Test vertical reflection symmetry (top-bottom mirror).
    sy_is_vsymmetric/1,
    % Test 180-degree rotational symmetry.
    sy_is_rot180/1,
    % Test 90-degree rotational symmetry (square grids only).
    sy_is_rot90/1,
    % Test diagonal symmetry (transpose = self, square grids only).
    sy_is_diagonal/1,
    % Test anti-diagonal symmetry (anti-transpose = self, square grids only).
    sy_is_antidiagonal/1,
    % Return the symmetry group: list of symmetry atoms that hold.
    sy_group/2,
    % Compute all distinct rotations of a grid (1, 2, or 4 variants).
    sy_rotations/2,
    % Compute all distinct reflections and rotations (the full dihedral orbit).
    sy_orbit/2,
    % Return the canonical (lexicographically smallest) orientation of a grid.
    sy_canonical/2,
    % Test whether two grids are equivalent under any rotation or reflection.
    sy_equivalent/2,
    % Count the symmetry order (size of the stabilizer = number of transforms
    % that map the grid to itself).
    sy_order/2
]).

% Load list utilities.
:- use_module(library(lists), [member/2, append/2, append/3, numlist/3, last/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, include/3, foldl/4]).
% Load grid pack.
:- use_module(library(grid)).

% sy_is_hsymmetric(+Grid)
% Grid is horizontally symmetric (left-right mirror): Grid = gd_reflect_v(Grid).
% gd_reflect_v reverses each row (left-right reflection).
sy_is_hsymmetric(Grid) :-
    gd_reflect_v(Grid, Grid2),
    gd_equal(Grid, Grid2).

% sy_is_vsymmetric(+Grid)
% Grid is vertically symmetric (top-bottom mirror): Grid = gd_reflect_h(Grid).
% gd_reflect_h reverses the row order (top-bottom reflection).
sy_is_vsymmetric(Grid) :-
    gd_reflect_h(Grid, Grid2),
    gd_equal(Grid, Grid2).

% sy_is_rot180(+Grid)
% Grid is invariant under 180-degree rotation.
sy_is_rot180(Grid) :-
    gd_rotate90(Grid, R90),
    gd_rotate90(R90, R180),
    gd_equal(Grid, R180).

% sy_is_rot90(+Grid)
% Grid is invariant under 90-degree clockwise rotation.
% Only possible for square grids.
sy_is_rot90(Grid) :-
    gd_size(Grid, Rows, Cols),
    Rows =:= Cols,
    gd_rotate90(Grid, Grid2),
    gd_equal(Grid, Grid2).

% sy_is_diagonal(+Grid)
% Grid equals its main-diagonal reflection (gd_reflect_d1 = transpose).
sy_is_diagonal(Grid) :-
    gd_size(Grid, Rows, Cols),
    Rows =:= Cols,
    gd_reflect_d1(Grid, Grid2),
    gd_equal(Grid, Grid2).

% sy_is_antidiagonal(+Grid)
% Grid equals its anti-diagonal reflection (gd_reflect_d2).
sy_is_antidiagonal(Grid) :-
    gd_size(Grid, Rows, Cols),
    Rows =:= Cols,
    gd_reflect_d2(Grid, Grid2),
    gd_equal(Grid, Grid2).

% sy_group(+Grid, -Group)
% Group is the list of symmetry atoms that hold for Grid.
% Atoms: h (horizontal), v (vertical), rot180, rot90, diag, antidiag.
sy_group(Grid, Group) :-
    findall(Sym,
        (   member(Sym, [h, v, rot180, rot90, diag, antidiag]),
            sy_test_sym_(Grid, Sym)
        ),
        Group).

% sy_test_sym_(Grid, Sym) - dispatch to the appropriate test predicate.
sy_test_sym_(Grid, h)        :- sy_is_hsymmetric(Grid).
sy_test_sym_(Grid, v)        :- sy_is_vsymmetric(Grid).
sy_test_sym_(Grid, rot180)   :- sy_is_rot180(Grid).
sy_test_sym_(Grid, rot90)    :- sy_is_rot90(Grid).
sy_test_sym_(Grid, diag)     :- sy_is_diagonal(Grid).
sy_test_sym_(Grid, antidiag) :- sy_is_antidiagonal(Grid).

% sy_rotations(+Grid, -Rotations)
% All distinct rotations of Grid: R0 (identity), R90, R180, R270.
% Distinct means equal rotations are included only once.
sy_rotations(Grid, Rotations) :-
    gd_rotate90(Grid, R90),
    gd_rotate90(R90, R180),
    gd_rotate90(R180, R270),
    sy_unique_grids_([Grid, R90, R180, R270], Rotations).

% sy_orbit(+Grid, -Orbit)
% The dihedral orbit: all distinct grids reachable by rotations and reflections.
% Maximum 8 elements (4 rotations x 2 for reflection).
sy_orbit(Grid, Orbit) :-
    gd_reflect_v(Grid, HFlip),
    sy_rotations(Grid, Rots),
    sy_rotations(HFlip, FlipRots),
    append(Rots, FlipRots, All),
    sy_unique_grids_(All, Orbit).

% sy_unique_grids_(+Grids, -Unique)
% Remove duplicate grids (by grid equality) from a list, preserving order.
sy_unique_grids_([], []).
sy_unique_grids_([G|Gs], [G|Unique]) :-
    include(sy_not_equal_(G), Gs, Gs2),
    sy_unique_grids_(Gs2, Unique).

% sy_not_equal_(A, B) - true if A and B are NOT grid-equal.
sy_not_equal_(A, B) :-
    \+ gd_equal(A, B).

% sy_canonical(+Grid, -Canon)
% The lexicographically smallest element of sy_orbit(Grid).
sy_canonical(Grid, Canon) :-
    sy_orbit(Grid, Orbit),
    foldl(sy_lex_min_, Orbit, none, Canon0),
    Canon0 \= none,
    Canon = Canon0.

% sy_lex_min_(Grid, Acc, NewAcc) - keep the lex-smaller of Grid and Acc.
sy_lex_min_(Grid, none, Grid) :- !.
sy_lex_min_(Grid, Best, NewBest) :-
    (Grid @< Best -> NewBest = Grid ; NewBest = Best).

% sy_equivalent(+GridA, +GridB)
% Succeed if GridA and GridB are in the same dihedral orbit.
sy_equivalent(GridA, GridB) :-
    sy_canonical(GridA, Canon),
    sy_canonical(GridB, Canon2),
    gd_equal(Canon, Canon2).

% sy_order(+Grid, -N)
% N is the number of distinct transforms (from the 8-element dihedral group)
% that map Grid to itself. Values: 1, 2, 4, or 8.
sy_order(Grid, N) :-
    sy_orbit(Grid, Orbit),
    length(Orbit, OrbitSize),
    N is 8 // OrbitSize.
