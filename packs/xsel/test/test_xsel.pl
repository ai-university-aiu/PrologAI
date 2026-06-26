:- use_module('../prolog/xsel').

:- begin_tests(xsel).

% --- xs_cells_lt ---

test(cells_lt_basic) :-
    xs_cells_lt([[1,2],[3,4]], 3, Cs),
    Cs = [0-0, 0-1].

test(cells_lt_zeros) :-
    xs_cells_lt([[0,5],[5,0]], 1, Cs),
    Cs = [0-0, 1-1].

test(cells_lt_none) :-
    xs_cells_lt([[3,3],[3,3]], 3, Cs),
    Cs = [].

% --- xs_cells_gt ---

test(cells_gt_basic) :-
    xs_cells_gt([[1,2],[3,4]], 2, Cs),
    Cs = [1-0, 1-1].

test(cells_gt_corners) :-
    xs_cells_gt([[5,0],[0,5]], 4, Cs),
    Cs = [0-0, 1-1].

test(cells_gt_none) :-
    xs_cells_gt([[1,1],[1,1]], 5, Cs),
    Cs = [].

% --- xs_cells_le ---

test(cells_le_basic) :-
    xs_cells_le([[1,2],[3,4]], 2, Cs),
    Cs = [0-0, 0-1].

test(cells_le_two) :-
    xs_cells_le([[0,1],[2,3]], 1, Cs),
    Cs = [0-0, 0-1].

test(cells_le_none) :-
    xs_cells_le([[5,5],[5,5]], 4, Cs),
    Cs = [].

% --- xs_cells_ge ---

test(cells_ge_basic) :-
    xs_cells_ge([[1,2],[3,4]], 3, Cs),
    Cs = [1-0, 1-1].

test(cells_ge_equal) :-
    xs_cells_ge([[0,5],[5,0]], 5, Cs),
    Cs = [0-1, 1-0].

test(cells_ge_none) :-
    xs_cells_ge([[1,1],[1,1]], 2, Cs),
    Cs = [].

% --- xs_cells_between ---

test(cells_between_mid) :-
    xs_cells_between([[0,1],[2,3]], 1, 2, Cs),
    Cs = [0-1, 1-0].

test(cells_between_all) :-
    xs_cells_between([[1,2],[3,4]], 1, 4, Cs),
    Cs = [0-0, 0-1, 1-0, 1-1].

test(cells_between_none) :-
    xs_cells_between([[0,5],[5,0]], 2, 4, Cs),
    Cs = [].

% --- xs_cells_ne ---

test(cells_ne_basic) :-
    xs_cells_ne([[0,1],[1,0]], 0, Cs),
    Cs = [0-1, 1-0].

test(cells_ne_all_same) :-
    xs_cells_ne([[1,1],[1,1]], 1, Cs),
    Cs = [].

test(cells_ne_absent) :-
    xs_cells_ne([[0,1],[2,3]], 9, Cs),
    Cs = [0-0, 0-1, 1-0, 1-1].

% --- xs_max_cells ---

test(max_cells_unique) :-
    xs_max_cells([[1,2],[3,4]], Cs),
    Cs = [1-1].

test(max_cells_two) :-
    xs_max_cells([[5,0],[0,5]], Cs),
    Cs = [0-0, 1-1].

test(max_cells_all_equal) :-
    xs_max_cells([[3,3],[3,3]], Cs),
    Cs = [0-0, 0-1, 1-0, 1-1].

% --- xs_min_cells ---

test(min_cells_unique) :-
    xs_min_cells([[1,2],[3,4]], Cs),
    Cs = [0-0].

test(min_cells_two) :-
    xs_min_cells([[0,5],[5,0]], Cs),
    Cs = [0-0, 1-1].

test(min_cells_all_equal) :-
    xs_min_cells([[3,3],[3,3]], Cs),
    Cs = [0-0, 0-1, 1-0, 1-1].

% --- xs_threshold ---

test(threshold_mixed) :-
    xs_threshold([[1,3],[5,2]], 3, 1, 0, G),
    G = [[0,1],[1,0]].

test(threshold_all_below) :-
    xs_threshold([[0,0],[0,0]], 1, 1, 0, G),
    G = [[0,0],[0,0]].

test(threshold_all_above) :-
    xs_threshold([[5,5],[5,5]], 3, 9, 0, G),
    G = [[9,9],[9,9]].

% --- xs_replace_lt ---

test(replace_lt_basic) :-
    xs_replace_lt([[1,3],[2,4]], 3, 0, G),
    G = [[0,3],[0,4]].

test(replace_lt_none) :-
    xs_replace_lt([[5,5],[5,5]], 3, 0, G),
    G = [[5,5],[5,5]].

test(replace_lt_all) :-
    xs_replace_lt([[1,2],[3,4]], 5, 0, G),
    G = [[0,0],[0,0]].

% --- xs_replace_gt ---

test(replace_gt_one) :-
    xs_replace_gt([[1,3],[5,2]], 3, 0, G),
    G = [[1,3],[0,2]].

test(replace_gt_none) :-
    xs_replace_gt([[5,5],[5,5]], 6, 0, G),
    G = [[5,5],[5,5]].

test(replace_gt_all) :-
    xs_replace_gt([[1,2],[3,4]], 0, 0, G),
    G = [[0,0],[0,0]].

% --- xs_rank_vals ---

test(rank_vals_mixed) :-
    xs_rank_vals([[3,1],[2,1]], Vs),
    Vs = [1, 2, 3].

test(rank_vals_uniform) :-
    xs_rank_vals([[0,0],[0,0]], Vs),
    Vs = [0].

test(rank_vals_four) :-
    xs_rank_vals([[5,3],[1,7]], Vs),
    Vs = [1, 3, 5, 7].

% --- xs_val_rank ---

test(val_rank_min) :-
    xs_val_rank([[3,1],[2,1]], 1, R),
    R = 0.

test(val_rank_max) :-
    xs_val_rank([[3,1],[2,1]], 3, R),
    R = 2.

test(val_rank_largest) :-
    xs_val_rank([[5,3],[1,7]], 7, R),
    R = 3.

% --- xs_rank_grid ---

test(rank_grid_basic) :-
    xs_rank_grid([[3,1],[2,1]], G),
    G = [[2,0],[1,0]].

test(rank_grid_uniform) :-
    xs_rank_grid([[0,0],[0,0]], G),
    G = [[0,0],[0,0]].

test(rank_grid_four_vals) :-
    xs_rank_grid([[5,3],[1,7]], G),
    G = [[2,1],[0,3]].

:- end_tests(xsel).
