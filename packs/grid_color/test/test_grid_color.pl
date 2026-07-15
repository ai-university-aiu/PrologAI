:- use_module('../prolog/grid_color').

% Grid fixtures
% 3x3 grid with 4 r cells, 4 x cells, 1 b cell
g3x3_mixed([[r,r,x],[r,x,b],[x,x,r]]).
% Uniform grid
g3x3_all_r([[r,r,r],[r,r,r],[r,r,r]]).
% Two colors equally
g2x4_equal([[r,r,x,x],[r,r,x,x]]).
% Single cell
g1x1_r([[r]]).
% 3x3 with r region and x background
g3x3_rb([[r,r,x],[r,r,x],[x,x,x]]).
% Small grid for recolor tests
g2x2([[a,b],[b,a]]).
% Grid for color_map
g2x3_map([[r,g,b],[g,r,b]]).
% Empty (0 rows) - edge case handled by H=0
g_empty([]).

:- begin_tests(grid_color).

% --- grid_color_count ---
test(count_color_present, []) :-
    g3x3_mixed(G),
    grid_color_count(G, r, N),
    N =:= 4.

test(count_color_absent, []) :-
    g3x3_mixed(G),
    grid_color_count(G, g, N),
    N =:= 0.

test(count_background, []) :-
    g3x3_mixed(G),
    grid_color_count(G, x, N),
    N =:= 4.

% --- grid_color_histogram ---
test(histogram_correct_pairs, []) :-
    G = [[r,r],[r,x]],
    grid_color_histogram(G, Pairs),
    memberchk(r-3, Pairs),
    memberchk(x-1, Pairs).

test(histogram_single_color, []) :-
    g3x3_all_r(G),
    grid_color_histogram(G, Pairs),
    Pairs = [r-9].

test(histogram_sorted_by_color, []) :-
    G = [[b,a],[c,a]],
    grid_color_histogram(G, Pairs),
    Pairs = [a-2, b-1, c-1].

% --- grid_color_most_frequent ---
test(most_frequent_r, []) :-
    G = [[r,r,r],[r,x,x],[r,r,r]],
    grid_color_most_frequent(G, r).

test(most_frequent_uniform, []) :-
    g3x3_all_r(G),
    grid_color_most_frequent(G, r).

% --- grid_color_least_frequent ---
test(least_frequent_b, []) :-
    g3x3_mixed(G),
    grid_color_least_frequent(G, b).

test(least_frequent_single, []) :-
    g1x1_r(G),
    grid_color_least_frequent(G, r).

% --- grid_color_unique_colors ---
test(unique_colors_3, []) :-
    g3x3_mixed(G),
    grid_color_unique_colors(G, Colors),
    Colors = [b, r, x].

test(unique_colors_1, []) :-
    g3x3_all_r(G),
    grid_color_unique_colors(G, [r]).

test(unique_colors_equal, []) :-
    g2x4_equal(G),
    grid_color_unique_colors(G, [r, x]).

% --- grid_color_color_cells ---
test(color_cells_positions, []) :-
    G = [[r,x],[x,r]],
    grid_color_color_cells(G, r, Cells),
    Cells = [0-0, 1-1].

test(color_cells_absent, []) :-
    g3x3_all_r(G),
    grid_color_color_cells(G, x, []).

test(color_cells_all, []) :-
    G = [[a,a],[a,a]],
    grid_color_color_cells(G, a, Cells),
    length(Cells, 4).

% --- grid_color_contains ---
test(contains_true, []) :-
    g3x3_mixed(G),
    grid_color_contains(G, b).

test(contains_false, [fail]) :-
    g3x3_all_r(G),
    grid_color_contains(G, x).

% --- grid_color_recolor ---
test(recolor_replaces_all, []) :-
    g2x2(G),
    grid_color_recolor(G, a, r, R),
    R = [[r,b],[b,r]].

test(recolor_absent_color_unchanged, []) :-
    g2x2(G),
    grid_color_recolor(G, z, r, G).

test(recolor_full_grid, []) :-
    g3x3_all_r(G),
    grid_color_recolor(G, r, x, R),
    grid_color_count(R, x, 9).

% --- grid_color_color_map ---
test(color_map_two_swaps, []) :-
    G = [[r,g],[g,r]],
    grid_color_color_map(G, [r-b, g-r], R),
    R = [[b,r],[r,b]].

test(color_map_partial_mapping, []) :-
    g2x3_map(G),
    grid_color_color_map(G, [r-x], R),
    grid_color_count(R, x, 2),
    grid_color_count(R, r, 0).

test(color_map_empty_map, []) :-
    g2x2(G),
    grid_color_color_map(G, [], G).

% --- grid_color_threshold ---
test(threshold_select_r, []) :-
    g3x3_mixed(G),
    grid_color_threshold(G, [r], sel, bg, R),
    grid_color_count(R, sel, 4),
    grid_color_count(R, bg, 5).

test(threshold_select_multiple, []) :-
    g3x3_mixed(G),
    grid_color_threshold(G, [r, b], sel, bg, R),
    grid_color_count(R, sel, 5).

test(threshold_empty_select, []) :-
    g3x3_all_r(G),
    grid_color_threshold(G, [], sel, bg, R),
    grid_color_count(R, bg, 9).

% --- grid_color_dominant ---
test(dominant_non_bg, []) :-
    g3x3_rb(G),
    grid_color_dominant(G, x, r).

test(dominant_single_fg, []) :-
    G = [[x,r,x],[x,x,x],[x,x,x]],
    grid_color_dominant(G, x, r).

% --- grid_color_fraction ---
test(fraction_r_in_mixed, []) :-
    g3x3_mixed(G),
    grid_color_fraction(G, r, F),
    abs(F - 4.0/9.0) < 0.001.

test(fraction_all_r, []) :-
    g3x3_all_r(G),
    grid_color_fraction(G, r, F),
    F =:= 1.0.

test(fraction_absent_color, []) :-
    g3x3_all_r(G),
    grid_color_fraction(G, x, F),
    F =:= 0.0.

% --- grid_color_count_colors ---
test(count_colors_mixed, []) :-
    g3x3_mixed(G),
    grid_color_count_colors(G, N),
    N =:= 3.

test(count_colors_uniform, []) :-
    g3x3_all_r(G),
    grid_color_count_colors(G, 1).

% --- grid_color_sorted_by_freq ---
test(sorted_by_freq_mixed, []) :-
    G = [[r,r,r],[r,x,b],[x,x,x]],
    grid_color_sorted_by_freq(G, Colors),
    Colors = [r, x, b].

test(sorted_by_freq_uniform, []) :-
    g3x3_all_r(G),
    grid_color_sorted_by_freq(G, [r]).

% --- Combined / extra tests ---
test(count_then_fraction_consistent, []) :-
    g3x3_rb(G),
    grid_color_count(G, r, N),
    grid_color_fraction(G, r, F),
    F =:= float(N) / 9.0.

test(recolor_then_count, []) :-
    g3x3_mixed(G),
    grid_color_recolor(G, x, r, R),
    grid_color_count(R, x, 0),
    grid_color_count(R, r, 8).

test(threshold_then_unique_colors, []) :-
    g3x3_mixed(G),
    grid_color_threshold(G, [r, b], sel, bg, R),
    grid_color_unique_colors(R, Colors),
    Colors = [bg, sel].

test(color_map_then_histogram, []) :-
    G = [[r,g],[g,r]],
    grid_color_color_map(G, [r-x, g-x], R),
    grid_color_histogram(R, [x-4]).

test(dominant_after_recolor, []) :-
    g3x3_mixed(G),
    grid_color_recolor(G, b, r, R),
    grid_color_dominant(R, x, r).

test(color_cells_count_matches_gc_count, []) :-
    g3x3_rb(G),
    grid_color_color_cells(G, r, Cells),
    length(Cells, N),
    grid_color_count(G, r, N).

test(unique_colors_2_in_rb, []) :-
    g3x3_rb(G),
    grid_color_unique_colors(G, [r, x]).

test(count_colors_rb_is_2, []) :-
    g3x3_rb(G),
    grid_color_count_colors(G, 2).

:- end_tests(grid_color).
