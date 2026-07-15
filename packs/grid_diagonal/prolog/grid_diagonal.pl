:- module(grid_diagonal, [
    grid_diagonal_main_diag/3,
    grid_diagonal_anti_diag/3,
    grid_diagonal_trace/2,
    grid_diagonal_all_main_diags/2,
    grid_diagonal_all_anti_diags/2,
    grid_diagonal_main_count/4,
    grid_diagonal_anti_count/4,
    grid_diagonal_main_uniform/3,
    grid_diagonal_anti_uniform/3,
    grid_diagonal_set_main_diag/4,
    grid_diagonal_set_anti_diag/4,
    grid_diagonal_uniform_main_diags/2,
    grid_diagonal_uniform_anti_diags/2,
    grid_diagonal_diag_length/3
]).
% griddiag.pl - Layer 215: Grid Diagonal Analysis (gdi_* prefix).
% Extracts, analyzes, and modifies main and anti-diagonals of symbolic grids.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% Main diagonal k: cells (R,C) where C - R = K (k=0 is the principal diagonal).
% Anti-diagonal k: cells (R,C) where R + C = K (k=0 is top-left corner).
:- use_module(library(lists), [
    nth0/3, member/2
]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
grid_diagonal_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed); fails if out of bounds.
grid_diagonal_cell_(Grid, R, C, V) :-
% Select row R.
    nth0(R, Grid, Row),
% Select column C.
    nth0(C, Row, V).

% Build a new H x W grid using a lambda Goal(R, C, V).
grid_diagonal_build_(H, W, Goal, Grid) :-
% Compute last indices.
    H1 is H - 1, W1 is W - 1,
% Collect rows.
    findall(Row,
        (between(0, H1, R),
         findall(V, (between(0, W1, C), call(Goal, R, C, V)), Row)),
        Grid).

% Valid (R, C) coordinates for main diagonal k in an H x W grid.
% C - R = K → R in [max(0,-K), min(H-1,W-1-K)], C = R+K.
grid_diagonal_main_rc_(H, W, K, R, C) :-
    RMin is max(0, -K),
    RMax is min(H - 1, W - 1 - K),
    RMin =< RMax,
    between(RMin, RMax, R),
    C is R + K.

% Valid (R, C) coordinates for anti-diagonal k in an H x W grid.
% R + C = K → C in [max(0,K-H+1), min(W-1,K)], R = K-C.
grid_diagonal_anti_rc_(H, W, K, R, C) :-
    CMin is max(0, K - H + 1),
    CMax is min(W - 1, K),
    CMin =< CMax,
    between(CMin, CMax, C),
    R is K - C.

% Test if all elements of a non-empty list are equal.
grid_diagonal_all_eq_([]).
grid_diagonal_all_eq_([_]).
grid_diagonal_all_eq_([A, A | Rest]) :- grid_diagonal_all_eq_([A | Rest]).

% --- PUBLIC PREDICATES ---

% grid_diagonal_main_diag(+Grid, +K, -Vals)
% Vals is the list of color values on the K-th main diagonal.
% Main diagonal K: cells (R,C) where C - R = K, in ascending R order.
% K = 0: principal diagonal from (0,0). K > 0: above. K < 0: below.
grid_diagonal_main_diag(Grid, K, Vals) :-
% Get dimensions.
    grid_diagonal_dims_(Grid, H, W),
% Collect values along the diagonal.
    findall(V,
        (grid_diagonal_main_rc_(H, W, K, R, C),
         grid_diagonal_cell_(Grid, R, C, V)),
        Vals).

% grid_diagonal_anti_diag(+Grid, +K, -Vals)
% Vals is the list of color values on the K-th anti-diagonal.
% Anti-diagonal K: cells (R,C) where R + C = K, in ascending C order.
% K = 0: only cell (0,0). K = H+W-2: bottom-right corner.
grid_diagonal_anti_diag(Grid, K, Vals) :-
% Get dimensions.
    grid_diagonal_dims_(Grid, H, W),
% Collect values along the anti-diagonal.
    findall(V,
        (grid_diagonal_anti_rc_(H, W, K, R, C),
         grid_diagonal_cell_(Grid, R, C, V)),
        Vals).

% grid_diagonal_trace(+Grid, -Vals)
% Vals is the list of values on the principal diagonal: (0,0),(1,1),...
% Length is min(H, W).
grid_diagonal_trace(Grid, Vals) :-
% The principal diagonal is main diagonal 0.
    grid_diagonal_main_diag(Grid, 0, Vals).

% grid_diagonal_all_main_diags(+Grid, -Diags)
% Diags is the list of all main diagonals, ordered from K = -(H-1) to K = W-1.
% Each element is the Vals list for that diagonal.
grid_diagonal_all_main_diags(Grid, Diags) :-
% Get dimensions.
    grid_diagonal_dims_(Grid, H, W),
    KMin is -(H - 1),
    KMax is W - 1,
% Collect all diagonals in order.
    findall(Vals,
        (between(KMin, KMax, K),
         grid_diagonal_main_diag(Grid, K, Vals)),
        Diags).

% grid_diagonal_all_anti_diags(+Grid, -Diags)
% Diags is the list of all anti-diagonals, ordered from K = 0 to K = H+W-2.
% Each element is the Vals list for that anti-diagonal.
grid_diagonal_all_anti_diags(Grid, Diags) :-
% Get dimensions.
    grid_diagonal_dims_(Grid, H, W),
    KMax is H + W - 2,
% Collect all anti-diagonals in order.
    findall(Vals,
        (between(0, KMax, K),
         grid_diagonal_anti_diag(Grid, K, Vals)),
        Diags).

% grid_diagonal_main_count(+Grid, +K, +Color, -Count)
% Count is the number of cells of Color on the K-th main diagonal.
grid_diagonal_main_count(Grid, K, Color, Count) :-
% Get the diagonal values.
    grid_diagonal_main_diag(Grid, K, Vals),
% Count Color occurrences.
    findall(1, member(Color, Vals), Ones),
    length(Ones, Count).

% grid_diagonal_anti_count(+Grid, +K, +Color, -Count)
% Count is the number of cells of Color on the K-th anti-diagonal.
grid_diagonal_anti_count(Grid, K, Color, Count) :-
% Get the anti-diagonal values.
    grid_diagonal_anti_diag(Grid, K, Vals),
% Count Color occurrences.
    findall(1, member(Color, Vals), Ones),
    length(Ones, Count).

% grid_diagonal_main_uniform(+Grid, +K, -Bool)
% Bool is yes if all cells on main diagonal K are the same color; no otherwise.
% Fails if the diagonal is empty.
grid_diagonal_main_uniform(Grid, K, Bool) :-
% Get diagonal values.
    grid_diagonal_main_diag(Grid, K, Vals),
% Diagonal must be non-empty.
    Vals \= [],
% Check uniformity.
    (grid_diagonal_all_eq_(Vals) -> Bool = yes ; Bool = no).

% grid_diagonal_anti_uniform(+Grid, +K, -Bool)
% Bool is yes if all cells on anti-diagonal K are the same color; no otherwise.
grid_diagonal_anti_uniform(Grid, K, Bool) :-
% Get anti-diagonal values.
    grid_diagonal_anti_diag(Grid, K, Vals),
% Diagonal must be non-empty.
    Vals \= [],
% Check uniformity.
    (grid_diagonal_all_eq_(Vals) -> Bool = yes ; Bool = no).

% grid_diagonal_set_main_diag(+Grid, +K, +Color, -Result)
% Result is Grid with all cells on main diagonal K set to Color.
grid_diagonal_set_main_diag(Grid, K, Color, Result) :-
% Get dimensions.
    grid_diagonal_dims_(Grid, H, W),
% Collect cells on diagonal K.
    findall(R-C, grid_diagonal_main_rc_(H, W, K, R, C), DiagCells),
% Build result: replace diagonal cells with Color.
    grid_diagonal_build_(H, W,
        [R, C, V]>>(grid_diagonal_cell_(Grid, R, C, Orig),
                    (memberchk(R-C, DiagCells) -> V = Color ; V = Orig)),
        Result).

% grid_diagonal_set_anti_diag(+Grid, +K, +Color, -Result)
% Result is Grid with all cells on anti-diagonal K set to Color.
grid_diagonal_set_anti_diag(Grid, K, Color, Result) :-
% Get dimensions.
    grid_diagonal_dims_(Grid, H, W),
% Collect cells on anti-diagonal K.
    findall(R-C, grid_diagonal_anti_rc_(H, W, K, R, C), DiagCells),
% Build result: replace anti-diagonal cells with Color.
    grid_diagonal_build_(H, W,
        [R, C, V]>>(grid_diagonal_cell_(Grid, R, C, Orig),
                    (memberchk(R-C, DiagCells) -> V = Color ; V = Orig)),
        Result).

% grid_diagonal_uniform_main_diags(+Grid, -Ks)
% Ks is the list of K values (from -(H-1) to W-1) for which the K-th main
% diagonal is uniform (all the same color).
grid_diagonal_uniform_main_diags(Grid, Ks) :-
% Get dimensions.
    grid_diagonal_dims_(Grid, H, W),
    KMin is -(H - 1),
    KMax is W - 1,
% Collect K values of uniform diagonals.
    findall(K,
        (between(KMin, KMax, K),
         grid_diagonal_main_uniform(Grid, K, yes)),
        Ks).

% grid_diagonal_uniform_anti_diags(+Grid, -Ks)
% Ks is the list of K values (from 0 to H+W-2) for which the K-th anti-diagonal
% is uniform (all the same color).
grid_diagonal_uniform_anti_diags(Grid, Ks) :-
% Get dimensions.
    grid_diagonal_dims_(Grid, H, W),
    KMax is H + W - 2,
% Collect K values of uniform anti-diagonals.
    findall(K,
        (between(0, KMax, K),
         grid_diagonal_anti_uniform(Grid, K, yes)),
        Ks).

% grid_diagonal_diag_length(+Grid, +K, -Len)
% Len is the number of cells on the K-th main diagonal of Grid.
grid_diagonal_diag_length(Grid, K, Len) :-
% Get the diagonal and count its cells.
    grid_diagonal_main_diag(Grid, K, Vals),
    length(Vals, Len).
