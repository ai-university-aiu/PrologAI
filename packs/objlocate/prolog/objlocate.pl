% objlocate.pl - Layer 183: Object-List Spatial and Attribute Query Against a Reference (lq_* prefix).
% Queries a list of obj(Color, Cells) terms for those satisfying a spatial or attribute
% relationship to a given reference object (also an obj term).
% Complements objrel (pairwise relationship tests on two objects) by applying those
% tests across a list to produce filtered subsets.
% No cross-pack dependencies.
:- module(objlocate, [
    % objlocate_above/3: objects whose centroid row is strictly less than Ref's centroid row.
    objlocate_above/3,
    % objlocate_below/3: objects whose centroid row is strictly greater than Ref's.
    objlocate_below/3,
    % objlocate_left_of/3: objects whose centroid col is strictly less than Ref's.
    objlocate_left_of/3,
    % objlocate_right_of/3: objects whose centroid col is strictly greater than Ref's.
    objlocate_right_of/3,
    % objlocate_touching4/3: objects 4-adjacent to Ref (share an edge: Manhattan distance 1 between cells).
    objlocate_touching4/3,
    % objlocate_touching8/3: objects 8-adjacent to Ref (share edge or corner: Chebyshev distance 1).
    objlocate_touching8/3,
    % objlocate_overlapping/3: objects sharing at least one cell with Ref.
    objlocate_overlapping/3,
    % objlocate_same_color/3: objects with the same color as Ref.
    objlocate_same_color/3,
    % objlocate_same_form/3: objects with the same normalized shape as Ref.
    objlocate_same_form/3,
    % objlocate_aligned_h/3: objects whose top-left row equals Ref's top-left row.
    objlocate_aligned_h/3,
    % objlocate_aligned_v/3: objects whose top-left col equals Ref's top-left col.
    objlocate_aligned_v/3,
    % objlocate_nearest/3: the single object in Objs nearest to Ref by squared centroid distance.
    objlocate_nearest/3,
    % objlocate_farthest/3: the single object in Objs farthest from Ref by squared centroid distance.
    objlocate_farthest/3,
    % objlocate_n_touching4/3: count of objects in Objs that are 4-touching Ref.
    objlocate_n_touching4/3
]).

% Load list utilities.
:- use_module(library(lists), [member/2]).

% --- Private helpers ---------------------------------------------------------

% objlocate_color_(+Obj, -Color): extract color.
objlocate_color_(obj(Color, _), Color).

% objlocate_cells_(+Obj, -Cells): extract cells.
objlocate_cells_(obj(_, Cells), Cells).

% objlocate_centroid_(+Obj, -CR-CC): float centroid (row, col).
objlocate_centroid_(Obj, CR-CC) :-
    objlocate_cells_(Obj, Cells),
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    length(Rs, N), N > 0,
    sum_list(Rs, SR), sum_list(Cs, SC),
    CR is SR / N,
    CC is SC / N.

% objlocate_topleft_(+Obj, -MinR-MinC): top-left corner (min row, min col).
objlocate_topleft_(Obj, MinR-MinC) :-
    objlocate_cells_(Obj, Cells),
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% objlocate_norm_(+Obj, -Sorted): normalized form (translate to origin, sort cells).
objlocate_norm_(Obj, Sorted) :-
    objlocate_cells_(Obj, Cells),
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

% objlocate_sq_dist_(+C1R-C1C, +C2R-C2C, -Dist2): squared centroid distance.
objlocate_sq_dist_(R1-C1, R2-C2, D) :-
    D is (R1-R2)*(R1-R2) + (C1-C2)*(C1-C2).

% objlocate_touch4_(+Cells1, +Cells2): 4-touching (Manhattan dist 1 between any cell pair).
objlocate_touch4_(Cells1, Cells2) :-
    member(r(R1,C1), Cells1),
    member(r(R2,C2), Cells2),
    abs(R1-R2) + abs(C1-C2) =:= 1,
    !.

% objlocate_touch8_(+Cells1, +Cells2): 8-touching (Chebyshev dist 1 between any cell pair).
objlocate_touch8_(Cells1, Cells2) :-
    member(r(R1,C1), Cells1),
    member(r(R2,C2), Cells2),
    max(abs(R1-R2), abs(C1-C2)) =:= 1,
    !.

% objlocate_overlap_(+Cells1, +Cells2): share at least one cell.
objlocate_overlap_(Cells1, Cells2) :-
    member(Cell, Cells1),
    memberchk(Cell, Cells2),
    !.

% --- Exported predicates -----------------------------------------------------

% objlocate_above(+Objs, +Ref, -Found): objects with centroid row < Ref centroid row.
objlocate_above(Objs, Ref, Found) :-
    objlocate_centroid_(Ref, RefR-_),
    findall(O,
        (member(O, Objs),
         objlocate_centroid_(O, OR-_),
         OR < RefR),
        Found).

% objlocate_below(+Objs, +Ref, -Found): objects with centroid row > Ref centroid row.
objlocate_below(Objs, Ref, Found) :-
    objlocate_centroid_(Ref, RefR-_),
    findall(O,
        (member(O, Objs),
         objlocate_centroid_(O, OR-_),
         OR > RefR),
        Found).

% objlocate_left_of(+Objs, +Ref, -Found): objects with centroid col < Ref centroid col.
objlocate_left_of(Objs, Ref, Found) :-
    objlocate_centroid_(Ref, _-RefC),
    findall(O,
        (member(O, Objs),
         objlocate_centroid_(O, _-OC),
         OC < RefC),
        Found).

% objlocate_right_of(+Objs, +Ref, -Found): objects with centroid col > Ref centroid col.
objlocate_right_of(Objs, Ref, Found) :-
    objlocate_centroid_(Ref, _-RefC),
    findall(O,
        (member(O, Objs),
         objlocate_centroid_(O, _-OC),
         OC > RefC),
        Found).

% objlocate_touching4(+Objs, +Ref, -Found): objects 4-adjacent to Ref, not overlapping.
objlocate_touching4(Objs, Ref, Found) :-
    objlocate_cells_(Ref, RefCells),
    findall(O,
        (member(O, Objs),
         objlocate_cells_(O, OCells),
         \+ objlocate_overlap_(OCells, RefCells),
         objlocate_touch4_(OCells, RefCells)),
        Found).

% objlocate_touching8(+Objs, +Ref, -Found): objects 8-adjacent to Ref, not overlapping.
objlocate_touching8(Objs, Ref, Found) :-
    objlocate_cells_(Ref, RefCells),
    findall(O,
        (member(O, Objs),
         objlocate_cells_(O, OCells),
         \+ objlocate_overlap_(OCells, RefCells),
         objlocate_touch8_(OCells, RefCells)),
        Found).

% objlocate_overlapping(+Objs, +Ref, -Found): objects sharing at least one cell with Ref.
objlocate_overlapping(Objs, Ref, Found) :-
    objlocate_cells_(Ref, RefCells),
    findall(O,
        (member(O, Objs),
         objlocate_cells_(O, OCells),
         objlocate_overlap_(OCells, RefCells)),
        Found).

% objlocate_same_color(+Objs, +Ref, -Found): objects with same color as Ref.
objlocate_same_color(Objs, Ref, Found) :-
    objlocate_color_(Ref, Color),
    findall(O,
        (member(O, Objs),
         objlocate_color_(O, Color)),
        Found).

% objlocate_same_form(+Objs, +Ref, -Found): objects with same normalized form as Ref.
objlocate_same_form(Objs, Ref, Found) :-
    objlocate_norm_(Ref, RefNorm),
    findall(O,
        (member(O, Objs),
         objlocate_norm_(O, RefNorm)),
        Found).

% objlocate_aligned_h(+Objs, +Ref, -Found): objects with same top-left row as Ref.
objlocate_aligned_h(Objs, Ref, Found) :-
    objlocate_topleft_(Ref, RefR-_),
    findall(O,
        (member(O, Objs),
         objlocate_topleft_(O, OR-_),
         OR =:= RefR),
        Found).

% objlocate_aligned_v(+Objs, +Ref, -Found): objects with same top-left col as Ref.
objlocate_aligned_v(Objs, Ref, Found) :-
    objlocate_topleft_(Ref, _-RefC),
    findall(O,
        (member(O, Objs),
         objlocate_topleft_(O, _-OC),
         OC =:= RefC),
        Found).

% objlocate_nearest(+Objs, +Ref, -Nearest): closest object in Objs to Ref by squared centroid dist.
objlocate_nearest(Objs, Ref, Nearest) :-
    Objs \= [],
    objlocate_centroid_(Ref, RC),
    findall(D-O, (member(O, Objs), objlocate_centroid_(O, OC), objlocate_sq_dist_(RC, OC, D)), Keyed),
    msort(Keyed, [_-Nearest|_]).

% objlocate_farthest(+Objs, +Ref, -Farthest): farthest object in Objs from Ref by squared centroid dist.
objlocate_farthest(Objs, Ref, Farthest) :-
    Objs \= [],
    objlocate_centroid_(Ref, RC),
    findall(NegD-O, (member(O, Objs), objlocate_centroid_(O, OC), objlocate_sq_dist_(RC, OC, D), NegD is -D), Keyed),
    msort(Keyed, [_-Farthest|_]).

% objlocate_n_touching4(+Objs, +Ref, -N): count of objects 4-touching Ref.
objlocate_n_touching4(Objs, Ref, N) :-
    objlocate_touching4(Objs, Ref, Found),
    length(Found, N).
