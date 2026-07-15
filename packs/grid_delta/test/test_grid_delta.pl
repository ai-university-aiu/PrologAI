:- use_module('../prolog/grid_delta').

% Grid fixtures
% 3x3 plain grid
g3x3a([[r,r,r],[r,x,r],[r,r,r]]).
% Same grid (identity)
g3x3a_copy([[r,r,r],[r,x,r],[r,r,r]]).
% Modified: center changed to b
g3x3b([[r,r,r],[r,b,r],[r,r,r]]).
% Modified: top-left changed to x
g3x3c([[x,r,r],[r,x,r],[r,r,r]]).
% Two cells changed: top-left and center
g3x3d([[x,r,r],[r,b,r],[r,r,r]]).
% Completely different
g3x3e([[x,x,x],[x,x,x],[x,x,x]]).
% 3x3 uniform
g3x3r([[r,r,r],[r,r,r],[r,r,r]]).
% 3x3 overlay target
g3x3f([[r,b,r],[r,r,r],[r,r,r]]).
% 4x4 grids
g4x4a([[a,a,a,a],[a,a,a,a],[a,a,a,a],[a,a,a,a]]).
g4x4b([[a,a,a,a],[a,b,a,a],[a,a,a,a],[a,a,a,a]]).
% Overlay source: non-transparent cells
g3x3_overlay([[r,n,r],[n,r,n],[r,n,r]]).

:- begin_tests(grid_delta).

% --- grid_delta_compatible ---
test(compatible_same_size, []) :-
    g3x3a(G1), g3x3b(G2),
    grid_delta_compatible(G1, G2).

test(compatible_self, []) :-
    g3x3a(G),
    grid_delta_compatible(G, G).

% --- grid_delta_diff_cells ---
test(difference_cells_none, []) :-
    g3x3a(G1), g3x3a_copy(G2),
    grid_delta_diff_cells(G1, G2, []).

test(difference_cells_one, []) :-
    g3x3a(G1), g3x3b(G2),
    % Only center (1,1) changed
    grid_delta_diff_cells(G1, G2, [1-1]).

test(difference_cells_two, []) :-
    g3x3a(G1), g3x3d(G2),
    % (0,0) and (1,1) changed
    grid_delta_diff_cells(G1, G2, Cells),
    length(Cells, 2),
    memberchk(0-0, Cells),
    memberchk(1-1, Cells).

test(difference_cells_all, []) :-
    g3x3r(G1), g3x3e(G2),
    % All 9 cells differ (r vs x everywhere)
    grid_delta_diff_cells(G1, G2, Cells),
    length(Cells, 9).

% --- grid_delta_diff_count ---
test(difference_count_zero, []) :-
    g3x3a(G1), g3x3a_copy(G2),
    grid_delta_diff_count(G1, G2, 0).

test(difference_count_one, []) :-
    g3x3a(G1), g3x3b(G2),
    grid_delta_diff_count(G1, G2, 1).

test(difference_count_all, []) :-
    g3x3r(G1), g3x3e(G2),
    grid_delta_diff_count(G1, G2, 9).

% --- grid_delta_same_cells ---
test(same_cells_all, []) :-
    g3x3a(G1), g3x3a_copy(G2),
    grid_delta_same_cells(G1, G2, Cells),
    length(Cells, 9).

test(same_cells_eight, []) :-
    g3x3a(G1), g3x3b(G2),
    % 8 cells agree (only center differs)
    grid_delta_same_cells(G1, G2, Cells),
    length(Cells, 8).

test(same_cells_none, []) :-
    g3x3r(G1), g3x3e(G2),
    % No cell agrees
    grid_delta_same_cells(G1, G2, []).

% --- grid_delta_changed_pairs ---
test(changed_pairs_one, []) :-
    g3x3a(G1), g3x3b(G2),
    % One change: (1,1) from x to b
    grid_delta_changed_pairs(G1, G2, [1-1-(x->b)]).

test(changed_pairs_two, []) :-
    g3x3a(G1), g3x3d(G2),
    % Two changes: (0,0) from r to x, (1,1) from x to b
    grid_delta_changed_pairs(G1, G2, Pairs),
    length(Pairs, 2),
    memberchk(0-0-(r->x), Pairs),
    memberchk(1-1-(x->b), Pairs).

% --- grid_delta_color_changes ---
test(color_changes_r_count, []) :-
    g3x3r(G1), g3x3e(G2),
    % All 9 r cells changed to x
    grid_delta_color_changes(G1, G2, r, 9).

test(color_changes_x_count, []) :-
    g3x3a(G1), g3x3b(G2),
    % 1 x cell (center) changed to b
    grid_delta_color_changes(G1, G2, x, 1).

test(color_changes_none, []) :-
    g3x3a(G1), g3x3a_copy(G2),
    % No changes from r
    grid_delta_color_changes(G1, G2, r, 0).

% --- grid_delta_changed_colors ---
test(changed_colors_one, []) :-
    g3x3a(G1), g3x3b(G2),
    % Center changed to b
    grid_delta_changed_colors(G1, G2, [b]).

test(changed_colors_two, []) :-
    g3x3a(G1), g3x3d(G2),
    % (0,0) changed to x, (1,1) changed to b
    grid_delta_changed_colors(G1, G2, Colors),
    length(Colors, 2),
    memberchk(b, Colors),
    memberchk(x, Colors).

test(changed_colors_none, []) :-
    g3x3a(G1), g3x3a_copy(G2),
    grid_delta_changed_colors(G1, G2, []).

% --- grid_delta_apply_delta ---
test(apply_delta_identity, []) :-
    % G1=G2=unchanged: applying no-op delta leaves G3 unchanged
    g3x3a(G),
    grid_delta_apply_delta(G, G, G, Result),
    Result = G.

test(apply_delta_center, []) :-
    g3x3a(G1), g3x3b(G2), g3x3a(G3),
    % Delta: center x→b; G3 has x at center → Result has b at center
    grid_delta_apply_delta(G1, G2, G3, Result),
    nth0(1, Result, Row1), nth0(1, Row1, b).

test(apply_delta_no_match, []) :-
    g3x3a(G1), g3x3c(G2), g3x3b(G3),
    % Delta: (0,0) r→x; G3 has b center (not r at (0,0))
    % G3's (0,0) = r, so it should get x
    grid_delta_apply_delta(G1, G2, G3, Result),
    nth0(0, Result, Row0), nth0(0, Row0, x).

% --- grid_delta_diff_rows ---
test(difference_rows_none, []) :-
    g3x3a(G1), g3x3a_copy(G2),
    grid_delta_diff_rows(G1, G2, []).

test(difference_rows_one, []) :-
    g3x3a(G1), g3x3b(G2),
    % Only row 1 has a difference
    grid_delta_diff_rows(G1, G2, [1]).

test(difference_rows_all, []) :-
    g3x3r(G1), g3x3e(G2),
    % All 3 rows differ
    grid_delta_diff_rows(G1, G2, [0, 1, 2]).

% --- grid_delta_diff_cols ---
test(difference_cols_one, []) :-
    g3x3a(G1), g3x3b(G2),
    % Only column 1 has a difference
    grid_delta_diff_cols(G1, G2, [1]).

test(difference_cols_all, []) :-
    g3x3r(G1), g3x3e(G2),
    % All 3 columns differ
    grid_delta_diff_cols(G1, G2, [0, 1, 2]).

% --- grid_delta_agree_region ---
test(agree_region_all, []) :-
    g3x3a(G1), g3x3a_copy(G2),
    grid_delta_agree_region(G1, G2, 0, 2, 0, 2).

test(agree_region_top_row, []) :-
    g3x3a(G1), g3x3b(G2),
    % Row 0 is unchanged
    grid_delta_agree_region(G1, G2, 0, 0, 0, 2).

test(agree_region_fails_center, []) :-
    g3x3a(G1), g3x3b(G2),
    % Center row includes (1,1) which changed
    \+ grid_delta_agree_region(G1, G2, 1, 1, 1, 1).

% --- grid_delta_overlay ---
test(overlay_non_transparent, []) :-
    g3x3r(Base),
    g3x3_overlay(Overlay),
    % Overlay n cells onto r base; r is transparent
    grid_delta_overlay(Base, Overlay, r, Result),
    % (0,1)=n, (1,0)=n etc. from Overlay; (0,0)=r from Base
    nth0(0, Result, Row0), nth0(1, Row0, n),
    nth0(0, Result, Row0b), nth0(0, Row0b, r).

test(overlay_fully_transparent, []) :-
    g3x3a(G1), g3x3r(G2),
    % All of G2 is r (the transparent marker), so result = G1
    grid_delta_overlay(G1, G2, r, Result),
    Result = G1.

% --- grid_delta_invert_delta ---
test(invert_delta_restores, []) :-
    g3x3a(G1), g3x3b(G2),
    % Invert delta: changed cells in G2 get G1's values back
    grid_delta_invert_delta(G1, G2, Inv),
    % Result should equal G1
    Inv = G1.

test(invert_delta_identity, []) :-
    g3x3a(G),
    grid_delta_invert_delta(G, G, Inv),
    Inv = G.

% --- grid_delta_is_identity ---
test(is_identity_same, []) :-
    g3x3a(G1), g3x3a_copy(G2),
    grid_delta_is_identity(G1, G2).

test(is_identity_self, []) :-
    g3x3a(G),
    grid_delta_is_identity(G, G).

test(is_identity_fails, []) :-
    g3x3a(G1), g3x3b(G2),
    \+ grid_delta_is_identity(G1, G2).

% Combined tests
test(difference_count_plus_same_count_equals_total, []) :-
    g3x3a(G1), g3x3d(G2),
    grid_delta_diff_count(G1, G2, D),
    grid_delta_same_cells(G1, G2, Same),
    length(Same, S),
    Total is D + S,
    Total =:= 9.

test(invert_delta_roundtrip, []) :-
    g3x3a(G1), g3x3b(G2),
    grid_delta_invert_delta(G1, G2, Inv),
    grid_delta_is_identity(G1, Inv).

test(apply_delta_4x4, []) :-
    g4x4a(G1), g4x4b(G2), g4x4a(G3),
    % Delta: (1,1) a→b; G3 has a at (1,1) → gets b
    grid_delta_apply_delta(G1, G2, G3, Result),
    nth0(1, Result, Row1), nth0(1, Row1, b).

test(difference_rows_two_changes, []) :-
    g3x3a(G1), g3x3c(G2),
    % g3x3c: (0,0) changed from r to x; only row 0 differs
    grid_delta_diff_rows(G1, G2, [0]).

test(changed_pairs_none, []) :-
    g3x3a(G1), g3x3a_copy(G2),
    grid_delta_changed_pairs(G1, G2, []).

test(difference_cols_two, []) :-
    g3x3a(G1), g3x3d(G2),
    % g3x3d: (0,0) and (1,1) changed; cols 0 and 1 have differences
    grid_delta_diff_cols(G1, G2, Cols),
    length(Cols, 2),
    memberchk(0, Cols),
    memberchk(1, Cols).

:- end_tests(grid_delta).
