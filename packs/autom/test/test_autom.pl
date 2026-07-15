:- use_module('../prolog/autom').

:- begin_tests(autom).

% --- autom_count_nbrs_4 ---

test(count_nbrs_4_center) :-
    autom_count_nbrs_4([[0,0,0],[0,1,0],[0,0,0]], 0, CGrid),
    CGrid = [[2,2,2],[2,4,2],[2,2,2]].

test(count_nbrs_4_diag) :-
    autom_count_nbrs_4([[1,0],[0,1]], 1, CGrid),
    CGrid = [[0,2],[2,0]].

test(count_nbrs_4_none) :-
    autom_count_nbrs_4([[0,0],[0,0]], 1, CGrid),
    CGrid = [[0,0],[0,0]].

% --- autom_count_nbrs_8 ---

test(count_nbrs_8_ring) :-
    autom_count_nbrs_8([[0,0,0],[0,1,0],[0,0,0]], 1, CGrid),
    CGrid = [[1,1,1],[1,0,1],[1,1,1]].

test(count_nbrs_8_uniform) :-
    autom_count_nbrs_8([[1,1],[1,1]], 1, CGrid),
    CGrid = [[3,3],[3,3]].

test(count_nbrs_8_none) :-
    autom_count_nbrs_8([[0,0],[0,0]], 1, CGrid),
    CGrid = [[0,0],[0,0]].

% --- autom_count_same_4 ---

test(count_same_4_uniform) :-
    autom_count_same_4([[1,1],[1,1]], CGrid),
    CGrid = [[2,2],[2,2]].

test(count_same_4_checker) :-
    autom_count_same_4([[0,1],[1,0]], CGrid),
    CGrid = [[0,0],[0,0]].

test(count_same_4_3x3_uniform) :-
    autom_count_same_4([[2,2,2],[2,2,2],[2,2,2]], CGrid),
    CGrid = [[2,3,2],[3,4,3],[2,3,2]].

% --- autom_count_same_8 ---

test(count_same_8_uniform) :-
    autom_count_same_8([[5,5],[5,5]], CGrid),
    CGrid = [[3,3],[3,3]].

test(count_same_8_3x3) :-
    autom_count_same_8([[2,2,2],[2,2,2],[2,2,2]], CGrid),
    CGrid = [[3,5,3],[5,8,5],[3,5,3]].

test(count_same_8_none) :-
    autom_count_same_8([[0,1],[2,3]], CGrid),
    CGrid = [[0,0],[0,0]].

% --- autom_any_nbr_4 ---

test(any_nbr_4_cross) :-
    autom_any_nbr_4([[0,0,0],[0,1,0],[0,0,0]], 1, BGrid),
    BGrid = [[0,1,0],[1,0,1],[0,1,0]].

test(any_nbr_4_none) :-
    autom_any_nbr_4([[0,0],[0,0]], 1, BGrid),
    BGrid = [[0,0],[0,0]].

test(any_nbr_4_all) :-
    autom_any_nbr_4([[1,1],[1,1]], 1, BGrid),
    BGrid = [[1,1],[1,1]].

% --- autom_all_nbrs_4 ---

test(all_nbrs_4_corners) :-
    autom_all_nbrs_4([[1,1,1],[1,0,1],[1,1,1]], 1, BGrid),
    BGrid = [[1,0,1],[0,1,0],[1,0,1]].

test(all_nbrs_4_none) :-
    autom_all_nbrs_4([[0,0],[0,0]], 1, BGrid),
    BGrid = [[0,0],[0,0]].

test(all_nbrs_4_uniform) :-
    autom_all_nbrs_4([[1,1],[1,1]], 1, BGrid),
    BGrid = [[1,1],[1,1]].

% --- autom_any_nbr_8 ---

test(any_nbr_8_center) :-
    autom_any_nbr_8([[0,0,0],[0,1,0],[0,0,0]], 1, BGrid),
    BGrid = [[1,1,1],[1,0,1],[1,1,1]].

test(any_nbr_8_none) :-
    autom_any_nbr_8([[0,0],[0,0]], 1, BGrid),
    BGrid = [[0,0],[0,0]].

test(any_nbr_8_all) :-
    autom_any_nbr_8([[1,1],[1,1]], 1, BGrid),
    BGrid = [[1,1],[1,1]].

% --- autom_all_nbrs_8 ---

test(all_nbrs_8_none) :-
    autom_all_nbrs_8([[0,0],[0,0]], 1, BGrid),
    BGrid = [[0,0],[0,0]].

test(all_nbrs_8_uniform) :-
    autom_all_nbrs_8([[1,1],[1,1]], 1, BGrid),
    BGrid = [[1,1],[1,1]].

test(all_nbrs_8_mixed) :-
    autom_all_nbrs_8([[1,1,1],[1,0,1],[1,1,1]], 1, BGrid),
    BGrid = [[0,0,0],[0,1,0],[0,0,0]].

% --- autom_isolated_4 ---

test(isolated_4_center) :-
    autom_isolated_4([[0,0,0],[0,1,0],[0,0,0]], 1, Cells),
    Cells = [1-1].

test(isolated_4_adjacent_not_isolated) :-
    autom_isolated_4([[1,1],[0,0]], 1, Cells),
    Cells = [].

test(isolated_4_two_isolated) :-
    autom_isolated_4([[1,0,1],[0,0,0]], 1, Cells),
    Cells = [0-0, 0-2].

% --- autom_isolated_8 ---

test(isolated_8_center) :-
    autom_isolated_8([[0,0,0,0,0],[0,0,0,0,0],[0,0,1,0,0],[0,0,0,0,0],[0,0,0,0,0]], 1, Cells),
    Cells = [2-2].

test(isolated_8_diagonal_not_isolated) :-
    autom_isolated_8([[1,0],[0,1]], 1, Cells),
    Cells = [].

test(isolated_8_apart) :-
    autom_isolated_8([[1,0,0,1]], 1, Cells),
    Cells = [0-0, 0-3].

% --- autom_birth_4 ---

test(birth_4_center) :-
    autom_birth_4([[0,1,0],[1,0,1],[0,1,0]], 0, 1, 4, Grid2),
    Grid2 = [[0,1,0],[1,1,1],[0,1,0]].

test(birth_4_no_live) :-
    autom_birth_4([[0,0],[0,0]], 0, 1, 2, Grid2),
    Grid2 = [[0,0],[0,0]].

test(birth_4_n1) :-
    autom_birth_4([[0,1,0],[0,0,0]], 0, 1, 1, Grid2),
    Grid2 = [[1,1,1],[0,1,0]].

% --- autom_birth_8 ---

test(birth_8_three_nbrs) :-
    autom_birth_8([[0,1,1],[1,0,0],[0,0,0]], 0, 1, 3, Grid2),
    Grid2 = [[0,1,1],[1,1,0],[0,0,0]].

test(birth_8_no_births) :-
    autom_birth_8([[0,0],[0,0]], 0, 1, 1, Grid2),
    Grid2 = [[0,0],[0,0]].

test(birth_8_one_nbr_born) :-
    autom_birth_8([[0,0,0],[0,0,0],[0,0,1]], 0, 1, 1, Grid2),
    Grid2 = [[0,0,0],[0,1,1],[0,1,1]].

% --- autom_majority_4 ---

test(majority_4_uniform) :-
    autom_majority_4([[2,2],[2,2]], 0, Grid2),
    Grid2 = [[2,2],[2,2]].

test(majority_4_wins) :-
    autom_majority_4([[1,1],[1,0]], 0, Grid2),
    Grid2 = [[1,1],[1,1]].

test(majority_4_all_zero) :-
    autom_majority_4([[0,0,0],[0,1,0],[0,0,0]], 0, Grid2),
    Grid2 = [[0,0,0],[0,0,0],[0,0,0]].

% --- autom_step_gol ---

test(gol_lone_cell_dies) :-
    autom_step_gol([[0,0,0],[0,1,0],[0,0,0]], Grid2),
    Grid2 = [[0,0,0],[0,0,0],[0,0,0]].

test(gol_blinker_h) :-
    autom_step_gol([[0,0,0],[1,1,1],[0,0,0]], Grid2),
    Grid2 = [[0,1,0],[0,1,0],[0,1,0]].

test(gol_block_stable) :-
    autom_step_gol([[0,0,0,0],[0,1,1,0],[0,1,1,0],[0,0,0,0]], Grid2),
    Grid2 = [[0,0,0,0],[0,1,1,0],[0,1,1,0],[0,0,0,0]].

:- end_tests(autom).
