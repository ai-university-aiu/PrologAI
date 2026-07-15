% objgroup.pl - Layer 181: Object-List Grouping by Shared Attribute (og_* prefix).
% Partitions a list of obj(Color, Cells) terms into groups sharing a common property.
% Groups are Key-ObjList pairs where Key identifies the shared attribute and ObjList
% holds all objects with that attribute value.
% Complements objfilter (selects by predicate) and objattr (aggregates over all).
% No cross-pack dependencies.
:- module(objgroup, [
    % objgroup_by_color/2: partition into Color-ObjList groups, sorted by Color.
    objgroup_by_color/2,
    % objgroup_by_size/2: partition into Size-ObjList groups, sorted by Size ascending.
    objgroup_by_size/2,
    % objgroup_by_form/2: partition into Form-ObjList groups; Form = normalized cell list.
    objgroup_by_form/2,
    % objgroup_by_row/2: partition into Row-ObjList groups by top-left row, sorted ascending.
    objgroup_by_row/2,
    % objgroup_by_col/2: partition into Col-ObjList groups by top-left col, sorted ascending.
    objgroup_by_col/2,
    % objgroup_n_groups/2: count of groups in a group list.
    objgroup_n_groups/2,
    % objgroup_n_members/3: filter groups to those with exactly N members.
    objgroup_n_members/3,
    % objgroup_singletons/2: groups with exactly one member.
    objgroup_singletons/2,
    % objgroup_largest/2: the group with the most members (first if tied).
    objgroup_largest/2,
    % objgroup_smallest/2: the group with the fewest members (first if tied).
    objgroup_smallest/2,
    % objgroup_all_same_size/1: true iff every group has the same member count.
    objgroup_all_same_size/1,
    % objgroup_sort_desc/2: sort groups by member count descending.
    objgroup_sort_desc/2,
    % objgroup_flat/2: flatten groups back to a list of obj terms (preserving group order).
    objgroup_flat/2,
    % objgroup_filter_size/4: keep groups whose member count is between Min and Max inclusive.
    objgroup_filter_size/4
]).

% Load list utilities.
:- use_module(library(lists), [member/2, append/3]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% objgroup_color_(+Obj, -Color): extract color from obj term.
objgroup_color_(obj(Color, _), Color).

% objgroup_size_(+Obj, -N): cell count of obj.
objgroup_size_(obj(_, Cells), N) :-
    length(Cells, N).

% objgroup_topleft_(+Obj, -r(MinR,MinC)): top-left corner (min row, min col).
objgroup_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% objgroup_norm_(+Obj, -Sorted): normalize to origin; sort cells.
objgroup_norm_(obj(_, Cells), Sorted) :-
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

% objgroup_group_by_(+Objs, :KeyPred, -Groups): generic grouping.
% KeyPred is called as KeyPred(Obj, Key).
% Groups is a sorted list of Key-ObjList pairs.
objgroup_group_by_(Objs, KeyPred, Groups) :-
% Collect all Key-Obj pairs.
    findall(Key-Obj,
        (member(Obj, Objs), call(KeyPred, Obj, Key)),
        Pairs),
% Collect distinct keys in sorted order.
    findall(K, member(K-_, Pairs), Ks),
    sort(Ks, Keys),
% For each key, collect its objects in original order.
    findall(Key-Members,
        (member(Key, Keys),
         findall(O, member(Key-O, Pairs), Members)),
        Groups).
:- meta_predicate objgroup_group_by_(+, 2, -).

% objgroup_count_(+KeyObjList, -N): number of members in a Key-ObjList group.
objgroup_count_(_Key-Members, N) :-
    length(Members, N).

% --- Exported predicates -----------------------------------------------------

% objgroup_by_color(+Objs, -Groups): partition into Color-ObjList groups.
objgroup_by_color(Objs, Groups) :-
    objgroup_group_by_(Objs, objgroup_color_, Groups).

% objgroup_by_size(+Objs, -Groups): partition into Size-ObjList groups.
objgroup_by_size(Objs, Groups) :-
    objgroup_group_by_(Objs, objgroup_size_, Groups).

% objgroup_by_form(+Objs, -Groups): partition into Form-ObjList groups.
% Form is the normalized (origin-translated, sorted) cell list.
objgroup_by_form(Objs, Groups) :-
    objgroup_group_by_(Objs, objgroup_norm_, Groups).

% objgroup_by_row(+Objs, -Groups): partition by top-left row.
objgroup_by_row(Objs, Groups) :-
    objgroup_group_by_(Objs, objgroup_row_key_, Groups).

% objgroup_row_key_(+Obj, -Row): extract min row from obj.
objgroup_row_key_(Obj, Row) :-
    objgroup_topleft_(Obj, r(Row, _)).

% objgroup_by_col(+Objs, -Groups): partition by top-left col.
objgroup_by_col(Objs, Groups) :-
    objgroup_group_by_(Objs, objgroup_col_key_, Groups).

% objgroup_col_key_(+Obj, -Col): extract min col from obj.
objgroup_col_key_(Obj, Col) :-
    objgroup_topleft_(Obj, r(_, Col)).

% objgroup_n_groups(+Groups, -N): number of groups.
objgroup_n_groups(Groups, N) :-
    length(Groups, N).

% objgroup_n_members(+Groups, +N, -Selected): groups with exactly N members.
objgroup_n_members(Groups, N, Selected) :-
    findall(G,
        (member(G, Groups),
         objgroup_count_(G, N)),
        Selected).

% objgroup_singletons(+Groups, -Singletons): groups with exactly one member.
objgroup_singletons(Groups, Singletons) :-
    objgroup_n_members(Groups, 1, Singletons).

% objgroup_largest(+Groups, -Group): group with the most members.
objgroup_largest(Groups, Group) :-
    Groups \= [],
    findall(NegN-G, (member(G, Groups), objgroup_count_(G, N), NegN is -N), Keyed),
    msort(Keyed, [_-Group|_]).

% objgroup_smallest(+Groups, -Group): group with the fewest members.
objgroup_smallest(Groups, Group) :-
    Groups \= [],
    findall(N-G, (member(G, Groups), objgroup_count_(G, N)), Keyed),
    msort(Keyed, [_-Group|_]).

% objgroup_all_same_size(+Groups): all groups have the same member count.
objgroup_all_same_size([]).
objgroup_all_same_size([First|Rest]) :-
    objgroup_count_(First, N),
    maplist(objgroup_count_eq_(N), Rest).

% objgroup_count_eq_(+N, +Group): group has exactly N members.
objgroup_count_eq_(N, Group) :-
    objgroup_count_(Group, N).

% objgroup_sort_desc(+Groups, -Sorted): sort groups by member count descending.
objgroup_sort_desc(Groups, Sorted) :-
    findall(NegN-G, (member(G, Groups), objgroup_count_(G, N), NegN is -N), Keyed),
    msort(Keyed, SortedKeyed),
    findall(G, member(_-G, SortedKeyed), Sorted).

% objgroup_flat(+Groups, -Objs): flatten groups into a single obj list.
objgroup_flat(Groups, Objs) :-
    findall(O, (member(_-Members, Groups), member(O, Members)), Objs).

% objgroup_filter_size(+Groups, +Min, +Max, -Filtered): keep groups with Min..Max members.
objgroup_filter_size(Groups, Min, Max, Filtered) :-
    findall(G,
        (member(G, Groups),
         objgroup_count_(G, N),
         N >= Min,
         N =< Max),
        Filtered).
