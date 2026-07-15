% border.pl - Layer 146: Concentric Ring (Border) Analysis for 2D Grids (br_* prefix).
% Provides predicates for identifying cells in specific concentric rings, extracting
% ring values and colors, testing ring uniformity, adding and stripping border layers,
% extracting nested inner grids, building depth maps (ring-distance from edge), filling
% specific rings with a new color, and analyzing complete nested ring structures.
%
% Ring convention: ring N contains all cells where min(R, H-1-R, C, W-1-C) = N.
% Ring 0 is the outermost border ring. Ring N is the N-th ring from the outside.
% A 5x5 grid has rings 0, 1, 2 where ring 2 is the single center cell.
:- module(border, [
    % border_ring_cells/3: list of R-C pairs in ring N (row-major order).
    border_ring_cells/3,
    % border_ring_vals/3: list of values in ring N (row-major order).
    border_ring_vals/3,
    % border_ring_color/3: uniform color of ring N; fails if ring is not uniform or empty.
    border_ring_color/3,
    % border_is_uniform_ring/2: succeed if ring N of Grid has a single uniform color.
    border_is_uniform_ring/2,
    % border_add_border/3: add one layer of V cells around Grid; result is (H+2)x(W+2).
    border_add_border/3,
    % border_strip_border/2: remove the outermost ring; result is (H-2)x(W-2) (or empty).
    border_strip_border/2,
    % border_inner_n/3: remove N outermost rings; equivalent to border_strip_border applied N times.
    border_inner_n/3,
    % border_outer_color/2: uniform color of ring 0 (outermost); fails if not uniform.
    border_outer_color/2,
    % border_is_uniform_outer/1: succeed if the outermost ring of Grid is uniform.
    border_is_uniform_outer/1,
    % border_ring_colors/2: list of uniform ring colors [ring0, ring1, ...] from outside in.
    border_ring_colors/2,
    % border_max_ring/2: index of the innermost ring; equals (min(H,W)-1)//2.
    border_max_ring/2,
    % border_is_nested/1: succeed if every ring of Grid is uniform (concentric bullseye).
    border_is_nested/1,
    % border_depth_map/2: grid where each cell holds its ring index N.
    border_depth_map/2,
    % border_fill_ring/4: replace all cells in ring N with value V.
    border_fill_ring/4
]).

% Import list utilities for membership, indexing, and range generation.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/2, append/3]).
% Import higher-order utilities for per-row transformations.
:- use_module(library(apply), [maplist/2, maplist/3]).

% border_dims_(+Grid, -H, -W): get row count H and column count W.
border_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Get column count from the first row; 0 if grid is empty.
    ( H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0 ).

% border_ring_depth_(+H, +W, +R, +C, -D): ring depth of cell (R,C) in an H x W grid.
% D = min(R, H-1-R, C, W-1-C). Ring 0 is outermost; higher D is more central.
border_ring_depth_(H, W, R, C, D) :-
% Compute all four distances from the nearest edge.
    DR1 is R,
    DR2 is H - 1 - R,
    DC1 is C,
    DC2 is W - 1 - C,
% D is the minimum of the four distances.
    D is min(DR1, min(DR2, min(DC1, DC2))).

% border_ring_cells(+Grid, +N, -Cells): R-C pairs in ring N, listed in row-major order.
% Fails or returns [] if N is out of range (greater than border_max_ring).
border_ring_cells(Grid, N, Cells) :-
% Get grid dimensions.
    border_dims_(Grid, H, W),
% Compute max row and column indices.
    H1 is H - 1,
    W1 is W - 1,
% Enumerate all cells and keep those at ring depth N.
    findall(R-C, (
        between(0, H1, R),
        between(0, W1, C),
        border_ring_depth_(H, W, R, C, D),
        D =:= N
    ), Cells).

% border_ring_vals(+Grid, +N, -Vals): values at ring N in row-major order.
border_ring_vals(Grid, N, Vals) :-
% Get cells in ring N.
    border_ring_cells(Grid, N, Cells),
% Collect the value at each cell.
    findall(V, (
        member(R-C, Cells),
        nth0(R, Grid, Row),
        nth0(C, Row, V)
    ), Vals).

% border_ring_color(+Grid, +N, -Color): uniform color of ring N.
% Fails if the ring is empty or contains more than one distinct value.
border_ring_color(Grid, N, Color) :-
% Collect ring values.
    border_ring_vals(Grid, N, Vals),
% Ring must be non-empty.
    Vals \= [],
% All values must be identical to the first; use sort to get distinct values.
    sort(Vals, [Color]).

% border_is_uniform_ring(+Grid, +N): succeed if ring N has exactly one distinct value.
border_is_uniform_ring(Grid, N) :-
    border_ring_color(Grid, N, _).

% border_add_border_(+Row, +V, -NewRow): prepend and append V to a row.
border_add_border_(Row, V, NewRow) :-
    append([V|Row], [V], NewRow).

% border_add_border(+Grid, +V, -Out): add one layer of V around Grid.
% Out has H+2 rows and W+2 columns.
border_add_border(Grid, V, Out) :-
% Get original dimensions.
    border_dims_(Grid, _H, W),
% Build the top and bottom rows of all Vs.
    NewW is W + 2,
    length(TopBot, NewW),
    maplist(=(V), TopBot),
% Build the middle rows: each original row gets V prepended and appended.
    findall(NewRow, (member(Row, Grid), append([V|Row], [V], NewRow)), MiddleRows),
% Assemble: TopBot, middle rows, TopBot.
    append([[TopBot|MiddleRows], [TopBot]], Out).

% border_strip_border(+Grid, -Inner): remove the outermost ring from Grid.
% Inner is the (H-2) x (W-2) sub-grid. If H < 2 or W < 2, Inner = [].
border_strip_border(Grid, Inner) :-
% Get dimensions.
    border_dims_(Grid, H, W),
% Compute bounds of the inner rows and columns.
    H2 is H - 2,
    W2 is W - 2,
% If the grid is too small, result is empty.
    ( H2 > 0, W2 > 0 ->
        findall(InRow, (
            between(1, H2, R),
            nth0(R, Grid, Row),
            findall(V, (between(1, W2, C), nth0(C, Row, V)), InRow)
        ), Inner)
    ;
        Inner = []
    ).

% border_inner_n(+Grid, +N, -Inner): strip N outermost rings from Grid.
% N=0: identity. N>0: recursive strip.
border_inner_n(Grid, 0, Grid) :- !.
% Strip one border, then recurse for the remaining N-1 strips.
border_inner_n(Grid, N, Inner) :-
    N > 0,
    N1 is N - 1,
    border_strip_border(Grid, Stripped),
    border_inner_n(Stripped, N1, Inner).

% border_outer_color(+Grid, -V): uniform color of the outermost ring (ring 0).
% Fails if the outermost ring is not uniform.
border_outer_color(Grid, V) :-
    border_ring_color(Grid, 0, V).

% border_is_uniform_outer(+Grid): succeed if the outermost ring is uniform.
border_is_uniform_outer(Grid) :-
    border_outer_color(Grid, _).

% border_ring_colors_(+Grid, +N, +MaxN, -Colors): accumulate uniform ring colors.
border_ring_colors_(_, N, MaxN, []) :-
% Terminate when we exceed the max ring index.
    N > MaxN,
    !.
border_ring_colors_(Grid, N, MaxN, [C|Rest]) :-
% Try to get ring N's uniform color.
    border_ring_color(Grid, N, C),
    !,
% Recurse for the next ring.
    N1 is N + 1,
    border_ring_colors_(Grid, N1, MaxN, Rest).
% Ring N is non-uniform; stop collecting.
border_ring_colors_(_, _, _, []).

% border_ring_colors(+Grid, -Colors): list of uniform ring colors from outside in.
% Collects ring colors starting at ring 0 until a non-uniform ring is encountered.
border_ring_colors(Grid, Colors) :-
% Get the maximum ring index.
    border_max_ring(Grid, MaxN),
    border_ring_colors_(Grid, 0, MaxN, Colors).

% border_max_ring(+Grid, -N): index of the innermost ring.
% N = (min(H, W) - 1) // 2.
border_max_ring(Grid, N) :-
% Get grid dimensions.
    border_dims_(Grid, H, W),
% Compute the maximum ring index.
    MinHW is min(H, W),
    N is (MinHW - 1) // 2.

% border_is_nested(+Grid): succeed if every ring of Grid is uniform.
% Equivalent to border_ring_colors returning a list of length (max_ring + 1).
border_is_nested(Grid) :-
% Get max ring index.
    border_max_ring(Grid, MaxN),
% Check that every ring from 0 to MaxN is uniform.
    forall(between(0, MaxN, N), border_is_uniform_ring(Grid, N)).

% border_depth_map(+Grid, -DepthGrid): grid where DepthGrid[R][C] = ring index of (R,C).
border_depth_map(Grid, DepthGrid) :-
% Get dimensions.
    border_dims_(Grid, H, W),
% Compute max row and column indices.
    H1 is H - 1,
    W1 is W - 1,
% Build depth map row by row.
    findall(DepthRow, (
        between(0, H1, R),
        findall(D, (
            between(0, W1, C),
            border_ring_depth_(H, W, R, C, D)
        ), DepthRow)
    ), DepthGrid).

% border_replace_cell_if_(+H, +W, +N, +V, +R, +C, +OldV, -NewV):
% replace OldV with V if (R,C) is in ring N; otherwise keep OldV.
border_replace_cell_if_(H, W, N, V, R, C, _OldV, V) :-
% Check if (R,C) is at ring depth N.
    border_ring_depth_(H, W, R, C, D),
    D =:= N,
    !.
% Cell is not in ring N; keep the original value.
border_replace_cell_if_(_, _, _, _, _, _, OldV, OldV).

% border_fill_ring(+Grid, +N, +V, -Out): replace all cells in ring N with value V.
border_fill_ring(Grid, N, V, Out) :-
% Get dimensions.
    border_dims_(Grid, H, W),
% Compute max row and column indices.
    H1 is H - 1,
    W1 is W - 1,
% Build output row by row.
    findall(NewRow, (
        between(0, H1, R),
        nth0(R, Grid, Row),
        findall(NewV, (
            between(0, W1, C),
            nth0(C, Row, OldV),
            border_replace_cell_if_(H, W, N, V, R, C, OldV, NewV)
        ), NewRow)
    ), Out).
