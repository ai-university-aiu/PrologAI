:- use_module('../prolog/histogram').

:- begin_tests(histogram).

% hi_count/3 tests

% Count three occurrences of value 1 in a mixed list.
test(count_multiple) :-
    hi_count([1,2,1,3,1], 1, N),
    N = 3.

% Count of a value not present in the list is zero.
test(count_absent) :-
    hi_count([1,2,3], 4, N),
    N = 0.

% Count in a single-element list equals 1 for the matching value.
test(count_single) :-
    hi_count([5], 5, N),
    N = 1.

% hi_freq/2 tests

% Frequency table of a mixed list is sorted by value ascending.
test(freq_mixed) :-
    hi_freq([3,1,2,1,3,3], Pairs),
    Pairs = [1-2, 2-1, 3-3].

% Frequency table of an empty list is empty.
test(freq_empty) :-
    hi_freq([], Pairs),
    Pairs = [].

% Frequency table of a uniform list has one entry.
test(freq_uniform) :-
    hi_freq([5,5,5], Pairs),
    Pairs = [5-3].

% hi_mode/3 tests

% Mode of a list with a clear winner.
test(mode_clear) :-
    hi_mode([1,2,2,3], V, N),
    V = 2,
    N = 2.

% On ties in count, the smallest value wins.
test(mode_tie) :-
    hi_mode([1,1,2,2], V, N),
    V = 1,
    N = 2.

% Mode of a single-element list is that element.
test(mode_single) :-
    hi_mode([7], V, N),
    V = 7,
    N = 1.

% hi_rare/3 tests

% Rarest value has count 1.
test(rare_clear) :-
    hi_rare([1,2,2,3,3,3], V, N),
    V = 1,
    N = 1.

% On ties, the largest value is returned as the rarest.
test(rare_tie) :-
    hi_rare([1,1,2,2], V, N),
    V = 2,
    N = 2.

% Rare of a single-element list is that element.
test(rare_single) :-
    hi_rare([7], V, N),
    V = 7,
    N = 1.

% hi_unique_vals/2 tests

% Unique values are sorted ascending with duplicates removed.
test(unique_vals_mixed) :-
    hi_unique_vals([3,1,2,1,3], Vals),
    Vals = [1,2,3].

% Unique values of an empty list is empty.
test(unique_vals_empty) :-
    hi_unique_vals([], Vals),
    Vals = [].

% Unique values of a uniform list has one element.
test(unique_vals_uniform) :-
    hi_unique_vals([5,5,5], Vals),
    Vals = [5].

% hi_unique_count/2 tests

% Count of distinct values in a mixed list.
test(unique_count_mixed) :-
    hi_unique_count([1,1,2,3,3], N),
    N = 3.

% Count of distinct values in an empty list is zero.
test(unique_count_empty) :-
    hi_unique_count([], N),
    N = 0.

% Count of distinct values in a uniform list is one.
test(unique_count_uniform) :-
    hi_unique_count([7,7,7,7], N),
    N = 1.

% hi_sorted_by_freq/2 tests

% Sorted by frequency descending: most common first.
test(sorted_by_freq_desc) :-
    hi_sorted_by_freq([1,2,2,3,3,3], Pairs),
    Pairs = [3-3, 2-2, 1-1].

% On ties in count, smaller value appears first.
test(sorted_by_freq_tie) :-
    hi_sorted_by_freq([1,1,2,2], Pairs),
    Pairs = [1-2, 2-2].

% Single-element list produces one pair.
test(sorted_by_freq_single) :-
    hi_sorted_by_freq([5], Pairs),
    Pairs = [5-1].

% hi_top_n/3 tests

% Top 2 most frequent values from a list with 3 distinct values.
test(top_n_two) :-
    hi_top_n([1,2,2,3,3,3], 2, T),
    T = [3-3, 2-2].

% Top 1 from a list where all values are equally frequent (smallest wins).
test(top_n_tie) :-
    hi_top_n([1,2,3], 1, T),
    T = [1-1].

% Top 1 from a uniform list.
test(top_n_uniform) :-
    hi_top_n([5,5,5], 1, T),
    T = [5-3].

% hi_has_value/2 tests

% A value present in the list is found.
test(has_value_present) :-
    hi_has_value([1,2,3], 2).

% A value absent from the list fails.
test(has_value_absent, [fail]) :-
    hi_has_value([1,2,3], 4).

% A single-element list contains that element.
test(has_value_single) :-
    hi_has_value([5], 5).

% hi_all_equal/2 tests

% A uniform list succeeds and binds V.
test(all_equal_yes) :-
    hi_all_equal([3,3,3], V),
    V = 3.

% A non-uniform list fails.
test(all_equal_no, [fail]) :-
    hi_all_equal([3,3,4], _).

% A single-element list succeeds vacuously.
test(all_equal_single) :-
    hi_all_equal([7], V),
    V = 7.

% hi_grid_freq/2 tests

% Frequency table of a 2x2 grid with three distinct values.
test(grid_freq_mixed) :-
    hi_grid_freq([[1,2],[2,3]], Pairs),
    Pairs = [1-1, 2-2, 3-1].

% Frequency table of a uniform grid has one entry.
test(grid_freq_uniform) :-
    hi_grid_freq([[0,0],[0,0]], Pairs),
    Pairs = [0-4].

% Frequency table of a single-row grid.
test(grid_freq_single_row) :-
    hi_grid_freq([[1,2,3]], Pairs),
    Pairs = [1-1, 2-1, 3-1].

% hi_grid_mode/3 tests

% Most frequent color in a 2x2 grid with a clear winner.
test(grid_mode_clear) :-
    hi_grid_mode([[1,2],[2,2]], C, N),
    C = 2,
    N = 3.

% On ties, smallest color wins.
test(grid_mode_tie) :-
    hi_grid_mode([[0,1],[0,1]], C, N),
    C = 0,
    N = 2.

% Single-cell grid.
test(grid_mode_single) :-
    hi_grid_mode([[5]], C, N),
    C = 5,
    N = 1.

% hi_grid_rare/3 tests

% Least frequent color in a 1x4 grid.
test(grid_rare_clear) :-
    hi_grid_rare([[1,2,2,2]], C, N),
    C = 1,
    N = 1.

% On ties, largest color is returned as the rarest.
test(grid_rare_tie) :-
    hi_grid_rare([[1,2],[3,4]], C, N),
    C = 4,
    N = 1.

% Single-cell grid.
test(grid_rare_single) :-
    hi_grid_rare([[5]], C, N),
    C = 5,
    N = 1.

% hi_rank/3 tests

% Most frequent value has rank 1.
test(rank_first) :-
    hi_rank([1,2,2,3,3,3], 3, R),
    R = 1.

% Least frequent value in a 3-value list has rank 3.
test(rank_last) :-
    hi_rank([1,2,2,3,3,3], 1, R),
    R = 3.

% Single distinct value always has rank 1.
test(rank_single) :-
    hi_rank([5,5,5], 5, R),
    R = 1.

:- end_tests(histogram).
