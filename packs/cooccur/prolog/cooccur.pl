% cooccur.pl - Layer 139: Value Co-Occurrence and Adjacency Analysis in 2D Grids (co_* prefix).
% Provides ordered horizontal and vertical adjacent value pairs, down-right and
% down-left diagonal adjacent pairs, directed pair counts, undirected 4-adjacency
% counts, universal adjacency testing, isolation detection, border-value enumeration,
% shared-border testing, horizontal transition frequency tables, and most-common
% 4-adjacent value lookup for integer 2D grids.
:- module(cooccur, [
    co_h_pairs/2,
    co_v_pairs/2,
    co_d_pairs_dr/2,
    co_d_pairs_dl/2,
    co_count_h/4,
    co_count_v/4,
    co_count_adj4/4,
    co_always_adj4/3,
    co_never_adj4/3,
    co_isolated4/3,
    co_border_vals/3,
    co_shared_border/3,
    co_row_transitions/2,
    co_most_common_adj4/3
]).
% Import list utilities; sort/2, msort/2, length/2, between/3, findall/3, \+/1 are built-ins.
:- use_module(library(lists), [member/2, nth0/3, last/2, append/3]).
% Import include/3 for counting matching pairs.
:- use_module(library(apply), [include/3]).

% co_h_pairs(+Grid, -Pairs): Pairs is the list of all ordered horizontal adjacent
% value pairs A-B where A is immediately to the left of B within the same row.
% Row-major order; each row contributes length(Row)-1 pairs.
co_h_pairs(Grid, Pairs) :-
% For each row collect consecutive adjacent pairs via co_row_adj_.
    findall(A-B, (member(Row, Grid), co_row_adj_(Row, A, B)), Pairs).

% co_v_pairs(+Grid, -Pairs): Pairs is the list of all ordered vertical adjacent
% value pairs A-B where A is immediately above B in the same column.
% Column-major order within each column; H-1 pairs per column.
co_v_pairs(Grid, Pairs) :-
% Determine column count from the first row; default 0 for empty grid.
    (Grid = [Fr | _] -> length(Fr, W) ; W = 0),
% Highest valid column index.
    W1 is W - 1,
% For each column, collect pairs from adjacent rows via co_col_adj_.
    findall(A-B, (between(0, W1, C), co_col_adj_(Grid, C, A, B)), Pairs).

% co_d_pairs_dr(+Grid, -Pairs): Pairs is the ordered list of diagonal adjacent
% value pairs A-B going down-right: A at (R,C), B at (R+1,C+1).
co_d_pairs_dr(Grid, Pairs) :-
% Determine grid bounds.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr | _] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Collect all valid down-right diagonal pairs in row-major enumeration order.
    findall(A-B, (between(0, H1, R), between(0, W1, C),
        R1 is R + 1, C1 is C + 1,
        R1 =< H1, C1 =< W1,
        nth0(R, Grid, Row), nth0(C, Row, A),
        nth0(R1, Grid, Row1), nth0(C1, Row1, B)), Pairs).

% co_d_pairs_dl(+Grid, -Pairs): Pairs is the ordered list of diagonal adjacent
% value pairs A-B going down-left: A at (R,C), B at (R+1,C-1).
co_d_pairs_dl(Grid, Pairs) :-
% Determine grid bounds.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr | _] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Collect all valid down-left diagonal pairs in row-major enumeration order.
    findall(A-B, (between(0, H1, R), between(0, W1, C),
        R1 is R + 1, C1 is C - 1,
        R1 =< H1, C1 >= 0,
        nth0(R, Grid, Row), nth0(C, Row, A),
        nth0(R1, Grid, Row1), nth0(C1, Row1, B)), Pairs).

% co_count_h(+Grid, +V1, +V2, -N): N is the count of directed horizontal pairs
% where value V1 appears immediately to the left of value V2.
co_count_h(Grid, V1, V2, N) :-
% Collect all horizontal pairs then filter to those matching V1-V2.
    co_h_pairs(Grid, Pairs),
    include(=(V1-V2), Pairs, M),
    length(M, N).

% co_count_v(+Grid, +V1, +V2, -N): N is the count of directed vertical pairs
% where value V1 appears immediately above value V2.
co_count_v(Grid, V1, V2, N) :-
% Collect all vertical pairs then filter to those matching V1-V2.
    co_v_pairs(Grid, Pairs),
    include(=(V1-V2), Pairs, M),
    length(M, N).

% co_count_adj4(+Grid, +V1, +V2, -N): N is the total count of undirected
% 4-adjacent {V1, V2} pairs in Grid. When V1 == V2, counts each V1-V1
% adjacent pair once per occurrence in horizontal and vertical pair lists.
% When V1 \= V2, adds the count of V1-V2 and V2-V1 ordered pairs.
co_count_adj4(Grid, V1, V2, N) :-
% Collect all horizontal and vertical ordered pairs.
    co_h_pairs(Grid, H),
    co_v_pairs(Grid, V),
    append(H, V, All),
% Count V1-V2 pairs; if asymmetric, also count V2-V1 and add.
    include(=(V1-V2), All, M1), length(M1, N1),
    (V1 == V2 ->
        N is N1
    ;
        include(=(V2-V1), All, M2), length(M2, N2),
        N is N1 + N2).

% co_always_adj4(+Grid, +V1, +V2): succeeds if every cell with value V1 has
% at least one 4-adjacent cell with value V2. Fails if Grid has no V1 cells.
co_always_adj4(Grid, V1, V2) :-
% Fails if any V1 cell has no V2 among its 4-neighbors.
    \+ co_has_nonadj4_(Grid, V1, V2).

% co_never_adj4(+Grid, +V1, +V2): succeeds if no cell with value V1 is
% 4-adjacent to any cell with value V2.
co_never_adj4(Grid, V1, V2) :-
% Fails if any V1-V2 shared edge exists.
    \+ co_shared_border(Grid, V1, V2).

% co_isolated4(+Grid, +V, -Cells): Cells is the sorted R-C list of positions
% with value V that have no 4-adjacent cell with the same value V.
co_isolated4(Grid, V, Cells) :-
% Determine grid bounds.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr | _] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Collect V cells that have no in-bounds 4-neighbor also equal to V.
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        \+ (member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
            R2 is R + DR, C2 is C + DC,
            R2 >= 0, R2 =< H1, C2 >= 0, C2 =< W1,
            nth0(R2, Grid, Row2), nth0(C2, Row2, V))),
        Cells).

% co_border_vals(+Grid, +V, -Vals): Vals is the sorted list of distinct values
% W (where W \= V) that appear in at least one 4-adjacent position to a V cell.
co_border_vals(Grid, V, Vals) :-
% Determine grid bounds.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr | _] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Collect all neighboring values of V cells, excluding V itself.
    findall(NV, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
        R2 is R + DR, C2 is C + DC,
        R2 >= 0, R2 =< H1, C2 >= 0, C2 =< W1,
        nth0(R2, Grid, Row2), nth0(C2, Row2, NV),
        NV \= V), RawVals),
% Sort to remove duplicates.
    sort(RawVals, Vals).

% co_shared_border(+Grid, +V1, +V2): succeeds if some cell with value V1 is
% 4-adjacent to some cell with value V2. Deterministic (cuts after first hit).
co_shared_border(Grid, V1, V2) :-
% Determine grid bounds.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr | _] -> length(Fr, W) ; W = 0), W1 is W - 1,
% Find one V1 cell adjacent to a V2 cell; cut to avoid further backtracking.
    between(0, H1, R), between(0, W1, C),
    nth0(R, Grid, Row), nth0(C, Row, V1),
    member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
    R2 is R + DR, C2 is C + DC,
    R2 >= 0, R2 =< H1, C2 >= 0, C2 =< W1,
    nth0(R2, Grid, Row2), nth0(C2, Row2, V2), !.

% co_row_transitions(+Grid, -Triples): Triples is a list of A-B-N terms, each
% representing a directed horizontal adjacent pair A-B occurring N times.
% Sorted by count descending (most frequent first).
co_row_transitions(Grid, Triples) :-
% Collect all ordered horizontal pairs.
    co_h_pairs(Grid, Pairs),
% Get unique pairs to iterate over.
    sort(Pairs, UniqPairs),
% For each unique pair, count occurrences; build N-A-B for sort-by-count.
    findall(N-A-B, (member(A-B, UniqPairs),
        include(=(A-B), Pairs, M), length(M, N)), Raw),
% Sort ascending by N; reverse for descending order.
    msort(Raw, Sorted),
    reverse(Sorted, RevSorted),
% Convert N-A-B back to A-B-N format.
    findall(A-B-N, member(N-A-B, RevSorted), Triples).

% co_most_common_adj4(+Grid, +V, -W): W is the value most frequently 4-adjacent
% to cells with value V. Ties broken by taking the largest value (via msort+last).
% Fails if V has no 4-adjacent cells of any other value.
co_most_common_adj4(Grid, V, W) :-
% Get distinct values that border V.
    co_border_vals(Grid, V, BVals),
% Fail if no other value borders V.
    BVals \= [],
% Count undirected adjacency of each border value.
    findall(N-X, (member(X, BVals), co_count_adj4(Grid, V, X, N)), Counts),
% Sort ascending; last element has highest count (and highest value on tie).
    msort(Counts, Sorted),
    last(Sorted, _-W).

% co_row_adj_(+Row, -A, -B): A and B are consecutive elements of Row.
% Backtracks over all adjacent pairs in left-to-right order.
co_row_adj_([A, B | _], A, B).
co_row_adj_([_ | T], A, B) :-
% Require at least two more elements to prevent out-of-bounds.
    T = [_ | _],
    co_row_adj_(T, A, B).

% co_col_adj_(+Grid, +C, -A, -B): A is the value in column C of some row R,
% B is the value in column C of row R+1. Backtracks over adjacent row pairs.
co_col_adj_([R1, R2 | _], C, A, B) :-
    nth0(C, R1, A),
    nth0(C, R2, B).
co_col_adj_([_ | T], C, A, B) :-
% Require at least two more rows to prevent out-of-bounds.
    T = [_ | _],
    co_col_adj_(T, C, A, B).

% co_has_nonadj4_(+Grid, +V1, +V2): internal helper. Succeeds if there exists
% a V1 cell that has NO 4-adjacent cell with value V2. Used by co_always_adj4.
co_has_nonadj4_(Grid, V1, V2) :-
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr | _] -> length(Fr, W) ; W = 0), W1 is W - 1,
    between(0, H1, R), between(0, W1, C),
    nth0(R, Grid, Row), nth0(C, Row, V1),
    \+ (member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
        R2 is R + DR, C2 is C + DC,
        R2 >= 0, R2 =< H1, C2 >= 0, C2 =< W1,
        nth0(R2, Grid, Row2), nth0(C2, Row2, V2)).
