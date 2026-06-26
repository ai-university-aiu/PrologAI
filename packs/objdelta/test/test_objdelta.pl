:- use_module('../prolog/objdelta').
:- use_module(library(plunit)).

:- begin_tests(objdelta).

% --- Test fixtures ---
% dot_r: single red cell at (0,0).
dot_r(obj(r, [r(0,0)])).
% dot_b: single blue cell at (0,0).
dot_b(obj(b, [r(0,0)])).
% dot_g: single green cell at (0,0).
dot_g(obj(g, [r(0,0)])).
% bar2_r: 2-cell red bar at r(0,0)-r(0,1).
bar2_r(obj(r, [r(0,0),r(0,1)])).
% bar2_b: 2-cell blue bar at r(0,0)-r(0,1). Same form as bar2_r.
bar2_b(obj(b, [r(0,0),r(0,1)])).
% bar3_r: 3-cell red bar at r(0,0)-r(0,2).
bar3_r(obj(r, [r(0,0),r(0,1),r(0,2)])).
% dot_at22: single red cell at r(2,2).
dot_at22(obj(r, [r(2,2)])).
% dot_at04: single red cell at r(0,4).
dot_at04(obj(r, [r(0,4)])).
% dot_at24: single green cell at r(2,4).
dot_at24(obj(g, [r(2,4)])).
% lshape_r: L-shape, red.
lshape_r(obj(r, [r(0,0),r(1,0),r(1,1)])).
% lshape_b: same L-shape, blue.
lshape_b(obj(b, [r(0,0),r(1,0),r(1,1)])).

% --- dp_color_delta/3 ---

test(color_delta_change) :-
    dot_r(A), dot_b(B),
    dp_color_delta(A, B, Delta),
    Delta == r-b.

test(color_delta_same) :-
    dot_r(A), dot_r(B),
    dp_color_delta(A, B, Delta),
    Delta == r-r.

test(color_delta_rgb) :-
    dot_b(A), dot_g(B),
    dp_color_delta(A, B, Delta),
    Delta == b-g.

% --- dp_pos_delta/3 ---

test(pos_delta_zero) :-
    dot_r(A), dot_b(B),
    dp_pos_delta(A, B, Delta),
    Delta == dr(0,0).

test(pos_delta_row) :-
    dot_r(A), dot_at22(B),
    dp_pos_delta(A, B, Delta),
    Delta == dr(2,2).

test(pos_delta_col) :-
    dot_r(A), dot_at04(B),
    dp_pos_delta(A, B, Delta),
    Delta == dr(0,4).

% --- dp_size_delta/3 ---

test(size_delta_grow) :-
    dot_r(A), bar2_r(B),
    dp_size_delta(A, B, D),
    D == 1.

test(size_delta_shrink) :-
    bar3_r(A), bar2_r(B),
    dp_size_delta(A, B, D),
    D == -1.

test(size_delta_same) :-
    dot_r(A), dot_b(B),
    dp_size_delta(A, B, D),
    D == 0.

% --- dp_same_color/2 ---

test(same_color_yes) :-
    dot_r(A), bar2_r(B),
    dp_same_color(A, B).

test(same_color_no, [fail]) :-
    dot_r(A), dot_b(B),
    dp_same_color(A, B).

% --- dp_same_form/2 ---

test(same_form_yes) :-
    bar2_r(A), bar2_b(B),
    dp_same_form(A, B).

test(same_form_no, [fail]) :-
    dot_r(A), bar2_r(B),
    dp_same_form(A, B).

test(same_form_lshape) :-
    lshape_r(A), lshape_b(B),
    dp_same_form(A, B).

% --- dp_same_pos/2 ---

test(same_pos_yes) :-
    dot_r(A), dot_b(B),
    dp_same_pos(A, B).

test(same_pos_no, [fail]) :-
    dot_r(A), dot_at22(B),
    dp_same_pos(A, B).

% --- dp_color_map/2 ---

test(color_map_basic) :-
    Pairs = [obj(r,[r(0,0)])-obj(b,[r(0,0)]),
             obj(g,[r(1,0)])-obj(r,[r(1,0)])],
    dp_color_map(Pairs, Map),
    Map == [g-r, r-b].

test(color_map_single) :-
    Pairs = [obj(r,[r(0,0)])-obj(b,[r(0,0)])],
    dp_color_map(Pairs, Map),
    Map == [r-b].

test(color_map_dedup) :-
    Pairs = [obj(r,[r(0,0)])-obj(b,[r(0,0)]),
             obj(r,[r(1,0)])-obj(b,[r(1,0)])],
    dp_color_map(Pairs, Map),
    Map == [r-b].

% --- dp_apply_color/3 ---

test(apply_color_match) :-
    dot_r(Obj),
    dp_apply_color(r-b, Obj, Obj2),
    Obj2 == obj(b, [r(0,0)]).

test(apply_color_no_match, [fail]) :-
    dot_r(Obj),
    dp_apply_color(g-b, Obj, _).

% --- dp_apply_color_map/3 ---

test(apply_map_found) :-
    Map = [g-y, r-b],
    dot_r(Obj),
    dp_apply_color_map(Map, Obj, Obj2),
    Obj2 == obj(b, [r(0,0)]).

test(apply_map_not_found, [fail]) :-
    Map = [g-y],
    dot_r(Obj),
    dp_apply_color_map(Map, Obj, _).

% --- dp_apply_map_all/3 ---

test(apply_map_all_basic) :-
    Map = [r-b, g-y],
    dot_r(R), dot_g(G), dot_b(B),
    dp_apply_map_all(Map, [R, G, B], Objs2),
    Objs2 == [obj(b,[r(0,0)]), obj(y,[r(0,0)]), obj(b,[r(0,0)])].

test(apply_map_all_empty) :-
    dp_apply_map_all([r-b], [], Objs2),
    Objs2 == [].

% --- dp_const_dr/2 ---

test(const_dr_yes) :-
    Pairs = [obj(r,[r(0,0)])-obj(r,[r(2,0)]),
             obj(g,[r(1,0)])-obj(g,[r(3,0)])],
    dp_const_dr(Pairs, DR),
    DR == 2.

test(const_dr_fail, [fail]) :-
    Pairs = [obj(r,[r(0,0)])-obj(r,[r(2,0)]),
             obj(g,[r(1,0)])-obj(g,[r(4,0)])],
    dp_const_dr(Pairs, _).

% --- dp_const_dc/2 ---

test(const_dc_yes) :-
    Pairs = [obj(r,[r(0,0)])-obj(r,[r(0,3)]),
             obj(g,[r(1,0)])-obj(g,[r(1,3)])],
    dp_const_dc(Pairs, DC),
    DC == 3.

test(const_dc_fail, [fail]) :-
    Pairs = [obj(r,[r(0,0)])-obj(r,[r(0,3)]),
             obj(g,[r(1,0)])-obj(g,[r(1,5)])],
    dp_const_dc(Pairs, _).

% --- dp_common_cells/3 ---

test(common_cells_overlap) :-
    A = obj(r, [r(0,0), r(0,1), r(1,0)]),
    B = obj(b, [r(0,0), r(1,0), r(1,1)]),
    dp_common_cells(A, B, Cells),
    Cells == [r(0,0), r(1,0)].

test(common_cells_none) :-
    A = obj(r, [r(0,0)]),
    B = obj(b, [r(1,1)]),
    dp_common_cells(A, B, Cells),
    Cells == [].

% --- dp_cell_diff/4 ---

test(cell_diff_basic) :-
    A = obj(r, [r(0,0), r(0,1)]),
    B = obj(b, [r(0,1), r(0,2)]),
    dp_cell_diff(A, B, Added, Removed),
    Added == [r(0,2)],
    Removed == [r(0,0)].

test(cell_diff_no_change) :-
    A = obj(r, [r(0,0), r(0,1)]),
    B = obj(b, [r(0,0), r(0,1)]),
    dp_cell_diff(A, B, Added, Removed),
    Added == [],
    Removed == [].

% --- Additional tests ---

test(same_color_self) :-
    dot_r(A),
    dp_same_color(A, A).

test(same_pos_bar) :-
    bar2_r(A), bar2_b(B),
    dp_same_pos(A, B).

test(color_map_empty_pairs) :-
    dp_color_map([], Map),
    Map == [].

test(apply_map_first_wins) :-
    Map = [r-b, r-g],
    dot_r(Obj),
    dp_apply_color_map(Map, Obj, Obj2),
    Obj2 == obj(b, [r(0,0)]).

test(apply_map_all_unmapped) :-
    Map = [g-y],
    dot_r(R),
    dp_apply_map_all(Map, [R], Objs2),
    Objs2 == [obj(r,[r(0,0)])].

test(const_dr_single_pair) :-
    Pairs = [obj(r,[r(0,0)])-obj(r,[r(3,0)])],
    dp_const_dr(Pairs, DR),
    DR == 3.

test(const_dc_zero) :-
    Pairs = [obj(r,[r(0,0)])-obj(g,[r(0,0)]),
             obj(b,[r(1,0)])-obj(y,[r(1,0)])],
    dp_const_dc(Pairs, DC),
    DC == 0.

test(pos_delta_negative) :-
    dot_at22(A), dot_r(B),
    dp_pos_delta(A, B, Delta),
    Delta == dr(-2,-2).

:- end_tests(objdelta).
