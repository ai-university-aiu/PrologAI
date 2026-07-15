:- use_module('../prolog/gridops').
:- use_module(library(plunit)).

% Test grids:
% gs2: two 2x2 grids sharing col 0 and row 1 but differing at (0,1).
% gs3: three 2x2 grids; grids 0 and 2 are equal.
% gsadd: two grids for arithmetic tests.
% gsov: two grids with Bg=0 for overlay test.
% gsint: two grids with Bg=0 for intersect test.
% gseq: two identical grids for gridops_eq.
% gsne: two differing grids for gridops_eq fail.
% gmax: two grids for elementwise max/min.

gs2([[[1,2],[3,0]], [[1,5],[3,0]]]).
gs3([[[1,2],[3,4]], [[1,5],[3,0]], [[1,2],[3,4]]]).
gsadd([[[1,2],[3,4]], [[10,20],[30,40]]]).
gsov([[[1,0],[0,2]], [[0,3],[4,0]]]).
gsint([[[1,0],[0,2]], [[1,3],[4,0]]]).
gseq([[[1,2],[3,4]], [[1,2],[3,4]]]).
gsne([[[1,2],[3,4]], [[1,2],[3,5]]]).
gmax([[[1,5],[3,2]], [[4,2],[1,5]]]).

:- begin_tests(gridops).

% gridops_always: positions where EVERY grid has value V.
test(always_1) :- gs2(G), gridops_always(G, 1, C), C = [0-0].
test(always_2) :- gs2(G), gridops_always(G, 0, C), C = [1-1].
test(always_3) :- gs3(G), gridops_always(G, 1, C), C = [0-0].

% gridops_never: positions where NO grid has value V.
test(never_1) :- gs2(G), gridops_never(G, 0, C), C = [0-0,0-1,1-0].
test(never_2) :- gs3(G), gridops_never(G, 5, C), C = [0-0,1-0,1-1].
test(never_3) :- gs2(G), gridops_never(G, 99, C), C = [0-0,0-1,1-0,1-1].

% gridops_sometimes: positions where SOME but NOT ALL grids have value V.
test(sometimes_1) :- gs2(G), gridops_sometimes(G, 2, C), C = [0-1].
test(sometimes_2) :- gs3(G), gridops_sometimes(G, 4, C), C = [1-1].
test(sometimes_3) :- gs2(G), gridops_sometimes(G, 1, C), C = [].

% gridops_count_v: count of grids having V at each cell.
test(count_v_1) :-
    gs2(G), gridops_count_v(G, 0, CG), CG = [[0,0],[0,2]].
test(count_v_2) :-
    gs3(G), gridops_count_v(G, 1, CG), CG = [[3,0],[0,0]].
test(count_v_3) :-
    gs2(G), gridops_count_v(G, 5, CG), CG = [[0,1],[0,0]].

% gridops_modal: most frequent value per cell; smallest wins ties.
test(modal_1) :-
    gs2(G), gridops_modal(G, MG), MG = [[1,2],[3,0]].
test(modal_2) :-
    gs3(G), gridops_modal(G, MG), MG = [[1,2],[3,4]].
test(modal_3) :-
    G = [[[1,3],[2,4]], [[2,3],[1,4]]], gridops_modal(G, MG), MG = [[1,3],[1,4]].

% gridops_stable: positions where all grids agree on the same value.
test(stable_1) :-
    gs2(G), gridops_stable(G, T), T = [0-0-1, 1-0-3, 1-1-0].
test(stable_2) :-
    gs3(G), gridops_stable(G, T), T = [0-0-1, 1-0-3].
test(stable_3) :-
    gseq(G), gridops_stable(G, T), length(T, 4).

% gridops_unstable: positions where grids disagree.
test(unstable_1) :- gs2(G), gridops_unstable(G, C), C = [0-1].
test(unstable_2) :- gs3(G), gridops_unstable(G, C), C = [0-1,1-1].
test(unstable_3) :- gseq(G), gridops_unstable(G, C), C = [].

% gridops_eq: cell-for-cell grid equality.
test(eq_1) :- gridops_eq([[1,2],[3,4]], [[1,2],[3,4]]).
test(eq_2, [fail]) :- gridops_eq([[1,2],[3,4]], [[1,2],[3,5]]).
test(eq_3) :- gseq([G1,G2]), gridops_eq(G1, G2).

% gridops_add: elementwise integer addition.
test(add_1) :-
    gridops_add([[1,2],[3,4]], [[10,20],[30,40]], G), G = [[11,22],[33,44]].
test(add_2) :-
    gridops_add([[0,0],[0,0]], [[5,6],[7,8]], G), G = [[5,6],[7,8]].
test(add_3) :-
    gridops_add([[1,1],[1,1]], [[-1,-1],[-1,-1]], G), G = [[0,0],[0,0]].

% gridops_sub: elementwise integer subtraction.
test(sub_1) :-
    gridops_sub([[10,20],[30,40]], [[1,2],[3,4]], G), G = [[9,18],[27,36]].
test(sub_2) :-
    gridops_sub([[5,5],[5,5]], [[5,5],[5,5]], G), G = [[0,0],[0,0]].
test(sub_3) :-
    gridops_sub([[3,4],[5,6]], [[1,2],[3,4]], G), G = [[2,2],[2,2]].

% gridops_emax: elementwise maximum.
test(emax_1) :-
    gmax(G), G = [G1,G2], gridops_emax(G1, G2, R), R = [[4,5],[3,5]].
test(emax_2) :-
    gridops_emax([[1,2],[3,4]], [[4,3],[2,1]], R), R = [[4,3],[3,4]].
test(emax_3) :-
    gridops_emax([[0,0],[0,0]], [[1,2],[3,4]], R), R = [[1,2],[3,4]].

% gridops_emin: elementwise minimum.
test(emin_1) :-
    gmax(G), G = [G1,G2], gridops_emin(G1, G2, R), R = [[1,2],[1,2]].
test(emin_2) :-
    gridops_emin([[1,2],[3,4]], [[4,3],[2,1]], R), R = [[1,2],[2,1]].
test(emin_3) :-
    gridops_emin([[5,5],[5,5]], [[1,2],[3,4]], R), R = [[1,2],[3,4]].

% gridops_overlay: first non-Bg value per cell across grids.
test(overlay_1) :-
    gsov(G), gridops_overlay(G, 0, R), R = [[1,3],[4,2]].
test(overlay_2) :-
    gridops_overlay([[[0,0],[0,0]], [[1,2],[3,4]]], 0, R), R = [[1,2],[3,4]].
test(overlay_3) :-
    gridops_overlay([[[1,2],[3,4]], [[5,6],[7,8]]], 0, R), R = [[1,2],[3,4]].

% gridops_intersect: non-Bg value only where all grids agree on same non-Bg value.
test(intersect_1) :-
    gsint(G), gridops_intersect(G, 0, R), R = [[1,0],[0,0]].
test(intersect_2) :-
    gridops_intersect([[[1,2],[3,4]], [[1,2],[3,4]]], 9, R), R = [[1,2],[3,4]].
test(intersect_3) :-
    gridops_intersect([[[1,0],[0,2]], [[0,3],[4,0]]], 0, R), R = [[0,0],[0,0]].

:- end_tests(gridops).
