:- use_module('../prolog/object_component').
:- begin_tests(object_component).

% Helper objects.
% A: obj(a, [r(0,0)]): single cell at (0,0).
% B: obj(b, [r(0,1)]): single cell at (0,1). Touches A (4-adjacent).
% C: obj(c, [r(0,3)]): single cell at (0,3). Does NOT touch A or B.
% D: obj(d, [r(1,0)]): single cell at (1,0). Touches A.
% E: obj(e, [r(2,2)]): single cell at (2,2). Isolated.
% F: obj(f, [r(0,2)]): single cell at (0,2). Touches B and C.

a_obj(obj(a, [r(0,0)])).
b_obj(obj(b, [r(0,1)])).
c_obj(obj(c, [r(0,3)])).
d_obj(obj(d, [r(1,0)])).
e_obj(obj(e, [r(2,2)])).
f_obj(obj(f, [r(0,2)])).

% Adjacency: A-B, A-D, B-F, C-F. Chain: A-B-F-C. D hangs off A. E is isolated.

objs_abcdef(Objs) :-
    a_obj(A), b_obj(B), c_obj(C), d_obj(D), e_obj(E), f_obj(F),
    Objs = [A,B,C,D,E,F].

% object_component_touches tests.

test(touches_ab) :-
    a_obj(A), b_obj(B), object_component_touches(A, B).

test(touches_ad) :-
    a_obj(A), d_obj(D), object_component_touches(A, D).

test(touches_bf) :-
    b_obj(B), f_obj(F), object_component_touches(B, F).

test(touches_cf) :-
    c_obj(C), f_obj(F), object_component_touches(C, F).

test(not_touches_ac) :-
    a_obj(A), c_obj(C), \+ object_component_touches(A, C).

test(not_touches_ae) :-
    a_obj(A), e_obj(E), \+ object_component_touches(A, E).

test(not_touches_bc) :-
    b_obj(B), c_obj(C), \+ object_component_touches(B, C).

test(touches_symmetric) :-
    a_obj(A), b_obj(B),
    object_component_touches(A, B), object_component_touches(B, A).

% object_component_touching_pairs tests.

test(touching_pairs_ab) :-
    a_obj(A), b_obj(B), objs_abcdef(Objs),
    object_component_touching_pairs(Objs, Pairs),
    memberchk(A-B, Pairs).

test(touching_pairs_count) :-
    % A-B, A-D, B-F, C-F = 4 pairs.
    objs_abcdef(Objs),
    object_component_touching_pairs(Objs, Pairs),
    length(Pairs, 4).

test(touching_pairs_no_e) :-
    % E is isolated; no pair involves E.
    e_obj(E), objs_abcdef(Objs),
    object_component_touching_pairs(Objs, Pairs),
    \+ (memberchk(E-_, Pairs) ; memberchk(_-E, Pairs)).

test(touching_pairs_empty) :-
    e_obj(E), object_component_touching_pairs([E], Pairs), Pairs == [].

% object_component_adj_list tests.

test(adj_list_length) :-
    objs_abcdef(Objs),
    object_component_adj_list(Objs, AdjList),
    length(AdjList, 6).

test(adj_list_a_neighbors) :-
    a_obj(A), b_obj(B), d_obj(D), objs_abcdef(Objs),
    object_component_adj_list(Objs, AdjList),
    memberchk(A-Nbrs, AdjList),
    sort(Nbrs, Sorted),
    sort([B,D], Expected),
    Sorted == Expected.

test(adj_list_e_empty) :-
    e_obj(E), objs_abcdef(Objs),
    object_component_adj_list(Objs, AdjList),
    memberchk(E-Nbrs, AdjList),
    Nbrs == [].

% object_component_degree tests.

test(degree_a) :-
    % A touches B and D -> degree 2.
    a_obj(A), objs_abcdef(Objs),
    object_component_degree(A, Objs, D), D == 2.

test(degree_e_zero) :-
    e_obj(E), objs_abcdef(Objs),
    object_component_degree(E, Objs, D), D == 0.

test(degree_f) :-
    % F touches B and C -> degree 2.
    f_obj(F), objs_abcdef(Objs),
    object_component_degree(F, Objs, D), D == 2.

test(degree_c) :-
    % C touches only F -> degree 1.
    c_obj(C), objs_abcdef(Objs),
    object_component_degree(C, Objs, D), D == 1.

% object_component_isolated tests.

test(isolated_e_only) :-
    objs_abcdef(Objs), e_obj(E),
    object_component_isolated(Objs, Isolated),
    Isolated == [E].

test(isolated_empty_when_all_touch) :-
    a_obj(A), b_obj(B),
    object_component_isolated([A, B], Isolated),
    Isolated == [].

test(isolated_all_when_single) :-
    a_obj(A),
    object_component_isolated([A], Isolated),
    Isolated == [A].

% object_component_connected tests.

test(connected_from_a) :-
    % A-B-F-C chain plus D. Component of A = {A,B,C,D,F}.
    a_obj(A), b_obj(B), c_obj(C), d_obj(D), f_obj(F),
    objs_abcdef(Objs),
    object_component_connected(A, Objs, Comp),
    sort(Comp, Sorted),
    sort([A,B,C,D,F], Expected),
    Sorted == Expected.

test(connected_from_e) :-
    % E is isolated; its component is just [E].
    e_obj(E), objs_abcdef(Objs),
    object_component_connected(E, Objs, Comp),
    Comp == [E].

test(connected_from_c) :-
    % From C: can reach F, B, A, D. Same component as from A.
    a_obj(A), b_obj(B), c_obj(C), d_obj(D), f_obj(F),
    objs_abcdef(Objs),
    object_component_connected(C, Objs, Comp),
    sort(Comp, Sorted),
    sort([A,B,C,D,F], Expected),
    Sorted == Expected.

% object_component_components tests.

test(num_components_2) :-
    % Two components: {A,B,C,D,F} and {E}.
    objs_abcdef(Objs),
    object_component_num_components(Objs, N), N == 2.

test(components_sizes) :-
    objs_abcdef(Objs),
    object_component_components(Objs, Comps),
    findall(N, (member(C, Comps), length(C, N)), Sizes),
    sort(Sizes, Sorted),
    Sorted == [1, 5].

test(num_components_single_obj) :-
    a_obj(A), object_component_num_components([A], N), N == 1.

test(num_components_no_touching) :-
    a_obj(A), e_obj(E),
    object_component_num_components([A, E], N), N == 2.

% object_component_largest_component tests.

test(largest_component_5) :-
    a_obj(A), b_obj(B), c_obj(C), d_obj(D), f_obj(F),
    objs_abcdef(Objs),
    object_component_largest_component(Objs, Comp),
    sort(Comp, Sorted),
    sort([A,B,C,D,F], Expected),
    Sorted == Expected.

test(largest_component_single_list) :-
    a_obj(A), object_component_largest_component([A], Comp),
    Comp == [A].

% object_component_smallest_component tests.

test(smallest_component_e) :-
    e_obj(E), objs_abcdef(Objs),
    object_component_smallest_component(Objs, Comp),
    Comp == [E].

% object_component_singleton_components tests.

test(singletons_one) :-
    e_obj(E), objs_abcdef(Objs),
    object_component_singleton_components(Objs, Singles),
    Singles == [[E]].

test(singletons_empty_when_all_touching) :-
    a_obj(A), b_obj(B),
    object_component_singleton_components([A, B], Singles),
    Singles == [].

% object_component_shared_components tests.

test(shared_one) :-
    objs_abcdef(Objs),
    object_component_shared_components(Objs, Groups),
    length(Groups, 1).

test(shared_empty_all_isolated) :-
    a_obj(A), e_obj(E),
    object_component_shared_components([A, E], Groups),
    Groups == [].

% object_component_max_degree tests.

test(max_degree_abcdef) :-
    % Max degree: A has 2 (B,D), B has 2 (A,F), F has 2 (B,C). Max = 2.
    objs_abcdef(Objs),
    object_component_max_degree(Objs, MaxD),
    MaxD == 2.

test(max_degree_single_obj) :-
    a_obj(A), object_component_max_degree([A], MaxD), MaxD == 0.

% object_component_sort_by_degree tests.

test(sort_by_degree_first_is_min) :-
    % E has degree 0, so it should be first.
    objs_abcdef(Objs), e_obj(E),
    object_component_sort_by_degree(Objs, Sorted),
    Sorted = [E|_].

test(sort_by_degree_length) :-
    objs_abcdef(Objs),
    object_component_sort_by_degree(Objs, Sorted),
    length(Sorted, 6).

:- end_tests(object_component).
