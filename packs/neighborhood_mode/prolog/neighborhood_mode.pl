% nmode.pl - Layer 136: Neighborhood Mode Filter for 2D Grids (nm_* prefix).
% Provides the mode (most frequent value) for integer lists, per-row and per-column
% modes, the grid-wide mode, 4-connected and 8-connected mode filters, uniform cell
% detection (all in-bounds neighbors share one value), and outlier detection (cells
% whose value differs from the neighborhood mode, neighbors only, cell excluded).
% Ties in frequency are broken by returning the smallest tied value.
:- module(neighborhood_mode, [
    neighborhood_mode_mode/2,
    neighborhood_mode_mode_all/2,
    neighborhood_mode_mode_count/3,
    neighborhood_mode_row/3, neighborhood_mode_col/3,
    neighborhood_mode_row_modes/2, neighborhood_mode_col_modes/2,
    neighborhood_mode_grid/2,
    neighborhood_mode_filter4/2, neighborhood_mode_filter8/2,
    neighborhood_mode_uniform4/2, neighborhood_mode_uniform8/2,
    neighborhood_mode_outlier4/2, neighborhood_mode_outlier8/2
]).
% Import list utilities; msort/2, sort/2, length/2, between/3, findall/3 are built-ins.
:- use_module(library(lists), [member/2, nth0/3, max_list/2]).

% neighborhood_mode_mode(+List, -M): M is the mode (most frequent value) of a non-empty integer list.
% Ties are broken by returning the smallest value among those tied for highest frequency.
neighborhood_mode_mode(List, M) :-
% Sort preserving duplicates to group equal elements, then compute frequency pairs.
    msort(List, Sorted),
    neighborhood_mode_freq_pairs_(Sorted, Pairs),
% Extract just the counts, find the maximum count.
    neighborhood_mode_pair_vals_(Pairs, Counts),
    max_list(Counts, MaxCount),
% Collect all values with the maximum count; sort ascending so smallest is first.
    findall(V, member(V-MaxCount, Pairs), Candidates),
    sort(Candidates, [M|_]).

% neighborhood_mode_mode_count(+List, -M, -Count): M is the mode and Count is how many times M appears.
% Ties in mode are broken by the smallest value; Count is the winning frequency.
neighborhood_mode_mode_count(List, M, Count) :-
% Compute frequency pairs, find max count, then retrieve the mode.
    msort(List, Sorted),
    neighborhood_mode_freq_pairs_(Sorted, Pairs),
    neighborhood_mode_pair_vals_(Pairs, Counts),
    max_list(Counts, MaxCount),
    findall(V, member(V-MaxCount, Pairs), Candidates),
    sort(Candidates, [M|_]),
    Count = MaxCount.

% neighborhood_mode_mode_all(+List, -Ms): Ms is the sorted list of all values tied for highest frequency.
neighborhood_mode_mode_all(List, Ms) :-
% Same frequency analysis as neighborhood_mode_mode but collect all tied values.
    msort(List, Sorted),
    neighborhood_mode_freq_pairs_(Sorted, Pairs),
    neighborhood_mode_pair_vals_(Pairs, Counts),
    max_list(Counts, MaxCount),
    findall(V, member(V-MaxCount, Pairs), Candidates),
    sort(Candidates, Ms).

% neighborhood_mode_row(+Grid, +R, -M): M is the mode of row R (0-based) of Grid.
neighborhood_mode_row(Grid, R, M) :-
% Extract the row by index, then compute its mode.
    nth0(R, Grid, Row),
    neighborhood_mode_mode(Row, M).

% neighborhood_mode_col(+Grid, +C, -M): M is the mode of column C (0-based) of Grid.
neighborhood_mode_col(Grid, C, M) :-
% Collect the column values, then compute the mode.
    findall(V, (member(Row, Grid), nth0(C, Row, V)), ColVals),
    neighborhood_mode_mode(ColVals, M).

% neighborhood_mode_row_modes(+Grid, -Ms): Ms is the list of modes, one per row, in row order.
neighborhood_mode_row_modes(Grid, Ms) :-
% Map neighborhood_mode_mode over each row of the grid.
    findall(M, (member(Row, Grid), neighborhood_mode_mode(Row, M)), Ms).

% neighborhood_mode_col_modes(+Grid, -Ms): Ms is the list of modes, one per column, in column order.
neighborhood_mode_col_modes(Grid, Ms) :-
% Enumerate column indices, collect each column, compute its mode.
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(M, (between(0, W1, C), neighborhood_mode_col(Grid, C, M)), Ms).

% neighborhood_mode_grid(+Grid, -M): M is the mode of all cell values in Grid.
neighborhood_mode_grid(Grid, M) :-
% Flatten all cell values and compute the mode of the flat list.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    neighborhood_mode_mode(Vals, M).

% neighborhood_mode_filter4(+Grid, -OutGrid): OutGrid[R][C] is the mode of the cell and its in-bounds
% 4-connected neighbors combined. Useful for denoising and pattern completion.
neighborhood_mode_filter4(Grid, OutGrid) :-
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
            neighborhood_mode_mode([V|NbrVals], M)), Row)), OutGrid).

% neighborhood_mode_filter8(+Grid, -OutGrid): OutGrid[R][C] is the mode of the cell and its in-bounds
% 8-connected neighbors combined.
neighborhood_mode_filter8(Grid, OutGrid) :-
% Same structure as neighborhood_mode_filter4 but with 8-directional offsets.
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
            neighborhood_mode_mode([V|NbrVals], M)), Row)), OutGrid).

% neighborhood_mode_uniform4(+Grid, -Cells): Cells is the sorted list of R-C positions whose
% in-bounds 4-connected neighbors all share exactly one distinct value.
% Corner/edge cells with only two or three neighbors can still qualify.
neighborhood_mode_uniform4(Grid, Cells) :-
% Collect 4-neighbor values; succeed only if sort yields a singleton list.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        neighborhood_mode_nbr4_vals_(Grid, H, W, R, C, NbrVals),
        NbrVals \= [],
        sort(NbrVals, [_])), Cells).

% neighborhood_mode_uniform8(+Grid, -Cells): Cells is the sorted list of R-C positions whose
% in-bounds 8-connected neighbors all share exactly one distinct value.
neighborhood_mode_uniform8(Grid, Cells) :-
% Collect 8-neighbor values; succeed only if sort yields a singleton list.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        neighborhood_mode_nbr8_vals_(Grid, H, W, R, C, NbrVals),
        NbrVals \= [],
        sort(NbrVals, [_])), Cells).

% neighborhood_mode_outlier4(+Grid, -Cells): Cells is the sorted list of R-C positions whose value
% differs numerically from the mode of their in-bounds 4-connected neighbors (cell excluded).
neighborhood_mode_outlier4(Grid, Cells) :-
% Cell is an outlier if its own value differs from the mode of its 4-neighbors alone.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, CRow), nth0(C, CRow, V),
        neighborhood_mode_nbr4_vals_(Grid, H, W, R, C, NbrVals),
        NbrVals \= [],
        neighborhood_mode_mode(NbrVals, NbrMode),
        V =\= NbrMode), Cells).

% neighborhood_mode_outlier8(+Grid, -Cells): Cells is the sorted list of R-C positions whose value
% differs numerically from the mode of their in-bounds 8-connected neighbors (cell excluded).
neighborhood_mode_outlier8(Grid, Cells) :-
% Cell is an outlier if its own value differs from the mode of its 8-neighbors alone.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, CRow), nth0(C, CRow, V),
        neighborhood_mode_nbr8_vals_(Grid, H, W, R, C, NbrVals),
        NbrVals \= [],
        neighborhood_mode_mode(NbrVals, NbrMode),
        V =\= NbrMode), Cells).

% neighborhood_mode_nbr4_vals_(+Grid, +H, +W, +R, +C, -Vals): collects in-bounds 4-neighbor values.
neighborhood_mode_nbr4_vals_(Grid, H, W, R, C, Vals) :-
% Enumerate 4-direction offsets, guard bounds, collect values.
    findall(V, (member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
        NR is R+DR, NC is C+DC,
        NR >= 0, NR < H, NC >= 0, NC < W,
        nth0(NR, Grid, NRow), nth0(NC, NRow, V)), Vals).

% neighborhood_mode_nbr8_vals_(+Grid, +H, +W, +R, +C, -Vals): collects in-bounds 8-neighbor values.
neighborhood_mode_nbr8_vals_(Grid, H, W, R, C, Vals) :-
% Enumerate 8-direction offsets, guard bounds, collect values.
    findall(V, (member(DR-DC, [-1-(-1), -1-0, -1-1, 0-(-1), 0-1, 1-(-1), 1-0, 1-1]),
        NR is R+DR, NC is C+DC,
        NR >= 0, NR < H, NC >= 0, NC < W,
        nth0(NR, Grid, NRow), nth0(NC, NRow, V)), Vals).

% neighborhood_mode_freq_pairs_(+SortedList, -Pairs): converts a sorted list to Value-Count pairs.
% Consecutive equal elements are grouped; output is a list of Val-Count pairs.
neighborhood_mode_freq_pairs_([], []).
neighborhood_mode_freq_pairs_([H|T], Pairs) :-
% Count how many leading elements equal H, then recurse on the remainder.
    neighborhood_mode_count_prefix_(H, T, Count, Rest),
    Total is Count + 1,
    neighborhood_mode_freq_pairs_(Rest, RestPairs),
    Pairs = [H-Total|RestPairs].

% neighborhood_mode_count_prefix_(+Val, +List, -Count, -Remainder): counts leading Val occurrences.
% Cut in clause 1 prevents clause 3 from matching when List is empty.
neighborhood_mode_count_prefix_(_, [], 0, []) :- !.
neighborhood_mode_count_prefix_(Val, [Val|T], Count, Rest) :-
    !,
% This element matches Val; count it and continue checking the tail.
    neighborhood_mode_count_prefix_(Val, T, C1, Rest),
    Count is C1 + 1.
neighborhood_mode_count_prefix_(_, List, 0, List).

% neighborhood_mode_pair_vals_(+Pairs, -Values): extracts the count (right element) from Key-Count pairs.
neighborhood_mode_pair_vals_([], []).
neighborhood_mode_pair_vals_([_-V|T], [V|Vs]) :-
% Strip the key, keep the count, recurse.
    neighborhood_mode_pair_vals_(T, Vs).
