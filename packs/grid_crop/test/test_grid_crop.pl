:- use_module('../prolog/grid_crop').

% Test grids used throughout.
% g1: 4x4 grid with a 2x2 block of x at rows 1-2, cols 1-2; bg = b.
% g2: 3x5 grid with x at (0,2), (1,0), (2,4); bg = b.
% g3: 5x5 grid; bg = b; single x at (2,2).
% g4: 3x3 all-b grid.
% g5: 3x3 grid with a border of x.

g1([[b,b,b,b],[b,x,x,b],[b,x,x,b],[b,b,b,b]]).
g2([[b,b,x,b,b],[x,b,b,b,b],[b,b,b,b,x]]).
g3([[b,b,b,b,b],[b,b,b,b,b],[b,b,x,b,b],[b,b,b,b,b],[b,b,b,b,b]]).
g4([[b,b,b],[b,b,b],[b,b,b]]).
g5([[x,x,x],[x,b,x],[x,x,x]]).

:- begin_tests(grid_crop_bbox).

% AC-GCR-001: bbox of g1 is rows 1-2, cols 1-2.
test(bbox_g1) :-
    g1(G), grid_crop_bbox(G, b, Box), Box = 1-1-2-2.

% AC-GCR-002: bbox of g2 spans rows 0-2, cols 0-4.
test(bbox_g2) :-
    g2(G), grid_crop_bbox(G, b, Box), Box = 0-0-2-4.

% AC-GCR-003: bbox of g3 is the single cell (2,2).
test(bbox_g3) :-
    g3(G), grid_crop_bbox(G, b, Box), Box = 2-2-2-2.

:- end_tests(grid_crop_bbox).

:- begin_tests(grid_crop_crop_bbox).

% AC-GCR-004: crop_bbox of g1 yields 2x2 all-x grid.
test(crop_bbox_g1) :-
    g1(G), grid_crop_crop_bbox(G, b, C),
    C = [[x,x],[x,x]].

% AC-GCR-005: crop_bbox of g2 yields a 3x5 grid (full width and height used).
test(crop_bbox_g2) :-
    g2(G), grid_crop_crop_bbox(G, b, C),
    C = [[b,b,x,b,b],[x,b,b,b,b],[b,b,b,b,x]].

% AC-GCR-006: crop_bbox of g3 yields 1x1 grid [[x]].
test(crop_bbox_g3) :-
    g3(G), grid_crop_crop_bbox(G, b, C), C = [[x]].

:- end_tests(grid_crop_crop_bbox).

:- begin_tests(grid_crop_trim).

% AC-GCR-007: trim g1 yields 2x2 all-x.
test(trim_g1) :-
    g1(G), grid_crop_trim(G, b, T), T = [[x,x],[x,x]].

% AC-GCR-008: trim g5 (border of x, center b) yields g5 itself (no uniform bg border).
test(trim_g5) :-
    g5(G), grid_crop_trim(G, b, T), T = [[x,x,x],[x,b,x],[x,x,x]].

% AC-GCR-009: trim a 3x3 grid with padding returns just the inner 1x1.
test(trim_padded) :-
    G = [[b,b,b,b,b],[b,b,b,b,b],[b,b,x,b,b],[b,b,b,b,b],[b,b,b,b,b]],
    grid_crop_trim(G, b, T), T = [[x]].

:- end_tests(grid_crop_trim).

:- begin_tests(grid_crop_trim_rows).

% AC-GCR-010: trim_rows g1 removes first and last row.
test(trim_rows_g1) :-
    g1(G), grid_crop_trim_rows(G, b, T),
    T = [[b,x,x,b],[b,x,x,b]].

% AC-GCR-011: trim_rows on g2 removes no rows (all rows have non-bg cells).
test(trim_rows_g2) :-
    g2(G), grid_crop_trim_rows(G, b, T), T = G.

% AC-GCR-012: trim_rows only removes top/bottom uniform rows, not columns.
test(trim_rows_only_rows) :-
    G = [[b,b,b],[b,x,b],[b,b,b]],
    grid_crop_trim_rows(G, b, T),
    T = [[b,x,b]].

:- end_tests(grid_crop_trim_rows).

:- begin_tests(grid_crop_trim_cols).

% AC-GCR-013: trim_cols g1 removes first and last column.
test(trim_cols_g1) :-
    g1(G), grid_crop_trim_cols(G, b, T),
    T = [[b,b],[x,x],[x,x],[b,b]].

% AC-GCR-014: trim_cols on g5 removes no columns.
test(trim_cols_g5) :-
    g5(G), grid_crop_trim_cols(G, b, T), T = G.

% AC-GCR-015: trim_cols only removes left/right uniform columns, not rows.
test(trim_cols_only_cols) :-
    G = [[b,b,b],[b,x,b],[b,b,b]],
    grid_crop_trim_cols(G, b, T),
    T = [[b],[x],[b]].

:- end_tests(grid_crop_trim_cols).

:- begin_tests(grid_crop_crop).

% AC-GCR-016: crop g1 to 1-1..2-2 yields 2x2 all-x.
test(crop_g1_inner) :-
    g1(G), grid_crop_crop(G, 1, 1, 2, 2, C), C = [[x,x],[x,x]].

% AC-GCR-017: crop g2 to 0-0..1-2 yields top-left 2x3.
test(crop_g2_topleft) :-
    g2(G), grid_crop_crop(G, 0, 0, 1, 2, C),
    C = [[b,b,x],[x,b,b]].

% AC-GCR-018: crop single cell (1,1) from g1.
test(crop_single_cell) :-
    g1(G), grid_crop_crop(G, 1, 1, 1, 1, C), C = [[x]].

:- end_tests(grid_crop_crop).

:- begin_tests(grid_crop_pad_to).

% AC-GCR-019: pad 2x2 all-x to 4x4.
test(pad_to_4x4) :-
    G = [[x,x],[x,x]],
    grid_crop_pad_to(G, b, 4, 4, P),
    P = [[x,x,b,b],[x,x,b,b],[b,b,b,b],[b,b,b,b]].

% AC-GCR-020: pad to same size yields unchanged grid.
test(pad_to_same_size) :-
    g1(G), grid_crop_pad_to(G, b, 4, 4, P), P = G.

% AC-GCR-021: pad to wider only (no extra rows).
test(pad_wider_only) :-
    G = [[x,x],[x,x]],
    grid_crop_pad_to(G, b, 2, 4, P),
    P = [[x,x,b,b],[x,x,b,b]].

:- end_tests(grid_crop_pad_to).

:- begin_tests(grid_crop_center_in).

% AC-GCR-022: center 1x1 [[x]] in 3x3.
test(center_1x1_in_3x3) :-
    G = [[x]],
    grid_crop_center_in(G, b, 3, 3, C),
    C = [[b,b,b],[b,x,b],[b,b,b]].

% AC-GCR-023: center 2x2 in 4x4.
test(center_2x2_in_4x4) :-
    G = [[x,x],[x,x]],
    grid_crop_center_in(G, b, 4, 4, C),
    C = [[b,b,b,b],[b,x,x,b],[b,x,x,b],[b,b,b,b]].

% AC-GCR-024: center grid already the right size is a no-op.
test(center_same_size) :-
    G = [[x,x],[x,x]],
    grid_crop_center_in(G, b, 2, 2, C), C = G.

:- end_tests(grid_crop_center_in).

:- begin_tests(grid_crop_add_border).

% AC-GCR-025: add 1-cell border of m to 2x2 all-x.
test(add_border_1) :-
    G = [[x,x],[x,x]],
    grid_crop_add_border(G, 1, m, B),
    B = [[m,m,m,m],[m,x,x,m],[m,x,x,m],[m,m,m,m]].

% AC-GCR-026: add 2-cell border of b to 1x1 [[x]].
test(add_border_2) :-
    G = [[x]],
    grid_crop_add_border(G, 2, b, B),
    B = [[b,b,b,b,b],[b,b,b,b,b],[b,b,x,b,b],[b,b,b,b,b],[b,b,b,b,b]].

% AC-GCR-027: add_border then remove_border recovers original.
test(add_remove_border) :-
    g4(G), grid_crop_add_border(G, 1, m, B),
    grid_crop_remove_border(B, 1, m, R), R = G.

:- end_tests(grid_crop_add_border).

:- begin_tests(grid_crop_remove_border).

% AC-GCR-028: remove 1-cell border from g5 yields [[b]].
test(remove_border_g5) :-
    g5(G), grid_crop_remove_border(G, 1, x, R), R = [[b]].

% AC-GCR-029: remove 1-cell border from g1 yields inner 2x2.
test(remove_border_g1) :-
    g1(G), grid_crop_remove_border(G, 1, b, R),
    R = [[x,x],[x,x]].

% AC-GCR-030: remove_border is the inverse of add_border.
test(remove_border_inverse) :-
    G = [[a,b],[c,d]],
    grid_crop_add_border(G, 1, z, B),
    grid_crop_remove_border(B, 1, z, R), R = G.

:- end_tests(grid_crop_remove_border).

:- begin_tests(grid_crop_expand_down).

% AC-GCR-031: expand_down g4 by 2 rows of x.
test(expand_down_g4) :-
    g4(G), grid_crop_expand_down(G, 2, x, E),
    E = [[b,b,b],[b,b,b],[b,b,b],[x,x,x],[x,x,x]].

% AC-GCR-032: expand_down by 0 rows yields unchanged grid.
test(expand_down_zero) :-
    g4(G), grid_crop_expand_down(G, 0, x, E), E = G.

% AC-GCR-033: expand_down 1x1 [[a]] by 1 row.
test(expand_down_1x1) :-
    G = [[a]], grid_crop_expand_down(G, 1, b, E),
    E = [[a],[b]].

:- end_tests(grid_crop_expand_down).

:- begin_tests(grid_crop_expand_right).

% AC-GCR-034: expand_right g4 by 2 columns of x.
test(expand_right_g4) :-
    g4(G), grid_crop_expand_right(G, 2, x, E),
    E = [[b,b,b,x,x],[b,b,b,x,x],[b,b,b,x,x]].

% AC-GCR-035: expand_right by 0 columns yields unchanged grid.
test(expand_right_zero) :-
    g4(G), grid_crop_expand_right(G, 0, x, E), E = G.

% AC-GCR-036: expand_right 1x1 [[a]] by 1 column.
test(expand_right_1x1) :-
    G = [[a]], grid_crop_expand_right(G, 1, b, E),
    E = [[a,b]].

:- end_tests(grid_crop_expand_right).

:- begin_tests(grid_crop_content_h).

% AC-GCR-037: content_h of g1 is 2 (rows 1-2).
test(content_h_g1) :-
    g1(G), grid_crop_content_h(G, b, H), H =:= 2.

% AC-GCR-038: content_h of g3 is 1 (single cell).
test(content_h_g3) :-
    g3(G), grid_crop_content_h(G, b, H), H =:= 1.

% AC-GCR-039: content_h of g2 is 3 (all rows used).
test(content_h_g2) :-
    g2(G), grid_crop_content_h(G, b, H), H =:= 3.

:- end_tests(grid_crop_content_h).

:- begin_tests(grid_crop_content_w).

% AC-GCR-040: content_w of g1 is 2 (cols 1-2).
test(content_w_g1) :-
    g1(G), grid_crop_content_w(G, b, W), W =:= 2.

% AC-GCR-041: content_w of g3 is 1 (single cell).
test(content_w_g3) :-
    g3(G), grid_crop_content_w(G, b, W), W =:= 1.

% AC-GCR-042: content_w of g2 is 5 (full width).
test(content_w_g2) :-
    g2(G), grid_crop_content_w(G, b, W), W =:= 5.

:- end_tests(grid_crop_content_w).

:- begin_tests(gcr_combined).

% AC-GCR-043: pad then trim recovers original content.
test(pad_then_trim) :-
    G = [[x,x],[x,x]],
    grid_crop_pad_to(G, b, 5, 5, Padded),
    grid_crop_trim(Padded, b, Trimmed),
    Trimmed = G.

% AC-GCR-044: add_border then crop_bbox recovers the inner content.
test(add_border_then_crop_bbox) :-
    G = [[r,g],[b,y]],
    grid_crop_add_border(G, 2, b, Bordered),
    grid_crop_crop_bbox(Bordered, b, Cropped),
    Cropped = G.

:- end_tests(gcr_combined).
