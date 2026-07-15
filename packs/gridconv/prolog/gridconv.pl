:- module(gridconv, [
    gridconv_window/6,
    gridconv_count_in/6,
    gridconv_density_map/4,
    gridconv_majority/5,
    gridconv_majority_map/3,
    gridconv_uniform_at/5,
    gridconv_uniform_cells/3,
    gridconv_find_pattern/3,
    gridconv_count_pattern/3,
    gridconv_has_pattern/2,
    gridconv_hot_spots/5,
    gridconv_dilate_sq/4,
    gridconv_erode_sq/4,
    gridconv_replace_pattern/4
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
gridconv_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed); fails if out of bounds.
gridconv_cell_(Grid, R, C, V) :-
% Select row R.
    nth0(R, Grid, Row),
% Select column C.
    nth0(C, Row, V).

% Cell value with fallback Fill for out-of-bounds positions.
gridconv_cell_fill_(Grid, R, C, Fill, V) :-
% Try in-bounds lookup; use Fill if out of bounds.
    (gridconv_cell_(Grid, R, C, V0) -> V = V0 ; V = Fill).

% Build a new H x W grid using a lambda Goal(R, C, V).
gridconv_build_(H, W, Goal, Grid) :-
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
gridconv_inbounds_vals_(Grid, R, C, N, Vals) :-
% Compute window bounds.
    RMin is R - N, RMax is R + N,
    CMin is C - N, CMax is C + N,
% Collect all in-bounds values.
    findall(V,
        (between(RMin, RMax, WR), between(CMin, CMax, WC),
         gridconv_cell_(Grid, WR, WC, V)),
        Vals).

% Most frequent element in a non-empty list (ties broken by term order).
gridconv_mode_(List, Mode) :-
% Sort to group duplicates (msort preserves duplicates).
    msort(List, Sorted),
% Count runs and find the longest; ties broken by first occurrence in sorted order.
    Sorted = [First|Rest],
    gridconv_max_run_(Rest, First, 1, 0, First, Mode).

% gridconv_max_run_(Tail, CurElem, CurCount, BestCount, BestElem, FinalBest).
% Base case: end of list.
gridconv_max_run_([], Cur, CurCount, BestCount, Best, Final) :-
% Compare last run against best.
    (CurCount > BestCount -> Final = Cur ; Final = Best).
% Continuing current run.
gridconv_max_run_([H|T], Cur, CurCount, BestCount, Best, Final) :-
    (H = Cur ->
% Same element: extend run.
        NewCount is CurCount + 1,
        (NewCount > BestCount ->
            gridconv_max_run_(T, Cur, NewCount, NewCount, Cur, Final)
        ;
            gridconv_max_run_(T, Cur, NewCount, BestCount, Best, Final))
    ;
% Different element: finalize current run, start new.
        (CurCount > BestCount ->
            gridconv_max_run_(T, H, 1, CurCount, Cur, Final)
        ;
            gridconv_max_run_(T, H, 1, BestCount, Best, Final))).

% Check whether all elements of Vals are equal to the same value.
gridconv_all_eq_([]).
gridconv_all_eq_([_]).
gridconv_all_eq_([A, A|Rest]) :- gridconv_all_eq_([A|Rest]).

% Count in-bounds cells in window (any color).
gridconv_count_inbounds_(Grid, R, C, N, Total) :-
% Compute window bounds.
    RMin is R - N, RMax is R + N,
    CMin is C - N, CMax is C + N,
% Count cells that exist in grid.
    findall(1,
        (between(RMin, RMax, WR), between(CMin, CMax, WC),
         gridconv_cell_(Grid, WR, WC, _)),
        Ones),
    length(Ones, Total).

% Check whether Pattern exactly matches Grid at top-left (R,C).
gridconv_match_at_(Grid, Pattern, R, C) :-
% Verify every pattern cell matches the corresponding grid cell.
    gridconv_dims_(Pattern, PH, PW),
    PH1 is PH - 1, PW1 is PW - 1,
    \+ (between(0, PH1, PR), between(0, PW1, PC),
        gridconv_cell_(Pattern, PR, PC, PV),
        GR is R + PR, GC is C + PC,
        \+ gridconv_cell_(Grid, GR, GC, PV)).

% --- PUBLIC PREDICATES ---

% gridconv_window(+Grid, +R, +C, +N, +Fill, -Window)
% Window is the (2N+1) x (2N+1) subgrid centered at (R,C).
% Out-of-bounds positions are filled with Fill.
gridconv_window(Grid, R, C, N, Fill, Window) :-
% Compute window dimension.
    Size is 2 * N + 1,
% Build window grid using fill for out-of-bounds.
    gridconv_build_(Size, Size,
        [WRow, WCol, V]>>(GR is R - N + WRow, GC is C - N + WCol,
                          gridconv_cell_fill_(Grid, GR, GC, Fill, V)),
        Window).

% gridconv_count_in(+Grid, +R, +C, +N, +Color, -Count)
% Count cells equal to Color in the (2N+1) x (2N+1) window at (R,C).
% Only in-bounds positions are counted; out-of-bounds are ignored.
gridconv_count_in(Grid, R, C, N, Color, Count) :-
% Compute window bounds.
    RMin is R - N, RMax is R + N,
    CMin is C - N, CMax is C + N,
% Count matching in-bounds cells.
    findall(1,
        (between(RMin, RMax, WR), between(CMin, CMax, WC),
         gridconv_cell_(Grid, WR, WC, Color)),
        Ones),
    length(Ones, Count).

% gridconv_density_map(+Grid, +N, +Color, -DMap)
% DMap is a grid of the same dimensions as Grid.
% Each cell DMap[R][C] is the count of Color in the (2N+1) x (2N+1) window at (R,C).
gridconv_density_map(Grid, N, Color, DMap) :-
% Get dimensions.
    gridconv_dims_(Grid, H, W),
% Build density map: each cell holds Color count in its window.
    gridconv_build_(H, W,
        [R, C, Count]>>(gridconv_count_in(Grid, R, C, N, Color, Count)),
        DMap).

% gridconv_majority(+Grid, +R, +C, +N, -Color)
% Color is the most frequent color in the in-bounds cells of the
% (2N+1) x (2N+1) window at (R,C). Fails if no in-bounds cells exist.
gridconv_majority(Grid, R, C, N, Color) :-
% Collect in-bounds window values.
    gridconv_inbounds_vals_(Grid, R, C, N, Vals),
% Mode is the most frequent value.
    Vals \= [],
    gridconv_mode_(Vals, Color).

% gridconv_majority_map(+Grid, +N, -Result)
% Result is Grid with each cell replaced by its local majority color (radius N).
gridconv_majority_map(Grid, N, Result) :-
% Get dimensions.
    gridconv_dims_(Grid, H, W),
% Build result: each cell gets its window majority.
    gridconv_build_(H, W,
        [R, C, Maj]>>(gridconv_majority(Grid, R, C, N, Maj)),
        Result).

% gridconv_uniform_at(+Grid, +R, +C, +N, -Bool)
% Bool is yes if all in-bounds cells in the (2N+1) x (2N+1) window at (R,C)
% are the same color; no otherwise.
gridconv_uniform_at(Grid, R, C, N, Bool) :-
% Collect in-bounds window values.
    gridconv_inbounds_vals_(Grid, R, C, N, Vals),
% All equal means uniform.
    (Vals \= [], gridconv_all_eq_(Vals) -> Bool = yes ; Bool = no).

% gridconv_uniform_cells(+Grid, +N, -Cells)
% Cells is the list of (R,C) positions where the in-bounds cells of the
% (2N+1) x (2N+1) window are all the same color.
gridconv_uniform_cells(Grid, N, Cells) :-
% Get dimensions.
    gridconv_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect uniform positions.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         gridconv_uniform_at(Grid, R, C, N, yes)),
        Cells).

% gridconv_find_pattern(+Grid, +Pattern, -Positions)
% Positions is the list of (R,C) positions where Pattern exactly matches
% as a subgrid of Grid; (R,C) is the top-left corner of the match.
gridconv_find_pattern(Grid, Pattern, Positions) :-
% Get grid and pattern dimensions.
    gridconv_dims_(Grid, GH, GW),
    gridconv_dims_(Pattern, PH, PW),
% Last valid top-left position.
    RMax is GH - PH,
    CMax is GW - PW,
% Collect matching positions.
    findall(R-C,
        (between(0, RMax, R), between(0, CMax, C),
         gridconv_match_at_(Grid, Pattern, R, C)),
        Positions).

% gridconv_count_pattern(+Grid, +Pattern, -Count)
% Count is the total number of positions where Pattern matches in Grid.
gridconv_count_pattern(Grid, Pattern, Count) :-
% Find all matching positions and count them.
    gridconv_find_pattern(Grid, Pattern, Positions),
    length(Positions, Count).

% gridconv_has_pattern(+Grid, +Pattern)
% Succeeds if Pattern occurs at least once as a subgrid of Grid.
gridconv_has_pattern(Grid, Pattern) :-
% Find at least one match using once for efficiency.
    gridconv_dims_(Grid, GH, GW),
    gridconv_dims_(Pattern, PH, PW),
    RMax is GH - PH,
    CMax is GW - PW,
    once((between(0, RMax, R), between(0, CMax, C),
          gridconv_match_at_(Grid, Pattern, R, C))).

% gridconv_hot_spots(+Grid, +N, +Color, +Threshold, -Cells)
% Cells is the list of (R,C) positions where the count of Color in the
% (2N+1) x (2N+1) window is >= Threshold.
gridconv_hot_spots(Grid, N, Color, Threshold, Cells) :-
% Get dimensions.
    gridconv_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect cells where Color density meets or exceeds threshold.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         gridconv_count_in(Grid, R, C, N, Color, Count),
         Count >= Threshold),
        Cells).

% gridconv_dilate_sq(+Grid, +FgColor, +N, -Result)
% Square structuring element dilation of radius N: a cell becomes FgColor
% if any cell in its (2N+1) x (2N+1) window is FgColor.
gridconv_dilate_sq(Grid, FgColor, N, Result) :-
% Get dimensions.
    gridconv_dims_(Grid, H, W),
% A cell becomes FgColor if window count > 0.
    gridconv_build_(H, W,
        [R, C, V]>>(gridconv_cell_(Grid, R, C, GV),
                    (GV = FgColor -> V = FgColor
                    ; (gridconv_count_in(Grid, R, C, N, FgColor, Count),
                       Count > 0 -> V = FgColor ; V = GV))),
        Result).

% gridconv_erode_sq(+Grid, +FgColor, +N, -Result)
% Square structuring element erosion of radius N: a FgColor cell keeps its
% color only if ALL in-bounds cells in its (2N+1) x (2N+1) window are FgColor.
% Otherwise it becomes background (first non-FgColor cell found in grid).
gridconv_erode_sq(Grid, FgColor, N, Result) :-
% Find background color.
    gridconv_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    (findall(V, (between(0, H1, R), between(0, W1, C),
                 gridconv_cell_(Grid, R, C, V), V \= FgColor), [BgColor|_])
     -> true ; BgColor = bg),
% Build result: FgColor cell survives only if every window cell is FgColor.
    gridconv_build_(H, W,
        [R, C, V]>>(gridconv_cell_(Grid, R, C, GV),
                    (GV = FgColor ->
                        (gridconv_count_inbounds_(Grid, R, C, N, Total),
                         gridconv_count_in(Grid, R, C, N, FgColor, FgCount),
                         (FgCount =:= Total -> V = FgColor ; V = BgColor))
                    ;
                        V = GV)),
        Result).

% gridconv_replace_pattern(+Grid, +Pattern, +Replacement, -Result)
% Result is Grid with the first-found (row-major) occurrence of Pattern
% replaced by Replacement. Pattern and Replacement must have the same dimensions.
% If no match is found, Result = Grid.
gridconv_replace_pattern(Grid, Pattern, Replacement, Result) :-
% Find first matching position.
    gridconv_dims_(Grid, GH, GW),
    gridconv_dims_(Pattern, PH, PW),
    RMax is GH - PH,
    CMax is GW - PW,
    (once((between(0, RMax, R0), between(0, CMax, C0),
           gridconv_match_at_(Grid, Pattern, R0, C0))) ->
% Replace Pattern at (R0,C0) with Replacement.
        gridconv_build_(GH, GW,
            [R, C, V]>>(PR is R - R0, PC is C - C0,
                         (PR >= 0, PR < PH, PC >= 0, PC < PW ->
                             gridconv_cell_(Replacement, PR, PC, V)
                         ;
                             gridconv_cell_(Grid, R, C, V))),
            Result)
    ;
% No match: return Grid unchanged.
        Result = Grid).
