% objdelta.pl - Layer 176: Object-Pair Change Analysis and Rule Application (dp_* prefix).
% Analyses pairs of obj(Color, Cells) terms (before/after) to extract what changed:
% color, position, or size. Extracts generalisable rules (color maps, constant
% displacement) from a list of pairs and applies those rules to new objects.
% Pairs are represented as O1-O2 terms, consistent with the link pack.
% No cross-pack dependencies.
:- module(objdelta, [
    % objdelta_color_delta/3: extract the color change C1-C2 from a before-after pair.
    objdelta_color_delta/3,
    % objdelta_pos_delta/3: extract the centroid displacement dr(DR,DC) from a pair.
    objdelta_pos_delta/3,
    % objdelta_size_delta/3: extract the size change (N2-N1) from a pair.
    objdelta_size_delta/3,
    % objdelta_same_color/2: succeed if O1 and O2 have the same color.
    objdelta_same_color/2,
    % objdelta_same_form/2: succeed if O1 and O2 have the same origin-normalised shape.
    objdelta_same_form/2,
    % objdelta_same_pos/2: succeed if O1 and O2 have the same floor-average centroid.
    objdelta_same_pos/2,
    % objdelta_color_map/2: extract sorted distinct C1-C2 pairs from a list of O1-O2 pairs.
    objdelta_color_map/2,
    % objdelta_apply_color/3: recolor Obj to C2 if its color equals C1; otherwise fail.
    objdelta_apply_color/3,
    % objdelta_apply_color_map/3: apply the first matching entry in Map to Obj.
    objdelta_apply_color_map/3,
    % objdelta_apply_map_all/3: apply Map to every obj in a list.
    objdelta_apply_map_all/3,
    % objdelta_const_dr/2: all O1-O2 pairs have the same row centroid delta DR.
    objdelta_const_dr/2,
    % objdelta_const_dc/2: all O1-O2 pairs have the same col centroid delta DC.
    objdelta_const_dc/2,
    % objdelta_common_cells/3: cell positions present in both O1 and O2.
    objdelta_common_cells/3,
    % objdelta_cell_diff/4: Added = in O2 but not O1; Removed = in O1 but not O2.
    objdelta_cell_diff/4
]).

% Load list utilities.
:- use_module(library(lists), [member/2, sum_list/2, min_list/2, subtract/3, intersection/3]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% objdelta_centroid_(+Obj, -r(CR,CC)): floor-average centroid of an obj term.
objdelta_centroid_(obj(_, Cells), r(CR, CC)) :-
% Collect row indices from cell list.
    findall(R, member(r(R,_), Cells), Rs),
% Collect col indices from cell list.
    findall(C, member(r(_,C), Cells), Cs),
% Denominator is the number of cells.
    length(Rs, N),
% Sum the rows.
    sum_list(Rs, SR),
% Sum the columns.
    sum_list(Cs, SC),
% Floor-average row.
    CR is SR // N,
% Floor-average column.
    CC is SC // N.

% objdelta_norm_(+Cells, -Norm): translate cell list to origin, sorted.
objdelta_norm_(Cells, Norm) :-
% Collect row indices.
    findall(R, member(r(R,_), Cells), Rs),
% Collect col indices.
    findall(C, member(r(_,C), Cells), Cs),
% Find minimum row and col for translation.
    min_list(Rs, MinR),
    min_list(Cs, MinC),
% Translate all cells to origin.
    findall(r(NR,NC),
        (member(r(R,C), Cells),
         NR is R - MinR,
         NC is C - MinC),
        Raw),
% Sort to canonical order.
    sort(Raw, Norm).

% objdelta_row_of_(+DR, +dr(DR,_)): unify the row component of a displacement.
objdelta_row_of_(DR, dr(DR, _)).

% objdelta_col_of_(+DC, +dr(_,DC)): unify the col component of a displacement.
objdelta_col_of_(DC, dr(_, DC)).

% objdelta_pair_delta_(+O1-O2, -dr(DR,DC)): centroid displacement for one pair.
objdelta_pair_delta_(O1-O2, dr(DR, DC)) :-
% Centroid of the first object.
    objdelta_centroid_(O1, r(R1, C1)),
% Centroid of the second object.
    objdelta_centroid_(O2, r(R2, C2)),
% Row delta.
    DR is R2 - R1,
% Col delta.
    DC is C2 - C1.

% objdelta_color_pair_(+O1-O2, -C1-C2): color pair for one O1-O2 term.
objdelta_color_pair_(obj(C1,_)-obj(C2,_), C1-C2).

% objdelta_positions_(+Obj, -Positions): sorted list of r(R,C) positions in an obj.
objdelta_positions_(obj(_, Cells), Positions) :-
% Extract the sorted cell positions.
    sort(Cells, Positions).

% --- Exported predicates -----------------------------------------------------

% objdelta_color_delta(+O1, +O2, -C1-C2): color of O1 is C1; color of O2 is C2.
% Both C1 and C2 are always bound; they may be equal (no color change).
objdelta_color_delta(obj(C1, _), obj(C2, _), C1-C2).

% objdelta_pos_delta(+O1, +O2, -dr(DR,DC)): centroid displacement from O1 to O2.
objdelta_pos_delta(O1, O2, dr(DR, DC)) :-
% Compute centroid of the before object.
    objdelta_centroid_(O1, r(R1, C1)),
% Compute centroid of the after object.
    objdelta_centroid_(O2, r(R2, C2)),
% Row displacement.
    DR is R2 - R1,
% Column displacement.
    DC is C2 - C1.

% objdelta_size_delta(+O1, +O2, -D): D = |Cells2| - |Cells1|.
objdelta_size_delta(obj(_, C1), obj(_, C2), D) :-
% Count cells in before object.
    length(C1, N1),
% Count cells in after object.
    length(C2, N2),
% Size change is N2 minus N1.
    D is N2 - N1.

% objdelta_same_color(+O1, +O2): O1 and O2 have the same color atom.
objdelta_same_color(obj(C, _), obj(C, _)).

% objdelta_same_form(+O1, +O2): O1 and O2 have the same origin-normalised cell list.
% Colour is ignored; only the shape matters.
objdelta_same_form(obj(_, C1), obj(_, C2)) :-
% Normalise both cell lists to origin.
    objdelta_norm_(C1, N1),
    objdelta_norm_(C2, N2),
% Compare normalised forms.
    N1 == N2.

% objdelta_same_pos(+O1, +O2): O1 and O2 share the same floor-average centroid.
objdelta_same_pos(O1, O2) :-
% Centroid of O1.
    objdelta_centroid_(O1, C),
% Centroid of O2 must equal C.
    objdelta_centroid_(O2, C).

% objdelta_color_map(+Pairs, -Map): sorted distinct C1-C2 pairs from O1-O2 list.
% Pairs where C1 = C2 (no change) are included. Map is a sorted distinct list.
objdelta_color_map(Pairs, Map) :-
% Extract raw C1-C2 from each pair.
    maplist(objdelta_color_pair_, Pairs, RawMap),
% Sort to remove duplicates and produce a canonical order.
    sort(RawMap, Map).

% objdelta_apply_color(+C1-C2, +Obj, -Obj2): recolor Obj from C1 to C2.
% Fails if Obj's color is not C1. Obj2 has the same cells as Obj.
objdelta_apply_color(C1-C2, obj(C1, Cells), obj(C2, Cells)).

% objdelta_apply_color_map(+Map, +Obj, -Obj2): apply the first matching entry in Map.
% Fails if no Map entry matches Obj's color.
objdelta_apply_color_map([Rule|_], Obj, Obj2) :-
% Try the current rule; succeed if it matches.
    objdelta_apply_color(Rule, Obj, Obj2), !.
objdelta_apply_color_map([_|Rest], Obj, Obj2) :-
% Try remaining rules.
    objdelta_apply_color_map(Rest, Obj, Obj2).

% objdelta_apply_map_all(+Map, +Objs, -Objs2): apply Map to every obj in Objs.
% Objects whose color is not in Map are left unchanged.
objdelta_apply_map_all(_, [], []).
objdelta_apply_map_all(Map, [Obj|Rest], [Obj2|Rest2]) :-
% Apply the map to the head object.
    (   objdelta_apply_color_map(Map, Obj, Obj2)
    ->  true
    ;   Obj2 = Obj
    ),
% Recurse on the tail.
    objdelta_apply_map_all(Map, Rest, Rest2).

% objdelta_const_dr(+Pairs, -DR): all O1-O2 pairs have the same row centroid delta DR.
% Requires at least one pair. Fails if deltas differ.
objdelta_const_dr(Pairs, DR) :-
% At least one pair required.
    Pairs = [_|_],
% Compute displacement for each pair.
    maplist(objdelta_pair_delta_, Pairs, Deltas),
% Extract first DR as reference.
    Deltas = [dr(DR,_)|Rest],
% Verify all remaining row deltas match.
    maplist(objdelta_row_of_(DR), Rest).

% objdelta_const_dc(+Pairs, -DC): all O1-O2 pairs have the same col centroid delta DC.
% Requires at least one pair. Fails if deltas differ.
objdelta_const_dc(Pairs, DC) :-
% At least one pair required.
    Pairs = [_|_],
% Compute displacement for each pair.
    maplist(objdelta_pair_delta_, Pairs, Deltas),
% Extract first DC as reference.
    Deltas = [dr(_,DC)|Rest],
% Verify all remaining col deltas match.
    maplist(objdelta_col_of_(DC), Rest).

% objdelta_common_cells(+O1, +O2, -Cells): cell positions in both O1 and O2.
% Cells is the sorted intersection of the two position lists.
objdelta_common_cells(O1, O2, Cells) :-
% Sorted positions of O1.
    objdelta_positions_(O1, P1),
% Sorted positions of O2.
    objdelta_positions_(O2, P2),
% Intersection of the two position sets.
    intersection(P1, P2, Cells).

% objdelta_cell_diff(+O1, +O2, -Added, -Removed): cell position symmetric difference.
% Added: positions in O2 not in O1. Removed: positions in O1 not in O2.
objdelta_cell_diff(O1, O2, Added, Removed) :-
% Sorted positions of O1.
    objdelta_positions_(O1, P1),
% Sorted positions of O2.
    objdelta_positions_(O2, P2),
% Cells added (present in O2 but absent from O1).
    subtract(P2, P1, Added),
% Cells removed (present in O1 but absent from O2).
    subtract(P1, P2, Removed).
