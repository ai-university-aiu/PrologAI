% rank.pl - Layer 137: Dense Ranking of Integer Values in Lists and 2D Grids (rk_* prefix).
% Provides dense ranking (rank 1 = smallest distinct value) for integer lists,
% 0-based argsort, per-row and per-column dense ranking grids, grid-wide dense
% ranking, cell-level rank queries, top-N and bottom-N cell selection, and
% rank-threshold cell filtering.
%
% Dense rank: given distinct sorted values [v1 < v2 < ... < vK], value vi maps
% to rank i. All occurrences of the same value receive the same rank.
:- module(rank, [
    rank_rank_of/3,
    rank_dense/2,
    rank_argsort_asc/2,
    rank_argsort_desc/2,
    rank_row_dense/2,
    rank_col_dense/2,
    rank_grid_dense/2,
    rank_row_rank_of/4,
    rank_col_rank_of/4,
    rank_grid_rank_of/4,
    rank_top_n/3,
    rank_bottom_n/3,
    rank_above_rank/3,
    rank_below_rank/3
]).
% Import list utilities; sort/2, msort/2, length/2, between/3, findall/3 are built-ins.
:- use_module(library(lists), [member/2, nth0/3, numlist/3]).

% rank_rank_of(+List, +V, -R): R is the 1-based dense rank of value V in List.
% Rank 1 = smallest distinct value, 2 = second smallest, etc. Fails if V absent.
rank_rank_of(List, V, R) :-
% Sort to get unique values in ascending order, then find 1-based position of V.
    sort(List, Uniq),
    rank_pos1_(Uniq, V, R).

% rank_dense(+List, -Ranks): Ranks is the list of 1-based dense ranks for each element.
% Elements with the same value receive the same rank.
rank_dense(List, Ranks) :-
% Sort unique values ascending; map each element to its 1-based position in Uniq.
    sort(List, Uniq),
    findall(R, (member(V, List), rank_pos1_(Uniq, V, R)), Ranks).

% rank_argsort_asc(+List, -Indices): Indices are 0-based positions of List elements
% sorted in ascending order. Stable: equal values keep their original left-to-right order.
rank_argsort_asc(List, Indices) :-
% Pair each element with its 0-based index; msort by value (stable); extract indices.
    length(List, N), N1 is N - 1,
    numlist(0, N1, Idxs),
    rank_zip_(List, Idxs, Pairs),
    msort(Pairs, Sorted),
    findall(I, member(_-I, Sorted), Indices).

% rank_argsort_desc(+List, -Indices): 0-based positions sorted in descending value order.
% Stable: equal values keep original left-to-right order.
rank_argsort_desc(List, Indices) :-
% Negate values so ascending msort gives descending order; extract indices.
    length(List, N), N1 is N - 1,
    numlist(0, N1, Idxs),
    rank_zip_(List, Idxs, Pairs),
    findall(NV-I, (member(V-I, Pairs), NV is -V), NegPairs),
    msort(NegPairs, Sorted),
    findall(I, member(_-I, Sorted), Indices).

% rank_row_dense(+Grid, -RankGrid): each cell replaced with its 1-based dense rank
% within its own row.
rank_row_dense(Grid, RankGrid) :-
% Apply rank_dense to each row independently.
    findall(Ranks, (member(Row, Grid), rank_dense(Row, Ranks)), RankGrid).

% rank_col_dense(+Grid, -RankGrid): each cell replaced with its 1-based dense rank
% within its own column.
rank_col_dense(Grid, RankGrid) :-
% For each (row, col) cell, collect the column values, rank, return cell rank.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(RowRanks, (between(0, H1, R),
        findall(Rank, (between(0, W1, C),
            findall(CV, (member(Row2, Grid), nth0(C, Row2, CV)), ColVals),
            sort(ColVals, Uniq),
            nth0(R, Grid, CRow), nth0(C, CRow, V),
            rank_pos1_(Uniq, V, Rank)), RowRanks)), RankGrid).

% rank_grid_dense(+Grid, -RankGrid): each cell replaced with its 1-based dense rank
% among ALL cell values in the entire grid.
rank_grid_dense(Grid, RankGrid) :-
% Flatten all values, get unique sorted, map each cell to its rank.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    sort(Vals, Uniq),
    findall(RowRanks, (member(Row, Grid),
        findall(R, (member(V, Row), rank_pos1_(Uniq, V, R)), RowRanks)), RankGrid).

% rank_row_rank_of(+Grid, +R, +C, -Rank): 1-based dense rank of cell (R,C) within row R.
rank_row_rank_of(Grid, R, C, Rank) :-
% Extract the row; get cell value; find its rank in the sorted unique row values.
    nth0(R, Grid, Row),
    nth0(C, Row, V),
    sort(Row, Uniq),
    rank_pos1_(Uniq, V, Rank).

% rank_col_rank_of(+Grid, +R, +C, -Rank): 1-based dense rank of cell (R,C) within col C.
rank_col_rank_of(Grid, R, C, Rank) :-
% Collect all column values; get cell value; rank it.
    findall(V, (member(Row, Grid), nth0(C, Row, V)), ColVals),
    nth0(R, Grid, CRow), nth0(C, CRow, CV),
    sort(ColVals, Uniq),
    rank_pos1_(Uniq, CV, Rank).

% rank_grid_rank_of(+Grid, +R, +C, -Rank): 1-based dense rank of cell (R,C) among all cells.
rank_grid_rank_of(Grid, R, C, Rank) :-
% Flatten; sort; get cell value; rank it globally.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    sort(Vals, Uniq),
    nth0(R, Grid, CRow), nth0(C, CRow, CV),
    rank_pos1_(Uniq, CV, Rank).

% rank_top_n(+Grid, +N, -Cells): sorted R-C positions of cells whose value is among
% the N largest distinct values in Grid (all cells with those values included).
rank_top_n(Grid, N, Cells) :-
% Get sorted unique values; take last N (largest); collect cells with those values.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    sort(Vals, Uniq),
    rank_last_n_(Uniq, N, TopVals),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        member(V, TopVals)), Cells).

% rank_bottom_n(+Grid, +N, -Cells): sorted R-C positions of cells whose value is among
% the N smallest distinct values in Grid.
rank_bottom_n(Grid, N, Cells) :-
% Get sorted unique values; take first N (smallest); collect cells with those values.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    sort(Vals, Uniq),
    rank_first_n_(Uniq, N, BotVals),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        member(V, BotVals)), Cells).

% rank_above_rank(+Grid, +K, -Cells): sorted R-C positions whose grid-wide dense rank > K.
rank_above_rank(Grid, K, Cells) :-
% Compute global unique values; for each cell, compute rank; keep rank > K.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    sort(Vals, Uniq),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        rank_pos1_(Uniq, V, Rank),
        Rank > K), Cells).

% rank_below_rank(+Grid, +K, -Cells): sorted R-C positions whose grid-wide dense rank < K.
rank_below_rank(Grid, K, Cells) :-
% Compute global unique values; for each cell, compute rank; keep rank < K.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    sort(Vals, Uniq),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        rank_pos1_(Uniq, V, Rank),
        Rank < K), Cells).

% rank_pos1_(+SortedUniq, +V, -Pos): 1-based position of V in sorted unique list.
% Fails if V is not present.
rank_pos1_(Uniq, V, Pos) :-
% Walk the list from position 1, succeed when V matches the head.
    rank_pos1_acc_(Uniq, V, 1, Pos).

rank_pos1_acc_([H|_], H, Acc, Acc) :- !.
rank_pos1_acc_([_|T], V, Acc, Pos) :-
% Head does not match; increment counter and try the tail.
    Acc1 is Acc + 1,
    rank_pos1_acc_(T, V, Acc1, Pos).

% rank_zip_(+As, +Bs, -Pairs): zip two equal-length lists into A-B pairs.
rank_zip_([], [], []).
rank_zip_([A|As], [B|Bs], [A-B|Pairs]) :-
% Pair corresponding elements; recurse on tails.
    rank_zip_(As, Bs, Pairs).

% rank_last_n_(+List, +N, -LastN): last N elements of List.
% If List has fewer than N elements, returns the whole list.
rank_last_n_(List, N, LastN) :-
    length(List, Len),
    Skip is max(0, Len - N),
    rank_drop_(List, Skip, LastN).

% rank_first_n_(+List, +N, -FirstN): first N elements of List.
rank_first_n_(List, N, FirstN) :-
    rank_take_(List, N, FirstN).

% rank_take_(+List, +N, -Taken): first N elements of List.
rank_take_(_, 0, []) :- !.
rank_take_([], _, []) :- !.
rank_take_([H|T], N, [H|Rest]) :-
    N1 is N - 1,
    rank_take_(T, N1, Rest).

% rank_drop_(+List, +N, -Rest): drop N elements from the front of List.
rank_drop_(List, 0, List) :- !.
rank_drop_([_|T], N, Rest) :-
    N1 is N - 1,
    rank_drop_(T, N1, Rest).
