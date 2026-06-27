:- module(gridlogic, [
    ggl_and/4,
    ggl_or/4,
    ggl_xor/4,
    ggl_not/4,
    ggl_subtract/4,
    ggl_common/4,
    ggl_differ/4,
    ggl_any/3,
    ggl_all/3,
    ggl_majority/3,
    ggl_unanimous/3,
    ggl_mask/5,
    ggl_if/5,
    ggl_filter/4
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

% ggl_op_/5: apply a pairwise cell operation.
% V1, V2 are the two cell values; Bg is background; Op is the operation atom.
ggl_op_(V1, V2, Bg, and, V) :- !,
% AND: both non-bg → V1; else → Bg.
    (V1 \= Bg, V2 \= Bg -> V = V1 ; V = Bg).
ggl_op_(V1, V2, Bg, or, V) :- !,
% OR: first non-bg wins; else → Bg.
    (V1 \= Bg -> V = V1 ; V2 \= Bg -> V = V2 ; V = Bg).
ggl_op_(V1, V2, Bg, xor, V) :- !,
% XOR: exactly one non-bg → that value; else → Bg.
    (V1 \= Bg, V2 = Bg -> V = V1
    ; V1 = Bg, V2 \= Bg -> V = V2
    ; V = Bg).
ggl_op_(V1, V2, Bg, subtract, V) :- !,
% SUBTRACT: V1 non-bg AND V2 is Bg → V1; else → Bg.
    (V1 \= Bg, V2 = Bg -> V = V1 ; V = Bg).
ggl_op_(V1, V2, Bg, common, V) :- !,
% COMMON: V1 = V2 and both non-bg → V1; else → Bg.
    (V1 = V2, V1 \= Bg -> V = V1 ; V = Bg).
ggl_op_(V1, V2, Bg, differ, V) :- !,
% DIFFER: both non-bg and different → V1; else → Bg.
    (V1 \= Bg, V2 \= Bg, V1 \= V2 -> V = V1 ; V = Bg).
ggl_op_(V1, V2, Bg, unanimous, V) :- !,
% UNANIMOUS: V1 = V2 (any value) → V1; else → Bg.
    (V1 = V2 -> V = V1 ; V = Bg).

% ggl_pair_cells_/5: apply ggl_op_ to corresponding cells of two rows.
ggl_pair_cells_([], [], _, _, []).
ggl_pair_cells_([V1|T1], [V2|T2], Bg, Op, [V|Vs]) :-
    ggl_op_(V1, V2, Bg, Op, V),
    ggl_pair_cells_(T1, T2, Bg, Op, Vs).

% ggl_pair_/5: apply pairwise cell operation to two same-sized grids.
ggl_pair_([], [], _, _, []).
ggl_pair_([R1|T1], [R2|T2], Bg, Op, [NewRow|Rest]) :-
    ggl_pair_cells_(R1, R2, Bg, Op, NewRow),
    ggl_pair_(T1, T2, Bg, Op, Rest).

% ggl_count_/3: count occurrences of V in List.
ggl_count_(V, List, Count) :-
    findall(1, member(V, List), Ones),
    length(Ones, Count).

% ggl_unique_/2: collect unique elements of List (order may vary).
ggl_unique_([], []).
ggl_unique_([H|T], Result) :-
    (member(H, T) ->
        ggl_unique_(T, Result)
    ;
        ggl_unique_(T, Rest),
        Result = [H|Rest]
    ).

% ggl_max_pair_/2: find the Count-V pair with the highest Count.
ggl_max_pair_([Pair], Pair) :- !.
ggl_max_pair_([C1-V1|Rest], Best) :-
    ggl_max_pair_(Rest, RC-RV),
    (C1 > RC -> Best = C1-V1 ; Best = RC-RV).

% ggl_mode_/3: find the most frequent value in Vals if its count > Threshold.
% Fails if Vals is empty or no value exceeds the threshold.
ggl_mode_(Vals, Threshold, Mode) :-
    Vals \= [],
    ggl_unique_(Vals, Set),
    findall(Count-V, (member(V, Set), ggl_count_(V, Vals, Count)), Pairs),
    ggl_max_pair_(Pairs, BestCount-Mode),
    BestCount > Threshold.

% --- PUBLIC PREDICATES ---

% ggl_and(+Grid1, +Grid2, +BgColor, -Result)
% Cell-wise AND: where both grids have a non-BgColor cell, Result keeps Grid1's value.
% Where either cell is BgColor, Result has BgColor.
ggl_and(Grid1, Grid2, Bg, Result) :-
    ggl_pair_(Grid1, Grid2, Bg, and, Result).

% ggl_or(+Grid1, +Grid2, +BgColor, -Result)
% Cell-wise OR: Grid1's non-bg cells win; where Grid1 is bg, Grid2's value is used.
% Where both are bg, Result has BgColor.
ggl_or(Grid1, Grid2, Bg, Result) :-
    ggl_pair_(Grid1, Grid2, Bg, or, Result).

% ggl_xor(+Grid1, +Grid2, +BgColor, -Result)
% Cell-wise XOR: exactly one grid is non-bg → that value; both bg or both non-bg → BgColor.
ggl_xor(Grid1, Grid2, Bg, Result) :-
    ggl_pair_(Grid1, Grid2, Bg, xor, Result).

% ggl_not(+Grid, +BgColor, +FgColor, -Result)
% Logical NOT: BgColor cells become FgColor; non-BgColor cells become BgColor.
ggl_not(Grid, Bg, FgColor, Result) :-
% For each cell: bg → FgColor; non-bg → Bg.
    findall(NewRow,
        (member(Row, Grid),
         findall(V2, (member(V, Row), (V = Bg -> V2 = FgColor ; V2 = Bg)), NewRow)),
        Result).

% ggl_subtract(+Grid1, +Grid2, +BgColor, -Result)
% Set difference: cells where Grid1 is non-bg AND Grid2 is bg → Grid1's value; else bg.
ggl_subtract(Grid1, Grid2, Bg, Result) :-
    ggl_pair_(Grid1, Grid2, Bg, subtract, Result).

% ggl_common(+Grid1, +Grid2, +BgColor, -Result)
% Cells where both grids have the same non-BgColor value → that value; else bg.
ggl_common(Grid1, Grid2, Bg, Result) :-
    ggl_pair_(Grid1, Grid2, Bg, common, Result).

% ggl_differ(+Grid1, +Grid2, +BgColor, -Result)
% Cells where both grids are non-bg but have different values → Grid1's value; else bg.
ggl_differ(Grid1, Grid2, Bg, Result) :-
    ggl_pair_(Grid1, Grid2, Bg, differ, Result).

% ggl_any(+Grids, +BgColor, -Result)
% List-wise OR: at each position, the first non-bg value across the grid list wins.
% Equivalent to folding ggl_or left to right.
ggl_any([G], _, G) :- !.
ggl_any([G1|Rest], Bg, Result) :-
    ggl_any(Rest, Bg, RRest),
    ggl_pair_(G1, RRest, Bg, or, Result).

% ggl_all(+Grids, +BgColor, -Result)
% List-wise AND: at each position, non-bg value if ALL grids agree on the same non-bg.
% Equivalent to folding ggl_common left to right.
ggl_all([G], _, G) :- !.
ggl_all([G1|Rest], Bg, Result) :-
    ggl_all(Rest, Bg, RRest),
    ggl_pair_(G1, RRest, Bg, common, Result).

% ggl_majority(+Grids, +BgColor, -Result)
% At each position, the most frequent non-bg value if it appears more than N/2 times.
% If no value exceeds that threshold (tie or all bg), the cell is BgColor.
ggl_majority(Grids, Bg, Result) :-
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
              (ggl_mode_(Vals, Threshold, V) -> true ; V = Bg)),
             NewRow)),
        Result).

% ggl_unanimous(+Grids, +BgColor, -Result)
% At each position, all grids (including bg cells) must agree on the same value.
% If any two grids differ, the cell is BgColor.
ggl_unanimous([G], _, G) :- !.
ggl_unanimous([G1|Rest], Bg, Result) :-
    ggl_unanimous(Rest, Bg, RRest),
    ggl_pair_(G1, RRest, Bg, unanimous, Result).

% ggl_mask(+Grid, +MaskGrid, +MaskColor, +BgColor, -Result)
% Keep Grid's cell values where MaskGrid has MaskColor; all others become BgColor.
ggl_mask(Grid, MaskGrid, MaskColor, Bg, Result) :-
    ggl_mask_rows_(Grid, MaskGrid, MaskColor, Bg, Result).

% ggl_mask_rows_/5: apply mask row by row.
ggl_mask_rows_([], [], _, _, []).
ggl_mask_rows_([R1|T1], [R2|T2], MC, Bg, [NR|Rest]) :-
    ggl_mask_cells_(R1, R2, MC, Bg, NR),
    ggl_mask_rows_(T1, T2, MC, Bg, Rest).

% ggl_mask_cells_/5: apply mask cell by cell.
ggl_mask_cells_([], [], _, _, []).
ggl_mask_cells_([V1|T1], [V2|T2], MC, Bg, [V|Vs]) :-
% Keep Grid value where Mask = MaskColor; else replace with Bg.
    (V2 = MC -> V = V1 ; V = Bg),
    ggl_mask_cells_(T1, T2, MC, Bg, Vs).

% ggl_if(+CondGrid, +CondColor, +ThenGrid, +ElseGrid, -Result)
% Cell-wise conditional: where CondGrid = CondColor → ThenGrid value; else ElseGrid value.
ggl_if(Cond, CC, Then, Else, Result) :-
    ggl_if_rows_(Cond, Then, Else, CC, Result).

% ggl_if_rows_/5: apply conditional row by row.
ggl_if_rows_([], [], [], _, []).
ggl_if_rows_([RC|TC], [RT|TT], [RE|TE], CC, [NR|Rest]) :-
    ggl_if_cells_(RC, RT, RE, CC, NR),
    ggl_if_rows_(TC, TT, TE, CC, Rest).

% ggl_if_cells_/5: apply conditional cell by cell.
ggl_if_cells_([], [], [], _, []).
ggl_if_cells_([VC|TC], [VT|TT], [VE|TE], CC, [V|Vs]) :-
% Select ThenGrid value if Cond = CondColor; else ElseGrid value.
    (VC = CC -> V = VT ; V = VE),
    ggl_if_cells_(TC, TT, TE, CC, Vs).

% ggl_filter(+Grid, +Colors, +BgColor, -Result)
% Keep cells whose color is in the Colors list; replace all others with BgColor.
ggl_filter(Grid, Colors, Bg, Result) :-
% For each cell: if color in Colors keep it; else → Bg.
    findall(NewRow,
        (member(Row, Grid),
         findall(V2, (member(V, Row),
                      (member(V, Colors) -> V2 = V ; V2 = Bg)), NewRow)),
        Result).
