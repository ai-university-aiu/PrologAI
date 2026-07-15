% order.pl - Layer 90: Object Spatial Ordering and Ranking (od_* prefix).
% Operates on obj(Color, Cells) terms where Cells is a list of r(R,C) cells.
:- module(order, [
    order_centroid/3,
    order_sort_row/2,
    order_sort_col/2,
    order_reading_order/2,
    order_sort_color/2,
    order_topmost/2,
    order_bottommost/2,
    order_leftmost/2,
    order_rightmost/2,
    order_nth_row/3,
    order_nth_col/3,
    order_nearest/4,
    order_farthest/4,
    order_rank_row/3
]).
% Import list utilities; length/2, keysort/2 are built-ins, not imported.
:- use_module(library(lists), [member/2, nth0/3, last/2]).
% Import higher-order utilities for maplist.
:- use_module(library(apply), [maplist/3, foldl/4]).

% order_sum_rc_: accumulate row and column sums for foldl in order_centroid.
order_sum_rc_(r(R, C), SR0-SC0, SR1-SC1) :-
% Add R to the running row sum and C to the running column sum.
    SR1 is SR0 + R, SC1 is SC0 + C.

% order_strip_: remove sort keys from Key-Value pairs.
order_strip_([], []).
order_strip_([_-V|T], [V|Vs]) :-
% Discard the key; keep the value.
    order_strip_(T, Vs).

% order_strip2_: remove compound sort keys from (K1-K2)-Value pairs.
order_strip2_([], []).
order_strip2_([(_-_)-V|T], [V|Vs]) :-
% Discard both key fields; keep the value.
    order_strip2_(T, Vs).

% order_rank_find_: find 1-based rank of Target in a sorted list.
order_rank_find_([H|_], H, N, N) :- !.
order_rank_find_([_|T], Target, N0, Rank) :-
% Increment and recurse on the rest.
    N1 is N0 + 1, order_rank_find_(T, Target, N1, Rank).

% order_centroid(+Obj, -CR, -CC): integer floor centroid of an obj(Color, Cells) term.
% CR = floor(mean of all row indices). CC = floor(mean of all column indices).
% Fails if Cells is empty.
order_centroid(obj(_, Cells), CR, CC) :-
% Require at least one cell.
    Cells = [_|_],
% Count cells.
    length(Cells, N),
% Sum all row and column indices.
    foldl(order_sum_rc_, Cells, 0-0, SR-SC),
% Integer division gives the floor mean.
    CR is SR // N, CC is SC // N.

% order_sort_row(+Objs, -Sorted): sort objects by centroid row ascending (topmost first).
order_sort_row(Objs, Sorted) :-
% Key each object by its centroid row.
    maplist([Obj, CR-Obj]>>(order_centroid(Obj, CR, _)), Objs, Keyed),
% Sort by key ascending (keysort is stable).
    keysort(Keyed, SortedKeyed),
% Strip keys to get the sorted object list.
    order_strip_(SortedKeyed, Sorted).

% order_sort_col(+Objs, -Sorted): sort objects by centroid column ascending (leftmost first).
order_sort_col(Objs, Sorted) :-
% Key each object by its centroid column.
    maplist([Obj, CC-Obj]>>(order_centroid(Obj, _, CC)), Objs, Keyed),
% Sort by key ascending.
    keysort(Keyed, SortedKeyed),
% Strip keys.
    order_strip_(SortedKeyed, Sorted).

% order_reading_order(+Objs, -Sorted): sort by centroid row first, then column (reading order).
order_reading_order(Objs, Sorted) :-
% Key each object by (Row-Col) compound key; keysort orders by row then col.
    maplist([Obj, (CR-CC)-Obj]>>(order_centroid(Obj, CR, CC)), Objs, Keyed),
% Sort by compound key.
    keysort(Keyed, SortedKeyed),
% Strip the compound keys.
    order_strip2_(SortedKeyed, Sorted).

% order_sort_color(+Objs, -Sorted): sort objects by color value ascending.
order_sort_color(Objs, Sorted) :-
% Key each object by its color.
    maplist([obj(C, Cells), C-obj(C, Cells)]>>true, Objs, Keyed),
% Sort by color key.
    keysort(Keyed, SortedKeyed),
% Strip keys.
    order_strip_(SortedKeyed, Sorted).

% order_topmost(+Objs, -TopObj): object whose centroid row is smallest (nearest top).
% Fails if Objs is empty.
order_topmost(Objs, TopObj) :-
% Require at least one object.
    Objs = [_|_],
% Sort by centroid row; the first element is the topmost.
    order_sort_row(Objs, [TopObj|_]).

% order_bottommost(+Objs, -BotObj): object whose centroid row is largest (nearest bottom).
% Fails if Objs is empty.
order_bottommost(Objs, BotObj) :-
% Require at least one object.
    Objs = [_|_],
% Sort by centroid row; the last element is the bottommost.
    order_sort_row(Objs, Sorted),
    last(Sorted, BotObj).

% order_leftmost(+Objs, -LeftObj): object whose centroid column is smallest (nearest left).
% Fails if Objs is empty.
order_leftmost(Objs, LeftObj) :-
% Require at least one object.
    Objs = [_|_],
% Sort by centroid column; the first element is leftmost.
    order_sort_col(Objs, [LeftObj|_]).

% order_rightmost(+Objs, -RightObj): object whose centroid column is largest (nearest right).
% Fails if Objs is empty.
order_rightmost(Objs, RightObj) :-
% Require at least one object.
    Objs = [_|_],
% Sort by centroid column; the last element is rightmost.
    order_sort_col(Objs, Sorted),
    last(Sorted, RightObj).

% order_nth_row(+Objs, +N, -Obj): Nth object in row-ascending order. N is 1-indexed.
% Fails if N is out of range or Objs is empty.
order_nth_row(Objs, N, Obj) :-
% Sort by row.
    order_sort_row(Objs, Sorted),
% Convert to 0-indexed.
    Idx is N - 1,
% Retrieve the element at that index.
    nth0(Idx, Sorted, Obj).

% order_nth_col(+Objs, +N, -Obj): Nth object in column-ascending order. N is 1-indexed.
% Fails if N is out of range or Objs is empty.
order_nth_col(Objs, N, Obj) :-
% Sort by column.
    order_sort_col(Objs, Sorted),
% Convert to 0-indexed.
    Idx is N - 1,
% Retrieve the element at that index.
    nth0(Idx, Sorted, Obj).

% order_nearest(+Objs, +R, +C, -NearObj): object whose centroid has smallest Manhattan distance to (R,C).
% Fails if Objs is empty.
order_nearest(Objs, R, C, NearObj) :-
% Require at least one object.
    Objs = [_|_],
% Key each object by its Manhattan distance to (R,C).
    maplist([Obj, Dist-Obj]>>(
        order_centroid(Obj, CR, CC),
        Dist is abs(CR - R) + abs(CC - C)
    ), Objs, Keyed),
% Sort by distance; smallest is first.
    keysort(Keyed, [_-NearObj|_]).

% order_farthest(+Objs, +R, +C, -FarObj): object whose centroid has largest Manhattan distance to (R,C).
% Fails if Objs is empty.
order_farthest(Objs, R, C, FarObj) :-
% Require at least one object.
    Objs = [_|_],
% Key each object by its Manhattan distance to (R,C).
    maplist([Obj, Dist-Obj]>>(
        order_centroid(Obj, CR, CC),
        Dist is abs(CR - R) + abs(CC - C)
    ), Objs, Keyed),
% Sort by distance; largest is last.
    keysort(Keyed, Sorted),
    last(Sorted, _-FarObj).

% order_rank_row(+Objs, +TargetObj, -Rank): 1-based rank of TargetObj in row-ascending order.
% Rank = 1 means TargetObj is the topmost object. Fails if TargetObj is not in Objs.
order_rank_row(Objs, TargetObj, Rank) :-
% Sort all objects by row.
    order_sort_row(Objs, Sorted),
% Find the 1-based position of TargetObj in the sorted list.
    order_rank_find_(Sorted, TargetObj, 1, Rank).
