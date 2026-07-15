% gridops.pl - Layer 141: Grid Collection Operations (go_* prefix).
% Provides predicates for reasoning across a collection of multiple 2D integer
% grids simultaneously: finding cell positions that always, never, or sometimes
% hold a given value; counting per-cell value occurrences; computing the modal
% value per cell; finding stable and unstable cells; testing grid equality; and
% performing elementwise arithmetic (add, subtract, max, min, overlay, intersect).
:- module(grid_operations, [
    grid_operations_always/3,
    grid_operations_never/3,
    grid_operations_sometimes/3,
    grid_operations_count_v/3,
    grid_operations_modal/2,
    grid_operations_stable/2,
    grid_operations_unstable/2,
    grid_operations_eq/2,
    grid_operations_add/3,
    grid_operations_sub/3,
    grid_operations_emax/3,
    grid_operations_emin/3,
    grid_operations_overlay/3,
    grid_operations_intersect/3
]).
% Import list utilities; sort/2, msort/2, length/2, between/3, forall/2, findall/3 are built-ins.
:- use_module(library(lists), [member/2, nth0/3, last/2]).
% Import maplist/3, maplist/4, include/3 for elementwise grid operations.
:- use_module(library(apply), [maplist/3, maplist/4, include/3]).

% grid_operations_dims_(+Grids, -NR, -NC): extract row and column counts from the first grid.
grid_operations_dims_(Grids, NR, NC) :-
% Use the first grid in the collection for dimension extraction.
    (Grids = [G1|_], G1 = [Fr|_] -> length(G1, NR), length(Fr, NC) ; NR=0, NC=0).

% grid_operations_always(+Grids, +V, -Cells): Cells is the sorted list of R-C positions at which
% EVERY grid in Grids contains value V. Empty if Grids is empty or V absent in all.
grid_operations_always(Grids, V, Cells) :-
% Determine grid dimensions from the first grid.
    grid_operations_dims_(Grids, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
% Collect positions where every grid has value V using forall.
    findall(R-C, (between(0, NR1, R), between(0, NC1, C),
        forall(member(Grid, Grids),
            (nth0(R, Grid, Row), nth0(C, Row, V)))), Cells).

% grid_operations_never(+Grids, +V, -Cells): Cells is the sorted list of R-C positions at which
% NO grid in Grids contains value V.
grid_operations_never(Grids, V, Cells) :-
% Determine grid dimensions.
    grid_operations_dims_(Grids, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
% Collect positions where no grid has value V.
    findall(R-C, (between(0, NR1, R), between(0, NC1, C),
        \+ (member(Grid, Grids),
            nth0(R, Grid, Row), nth0(C, Row, V))), Cells).

% grid_operations_sometimes(+Grids, +V, -Cells): Cells is the sorted list of R-C positions at which
% SOME (at least one) grid has value V but NOT every grid does. Deduplicated by sort.
grid_operations_sometimes(Grids, V, Cells) :-
% Determine grid dimensions.
    grid_operations_dims_(Grids, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
% Collect positions where at least one grid has V but not all grids do.
    findall(R-C, (between(0, NR1, R), between(0, NC1, C),
        member(Grid, Grids),
        nth0(R, Grid, Row), nth0(C, Row, V),
        \+ forall(member(G2, Grids), (nth0(R, G2, Row2), nth0(C, Row2, V)))), Raw),
% Remove duplicates arising from multiple grids having V at the same position.
    sort(Raw, Cells).

% grid_operations_count_v(+Grids, +V, -CountGrid): CountGrid is a grid of integers where each
% cell (R,C) holds the count of how many grids in Grids have value V at (R,C).
grid_operations_count_v(Grids, V, CountGrid) :-
% Determine grid dimensions.
    grid_operations_dims_(Grids, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
% Build a count row for each row index, then collect all rows.
    findall(CountRow,
        (between(0, NR1, R),
         findall(Cnt,
             (between(0, NC1, C),
% Count grids that have V at (R,C) using findall then length.
              findall(x, (member(Grid, Grids),
                  nth0(R, Grid, GRow), nth0(C, GRow, V)), Ms),
              length(Ms, Cnt)),
             CountRow)),
        CountGrid).

% grid_operations_modal(+Grids, -ModalGrid): ModalGrid is a grid where each cell (R,C) holds
% the value that appears most often across all grids at that position. When counts
% tie, the smallest value wins.
grid_operations_modal(Grids, ModalGrid) :-
% Determine grid dimensions.
    grid_operations_dims_(Grids, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
% Build a modal row for each row, then collect all rows.
    findall(ModalRow,
        (between(0, NR1, R),
         findall(MV,
             (between(0, NC1, C),
% Collect all values at (R,C) from all grids.
              findall(V, (member(Grid, Grids), nth0(R, Grid, GRow), nth0(C, GRow, V)), Vs),
              grid_operations_mode_(Vs, MV)),
             ModalRow)),
        ModalGrid).

% grid_operations_stable(+Grids, -Triples): Triples is the list of R-C-V terms for positions
% where ALL grids in Grids agree on value V. The value V comes from the first grid.
grid_operations_stable(Grids, Triples) :-
% Determine grid dimensions.
    grid_operations_dims_(Grids, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
% A cell is stable if the first grid's value matches all other grids' values.
    findall(R-C-V, (between(0, NR1, R), between(0, NC1, C),
        Grids = [FG|RestGs],
        nth0(R, FG, FR), nth0(C, FR, V),
        forall(member(Grid, RestGs),
            (nth0(R, Grid, GRow), nth0(C, GRow, V)))), Triples).

% grid_operations_unstable(+Grids, -Cells): Cells is the sorted list of R-C positions where
% the grids in Grids do NOT all agree on the same value.
grid_operations_unstable(Grids, Cells) :-
% Determine grid dimensions.
    grid_operations_dims_(Grids, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
% First collect stable positions so we can exclude them.
    grid_operations_stable(Grids, Stable),
% Collect all positions not in the stable set.
    findall(R-C, (between(0, NR1, R), between(0, NC1, C),
        \+ member(R-C-_, Stable)), Cells).

% grid_operations_eq(+G1, +G2): succeeds if G1 and G2 are cell-for-cell identical grids.
grid_operations_eq(G1, G2) :-
% Unification of two lists of lists tests all elements.
    G1 = G2.

% grid_operations_add(+G1, +G2, -G): G is the elementwise integer sum of G1 and G2.
% G[R][C] = G1[R][C] + G2[R][C]. Grids must have identical dimensions.
grid_operations_add(G1, G2, G) :-
% Apply row-wise addition using maplist/4.
    maplist(grid_operations_add_row_, G1, G2, G).

% grid_operations_sub(+G1, +G2, -G): G is the elementwise integer difference G1 minus G2.
% G[R][C] = G1[R][C] - G2[R][C]. Grids must have identical dimensions.
grid_operations_sub(G1, G2, G) :-
% Apply row-wise subtraction using maplist/4.
    maplist(grid_operations_sub_row_, G1, G2, G).

% grid_operations_emax(+G1, +G2, -G): G is the elementwise integer maximum of G1 and G2.
% G[R][C] = max(G1[R][C], G2[R][C]).
grid_operations_emax(G1, G2, G) :-
% Apply row-wise max using maplist/4.
    maplist(grid_operations_emax_row_, G1, G2, G).

% grid_operations_emin(+G1, +G2, -G): G is the elementwise integer minimum of G1 and G2.
% G[R][C] = min(G1[R][C], G2[R][C]).
grid_operations_emin(G1, G2, G) :-
% Apply row-wise min using maplist/4.
    maplist(grid_operations_emin_row_, G1, G2, G).

% grid_operations_overlay(+Grids, +Bg, -G): G is the overlay of all grids. At each (R,C), the
% result is the first non-Bg value found scanning Grids in order; Bg if all are Bg.
grid_operations_overlay(Grids, Bg, G) :-
% Determine grid dimensions.
    grid_operations_dims_(Grids, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
% Build each row by scanning grids for the first non-Bg value per cell.
    findall(Row,
        (between(0, NR1, R),
         findall(V,
             (between(0, NC1, C), grid_operations_overlay_cell_(Grids, Bg, R, C, V)),
             Row)),
        G).

% grid_operations_intersect(+Grids, +Bg, -G): G is the intersection of all grids. At each (R,C),
% if ALL grids have the same non-Bg value V, the result is V. Otherwise it is Bg.
grid_operations_intersect(Grids, Bg, G) :-
% Determine grid dimensions.
    grid_operations_dims_(Grids, NR, NC),
    NR1 is NR - 1, NC1 is NC - 1,
% Build each row by checking full agreement among grids.
    findall(Row,
        (between(0, NR1, R),
         findall(V,
             (between(0, NC1, C), grid_operations_intersect_cell_(Grids, Bg, R, C, V)),
             Row)),
        G).

% grid_operations_mode_(+Vals, -Mode): Mode is the value appearing most often in Vals.
% When multiple values tie for the highest count, the smallest value wins.
grid_operations_mode_(Vals, Mode) :-
% Deduplicate to find candidates.
    sort(Vals, Uniq),
% Count each unique value.
    findall(N-V, (member(V, Uniq), include(=(V), Vals, Ms), length(Ms, N)), Counts),
% Sort ascending by count then by value; last entry has highest count.
    msort(Counts, Sorted),
    last(Sorted, MaxN-_),
% Among all entries with the maximum count, collect values.
% In msort order, same-N entries are sorted ascending by V.
    findall(V, member(MaxN-V, Sorted), Candidates),
% Take the first (smallest) candidate as Mode.
    Candidates = [Mode|_].

% grid_operations_add_row_(+Row1, +Row2, -Row): Row is the elementwise sum of Row1 and Row2.
grid_operations_add_row_(Row1, Row2, Row) :-
    maplist(grid_operations_add_cell_, Row1, Row2, Row).

% grid_operations_add_cell_(+A, +B, -C): C is A + B.
grid_operations_add_cell_(A, B, C) :-
    C is A + B.

% grid_operations_sub_row_(+Row1, +Row2, -Row): Row is the elementwise difference Row1 minus Row2.
grid_operations_sub_row_(Row1, Row2, Row) :-
    maplist(grid_operations_sub_cell_, Row1, Row2, Row).

% grid_operations_sub_cell_(+A, +B, -C): C is A - B.
grid_operations_sub_cell_(A, B, C) :-
    C is A - B.

% grid_operations_emax_row_(+Row1, +Row2, -Row): Row is the elementwise maximum of Row1 and Row2.
grid_operations_emax_row_(Row1, Row2, Row) :-
    maplist(grid_operations_emax_cell_, Row1, Row2, Row).

% grid_operations_emax_cell_(+A, +B, -C): C is max(A, B).
grid_operations_emax_cell_(A, B, C) :-
    C is max(A, B).

% grid_operations_emin_row_(+Row1, +Row2, -Row): Row is the elementwise minimum of Row1 and Row2.
grid_operations_emin_row_(Row1, Row2, Row) :-
    maplist(grid_operations_emin_cell_, Row1, Row2, Row).

% grid_operations_emin_cell_(+A, +B, -C): C is min(A, B).
grid_operations_emin_cell_(A, B, C) :-
    C is min(A, B).

% grid_operations_overlay_cell_(+Grids, +Bg, +R, +C, -V): V is the first non-Bg value at (R,C)
% across Grids in order, or Bg if all grids have Bg at (R,C).
grid_operations_overlay_cell_(Grids, Bg, R, C, V) :-
% Soft-cut: use first non-Bg value found; fall through to Bg if none found.
    (member(Grid, Grids), nth0(R, Grid, GRow), nth0(C, GRow, GV), GV \= Bg
    -> V = GV
    ;  V = Bg).

% grid_operations_intersect_cell_(+Grids, +Bg, +R, +C, -V): V is the common non-Bg value
% at (R,C) if ALL grids have the same non-Bg value there; otherwise V is Bg.
grid_operations_intersect_cell_(Grids, Bg, R, C, V) :-
% Check the first grid: if it has non-Bg, verify all others match.
    (Grids = [FG|RestGs],
     nth0(R, FG, FR), nth0(C, FR, FV), FV \= Bg,
     forall(member(Grid, RestGs), (nth0(R, Grid, GRow), nth0(C, GRow, FV)))
    -> V = FV
    ;  V = Bg).
