% test_region.pl - PLUnit tests for the region pack (Layer 92: rg_* predicates).
:- use_module('../prolog/region').

% Tests for rg_sep_rows/3

:- begin_tests(rg_sep_rows).

test(two_sep_rows) :-
    rg_sep_rows([[0,0,0],[1,2,3],[0,0,0]], 0, [0,2]).

test(one_sep_row) :-
    rg_sep_rows([[1,2],[0,0],[3,4],[0,0],[5,6]], 0, [1,3]).

test(no_sep_rows) :-
    rg_sep_rows([[1,2],[3,4]], 0, []).

:- end_tests(rg_sep_rows).

% Tests for rg_sep_cols/3

:- begin_tests(rg_sep_cols).

test(two_sep_cols) :-
    rg_sep_cols([[0,1,0],[0,2,0],[0,3,0]], 0, [0,2]).

test(one_sep_col) :-
    rg_sep_cols([[1,0,2],[3,0,4]], 0, [1]).

test(no_sep_cols) :-
    rg_sep_cols([[1,2],[3,4]], 0, []).

:- end_tests(rg_sep_cols).

% Tests for rg_is_sep_row/3

:- begin_tests(rg_is_sep_row).

test(all_sep) :-
    rg_is_sep_row([[1,2],[0,0],[3,4]], 1, 0).

test(not_sep) :-
    \+ rg_is_sep_row([[1,2],[0,1],[3,4]], 1, 0).

test(single_cell_sep) :-
    rg_is_sep_row([[5],[0],[7]], 1, 0).

:- end_tests(rg_is_sep_row).

% Tests for rg_is_sep_col/3

:- begin_tests(rg_is_sep_col).

test(col_all_sep) :-
    rg_is_sep_col([[0,1],[0,2],[0,3]], 0, 0).

test(col_not_sep) :-
    \+ rg_is_sep_col([[0,1],[1,2],[0,3]], 0, 0).

test(single_row_col_sep) :-
    rg_is_sep_col([[1,0,3]], 1, 0).

:- end_tests(rg_is_sep_col).

% Tests for rg_spans_h/3

:- begin_tests(rg_spans_h).

test(one_sep_two_sections) :-
    rg_spans_h([[1,2],[0,0],[3,4],[5,6]], 0, [0-0, 2-3]).

test(two_seps_three_sections) :-
    rg_spans_h([[1,2],[0,0],[3,4],[0,0],[5,6]], 0, [0-0, 2-2, 4-4]).

test(no_seps_one_full_span) :-
    rg_spans_h([[1,2],[3,4]], 0, [0-1]).

:- end_tests(rg_spans_h).

% Tests for rg_spans_v/3

:- begin_tests(rg_spans_v).

test(one_sep_col_two_sections) :-
    rg_spans_v([[1,0,2],[3,0,4]], 0, [0-0, 2-2]).

test(two_sep_cols_three_sections) :-
    rg_spans_v([[1,0,2,0,3]], 0, [0-0, 2-2, 4-4]).

test(no_sep_cols_full_span) :-
    rg_spans_v([[1,2],[3,4]], 0, [0-1]).

:- end_tests(rg_spans_v).

% Tests for rg_cut_h/3

:- begin_tests(rg_cut_h).

test(two_sections_from_one_sep) :-
    rg_cut_h([[1,2],[0,0],[3,4],[5,6]], 0, [[[1,2]], [[3,4],[5,6]]]).

test(sep_at_start_one_section) :-
    rg_cut_h([[0,0],[1,2],[3,4]], 0, [[[1,2],[3,4]]]).

test(no_sep_whole_grid) :-
    rg_cut_h([[1,2],[3,4]], 0, [[[1,2],[3,4]]]).

:- end_tests(rg_cut_h).

% Tests for rg_cut_v/3

:- begin_tests(rg_cut_v).

test(two_sections_from_one_sep_col) :-
    rg_cut_v([[1,0,2],[3,0,4]], 0, [[[1],[3]], [[2],[4]]]).

test(no_sep_col_whole_grid) :-
    rg_cut_v([[1,2],[3,4]], 0, [[[1,2],[3,4]]]).

test(three_sections_from_two_sep_cols) :-
    rg_cut_v([[1,0,2,0,3]], 0, [[[1]], [[2]], [[3]]]).

:- end_tests(rg_cut_v).

% Tests for rg_sections/3

:- begin_tests(rg_sections).

test(two_by_two_sections) :-
    rg_sections([[1,0,2],[0,0,0],[3,0,4]], 0, [[[[1]],[[2]]], [[[3]],[[4]]]]).

test(only_h_sep) :-
    rg_sections([[1,2],[0,0],[3,4]], 0, [[[[1,2]]], [[[3,4]]]]).

test(only_v_sep) :-
    rg_sections([[1,0,2],[3,0,4]], 0, [[[[1],[3]], [[2],[4]]]]).

:- end_tests(rg_sections).

% Tests for rg_section_h/4

:- begin_tests(rg_section_h).

test(first_section) :-
    rg_section_h([[1,2],[0,0],[3,4]], 0, 1, R),
    R = [[1,2]].

test(second_section) :-
    rg_section_h([[1,2],[0,0],[3,4]], 0, 2, R),
    R = [[3,4]].

test(no_sep_single_section) :-
    rg_section_h([[1,2],[3,4]], 0, 1, R),
    R = [[1,2],[3,4]].

:- end_tests(rg_section_h).

% Tests for rg_section_v/4

:- begin_tests(rg_section_v).

test(first_v_section) :-
    rg_section_v([[1,0,2],[3,0,4]], 0, 1, R),
    R = [[1],[3]].

test(second_v_section) :-
    rg_section_v([[1,0,2],[3,0,4]], 0, 2, R),
    R = [[2],[4]].

test(no_sep_col_single_section) :-
    rg_section_v([[1,2],[3,4]], 0, 1, R),
    R = [[1,2],[3,4]].

:- end_tests(rg_section_v).

% Tests for rg_count_h/3

:- begin_tests(rg_count_h).

test(two_sections) :-
    rg_count_h([[1,2],[0,0],[3,4]], 0, 2).

test(three_sections) :-
    rg_count_h([[1,2],[0,0],[3,4],[0,0],[5,6]], 0, 3).

test(no_sep_one_section) :-
    rg_count_h([[1,2],[3,4]], 0, 1).

:- end_tests(rg_count_h).

% Tests for rg_count_v/3

:- begin_tests(rg_count_v).

test(two_v_sections) :-
    rg_count_v([[1,0,2],[3,0,4]], 0, 2).

test(three_v_sections) :-
    rg_count_v([[1,0,2,0,3]], 0, 3).

test(no_sep_col_one_section) :-
    rg_count_v([[1,2],[3,4]], 0, 1).

:- end_tests(rg_count_v).

% Tests for rg_region/5

:- begin_tests(rg_region).

test(top_left_region) :-
    rg_region([[1,0,2],[0,0,0],[3,0,4]], 0, 0, 0, R),
    R = [[1]].

test(bottom_right_region) :-
    rg_region([[1,0,2],[0,0,0],[3,0,4]], 0, 2, 2, R),
    R = [[4]].

test(middle_region_three_by_three) :-
    rg_region([[1,0,2],[0,0,0],[3,0,4]], 0, 2, 0, R),
    R = [[3]].

:- end_tests(rg_region).
