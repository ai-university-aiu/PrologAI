% group.pl - Layer 156: Object Grouping and Partition (gp_* prefix).
% Partitions a list of obj(Color, Cells) terms into named groups sharing a
% common property: color, cell count (size), topmost row, leftmost column,
% or origin-normalized form (shape). Groups are represented as sorted Key-[Objs]
% pairs. Provides group inspection, element access, and aggregate predicates.
:- module(group, [
    % group_by_color/2: partition by color into sorted Color-[Objs] pairs.
    group_by_color/2,
    % group_by_size/2: partition by cell count into sorted N-[Objs] pairs.
    group_by_size/2,
    % group_by_row/2: partition by minimum row of cells into R-[Objs] pairs.
    group_by_row/2,
    % group_by_col/2: partition by minimum column of cells into C-[Objs] pairs.
    group_by_col/2,
    % group_by_form/2: partition by origin-normalized cell list (shape).
    group_by_form/2,
    % group_size_of/2: number of distinct groups.
    group_size_of/2,
    % group_flatten/2: collect all objects from all groups in key order.
    group_flatten/2,
    % group_largest_group/2: Key-[Objs] pair with the most objects; smallest key on ties.
    group_largest_group/2,
    % group_smallest_group/2: Key-[Objs] pair with the fewest objects; smallest key on ties.
    group_smallest_group/2,
    % group_singleton_groups/2: sub-list of groups containing exactly one object.
    group_singleton_groups/2,
    % group_shared_groups/2: sub-list of groups containing more than one object.
    group_shared_groups/2,
    % group_group_sizes/2: sorted list of group cardinalities (distinct sizes).
    group_group_sizes/2,
    % group_all_same_size/1: succeed iff every group has the same cardinality.
    group_all_same_size/1,
    % group_keys/2: sorted list of group keys.
    group_keys/2
]).

% Import list utilities; length/2, sort/2, findall/3 are built-ins.
:- use_module(library(lists), [member/2, memberchk/2, min_list/2, max_list/2]).

% group_norm_(+Cells, -Form): origin-normalized cell list (min R=0, min C=0, sorted).
% Used internally by group_by_form to compute the canonical shape key.
group_norm_(Cells, Form) :-
% Collect all row values and find the minimum.
    findall(R, member(r(R,_), Cells), Rs),
    min_list(Rs, MinR),
% Collect all column values and find the minimum.
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Cs, MinC),
% Translate each cell to origin by subtracting minimum row and column.
    findall(r(R2,C2), (
        member(r(R,C), Cells),
        R2 is R - MinR,
        C2 is C - MinC
    ), Form0),
% Sort for canonical order; deduplicates in case Cells had duplicates.
    sort(Form0, Form).

% group_by_color(+Objs, -Groups): partition objects by color.
% Groups is a sorted list of Color-[ObjsOfColor] pairs.
% Colors are sorted ascending; within each group, objects appear in Objs order.
group_by_color(Objs, Groups) :-
% Collect all colors and deduplicate with sort.
    findall(C, member(obj(C,_), Objs), Cs0),
    sort(Cs0, Colors),
% For each color, collect objects with that color.
    findall(C-Grp, (
        member(C, Colors),
        findall(O, (member(O, Objs), O = obj(C,_)), Grp)
    ), Groups).

% group_by_size(+Objs, -Groups): partition objects by cell count.
% Groups is a sorted list of N-[ObjsOfSizeN] pairs.
group_by_size(Objs, Groups) :-
% Collect all cell counts and deduplicate.
    findall(N, (member(obj(_,Cells), Objs), length(Cells, N)), Ns0),
    sort(Ns0, Sizes),
% For each size, collect objects with that cell count.
    findall(N-Grp, (
        member(N, Sizes),
        findall(O, (member(O, Objs), O = obj(_,Cells), length(Cells, N)), Grp)
    ), Groups).

% group_by_row(+Objs, -Groups): partition objects by minimum row of cells.
% Groups is a sorted list of R-[ObjsWithTopRow R] pairs.
group_by_row(Objs, Groups) :-
% Compute the minimum row for each object and deduplicate.
    findall(R, (
        member(obj(_,Cells), Objs),
        findall(Rr, member(r(Rr,_), Cells), Rs),
        min_list(Rs, R)
    ), Rs0),
    sort(Rs0, Rows),
% For each distinct minimum row, collect matching objects.
    findall(R-Grp, (
        member(R, Rows),
        findall(O, (
            member(O, Objs),
            O = obj(_,Cells),
            findall(Rr, member(r(Rr,_), Cells), Rs2),
            min_list(Rs2, R)
        ), Grp)
    ), Groups).

% group_by_col(+Objs, -Groups): partition objects by minimum column of cells.
% Groups is a sorted list of C-[ObjsWithLeftCol C] pairs.
group_by_col(Objs, Groups) :-
% Compute the minimum column for each object and deduplicate.
    findall(C, (
        member(obj(_,Cells), Objs),
        findall(Cc, member(r(_,Cc), Cells), Cs),
        min_list(Cs, C)
    ), Cs0),
    sort(Cs0, Cols),
% For each distinct minimum column, collect matching objects.
    findall(C-Grp, (
        member(C, Cols),
        findall(O, (
            member(O, Objs),
            O = obj(_,Cells),
            findall(Cc, member(r(_,Cc), Cells), Cs2),
            min_list(Cs2, C)
        ), Grp)
    ), Groups).

% group_by_form(+Objs, -Groups): partition objects by origin-normalized cell list.
% Two objects share a form iff their cells are identical after translation to origin.
% Groups is a sorted list of Form-[ObjsOfForm] pairs.
group_by_form(Objs, Groups) :-
% Compute the normalized form for each object and deduplicate.
    findall(F, (member(obj(_,Cells), Objs), group_norm_(Cells, F)), Fs0),
    sort(Fs0, Forms),
% For each distinct form, collect objects with that form.
    findall(F-Grp, (
        member(F, Forms),
        findall(O, (member(O, Objs), O = obj(_,Cells), group_norm_(Cells, F)), Grp)
    ), Groups).

% group_size_of(+Groups, -N): number of distinct groups.
group_size_of(Groups, N) :-
% Group count is simply the list length.
    length(Groups, N).

% group_flatten(+Groups, -Objs): collect every object from every group in key order.
% Objects within each group appear in their original Objs order.
group_flatten(Groups, Objs) :-
% For each group in key order, yield each object.
    findall(O, (member(_-Grp, Groups), member(O, Grp)), Objs).

% group_largest_group(+Groups, -Largest): Key-[Objs] pair with the most objects.
% Ties broken by smallest Key (first Key in sorted Groups order).
group_largest_group(Groups, Key-Grp) :-
% Build N-Key pairs using group cardinality as sort key.
    findall(N-K, (member(K-G, Groups), length(G, N)), Pairs),
% Extract cardinalities.
    findall(N, member(N-_, Pairs), Ns),
% Find the maximum cardinality.
    max_list(Ns, MaxN),
% First match is the smallest key at max cardinality (Pairs is in Groups order = sorted keys).
    member(MaxN-Key, Pairs), !,
% Retrieve the actual group list; memberchk avoids leaving a choicepoint.
    memberchk(Key-Grp, Groups).

% group_smallest_group(+Groups, -Smallest): Key-[Objs] pair with the fewest objects.
% Ties broken by smallest Key.
group_smallest_group(Groups, Key-Grp) :-
% Build N-Key pairs.
    findall(N-K, (member(K-G, Groups), length(G, N)), Pairs),
% Extract cardinalities.
    findall(N, member(N-_, Pairs), Ns),
% Find the minimum cardinality.
    min_list(Ns, MinN),
% First match at minimum is the smallest key with min cardinality.
    member(MinN-Key, Pairs), !,
% Retrieve the actual group list; memberchk avoids leaving a choicepoint.
    memberchk(Key-Grp, Groups).

% group_singleton_groups(+Groups, -Singles): groups containing exactly one object.
group_singleton_groups(Groups, Singles) :-
% Keep only groups where the objects list has length 1.
    findall(G, (member(G, Groups), G = _-Objs, length(Objs, 1)), Singles).

% group_shared_groups(+Groups, -Shared): groups containing more than one object.
group_shared_groups(Groups, Shared) :-
% Keep only groups where the objects list has length > 1.
    findall(G, (member(G, Groups), G = _-Objs, length(Objs, N), N > 1), Shared).

% group_group_sizes(+Groups, -Sizes): sorted list of distinct group cardinalities.
% Deduplicates: if two groups have the same number of members, that number appears once.
group_group_sizes(Groups, Sizes) :-
% Collect all group cardinalities.
    findall(N, (member(_-Grp, Groups), length(Grp, N)), Ns0),
% Sort and deduplicate.
    sort(Ns0, Sizes).

% group_all_same_size(+Groups): succeed iff all groups have the same cardinality.
% Empty groups list: succeeds vacuously (no counterexample exists).
group_all_same_size([]) :- !.
group_all_same_size(Groups) :-
% Compute all cardinalities; after sort/2 deduplication, exactly one distinct value must remain.
    findall(N, (member(_-G, Groups), length(G, N)), Ns0),
    sort(Ns0, [_]).

% group_keys(+Groups, -Keys): sorted list of group keys.
group_keys(Groups, Keys) :-
% Collect keys from the Key-[Objs] pairs.
    findall(K, member(K-_, Groups), Ks0),
% Sort and deduplicate (handles any out-of-order input).
    sort(Ks0, Keys).
