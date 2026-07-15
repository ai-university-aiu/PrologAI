% arrange.pl - Layer 150: Object Arrangement and Spatial Ordering (ag_* prefix).
% Operates on obj(Color, Cells) terms produced by the scene pack.
% Provides centroid computation, pairwise spatial order, stable sort by position,
% gap analysis between object centroids, group bounding boxes, and nearest-neighbor
% lookup. All predicates accept obj(Color, Cells) terms with r(R,C) cell lists.
:- module(arrange, [
    % arrange_centroid/2: integer (floor-average) centroid of an obj term.
    arrange_centroid/2,
    % arrange_offset/3: row-column displacement vector from Obj1 centroid to Obj2 centroid.
    arrange_offset/3,
    % arrange_row_order/2: Obj1 centroid row is at most Obj2 centroid row (top-to-bottom).
    arrange_row_order/2,
    % arrange_col_order/2: Obj1 centroid column is at most Obj2 centroid column (left-to-right).
    arrange_col_order/2,
    % arrange_row_aligned/2: Obj1 and Obj2 share the same centroid row.
    arrange_row_aligned/2,
    % arrange_col_aligned/2: Obj1 and Obj2 share the same centroid column.
    arrange_col_aligned/2,
    % arrange_sort_by_row/2: sort an obj list by centroid row, top to bottom (stable keysort).
    arrange_sort_by_row/2,
    % arrange_sort_by_col/2: sort an obj list by centroid column, left to right (stable keysort).
    arrange_sort_by_col/2,
    % arrange_row_gaps/2: consecutive gaps between sorted distinct centroid rows.
    arrange_row_gaps/2,
    % arrange_col_gaps/2: consecutive gaps between sorted distinct centroid columns.
    arrange_col_gaps/2,
    % arrange_equal_row_gaps/1: all consecutive centroid row gaps are equal (at least 2 distinct rows).
    arrange_equal_row_gaps/1,
    % arrange_equal_col_gaps/1: all consecutive centroid column gaps are equal (at least 2 distinct cols).
    arrange_equal_col_gaps/1,
    % arrange_group_bbox/5: bounding box enclosing every cell of every obj in the list.
    arrange_group_bbox/5,
    % arrange_nearest/3: obj in a list whose centroid is closest (Manhattan) to a reference obj.
    arrange_nearest/3
]).

% Import list utilities; length/2, sort/2, keysort/2, findall/3 are built-ins.
:- use_module(library(lists), [member/2, min_list/2, max_list/2, sum_list/2]).

% arrange_centroid(+Obj, -r(CR,CC)): floor-average row and column of an obj cell list.
arrange_centroid(obj(_, Cells), r(CR, CC)) :-
% Collect all row indices from the cell list.
    findall(R, member(r(R,_), Cells), Rs),
% Collect all column indices from the cell list.
    findall(C, member(r(_,C), Cells), Cs),
% Number of cells determines the denominator.
    length(Rs, N),
% Sum of row indices.
    sum_list(Rs, SR),
% Sum of column indices.
    sum_list(Cs, SC),
% Integer centroid: floor division keeps result within the bounding box.
    CR is SR // N,
    CC is SC // N.

% arrange_offset(+Obj1, +Obj2, -r(DR,DC)): centroid of Obj2 minus centroid of Obj1.
arrange_offset(Obj1, Obj2, r(DR, DC)) :-
% Centroid of the reference object.
    arrange_centroid(Obj1, r(R1, C1)),
% Centroid of the target object.
    arrange_centroid(Obj2, r(R2, C2)),
% Row and column displacement.
    DR is R2 - R1,
    DC is C2 - C1.

% arrange_row_order(+Obj1, +Obj2): Obj1 centroid row is at most Obj2 centroid row.
arrange_row_order(Obj1, Obj2) :-
% Centroid rows of both objects.
    arrange_centroid(Obj1, r(R1, _)),
    arrange_centroid(Obj2, r(R2, _)),
% Obj1 is at or above Obj2.
    R1 =< R2.

% arrange_col_order(+Obj1, +Obj2): Obj1 centroid column is at most Obj2 centroid column.
arrange_col_order(Obj1, Obj2) :-
% Centroid columns of both objects.
    arrange_centroid(Obj1, r(_, C1)),
    arrange_centroid(Obj2, r(_, C2)),
% Obj1 is at or left of Obj2.
    C1 =< C2.

% arrange_row_aligned(+Obj1, +Obj2): both objects share the same centroid row.
arrange_row_aligned(Obj1, Obj2) :-
% Unifying R forces both centroids to the same row.
    arrange_centroid(Obj1, r(R, _)),
    arrange_centroid(Obj2, r(R, _)).

% arrange_col_aligned(+Obj1, +Obj2): both objects share the same centroid column.
arrange_col_aligned(Obj1, Obj2) :-
% Unifying C forces both centroids to the same column.
    arrange_centroid(Obj1, r(_, C)),
    arrange_centroid(Obj2, r(_, C)).

% arrange_sort_by_row(+Objs, -Sorted): stable sort of obj list by centroid row (top to bottom).
arrange_sort_by_row(Objs, Sorted) :-
% Pair each obj with its centroid row as the sort key.
    findall(R-O, (member(O, Objs), arrange_centroid(O, r(R,_))), Pairs),
% keysort is stable: equal-row objects preserve their original relative order.
    keysort(Pairs, SortedPairs),
% Strip the sort keys to produce the sorted obj list.
    findall(O, member(_-O, SortedPairs), Sorted).

% arrange_sort_by_col(+Objs, -Sorted): stable sort of obj list by centroid column (left to right).
arrange_sort_by_col(Objs, Sorted) :-
% Pair each obj with its centroid column as the sort key.
    findall(C-O, (member(O, Objs), arrange_centroid(O, r(_,C))), Pairs),
% keysort is stable: equal-column objects preserve their original relative order.
    keysort(Pairs, SortedPairs),
% Strip the sort keys.
    findall(O, member(_-O, SortedPairs), Sorted).

% arrange_consec_gaps_(+SortedList, -Gaps): consecutive differences of a sorted integer list.
arrange_consec_gaps_([], []).
arrange_consec_gaps_([_], []) :- !.
arrange_consec_gaps_([A,B|T], [G|Gs]) :-
% Gap between the current pair of adjacent values.
    G is B - A,
% Recurse with B as the new head.
    arrange_consec_gaps_([B|T], Gs).

% arrange_row_gaps(+Objs, -Gaps): consecutive gaps between sorted distinct centroid rows.
arrange_row_gaps(Objs, Gaps) :-
% Collect all centroid row values.
    findall(R, (member(O, Objs), arrange_centroid(O, r(R,_))), Rs0),
% sort/2 removes duplicates and sorts ascending.
    sort(Rs0, Rs),
% Compute consecutive differences.
    arrange_consec_gaps_(Rs, Gaps).

% arrange_col_gaps(+Objs, -Gaps): consecutive gaps between sorted distinct centroid columns.
arrange_col_gaps(Objs, Gaps) :-
% Collect all centroid column values.
    findall(C, (member(O, Objs), arrange_centroid(O, r(_,C))), Cs0),
% sort/2 removes duplicates and sorts ascending.
    sort(Cs0, Cs),
% Compute consecutive differences.
    arrange_consec_gaps_(Cs, Gaps).

% arrange_all_equal_(+List): all elements of a non-empty list are the same value.
arrange_all_equal_([_]) :- !.
arrange_all_equal_([X,X|T]) :-
% The first two elements match; recurse on the tail starting at the second.
    arrange_all_equal_([X|T]).

% arrange_equal_row_gaps(+Objs): all consecutive centroid row gaps are equal.
arrange_equal_row_gaps(Objs) :-
% Compute the row gap list.
    arrange_row_gaps(Objs, Gaps),
% There must be at least one gap (at least 2 objects with distinct centroid rows).
    Gaps = [_|_],
% All gaps are the same value.
    arrange_all_equal_(Gaps).

% arrange_equal_col_gaps(+Objs): all consecutive centroid column gaps are equal.
arrange_equal_col_gaps(Objs) :-
% Compute the column gap list.
    arrange_col_gaps(Objs, Gaps),
% There must be at least one gap (at least 2 objects with distinct centroid cols).
    Gaps = [_|_],
% All gaps are the same value.
    arrange_all_equal_(Gaps).

% arrange_group_bbox(+Objs, -R0, -C0, -R1, -C1): bounding box of all cells of all objs.
arrange_group_bbox(Objs, R0, C0, R1, C1) :-
% Collect every row index from every cell of every obj.
    findall(R, (member(obj(_,Cells), Objs), member(r(R,_), Cells)), Rs),
% Collect every column index.
    findall(C, (member(obj(_,Cells), Objs), member(r(_,C), Cells)), Cs),
% Bounding box top-left corner.
    min_list(Rs, R0),
    min_list(Cs, C0),
% Bounding box bottom-right corner.
    max_list(Rs, R1),
    max_list(Cs, C1).

% arrange_nearest(+RefObj, +Objs, -Nearest): obj in Objs with minimum Manhattan centroid distance to RefObj.
arrange_nearest(RefObj, Objs, Nearest) :-
% Reference centroid.
    arrange_centroid(RefObj, r(RR, RC)),
% Compute Manhattan distance from the reference centroid to each candidate centroid.
    findall(D-O, (
        member(O, Objs),
        arrange_centroid(O, r(OR, OC)),
        D is abs(OR - RR) + abs(OC - RC)
    ), Pairs),
% keysort puts the smallest distance first; take that obj as the nearest.
    keysort(Pairs, [_-Nearest|_]).
