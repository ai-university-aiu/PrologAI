% naggr.pl - Layer 134: Per-Cell Neighborhood Value Aggregation (na_* prefix).
% Provides per-cell aggregate statistics (sum, max, min, mean, range, spread,
% and difference count) computed over in-bounds 4-connected and 8-connected
% neighborhoods. Complements the automaton pack (at_*) which covers count-based
% neighbor operations; this pack covers value-based aggregation.
:- module(naggr, [
    na_sum4/2, na_sum8/2,
    na_max4/2, na_max8/2,
    na_min4/2, na_min8/2,
    na_mean4/2, na_mean8/2,
    na_range4/2, na_range8/2,
    na_spread4/2, na_spread8/2,
    na_diff4/2, na_diff8/2
]).
% Import list utilities; sort/2, length/2, between/3, findall/3 are built-ins.
:- use_module(library(lists), [member/2, nth0/3, max_list/2, min_list/2, sum_list/2]).

% na_sum4(+Grid, -SumGrid): SumGrid[R][C] is the sum of in-bounds 4-neighbor values.
% Returns 0 for cells with no in-bounds 4-neighbors (e.g., a 1x1 grid).
na_sum4(Grid, SumGrid) :-
% Compute grid dimensions and build the output grid row by row via nested findall.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(S, (between(0, W1, C),
            na_nbr4_vals_(Grid, H, W, R, C, Vals),
            sum_list(Vals, S)), Row)), SumGrid).

% na_sum8(+Grid, -SumGrid): SumGrid[R][C] is the sum of in-bounds 8-neighbor values.
% Returns 0 for cells with no in-bounds 8-neighbors.
na_sum8(Grid, SumGrid) :-
% Same structure as na_sum4 using the 8-connected neighborhood helper.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(S, (between(0, W1, C),
            na_nbr8_vals_(Grid, H, W, R, C, Vals),
            sum_list(Vals, S)), Row)), SumGrid).

% na_max4(+Grid, -MaxGrid): MaxGrid[R][C] is the maximum of in-bounds 4-neighbor values.
% Returns 0 for cells with no in-bounds neighbors.
na_max4(Grid, MaxGrid) :-
% Use 0 as sentinel for empty neighborhoods (no in-bounds neighbors exist).
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(M, (between(0, W1, C),
            na_nbr4_vals_(Grid, H, W, R, C, Vals),
            (Vals = [] -> M = 0 ; max_list(Vals, M))), Row)), MaxGrid).

% na_max8(+Grid, -MaxGrid): MaxGrid[R][C] is the maximum of in-bounds 8-neighbor values.
% Returns 0 for cells with no in-bounds neighbors.
na_max8(Grid, MaxGrid) :-
% Use 0 as sentinel for empty neighborhoods.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(M, (between(0, W1, C),
            na_nbr8_vals_(Grid, H, W, R, C, Vals),
            (Vals = [] -> M = 0 ; max_list(Vals, M))), Row)), MaxGrid).

% na_min4(+Grid, -MinGrid): MinGrid[R][C] is the minimum of in-bounds 4-neighbor values.
% Returns 0 for cells with no in-bounds neighbors.
na_min4(Grid, MinGrid) :-
% Use 0 as sentinel for empty neighborhoods.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(M, (between(0, W1, C),
            na_nbr4_vals_(Grid, H, W, R, C, Vals),
            (Vals = [] -> M = 0 ; min_list(Vals, M))), Row)), MinGrid).

% na_min8(+Grid, -MinGrid): MinGrid[R][C] is the minimum of in-bounds 8-neighbor values.
% Returns 0 for cells with no in-bounds neighbors.
na_min8(Grid, MinGrid) :-
% Use 0 as sentinel for empty neighborhoods.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(M, (between(0, W1, C),
            na_nbr8_vals_(Grid, H, W, R, C, Vals),
            (Vals = [] -> M = 0 ; min_list(Vals, M))), Row)), MinGrid).

% na_mean4(+Grid, -MeanGrid): MeanGrid[R][C] is floor(sum/count) of 4-neighbor values.
% Returns 0 for cells with no in-bounds neighbors.
na_mean4(Grid, MeanGrid) :-
% Use integer floor division; 0 sentinel for empty neighborhoods.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(M, (between(0, W1, C),
            na_nbr4_vals_(Grid, H, W, R, C, Vals),
            (Vals = [] -> M = 0 ;
                sum_list(Vals, S), length(Vals, N), M is S // N)), Row)), MeanGrid).

% na_mean8(+Grid, -MeanGrid): MeanGrid[R][C] is floor(sum/count) of 8-neighbor values.
% Returns 0 for cells with no in-bounds neighbors.
na_mean8(Grid, MeanGrid) :-
% Use integer floor division; 0 sentinel for empty neighborhoods.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(M, (between(0, W1, C),
            na_nbr8_vals_(Grid, H, W, R, C, Vals),
            (Vals = [] -> M = 0 ;
                sum_list(Vals, S), length(Vals, N), M is S // N)), Row)), MeanGrid).

% na_range4(+Grid, -RangeGrid): RangeGrid[R][C] is max - min of 4-neighbor values.
% Returns 0 when fewer than 2 in-bounds neighbors exist.
na_range4(Grid, RangeGrid) :-
% Need at least 2 values to define a range; 0 for 0 or 1 neighbor.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(Rng, (between(0, W1, C),
            na_nbr4_vals_(Grid, H, W, R, C, Vals),
            (length(Vals, VN), VN < 2 -> Rng = 0 ;
                max_list(Vals, Mx), min_list(Vals, Mn), Rng is Mx - Mn)), Row)), RangeGrid).

% na_range8(+Grid, -RangeGrid): RangeGrid[R][C] is max - min of 8-neighbor values.
% Returns 0 when fewer than 2 in-bounds neighbors exist.
na_range8(Grid, RangeGrid) :-
% Need at least 2 values to define a range; 0 for 0 or 1 neighbor.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(Rng, (between(0, W1, C),
            na_nbr8_vals_(Grid, H, W, R, C, Vals),
            (length(Vals, VN), VN < 2 -> Rng = 0 ;
                max_list(Vals, Mx), min_list(Vals, Mn), Rng is Mx - Mn)), Row)), RangeGrid).

% na_spread4(+Grid, -SpreadGrid): SpreadGrid[R][C] is the count of distinct values
% among in-bounds 4-neighbors. Returns 0 when no in-bounds neighbors exist.
na_spread4(Grid, SpreadGrid) :-
% sort/2 is a built-in that removes duplicates; length counts the distinct set.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(N, (between(0, W1, C),
            na_nbr4_vals_(Grid, H, W, R, C, Vals),
            sort(Vals, Uniq), length(Uniq, N)), Row)), SpreadGrid).

% na_spread8(+Grid, -SpreadGrid): SpreadGrid[R][C] is the count of distinct values
% among in-bounds 8-neighbors. Returns 0 when no in-bounds neighbors exist.
na_spread8(Grid, SpreadGrid) :-
% sort/2 removes duplicates; length counts the distinct value set.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(N, (between(0, W1, C),
            na_nbr8_vals_(Grid, H, W, R, C, Vals),
            sort(Vals, Uniq), length(Uniq, N)), Row)), SpreadGrid).

% na_diff4(+Grid, -DiffGrid): DiffGrid[R][C] is the count of in-bounds 4-neighbors
% whose value differs from the cell's own value.
na_diff4(Grid, DiffGrid) :-
% Count same-valued neighbors via inner findall, then subtract from total.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(D, (between(0, W1, C),
            nth0(R, Grid, CRow), nth0(C, CRow, CV),
            na_nbr4_vals_(Grid, H, W, R, C, Vals),
            length(Vals, Total),
            findall(_, (member(NV, Vals), NV =:= CV), Same),
            length(Same, SC), D is Total - SC), Row)), DiffGrid).

% na_diff8(+Grid, -DiffGrid): DiffGrid[R][C] is the count of in-bounds 8-neighbors
% whose value differs from the cell's own value.
na_diff8(Grid, DiffGrid) :-
% Count same-valued neighbors via inner findall, then subtract from total.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(D, (between(0, W1, C),
            nth0(R, Grid, CRow), nth0(C, CRow, CV),
            na_nbr8_vals_(Grid, H, W, R, C, Vals),
            length(Vals, Total),
            findall(_, (member(NV, Vals), NV =:= CV), Same),
            length(Same, SC), D is Total - SC), Row)), DiffGrid).

% Private: collect values of all in-bounds 4-neighbors of cell R-C in Grid.
na_nbr4_vals_(Grid, H, W, R, C, Vals) :-
% Enumerate four orthogonal offsets and discard positions outside grid bounds.
    findall(V, (member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
        NR is R + DR, NC is C + DC,
        NR >= 0, NR < H, NC >= 0, NC < W,
        nth0(NR, Grid, NRow), nth0(NC, NRow, V)), Vals).

% Private: collect values of all in-bounds 8-neighbors of cell R-C in Grid.
na_nbr8_vals_(Grid, H, W, R, C, Vals) :-
% Enumerate all eight direction offsets and discard out-of-bounds positions.
    findall(V, (member(DR-DC, [-1-(-1), -1-0, -1-1, 0-(-1), 0-1, 1-(-1), 1-0, 1-1]),
        NR is R + DR, NC is C + DC,
        NR >= 0, NR < H, NC >= 0, NC < W,
        nth0(NR, Grid, NRow), nth0(NC, NRow, V)), Vals).
