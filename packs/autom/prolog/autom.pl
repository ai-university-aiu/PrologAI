% autom.pl - Layer 120: Cellular Automaton Neighborhood Aggregation (at_* prefix).
% Provides grid-wide neighborhood count grids, boolean neighbor tests,
% isolated cell detection, birth rules, majority voting, and one step of
% Conway's Game of Life for symbolic grid reasoning.
:- module(autom, [
    at_count_nbrs_4/3, at_count_nbrs_8/3,
    at_count_same_4/2, at_count_same_8/2,
    at_any_nbr_4/3, at_all_nbrs_4/3,
    at_any_nbr_8/3, at_all_nbrs_8/3,
    at_isolated_4/3, at_isolated_8/3,
    at_birth_4/5, at_birth_8/5,
    at_majority_4/3, at_step_gol/2
]).
% Import member/2 for offset enumeration and value membership.
:- use_module(library(lists), [member/2, nth0/3, max_list/2]).

% at_offs4_: 4-connected direction offsets as DR-DC pairs.
at_offs4_([-1-0, 1-0, 0-(-1), 0-1]).

% at_offs8_: 8-connected direction offsets as DR-DC pairs.
at_offs8_([-1-(-1), -1-0, -1-1, 0-(-1), 0-1, 1-(-1), 1-0, 1-1]).

% at_count_nbrs_4(+Grid, +V, -CGrid): CGrid[R][C] = count of V-valued 4-neighbors of (R,C).
at_count_nbrs_4(Grid, V, CGrid) :-
% compute last row index
    length(Grid, H), H1 is H - 1,
% compute last column index from first row; 0 for empty grid
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% get the 4-direction offsets once
    at_offs4_(Offs),
% outer findall builds one CRow per row index R
    findall(CRow, (
        between(0, H1, R),
% inner findall builds one count N per column index C
        findall(N, (
            between(0, W1, C),
% innermost findall counts in-bounds 4-neighbors with value V
            findall(_, (
                member(DR-DC, Offs),
                NR is R + DR, NC is C + DC,
                nth0(NR, Grid, NRow), nth0(NC, NRow, V)
            ), Ks),
% N = number of V-valued 4-neighbors
            length(Ks, N)
        ), CRow)
    ), CGrid).

% at_count_nbrs_8(+Grid, +V, -CGrid): CGrid[R][C] = count of V-valued 8-neighbors of (R,C).
at_count_nbrs_8(Grid, V, CGrid) :-
% compute last row index
    length(Grid, H), H1 is H - 1,
% compute last column index from first row; 0 for empty grid
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% get the 8-direction offsets once
    at_offs8_(Offs),
% outer findall builds one CRow per row index R
    findall(CRow, (
        between(0, H1, R),
% inner findall builds one count N per column index C
        findall(N, (
            between(0, W1, C),
% innermost findall counts in-bounds 8-neighbors with value V
            findall(_, (
                member(DR-DC, Offs),
                NR is R + DR, NC is C + DC,
                nth0(NR, Grid, NRow), nth0(NC, NRow, V)
            ), Ks),
% N = number of V-valued 8-neighbors
            length(Ks, N)
        ), CRow)
    ), CGrid).

% at_count_same_4(+Grid, -CGrid): CGrid[R][C] = count of 4-neighbors equal to Grid[R][C].
at_count_same_4(Grid, CGrid) :-
% compute last row index
    length(Grid, H), H1 is H - 1,
% compute last column index from first row; 0 for empty grid
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% get the 4-direction offsets once
    at_offs4_(Offs),
% outer findall builds one CRow per row index R
    findall(CRow, (
        between(0, H1, R),
% inner findall builds one count N per column index C
        findall(N, (
            between(0, W1, C),
% retrieve the cell value at (R, C)
            nth0(R, Grid, Row), nth0(C, Row, Val),
% innermost findall counts in-bounds 4-neighbors sharing Val
            findall(_, (
                member(DR-DC, Offs),
                NR is R + DR, NC is C + DC,
                nth0(NR, Grid, NRow), nth0(NC, NRow, Val)
            ), Ks),
% N = number of same-valued 4-neighbors
            length(Ks, N)
        ), CRow)
    ), CGrid).

% at_count_same_8(+Grid, -CGrid): CGrid[R][C] = count of 8-neighbors equal to Grid[R][C].
at_count_same_8(Grid, CGrid) :-
% compute last row index
    length(Grid, H), H1 is H - 1,
% compute last column index from first row; 0 for empty grid
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% get the 8-direction offsets once
    at_offs8_(Offs),
% outer findall builds one CRow per row index R
    findall(CRow, (
        between(0, H1, R),
% inner findall builds one count N per column index C
        findall(N, (
            between(0, W1, C),
% retrieve the cell value at (R, C)
            nth0(R, Grid, Row), nth0(C, Row, Val),
% innermost findall counts in-bounds 8-neighbors sharing Val
            findall(_, (
                member(DR-DC, Offs),
                NR is R + DR, NC is C + DC,
                nth0(NR, Grid, NRow), nth0(NC, NRow, Val)
            ), Ks),
% N = number of same-valued 8-neighbors
            length(Ks, N)
        ), CRow)
    ), CGrid).

% at_any_nbr_4(+Grid, +V, -BGrid): BGrid[R][C] = 1 if any in-bounds 4-neighbor equals V; else 0.
at_any_nbr_4(Grid, V, BGrid) :-
% compute last row index
    length(Grid, H), H1 is H - 1,
% compute last column index from first row; 0 for empty grid
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% outer findall builds one BRow per row index R
    findall(BRow, (
        between(0, H1, R),
% inner findall builds one bit B per column index C
        findall(B, (
            between(0, W1, C),
% B = 1 if at_has_nbr_4_ succeeds (any V 4-neighbor exists); else 0
            (at_has_nbr_4_(Grid, R, C, V) -> B = 1 ; B = 0)
        ), BRow)
    ), BGrid).

% at_has_nbr_4_(+Grid, +R, +C, +V): succeed if (R,C) has at least one V-valued 4-neighbor.
at_has_nbr_4_(Grid, R, C, V) :-
% try each 4-direction; cut on first V-neighbor found
    member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
    NR is R + DR, NC is C + DC,
% nth0 fails on out-of-bounds; succeed only when cell value equals V
    nth0(NR, Grid, NRow), nth0(NC, NRow, V), !.

% at_all_nbrs_4(+Grid, +V, -BGrid): BGrid[R][C] = 1 if all in-bounds 4-neighbors equal V; else 0.
% A cell with no in-bounds 4-neighbors vacuously satisfies the condition (returns 1).
at_all_nbrs_4(Grid, V, BGrid) :-
% compute last row index
    length(Grid, H), H1 is H - 1,
% compute last column index from first row; 0 for empty grid
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% outer findall builds one BRow per row index R
    findall(BRow, (
        between(0, H1, R),
% inner findall builds one bit B per column index C
        findall(B, (
            between(0, W1, C),
% B = 1 if forall succeeds: every in-bounds 4-neighbor equals V
            (   forall(
                    (member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
                     NR is R + DR, NC is C + DC,
                     nth0(NR, Grid, NRow), nth0(NC, NRow, _)),
                    nth0(NC, NRow, V)
                )
            ->  B = 1
            ;   B = 0
            )
        ), BRow)
    ), BGrid).

% at_any_nbr_8(+Grid, +V, -BGrid): BGrid[R][C] = 1 if any in-bounds 8-neighbor equals V; else 0.
at_any_nbr_8(Grid, V, BGrid) :-
% compute last row index
    length(Grid, H), H1 is H - 1,
% compute last column index from first row; 0 for empty grid
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% outer findall builds one BRow per row index R
    findall(BRow, (
        between(0, H1, R),
% inner findall builds one bit B per column index C
        findall(B, (
            between(0, W1, C),
% B = 1 if at_has_nbr_8_ succeeds (any V 8-neighbor exists); else 0
            (at_has_nbr_8_(Grid, R, C, V) -> B = 1 ; B = 0)
        ), BRow)
    ), BGrid).

% at_has_nbr_8_(+Grid, +R, +C, +V): succeed if (R,C) has at least one V-valued 8-neighbor.
at_has_nbr_8_(Grid, R, C, V) :-
% try each 8-direction; cut on first V-neighbor found
    member(DR-DC, [-1-(-1), -1-0, -1-1, 0-(-1), 0-1, 1-(-1), 1-0, 1-1]),
    NR is R + DR, NC is C + DC,
% nth0 fails on out-of-bounds; succeed only when cell value equals V
    nth0(NR, Grid, NRow), nth0(NC, NRow, V), !.

% at_all_nbrs_8(+Grid, +V, -BGrid): BGrid[R][C] = 1 if all in-bounds 8-neighbors equal V; else 0.
at_all_nbrs_8(Grid, V, BGrid) :-
% compute last row index
    length(Grid, H), H1 is H - 1,
% compute last column index from first row; 0 for empty grid
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% outer findall builds one BRow per row index R
    findall(BRow, (
        between(0, H1, R),
% inner findall builds one bit B per column index C
        findall(B, (
            between(0, W1, C),
% B = 1 if forall succeeds: every in-bounds 8-neighbor equals V
            (   forall(
                    (member(DR-DC, [-1-(-1), -1-0, -1-1, 0-(-1), 0-1, 1-(-1), 1-0, 1-1]),
                     NR is R + DR, NC is C + DC,
                     nth0(NR, Grid, NRow), nth0(NC, NRow, _)),
                    nth0(NC, NRow, V)
                )
            ->  B = 1
            ;   B = 0
            )
        ), BRow)
    ), BGrid).

% at_isolated_4(+Grid, +V, -Cells): sorted R-C pairs of V cells with no V-valued 4-neighbor.
at_isolated_4(Grid, V, Cells) :-
% compute last row index
    length(Grid, H), H1 is H - 1,
% compute last column index from first row; 0 for empty grid
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% collect all V-valued cells that have no V 4-neighbor
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
% succeed only if no V-valued 4-neighbor exists
        \+ at_has_nbr_4_(Grid, R, C, V)
    ), Unsorted),
% sort to canonical order
    sort(Unsorted, Cells).

% at_isolated_8(+Grid, +V, -Cells): sorted R-C pairs of V cells with no V-valued 8-neighbor.
at_isolated_8(Grid, V, Cells) :-
% compute last row index
    length(Grid, H), H1 is H - 1,
% compute last column index from first row; 0 for empty grid
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% collect all V-valued cells that have no V 8-neighbor
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
% succeed only if no V-valued 8-neighbor exists
        \+ at_has_nbr_8_(Grid, R, C, V)
    ), Unsorted),
% sort to canonical order
    sort(Unsorted, Cells).

% at_birth_4(+Grid, +Dead, +Live, +N, -Grid2): Dead cells with exactly N Live 4-neighbors become Live.
% All other cells retain their current value.
at_birth_4(Grid, Dead, Live, N, Grid2) :-
% compute last row index
    length(Grid, H), H1 is H - 1,
% compute last column index from first row; 0 for empty grid
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% get 4-direction offsets
    at_offs4_(Offs),
% outer findall builds one output row per row index R
    findall(Row2, (
        between(0, H1, R),
% inner findall builds one output cell per column index C
        findall(V2, (
            between(0, W1, C),
            nth0(R, Grid, Row), nth0(C, Row, V),
% count Live-valued 4-neighbors at (R,C)
            findall(_, (
                member(DR-DC, Offs),
                NR is R + DR, NC is C + DC,
                nth0(NR, Grid, NRow), nth0(NC, NRow, Live)
            ), Ks),
            length(Ks, LN),
% Dead cell with exactly N Live neighbors becomes Live; otherwise keep V
            (V == Dead, LN =:= N -> V2 = Live ; V2 = V)
        ), Row2)
    ), Grid2).

% at_birth_8(+Grid, +Dead, +Live, +N, -Grid2): Dead cells with exactly N Live 8-neighbors become Live.
at_birth_8(Grid, Dead, Live, N, Grid2) :-
% compute last row index
    length(Grid, H), H1 is H - 1,
% compute last column index from first row; 0 for empty grid
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% get 8-direction offsets
    at_offs8_(Offs),
% outer findall builds one output row per row index R
    findall(Row2, (
        between(0, H1, R),
% inner findall builds one output cell per column index C
        findall(V2, (
            between(0, W1, C),
            nth0(R, Grid, Row), nth0(C, Row, V),
% count Live-valued 8-neighbors at (R,C)
            findall(_, (
                member(DR-DC, Offs),
                NR is R + DR, NC is C + DC,
                nth0(NR, Grid, NRow), nth0(NC, NRow, Live)
            ), Ks),
            length(Ks, LN),
% Dead cell with exactly N Live neighbors becomes Live; otherwise keep V
            (V == Dead, LN =:= N -> V2 = Live ; V2 = V)
        ), Row2)
    ), Grid2).

% at_majority_4(+Grid, +Bg, -Grid2): each cell takes the majority value among itself and
% its in-bounds 4-neighbors. Ties are broken by returning Bg.
at_majority_4(Grid, Bg, Grid2) :-
% compute last row index
    length(Grid, H), H1 is H - 1,
% compute last column index from first row; 0 for empty grid
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% outer findall builds one output row per row index R
    findall(Row2, (
        between(0, H1, R),
% inner findall builds one output cell per column index C
        findall(MV, (
            between(0, W1, C),
% delegate to at_maj4_cell_ to compute the majority value
            at_maj4_cell_(Grid, Bg, R, C, MV)
        ), Row2)
    ), Grid2).

% at_maj4_cell_(+Grid, +Bg, +R, +C, -MV): compute majority value at (R,C) over self + 4-nbrs.
at_maj4_cell_(Grid, Bg, R, C, MV) :-
% collect self + all in-bounds 4-neighbors as a value list
    findall(Val, (
        member(DR-DC, [0-0, -1-0, 1-0, 0-(-1), 0-1]),
        NR is R + DR, NC is C + DC,
        nth0(NR, Grid, NRow), nth0(NC, NRow, Val)
    ), Vals),
% compute the majority value with tie-breaking to Bg
    at_mode_(Vals, Bg, MV).

% at_mode_(+Vals, +Bg, -Mode): most frequent value in Vals; ties return Bg.
at_mode_(Vals, Bg, Mode) :-
% find the set of unique values in Vals
    sort(Vals, Unique),
% for each unique value compute its frequency as N-V pair
    findall(N-Vv, (
        member(Vv, Unique),
        findall(_, member(Vv, Vals), Ks),
        length(Ks, N)
    ), Counts),
% collect just the frequency numbers
    findall(N, member(N-_, Counts), Ns),
% find the maximum frequency
    max_list(Ns, MaxN),
% collect all values sharing the maximum frequency
    findall(Vv, member(MaxN-Vv, Counts), Winners),
% unique winner becomes Mode; multiple winners resolve to Bg
    (Winners = [Mode] -> true ; Mode = Bg).

% at_step_gol(+Grid, -Grid2): one step of Conway's Game of Life (0 = dead, 1 = alive).
% Birth rule B3: dead cell with exactly 3 alive 8-neighbors becomes alive.
% Survival rule S23: alive cell with 2 or 3 alive 8-neighbors survives; otherwise dies.
at_step_gol(Grid, Grid2) :-
% compute last row index
    length(Grid, H), H1 is H - 1,
% compute last column index from first row; 0 for empty grid
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
% get 8-direction offsets
    at_offs8_(Offs),
% outer findall builds one output row per row index R
    findall(Row2, (
        between(0, H1, R),
% inner findall builds one output cell per column index C
        findall(V2, (
            between(0, W1, C),
% retrieve current cell value (0 = dead, 1 = alive)
            nth0(R, Grid, Row), nth0(C, Row, V),
% count alive (1-valued) 8-neighbors
            findall(_, (
                member(DR-DC, Offs),
                NR is R + DR, NC is C + DC,
                nth0(NR, Grid, NRow), nth0(NC, NRow, 1)
            ), Ks),
            length(Ks, N),
% apply GoL transition: alive cell survives at 2 or 3 neighbors
            at_gol_next_(V, N, V2)
        ), Row2)
    ), Grid2).

% at_gol_next_: Game of Life next-state rule for one cell.
% Alive cell survives with exactly 2 or 3 alive neighbors.
at_gol_next_(1, N, 1) :- (N =:= 2 ; N =:= 3), !.
% Dead cell is born with exactly 3 alive neighbors.
at_gol_next_(0, 3, 1) :- !.
% All other cases: cell is or remains dead.
at_gol_next_(_, _, 0).
