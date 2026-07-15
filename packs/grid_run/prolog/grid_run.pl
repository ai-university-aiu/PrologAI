:- module(grid_run, [
    grid_run_row_runs/3,
    grid_run_col_runs/3,
    grid_run_all_row_runs/2,
    grid_run_all_col_runs/2,
    grid_run_decode/2,
    grid_run_run_count/3,
    grid_run_uniform_row/3,
    grid_run_uniform_col/3,
    grid_run_is_striped_h/1,
    grid_run_is_striped_v/1,
    grid_run_stripe_colors_h/2,
    grid_run_stripe_colors_v/2,
    grid_run_max_run/4,
    grid_run_alternating/2
]).
% gridrun.pl - Layer 203: Grid Run-Length Encoding and Stripe Analysis (grl_* prefix).
% All predicates operate on raw grid format: list of rows, each row a list
% of color atoms, 0-indexed (row 0 = top, col 0 = left).
% A "run" is a maximal sequence of adjacent identical color values, encoded
% as the pair Color-Length. Run-length encoding (RLE) of a list is the
% ordered list of such runs; decoding recovers the original list.
:- use_module(library(lists), [
    nth0/3, member/2, append/2, append/3, list_to_set/2
]).
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
grid_run_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row; 0 for an empty grid.
    (H > 0 -> Grid = [First|_], length(First, W) ; W = 0).

% Encode a flat list into run-length pairs Color-Length.
grid_run_list_runs_([], []) :- !.
grid_run_list_runs_([V|Rest], Runs) :-
    grid_run_run_acc_(V, 1, Rest, Runs).

% Accumulate a run of V; when the color changes, emit V-N and start new run.
grid_run_run_acc_(V, N, [], [V-N]) :- !.
grid_run_run_acc_(V, N, [V|Rest], Runs) :- !,
% Same color: extend the current run.
    N1 is N + 1,
    grid_run_run_acc_(V, N1, Rest, Runs).
grid_run_run_acc_(V, N, [W|Rest], [V-N|Runs]) :-
% Different color: emit run, start fresh.
    grid_run_run_acc_(W, 1, Rest, Runs).

% Extract column C of Grid as a flat list.
grid_run_col_list_(Grid, C, Col) :-
    grid_run_dims_(Grid, H, _),
    H1 is H - 1,
    findall(V, (between(0, H1, R), nth0(R, Grid, Row), nth0(C, Row, V)), Col).

% --- EXPORTED PREDICATES ---

% grid_run_row_runs(+Grid, +R, -Runs)
% Runs is the run-length encoding of row R of Grid. Each element is Color-Len
% representing a maximal run of Len consecutive copies of Color. Row 0 is top.
grid_run_row_runs(Grid, R, Runs) :-
    nth0(R, Grid, Row),
    grid_run_list_runs_(Row, Runs).

% grid_run_col_runs(+Grid, +C, -Runs)
% Runs is the run-length encoding of column C of Grid. Column 0 is leftmost.
grid_run_col_runs(Grid, C, Runs) :-
    grid_run_col_list_(Grid, C, Col),
    grid_run_list_runs_(Col, Runs).

% grid_run_all_row_runs(+Grid, -AllRuns)
% AllRuns is a list with one element per row: the run-length encoding of that row.
% AllRuns[R] is the run list for row R.
grid_run_all_row_runs(Grid, AllRuns) :-
    grid_run_dims_(Grid, H, _),
    H1 is H - 1,
    findall(Runs, (between(0, H1, R), grid_run_row_runs(Grid, R, Runs)), AllRuns).

% grid_run_all_col_runs(+Grid, -AllRuns)
% AllRuns is a list with one element per column: the run-length encoding of that column.
grid_run_all_col_runs(Grid, AllRuns) :-
    grid_run_dims_(Grid, _, W),
    W1 is W - 1,
    findall(Runs, (between(0, W1, C), grid_run_col_runs(Grid, C, Runs)), AllRuns).

% grid_run_decode(+Runs, -List)
% List is the flat color list recovered from run-length encoding Runs.
% Each Color-Len pair in Runs contributes Len consecutive copies of Color.
grid_run_decode(Runs, List) :-
    findall(V, (member(C-N, Runs), between(1, N, _), V = C), List).

% grid_run_run_count(+Grid, +R, -N)
% N is the number of distinct runs in row R of Grid. A uniform row has N=1.
grid_run_run_count(Grid, R, N) :-
    grid_run_row_runs(Grid, R, Runs),
    length(Runs, N).

% grid_run_uniform_row(+Grid, +R, -Color)
% Succeed if row R of Grid is all one Color (single run of length W).
% Color is that uniform color. Fails if the row contains more than one color.
grid_run_uniform_row(Grid, R, Color) :-
    grid_run_row_runs(Grid, R, [Color-_]).

% grid_run_uniform_col(+Grid, +C, -Color)
% Succeed if column C of Grid is all one Color (single run of length H).
grid_run_uniform_col(Grid, C, Color) :-
    grid_run_col_runs(Grid, C, [Color-_]).

% grid_run_is_striped_h(+Grid)
% Succeed if every row of Grid is uniform (each row is a single-color stripe).
% A horizontally striped grid looks like solid color bands stacked vertically.
grid_run_is_striped_h(Grid) :-
    grid_run_dims_(Grid, H, _),
    H1 is H - 1,
    \+ (between(0, H1, R), \+ grid_run_uniform_row(Grid, R, _)).

% grid_run_is_striped_v(+Grid)
% Succeed if every column of Grid is uniform (each column is a single-color stripe).
% A vertically striped grid looks like solid color bands arranged left-to-right.
grid_run_is_striped_v(Grid) :-
    grid_run_dims_(Grid, _, W),
    W1 is W - 1,
    \+ (between(0, W1, C), \+ grid_run_uniform_col(Grid, C, _)).

% grid_run_stripe_colors_h(+Grid, -Colors)
% Colors is the list of row colors for a horizontally striped grid. Colors[R]
% is the single color of row R. Fails if any row is not uniform.
grid_run_stripe_colors_h(Grid, Colors) :-
    grid_run_dims_(Grid, H, _),
    H1 is H - 1,
    findall(Color, (between(0, H1, R), grid_run_uniform_row(Grid, R, Color)), Colors),
    length(Colors, H).

% grid_run_stripe_colors_v(+Grid, -Colors)
% Colors is the list of column colors for a vertically striped grid. Colors[C]
% is the single color of column C. Fails if any column is not uniform.
grid_run_stripe_colors_v(Grid, Colors) :-
    grid_run_dims_(Grid, _, W),
    W1 is W - 1,
    findall(Color, (between(0, W1, C), grid_run_uniform_col(Grid, C, Color)), Colors),
    length(Colors, W).

% grid_run_max_run(+Grid, +R, -Color, -Len)
% Color and Len describe the longest run in row R. Ties are broken by
% first occurrence (leftmost longest run). Fails if row R is empty.
grid_run_max_run(Grid, R, Color, Len) :-
    grid_run_row_runs(Grid, R, Runs),
    Runs = [_|_],
    findall(NegLen-C, (member(C-L, Runs), NegLen is -L), Keyed),
    msort(Keyed, [NegBest-Color|_]),
    Len is -NegBest.

% grid_run_alternating(+Grid, +R)
% Succeed if row R of Grid strictly alternates between exactly two colors:
% the pattern is A,B,A,B,... or B,A,B,A,... with at least 2 cells.
% Fails for rows with fewer than 2 cells, uniform rows, or more than 2 colors.
grid_run_alternating(Grid, R) :-
    grid_run_row_runs(Grid, R, Runs),
    Runs = [_-1|_],
% All runs must have length exactly 1.
    \+ (member(_-L, Runs), L \= 1),
% Exactly two colors must appear.
    findall(C, member(C-_, Runs), Colors),
    list_to_set(Colors, [_,_]),
% At least 2 cells.
    length(Runs, NRuns),
    NRuns >= 2.
