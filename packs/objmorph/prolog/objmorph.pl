% objmorph.pl - Layer 165: Morphological Operations on obj(Color, Cells) Terms (om_* prefix).
% Provides cell neighborhood generators, boundary and interior extraction (4-connected and
% 8-connected), single-step and multi-step dilation, single-step and multi-step erosion,
% and morphological opening and closing — all operating directly on obj terms without
% requiring a grid. The obj-level counterpart of the morph pack's grid operations.
:- module(objmorph, [
    om_neighbors4/2,
    om_neighbors8/2,
    om_boundary4/2,
    om_interior4/2,
    om_boundary8/2,
    om_interior8/2,
    om_dilate4/2,
    om_erode4/2,
    om_dilate8/2,
    om_erode8/2,
    om_dilate4_n/3,
    om_erode4_n/3,
    om_open4/2,
    om_close4/2
]).
% member/2 for cell-list membership testing.
:- use_module(library(lists), [member/2]).

% om_neighbors4(+Cell, -Neighbors): 4-connected (up, down, left, right) neighbors of r(R,C).
% Always returns exactly 4 cells; coordinates may be negative or out of any grid bounds.
om_neighbors4(r(R, C), [r(R1,C), r(R2,C), r(R,C1), r(R,C2)]) :-
% Compute row neighbors: one step up and one step down.
    R1 is R - 1, R2 is R + 1,
% Compute column neighbors: one step left and one step right.
    C1 is C - 1, C2 is C + 1.

% om_neighbors8(+Cell, -Neighbors): 8-connected neighbors of r(R,C) (4-connected + diagonals).
% Always returns exactly 8 cells.
om_neighbors8(r(R, C), [r(R1,C1),r(R1,C),r(R1,C2),
                         r(R, C1),          r(R, C2),
                         r(R2,C1),r(R2,C),r(R2,C2)]) :-
% Compute row offsets: up, same, down.
    R1 is R - 1, R2 is R + 1,
% Compute column offsets: left, same, right.
    C1 is C - 1, C2 is C + 1.

% om_boundary4(+Obj, -Boundary): cells of Obj with at least one 4-connected neighbor outside Obj.
% The boundary is the outer ring of cells when viewed with 4-connectivity.
om_boundary4(obj(Color, Cells), obj(Color, Boundary)) :-
% Sort the cell list to enable O(n) member checks and ensure canonical order.
    sort(Cells, S),
% Keep cells for which not ALL 4-neighbors are also in S (= at least one is outside).
    findall(r(R,C),
            (member(r(R,C), S),
             om_neighbors4(r(R,C), Nbrs),
             \+ forall(member(N, Nbrs), member(N, S))),
            Boundary).

% om_interior4(+Obj, -Interior): cells of Obj where ALL 4-connected neighbors are also in Obj.
% The interior is the set of cells fully surrounded on all 4 sides by other cells of Obj.
om_interior4(obj(Color, Cells), obj(Color, Interior)) :-
% Sort for canonical order and efficient membership.
    sort(Cells, S),
% Keep cells for which ALL 4-neighbors are in S.
    findall(r(R,C),
            (member(r(R,C), S),
             om_neighbors4(r(R,C), Nbrs),
             forall(member(N, Nbrs), member(N, S))),
            Interior).

% om_boundary8(+Obj, -Boundary): cells of Obj with at least one 8-connected neighbor outside Obj.
% Looser than boundary4: a cell is "interior" only if all 8 diagonal neighbors are also in Obj.
om_boundary8(obj(Color, Cells), obj(Color, Boundary)) :-
% Sort for canonical order.
    sort(Cells, S),
% Keep cells for which at least one 8-neighbor is outside S.
    findall(r(R,C),
            (member(r(R,C), S),
             om_neighbors8(r(R,C), Nbrs),
             \+ forall(member(N, Nbrs), member(N, S))),
            Boundary).

% om_interior8(+Obj, -Interior): cells of Obj where ALL 8-connected neighbors are also in Obj.
% Stricter than interior4: requires all 8 diagonal neighbors to be present too.
om_interior8(obj(Color, Cells), obj(Color, Interior)) :-
% Sort for canonical order.
    sort(Cells, S),
% Keep cells for which ALL 8-neighbors are in S.
    findall(r(R,C),
            (member(r(R,C), S),
             om_neighbors8(r(R,C), Nbrs),
             forall(member(N, Nbrs), member(N, S))),
            Interior).

% om_dilate4(+Obj, -Result): expand Obj by one 4-connected step.
% Each existing cell contributes its 4 neighbors; the original cells are kept.
% Result contains all original cells plus all cells adjacent (4-connected) to any original cell.
om_dilate4(obj(Color, Cells), obj(Color, Dilated)) :-
% Sort to canonical order.
    sort(Cells, S),
% Collect all 4-connected neighbors of every cell.
    findall(r(NR,NC),
            (member(r(R,C), S), om_neighbors4(r(R,C), Nbrs), member(r(NR,NC), Nbrs)),
            NewCells),
% Union original cells with new neighbors; sort deduplicates.
    append(S, NewCells, All),
    sort(All, Dilated).

% om_erode4(+Obj, -Result): shrink Obj by one 4-connected step.
% Removes all boundary4 cells; the result is the interior4 of Obj.
% Equivalent to om_interior4: keeps only cells fully surrounded on all 4 sides.
om_erode4(Obj, Eroded) :-
% Erosion = keep only interior4 cells.
    om_interior4(Obj, Eroded).

% om_dilate8(+Obj, -Result): expand Obj by one 8-connected step.
% Each existing cell contributes all 8 neighbors; includes diagonal expansion.
om_dilate8(obj(Color, Cells), obj(Color, Dilated)) :-
% Sort to canonical order.
    sort(Cells, S),
% Collect all 8-connected neighbors of every cell.
    findall(r(NR,NC),
            (member(r(R,C), S), om_neighbors8(r(R,C), Nbrs), member(r(NR,NC), Nbrs)),
            NewCells),
% Union original cells with new neighbors; sort deduplicates.
    append(S, NewCells, All),
    sort(All, Dilated).

% om_erode8(+Obj, -Result): shrink Obj by one 8-connected step.
% Removes all boundary8 cells; the result is the interior8 of Obj.
% Stricter than erode4: keeps only cells fully surrounded in all 8 directions.
om_erode8(Obj, Eroded) :-
% Erosion under 8-connectivity = keep only interior8 cells.
    om_interior8(Obj, Eroded).

% om_dilate4_n(+Obj, +N, -Result): apply om_dilate4 exactly N times.
% N=0 returns Obj unchanged.
om_dilate4_n(Obj, 0, Obj) :- !.
% Recursive case: dilate once then dilate the result N-1 more times.
om_dilate4_n(Obj, N, Result) :-
    N > 0,
% One dilation step.
    om_dilate4(Obj, Step),
% Continue for the remaining steps.
    N1 is N - 1,
    om_dilate4_n(Step, N1, Result).

% om_erode4_n(+Obj, +N, -Result): apply om_erode4 exactly N times.
% N=0 returns Obj unchanged. Stops when the cell set becomes empty.
om_erode4_n(Obj, 0, Obj) :- !.
% Recursive case: erode once then erode the result N-1 more times.
om_erode4_n(obj(Color, Cells), N, Result) :-
    N > 0,
% One erosion step.
    om_erode4(obj(Color, Cells), Step),
% Continue eroding; if Step has empty cells, further erosion gives empty cells.
    N1 is N - 1,
    om_erode4_n(Step, N1, Result).

% om_open4(+Obj, -Result): morphological opening = erode4 then dilate4.
% Removes small protrusions and thin connections while preserving bulk shapes.
om_open4(Obj, Result) :-
% First erode to remove boundary cells.
    om_erode4(Obj, Eroded),
% Then dilate to restore bulk size.
    om_dilate4(Eroded, Result).

% om_close4(+Obj, -Result): morphological closing = dilate4 then erode4.
% Fills small gaps and indentations while preserving bulk shapes.
om_close4(Obj, Result) :-
% First dilate to fill gaps.
    om_dilate4(Obj, Dilated),
% Then erode to restore bulk size.
    om_erode4(Dilated, Result).
