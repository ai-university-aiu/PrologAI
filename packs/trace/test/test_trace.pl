% PLUnit tests for the trace pack (tr_* predicates, Layer 82).
:- use_module(library(plunit)).
:- use_module('../prolog/trace.pl').

:- begin_tests(trace_runs_row).

% Row with two non-Bg runs separated by a Bg cell.
test(runs_row_two_runs) :-
    tr_runs_row([1,0,1,1,0], 0, Runs),
    Runs = [0-0, 2-3].

% All-Bg row produces empty run list.
test(runs_row_none) :-
    tr_runs_row([0,0,0], 0, Runs),
    Runs = [].

% Entire row is one run.
test(runs_row_one_run) :-
    tr_runs_row([1,1,1], 0, Runs),
    Runs = [0-2].

:- end_tests(trace_runs_row).

:- begin_tests(trace_spans_h).

% Per-row spans for a 2x2 alternating grid.
test(spans_h_basic) :-
    tr_spans_h([[1,0],[0,1]], 0, Spans),
    Spans = [[0-0],[1-1]].

% First row empty, second row is one run.
test(spans_h_empty_first) :-
    tr_spans_h([[0,0],[1,1]], 0, Spans),
    Spans = [[],[0-1]].

% Single row with two runs.
test(spans_h_two_runs) :-
    tr_spans_h([[1,1,0,1]], 0, Spans),
    Spans = [[0-1,3-3]].

:- end_tests(trace_spans_h).

:- begin_tests(trace_spans_v).

% Per-column spans for a 3x2 grid.
test(spans_v_basic) :-
    tr_spans_v([[1,0],[0,1],[1,0]], 0, Spans),
    Spans = [[0-0,2-2],[1-1]].

% All-zero grid produces empty spans for each column.
test(spans_v_empty) :-
    tr_spans_v([[0,0],[0,0]], 0, Spans),
    Spans = [[],[]].

% All-one grid produces one full span per column.
test(spans_v_full) :-
    tr_spans_v([[1,1],[1,1]], 0, Spans),
    Spans = [[0-1],[0-1]].

:- end_tests(trace_spans_v).

:- begin_tests(trace_ray_h).

% Ray moving right finds first non-Bg cell.
test(ray_h_right) :-
    tr_ray_h([[0,0,1,0]], 0, 1, 1, 0, H),
    H = 0-2.

% Ray moving left finds first non-Bg cell.
test(ray_h_left) :-
    tr_ray_h([[0,1,0,0]], 0, 3, -1, 0, H),
    H = 0-1.

% Ray moving right from near end finds the last cell.
test(ray_h_right_end) :-
    tr_ray_h([[0,0,0,1]], 0, 2, 1, 0, H),
    H = 0-3.

:- end_tests(trace_ray_h).

:- begin_tests(trace_ray_v).

% Ray moving down finds first non-Bg cell.
test(ray_v_down) :-
    tr_ray_v([[0],[0],[1],[0]], 0, 0, 1, 0, H),
    H = 2-0.

% Ray moving up finds first non-Bg cell.
test(ray_v_up) :-
    tr_ray_v([[1],[0],[0],[0]], 3, 0, -1, 0, H),
    H = 0-0.

% Ray moving up from bottom finds the nearest non-Bg cell.
test(ray_v_up_near) :-
    tr_ray_v([[0],[1],[0]], 2, 0, -1, 0, H),
    H = 1-0.

:- end_tests(trace_ray_v).

:- begin_tests(trace_line_h).

% Horizontal line of 3 cells.
test(line_h_basic) :-
    tr_line_h(2, 1, 3, Cells),
    Cells = [2-1, 2-2, 2-3].

% Horizontal line of one cell (C0 = C1).
test(line_h_single) :-
    tr_line_h(0, 0, 0, Cells),
    Cells = [0-0].

% Horizontal line going right-to-left.
test(line_h_reversed) :-
    tr_line_h(1, 3, 1, Cells),
    Cells = [1-3, 1-2, 1-1].

:- end_tests(trace_line_h).

:- begin_tests(trace_line_v).

% Vertical line of 3 cells.
test(line_v_basic) :-
    tr_line_v(2, 0, 2, Cells),
    Cells = [0-2, 1-2, 2-2].

% Vertical line of one cell (R0 = R1).
test(line_v_single) :-
    tr_line_v(0, 1, 1, Cells),
    Cells = [1-0].

% Vertical line going bottom-to-top.
test(line_v_reversed) :-
    tr_line_v(1, 2, 0, Cells),
    Cells = [2-1, 1-1, 0-1].

:- end_tests(trace_line_v).

:- begin_tests(trace_path_vals).

% Extract values along a path in a 2x2 grid.
test(path_vals_basic) :-
    tr_path_vals([[1,2],[3,4]], [0-0, 0-1, 1-0], Vals),
    Vals = [1,2,3].

% Extract a single value.
test(path_vals_single) :-
    tr_path_vals([[5]], [0-0], Vals),
    Vals = [5].

% Extract values along a non-contiguous path.
test(path_vals_scattered) :-
    tr_path_vals([[1,2,3],[4,5,6]], [1-0, 0-2], Vals),
    Vals = [4,3].

:- end_tests(trace_path_vals).

:- begin_tests(trace_draw_path).

% Draw value 1 at three positions in a zero grid.
test(draw_path_basic) :-
    tr_draw_path([[0,0,0],[0,0,0]], [0-0, 0-2, 1-1], 1, R),
    R = [[1,0,1],[0,1,0]].

% Drawing with an empty path list returns the grid unchanged.
test(draw_path_empty) :-
    tr_draw_path([[0,0],[0,0]], [], 5, R),
    R = [[0,0],[0,0]].

% Fill all four cells of a 2x2 grid.
test(draw_path_fill) :-
    tr_draw_path([[0,0],[0,0]], [0-0, 0-1, 1-0, 1-1], 3, R),
    R = [[3,3],[3,3]].

:- end_tests(trace_draw_path).

:- begin_tests(trace_bbox_border).

% Border of a 3x3 box (all 8 outer cells).
test(bbox_border_3x3) :-
    tr_bbox_border(0, 0, 2, 2, Cells),
    Cells = [0-0, 0-1, 0-2, 1-0, 1-2, 2-0, 2-1, 2-2].

% Border of a 1-row rectangle returns all 3 cells.
test(bbox_border_1row) :-
    tr_bbox_border(1, 1, 1, 3, Cells),
    Cells = [1-1, 1-2, 1-3].

% Border of a single cell returns just that cell.
test(bbox_border_1cell) :-
    tr_bbox_border(0, 0, 0, 0, Cells),
    Cells = [0-0].

:- end_tests(trace_bbox_border).

:- begin_tests(trace_perimeter).

% Single non-Bg cell surrounded by Bg is on the perimeter.
test(perimeter_single) :-
    tr_perimeter([[0,0,0],[0,1,0],[0,0,0]], 0, Cells),
    Cells = [1-1].

% All cells of a fully-filled grid are on the perimeter (all on grid edge).
test(perimeter_full) :-
    tr_perimeter([[1,1],[1,1]], 0, Cells),
    Cells = [0-0, 0-1, 1-0, 1-1].

% 2x2 block in center of 4x4 Bg grid — all 4 inner cells touch Bg.
test(perimeter_inner_block) :-
    tr_perimeter([[0,0,0,0],[0,1,1,0],[0,1,1,0],[0,0,0,0]], 0, Cells),
    Cells = [1-1, 1-2, 2-1, 2-2].

:- end_tests(trace_perimeter).

:- begin_tests(trace_outline).

% Bg cells adjacent to single center cell.
test(outline_single) :-
    tr_outline([[0,0,0],[0,1,0],[0,0,0]], 0, Cells),
    Cells = [0-1, 1-0, 1-2, 2-1].

% Fully-filled grid has no Bg cells so outline is empty.
test(outline_full) :-
    tr_outline([[1,1],[1,1]], 0, Cells),
    Cells = [].

% Checkerboard-like grid: every Bg cell touches a non-Bg cell.
test(outline_checkerboard) :-
    tr_outline([[0,1,0],[1,0,1],[0,1,0]], 0, Cells),
    Cells = [0-0, 0-2, 1-1, 2-0, 2-2].

:- end_tests(trace_outline).

:- begin_tests(trace_edge_cells).

% All cells of a 2x2 grid are edge cells.
test(edge_cells_2x2) :-
    tr_edge_cells([[1,2],[3,4]], Cells),
    Cells = [0-0, 0-1, 1-0, 1-1].

% Edge cells of a 3x3 grid (interior excluded).
test(edge_cells_3x3) :-
    tr_edge_cells([[1,2,3],[4,5,6],[7,8,9]], Cells),
    Cells = [0-0, 0-1, 0-2, 1-0, 1-2, 2-0, 2-1, 2-2].

% Single-cell grid returns that cell.
test(edge_cells_1x1) :-
    tr_edge_cells([[1]], Cells),
    Cells = [0-0].

:- end_tests(trace_edge_cells).

:- begin_tests(trace_midpoint).

% Midpoint of (0,0) and (4,4) is (2,2).
test(midpoint_even) :-
    tr_midpoint(0-0, 4-4, M),
    M = 2-2.

% Floor midpoint of (0,0) and (3,3) is (1,1).
test(midpoint_floor) :-
    tr_midpoint(0-0, 3-3, M),
    M = 1-1.

% Midpoint of (1,2) and (3,6) is (2,4).
test(midpoint_offset) :-
    tr_midpoint(1-2, 3-6, M),
    M = 2-4.

:- end_tests(trace_midpoint).
