% test_region.pl - PLUnit tests for the region pack (Layer 92: rg_* predicates).
:- use_module('../prolog/region').

% Tests for region_sep_rows/3

:- begin_tests(region_sep_rows).

test(two_sep_rows) :-
    region_sep_rows([[0,0,0],[1,2,3],[0,0,0]], 0, [0,2]).

test(one_sep_row) :-
    region_sep_rows([[1,2],[0,0],[3,4],[0,0],[5,6]], 0, [1,3]).

test(no_sep_rows) :-
    region_sep_rows([[1,2],[3,4]], 0, []).

:- end_tests(region_sep_rows).

% Tests for region_sep_cols/3

:- begin_tests(region_sep_cols).

test(two_sep_cols) :-
    region_sep_cols([[0,1,0],[0,2,0],[0,3,0]], 0, [0,2]).

test(one_sep_col) :-
    region_sep_cols([[1,0,2],[3,0,4]], 0, [1]).

test(no_sep_cols) :-
    region_sep_cols([[1,2],[3,4]], 0, []).

:- end_tests(region_sep_cols).

% Tests for region_is_sep_row/3

:- begin_tests(region_is_sep_row).

test(all_sep) :-
    region_is_sep_row([[1,2],[0,0],[3,4]], 1, 0).

test(not_sep) :-
    \+ region_is_sep_row([[1,2],[0,1],[3,4]], 1, 0).

test(single_cell_sep) :-
    region_is_sep_row([[5],[0],[7]], 1, 0).

:- end_tests(region_is_sep_row).

% Tests for region_is_sep_col/3

:- begin_tests(region_is_sep_col).

test(col_all_sep) :-
    region_is_sep_col([[0,1],[0,2],[0,3]], 0, 0).

test(col_not_sep) :-
    \+ region_is_sep_col([[0,1],[1,2],[0,3]], 0, 0).

test(single_row_col_sep) :-
    region_is_sep_col([[1,0,3]], 1, 0).

:- end_tests(region_is_sep_col).

% Tests for region_spans_h/3

:- begin_tests(region_spans_h).

test(one_sep_two_sections) :-
    region_spans_h([[1,2],[0,0],[3,4],[5,6]], 0, [0-0, 2-3]).

test(two_seps_three_sections) :-
    region_spans_h([[1,2],[0,0],[3,4],[0,0],[5,6]], 0, [0-0, 2-2, 4-4]).

test(no_seps_one_full_span) :-
    region_spans_h([[1,2],[3,4]], 0, [0-1]).

:- end_tests(region_spans_h).

% Tests for region_spans_v/3

:- begin_tests(region_spans_v).

test(one_sep_col_two_sections) :-
    region_spans_v([[1,0,2],[3,0,4]], 0, [0-0, 2-2]).

test(two_sep_cols_three_sections) :-
    region_spans_v([[1,0,2,0,3]], 0, [0-0, 2-2, 4-4]).

test(no_sep_cols_full_span) :-
    region_spans_v([[1,2],[3,4]], 0, [0-1]).

:- end_tests(region_spans_v).

% Tests for region_cut_h/3

:- begin_tests(region_cut_h).

test(two_sections_from_one_sep) :-
    region_cut_h([[1,2],[0,0],[3,4],[5,6]], 0, [[[1,2]], [[3,4],[5,6]]]).

test(sep_at_start_one_section) :-
    region_cut_h([[0,0],[1,2],[3,4]], 0, [[[1,2],[3,4]]]).

test(no_sep_whole_grid) :-
    region_cut_h([[1,2],[3,4]], 0, [[[1,2],[3,4]]]).

:- end_tests(region_cut_h).

% Tests for region_cut_v/3

:- begin_tests(region_cut_v).

test(two_sections_from_one_sep_col) :-
    region_cut_v([[1,0,2],[3,0,4]], 0, [[[1],[3]], [[2],[4]]]).

test(no_sep_col_whole_grid) :-
    region_cut_v([[1,2],[3,4]], 0, [[[1,2],[3,4]]]).

test(three_sections_from_two_sep_cols) :-
    region_cut_v([[1,0,2,0,3]], 0, [[[1]], [[2]], [[3]]]).

:- end_tests(region_cut_v).

% Tests for region_sections/3

:- begin_tests(region_sections).

test(two_by_two_sections) :-
    region_sections([[1,0,2],[0,0,0],[3,0,4]], 0, [[[[1]],[[2]]], [[[3]],[[4]]]]).

test(only_h_sep) :-
    region_sections([[1,2],[0,0],[3,4]], 0, [[[[1,2]]], [[[3,4]]]]).

test(only_v_sep) :-
    region_sections([[1,0,2],[3,0,4]], 0, [[[[1],[3]], [[2],[4]]]]).

:- end_tests(region_sections).

% Tests for region_section_h/4

:- begin_tests(region_section_h).

test(first_section) :-
    region_section_h([[1,2],[0,0],[3,4]], 0, 1, R),
    R = [[1,2]].

test(second_section) :-
    region_section_h([[1,2],[0,0],[3,4]], 0, 2, R),
    R = [[3,4]].

test(no_sep_single_section) :-
    region_section_h([[1,2],[3,4]], 0, 1, R),
    R = [[1,2],[3,4]].

:- end_tests(region_section_h).

% Tests for region_section_v/4

:- begin_tests(region_section_v).

test(first_v_section) :-
    region_section_v([[1,0,2],[3,0,4]], 0, 1, R),
    R = [[1],[3]].

test(second_v_section) :-
    region_section_v([[1,0,2],[3,0,4]], 0, 2, R),
    R = [[2],[4]].

test(no_sep_col_single_section) :-
    region_section_v([[1,2],[3,4]], 0, 1, R),
    R = [[1,2],[3,4]].

:- end_tests(region_section_v).

% Tests for region_count_h/3

:- begin_tests(region_count_h).

test(two_sections) :-
    region_count_h([[1,2],[0,0],[3,4]], 0, 2).

test(three_sections) :-
    region_count_h([[1,2],[0,0],[3,4],[0,0],[5,6]], 0, 3).

test(no_sep_one_section) :-
    region_count_h([[1,2],[3,4]], 0, 1).

:- end_tests(region_count_h).

% Tests for region_count_v/3

:- begin_tests(region_count_v).

test(two_v_sections) :-
    region_count_v([[1,0,2],[3,0,4]], 0, 2).

test(three_v_sections) :-
    region_count_v([[1,0,2,0,3]], 0, 3).

test(no_sep_col_one_section) :-
    region_count_v([[1,2],[3,4]], 0, 1).

:- end_tests(region_count_v).

% Tests for region_region/5

:- begin_tests(region_region).

test(top_left_region) :-
    region_region([[1,0,2],[0,0,0],[3,0,4]], 0, 0, 0, R),
    R = [[1]].

test(bottom_right_region) :-
    region_region([[1,0,2],[0,0,0],[3,0,4]], 0, 2, 2, R),
    R = [[4]].

test(middle_region_three_by_three) :-
    region_region([[1,0,2],[0,0,0],[3,0,4]], 0, 2, 0, R),
    R = [[3]].

:- end_tests(region_region).
