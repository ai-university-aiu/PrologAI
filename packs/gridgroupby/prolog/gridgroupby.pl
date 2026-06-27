% Module declaration with all fourteen public predicates.
:- module(gridgroupby, [
% Group ob(Color,Cells,BBox) objects by shared color into grp(Key,List) terms.
    ggb_group_by_color/2,
% Group objects by shared cell count into grp(Key,List) terms.
    ggb_group_by_size/2,
% Group objects by shared top row (first row of bounding box) into grp(Key,List) terms.
    ggb_group_by_row/2,
% Group objects by shared left column (first col of bounding box) into grp(Key,List) terms.
    ggb_group_by_col/2,
% Filter objects to only those whose color equals Color.
    ggb_filter_by_color/3,
% Filter objects to only those whose cell count equals Size.
    ggb_filter_by_size/3,
% Filter objects to only those whose cell count is greater than N.
    ggb_filter_larger/3,
% Filter objects to only those whose cell count is less than N.
    ggb_filter_smaller/3,
% Sort objects by cell count, smallest first.
    ggb_sort_by_size_asc/2,
% Sort objects by cell count, largest first.
    ggb_sort_by_size_desc/2,
% Sort objects by top row of bounding box, smallest row first (scan order).
    ggb_sort_by_row/2,
% Sort objects by left column of bounding box, smallest column first.
    ggb_sort_by_col/2,
% Produce pair(Color, Obj1, Obj2) for each color that has exactly two objects.
    ggb_pair_by_color/2,
% Count objects per color; returns list of cnt(Color, N) in descending count order.
    ggb_count_per_color/2
]).
% gridgroupby.pl - Layer 243: Grid Group-By Operations (ggb_* prefix).
% Fourteen predicates for grouping, filtering, sorting, pairing, and counting
% ob(Color,Cells,BBox) object terms produced by gob_all_objects/3.
:- use_module(library(lists), [member/2, append/3]).

% --- PRIVATE HELPERS ---

% ggb_obj_size_/2: cell count of an ob/3 object.
ggb_obj_size_(ob(_,Cells,_), Size) :-
    length(Cells, Size).

% ggb_obj_row_/2: top row (R0) from the bounding box of an ob/3 object.
ggb_obj_row_(ob(_,_,r0(R0,_,_,_)), R0).

% ggb_obj_col_/2: left column (C0) from the bounding box of an ob/3 object.
ggb_obj_col_(ob(_,_,r0(_,C0,_,_)), C0).

% ggb_group_by_key_/3: group a list of ob/3 terms by a key extracted via Goal.
% Goal is called as call(Goal, Obj, Key).
% Returns a sorted list of grp(Key, ObjList) in ascending key order.
ggb_group_by_key_(Objects, Goal, Groups) :-
    findall(k(Key, Obj),
        ( member(Obj, Objects), call(Goal, Obj, Key) ),
        Keyed),
    msort(Keyed, Sorted),
    ggb_collect_groups_(Sorted, Groups).

% ggb_collect_groups_/2: convert sorted k(Key,Obj) list to grp(Key,List) list.
ggb_collect_groups_([], []).
ggb_collect_groups_([k(Key,Obj)|Rest], [grp(Key,ObjList)|Groups]) :-
    ggb_span_key_(Key, Rest, Same, Different),
    maplist(ggb_obj_of_k_, [k(Key,Obj)|Same], ObjList),
    ggb_collect_groups_(Different, Groups).

% ggb_span_key_/4: split a sorted k(Key,_) list at the first key change.
ggb_span_key_(_, [], [], []).
ggb_span_key_(Key, [k(K2,O)|Rest], [k(K2,O)|Same], Different) :-
    K2 == Key, !,
    ggb_span_key_(Key, Rest, Same, Different).
ggb_span_key_(_, Different, [], Different).

% ggb_obj_of_k_/2: extract the ob/3 term from a k(Key,Obj) term.
ggb_obj_of_k_(k(_,Obj), Obj).

% ggb_color_key_/2: extract color from ob/3.
ggb_color_key_(ob(Color,_,_), Color).

% ggb_sort_by_key_asc_/3: sort objects by numeric key extracted via Goal, ascending.
ggb_sort_by_key_asc_(Objects, Goal, Sorted) :-
    findall(k(Key, Obj),
        ( member(Obj, Objects), call(Goal, Obj, Key) ),
        Keyed),
    msort(Keyed, KeyedSorted),
    maplist(ggb_obj_of_k_, KeyedSorted, Sorted).

% ggb_sort_by_key_desc_/3: sort objects by numeric key, descending.
ggb_sort_by_key_desc_(Objects, Goal, Sorted) :-
    findall(neg(Neg, Obj),
        ( member(Obj, Objects), call(Goal, Obj, Key), Neg is -Key ),
        Keyed),
    msort(Keyed, KeyedSorted),
    findall(Obj, member(neg(_,Obj), KeyedSorted), Sorted).

% --- PUBLIC PREDICATES ---

% ggb_group_by_color(+Objects, -Groups)
% Groups objects by shared color. Each group is grp(Color, ObjList).
% Groups are in ascending color (term) order.
ggb_group_by_color(Objects, Groups) :-
    ggb_group_by_key_(Objects, ggb_color_key_, Groups).

% ggb_group_by_size(+Objects, -Groups)
% Groups objects by shared cell count. Each group is grp(Size, ObjList).
% Groups are in ascending size order.
ggb_group_by_size(Objects, Groups) :-
    ggb_group_by_key_(Objects, ggb_obj_size_, Groups).

% ggb_group_by_row(+Objects, -Groups)
% Groups objects by shared top row of their bounding box. Each group is grp(Row, ObjList).
% Groups are in ascending row order.
ggb_group_by_row(Objects, Groups) :-
    ggb_group_by_key_(Objects, ggb_obj_row_, Groups).

% ggb_group_by_col(+Objects, -Groups)
% Groups objects by shared left column of their bounding box. Each group is grp(Col, ObjList).
% Groups are in ascending column order.
ggb_group_by_col(Objects, Groups) :-
    ggb_group_by_key_(Objects, ggb_obj_col_, Groups).

% ggb_filter_by_color(+Objects, +Color, -Filtered)
% Filtered is the sub-list of Objects whose color equals Color.
ggb_filter_by_color(Objects, Color, Filtered) :-
    findall(Obj, ( member(Obj, Objects), Obj = ob(Color,_,_) ), Filtered).

% ggb_filter_by_size(+Objects, +Size, -Filtered)
% Filtered is the sub-list of Objects whose cell count equals Size.
ggb_filter_by_size(Objects, Size, Filtered) :-
    findall(Obj,
        ( member(Obj, Objects), ggb_obj_size_(Obj, Size) ),
        Filtered).

% ggb_filter_larger(+Objects, +N, -Filtered)
% Filtered is the sub-list of Objects whose cell count is strictly greater than N.
ggb_filter_larger(Objects, N, Filtered) :-
    findall(Obj,
        ( member(Obj, Objects), ggb_obj_size_(Obj, S), S > N ),
        Filtered).

% ggb_filter_smaller(+Objects, +N, -Filtered)
% Filtered is the sub-list of Objects whose cell count is strictly less than N.
ggb_filter_smaller(Objects, N, Filtered) :-
    findall(Obj,
        ( member(Obj, Objects), ggb_obj_size_(Obj, S), S < N ),
        Filtered).

% ggb_sort_by_size_asc(+Objects, -Sorted)
% Sorted is Objects ordered by cell count, smallest first.
ggb_sort_by_size_asc(Objects, Sorted) :-
    ggb_sort_by_key_asc_(Objects, ggb_obj_size_, Sorted).

% ggb_sort_by_size_desc(+Objects, -Sorted)
% Sorted is Objects ordered by cell count, largest first.
ggb_sort_by_size_desc(Objects, Sorted) :-
    ggb_sort_by_key_desc_(Objects, ggb_obj_size_, Sorted).

% ggb_sort_by_row(+Objects, -Sorted)
% Sorted is Objects ordered by the top row of their bounding box, smallest row first.
ggb_sort_by_row(Objects, Sorted) :-
    ggb_sort_by_key_asc_(Objects, ggb_obj_row_, Sorted).

% ggb_sort_by_col(+Objects, -Sorted)
% Sorted is Objects ordered by the left column of their bounding box, smallest col first.
ggb_sort_by_col(Objects, Sorted) :-
    ggb_sort_by_key_asc_(Objects, ggb_obj_col_, Sorted).

% ggb_pair_by_color(+Objects, -Pairs)
% Pairs is a list of pair(Color, Obj1, Obj2) for each color that has exactly two objects.
% Colors with fewer or more than two objects are omitted.
ggb_pair_by_color(Objects, Pairs) :-
    ggb_group_by_color(Objects, Groups),
    findall(pair(Color, Obj1, Obj2),
        ( member(grp(Color, [Obj1, Obj2]), Groups) ),
        Pairs).

% ggb_count_per_color(+Objects, -Counts)
% Counts is a list of cnt(Color, N) for each distinct color, sorted by N descending.
ggb_count_per_color(Objects, Counts) :-
    ggb_group_by_color(Objects, Groups),
    findall(neg(Neg, Color, N),
        ( member(grp(Color, ObjList), Groups),
          length(ObjList, N), Neg is -N ),
        Keyed),
    msort(Keyed, KeyedSorted),
    findall(cnt(Color, N), member(neg(_,Color,N), KeyedSorted), Counts).
