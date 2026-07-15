% sizeop.pl - Layer 161: Size-Based Sorting and Assignment for Object Collections
%             (sz_* prefix).
% General-purpose predicates that operate on the cell-count (size) of
% obj(Color, Cells) terms. Provides: size extraction, ascending/descending
% sort by size, smallest/largest selection, rank-by-size, rank-indexed access,
% color assignment in size order, exact/above/below size filtering, distinct
% size enumeration, and total cell count aggregation.
:- module(size_operation, [
    size_operation_of/2,
    size_operation_sort_asc/2,
    size_operation_sort_desc/2,
    size_operation_smallest/2,
    size_operation_largest/2,
    size_operation_nth_smallest/3,
    size_operation_nth_largest/3,
    size_operation_rank_of/3,
    size_operation_assign_colors/3,
    size_operation_by_size/3,
    size_operation_above/3,
    size_operation_below/3,
    size_operation_unique_sizes/2,
    size_operation_total_cells/2
]).
% Import list utilities; length/2, findall/3, sort/2, keysort/2 are built-ins.
:- use_module(library(lists), [member/2, nth1/3, min_list/2, max_list/2,
                                 sum_list/2]).

% size_operation_of(+Obj, -N): N is the number of cells (size) of Obj.
size_operation_of(obj(_, Cells), N) :-
% Count the cells by measuring the length of the Cells list.
    length(Cells, N).

% size_operation_sort_asc(+Objs, -Sorted): sort Objs by cell count ascending (smallest first).
% Objects with equal size retain their relative order from the input (stable sort).
size_operation_sort_asc(Objs, Sorted) :-
% Build N-Obj pairs where N is each object's cell count.
    findall(N-O, (member(O, Objs), size_operation_of(O, N)), Pairs),
% keysort/2 is a built-in stable sort ascending by key.
    keysort(Pairs, SortedPairs),
% Strip the keys to recover the sorted object list.
    findall(O, member(_-O, SortedPairs), Sorted).

% size_operation_sort_desc(+Objs, -Sorted): sort Objs by cell count descending (largest first).
% Objects with equal size retain their relative order from the input (stable sort).
size_operation_sort_desc(Objs, Sorted) :-
% Build N-Obj pairs where N is each object's cell count.
    findall(N-O, (member(O, Objs), size_operation_of(O, N)), Pairs),
% Negate each key so that keysort ascending produces descending size order.
    findall(Neg-O, (member(N-O, Pairs), Neg is -N), NegPairs),
% Sort by negated key ascending = sort by original key descending.
    keysort(NegPairs, SortedNeg),
% Strip keys to get the final sorted object list.
    findall(O, member(_-O, SortedNeg), Sorted).

% size_operation_smallest(+Objs, -Obj): Obj is the first object in Objs (by input order) with
% the fewest cells. Fails if Objs is empty.
size_operation_smallest(Objs, Obj) :-
% Collect all sizes to find the minimum.
    findall(N, (member(O, Objs), size_operation_of(O, N)), Sizes),
% Find the minimum size value.
    min_list(Sizes, MinN),
% Return the first object in input order that has the minimum size.
    member(Obj, Objs), size_operation_of(Obj, MinN), !.

% size_operation_largest(+Objs, -Obj): Obj is the first object in Objs (by input order) with
% the most cells. Fails if Objs is empty.
size_operation_largest(Objs, Obj) :-
% Collect all sizes to find the maximum.
    findall(N, (member(O, Objs), size_operation_of(O, N)), Sizes),
% Find the maximum size value.
    max_list(Sizes, MaxN),
% Return the first object in input order that has the maximum size.
    member(Obj, Objs), size_operation_of(Obj, MaxN), !.

% size_operation_nth_smallest(+Objs, +N, -Obj): Obj is the Nth object in ascending size order.
% N is 1-based. Ties preserve input order (stable sort).
size_operation_nth_smallest(Objs, N, Obj) :-
% Sort ascending to get objects in size order, then index.
    size_operation_sort_asc(Objs, Sorted),
    nth1(N, Sorted, Obj).

% size_operation_nth_largest(+Objs, +N, -Obj): Obj is the Nth object in descending size order.
% N is 1-based. Ties preserve input order (stable sort).
size_operation_nth_largest(Objs, N, Obj) :-
% Sort descending to get objects in reverse size order, then index.
    size_operation_sort_desc(Objs, Sorted),
    nth1(N, Sorted, Obj).

% size_operation_rank_of(+Objs, +Obj, -Rank): Rank is the 1-based position of Obj in the
% ascending size ordering of Objs. Ties are broken by input order (stable sort).
size_operation_rank_of(Objs, Obj, Rank) :-
% Sort ascending and find the position of Obj via nth1.
    size_operation_sort_asc(Objs, Sorted),
    nth1(Rank, Sorted, Obj).

% size_operation_assign_colors(+Objs, +Colors, -Result): sort Objs by size ascending, then
% recolor each object with the corresponding color from Colors. Truncates at
% the shorter of Objs and Colors. Result is a list of recolored obj terms.
size_operation_assign_colors(Objs, Colors, Result) :-
% Sort objects by size so smallest gets Colors[1], next gets Colors[2], etc.
    size_operation_sort_asc(Objs, Sorted),
% Zip sorted objects with colors and recolor each.
    size_operation_zip_recolor_(Sorted, Colors, Result).

% size_operation_zip_recolor_(+Objs, +Colors, -Result): private helper to zip and recolor.
% Base case: first list exhausted.
size_operation_zip_recolor_([], _, []) :- !.
% Base case: second list exhausted.
size_operation_zip_recolor_(_, [], []) :- !.
% Pair each object with a color; create obj(NewColor, OriginalCells) and recurse.
size_operation_zip_recolor_([obj(_, Cells)|Ts], [C|Tc], [obj(C, Cells)|Rs]) :-
    size_operation_zip_recolor_(Ts, Tc, Rs).

% size_operation_by_size(+Objs, +N, -Filtered): Filtered is the sub-list of Objs whose objects
% have exactly N cells. Returns [] if none match.
size_operation_by_size(Objs, N, Filtered) :-
% Keep objects whose cell count equals N.
    findall(O, (member(O, Objs), size_operation_of(O, N)), Filtered).

% size_operation_above(+Objs, +N, -Filtered): Filtered is the sub-list of Objs whose objects
% have strictly more than N cells.
size_operation_above(Objs, N, Filtered) :-
% Keep objects whose cell count is strictly greater than N.
    findall(O, (member(O, Objs), size_operation_of(O, S), S > N), Filtered).

% size_operation_below(+Objs, +N, -Filtered): Filtered is the sub-list of Objs whose objects
% have strictly fewer than N cells.
size_operation_below(Objs, N, Filtered) :-
% Keep objects whose cell count is strictly less than N.
    findall(O, (member(O, Objs), size_operation_of(O, S), S < N), Filtered).

% size_operation_unique_sizes(+Objs, -Sizes): Sizes is the sorted list of distinct cell counts
% across all objects in Objs. Duplicates are removed by sort/2.
size_operation_unique_sizes(Objs, Sizes) :-
% Collect all cell counts; sort/2 deduplicates and orders ascending.
    findall(N, (member(O, Objs), size_operation_of(O, N)), Ns),
    sort(Ns, Sizes).

% size_operation_total_cells(+Objs, -N): N is the sum of cell counts across all objects.
% Returns 0 for empty Objs.
size_operation_total_cells(Objs, N) :-
% Collect all individual sizes then sum them.
    findall(S, (member(O, Objs), size_operation_of(O, S)), Sizes),
    sum_list(Sizes, N).
