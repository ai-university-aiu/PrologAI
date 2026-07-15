:- module(grid_convolution, [
    grid_convolution_window/6,
    grid_convolution_count_in/6,
    grid_convolution_density_map/4,
    grid_convolution_majority/5,
    grid_convolution_majority_map/3,
    grid_convolution_uniform_at/5,
    grid_convolution_uniform_cells/3,
    grid_convolution_find_pattern/3,
    grid_convolution_count_pattern/3,
    grid_convolution_has_pattern/2,
    grid_convolution_hot_spots/5,
    grid_convolution_dilate_sq/4,
    grid_convolution_erode_sq/4,
    grid_convolution_replace_pattern/4
]).
% gridconv.pl - Layer 213: Grid Convolution - sliding window statistics,
% pattern matching, density maps, and square structuring element morphology (gcv_* prefix).
% Operates on raw grid format: list of rows, each a list of color atoms, 0-indexed.
% Window radius N means a (2N+1) x (2N+1) neighborhood centered at (R,C).
:- use_module(library(lists), [
    nth0/3, member/2, append/3
]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
grid_convolution_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed); fails if out of bounds.
grid_convolution_cell_(Grid, R, C, V) :-
% Select row R.
    nth0(R, Grid, Row),
% Select column C.
    nth0(C, Row, V).

% Cell value with fallback Fill for out-of-bounds positions.
grid_convolution_cell_fill_(Grid, R, C, Fill, V) :-
% Try in-bounds lookup; use Fill if out of bounds.
    (grid_convolution_cell_(Grid, R, C, V0) -> V = V0 ; V = Fill).

% Build a new H x W grid using a lambda Goal(R, C, V).
grid_convolution_build_(H, W, Goal, Grid) :-
% Compute last row and column indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect rows.
    findall(Row,
        (between(0, H1, R),
         findall(V, (between(0, W1, C), call(Goal, R, C, V)), Row)),
        Grid).

% Collect all in-bounds cell values in (2N+1) x (2N+1) window at (R,C).
grid_convolution_inbounds_vals_(Grid, R, C, N, Vals) :-
% Compute window bounds.
    RMin is R - N, RMax is R + N,
    CMin is C - N, CMax is C + N,
% Collect all in-bounds values.
    findall(V,
        (between(RMin, RMax, WR), between(CMin, CMax, WC),
         grid_convolution_cell_(Grid, WR, WC, V)),
        Vals).

% Most frequent element in a non-empty list (ties broken by term order).
grid_convolution_mode_(List, Mode) :-
% Sort to group duplicates (msort preserves duplicates).
    msort(List, Sorted),
% Count runs and find the longest; ties broken by first occurrence in sorted order.
    Sorted = [First|Rest],
    grid_convolution_max_run_(Rest, First, 1, 0, First, Mode).

% grid_convolution_max_run_(Tail, CurElem, CurCount, BestCount, BestElem, FinalBest).
% Base case: end of list.
grid_convolution_max_run_([], Cur, CurCount, BestCount, Best, Final) :-
% Compare last run against best.
    (CurCount > BestCount -> Final = Cur ; Final = Best).
% Continuing current run.
grid_convolution_max_run_([H|T], Cur, CurCount, BestCount, Best, Final) :-
    (H = Cur ->
% Same element: extend run.
        NewCount is CurCount + 1,
        (NewCount > BestCount ->
            grid_convolution_max_run_(T, Cur, NewCount, NewCount, Cur, Final)
        ;
            grid_convolution_max_run_(T, Cur, NewCount, BestCount, Best, Final))
    ;
% Different element: finalize current run, start new.
        (CurCount > BestCount ->
            grid_convolution_max_run_(T, H, 1, CurCount, Cur, Final)
        ;
            grid_convolution_max_run_(T, H, 1, BestCount, Best, Final))).

% Check whether all elements of Vals are equal to the same value.
grid_convolution_all_eq_([]).
grid_convolution_all_eq_([_]).
grid_convolution_all_eq_([A, A|Rest]) :- grid_convolution_all_eq_([A|Rest]).

% Count in-bounds cells in window (any color).
grid_convolution_count_inbounds_(Grid, R, C, N, Total) :-
% Compute window bounds.
    RMin is R - N, RMax is R + N,
    CMin is C - N, CMax is C + N,
% Count cells that exist in grid.
    findall(1,
        (between(RMin, RMax, WR), between(CMin, CMax, WC),
         grid_convolution_cell_(Grid, WR, WC, _)),
        Ones),
    length(Ones, Total).

% Check whether Pattern exactly matches Grid at top-left (R,C).
grid_convolution_match_at_(Grid, Pattern, R, C) :-
% Verify every pattern cell matches the corresponding grid cell.
    grid_convolution_dims_(Pattern, PH, PW),
    PH1 is PH - 1, PW1 is PW - 1,
    \+ (between(0, PH1, PR), between(0, PW1, PC),
        grid_convolution_cell_(Pattern, PR, PC, PV),
        GR is R + PR, GC is C + PC,
        \+ grid_convolution_cell_(Grid, GR, GC, PV)).

% --- PUBLIC PREDICATES ---

% grid_convolution_window(+Grid, +R, +C, +N, +Fill, -Window)
% Window is the (2N+1) x (2N+1) subgrid centered at (R,C).
% Out-of-bounds positions are filled with Fill.
grid_convolution_window(Grid, R, C, N, Fill, Window) :-
% Compute window dimension.
    Size is 2 * N + 1,
% Build window grid using fill for out-of-bounds.
    grid_convolution_build_(Size, Size,
        [WRow, WCol, V]>>(GR is R - N + WRow, GC is C - N + WCol,
                          grid_convolution_cell_fill_(Grid, GR, GC, Fill, V)),
        Window).

% grid_convolution_count_in(+Grid, +R, +C, +N, +Color, -Count)
% Count cells equal to Color in the (2N+1) x (2N+1) window at (R,C).
% Only in-bounds positions are counted; out-of-bounds are ignored.
grid_convolution_count_in(Grid, R, C, N, Color, Count) :-
% Compute window bounds.
    RMin is R - N, RMax is R + N,
    CMin is C - N, CMax is C + N,
% Count matching in-bounds cells.
    findall(1,
        (between(RMin, RMax, WR), between(CMin, CMax, WC),
         grid_convolution_cell_(Grid, WR, WC, Color)),
        Ones),
    length(Ones, Count).

% grid_convolution_density_map(+Grid, +N, +Color, -DMap)
% DMap is a grid of the same dimensions as Grid.
% Each cell DMap[R][C] is the count of Color in the (2N+1) x (2N+1) window at (R,C).
grid_convolution_density_map(Grid, N, Color, DMap) :-
% Get dimensions.
    grid_convolution_dims_(Grid, H, W),
% Build density map: each cell holds Color count in its window.
    grid_convolution_build_(H, W,
        [R, C, Count]>>(grid_convolution_count_in(Grid, R, C, N, Color, Count)),
        DMap).

% grid_convolution_majority(+Grid, +R, +C, +N, -Color)
% Color is the most frequent color in the in-bounds cells of the
% (2N+1) x (2N+1) window at (R,C). Fails if no in-bounds cells exist.
grid_convolution_majority(Grid, R, C, N, Color) :-
% Collect in-bounds window values.
    grid_convolution_inbounds_vals_(Grid, R, C, N, Vals),
% Mode is the most frequent value.
    Vals \= [],
    grid_convolution_mode_(Vals, Color).

% grid_convolution_majority_map(+Grid, +N, -Result)
% Result is Grid with each cell replaced by its local majority color (radius N).
grid_convolution_majority_map(Grid, N, Result) :-
% Get dimensions.
    grid_convolution_dims_(Grid, H, W),
% Build result: each cell gets its window majority.
    grid_convolution_build_(H, W,
        [R, C, Maj]>>(grid_convolution_majority(Grid, R, C, N, Maj)),
        Result).

% grid_convolution_uniform_at(+Grid, +R, +C, +N, -Bool)
% Bool is yes if all in-bounds cells in the (2N+1) x (2N+1) window at (R,C)
% are the same color; no otherwise.
grid_convolution_uniform_at(Grid, R, C, N, Bool) :-
% Collect in-bounds window values.
    grid_convolution_inbounds_vals_(Grid, R, C, N, Vals),
% All equal means uniform.
    (Vals \= [], grid_convolution_all_eq_(Vals) -> Bool = yes ; Bool = no).

% grid_convolution_uniform_cells(+Grid, +N, -Cells)
% Cells is the list of (R,C) positions where the in-bounds cells of the
% (2N+1) x (2N+1) window are all the same color.
grid_convolution_uniform_cells(Grid, N, Cells) :-
% Get dimensions.
    grid_convolution_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect uniform positions.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         grid_convolution_uniform_at(Grid, R, C, N, yes)),
        Cells).

% grid_convolution_find_pattern(+Grid, +Pattern, -Positions)
% Positions is the list of (R,C) positions where Pattern exactly matches
% as a subgrid of Grid; (R,C) is the top-left corner of the match.
grid_convolution_find_pattern(Grid, Pattern, Positions) :-
% Get grid and pattern dimensions.
    grid_convolution_dims_(Grid, GH, GW),
    grid_convolution_dims_(Pattern, PH, PW),
% Last valid top-left position.
    RMax is GH - PH,
    CMax is GW - PW,
% Collect matching positions.
    findall(R-C,
        (between(0, RMax, R), between(0, CMax, C),
         grid_convolution_match_at_(Grid, Pattern, R, C)),
        Positions).

% grid_convolution_count_pattern(+Grid, +Pattern, -Count)
% Count is the total number of positions where Pattern matches in Grid.
grid_convolution_count_pattern(Grid, Pattern, Count) :-
% Find all matching positions and count them.
    grid_convolution_find_pattern(Grid, Pattern, Positions),
    length(Positions, Count).

% grid_convolution_has_pattern(+Grid, +Pattern)
% Succeeds if Pattern occurs at least once as a subgrid of Grid.
grid_convolution_has_pattern(Grid, Pattern) :-
% Find at least one match using once for efficiency.
    grid_convolution_dims_(Grid, GH, GW),
    grid_convolution_dims_(Pattern, PH, PW),
    RMax is GH - PH,
    CMax is GW - PW,
    once((between(0, RMax, R), between(0, CMax, C),
          grid_convolution_match_at_(Grid, Pattern, R, C))).

% grid_convolution_hot_spots(+Grid, +N, +Color, +Threshold, -Cells)
% Cells is the list of (R,C) positions where the count of Color in the
% (2N+1) x (2N+1) window is >= Threshold.
grid_convolution_hot_spots(Grid, N, Color, Threshold, Cells) :-
% Get dimensions.
    grid_convolution_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect cells where Color density meets or exceeds threshold.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         grid_convolution_count_in(Grid, R, C, N, Color, Count),
         Count >= Threshold),
        Cells).

% grid_convolution_dilate_sq(+Grid, +FgColor, +N, -Result)
% Square structuring element dilation of radius N: a cell becomes FgColor
% if any cell in its (2N+1) x (2N+1) window is FgColor.
grid_convolution_dilate_sq(Grid, FgColor, N, Result) :-
% Get dimensions.
    grid_convolution_dims_(Grid, H, W),
% A cell becomes FgColor if window count > 0.
    grid_convolution_build_(H, W,
        [R, C, V]>>(grid_convolution_cell_(Grid, R, C, GV),
                    (GV = FgColor -> V = FgColor
                    ; (grid_convolution_count_in(Grid, R, C, N, FgColor, Count),
                       Count > 0 -> V = FgColor ; V = GV))),
        Result).

% grid_convolution_erode_sq(+Grid, +FgColor, +N, -Result)
% Square structuring element erosion of radius N: a FgColor cell keeps its
% color only if ALL in-bounds cells in its (2N+1) x (2N+1) window are FgColor.
% Otherwise it becomes background (first non-FgColor cell found in grid).
grid_convolution_erode_sq(Grid, FgColor, N, Result) :-
% Find background color.
    grid_convolution_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    (findall(V, (between(0, H1, R), between(0, W1, C),
                 grid_convolution_cell_(Grid, R, C, V), V \= FgColor), [BgColor|_])
     -> true ; BgColor = bg),
% Build result: FgColor cell survives only if every window cell is FgColor.
    grid_convolution_build_(H, W,
        [R, C, V]>>(grid_convolution_cell_(Grid, R, C, GV),
                    (GV = FgColor ->
                        (grid_convolution_count_inbounds_(Grid, R, C, N, Total),
                         grid_convolution_count_in(Grid, R, C, N, FgColor, FgCount),
                         (FgCount =:= Total -> V = FgColor ; V = BgColor))
                    ;
                        V = GV)),
        Result).

% grid_convolution_replace_pattern(+Grid, +Pattern, +Replacement, -Result)
% Result is Grid with the first-found (row-major) occurrence of Pattern
% replaced by Replacement. Pattern and Replacement must have the same dimensions.
% If no match is found, Result = Grid.
grid_convolution_replace_pattern(Grid, Pattern, Replacement, Result) :-
% Find first matching position.
    grid_convolution_dims_(Grid, GH, GW),
    grid_convolution_dims_(Pattern, PH, PW),
    RMax is GH - PH,
    CMax is GW - PW,
    (once((between(0, RMax, R0), between(0, CMax, C0),
           grid_convolution_match_at_(Grid, Pattern, R0, C0))) ->
% Replace Pattern at (R0,C0) with Replacement.
        grid_convolution_build_(GH, GW,
            [R, C, V]>>(PR is R - R0, PC is C - C0,
                         (PR >= 0, PR < PH, PC >= 0, PC < PW ->
                             grid_convolution_cell_(Replacement, PR, PC, V)
                         ;
                             grid_convolution_cell_(Grid, R, C, V))),
            Result)
    ;
% No match: return Grid unchanged.
        Result = Grid).
