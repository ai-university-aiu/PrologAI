% nmode.pl - Layer 136: Neighborhood Mode Filter for 2D Grids (nm_* prefix).
% Provides the mode (most frequent value) for integer lists, per-row and per-column
% modes, the grid-wide mode, 4-connected and 8-connected mode filters, uniform cell
% detection (all in-bounds neighbors share one value), and outlier detection (cells
% whose value differs from the neighborhood mode, neighbors only, cell excluded).
% Ties in frequency are broken by returning the smallest tied value.
:- module(nmode, [
    nmode_mode/2,
    nmode_mode_all/2,
    nmode_mode_count/3,
    nmode_row/3, nmode_col/3,
    nmode_row_modes/2, nmode_col_modes/2,
    nmode_grid/2,
    nmode_filter4/2, nmode_filter8/2,
    nmode_uniform4/2, nmode_uniform8/2,
    nmode_outlier4/2, nmode_outlier8/2
]).
% Import list utilities; msort/2, sort/2, length/2, between/3, findall/3 are built-ins.
:- use_module(library(lists), [member/2, nth0/3, max_list/2]).

% nmode_mode(+List, -M): M is the mode (most frequent value) of a non-empty integer list.
% Ties are broken by returning the smallest value among those tied for highest frequency.
nmode_mode(List, M) :-
% Sort preserving duplicates to group equal elements, then compute frequency pairs.
    msort(List, Sorted),
    nmode_freq_pairs_(Sorted, Pairs),
% Extract just the counts, find the maximum count.
    nmode_pair_vals_(Pairs, Counts),
    max_list(Counts, MaxCount),
% Collect all values with the maximum count; sort ascending so smallest is first.
    findall(V, member(V-MaxCount, Pairs), Candidates),
    sort(Candidates, [M|_]).

% nmode_mode_count(+List, -M, -Count): M is the mode and Count is how many times M appears.
% Ties in mode are broken by the smallest value; Count is the winning frequency.
nmode_mode_count(List, M, Count) :-
% Compute frequency pairs, find max count, then retrieve the mode.
    msort(List, Sorted),
    nmode_freq_pairs_(Sorted, Pairs),
    nmode_pair_vals_(Pairs, Counts),
    max_list(Counts, MaxCount),
    findall(V, member(V-MaxCount, Pairs), Candidates),
    sort(Candidates, [M|_]),
    Count = MaxCount.

% nmode_mode_all(+List, -Ms): Ms is the sorted list of all values tied for highest frequency.
nmode_mode_all(List, Ms) :-
% Same frequency analysis as nmode_mode but collect all tied values.
    msort(List, Sorted),
    nmode_freq_pairs_(Sorted, Pairs),
    nmode_pair_vals_(Pairs, Counts),
    max_list(Counts, MaxCount),
    findall(V, member(V-MaxCount, Pairs), Candidates),
    sort(Candidates, Ms).

% nmode_row(+Grid, +R, -M): M is the mode of row R (0-based) of Grid.
nmode_row(Grid, R, M) :-
% Extract the row by index, then compute its mode.
    nth0(R, Grid, Row),
    nmode_mode(Row, M).

% nmode_col(+Grid, +C, -M): M is the mode of column C (0-based) of Grid.
nmode_col(Grid, C, M) :-
% Collect the column values, then compute the mode.
    findall(V, (member(Row, Grid), nth0(C, Row, V)), ColVals),
    nmode_mode(ColVals, M).

% nmode_row_modes(+Grid, -Ms): Ms is the list of modes, one per row, in row order.
nmode_row_modes(Grid, Ms) :-
% Map nmode_mode over each row of the grid.
    findall(M, (member(Row, Grid), nmode_mode(Row, M)), Ms).

% nmode_col_modes(+Grid, -Ms): Ms is the list of modes, one per column, in column order.
nmode_col_modes(Grid, Ms) :-
% Enumerate column indices, collect each column, compute its mode.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(M, (between(0, W1, C), nmode_col(Grid, C, M)), Ms).

% nmode_grid(+Grid, -M): M is the mode of all cell values in Grid.
nmode_grid(Grid, M) :-
% Flatten all cell values and compute the mode of the flat list.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    nmode_mode(Vals, M).

% nmode_filter4(+Grid, -OutGrid): OutGrid[R][C] is the mode of the cell and its in-bounds
% 4-connected neighbors combined. Useful for denoising and pattern completion.
nmode_filter4(Grid, OutGrid) :-
% Build output grid via nested findall; for each cell collect self + 4-neighbor values.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(M, (between(0, W1, C),
            nth0(R, Grid, CRow), nth0(C, CRow, V),
            findall(NV, (member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
                NR is R+DR, NC is C+DC,
                NR >= 0, NR < H, NC >= 0, NC < W,
                nth0(NR, Grid, NRow), nth0(NC, NRow, NV)), NbrVals),
            nmode_mode([V|NbrVals], M)), Row)), OutGrid).

% nmode_filter8(+Grid, -OutGrid): OutGrid[R][C] is the mode of the cell and its in-bounds
% 8-connected neighbors combined.
nmode_filter8(Grid, OutGrid) :-
% Same structure as nmode_filter4 but with 8-directional offsets.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(Row, (between(0, H1, R),
        findall(M, (between(0, W1, C),
            nth0(R, Grid, CRow), nth0(C, CRow, V),
            findall(NV, (
                member(DR-DC, [-1-(-1), -1-0, -1-1, 0-(-1), 0-1, 1-(-1), 1-0, 1-1]),
                NR is R+DR, NC is C+DC,
                NR >= 0, NR < H, NC >= 0, NC < W,
                nth0(NR, Grid, NRow), nth0(NC, NRow, NV)), NbrVals),
            nmode_mode([V|NbrVals], M)), Row)), OutGrid).

% nmode_uniform4(+Grid, -Cells): Cells is the sorted list of R-C positions whose
% in-bounds 4-connected neighbors all share exactly one distinct value.
% Corner/edge cells with only two or three neighbors can still qualify.
nmode_uniform4(Grid, Cells) :-
% Collect 4-neighbor values; succeed only if sort yields a singleton list.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nmode_nbr4_vals_(Grid, H, W, R, C, NbrVals),
        NbrVals \= [],
        sort(NbrVals, [_])), Cells).

% nmode_uniform8(+Grid, -Cells): Cells is the sorted list of R-C positions whose
% in-bounds 8-connected neighbors all share exactly one distinct value.
nmode_uniform8(Grid, Cells) :-
% Collect 8-neighbor values; succeed only if sort yields a singleton list.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nmode_nbr8_vals_(Grid, H, W, R, C, NbrVals),
        NbrVals \= [],
        sort(NbrVals, [_])), Cells).

% nmode_outlier4(+Grid, -Cells): Cells is the sorted list of R-C positions whose value
% differs numerically from the mode of their in-bounds 4-connected neighbors (cell excluded).
nmode_outlier4(Grid, Cells) :-
% Cell is an outlier if its own value differs from the mode of its 4-neighbors alone.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, CRow), nth0(C, CRow, V),
        nmode_nbr4_vals_(Grid, H, W, R, C, NbrVals),
        NbrVals \= [],
        nmode_mode(NbrVals, NbrMode),
        V =\= NbrMode), Cells).

% nmode_outlier8(+Grid, -Cells): Cells is the sorted list of R-C positions whose value
% differs numerically from the mode of their in-bounds 8-connected neighbors (cell excluded).
nmode_outlier8(Grid, Cells) :-
% Cell is an outlier if its own value differs from the mode of its 8-neighbors alone.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, CRow), nth0(C, CRow, V),
        nmode_nbr8_vals_(Grid, H, W, R, C, NbrVals),
        NbrVals \= [],
        nmode_mode(NbrVals, NbrMode),
        V =\= NbrMode), Cells).

% nmode_nbr4_vals_(+Grid, +H, +W, +R, +C, -Vals): collects in-bounds 4-neighbor values.
nmode_nbr4_vals_(Grid, H, W, R, C, Vals) :-
% Enumerate 4-direction offsets, guard bounds, collect values.
    findall(V, (member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
        NR is R+DR, NC is C+DC,
        NR >= 0, NR < H, NC >= 0, NC < W,
        nth0(NR, Grid, NRow), nth0(NC, NRow, V)), Vals).

% nmode_nbr8_vals_(+Grid, +H, +W, +R, +C, -Vals): collects in-bounds 8-neighbor values.
nmode_nbr8_vals_(Grid, H, W, R, C, Vals) :-
% Enumerate 8-direction offsets, guard bounds, collect values.
    findall(V, (member(DR-DC, [-1-(-1), -1-0, -1-1, 0-(-1), 0-1, 1-(-1), 1-0, 1-1]),
        NR is R+DR, NC is C+DC,
        NR >= 0, NR < H, NC >= 0, NC < W,
        nth0(NR, Grid, NRow), nth0(NC, NRow, V)), Vals).

% nmode_freq_pairs_(+SortedList, -Pairs): converts a sorted list to Value-Count pairs.
% Consecutive equal elements are grouped; output is a list of Val-Count pairs.
nmode_freq_pairs_([], []).
nmode_freq_pairs_([H|T], Pairs) :-
% Count how many leading elements equal H, then recurse on the remainder.
    nmode_count_prefix_(H, T, Count, Rest),
    Total is Count + 1,
    nmode_freq_pairs_(Rest, RestPairs),
    Pairs = [H-Total|RestPairs].

% nmode_count_prefix_(+Val, +List, -Count, -Remainder): counts leading Val occurrences.
% Cut in clause 1 prevents clause 3 from matching when List is empty.
nmode_count_prefix_(_, [], 0, []) :- !.
nmode_count_prefix_(Val, [Val|T], Count, Rest) :-
    !,
% This element matches Val; count it and continue checking the tail.
    nmode_count_prefix_(Val, T, C1, Rest),
    Count is C1 + 1.
nmode_count_prefix_(_, List, 0, List).

% nmode_pair_vals_(+Pairs, -Values): extracts the count (right element) from Key-Count pairs.
nmode_pair_vals_([], []).
nmode_pair_vals_([_-V|T], [V|Vs]) :-
% Strip the key, keep the count, recurse.
    nmode_pair_vals_(T, Vs).
