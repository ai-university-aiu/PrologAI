:- module(grid_wave, [
    grid_wave_step/3,
    grid_wave_fill/3,
    grid_wave_fill_n/4,
    grid_wave_frontier/3,
    grid_wave_color_frontier/4,
    grid_wave_equidistant_front/3,
    grid_wave_color_expand/4,
    grid_wave_color_expand_n/5,
    grid_wave_shadow_right/4,
    grid_wave_shadow_down/4,
    grid_wave_shadow_left/4,
    grid_wave_shadow_up/4,
    grid_wave_contract/3,
    grid_wave_contract_n/4
]).
% gridwave.pl - Layer 229: Grid Wave Propagation (gwv_* prefix).
% Fourteen predicates for color wave expansion, contraction, frontier detection,
% and directional shadow casting on symbolic grids.
% grid_wave_step/fill/fill_n: multi-color wave expansion (BFS-style with conflict handling).
% grid_wave_frontier/color_frontier/equidistant_front: detect frontier cells.
% grid_wave_color_expand/color_expand_n: single-color expansion.
% grid_wave_shadow_right/down/left/up: directional shadow casting from non-bg cells.
% grid_wave_contract/contract_n: interior erosion (non-bg cells touching in-bounds bg contract).
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% No cross-pack dependencies.
:- use_module(library(lists), [nth0/3, member/2, append/2, reverse/2, list_to_set/2]).

% --- PRIVATE HELPERS ---

% grid_wave_dims_(+Grid, -H, -W): extract grid height and width.
grid_wave_dims_(Grid, H, W) :-
% Count rows for height.
    length(Grid, H),
% Extract first row to measure width.
    Grid = [Row|_], length(Row, W).

% grid_wave_heads_tails_(+Rows, -Heads, -Tails): split each row into its head and tail.
grid_wave_heads_tails_([], [], []).
grid_wave_heads_tails_([[H|T]|Rest], [H|Hs], [T|Ts]) :-
% Recurse over remaining rows.
    grid_wave_heads_tails_(Rest, Hs, Ts).

% grid_wave_transpose_(+Grid, -Transposed): transpose a rectangular grid.
grid_wave_transpose_([], []) :- !.
grid_wave_transpose_([[]|_], []) :- !.
grid_wave_transpose_(Grid, [Heads|Tails]) :-
% Split all rows into heads and tails.
    grid_wave_heads_tails_(Grid, Heads, RestRows),
% Transpose the tails recursively.
    grid_wave_transpose_(RestRows, Tails).

% grid_wave_shadow_row_(+Row, +BgColor, +ShadowColor, +Active, -ShadowRow):
% State-machine scan: once a non-bg cell is seen (Active=yes),
% subsequent bg cells become ShadowColor until the row ends.
grid_wave_shadow_row_([], _, _, _, []).
grid_wave_shadow_row_([V|Rest], Bg, Shad, Active, [V2|Rest2]) :-
% Non-bg cell: keep its value and activate shadow for cells to its right.
    (V \= Bg ->
        V2 = V,
        grid_wave_shadow_row_(Rest, Bg, Shad, yes, Rest2)
    ;
% Bg cell in shadow: replace with ShadowColor.
        (Active = yes -> V2 = Shad ; V2 = Bg),
        grid_wave_shadow_row_(Rest, Bg, Shad, Active, Rest2)
    ).

% grid_wave_has_bg_nbr_(+Grid, +R, +C, +H1, +W1, +BgColor):
% Succeeds if cell (R,C) has at least one in-bounds 4-connected neighbor equal to BgColor.
grid_wave_has_bg_nbr_(Grid, R, C, H1, W1, BgColor) :-
% Enumerate four cardinal directions.
    member(DR-DC, [(-1)-0, 1-0, 0-(-1), 0-1]),
    NR is R + DR, NC is C + DC,
% Accept only in-bounds neighbors (OOB does NOT count as bg for contract).
    NR >= 0, NR =< H1, NC >= 0, NC =< W1,
% Check that the neighbor cell holds BgColor.
    nth0(NR, Grid, NRow), nth0(NC, NRow, BgColor).

% --- PUBLIC PREDICATES ---

% grid_wave_step(+Grid, +BgColor, -Stepped)
% One wave-expansion step: each BgColor cell that borders exactly one non-bg
% color takes that color. Cells adjacent to two or more different non-bg colors
% remain BgColor (conflict). All non-bg cells are unchanged.
grid_wave_step(Grid, BgColor, Stepped) :-
% Compute grid bounds.
    grid_wave_dims_(Grid, H, W),
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

% grid_wave_fill(+Grid, +BgColor, -Filled)
% Repeatedly apply grid_wave_step until no bg cell changes (fixed point).
grid_wave_fill(Grid, BgColor, Filled) :-
% Apply one expansion step.
    grid_wave_step(Grid, BgColor, Stepped),
% If nothing changed, we have reached the fixed point.
    (Stepped = Grid ->
        Filled = Grid
    ;
% Otherwise continue expanding.
        grid_wave_fill(Stepped, BgColor, Filled)
    ).

% grid_wave_fill_n(+Grid, +N, +BgColor, -Result)
% Apply exactly N wave-expansion steps (grid_wave_step).
grid_wave_fill_n(Grid, 0, _, Grid) :- !.
grid_wave_fill_n(Grid, N, BgColor, Result) :-
% Apply one step.
    grid_wave_step(Grid, BgColor, Stepped),
% Decrement counter and recurse.
    N1 is N - 1,
    grid_wave_fill_n(Stepped, N1, BgColor, Result).

% grid_wave_frontier(+Grid, +BgColor, -Cells)
% Cells is the list of R-C positions of BgColor cells that border at least
% one non-BgColor cell (4-connected). Ordered by row then column.
grid_wave_frontier(Grid, BgColor, Cells) :-
% Compute grid bounds.
    grid_wave_dims_(Grid, H, W),
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

% grid_wave_color_frontier(+Grid, +BgColor, +Color, -Cells)
% Cells is the list of R-C positions of BgColor cells that border at least
% one cell holding Color specifically (4-connected).
grid_wave_color_frontier(Grid, BgColor, Color, Cells) :-
% Compute grid bounds.
    grid_wave_dims_(Grid, H, W),
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

% grid_wave_equidistant_front(+Grid, +BgColor, -Cells)
% Cells is the list of R-C positions of BgColor cells that border two or more
% different non-BgColor colors (4-connected). These are conflict / boundary cells.
grid_wave_equidistant_front(Grid, BgColor, Cells) :-
% Compute grid bounds.
    grid_wave_dims_(Grid, H, W),
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

% grid_wave_color_expand(+Grid, +Color, +BgColor, -Expanded)
% One expansion step for a single Color: each BgColor cell adjacent to Color
% becomes Color. All other cells (including other non-bg colors) are unchanged.
grid_wave_color_expand(Grid, Color, BgColor, Expanded) :-
% Compute grid bounds.
    grid_wave_dims_(Grid, H, W),
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

% grid_wave_color_expand_n(+Grid, +Color, +N, +BgColor, -Result)
% Apply grid_wave_color_expand exactly N times for the given Color.
grid_wave_color_expand_n(Grid, _, 0, _, Grid) :- !.
grid_wave_color_expand_n(Grid, Color, N, BgColor, Result) :-
% Apply one single-color expansion step.
    grid_wave_color_expand(Grid, Color, BgColor, Expanded),
% Decrement counter and recurse.
    N1 is N - 1,
    grid_wave_color_expand_n(Expanded, Color, N1, BgColor, Result).

% grid_wave_shadow_right(+Grid, +BgColor, +ShadowColor, -Shadow)
% Shadow: each bg cell to the right of any non-bg cell (with no non-bg cell
% between them) becomes ShadowColor. Non-bg cells keep their color.
% The shadow continues across subsequent non-bg cells (each re-triggers shadow).
grid_wave_shadow_right(Grid, BgColor, ShadowColor, Shadow) :-
% Get grid height.
    grid_wave_dims_(Grid, H, _),
    H1 is H - 1,
% Apply row-wise shadow scan from left to right.
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, GRow),
         grid_wave_shadow_row_(GRow, BgColor, ShadowColor, no, NewRow)),
        Shadow).

% grid_wave_shadow_left(+Grid, +BgColor, +ShadowColor, -Shadow)
% Like grid_wave_shadow_right but cast leftward: bg cells to the left of any non-bg cell
% become ShadowColor.
grid_wave_shadow_left(Grid, BgColor, ShadowColor, Shadow) :-
% Get grid height.
    grid_wave_dims_(Grid, H, _),
    H1 is H - 1,
% Reverse each row, shadow rightward, then reverse back.
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, GRow),
         reverse(GRow, RevRow),
         grid_wave_shadow_row_(RevRow, BgColor, ShadowColor, no, RevShad),
         reverse(RevShad, NewRow)),
        Shadow).

% grid_wave_shadow_down(+Grid, +BgColor, +ShadowColor, -Shadow)
% Cast shadow downward: bg cells below any non-bg cell become ShadowColor.
grid_wave_shadow_down(Grid, BgColor, ShadowColor, Shadow) :-
% Transpose rows to columns, shadow rightward (= downward in original), transpose back.
    grid_wave_transpose_(Grid, TGrid),
    grid_wave_shadow_right(TGrid, BgColor, ShadowColor, TShadow),
    grid_wave_transpose_(TShadow, Shadow).

% grid_wave_shadow_up(+Grid, +BgColor, +ShadowColor, -Shadow)
% Cast shadow upward: bg cells above any non-bg cell become ShadowColor.
grid_wave_shadow_up(Grid, BgColor, ShadowColor, Shadow) :-
% Transpose rows to columns, shadow leftward (= upward in original), transpose back.
    grid_wave_transpose_(Grid, TGrid),
    grid_wave_shadow_left(TGrid, BgColor, ShadowColor, TShadow),
    grid_wave_transpose_(TShadow, Shadow).

% grid_wave_contract(+Grid, +BgColor, -Contracted)
% One contraction step: each non-BgColor cell that has at least one in-bounds
% 4-connected BgColor neighbor becomes BgColor. Out-of-bounds neighbors do NOT
% count as bg (distinct from morphological erosion). Isolated non-bg cells with
% no in-bounds bg neighbors are unchanged.
grid_wave_contract(Grid, BgColor, Contracted) :-
% Compute grid bounds.
    grid_wave_dims_(Grid, H, W),
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
              ;   (grid_wave_has_bg_nbr_(Grid, R, C, H1, W1, BgColor) ->
                      V2 = BgColor
% Non-bg cell with no in-bounds bg neighbor: unchanged.
                  ;   V2 = V
                  ))),
             NewRow)),
        Contracted).

% grid_wave_contract_n(+Grid, +N, +BgColor, -Result)
% Apply grid_wave_contract exactly N times.
grid_wave_contract_n(Grid, 0, _, Grid) :- !.
grid_wave_contract_n(Grid, N, BgColor, Result) :-
% Apply one contraction step.
    grid_wave_contract(Grid, BgColor, Contracted),
% Decrement counter and recurse.
    N1 is N - 1,
    grid_wave_contract_n(Contracted, N1, BgColor, Result).
