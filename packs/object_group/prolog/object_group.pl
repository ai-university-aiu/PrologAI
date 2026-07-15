% objgroup.pl - Layer 181: Object-List Grouping by Shared Attribute (og_* prefix).
% Partitions a list of obj(Color, Cells) terms into groups sharing a common property.
% Groups are Key-ObjList pairs where Key identifies the shared attribute and ObjList
% holds all objects with that attribute value.
% Complements objfilter (selects by predicate) and objattr (aggregates over all).
% No cross-pack dependencies.
:- module(object_group, [
    % object_group_by_color/2: partition into Color-ObjList groups, sorted by Color.
    object_group_by_color/2,
    % object_group_by_size/2: partition into Size-ObjList groups, sorted by Size ascending.
    object_group_by_size/2,
    % object_group_by_form/2: partition into Form-ObjList groups; Form = normalized cell list.
    object_group_by_form/2,
    % object_group_by_row/2: partition into Row-ObjList groups by top-left row, sorted ascending.
    object_group_by_row/2,
    % object_group_by_col/2: partition into Col-ObjList groups by top-left col, sorted ascending.
    object_group_by_col/2,
    % object_group_n_groups/2: count of groups in a group list.
    object_group_n_groups/2,
    % object_group_n_members/3: filter groups to those with exactly N members.
    object_group_n_members/3,
    % object_group_singletons/2: groups with exactly one member.
    object_group_singletons/2,
    % object_group_largest/2: the group with the most members (first if tied).
    object_group_largest/2,
    % object_group_smallest/2: the group with the fewest members (first if tied).
    object_group_smallest/2,
    % object_group_all_same_size/1: true iff every group has the same member count.
    object_group_all_same_size/1,
    % object_group_sort_desc/2: sort groups by member count descending.
    object_group_sort_desc/2,
    % object_group_flat/2: flatten groups back to a list of obj terms (preserving group order).
    object_group_flat/2,
    % object_group_filter_size/4: keep groups whose member count is between Min and Max inclusive.
    object_group_filter_size/4
]).

% Load list utilities.
:- use_module(library(lists), [member/2, append/3]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% object_group_color_(+Obj, -Color): extract color from obj term.
object_group_color_(obj(Color, _), Color).

% object_group_size_(+Obj, -N): cell count of obj.
object_group_size_(obj(_, Cells), N) :-
    length(Cells, N).

% object_group_topleft_(+Obj, -r(MinR,MinC)): top-left corner (min row, min col).
object_group_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% object_group_norm_(+Obj, -Sorted): normalize to origin; sort cells.
object_group_norm_(obj(_, Cells), Sorted) :-
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

% object_group_group_by_(+Objs, :KeyPred, -Groups): generic grouping.
% KeyPred is called as KeyPred(Obj, Key).
% Groups is a sorted list of Key-ObjList pairs.
object_group_group_by_(Objs, KeyPred, Groups) :-
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
:- meta_predicate object_group_group_by_(+, 2, -).

% object_group_count_(+KeyObjList, -N): number of members in a Key-ObjList group.
object_group_count_(_Key-Members, N) :-
    length(Members, N).

% --- Exported predicates -----------------------------------------------------

% object_group_by_color(+Objs, -Groups): partition into Color-ObjList groups.
object_group_by_color(Objs, Groups) :-
    object_group_group_by_(Objs, object_group_color_, Groups).

% object_group_by_size(+Objs, -Groups): partition into Size-ObjList groups.
object_group_by_size(Objs, Groups) :-
    object_group_group_by_(Objs, object_group_size_, Groups).

% object_group_by_form(+Objs, -Groups): partition into Form-ObjList groups.
% Form is the normalized (origin-translated, sorted) cell list.
object_group_by_form(Objs, Groups) :-
    object_group_group_by_(Objs, object_group_norm_, Groups).

% object_group_by_row(+Objs, -Groups): partition by top-left row.
object_group_by_row(Objs, Groups) :-
    object_group_group_by_(Objs, object_group_row_key_, Groups).

% object_group_row_key_(+Obj, -Row): extract min row from obj.
object_group_row_key_(Obj, Row) :-
    object_group_topleft_(Obj, r(Row, _)).

% object_group_by_col(+Objs, -Groups): partition by top-left col.
object_group_by_col(Objs, Groups) :-
    object_group_group_by_(Objs, object_group_col_key_, Groups).

% object_group_col_key_(+Obj, -Col): extract min col from obj.
object_group_col_key_(Obj, Col) :-
    object_group_topleft_(Obj, r(_, Col)).

% object_group_n_groups(+Groups, -N): number of groups.
object_group_n_groups(Groups, N) :-
    length(Groups, N).

% object_group_n_members(+Groups, +N, -Selected): groups with exactly N members.
object_group_n_members(Groups, N, Selected) :-
    findall(G,
        (member(G, Groups),
         object_group_count_(G, N)),
        Selected).

% object_group_singletons(+Groups, -Singletons): groups with exactly one member.
object_group_singletons(Groups, Singletons) :-
    object_group_n_members(Groups, 1, Singletons).

% object_group_largest(+Groups, -Group): group with the most members.
object_group_largest(Groups, Group) :-
    Groups \= [],
    findall(NegN-G, (member(G, Groups), object_group_count_(G, N), NegN is -N), Keyed),
    msort(Keyed, [_-Group|_]).

% object_group_smallest(+Groups, -Group): group with the fewest members.
object_group_smallest(Groups, Group) :-
    Groups \= [],
    findall(N-G, (member(G, Groups), object_group_count_(G, N)), Keyed),
    msort(Keyed, [_-Group|_]).

% object_group_all_same_size(+Groups): all groups have the same member count.
object_group_all_same_size([]).
object_group_all_same_size([First|Rest]) :-
    object_group_count_(First, N),
    maplist(object_group_count_eq_(N), Rest).

% object_group_count_eq_(+N, +Group): group has exactly N members.
object_group_count_eq_(N, Group) :-
    object_group_count_(Group, N).

% object_group_sort_desc(+Groups, -Sorted): sort groups by member count descending.
object_group_sort_desc(Groups, Sorted) :-
    findall(NegN-G, (member(G, Groups), object_group_count_(G, N), NegN is -N), Keyed),
    msort(Keyed, SortedKeyed),
    findall(G, member(_-G, SortedKeyed), Sorted).

% object_group_flat(+Groups, -Objs): flatten groups into a single obj list.
object_group_flat(Groups, Objs) :-
    findall(O, (member(_-Members, Groups), member(O, Members)), Objs).

% object_group_filter_size(+Groups, +Min, +Max, -Filtered): keep groups with Min..Max members.
object_group_filter_size(Groups, Min, Max, Filtered) :-
    findall(G,
        (member(G, Groups),
         object_group_count_(G, N),
         N >= Min,
         N =< Max),
        Filtered).
