% objmatch.pl - Layer 178: Object-List Correspondence and Matching (mx_* prefix).
% Finds correspondences between two obj(Color, Cells) term lists.
% Supports matching by color, size, form, and position; extracting unmatched
% objects; filtering pairs by change type; computing per-pair deltas; and
% testing whether all pairs share the same delta. Also provides positional zip.
% No cross-pack dependencies.
:- module(objmatch, [
    % objmatch_by_color/3: match objects with the same color; returns o1-o2 pairs.
    objmatch_by_color/3,
    % objmatch_by_size/3: match objects with the same cell count; returns o1-o2 pairs.
    objmatch_by_size/3,
    % objmatch_by_form/3: match objects with the same normalized shape; returns o1-o2 pairs.
    objmatch_by_form/3,
    % objmatch_by_nearest/3: greedy nearest-centroid matching; returns o1-o2 pairs.
    objmatch_by_nearest/3,
    % objmatch_unmatched/5: objects from each list that do not appear in Pairs.
    objmatch_unmatched/5,
    % objmatch_filter_changed_color/2: keep only pairs where the two colors differ.
    objmatch_filter_changed_color/2,
    % objmatch_filter_same_color/2: keep only pairs where the two colors are identical.
    objmatch_filter_same_color/2,
    % objmatch_color_deltas/2: list of c1-c2 atoms from each matched pair.
    objmatch_color_deltas/2,
    % objmatch_pos_deltas/2: list of dr(DR,DC) terms from each matched pair.
    objmatch_pos_deltas/2,
    % objmatch_size_deltas/2: list of integer N2-N1 values from each matched pair.
    objmatch_size_deltas/2,
    % objmatch_all_same_color_delta/1: true iff all pairs have the same c1-c2 color change.
    objmatch_all_same_color_delta/1,
    % objmatch_all_same_pos_delta/1: true iff all pairs have the same dr(DR,DC) delta.
    objmatch_all_same_pos_delta/1,
    % objmatch_all_same_size_delta/1: true iff all pairs have the same N2-N1 size change.
    objmatch_all_same_size_delta/1,
    % objmatch_zip/3: positional zip — pair List1[I] with List2[I] (lists must be equal length).
    objmatch_zip/3
]).

% Load list utilities.
:- use_module(library(lists), [member/2, subtract/3, nth0/3]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% objmatch_color_(+Obj, -Color): extract the color field from an obj term.
objmatch_color_(obj(Color, _), Color).

% objmatch_size_(+Obj, -N): extract cell count from an obj term.
objmatch_size_(obj(_, Cells), N) :-
% Count cells directly.
    length(Cells, N).

% objmatch_norm_(+Obj, -Sorted): normalize obj to origin and sort cells.
objmatch_norm_(obj(_, Cells), Sorted) :-
% Compute bounding box top-left.
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC),
% Translate all cells to origin.
    findall(r(NR,NC),
        (member(r(R,C), Cells),
         NR is R - MinR,
         NC is C - MinC),
        Raw),
% Sort for canonical form.
    sort(Raw, Sorted).

% objmatch_centroid_(+Obj, -r(CR,CC)): floor-average centroid.
objmatch_centroid_(obj(_, Cells), r(CR, CC)) :-
% Collect row and col values.
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    length(Rs, N),
    sum_list(Rs, SR),
    sum_list(Cs, SC),
% Integer floor division for centroid.
    CR is SR // N,
    CC is SC // N.

% objmatch_sq_dist_(+r(R1,C1), +r(R2,C2), -D2): squared Euclidean distance.
objmatch_sq_dist_(r(R1,C1), r(R2,C2), D2) :-
    DR is R2 - R1,
    DC is C2 - C1,
    D2 is DR*DR + DC*DC.

% objmatch_nearest_in_(+Centroids2, +Objs2, +Centroid1, -Obj2): find closest Obj2.
% Centroids2 is parallel to Objs2. Returns first minimum-distance match.
objmatch_nearest_in_(Centroids2, Objs2, Centroid1, Obj2) :-
% Compute squared distances from Centroid1 to each Centroid2.
    findall(D2-O2,
        (nth0(I, Centroids2, C2),
         nth0(I, Objs2, O2),
         objmatch_sq_dist_(Centroid1, C2, D2)),
        Pairs),
% Sort by distance ascending.
    msort(Pairs, [_-Obj2|_]).

% objmatch_greedy_match_(+Objs1, +Objs2, -Pairs): greedy nearest-centroid matching.
% Processes Objs1 in order; each obj in Objs1 claims the nearest remaining Objs2.
objmatch_greedy_match_([], _, []).
objmatch_greedy_match_([O1|Rest1], Objs2, [O1-O2|Pairs]) :-
    Objs2 \= [],
    objmatch_centroid_(O1, C1),
    maplist(objmatch_centroid_, Objs2, Cs2),
    objmatch_nearest_in_(Cs2, Objs2, C1, O2),
    subtract(Objs2, [O2], Remaining),
    objmatch_greedy_match_(Rest1, Remaining, Pairs).
objmatch_greedy_match_([_|Rest1], [], Pairs) :-
    objmatch_greedy_match_(Rest1, [], Pairs).

% objmatch_color_delta_(+O1-O2, -c1-c2): extract color pair from a match pair.
objmatch_color_delta_(O1-O2, C1-C2) :-
    objmatch_color_(O1, C1),
    objmatch_color_(O2, C2).

% objmatch_pos_delta_(+O1-O2, -dr(DR,DC)): centroid delta from a match pair.
objmatch_pos_delta_(O1-O2, dr(DR, DC)) :-
    objmatch_centroid_(O1, r(R1,C1)),
    objmatch_centroid_(O2, r(R2,C2)),
    DR is R2 - R1,
    DC is C2 - C1.

% objmatch_size_delta_(+O1-O2, -Delta): size delta (N2-N1) from a match pair.
objmatch_size_delta_(O1-O2, Delta) :-
    objmatch_size_(O1, N1),
    objmatch_size_(O2, N2),
    Delta is N2 - N1.

% --- Exported predicates -----------------------------------------------------

% objmatch_by_color(+List1, +List2, -Pairs): match objects with the same color.
% Each Obj1 in List1 is paired with the first Obj2 in List2 that has the same color.
% Result is a list of O1-O2 pairs (may have duplicates if colors repeat).
objmatch_by_color(List1, List2, Pairs) :-
% For each object in List1, find matching color objects in List2.
    findall(O1-O2,
        (member(O1, List1),
         objmatch_color_(O1, C),
         member(O2, List2),
         objmatch_color_(O2, C)),
        Pairs).

% objmatch_by_size(+List1, +List2, -Pairs): match objects with the same cell count.
% Each Obj1 is paired with each Obj2 sharing the same size.
objmatch_by_size(List1, List2, Pairs) :-
% For each object in List1, find matching size objects in List2.
    findall(O1-O2,
        (member(O1, List1),
         objmatch_size_(O1, N),
         member(O2, List2),
         objmatch_size_(O2, N)),
        Pairs).

% objmatch_by_form(+List1, +List2, -Pairs): match objects with the same normalized shape.
% Two objects share a form iff their cells, translated to origin and sorted, are equal.
objmatch_by_form(List1, List2, Pairs) :-
% For each object in List1, find matching form objects in List2.
    findall(O1-O2,
        (member(O1, List1),
         objmatch_norm_(O1, Norm),
         member(O2, List2),
         objmatch_norm_(O2, Norm)),
        Pairs).

% objmatch_by_nearest(+List1, +List2, -Pairs): greedy nearest-centroid matching.
% Each Obj1 in List1 is greedily matched to its nearest remaining Obj2 in List2.
% If List2 runs out before List1, remaining Obj1 items are silently skipped.
objmatch_by_nearest(List1, List2, Pairs) :-
% Delegate to the greedy accumulator.
    objmatch_greedy_match_(List1, List2, Pairs).

% objmatch_unmatched(+Pairs, +List1, -Unmatched1, -Unmatched2):
% Obj1 items in List1 that do not appear as the first element of any pair.
% Obj2 items that do not appear as the second element of any pair.
% Note: List2 must be passed as the context; this predicate reconstructs it from Pairs + extras.
% Simpler API: takes the original List1 and List2 and returns leftovers.
objmatch_unmatched(Pairs, List1, List2, Unmatched1, Unmatched2) :-
% Collect all matched O1 and O2 from Pairs.
    findall(O1, member(O1-_, Pairs), Matched1),
    findall(O2, member(_-O2, Pairs), Matched2),
% Subtract matched from original lists.
    subtract(List1, Matched1, Unmatched1),
    subtract(List2, Matched2, Unmatched2).

% objmatch_filter_changed_color(+Pairs, -Changed): pairs where the two colors differ.
objmatch_filter_changed_color(Pairs, Changed) :-
% Keep only pairs where O1 color != O2 color.
    findall(O1-O2,
        (member(O1-O2, Pairs),
         objmatch_color_(O1, C1),
         objmatch_color_(O2, C2),
         C1 \= C2),
        Changed).

% objmatch_filter_same_color(+Pairs, -Same): pairs where the two colors are identical.
objmatch_filter_same_color(Pairs, Same) :-
% Keep only pairs where O1 color == O2 color.
    findall(O1-O2,
        (member(O1-O2, Pairs),
         objmatch_color_(O1, C),
         objmatch_color_(O2, C)),
        Same).

% objmatch_color_deltas(+Pairs, -Deltas): list of c1-c2 color pairs from matched pairs.
objmatch_color_deltas(Pairs, Deltas) :-
% Map each pair to its color delta.
    maplist(objmatch_color_delta_, Pairs, Deltas).

% objmatch_pos_deltas(+Pairs, -Deltas): list of dr(DR,DC) centroid deltas.
objmatch_pos_deltas(Pairs, Deltas) :-
% Map each pair to its positional delta.
    maplist(objmatch_pos_delta_, Pairs, Deltas).

% objmatch_size_deltas(+Pairs, -Deltas): list of N2-N1 size deltas.
objmatch_size_deltas(Pairs, Deltas) :-
% Map each pair to its size delta.
    maplist(objmatch_size_delta_, Pairs, Deltas).

% objmatch_all_same_color_delta(+Pairs): true iff all pairs share the same c1-c2 color change.
objmatch_all_same_color_delta([]).
objmatch_all_same_color_delta([First|Rest]) :-
% Extract the reference color delta from the first pair.
    objmatch_color_delta_(First, Ref),
% All remaining pairs must match.
    maplist(objmatch_color_delta_eq_(Ref), Rest).

% objmatch_color_delta_eq_(+Ref, +Pair): true iff Pair's color delta equals Ref.
objmatch_color_delta_eq_(Ref, Pair) :-
    objmatch_color_delta_(Pair, Ref).

% objmatch_all_same_pos_delta(+Pairs): true iff all pairs share the same dr(DR,DC) delta.
objmatch_all_same_pos_delta([]).
objmatch_all_same_pos_delta([First|Rest]) :-
% Extract the reference positional delta from the first pair.
    objmatch_pos_delta_(First, Ref),
% All remaining pairs must match.
    maplist(objmatch_pos_delta_eq_(Ref), Rest).

% objmatch_pos_delta_eq_(+Ref, +Pair): true iff Pair's pos delta equals Ref.
objmatch_pos_delta_eq_(Ref, Pair) :-
    objmatch_pos_delta_(Pair, Ref).

% objmatch_all_same_size_delta(+Pairs): true iff all pairs share the same N2-N1 size change.
objmatch_all_same_size_delta([]).
objmatch_all_same_size_delta([First|Rest]) :-
% Extract the reference size delta from the first pair.
    objmatch_size_delta_(First, Ref),
% All remaining pairs must match.
    maplist(objmatch_size_delta_eq_(Ref), Rest).

% objmatch_size_delta_eq_(+Ref, +Pair): true iff Pair's size delta equals Ref.
objmatch_size_delta_eq_(Ref, Pair) :-
    objmatch_size_delta_(Pair, Ref).

% objmatch_zip(+List1, +List2, -Pairs): index-wise pairing of two equal-length lists.
% objmatch_zip([A,B,C], [X,Y,Z], [A-X, B-Y, C-Z]).
objmatch_zip([], [], []).
objmatch_zip([H1|T1], [H2|T2], [H1-H2|Rest]) :-
% Pair heads and recurse on tails.
    objmatch_zip(T1, T2, Rest).
