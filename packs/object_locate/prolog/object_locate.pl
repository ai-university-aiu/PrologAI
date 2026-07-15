% objlocate.pl - Layer 183: Object-List Spatial and Attribute Query Against a Reference (lq_* prefix).
% Queries a list of obj(Color, Cells) terms for those satisfying a spatial or attribute
% relationship to a given reference object (also an obj term).
% Complements objrel (pairwise relationship tests on two objects) by applying those
% tests across a list to produce filtered subsets.
% No cross-pack dependencies.
:- module(object_locate, [
    % object_locate_above/3: objects whose centroid row is strictly less than Ref's centroid row.
    object_locate_above/3,
    % object_locate_below/3: objects whose centroid row is strictly greater than Ref's.
    object_locate_below/3,
    % object_locate_left_of/3: objects whose centroid col is strictly less than Ref's.
    object_locate_left_of/3,
    % object_locate_right_of/3: objects whose centroid col is strictly greater than Ref's.
    object_locate_right_of/3,
    % object_locate_touching4/3: objects 4-adjacent to Ref (share an edge: Manhattan distance 1 between cells).
    object_locate_touching4/3,
    % object_locate_touching8/3: objects 8-adjacent to Ref (share edge or corner: Chebyshev distance 1).
    object_locate_touching8/3,
    % object_locate_overlapping/3: objects sharing at least one cell with Ref.
    object_locate_overlapping/3,
    % object_locate_same_color/3: objects with the same color as Ref.
    object_locate_same_color/3,
    % object_locate_same_form/3: objects with the same normalized shape as Ref.
    object_locate_same_form/3,
    % object_locate_aligned_h/3: objects whose top-left row equals Ref's top-left row.
    object_locate_aligned_h/3,
    % object_locate_aligned_v/3: objects whose top-left col equals Ref's top-left col.
    object_locate_aligned_v/3,
    % object_locate_nearest/3: the single object in Objs nearest to Ref by squared centroid distance.
    object_locate_nearest/3,
    % object_locate_farthest/3: the single object in Objs farthest from Ref by squared centroid distance.
    object_locate_farthest/3,
    % object_locate_n_touching4/3: count of objects in Objs that are 4-touching Ref.
    object_locate_n_touching4/3
]).

% Load list utilities.
:- use_module(library(lists), [member/2]).

% --- Private helpers ---------------------------------------------------------

% object_locate_color_(+Obj, -Color): extract color.
object_locate_color_(obj(Color, _), Color).

% object_locate_cells_(+Obj, -Cells): extract cells.
object_locate_cells_(obj(_, Cells), Cells).

% object_locate_centroid_(+Obj, -CR-CC): float centroid (row, col).
object_locate_centroid_(Obj, CR-CC) :-
    object_locate_cells_(Obj, Cells),
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    length(Rs, N), N > 0,
    sum_list(Rs, SR), sum_list(Cs, SC),
    CR is SR / N,
    CC is SC / N.

% object_locate_topleft_(+Obj, -MinR-MinC): top-left corner (min row, min col).
object_locate_topleft_(Obj, MinR-MinC) :-
    object_locate_cells_(Obj, Cells),
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% object_locate_norm_(+Obj, -Sorted): normalized form (translate to origin, sort cells).
object_locate_norm_(Obj, Sorted) :-
    object_locate_cells_(Obj, Cells),
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC),
    findall(r(NR,NC),
        (member(r(R,C), Cells),
         NR is R - MinR,
         NC is C - MinC),
        Raw),
    sort(Raw, Sorted).

% object_locate_sq_dist_(+C1R-C1C, +C2R-C2C, -Dist2): squared centroid distance.
object_locate_sq_dist_(R1-C1, R2-C2, D) :-
    D is (R1-R2)*(R1-R2) + (C1-C2)*(C1-C2).

% object_locate_touch4_(+Cells1, +Cells2): 4-touching (Manhattan dist 1 between any cell pair).
object_locate_touch4_(Cells1, Cells2) :-
    member(r(R1,C1), Cells1),
    member(r(R2,C2), Cells2),
    abs(R1-R2) + abs(C1-C2) =:= 1,
    !.

% object_locate_touch8_(+Cells1, +Cells2): 8-touching (Chebyshev dist 1 between any cell pair).
object_locate_touch8_(Cells1, Cells2) :-
    member(r(R1,C1), Cells1),
    member(r(R2,C2), Cells2),
    max(abs(R1-R2), abs(C1-C2)) =:= 1,
    !.

% object_locate_overlap_(+Cells1, +Cells2): share at least one cell.
object_locate_overlap_(Cells1, Cells2) :-
    member(Cell, Cells1),
    memberchk(Cell, Cells2),
    !.

% --- Exported predicates -----------------------------------------------------

% object_locate_above(+Objs, +Ref, -Found): objects with centroid row < Ref centroid row.
object_locate_above(Objs, Ref, Found) :-
    object_locate_centroid_(Ref, RefR-_),
    findall(O,
        (member(O, Objs),
         object_locate_centroid_(O, OR-_),
         OR < RefR),
        Found).

% object_locate_below(+Objs, +Ref, -Found): objects with centroid row > Ref centroid row.
object_locate_below(Objs, Ref, Found) :-
    object_locate_centroid_(Ref, RefR-_),
    findall(O,
        (member(O, Objs),
         object_locate_centroid_(O, OR-_),
         OR > RefR),
        Found).

% object_locate_left_of(+Objs, +Ref, -Found): objects with centroid col < Ref centroid col.
object_locate_left_of(Objs, Ref, Found) :-
    object_locate_centroid_(Ref, _-RefC),
    findall(O,
        (member(O, Objs),
         object_locate_centroid_(O, _-OC),
         OC < RefC),
        Found).

% object_locate_right_of(+Objs, +Ref, -Found): objects with centroid col > Ref centroid col.
object_locate_right_of(Objs, Ref, Found) :-
    object_locate_centroid_(Ref, _-RefC),
    findall(O,
        (member(O, Objs),
         object_locate_centroid_(O, _-OC),
         OC > RefC),
        Found).

% object_locate_touching4(+Objs, +Ref, -Found): objects 4-adjacent to Ref, not overlapping.
object_locate_touching4(Objs, Ref, Found) :-
    object_locate_cells_(Ref, RefCells),
    findall(O,
        (member(O, Objs),
         object_locate_cells_(O, OCells),
         \+ object_locate_overlap_(OCells, RefCells),
         object_locate_touch4_(OCells, RefCells)),
        Found).

% object_locate_touching8(+Objs, +Ref, -Found): objects 8-adjacent to Ref, not overlapping.
object_locate_touching8(Objs, Ref, Found) :-
    object_locate_cells_(Ref, RefCells),
    findall(O,
        (member(O, Objs),
         object_locate_cells_(O, OCells),
         \+ object_locate_overlap_(OCells, RefCells),
         object_locate_touch8_(OCells, RefCells)),
        Found).

% object_locate_overlapping(+Objs, +Ref, -Found): objects sharing at least one cell with Ref.
object_locate_overlapping(Objs, Ref, Found) :-
    object_locate_cells_(Ref, RefCells),
    findall(O,
        (member(O, Objs),
         object_locate_cells_(O, OCells),
         object_locate_overlap_(OCells, RefCells)),
        Found).

% object_locate_same_color(+Objs, +Ref, -Found): objects with same color as Ref.
object_locate_same_color(Objs, Ref, Found) :-
    object_locate_color_(Ref, Color),
    findall(O,
        (member(O, Objs),
         object_locate_color_(O, Color)),
        Found).

% object_locate_same_form(+Objs, +Ref, -Found): objects with same normalized form as Ref.
object_locate_same_form(Objs, Ref, Found) :-
    object_locate_norm_(Ref, RefNorm),
    findall(O,
        (member(O, Objs),
         object_locate_norm_(O, RefNorm)),
        Found).

% object_locate_aligned_h(+Objs, +Ref, -Found): objects with same top-left row as Ref.
object_locate_aligned_h(Objs, Ref, Found) :-
    object_locate_topleft_(Ref, RefR-_),
    findall(O,
        (member(O, Objs),
         object_locate_topleft_(O, OR-_),
         OR =:= RefR),
        Found).

% object_locate_aligned_v(+Objs, +Ref, -Found): objects with same top-left col as Ref.
object_locate_aligned_v(Objs, Ref, Found) :-
    object_locate_topleft_(Ref, _-RefC),
    findall(O,
        (member(O, Objs),
         object_locate_topleft_(O, _-OC),
         OC =:= RefC),
        Found).

% object_locate_nearest(+Objs, +Ref, -Nearest): closest object in Objs to Ref by squared centroid dist.
object_locate_nearest(Objs, Ref, Nearest) :-
    Objs \= [],
    object_locate_centroid_(Ref, RC),
    findall(D-O, (member(O, Objs), object_locate_centroid_(O, OC), object_locate_sq_dist_(RC, OC, D)), Keyed),
    msort(Keyed, [_-Nearest|_]).

% object_locate_farthest(+Objs, +Ref, -Farthest): farthest object in Objs from Ref by squared centroid dist.
object_locate_farthest(Objs, Ref, Farthest) :-
    Objs \= [],
    object_locate_centroid_(Ref, RC),
    findall(NegD-O, (member(O, Objs), object_locate_centroid_(O, OC), object_locate_sq_dist_(RC, OC, D), NegD is -D), Keyed),
    msort(Keyed, [_-Farthest|_]).

% object_locate_n_touching4(+Objs, +Ref, -N): count of objects 4-touching Ref.
object_locate_n_touching4(Objs, Ref, N) :-
    object_locate_touching4(Objs, Ref, Found),
    length(Found, N).
