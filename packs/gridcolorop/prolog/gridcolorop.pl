% Module declaration with all fourteen public predicates.
:- module(gridcolorop, [
% List of cc(Color,Count) pairs sorted by count descending.
    gco_color_counts/3,
% List of distinct non-bg colors sorted by count descending.
    gco_distinct_colors/3,
% The Nth most frequent non-bg color (0-indexed).
    gco_nth_color/4,
% Count of distinct non-bg colors in Grid.
    gco_count_distinct/3,
% Swap Color1 and Color2 throughout Grid.
    gco_swap/5,
% Replace all cells of OldColor with NewColor.
    gco_replace/5,
% Apply a list of OldColor-NewColor substitution pairs.
    gco_apply_map/4,
% Keep cells of Color; replace all others with Bg.
    gco_keep_only/4,
% Replace cells of Color with Bg; keep all other cells.
    gco_remove_color/4,
% Cycle each color N steps through a Palette list.
    gco_cycle/5,
% Replace each non-bg cell with its color's 0-indexed frequency rank.
    gco_rank_grid/3,
% Replace the Kth most frequent color with Kth palette color.
    gco_apply_palette/4,
% Most and least frequent non-bg colors.
    gco_most_least/4,
% Binary invert: non-bg cells become Bg; Bg cells become FgColor.
    gco_invert/4
]).
% gridcolorop.pl - Layer 240: Grid Color Operations (gco_* prefix).
% Fourteen predicates for querying, swapping, replacing, masking, cycling,
% ranking, palette application, and inverting colors in symbolic grids.
% No cross-pack dependencies.
:- use_module(library(lists), [member/2]).

% --- PRIVATE HELPERS ---

% gco_cell_colors_/3: collect all non-bg cell values in scan order.
gco_cell_colors_(Grid, Bg, Colors) :-
    length(Grid, H),
    (H > 0 ->
        Grid = [Row0|_], length(Row0, W),
        H1 is H - 1, W1 is W - 1,
        findall(V,
            (between(0, H1, R), nth0(R, Grid, Row),
             between(0, W1, C), nth0(C, Row, V), V \= Bg),
            Colors)
    ;
        Colors = []
    ).

% gco_count_val_/3: count occurrences of Val in list.
gco_count_val_([], _, 0).
gco_count_val_([H|T], Val, N) :-
    gco_count_val_(T, Val, N0),
    (H = Val -> N is N0 + 1 ; N = N0).

% gco_sort_by_count_desc_/2: sort cc(Color,Count) pairs by count descending.
% Uses Neg is -N to evaluate integer negation (not compound -(N) term).
gco_sort_by_count_desc_(Pairs, Sorted) :-
% Evaluate -N as integer so msort produces descending numeric order.
    findall(neg(Neg, cc(V,N)),
        (member(cc(V,N), Pairs), Neg is -N),
        Keyed),
    msort(Keyed, KeyedSorted),
    findall(cc(V,N), member(neg(_,cc(V,N)), KeyedSorted), Sorted).

% gco_nth_in_/3: 0-indexed element of a list.
gco_nth_in_(N, List, Elem) :- nth0(N, List, Elem).

% gco_grid_dims_/3: (H, W) of a non-empty grid.
gco_grid_dims_(Grid, H, W) :-
    length(Grid, H), Grid = [Row0|_], length(Row0, W).

% --- PUBLIC PREDICATES ---

% gco_color_counts(+Grid, +Bg, -Counts)
% Counts is a list of cc(Color,Count) pairs, sorted by count descending.
% Only non-bg colors are included.
gco_color_counts(Grid, Bg, Counts) :-
    gco_cell_colors_(Grid, Bg, AllColors),
    list_to_set(AllColors, Distinct),
    findall(cc(V, N),
        (member(V, Distinct), gco_count_val_(AllColors, V, N)),
        Pairs),
    gco_sort_by_count_desc_(Pairs, Counts).

% gco_distinct_colors(+Grid, +Bg, -Colors)
% Colors is the list of distinct non-bg colors sorted by count descending.
gco_distinct_colors(Grid, Bg, Colors) :-
    gco_color_counts(Grid, Bg, Counts),
    findall(V, member(cc(V, _), Counts), Colors).

% gco_nth_color(+Grid, +Bg, +N, -Color)
% Color is the Nth most frequent non-bg color (0-indexed). Fails if N >= count.
gco_nth_color(Grid, Bg, N, Color) :-
    gco_distinct_colors(Grid, Bg, Colors),
    gco_nth_in_(N, Colors, Color).

% gco_count_distinct(+Grid, +Bg, -Count)
% Count is the number of distinct non-bg colors.
gco_count_distinct(Grid, Bg, Count) :-
    gco_distinct_colors(Grid, Bg, Colors),
    length(Colors, Count).

% gco_swap(+Grid, +Color1, +Color2, +Bg, -Result)
% Swap Color1 and Color2 throughout Grid. All other cells are unchanged.
gco_swap(Grid, Color1, Color2, _Bg, Result) :-
    gco_grid_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R), nth0(R, Grid, OldRow),
         findall(NewV,
             (between(0, W1, C), nth0(C, OldRow, V),
              (V = Color1 -> NewV = Color2
              ;V = Color2 -> NewV = Color1
              ;NewV = V)),
             NewRow)),
        Result).

% gco_replace(+Grid, +OldColor, +NewColor, +Bg, -Result)
% Replace every OldColor cell with NewColor. Other cells unchanged.
gco_replace(Grid, OldColor, NewColor, _Bg, Result) :-
    gco_grid_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R), nth0(R, Grid, OldRow),
         findall(NewV,
             (between(0, W1, C), nth0(C, OldRow, V),
              (V = OldColor -> NewV = NewColor ; NewV = V)),
             NewRow)),
        Result).

% gco_apply_map(+Grid, +Map, +Bg, -Result)
% Apply a list of OldColor-NewColor substitutions. Map = [old1-new1, ...].
% Cells not appearing as a key in Map are unchanged.
gco_apply_map(Grid, Map, _Bg, Result) :-
    gco_grid_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R), nth0(R, Grid, OldRow),
         findall(NewV,
             (between(0, W1, C), nth0(C, OldRow, V),
              (member(V-MV, Map) -> NewV = MV ; NewV = V)),
             NewRow)),
        Result).

% gco_keep_only(+Grid, +Color, +Bg, -Result)
% Keep cells matching Color; replace all other cells with Bg.
gco_keep_only(Grid, Color, Bg, Result) :-
    gco_grid_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R), nth0(R, Grid, OldRow),
         findall(NewV,
             (between(0, W1, C), nth0(C, OldRow, V),
              (V = Color -> NewV = Color ; NewV = Bg)),
             NewRow)),
        Result).

% gco_remove_color(+Grid, +Color, +Bg, -Result)
% Replace cells matching Color with Bg; keep all other cells unchanged.
gco_remove_color(Grid, Color, Bg, Result) :-
    gco_grid_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R), nth0(R, Grid, OldRow),
         findall(NewV,
             (between(0, W1, C), nth0(C, OldRow, V),
              (V = Color -> NewV = Bg ; NewV = V)),
             NewRow)),
        Result).

% gco_cycle(+Grid, +Palette, +N, +Bg, -Result)
% For each cell whose color appears in Palette, replace it with the
% color N positions forward (mod |Palette|, wrapping). Negative N cycles back.
% Colors not in Palette are unchanged.
gco_cycle(Grid, Palette, N, _Bg, Result) :-
    length(Palette, PLen),
    gco_grid_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R), nth0(R, Grid, OldRow),
         findall(NewV,
             (between(0, W1, C), nth0(C, OldRow, V),
              (nth0(Idx, Palette, V) ->
                  NewIdx is ((Idx + N) mod PLen + PLen) mod PLen,
                  nth0(NewIdx, Palette, NewV)
              ;
                  NewV = V
              )),
             NewRow)),
        Result).

% gco_rank_grid(+Grid, +Bg, -Result)
% Replace each non-bg cell with its color's 0-indexed frequency rank
% (integer: 0 = most frequent). Bg cells remain Bg.
gco_rank_grid(Grid, Bg, Result) :-
    gco_distinct_colors(Grid, Bg, ByFreq),
    gco_grid_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R), nth0(R, Grid, OldRow),
         findall(NewV,
             (between(0, W1, C), nth0(C, OldRow, V),
              (V = Bg ->
                  NewV = Bg
              ;
                  (nth0(Rank, ByFreq, V) -> NewV = Rank ; NewV = V)
              )),
             NewRow)),
        Result).

% gco_apply_palette(+Grid, +Bg, +Palette, -Result)
% Replace the Kth most frequent non-bg color with the Kth entry in Palette.
% Colors beyond |Palette| length are unchanged. Bg is unchanged.
gco_apply_palette(Grid, Bg, Palette, Result) :-
    gco_distinct_colors(Grid, Bg, ByFreq),
    findall(Old-New,
        (nth0(K, Palette, New), nth0(K, ByFreq, Old)),
        ReplaceMap),
    gco_apply_map(Grid, ReplaceMap, Bg, Result).

% gco_most_least(+Grid, +Bg, -Most, -Least)
% Most is the most frequent non-bg color; Least is the least frequent.
% Fails if Grid has no non-bg cells.
gco_most_least(Grid, Bg, Most, Least) :-
    gco_color_counts(Grid, Bg, Counts),
    Counts \= [],
    Counts = [cc(Most,_)|_],
    last(Counts, cc(Least,_)).

% gco_invert(+Grid, +Bg, +FgColor, -Result)
% Binary invert: non-bg cells become Bg; Bg cells become FgColor.
% Useful for creating binary masks or negative images.
gco_invert(Grid, Bg, FgColor, Result) :-
    gco_grid_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R), nth0(R, Grid, OldRow),
         findall(NewV,
             (between(0, W1, C), nth0(C, OldRow, V),
              (V = Bg -> NewV = FgColor ; NewV = Bg)),
             NewRow)),
        Result).
