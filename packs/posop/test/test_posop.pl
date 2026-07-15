:- use_module('../prolog/posop.pl').
:- use_module(library(plunit)).

% Test fixtures: obj(Color, Cells) with distinct spatial positions.
%   top_left:  topmost row 0, leftmost col 0  (3 cells)
%   top_right: topmost row 0, leftmost col 3  (3 cells)
%   mid_left:  topmost row 2, leftmost col 0  (2 cells)
%   mid_right: topmost row 2, leftmost col 3  (1 cell)
%   bottom:    topmost row 4, leftmost col 0  (3 cells)
top_left(obj(red,   [r(0,0), r(0,1), r(1,0)])).
top_right(obj(blue,  [r(0,3), r(0,4), r(1,4)])).
mid_left(obj(green, [r(2,0), r(2,1)])).
mid_right(obj(yellow,[r(2,3)])).
bottom(obj(white,  [r(4,0), r(4,1), r(4,2)])).

% scene5: all five objects in scene order.
scene5(Objs) :-
    top_left(TL), top_right(TR), mid_left(ML), mid_right(MR), bottom(B),
    Objs = [TL, TR, ML, MR, B].

% row_tied: two objects with the same topmost row (0), for tie-break tests.
row_tied(Objs) :- top_left(TL), top_right(TR), Objs = [TL, TR].

% col_tied: three objects with the same leftmost col (0).
col_tied(Objs) :- top_left(TL), mid_left(ML), bottom(B), Objs = [TL, ML, B].

:- begin_tests(posop_row_of).

test(top_left_row_0) :- top_left(O), posop_row_of(O, 0).
test(top_right_row_0) :- top_right(O), posop_row_of(O, 0).
test(mid_left_row_2) :- mid_left(O), posop_row_of(O, 2).
test(mid_right_row_2) :- mid_right(O), posop_row_of(O, 2).
test(bottom_row_4) :- bottom(O), posop_row_of(O, 4).

:- end_tests(posop_row_of).

:- begin_tests(posop_col_of).

test(top_left_col_0) :- top_left(O), posop_col_of(O, 0).
test(top_right_col_3) :- top_right(O), posop_col_of(O, 3).
test(mid_left_col_0) :- mid_left(O), posop_col_of(O, 0).
test(mid_right_col_3) :- mid_right(O), posop_col_of(O, 3).
test(bottom_col_0) :- bottom(O), posop_col_of(O, 0).

:- end_tests(posop_col_of).

:- begin_tests(posop_row_rank).

% scene5 sorted by topmost row: [TL(r0), TR(r0), ML(r2), MR(r2), B(r4)].
% Ties (r0 and r2) break by input order (stable keysort).
test(top_left_rank_1) :-
    scene5(Objs), top_left(TL), posop_row_rank(Objs, TL, 1).
test(top_right_rank_2) :-
    scene5(Objs), top_right(TR), posop_row_rank(Objs, TR, 2).
test(mid_left_rank_3) :-
    scene5(Objs), mid_left(ML), posop_row_rank(Objs, ML, 3).
test(mid_right_rank_4) :-
    scene5(Objs), mid_right(MR), posop_row_rank(Objs, MR, 4).
test(bottom_rank_5) :-
    scene5(Objs), bottom(B), posop_row_rank(Objs, B, 5).

:- end_tests(posop_row_rank).

:- begin_tests(posop_col_rank).

% scene5 sorted by leftmost col: [TL(c0), ML(c0), B(c0), TR(c3), MR(c3)].
% Input order within each col group (c0: TL before ML before B; c3: TR before MR).
test(top_left_col_rank_1) :-
    scene5(Objs), top_left(TL), posop_col_rank(Objs, TL, 1).
test(mid_left_col_rank_2) :-
    scene5(Objs), mid_left(ML), posop_col_rank(Objs, ML, 2).
test(bottom_col_rank_3) :-
    scene5(Objs), bottom(B), posop_col_rank(Objs, B, 3).
test(top_right_col_rank_4) :-
    scene5(Objs), top_right(TR), posop_col_rank(Objs, TR, 4).
test(mid_right_col_rank_5) :-
    scene5(Objs), mid_right(MR), posop_col_rank(Objs, MR, 5).

:- end_tests(posop_col_rank).

:- begin_tests(posop_reading_rank).

% Reading order (row then col): TL(0,0), TR(0,3), ML(2,0), MR(2,3), B(4,0).
test(top_left_reading_rank_1) :-
    scene5(Objs), top_left(TL), posop_reading_rank(Objs, TL, 1).
test(top_right_reading_rank_2) :-
    scene5(Objs), top_right(TR), posop_reading_rank(Objs, TR, 2).
test(mid_left_reading_rank_3) :-
    scene5(Objs), mid_left(ML), posop_reading_rank(Objs, ML, 3).
test(mid_right_reading_rank_4) :-
    scene5(Objs), mid_right(MR), posop_reading_rank(Objs, MR, 4).
test(bottom_reading_rank_5) :-
    scene5(Objs), bottom(B), posop_reading_rank(Objs, B, 5).

:- end_tests(posop_reading_rank).

:- begin_tests(posop_assign_by_row).

% Sort by topmost row: [TL(r0), TR(r0), ML(r2), MR(r2), B(r4)].
% Assign colors [a,b,c,d,e] in that order.
test(five_colors) :-
    scene5(Objs),
    posop_assign_by_row(Objs, [a,b,c,d,e], Result),
    Result = [obj(a,_), obj(b,_), obj(c,_), obj(d,_), obj(e,_)].

test(truncates_at_colors) :-
    % Only 3 colors -> only first 3 sorted objects get colors.
    scene5(Objs),
    posop_assign_by_row(Objs, [x,y,z], Result),
    length(Result, 3),
    Result = [obj(x,_), obj(y,_), obj(z,_)].

test(truncates_at_objects) :-
    % Only 2 objects but 5 colors -> only 2 results.
    top_left(TL), mid_left(ML),
    posop_assign_by_row([TL, ML], [a,b,c,d,e], Result),
    length(Result, 2).

test(empty_objs) :-
    posop_assign_by_row([], [a,b,c], []).

test(empty_colors) :-
    scene5(Objs), posop_assign_by_row(Objs, [], []).

:- end_tests(posop_assign_by_row).

:- begin_tests(posop_assign_by_col).

% Sort by leftmost col: [TL(c0), ML(c0), B(c0), TR(c3), MR(c3)].
test(five_colors) :-
    scene5(Objs),
    posop_assign_by_col(Objs, [a,b,c,d,e], Result),
    % Verify: first result has col 0 (TL), second has col 0 (ML), etc.
    length(Result, 5),
    Result = [obj(a,TLC)|_],
    top_left(obj(_, TLC)).

test(truncates_at_colors) :-
    scene5(Objs),
    posop_assign_by_col(Objs, [p,q], Result),
    length(Result, 2).

test(empty_objs) :-
    posop_assign_by_col([], [a,b], []).

test(single_object) :-
    top_left(TL),
    posop_assign_by_col([TL], [z], [obj(z,_)]).

:- end_tests(posop_assign_by_col).

:- begin_tests(posop_assign_reading).

% Reading order: TL(0,0), TR(0,3), ML(2,0), MR(2,3), B(4,0).
test(five_colors_reading) :-
    scene5(Objs),
    posop_assign_reading(Objs, [a,b,c,d,e], Result),
    Result = [obj(a,_), obj(b,_), obj(c,_), obj(d,_), obj(e,_)].

test(empty_objs) :-
    posop_assign_reading([], [a,b,c], []).

test(single_object) :-
    mid_right(MR),
    posop_assign_reading([MR], [gold], [obj(gold,_)]).

:- end_tests(posop_assign_reading).

:- begin_tests(posop_above_row).

% Objects with topmost row < 2: TL(r0), TR(r0).
test(above_row_2) :-
    scene5(Objs), top_left(TL), top_right(TR),
    posop_above_row(Objs, 2, [TL, TR]).

% Objects with topmost row < 0: none.
test(above_row_0_empty) :-
    scene5(Objs), posop_above_row(Objs, 0, []).

% Objects with topmost row < 5: all five.
test(above_row_5_all) :-
    scene5(Objs), posop_above_row(Objs, 5, Objs).

test(empty_scene) :-
    posop_above_row([], 3, []).

:- end_tests(posop_above_row).

:- begin_tests(posop_from_row).

% Objects with topmost row >= 2: ML(r2), MR(r2), B(r4).
test(from_row_2) :-
    scene5(Objs), mid_left(ML), mid_right(MR), bottom(B),
    posop_from_row(Objs, 2, [ML, MR, B]).

% Objects with topmost row >= 0: all five.
test(from_row_0_all) :-
    scene5(Objs), posop_from_row(Objs, 0, Objs).

% Objects with topmost row >= 5: none.
test(from_row_5_empty) :-
    scene5(Objs), posop_from_row(Objs, 5, []).

test(empty_scene) :-
    posop_from_row([], 1, []).

:- end_tests(posop_from_row).

:- begin_tests(posop_left_of).

% Objects with leftmost col < 3: TL(c0), ML(c0), B(c0).
test(left_of_col_3) :-
    scene5(Objs), top_left(TL), mid_left(ML), bottom(B),
    posop_left_of(Objs, 3, [TL, ML, B]).

% Objects with leftmost col < 0: none.
test(left_of_col_0_empty) :-
    scene5(Objs), posop_left_of(Objs, 0, []).

test(empty_scene) :-
    posop_left_of([], 2, []).

:- end_tests(posop_left_of).

:- begin_tests(posop_from_col).

% Objects with leftmost col >= 3: TR(c3), MR(c3).
test(from_col_3) :-
    scene5(Objs), top_right(TR), mid_right(MR),
    posop_from_col(Objs, 3, [TR, MR]).

% Objects with leftmost col >= 0: all five.
test(from_col_0_all) :-
    scene5(Objs), posop_from_col(Objs, 0, Objs).

test(empty_scene) :-
    posop_from_col([], 1, []).

:- end_tests(posop_from_col).

:- begin_tests(posop_in_row_band).

% Row band [0, 2] includes TL(r0), TR(r0), ML(r2), MR(r2).
test(band_0_to_2) :-
    scene5(Objs), top_left(TL), top_right(TR), mid_left(ML), mid_right(MR),
    posop_in_row_band(Objs, 0, 2, [TL, TR, ML, MR]).

% Row band [2, 4] includes ML(r2), MR(r2), B(r4).
test(band_2_to_4) :-
    scene5(Objs), mid_left(ML), mid_right(MR), bottom(B),
    posop_in_row_band(Objs, 2, 4, [ML, MR, B]).

% Row band [3, 3]: only objects with topmost row exactly 3 -> none.
test(band_3_to_3_empty) :-
    scene5(Objs), posop_in_row_band(Objs, 3, 3, []).

test(empty_scene) :-
    posop_in_row_band([], 0, 5, []).

:- end_tests(posop_in_row_band).

:- begin_tests(posop_in_col_band).

% Col band [0, 0]: TL(c0), ML(c0), B(c0).
test(band_0_to_0) :-
    scene5(Objs), top_left(TL), mid_left(ML), bottom(B),
    posop_in_col_band(Objs, 0, 0, [TL, ML, B]).

% Col band [3, 4]: TR(c3), MR(c3).
test(band_3_to_4) :-
    scene5(Objs), top_right(TR), mid_right(MR),
    posop_in_col_band(Objs, 3, 4, [TR, MR]).

test(empty_scene) :-
    posop_in_col_band([], 0, 5, []).

:- end_tests(posop_in_col_band).
