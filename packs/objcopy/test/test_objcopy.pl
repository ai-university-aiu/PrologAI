:- use_module('../prolog/objcopy').
:- use_module(library(plunit)).

:- begin_tests(objcopy).

% --- Test fixtures ---
% dot: single red cell at r(0,0). BBox: H=1, W=1.
dot(obj(r, [r(0,0)])).
% dot_at22: single red cell at r(2,2).
dot_at22(obj(r, [r(2,2)])).
% bar_h: 3-cell horizontal bar at row 0, cols 0-2. BBox H=1, W=3.
bar_h(obj(b, [r(0,0),r(0,1),r(0,2)])).
% bar_h_at1: 3-cell horizontal bar at row 1, cols 0-2.
bar_h_at1(obj(b, [r(1,0),r(1,1),r(1,2)])).
% bar_v: 3-cell vertical bar at col 0, rows 0-2. BBox H=3, W=1.
bar_v(obj(g, [r(0,0),r(1,0),r(2,0)])).
% sq: 2x2 square at rows 0-1, cols 0-1. BBox H=2, W=2.
sq(obj(y, [r(0,0),r(0,1),r(1,0),r(1,1)])).
% lshape: L-shape at r(0,0),r(1,0),r(1,1).
lshape(obj(p, [r(0,0),r(1,0),r(1,1)])).

% --- objcopy_place_at/4 ---

test(place_at_origin) :-
    dot(D),
    objcopy_place_at(D, 0, 0, D2),
    D2 == obj(r, [r(0,0)]).

test(place_at_move) :-
    dot(D),
    objcopy_place_at(D, 3, 5, D2),
    D2 == obj(r, [r(3,5)]).

test(place_at_bar) :-
    bar_h(B),
    objcopy_place_at(B, 2, 4, B2),
    B2 == obj(b, [r(2,4),r(2,5),r(2,6)]).

% --- objcopy_recolor_all/3 ---

test(recolor_all_basic) :-
    dot(D), bar_h(B),
    objcopy_recolor_all(x, [D, B], Objs2),
    Objs2 == [obj(x,[r(0,0)]), obj(x,[r(0,0),r(0,1),r(0,2)])].

test(recolor_all_empty) :-
    objcopy_recolor_all(x, [], Objs2),
    Objs2 == [].

% --- objcopy_tile_row/4 ---

test(tile_row_basic) :-
    dot(D),
    objcopy_tile_row(D, 3, 2, Objs),
    Objs == [obj(r,[r(0,0)]), obj(r,[r(0,2)]), obj(r,[r(0,4)])].

test(tile_row_one) :-
    bar_h(B),
    objcopy_tile_row(B, 1, 10, Objs),
    length(Objs, 1).

% --- objcopy_tile_col/4 ---

test(tile_col_basic) :-
    dot(D),
    objcopy_tile_col(D, 3, 2, Objs),
    Objs == [obj(r,[r(0,0)]), obj(r,[r(2,0)]), obj(r,[r(4,0)])].

test(tile_col_one) :-
    dot(D),
    objcopy_tile_col(D, 1, 5, Objs),
    Objs == [obj(r,[r(0,0)])].

% --- objcopy_tile_grid/6 ---

test(tile_grid_2x2) :-
    dot(D),
    objcopy_tile_grid(D, 2, 2, 3, 4, Objs),
    length(Objs, 4),
    Objs == [obj(r,[r(0,0)]), obj(r,[r(0,4)]),
             obj(r,[r(3,0)]), obj(r,[r(3,4)])].

test(tile_grid_1x3) :-
    dot(D),
    objcopy_tile_grid(D, 1, 3, 2, 2, Objs),
    length(Objs, 3).

% --- objcopy_at_positions/3 ---

test(at_positions_basic) :-
    dot(D),
    objcopy_at_positions(D, [r(1,0), r(3,5)], Objs),
    Objs == [obj(r,[r(1,0)]), obj(r,[r(3,5)])].

test(at_positions_empty) :-
    dot(D),
    objcopy_at_positions(D, [], Objs),
    Objs == [].

% --- objcopy_align_top/2 ---

test(align_top_basic) :-
    A = obj(r,[r(1,0)]),  % min row = 1
    B = obj(b,[r(3,0)]),  % min row = 3
    objcopy_align_top([A,B], Aligned),
    Aligned == [obj(r,[r(1,0)]), obj(b,[r(1,0)])].

test(align_top_already) :-
    A = obj(r,[r(0,0)]),
    B = obj(b,[r(0,1)]),
    objcopy_align_top([A,B], Aligned),
    Aligned == [A, B].

% --- objcopy_align_left/2 ---

test(align_left_basic) :-
    A = obj(r,[r(0,2)]),  % min col = 2
    B = obj(b,[r(0,5)]),  % min col = 5
    objcopy_align_left([A,B], Aligned),
    Aligned == [obj(r,[r(0,2)]), obj(b,[r(0,2)])].

test(align_left_already) :-
    A = obj(r,[r(0,0)]),
    B = obj(b,[r(1,0)]),
    objcopy_align_left([A,B], Aligned),
    Aligned == [A, B].

% --- objcopy_pack_row/5 ---

test(pack_row_basic) :-
    dot(D), sq(S),
    % dot bbox W=1, sq bbox W=2
    % dot placed at row 0, col 0; sq placed at row 0, col 0+1+1=2
    objcopy_pack_row([D, S], 0, 0, 1, Objs),
    Objs == [obj(r,[r(0,0)]), obj(y,[r(0,2),r(0,3),r(1,2),r(1,3)])].

test(pack_row_gap0) :-
    bar_h(B1), bar_h(B2),
    % first bar at col 0 (W=3), second at col 0+3+0=3
    objcopy_pack_row([B1, B2], 2, 0, 0, Objs),
    Objs == [obj(b,[r(2,0),r(2,1),r(2,2)]),
             obj(b,[r(2,3),r(2,4),r(2,5)])].

% --- objcopy_pack_col/5 ---

test(pack_col_basic) :-
    dot(D), sq(S),
    % dot bbox H=1, sq bbox H=2
    % dot placed at col 0, row 0; sq placed at col 0, row 0+1+1=2
    objcopy_pack_col([D, S], 0, 0, 1, Objs),
    Objs == [obj(r,[r(0,0)]), obj(y,[r(2,0),r(2,1),r(3,0),r(3,1)])].

test(pack_col_gap0) :-
    bar_v(V1), bar_v(V2),
    % first bar at row 0 (H=3), second at row 0+3+0=3
    objcopy_pack_col([V1, V2], 2, 0, 0, Objs),
    Objs == [obj(g,[r(0,2),r(1,2),r(2,2)]),
             obj(g,[r(3,2),r(4,2),r(5,2)])].

% --- objcopy_spread_h/4 ---

test(spread_h_basic) :-
    dot(A), dot(B), dot(C),
    objcopy_spread_h([A, B, C], 0, 3, Objs),
    Objs == [obj(r,[r(0,0)]), obj(r,[r(0,3)]), obj(r,[r(0,6)])].

test(spread_h_offset) :-
    dot(A), dot(B),
    objcopy_spread_h([A, B], 2, 4, Objs),
    Objs == [obj(r,[r(0,2)]), obj(r,[r(0,6)])].

% --- objcopy_spread_v/4 ---

test(spread_v_basic) :-
    dot(A), dot(B), dot(C),
    objcopy_spread_v([A, B, C], 0, 3, Objs),
    Objs == [obj(r,[r(0,0)]), obj(r,[r(3,0)]), obj(r,[r(6,0)])].

test(spread_v_offset) :-
    dot(A), dot(B),
    objcopy_spread_v([A, B], 1, 2, Objs),
    Objs == [obj(r,[r(1,0)]), obj(r,[r(3,0)])].

% --- objcopy_center/4 ---

test(center_dot_in_3x3) :-
    dot(D),
    objcopy_center(D, 3, 3, D2),
    D2 == obj(r, [r(1,1)]).

test(center_bar_in_canvas) :-
    bar_h(B),  % bbox H=1, W=3
    % In a 3x9 canvas: row offset = (3-1)//2 = 1, col offset = (9-3)//2 = 3
    objcopy_center(B, 3, 9, B2),
    B2 == obj(b, [r(1,3),r(1,4),r(1,5)]).

% --- objcopy_flip_h/3 ---

test(flip_h_basic) :-
    dot(D),  % r(0,0) in width 5 -> r(0,4)
    objcopy_flip_h(D, 5, D2),
    D2 == obj(r, [r(0,4)]).

test(flip_h_bar) :-
    bar_h(B),  % r(0,0),r(0,1),r(0,2) in width 4 -> r(0,3),r(0,2),r(0,1)
    objcopy_flip_h(B, 4, B2),
    B2 == obj(b, [r(0,3),r(0,2),r(0,1)]).

% --- Additional tests ---

test(place_at_from_nonorigin) :-
    dot_at22(D),  % at r(2,2)
    objcopy_place_at(D, 0, 1, D2),
    D2 == obj(r, [r(0,1)]).

test(tile_row_bar) :-
    bar_h(B),  % bbox W=3, so tiles at col 0, 4, 8 with step 4
    objcopy_tile_row(B, 2, 4, Objs),
    length(Objs, 2),
    nth0(0, Objs, obj(b,[r(0,0),r(0,1),r(0,2)])),
    nth0(1, Objs, obj(b,[r(0,4),r(0,5),r(0,6)])).

test(tile_col_bar) :-
    bar_v(V),  % bbox H=3, rows 0-2; tile with step 4
    objcopy_tile_col(V, 2, 4, Objs),
    length(Objs, 2),
    nth0(0, Objs, obj(g,[r(0,0),r(1,0),r(2,0)])),
    nth0(1, Objs, obj(g,[r(4,0),r(5,0),r(6,0)])).

test(tile_grid_3x2) :-
    dot(D),
    objcopy_tile_grid(D, 3, 2, 2, 3, Objs),
    length(Objs, 6).

test(align_top_three) :-
    A = obj(r,[r(2,0)]),
    B = obj(b,[r(0,1)]),
    C = obj(g,[r(4,2)]),
    objcopy_align_top([A,B,C], Aligned),
    Aligned == [obj(r,[r(0,0)]), obj(b,[r(0,1)]), obj(g,[r(0,2)])].

test(align_left_three) :-
    A = obj(r,[r(0,3)]),
    B = obj(b,[r(1,1)]),
    C = obj(g,[r(2,5)]),
    objcopy_align_left([A,B,C], Aligned),
    Aligned == [obj(r,[r(0,1)]), obj(b,[r(1,1)]), obj(g,[r(2,1)])].

test(pack_row_single) :-
    dot(D),
    objcopy_pack_row([D], 5, 3, 2, Objs),
    Objs == [obj(r,[r(5,3)])].

test(pack_col_single) :-
    dot(D),
    objcopy_pack_col([D], 4, 1, 2, Objs),
    Objs == [obj(r,[r(1,4)])].

test(spread_h_single) :-
    dot(D),
    objcopy_spread_h([D], 3, 5, Objs),
    Objs == [obj(r,[r(0,3)])].

test(spread_v_three_offset) :-
    dot(A), dot(B), dot(C),
    objcopy_spread_v([A, B, C], 2, 4, Objs),
    Objs == [obj(r,[r(2,0)]), obj(r,[r(6,0)]), obj(r,[r(10,0)])].

test(center_sq_in_4x4) :-
    sq(S),  % bbox H=2, W=2; in 4x4: row=(4-2)//2=1, col=(4-2)//2=1
    objcopy_center(S, 4, 4, S2),
    S2 == obj(y, [r(1,1),r(1,2),r(2,1),r(2,2)]).

test(flip_h_lshape) :-
    lshape(L),  % r(0,0),r(1,0),r(1,1) in width 3 -> r(0,2),r(1,2),r(1,1)
    objcopy_flip_h(L, 3, L2),
    L2 == obj(p, [r(0,2),r(1,2),r(1,1)]).

:- end_tests(objcopy).
