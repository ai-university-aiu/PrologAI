:- use_module('../prolog/objbound').
:- begin_tests(objbound).

% Single cell at r(0,0).
dot_obj(obj(d, [r(0,0)])).

% Horizontal bar: 1x3 at row 0, cols 0-2.
hbar_obj(obj(h, [r(0,0), r(0,1), r(0,2)])).

% Vertical bar: 3x1 at rows 0-2, col 0.
vbar_obj(obj(v, [r(0,0), r(1,0), r(2,0)])).

% Solid 2x2 square.
sq2_obj(obj(s, [r(0,0), r(0,1), r(1,0), r(1,1)])).

% Solid 3x3 square.
sq3_obj(obj(s3, [r(0,0),r(0,1),r(0,2),
                  r(1,0),r(1,1),r(1,2),
                  r(2,0),r(2,1),r(2,2)])).

% Frame: 3x3 hollow rectangle. Border filled, interior empty.
frame3_obj(obj(f, [r(0,0),r(0,1),r(0,2),
                    r(1,0),         r(1,2),
                    r(2,0),r(2,1),r(2,2)])).

% Frame: 4x5 hollow rectangle.
frame45_obj(obj(g, [r(0,0),r(0,1),r(0,2),r(0,3),r(0,4),
                     r(1,0),                    r(1,4),
                     r(2,0),                    r(2,4),
                     r(3,0),r(3,1),r(3,2),r(3,3),r(3,4)])).

% L-shape: r(0,0), r(1,0), r(1,1) - not a rectangle, not a frame.
l_obj(obj(l, [r(0,0), r(1,0), r(1,1)])).

% Plus sign: r(0,1), r(1,0), r(1,1), r(1,2), r(2,1). Has square bbox.
plus_obj(obj(p, [r(0,1), r(1,0), r(1,1), r(1,2), r(2,1)])).

% Wide rectangle: 2x4, all cells filled.
rect24_obj(obj(r, [r(0,0),r(0,1),r(0,2),r(0,3),
                    r(1,0),r(1,1),r(1,2),r(1,3)])).

% objbound_bbox_h tests.

test(bbox_h_dot) :-
    dot_obj(O), objbound_bbox_h(O, H), H == 1.

test(bbox_h_hbar) :-
    hbar_obj(O), objbound_bbox_h(O, H), H == 1.

test(bbox_h_vbar) :-
    vbar_obj(O), objbound_bbox_h(O, H), H == 3.

test(bbox_h_sq2) :-
    sq2_obj(O), objbound_bbox_h(O, H), H == 2.

test(bbox_h_frame3) :-
    frame3_obj(O), objbound_bbox_h(O, H), H == 3.

% objbound_bbox_w tests.

test(bbox_w_dot) :-
    dot_obj(O), objbound_bbox_w(O, W), W == 1.

test(bbox_w_hbar) :-
    hbar_obj(O), objbound_bbox_w(O, W), W == 3.

test(bbox_w_vbar) :-
    vbar_obj(O), objbound_bbox_w(O, W), W == 1.

test(bbox_w_sq2) :-
    sq2_obj(O), objbound_bbox_w(O, W), W == 2.

test(bbox_w_rect24) :-
    rect24_obj(O), objbound_bbox_w(O, W), W == 4.

% objbound_bbox_area tests.

test(bbox_area_dot) :-
    dot_obj(O), objbound_bbox_area(O, A), A == 1.

test(bbox_area_hbar) :-
    hbar_obj(O), objbound_bbox_area(O, A), A == 3.

test(bbox_area_vbar) :-
    vbar_obj(O), objbound_bbox_area(O, A), A == 3.

test(bbox_area_sq2) :-
    sq2_obj(O), objbound_bbox_area(O, A), A == 4.

test(bbox_area_rect24) :-
    rect24_obj(O), objbound_bbox_area(O, A), A == 8.

test(bbox_area_frame45) :-
    % 4x5 = 20 positions.
    frame45_obj(O), objbound_bbox_area(O, A), A == 20.

% objbound_is_rect tests.

test(is_rect_dot) :-
    dot_obj(O), objbound_is_rect(O).

test(is_rect_hbar) :-
    hbar_obj(O), objbound_is_rect(O).

test(is_rect_vbar) :-
    vbar_obj(O), objbound_is_rect(O).

test(is_rect_sq2) :-
    sq2_obj(O), objbound_is_rect(O).

test(is_rect_rect24) :-
    rect24_obj(O), objbound_is_rect(O).

test(not_rect_l) :-
    l_obj(O), \+ objbound_is_rect(O).

test(not_rect_frame3) :-
    frame3_obj(O), \+ objbound_is_rect(O).

test(not_rect_plus) :-
    plus_obj(O), \+ objbound_is_rect(O).

% objbound_is_hline tests.

test(is_hline_dot) :-
    dot_obj(O), objbound_is_hline(O).

test(is_hline_hbar) :-
    hbar_obj(O), objbound_is_hline(O).

test(not_hline_vbar) :-
    vbar_obj(O), \+ objbound_is_hline(O).

test(not_hline_sq2) :-
    sq2_obj(O), \+ objbound_is_hline(O).

% objbound_is_vline tests.

test(is_vline_dot) :-
    dot_obj(O), objbound_is_vline(O).

test(is_vline_vbar) :-
    vbar_obj(O), objbound_is_vline(O).

test(not_vline_hbar) :-
    hbar_obj(O), \+ objbound_is_vline(O).

test(not_vline_sq2) :-
    sq2_obj(O), \+ objbound_is_vline(O).

% objbound_is_single tests.

test(is_single_dot) :-
    dot_obj(O), objbound_is_single(O).

test(not_single_hbar) :-
    hbar_obj(O), \+ objbound_is_single(O).

test(not_single_vbar) :-
    vbar_obj(O), \+ objbound_is_single(O).

test(not_single_sq2) :-
    sq2_obj(O), \+ objbound_is_single(O).

% objbound_is_square_bbox tests.

test(is_square_bbox_dot) :-
    dot_obj(O), objbound_is_square_bbox(O).

test(is_square_bbox_sq2) :-
    sq2_obj(O), objbound_is_square_bbox(O).

test(is_square_bbox_sq3) :-
    sq3_obj(O), objbound_is_square_bbox(O).

test(is_square_bbox_plus) :-
    plus_obj(O), objbound_is_square_bbox(O).

test(is_square_bbox_frame3) :-
    frame3_obj(O), objbound_is_square_bbox(O).

test(not_square_bbox_hbar) :-
    hbar_obj(O), \+ objbound_is_square_bbox(O).

test(not_square_bbox_vbar) :-
    vbar_obj(O), \+ objbound_is_square_bbox(O).

test(not_square_bbox_rect24) :-
    rect24_obj(O), \+ objbound_is_square_bbox(O).

% objbound_holes tests.

test(holes_rect_empty) :-
    sq2_obj(O), objbound_holes(O, Holes), Holes == [].

test(holes_frame3) :-
    % 3x3 frame has 1 hole at r(1,1).
    frame3_obj(O), objbound_holes(O, Holes), Holes == [r(1,1)].

test(holes_plus) :-
    % Plus in 3x3 bbox: corners r(0,0),r(0,2),r(2,0),r(2,2) are holes.
    plus_obj(O), objbound_holes(O, Holes),
    msort(Holes, Sorted),
    Sorted == [r(0,0), r(0,2), r(2,0), r(2,2)].

test(holes_l) :-
    % L-shape in 2x2 bbox: r(0,1) is missing (top-right corner).
    l_obj(O), objbound_holes(O, Holes), Holes == [r(0,1)].

% objbound_n_holes tests.

test(n_holes_rect) :-
    sq2_obj(O), objbound_n_holes(O, N), N == 0.

test(n_holes_frame3) :-
    frame3_obj(O), objbound_n_holes(O, N), N == 1.

test(n_holes_plus) :-
    plus_obj(O), objbound_n_holes(O, N), N == 4.

% objbound_is_hollow tests.

test(is_hollow_frame3) :-
    frame3_obj(O), objbound_is_hollow(O).

test(is_hollow_plus) :-
    plus_obj(O), objbound_is_hollow(O).

test(is_hollow_l) :-
    l_obj(O), objbound_is_hollow(O).

test(not_hollow_rect) :-
    sq2_obj(O), \+ objbound_is_hollow(O).

test(not_hollow_hbar) :-
    hbar_obj(O), \+ objbound_is_hollow(O).

% objbound_is_frame tests.

test(is_frame_frame3) :-
    frame3_obj(O), objbound_is_frame(O).

test(is_frame_frame45) :-
    frame45_obj(O), objbound_is_frame(O).

test(not_frame_plus) :-
    % Plus has corners missing from the "frame".
    plus_obj(O), \+ objbound_is_frame(O).

test(not_frame_l) :-
    l_obj(O), \+ objbound_is_frame(O).

test(not_frame_sq2) :-
    % 2x2 is too small (H < 3); but let's check: H=2, not >= 3, so fails.
    sq2_obj(O), \+ objbound_is_frame(O).

test(not_frame_rect24) :-
    % Solid rectangle has interior cells, so not a frame.
    rect24_obj(O), \+ objbound_is_frame(O).

test(not_frame_hbar) :-
    % 1x3 bar: H=1 < 3, so fails.
    hbar_obj(O), \+ objbound_is_frame(O).

% objbound_perimeter tests.

test(perimeter_dot) :-
    % Single cell: 4 exposed edges.
    dot_obj(O), objbound_perimeter(O, P), P == 4.

test(perimeter_hbar) :-
    % 1x3: r(0,0) has 3 exposed (up,down,left), r(0,1) has 2 (up,down), r(0,2) has 3 (up,down,right) = 8.
    hbar_obj(O), objbound_perimeter(O, P), P == 8.

test(perimeter_vbar) :-
    % 3x1: same as hbar by symmetry = 8.
    vbar_obj(O), objbound_perimeter(O, P), P == 8.

test(perimeter_sq2) :-
    % 2x2: each corner cell has 2 exposed edges; 4 cells * 2 = 8.
    sq2_obj(O), objbound_perimeter(O, P), P == 8.

test(perimeter_frame3) :-
    % 3x3 frame: 8 cells. Every cell has exactly 2 exposed edges.
    % Corners: 2 outside. Edge middles: 1 outside + 1 to interior hole = 2.
    % Total: 8 * 2 = 16.
    frame3_obj(O), objbound_perimeter(O, P), P == 16.

% objbound_dense_hull tests.

test(dense_hull_dot) :-
    dot_obj(O), objbound_dense_hull(O, obj(d, Hull)),
    Hull == [r(0,0)].

test(dense_hull_hbar) :-
    hbar_obj(O), objbound_dense_hull(O, obj(h, Hull)),
    Hull == [r(0,0), r(0,1), r(0,2)].

test(dense_hull_frame3) :-
    frame3_obj(O), objbound_dense_hull(O, obj(f, Hull)),
    length(Hull, 9).

test(dense_hull_color) :-
    % dense_hull preserves the color.
    l_obj(O), objbound_dense_hull(O, obj(Color, _)),
    Color == l.

test(dense_hull_area) :-
    % hull area = bbox area.
    plus_obj(O), objbound_bbox_area(O, A), objbound_dense_hull(O, obj(_, Hull)),
    length(Hull, A).

:- end_tests(objbound).
