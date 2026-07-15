% xform.pl - Layer 151: Object-Level Transformation and Inference (xf_* prefix).
% Operates on obj(Color, Cells) terms where Cells is a sorted list of r(R,C) terms.
% Provides predicates for applying transformations to individual obj terms (recolor,
% translate, D4 symmetry operations, normalize) and for inferring what transformation
% connects two obj terms (cell offset, overlap, cell-set arithmetic, D4 discovery,
% scale factor, and cell-set merge).
:- module(xform, [
    % xform_recolor/3: create a new obj with a different color, keeping the same cells.
    xform_recolor/3,
    % xform_translate/3: shift all cells of an obj by a row-column offset r(DR,DC).
    xform_translate/3,
    % xform_normalize/2: translate an obj to the origin (min row=0, min col=0).
    xform_normalize/2,
    % xform_d4/3: apply a named D4 symmetry operation to the normalized form of an obj.
    xform_d4/3,
    % xform_same_cells/2: succeed if two obj terms have identical sorted cell sets.
    xform_same_cells/2,
    % xform_cell_offset/3: r(DR,DC) such that shifting Obj1 cells by (DR,DC) gives Obj2 cells.
    xform_cell_offset/3,
    % xform_is_recolor/2: same cells, different color.
    xform_is_recolor/2,
    % xform_cells_added/3: cells present in Obj2 but absent from Obj1.
    xform_cells_added/3,
    % xform_cells_removed/3: cells present in Obj1 but absent from Obj2.
    xform_cells_removed/3,
    % xform_cells_kept/3: cells present in both Obj1 and Obj2 (sorted intersection).
    xform_cells_kept/3,
    % xform_overlap_count/3: number of cells shared by Obj1 and Obj2.
    xform_overlap_count/3,
    % xform_any_d4/3: find a D4 Op such that applying Op to Obj1's normalized form gives Obj2's normalized form.
    xform_any_d4/3,
    % xform_scale_factor/3: integer N >= 1 such that Obj2 has N * size(Obj1) cells.
    xform_scale_factor/3,
    % xform_merge/3: merge two same-color obj terms into one obj with the union cell set.
    xform_merge/3
]).

% Import list utilities; sort/2, findall/3, length/2 are built-ins.
:- use_module(library(lists), [member/2, min_list/2, max_list/2, subtract/3,
                                memberchk/2]).

% xform_recolor(+Obj, +Color, -Out): replace the color field; keep the cell list unchanged.
xform_recolor(obj(_, Cells), Color, obj(Color, Cells)).

% xform_translate(+Obj, +r(DR,DC), -Out): shift every cell by (DR,DC); sort the result.
xform_translate(obj(Color, Cells), r(DR, DC), obj(Color, Out)) :-
% Build the shifted cell list.
    findall(r(R2,C2), (
        member(r(R,C), Cells),
        R2 is R + DR,
        C2 is C + DC
    ), Raw),
% Sort to maintain canonical cell order.
    sort(Raw, Out).

% xform_normalize(+Obj, -Out): translate obj so that min row = 0 and min col = 0.
xform_normalize(obj(Color, Cells), obj(Color, Norm)) :-
% Extract row and column indices.
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
% Top-left corner of the bounding box.
    min_list(Rs, MinR),
    min_list(Cs, MinC),
% Translate every cell to origin-relative coordinates.
    findall(r(R2,C2), (
        member(r(R,C), Cells),
        R2 is R - MinR,
        C2 is C - MinC
    ), Raw),
% Sort to maintain canonical cell order.
    sort(Raw, Norm).

% xform_cell_d4_(+Op, +R, +C, +H1, +W1, -NR, -NC): one D4 operation on a single cell.
% H1 = max row, W1 = max col of the normalized (origin-anchored) cell set.
% identity.
xform_cell_d4_(id,  R, C,  _,  _, R,  C).
% 90 degrees CW: (R,C) -> (C, H1-R).
xform_cell_d4_(r90, R, C, H1,  _, NR, NC) :- NR is C,      NC is H1 - R.
% 180 degrees: (R,C) -> (H1-R, W1-C).
xform_cell_d4_(r180,R, C, H1, W1, NR, NC) :- NR is H1 - R, NC is W1 - C.
% 270 degrees CW: (R,C) -> (W1-C, R).
xform_cell_d4_(r270,R, C,  _, W1, NR, NC) :- NR is W1 - C, NC is R.
% Horizontal flip: (R,C) -> (R, W1-C).
xform_cell_d4_(fh,  R, C,  _, W1, R,  NC) :- NC is W1 - C.
% Vertical flip: (R,C) -> (H1-R, C).
xform_cell_d4_(fv,  R, C, H1,  _, NR, C)  :- NR is H1 - R.
% Main diagonal transpose: (R,C) -> (C, R).
xform_cell_d4_(fd1, R, C,  _,  _, C,  R).
% Anti-diagonal transpose: (R,C) -> (W1-C, H1-R).
xform_cell_d4_(fd2, R, C, H1, W1, NR, NC) :- NR is W1 - C, NC is H1 - R.

% xform_d4(+Obj, +Op, -Out): apply named D4 op to the normalized form of Obj.
% The result is translated back to the same top-left corner as the input.
xform_d4(Obj, Op, Out) :-
% Extract color and cells.
    Obj = obj(Color, Cells),
% Find the top-left corner (used to restore position after normalization).
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC),
% Normalize to origin.
    findall(r(NR0,NC0), (
        member(r(R,C), Cells),
        NR0 is R - MinR,
        NC0 is C - MinC
    ), NormCells),
% Compute H1 and W1 of the normalized cell set.
    findall(R2, member(r(R2,_), NormCells), NRs),
    findall(C2, member(r(_,C2), NormCells), NCs),
    max_list(NRs, H1),
    max_list(NCs, W1),
% Apply the D4 operation and sort.
    findall(r(TR,TC), (
        member(r(R3,C3), NormCells),
        xform_cell_d4_(Op, R3, C3, H1, W1, TR, TC)
    ), TransRaw),
    sort(TransRaw, TransNorm),
% Translate back to the original top-left corner.
    findall(r(FR,FC), (
        member(r(R4,C4), TransNorm),
        FR is R4 + MinR,
        FC is C4 + MinC
    ), OutRaw),
    sort(OutRaw, OutCells),
    Out = obj(Color, OutCells).

% xform_same_cells(+Obj1, +Obj2): succeed if both obj terms have identical sorted cell sets.
xform_same_cells(obj(_, Cells), obj(_, Cells)).

% xform_cell_offset(+Obj1, +Obj2, -r(DR,DC)): translation vector from Obj1 to Obj2.
% Succeeds only when Obj1 and Obj2 have the same normalized shape (pure translation).
xform_cell_offset(Obj1, Obj2, r(DR, DC)) :-
% Normalize both objects to origin.
    xform_normalize(Obj1, obj(_, Norm1)),
    xform_normalize(Obj2, obj(_, Norm2)),
% Normalized cell sets must be identical (same shape).
    Norm1 = Norm2,
% The offset is the difference of the original top-left corners.
    Obj1 = obj(_, Cells1),
    Obj2 = obj(_, Cells2),
    findall(R, member(r(R,_), Cells1), Rs1),
    findall(C, member(r(_,C), Cells1), Cs1),
    findall(R, member(r(R,_), Cells2), Rs2),
    findall(C, member(r(_,C), Cells2), Cs2),
    min_list(Rs1, MinR1),
    min_list(Cs1, MinC1),
    min_list(Rs2, MinR2),
    min_list(Cs2, MinC2),
    DR is MinR2 - MinR1,
    DC is MinC2 - MinC1.

% xform_is_recolor(+Obj1, +Obj2): succeed if Obj1 and Obj2 have the same cells and different colors.
xform_is_recolor(obj(C1, Cells), obj(C2, Cells)) :-
% Colors must differ; cell lists are equal by unification.
    C1 \= C2.

% xform_cells_added(+Obj1, +Obj2, -Added): cells in Obj2 not present in Obj1 (sorted).
xform_cells_added(obj(_, C1), obj(_, C2), Added) :-
% subtract/3 removes elements of C1 from C2; both must be sorted for correct results.
    subtract(C2, C1, Added).

% xform_cells_removed(+Obj1, +Obj2, -Removed): cells in Obj1 not present in Obj2 (sorted).
xform_cells_removed(obj(_, C1), obj(_, C2), Removed) :-
% subtract/3 removes elements of C2 from C1.
    subtract(C1, C2, Removed).

% xform_cells_kept(+Obj1, +Obj2, -Kept): cells present in both Obj1 and Obj2 (sorted).
xform_cells_kept(obj(_, C1), obj(_, C2), Kept) :-
% Collect cells in C1 that also appear in C2.
    findall(Cell, (member(Cell, C1), memberchk(Cell, C2)), Raw),
% Sort removes duplicates in case the same cell appears twice.
    sort(Raw, Kept).

% xform_overlap_count(+Obj1, +Obj2, -N): number of cells shared by both obj terms.
xform_overlap_count(Obj1, Obj2, N) :-
% Compute the intersection first.
    xform_cells_kept(Obj1, Obj2, Kept),
% Count the shared cells.
    length(Kept, N).

% xform_any_d4(+Obj1, +Obj2, -Op): find a D4 Op s.t. d4(Op, Obj1.normalized) = Obj2.normalized.
xform_any_d4(Obj1, Obj2, Op) :-
% Normalize both objects to origin.
    xform_normalize(Obj1, obj(_, N1)),
    xform_normalize(Obj2, obj(_, N2)),
% Compute H1 and W1 of N1.
    findall(R, member(r(R,_), N1), Rs1),
    findall(C, member(r(_,C), N1), Cs1),
    max_list(Rs1, H1),
    max_list(Cs1, W1),
% Try each D4 operation in order; commit to the first match.
    member(Op, [id, r90, r180, r270, fh, fv, fd1, fd2]),
% Apply Op to N1 and sort.
    findall(r(NR,NC), (
        member(r(R,C), N1),
        xform_cell_d4_(Op, R, C, H1, W1, NR, NC)
    ), Raw),
    sort(Raw, N2),
% Cut after first matching operation to prevent choicepoint.
    !.

% xform_scale_factor(+Obj1, +Obj2, -N): integer N >= 1 such that |Obj2.cells| = N * |Obj1.cells|.
% Fails if the ratio is not a positive integer.
xform_scale_factor(obj(_, C1), obj(_, C2), N) :-
% Cell counts.
    length(C1, Len1),
    length(C2, Len2),
% Len1 must divide Len2 exactly.
    Len1 > 0,
    0 =:= Len2 mod Len1,
% N is the integer quotient.
    N is Len2 // Len1,
% Require a positive scale factor.
    N >= 1.

% xform_merge(+Obj1, +Obj2, -Out): merge two same-color obj terms into one with the union cell set.
xform_merge(obj(Color, C1), obj(Color, C2), obj(Color, Merged)) :-
% Concatenate the two cell lists.
    append(C1, C2, Combined),
% sort removes duplicates and produces a canonical sorted list.
    sort(Combined, Merged).
