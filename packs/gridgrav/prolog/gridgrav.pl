:- module(gridgrav, [
    gv_fall_down/3,
    gv_fall_up/3,
    gv_fall_left/3,
    gv_fall_right/3,
    gv_col_pile_h/4,
    gv_row_pile_w/4,
    gv_all_col_piles/3,
    gv_all_row_piles/3,
    gv_floating_cells/3,
    gv_settled/2,
    gv_col_gap_above/4,
    gv_max_col_pile/3,
    gv_min_col_pile/3,
    gv_non_bg_count/3
]).
% gridgrav.pl - Layer 223: Grid Gravity Simulation (gv_* prefix).
% Fourteen predicates for simulating gravity within a raw grid: settling
% non-background cells to the bottom, top, left, or right of their row or
% column; measuring pile heights and row widths; detecting floating cells;
% and computing column gap and column pile statistics.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% BgColor: the background color atom; non-BgColor cells are "non-bg" (active).
% Fall down: non-bg cells settle to the bottom of each column.
% Fall up: non-bg cells settle to the top of each column.
% Fall left: non-bg cells settle to the left of each row.
% Fall right: non-bg cells settle to the right of each row.
% No cross-pack dependencies.
:- use_module(library(lists), [nth0/3, member/2, append/3, reverse/2]).
:- use_module(library(apply), [maplist/3]).

% --- PRIVATE HELPERS ---

% Grid dimensions.
gv_dims_(Grid, H, W) :-
    length(Grid, H),
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Extract column C as a top-to-bottom list.
gv_col_(Grid, C, Col) :-
    findall(V, (member(Row, Grid), nth0(C, Row, V)), Col).

% Extract non-bg elements from a list in order.
gv_non_bg_(List, BgColor, NonBg) :-
    findall(V, (member(V, List), V \= BgColor), NonBg).

% Build a list of N copies of BgColor.
gv_bg_pad_(BgColor, N, Pad) :-
    findall(BgColor, between(1, N, _), Pad).

% Settle a column downward: bg cells rise to top, non-bg sink to bottom.
gv_settle_col_down_(Col, BgColor, Settled) :-
    gv_non_bg_(Col, BgColor, NonBg),
    length(Col, Len), length(NonBg, NNB), BgN is Len - NNB,
    gv_bg_pad_(BgColor, BgN, Pad),
    append(Pad, NonBg, Settled).

% Settle a column upward: non-bg cells rise to top, bg sink to bottom.
gv_settle_col_up_(Col, BgColor, Settled) :-
    gv_non_bg_(Col, BgColor, NonBg),
    length(Col, Len), length(NonBg, NNB), BgN is Len - NNB,
    gv_bg_pad_(BgColor, BgN, Pad),
    append(NonBg, Pad, Settled).

% Settle a row leftward: non-bg cells pack left, bg cells fill right.
gv_settle_row_left_(Row, BgColor, Settled) :-
    gv_non_bg_(Row, BgColor, NonBg),
    length(Row, Len), length(NonBg, NNB), BgN is Len - NNB,
    gv_bg_pad_(BgColor, BgN, Pad),
    append(NonBg, Pad, Settled).

% Settle a row rightward: non-bg cells pack right, bg cells fill left.
gv_settle_row_right_(Row, BgColor, Settled) :-
    gv_non_bg_(Row, BgColor, NonBg),
    length(Row, Len), length(NonBg, NNB), BgN is Len - NNB,
    gv_bg_pad_(BgColor, BgN, Pad),
    append(Pad, NonBg, Settled).

% Helper: apply column settlement (down) given a bound BgColor.
gv_apply_down_(BgColor, Col, Settled) :- gv_settle_col_down_(Col, BgColor, Settled).

% Helper: apply column settlement (up) given a bound BgColor.
gv_apply_up_(BgColor, Col, Settled) :- gv_settle_col_up_(Col, BgColor, Settled).

% Helper: apply row settlement (left) given a bound BgColor.
gv_apply_left_(BgColor, Row, Settled) :- gv_settle_row_left_(Row, BgColor, Settled).

% Helper: apply row settlement (right) given a bound BgColor.
gv_apply_right_(BgColor, Row, Settled) :- gv_settle_row_right_(Row, BgColor, Settled).

% Reconstruct a grid (H rows, W cols) from a list of W settled columns.
gv_cols_to_grid_(SettledCols, H, Grid) :-
    H1 is H - 1,
    findall(Row,
        (between(0, H1, R),
         findall(V, (member(SC, SettledCols), nth0(R, SC, V)), Row)),
        Grid).

% Count leading BgColor cells at the top of a column.
gv_count_leading_bg_([], _, 0).
gv_count_leading_bg_([V|_], BgColor, 0) :- V \= BgColor, !.
gv_count_leading_bg_([BgColor|Rest], BgColor, Gap) :-
    gv_count_leading_bg_(Rest, BgColor, G1),
    Gap is G1 + 1.

% --- PUBLIC PREDICATES ---

% gv_fall_down(+Grid, +BgColor, -Fallen)
% Fallen is Grid with non-BgColor cells settled to the bottom of each column.
% BgColor cells fill the vacated top positions in each column.
gv_fall_down(Grid, BgColor, Fallen) :-
    gv_dims_(Grid, H, W),
    (W =:= 0 -> Fallen = Grid ;
     W1 is W - 1,
     findall(SC,
         (between(0, W1, C),
          gv_col_(Grid, C, Col),
          gv_settle_col_down_(Col, BgColor, SC)),
         SettledCols),
     gv_cols_to_grid_(SettledCols, H, Fallen)).

% gv_fall_up(+Grid, +BgColor, -Fallen)
% Fallen is Grid with non-BgColor cells settled to the top of each column.
gv_fall_up(Grid, BgColor, Fallen) :-
    gv_dims_(Grid, H, W),
    (W =:= 0 -> Fallen = Grid ;
     W1 is W - 1,
     findall(SC,
         (between(0, W1, C),
          gv_col_(Grid, C, Col),
          gv_settle_col_up_(Col, BgColor, SC)),
         SettledCols),
     gv_cols_to_grid_(SettledCols, H, Fallen)).

% gv_fall_left(+Grid, +BgColor, -Fallen)
% Fallen is Grid with non-BgColor cells settled to the left of each row.
gv_fall_left(Grid, BgColor, Fallen) :-
    maplist(gv_apply_left_(BgColor), Grid, Fallen).

% gv_fall_right(+Grid, +BgColor, -Fallen)
% Fallen is Grid with non-BgColor cells settled to the right of each row.
gv_fall_right(Grid, BgColor, Fallen) :-
    maplist(gv_apply_right_(BgColor), Grid, Fallen).

% gv_col_pile_h(+Grid, +C, +BgColor, -H)
% H is the count of non-BgColor cells in column C.
gv_col_pile_h(Grid, C, BgColor, H) :-
    gv_col_(Grid, C, Col),
    gv_non_bg_(Col, BgColor, NonBg),
    length(NonBg, H).

% gv_row_pile_w(+Grid, +R, +BgColor, -W)
% W is the count of non-BgColor cells in row R.
gv_row_pile_w(Grid, R, BgColor, W) :-
    nth0(R, Grid, Row),
    gv_non_bg_(Row, BgColor, NonBg),
    length(NonBg, W).

% gv_all_col_piles(+Grid, +BgColor, -Piles)
% Piles is the list of non-BgColor cell counts for columns 0, 1, ... W-1.
gv_all_col_piles(Grid, BgColor, Piles) :-
    gv_dims_(Grid, _, W),
    (W =:= 0 -> Piles = [] ;
     W1 is W - 1,
     findall(H, (between(0, W1, C), gv_col_pile_h(Grid, C, BgColor, H)), Piles)).

% gv_all_row_piles(+Grid, +BgColor, -Piles)
% Piles is the list of non-BgColor cell counts for rows 0, 1, ... H-1.
gv_all_row_piles(Grid, BgColor, Piles) :-
    length(Grid, H),
    (H =:= 0 -> Piles = [] ;
     H1 is H - 1,
     findall(W, (between(0, H1, R), gv_row_pile_w(Grid, R, BgColor, W)), Piles)).

% gv_floating_cells(+Grid, +BgColor, -Cells)
% Cells is the list of R-C pairs for non-BgColor cells that have a BgColor cell
% directly below them in the same column (i.e., they would fall under down gravity).
gv_floating_cells(Grid, BgColor, Cells) :-
    gv_dims_(Grid, H, W),
    H2 is H - 2, W1 is W - 1,
    (H2 < 0 -> Cells = [] ;
     findall(R-C,
         (between(0, H2, R),
          between(0, W1, C),
          nth0(R, Grid, Row), nth0(C, Row, V), V \= BgColor,
          R1 is R + 1,
          nth0(R1, Grid, BelowRow), nth0(C, BelowRow, Bg), Bg = BgColor),
         Cells)).

% gv_settled(+Grid, +BgColor)
% Succeeds if Grid is settled under down gravity: no non-BgColor cell has
% a BgColor cell directly below it in the same column.
gv_settled(Grid, BgColor) :-
    gv_floating_cells(Grid, BgColor, []).

% gv_col_gap_above(+Grid, +C, +BgColor, -Gap)
% Gap is the count of BgColor cells at the top of column C before the first
% non-BgColor cell. Returns H (full column height) if column is all BgColor.
gv_col_gap_above(Grid, C, BgColor, Gap) :-
    gv_col_(Grid, C, Col),
    gv_count_leading_bg_(Col, BgColor, Gap).

% gv_max_col_pile(+Grid, +BgColor, -MaxC)
% MaxC is the 0-indexed column with the most non-BgColor cells.
% Ties are broken by lowest column index.
gv_max_col_pile(Grid, BgColor, MaxC) :-
% Build H-C pairs for all columns and sort ascending by H.
    gv_dims_(Grid, _, W), W1 is W - 1,
    findall(H-C, (between(0, W1, C), gv_col_pile_h(Grid, C, BgColor, H)), Pairs),
    msort(Pairs, Sorted),
% The last element of sorted pairs has the highest H.
    reverse(Sorted, [BestH-_|_]),
% Collect all column indices with that height; take the lowest.
    findall(C, member(BestH-C, Pairs), Cs),
    Cs = [MaxC|_].

% gv_min_col_pile(+Grid, +BgColor, -MinC)
% MinC is the 0-indexed column with the fewest non-BgColor cells.
% Considers all columns including those with zero non-bg cells.
% Ties are broken by lowest column index.
gv_min_col_pile(Grid, BgColor, MinC) :-
    gv_dims_(Grid, _, W), W1 is W - 1,
    findall(H-C, (between(0, W1, C), gv_col_pile_h(Grid, C, BgColor, H)), Pairs),
    msort(Pairs, [BestH-_|_]),
    findall(C, member(BestH-C, Pairs), Cs),
    Cs = [MinC|_].

% gv_non_bg_count(+Grid, +BgColor, -N)
% N is the total count of non-BgColor cells across the entire grid.
gv_non_bg_count(Grid, BgColor, N) :-
    findall(V, (member(Row, Grid), member(V, Row), V \= BgColor), Cells),
    length(Cells, N).
