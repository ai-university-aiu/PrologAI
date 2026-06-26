:- use_module('../prolog/objchain').
:- begin_tests(objchain).

% Horizontal chain: a-b-c-d-e in the same row (row 0, cols 0-4).
% Each consecutive pair touches (same row, adjacent columns).
a_obj(obj(a,[r(0,0)])).
b_obj(obj(b,[r(0,1)])).
c_obj(obj(c,[r(0,2)])).
d_obj(obj(d,[r(0,3)])).
e_obj(obj(e,[r(0,4)])).

% Vertical chain: v1-v2-v3 in the same column (col 0, rows 0-2).
v1_obj(obj(v1,[r(0,0)])).
v2_obj(obj(v2,[r(1,0)])).
v3_obj(obj(v3,[r(2,0)])).

% Branching: bx at r(0,1), cx at r(1,1), dx at r(0,2).
% bx touches a_obj and cx and dx -> degree 3 -> NOT a chain.
bx_obj(obj(bx,[r(0,1)])).
cx_obj(obj(cx,[r(1,1)])).
dx_obj(obj(dx,[r(0,2)])).

% Cycle: four single-cell objects forming a 2x2 square.
% cy1-cy2, cy2-cy3, cy3-cy4, cy4-cy1 all touch -> cycle.
cy1_obj(obj(cy1,[r(0,0)])).
cy2_obj(obj(cy2,[r(0,1)])).
cy3_obj(obj(cy3,[r(1,1)])).
cy4_obj(obj(cy4,[r(1,0)])).

% L-shaped chain: p at r(0,0), q at r(0,1), s at r(1,1).
% p-q horizontal, q-s vertical -> direction = other.
p_obj(obj(p,[r(0,0)])).
q_obj(obj(q,[r(0,1)])).
s_obj(obj(s,[r(1,1)])).

h_chain(Objs) :-
    a_obj(A), b_obj(B), c_obj(C), d_obj(D), e_obj(E),
    Objs = [A,B,C,D,E].

v_chain(Objs) :-
    v1_obj(V1), v2_obj(V2), v3_obj(V3),
    Objs = [V1,V2,V3].

cycle_objs(Objs) :-
    cy1_obj(C1), cy2_obj(C2), cy3_obj(C3), cy4_obj(C4),
    Objs = [C1,C2,C3,C4].

% ch_touches tests.

test(touches_ab) :-
    a_obj(A), b_obj(B), ch_touches(A, B).

test(touches_bc) :-
    b_obj(B), c_obj(C), ch_touches(B, C).

test(not_touches_ac) :-
    a_obj(A), c_obj(C), \+ ch_touches(A, C).

test(not_touches_ae) :-
    a_obj(A), e_obj(E), \+ ch_touches(A, E).

test(touches_vertical) :-
    v1_obj(V1), v2_obj(V2), ch_touches(V1, V2).

test(touches_symmetric) :-
    a_obj(A), b_obj(B), ch_touches(A, B), ch_touches(B, A).

% ch_degree tests.

test(degree_a_in_hchain) :-
    h_chain(Objs), a_obj(A), ch_degree(A, Objs, D), D == 1.

test(degree_b_in_hchain) :-
    h_chain(Objs), b_obj(B), ch_degree(B, Objs, D), D == 2.

test(degree_e_in_hchain) :-
    h_chain(Objs), e_obj(E), ch_degree(E, Objs, D), D == 1.

test(degree_v1_in_vchain) :-
    v_chain(Objs), v1_obj(V1), ch_degree(V1, Objs, D), D == 1.

test(degree_v2_interior) :-
    v_chain(Objs), v2_obj(V2), ch_degree(V2, Objs, D), D == 2.

% ch_is_chain tests.

test(is_chain_empty) :-
    ch_is_chain([]).

test(is_chain_single) :-
    a_obj(A), ch_is_chain([A]).

test(is_chain_two) :-
    a_obj(A), b_obj(B), ch_is_chain([A, B]).

test(is_chain_hchain5) :-
    h_chain(Objs), ch_is_chain(Objs).

test(is_chain_vchain3) :-
    v_chain(Objs), ch_is_chain(Objs).

test(not_chain_branching) :-
    a_obj(A), bx_obj(Bx), cx_obj(Cx), dx_obj(Dx),
    \+ ch_is_chain([A, Bx, Cx, Dx]).

test(not_chain_isolated) :-
    a_obj(A), e_obj(E), \+ ch_is_chain([A, E]).

% ch_has_cycle tests.

test(has_cycle_square) :-
    cycle_objs(Objs), ch_has_cycle(Objs).

test(not_cycle_linear) :-
    h_chain(Objs), \+ ch_has_cycle(Objs).

test(not_cycle_two) :-
    a_obj(A), b_obj(B), \+ ch_has_cycle([A, B]).

test(not_cycle_single) :-
    a_obj(A), \+ ch_has_cycle([A]).

% ch_endpoints tests.

test(endpoints_hchain) :-
    h_chain(Objs), a_obj(A), e_obj(E),
    ch_endpoints(Objs, E1, E2),
    sort([E1,E2], Sorted),
    sort([A,E], Expected),
    Sorted == Expected.

test(endpoints_vchain) :-
    v_chain(Objs), v1_obj(V1), v3_obj(V3),
    ch_endpoints(Objs, E1, E2),
    sort([E1,E2], Sorted),
    sort([V1,V3], Expected),
    Sorted == Expected.

% ch_linearize tests.

test(linearize_hchain_length) :-
    h_chain(Objs), ch_linearize(Objs, Ord), length(Ord, 5).

test(linearize_scrambled) :-
    % Put objects in a scrambled order; linearize should produce a valid path.
    a_obj(A), b_obj(B), c_obj(C), d_obj(D), e_obj(E),
    ch_linearize([E,C,A,D,B], Ord),
    ch_is_linear_path(Ord).

test(linearize_two) :-
    a_obj(A), b_obj(B),
    ch_linearize([A,B], Ord),
    length(Ord, 2).

% ch_from_endpoint tests.

test(from_endpoint_abc_order) :-
    a_obj(A), b_obj(B), c_obj(C),
    ch_from_endpoint([A,B,C], A, Ord),
    Ord == [A,B,C].

test(from_endpoint_reverse) :-
    a_obj(A), b_obj(B), c_obj(C),
    ch_from_endpoint([A,B,C], C, Ord),
    Ord == [C,B,A].

% ch_nth tests.

test(nth_zero) :-
    a_obj(A), b_obj(B), c_obj(C),
    ch_nth([A,B,C], 0, Obj), Obj == A.

test(nth_two) :-
    a_obj(A), b_obj(B), c_obj(C),
    ch_nth([A,B,C], 2, Obj), Obj == C.

% ch_color_seq tests.

test(color_seq_hchain) :-
    h_chain(Objs), ch_linearize(Objs, Ord),
    ch_color_seq(Ord, Colors),
    sort(Colors, Sorted),
    sort([a,b,c,d,e], Expected),
    Sorted == Expected.

test(color_seq_single) :-
    a_obj(A), ch_color_seq([A], Colors), Colors == [a].

% ch_sub tests.

test(sub_middle) :-
    a_obj(A), b_obj(B), c_obj(C), d_obj(D), e_obj(E),
    ch_sub([A,B,C,D,E], 1, 3, Sub),
    Sub == [B,C,D].

test(sub_full) :-
    a_obj(A), b_obj(B), c_obj(C),
    ch_sub([A,B,C], 0, 2, Sub),
    Sub == [A,B,C].

test(sub_single) :-
    a_obj(A), b_obj(B), c_obj(C),
    ch_sub([A,B,C], 1, 1, Sub),
    Sub == [B].

% ch_reverse tests.

test(reverse_hchain) :-
    a_obj(A), b_obj(B), c_obj(C),
    ch_reverse([A,B,C], Rev),
    Rev == [C,B,A].

test(reverse_single) :-
    a_obj(A), ch_reverse([A], Rev), Rev == [A].

% ch_length tests.

test(length_five) :-
    h_chain(Objs), ch_length(Objs, N), N == 5.

test(length_one) :-
    a_obj(A), ch_length([A], N), N == 1.

test(length_empty) :-
    ch_length([], N), N == 0.

% ch_is_linear_path tests.

test(is_linear_path_valid) :-
    a_obj(A), b_obj(B), c_obj(C), d_obj(D), e_obj(E),
    ch_is_linear_path([A,B,C,D,E]).

test(not_linear_path_gap) :-
    a_obj(A), c_obj(C), b_obj(B),
    \+ ch_is_linear_path([A,C,B]).

test(is_linear_path_single) :-
    a_obj(A), ch_is_linear_path([A]).

test(is_linear_path_empty) :-
    ch_is_linear_path([]).

% ch_direction tests.

test(direction_h) :-
    h_chain(Objs), ch_linearize(Objs, Ord), ch_direction(Ord, Dir), Dir == h.

test(direction_v) :-
    v_chain(Objs), ch_direction(Objs, Dir), Dir == v.

test(direction_other_lshape) :-
    p_obj(P), q_obj(Q), s_obj(S),
    ch_direction([P,Q,S], Dir), Dir == other.

:- end_tests(objchain).
