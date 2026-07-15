% objsym.pl - Layer 170: Object Symmetry Analysis for obj(Color, Cells) Terms (os_* prefix).
% Provides bounding-box-relative reflection, rotation, and symmetry testing
% for individual obj(Color, Cells) terms. Works on object cell sets, not grids.
% Complements the sym and symmetry packs which operate on list-of-lists grids.
% Rotate-90 maps r(R,C) to r(C-MinC, MaxR-R) (CW rotation normalized to origin).
:- module(object_symmetry, [
    object_symmetry_bbox/5,
    object_symmetry_normalize/2,
    object_symmetry_translate/4,
    object_symmetry_reflect_h/2,
    object_symmetry_reflect_v/2,
    object_symmetry_rotate180/2,
    object_symmetry_rotate90/2,
    object_symmetry_is_hsymm/1,
    object_symmetry_is_vsymm/1,
    object_symmetry_is_rot180/1,
    object_symmetry_is_rot90/1,
    object_symmetry_has_symmetry/1,
    object_symmetry_symmetries/2,
    object_symmetry_equivalent/2
]).
% member/2, min_list/2, max_list/2 from library(lists).
:- use_module(library(lists), [member/2, min_list/2, max_list/2]).

% object_symmetry_bbox(+Obj, -MinR, -MinC, -MaxR, -MaxC): bounding box of Obj's cell set.
% MinR and MinC are the smallest row and column; MaxR and MaxC are the largest.
object_symmetry_bbox(obj(_, Cells), MinR, MinC, MaxR, MaxC) :-
% Collect all row indices from the cell list.
    findall(R, member(r(R,_), Cells), Rs),
% Collect all column indices from the cell list.
    findall(C, member(r(_,C), Cells), Cs),
% Minimum row is the top edge of the bounding box.
    min_list(Rs, MinR),
% Maximum row is the bottom edge of the bounding box.
    max_list(Rs, MaxR),
% Minimum column is the left edge of the bounding box.
    min_list(Cs, MinC),
% Maximum column is the right edge of the bounding box.
    max_list(Cs, MaxC).

% object_symmetry_normalize(+Obj, -NormObj): translate Obj so its bounding box starts at r(0,0).
% Subtracts MinR from every row index and MinC from every column index.
object_symmetry_normalize(obj(Color, Cells), obj(Color, NormCells)) :-
% Compute the bounding box minimum to determine translation offsets.
    object_symmetry_bbox(obj(Color, Cells), MinR, MinC, _, _),
% Translate each cell by (-MinR, -MinC) to anchor the bbox top-left at origin.
    findall(r(NR,NC), (member(r(R,C), Cells), NR is R - MinR, NC is C - MinC), NormCells).

% object_symmetry_translate(+Obj, +DR, +DC, -Moved): shift every cell of Obj by (DR, DC).
% DR is added to each row index; DC is added to each column index.
object_symmetry_translate(obj(Color, Cells), DR, DC, obj(Color, Moved)) :-
% Add the row delta to each row index and the column delta to each column index.
    findall(r(NR,NC), (member(r(R,C), Cells), NR is R + DR, NC is C + DC), Moved).

% object_symmetry_reflect_h(+Obj, -Reflected): reflect Obj left-right about its vertical center axis.
% For each cell r(R,C): new column = MinC + MaxC - C; row is unchanged.
% The vertical center axis is at column (MinC + MaxC) / 2.
object_symmetry_reflect_h(Obj, obj(Color, Reflected)) :-
% Get bounding box extents to compute the reflection column offset.
    Obj = obj(Color, Cells),
    object_symmetry_bbox(Obj, _, MinC, _, MaxC),
% Mirror each column about the bbox center: new C = MinC + MaxC - C.
    findall(r(R, NC), (member(r(R,C), Cells), NC is MinC + MaxC - C), Reflected).

% object_symmetry_reflect_v(+Obj, -Reflected): reflect Obj top-bottom about its horizontal center axis.
% For each cell r(R,C): new row = MinR + MaxR - R; column is unchanged.
% The horizontal center axis is at row (MinR + MaxR) / 2.
object_symmetry_reflect_v(Obj, obj(Color, Reflected)) :-
% Get bounding box extents to compute the reflection row offset.
    Obj = obj(Color, Cells),
    object_symmetry_bbox(Obj, MinR, _, MaxR, _),
% Mirror each row about the bbox center: new R = MinR + MaxR - R.
    findall(r(NR, C), (member(r(R,C), Cells), NR is MinR + MaxR - R), Reflected).

% object_symmetry_rotate180(+Obj, -Rotated): rotate Obj 180 degrees about its bbox center.
% Equivalent to applying both reflect_h and reflect_v simultaneously.
% For each cell r(R,C): new R = MinR+MaxR-R, new C = MinC+MaxC-C.
object_symmetry_rotate180(Obj, obj(Color, Rotated)) :-
% Get full bounding box to compute both row and column reflection offsets.
    Obj = obj(Color, Cells),
    object_symmetry_bbox(Obj, MinR, MinC, MaxR, MaxC),
% Apply 180-degree rotation: negate both coordinates relative to bbox center.
    findall(r(NR,NC),
            (member(r(R,C), Cells), NR is MinR + MaxR - R, NC is MinC + MaxC - C),
            Rotated).

% object_symmetry_rotate90(+Obj, -Rotated): rotate Obj 90 degrees clockwise, normalized to origin.
% Formula: r(R,C) -> r(C - MinC, MaxR - R), which maps the bbox to the origin.
% The result has bbox starting at r(0,0). This changes bbox aspect ratio.
object_symmetry_rotate90(Obj, obj(Color, Rotated)) :-
% Get bounding box to compute the CW-rotation formula components.
    Obj = obj(Color, Cells),
    object_symmetry_bbox(Obj, _, MinC, MaxR, _),
% CW rotate: new row = old col - MinC; new col = MaxR - old row.
    findall(r(NR,NC),
            (member(r(R,C), Cells), NR is C - MinC, NC is MaxR - R),
            Rotated).

% object_symmetry_cells_sorted_(+obj(_, Cells), -Sorted): helper; sort the cell list for comparison.
object_symmetry_cells_sorted_(obj(_, Cells), Sorted) :-
% Sort cells to produce a canonical order independent of generation order.
    msort(Cells, Sorted).

% object_symmetry_is_hsymm(+Obj): true when Obj is symmetric under left-right reflection.
% The object maps to itself under object_symmetry_reflect_h: sorted cells are unchanged.
object_symmetry_is_hsymm(Obj) :-
% Reflect the object and compare sorted cell sets.
    object_symmetry_reflect_h(Obj, Ref),
    object_symmetry_cells_sorted_(Obj, S1),
    object_symmetry_cells_sorted_(Ref, S2),
    S1 == S2.

% object_symmetry_is_vsymm(+Obj): true when Obj is symmetric under top-bottom reflection.
% The object maps to itself under object_symmetry_reflect_v: sorted cells are unchanged.
object_symmetry_is_vsymm(Obj) :-
% Reflect the object vertically and compare sorted cell sets.
    object_symmetry_reflect_v(Obj, Ref),
    object_symmetry_cells_sorted_(Obj, S1),
    object_symmetry_cells_sorted_(Ref, S2),
    S1 == S2.

% object_symmetry_is_rot180(+Obj): true when Obj is symmetric under 180-degree rotation.
% The object maps to itself under object_symmetry_rotate180: sorted cells are unchanged.
object_symmetry_is_rot180(Obj) :-
% Rotate 180 degrees and compare sorted cell sets.
    object_symmetry_rotate180(Obj, Rot),
    object_symmetry_cells_sorted_(Obj, S1),
    object_symmetry_cells_sorted_(Rot, S2),
    S1 == S2.

% object_symmetry_is_rot90(+Obj): true when Obj is symmetric under 90-degree CW rotation.
% Compare sorted cells of normalized Obj with sorted cells of normalized rotate90.
% Requires normalization to origin before and after rotation for fair comparison.
object_symmetry_is_rot90(Obj) :-
% Normalize Obj to origin so comparison is position-independent.
    object_symmetry_normalize(Obj, Norm),
% Rotate the normalized object 90 degrees CW (result already at origin).
    object_symmetry_rotate90(Norm, Rotated),
% Normalize the rotated result again to handle any residual offset.
    object_symmetry_normalize(Rotated, RotNorm),
    object_symmetry_cells_sorted_(Norm, S1),
    object_symmetry_cells_sorted_(RotNorm, S2),
    S1 == S2.

% object_symmetry_has_symmetry(+Obj): true when Obj has at least one non-trivial symmetry.
% Checks h, v, rot180, and rot90 symmetries.
object_symmetry_has_symmetry(Obj) :-
% Succeed as soon as the first symmetry test passes.
    (object_symmetry_is_hsymm(Obj) ; object_symmetry_is_vsymm(Obj) ; object_symmetry_is_rot180(Obj) ; object_symmetry_is_rot90(Obj)), !.

% object_symmetry_symmetries(+Obj, -List): List is the set of symmetry atoms that hold for Obj.
% Atoms are h (horizontal), v (vertical), rot180, rot90.
object_symmetry_symmetries(Obj, List) :-
% Check each symmetry type and include its atom only if the test succeeds.
    findall(Sym,
            (member(Sym, [h, v, rot180, rot90]),
             (Sym == h     -> object_symmetry_is_hsymm(Obj)  ;
              Sym == v     -> object_symmetry_is_vsymm(Obj)  ;
              Sym == rot180 -> object_symmetry_is_rot180(Obj) ;
                              object_symmetry_is_rot90(Obj))),
            List).

% object_symmetry_d4_orbit_(+Obj, -Variant): generate all 8 D4 orientations of Obj (normalized).
% The dihedral group D4 has 4 rotations and 4 rotation-then-reflection variants.
object_symmetry_d4_orbit_(Obj, Variant) :-
% Normalize to origin so all comparisons are position-independent.
    object_symmetry_normalize(Obj, N),
% Compute all three non-identity rotations.
    object_symmetry_rotate90(N, R1tmp), object_symmetry_normalize(R1tmp, R1),
    object_symmetry_rotate90(R1, R2tmp), object_symmetry_normalize(R2tmp, R2),
    object_symmetry_rotate90(R2, R3tmp), object_symmetry_normalize(R3tmp, R3),
% Compute the horizontal reflection and its three rotations.
    object_symmetry_reflect_h(N, Ftmp), object_symmetry_normalize(Ftmp, F),
    object_symmetry_rotate90(F, F1tmp), object_symmetry_normalize(F1tmp, F1),
    object_symmetry_rotate90(F1, F2tmp), object_symmetry_normalize(F2tmp, F2),
    object_symmetry_rotate90(F2, F3tmp), object_symmetry_normalize(F3tmp, F3),
% Yield each of the 8 variants one by one via backtracking.
    member(Variant, [N, R1, R2, R3, F, F1, F2, F3]).

% object_symmetry_equivalent(+Obj1, +Obj2): true when Obj1 and Obj2 have the same cell shape
% under any D4 orientation (4 rotations x 2 reflections). Color is ignored.
% Normalization ensures position-independent comparison.
object_symmetry_equivalent(Obj1, Obj2) :-
% Normalize Obj1 and get its sorted cell set for comparison.
    object_symmetry_normalize(Obj1, Norm1),
    object_symmetry_cells_sorted_(Norm1, S1),
% Try each D4 variant of Obj2 until one matches Obj1's normalized cell set.
    object_symmetry_d4_orbit_(Obj2, Variant),
    object_symmetry_cells_sorted_(Variant, SV),
    S1 == SV, !.
