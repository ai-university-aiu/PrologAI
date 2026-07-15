:- use_module('../prolog/gridxform').

% Grid fixtures
% 3x3 labeled grid for rotation/flip verification
g3x3_id([[a,b,c],[d,e,f],[g,h,i]]).
% 2x3 non-square grid
g2x3([[a,b,c],[d,e,f]]).
% 3x2 non-square grid
g3x2([[a,b],[c,d],[e,f]]).
% 3x3 grid with r region in top-left and x background
g3x3_rb([[r,r,x],[r,r,x],[x,x,x]]).
% 1x1 single-cell grid
g1x1([[a]]).
% 3x3 grid with single non-background cell in center
g3x3_center([[x,x,x],[x,r,x],[x,x,x]]).
% 2x2 grid
g2x2([[p,q],[s,t]]).

:- begin_tests(gridxform).

% --- gridxform_rotate90 ---
test(rotate90_3x3, []) :-
    g3x3_id(G),
    gridxform_rotate90(G, R),
    R = [[g,d,a],[h,e,b],[i,f,c]].

test(rotate90_2x3, []) :-
    g2x3(G),
    gridxform_rotate90(G, R),
    R = [[d,a],[e,b],[f,c]].

test(rotate90_1x1, []) :-
    g1x1(G),
    gridxform_rotate90(G, R),
    R = [[a]].

% --- gridxform_rotate180 ---
test(rotate180_3x3, []) :-
    g3x3_id(G),
    gridxform_rotate180(G, R),
    R = [[i,h,g],[f,e,d],[c,b,a]].

test(rotate180_2x3, []) :-
    g2x3(G),
    gridxform_rotate180(G, R),
    R = [[f,e,d],[c,b,a]].

test(rotate180_twice_identity, []) :-
    g3x3_rb(G),
    gridxform_rotate180(G, R1),
    gridxform_rotate180(R1, G).

% --- gridxform_rotate270 ---
test(rotate270_3x3, []) :-
    g3x3_id(G),
    gridxform_rotate270(G, R),
    R = [[c,f,i],[b,e,h],[a,d,g]].

test(rotate270_2x3, []) :-
    g2x3(G),
    gridxform_rotate270(G, R),
    R = [[c,f],[b,e],[a,d]].

test(rotate90_then_270_identity, []) :-
    g3x3_id(G),
    gridxform_rotate90(G, R1),
    gridxform_rotate270(R1, G).

% --- gridxform_flip_h ---
test(flip_h_3x3, []) :-
    g3x3_id(G),
    gridxform_flip_h(G, R),
    R = [[c,b,a],[f,e,d],[i,h,g]].

test(flip_h_2x3, []) :-
    g2x3(G),
    gridxform_flip_h(G, R),
    R = [[c,b,a],[f,e,d]].

test(flip_h_twice_identity, []) :-
    g3x3_id(G),
    gridxform_flip_h(G, R1),
    gridxform_flip_h(R1, G).

% --- gridxform_flip_v ---
test(flip_v_3x3, []) :-
    g3x3_id(G),
    gridxform_flip_v(G, R),
    R = [[g,h,i],[d,e,f],[a,b,c]].

test(flip_v_2x3, []) :-
    g2x3(G),
    gridxform_flip_v(G, R),
    R = [[d,e,f],[a,b,c]].

test(flip_v_twice_identity, []) :-
    g3x3_id(G),
    gridxform_flip_v(G, R1),
    gridxform_flip_v(R1, G).

% --- gridxform_transpose ---
test(transpose_3x3, []) :-
    g3x3_id(G),
    gridxform_transpose(G, R),
    R = [[a,d,g],[b,e,h],[c,f,i]].

test(transpose_2x3, []) :-
    g2x3(G),
    gridxform_transpose(G, R),
    R = [[a,d],[b,e],[c,f]].

test(transpose_twice_identity, []) :-
    g3x3_id(G),
    gridxform_transpose(G, R1),
    gridxform_transpose(R1, G).

% --- gridxform_flip_d2 ---
test(flip_d2_3x3, []) :-
    g3x3_id(G),
    gridxform_flip_d2(G, R),
    R = [[i,f,c],[h,e,b],[g,d,a]].

test(flip_d2_2x3, []) :-
    g2x3(G),
    gridxform_flip_d2(G, R),
    R = [[f,c],[e,b],[d,a]].

test(flip_d2_twice_identity, []) :-
    g3x3_id(G),
    gridxform_flip_d2(G, R1),
    gridxform_flip_d2(R1, G).

% --- gridxform_crop ---
test(crop_center_1x1, []) :-
    g3x3_id(G),
    gridxform_crop(G, 1, 1, 1, 1, R),
    R = [[e]].

test(crop_top_row, []) :-
    g3x3_id(G),
    gridxform_crop(G, 0, 0, 0, 2, R),
    R = [[a,b,c]].

test(crop_bottom_right_2x2, []) :-
    g3x3_id(G),
    gridxform_crop(G, 1, 1, 2, 2, R),
    R = [[e,f],[h,i]].

% --- gridxform_crop_content ---
test(crop_content_center, []) :-
    g3x3_center(G),
    gridxform_crop_content(G, x, R),
    R = [[r]].

test(crop_content_all_bg, []) :-
    G = [[x,x],[x,x]],
    gridxform_crop_content(G, x, R),
    R = G.

test(crop_content_corner, []) :-
    G = [[r,x,x],[x,x,x],[x,x,x]],
    gridxform_crop_content(G, x, R),
    R = [[r]].

% --- gridxform_pad ---
test(pad_uniform_1, []) :-
    G = [[r]],
    gridxform_pad(G, 1, 1, 1, 1, x, R),
    R = [[x,x,x],[x,r,x],[x,x,x]].

test(pad_left_right, []) :-
    G = [[r,r],[r,r]],
    gridxform_pad(G, 0, 0, 1, 1, x, R),
    R = [[x,r,r,x],[x,r,r,x]].

test(pad_asymmetric, []) :-
    G = [[a]],
    gridxform_pad(G, 2, 0, 0, 1, x, R),
    R = [[x,x],[x,x],[a,x]].

% --- gridxform_scale ---
test(scale_1_identity, []) :-
    g2x2(G),
    gridxform_scale(G, 1, G).

test(scale_2_2x2, []) :-
    g2x2(G),
    gridxform_scale(G, 2, R),
    R = [[p,p,q,q],[p,p,q,q],[s,s,t,t],[s,s,t,t]].

test(scale_3_1x1, []) :-
    g1x1(G),
    gridxform_scale(G, 3, R),
    R = [[a,a,a],[a,a,a],[a,a,a]].

% --- gridxform_tile ---
test(tile_exact_same, []) :-
    g2x3(G),
    gridxform_tile(G, 2, 3, G).

test(tile_larger, []) :-
    G = [[r,x],[x,r]],
    gridxform_tile(G, 4, 4, R),
    R = [[r,x,r,x],[x,r,x,r],[r,x,r,x],[x,r,x,r]].

test(tile_1x1_to_3x3, []) :-
    G = [[r]],
    gridxform_tile(G, 3, 3, R),
    R = [[r,r,r],[r,r,r],[r,r,r]].

% --- gridxform_d4_group ---
test(d4_group_has_8_elements, []) :-
    g3x3_id(G),
    gridxform_d4_group(G, Ts),
    length(Ts, 8).

test(d4_group_first_is_identity, []) :-
    g3x3_id(G),
    gridxform_d4_group(G, [G|_]).

test(d4_group_symmetric_grid, []) :-
    G = [[r,r,r],[r,x,r],[r,r,r]],
    gridxform_d4_group(G, Ts),
    length(Ts, 8).

% --- gridxform_normalize ---
test(normalize_returns_minimum, []) :-
    g3x3_id(G),
    gridxform_normalize(G, Canon),
    gridxform_d4_group(G, Ts),
    msort(Ts, [Canon|_]).

test(normalize_uniform_grid, []) :-
    G = [[r,r],[r,r]],
    gridxform_normalize(G, G).

% --- Combined tests ---
test(rotate90_four_times_identity, []) :-
    g3x3_rb(G),
    gridxform_rotate90(G, R1),
    gridxform_rotate90(R1, R2),
    gridxform_rotate90(R2, R3),
    gridxform_rotate90(R3, G).

test(scale_2_center_grid, []) :-
    G = [[x,x,x],[x,r,x],[x,x,x]],
    gridxform_scale(G, 2, R),
    R = [[x,x,x,x,x,x],[x,x,x,x,x,x],
         [x,x,r,r,x,x],[x,x,r,r,x,x],
         [x,x,x,x,x,x],[x,x,x,x,x,x]].

test(crop_content_non_square, []) :-
    G = [[x,x,x],[x,r,r],[x,r,r]],
    gridxform_crop_content(G, x, R),
    R = [[r,r],[r,r]].

:- end_tests(gridxform).
