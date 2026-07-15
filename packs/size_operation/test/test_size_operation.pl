:- use_module('../prolog/size_operation.pl').
:- use_module(library(plunit)).

% Test helpers: named object fixtures.
% dot: 1 cell.
dot(obj(red, [r(0,0)])).
% small: 2 cells.
small(obj(blue, [r(0,0), r(0,1)])).
% medium: 3 cells.
medium(obj(green, [r(0,0), r(0,1), r(0,2)])).
% large: 4 cells.
large(obj(yellow, [r(0,0), r(0,1), r(1,0), r(1,1)])).
% extra_large: 6 cells.
extra_large(obj(white, [r(0,0),r(0,1),r(0,2),r(1,0),r(1,1),r(1,2)])).
% twin: same size as medium (3 cells), different color.
twin(obj(black, [r(2,0), r(2,1), r(2,2)])).

% Mixed scene: [dot, small, medium, large].
scene4(Objs) :- dot(D), small(S), medium(M), large(L), Objs = [D,S,M,L].
% Scene with a tie: [dot, twin, medium] where twin and medium both have 3 cells.
scene_tie(Objs) :- dot(D), twin(T), medium(M), Objs = [D,T,M].

:- begin_tests(size_operation_of).

test(dot_size_1) :- dot(O), size_operation_of(O, 1).
test(small_size_2) :- small(O), size_operation_of(O, 2).
test(medium_size_3) :- medium(O), size_operation_of(O, 3).
test(large_size_4) :- large(O), size_operation_of(O, 4).
test(extra_large_size_6) :- extra_large(O), size_operation_of(O, 6).

:- end_tests(size_operation_of).

:- begin_tests(size_operation_sort_asc).

test(four_objects) :-
    scene4(Objs),
    size_operation_sort_asc(Objs, [D,S,M,L]),
    size_operation_of(D, 1), size_operation_of(S, 2), size_operation_of(M, 3), size_operation_of(L, 4).

test(already_ascending) :-
    dot(D), small(S),
    size_operation_sort_asc([D,S], [D,S]).

test(reverse_order) :-
    dot(D), small(S), medium(M),
    size_operation_sort_asc([M,S,D], [D,S,M]).

test(single_object) :-
    dot(D), size_operation_sort_asc([D], [D]).

test(empty_list) :-
    size_operation_sort_asc([], []).

test(ties_preserve_input_order) :-
    % twin and medium both have 3 cells; twin appears first in input so stays first.
    scene_tie(Objs),
    size_operation_sort_asc(Objs, [D|Rest]),
    size_operation_of(D, 1),
    Rest = [T, M],
    size_operation_of(T, 3), size_operation_of(M, 3),
    twin(T), medium(M).

:- end_tests(size_operation_sort_asc).

:- begin_tests(size_operation_sort_desc).

test(four_objects) :-
    scene4(Objs),
    size_operation_sort_desc(Objs, [L,M,S,D]),
    size_operation_of(L, 4), size_operation_of(M, 3), size_operation_of(S, 2), size_operation_of(D, 1).

test(already_descending) :-
    dot(D), small(S), medium(M),
    size_operation_sort_desc([M,S,D], [M,S,D]).

test(ascending_reversed) :-
    dot(D), small(S), medium(M),
    size_operation_sort_desc([D,S,M], [M,S,D]).

test(single_object) :-
    dot(D), size_operation_sort_desc([D], [D]).

test(empty_list) :-
    size_operation_sort_desc([], []).

:- end_tests(size_operation_sort_desc).

:- begin_tests(size_operation_smallest).

test(smallest_of_four) :-
    scene4(Objs), dot(D), size_operation_smallest(Objs, D).

test(single_obj) :-
    medium(M), size_operation_smallest([M], M).

test(tie_not_smallest) :-
    % In scene_tie = [dot, twin, medium], dot (size 1) is smallest.
    scene_tie(Objs), dot(D),
    size_operation_smallest(Objs, D).

:- end_tests(size_operation_smallest).

:- begin_tests(size_operation_largest).

test(largest_of_four) :-
    scene4(Objs), large(L), size_operation_largest(Objs, L).

test(single_obj) :-
    medium(M), size_operation_largest([M], M).

test(largest_from_reversed) :-
    dot(D), small(S), medium(M), large(L),
    size_operation_largest([L,M,S,D], L).

:- end_tests(size_operation_largest).

:- begin_tests(size_operation_nth_smallest).

test(first_smallest) :-
    scene4(Objs), dot(D), size_operation_nth_smallest(Objs, 1, D).

test(second_smallest) :-
    scene4(Objs), small(S), size_operation_nth_smallest(Objs, 2, S).

test(third_smallest) :-
    scene4(Objs), medium(M), size_operation_nth_smallest(Objs, 3, M).

test(fourth_smallest) :-
    scene4(Objs), large(L), size_operation_nth_smallest(Objs, 4, L).

:- end_tests(size_operation_nth_smallest).

:- begin_tests(size_operation_nth_largest).

test(first_largest) :-
    scene4(Objs), large(L), size_operation_nth_largest(Objs, 1, L).

test(second_largest) :-
    scene4(Objs), medium(M), size_operation_nth_largest(Objs, 2, M).

test(third_largest) :-
    scene4(Objs), small(S), size_operation_nth_largest(Objs, 3, S).

test(fourth_largest) :-
    scene4(Objs), dot(D), size_operation_nth_largest(Objs, 4, D).

:- end_tests(size_operation_nth_largest).

:- begin_tests(size_operation_rank_of).

test(dot_is_rank_1) :-
    scene4(Objs), dot(D), size_operation_rank_of(Objs, D, 1).

test(small_is_rank_2) :-
    scene4(Objs), small(S), size_operation_rank_of(Objs, S, 2).

test(medium_is_rank_3) :-
    scene4(Objs), medium(M), size_operation_rank_of(Objs, M, 3).

test(large_is_rank_4) :-
    scene4(Objs), large(L), size_operation_rank_of(Objs, L, 4).

:- end_tests(size_operation_rank_of).

:- begin_tests(size_operation_assign_colors).

test(assign_four_colors) :-
    % Objects sorted by size ascending: dot(1), small(2), medium(3), large(4).
    % Colors assigned: dot->a, small->b, medium->c, large->d.
    scene4(Objs),
    size_operation_assign_colors(Objs, [a,b,c,d], Result),
    Result = [obj(a,_), obj(b,_), obj(c,_), obj(d,_)],
    % Verify that dot-sized cells are in the first result object.
    Result = [obj(a, C1)|_], length(C1, 1).

test(assign_truncates_at_colors) :-
    % 4 objects but only 2 colors: only first 2 (smallest) get new colors.
    scene4(Objs),
    size_operation_assign_colors(Objs, [x,y], Result),
    length(Result, 2).

test(assign_truncates_at_objects) :-
    % 2 objects but 4 colors: only 2 results.
    dot(D), small(S),
    size_operation_assign_colors([D,S], [a,b,c,d], Result),
    length(Result, 2).

test(assign_empty_objs) :-
    size_operation_assign_colors([], [a,b,c], []).

test(assign_empty_colors) :-
    scene4(Objs), size_operation_assign_colors(Objs, [], []).

:- end_tests(size_operation_assign_colors).

:- begin_tests(size_operation_by_size).

test(filter_size_2) :-
    scene4(Objs), small(S),
    size_operation_by_size(Objs, 2, [S]).

test(filter_size_3) :-
    scene4(Objs), medium(M),
    size_operation_by_size(Objs, 3, [M]).

test(filter_no_match) :-
    scene4(Objs),
    size_operation_by_size(Objs, 99, []).

test(filter_ties) :-
    % scene_tie has dot(1), twin(3), medium(3): filter for 3 returns [twin, medium].
    scene_tie(Objs), twin(T), medium(M),
    size_operation_by_size(Objs, 3, [T, M]).

test(filter_empty) :-
    size_operation_by_size([], 5, []).

:- end_tests(size_operation_by_size).

:- begin_tests(size_operation_above).

test(above_2) :-
    % From scene4, objects with > 2 cells: medium(3) and large(4).
    scene4(Objs), medium(M), large(L),
    size_operation_above(Objs, 2, [M, L]).

test(above_0_all) :-
    % Everything has > 0 cells.
    scene4(Objs),
    size_operation_above(Objs, 0, Objs).

test(above_large_none) :-
    scene4(Objs), size_operation_above(Objs, 10, []).

test(above_empty) :-
    size_operation_above([], 0, []).

:- end_tests(size_operation_above).

:- begin_tests(size_operation_below).

test(below_3) :-
    % From scene4, objects with < 3 cells: dot(1) and small(2).
    scene4(Objs), dot(D), small(S),
    size_operation_below(Objs, 3, [D, S]).

test(below_2) :-
    scene4(Objs), dot(D),
    size_operation_below(Objs, 2, [D]).

test(below_1_none) :-
    scene4(Objs), size_operation_below(Objs, 1, []).

test(below_empty) :-
    size_operation_below([], 5, []).

:- end_tests(size_operation_below).

:- begin_tests(size_operation_unique_sizes).

test(four_distinct) :-
    scene4(Objs),
    size_operation_unique_sizes(Objs, [1, 2, 3, 4]).

test(with_ties) :-
    % scene_tie has sizes 1, 3, 3 -> unique: [1, 3].
    scene_tie(Objs),
    size_operation_unique_sizes(Objs, [1, 3]).

test(single_obj) :-
    medium(M),
    size_operation_unique_sizes([M], [3]).

test(empty) :-
    size_operation_unique_sizes([], []).

:- end_tests(size_operation_unique_sizes).

:- begin_tests(size_operation_total_cells).

test(four_objects) :-
    % 1 + 2 + 3 + 4 = 10.
    scene4(Objs),
    size_operation_total_cells(Objs, 10).

test(single_medium) :-
    medium(M), size_operation_total_cells([M], 3).

test(empty_is_0) :-
    size_operation_total_cells([], 0).

test(with_ties) :-
    % dot(1) + twin(3) + medium(3) = 7.
    scene_tie(Objs),
    size_operation_total_cells(Objs, 7).

:- end_tests(size_operation_total_cells).
