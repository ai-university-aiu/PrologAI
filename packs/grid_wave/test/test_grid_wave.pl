:- use_module('../prolog/grid_wave').
:- use_module(library(lists), [length/2]).

% Test grids used throughout.
% c3: 3x3, single x at center, all else bg.
%   Row 0: b b b
%   Row 1: b x b
%   Row 2: b b b
% multi: 3x3, x top-left, y top-right, rest bg.
%   Row 0: x b y
%   Row 1: b b b
%   Row 2: b b b
% full3: 3x3, all x (no bg).
% block5: 5x5, 3x3 block of x surrounded by bg.
% eq4: 3x3, three colors for equidistant test.
%   Row 0: b x b
%   Row 1: y b z
%   Row 2: b b b
% ab3: 3x3 all-bg grid.
% s3: same as c3 (reused for shadow tests).

c3([[b,b,b],[b,x,b],[b,b,b]]).
multi([[x,b,y],[b,b,b],[b,b,b]]).
full3([[x,x,x],[x,x,x],[x,x,x]]).
block5([[b,b,b,b,b],[b,x,x,x,b],[b,x,x,x,b],[b,x,x,x,b],[b,b,b,b,b]]).
eq4([[b,x,b],[y,b,z],[b,b,b]]).
ab3([[b,b,b],[b,b,b],[b,b,b]]).

:- begin_tests(grid_wave_step).

% AC-GWV-001: center x in 3x3 expands to four cardinal cells.
test(step_center) :-
    c3(G), grid_wave_step(G, b, S),
    S = [[b,x,b],[x,x,x],[b,x,b]].

% AC-GWV-002: two-color grid: conflict cell at (0,1) stays bg; flanks take nearest color.
test(step_conflict) :-
    multi(G), grid_wave_step(G, b, S),
    S = [[x,b,y],[x,b,y],[b,b,b]].

% AC-GWV-003: all-fg grid: no bg to expand into; step returns unchanged grid.
test(step_all_fg) :-
    full3(G), grid_wave_step(G, b, S),
    S = [[x,x,x],[x,x,x],[x,x,x]].

:- end_tests(grid_wave_step).

:- begin_tests(grid_wave_fill).

% AC-GWV-004: single-color fill of 3x3 with center x floods entire grid.
test(fill_single) :-
    c3(G), grid_wave_fill(G, b, F),
    F = [[x,x,x],[x,x,x],[x,x,x]].

% AC-GWV-005: two-color fill reaches fixed point with conflict column intact.
test(fill_two) :-
    multi(G), grid_wave_fill(G, b, F),
    F = [[x,b,y],[x,b,y],[x,b,y]].

% AC-GWV-006: all-fg grid: fill returns grid unchanged.
test(fill_noop) :-
    full3(G), grid_wave_fill(G, b, F),
    F = [[x,x,x],[x,x,x],[x,x,x]].

:- end_tests(grid_wave_fill).

:- begin_tests(grid_wave_fill_n).

% AC-GWV-007: fill_n 0 steps returns grid unchanged.
test(fill_n_zero) :-
    c3(G), grid_wave_fill_n(G, 0, b, R),
    R = [[b,b,b],[b,x,b],[b,b,b]].

% AC-GWV-008: fill_n 1 step from center produces plus shape.
test(fill_n_one) :-
    c3(G), grid_wave_fill_n(G, 1, b, R),
    R = [[b,x,b],[x,x,x],[b,x,b]].

% AC-GWV-009: fill_n 2 steps from center floods entire 3x3.
test(fill_n_two) :-
    c3(G), grid_wave_fill_n(G, 2, b, R),
    R = [[x,x,x],[x,x,x],[x,x,x]].

:- end_tests(grid_wave_fill_n).

:- begin_tests(grid_wave_frontier).

% AC-GWV-010: all-bg grid has no frontier cells.
test(frontier_all_bg) :-
    ab3(G), grid_wave_frontier(G, b, F),
    F = [].

% AC-GWV-011: c3 frontier is the four cardinal bg cells around center x.
test(frontier_c3) :-
    c3(G), grid_wave_frontier(G, b, F),
    F = [0-1, 1-0, 1-2, 2-1].

% AC-GWV-012: multi frontier has exactly three cells.
test(frontier_multi) :-
    multi(G), grid_wave_frontier(G, b, F),
    length(F, N), N =:= 3.

:- end_tests(grid_wave_frontier).

:- begin_tests(grid_wave_color_frontier).

% AC-GWV-013: color frontier of x in multi: cells (0,1) and (1,0).
test(color_frontier_x) :-
    multi(G), grid_wave_color_frontier(G, b, x, F),
    F = [0-1, 1-0].

% AC-GWV-014: color frontier in all-fg grid returns empty (no bg cells).
test(color_frontier_none) :-
    full3(G), grid_wave_color_frontier(G, b, x, F),
    F = [].

% AC-GWV-015: color frontier of y in multi: cells (0,1) and (1,2).
test(color_frontier_y) :-
    multi(G), grid_wave_color_frontier(G, b, y, F),
    F = [0-1, 1-2].

:- end_tests(grid_wave_color_frontier).

:- begin_tests(grid_wave_equidistant_front).

% AC-GWV-016: multi has one equidistant cell: (0,1) touches both x and y.
test(equidistant_multi) :-
    multi(G), grid_wave_equidistant_front(G, b, E),
    E = [0-1].

% AC-GWV-017: single-color c3 has no equidistant cells.
test(equidistant_single) :-
    c3(G), grid_wave_equidistant_front(G, b, E),
    E = [].

% AC-GWV-018: eq4 grid has three equidistant cells (touching two or more of x,y,z).
test(equidistant_three) :-
    eq4(G), grid_wave_equidistant_front(G, b, E),
    length(E, N), N =:= 3.

:- end_tests(grid_wave_equidistant_front).

:- begin_tests(grid_wave_color_expand).

% AC-GWV-019: expand x in multi: x spreads to (0,1) and (1,0) only.
test(color_expand_x) :-
    multi(G), grid_wave_color_expand(G, x, b, E),
    E = [[x,x,y],[x,b,b],[b,b,b]].

% AC-GWV-020: expand y in multi: y spreads to (0,1) and (1,2) only.
test(color_expand_y) :-
    multi(G), grid_wave_color_expand(G, y, b, E),
    E = [[x,y,y],[b,b,y],[b,b,b]].

% AC-GWV-021: expand x in all-fg grid: no bg to fill; result unchanged.
test(color_expand_noop) :-
    full3(G), grid_wave_color_expand(G, x, b, E),
    E = [[x,x,x],[x,x,x],[x,x,x]].

:- end_tests(grid_wave_color_expand).

:- begin_tests(grid_wave_color_expand_n).

% AC-GWV-022: color_expand_n 0 returns grid unchanged.
test(color_expand_n_zero) :-
    c3(G), grid_wave_color_expand_n(G, x, 0, b, R),
    R = [[b,b,b],[b,x,b],[b,b,b]].

% AC-GWV-023: color_expand_n 1 from center produces plus shape.
test(color_expand_n_one) :-
    c3(G), grid_wave_color_expand_n(G, x, 1, b, R),
    R = [[b,x,b],[x,x,x],[b,x,b]].

% AC-GWV-024: color_expand_n 2 from center floods entire 3x3.
test(color_expand_n_two) :-
    c3(G), grid_wave_color_expand_n(G, x, 2, b, R),
    R = [[x,x,x],[x,x,x],[x,x,x]].

:- end_tests(grid_wave_color_expand_n).

:- begin_tests(grid_wave_shadow_right).

% AC-GWV-025: center x in 3x3 casts rightward shadow to (1,2).
test(shadow_right_s3) :-
    c3(G), grid_wave_shadow_right(G, b, s, S),
    S = [[b,b,b],[b,x,s],[b,b,b]].

% AC-GWV-026: row with x then y: bg cells between and after shadow.
test(shadow_right_row) :-
    G = [[x,b,b,y],[b,b,b,b]],
    grid_wave_shadow_right(G, b, s, S),
    S = [[x,s,s,y],[b,b,b,b]].

% AC-GWV-027: all-bg grid: shadow_right produces no shadows.
test(shadow_right_all_bg) :-
    ab3(G), grid_wave_shadow_right(G, b, s, S),
    S = [[b,b,b],[b,b,b],[b,b,b]].

:- end_tests(grid_wave_shadow_right).

:- begin_tests(grid_wave_shadow_left).

% AC-GWV-028: center x in 3x3 casts leftward shadow to (1,0).
test(shadow_left_s3) :-
    c3(G), grid_wave_shadow_left(G, b, s, S),
    S = [[b,b,b],[s,x,b],[b,b,b]].

% AC-GWV-029: row with x at col 2: both cells to its left become shadow.
test(shadow_left_row) :-
    G = [[b,b,x,b],[b,b,b,b]],
    grid_wave_shadow_left(G, b, s, S),
    S = [[s,s,x,b],[b,b,b,b]].

% AC-GWV-030: all-bg grid: shadow_left produces no shadows.
test(shadow_left_all_bg) :-
    ab3(G), grid_wave_shadow_left(G, b, s, S),
    S = [[b,b,b],[b,b,b],[b,b,b]].

:- end_tests(grid_wave_shadow_left).

:- begin_tests(grid_wave_shadow_down).

% AC-GWV-031: center x in 3x3 casts downward shadow to (2,1).
test(shadow_down_s3) :-
    c3(G), grid_wave_shadow_down(G, b, s, S),
    S = [[b,b,b],[b,x,b],[b,s,b]].

% AC-GWV-032: x in row 1 col 0 casts downward shadow to row 2.
test(shadow_down_col) :-
    G = [[b,b],[x,b],[b,b]],
    grid_wave_shadow_down(G, b, s, S),
    S = [[b,b],[x,b],[s,b]].

% AC-GWV-033: all-bg grid: shadow_down produces no shadows.
test(shadow_down_all_bg) :-
    ab3(G), grid_wave_shadow_down(G, b, s, S),
    S = [[b,b,b],[b,b,b],[b,b,b]].

:- end_tests(grid_wave_shadow_down).

:- begin_tests(grid_wave_shadow_up).

% AC-GWV-034: center x in 3x3 casts upward shadow to (0,1).
test(shadow_up_s3) :-
    c3(G), grid_wave_shadow_up(G, b, s, S),
    S = [[b,s,b],[b,x,b],[b,b,b]].

% AC-GWV-035: x in row 2 col 0 casts upward shadow to rows 0 and 1.
test(shadow_up_col) :-
    G = [[b,b],[b,b],[x,b]],
    grid_wave_shadow_up(G, b, s, S),
    S = [[s,b],[s,b],[x,b]].

% AC-GWV-036: all-bg grid: shadow_up produces no shadows.
test(shadow_up_all_bg) :-
    ab3(G), grid_wave_shadow_up(G, b, s, S),
    S = [[b,b,b],[b,b,b],[b,b,b]].

:- end_tests(grid_wave_shadow_up).

:- begin_tests(grid_wave_contract).

% AC-GWV-037: isolated center x in 3x3 has all in-bounds bg neighbors; fully contracts.
test(contract_single) :-
    c3(G), grid_wave_contract(G, b, C),
    C = [[b,b,b],[b,b,b],[b,b,b]].

% AC-GWV-038: 3x3 block in 5x5: edge x cells contract; center x has no bg neighbor, stays.
test(contract_block) :-
    block5(G), grid_wave_contract(G, b, C),
    C = [[b,b,b,b,b],[b,b,b,b,b],[b,b,x,b,b],[b,b,b,b,b],[b,b,b,b,b]].

% AC-GWV-039: all-bg grid: no non-bg cells; contract returns unchanged.
test(contract_all_bg) :-
    ab3(G), grid_wave_contract(G, b, C),
    C = [[b,b,b],[b,b,b],[b,b,b]].

:- end_tests(grid_wave_contract).

:- begin_tests(grid_wave_contract_n).

% AC-GWV-040: contract_n 0 returns block5 unchanged.
test(contract_n_zero) :-
    block5(G), grid_wave_contract_n(G, 0, b, R),
    block5(R).

% AC-GWV-041: contract_n 1 reduces 3x3 block to single center cell.
test(contract_n_one) :-
    block5(G), grid_wave_contract_n(G, 1, b, R),
    R = [[b,b,b,b,b],[b,b,b,b,b],[b,b,x,b,b],[b,b,b,b,b],[b,b,b,b,b]].

% AC-GWV-042: contract_n 2 fully erases the 3x3 block.
test(contract_n_two) :-
    block5(G), grid_wave_contract_n(G, 2, b, R),
    R = [[b,b,b,b,b],[b,b,b,b,b],[b,b,b,b,b],[b,b,b,b,b],[b,b,b,b,b]].

:- end_tests(grid_wave_contract_n).

:- begin_tests(gwv_combined).

% AC-GWV-043: step c3 once (plus), frontier of result is the four corner bg cells.
test(combined_step_frontier) :-
    c3(G),
    grid_wave_step(G, b, Plus),
    Plus = [[b,x,b],[x,x,x],[b,x,b]],
    grid_wave_frontier(Plus, b, F),
    length(F, N), N =:= 4.

% AC-GWV-044: expand c3 x once to plus, then contract: round-trips back to c3.
test(combined_expand_contract) :-
    c3(G),
    grid_wave_color_expand_n(G, x, 1, b, Plus),
    Plus = [[b,x,b],[x,x,x],[b,x,b]],
    grid_wave_contract(Plus, b, Back),
    Back = [[b,b,b],[b,x,b],[b,b,b]].

:- end_tests(gwv_combined).
