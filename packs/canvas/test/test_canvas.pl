:- use_module('../prolog/canvas').

% Standard test objects used across multiple tests.
% Dot  = single red cell at r(0,0)
% Hbar = blue horizontal bar at r(1,0)-r(1,1)-r(1,2)
% Vbar = green vertical bar at r(0,2)-r(1,2)-r(2,2)
% Rect = yellow 2x2 block at r(2,0)-r(2,1)-r(3,0)-r(3,1)
% L    = purple L-shape at r(0,0)-r(1,0)-r(1,1)

dot(obj(r, [r(0,0)])).
hbar(obj(b, [r(1,0),r(1,1),r(1,2)])).
vbar(obj(g, [r(0,2),r(1,2),r(2,2)])).
rect(obj(y, [r(2,0),r(2,1),r(3,0),r(3,1)])).
l_shape(obj(p, [r(0,0),r(1,0),r(1,1)])).

% Standard 3x3 blank grid (background = 0).
blank3x3([[0,0,0],[0,0,0],[0,0,0]]).

% Standard 4x3 grid with one red cell painted.
grid_with_dot([[r,0,0],[0,0,0],[0,0,0],[0,0,0]]).

:- begin_tests(canvas).

% canvas_blank/4 tests
test(blank_3x3) :-
    canvas_blank(3, 3, 0, G),
    G = [[0,0,0],[0,0,0],[0,0,0]].

test(blank_1x1) :-
    canvas_blank(1, 1, 9, G),
    G = [[9]].

test(blank_2x4) :-
    canvas_blank(2, 4, x, G),
    G = [[x,x,x,x],[x,x,x,x]].

% canvas_size/3 tests
test(size_3x3) :-
    blank3x3(G),
    canvas_size(G, 3, 3).

test(size_2x4) :-
    canvas_blank(2, 4, 0, G),
    canvas_size(G, 2, 4).

test(size_1x1) :-
    canvas_blank(1, 1, 0, G),
    canvas_size(G, 1, 1).

% canvas_paint/3 tests
test(paint_dot) :-
    canvas_blank(3, 3, 0, G0),
    dot(Dot),
    canvas_paint(G0, Dot, G1),
    G1 = [[r,0,0],[0,0,0],[0,0,0]].

test(paint_hbar) :-
    canvas_blank(3, 3, 0, G0),
    hbar(Hbar),
    canvas_paint(G0, Hbar, G1),
    G1 = [[0,0,0],[b,b,b],[0,0,0]].

test(paint_preserves_other_cells) :-
    canvas_blank(3, 3, 0, G0),
    dot(Dot),
    canvas_paint(G0, Dot, G1),
    hbar(Hbar),
    canvas_paint(G1, Hbar, G2),
    nth0(0, G2, Row0),
    nth0(0, Row0, r),   % dot still there
    nth0(1, G2, Row1),
    Row1 = [b,b,b].     % hbar painted

% canvas_paint_all/3 tests
test(paint_all_two_objs) :-
    canvas_blank(3, 3, 0, G0),
    dot(Dot), hbar(Hbar),
    canvas_paint_all(G0, [Dot, Hbar], G1),
    nth0(0, G1, [r,0,0]),
    nth0(1, G1, [b,b,b]).

test(paint_all_empty_list) :-
    canvas_blank(3, 3, 0, G0),
    canvas_paint_all(G0, [], G0).

test(paint_all_later_overwrites) :-
    % Paint dot first (r at r(0,0)), then paint obj that covers r(0,0) in blue.
    canvas_blank(3, 3, 0, G0),
    dot(Dot),
    Over = obj(b, [r(0,0)]),
    canvas_paint_all(G0, [Dot, Over], G1),
    nth0(0, G1, Row0),
    nth0(0, Row0, b).

% canvas_paint_at/5 tests
test(paint_at_offset_1_1) :-
    canvas_blank(4, 4, 0, G0),
    dot(Dot),
    canvas_paint_at(G0, Dot, 1, 1, G1),
    % dot at r(0,0) moved to r(1,1)
    nth0(1, G1, Row1),
    nth0(1, Row1, r).

test(paint_at_zero_offset) :-
    canvas_blank(3, 3, 0, G0),
    dot(Dot),
    canvas_paint_at(G0, Dot, 0, 0, G1),
    canvas_paint(G0, Dot, G2),
    G1 = G2.

test(paint_at_negative_offset) :-
    % Paint a 3x3 object shifted up by 1 (DR=-1); top row goes out of bounds (no crash).
    canvas_blank(3, 3, 0, G0),
    Obj = obj(5, [r(1,0),r(1,1),r(2,0)]),
    canvas_paint_at(G0, Obj, -1, 0, G1),
    % r(1,0) -> r(0,0) visible; r(1,1) -> r(0,1) visible; r(2,0) -> r(1,0) visible.
    % r(0,0) with value before -1 shift would be r(-1,0) which is outside; but the
    % original cells are already at row 1 and 2 so shift -1 puts them at 0 and 1.
    nth0(0, G1, Row0),
    nth0(0, Row0, 5).

% canvas_paint_clip/3 tests
test(paint_clip_all_in_bounds) :-
    canvas_blank(3, 3, 0, G0),
    dot(Dot),
    canvas_paint_clip(G0, Dot, G1),
    canvas_paint(G0, Dot, G2),
    G1 = G2.

test(paint_clip_out_of_bounds_skipped) :-
    % Object with one in-bounds and one out-of-bounds cell.
    canvas_blank(3, 3, 0, G0),
    Obj = obj(9, [r(0,0), r(5,5)]),
    canvas_paint_clip(G0, Obj, G1),
    % r(0,0) is painted, r(5,5) is silently dropped.
    nth0(0, G1, Row0),
    nth0(0, Row0, 9),
    % Grid unchanged beyond row 0.
    nth0(1, G1, [0,0,0]).

test(paint_clip_all_out_of_bounds) :-
    canvas_blank(2, 2, 0, G0),
    Obj = obj(7, [r(5,5), r(6,6)]),
    canvas_paint_clip(G0, Obj, G1),
    G1 = G0.

% canvas_paint_bg/4 tests
test(paint_bg_paints_on_bg) :-
    canvas_blank(3, 3, 0, G0),
    dot(Dot),
    canvas_paint_bg(G0, Dot, 0, G1),
    nth0(0, G1, Row0),
    nth0(0, Row0, r).

test(paint_bg_skips_occupied) :-
    % Pre-paint a cell, then try to paint on it with paint_bg.
    canvas_blank(3, 3, 0, G0),
    Pre = obj(5, [r(0,0)]),
    canvas_paint(G0, Pre, G1),
    Over = obj(9, [r(0,0)]),
    canvas_paint_bg(G1, Over, 0, G2),
    % Cell stays 5, not overwritten with 9.
    nth0(0, G2, Row0),
    nth0(0, Row0, 5).

test(paint_bg_paints_remaining_cells) :-
    canvas_blank(3, 3, 0, G0),
    Pre = obj(5, [r(0,0)]),
    canvas_paint(G0, Pre, G1),
    % Paint obj covering r(0,0) and r(0,1); only r(0,1) should be painted.
    Over = obj(9, [r(0,0), r(0,1)]),
    canvas_paint_bg(G1, Over, 0, G2),
    nth0(0, G2, Row0),
    nth0(0, Row0, 5),   % r(0,0) not overwritten
    nth0(1, Row0, 9).   % r(0,1) painted

% canvas_erase/4 tests
test(erase_dot) :-
    canvas_blank(3, 3, 0, G0),
    dot(Dot),
    canvas_paint(G0, Dot, G1),
    canvas_erase(G1, Dot, 0, G2),
    G2 = G0.

test(erase_leaves_other_cells) :-
    canvas_blank(3, 3, 0, G0),
    dot(Dot), hbar(Hbar),
    canvas_paint_all(G0, [Dot, Hbar], G1),
    canvas_erase(G1, Dot, 0, G2),
    % Dot erased.
    nth0(0, G2, Row0),
    nth0(0, Row0, 0),
    % Hbar still there.
    nth0(1, G2, [b,b,b]).

test(erase_uses_bg) :-
    canvas_blank(3, 3, 7, G0),
    dot(Dot),
    canvas_paint(G0, Dot, G1),
    canvas_erase(G1, Dot, 7, G2),
    G2 = G0.

% canvas_extract/3 tests
test(extract_existing_color) :-
    canvas_blank(3, 3, 0, G0),
    dot(Dot),
    canvas_paint(G0, Dot, G1),
    canvas_extract(G1, r, Obj),
    Obj = obj(r, [r(0,0)]).

test(extract_absent_color) :-
    canvas_blank(3, 3, 0, G0),
    canvas_extract(G0, r, Obj),
    Obj = obj(r, []).

test(extract_multiple_cells) :-
    canvas_blank(3, 3, 0, G0),
    hbar(Hbar),
    canvas_paint(G0, Hbar, G1),
    canvas_extract(G1, b, Obj),
    Obj = obj(b, [r(1,0),r(1,1),r(1,2)]).

% canvas_extract_all/3 tests
test(extract_all_two_colors) :-
    canvas_blank(3, 3, 0, G0),
    dot(Dot), hbar(Hbar),
    canvas_paint_all(G0, [Dot, Hbar], G1),
    canvas_extract_all(G1, 0, Objs),
    length(Objs, 2),
    member(obj(r, _), Objs),
    member(obj(b, _), Objs).

test(extract_all_empty_grid) :-
    canvas_blank(3, 3, 0, G0),
    canvas_extract_all(G0, 0, Objs),
    Objs = [].

test(extract_all_single_color) :-
    canvas_blank(2, 2, 0, G0),
    Obj = obj(5, [r(0,0),r(1,1)]),
    canvas_paint(G0, Obj, G1),
    canvas_extract_all(G1, 0, Objs),
    Objs = [obj(5, [r(0,0),r(1,1)])].

% canvas_render/5 tests
test(render_empty_scene) :-
    canvas_render(3, 3, 0, [], G),
    G = [[0,0,0],[0,0,0],[0,0,0]].

test(render_two_objs) :-
    dot(Dot), hbar(Hbar),
    canvas_render(3, 3, 0, [Dot, Hbar], G),
    nth0(0, G, [r,0,0]),
    nth0(1, G, [b,b,b]).

test(render_round_trip) :-
    % Render a scene, then extract all objects and verify.
    dot(Dot), vbar(Vbar),
    canvas_render(3, 3, 0, [Dot, Vbar], G),
    canvas_extract_all(G, 0, Objs),
    member(obj(r, [r(0,0)]), Objs),
    member(obj(g, _), Objs).

% canvas_move/6 tests
test(move_dot_down_right) :-
    canvas_blank(3, 3, 0, G0),
    dot(Dot),
    canvas_paint(G0, Dot, G1),
    canvas_move(G1, Dot, 1, 1, 0, G2),
    % Original position (0,0) is now 0.
    nth0(0, G2, Row0), nth0(0, Row0, 0),
    % New position (1,1) is r.
    nth0(1, G2, Row1), nth0(1, Row1, r).

test(move_erase_and_repaint) :-
    canvas_blank(4, 4, 0, G0),
    hbar(Hbar),
    canvas_paint(G0, Hbar, G1),
    % Move hbar down by 2 rows.
    canvas_move(G1, Hbar, 2, 0, 0, G2),
    % Original row 1 should be all 0.
    nth0(1, G2, [0,0,0,0]),
    % New row 3 should have b at cols 0,1,2.
    nth0(3, G2, Row3),
    nth0(0, Row3, b), nth0(1, Row3, b), nth0(2, Row3, b).

% canvas_stamp/3 tests
test(stamp_single_cell) :-
    dot(Dot),
    canvas_stamp(Dot, 0, Patch),
    Patch = [[r]].

test(stamp_hbar) :-
    hbar(Hbar),
    canvas_stamp(Hbar, 0, Patch),
    % Hbar spans 1 row, 3 cols.
    Patch = [[b,b,b]].

test(stamp_l_shape) :-
    l_shape(L),
    canvas_stamp(L, 0, Patch),
    % L at r(0,0)-r(1,0)-r(1,1): bbox 2x2, origin-normalized.
    Patch = [[p,0],[p,p]].

% canvas_blit/5 tests
test(blit_patch_at_origin) :-
    canvas_blank(3, 3, 0, G0),
    Patch = [[1,2],[3,4]],
    canvas_blit(G0, Patch, 0, 0, G1),
    nth0(0, G1, [1,2,0]),
    nth0(1, G1, [3,4,0]),
    nth0(2, G1, [0,0,0]).

test(blit_patch_at_offset) :-
    canvas_blank(3, 3, 0, G0),
    Patch = [[9]],
    canvas_blit(G0, Patch, 1, 2, G1),
    nth0(1, G1, Row1),
    nth0(2, Row1, 9).

test(blit_patch_partially_out_of_bounds) :-
    canvas_blank(3, 3, 0, G0),
    Patch = [[1,2],[3,4]],
    % Place 2x2 patch at (2,2): only top-left of patch fits in 3x3 canvas.
    canvas_blit(G0, Patch, 2, 2, G1),
    nth0(2, G1, Row2),
    nth0(2, Row2, 1).   % only Patch[0][0] lands at (2,2)

:- end_tests(canvas).
