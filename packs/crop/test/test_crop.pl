% PLUnit tests for the crop pack (cr_* predicates).
:- use_module(library(plunit)).
:- use_module(library(crop)).

% Helper grids for testing.
% 3x3 grid: rows=3, cols=3.
g3x3([[0,1,0],[1,1,1],[0,1,0]]).
% 4x4 grid with background 0.
g4x4([[0,0,0,0],[0,1,2,0],[0,3,4,0],[0,0,0,0]]).
% 2x4 grid.
g2x4([[1,2,3,4],[5,6,7,8]]).
% 4x2 grid.
g4x2([[1,2],[3,4],[5,6],[7,8]]).
% Simple 2x2.
g2x2([[1,2],[3,4]]).
% 2x3.
g2x3([[1,2,3],[4,5,6]]).
% 3x2.
g3x2([[1,2],[3,4],[5,6]]).

:- begin_tests(crop_bbox).

test(bbox_basic) :-
    g4x4(G),
    cr_bbox(G, 0, bbox(1,1,2,2)).

test(bbox_3x3) :-
    g3x3(G),
    cr_bbox(G, 0, bbox(0,0,2,2)).

test(bbox_full) :-
    % All cells non-background.
    G = [[1,2],[3,4]],
    cr_bbox(G, 0, bbox(0,0,1,1)).

test(bbox_fails_all_bg, [fail]) :-
    G = [[0,0],[0,0]],
    cr_bbox(G, 0, _).

:- end_tests(crop_bbox).

:- begin_tests(crop_crop_bbox).

test(crop_bbox_basic) :-
    g4x4(G),
    cr_crop_bbox(G, 1, 1, 2, 2, Sub),
    Sub = [[1,2],[3,4]].

test(crop_bbox_full_row) :-
    G = [[1,2,3],[4,5,6],[7,8,9]],
    cr_crop_bbox(G, 0, 0, 2, 2, Sub),
    Sub = [[1,2,3],[4,5,6],[7,8,9]].

test(crop_bbox_single_cell) :-
    G = [[1,2,3],[4,5,6]],
    cr_crop_bbox(G, 1, 2, 1, 2, Sub),
    Sub = [[6]].

test(crop_bbox_single_row) :-
    g2x4(G),
    cr_crop_bbox(G, 0, 1, 0, 2, Sub),
    Sub = [[2,3]].

:- end_tests(crop_crop_bbox).

:- begin_tests(crop_crop_content).

test(content_basic) :-
    g4x4(G),
    cr_crop_content(G, 0, Cropped),
    Cropped = [[1,2],[3,4]].

test(content_no_border) :-
    G = [[1,2],[3,4]],
    cr_crop_content(G, 0, Cropped),
    Cropped = [[1,2],[3,4]].

test(content_asymmetric) :-
    G = [[0,0,0],[0,1,0],[0,0,0]],
    cr_crop_content(G, 0, Cropped),
    Cropped = [[1]].

test(content_top_border) :-
    G = [[0,0],[1,2],[3,4]],
    cr_crop_content(G, 0, Cropped),
    Cropped = [[1,2],[3,4]].

:- end_tests(crop_crop_content).

:- begin_tests(crop_pad).

test(pad_basic) :-
    G = [[1,2],[3,4]],
    cr_pad(G, 0, 1, Padded),
    Padded = [[0,0,0,0],[0,1,2,0],[0,3,4,0],[0,0,0,0]].

test(pad_zero) :-
    G = [[1,2],[3,4]],
    cr_pad(G, 0, 0, Padded),
    Padded = [[1,2],[3,4]].

test(pad_two) :-
    G = [[5]],
    cr_pad(G, 0, 2, Padded),
    Padded = [[0,0,0,0,0],[0,0,0,0,0],[0,0,5,0,0],[0,0,0,0,0],[0,0,0,0,0]].

:- end_tests(crop_pad).

:- begin_tests(crop_strip_border).

test(strip_basic) :-
    g4x4(G),
    cr_strip_border(G, 1, Inner),
    Inner = [[1,2],[3,4]].

test(strip_zero) :-
    G = [[1,2],[3,4]],
    cr_strip_border(G, 0, Inner),
    Inner = [[1,2],[3,4]].

test(strip_fails_too_large, [fail]) :-
    G = [[1,2],[3,4]],
    cr_strip_border(G, 2, _).

:- end_tests(crop_strip_border).

:- begin_tests(crop_split_h).

test(split_h_basic) :-
    G = [[1,2],[3,4],[5,6],[7,8]],
    cr_split_h(G, 2, Top, Bottom),
    Top = [[1,2],[3,4]],
    Bottom = [[5,6],[7,8]].

test(split_h_one) :-
    G = [[1,2],[3,4],[5,6]],
    cr_split_h(G, 1, Top, Bottom),
    Top = [[1,2]],
    Bottom = [[3,4],[5,6]].

test(split_h_last) :-
    G = [[1,2],[3,4],[5,6]],
    cr_split_h(G, 2, Top, Bottom),
    Top = [[1,2],[3,4]],
    Bottom = [[5,6]].

test(split_h_fails_zero, [fail]) :-
    G = [[1,2],[3,4]],
    cr_split_h(G, 0, _, _).

test(split_h_fails_full, [fail]) :-
    G = [[1,2],[3,4]],
    cr_split_h(G, 2, _, _).

:- end_tests(crop_split_h).

:- begin_tests(crop_split_v).

test(split_v_basic) :-
    G = [[1,2,3,4],[5,6,7,8]],
    cr_split_v(G, 2, Left, Right),
    Left = [[1,2],[5,6]],
    Right = [[3,4],[7,8]].

test(split_v_one) :-
    G = [[1,2,3],[4,5,6]],
    cr_split_v(G, 1, Left, Right),
    Left = [[1],[4]],
    Right = [[2,3],[5,6]].

test(split_v_fails_zero, [fail]) :-
    G = [[1,2],[3,4]],
    cr_split_v(G, 0, _, _).

test(split_v_fails_full, [fail]) :-
    G = [[1,2],[3,4]],
    cr_split_v(G, 2, _, _).

:- end_tests(crop_split_v).

:- begin_tests(crop_rows).

test(rows_basic) :-
    G = [[1,2],[3,4],[5,6],[7,8]],
    cr_rows(G, 1, 3, Sub),
    Sub = [[3,4],[5,6]].

test(rows_from_zero) :-
    G = [[1,2],[3,4],[5,6]],
    cr_rows(G, 0, 2, Sub),
    Sub = [[1,2],[3,4]].

test(rows_single) :-
    G = [[1,2],[3,4],[5,6]],
    cr_rows(G, 2, 3, Sub),
    Sub = [[5,6]].

test(rows_fails_out_of_range, [fail]) :-
    G = [[1,2],[3,4]],
    cr_rows(G, 1, 3, _).

:- end_tests(crop_rows).

:- begin_tests(crop_cols).

test(cols_basic) :-
    G = [[1,2,3,4],[5,6,7,8]],
    cr_cols(G, 1, 3, Sub),
    Sub = [[2,3],[6,7]].

test(cols_from_zero) :-
    G = [[1,2,3],[4,5,6]],
    cr_cols(G, 0, 2, Sub),
    Sub = [[1,2],[4,5]].

test(cols_single) :-
    G = [[1,2,3],[4,5,6]],
    cr_cols(G, 2, 3, Sub),
    Sub = [[3],[6]].

test(cols_fails_out_of_range, [fail]) :-
    G = [[1,2,3],[4,5,6]],
    cr_cols(G, 2, 4, _).

:- end_tests(crop_cols).

:- begin_tests(crop_stitch_h).

test(stitch_h_basic) :-
    Left = [[1,2],[3,4]],
    Right = [[5,6],[7,8]],
    cr_stitch_h(Left, Right, Joined),
    Joined = [[1,2,5,6],[3,4,7,8]].

test(stitch_h_asymmetric) :-
    Left = [[1],[2]],
    Right = [[3,4],[5,6]],
    cr_stitch_h(Left, Right, Joined),
    Joined = [[1,3,4],[2,5,6]].

test(stitch_h_inverse_split_v) :-
    G = [[1,2,3,4],[5,6,7,8]],
    cr_split_v(G, 2, Left, Right),
    cr_stitch_h(Left, Right, G).

:- end_tests(crop_stitch_h).

:- begin_tests(crop_stitch_v).

test(stitch_v_basic) :-
    Top = [[1,2],[3,4]],
    Bottom = [[5,6],[7,8]],
    cr_stitch_v(Top, Bottom, Joined),
    Joined = [[1,2],[3,4],[5,6],[7,8]].

test(stitch_v_inverse_split_h) :-
    G = [[1,2],[3,4],[5,6],[7,8]],
    cr_split_h(G, 2, Top, Bottom),
    cr_stitch_v(Top, Bottom, G).

:- end_tests(crop_stitch_v).

:- begin_tests(crop_embed).

test(embed_basic) :-
    Base = [[0,0,0],[0,0,0],[0,0,0]],
    Sub  = [[1,2],[3,4]],
    cr_embed(Base, Sub, 1, 1, Result),
    Result = [[0,0,0],[0,1,2],[0,3,4]].

test(embed_at_origin) :-
    Base = [[0,0,0],[0,0,0],[0,0,0]],
    Sub  = [[1,2],[3,4]],
    cr_embed(Base, Sub, 0, 0, Result),
    Result = [[1,2,0],[3,4,0],[0,0,0]].

test(embed_single_cell) :-
    Base = [[0,0,0],[0,0,0],[0,0,0]],
    Sub  = [[7]],
    cr_embed(Base, Sub, 1, 1, Result),
    Result = [[0,0,0],[0,7,0],[0,0,0]].

:- end_tests(crop_embed).

:- begin_tests(crop_center).

test(center_basic) :-
    G = [[1,2,3,4,5],[6,7,8,9,10],[11,12,13,14,15],[16,17,18,19,20],[21,22,23,24,25]],
    cr_center(G, 3, 3, Center),
    Center = [[7,8,9],[12,13,14],[17,18,19]].

test(center_1x1) :-
    G = [[1,2,3],[4,5,6],[7,8,9]],
    cr_center(G, 1, 1, Center),
    Center = [[5]].

test(center_exact_size) :-
    G = [[1,2],[3,4]],
    cr_center(G, 2, 2, Center),
    Center = [[1,2],[3,4]].

:- end_tests(crop_center).

:- begin_tests(crop_quadrants).

test(quadrants_2x2) :-
    G = [[1,2],[3,4]],
    cr_quadrants(G, Q1, Q2, Q3, Q4),
    Q1 = [[1]], Q2 = [[2]], Q3 = [[3]], Q4 = [[4]].

test(quadrants_4x4) :-
    G = [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]],
    cr_quadrants(G, Q1, Q2, Q3, Q4),
    Q1 = [[1,2],[5,6]],
    Q2 = [[3,4],[7,8]],
    Q3 = [[9,10],[13,14]],
    Q4 = [[11,12],[15,16]].

test(quadrants_fails_1x1, [fail]) :-
    G = [[1]],
    cr_quadrants(G, _, _, _, _).

:- end_tests(crop_quadrants).
