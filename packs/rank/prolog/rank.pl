% rank.pl - Layer 137: Dense Ranking of Integer Values in Lists and 2D Grids (rk_* prefix).
% Provides dense ranking (rank 1 = smallest distinct value) for integer lists,
% 0-based argsort, per-row and per-column dense ranking grids, grid-wide dense
% ranking, cell-level rank queries, top-N and bottom-N cell selection, and
% rank-threshold cell filtering.
%
% Dense rank: given distinct sorted values [v1 < v2 < ... < vK], value vi maps
% to rank i. All occurrences of the same value receive the same rank.
:- module(rank, [
    rk_rank_of/3,
    rk_dense/2,
    rk_argsort_asc/2,
    rk_argsort_desc/2,
    rk_row_dense/2,
    rk_col_dense/2,
    rk_grid_dense/2,
    rk_row_rank_of/4,
    rk_col_rank_of/4,
    rk_grid_rank_of/4,
    rk_top_n/3,
    rk_bottom_n/3,
    rk_above_rank/3,
    rk_below_rank/3
]).
% Import list utilities; sort/2, msort/2, length/2, between/3, findall/3 are built-ins.
:- use_module(library(lists), [member/2, nth0/3, numlist/3]).

% rk_rank_of(+List, +V, -R): R is the 1-based dense rank of value V in List.
% Rank 1 = smallest distinct value, 2 = second smallest, etc. Fails if V absent.
rk_rank_of(List, V, R) :-
% Sort to get unique values in ascending order, then find 1-based position of V.
    sort(List, Uniq),
    rk_pos1_(Uniq, V, R).

% rk_dense(+List, -Ranks): Ranks is the list of 1-based dense ranks for each element.
% Elements with the same value receive the same rank.
rk_dense(List, Ranks) :-
% Sort unique values ascending; map each element to its 1-based position in Uniq.
    sort(List, Uniq),
    findall(R, (member(V, List), rk_pos1_(Uniq, V, R)), Ranks).

% rk_argsort_asc(+List, -Indices): Indices are 0-based positions of List elements
% sorted in ascending order. Stable: equal values keep their original left-to-right order.
rk_argsort_asc(List, Indices) :-
% Pair each element with its 0-based index; msort by value (stable); extract indices.
    length(List, N), N1 is N - 1,
    numlist(0, N1, Idxs),
    rk_zip_(List, Idxs, Pairs),
    msort(Pairs, Sorted),
    findall(I, member(_-I, Sorted), Indices).

% rk_argsort_desc(+List, -Indices): 0-based positions sorted in descending value order.
% Stable: equal values keep original left-to-right order.
rk_argsort_desc(List, Indices) :-
% Negate values so ascending msort gives descending order; extract indices.
    length(List, N), N1 is N - 1,
    numlist(0, N1, Idxs),
    rk_zip_(List, Idxs, Pairs),
    findall(NV-I, (member(V-I, Pairs), NV is -V), NegPairs),
    msort(NegPairs, Sorted),
    findall(I, member(_-I, Sorted), Indices).

% rk_row_dense(+Grid, -RankGrid): each cell replaced with its 1-based dense rank
% within its own row.
rk_row_dense(Grid, RankGrid) :-
% Apply rk_dense to each row independently.
    findall(Ranks, (member(Row, Grid), rk_dense(Row, Ranks)), RankGrid).

% rk_col_dense(+Grid, -RankGrid): each cell replaced with its 1-based dense rank
% within its own column.
rk_col_dense(Grid, RankGrid) :-
% For each (row, col) cell, collect the column values, rank, return cell rank.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(RowRanks, (between(0, H1, R),
        findall(Rank, (between(0, W1, C),
            findall(CV, (member(Row2, Grid), nth0(C, Row2, CV)), ColVals),
            sort(ColVals, Uniq),
            nth0(R, Grid, CRow), nth0(C, CRow, V),
            rk_pos1_(Uniq, V, Rank)), RowRanks)), RankGrid).

% rk_grid_dense(+Grid, -RankGrid): each cell replaced with its 1-based dense rank
% among ALL cell values in the entire grid.
rk_grid_dense(Grid, RankGrid) :-
% Flatten all values, get unique sorted, map each cell to its rank.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    sort(Vals, Uniq),
    findall(RowRanks, (member(Row, Grid),
        findall(R, (member(V, Row), rk_pos1_(Uniq, V, R)), RowRanks)), RankGrid).

% rk_row_rank_of(+Grid, +R, +C, -Rank): 1-based dense rank of cell (R,C) within row R.
rk_row_rank_of(Grid, R, C, Rank) :-
% Extract the row; get cell value; find its rank in the sorted unique row values.
    nth0(R, Grid, Row),
    nth0(C, Row, V),
    sort(Row, Uniq),
    rk_pos1_(Uniq, V, Rank).

% rk_col_rank_of(+Grid, +R, +C, -Rank): 1-based dense rank of cell (R,C) within col C.
rk_col_rank_of(Grid, R, C, Rank) :-
% Collect all column values; get cell value; rank it.
    findall(V, (member(Row, Grid), nth0(C, Row, V)), ColVals),
    nth0(R, Grid, CRow), nth0(C, CRow, CV),
    sort(ColVals, Uniq),
    rk_pos1_(Uniq, CV, Rank).

% rk_grid_rank_of(+Grid, +R, +C, -Rank): 1-based dense rank of cell (R,C) among all cells.
rk_grid_rank_of(Grid, R, C, Rank) :-
% Flatten; sort; get cell value; rank it globally.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    sort(Vals, Uniq),
    nth0(R, Grid, CRow), nth0(C, CRow, CV),
    rk_pos1_(Uniq, CV, Rank).

% rk_top_n(+Grid, +N, -Cells): sorted R-C positions of cells whose value is among
% the N largest distinct values in Grid (all cells with those values included).
rk_top_n(Grid, N, Cells) :-
% Get sorted unique values; take last N (largest); collect cells with those values.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    sort(Vals, Uniq),
    rk_last_n_(Uniq, N, TopVals),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        member(V, TopVals)), Cells).

% rk_bottom_n(+Grid, +N, -Cells): sorted R-C positions of cells whose value is among
% the N smallest distinct values in Grid.
rk_bottom_n(Grid, N, Cells) :-
% Get sorted unique values; take first N (smallest); collect cells with those values.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    sort(Vals, Uniq),
    rk_first_n_(Uniq, N, BotVals),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        member(V, BotVals)), Cells).

% rk_above_rank(+Grid, +K, -Cells): sorted R-C positions whose grid-wide dense rank > K.
rk_above_rank(Grid, K, Cells) :-
% Compute global unique values; for each cell, compute rank; keep rank > K.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    sort(Vals, Uniq),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        rk_pos1_(Uniq, V, Rank),
        Rank > K), Cells).

% rk_below_rank(+Grid, +K, -Cells): sorted R-C positions whose grid-wide dense rank < K.
rk_below_rank(Grid, K, Cells) :-
% Compute global unique values; for each cell, compute rank; keep rank < K.
    findall(V, (member(Row, Grid), member(V, Row)), Vals),
    sort(Vals, Uniq),
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        rk_pos1_(Uniq, V, Rank),
        Rank < K), Cells).

% rk_pos1_(+SortedUniq, +V, -Pos): 1-based position of V in sorted unique list.
% Fails if V is not present.
rk_pos1_(Uniq, V, Pos) :-
% Walk the list from position 1, succeed when V matches the head.
    rk_pos1_acc_(Uniq, V, 1, Pos).

rk_pos1_acc_([H|_], H, Acc, Acc) :- !.
rk_pos1_acc_([_|T], V, Acc, Pos) :-
% Head does not match; increment counter and try the tail.
    Acc1 is Acc + 1,
    rk_pos1_acc_(T, V, Acc1, Pos).

% rk_zip_(+As, +Bs, -Pairs): zip two equal-length lists into A-B pairs.
rk_zip_([], [], []).
rk_zip_([A|As], [B|Bs], [A-B|Pairs]) :-
% Pair corresponding elements; recurse on tails.
    rk_zip_(As, Bs, Pairs).

% rk_last_n_(+List, +N, -LastN): last N elements of List.
% If List has fewer than N elements, returns the whole list.
rk_last_n_(List, N, LastN) :-
    length(List, Len),
    Skip is max(0, Len - N),
    rk_drop_(List, Skip, LastN).

% rk_first_n_(+List, +N, -FirstN): first N elements of List.
rk_first_n_(List, N, FirstN) :-
    rk_take_(List, N, FirstN).

% rk_take_(+List, +N, -Taken): first N elements of List.
rk_take_(_, 0, []) :- !.
rk_take_([], _, []) :- !.
rk_take_([H|T], N, [H|Rest]) :-
    N1 is N - 1,
    rk_take_(T, N1, Rest).

% rk_drop_(+List, +N, -Rest): drop N elements from the front of List.
rk_drop_(List, 0, List) :- !.
rk_drop_([_|T], N, Rest) :-
    N1 is N - 1,
    rk_drop_(T, N1, Rest).
