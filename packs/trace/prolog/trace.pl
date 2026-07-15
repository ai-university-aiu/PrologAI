% trace.pl - Layer 82: Path Tracing, Rays, and Grid Boundaries (tr_* prefix).
% ARC-AGI-2 visual reasoning: runs, spans, rays, lines, paths, boundaries.
:- module(trace, [
    trace_runs_row/3,
    trace_spans_h/3,
    trace_spans_v/3,
    trace_ray_h/6,
    trace_ray_v/6,
    trace_line_h/4,
    trace_line_v/4,
    trace_path_vals/3,
    trace_draw_path/4,
    trace_bbox_border/5,
    trace_perimeter/3,
    trace_outline/3,
    trace_edge_cells/2,
    trace_midpoint/3
]).

% Import list operations used throughout this module.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3, reverse/2]).
% Import higher-order operations used throughout this module.
:- use_module(library(apply), [maplist/2, maplist/3, maplist/4, foldl/4]).

% trace_runs_row(+Row, +Bg, -Runs): Runs is the list of Start-End pairs for non-Bg contiguous runs.
trace_runs_row(Row, Bg, Runs) :-
    % Iterate all valid start/end combinations using findall.
    length(Row, N), NM1 is N - 1,
    findall(Start-End, (
        % Start: first non-Bg cell after a Bg boundary.
        between(0, NM1, Start),
        nth0(Start, Row, SVal), SVal \== Bg,
        (Start =:= 0 -> true ;
            Prev is Start - 1, nth0(Prev, Row, PVal), PVal == Bg),
        % End: last non-Bg cell before a Bg boundary.
        between(Start, NM1, End),
        nth0(End, Row, EVal), EVal \== Bg,
        (End =:= NM1 -> true ;
            Next is End + 1, nth0(Next, Row, NxVal), NxVal == Bg),
        % All cells from Start to End must be non-Bg.
        forall(between(Start, End, J), (nth0(J, Row, V), V \== Bg))
    ), Runs).

% trace_spans_h(+Grid, +Bg, -Spans): Spans[I] is the run list for row I of Grid.
trace_spans_h(Grid, Bg, Spans) :-
    % Apply trace_runs_row to each row of the grid.
    maplist([Row, Runs]>>(trace_runs_row(Row, Bg, Runs)), Grid, Spans).

% trace_transpose_(+Grid, -Transposed): private transpose helper (shared with other packs).
trace_transpose_([], []) :- !.
trace_transpose_(Grid, Transposed) :-
    % Extract each column as a row in the transposed grid.
    Grid = [FR|_], length(FR, NCols), NColsM1 is NCols - 1,
    numlist(0, NColsM1, CIdxs),
    maplist([CI, Col]>>(maplist([Row, V]>>(nth0(CI, Row, V)), Grid, Col)), CIdxs, Transposed).

% trace_spans_v(+Grid, +Bg, -Spans): Spans[J] is the run list for column J of Grid.
trace_spans_v(Grid, Bg, Spans) :-
    % Transpose so columns become rows, then apply row-span logic.
    trace_transpose_(Grid, T),
    maplist([Col, Runs]>>(trace_runs_row(Col, Bg, Runs)), T, Spans).

% trace_ray_h(+Grid, +R, +C, +Dir, +Bg, -HR-HC): cast horizontal ray from (R,C) in Dir (+1/-1).
trace_ray_h(Grid, R, C, Dir, Bg, R-HC) :-
    % Get the row and column bounds.
    nth0(R, Grid, Row),
    length(Row, NCols), NColsM1 is NCols - 1,
    % Compute the first candidate column.
    NC0 is C + Dir,
    NC0 >= 0, NC0 =< NColsM1,
    % Build candidate list in the ray direction.
    (Dir > 0 ->
        numlist(NC0, NColsM1, Candidates)
    ;
        numlist(0, NC0, RevCands), reverse(RevCands, Candidates)
    ),
    % Find the first non-Bg cell among the candidates.
    member(HC, Candidates),
    nth0(HC, Row, Val), Val \== Bg, !.

% trace_ray_v(+Grid, +R, +C, +Dir, +Bg, -HR-HC): cast vertical ray from (R,C) in Dir (+1/-1).
trace_ray_v(Grid, R, C, Dir, Bg, HR-C) :-
    % Get the row bounds.
    length(Grid, NRows), NRowsM1 is NRows - 1,
    % Compute the first candidate row.
    NR0 is R + Dir,
    NR0 >= 0, NR0 =< NRowsM1,
    % Build candidate list in the ray direction.
    (Dir > 0 ->
        numlist(NR0, NRowsM1, Candidates)
    ;
        numlist(0, NR0, RevCands), reverse(RevCands, Candidates)
    ),
    % Find the first non-Bg row among the candidates.
    member(HR, Candidates),
    nth0(HR, Grid, Row), nth0(C, Row, Val), Val \== Bg, !.

% trace_line_h(+R, +C0, +C1, -Cells): list R-C pairs from (R,C0) to (R,C1) inclusive.
trace_line_h(R, C0, C1, Cells) :-
    % Build column indices in the correct direction.
    (C0 =< C1 ->
        numlist(C0, C1, Cs)
    ;
        numlist(C1, C0, Cs0), reverse(Cs0, Cs)
    ),
    % Map each column index to an R-C pair (R is captured from outer scope).
    maplist([C, R-C]>>(true), Cs, Cells).

% trace_line_v(+C, +R0, +R1, -Cells): list R-C pairs from (R0,C) to (R1,C) inclusive.
trace_line_v(C, R0, R1, Cells) :-
    % Build row indices in the correct direction.
    (R0 =< R1 ->
        numlist(R0, R1, Rs)
    ;
        numlist(R1, R0, Rs0), reverse(Rs0, Rs)
    ),
    % Map each row index to an R-C pair (C is captured from outer scope).
    maplist([R, R-C]>>(true), Rs, Cells).

% trace_path_vals(+Grid, +Cells, -Vals): Vals[I] is the grid value at Cells[I].
trace_path_vals(Grid, Cells, Vals) :-
    % Extract the value at each R-C position in the path.
    maplist([R-C, V]>>(nth0(R, Grid, Row), nth0(C, Row, V)), Cells, Vals).

% trace_set_cell_(+Grid, +R, +C, +Val, -Result): private; set Grid[R][C] = Val.
trace_set_cell_(Grid, R, C, Val, Result) :-
    % Get grid dimensions for full row/col iteration.
    length(Grid, NRows), NRowsM1 is NRows - 1,
    Grid = [FR|_], length(FR, NCols), NColsM1 is NCols - 1,
    numlist(0, NRowsM1, RowIdxs),
    numlist(0, NColsM1, ColIdxs),
    % For each row: update target row, copy others unchanged.
    maplist([RI, OldRow, NewRow]>>(
        (RI =:= R ->
            maplist([CI, OC, NC]>>(CI =:= C -> NC = Val ; NC = OC), ColIdxs, OldRow, NewRow)
        ;
            NewRow = OldRow
        )
    ), RowIdxs, Grid, Result).

% trace_draw_path(+Grid, +Cells, +Val, -Result): paint Val at every R-C cell in Cells.
trace_draw_path(Grid, Cells, Val, Result) :-
    % Fold over the cell list, stamping Val at each position.
    foldl([R-C, Acc, NAcc]>>(trace_set_cell_(Acc, R, C, Val, NAcc)), Cells, Grid, Result).

% trace_bbox_border_cell_(+R0,+C0,+R1,+C1,?R,?C): enumerates border cells of rectangle.
trace_bbox_border_cell_(R0, C0, R1, C1, R, C) :-
    % Top and bottom rows.
    (R = R0 ; R = R1), between(C0, C1, C).
trace_bbox_border_cell_(R0, C0, R1, C1, R, C) :-
    % Left and right columns (interior rows only to avoid dup corners).
    between(R0, R1, R), (C = C0 ; C = C1).

% trace_bbox_border(+R0, +C0, +R1, +C1, -Cells): sorted list of R-C pairs on the border.
trace_bbox_border(R0, C0, R1, C1, Cells) :-
    % Collect all border cells (with duplicates at corners) then sort to deduplicate.
    findall(R-C, trace_bbox_border_cell_(R0, C0, R1, C1, R, C), CellsDup),
    sort(CellsDup, Cells).

% trace_perimeter(+Grid, +Bg, -Cells): non-Bg cells touching Bg or on the grid boundary.
trace_perimeter(Grid, Bg, Cells) :-
    % Get grid dimensions.
    length(Grid, NRows), Grid = [FR|_], length(FR, NCols),
    NRowsM1 is NRows - 1, NColsM1 is NCols - 1,
    % Collect all qualifying non-Bg cells (may be duplicated via multiple branches).
    findall(R-C, (
        between(0, NRowsM1, R), between(0, NColsM1, C),
        nth0(R, Grid, Row), nth0(C, Row, Val), Val \== Bg,
        % On grid edge OR adjacent to a Bg cell.
        (R =:= 0 ; R =:= NRowsM1 ; C =:= 0 ; C =:= NColsM1
        ;
         member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
         R2 is R + DR, C2 is C + DC,
         R2 >= 0, R2 =< NRowsM1, C2 >= 0, C2 =< NColsM1,
         nth0(R2, Grid, Row2), nth0(C2, Row2, Bg))
    ), CellsDup),
    % Sort to deduplicate cells qualifying via multiple conditions.
    sort(CellsDup, Cells).

% trace_outline(+Grid, +Bg, -Cells): sorted list of Bg cells adjacent to a non-Bg cell.
trace_outline(Grid, Bg, Cells) :-
    % Get grid dimensions.
    length(Grid, NRows), Grid = [FR|_], length(FR, NCols),
    NRowsM1 is NRows - 1, NColsM1 is NCols - 1,
    % Collect all Bg cells with at least one non-Bg 4-neighbor.
    findall(R-C, (
        between(0, NRowsM1, R), between(0, NColsM1, C),
        nth0(R, Grid, Row), nth0(C, Row, Bg),
        member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
        R2 is R + DR, C2 is C + DC,
        R2 >= 0, R2 =< NRowsM1, C2 >= 0, C2 =< NColsM1,
        nth0(R2, Grid, Row2), nth0(C2, Row2, NVal), NVal \== Bg
    ), CellsDup),
    % Sort to deduplicate cells with multiple non-Bg neighbors.
    sort(CellsDup, Cells).

% trace_edge_cells(+Grid, -Cells): sorted list of all R-C pairs on the grid boundary.
trace_edge_cells(Grid, Cells) :-
    % Get bounding indices and delegate to trace_bbox_border.
    length(Grid, NRows), Grid = [FR|_], length(FR, NCols),
    NRowsM1 is NRows - 1, NColsM1 is NCols - 1,
    trace_bbox_border(0, 0, NRowsM1, NColsM1, Cells).

% trace_midpoint(+R1-C1, +R2-C2, -RM-CM): floor midpoint of two grid positions.
trace_midpoint(R1-C1, R2-C2, RM-CM) :-
    % Compute integer (floor) midpoint in both dimensions.
    RM is (R1 + R2) // 2,
    CM is (C1 + C2) // 2.
