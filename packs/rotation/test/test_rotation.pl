% test_rotation.pl - PLUnit tests for the rotation pack (ro_*, Layer 144).
:- use_module('../prolog/rotation.pl').

% Load the PLUnit framework.
:- use_module(library(plunit)).

% Begin test suite for the rotation pack.
:- begin_tests(rotation).

% rotation_rot90: 2x2 grid [[a,b],[c,d]] -> 90 CW = [[c,a],[d,b]].
% (0,0)=a -> (0,1). (0,1)=b -> (1,1). (1,0)=c -> (0,0). (1,1)=d -> (1,0).
test(rot90_2x2) :-
    rotation_rot90([[a,b],[c,d]], Out),
    Out = [[c,a],[d,b]].

% rotation_rot90: 3x2 grid (H=3, W=2). New grid is 2x3.
% Out[C] = col C of Grid read bottom-to-top.
% Col 0 bottom-to-top = [5,3,1]. Col 1 bottom-to-top = [6,4,2].
test(rot90_3x2) :-
    rotation_rot90([[1,2],[3,4],[5,6]], Out),
    Out = [[5,3,1],[6,4,2]].

% rotation_rot90: single-row grid [1,2,3] becomes a 3x1 column grid.
% Col 0 bottom-to-top = [3]. Col 1 = [2]. Col 2 = [1].
% Wait: H=1, W=3. Col 0: R=0, R2=0, G[0][0]=1. Only one row, so col C = [G[0][C]].
% But bottom-to-top for H=1: R=0->R2=0. Col 0=[1], col 1=[2], col 2=[3].
% Out = [[1],[2],[3]].
test(rot90_single_row) :-
    rotation_rot90([[1,2,3]], Out),
    Out = [[1],[2],[3]].

% rotation_rot90: identity on 1x1 grid.
test(rot90_1x1) :-
    rotation_rot90([[x]], Out),
    Out = [[x]].

% rotation_rot180: 2x2 grid [[a,b],[c,d]] -> 180 = [[d,c],[b,a]].
test(rot180_2x2) :-
    rotation_rot180([[a,b],[c,d]], Out),
    Out = [[d,c],[b,a]].

% rotation_rot180: 3x2 grid -> same dimensions, reversed rows and row order.
test(rot180_3x2) :-
    rotation_rot180([[1,2],[3,4],[5,6]], Out),
    Out = [[6,5],[4,3],[2,1]].

% rotation_rot180: 1x4 grid -> reversed row.
test(rot180_1x4) :-
    rotation_rot180([[a,b,c,d]], Out),
    Out = [[d,c,b,a]].

% rotation_rot270: 2x2 grid [[a,b],[c,d]] -> 270 CW = [[b,d],[a,c]].
% (R,C) -> (W-1-C, R). W=2, W1=1.
% (0,0)=a -> (1,0). (0,1)=b -> (0,0). (1,0)=c -> (1,1). (1,1)=d -> (0,1).
% Out[0]=[b,d], Out[1]=[a,c].
test(rot270_2x2) :-
    rotation_rot270([[a,b],[c,d]], Out),
    Out = [[b,d],[a,c]].

% rotation_rot270: 3x2 grid. New grid 2x3. W=2, W1=1.
% C=0, C2=W1-0=1: col 1 top-to-bottom = [2,4,6]. Row=[2,4,6].
% C=1, C2=W1-1=0: col 0 top-to-bottom = [1,3,5]. Row=[1,3,5].
test(rot270_3x2) :-
    rotation_rot270([[1,2],[3,4],[5,6]], Out),
    Out = [[2,4,6],[1,3,5]].

% rotation_rot270: single-row grid [1,2,3]. H=1, W=3, W1=2.
% C=0,C2=2: col 2 top-to-bottom=[3]. C=1,C2=1: col 1=[2]. C=2,C2=0: col 0=[1].
% Wait: new row index C from 0 to W1=2.
% Out = [[3],[2],[1]].
test(rot270_single_row) :-
    rotation_rot270([[1,2,3]], Out),
    Out = [[3],[2],[1]].

% rotation_rot_n: N=0 is identity.
test(rot_n_0) :-
    rotation_rot_n([[1,2],[3,4]], 0, Out),
    Out = [[1,2],[3,4]].

% rotation_rot_n: N=1 delegates to rotation_rot90.
test(rot_n_1) :-
    rotation_rot_n([[a,b],[c,d]], 1, Out),
    Out = [[c,a],[d,b]].

% rotation_rot_n: N=2 delegates to rotation_rot180.
test(rot_n_2) :-
    rotation_rot_n([[a,b],[c,d]], 2, Out),
    Out = [[d,c],[b,a]].

% rotation_rot_n: N=3 delegates to rotation_rot270.
test(rot_n_3) :-
    rotation_rot_n([[a,b],[c,d]], 3, Out),
    Out = [[b,d],[a,c]].

% rotation_all: produces list of all four rotations in order.
test(all_rotations) :-
    rotation_all([[1,0],[0,0]], Rots),
    Rots = [[[1,0],[0,0]], [[0,1],[0,0]], [[0,0],[0,1]], [[0,0],[1,0]]].

% rotation_canonical: for a 2x2 grid with atoms, find lexicographically smallest rotation.
% Rotations of [[c,a],[d,b]]: G0=[[c,a],[d,b]], G90=[[d,c],[b,a]],
%   G180=[[b,d],[a,c]], G270=[[a,b],[c,d]].
% Lex order: [[a,b],[c,d]] < [[b,d],[a,c]] < [[c,a],[d,b]] < [[d,c],[b,a]].
% Canon = [[a,b],[c,d]].
test(canonical) :-
    rotation_canonical([[c,a],[d,b]], Canon),
    Canon = [[a,b],[c,d]].

% rotation_canonical: a grid already in canonical form returns itself.
test(canonical_self) :-
    rotation_canonical([[0,0],[0,1]], Canon),
    % Rotations: G0=[[0,0],[0,1]], G90=[[0,0],[1,0]], G180=[[1,0],[0,0]], G270=[[0,0],[0,0]]?
    % Wait: rotation_rot270([[0,0],[0,1]]): H=2,W=2,W1=1.
    % C=0,C2=1: col 1 of [[0,0],[0,1]] top-to-bottom=[0,1]. Row=[0,1].
    % C=1,C2=0: col 0 top-to-bottom=[0,0]. Row=[0,0].
    % G270=[[0,1],[0,0]].
    % Sorted: [[0,0],[0,1]],[[0,0],[1,0]],[[0,1],[0,0]],[[1,0],[0,0]].
    % Canon = [[0,0],[0,1]]. Same as G0.
    Canon = [[0,0],[0,1]].

% rotation_is_rot2: [[1,2],[2,1]] is invariant under 180 rotation.
% rotation_rot180([[1,2],[2,1]]) = reverse([reverse([1,2]),reverse([2,1])]) = reverse([[2,1],[1,2]]) = [[1,2],[2,1]]. Correct!
test(is_rot2_succeed) :-
    rotation_is_rot2([[1,2],[2,1]]).

% rotation_is_rot2: [[1,2],[3,4]] is NOT invariant under 180.
test(is_rot2_fail, [fail]) :-
    rotation_is_rot2([[1,2],[3,4]]).

% rotation_is_rot2: 3x3 symmetric grid.
% [[a,b,a],[b,c,b],[a,b,a]] -> rotation_rot180: reverse rows then reverse list.
% reverse each row: [[a,b,a],[b,c,b],[a,b,a]]. Reverse list: [[a,b,a],[b,c,b],[a,b,a]].
% Same as original. Symmetric!
test(is_rot2_3x3) :-
    rotation_is_rot2([[a,b,a],[b,c,b],[a,b,a]]).

% rotation_is_rot4: [[a,a],[a,a]] is invariant under 90 rotation.
test(is_rot4_succeed) :-
    rotation_is_rot4([[a,a],[a,a]]).

% rotation_is_rot4: [[a,b],[a,b]] is NOT invariant under 90 rotation.
% rotation_rot90([[a,b],[a,b]]) = [[a,a],[b,b]]. Not the same.
test(is_rot4_fail, [fail]) :-
    rotation_is_rot4([[a,b],[a,b]]).

% rotation_sym_order: all-same grid has order 4 (invariant under 90).
test(sym_order_4) :-
    rotation_sym_order([[1,1],[1,1]], N),
    N = 4.

% rotation_sym_order: [[1,2],[2,1]] has order 2 (180-invariant, not 90-invariant).
test(sym_order_2) :-
    rotation_sym_order([[1,2],[2,1]], N),
    N = 2.

% rotation_sym_order: [[a,b],[c,d]] (all distinct) has order 1.
test(sym_order_1) :-
    rotation_sym_order([[a,b],[c,d]], N),
    N = 1.

% rotation_rotate_cells: N=0 is identity.
test(rotate_cells_n0) :-
    rotation_rotate_cells([0-0, 0-1, 1-0], 3, 3, 0, Out),
    Out = [0-0, 0-1, 1-0].

% rotation_rotate_cells: N=1 (90 CW): (R,C) -> (C, H-1-R). H=3, H1=2.
% (0,0)->(0,2). (0,1)->(1,2). (1,0)->(0,1).
test(rotate_cells_n1) :-
    rotation_rotate_cells([0-0, 0-1, 1-0], 3, 3, 1, Out),
    Out = [0-2, 1-2, 0-1].

% rotation_rotate_cells: N=2 (180): (R,C) -> (H-1-R, W-1-C). H=W=3, H1=W1=2.
% (0,0)->(2,2). (0,1)->(2,1). (1,0)->(1,2).
test(rotate_cells_n2) :-
    rotation_rotate_cells([0-0, 0-1, 1-0], 3, 3, 2, Out),
    Out = [2-2, 2-1, 1-2].

% rotation_rotate_cells: N=3 (270 CW): (R,C) -> (W-1-C, R). W=3, W1=2.
% (0,0)->(2,0). (0,1)->(1,0). (1,0)->(2,1).
test(rotate_cells_n3) :-
    rotation_rotate_cells([0-0, 0-1, 1-0], 3, 3, 3, Out),
    Out = [2-0, 1-0, 2-1].

% rotation_rotate_cells: empty cell list gives empty output.
test(rotate_cells_empty) :-
    rotation_rotate_cells([], 3, 3, 1, Out),
    Out = [].

% rotation_spin2: overlay Grid with 180 rotation; non-bg cells survive.
% Grid = [[1,0],[0,0]], bg=0. rot180 = [[0,0],[0,1]].
% (0,0): 1!=0->1. (0,1): 0==0->0. (1,0): 0==0->0. (1,1): 0==0->1.
test(spin2_basic) :-
    rotation_spin2([[1,0],[0,0]], 0, Out),
    Out = [[1,0],[0,1]].

% rotation_spin2: grid already 2-fold symmetric stays unchanged.
test(spin2_symmetric) :-
    rotation_spin2([[1,2],[2,1]], 0, Out),
    Out = [[1,2],[2,1]].

% rotation_spin2: all-bg grid stays all-bg.
test(spin2_all_bg) :-
    rotation_spin2([[0,0],[0,0]], 0, Out),
    Out = [[0,0],[0,0]].

% rotation_spin4: overlay all 4 rotations of [[1,0],[0,0]] with bg=0.
% rot90=[[0,1],[0,0]], rot180=[[0,0],[0,1]], rot270=[[0,0],[1,0]].
% Overlay: (0,0):1; (0,1):0->1; (1,0):0->0->1; (1,1):0->0->1.
% After overlay all: [[1,1],[1,1]].
test(spin4_basic) :-
    rotation_spin4([[1,0],[0,0]], 0, Out),
    Out = [[1,1],[1,1]].

% rotation_spin4: 3x3 grid with single corner cell, bg=0.
% Grid = [[1,0,0],[0,0,0],[0,0,0]].
% rot90: H=W=3,H1=2. Col C from bottom:
%   C=0: R=0->R2=2->G[2][0]=0; R=1->R2=1->G[1][0]=0; R=2->R2=0->G[0][0]=1. Row=[0,0,1].
%   C=1: all G[R][1]=0. Row=[0,0,0].
%   C=2: all G[R][2]=0. Row=[0,0,0].
%   rot90=[[0,0,1],[0,0,0],[0,0,0]].
% rot180: reverse each row [[0,0,1],[0,0,0],[0,0,0]] then reverse list:
%   Wait, rot180 of original [[1,0,0],[0,0,0],[0,0,0]]:
%   reverse each row: [[0,0,1],[0,0,0],[0,0,0]], reverse list: [[0,0,0],[0,0,0],[0,0,1]].
% rot270 of original: W1=2. C=0,C2=2: col 2 top-to-bottom=[0,0,0]. C=1,C2=1: [0,0,0]. C=2,C2=0: [1,0,0].
%   rot270=[[0,0,0],[0,0,0],[1,0,0]].
% Spin4: overlay of all 4:
%   (0,0):1; (0,2): 0->1; (2,0): 0->0->1; (2,2): 0->0->0->1.
%   Others: all 0.
%   Out = [[1,0,1],[0,0,0],[1,0,1]].
test(spin4_3x3_corner) :-
    rotation_spin4([[1,0,0],[0,0,0],[0,0,0]], 0, Out),
    Out = [[1,0,1],[0,0,0],[1,0,1]].

% rotation_match_rotation: N=0 when grids are already equal.
test(match_rotation_n0) :-
    rotation_match_rotation([[1,2],[3,4]], [[1,2],[3,4]], N),
    N = 0.

% rotation_match_rotation: N=1 when GridB is 90 CW of GridA.
test(match_rotation_n1) :-
    rotation_match_rotation([[a,b],[c,d]], [[c,a],[d,b]], N),
    N = 1.

% rotation_match_rotation: N=2 when GridB is 180 of GridA.
test(match_rotation_n2) :-
    rotation_match_rotation([[a,b],[c,d]], [[d,c],[b,a]], N),
    N = 2.

% rotation_match_rotation: N=3 when GridB is 270 CW of GridA.
test(match_rotation_n3) :-
    rotation_match_rotation([[a,b],[c,d]], [[b,d],[a,c]], N),
    N = 3.

% rotation_match_rotation: fails when no rotation matches.
test(match_rotation_fail, [fail]) :-
    rotation_match_rotation([[1,2],[3,4]], [[5,6],[7,8]], _).

% rotation_equiv_rotation: succeed when GridB is a rotation of GridA.
test(equiv_rotation_succeed) :-
    rotation_equiv_rotation([[1,0],[0,0]], [[0,0],[0,1]]).

% rotation_equiv_rotation: fail when GridB is not a rotation of GridA.
test(equiv_rotation_fail, [fail]) :-
    rotation_equiv_rotation([[1,0],[0,0]], [[2,0],[0,0]]).

% Round-trip: rot90 four times is identity.
test(rot90_roundtrip) :-
    Grid = [[a,b,c],[d,e,f],[g,h,i]],
    rotation_rot90(Grid, G1),
    rotation_rot90(G1, G2),
    rotation_rot90(G2, G3),
    rotation_rot90(G3, G4),
    G4 == Grid.

% Round-trip: rot180 twice is identity.
test(rot180_roundtrip) :-
    Grid = [[1,2,3],[4,5,6]],
    rotation_rot180(Grid, G1),
    rotation_rot180(G1, G2),
    G2 == Grid.

% Round-trip: rot270 four times is identity.
test(rot270_roundtrip) :-
    Grid = [[1,2],[3,4],[5,6]],
    rotation_rot270(Grid, G1),
    rotation_rot270(G1, G2),
    rotation_rot270(G2, G3),
    rotation_rot270(G3, G4),
    G4 == Grid.

% Consistency: rot90 three times equals rot270.
test(rot90x3_eq_rot270) :-
    Grid = [[a,b],[c,d]],
    rotation_rot90(Grid, G1),
    rotation_rot90(G1, G2),
    rotation_rot90(G2, G3),
    rotation_rot270(Grid, G270),
    G3 == G270.

% End of test suite.
:- end_tests(rotation).
