% objgroup.pl - Layer 181: Object-List Grouping by Shared Attribute (og_* prefix).
% Partitions a list of obj(Color, Cells) terms into groups sharing a common property.
% Groups are Key-ObjList pairs where Key identifies the shared attribute and ObjList
% holds all objects with that attribute value.
% Complements objfilter (selects by predicate) and objattr (aggregates over all).
% No cross-pack dependencies.
:- module(objgroup, [
    % og_by_color/2: partition into Color-ObjList groups, sorted by Color.
    og_by_color/2,
    % og_by_size/2: partition into Size-ObjList groups, sorted by Size ascending.
    og_by_size/2,
    % og_by_form/2: partition into Form-ObjList groups; Form = normalized cell list.
    og_by_form/2,
    % og_by_row/2: partition into Row-ObjList groups by top-left row, sorted ascending.
    og_by_row/2,
    % og_by_col/2: partition into Col-ObjList groups by top-left col, sorted ascending.
    og_by_col/2,
    % og_n_groups/2: count of groups in a group list.
    og_n_groups/2,
    % og_n_members/3: filter groups to those with exactly N members.
    og_n_members/3,
    % og_singletons/2: groups with exactly one member.
    og_singletons/2,
    % og_largest/2: the group with the most members (first if tied).
    og_largest/2,
    % og_smallest/2: the group with the fewest members (first if tied).
    og_smallest/2,
    % og_all_same_size/1: true iff every group has the same member count.
    og_all_same_size/1,
    % og_sort_desc/2: sort groups by member count descending.
    og_sort_desc/2,
    % og_flat/2: flatten groups back to a list of obj terms (preserving group order).
    og_flat/2,
    % og_filter_size/4: keep groups whose member count is between Min and Max inclusive.
    og_filter_size/4
]).

% Load list utilities.
:- use_module(library(lists), [member/2, append/3]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% og_color_(+Obj, -Color): extract color from obj term.
og_color_(obj(Color, _), Color).

% og_size_(+Obj, -N): cell count of obj.
og_size_(obj(_, Cells), N) :-
    length(Cells, N).

% og_topleft_(+Obj, -r(MinR,MinC)): top-left corner (min row, min col).
og_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% og_norm_(+Obj, -Sorted): normalize to origin; sort cells.
og_norm_(obj(_, Cells), Sorted) :-
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

% og_group_by_(+Objs, :KeyPred, -Groups): generic grouping.
% KeyPred is called as KeyPred(Obj, Key).
% Groups is a sorted list of Key-ObjList pairs.
og_group_by_(Objs, KeyPred, Groups) :-
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
:- meta_predicate og_group_by_(+, 2, -).

% og_count_(+KeyObjList, -N): number of members in a Key-ObjList group.
og_count_(_Key-Members, N) :-
    length(Members, N).

% --- Exported predicates -----------------------------------------------------

% og_by_color(+Objs, -Groups): partition into Color-ObjList groups.
og_by_color(Objs, Groups) :-
    og_group_by_(Objs, og_color_, Groups).

% og_by_size(+Objs, -Groups): partition into Size-ObjList groups.
og_by_size(Objs, Groups) :-
    og_group_by_(Objs, og_size_, Groups).

% og_by_form(+Objs, -Groups): partition into Form-ObjList groups.
% Form is the normalized (origin-translated, sorted) cell list.
og_by_form(Objs, Groups) :-
    og_group_by_(Objs, og_norm_, Groups).

% og_by_row(+Objs, -Groups): partition by top-left row.
og_by_row(Objs, Groups) :-
    og_group_by_(Objs, og_row_key_, Groups).

% og_row_key_(+Obj, -Row): extract min row from obj.
og_row_key_(Obj, Row) :-
    og_topleft_(Obj, r(Row, _)).

% og_by_col(+Objs, -Groups): partition by top-left col.
og_by_col(Objs, Groups) :-
    og_group_by_(Objs, og_col_key_, Groups).

% og_col_key_(+Obj, -Col): extract min col from obj.
og_col_key_(Obj, Col) :-
    og_topleft_(Obj, r(_, Col)).

% og_n_groups(+Groups, -N): number of groups.
og_n_groups(Groups, N) :-
    length(Groups, N).

% og_n_members(+Groups, +N, -Selected): groups with exactly N members.
og_n_members(Groups, N, Selected) :-
    findall(G,
        (member(G, Groups),
         og_count_(G, N)),
        Selected).

% og_singletons(+Groups, -Singletons): groups with exactly one member.
og_singletons(Groups, Singletons) :-
    og_n_members(Groups, 1, Singletons).

% og_largest(+Groups, -Group): group with the most members.
og_largest(Groups, Group) :-
    Groups \= [],
    findall(NegN-G, (member(G, Groups), og_count_(G, N), NegN is -N), Keyed),
    msort(Keyed, [_-Group|_]).

% og_smallest(+Groups, -Group): group with the fewest members.
og_smallest(Groups, Group) :-
    Groups \= [],
    findall(N-G, (member(G, Groups), og_count_(G, N)), Keyed),
    msort(Keyed, [_-Group|_]).

% og_all_same_size(+Groups): all groups have the same member count.
og_all_same_size([]).
og_all_same_size([First|Rest]) :-
    og_count_(First, N),
    maplist(og_count_eq_(N), Rest).

% og_count_eq_(+N, +Group): group has exactly N members.
og_count_eq_(N, Group) :-
    og_count_(Group, N).

% og_sort_desc(+Groups, -Sorted): sort groups by member count descending.
og_sort_desc(Groups, Sorted) :-
    findall(NegN-G, (member(G, Groups), og_count_(G, N), NegN is -N), Keyed),
    msort(Keyed, SortedKeyed),
    findall(G, member(_-G, SortedKeyed), Sorted).

% og_flat(+Groups, -Objs): flatten groups into a single obj list.
og_flat(Groups, Objs) :-
    findall(O, (member(_-Members, Groups), member(O, Members)), Objs).

% og_filter_size(+Groups, +Min, +Max, -Filtered): keep groups with Min..Max members.
og_filter_size(Groups, Min, Max, Filtered) :-
    findall(G,
        (member(G, Groups),
         og_count_(G, N),
         N >= Min,
         N =< Max),
        Filtered).
