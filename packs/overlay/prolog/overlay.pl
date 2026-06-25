% Module overlay: combining two grids by layering, blending, and masking rules.
% Layer 50. Prefix: ov_. Requires: grid.
:- module(overlay, [
    % Place Grid B on top of Grid A; cells of B that equal BG are transparent.
    ov_over/4,
    % Combine two grids by taking B's value unless B equals BG (alias for ov_over).
    ov_blend/4,
    % Pointwise bitwise OR of two same-size grids.
    ov_or/3,
    % Pointwise bitwise AND of two same-size grids.
    ov_and/3,
    % XOR with background as zero: non-BG where exactly one grid is non-BG.
    ov_xor/4,
    % Difference: A's value where A and B differ; BG elsewhere.
    ov_diff/4,
    % Intersection: A's value where A equals B; BG elsewhere.
    ov_intersect/4,
    % Mask: A's value where Mask is non-BG; BG where Mask equals BG.
    ov_mask/4,
    % Inverse mask: A's value where Mask equals BG; BG where Mask is non-BG.
    ov_mask_inv/4,
    % Priority merge: first non-BG value scanning a list of grids.
    ov_priority/3,
    % Replace all cells of color Old in Grid with color New.
    ov_replace/4,
    % Replace all BG cells with a fill color; keep non-BG cells unchanged.
    ov_fill_bg/4,
    % Pointwise maximum of two same-size grids.
    ov_max/3,
    % Pointwise minimum of two same-size grids.
    ov_min/3
]).

% Load list utilities.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, maplist/4]).

% ov_cell_over_(+BG, +A, +B, -C)
% C = B when B != BG; C = A when B = BG (A shows through).
ov_cell_over_(BG, A, B, C) :-
    (B =:= BG -> C = A ; C = B).

% ov_row_over_(+BG, +RowA, +RowB, -RowC)
% Apply ov_cell_over_ across all cells of two rows.
ov_row_over_(BG, RowA, RowB, RowC) :-
    maplist(ov_cell_over_(BG), RowA, RowB, RowC).

% ov_over(+A, +B, +BG, -Result)
% Place grid B over grid A; BG cells in B are transparent.
ov_over(A, B, BG, Result) :-
    maplist(ov_row_over_(BG), A, B, Result).

% ov_blend(+A, +B, +BG, -Result)
% Alias for ov_over. B's non-BG cells overwrite A.
ov_blend(A, B, BG, Result) :-
    ov_over(A, B, BG, Result).

% ov_cell_or_(+A, +B, -C)
% Bitwise OR of two integer cell values.
ov_cell_or_(A, B, C) :- C is A \/ B.

% ov_row_or_(+RowA, +RowB, -RowC)
% Pointwise bitwise OR of two rows.
ov_row_or_(RowA, RowB, RowC) :-
    maplist(ov_cell_or_, RowA, RowB, RowC).

% ov_or(+A, +B, -Result)
% Pointwise bitwise OR of two same-size grids.
ov_or(A, B, Result) :-
    maplist(ov_row_or_, A, B, Result).

% ov_cell_and_(+A, +B, -C)
% Bitwise AND of two integer cell values.
ov_cell_and_(A, B, C) :- C is A /\ B.

% ov_row_and_(+RowA, +RowB, -RowC)
% Pointwise bitwise AND of two rows.
ov_row_and_(RowA, RowB, RowC) :-
    maplist(ov_cell_and_, RowA, RowB, RowC).

% ov_and(+A, +B, -Result)
% Pointwise bitwise AND of two same-size grids.
ov_and(A, B, Result) :-
    maplist(ov_row_and_, A, B, Result).

% ov_cell_xor_(+BG, +A, +B, -C)
% C = A when only A is non-BG; C = B when only B is non-BG; BG when both or neither.
ov_cell_xor_(BG, A, B, C) :-
    (   A =\= BG, B =:= BG  -> C = A
    ;   B =\= BG, A =:= BG  -> C = B
    ;   C = BG
    ).

% ov_row_xor_(+BG, +RowA, +RowB, -RowC)
% XOR row: non-BG value where exactly one of RowA, RowB is non-BG.
ov_row_xor_(BG, RowA, RowB, RowC) :-
    maplist(ov_cell_xor_(BG), RowA, RowB, RowC).

% ov_xor(+A, +B, +BG, -Result)
% Result has a non-BG value where exactly one of A, B differs from BG.
ov_xor(A, B, BG, Result) :-
    maplist(ov_row_xor_(BG), A, B, Result).

% ov_cell_diff_(+BG, +A, +B, -C)
% C = A when A != B; BG when A = B.
ov_cell_diff_(BG, A, B, C) :-
    (A =\= B -> C = A ; C = BG).

% ov_row_diff_(+BG, +RowA, +RowB, -RowC)
% Row difference: A's value where A and B differ.
ov_row_diff_(BG, RowA, RowB, RowC) :-
    maplist(ov_cell_diff_(BG), RowA, RowB, RowC).

% ov_diff(+A, +B, +BG, -Result)
% Result keeps A's value where A and B differ; BG where they agree.
ov_diff(A, B, BG, Result) :-
    maplist(ov_row_diff_(BG), A, B, Result).

% ov_cell_intersect_(+BG, +A, +B, -C)
% C = A when A = B; BG when they differ.
ov_cell_intersect_(BG, A, B, C) :-
    (A =:= B -> C = A ; C = BG).

% ov_row_intersect_(+BG, +RowA, +RowB, -RowC)
% Row intersection: A's value where A equals B.
ov_row_intersect_(BG, RowA, RowB, RowC) :-
    maplist(ov_cell_intersect_(BG), RowA, RowB, RowC).

% ov_intersect(+A, +B, +BG, -Result)
% Result keeps A's value where A equals B; BG where they differ.
ov_intersect(A, B, BG, Result) :-
    maplist(ov_row_intersect_(BG), A, B, Result).

% ov_cell_mask_(+BG, +A, +M, -C)
% C = A when M != BG; BG when M = BG.
ov_cell_mask_(BG, A, M, C) :-
    (M =\= BG -> C = A ; C = BG).

% ov_row_mask_(+BG, +RowA, +RowM, -RowC)
% Row mask: keep A's cell where mask is non-BG.
ov_row_mask_(BG, RowA, RowM, RowC) :-
    maplist(ov_cell_mask_(BG), RowA, RowM, RowC).

% ov_mask(+Grid, +Mask, +BG, -Result)
% Result keeps Grid's value where Mask is non-BG; BG elsewhere.
ov_mask(Grid, Mask, BG, Result) :-
    maplist(ov_row_mask_(BG), Grid, Mask, Result).

% ov_cell_mask_inv_(+BG, +A, +M, -C)
% C = A when M = BG; BG when M != BG (inverse mask).
ov_cell_mask_inv_(BG, A, M, C) :-
    (M =:= BG -> C = A ; C = BG).

% ov_row_mask_inv_(+BG, +RowA, +RowM, -RowC)
% Inverse row mask: keep A's cell where mask equals BG.
ov_row_mask_inv_(BG, RowA, RowM, RowC) :-
    maplist(ov_cell_mask_inv_(BG), RowA, RowM, RowC).

% ov_mask_inv(+Grid, +Mask, +BG, -Result)
% Result keeps Grid's value where Mask equals BG; BG elsewhere.
ov_mask_inv(Grid, Mask, BG, Result) :-
    maplist(ov_row_mask_inv_(BG), Grid, Mask, Result).

% ov_first_nonbg_(+BG, +Vals, -Val)
% Val is the first element of Vals that is not BG; BG if all are BG.
ov_first_nonbg_(BG, Vals, Val) :-
    (   member(V, Vals), V =\= BG
    ->  Val = V
    ;   Val = BG
    ).

% ov_priority_cell_(+BG, +Grids, +R, +C, -Val)
% Val is the first non-BG value at (R,C) across Grids.
ov_priority_cell_(BG, Grids, R, C, Val) :-
    maplist(ov_get_rc_(R, C), Grids, Vals),
    ov_first_nonbg_(BG, Vals, Val).

% ov_get_rc_(+R, +C, +Grid, -Val)
% Extract value at row R, column C from Grid.
ov_get_rc_(R, C, Grid, Val) :-
    nth0(R, Grid, Row),
    nth0(C, Row, Val).

% ov_priority_row_(+BG, +Grids, +R, +Cols, -ResultRow)
% Build one result row by scanning Grids for the first non-BG value per column.
ov_priority_row_(BG, Grids, R, Cols, ResultRow) :-
    maplist(ov_priority_cell_(BG, Grids, R), Cols, ResultRow).

% ov_priority(+Grids, +BG, -Result)
% Result[r][c] = first non-BG value at (r,c) scanning Grids in order.
% All grids must have the same dimensions.
ov_priority(Grids, BG, Result) :-
    Grids = [G1|_], G1 = [R1|_],
    length(G1, H), H1 is H - 1, numlist(0, H1, RowIds),
    length(R1, W), W1 is W - 1, numlist(0, W1, ColIds),
    maplist(ov_priority_row_idx_(BG, Grids, ColIds), RowIds, Result).

% ov_priority_row_idx_(+BG, +Grids, +ColIds, +R, -ResultRow)
% Build one result row for row R by scanning all Grids for first non-BG value per column.
ov_priority_row_idx_(BG, Grids, ColIds, R, ResultRow) :-
    maplist(ov_priority_cell_(BG, Grids, R), ColIds, ResultRow).

% ov_cell_replace_(+Old, +New, +A, -C)
% C = New if A equals Old; A otherwise.
ov_cell_replace_(Old, New, A, C) :-
    (A =:= Old -> C = New ; C = A).

% ov_row_replace_(+Old, +New, +Row, -ResultRow)
% Replace all occurrences of Old with New in a single row.
ov_row_replace_(Old, New, Row, ResultRow) :-
    maplist(ov_cell_replace_(Old, New), Row, ResultRow).

% ov_replace(+Grid, +Old, +New, -Result)
% Replace every cell equal to Old with New across the entire grid.
ov_replace(Grid, Old, New, Result) :-
    maplist(ov_row_replace_(Old, New), Grid, Result).

% ov_cell_fill_bg_(+BG, +Fill, +A, -C)
% C = Fill if A equals BG; A otherwise.
ov_cell_fill_bg_(BG, Fill, A, C) :-
    (A =:= BG -> C = Fill ; C = A).

% ov_row_fill_bg_(+BG, +Fill, +Row, -ResultRow)
% Replace all BG values with Fill in a single row.
ov_row_fill_bg_(BG, Fill, Row, ResultRow) :-
    maplist(ov_cell_fill_bg_(BG, Fill), Row, ResultRow).

% ov_fill_bg(+Grid, +BG, +Fill, -Result)
% Replace every cell equal to BG with Fill; all other cells unchanged.
ov_fill_bg(Grid, BG, Fill, Result) :-
    maplist(ov_row_fill_bg_(BG, Fill), Grid, Result).

% ov_cell_max_(+A, +B, -C)
% C = maximum of A and B.
ov_cell_max_(A, B, C) :- C is max(A, B).

% ov_row_max_(+RowA, +RowB, -RowC)
% Pointwise maximum of two rows.
ov_row_max_(RowA, RowB, RowC) :-
    maplist(ov_cell_max_, RowA, RowB, RowC).

% ov_max(+A, +B, -Result)
% Pointwise maximum of two same-size grids.
ov_max(A, B, Result) :-
    maplist(ov_row_max_, A, B, Result).

% ov_cell_min_(+A, +B, -C)
% C = minimum of A and B.
ov_cell_min_(A, B, C) :- C is min(A, B).

% ov_row_min_(+RowA, +RowB, -RowC)
% Pointwise minimum of two rows.
ov_row_min_(RowA, RowB, RowC) :-
    maplist(ov_cell_min_, RowA, RowB, RowC).

% ov_min(+A, +B, -Result)
% Pointwise minimum of two same-size grids.
ov_min(A, B, Result) :-
    maplist(ov_row_min_, A, B, Result).
