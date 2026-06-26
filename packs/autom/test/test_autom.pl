:- use_module('../prolog/autom').

:- begin_tests(autom).

% --- at_count_nbrs_4 ---

test(count_nbrs_4_center) :-
    at_count_nbrs_4([[0,0,0],[0,1,0],[0,0,0]], 0, CGrid),
    CGrid = [[2,2,2],[2,4,2],[2,2,2]].

test(count_nbrs_4_diag) :-
    at_count_nbrs_4([[1,0],[0,1]], 1, CGrid),
    CGrid = [[0,2],[2,0]].

test(count_nbrs_4_none) :-
    at_count_nbrs_4([[0,0],[0,0]], 1, CGrid),
    CGrid = [[0,0],[0,0]].

% --- at_count_nbrs_8 ---

test(count_nbrs_8_ring) :-
    at_count_nbrs_8([[0,0,0],[0,1,0],[0,0,0]], 1, CGrid),
    CGrid = [[1,1,1],[1,0,1],[1,1,1]].

test(count_nbrs_8_uniform) :-
    at_count_nbrs_8([[1,1],[1,1]], 1, CGrid),
    CGrid = [[3,3],[3,3]].

test(count_nbrs_8_none) :-
    at_count_nbrs_8([[0,0],[0,0]], 1, CGrid),
    CGrid = [[0,0],[0,0]].

% --- at_count_same_4 ---

test(count_same_4_uniform) :-
    at_count_same_4([[1,1],[1,1]], CGrid),
    CGrid = [[2,2],[2,2]].

test(count_same_4_checker) :-
    at_count_same_4([[0,1],[1,0]], CGrid),
    CGrid = [[0,0],[0,0]].

test(count_same_4_3x3_uniform) :-
    at_count_same_4([[2,2,2],[2,2,2],[2,2,2]], CGrid),
    CGrid = [[2,3,2],[3,4,3],[2,3,2]].

% --- at_count_same_8 ---

test(count_same_8_uniform) :-
    at_count_same_8([[5,5],[5,5]], CGrid),
    CGrid = [[3,3],[3,3]].

test(count_same_8_3x3) :-
    at_count_same_8([[2,2,2],[2,2,2],[2,2,2]], CGrid),
    CGrid = [[3,5,3],[5,8,5],[3,5,3]].

test(count_same_8_none) :-
    at_count_same_8([[0,1],[2,3]], CGrid),
    CGrid = [[0,0],[0,0]].

% --- at_any_nbr_4 ---

test(any_nbr_4_cross) :-
    at_any_nbr_4([[0,0,0],[0,1,0],[0,0,0]], 1, BGrid),
    BGrid = [[0,1,0],[1,0,1],[0,1,0]].

test(any_nbr_4_none) :-
    at_any_nbr_4([[0,0],[0,0]], 1, BGrid),
    BGrid = [[0,0],[0,0]].

test(any_nbr_4_all) :-
    at_any_nbr_4([[1,1],[1,1]], 1, BGrid),
    BGrid = [[1,1],[1,1]].

% --- at_all_nbrs_4 ---

test(all_nbrs_4_corners) :-
    at_all_nbrs_4([[1,1,1],[1,0,1],[1,1,1]], 1, BGrid),
    BGrid = [[1,0,1],[0,1,0],[1,0,1]].

test(all_nbrs_4_none) :-
    at_all_nbrs_4([[0,0],[0,0]], 1, BGrid),
    BGrid = [[0,0],[0,0]].

test(all_nbrs_4_uniform) :-
    at_all_nbrs_4([[1,1],[1,1]], 1, BGrid),
    BGrid = [[1,1],[1,1]].

% --- at_any_nbr_8 ---

test(any_nbr_8_center) :-
    at_any_nbr_8([[0,0,0],[0,1,0],[0,0,0]], 1, BGrid),
    BGrid = [[1,1,1],[1,0,1],[1,1,1]].

test(any_nbr_8_none) :-
    at_any_nbr_8([[0,0],[0,0]], 1, BGrid),
    BGrid = [[0,0],[0,0]].

test(any_nbr_8_all) :-
    at_any_nbr_8([[1,1],[1,1]], 1, BGrid),
    BGrid = [[1,1],[1,1]].

% --- at_all_nbrs_8 ---

test(all_nbrs_8_none) :-
    at_all_nbrs_8([[0,0],[0,0]], 1, BGrid),
    BGrid = [[0,0],[0,0]].

test(all_nbrs_8_uniform) :-
    at_all_nbrs_8([[1,1],[1,1]], 1, BGrid),
    BGrid = [[1,1],[1,1]].

test(all_nbrs_8_mixed) :-
    at_all_nbrs_8([[1,1,1],[1,0,1],[1,1,1]], 1, BGrid),
    BGrid = [[0,0,0],[0,1,0],[0,0,0]].

% --- at_isolated_4 ---

test(isolated_4_center) :-
    at_isolated_4([[0,0,0],[0,1,0],[0,0,0]], 1, Cells),
    Cells = [1-1].

test(isolated_4_adjacent_not_isolated) :-
    at_isolated_4([[1,1],[0,0]], 1, Cells),
    Cells = [].

test(isolated_4_two_isolated) :-
    at_isolated_4([[1,0,1],[0,0,0]], 1, Cells),
    Cells = [0-0, 0-2].

% --- at_isolated_8 ---

test(isolated_8_center) :-
    at_isolated_8([[0,0,0,0,0],[0,0,0,0,0],[0,0,1,0,0],[0,0,0,0,0],[0,0,0,0,0]], 1, Cells),
    Cells = [2-2].

test(isolated_8_diagonal_not_isolated) :-
    at_isolated_8([[1,0],[0,1]], 1, Cells),
    Cells = [].

test(isolated_8_apart) :-
    at_isolated_8([[1,0,0,1]], 1, Cells),
    Cells = [0-0, 0-3].

% --- at_birth_4 ---

test(birth_4_center) :-
    at_birth_4([[0,1,0],[1,0,1],[0,1,0]], 0, 1, 4, Grid2),
    Grid2 = [[0,1,0],[1,1,1],[0,1,0]].

test(birth_4_no_live) :-
    at_birth_4([[0,0],[0,0]], 0, 1, 2, Grid2),
    Grid2 = [[0,0],[0,0]].

test(birth_4_n1) :-
    at_birth_4([[0,1,0],[0,0,0]], 0, 1, 1, Grid2),
    Grid2 = [[1,1,1],[0,1,0]].

% --- at_birth_8 ---

test(birth_8_three_nbrs) :-
    at_birth_8([[0,1,1],[1,0,0],[0,0,0]], 0, 1, 3, Grid2),
    Grid2 = [[0,1,1],[1,1,0],[0,0,0]].

test(birth_8_no_births) :-
    at_birth_8([[0,0],[0,0]], 0, 1, 1, Grid2),
    Grid2 = [[0,0],[0,0]].

test(birth_8_one_nbr_born) :-
    at_birth_8([[0,0,0],[0,0,0],[0,0,1]], 0, 1, 1, Grid2),
    Grid2 = [[0,0,0],[0,1,1],[0,1,1]].

% --- at_majority_4 ---

test(majority_4_uniform) :-
    at_majority_4([[2,2],[2,2]], 0, Grid2),
    Grid2 = [[2,2],[2,2]].

test(majority_4_wins) :-
    at_majority_4([[1,1],[1,0]], 0, Grid2),
    Grid2 = [[1,1],[1,1]].

test(majority_4_all_zero) :-
    at_majority_4([[0,0,0],[0,1,0],[0,0,0]], 0, Grid2),
    Grid2 = [[0,0,0],[0,0,0],[0,0,0]].

% --- at_step_gol ---

test(gol_lone_cell_dies) :-
    at_step_gol([[0,0,0],[0,1,0],[0,0,0]], Grid2),
    Grid2 = [[0,0,0],[0,0,0],[0,0,0]].

test(gol_blinker_h) :-
    at_step_gol([[0,0,0],[1,1,1],[0,0,0]], Grid2),
    Grid2 = [[0,1,0],[0,1,0],[0,1,0]].

test(gol_block_stable) :-
    at_step_gol([[0,0,0,0],[0,1,1,0],[0,1,1,0],[0,0,0,0]], Grid2),
    Grid2 = [[0,0,0,0],[0,1,1,0],[0,1,1,0],[0,0,0,0]].

:- end_tests(autom).
