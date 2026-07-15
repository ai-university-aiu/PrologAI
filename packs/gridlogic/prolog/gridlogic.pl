:- module(gridlogic, [
    gridlogic_and/4,
    gridlogic_or/4,
    gridlogic_xor/4,
    gridlogic_not/4,
    gridlogic_subtract/4,
    gridlogic_common/4,
    gridlogic_differ/4,
    gridlogic_any/3,
    gridlogic_all/3,
    gridlogic_majority/3,
    gridlogic_unanimous/3,
    gridlogic_mask/5,
    gridlogic_if/5,
    gridlogic_filter/4
]).
% gridlogic.pl - Layer 233: Grid Logical Operations (ggl_* prefix).
% Fourteen predicates for cell-wise logical and set operations on grids.
% Pairwise: and, or, xor, not, subtract, common, differ.
% List-wise: any, all, majority, unanimous.
% Conditional: mask, if-then-else, filter.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% No cross-pack dependencies.
:- use_module(library(lists), [member/2, nth0/3]).

% --- PRIVATE HELPERS ---

% gridlogic_op_/5: apply a pairwise cell operation.
% V1, V2 are the two cell values; Bg is background; Op is the operation atom.
gridlogic_op_(V1, V2, Bg, and, V) :- !,
% AND: both non-bg → V1; else → Bg.
    (V1 \= Bg, V2 \= Bg -> V = V1 ; V = Bg).
gridlogic_op_(V1, V2, Bg, or, V) :- !,
% OR: first non-bg wins; else → Bg.
    (V1 \= Bg -> V = V1 ; V2 \= Bg -> V = V2 ; V = Bg).
gridlogic_op_(V1, V2, Bg, xor, V) :- !,
% XOR: exactly one non-bg → that value; else → Bg.
    (V1 \= Bg, V2 = Bg -> V = V1
    ; V1 = Bg, V2 \= Bg -> V = V2
    ; V = Bg).
gridlogic_op_(V1, V2, Bg, subtract, V) :- !,
% SUBTRACT: V1 non-bg AND V2 is Bg → V1; else → Bg.
    (V1 \= Bg, V2 = Bg -> V = V1 ; V = Bg).
gridlogic_op_(V1, V2, Bg, common, V) :- !,
% COMMON: V1 = V2 and both non-bg → V1; else → Bg.
    (V1 = V2, V1 \= Bg -> V = V1 ; V = Bg).
gridlogic_op_(V1, V2, Bg, differ, V) :- !,
% DIFFER: both non-bg and different → V1; else → Bg.
    (V1 \= Bg, V2 \= Bg, V1 \= V2 -> V = V1 ; V = Bg).
gridlogic_op_(V1, V2, Bg, unanimous, V) :- !,
% UNANIMOUS: V1 = V2 (any value) → V1; else → Bg.
    (V1 = V2 -> V = V1 ; V = Bg).

% gridlogic_pair_cells_/5: apply gridlogic_op_ to corresponding cells of two rows.
gridlogic_pair_cells_([], [], _, _, []).
gridlogic_pair_cells_([V1|T1], [V2|T2], Bg, Op, [V|Vs]) :-
    gridlogic_op_(V1, V2, Bg, Op, V),
    gridlogic_pair_cells_(T1, T2, Bg, Op, Vs).

% gridlogic_pair_/5: apply pairwise cell operation to two same-sized grids.
gridlogic_pair_([], [], _, _, []).
gridlogic_pair_([R1|T1], [R2|T2], Bg, Op, [NewRow|Rest]) :-
    gridlogic_pair_cells_(R1, R2, Bg, Op, NewRow),
    gridlogic_pair_(T1, T2, Bg, Op, Rest).

% gridlogic_count_/3: count occurrences of V in List.
gridlogic_count_(V, List, Count) :-
    findall(1, member(V, List), Ones),
    length(Ones, Count).

% gridlogic_unique_/2: collect unique elements of List (order may vary).
gridlogic_unique_([], []).
gridlogic_unique_([H|T], Result) :-
    (member(H, T) ->
        gridlogic_unique_(T, Result)
    ;
        gridlogic_unique_(T, Rest),
        Result = [H|Rest]
    ).

% gridlogic_max_pair_/2: find the Count-V pair with the highest Count.
gridlogic_max_pair_([Pair], Pair) :- !.
gridlogic_max_pair_([C1-V1|Rest], Best) :-
    gridlogic_max_pair_(Rest, RC-RV),
    (C1 > RC -> Best = C1-V1 ; Best = RC-RV).

% gridlogic_mode_/3: find the most frequent value in Vals if its count > Threshold.
% Fails if Vals is empty or no value exceeds the threshold.
gridlogic_mode_(Vals, Threshold, Mode) :-
    Vals \= [],
    gridlogic_unique_(Vals, Set),
    findall(Count-V, (member(V, Set), gridlogic_count_(V, Vals, Count)), Pairs),
    gridlogic_max_pair_(Pairs, BestCount-Mode),
    BestCount > Threshold.

% --- PUBLIC PREDICATES ---

% gridlogic_and(+Grid1, +Grid2, +BgColor, -Result)
% Cell-wise AND: where both grids have a non-BgColor cell, Result keeps Grid1's value.
% Where either cell is BgColor, Result has BgColor.
gridlogic_and(Grid1, Grid2, Bg, Result) :-
    gridlogic_pair_(Grid1, Grid2, Bg, and, Result).

% gridlogic_or(+Grid1, +Grid2, +BgColor, -Result)
% Cell-wise OR: Grid1's non-bg cells win; where Grid1 is bg, Grid2's value is used.
% Where both are bg, Result has BgColor.
gridlogic_or(Grid1, Grid2, Bg, Result) :-
    gridlogic_pair_(Grid1, Grid2, Bg, or, Result).

% gridlogic_xor(+Grid1, +Grid2, +BgColor, -Result)
% Cell-wise XOR: exactly one grid is non-bg → that value; both bg or both non-bg → BgColor.
gridlogic_xor(Grid1, Grid2, Bg, Result) :-
    gridlogic_pair_(Grid1, Grid2, Bg, xor, Result).

% gridlogic_not(+Grid, +BgColor, +FgColor, -Result)
% Logical NOT: BgColor cells become FgColor; non-BgColor cells become BgColor.
gridlogic_not(Grid, Bg, FgColor, Result) :-
% For each cell: bg → FgColor; non-bg → Bg.
    findall(NewRow,
        (member(Row, Grid),
         findall(V2, (member(V, Row), (V = Bg -> V2 = FgColor ; V2 = Bg)), NewRow)),
        Result).

% gridlogic_subtract(+Grid1, +Grid2, +BgColor, -Result)
% Set difference: cells where Grid1 is non-bg AND Grid2 is bg → Grid1's value; else bg.
gridlogic_subtract(Grid1, Grid2, Bg, Result) :-
    gridlogic_pair_(Grid1, Grid2, Bg, subtract, Result).

% gridlogic_common(+Grid1, +Grid2, +BgColor, -Result)
% Cells where both grids have the same non-BgColor value → that value; else bg.
gridlogic_common(Grid1, Grid2, Bg, Result) :-
    gridlogic_pair_(Grid1, Grid2, Bg, common, Result).

% gridlogic_differ(+Grid1, +Grid2, +BgColor, -Result)
% Cells where both grids are non-bg but have different values → Grid1's value; else bg.
gridlogic_differ(Grid1, Grid2, Bg, Result) :-
    gridlogic_pair_(Grid1, Grid2, Bg, differ, Result).

% gridlogic_any(+Grids, +BgColor, -Result)
% List-wise OR: at each position, the first non-bg value across the grid list wins.
% Equivalent to folding gridlogic_or left to right.
gridlogic_any([G], _, G) :- !.
gridlogic_any([G1|Rest], Bg, Result) :-
    gridlogic_any(Rest, Bg, RRest),
    gridlogic_pair_(G1, RRest, Bg, or, Result).

% gridlogic_all(+Grids, +BgColor, -Result)
% List-wise AND: at each position, non-bg value if ALL grids agree on the same non-bg.
% Equivalent to folding gridlogic_common left to right.
gridlogic_all([G], _, G) :- !.
gridlogic_all([G1|Rest], Bg, Result) :-
    gridlogic_all(Rest, Bg, RRest),
    gridlogic_pair_(G1, RRest, Bg, common, Result).

% gridlogic_majority(+Grids, +BgColor, -Result)
% At each position, the most frequent non-bg value if it appears more than N/2 times.
% If no value exceeds that threshold (tie or all bg), the cell is BgColor.
gridlogic_majority(Grids, Bg, Result) :-
    length(Grids, N),
    Threshold is N / 2,
    Grids = [G1|_],
    length(G1, H), H1 is H - 1,
    G1 = [Row1|_], length(Row1, W), W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R),
         findall(V,
             (between(0, W1, C),
              findall(Val,
                  (member(G, Grids),
                   nth0(R, G, GRow), nth0(C, GRow, Val), Val \= Bg),
                  Vals),
              (gridlogic_mode_(Vals, Threshold, V) -> true ; V = Bg)),
             NewRow)),
        Result).

% gridlogic_unanimous(+Grids, +BgColor, -Result)
% At each position, all grids (including bg cells) must agree on the same value.
% If any two grids differ, the cell is BgColor.
gridlogic_unanimous([G], _, G) :- !.
gridlogic_unanimous([G1|Rest], Bg, Result) :-
    gridlogic_unanimous(Rest, Bg, RRest),
    gridlogic_pair_(G1, RRest, Bg, unanimous, Result).

% gridlogic_mask(+Grid, +MaskGrid, +MaskColor, +BgColor, -Result)
% Keep Grid's cell values where MaskGrid has MaskColor; all others become BgColor.
gridlogic_mask(Grid, MaskGrid, MaskColor, Bg, Result) :-
    gridlogic_mask_rows_(Grid, MaskGrid, MaskColor, Bg, Result).

% gridlogic_mask_rows_/5: apply mask row by row.
gridlogic_mask_rows_([], [], _, _, []).
gridlogic_mask_rows_([R1|T1], [R2|T2], MC, Bg, [NR|Rest]) :-
    gridlogic_mask_cells_(R1, R2, MC, Bg, NR),
    gridlogic_mask_rows_(T1, T2, MC, Bg, Rest).

% gridlogic_mask_cells_/5: apply mask cell by cell.
gridlogic_mask_cells_([], [], _, _, []).
gridlogic_mask_cells_([V1|T1], [V2|T2], MC, Bg, [V|Vs]) :-
% Keep Grid value where Mask = MaskColor; else replace with Bg.
    (V2 = MC -> V = V1 ; V = Bg),
    gridlogic_mask_cells_(T1, T2, MC, Bg, Vs).

% gridlogic_if(+CondGrid, +CondColor, +ThenGrid, +ElseGrid, -Result)
% Cell-wise conditional: where CondGrid = CondColor → ThenGrid value; else ElseGrid value.
gridlogic_if(Cond, CC, Then, Else, Result) :-
    gridlogic_if_rows_(Cond, Then, Else, CC, Result).

% gridlogic_if_rows_/5: apply conditional row by row.
gridlogic_if_rows_([], [], [], _, []).
gridlogic_if_rows_([RC|TC], [RT|TT], [RE|TE], CC, [NR|Rest]) :-
    gridlogic_if_cells_(RC, RT, RE, CC, NR),
    gridlogic_if_rows_(TC, TT, TE, CC, Rest).

% gridlogic_if_cells_/5: apply conditional cell by cell.
gridlogic_if_cells_([], [], [], _, []).
gridlogic_if_cells_([VC|TC], [VT|TT], [VE|TE], CC, [V|Vs]) :-
% Select ThenGrid value if Cond = CondColor; else ElseGrid value.
    (VC = CC -> V = VT ; V = VE),
    gridlogic_if_cells_(TC, TT, TE, CC, Vs).

% gridlogic_filter(+Grid, +Colors, +BgColor, -Result)
% Keep cells whose color is in the Colors list; replace all others with BgColor.
gridlogic_filter(Grid, Colors, Bg, Result) :-
% For each cell: if color in Colors keep it; else → Bg.
    findall(NewRow,
        (member(Row, Grid),
         findall(V2, (member(V, Row),
                      (member(V, Colors) -> V2 = V ; V2 = Bg)), NewRow)),
        Result).
