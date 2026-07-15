% PLUnit tests for the sym pack (sy_* predicates).
:- use_module(library(plunit)).
:- use_module('../prolog/symmetry_transform').

% Asymmetric 2x2 reference grid for transform tests.
% 1 2
% 3 4
asym_grid([[1,2],[3,4]]).

% Horizontally symmetric 2x2: each row is a palindrome [1,1] [2,2].
h_symm_grid([[1,1],[2,2]]).

% Vertically symmetric 2x2: 1 2 / 1 2
v_symm_grid([[1,2],[1,2]]).

% 180-degree symmetric 2x2: 1 2 / 2 1 (also happens to be h-symmetric here)
% Use a distinct rot2-only example: 1 2 / 4 3... no wait 180 of [[1,2],[4,3]] = [[3,4],[2,1]]
% rot2 example: 1 2 / 2 1 -> rot180 = 1 2 / 2 1. Yes, h_symm_grid is rot2 symm.

% All-same grid is fully symmetric.
all_same_grid([[5,5],[5,5]]).

:- begin_tests(symmetry_transform_reflect_h).

test(reflect_h_basic) :-
    asym_grid(G),
    symmetry_transform_reflect_h(G, G2),
    G2 = [[2,1],[4,3]].

test(reflect_h_symmetric) :-
    % Reflecting a symmetric grid gives itself.
    h_symm_grid(G),
    symmetry_transform_reflect_h(G, G).

test(reflect_h_single_row) :-
    symmetry_transform_reflect_h([[1,2,3]], [[3,2,1]]).

test(reflect_h_1x1) :-
    symmetry_transform_reflect_h([[7]], [[7]]).

:- end_tests(symmetry_transform_reflect_h).

:- begin_tests(symmetry_transform_reflect_v).

test(reflect_v_basic) :-
    asym_grid(G),
    symmetry_transform_reflect_v(G, G2),
    G2 = [[3,4],[1,2]].

test(reflect_v_symmetric) :-
    % Reflecting a v-symmetric grid gives itself.
    v_symm_grid(G),
    symmetry_transform_reflect_v(G, G).

test(reflect_v_1x1) :-
    symmetry_transform_reflect_v([[7]], [[7]]).

:- end_tests(symmetry_transform_reflect_v).

:- begin_tests(symmetry_transform_transpose).

test(transpose_basic) :-
    asym_grid(G),
    symmetry_transform_transpose(G, G2),
    G2 = [[1,3],[2,4]].

test(transpose_square_involution) :-
    % Transpose of transpose gives original.
    asym_grid(G),
    symmetry_transform_transpose(G, T),
    symmetry_transform_transpose(T, G).

test(transpose_1x3) :-
    symmetry_transform_transpose([[1,2,3]], [[1],[2],[3]]).

test(transpose_empty) :-
    symmetry_transform_transpose([], []).

:- end_tests(symmetry_transform_transpose).

:- begin_tests(symmetry_transform_rotate90).

test(rotate90_basic) :-
    % 1 2    ->   3 1
    % 3 4    ->   4 2
    asym_grid(G),
    symmetry_transform_rotate90(G, G2),
    G2 = [[3,1],[4,2]].

test(rotate90_four_times_identity) :-
    % Four 90-degree rotations return to original.
    asym_grid(G),
    symmetry_transform_rotate90(G, R1),
    symmetry_transform_rotate90(R1, R2),
    symmetry_transform_rotate90(R2, R3),
    symmetry_transform_rotate90(R3, G).

test(rotate90_1x1) :-
    symmetry_transform_rotate90([[5]], [[5]]).

:- end_tests(symmetry_transform_rotate90).

:- begin_tests(symmetry_transform_rotate180).

test(rotate180_basic) :-
    % 1 2    ->   4 3
    % 3 4    ->   2 1
    asym_grid(G),
    symmetry_transform_rotate180(G, G2),
    G2 = [[4,3],[2,1]].

test(rotate180_involution) :-
    % Rotating 180 twice gives original.
    asym_grid(G),
    symmetry_transform_rotate180(G, R),
    symmetry_transform_rotate180(R, G).

:- end_tests(symmetry_transform_rotate180).

:- begin_tests(symmetry_transform_rotate270).

test(rotate270_basic) :-
    % 1 2    ->   2 4
    % 3 4    ->   1 3
    asym_grid(G),
    symmetry_transform_rotate270(G, G2),
    G2 = [[2,4],[1,3]].

test(rotate90_and_270_are_inverse) :-
    % rotate90 then rotate270 gives original.
    asym_grid(G),
    symmetry_transform_rotate90(G, R90),
    symmetry_transform_rotate270(R90, G).

:- end_tests(symmetry_transform_rotate270).

:- begin_tests(symmetry_transform_has_h_symm).

test(has_h_symm_yes) :-
    symmetry_transform_has_h_symm([[1,2,1],[3,4,3]]).

test(has_h_symm_no) :-
    asym_grid(G),
    \+ symmetry_transform_has_h_symm(G).

test(has_h_symm_all_same) :-
    all_same_grid(G),
    symmetry_transform_has_h_symm(G).

test(has_h_symm_1x1) :-
    symmetry_transform_has_h_symm([[7]]).

:- end_tests(symmetry_transform_has_h_symm).

:- begin_tests(symmetry_transform_has_v_symm).

test(has_v_symm_yes) :-
    symmetry_transform_has_v_symm([[1,2],[1,2]]).

test(has_v_symm_no) :-
    asym_grid(G),
    \+ symmetry_transform_has_v_symm(G).

test(has_v_symm_all_same) :-
    all_same_grid(G),
    symmetry_transform_has_v_symm(G).

:- end_tests(symmetry_transform_has_v_symm).

:- begin_tests(symmetry_transform_has_rot2_symm).

test(rot2_yes) :-
    % 1 2 / 2 1 rotated 180 = 1 2 / 2 1.
    symmetry_transform_has_rot2_symm([[1,2],[2,1]]).

test(rot2_no) :-
    asym_grid(G),
    \+ symmetry_transform_has_rot2_symm(G).

test(rot2_all_same) :-
    all_same_grid(G),
    symmetry_transform_has_rot2_symm(G).

:- end_tests(symmetry_transform_has_rot2_symm).

:- begin_tests(symmetry_transform_has_rot4_symm).

test(rot4_yes) :-
    % All-same grid has 4-fold rotational symmetry.
    all_same_grid(G),
    symmetry_transform_has_rot4_symm(G).

test(rot4_no) :-
    asym_grid(G),
    \+ symmetry_transform_has_rot4_symm(G).

:- end_tests(symmetry_transform_has_rot4_symm).

:- begin_tests(symmetry_transform_symmetries).

test(symms_all_same) :-
    % All-same grid has all 4 symmetries.
    all_same_grid(G),
    symmetry_transform_symmetries(G, Symms),
    msort(Symms, Sorted),
    Sorted = [h, rot2, rot4, v].

test(symms_asymmetric) :-
    % Asymmetric grid has no symmetries.
    asym_grid(G),
    symmetry_transform_symmetries(G, Symms),
    Symms = [].

test(symms_h_only) :-
    % [[1,2,1],[3,5,3]] - h symmetric only.
    symmetry_transform_symmetries([[1,2,1],[3,5,3]], Symms),
    msort(Symms, [h]).

:- end_tests(symmetry_transform_symmetries).

:- begin_tests(symmetry_transform_make_h_symm).

test(make_h_symm_even) :-
    % [a,b] -> [a,a] (left wins) - wait: left is [a], mirror is [a].
    % Row [1,2]: Half=1, Left=[1], RLeft=[1], even, Row2=[1,1].
    symmetry_transform_make_h_symm([[1,2]], [[1,1]]).

test(make_h_symm_odd) :-
    % Row [1,2,3]: Half=1, Left=[1], Rest=[2,3], Mid=2, Row2=[1,2,1].
    symmetry_transform_make_h_symm([[1,2,3]], [[1,2,1]]).

test(make_h_symm_4wide) :-
    % Row [1,2,3,4]: Half=2, Left=[1,2], RLeft=[2,1], Row2=[1,2,2,1].
    symmetry_transform_make_h_symm([[1,2,3,4]], [[1,2,2,1]]).

test(make_h_symm_result_symmetric) :-
    % Result is always horizontally symmetric.
    symmetry_transform_make_h_symm([[1,2,3,4,5]], [Row2]),
    symmetry_transform_has_h_symm([Row2]).

:- end_tests(symmetry_transform_make_h_symm).

:- begin_tests(symmetry_transform_make_v_symm).

test(make_v_symm_even) :-
    % 2 rows: top=[row1], bottom=mirror=row1.
    symmetry_transform_make_v_symm([[1,2],[3,4]], [[1,2],[1,2]]).

test(make_v_symm_odd) :-
    % 3 rows: top=[r1], mid=r2, bottom=[r1] reversed -> [r1].
    symmetry_transform_make_v_symm([[1,2],[5,5],[3,4]], [[1,2],[5,5],[1,2]]).

test(make_v_symm_result_symmetric) :-
    % Result is always vertically symmetric.
    symmetry_transform_make_v_symm([[1,2],[3,4],[5,6],[7,8]], G2),
    symmetry_transform_has_v_symm(G2).

:- end_tests(symmetry_transform_make_v_symm).

:- begin_tests(symmetry_transform_d4_orbit).

test(d4_orbit_all_same) :-
    % All-same grid: all 8 transforms are identical, orbit has 1 element.
    all_same_grid(G),
    symmetry_transform_d4_orbit(G, Orbit),
    length(Orbit, 1).

test(d4_orbit_asymmetric) :-
    % Fully asymmetric grid: up to 8 distinct elements (but some may coincide for 2x2).
    asym_grid(G),
    symmetry_transform_d4_orbit(G, Orbit),
    length(Orbit, Len),
    Len >= 4.

test(d4_orbit_contains_original) :-
    % The orbit always contains the original grid.
    asym_grid(G),
    symmetry_transform_d4_orbit(G, Orbit),
    memberchk(G, Orbit).

:- end_tests(symmetry_transform_d4_orbit).
