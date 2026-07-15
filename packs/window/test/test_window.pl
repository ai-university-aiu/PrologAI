% PLUnit tests for the window pack (wn_* predicates, Layer 79).
:- use_module(library(plunit)).
:- use_module(library(window)).

:- begin_tests(window_neighbors4).

test(neighbors4_interior) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    window_neighbors4(Grid, 1, 1, Ns),
    length(Ns, 4).

test(neighbors4_corner) :-
    Grid = [[1,2],[3,4]],
    window_neighbors4(Grid, 0, 0, Ns),
    length(Ns, 2).

test(neighbors4_values) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    window_neighbors4(Grid, 1, 1, Ns),
    memberchk(0-1-2, Ns),
    memberchk(2-1-8, Ns),
    memberchk(1-0-4, Ns),
    memberchk(1-2-6, Ns).

:- end_tests(window_neighbors4).

:- begin_tests(window_neighbors8).

test(neighbors8_interior) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    window_neighbors8(Grid, 1, 1, Ns),
    length(Ns, 8).

test(neighbors8_corner) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    window_neighbors8(Grid, 0, 0, Ns),
    length(Ns, 3).

test(neighbors8_edge) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    window_neighbors8(Grid, 0, 1, Ns),
    length(Ns, 5).

:- end_tests(window_neighbors8).

:- begin_tests(window_count4).

test(count4_basic) :-
    Grid = [[0,1,0],[1,0,1],[0,1,0]],
    window_count4(Grid, 1, 1, 1, N),
    N = 4.

test(count4_zero) :-
    Grid = [[0,0,0],[0,1,0],[0,0,0]],
    window_count4(Grid, 1, 1, 1, N),
    N = 0.

test(count4_corner) :-
    Grid = [[1,1],[1,1]],
    window_count4(Grid, 0, 0, 1, N),
    N = 2.

:- end_tests(window_count4).

:- begin_tests(window_count8).

test(count8_basic) :-
    Grid = [[1,1,1],[1,0,1],[1,1,1]],
    window_count8(Grid, 1, 1, 1, N),
    N = 8.

test(count8_zero) :-
    Grid = [[0,0,0],[0,1,0],[0,0,0]],
    window_count8(Grid, 1, 1, 0, N),
    N = 8.

test(count8_corner) :-
    Grid = [[1,1],[1,1]],
    window_count8(Grid, 0, 0, 1, N),
    N = 3.

:- end_tests(window_count8).

:- begin_tests(window_extract).

test(extract_basic) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    window_extract(Grid, 0, 0, 2, 2, Sub),
    Sub = [[1,2],[4,5]].

test(extract_center) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    window_extract(Grid, 1, 1, 2, 2, Sub),
    Sub = [[5,6],[8,9]].

test(extract_row) :-
    Grid = [[1,2,3],[4,5,6]],
    window_extract(Grid, 0, 1, 1, 2, Sub),
    Sub = [[2,3]].

:- end_tests(window_extract).

:- begin_tests(window_slide).

test(slide_count) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    window_slide(Grid, 2, 2, Ws),
    length(Ws, 4).

test(slide_too_large) :-
    Grid = [[1,2],[3,4]],
    window_slide(Grid, 3, 3, Ws),
    Ws = [].

test(slide_first_window) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    window_slide(Grid, 2, 2, [W|_]),
    W = 0-0-[[1,2],[4,5]].

:- end_tests(window_slide).

:- begin_tests(window_pad).

test(pad_dimensions) :-
    Grid = [[1,2],[3,4]],
    window_pad(Grid, 0, 1, P),
    length(P, 4),
    P = [PRow|_],
    length(PRow, 4).

test(pad_zero) :-
    Grid = [[1,2],[3,4]],
    window_pad(Grid, 0, 0, P),
    P = [[1,2],[3,4]].

test(pad_values) :-
    Grid = [[5]],
    window_pad(Grid, 0, 1, P),
    P = [[0,0,0],[0,5,0],[0,0,0]].

:- end_tests(window_pad).

:- begin_tests(window_local_max4).

test(local_max4_true) :-
    Grid = [[1,2,1],[2,5,2],[1,2,1]],
    window_local_max4(Grid, 1, 1).

test(local_max4_false) :-
    Grid = [[1,2,1],[2,3,2],[1,2,1]],
    \+ window_local_max4(Grid, 0, 1).

test(local_max4_corner) :-
    Grid = [[5,1],[1,1]],
    window_local_max4(Grid, 0, 0).

:- end_tests(window_local_max4).

:- begin_tests(window_local_min4).

test(local_min4_true) :-
    Grid = [[5,2,5],[2,1,2],[5,2,5]],
    window_local_min4(Grid, 1, 1).

test(local_min4_false) :-
    Grid = [[1,2,1],[2,3,2],[1,2,1]],
    \+ window_local_min4(Grid, 1, 1).

test(local_min4_corner) :-
    Grid = [[1,5],[5,5]],
    window_local_min4(Grid, 0, 0).

:- end_tests(window_local_min4).

:- begin_tests(window_halo4).

test(halo4_basic) :-
    Grid = [[0,0,0],[0,1,0],[0,0,0]],
    window_halo4(Grid, 1, Cells),
    sort(Cells, Sorted),
    Sorted = [0-1, 1-0, 1-2, 2-1].

test(halo4_no_val) :-
    Grid = [[0,0],[0,0]],
    window_halo4(Grid, 1, Cells),
    Cells = [].

test(halo4_all_val) :-
    Grid = [[1,1],[1,1]],
    window_halo4(Grid, 1, Cells),
    Cells = [].

:- end_tests(window_halo4).

:- begin_tests(window_convolve).

test(convolve_basic) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    Kernel = [[1,0],[0,1]],
    window_convolve(Grid, Kernel, G2),
    G2 = [[6,8],[12,14]].

test(convolve_1x1) :-
    Grid = [[1,2],[3,4]],
    Kernel = [[2]],
    window_convolve(Grid, Kernel, G2),
    G2 = [[2,4],[6,8]].

test(convolve_too_large) :-
    Grid = [[1,2],[3,4]],
    Kernel = [[1,0,0],[0,1,0],[0,0,1]],
    window_convolve(Grid, Kernel, G2),
    G2 = [].

:- end_tests(window_convolve).

:- begin_tests(window_center).

test(center_odd) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    window_center(Grid, R, C),
    R = 1, C = 1.

test(center_even) :-
    Grid = [[1,2,3,4],[5,6,7,8]],
    window_center(Grid, R, C),
    R = 1, C = 2.

test(center_1x1) :-
    Grid = [[5]],
    window_center(Grid, R, C),
    R = 0, C = 0.

:- end_tests(window_center).

:- begin_tests(window_manhattan).

test(manhattan_basic) :-
    window_manhattan(0, 0, 2, 3, D),
    D = 5.

test(manhattan_zero) :-
    window_manhattan(1, 1, 1, 1, D),
    D = 0.

test(manhattan_negative_delta) :-
    window_manhattan(3, 3, 1, 1, D),
    D = 4.

:- end_tests(window_manhattan).

:- begin_tests(window_cells_at_dist).

test(cells_at_dist_basic) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    window_cells_at_dist(Grid, 1, 1, 1, Cells),
    sort(Cells, Sorted),
    Sorted = [0-1, 1-0, 1-2, 2-1].

test(cells_at_dist_zero) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    window_cells_at_dist(Grid, 1, 1, 0, Cells),
    Cells = [1-1].

test(cells_at_dist_boundary) :-
    Grid = [[1,2,3],[4,5,6],[7,8,9]],
    window_cells_at_dist(Grid, 0, 0, 2, Cells),
    sort(Cells, Sorted),
    Sorted = [0-2, 1-1, 2-0].

:- end_tests(window_cells_at_dist).
