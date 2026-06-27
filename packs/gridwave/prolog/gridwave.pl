:- module(gridwave, [
    gwv_step/3,
    gwv_fill/3,
    gwv_fill_n/4,
    gwv_frontier/3,
    gwv_color_frontier/4,
    gwv_equidistant_front/3,
    gwv_color_expand/4,
    gwv_color_expand_n/5,
    gwv_shadow_right/4,
    gwv_shadow_down/4,
    gwv_shadow_left/4,
    gwv_shadow_up/4,
    gwv_contract/3,
    gwv_contract_n/4
]).
% gridwave.pl - Layer 229: Grid Wave Propagation (gwv_* prefix).
% Fourteen predicates for color wave expansion, contraction, frontier detection,
% and directional shadow casting on symbolic grids.
% gwv_step/fill/fill_n: multi-color wave expansion (BFS-style with conflict handling).
% gwv_frontier/color_frontier/equidistant_front: detect frontier cells.
% gwv_color_expand/color_expand_n: single-color expansion.
% gwv_shadow_right/down/left/up: directional shadow casting from non-bg cells.
% gwv_contract/contract_n: interior erosion (non-bg cells touching in-bounds bg contract).
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% No cross-pack dependencies.
:- use_module(library(lists), [nth0/3, member/2, append/2, reverse/2, list_to_set/2]).

% --- PRIVATE HELPERS ---

% gwv_dims_(+Grid, -H, -W): extract grid height and width.
gwv_dims_(Grid, H, W) :-
% Count rows for height.
    length(Grid, H),
% Extract first row to measure width.
    Grid = [Row|_], length(Row, W).

% gwv_heads_tails_(+Rows, -Heads, -Tails): split each row into its head and tail.
gwv_heads_tails_([], [], []).
gwv_heads_tails_([[H|T]|Rest], [H|Hs], [T|Ts]) :-
% Recurse over remaining rows.
    gwv_heads_tails_(Rest, Hs, Ts).

% gwv_transpose_(+Grid, -Transposed): transpose a rectangular grid.
gwv_transpose_([], []) :- !.
gwv_transpose_([[]|_], []) :- !.
gwv_transpose_(Grid, [Heads|Tails]) :-
% Split all rows into heads and tails.
    gwv_heads_tails_(Grid, Heads, RestRows),
% Transpose the tails recursively.
    gwv_transpose_(RestRows, Tails).

% gwv_shadow_row_(+Row, +BgColor, +ShadowColor, +Active, -ShadowRow):
% State-machine scan: once a non-bg cell is seen (Active=yes),
% subsequent bg cells become ShadowColor until the row ends.
gwv_shadow_row_([], _, _, _, []).
gwv_shadow_row_([V|Rest], Bg, Shad, Active, [V2|Rest2]) :-
% Non-bg cell: keep its value and activate shadow for cells to its right.
    (V \= Bg ->
        V2 = V,
        gwv_shadow_row_(Rest, Bg, Shad, yes, Rest2)
    ;
% Bg cell in shadow: replace with ShadowColor.
        (Active = yes -> V2 = Shad ; V2 = Bg),
        gwv_shadow_row_(Rest, Bg, Shad, Active, Rest2)
    ).

% gwv_has_bg_nbr_(+Grid, +R, +C, +H1, +W1, +BgColor):
% Succeeds if cell (R,C) has at least one in-bounds 4-connected neighbor equal to BgColor.
gwv_has_bg_nbr_(Grid, R, C, H1, W1, BgColor) :-
% Enumerate four cardinal directions.
    member(DR-DC, [(-1)-0, 1-0, 0-(-1), 0-1]),
    NR is R + DR, NC is C + DC,
% Accept only in-bounds neighbors (OOB does NOT count as bg for contract).
    NR >= 0, NR =< H1, NC >= 0, NC =< W1,
% Check that the neighbor cell holds BgColor.
    nth0(NR, Grid, NRow), nth0(NC, NRow, BgColor).

% --- PUBLIC PREDICATES ---

% gwv_step(+Grid, +BgColor, -Stepped)
% One wave-expansion step: each BgColor cell that borders exactly one non-bg
% color takes that color. Cells adjacent to two or more different non-bg colors
% remain BgColor (conflict). All non-bg cells are unchanged.
gwv_step(Grid, BgColor, Stepped) :-
% Compute grid bounds.
    gwv_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Build each output row.
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, GRow),
% Build each cell in the row.
         findall(V2,
             (between(0, W1, C),
              nth0(C, GRow, V),
% Non-bg cell: unchanged.
              (V \= BgColor ->
                  V2 = V
              ;
% Collect all non-bg neighbor colors.
                  findall(NV,
                      (member(DR-DC, [(-1)-0, 1-0, 0-(-1), 0-1]),
                       NR is R + DR, NC is C + DC,
                       NR >= 0, NR =< H1, NC >= 0, NC =< W1,
                       nth0(NR, Grid, NRow), nth0(NC, NRow, NV),
                       NV \= BgColor),
                      Nbrs),
% No neighbors: stay bg. One unique color: take it. Multiple colors: conflict = stay bg.
                  (   Nbrs = [] -> V2 = BgColor
                  ;   list_to_set(Nbrs, [Single]) -> V2 = Single
                  ;   V2 = BgColor
                  ))),
             NewRow)),
        Stepped).

% gwv_fill(+Grid, +BgColor, -Filled)
% Repeatedly apply gwv_step until no bg cell changes (fixed point).
gwv_fill(Grid, BgColor, Filled) :-
% Apply one expansion step.
    gwv_step(Grid, BgColor, Stepped),
% If nothing changed, we have reached the fixed point.
    (Stepped = Grid ->
        Filled = Grid
    ;
% Otherwise continue expanding.
        gwv_fill(Stepped, BgColor, Filled)
    ).

% gwv_fill_n(+Grid, +N, +BgColor, -Result)
% Apply exactly N wave-expansion steps (gwv_step).
gwv_fill_n(Grid, 0, _, Grid) :- !.
gwv_fill_n(Grid, N, BgColor, Result) :-
% Apply one step.
    gwv_step(Grid, BgColor, Stepped),
% Decrement counter and recurse.
    N1 is N - 1,
    gwv_fill_n(Stepped, N1, BgColor, Result).

% gwv_frontier(+Grid, +BgColor, -Cells)
% Cells is the list of R-C positions of BgColor cells that border at least
% one non-BgColor cell (4-connected). Ordered by row then column.
gwv_frontier(Grid, BgColor, Cells) :-
% Compute grid bounds.
    gwv_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect bg cells that have at least one non-bg neighbor.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         nth0(R, Grid, GRow), nth0(C, GRow, BgColor),
         (   member(DR-DC, [(-1)-0, 1-0, 0-(-1), 0-1]),
             NR is R + DR, NC is C + DC,
             NR >= 0, NR =< H1, NC >= 0, NC =< W1,
             nth0(NR, Grid, NRow), nth0(NC, NRow, NV), NV \= BgColor
         -> true ; fail)),
        Cells).

% gwv_color_frontier(+Grid, +BgColor, +Color, -Cells)
% Cells is the list of R-C positions of BgColor cells that border at least
% one cell holding Color specifically (4-connected).
gwv_color_frontier(Grid, BgColor, Color, Cells) :-
% Compute grid bounds.
    gwv_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect bg cells adjacent to Color.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         nth0(R, Grid, GRow), nth0(C, GRow, BgColor),
         (   member(DR-DC, [(-1)-0, 1-0, 0-(-1), 0-1]),
             NR is R + DR, NC is C + DC,
             NR >= 0, NR =< H1, NC >= 0, NC =< W1,
             nth0(NR, Grid, NRow), nth0(NC, NRow, Color)
         -> true ; fail)),
        Cells).

% gwv_equidistant_front(+Grid, +BgColor, -Cells)
% Cells is the list of R-C positions of BgColor cells that border two or more
% different non-BgColor colors (4-connected). These are conflict / boundary cells.
gwv_equidistant_front(Grid, BgColor, Cells) :-
% Compute grid bounds.
    gwv_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect bg cells touching at least two distinct non-bg colors.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         nth0(R, Grid, GRow), nth0(C, GRow, BgColor),
% Gather all distinct non-bg neighbor colors.
         findall(NV,
             (member(DR-DC, [(-1)-0, 1-0, 0-(-1), 0-1]),
              NR is R + DR, NC is C + DC,
              NR >= 0, NR =< H1, NC >= 0, NC =< W1,
              nth0(NR, Grid, NRow), nth0(NC, NRow, NV), NV \= BgColor),
             Nbrs),
         list_to_set(Nbrs, NbrSet),
% At least two different non-bg colors present.
         NbrSet = [_,_|_]),
        Cells).

% gwv_color_expand(+Grid, +Color, +BgColor, -Expanded)
% One expansion step for a single Color: each BgColor cell adjacent to Color
% becomes Color. All other cells (including other non-bg colors) are unchanged.
gwv_color_expand(Grid, Color, BgColor, Expanded) :-
% Compute grid bounds.
    gwv_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Build each output row.
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, GRow),
% Build each cell in the row.
         findall(V2,
             (between(0, W1, C),
              nth0(C, GRow, V),
% Non-bg cell: unchanged.
              (V \= BgColor ->
                  V2 = V
              ;
% Bg cell adjacent to Color: expand.
                  (   member(DR-DC, [(-1)-0, 1-0, 0-(-1), 0-1]),
                      NR is R + DR, NC is C + DC,
                      NR >= 0, NR =< H1, NC >= 0, NC =< W1,
                      nth0(NR, Grid, NRow), nth0(NC, NRow, Color)
                  ->  V2 = Color
                  ;   V2 = BgColor
                  ))),
             NewRow)),
        Expanded).

% gwv_color_expand_n(+Grid, +Color, +N, +BgColor, -Result)
% Apply gwv_color_expand exactly N times for the given Color.
gwv_color_expand_n(Grid, _, 0, _, Grid) :- !.
gwv_color_expand_n(Grid, Color, N, BgColor, Result) :-
% Apply one single-color expansion step.
    gwv_color_expand(Grid, Color, BgColor, Expanded),
% Decrement counter and recurse.
    N1 is N - 1,
    gwv_color_expand_n(Expanded, Color, N1, BgColor, Result).

% gwv_shadow_right(+Grid, +BgColor, +ShadowColor, -Shadow)
% Shadow: each bg cell to the right of any non-bg cell (with no non-bg cell
% between them) becomes ShadowColor. Non-bg cells keep their color.
% The shadow continues across subsequent non-bg cells (each re-triggers shadow).
gwv_shadow_right(Grid, BgColor, ShadowColor, Shadow) :-
% Get grid height.
    gwv_dims_(Grid, H, _),
    H1 is H - 1,
% Apply row-wise shadow scan from left to right.
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, GRow),
         gwv_shadow_row_(GRow, BgColor, ShadowColor, no, NewRow)),
        Shadow).

% gwv_shadow_left(+Grid, +BgColor, +ShadowColor, -Shadow)
% Like gwv_shadow_right but cast leftward: bg cells to the left of any non-bg cell
% become ShadowColor.
gwv_shadow_left(Grid, BgColor, ShadowColor, Shadow) :-
% Get grid height.
    gwv_dims_(Grid, H, _),
    H1 is H - 1,
% Reverse each row, shadow rightward, then reverse back.
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, GRow),
         reverse(GRow, RevRow),
         gwv_shadow_row_(RevRow, BgColor, ShadowColor, no, RevShad),
         reverse(RevShad, NewRow)),
        Shadow).

% gwv_shadow_down(+Grid, +BgColor, +ShadowColor, -Shadow)
% Cast shadow downward: bg cells below any non-bg cell become ShadowColor.
gwv_shadow_down(Grid, BgColor, ShadowColor, Shadow) :-
% Transpose rows to columns, shadow rightward (= downward in original), transpose back.
    gwv_transpose_(Grid, TGrid),
    gwv_shadow_right(TGrid, BgColor, ShadowColor, TShadow),
    gwv_transpose_(TShadow, Shadow).

% gwv_shadow_up(+Grid, +BgColor, +ShadowColor, -Shadow)
% Cast shadow upward: bg cells above any non-bg cell become ShadowColor.
gwv_shadow_up(Grid, BgColor, ShadowColor, Shadow) :-
% Transpose rows to columns, shadow leftward (= upward in original), transpose back.
    gwv_transpose_(Grid, TGrid),
    gwv_shadow_left(TGrid, BgColor, ShadowColor, TShadow),
    gwv_transpose_(TShadow, Shadow).

% gwv_contract(+Grid, +BgColor, -Contracted)
% One contraction step: each non-BgColor cell that has at least one in-bounds
% 4-connected BgColor neighbor becomes BgColor. Out-of-bounds neighbors do NOT
% count as bg (distinct from morphological erosion). Isolated non-bg cells with
% no in-bounds bg neighbors are unchanged.
gwv_contract(Grid, BgColor, Contracted) :-
% Compute grid bounds.
    gwv_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Build each output row.
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, GRow),
% Build each cell in the row.
         findall(V2,
             (between(0, W1, C),
              nth0(C, GRow, V),
% Bg cell: stays bg.
              (V = BgColor ->
                  V2 = BgColor
% Non-bg cell with in-bounds bg neighbor: contract to bg.
              ;   (gwv_has_bg_nbr_(Grid, R, C, H1, W1, BgColor) ->
                      V2 = BgColor
% Non-bg cell with no in-bounds bg neighbor: unchanged.
                  ;   V2 = V
                  ))),
             NewRow)),
        Contracted).

% gwv_contract_n(+Grid, +N, +BgColor, -Result)
% Apply gwv_contract exactly N times.
gwv_contract_n(Grid, 0, _, Grid) :- !.
gwv_contract_n(Grid, N, BgColor, Result) :-
% Apply one contraction step.
    gwv_contract(Grid, BgColor, Contracted),
% Decrement counter and recurse.
    N1 is N - 1,
    gwv_contract_n(Contracted, N1, BgColor, Result).
