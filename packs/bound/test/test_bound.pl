:- use_module('../prolog/bound').

:- begin_tests(bound).

% --- bd_bbox ---

test(bbox_basic) :-
    bd_bbox([[0,1,0],[0,1,0],[0,0,0]], 1, R0, C0, R1, C1),
    R0 = 0, C0 = 1, R1 = 1, C1 = 1.

test(bbox_corner) :-
    bd_bbox([[1,0,0],[0,0,0],[0,0,1]], 1, R0, C0, R1, C1),
    R0 = 0, C0 = 0, R1 = 2, C1 = 2.

test(bbox_absent_fails) :-
    \+ bd_bbox([[0,0],[0,0]], 9, _, _, _, _).

% --- bd_bbox_h ---

test(bbox_h_basic) :-
    bd_bbox_h(1, 3, H),
    H = 3.

test(bbox_h_one) :-
    bd_bbox_h(2, 2, H),
    H = 1.

test(bbox_h_large) :-
    bd_bbox_h(0, 9, H),
    H = 10.

% --- bd_bbox_w ---

test(bbox_w_basic) :-
    bd_bbox_w(1, 4, W),
    W = 4.

test(bbox_w_one) :-
    bd_bbox_w(3, 3, W),
    W = 1.

test(bbox_w_large) :-
    bd_bbox_w(0, 7, W),
    W = 8.

% --- bd_crop_bbox ---

test(crop_bbox_center) :-
    bd_crop_bbox([[1,2,3],[4,5,6],[7,8,9]], 0, 1, 1, 2, Sub),
    Sub = [[2,3],[5,6]].

test(crop_bbox_row) :-
    bd_crop_bbox([[a,b,c],[d,e,f]], 1, 0, 1, 2, Sub),
    Sub = [[d,e,f]].

test(crop_bbox_cell) :-
    bd_crop_bbox([[1,2],[3,4]], 1, 1, 1, 1, Sub),
    Sub = [[4]].

% --- bd_crop_color ---

test(crop_color_basic) :-
    bd_crop_color([[0,0,0],[0,1,0],[0,0,0]], 1, Sub),
    Sub = [[1]].

test(crop_color_wider) :-
    bd_crop_color([[0,0,0],[0,1,1],[0,1,0]], 1, Sub),
    Sub = [[1,1],[1,0]].

test(crop_color_absent_fails) :-
    \+ bd_crop_color([[0,0],[0,0]], 5, _).

% --- bd_trim ---

test(trim_basic) :-
    bd_trim([[0,0,0],[0,1,0],[0,0,0]], 0, T),
    T = [[1]].

test(trim_no_border) :-
    bd_trim([[1,2],[3,4]], 0, T),
    T = [[1,2],[3,4]].

test(trim_all_bg) :-
    bd_trim([[0,0],[0,0]], 0, T),
    T = [[]].

% --- bd_pad ---

test(pad_one) :-
    bd_pad([[1,2],[3,4]], 1, 0, P),
    P = [[0,0,0,0],[0,1,2,0],[0,3,4,0],[0,0,0,0]].

test(pad_zero) :-
    bd_pad([[1,2],[3,4]], 0, 0, P),
    P = [[1,2],[3,4]].

test(pad_two) :-
    bd_pad([[5]], 2, 0, P),
    P = [[0,0,0,0,0],[0,0,0,0,0],[0,0,5,0,0],[0,0,0,0,0],[0,0,0,0,0]].

% --- bd_place ---

test(place_top_left) :-
    bd_place([[0,0,0],[0,0,0],[0,0,0]], [[1,2],[3,4]], 0, 0, 0, New),
    New = [[1,2,0],[3,4,0],[0,0,0]].

test(place_offset) :-
    bd_place([[0,0,0],[0,0,0],[0,0,0]], [[7]], 1, 2, 0, New),
    New = [[0,0,0],[0,0,7],[0,0,0]].

test(place_unchanged_outside) :-
    bd_place([[1,2],[3,4]], [[9]], 0, 0, 0, New),
    New = [[9,2],[3,4]].

% --- bd_center ---

test(center_symmetric) :-
    bd_center([[0,0,0],[0,1,0],[0,0,0]], 1, CR, CC),
    CR = 1, CC = 1.

test(center_rect) :-
    bd_center([[1,1,1],[1,1,1],[0,0,0]], 1, CR, CC),
    CR = 0, CC = 1.

test(center_single_cell) :-
    bd_center([[0,1,0],[0,0,0]], 1, CR, CC),
    CR = 0, CC = 1.

% --- bd_bbox_contains ---

test(contains_inside) :-
    bd_bbox_contains(1, 1, 3, 3, 2, 2).

test(contains_corner) :-
    bd_bbox_contains(0, 0, 2, 2, 2, 2).

test(contains_outside_fails) :-
    \+ bd_bbox_contains(1, 1, 3, 3, 0, 2).

% --- bd_bbox_overlap ---

test(overlap_yes) :-
    bd_bbox_overlap(0, 0, 2, 2, 1, 1, 3, 3).

test(overlap_touching) :-
    bd_bbox_overlap(0, 0, 2, 2, 2, 2, 4, 4).

test(overlap_no) :-
    \+ bd_bbox_overlap(0, 0, 1, 1, 3, 3, 4, 4).

% --- bd_bbox_union ---

test(union_basic) :-
    bd_bbox_union(0, 0, 2, 2, 1, 1, 3, 3, R0, C0, R1, C1),
    R0 = 0, C0 = 0, R1 = 3, C1 = 3.

test(union_one_inside) :-
    bd_bbox_union(0, 0, 4, 4, 1, 1, 2, 2, R0, C0, R1, C1),
    R0 = 0, C0 = 0, R1 = 4, C1 = 4.

test(union_disjoint) :-
    bd_bbox_union(0, 0, 1, 1, 3, 3, 4, 4, R0, C0, R1, C1),
    R0 = 0, C0 = 0, R1 = 4, C1 = 4.

% --- bd_expand ---

test(expand_basic) :-
    bd_expand(1, 1, 3, 3, 1, ER0, EC0, ER1, EC1),
    ER0 = 0, EC0 = 0, ER1 = 4, EC1 = 4.

test(expand_zero) :-
    bd_expand(2, 2, 5, 5, 0, ER0, EC0, ER1, EC1),
    ER0 = 2, EC0 = 2, ER1 = 5, EC1 = 5.

test(expand_two) :-
    bd_expand(3, 3, 3, 3, 2, ER0, EC0, ER1, EC1),
    ER0 = 1, EC0 = 1, ER1 = 5, EC1 = 5.

% --- bd_fill_bbox ---

test(fill_bbox_center) :-
    bd_fill_bbox([[0,0,0],[0,0,0],[0,0,0]], 1, 1, 1, 1, 9, New),
    New = [[0,0,0],[0,9,0],[0,0,0]].

test(fill_bbox_row) :-
    bd_fill_bbox([[0,0,0],[0,0,0],[0,0,0]], 1, 0, 1, 2, 5, New),
    New = [[0,0,0],[5,5,5],[0,0,0]].

test(fill_bbox_all) :-
    bd_fill_bbox([[0,0],[0,0]], 0, 0, 1, 1, 1, New),
    New = [[1,1],[1,1]].

:- end_tests(bound).
