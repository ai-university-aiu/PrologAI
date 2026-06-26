:- use_module('../prolog/objsym').
:- begin_tests(objsym).

% Square object: 2x2 block at rows 1-2, cols 1-2.
sq_obj(obj(s, [r(1,1), r(1,2), r(2,1), r(2,2)])).

% Horizontal bar: 1x3, row 0, cols 0-2.
hbar_obj(obj(h, [r(0,0), r(0,1), r(0,2)])).

% Vertical bar: 3x1, rows 0-2, col 0.
vbar_obj(obj(v, [r(0,0), r(1,0), r(2,0)])).

% Plus sign: 3x3, center cross. Has rot90 symmetry.
plus_obj(obj(p, [r(0,1), r(1,0), r(1,1), r(1,2), r(2,1)])).

% L-shape: no symmetry. Cells at r(0,0), r(1,0), r(1,1).
l_obj(obj(l, [r(0,0), r(1,0), r(1,1)])).

% T-shape: h-symmetric but not v. Cells r(0,0),r(0,1),r(0,2),r(1,1).
t_obj(obj(t, [r(0,0), r(0,1), r(0,2), r(1,1)])).

% Z-shape: rot180 symmetric but not h/v. r(0,0),r(0,1),r(1,1),r(1,2).
z_obj(obj(z, [r(0,0), r(0,1), r(1,1), r(1,2)])).

% Single cell at r(3,5): trivially symmetric under everything.
dot_obj(obj(d, [r(3,5)])).

% Diamond (rotated square): r(0,1),r(1,0),r(1,2),r(2,1). h+v+rot180+rot90 symmetric.
diamond_obj(obj(x, [r(0,1), r(1,0), r(1,2), r(2,1)])).

% Two separate cells same row: r(2,0), r(2,4). h+rot180 symmetric.
pair_obj(obj(pair, [r(2,0), r(2,4)])).

% os_bbox tests.

test(bbox_sq) :-
    sq_obj(O), os_bbox(O, 1, 1, 2, 2).

test(bbox_hbar) :-
    hbar_obj(O), os_bbox(O, 0, 0, 0, 2).

test(bbox_vbar) :-
    vbar_obj(O), os_bbox(O, 0, 0, 2, 0).

test(bbox_plus) :-
    plus_obj(O), os_bbox(O, 0, 0, 2, 2).

test(bbox_dot) :-
    dot_obj(O), os_bbox(O, 3, 5, 3, 5).

% os_normalize tests.

test(normalize_sq) :-
    sq_obj(O), os_normalize(O, obj(s, Cells)),
    msort(Cells, S),
    msort([r(0,0), r(0,1), r(1,0), r(1,1)], Expected),
    S == Expected.

test(normalize_hbar) :-
    hbar_obj(O), os_normalize(O, obj(h, Cells)),
    msort(Cells, S),
    msort([r(0,0), r(0,1), r(0,2)], Expected),
    S == Expected.

test(normalize_dot) :-
    dot_obj(O), os_normalize(O, obj(d, Cells)),
    Cells == [r(0,0)].

test(normalize_color_preserved) :-
    l_obj(O), os_normalize(O, obj(Color, _)),
    Color == l.

% os_translate tests.

test(translate_shift) :-
    hbar_obj(O), os_translate(O, 2, 3, obj(h, Cells)),
    msort(Cells, S),
    msort([r(2,3), r(2,4), r(2,5)], Expected),
    S == Expected.

test(translate_negative) :-
    sq_obj(O), os_translate(O, -1, -1, obj(s, Cells)),
    msort(Cells, S),
    msort([r(0,0), r(0,1), r(1,0), r(1,1)], Expected),
    S == Expected.

test(translate_zero) :-
    vbar_obj(O), os_translate(O, 0, 0, O).

% os_reflect_h tests.

test(reflect_h_hbar) :-
    hbar_obj(O), os_reflect_h(O, obj(h, Cells)),
    msort(Cells, S),
    % MinC=0, MaxC=2; r(0,C) -> r(0, 0+2-C).
    % r(0,0)->r(0,2), r(0,1)->r(0,1), r(0,2)->r(0,0)
    msort([r(0,2), r(0,1), r(0,0)], Expected),
    S == Expected.

test(reflect_h_sq) :-
    sq_obj(O), os_reflect_h(O, obj(s, Cells)),
    msort(Cells, S),
    % MinC=1, MaxC=2; NC = 1+2-C = 3-C.
    % r(1,1)->r(1,2), r(1,2)->r(1,1), r(2,1)->r(2,2), r(2,2)->r(2,1)
    msort([r(1,2), r(1,1), r(2,2), r(2,1)], Expected),
    S == Expected.

test(reflect_h_color_preserved) :-
    plus_obj(O), os_reflect_h(O, obj(Color, _)),
    Color == p.

% os_reflect_v tests.

test(reflect_v_vbar) :-
    vbar_obj(O), os_reflect_v(O, obj(v, Cells)),
    msort(Cells, S),
    % MinR=0, MaxR=2; NR = 0+2-R.
    % r(0,0)->r(2,0), r(1,0)->r(1,0), r(2,0)->r(0,0)
    msort([r(2,0), r(1,0), r(0,0)], Expected),
    S == Expected.

test(reflect_v_sq) :-
    sq_obj(O), os_reflect_v(O, obj(s, Cells)),
    msort(Cells, S),
    % MinR=1, MaxR=2; NR = 1+2-R = 3-R.
    % r(1,1)->r(2,1), r(1,2)->r(2,2), r(2,1)->r(1,1), r(2,2)->r(1,2)
    msort([r(2,1), r(2,2), r(1,1), r(1,2)], Expected),
    S == Expected.

% os_rotate180 tests.

test(rotate180_sq) :-
    sq_obj(O), os_rotate180(O, obj(s, Cells)),
    msort(Cells, S),
    % 2x2 block is unchanged under 180 rotation.
    msort([r(1,1), r(1,2), r(2,1), r(2,2)], Expected),
    S == Expected.

test(rotate180_l) :-
    l_obj(O), os_rotate180(O, obj(l, Cells)),
    msort(Cells, S),
    % L: r(0,0),r(1,0),r(1,1). MinR=0,MaxR=1,MinC=0,MaxC=1.
    % r(0,0)->r(1,1), r(1,0)->r(0,1), r(1,1)->r(0,0)
    msort([r(1,1), r(0,1), r(0,0)], Expected),
    S == Expected.

test(rotate180_hbar) :-
    hbar_obj(O), os_rotate180(O, obj(h, Cells)),
    msort(Cells, S),
    % 1x3 bar: MinR=0,MaxR=0,MinC=0,MaxC=2.
    % r(0,0)->r(0,2), r(0,1)->r(0,1), r(0,2)->r(0,0)
    msort([r(0,2), r(0,1), r(0,0)], Expected),
    S == Expected.

% os_rotate90 tests.

test(rotate90_single_cell) :-
    dot_obj(O), os_normalize(O, N), os_rotate90(N, obj(d, Cells)),
    Cells == [r(0,0)].

test(rotate90_hbar_becomes_vbar) :-
    hbar_obj(O), os_rotate90(O, obj(h, Cells)),
    msort(Cells, S),
    % hbar: r(0,0),r(0,1),r(0,2). MinR=0,MinC=0,MaxR=0.
    % NR = C - MinC = C. NC = MaxR - R = 0 - 0 = 0.
    % r(0,0)->r(0,0), r(0,1)->r(1,0), r(0,2)->r(2,0)
    msort([r(0,0), r(1,0), r(2,0)], Expected),
    S == Expected.

test(rotate90_vbar_becomes_hbar) :-
    vbar_obj(O), os_rotate90(O, obj(v, Cells)),
    msort(Cells, S),
    % vbar: r(0,0),r(1,0),r(2,0). MinR=0,MinC=0,MaxR=2.
    % NR = C - MinC = 0. NC = MaxR - R = 2-R.
    % r(0,0)->r(0,2), r(1,0)->r(0,1), r(2,0)->r(0,0)
    msort([r(0,2), r(0,1), r(0,0)], Expected),
    S == Expected.

test(rotate90_plus_invariant) :-
    plus_obj(O), os_normalize(O, N), os_rotate90(N, obj(p, Cells)),
    msort(Cells, S),
    % Plus is rot90 symmetric; rotated cells should match normalized original.
    N = obj(_, NCells), msort(NCells, S0),
    S == S0.

% os_is_hsymm tests.

test(is_hsymm_hbar) :-
    hbar_obj(O), os_is_hsymm(O).

test(is_hsymm_sq) :-
    sq_obj(O), os_is_hsymm(O).

test(is_hsymm_plus) :-
    plus_obj(O), os_is_hsymm(O).

test(is_hsymm_diamond) :-
    diamond_obj(O), os_is_hsymm(O).

test(not_hsymm_l) :-
    l_obj(O), \+ os_is_hsymm(O).

test(not_hsymm_z) :-
    z_obj(O), \+ os_is_hsymm(O).

% os_is_vsymm tests.

test(is_vsymm_vbar) :-
    vbar_obj(O), os_is_vsymm(O).

test(is_vsymm_sq) :-
    sq_obj(O), os_is_vsymm(O).

test(is_vsymm_plus) :-
    plus_obj(O), os_is_vsymm(O).

test(not_vsymm_t) :-
    t_obj(O), \+ os_is_vsymm(O).

test(not_vsymm_l) :-
    l_obj(O), \+ os_is_vsymm(O).

% os_is_rot180 tests.

test(is_rot180_sq) :-
    sq_obj(O), os_is_rot180(O).

test(is_rot180_plus) :-
    plus_obj(O), os_is_rot180(O).

test(is_rot180_z) :-
    z_obj(O), os_is_rot180(O).

test(is_rot180_hbar) :-
    hbar_obj(O), os_is_rot180(O).

test(not_rot180_l) :-
    l_obj(O), \+ os_is_rot180(O).

test(not_rot180_t) :-
    t_obj(O), \+ os_is_rot180(O).

% os_is_rot90 tests.

test(is_rot90_plus) :-
    plus_obj(O), os_is_rot90(O).

test(is_rot90_sq) :-
    sq_obj(O), os_is_rot90(O).

test(is_rot90_dot) :-
    dot_obj(O), os_is_rot90(O).

test(is_rot90_diamond) :-
    diamond_obj(O), os_is_rot90(O).

test(not_rot90_hbar) :-
    hbar_obj(O), \+ os_is_rot90(O).

test(not_rot90_l) :-
    l_obj(O), \+ os_is_rot90(O).

% os_has_symmetry tests.

test(has_symmetry_plus) :-
    plus_obj(O), os_has_symmetry(O).

test(has_symmetry_z) :-
    z_obj(O), os_has_symmetry(O).

test(has_symmetry_t) :-
    t_obj(O), os_has_symmetry(O).

test(not_has_symmetry_l) :-
    l_obj(O), \+ os_has_symmetry(O).

% os_symmetries tests.

test(symmetries_plus_all) :-
    plus_obj(O), os_symmetries(O, List),
    msort(List, S),
    S == [h, rot180, rot90, v].

test(symmetries_z_rot180_only) :-
    z_obj(O), os_symmetries(O, List),
    List == [rot180].

test(symmetries_t_h_only) :-
    t_obj(O), os_symmetries(O, List),
    List == [h].

test(symmetries_l_empty) :-
    l_obj(O), os_symmetries(O, List),
    List == [].

test(symmetries_sq_all) :-
    sq_obj(O), os_symmetries(O, List),
    msort(List, S),
    S == [h, rot180, rot90, v].

% os_equivalent tests.

test(equivalent_hbar_vbar) :-
    % A horizontal bar and a vertical bar are equivalent under 90-degree rotation.
    hbar_obj(O1), vbar_obj(O2),
    os_equivalent(O1, O2).

test(equivalent_self) :-
    l_obj(O), os_equivalent(O, O).

test(not_equivalent_l_z) :-
    l_obj(O1), z_obj(O2), \+ os_equivalent(O1, O2).

test(equivalent_l_rotated) :-
    % An L rotated 90 degrees is equivalent to the original L.
    l_obj(O), os_normalize(O, N), os_rotate90(N, R), os_normalize(R, O2),
    os_equivalent(O, O2).

test(not_equivalent_plus_l) :-
    plus_obj(O1), l_obj(O2), \+ os_equivalent(O1, O2).

:- end_tests(objsym).
