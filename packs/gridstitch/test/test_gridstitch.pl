:- use_module('../prolog/gridstitch').

% Grid fixtures
% 2x2 grids
g2x2_a([[a,a],[a,a]]).
g2x2_b([[b,b],[b,b]]).
g2x2_ab([[a,b],[a,b]]).
g2x2_ba([[b,a],[b,a]]).
% 2x3 grid
g2x3([[a,b,c],[d,e,f]]).
% 3x2 grid
g3x2([[a,b],[c,d],[e,f]]).
% Single row/col
g1x3([[p,q,r]]).
g3x1([[p],[q],[r]]).
% Uniform grids for border tests
g3x3_r([[r,r,r],[r,r,r],[r,r,r]]).
g2x2_x([[x,x],[x,x]]).
% 4x4 for quadrant tests
g4x4([[a,b,c,d],[e,f,g,h],[i,j,k,l],[m,n,o,p]]).
% 2x2 quadrants of g4x4
g4x4_tl([[a,b],[e,f]]).
g4x4_tr([[c,d],[g,h]]).
g4x4_bl([[i,j],[m,n]]).
g4x4_br([[k,l],[o,p]]).

:- begin_tests(gridstitch).

% --- gst_concat_h ---
test(concat_h_2x2, []) :-
    g2x2_a(A), g2x2_b(B),
    gst_concat_h(A, B, R),
    R = [[a,a,b,b],[a,a,b,b]].

test(concat_h_2x3_and_2x2, []) :-
    g2x3(A), g2x2_a(B),
    gst_concat_h(A, B, R),
    R = [[a,b,c,a,a],[d,e,f,a,a]].

test(concat_h_single_row, []) :-
    g1x3(A), g1x3(B),
    gst_concat_h(A, B, R),
    R = [[p,q,r,p,q,r]].

% --- gst_concat_v ---
test(concat_v_2x2, []) :-
    g2x2_a(A), g2x2_b(B),
    gst_concat_v(A, B, R),
    R = [[a,a],[a,a],[b,b],[b,b]].

test(concat_v_2x3_stacked, []) :-
    g2x3(A), g2x3(B),
    gst_concat_v(A, B, R),
    R = [[a,b,c],[d,e,f],[a,b,c],[d,e,f]].

test(concat_v_single_col, []) :-
    g3x1(A), g3x1(B),
    gst_concat_v(A, B, R),
    R = [[p],[q],[r],[p],[q],[r]].

% --- gst_hstack ---
test(hstack_three_grids, []) :-
    g2x2_a(A), g2x2_b(B), g2x2_a(C),
    gst_hstack([A, B, C], R),
    R = [[a,a,b,b,a,a],[a,a,b,b,a,a]].

test(hstack_single, []) :-
    g2x3(G),
    gst_hstack([G], G).

test(hstack_empty, []) :-
    gst_hstack([], []).

% --- gst_vstack ---
test(vstack_three_grids, []) :-
    g2x2_a(A), g2x2_b(B), g2x2_a(C),
    gst_vstack([A, B, C], R),
    R = [[a,a],[a,a],[b,b],[b,b],[a,a],[a,a]].

test(vstack_single, []) :-
    g2x3(G),
    gst_vstack([G], G).

test(vstack_empty, []) :-
    gst_vstack([], []).

% --- gst_split_h ---
test(split_h_at_1, []) :-
    g3x2(G),
    gst_split_h(G, 1, Top, Bottom),
    Top = [[a,b]],
    Bottom = [[c,d],[e,f]].

test(split_h_at_2, []) :-
    g4x4(G),
    gst_split_h(G, 2, Top, Bottom),
    Top = [[a,b,c,d],[e,f,g,h]],
    Bottom = [[i,j,k,l],[m,n,o,p]].

% --- gst_split_v ---
test(split_v_at_1, []) :-
    g2x3(G),
    gst_split_v(G, 1, Left, Right),
    Left = [[a],[d]],
    Right = [[b,c],[e,f]].

test(split_v_at_2, []) :-
    g4x4(G),
    gst_split_v(G, 2, Left, Right),
    Left = [[a,b],[e,f],[i,j],[m,n]],
    Right = [[c,d],[g,h],[k,l],[o,p]].

% --- gst_halves_h ---
test(halves_h_4x4, []) :-
    g4x4(G),
    gst_halves_h(G, Top, Bottom),
    Top = [[a,b,c,d],[e,f,g,h]],
    Bottom = [[i,j,k,l],[m,n,o,p]].

test(halves_h_reconstruct, []) :-
    g4x4(G),
    gst_halves_h(G, Top, Bottom),
    gst_concat_v(Top, Bottom, G).

% --- gst_halves_v ---
test(halves_v_4x4, []) :-
    g4x4(G),
    gst_halves_v(G, Left, Right),
    Left = [[a,b],[e,f],[i,j],[m,n]],
    Right = [[c,d],[g,h],[k,l],[o,p]].

test(halves_v_reconstruct, []) :-
    g4x4(G),
    gst_halves_v(G, Left, Right),
    gst_concat_h(Left, Right, G).

% --- gst_quadrants ---
test(quadrants_4x4, []) :-
    g4x4(G),
    gst_quadrants(G, TL, TR, BL, BR),
    g4x4_tl(TL),
    g4x4_tr(TR),
    g4x4_bl(BL),
    g4x4_br(BR).

test(quadrants_reconstruct, []) :-
    g4x4(G),
    gst_quadrants(G, TL, TR, BL, BR),
    gst_concat_h(TL, TR, Top),
    gst_concat_h(BL, BR, Bottom),
    gst_concat_v(Top, Bottom, G).

% --- gst_tile_grid ---
test(tile_grid_2x2_layout, []) :-
    g2x2_a(A), g2x2_b(B), g2x2_b(C), g2x2_a(D),
    gst_tile_grid([A, B, C, D], 2, 2, R),
    R = [[a,a,b,b],[a,a,b,b],[b,b,a,a],[b,b,a,a]].

test(tile_grid_1x3_layout, []) :-
    g2x2_a(A), g2x2_b(B), g2x2_a(C),
    gst_tile_grid([A, B, C], 1, 3, R),
    R = [[a,a,b,b,a,a],[a,a,b,b,a,a]].

% --- gst_repeat_h ---
test(repeat_h_twice, []) :-
    g2x2_a(G),
    gst_repeat_h(G, 2, R),
    R = [[a,a,a,a],[a,a,a,a]].

test(repeat_h_three, []) :-
    g1x3(G),
    gst_repeat_h(G, 3, R),
    R = [[p,q,r,p,q,r,p,q,r]].

test(repeat_h_once, []) :-
    g2x2_a(G),
    gst_repeat_h(G, 1, G).

% --- gst_repeat_v ---
test(repeat_v_twice, []) :-
    g2x2_b(G),
    gst_repeat_v(G, 2, R),
    R = [[b,b],[b,b],[b,b],[b,b]].

test(repeat_v_once, []) :-
    g2x2_b(G),
    gst_repeat_v(G, 1, G).

% --- gst_add_border ---
test(add_border_1_cell, []) :-
    g2x2_x(G),
    gst_add_border(G, 1, r, R),
    R = [[r,r,r,r],[r,x,x,r],[r,x,x,r],[r,r,r,r]].

test(add_border_2_cells, []) :-
    G = [[a]],
    gst_add_border(G, 2, b, R),
    length(R, 5),
    R = [[b,b,b,b,b],[b,b,b,b,b],[b,b,a,b,b],[b,b,b,b,b],[b,b,b,b,b]].

test(add_border_preserves_interior, []) :-
    g3x3_r(G),
    gst_add_border(G, 1, x, R),
    length(R, 5),
    R = [[x,x,x,x,x],[x,r,r,r,x],[x,r,r,r,x],[x,r,r,r,x],[x,x,x,x,x]].

% --- gst_strip_border ---
test(strip_border_1_cell, []) :-
    R = [[r,r,r,r],[r,x,x,r],[r,x,x,r],[r,r,r,r]],
    gst_strip_border(R, 1, G),
    G = [[x,x],[x,x]].

test(strip_border_is_inverse_of_add, []) :-
    g3x3_r(G),
    gst_add_border(G, 1, x, Bordered),
    gst_strip_border(Bordered, 1, G).

test(strip_border_2_cells, []) :-
    G = [[b,b,b,b,b],[b,b,b,b,b],[b,b,a,b,b],[b,b,b,b,b],[b,b,b,b,b]],
    gst_strip_border(G, 2, Inner),
    Inner = [[a]].

% --- Combined ---
test(hstack_then_split_v_recovers, []) :-
    g2x2_a(A), g2x2_b(B),
    gst_concat_h(A, B, AB),
    gst_split_v(AB, 2, LA, RB),
    LA = [[a,a],[a,a]],
    RB = [[b,b],[b,b]].

test(vstack_then_split_h_recovers, []) :-
    g2x3(A), g2x3(B),
    gst_concat_v(A, B, AB),
    gst_split_h(AB, 2, TA, BB2),
    TA = A,
    BB2 = B.

test(repeat_h_width_is_n_times, []) :-
    g2x2_a(G),
    gst_repeat_h(G, 3, R),
    length(R, 2),
    R = [Row|_], length(Row, 6).

test(tile_and_quadrant_consistent, []) :-
    g2x2_a(TL), g2x2_b(TR), g2x2_b(BL), g2x2_a(BR),
    gst_tile_grid([TL, TR, BL, BR], 2, 2, Full),
    gst_quadrants(Full, TL2, TR2, BL2, BR2),
    TL2 = TL, TR2 = TR, BL2 = BL, BR2 = BR.

test(concat_h_then_split_v_exact, []) :-
    g3x2(A), g3x2(B),
    gst_concat_h(A, B, Full),
    gst_split_v(Full, 2, LA, RB),
    LA = A, RB = B.

test(add_border_then_strip_roundtrip, []) :-
    g2x3(G),
    gst_add_border(G, 2, x, Bordered),
    gst_strip_border(Bordered, 2, G).

test(repeat_v_height_is_n_times, []) :-
    g2x2_b(G),
    gst_repeat_v(G, 4, R),
    length(R, 8).

test(split_h_then_vstack_recovers, []) :-
    g4x4(G),
    gst_split_h(G, 1, Top, Bottom),
    gst_vstack([Top, Bottom], G).

test(split_v_then_hstack_recovers, []) :-
    g4x4(G),
    gst_split_v(G, 1, Left, Right),
    gst_hstack([Left, Right], G).

:- end_tests(gridstitch).
