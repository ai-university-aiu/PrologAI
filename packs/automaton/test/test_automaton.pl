:- use_module('../prolog/automaton').

:- begin_tests(automaton).

% --- automaton_count_nbrs_4 ---

test(count_nbrs_4_center) :-
    automaton_count_nbrs_4([[0,0,0],[0,1,0],[0,0,0]], 0, CGrid),
    CGrid = [[2,2,2],[2,4,2],[2,2,2]].

test(count_nbrs_4_diag) :-
    automaton_count_nbrs_4([[1,0],[0,1]], 1, CGrid),
    CGrid = [[0,2],[2,0]].

test(count_nbrs_4_none) :-
    automaton_count_nbrs_4([[0,0],[0,0]], 1, CGrid),
    CGrid = [[0,0],[0,0]].

% --- automaton_count_nbrs_8 ---

test(count_nbrs_8_ring) :-
    automaton_count_nbrs_8([[0,0,0],[0,1,0],[0,0,0]], 1, CGrid),
    CGrid = [[1,1,1],[1,0,1],[1,1,1]].

test(count_nbrs_8_uniform) :-
    automaton_count_nbrs_8([[1,1],[1,1]], 1, CGrid),
    CGrid = [[3,3],[3,3]].

test(count_nbrs_8_none) :-
    automaton_count_nbrs_8([[0,0],[0,0]], 1, CGrid),
    CGrid = [[0,0],[0,0]].

% --- automaton_count_same_4 ---

test(count_same_4_uniform) :-
    automaton_count_same_4([[1,1],[1,1]], CGrid),
    CGrid = [[2,2],[2,2]].

test(count_same_4_checker) :-
    automaton_count_same_4([[0,1],[1,0]], CGrid),
    CGrid = [[0,0],[0,0]].

test(count_same_4_3x3_uniform) :-
    automaton_count_same_4([[2,2,2],[2,2,2],[2,2,2]], CGrid),
    CGrid = [[2,3,2],[3,4,3],[2,3,2]].

% --- automaton_count_same_8 ---

test(count_same_8_uniform) :-
    automaton_count_same_8([[5,5],[5,5]], CGrid),
    CGrid = [[3,3],[3,3]].

test(count_same_8_3x3) :-
    automaton_count_same_8([[2,2,2],[2,2,2],[2,2,2]], CGrid),
    CGrid = [[3,5,3],[5,8,5],[3,5,3]].

test(count_same_8_none) :-
    automaton_count_same_8([[0,1],[2,3]], CGrid),
    CGrid = [[0,0],[0,0]].

% --- automaton_any_nbr_4 ---

test(any_nbr_4_cross) :-
    automaton_any_nbr_4([[0,0,0],[0,1,0],[0,0,0]], 1, BGrid),
    BGrid = [[0,1,0],[1,0,1],[0,1,0]].

test(any_nbr_4_none) :-
    automaton_any_nbr_4([[0,0],[0,0]], 1, BGrid),
    BGrid = [[0,0],[0,0]].

test(any_nbr_4_all) :-
    automaton_any_nbr_4([[1,1],[1,1]], 1, BGrid),
    BGrid = [[1,1],[1,1]].

% --- automaton_all_nbrs_4 ---

test(all_nbrs_4_corners) :-
    automaton_all_nbrs_4([[1,1,1],[1,0,1],[1,1,1]], 1, BGrid),
    BGrid = [[1,0,1],[0,1,0],[1,0,1]].

test(all_nbrs_4_none) :-
    automaton_all_nbrs_4([[0,0],[0,0]], 1, BGrid),
    BGrid = [[0,0],[0,0]].

test(all_nbrs_4_uniform) :-
    automaton_all_nbrs_4([[1,1],[1,1]], 1, BGrid),
    BGrid = [[1,1],[1,1]].

% --- automaton_any_nbr_8 ---

test(any_nbr_8_center) :-
    automaton_any_nbr_8([[0,0,0],[0,1,0],[0,0,0]], 1, BGrid),
    BGrid = [[1,1,1],[1,0,1],[1,1,1]].

test(any_nbr_8_none) :-
    automaton_any_nbr_8([[0,0],[0,0]], 1, BGrid),
    BGrid = [[0,0],[0,0]].

test(any_nbr_8_all) :-
    automaton_any_nbr_8([[1,1],[1,1]], 1, BGrid),
    BGrid = [[1,1],[1,1]].

% --- automaton_all_nbrs_8 ---

test(all_nbrs_8_none) :-
    automaton_all_nbrs_8([[0,0],[0,0]], 1, BGrid),
    BGrid = [[0,0],[0,0]].

test(all_nbrs_8_uniform) :-
    automaton_all_nbrs_8([[1,1],[1,1]], 1, BGrid),
    BGrid = [[1,1],[1,1]].

test(all_nbrs_8_mixed) :-
    automaton_all_nbrs_8([[1,1,1],[1,0,1],[1,1,1]], 1, BGrid),
    BGrid = [[0,0,0],[0,1,0],[0,0,0]].

% --- automaton_isolated_4 ---

test(isolated_4_center) :-
    automaton_isolated_4([[0,0,0],[0,1,0],[0,0,0]], 1, Cells),
    Cells = [1-1].

test(isolated_4_adjacent_not_isolated) :-
    automaton_isolated_4([[1,1],[0,0]], 1, Cells),
    Cells = [].

test(isolated_4_two_isolated) :-
    automaton_isolated_4([[1,0,1],[0,0,0]], 1, Cells),
    Cells = [0-0, 0-2].

% --- automaton_isolated_8 ---

test(isolated_8_center) :-
    automaton_isolated_8([[0,0,0,0,0],[0,0,0,0,0],[0,0,1,0,0],[0,0,0,0,0],[0,0,0,0,0]], 1, Cells),
    Cells = [2-2].

test(isolated_8_diagonal_not_isolated) :-
    automaton_isolated_8([[1,0],[0,1]], 1, Cells),
    Cells = [].

test(isolated_8_apart) :-
    automaton_isolated_8([[1,0,0,1]], 1, Cells),
    Cells = [0-0, 0-3].

% --- automaton_birth_4 ---

test(birth_4_center) :-
    automaton_birth_4([[0,1,0],[1,0,1],[0,1,0]], 0, 1, 4, Grid2),
    Grid2 = [[0,1,0],[1,1,1],[0,1,0]].

test(birth_4_no_live) :-
    automaton_birth_4([[0,0],[0,0]], 0, 1, 2, Grid2),
    Grid2 = [[0,0],[0,0]].

test(birth_4_n1) :-
    automaton_birth_4([[0,1,0],[0,0,0]], 0, 1, 1, Grid2),
    Grid2 = [[1,1,1],[0,1,0]].

% --- automaton_birth_8 ---

test(birth_8_three_nbrs) :-
    automaton_birth_8([[0,1,1],[1,0,0],[0,0,0]], 0, 1, 3, Grid2),
    Grid2 = [[0,1,1],[1,1,0],[0,0,0]].

test(birth_8_no_births) :-
    automaton_birth_8([[0,0],[0,0]], 0, 1, 1, Grid2),
    Grid2 = [[0,0],[0,0]].

test(birth_8_one_nbr_born) :-
    automaton_birth_8([[0,0,0],[0,0,0],[0,0,1]], 0, 1, 1, Grid2),
    Grid2 = [[0,0,0],[0,1,1],[0,1,1]].

% --- automaton_majority_4 ---

test(majority_4_uniform) :-
    automaton_majority_4([[2,2],[2,2]], 0, Grid2),
    Grid2 = [[2,2],[2,2]].

test(majority_4_wins) :-
    automaton_majority_4([[1,1],[1,0]], 0, Grid2),
    Grid2 = [[1,1],[1,1]].

test(majority_4_all_zero) :-
    automaton_majority_4([[0,0,0],[0,1,0],[0,0,0]], 0, Grid2),
    Grid2 = [[0,0,0],[0,0,0],[0,0,0]].

% --- automaton_step_gol ---

test(gol_lone_cell_dies) :-
    automaton_step_gol([[0,0,0],[0,1,0],[0,0,0]], Grid2),
    Grid2 = [[0,0,0],[0,0,0],[0,0,0]].

test(gol_blinker_h) :-
    automaton_step_gol([[0,0,0],[1,1,1],[0,0,0]], Grid2),
    Grid2 = [[0,1,0],[0,1,0],[0,1,0]].

test(gol_block_stable) :-
    automaton_step_gol([[0,0,0,0],[0,1,1,0],[0,1,1,0],[0,0,0,0]], Grid2),
    Grid2 = [[0,0,0,0],[0,1,1,0],[0,1,1,0],[0,0,0,0]].

:- end_tests(automaton).
