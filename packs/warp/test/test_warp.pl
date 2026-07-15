% test_warp.pl - Acceptance tests for the warp pack (Layer 145).
% 42 tests covering all 14 exported predicates.
:- use_module('../prolog/warp.pl').

:- begin_tests(warp).

% warp_shift_row tests.

% Test 1: shift row 0 right by 1; left cell fills with Bg.
test(shift_row_right_1) :-
    warp_shift_row([[1,2,3],[4,5,6]], 0, 1, 0, Out),
    Out == [[0,1,2],[4,5,6]].

% Test 2: shift row 0 left by 1 (N=-1); right cell fills with Bg.
test(shift_row_left_1) :-
    warp_shift_row([[1,2,3],[4,5,6]], 0, -1, 0, Out),
    Out == [[2,3,0],[4,5,6]].

% Test 3: shift row 0 by 0 leaves grid unchanged.
test(shift_row_identity) :-
    warp_shift_row([[1,2,3],[4,5,6]], 0, 0, 0, Out),
    Out == [[1,2,3],[4,5,6]].

% Test 4: shift row 0 right by W (full width) produces all Bg in that row.
test(shift_row_full_width) :-
    warp_shift_row([[1,2,3],[4,5,6]], 0, 3, 0, Out),
    Out == [[0,0,0],[4,5,6]].

% Test 5: shift middle row (row 1) right by 1; rows 0 and 2 unchanged.
test(shift_row_middle) :-
    warp_shift_row([[1,2,3],[4,5,6],[7,8,9]], 1, 1, 0, Out),
    Out == [[1,2,3],[0,4,5],[7,8,9]].

% warp_shift_col tests.

% Test 6: shift column 0 down by 1; top cell fills with Bg.
test(shift_col_down_1) :-
    warp_shift_col([[1,2],[3,4],[5,6]], 0, 1, 0, Out),
    Out == [[0,2],[1,4],[3,6]].

% Test 7: shift column 0 up by 1 (N=-1); bottom cell fills with Bg.
test(shift_col_up_1) :-
    warp_shift_col([[1,2],[3,4],[5,6]], 0, -1, 0, Out),
    Out == [[3,2],[5,4],[0,6]].

% Test 8: shift column 1 by 0 leaves grid unchanged.
test(shift_col_identity) :-
    warp_shift_col([[1,2],[3,4],[5,6]], 1, 0, 0, Out),
    Out == [[1,2],[3,4],[5,6]].

% Test 9: shift column 0 down by H (full height) produces all Bg in that column.
test(shift_col_full_height) :-
    warp_shift_col([[1,2],[3,4],[5,6]], 0, 3, 0, Out),
    Out == [[0,2],[0,4],[0,6]].

% warp_shear_h tests.

% Test 10: shear horizontal step=1 on 3x3 grid.
test(shear_h_step1) :-
    warp_shear_h([[a,b,c],[d,e,f],[g,h,i]], 1, 0, Out),
    Out == [[a,b,c],[0,d,e],[0,0,g]].

% Test 11: shear horizontal step=-1 on 3x3 grid (left-going shear).
test(shear_h_step_neg1) :-
    warp_shear_h([[a,b,c],[d,e,f],[g,h,i]], -1, 0, Out),
    Out == [[a,b,c],[e,f,0],[i,0,0]].

% Test 12: shear horizontal step=0 is identity.
test(shear_h_step0) :-
    warp_shear_h([[a,b,c],[d,e,f]], 0, 0, Out),
    Out == [[a,b,c],[d,e,f]].

% Test 13: shear horizontal step=2; row 2 shifts by 4 and loses all content.
test(shear_h_step2) :-
    warp_shear_h([[a,b,c,d],[e,f,g,h],[i,j,k,l]], 2, 0, Out),
    Out == [[a,b,c,d],[0,0,e,f],[0,0,0,0]].

% warp_shear_v tests.

% Test 14: shear vertical step=1 on 3x3 grid.
test(shear_v_step1) :-
    warp_shear_v([[a,b,c],[d,e,f],[g,h,i]], 1, 0, Out),
    Out == [[a,0,0],[d,b,0],[g,e,c]].

% Test 15: shear vertical step=0 is identity.
test(shear_v_step0) :-
    warp_shear_v([[a,b,c],[d,e,f],[g,h,i]], 0, 0, Out),
    Out == [[a,b,c],[d,e,f],[g,h,i]].

% Test 16: shear vertical step=-1 (upward-going shear).
test(shear_v_step_neg1) :-
    warp_shear_v([[a,b,c],[d,e,f],[g,h,i]], -1, 0, Out),
    Out == [[a,e,i],[d,h,0],[g,0,0]].

% warp_unshear_h tests.

% Test 17: unshear_h with step=1 undoes shear_h step=1 (lossless grid).
test(unshear_h_round_trip) :-
    Grid = [[a,b,c,0],[d,e,0,0],[g,0,0,0]],
    warp_shear_h(Grid, 1, 0, Sh),
    warp_unshear_h(Sh, 1, 0, Back),
    Back == Grid.

% Test 18: unshear_h step=2 undoes shear_h step=2 (lossless grid).
test(unshear_h_step2_round_trip) :-
    Grid = [[a,b,c,d,e],[f,0,0,0,0],[g,0,0,0,0]],
    warp_shear_h(Grid, 2, 0, Sh),
    warp_unshear_h(Sh, 2, 0, Back),
    Back == Grid.

% warp_unshear_v tests.

% Test 19: unshear_v with step=1 undoes shear_v step=1 (lossless grid).
test(unshear_v_round_trip) :-
    Grid = [[a,b,c],[d,e,0],[g,0,0]],
    warp_shear_v(Grid, 1, 0, Sh),
    warp_unshear_v(Sh, 1, 0, Back),
    Back == Grid.

% warp_cyclic_h tests.

% Test 20: cyclic shift all rows right by 1.
test(cyclic_h_shift1) :-
    warp_cyclic_h([[1,2,3],[4,5,6]], 1, Out),
    Out == [[3,1,2],[6,4,5]].

% Test 21: cyclic shift by W = identity (wrap returns to start).
test(cyclic_h_shift_w) :-
    warp_cyclic_h([[1,2,3],[4,5,6]], 3, Out),
    Out == [[1,2,3],[4,5,6]].

% Test 22: cyclic shift by 0 = identity.
test(cyclic_h_shift0) :-
    warp_cyclic_h([[1,2,3],[4,5,6]], 0, Out),
    Out == [[1,2,3],[4,5,6]].

% Test 23: cyclic shift left by 1 (N=-1); equivalent to right by W-1=2.
test(cyclic_h_shift_neg1) :-
    warp_cyclic_h([[1,2,3]], -1, Out),
    Out == [[2,3,1]].

% warp_cyclic_v tests.

% Test 24: cyclic shift all columns down by 1.
test(cyclic_v_shift1) :-
    warp_cyclic_v([[1,2],[3,4],[5,6]], 1, Out),
    Out == [[5,6],[1,2],[3,4]].

% Test 25: cyclic shift by H = identity (wrap returns to start).
test(cyclic_v_shift_h) :-
    warp_cyclic_v([[1,2],[3,4],[5,6]], 3, Out),
    Out == [[1,2],[3,4],[5,6]].

% Test 26: cyclic shift by 0 = identity.
test(cyclic_v_shift0) :-
    warp_cyclic_v([[1,2],[3,4],[5,6]], 0, Out),
    Out == [[1,2],[3,4],[5,6]].

% warp_cyclic_shear_h tests.

% Test 27: cyclic shear horizontal step=1; row I wraps right by I.
test(cyclic_shear_h_step1) :-
    warp_cyclic_shear_h([[1,2,3],[4,5,6],[7,8,9]], 1, Out),
    Out == [[1,2,3],[6,4,5],[8,9,7]].

% Test 28: cyclic shear horizontal step=0 = identity.
test(cyclic_shear_h_step0) :-
    warp_cyclic_shear_h([[1,2,3],[4,5,6]], 0, Out),
    Out == [[1,2,3],[4,5,6]].

% warp_cyclic_shear_v tests.

% Test 29: cyclic shear vertical step=1; column J wraps down by J.
test(cyclic_shear_v_step1) :-
    warp_cyclic_shear_v([[1,2,3],[4,5,6],[7,8,9]], 1, Out),
    Out == [[1,8,6],[4,2,9],[7,5,3]].

% Test 30: cyclic shear vertical step=0 = identity.
test(cyclic_shear_v_step0) :-
    warp_cyclic_shear_v([[1,2,3],[4,5,6]], 0, Out),
    Out == [[1,2,3],[4,5,6]].

% warp_skew_offsets tests.

% Test 31: offsets [0,1,2] equivalent to shear_h step=1.
test(skew_offsets_shear_equiv) :-
    Grid = [[a,b,c],[d,e,f],[g,h,i]],
    warp_skew_offsets(Grid, [0,1,2], 0, Out),
    warp_shear_h(Grid, 1, 0, Expected),
    Out == Expected.

% Test 32: all-zero offsets = identity.
test(skew_offsets_all_zero) :-
    warp_skew_offsets([[a,b,c],[d,e,f]], [0,0], 0, Out),
    Out == [[a,b,c],[d,e,f]].

% Test 33: negative offsets shift rows left.
test(skew_offsets_negative) :-
    warp_skew_offsets([[a,b,c],[d,e,f]], [0,-1], 0, Out),
    Out == [[a,b,c],[e,f,0]].

% Test 34: offsets [0,2,4] equals shear_h step=2.
test(skew_offsets_step2_equiv) :-
    Grid = [[a,b,c,d],[e,f,g,h],[i,j,k,l]],
    warp_skew_offsets(Grid, [0,2,4], 0, Out),
    warp_shear_h(Grid, 2, 0, Expected),
    Out == Expected.

% warp_transpose_anti tests.

% Test 35: anti-diagonal transpose of 2x2 grid.
test(transpose_anti_2x2) :-
    warp_transpose_anti([[a,b],[c,d]], Out),
    Out == [[d,b],[c,a]].

% Test 36: anti-diagonal transpose of 3x3 grid.
test(transpose_anti_3x3) :-
    warp_transpose_anti([[1,2,3],[4,5,6],[7,8,9]], Out),
    Out == [[9,6,3],[8,5,2],[7,4,1]].

% Test 37: anti-diagonal transpose of non-square 2x3 grid; result is 3x2.
test(transpose_anti_2x3) :-
    warp_transpose_anti([[a,b,c],[d,e,f]], Out),
    Out == [[f,c],[e,b],[d,a]].

% Test 38: applying anti-diagonal transpose twice to a square grid returns the original.
test(transpose_anti_involution) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    warp_transpose_anti(Grid, Temp),
    warp_transpose_anti(Temp, Back),
    Back == Grid.

% warp_find_shear_h tests.

% Test 39: find_shear_h identifies step=1 from a known shear result.
test(find_shear_h_step1) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    warp_shear_h(Grid, 1, 0, Sheared),
    warp_find_shear_h(Grid, Sheared, 0, Step),
    Step == 1.

% Test 40: find_shear_h finds step=0 when grids are identical.
test(find_shear_h_step0) :-
    Grid = [[1,2],[3,4]],
    warp_find_shear_h(Grid, Grid, 0, Step),
    Step == 0.

% Test 41: find_shear_h identifies step=-1 from a known left-going shear result.
test(find_shear_h_step_neg1) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    warp_shear_h(Grid, -1, 0, Sheared),
    warp_find_shear_h(Grid, Sheared, 0, Step),
    Step == -1.

% warp_find_shear_v tests.

% Test 42: find_shear_v identifies step=1 from a known vertical shear result.
test(find_shear_v_step1) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    warp_shear_v(Grid, 1, 0, Sheared),
    warp_find_shear_v(Grid, Sheared, 0, Step),
    Step == 1.

:- end_tests(warp).
