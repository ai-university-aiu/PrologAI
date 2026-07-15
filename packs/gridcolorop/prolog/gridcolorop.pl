% Module declaration with all fourteen public predicates.
:- module(gridcolorop, [
% List of cc(Color,Count) pairs sorted by count descending.
    gridcolorop_color_counts/3,
% List of distinct non-bg colors sorted by count descending.
    gridcolorop_distinct_colors/3,
% The Nth most frequent non-bg color (0-indexed).
    gridcolorop_nth_color/4,
% Count of distinct non-bg colors in Grid.
    gridcolorop_count_distinct/3,
% Swap Color1 and Color2 throughout Grid.
    gridcolorop_swap/5,
% Replace all cells of OldColor with NewColor.
    gridcolorop_replace/5,
% Apply a list of OldColor-NewColor substitution pairs.
    gridcolorop_apply_map/4,
% Keep cells of Color; replace all others with Bg.
    gridcolorop_keep_only/4,
% Replace cells of Color with Bg; keep all other cells.
    gridcolorop_remove_color/4,
% Cycle each color N steps through a Palette list.
    gridcolorop_cycle/5,
% Replace each non-bg cell with its color's 0-indexed frequency rank.
    gridcolorop_rank_grid/3,
% Replace the Kth most frequent color with Kth palette color.
    gridcolorop_apply_palette/4,
% Most and least frequent non-bg colors.
    gridcolorop_most_least/4,
% Binary invert: non-bg cells become Bg; Bg cells become FgColor.
    gridcolorop_invert/4
]).
% gridcolorop.pl - Layer 240: Grid Color Operations (gco_* prefix).
% Fourteen predicates for querying, swapping, replacing, masking, cycling,
% ranking, palette application, and inverting colors in symbolic grids.
% No cross-pack dependencies.
:- use_module(library(lists), [member/2]).

% --- PRIVATE HELPERS ---

% gridcolorop_cell_colors_/3: collect all non-bg cell values in scan order.
gridcolorop_cell_colors_(Grid, Bg, Colors) :-
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

% gridcolorop_count_val_/3: count occurrences of Val in list.
gridcolorop_count_val_([], _, 0).
gridcolorop_count_val_([H|T], Val, N) :-
    gridcolorop_count_val_(T, Val, N0),
    (H = Val -> N is N0 + 1 ; N = N0).

% gridcolorop_sort_by_count_desc_/2: sort cc(Color,Count) pairs by count descending.
% Uses Neg is -N to evaluate integer negation (not compound -(N) term).
gridcolorop_sort_by_count_desc_(Pairs, Sorted) :-
% Evaluate -N as integer so msort produces descending numeric order.
    findall(neg(Neg, cc(V,N)),
        (member(cc(V,N), Pairs), Neg is -N),
        Keyed),
    msort(Keyed, KeyedSorted),
    findall(cc(V,N), member(neg(_,cc(V,N)), KeyedSorted), Sorted).

% gridcolorop_nth_in_/3: 0-indexed element of a list.
gridcolorop_nth_in_(N, List, Elem) :- nth0(N, List, Elem).

% gridcolorop_grid_dims_/3: (H, W) of a non-empty grid.
gridcolorop_grid_dims_(Grid, H, W) :-
    length(Grid, H), Grid = [Row0|_], length(Row0, W).

% --- PUBLIC PREDICATES ---

% gridcolorop_color_counts(+Grid, +Bg, -Counts)
% Counts is a list of cc(Color,Count) pairs, sorted by count descending.
% Only non-bg colors are included.
gridcolorop_color_counts(Grid, Bg, Counts) :-
    gridcolorop_cell_colors_(Grid, Bg, AllColors),
    list_to_set(AllColors, Distinct),
    findall(cc(V, N),
        (member(V, Distinct), gridcolorop_count_val_(AllColors, V, N)),
        Pairs),
    gridcolorop_sort_by_count_desc_(Pairs, Counts).

% gridcolorop_distinct_colors(+Grid, +Bg, -Colors)
% Colors is the list of distinct non-bg colors sorted by count descending.
gridcolorop_distinct_colors(Grid, Bg, Colors) :-
    gridcolorop_color_counts(Grid, Bg, Counts),
    findall(V, member(cc(V, _), Counts), Colors).

% gridcolorop_nth_color(+Grid, +Bg, +N, -Color)
% Color is the Nth most frequent non-bg color (0-indexed). Fails if N >= count.
gridcolorop_nth_color(Grid, Bg, N, Color) :-
    gridcolorop_distinct_colors(Grid, Bg, Colors),
    gridcolorop_nth_in_(N, Colors, Color).

% gridcolorop_count_distinct(+Grid, +Bg, -Count)
% Count is the number of distinct non-bg colors.
gridcolorop_count_distinct(Grid, Bg, Count) :-
    gridcolorop_distinct_colors(Grid, Bg, Colors),
    length(Colors, Count).

% gridcolorop_swap(+Grid, +Color1, +Color2, +Bg, -Result)
% Swap Color1 and Color2 throughout Grid. All other cells are unchanged.
gridcolorop_swap(Grid, Color1, Color2, _Bg, Result) :-
    gridcolorop_grid_dims_(Grid, H, W),
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

% gridcolorop_replace(+Grid, +OldColor, +NewColor, +Bg, -Result)
% Replace every OldColor cell with NewColor. Other cells unchanged.
gridcolorop_replace(Grid, OldColor, NewColor, _Bg, Result) :-
    gridcolorop_grid_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R), nth0(R, Grid, OldRow),
         findall(NewV,
             (between(0, W1, C), nth0(C, OldRow, V),
              (V = OldColor -> NewV = NewColor ; NewV = V)),
             NewRow)),
        Result).

% gridcolorop_apply_map(+Grid, +Map, +Bg, -Result)
% Apply a list of OldColor-NewColor substitutions. Map = [old1-new1, ...].
% Cells not appearing as a key in Map are unchanged.
gridcolorop_apply_map(Grid, Map, _Bg, Result) :-
    gridcolorop_grid_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R), nth0(R, Grid, OldRow),
         findall(NewV,
             (between(0, W1, C), nth0(C, OldRow, V),
              (member(V-MV, Map) -> NewV = MV ; NewV = V)),
             NewRow)),
        Result).

% gridcolorop_keep_only(+Grid, +Color, +Bg, -Result)
% Keep cells matching Color; replace all other cells with Bg.
gridcolorop_keep_only(Grid, Color, Bg, Result) :-
    gridcolorop_grid_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R), nth0(R, Grid, OldRow),
         findall(NewV,
             (between(0, W1, C), nth0(C, OldRow, V),
              (V = Color -> NewV = Color ; NewV = Bg)),
             NewRow)),
        Result).

% gridcolorop_remove_color(+Grid, +Color, +Bg, -Result)
% Replace cells matching Color with Bg; keep all other cells unchanged.
gridcolorop_remove_color(Grid, Color, Bg, Result) :-
    gridcolorop_grid_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R), nth0(R, Grid, OldRow),
         findall(NewV,
             (between(0, W1, C), nth0(C, OldRow, V),
              (V = Color -> NewV = Bg ; NewV = V)),
             NewRow)),
        Result).

% gridcolorop_cycle(+Grid, +Palette, +N, +Bg, -Result)
% For each cell whose color appears in Palette, replace it with the
% color N positions forward (mod |Palette|, wrapping). Negative N cycles back.
% Colors not in Palette are unchanged.
gridcolorop_cycle(Grid, Palette, N, _Bg, Result) :-
    length(Palette, PLen),
    gridcolorop_grid_dims_(Grid, H, W),
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

% gridcolorop_rank_grid(+Grid, +Bg, -Result)
% Replace each non-bg cell with its color's 0-indexed frequency rank
% (integer: 0 = most frequent). Bg cells remain Bg.
gridcolorop_rank_grid(Grid, Bg, Result) :-
    gridcolorop_distinct_colors(Grid, Bg, ByFreq),
    gridcolorop_grid_dims_(Grid, H, W),
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

% gridcolorop_apply_palette(+Grid, +Bg, +Palette, -Result)
% Replace the Kth most frequent non-bg color with the Kth entry in Palette.
% Colors beyond |Palette| length are unchanged. Bg is unchanged.
gridcolorop_apply_palette(Grid, Bg, Palette, Result) :-
    gridcolorop_distinct_colors(Grid, Bg, ByFreq),
    findall(Old-New,
        (nth0(K, Palette, New), nth0(K, ByFreq, Old)),
        ReplaceMap),
    gridcolorop_apply_map(Grid, ReplaceMap, Bg, Result).

% gridcolorop_most_least(+Grid, +Bg, -Most, -Least)
% Most is the most frequent non-bg color; Least is the least frequent.
% Fails if Grid has no non-bg cells.
gridcolorop_most_least(Grid, Bg, Most, Least) :-
    gridcolorop_color_counts(Grid, Bg, Counts),
    Counts \= [],
    Counts = [cc(Most,_)|_],
    last(Counts, cc(Least,_)).

% gridcolorop_invert(+Grid, +Bg, +FgColor, -Result)
% Binary invert: non-bg cells become Bg; Bg cells become FgColor.
% Useful for creating binary masks or negative images.
gridcolorop_invert(Grid, Bg, FgColor, Result) :-
    gridcolorop_grid_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NewRow,
        (between(0, H1, R), nth0(R, Grid, OldRow),
         findall(NewV,
             (between(0, W1, C), nth0(C, OldRow, V),
              (V = Bg -> NewV = FgColor ; NewV = Bg)),
             NewRow)),
        Result).
