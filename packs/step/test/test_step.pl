% test_step.pl - PLUnit acceptance tests for the step pack (st_* predicates).
% 42 tests: 3 per predicate for all 14 exported predicates.
:- use_module('../prolog/step.pl').

% Begin the step test suite.
:- begin_tests(step).

% --- step_step/3 ---

% step_step moves one step up from (1,1).
test(step_up) :-
    % Moving up means DR=-1, DC=0.
    step_step(1-1, (-1)-0, R2-C2),
    % New position should be (0,1).
    R2 =:= 0, C2 =:= 1.

% step_step moves one step diagonally down-right from (0,0).
test(step_diag) :-
    % DR=1, DC=1 is down-right diagonal.
    step_step(0-0, 1-1, R2-C2),
    % New position should be (1,1).
    R2 =:= 1, C2 =:= 1.

% step_step can produce negative coordinates (no bounds checking).
test(step_no_bounds) :-
    % Moving left from column 0 gives column -1.
    step_step(0-0, 0-(-1), R2-C2),
    % Row stays 0, column goes to -1.
    R2 =:= 0, C2 =:= -1.

% --- step_step_in/4 ---

% step_step_in succeeds for a step that stays inside a 3x3 grid.
test(step_in_valid) :-
    % Step right from (1,1) in a 3x3 grid stays in bounds.
    step_step_in([[0,0,0],[0,0,0],[0,0,0]], 1-1, 0-1, R2-C2),
    % New position is (1,2).
    R2 =:= 1, C2 =:= 2.

% step_step_in fails for a step that would leave the grid.
test(step_in_out, [fail]) :-
    % Step right from (1,2) in a 3x3 grid goes out of bounds.
    step_step_in([[0,0,0],[0,0,0],[0,0,0]], 1-2, 0-1, _).

% step_step_in succeeds for a diagonal step staying inside.
test(step_in_diag) :-
    % Diagonal down-right from (0,0) in a 3x3 grid.
    step_step_in([[0,0,0],[0,0,0],[0,0,0]], 0-0, 1-1, R2-C2),
    % New position is (1,1).
    R2 =:= 1, C2 =:= 1.

% --- step_ray/4 ---

% step_ray going up from (2,1) in a 3x3 grid gives (1,1) then (0,1).
test(ray_up) :-
    % Ray cast upward from bottom-middle cell.
    step_ray([[1,2,3],[4,5,6],[7,8,9]], 2-1, (-1)-0, Cells),
    % Two cells above: (1,1) then (0,1).
    Cells = [1-1, 0-1].

% step_ray going right from (1,0) gives (1,1) then (1,2).
test(ray_right) :-
    % Ray cast rightward from left-middle cell.
    step_ray([[1,2,3],[4,5,6],[7,8,9]], 1-0, 0-1, Cells),
    % Two cells to the right.
    Cells = [1-1, 1-2].

% step_ray from a corner in the outward direction gives empty list.
test(ray_empty) :-
    % Ray up from (0,0) has no cells above.
    step_ray([[1,2],[3,4]], 0-0, (-1)-0, Cells),
    % No cells in the ray.
    Cells = [].

% --- step_ray_to/5 ---

% step_ray_to stops before the first occurrence of the stop value.
test(ray_to_stops) :-
    % Ray right from (0,0) stops before first 3.
    step_ray_to([[1,2,3,4]], 0-0, 0-1, 3, Cells),
    % Cells before value 3: (0,1) and that's it -- (0,2) is value 3, stop.
    Cells = [0-1].

% step_ray_to returns all cells if stop value never appears.
test(ray_to_full) :-
    % No value 9 exists in this row.
    step_ray_to([[1,2,3]], 0-0, 0-1, 9, Cells),
    % All two cells after start are returned.
    Cells = [0-1, 0-2].

% step_ray_to returns empty when first step is stop value.
test(ray_to_immediate) :-
    % The very next cell has the stop value.
    step_ray_to([[0,5,0]], 0-0, 0-1, 5, Cells),
    % Empty: step immediately hits stop value.
    Cells = [].

% --- step_walk/4 ---

% step_walk includes the starting cell.
test(walk_includes_start) :-
    % Walk downward from (0,1) in a 3x3 grid.
    step_walk([[1,2,3],[4,5,6],[7,8,9]], 0-1, 1-0, Cells),
    % Includes start (0,1), then (1,1), (2,1).
    Cells = [0-1, 1-1, 2-1].

% step_walk at a corner returns only the start cell if direction is outward.
test(walk_corner_out) :-
    % Walk left from (0,0): no cells to the left, but start is included.
    step_walk([[1,2],[3,4]], 0-0, 0-(-1), Cells),
    % Only the starting cell.
    Cells = [0-0].

% step_walk with diagonal direction.
test(walk_diagonal) :-
    % Walk down-right from (0,0) in a 3x3 grid.
    step_walk([[1,2,3],[4,5,6],[7,8,9]], 0-0, 1-1, Cells),
    % Start (0,0), then (1,1), then (2,2).
    Cells = [0-0, 1-1, 2-2].

% --- step_dirs4/1 ---

% step_dirs4 returns exactly 4 directions.
test(dirs4_count) :-
    % Get the cardinal direction list.
    step_dirs4(Dirs),
    % Exactly four directions.
    length(Dirs, 4).

% step_dirs4 includes the up direction.
test(dirs4_up) :-
    % Get cardinal directions.
    step_dirs4(Dirs),
    % Up direction (-1,0) should be in the list; cut closes choicepoint.
    member((-1)-0, Dirs), !.

% step_dirs4 includes the right direction.
test(dirs4_right) :-
    % Get cardinal directions.
    step_dirs4(Dirs),
    % Right direction (0,1) should be in the list.
    member(0-1, Dirs).

% --- step_dirs8/1 ---

% step_dirs8 returns exactly 8 directions.
test(dirs8_count) :-
    % Get all 8 principal directions.
    step_dirs8(Dirs),
    % Exactly eight directions.
    length(Dirs, 8).

% step_dirs8 includes the down-right diagonal.
test(dirs8_diag) :-
    % Get all 8 directions.
    step_dirs8(Dirs),
    % Down-right diagonal (1,1) should be in the list.
    member(1-1, Dirs).

% step_dirs8 includes all four cardinals.
test(dirs8_has_cardinals) :-
    % Get all 8 directions.
    step_dirs8(Dirs),
    % All four cardinals must be present; cut closes choicepoint after last member.
    member((-1)-0, Dirs), member(1-0, Dirs),
    member(0-(-1), Dirs), member(0-1, Dirs), !.

% --- step_rotate_cw/2 ---

% Rotating up clockwise gives right.
test(rotate_cw_up) :-
    % Up = (-1,0), rotated CW = (0,1) = right.
    step_rotate_cw((-1)-0, DR2-DC2),
    DR2 =:= 0, DC2 =:= 1.

% Rotating right clockwise gives down.
test(rotate_cw_right) :-
    % Right = (0,1), rotated CW = (1,0) = down.
    step_rotate_cw(0-1, DR2-DC2),
    DR2 =:= 1, DC2 =:= 0.

% Rotating down clockwise gives left.
test(rotate_cw_down) :-
    % Down = (1,0), rotated CW = (0,-1) = left.
    step_rotate_cw(1-0, DR2-DC2),
    DR2 =:= 0, DC2 =:= -1.

% --- step_rotate_ccw/2 ---

% Rotating up counter-clockwise gives left.
test(rotate_ccw_up) :-
    % Up = (-1,0), rotated CCW = (0,-1) = left.
    step_rotate_ccw((-1)-0, DR2-DC2),
    DR2 =:= 0, DC2 =:= -1.

% Rotating right counter-clockwise gives up.
test(rotate_ccw_right) :-
    % Right = (0,1), rotated CCW = (-1,0) = up.
    step_rotate_ccw(0-1, DR2-DC2),
    DR2 =:= -1, DC2 =:= 0.

% Rotating left counter-clockwise gives down.
test(rotate_ccw_left) :-
    % Left = (0,-1), rotated CCW = (1,0) = down.
    step_rotate_ccw(0-(-1), DR2-DC2),
    DR2 =:= 1, DC2 =:= 0.

% --- step_opposite/2 ---

% Opposite of up is down.
test(opposite_up) :-
    % Up = (-1,0), opposite = (1,0) = down.
    step_opposite((-1)-0, DR2-DC2),
    DR2 =:= 1, DC2 =:= 0.

% Opposite of right is left.
test(opposite_right) :-
    % Right = (0,1), opposite = (0,-1) = left.
    step_opposite(0-1, DR2-DC2),
    DR2 =:= 0, DC2 =:= -1.

% Opposite of a diagonal is the reverse diagonal.
test(opposite_diag) :-
    % Down-right = (1,1), opposite = (-1,-1) = up-left.
    step_opposite(1-1, DR2-DC2),
    DR2 =:= -1, DC2 =:= -1.

% --- step_normalize/3 ---

% Normalizing (0,0) to (0,3) gives right direction.
test(normalize_right) :-
    % Same row, C increases: direction is (0,1).
    step_normalize(0-0, 0-3, DR-DC),
    DR =:= 0, DC =:= 1.

% Normalizing (2,2) to (0,0) gives up-left diagonal.
test(normalize_up_left) :-
    % Both row and column decrease: direction is (-1,-1).
    step_normalize(2-2, 0-0, DR-DC),
    DR =:= -1, DC =:= -1.

% Normalizing to the same cell gives (0,0).
test(normalize_same) :-
    % No movement: direction is (0,0).
    step_normalize(1-1, 1-1, DR-DC),
    DR =:= 0, DC =:= 0.

% --- step_path/3 ---

% step_path following two steps right from (0,0).
test(path_right) :-
    % Two right steps from (0,0).
    step_path(0-0, [0-1, 0-1], Cells),
    % Start, after step 1, after step 2.
    Cells = [0-0, 0-1, 0-2].

% step_path following mixed directions.
test(path_mixed) :-
    % Right then down from (0,0).
    step_path(0-0, [0-1, 1-0], Cells),
    % (0,0) -> (0,1) -> (1,1).
    Cells = [0-0, 0-1, 1-1].

% step_path with empty direction list returns only the start.
test(path_empty_dirs) :-
    % No steps to follow.
    step_path(2-3, [], Cells),
    % Only the starting position.
    Cells = [2-3].

% --- step_first/5 ---

% step_first finds the first cell with the target value going right.
test(first_found) :-
    % Row [[1,2,3,2,1]], look for value 3 going right from (0,0).
    step_first([[1,2,3,2,1]], 0-0, 0-1, 3, R2-C2),
    % First 3 is at (0,2).
    R2 =:= 0, C2 =:= 2.

% step_first going down finds the first matching cell in the column.
test(first_down) :-
    % Grid with value 5 in middle row.
    step_first([[1,0],[5,0],[1,0]], 0-0, 1-0, 5, R2-C2),
    % First 5 in column 0 going down is at (1,0).
    R2 =:= 1, C2 =:= 0.

% step_first fails when the value is not found.
test(first_not_found, [fail]) :-
    % Value 9 does not appear in this grid.
    step_first([[1,2],[3,4]], 0-0, 0-1, 9, _).

% --- step_to_edge/4 ---

% step_to_edge going right from (0,0) in a 1x3 grid is 2 steps.
test(to_edge_right) :-
    % From (0,0) going right: (0,1) then (0,2) then boundary.
    step_to_edge([[1,2,3]], 0-0, 0-1, Steps),
    % Two steps before leaving the grid.
    Steps =:= 2.

% step_to_edge from a cell already at the boundary going outward is 0.
test(to_edge_zero) :-
    % (0,2) going right in a 1x3 grid: already at right edge.
    step_to_edge([[1,2,3]], 0-2, 0-1, Steps),
    % No steps possible.
    Steps =:= 0.

% step_to_edge going up from (2,1) in a 3x3 grid is 2 steps.
test(to_edge_up) :-
    % From (2,1) going up: (1,1) then (0,1) then boundary.
    step_to_edge([[1,2,3],[4,5,6],[7,8,9]], 2-1, (-1)-0, Steps),
    % Two steps before leaving.
    Steps =:= 2.

% End the step test suite.
:- end_tests(step).
