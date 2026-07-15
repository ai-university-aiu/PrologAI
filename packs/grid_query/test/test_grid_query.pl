:- use_module('../prolog/grid_query').
:- use_module(library(plunit)).

% Grid fixtures (list of rows, each row a list of color atoms).
% grid_2x2: 2-row, 2-column grid
%   r b
%   g r
grid_2x2([[r,b],[g,r]]).

% grid_3x3: 3-row, 3-column grid
%   r b g
%   b r b
%   g b r
grid_3x3([[r,b,g],[b,r,b],[g,b,r]]).

% grid_1x1: trivial grid
grid_1x1([[r]]).

% grid_uniform: all one color
grid_uniform([[r,r],[r,r]]).

% grid_ab: two-row grid to test diff
%   r b
%   g y
grid_ab([[r,b],[g,y]]).

% grid_ac: same as grid_ab but with one cell changed
%   r b
%   g r
grid_ac([[r,b],[g,r]]).

:- begin_tests(grid_query).

% grid_query_size: 2x2 grid
test(size_2x2) :-
    grid_2x2(G), grid_query_size(G, H, W), H == 2, W == 2.

% grid_query_size: 3x3 grid
test(size_3x3) :-
    grid_3x3(G), grid_query_size(G, H, W), H == 3, W == 3.

% grid_query_size: 1x1 grid
test(size_1x1) :-
    grid_1x1(G), grid_query_size(G, H, W), H == 1, W == 1.

% grid_query_size: empty grid
test(size_empty) :-
    grid_query_size([], H, W), H == 0, W == 0.

% grid_query_at: top-left cell
test(at_topleft) :-
    grid_2x2(G), grid_query_at(G, 0, 0, C), C == r.

% grid_query_at: top-right cell
test(at_topright) :-
    grid_2x2(G), grid_query_at(G, 0, 1, C), C == b.

% grid_query_at: bottom-left cell
test(at_bottomleft) :-
    grid_2x2(G), grid_query_at(G, 1, 0, C), C == g.

% grid_query_at: center of 3x3
test(at_center) :-
    grid_3x3(G), grid_query_at(G, 1, 1, C), C == r.

% grid_query_row: first row
test(row_first) :-
    grid_2x2(G), grid_query_row(G, 0, Row), Row == [r,b].

% grid_query_row: second row
test(row_second) :-
    grid_2x2(G), grid_query_row(G, 1, Row), Row == [g,r].

% grid_query_col: first column
test(col_first) :-
    grid_2x2(G), grid_query_col(G, 0, Col), Col == [r,g].

% grid_query_col: second column
test(col_second) :-
    grid_2x2(G), grid_query_col(G, 1, Col), Col == [b,r].

% grid_query_colors: two-color grid
test(colors_two) :-
    grid_2x2(G), grid_query_colors(G, Colors),
    msort(Colors, Sorted), Sorted == [b,g,r].

% grid_query_colors: uniform grid
test(colors_uniform) :-
    grid_uniform(G), grid_query_colors(G, Colors), Colors == [r].

% grid_query_colors: 1x1 grid
test(colors_single) :-
    grid_1x1(G), grid_query_colors(G, Colors), Colors == [r].

% grid_query_n_cells: count r cells in 2x2
test(n_cells_r) :-
    grid_2x2(G), grid_query_n_cells(G, r, N), N == 2.

% grid_query_n_cells: count b cells
test(n_cells_b) :-
    grid_2x2(G), grid_query_n_cells(G, b, N), N == 1.

% grid_query_n_cells: absent color is zero
test(n_cells_absent) :-
    grid_1x1(G), grid_query_n_cells(G, b, N), N == 0.

% grid_query_n_cells: uniform grid
test(n_cells_uniform) :-
    grid_uniform(G), grid_query_n_cells(G, r, N), N == 4.

% grid_query_most_freq_color: uniform grid
test(most_freq_uniform) :-
    grid_uniform(G), grid_query_most_freq_color(G, C), C == r.

% grid_query_most_freq_color: 3x3 with r most frequent
test(most_freq_3x3) :-
    grid_3x3(G), grid_query_most_freq_color(G, C), C == b.

% grid_query_region: full 2x2 is identity
test(region_full) :-
    grid_2x2(G), grid_query_region(G, 0, 0, 1, 1, Sub),
    Sub == [[r,b],[g,r]].

% grid_query_region: top row only
test(region_top_row) :-
    grid_3x3(G), grid_query_region(G, 0, 0, 0, 2, Sub),
    Sub == [[r,b,g]].

% grid_query_region: top-left 2x2 of 3x3
test(region_topleft_2x2) :-
    grid_3x3(G), grid_query_region(G, 0, 0, 1, 1, Sub),
    Sub == [[r,b],[b,r]].

% grid_query_region: single cell
test(region_single_cell) :-
    grid_3x3(G), grid_query_region(G, 1, 1, 1, 1, Sub),
    Sub == [[r]].

% grid_query_diff: identical grids have no diff
test(difference_identical) :-
    grid_2x2(G), grid_query_diff(G, G, Cells), Cells == [].

% grid_query_diff: one cell different
test(difference_one_cell) :-
    grid_ab(G1), grid_ac(G2),
    grid_query_diff(G1, G2, Cells),
    length(Cells, 1).

% grid_query_n_diff: zero for identical grids
test(n_diff_zero) :-
    grid_2x2(G), grid_query_n_diff(G, G, N), N == 0.

% grid_query_n_diff: one differing cell
test(n_diff_one) :-
    grid_ab(G1), grid_ac(G2), grid_query_n_diff(G1, G2, N), N == 1.

% grid_query_same_size: identical grids are same size
test(same_size_yes) :-
    grid_2x2(G), grid_query_same_size(G, G).

% grid_query_same_size: 2x2 vs 3x3 differ
test(same_size_no) :-
    grid_2x2(G1), grid_3x3(G2), \+ grid_query_same_size(G1, G2).

% grid_query_transpose: transpose 2x2
test(transpose_2x2) :-
    grid_2x2(G), grid_query_transpose(G, T),
    T == [[r,g],[b,r]].

% grid_query_transpose: transpose returns row-count of original as col-count
test(transpose_3x3_size) :-
    grid_3x3(G), grid_query_transpose(G, T),
    grid_query_size(T, H, W), H == 3, W == 3.

% grid_query_transpose: empty grid
test(transpose_empty) :-
    grid_query_transpose([], T), T == [].

% grid_query_replace: replace top-left cell
test(replace_topleft) :-
    grid_2x2(G), grid_query_replace(G, 0, 0, y, NewG),
    grid_query_at(NewG, 0, 0, y),
    grid_query_at(NewG, 0, 1, b).

% grid_query_replace: replace bottom-right cell
test(replace_bottomright) :-
    grid_2x2(G), grid_query_replace(G, 1, 1, y, NewG),
    grid_query_at(NewG, 1, 1, y),
    grid_query_at(NewG, 0, 0, r).

% grid_query_replace: 1x1 grid
test(replace_1x1) :-
    grid_1x1(G), grid_query_replace(G, 0, 0, b, NewG),
    NewG == [[b]].

% grid_query_fill_region: fill entire 2x2
test(fill_full) :-
    grid_2x2(G), grid_query_fill_region(G, 0, 0, 1, 1, y, NewG),
    NewG == [[y,y],[y,y]].

% grid_query_fill_region: fill single cell
test(fill_single_cell) :-
    grid_2x2(G), grid_query_fill_region(G, 0, 0, 0, 0, y, NewG),
    grid_query_at(NewG, 0, 0, y),
    grid_query_at(NewG, 0, 1, b),
    grid_query_at(NewG, 1, 0, g).

% grid_query_fill_region: fill first row
test(fill_first_row) :-
    grid_3x3(G), grid_query_fill_region(G, 0, 0, 0, 2, y, NewG),
    grid_query_row(NewG, 0, [y,y,y]),
    grid_query_row(NewG, 1, [b,r,b]).

% grid_query_col: third column of 3x3
test(col_third_3x3) :-
    grid_3x3(G), grid_query_col(G, 2, Col), Col == [g,b,r].

% grid_query_at: verify 3x3 corners
test(at_corners_3x3) :-
    grid_3x3(G),
    grid_query_at(G, 0, 0, r), grid_query_at(G, 0, 2, g),
    grid_query_at(G, 2, 0, g), grid_query_at(G, 2, 2, r).

% grid_query_n_cells: 3x3 b count
test(n_cells_b_3x3) :-
    grid_3x3(G), grid_query_n_cells(G, b, N), N == 4.

% grid_query_n_diff: all cells differ
test(n_diff_all) :-
    grid_query_n_diff([[r,r],[r,r]], [[b,b],[b,b]], N), N == 4.

% grid_query_region: right column of 3x3 as region
test(region_right_col) :-
    grid_3x3(G), grid_query_region(G, 0, 2, 2, 2, Sub),
    Sub == [[g],[b],[r]].

:- end_tests(grid_query).
