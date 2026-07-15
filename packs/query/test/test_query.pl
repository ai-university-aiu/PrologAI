:- begin_tests(query).
:- use_module('../prolog/query').

% query_count_by_color/2 - sorted Color-N pairs.
test(count_color_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(1,[r(1,0)])],
    query_count_by_color(Objs, [1-2, 2-1]).

test(count_color_single) :-
    query_count_by_color([obj(3,[r(0,0)])], [3-1]).

test(count_color_three) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(3,[r(1,0)])],
    query_count_by_color(Objs, [1-1, 2-1, 3-1]).

% query_count_by_size/2 - sorted Size-N pairs.
test(count_size_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1),r(0,2)]), obj(3,[r(1,0)])],
    query_count_by_size(Objs, [1-2, 2-1]).

test(count_size_single) :-
    query_count_by_size([obj(1,[r(0,0)])], [1-1]).

test(count_size_three) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1),r(0,2)]), obj(3,[r(1,0),r(1,1),r(1,2)])],
    query_count_by_size(Objs, [1-1, 2-1, 3-1]).

% query_count_by_form/2 - sorted Form-N pairs using origin-normalized shapes.
test(count_form_basic) :-
    Objs = [obj(1,[r(0,0),r(0,1)]), obj(2,[r(1,0),r(1,1)])],
    query_count_by_form(Objs, [[r(0,0),r(0,1)]-2]).

test(count_form_diff) :-
    Objs = [obj(1,[r(0,0),r(0,1)]), obj(2,[r(0,0),r(1,0)])],
    query_count_by_form(Objs, [[r(0,0),r(0,1)]-1, [r(0,0),r(1,0)]-1]).

test(count_form_single) :-
    query_count_by_form([obj(1,[r(0,0),r(0,1)])], [[r(0,0),r(0,1)]-1]).

% query_most_frequent_color/2 - highest-count color, smallest on ties.
test(most_freq_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(1,[r(1,0)])],
    query_most_frequent_color(Objs, 1).

test(most_freq_tie) :-
    query_most_frequent_color([obj(2,[r(0,0)]), obj(5,[r(0,1)])], 2).

test(most_freq_single) :-
    query_most_frequent_color([obj(7,[r(0,0)])], 7).

% query_least_frequent_color/2 - lowest-count color, smallest on ties.
test(least_freq_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(1,[r(1,0)])],
    query_least_frequent_color(Objs, 2).

test(least_freq_tie) :-
    query_least_frequent_color([obj(3,[r(0,0)]), obj(5,[r(0,1)])], 3).

test(least_freq_single) :-
    query_least_frequent_color([obj(7,[r(0,0)])], 7).

% query_largest_obj/2 - obj with most cells, first in input on ties.
test(largest_basic) :-
    O1 = obj(1,[r(0,0),r(0,1),r(0,2)]),
    O2 = obj(2,[r(1,0)]),
    query_largest_obj([O1,O2], O1).

test(largest_tie) :-
    O1 = obj(1,[r(0,0),r(0,1)]),
    O2 = obj(2,[r(1,0),r(1,1)]),
    query_largest_obj([O1,O2], O1).

test(largest_single) :-
    O = obj(1,[r(0,0)]),
    query_largest_obj([O], O).

% query_smallest_obj/2 - obj with fewest cells, first in input on ties.
test(smallest_basic) :-
    O1 = obj(1,[r(0,0)]),
    O2 = obj(2,[r(1,0),r(1,1),r(1,2)]),
    query_smallest_obj([O1,O2], O1).

test(smallest_tie) :-
    O1 = obj(1,[r(0,0)]),
    O2 = obj(2,[r(1,0)]),
    query_smallest_obj([O1,O2], O1).

test(smallest_single) :-
    O = obj(3,[r(0,0),r(0,1)]),
    query_smallest_obj([O], O).

% query_total_cells/2 - sum of all cell counts.
test(total_basic) :-
    Objs = [obj(1,[r(0,0),r(0,1),r(0,2)]), obj(2,[r(1,0),r(1,1)])],
    query_total_cells(Objs, 5).

test(total_single) :-
    query_total_cells([obj(1,[r(0,0)])], 1).

test(total_three) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1),r(0,2)]), obj(3,[r(1,0),r(1,1),r(1,2)])],
    query_total_cells(Objs, 6).

% query_avg_size/2 - floor-average cell count per obj.
test(avg_basic) :-
    Objs = [obj(1,[r(0,0),r(0,1),r(0,2)]), obj(2,[r(1,0)])],
    query_avg_size(Objs, 2).

test(avg_floor) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1),r(0,2)]), obj(3,[r(1,0),r(1,1),r(1,2)])],
    query_avg_size(Objs, 2).

test(avg_single) :-
    query_avg_size([obj(1,[r(0,0),r(0,1),r(0,2),r(0,3)])], 4).

% query_all_same_color/1 - all objs share one color.
test(same_color_yes) :-
    query_all_same_color([obj(3,[r(0,0)]), obj(3,[r(1,0)]), obj(3,[r(2,0)])]).

test(same_color_no, [fail]) :-
    query_all_same_color([obj(1,[r(0,0)]), obj(2,[r(1,0)])]).

test(same_color_single) :-
    query_all_same_color([obj(5,[r(0,0)])]).

% query_all_same_size/1 - all objs share one cell count.
test(same_size_yes) :-
    query_all_same_size([obj(1,[r(0,0),r(0,1)]), obj(2,[r(1,0),r(1,1)])]).

test(same_size_no, [fail]) :-
    query_all_same_size([obj(1,[r(0,0)]), obj(2,[r(1,0),r(1,1)])]).

test(same_size_single) :-
    query_all_same_size([obj(1,[r(0,0),r(0,1),r(0,2)])]).

% query_all_same_form/1 - all objs share one origin-normalized shape.
test(same_form_yes) :-
    query_all_same_form([obj(1,[r(0,0),r(0,1)]), obj(2,[r(3,4),r(3,5)])]).

test(same_form_no, [fail]) :-
    query_all_same_form([obj(1,[r(0,0),r(0,1)]), obj(2,[r(0,0),r(1,0)])]).

test(same_form_single) :-
    query_all_same_form([obj(1,[r(2,3)])]).

% query_colors/2 - sorted distinct color values.
test(colors_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(1,[r(1,0)])],
    query_colors(Objs, [1,2]).

test(colors_all_same) :-
    query_colors([obj(3,[r(0,0)]), obj(3,[r(1,0)])], [3]).

test(colors_single) :-
    query_colors([obj(5,[r(0,0)])], [5]).

% query_sizes/2 - sorted distinct cell counts.
test(sizes_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1),r(0,2)]), obj(3,[r(1,0)])],
    query_sizes(Objs, [1,2]).

test(sizes_all_same) :-
    query_sizes([obj(1,[r(0,0),r(0,1)]), obj(2,[r(1,0),r(1,1)])], [2]).

test(sizes_single) :-
    query_sizes([obj(3,[r(0,0),r(0,1),r(0,2)])], [3]).

:- end_tests(query).
