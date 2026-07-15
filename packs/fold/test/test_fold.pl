% test_fold.pl - PLUnit tests for the fold pack (fd_*, Layer 143).
:- use_module('../prolog/fold.pl').

% Load the PLUnit framework.
:- use_module(library(plunit)).

% Begin test suite for the fold pack.
:- begin_tests(fold).

% fold_split_h: split a 4-row grid at row 1 (top = rows 0,1; bottom = rows 2,3).
test(split_h_basic) :-
    fold_split_h([[a,b],[c,d],[e,f],[g,h]], 1, Top, Bottom),
    Top = [[a,b],[c,d]],
    Bottom = [[e,f],[g,h]].

% fold_split_h: split at row 0 gives a one-row top and the rest as bottom.
test(split_h_row0) :-
    fold_split_h([[1,2],[3,4],[5,6]], 0, Top, Bottom),
    Top = [[1,2]],
    Bottom = [[3,4],[5,6]].

% fold_split_h: split at last row gives full grid as top and empty bottom.
test(split_h_last_row) :-
    fold_split_h([[1],[2],[3]], 2, Top, Bottom),
    Top = [[1],[2],[3]],
    Bottom = [].

% fold_split_v: split a 2x4 grid at col 1 (left = cols 0,1; right = cols 2,3).
test(split_v_basic) :-
    fold_split_v([[a,b,c,d],[e,f,g,h]], 1, Left, Right),
    Left = [[a,b],[e,f]],
    Right = [[c,d],[g,h]].

% fold_split_v: split at col 0 gives one-column left and rest as right.
test(split_v_col0) :-
    fold_split_v([[1,2,3],[4,5,6]], 0, Left, Right),
    Left = [[1],[4]],
    Right = [[2,3],[5,6]].

% fold_split_v: split at last column gives full row as left and empty right.
test(split_v_last_col) :-
    fold_split_v([[a,b,c],[d,e,f]], 2, Left, Right),
    Left = [[a,b,c],[d,e,f]],
    Right = [[],[]].

% fold_overlay: non-background cells of A overwrite B.
test(overlay_basic) :-
    fold_overlay([[0,1],[2,0]], [[9,9],[9,9]], 0, Out),
    Out = [[9,1],[2,9]].

% fold_overlay: when A is all background, result is B.
test(overlay_all_bg) :-
    fold_overlay([[0,0],[0,0]], [[1,2],[3,4]], 0, Out),
    Out = [[1,2],[3,4]].

% fold_overlay: when A has no background cells, result equals A.
test(overlay_no_bg) :-
    fold_overlay([[1,2],[3,4]], [[9,9],[9,9]], 0, Out),
    Out = [[1,2],[3,4]].

% fold_fold_h: fold a 4-row grid at row 1 (crease between rows 1 and 2).
% Top rows: 0=[a,b], 1=[c,d]. Bottom rows: 0=[e,f], 1=[g,h].
% Out[0] = overlay([a,b],[c's mirror=row K=1-0=1 of bottom=[g,h]], bg=0) = ?
% Wait: K = R - I where R=1 (crease row). I=0 -> K=1; I=1 -> K=0.
% Out[0]: overlay(Top[0]=[a,b], Bottom[1]=[g,h], 0) -> non-zero wins from A.
% Out[1]: overlay(Top[1]=[c,d], Bottom[0]=[e,f], 0) -> non-zero wins from A.
% With bg=0: a\=0 -> a, b\=0 -> b in row 0; c\=0 -> c, d\=0 -> d in row 1.
test(fold_h_basic) :-
    fold_fold_h([[a,b],[c,d],[e,f],[g,h]], 1, 0, Out),
    Out = [[a,b],[c,d]].

% fold_fold_h: fold a 3-row numeric grid at row 1 with background 0.
% Top: row0=[0,1], row1=[2,3]. Bottom: row0=[4,5].
% Out[0]: K=1-0=1, K>=HB=1 -> keep Top[0]=[0,1]. Out[1]: K=0, overlay([2,3],[4,5],0).
% overlay: 2\=0->2, 3\=0->3. So Out[1]=[2,3].
test(fold_h_num) :-
    fold_fold_h([[0,1],[2,3],[4,5]], 1, 0, Out),
    Out = [[0,1],[2,3]].

% fold_fold_h: fold with non-zero background and real ink from bottom.
% Grid: [[0,0],[0,7],[5,0]], crease at row 1, bg=0.
% Top: row0=[0,0], row1=[0,7]. Bottom: row0=[5,0].
% Out[0]: K=1-0=1, K>=HB=1 -> keep [0,0]. Out[1]: K=0, overlay([0,7],[5,0],0).
% overlay cell: 0==bg->use 5; 7\=bg->keep 7. Out[1]=[5,7].
test(fold_h_ink_from_bottom) :-
    fold_fold_h([[0,0],[0,7],[5,0]], 1, 0, Out),
    Out = [[0,0],[5,7]].

% fold_fold_v: fold a 2x4 grid at col 1 with background 0.
% Left: [[a,b],[e,f]]. Right: [[c,d],[g,h]].
% For row 0: col I=0: K=1-0=1, K<WR=2, overlay(a,d,0); I=1: K=0, overlay(b,c,0).
% a,b\=0 (atoms not equal to 0) -> a,b wins. Out=[[a,b],[e,f]].
test(fold_v_basic) :-
    fold_fold_v([[a,b,c,d],[e,f,g,h]], 1, 0, Out),
    Out = [[a,b],[e,f]].

% fold_fold_v: fold numeric grid; background cells get overwritten from right.
% Grid: [[0,0,3],[0,5,0]], crease at col 1, bg=0.
% Left: [[0,0],[0,5]]. Right: [[3],[0]].
% Row 0: I=0: K=1, K<1? No (WR=1). Keep LV=0. I=1: K=0, K<1. overlay(0,3,0)->3.
% Row 1: I=0: K=1>=1 keep 0. I=1: K=0 overlay(5,0,0)->5.
test(fold_v_ink_from_right) :-
    fold_fold_v([[0,0,3],[0,5,0]], 1, 0, Out),
    Out = [[0,3],[0,5]].

% fold_unfold_h: unfold a 2-row half into a 4-row symmetric grid.
test(unfold_h_basic) :-
    fold_unfold_h([[1,2],[3,4]], Grid),
    Grid = [[1,2],[3,4],[3,4],[1,2]].

% fold_unfold_h: single-row half gives 2-row grid.
test(unfold_h_single_row) :-
    fold_unfold_h([[a,b,c]], Grid),
    Grid = [[a,b,c],[a,b,c]].

% fold_unfold_v: unfold a 2x2 left half into a 2x4 symmetric grid.
test(unfold_v_basic) :-
    fold_unfold_v([[1,2],[3,4]], Grid),
    Grid = [[1,2,2,1],[3,4,4,3]].

% fold_unfold_v: single-column half gives 2-column grid.
test(unfold_v_single_col) :-
    fold_unfold_v([[a],[b],[c]], Grid),
    Grid = [[a,a],[b,b],[c,c]].

% fold_sym_h: a 4-row grid is symmetric with fold crease between rows 1 and 2.
% [[1,2],[3,4],[3,4],[1,2]] satisfies row I == row (2*1+1-I) = row (3-I):
% row0=[1,2]==row3=[1,2], row1=[3,4]==row2=[3,4].
test(symmetry_transform_h_palindrome) :-
    fold_sym_h([[1,2],[3,4],[3,4],[1,2]], 1).

% fold_sym_h: a 2-row grid with identical rows is symmetric around crease after row 0.
% Formula: row I == row (2*0+1-I) = row (1-I). row0==row1 and row1==row0.
test(symmetry_transform_h_trivial_row0) :-
    fold_sym_h([[a,b],[a,b]], 0).

% fold_sym_h: should fail when rows are not mirrored correctly.
test(symmetry_transform_h_fail, [fail]) :-
    fold_sym_h([[1,2],[3,4],[5,6]], 1).

% fold_sym_v: a 4-col grid is symmetric with fold crease between cols 1 and 2.
% [[1,2,2,1],[3,4,4,3]] satisfies col J == col (2*1+1-J) = col (3-J):
% col0=[1,3]==col3=[1,3], col1=[2,4]==col2=[2,4].
test(symmetry_transform_v_palindrome) :-
    fold_sym_v([[1,2,2,1],[3,4,4,3]], 1).

% fold_sym_v: should fail when columns are not mirrored correctly.
test(symmetry_transform_v_fail, [fail]) :-
    fold_sym_v([[1,2,3],[4,5,6]], 1).

% fold_find_fold_h: find fold crease in a 4-row between-rows-symmetric grid.
% [[a,b],[c,d],[c,d],[a,b]] has fold crease after row 1 (row I == row 3-I).
test(find_fold_h) :-
    fold_find_fold_h([[a,b],[c,d],[c,d],[a,b]], R),
    R = 1.

% fold_find_fold_h: single-row grid is trivially symmetric around row 0.
test(find_fold_h_single) :-
    fold_find_fold_h([[1,2,3]], R),
    R = 0.

% fold_find_fold_v: find fold crease in a 4-col between-cols-symmetric grid.
% [[1,2,2,1],[3,4,4,3]] has fold crease after col 1 (col J == col 3-J).
test(find_fold_v) :-
    fold_find_fold_v([[1,2,2,1],[3,4,4,3]], C),
    C = 1.

% fold_find_fold_v: 4-col grid [[a,b,b,a],[c,d,d,c]] symmetric around col 1 and col 2.
% Finds first (col 1).
test(find_fold_v_4col) :-
    fold_find_fold_v([[a,b,b,a],[c,d,d,c]], C),
    C = 1.

% fold_mark_row: find the first row where all cells equal 9.
test(mark_row_basic) :-
    fold_mark_row([[1,2],[9,9],[3,4]], 9, R),
    R = 1.

% fold_mark_row: find the separator row in a 4-row grid.
test(mark_row_second) :-
    fold_mark_row([[a,b],[c,d],[0,0],[e,f]], 0, R),
    R = 2.

% fold_mark_row: first row is all-V.
test(mark_row_first) :-
    fold_mark_row([[5,5,5],[1,2,3],[4,5,6]], 5, R),
    R = 0.

% fold_mark_col: find the first column where all cells equal 0.
test(mark_col_basic) :-
    fold_mark_col([[1,0,2],[3,0,4],[5,0,6]], 0, C),
    C = 1.

% fold_mark_col: first column is all-V.
test(mark_col_first) :-
    fold_mark_col([[9,1,2],[9,3,4],[9,5,6]], 9, C),
    C = 0.

% fold_mark_col: last column is all-V.
test(mark_col_last) :-
    fold_mark_col([[1,2,0],[3,4,0],[5,6,0]], 0, C),
    C = 2.

% fold_fold_both: fold at row 1 then col 1 of a 4x4 grid.
% Grid: [[a,b,c,d],[e,f,g,h],[i,j,k,l],[m,n,o,p]].
% After fold_h at row 1:
%   Top=[[a,b,c,d],[e,f,g,h]], Bottom=[[i,j,k,l],[m,n,o,p]].
%   Out[0]: K=1-0=1, K<2, overlay([a,b,c,d],[m,n,o,p],0): a,b,c,d all atoms\=0 -> [a,b,c,d].
%   Out[1]: K=0, overlay([e,f,g,h],[i,j,k,l],0): e,f,g,h all atoms\=0 -> [e,f,g,h].
%   FoldedH = [[a,b,c,d],[e,f,g,h]].
% After fold_v at col 1:
%   Left=[[a,b],[e,f]], Right=[[c,d],[g,h]].
%   Row0: I=0: K=1, K<2, overlay(a,d,0)->a. I=1: K=0, overlay(b,c,0)->b. Out0=[a,b].
%   Row1: I=0: K=1, overlay(e,h,0)->e. I=1: K=0, overlay(f,g,0)->f. Out1=[e,f].
%   Final: [[a,b],[e,f]].
test(fold_both_atoms) :-
    fold_fold_both([[a,b,c,d],[e,f,g,h],[i,j,k,l],[m,n,o,p]], 1, 1, 0, Out),
    Out = [[a,b],[e,f]].

% fold_fold_both: numeric 4x4 grid where background=0 allows ink merging.
% Grid: [[0,0,0,1],[0,0,2,0],[0,3,0,0],[4,0,0,0]], fold at row 1, col 1, bg=0.
% fold_h at row 1:
%   Top: row0=[0,0,0,1], row1=[0,0,2,0]. Bottom: row0=[0,3,0,0], row1=[4,0,0,0].
%   Out[0]: K=1-0=1, overlay([0,0,0,1],[4,0,0,0],0): 0->4,0->0,0->0,1->1. Out0=[4,0,0,1].
%   Out[1]: K=0, overlay([0,0,2,0],[0,3,0,0],0): 0->0,0->3,2->2,0->0. Out1=[0,3,2,0].
%   FoldedH = [[4,0,0,1],[0,3,2,0]].
% fold_v at col 1:
%   Left=[[4,0],[0,3]], Right=[[0,1],[2,0]].
%   Row0: I=0: K=1, overlay(4,1,0)->4. I=1: K=0, overlay(0,0,0)->0. Out0=[4,0].
%   Row1: I=0: K=1, overlay(0,0,0)->0. I=1: K=0, overlay(3,2,0)->3. Out1=[0,3].
%   Final: [[4,0],[0,3]].
test(fold_both_numeric) :-
    fold_fold_both([[0,0,0,1],[0,0,2,0],[0,3,0,0],[4,0,0,0]], 1, 1, 0, Out),
    Out = [[4,0],[0,3]].

% fold_fold_both: 3x3 grid folded at row 0 and col 0 gives a 1x1 result.
% Grid: [[1,2,3],[4,5,6],[7,8,9]], fold at row 0, col 0, bg=0.
% fold_h at row 0: Top=[[1,2,3]], Bottom=[[4,5,6],[7,8,9]].
%   Out[0]: K=0-0=0, K<2, overlay([1,2,3],[4,5,6],0): 1,2,3\=0 -> [1,2,3].
%   FoldedH = [[1,2,3]].
% fold_v at col 0: Left=[[1]], Right=[[2,3]].
%   Row0: I=0: K=0-0=0, overlay(1,2,0)->1. OutRow=[1].
%   Final: [[1]].
test(fold_both_1x1) :-
    fold_fold_both([[1,2,3],[4,5,6],[7,8,9]], 0, 0, 0, Out),
    Out = [[1]].

% fold_split_h and fold_split_v round-trip: split then reassemble gives original.
test(split_h_roundtrip) :-
    Grid = [[1,2],[3,4],[5,6],[7,8]],
    fold_split_h(Grid, 1, Top, Bottom),
    append(Top, Bottom, Grid).

% fold_split_v round-trip: reassemble rows.
test(split_v_roundtrip) :-
    Grid = [[1,2,3,4],[5,6,7,8]],
    fold_split_v(Grid, 1, Left, Right),
    maplist([LR,RR,Row]>>(append(LR,RR,Row)), Left, Right, Grid).

% fold_unfold_h then fold_find_fold_h: unfold creates a grid with fold at last row of half.
test(unfold_h_find_fold) :-
    Half = [[1,2],[3,4]],
    fold_unfold_h(Half, Grid),
    % Grid = [[1,2],[3,4],[3,4],[1,2]] - symmetric around row 1.
    fold_find_fold_h(Grid, R),
    R = 1.

% fold_unfold_v then fold_find_fold_v: unfold creates a grid with fold at last col of half.
test(unfold_v_find_fold) :-
    Half = [[1,2],[3,4]],
    fold_unfold_v(Half, Grid),
    % Grid = [[1,2,2,1],[3,4,4,3]] - symmetric around col 1.
    fold_find_fold_v(Grid, C),
    C = 1.

% fold_fold_h: fold bottom up with bottom taller than top.
% Grid: [[1],[2],[3],[4],[5]], crease at row 0 (top = [1], bottom = [2,3,4,5]).
% HB=4. Out[0]: K=0-0=0, K<4, overlay([1],[2],0) -> 1 (atom \= 0). Out=[[1]].
test(fold_h_tall_bottom) :-
    fold_fold_h([[1],[2],[3],[4],[5]], 0, 0, Out),
    Out = [[1]].

% fold_fold_v: fold right with right wider than left.
% Grid: [[1,2,3,4,5]], crease at col 0 (left=[[1]], right=[[2,3,4,5]]).
% WL=1, WR=4. Row0: I=0: K=0-0=0, K<4, overlay(1,2,0)->1. Out=[[1]].
test(fold_v_wide_right) :-
    fold_fold_v([[1,2,3,4,5]], 0, 0, Out),
    Out = [[1]].

% End of test suite.
:- end_tests(fold).
