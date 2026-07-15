:- use_module('../prolog/grid_histogram').

% Grid fixtures
% 3x3 checkerboard: alternating a and b
g3x3_ab([[a,b,a],[b,a,b],[a,b,a]]).
% 3x3 uniform: all r
g3x3_uni([[r,r,r],[r,r,r],[r,r,r]]).
% 3x3 all-distinct: each row has different colors
g3x3([[a,b,c],[d,e,f],[g,h,i]]).
% 2x3 with two colors per row
g2x3([[a,a,b],[b,b,a]]).
% 1x3 single row
g1x3([[a,b,a]]).
% 3x1 single column
g3x1([[a],[b],[a]]).

:- begin_tests(grid_histogram).

% --- grid_histogram_row_hist ---
test(row_hist_ab_r0, []) :-
    % Row 0 of g3x3_ab = [a,b,a]: a appears 2, b appears 1
    g3x3_ab(G), grid_histogram_row_hist(G, 0, [a-2, b-1]).

test(row_hist_uniform, []) :-
    % Row 0 of uniform grid = [r,r,r]: r appears 3
    g3x3_uni(G), grid_histogram_row_hist(G, 0, [r-3]).

test(row_hist_all_diff, []) :-
    % Row 0 of g3x3 = [a,b,c]: each appears 1
    g3x3(G), grid_histogram_row_hist(G, 0, [a-1, b-1, c-1]).

% --- grid_histogram_col_hist ---
test(col_hist_ab_c0, []) :-
    % Col 0 of g3x3_ab = [a,b,a]: a-2, b-1
    g3x3_ab(G), grid_histogram_col_hist(G, 0, [a-2, b-1]).

test(col_hist_ab_c1, []) :-
    % Col 1 of g3x3_ab = [b,a,b]: a-1, b-2
    g3x3_ab(G), grid_histogram_col_hist(G, 1, [a-1, b-2]).

test(col_hist_uniform, []) :-
    % Col 2 of uniform grid: r-3
    g3x3_uni(G), grid_histogram_col_hist(G, 2, [r-3]).

% --- grid_histogram_all_row_hists ---
test(all_row_hists_count, []) :-
    % 3 rows → 3 histograms
    g3x3_ab(G), grid_histogram_all_row_hists(G, H), length(H, 3).

test(all_row_hists_first, []) :-
    % First histogram is for row 0
    g3x3_ab(G), grid_histogram_all_row_hists(G, [H0|_]),
    H0 = [a-2, b-1].

% --- grid_histogram_all_col_hists ---
test(all_col_hists_count, []) :-
    % 3 cols → 3 histograms
    g3x3_ab(G), grid_histogram_all_col_hists(G, H), length(H, 3).

test(all_col_hists_first, []) :-
    % First histogram is for col 0
    g3x3_ab(G), grid_histogram_all_col_hists(G, [H0|_]),
    H0 = [a-2, b-1].

% --- grid_histogram_modal_row ---
test(modal_row_a, []) :-
    % Row 0 of g3x3_ab: a appears twice (more than b) → modal = a
    g3x3_ab(G), grid_histogram_modal_row(G, 0, a).

test(modal_row_uniform, []) :-
    % Row 0 of uniform grid: only r → modal = r
    g3x3_uni(G), grid_histogram_modal_row(G, 0, r).

test(modal_row_b, []) :-
    % Row 1 of g3x3_ab = [b,a,b]: b appears twice → modal = b
    g3x3_ab(G), grid_histogram_modal_row(G, 1, b).

% --- grid_histogram_modal_col ---
test(modal_col_a_c0, []) :-
    % Col 0 of g3x3_ab: a appears 2 → modal = a
    g3x3_ab(G), grid_histogram_modal_col(G, 0, a).

test(modal_col_b_c1, []) :-
    % Col 1 of g3x3_ab: b appears 2 → modal = b
    g3x3_ab(G), grid_histogram_modal_col(G, 1, b).

test(modal_col_uniform, []) :-
    % Col 0 of uniform grid → modal = r
    g3x3_uni(G), grid_histogram_modal_col(G, 0, r).

% --- grid_histogram_row_count ---
test(row_count_two, []) :-
    g3x3_ab(G), grid_histogram_row_count(G, 0, a, 2).

test(row_count_one, []) :-
    g3x3_ab(G), grid_histogram_row_count(G, 0, b, 1).

test(row_count_zero, []) :-
    g3x3_ab(G), grid_histogram_row_count(G, 0, x, 0).

test(row_count_uniform, []) :-
    g3x3_uni(G), grid_histogram_row_count(G, 1, r, 3).

% --- grid_histogram_col_count ---
test(col_count_two_a, []) :-
    g3x3_ab(G), grid_histogram_col_count(G, 0, a, 2).

test(col_count_two_b, []) :-
    g3x3_ab(G), grid_histogram_col_count(G, 1, b, 2).

% --- grid_histogram_row_entropy ---
test(row_entropy_two, []) :-
    % Row 0 of g3x3_ab has 2 distinct colors (a, b)
    g3x3_ab(G), grid_histogram_row_entropy(G, 0, 2).

test(row_entropy_one, []) :-
    % Row 0 of uniform grid has 1 distinct color
    g3x3_uni(G), grid_histogram_row_entropy(G, 0, 1).

test(row_entropy_three, []) :-
    % Row 0 of g3x3 = [a,b,c] has 3 distinct colors
    g3x3(G), grid_histogram_row_entropy(G, 0, 3).

% --- grid_histogram_col_entropy ---
test(col_entropy_two, []) :-
    % Col 0 of g3x3_ab = [a,b,a] has 2 distinct colors
    g3x3_ab(G), grid_histogram_col_entropy(G, 0, 2).

test(col_entropy_one, []) :-
    % Col 0 of uniform grid = [r,r,r] has 1 distinct color
    g3x3_uni(G), grid_histogram_col_entropy(G, 0, 1).

test(col_entropy_three, []) :-
    % Col 0 of g3x3 = [a,d,g] has 3 distinct colors
    g3x3(G), grid_histogram_col_entropy(G, 0, 3).

% --- grid_histogram_max_row ---
test(max_row_a, []) :-
    % g3x3_ab: rows 0 and 2 have 2 a's, row 1 has 1 a.
    % Ties won by highest index → Row 2.
    g3x3_ab(G), grid_histogram_max_row(G, a, 2).

test(max_row_uniform, []) :-
    % g3x3_uni: all rows have 3 r's. Highest index wins → Row 2.
    g3x3_uni(G), grid_histogram_max_row(G, r, 2).

test(max_row_b_row1, []) :-
    % g3x3_ab: row 1 has 2 b's (most). → Row 1.
    g3x3_ab(G), grid_histogram_max_row(G, b, 1).

% --- grid_histogram_min_row ---
test(min_row_a, []) :-
    % g3x3_ab: row 1 has 1 a (minimum > 0). → Row 1.
    g3x3_ab(G), grid_histogram_min_row(G, a, 1).

test(min_row_b, []) :-
    % g3x3_ab: rows 0 and 2 have 1 b each (minimum). Lowest index wins → Row 0.
    g3x3_ab(G), grid_histogram_min_row(G, b, 0).

test(min_row_fails, []) :-
    % Color x not in any row → fails.
    g3x3_ab(G), \+ grid_histogram_min_row(G, x, _).

% --- grid_histogram_rows_with ---
test(rows_with_a_ge2, []) :-
    % Rows where a appears >= 2 times: rows 0 and 2.
    g3x3_ab(G), grid_histogram_rows_with(G, a, 2, [0,2]).

test(rows_with_a_ge1, []) :-
    % All rows have at least 1 a: [0,1,2].
    g3x3_ab(G), grid_histogram_rows_with(G, a, 1, [0,1,2]).

test(rows_with_x_none, []) :-
    % No row has x → [].
    g3x3_ab(G), grid_histogram_rows_with(G, x, 1, []).

% --- grid_histogram_cols_with ---
test(cols_with_a_ge2, []) :-
    % Cols where a appears >= 2: cols 0 and 2 (each has [a,b,a]).
    g3x3_ab(G), grid_histogram_cols_with(G, a, 2, [0,2]).

test(cols_with_b_ge2, []) :-
    % Col 1 = [b,a,b] has 2 b's. Cols 0 and 2 have 1 b each.
    g3x3_ab(G), grid_histogram_cols_with(G, b, 2, [1]).

test(cols_with_x_none, []) :-
    g3x3_ab(G), grid_histogram_cols_with(G, x, 1, []).

% --- Combined tests ---
test(combined_entropy_matches_hist_len, []) :-
    % row_entropy equals length of row_hist
    g3x3(G),
    grid_histogram_row_hist(G, 0, Hist),
    grid_histogram_row_entropy(G, 0, N),
    length(Hist, N).

test(combined_modal_in_hist, []) :-
    % modal_row color appears in the histogram
    g3x3_ab(G),
    grid_histogram_row_hist(G, 0, Hist),
    grid_histogram_modal_row(G, 0, C),
    memberchk(C-_, Hist).

test(combined_count_sum_equals_width, []) :-
    % Sum of all counts in row hist equals width W
    g3x3_ab(G),
    grid_histogram_row_hist(G, 0, Hist),
    findall(N, member(_-N, Hist), Ns),
    sum_list(Ns, Total),
    Total =:= 3.

test(combined_rows_with_ge1_all, []) :-
    % For uniform grid, all rows have r with count >= 1
    g3x3_uni(G),
    grid_histogram_rows_with(G, r, 1, Rows),
    length(Rows, 3).

:- end_tests(grid_histogram).
