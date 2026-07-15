% Test suite for gridcolorop (gco_*, Layer 240).
:- use_module('../prolog/grid_color_operation.pl').

:- begin_tests(grid_color_operation).

% AC-GCO-001: grid_color_operation_color_counts returns correct counts.
test('AC-GCO-001: color_counts basic') :-
    Grid = [[r,r,g],[b,b,b]],
    grid_color_operation_color_counts(Grid, b, Counts),
    member(cc(r,2), Counts),
    member(cc(g,1), Counts).

% AC-GCO-002: grid_color_operation_color_counts most frequent first.
test('AC-GCO-002: color_counts ordered') :-
    Grid = [[r,r,r],[g,g,b]],
    grid_color_operation_color_counts(Grid, b, [cc(r,3)|_]).

% AC-GCO-003: grid_color_operation_color_counts on all-bg grid returns empty.
test('AC-GCO-003: color_counts all bg') :-
    Grid = [[b,b],[b,b]],
    grid_color_operation_color_counts(Grid, b, []).

% AC-GCO-004: grid_color_operation_distinct_colors returns colors by frequency.
test('AC-GCO-004: distinct_colors') :-
    Grid = [[r,r,g],[b,b,b]],
    grid_color_operation_distinct_colors(Grid, b, [r,g]).

% AC-GCO-005: grid_color_operation_distinct_colors on single color.
test('AC-GCO-005: distinct_colors single') :-
    Grid = [[r,r],[r,r]],
    grid_color_operation_distinct_colors(Grid, b, [r]).

% AC-GCO-006: grid_color_operation_distinct_colors on all-bg returns empty.
test('AC-GCO-006: distinct_colors empty') :-
    Grid = [[b,b],[b,b]],
    grid_color_operation_distinct_colors(Grid, b, []).

% AC-GCO-007: grid_color_operation_nth_color returns most frequent.
test('AC-GCO-007: nth_color 0') :-
    Grid = [[r,r,g],[b,b,b]],
    grid_color_operation_nth_color(Grid, b, 0, r).

% AC-GCO-008: grid_color_operation_nth_color returns second most frequent.
test('AC-GCO-008: nth_color 1') :-
    Grid = [[r,r,g],[b,b,b]],
    grid_color_operation_nth_color(Grid, b, 1, g).

% AC-GCO-009: grid_color_operation_count_distinct returns 2 for two colors.
test('AC-GCO-009: count_distinct two') :-
    Grid = [[r,g],[b,b]],
    grid_color_operation_count_distinct(Grid, b, 2).

% AC-GCO-010: grid_color_operation_count_distinct returns 0 for all-bg.
test('AC-GCO-010: count_distinct zero') :-
    Grid = [[b,b],[b,b]],
    grid_color_operation_count_distinct(Grid, b, 0).

% AC-GCO-011: grid_color_operation_swap exchanges two colors.
test('AC-GCO-011: swap basic') :-
    Grid = [[r,g],[g,r]],
    grid_color_operation_swap(Grid, r, g, b, Result),
    Result = [[g,r],[r,g]].

% AC-GCO-012: grid_color_operation_swap with no occurrence of one color is identity.
test('AC-GCO-012: swap no color2') :-
    Grid = [[r,b],[r,b]],
    grid_color_operation_swap(Grid, r, g, b, Result),
    Result = [[g,b],[g,b]].

% AC-GCO-013: grid_color_operation_swap does not affect bg.
test('AC-GCO-013: swap bg unchanged') :-
    Grid = [[r,b],[b,g]],
    grid_color_operation_swap(Grid, r, g, b, Result),
    Result = [[g,b],[b,r]].

% AC-GCO-014: grid_color_operation_replace replaces one color.
test('AC-GCO-014: replace basic') :-
    Grid = [[r,b],[r,g]],
    grid_color_operation_replace(Grid, r, x, b, Result),
    Result = [[x,b],[x,g]].

% AC-GCO-015: grid_color_operation_replace with non-existent color is identity.
test('AC-GCO-015: replace no match') :-
    Grid = [[r,b],[b,g]],
    grid_color_operation_replace(Grid, y, x, b, Result),
    Result = [[r,b],[b,g]].

% AC-GCO-016: grid_color_operation_apply_map applies multiple replacements.
test('AC-GCO-016: apply_map two pairs') :-
    Grid = [[r,g],[b,b]],
    grid_color_operation_apply_map(Grid, [r-x, g-y], b, Result),
    Result = [[x,y],[b,b]].

% AC-GCO-017: grid_color_operation_apply_map with empty map is identity.
test('AC-GCO-017: apply_map empty') :-
    Grid = [[r,g],[b,b]],
    grid_color_operation_apply_map(Grid, [], b, Result),
    Result = [[r,g],[b,b]].

% AC-GCO-018: grid_color_operation_keep_only keeps target color, bg-ifies rest.
test('AC-GCO-018: keep_only basic') :-
    Grid = [[r,g],[b,b]],
    grid_color_operation_keep_only(Grid, r, b, Result),
    Result = [[r,b],[b,b]].

% AC-GCO-019: grid_color_operation_keep_only on all-bg returns all-bg.
test('AC-GCO-019: keep_only all bg') :-
    Grid = [[b,b],[b,b]],
    grid_color_operation_keep_only(Grid, r, b, Result),
    Result = [[b,b],[b,b]].

% AC-GCO-020: grid_color_operation_remove_color removes target color.
test('AC-GCO-020: remove_color basic') :-
    Grid = [[r,g],[b,b]],
    grid_color_operation_remove_color(Grid, r, b, Result),
    Result = [[b,g],[b,b]].

% AC-GCO-021: grid_color_operation_remove_color with no match is identity.
test('AC-GCO-021: remove_color no match') :-
    Grid = [[r,g],[b,b]],
    grid_color_operation_remove_color(Grid, y, b, Result),
    Result = [[r,g],[b,b]].

% AC-GCO-022: grid_color_operation_cycle shifts colors by 1 forward.
test('AC-GCO-022: cycle N=1') :-
    Grid = [[r,g],[b,b]],
    grid_color_operation_cycle(Grid, [r,g,y], 1, b, Result),
    Result = [[g,y],[b,b]].

% AC-GCO-023: grid_color_operation_cycle wraps around (last -> first).
test('AC-GCO-023: cycle wrap') :-
    Grid = [[y,b],[b,b]],
    grid_color_operation_cycle(Grid, [r,g,y], 1, b, Result),
    Result = [[r,b],[b,b]].

% AC-GCO-024: grid_color_operation_cycle with N=0 is identity.
test('AC-GCO-024: cycle N=0') :-
    Grid = [[r,g],[b,b]],
    grid_color_operation_cycle(Grid, [r,g,y], 0, b, Result),
    Result = [[r,g],[b,b]].

% AC-GCO-025: grid_color_operation_cycle leaves non-palette colors unchanged.
test('AC-GCO-025: cycle non-palette unchanged') :-
    Grid = [[r,x],[b,b]],
    grid_color_operation_cycle(Grid, [r,g], 1, b, Result),
    Result = [[g,x],[b,b]].

% AC-GCO-026: grid_color_operation_rank_grid replaces cells with frequency ranks.
test('AC-GCO-026: rank_grid basic') :-
    Grid = [[r,r,r],[g,g,b]],
% r appears 3 times (rank 0), g appears 2 times (rank 1).
    grid_color_operation_rank_grid(Grid, b, Result),
    Result = [[0,0,0],[1,1,b]].

% AC-GCO-027: grid_color_operation_rank_grid single color gets rank 0.
test('AC-GCO-027: rank_grid single color') :-
    Grid = [[r,b],[r,b]],
    grid_color_operation_rank_grid(Grid, b, Result),
    Result = [[0,b],[0,b]].

% AC-GCO-028: grid_color_operation_rank_grid all-bg returns unchanged.
test('AC-GCO-028: rank_grid all bg') :-
    Grid = [[b,b],[b,b]],
    grid_color_operation_rank_grid(Grid, b, Result),
    Result = [[b,b],[b,b]].

% AC-GCO-029: grid_color_operation_apply_palette maps most-frequent to first palette color.
test('AC-GCO-029: apply_palette basic') :-
    Grid = [[r,r,r],[g,g,b]],
    grid_color_operation_apply_palette(Grid, b, [x,y], Result),
% r (rank 0) -> x; g (rank 1) -> y.
    Result = [[x,x,x],[y,y,b]].

% AC-GCO-030: grid_color_operation_apply_palette with shorter palette leaves unmatched colors.
test('AC-GCO-030: apply_palette partial') :-
    Grid = [[r,r,g],[b,b,b]],
    grid_color_operation_apply_palette(Grid, b, [x], Result),
% r (rank 0) -> x; g (rank 1) unchanged.
    Result = [[x,x,g],[b,b,b]].

% AC-GCO-031: grid_color_operation_most_least basic.
test('AC-GCO-031: most_least basic') :-
    Grid = [[r,r,r],[g,g,b]],
    grid_color_operation_most_least(Grid, b, Most, Least),
    Most = r, Least = g.

% AC-GCO-032: grid_color_operation_most_least single color: most = least.
test('AC-GCO-032: most_least single') :-
    Grid = [[r,r],[r,b]],
    grid_color_operation_most_least(Grid, b, r, r).

% AC-GCO-033: grid_color_operation_invert swaps non-bg with Bg.
test('AC-GCO-033: invert basic') :-
    Grid = [[r,b],[b,g]],
    grid_color_operation_invert(Grid, b, x, Result),
    Result = [[b,x],[x,b]].

% AC-GCO-034: grid_color_operation_invert on all-bg fills all with FgColor.
test('AC-GCO-034: invert all bg') :-
    Grid = [[b,b],[b,b]],
    grid_color_operation_invert(Grid, b, r, Result),
    Result = [[r,r],[r,r]].

% AC-GCO-035: grid_color_operation_invert on all non-bg returns all bg.
test('AC-GCO-035: invert all fg') :-
    Grid = [[r,g],[y,p]],
    grid_color_operation_invert(Grid, b, x, Result),
    Result = [[b,b],[b,b]].

% AC-GCO-036: grid_color_operation_replace replaces bg cells too.
test('AC-GCO-036: replace bg cells') :-
    Grid = [[r,b],[b,g]],
    grid_color_operation_replace(Grid, b, x, b, Result),
    Result = [[r,x],[x,g]].

% AC-GCO-037: grid_color_operation_cycle backward (N=-1).
test('AC-GCO-037: cycle backward') :-
    Grid = [[r,b],[b,b]],
    grid_color_operation_cycle(Grid, [r,g,y], -1, b, Result),
    Result = [[y,b],[b,b]].

% AC-GCO-038: grid_color_operation_apply_map with no matching cells is identity.
test('AC-GCO-038: apply_map no match') :-
    Grid = [[r,b],[g,b]],
    grid_color_operation_apply_map(Grid, [y-z], b, Result),
    Result = [[r,b],[g,b]].

% AC-GCO-039: grid_color_operation_keep_only on grid with only that color returns grid.
test('AC-GCO-039: keep_only all that color') :-
    Grid = [[r,r],[r,r]],
    grid_color_operation_keep_only(Grid, r, b, Result),
    Result = [[r,r],[r,r]].

% AC-GCO-040: grid_color_operation_color_counts has correct count for three colors.
test('AC-GCO-040: color_counts three colors') :-
    Grid = [[r,r,g],[g,y,b]],
    grid_color_operation_color_counts(Grid, b, Counts),
    length(Counts, 3).

% AC-GCO-041: grid_color_operation_count_distinct three colors.
test('AC-GCO-041: count_distinct three') :-
    Grid = [[r,g,y],[b,b,b]],
    grid_color_operation_count_distinct(Grid, b, 3).

% AC-GCO-042: grid_color_operation_cycle N=2 shifts two steps.
test('AC-GCO-042: cycle N=2') :-
    Grid = [[r,b],[b,b]],
    grid_color_operation_cycle(Grid, [r,g,y], 2, b, Result),
    Result = [[y,b],[b,b]].

% AC-GCO-043: integration - rank then apply_palette to recolor.
test('AC-GCO-043: integration rank and palette') :-
    Grid = [[r,r,g],[g,g,b]],
    grid_color_operation_apply_palette(Grid, b, [a,c], Result),
% g appears 3 times (rank 0) -> a; r appears 2 times (rank 1) -> c.
    Result = [[c,c,a],[a,a,b]].

% AC-GCO-044: integration - remove then count_distinct.
test('AC-GCO-044: integration remove then count') :-
    Grid = [[r,g],[g,r]],
    grid_color_operation_remove_color(Grid, r, b, Cleaned),
    grid_color_operation_count_distinct(Cleaned, b, Count),
    Count = 1.

:- end_tests(grid_color_operation).
