:- use_module('../prolog/gridrun').
:- use_module(library(plunit)).

% Grid fixtures

% 3x4: three uniform rows (horizontal stripes)
g3x4_hstripe([[r,r,r,r],[b,b,b,b],[g,g,g,g]]).

% 4x3: three uniform columns (vertical stripes)
g4x3_vstripe([[r,b,g],[r,b,g],[r,b,g],[r,b,g]]).

% 3x3: alternating rows
g3x3_alt([[r,b,r],[r,r,r],[b,r,b]]).

% 2x6: two alternating rows of r,b
g2x6_alt([[r,b,r,b,r,b],[b,r,b,r,b,r]]).

% 3x3: uniform grid
g3x3_r([[r,r,r],[r,r,r],[r,r,r]]).

% 4x4: mixed (not striped in either direction)
g4x4_mixed([[r,r,b,b],[r,r,b,b],[g,g,r,r],[g,g,r,r]]).

% 3x5: rows with varied run structure
g3x5_runs([[r,r,b,g,g],[b,b,b,r,r],[g,r,g,r,g]]).

% 1x1
g1x1([[r]]).

% 2x2 checkerboard
g2x2_check([[r,b],[b,r]]).

% 3x3: columns not uniform
g3x3_cols([[r,b,g],[r,b,g],[r,b,g]]).

% 4x1: single-column
g4x1([[r],[b],[g],[r]]).

:- begin_tests(gridrun).

% --- grl_row_runs/3 ---

test(row_runs_uniform) :-
% Uniform row [r,r,r,r] has one run r-4.
    g3x4_hstripe(G),
    grl_row_runs(G, 0, Runs),
    Runs = [r-4].

test(row_runs_two_colors) :-
% Row 0 of g3x5_runs = [r,r,b,g,g]: runs [r-2, b-1, g-2].
    g3x5_runs(G),
    grl_row_runs(G, 0, Runs),
    Runs = [r-2, b-1, g-2].

test(row_runs_all_different) :-
% Row 2 of g3x5_runs = [g,r,g,r,g]: runs [g-1,r-1,g-1,r-1,g-1].
    g3x5_runs(G),
    grl_row_runs(G, 2, Runs),
    Runs = [g-1, r-1, g-1, r-1, g-1].

test(row_runs_single_cell) :-
% 1x1 grid [[r]]: row 0 = [r], runs [r-1].
    g1x1(G),
    grl_row_runs(G, 0, Runs),
    Runs = [r-1].

test(row_runs_two_runs) :-
% Row 0 of g4x4_mixed = [r,r,b,b]: runs [r-2, b-2].
    g4x4_mixed(G),
    grl_row_runs(G, 0, Runs),
    Runs = [r-2, b-2].

% --- grl_col_runs/3 ---

test(col_runs_uniform) :-
% Column 0 of g4x3_vstripe = [r,r,r,r]: runs [r-4].
    g4x3_vstripe(G),
    grl_col_runs(G, 0, Runs),
    Runs = [r-4].

test(col_runs_two_values) :-
% Column 0 of g4x4_mixed = [r,r,g,g]: runs [r-2, g-2].
    g4x4_mixed(G),
    grl_col_runs(G, 0, Runs),
    Runs = [r-2, g-2].

test(col_runs_single) :-
% Single-column g4x1: col 0 = [r,b,g,r]: runs [r-1,b-1,g-1,r-1].
    g4x1(G),
    grl_col_runs(G, 0, Runs),
    Runs = [r-1, b-1, g-1, r-1].

% --- grl_all_row_runs/2 ---

test(all_row_runs_hstripe) :-
% 3 rows, each uniform: all runs lists are length 1.
    g3x4_hstripe(G),
    grl_all_row_runs(G, All),
    All = [[r-4],[b-4],[g-4]].

test(all_row_runs_mixed) :-
% g4x4_mixed: 4 rows, each with 2 runs.
    g4x4_mixed(G),
    grl_all_row_runs(G, All),
    length(All, 4),
    All = [[r-2,b-2],[r-2,b-2],[g-2,r-2],[g-2,r-2]].

% --- grl_all_col_runs/2 ---

test(all_col_runs_vstripe) :-
% 3 columns of g4x3_vstripe each uniform: runs [r-4],[b-4],[g-4].
    g4x3_vstripe(G),
    grl_all_col_runs(G, All),
    All = [[r-4],[b-4],[g-4]].

test(all_col_runs_mixed) :-
% g4x4_mixed: 4 cols each with runs [r-2,g-2],[r-2,g-2],[b-2,r-2],[b-2,r-2].
    g4x4_mixed(G),
    grl_all_col_runs(G, All),
    All = [[r-2,g-2],[r-2,g-2],[b-2,r-2],[b-2,r-2]].

% --- grl_decode/2 ---

test(decode_single_run) :-
% [r-3] decodes to [r,r,r].
    grl_decode([r-3], L),
    L = [r,r,r].

test(decode_two_runs) :-
% [r-2,b-3] decodes to [r,r,b,b,b].
    grl_decode([r-2, b-3], L),
    L = [r,r,b,b,b].

test(decode_all_single) :-
% [g-1,r-1,g-1,r-1,g-1] decodes to [g,r,g,r,g].
    grl_decode([g-1,r-1,g-1,r-1,g-1], L),
    L = [g,r,g,r,g].

test(decode_empty) :-
% Empty run list decodes to empty list.
    grl_decode([], L),
    L = [].

test(decode_roundtrip) :-
% Decode(encode(List)) = List for [r,r,b,g,g].
    grl_decode([r-2,b-1,g-2], L),
    L = [r,r,b,g,g].

% --- grl_run_count/3 ---

test(run_count_uniform) :-
% Uniform row has 1 run.
    g3x4_hstripe(G),
    grl_run_count(G, 0, N),
    N =:= 1.

test(run_count_two) :-
% Row 0 of g3x5_runs = [r,r,b,g,g]: 3 runs.
    g3x5_runs(G),
    grl_run_count(G, 0, N),
    N =:= 3.

test(run_count_all_diff) :-
% Row 2 of g3x5_runs = [g,r,g,r,g]: 5 runs (all length 1).
    g3x5_runs(G),
    grl_run_count(G, 2, N),
    N =:= 5.

% --- grl_uniform_row/3 ---

test(uniform_row_succeeds) :-
% Row 0 of g3x4_hstripe is uniform r.
    g3x4_hstripe(G),
    grl_uniform_row(G, 0, Color),
    Color = r.

test(uniform_row_fails, [fail]) :-
% Row 0 of g3x5_runs is [r,r,b,g,g] — not uniform.
    g3x5_runs(G),
    grl_uniform_row(G, 0, _).

test(uniform_row_single_cell) :-
% 1x1 [[r]]: row 0 is uniform r.
    g1x1(G),
    grl_uniform_row(G, 0, Color),
    Color = r.

% --- grl_uniform_col/3 ---

test(uniform_col_succeeds) :-
% Column 0 of g4x3_vstripe is uniform r.
    g4x3_vstripe(G),
    grl_uniform_col(G, 0, Color),
    Color = r.

test(uniform_col_fails, [fail]) :-
% Column 0 of g4x1 = [r,b,g,r] — not uniform.
    g4x1(G),
    grl_uniform_col(G, 0, _).

test(uniform_col_uniform_grid) :-
% g3x3_r: every column is uniform r.
    g3x3_r(G),
    grl_uniform_col(G, 1, Color),
    Color = r.

% --- grl_is_striped_h/1 ---

test(is_striped_h_succeeds) :-
% g3x4_hstripe: every row is uniform.
    g3x4_hstripe(G),
    grl_is_striped_h(G).

test(is_striped_h_uniform_grid) :-
% g3x3_r: every row is uniform (all r).
    g3x3_r(G),
    grl_is_striped_h(G).

test(is_striped_h_fails, [fail]) :-
% g3x3_alt: row 0 = [r,b,r] is not uniform.
    g3x3_alt(G),
    grl_is_striped_h(G).

% --- grl_is_striped_v/1 ---

test(is_striped_v_succeeds) :-
% g4x3_vstripe: every column is uniform.
    g4x3_vstripe(G),
    grl_is_striped_v(G).

test(is_striped_v_uniform_grid) :-
% g3x3_r: every column is uniform.
    g3x3_r(G),
    grl_is_striped_v(G).

test(is_striped_v_fails, [fail]) :-
% g3x3_cols = [[r,b,g],[r,b,g],[r,b,g]]: cols are uniform but rows are not.
% Actually g3x3_cols IS striped_v (each column is r or b or g).
% Use a grid where columns are NOT uniform:
    g3x3_alt(G),
    grl_is_striped_v(G).

% --- grl_stripe_colors_h/2 ---

test(stripe_colors_h_basic) :-
% g3x4_hstripe: colors are [r,b,g].
    g3x4_hstripe(G),
    grl_stripe_colors_h(G, Colors),
    Colors = [r,b,g].

test(stripe_colors_h_uniform) :-
% g3x3_r: all rows r -> colors [r,r,r].
    g3x3_r(G),
    grl_stripe_colors_h(G, Colors),
    Colors = [r,r,r].

test(stripe_colors_h_fails, [fail]) :-
% g3x5_runs has non-uniform rows.
    g3x5_runs(G),
    grl_stripe_colors_h(G, _).

% --- grl_stripe_colors_v/2 ---

test(stripe_colors_v_basic) :-
% g4x3_vstripe: col colors [r,b,g].
    g4x3_vstripe(G),
    grl_stripe_colors_v(G, Colors),
    Colors = [r,b,g].

test(stripe_colors_v_uniform) :-
% g3x3_r: all cols r -> colors [r,r,r].
    g3x3_r(G),
    grl_stripe_colors_v(G, Colors),
    Colors = [r,r,r].

test(stripe_colors_v_fails, [fail]) :-
% g3x3_alt has non-uniform columns.
    g3x3_alt(G),
    grl_stripe_colors_v(G, _).

% --- grl_max_run/4 ---

test(max_run_uniform) :-
% Uniform row r-4: max run is r, length 4.
    g3x4_hstripe(G),
    grl_max_run(G, 0, C, L),
    C = r, L =:= 4.

test(max_run_two_equal) :-
% Row 0 of g4x4_mixed = [r,r,b,b]: two runs each length 2.
% msort on negative-length keyed pairs: (-2-b, -2-r) -> b sorts before r (b<r term order).
    g4x4_mixed(G),
    grl_max_run(G, 0, C, L),
    C = b, L =:= 2.

test(max_run_varied) :-
% Row 1 of g3x5_runs = [b,b,b,r,r]: max run is b-3.
    g3x5_runs(G),
    grl_max_run(G, 1, C, L),
    C = b, L =:= 3.

test(max_run_all_singles) :-
% Row 2 of g3x5_runs = [g,r,g,r,g]: all runs length 1; first is g.
    g3x5_runs(G),
    grl_max_run(G, 2, C, L),
    C = g, L =:= 1.

% --- grl_alternating/2 ---

test(alternating_row0_g2x6) :-
% Row 0 of g2x6_alt = [r,b,r,b,r,b]: alternating r and b.
    g2x6_alt(G),
    grl_alternating(G, 0).

test(alternating_row1_g2x6) :-
% Row 1 of g2x6_alt = [b,r,b,r,b,r]: alternating b and r.
    g2x6_alt(G),
    grl_alternating(G, 1).

test(alternating_fails_uniform, [fail]) :-
% Uniform row [r,r,r,r] is not alternating.
    g3x4_hstripe(G),
    grl_alternating(G, 0).

test(alternating_fails_two_run, [fail]) :-
% Row 0 of g4x4_mixed = [r,r,b,b]: runs not all length 1.
    g4x4_mixed(G),
    grl_alternating(G, 0).

test(alternating_fails_three_colors, [fail]) :-
% Row 2 of g3x5_runs = [g,r,g,r,g]: all runs length 1 BUT only 2 colors
% Actually [g,r,g,r,g] has g and r only -> 2 colors -> should SUCCEED.
% Use a 3-color alternating row: needs grid fixture.
% g3x3_cols col 0 is [r,r,r] (from [[r,b,g],[r,b,g],[r,b,g]]) — not useful.
% Row 2 of g3x5_runs IS alternating with 2 colors. Let's test a non-alternating 3-color:
    grl_alternating([[g,r,b,g,r]], 0).

test(alternating_two_cells) :-
% [r,b]: single alternation of 2 cells -> alternating.
    grl_alternating([[r,b]], 0).

% Extra combined tests

test(encode_decode_roundtrip) :-
% Encoding then decoding a row recovers the original.
    g3x5_runs(G),
    grl_row_runs(G, 0, Runs),
    grl_decode(Runs, Row),
    nth0(0, G, OrigRow),
    Row = OrigRow.

test(hstripe_then_vstripe_false) :-
% A purely horizontal stripe is NOT vertically striped if row colors vary.
    g3x4_hstripe(G),
% g3x4_hstripe has rows [r,r,r,r],[b,b,b,b],[g,g,g,g].
% Column 0 = [r,b,g] — not uniform. So NOT vstriped.
    \+ grl_is_striped_v(G).

test(uniform_grid_both_striped) :-
% g3x3_r is both hstriped and vstriped.
    g3x3_r(G),
    grl_is_striped_h(G),
    grl_is_striped_v(G).

test(run_count_checkerboard_row0) :-
% g2x2_check row 0 = [r,b]: 2 runs.
    g2x2_check(G),
    grl_run_count(G, 0, N),
    N =:= 2.

test(all_row_runs_count) :-
% g3x5_runs has 3 rows.
    g3x5_runs(G),
    grl_all_row_runs(G, All),
    length(All, 3).

test(col_runs_vstripe_col1) :-
% Column 1 of g4x3_vstripe = [b,b,b,b]: runs [b-4].
    g4x3_vstripe(G),
    grl_col_runs(G, 1, Runs),
    Runs = [b-4].

test(col_runs_mixed) :-
% Column 2 of g4x4_mixed = [b,b,r,r]: runs [b-2,r-2].
    g4x4_mixed(G),
    grl_col_runs(G, 2, Runs),
    Runs = [b-2, r-2].

:- end_tests(gridrun).
