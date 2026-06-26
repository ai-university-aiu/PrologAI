% objmatch.pl - Layer 178: Object-List Correspondence and Matching (mx_* prefix).
% Finds correspondences between two obj(Color, Cells) term lists.
% Supports matching by color, size, form, and position; extracting unmatched
% objects; filtering pairs by change type; computing per-pair deltas; and
% testing whether all pairs share the same delta. Also provides positional zip.
% No cross-pack dependencies.
:- module(objmatch, [
    % mx_by_color/3: match objects with the same color; returns o1-o2 pairs.
    mx_by_color/3,
    % mx_by_size/3: match objects with the same cell count; returns o1-o2 pairs.
    mx_by_size/3,
    % mx_by_form/3: match objects with the same normalized shape; returns o1-o2 pairs.
    mx_by_form/3,
    % mx_by_nearest/3: greedy nearest-centroid matching; returns o1-o2 pairs.
    mx_by_nearest/3,
    % mx_unmatched/5: objects from each list that do not appear in Pairs.
    mx_unmatched/5,
    % mx_filter_changed_color/2: keep only pairs where the two colors differ.
    mx_filter_changed_color/2,
    % mx_filter_same_color/2: keep only pairs where the two colors are identical.
    mx_filter_same_color/2,
    % mx_color_deltas/2: list of c1-c2 atoms from each matched pair.
    mx_color_deltas/2,
    % mx_pos_deltas/2: list of dr(DR,DC) terms from each matched pair.
    mx_pos_deltas/2,
    % mx_size_deltas/2: list of integer N2-N1 values from each matched pair.
    mx_size_deltas/2,
    % mx_all_same_color_delta/1: true iff all pairs have the same c1-c2 color change.
    mx_all_same_color_delta/1,
    % mx_all_same_pos_delta/1: true iff all pairs have the same dr(DR,DC) delta.
    mx_all_same_pos_delta/1,
    % mx_all_same_size_delta/1: true iff all pairs have the same N2-N1 size change.
    mx_all_same_size_delta/1,
    % mx_zip/3: positional zip — pair List1[I] with List2[I] (lists must be equal length).
    mx_zip/3
]).

% Load list utilities.
:- use_module(library(lists), [member/2, subtract/3, nth0/3]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% mx_color_(+Obj, -Color): extract the color field from an obj term.
mx_color_(obj(Color, _), Color).

% mx_size_(+Obj, -N): extract cell count from an obj term.
mx_size_(obj(_, Cells), N) :-
% Count cells directly.
    length(Cells, N).

% mx_norm_(+Obj, -Sorted): normalize obj to origin and sort cells.
mx_norm_(obj(_, Cells), Sorted) :-
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

% mx_centroid_(+Obj, -r(CR,CC)): floor-average centroid.
mx_centroid_(obj(_, Cells), r(CR, CC)) :-
% Collect row and col values.
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    length(Rs, N),
    sum_list(Rs, SR),
    sum_list(Cs, SC),
% Integer floor division for centroid.
    CR is SR // N,
    CC is SC // N.

% mx_sq_dist_(+r(R1,C1), +r(R2,C2), -D2): squared Euclidean distance.
mx_sq_dist_(r(R1,C1), r(R2,C2), D2) :-
    DR is R2 - R1,
    DC is C2 - C1,
    D2 is DR*DR + DC*DC.

% mx_nearest_in_(+Centroids2, +Objs2, +Centroid1, -Obj2): find closest Obj2.
% Centroids2 is parallel to Objs2. Returns first minimum-distance match.
mx_nearest_in_(Centroids2, Objs2, Centroid1, Obj2) :-
% Compute squared distances from Centroid1 to each Centroid2.
    findall(D2-O2,
        (nth0(I, Centroids2, C2),
         nth0(I, Objs2, O2),
         mx_sq_dist_(Centroid1, C2, D2)),
        Pairs),
% Sort by distance ascending.
    msort(Pairs, [_-Obj2|_]).

% mx_greedy_match_(+Objs1, +Objs2, -Pairs): greedy nearest-centroid matching.
% Processes Objs1 in order; each obj in Objs1 claims the nearest remaining Objs2.
mx_greedy_match_([], _, []).
mx_greedy_match_([O1|Rest1], Objs2, [O1-O2|Pairs]) :-
    Objs2 \= [],
    mx_centroid_(O1, C1),
    maplist(mx_centroid_, Objs2, Cs2),
    mx_nearest_in_(Cs2, Objs2, C1, O2),
    subtract(Objs2, [O2], Remaining),
    mx_greedy_match_(Rest1, Remaining, Pairs).
mx_greedy_match_([_|Rest1], [], Pairs) :-
    mx_greedy_match_(Rest1, [], Pairs).

% mx_color_delta_(+O1-O2, -c1-c2): extract color pair from a match pair.
mx_color_delta_(O1-O2, C1-C2) :-
    mx_color_(O1, C1),
    mx_color_(O2, C2).

% mx_pos_delta_(+O1-O2, -dr(DR,DC)): centroid delta from a match pair.
mx_pos_delta_(O1-O2, dr(DR, DC)) :-
    mx_centroid_(O1, r(R1,C1)),
    mx_centroid_(O2, r(R2,C2)),
    DR is R2 - R1,
    DC is C2 - C1.

% mx_size_delta_(+O1-O2, -Delta): size delta (N2-N1) from a match pair.
mx_size_delta_(O1-O2, Delta) :-
    mx_size_(O1, N1),
    mx_size_(O2, N2),
    Delta is N2 - N1.

% --- Exported predicates -----------------------------------------------------

% mx_by_color(+List1, +List2, -Pairs): match objects with the same color.
% Each Obj1 in List1 is paired with the first Obj2 in List2 that has the same color.
% Result is a list of O1-O2 pairs (may have duplicates if colors repeat).
mx_by_color(List1, List2, Pairs) :-
% For each object in List1, find matching color objects in List2.
    findall(O1-O2,
        (member(O1, List1),
         mx_color_(O1, C),
         member(O2, List2),
         mx_color_(O2, C)),
        Pairs).

% mx_by_size(+List1, +List2, -Pairs): match objects with the same cell count.
% Each Obj1 is paired with each Obj2 sharing the same size.
mx_by_size(List1, List2, Pairs) :-
% For each object in List1, find matching size objects in List2.
    findall(O1-O2,
        (member(O1, List1),
         mx_size_(O1, N),
         member(O2, List2),
         mx_size_(O2, N)),
        Pairs).

% mx_by_form(+List1, +List2, -Pairs): match objects with the same normalized shape.
% Two objects share a form iff their cells, translated to origin and sorted, are equal.
mx_by_form(List1, List2, Pairs) :-
% For each object in List1, find matching form objects in List2.
    findall(O1-O2,
        (member(O1, List1),
         mx_norm_(O1, Norm),
         member(O2, List2),
         mx_norm_(O2, Norm)),
        Pairs).

% mx_by_nearest(+List1, +List2, -Pairs): greedy nearest-centroid matching.
% Each Obj1 in List1 is greedily matched to its nearest remaining Obj2 in List2.
% If List2 runs out before List1, remaining Obj1 items are silently skipped.
mx_by_nearest(List1, List2, Pairs) :-
% Delegate to the greedy accumulator.
    mx_greedy_match_(List1, List2, Pairs).

% mx_unmatched(+Pairs, +List1, -Unmatched1, -Unmatched2):
% Obj1 items in List1 that do not appear as the first element of any pair.
% Obj2 items that do not appear as the second element of any pair.
% Note: List2 must be passed as the context; this predicate reconstructs it from Pairs + extras.
% Simpler API: takes the original List1 and List2 and returns leftovers.
mx_unmatched(Pairs, List1, List2, Unmatched1, Unmatched2) :-
% Collect all matched O1 and O2 from Pairs.
    findall(O1, member(O1-_, Pairs), Matched1),
    findall(O2, member(_-O2, Pairs), Matched2),
% Subtract matched from original lists.
    subtract(List1, Matched1, Unmatched1),
    subtract(List2, Matched2, Unmatched2).

% mx_filter_changed_color(+Pairs, -Changed): pairs where the two colors differ.
mx_filter_changed_color(Pairs, Changed) :-
% Keep only pairs where O1 color != O2 color.
    findall(O1-O2,
        (member(O1-O2, Pairs),
         mx_color_(O1, C1),
         mx_color_(O2, C2),
         C1 \= C2),
        Changed).

% mx_filter_same_color(+Pairs, -Same): pairs where the two colors are identical.
mx_filter_same_color(Pairs, Same) :-
% Keep only pairs where O1 color == O2 color.
    findall(O1-O2,
        (member(O1-O2, Pairs),
         mx_color_(O1, C),
         mx_color_(O2, C)),
        Same).

% mx_color_deltas(+Pairs, -Deltas): list of c1-c2 color pairs from matched pairs.
mx_color_deltas(Pairs, Deltas) :-
% Map each pair to its color delta.
    maplist(mx_color_delta_, Pairs, Deltas).

% mx_pos_deltas(+Pairs, -Deltas): list of dr(DR,DC) centroid deltas.
mx_pos_deltas(Pairs, Deltas) :-
% Map each pair to its positional delta.
    maplist(mx_pos_delta_, Pairs, Deltas).

% mx_size_deltas(+Pairs, -Deltas): list of N2-N1 size deltas.
mx_size_deltas(Pairs, Deltas) :-
% Map each pair to its size delta.
    maplist(mx_size_delta_, Pairs, Deltas).

% mx_all_same_color_delta(+Pairs): true iff all pairs share the same c1-c2 color change.
mx_all_same_color_delta([]).
mx_all_same_color_delta([First|Rest]) :-
% Extract the reference color delta from the first pair.
    mx_color_delta_(First, Ref),
% All remaining pairs must match.
    maplist(mx_color_delta_eq_(Ref), Rest).

% mx_color_delta_eq_(+Ref, +Pair): true iff Pair's color delta equals Ref.
mx_color_delta_eq_(Ref, Pair) :-
    mx_color_delta_(Pair, Ref).

% mx_all_same_pos_delta(+Pairs): true iff all pairs share the same dr(DR,DC) delta.
mx_all_same_pos_delta([]).
mx_all_same_pos_delta([First|Rest]) :-
% Extract the reference positional delta from the first pair.
    mx_pos_delta_(First, Ref),
% All remaining pairs must match.
    maplist(mx_pos_delta_eq_(Ref), Rest).

% mx_pos_delta_eq_(+Ref, +Pair): true iff Pair's pos delta equals Ref.
mx_pos_delta_eq_(Ref, Pair) :-
    mx_pos_delta_(Pair, Ref).

% mx_all_same_size_delta(+Pairs): true iff all pairs share the same N2-N1 size change.
mx_all_same_size_delta([]).
mx_all_same_size_delta([First|Rest]) :-
% Extract the reference size delta from the first pair.
    mx_size_delta_(First, Ref),
% All remaining pairs must match.
    maplist(mx_size_delta_eq_(Ref), Rest).

% mx_size_delta_eq_(+Ref, +Pair): true iff Pair's size delta equals Ref.
mx_size_delta_eq_(Ref, Pair) :-
    mx_size_delta_(Pair, Ref).

% mx_zip(+List1, +List2, -Pairs): index-wise pairing of two equal-length lists.
% mx_zip([A,B,C], [X,Y,Z], [A-X, B-Y, C-Z]).
mx_zip([], [], []).
mx_zip([H1|T1], [H2|T2], [H1-H2|Rest]) :-
% Pair heads and recurse on tails.
    mx_zip(T1, T2, Rest).
