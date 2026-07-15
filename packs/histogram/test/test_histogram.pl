:- use_module('../prolog/histogram').

:- begin_tests(histogram).

% histogram_count/3 tests

% Count three occurrences of value 1 in a mixed list.
test(count_multiple) :-
    histogram_count([1,2,1,3,1], 1, N),
    N = 3.

% Count of a value not present in the list is zero.
test(count_absent) :-
    histogram_count([1,2,3], 4, N),
    N = 0.

% Count in a single-element list equals 1 for the matching value.
test(count_single) :-
    histogram_count([5], 5, N),
    N = 1.

% histogram_freq/2 tests

% Frequency table of a mixed list is sorted by value ascending.
test(freq_mixed) :-
    histogram_freq([3,1,2,1,3,3], Pairs),
    Pairs = [1-2, 2-1, 3-3].

% Frequency table of an empty list is empty.
test(freq_empty) :-
    histogram_freq([], Pairs),
    Pairs = [].

% Frequency table of a uniform list has one entry.
test(freq_uniform) :-
    histogram_freq([5,5,5], Pairs),
    Pairs = [5-3].

% histogram_mode/3 tests

% Mode of a list with a clear winner.
test(mode_clear) :-
    histogram_mode([1,2,2,3], V, N),
    V = 2,
    N = 2.

% On ties in count, the smallest value wins.
test(mode_tie) :-
    histogram_mode([1,1,2,2], V, N),
    V = 1,
    N = 2.

% Mode of a single-element list is that element.
test(mode_single) :-
    histogram_mode([7], V, N),
    V = 7,
    N = 1.

% histogram_rare/3 tests

% Rarest value has count 1.
test(rare_clear) :-
    histogram_rare([1,2,2,3,3,3], V, N),
    V = 1,
    N = 1.

% On ties, the largest value is returned as the rarest.
test(rare_tie) :-
    histogram_rare([1,1,2,2], V, N),
    V = 2,
    N = 2.

% Rare of a single-element list is that element.
test(rare_single) :-
    histogram_rare([7], V, N),
    V = 7,
    N = 1.

% histogram_unique_vals/2 tests

% Unique values are sorted ascending with duplicates removed.
test(unique_vals_mixed) :-
    histogram_unique_vals([3,1,2,1,3], Vals),
    Vals = [1,2,3].

% Unique values of an empty list is empty.
test(unique_vals_empty) :-
    histogram_unique_vals([], Vals),
    Vals = [].

% Unique values of a uniform list has one element.
test(unique_vals_uniform) :-
    histogram_unique_vals([5,5,5], Vals),
    Vals = [5].

% histogram_unique_count/2 tests

% Count of distinct values in a mixed list.
test(unique_count_mixed) :-
    histogram_unique_count([1,1,2,3,3], N),
    N = 3.

% Count of distinct values in an empty list is zero.
test(unique_count_empty) :-
    histogram_unique_count([], N),
    N = 0.

% Count of distinct values in a uniform list is one.
test(unique_count_uniform) :-
    histogram_unique_count([7,7,7,7], N),
    N = 1.

% histogram_sorted_by_freq/2 tests

% Sorted by frequency descending: most common first.
test(sorted_by_freq_desc) :-
    histogram_sorted_by_freq([1,2,2,3,3,3], Pairs),
    Pairs = [3-3, 2-2, 1-1].

% On ties in count, smaller value appears first.
test(sorted_by_freq_tie) :-
    histogram_sorted_by_freq([1,1,2,2], Pairs),
    Pairs = [1-2, 2-2].

% Single-element list produces one pair.
test(sorted_by_freq_single) :-
    histogram_sorted_by_freq([5], Pairs),
    Pairs = [5-1].

% histogram_top_n/3 tests

% Top 2 most frequent values from a list with 3 distinct values.
test(top_n_two) :-
    histogram_top_n([1,2,2,3,3,3], 2, T),
    T = [3-3, 2-2].

% Top 1 from a list where all values are equally frequent (smallest wins).
test(top_n_tie) :-
    histogram_top_n([1,2,3], 1, T),
    T = [1-1].

% Top 1 from a uniform list.
test(top_n_uniform) :-
    histogram_top_n([5,5,5], 1, T),
    T = [5-3].

% histogram_has_value/2 tests

% A value present in the list is found.
test(has_value_present) :-
    histogram_has_value([1,2,3], 2).

% A value absent from the list fails.
test(has_value_absent, [fail]) :-
    histogram_has_value([1,2,3], 4).

% A single-element list contains that element.
test(has_value_single) :-
    histogram_has_value([5], 5).

% histogram_all_equal/2 tests

% A uniform list succeeds and binds V.
test(all_equal_yes) :-
    histogram_all_equal([3,3,3], V),
    V = 3.

% A non-uniform list fails.
test(all_equal_no, [fail]) :-
    histogram_all_equal([3,3,4], _).

% A single-element list succeeds vacuously.
test(all_equal_single) :-
    histogram_all_equal([7], V),
    V = 7.

% histogram_grid_freq/2 tests

% Frequency table of a 2x2 grid with three distinct values.
test(grid_freq_mixed) :-
    histogram_grid_freq([[1,2],[2,3]], Pairs),
    Pairs = [1-1, 2-2, 3-1].

% Frequency table of a uniform grid has one entry.
test(grid_freq_uniform) :-
    histogram_grid_freq([[0,0],[0,0]], Pairs),
    Pairs = [0-4].

% Frequency table of a single-row grid.
test(grid_freq_single_row) :-
    histogram_grid_freq([[1,2,3]], Pairs),
    Pairs = [1-1, 2-1, 3-1].

% histogram_grid_mode/3 tests

% Most frequent color in a 2x2 grid with a clear winner.
test(grid_mode_clear) :-
    histogram_grid_mode([[1,2],[2,2]], C, N),
    C = 2,
    N = 3.

% On ties, smallest color wins.
test(grid_mode_tie) :-
    histogram_grid_mode([[0,1],[0,1]], C, N),
    C = 0,
    N = 2.

% Single-cell grid.
test(grid_mode_single) :-
    histogram_grid_mode([[5]], C, N),
    C = 5,
    N = 1.

% histogram_grid_rare/3 tests

% Least frequent color in a 1x4 grid.
test(grid_rare_clear) :-
    histogram_grid_rare([[1,2,2,2]], C, N),
    C = 1,
    N = 1.

% On ties, largest color is returned as the rarest.
test(grid_rare_tie) :-
    histogram_grid_rare([[1,2],[3,4]], C, N),
    C = 4,
    N = 1.

% Single-cell grid.
test(grid_rare_single) :-
    histogram_grid_rare([[5]], C, N),
    C = 5,
    N = 1.

% histogram_rank/3 tests

% Most frequent value has rank 1.
test(rank_first) :-
    histogram_rank([1,2,2,3,3,3], 3, R),
    R = 1.

% Least frequent value in a 3-value list has rank 3.
test(rank_last) :-
    histogram_rank([1,2,2,3,3,3], 1, R),
    R = 3.

% Single distinct value always has rank 1.
test(rank_single) :-
    histogram_rank([5,5,5], 5, R),
    R = 1.

:- end_tests(histogram).
