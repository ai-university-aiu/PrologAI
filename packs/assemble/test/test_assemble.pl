% test_assemble.pl - PLUnit tests for the assemble pack (Layer 91: as_* predicates).
:- use_module('../prolog/assemble').

% Tests for as_hcat/2

:- begin_tests(as_hcat).

test(two_2x2) :-
    as_hcat([[[1,2],[3,4]], [[5,6],[7,8]]], R),
    R = [[1,2,5,6],[3,4,7,8]].

test(three_2x1) :-
    as_hcat([[[1],[2]], [[3],[4]], [[5],[6]]], R),
    R = [[1,3,5],[2,4,6]].

test(single_grid) :-
    as_hcat([[[1,2],[3,4]]], R),
    R = [[1,2],[3,4]].

:- end_tests(as_hcat).

% Tests for as_vcat/2

:- begin_tests(as_vcat).

test(two_2x2) :-
    as_vcat([[[1,2],[3,4]], [[5,6],[7,8]]], R),
    R = [[1,2],[3,4],[5,6],[7,8]].

test(three_1x2) :-
    as_vcat([[[1,2]], [[3,4]], [[5,6]]], R),
    R = [[1,2],[3,4],[5,6]].

test(single_grid) :-
    as_vcat([[[9,0]]], R),
    R = [[9,0]].

:- end_tests(as_vcat).

% Tests for as_grid_of/2

:- begin_tests(as_grid_of).

test(two_by_two_matrix) :-
    as_grid_of([[[[1]],[[2]]],[[[3]],[[4]]]], R),
    R = [[1,2],[3,4]].

test(one_row_matrix) :-
    as_grid_of([[[[1,2],[3,4]], [[5,6],[7,8]]]], R),
    R = [[1,2,5,6],[3,4,7,8]].

test(two_row_matrix) :-
    as_grid_of([[[[1,2]]], [[[3,4]]]], R),
    R = [[1,2],[3,4]].

:- end_tests(as_grid_of).

% Tests for as_downscale/3

:- begin_tests(as_downscale).

test(uniform_2x2_k2) :-
    as_downscale([[1,1],[1,1]], 2, R),
    R = [[1]].

test(quadrant_4x4_k2) :-
    as_downscale([[1,1,2,2],[1,1,2,2],[3,3,4,4],[3,3,4,4]], 2, R),
    R = [[1,2],[3,4]].

test(two_block_2x4_k2) :-
    as_downscale([[1,1,2,2],[1,1,2,2]], 2, R),
    R = [[1,2]].

:- end_tests(as_downscale).

% Tests for as_border/4

:- begin_tests(as_border).

test(single_w1_color0) :-
    as_border([[5]], 1, 0, R),
    R = [[0,0,0],[0,5,0],[0,0,0]].

test(medium_w1_color9) :-
    as_border([[1,2],[3,4]], 1, 9, R),
    R = [[9,9,9,9],[9,1,2,9],[9,3,4,9],[9,9,9,9]].

test(single_w2_color1) :-
    as_border([[5]], 2, 1, R),
    R = [[1,1,1,1,1],[1,1,1,1,1],[1,1,5,1,1],[1,1,1,1,1],[1,1,1,1,1]].

:- end_tests(as_border).

% Tests for as_center_in/5

:- begin_tests(as_center_in).

test(single_in_three) :-
    as_center_in([[5]], 3, 3, 0, R),
    R = [[0,0,0],[0,5,0],[0,0,0]].

test(medium_in_large) :-
    as_center_in([[1,2],[3,4]], 4, 4, 0, R),
    R = [[0,0,0,0],[0,1,2,0],[0,3,4,0],[0,0,0,0]].

test(single_in_xlarge) :-
    as_center_in([[7]], 5, 5, 0, R),
    R = [[0,0,0,0,0],[0,0,0,0,0],[0,0,7,0,0],[0,0,0,0,0],[0,0,0,0,0]].

:- end_tests(as_center_in).

% Tests for as_quarter/3

:- begin_tests(as_quarter).

test(tl_4x4) :-
    as_quarter([[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]], tl, R),
    R = [[1,2],[5,6]].

test(br_4x4) :-
    as_quarter([[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]], br, R),
    R = [[11,12],[15,16]].

test(tr_4x4) :-
    as_quarter([[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]], tr, R),
    R = [[3,4],[7,8]].

:- end_tests(as_quarter).

% Tests for as_flip_h_cat/2

:- begin_tests(as_flip_h_cat).

test(medium_mirror_h) :-
    as_flip_h_cat([[1,2],[3,4]], R),
    R = [[1,2,2,1],[3,4,4,3]].

test(single_row_mirror_h) :-
    as_flip_h_cat([[1,2,3]], R),
    R = [[1,2,3,3,2,1]].

test(single_col_mirror_h) :-
    as_flip_h_cat([[1],[2]], R),
    R = [[1,1],[2,2]].

:- end_tests(as_flip_h_cat).

% Tests for as_flip_v_cat/2

:- begin_tests(as_flip_v_cat).

test(medium_mirror_v) :-
    as_flip_v_cat([[1,2],[3,4]], R),
    R = [[1,2],[3,4],[3,4],[1,2]].

test(single_row_mirror_v) :-
    as_flip_v_cat([[1,2,3]], R),
    R = [[1,2,3],[1,2,3]].

test(three_row_mirror_v) :-
    as_flip_v_cat([[1],[2],[3]], R),
    R = [[1],[2],[3],[3],[2],[1]].

:- end_tests(as_flip_v_cat).

% Tests for as_zip_h/3

:- begin_tests(as_zip_h).

test(two_2x2) :-
    as_zip_h([[1,2],[3,4]], [[5,6],[7,8]], R),
    R = [[1,5,2,6],[3,7,4,8]].

test(two_1x2) :-
    as_zip_h([[1,2]], [[3,4]], R),
    R = [[1,3,2,4]].

test(two_2x1) :-
    as_zip_h([[1],[2]], [[3],[4]], R),
    R = [[1,3],[2,4]].

:- end_tests(as_zip_h).

% Tests for as_zip_v/3

:- begin_tests(as_zip_v).

test(two_2x2) :-
    as_zip_v([[1,2],[3,4]], [[5,6],[7,8]], R),
    R = [[1,2],[5,6],[3,4],[7,8]].

test(two_3x1) :-
    as_zip_v([[1],[2],[3]], [[4],[5],[6]], R),
    R = [[1],[4],[2],[5],[3],[6]].

test(two_1x1) :-
    as_zip_v([[1]], [[2]], R),
    R = [[1],[2]].

:- end_tests(as_zip_v).

% Tests for as_paste/5

:- begin_tests(as_paste).

test(paste_1x1_center) :-
    as_paste([[0,0,0],[0,0,0],[0,0,0]], [[5]], 1, 1, R),
    R = [[0,0,0],[0,5,0],[0,0,0]].

test(paste_2x2_origin) :-
    as_paste([[0,0,0],[0,0,0],[0,0,0]], [[1,2],[3,4]], 0, 0, R),
    R = [[1,2,0],[3,4,0],[0,0,0]].

test(paste_1x1_corner) :-
    as_paste([[0,0,0],[0,0,0],[0,0,0]], [[5]], 2, 2, R),
    R = [[0,0,0],[0,0,0],[0,0,5]].

:- end_tests(as_paste).

% Tests for as_mask_fill/4

:- begin_tests(as_mask_fill).

test(all_zero_mask_unchanged) :-
    as_mask_fill([[1,2],[3,4]], [[0,0],[0,0]], 9, R),
    R = [[1,2],[3,4]].

test(all_nonzero_mask_all_fill) :-
    as_mask_fill([[1,2],[3,4]], [[1,1],[1,1]], 9, R),
    R = [[9,9],[9,9]].

test(partial_mask) :-
    as_mask_fill([[1,2],[3,4]], [[0,1],[1,0]], 9, R),
    R = [[1,9],[9,4]].

:- end_tests(as_mask_fill).

% Tests for as_crop_to/5

:- begin_tests(as_crop_to).

test(crop_4x4_to_2x2) :-
    as_crop_to([[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]], 2, 2, 0, R),
    R = [[1,2],[5,6]].

test(pad_2x2_to_4x4) :-
    as_crop_to([[1,2],[3,4]], 4, 4, 0, R),
    R = [[1,2,0,0],[3,4,0,0],[0,0,0,0],[0,0,0,0]].

test(exact_size_unchanged) :-
    as_crop_to([[1,2],[3,4]], 2, 2, 0, R),
    R = [[1,2],[3,4]].

:- end_tests(as_crop_to).
