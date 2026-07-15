% PLUnit tests for the seek pack (sk_* predicates, Layer 76).
:- use_module(library(plunit)).
:- use_module(library(seek)).

:- begin_tests(seek_positions).

test(positions_basic) :-
    seek_positions([[0,1],[1,0]], 1, Cells),
    Cells = [0-1, 1-0].

test(positions_none) :-
    seek_positions([[2,2],[2,2]], 1, Cells),
    Cells = [].

test(positions_all) :-
    seek_positions([[1,1],[1,1]], 1, Cells),
    Cells = [0-0, 0-1, 1-0, 1-1].

test(positions_multi) :-
    seek_positions([[1,0,1],[0,1,0]], 1, Cells),
    Cells = [0-0, 0-2, 1-1].

:- end_tests(seek_positions).

:- begin_tests(seek_rows_with).

test(rows_with_basic) :-
    seek_rows_with([[1,0],[0,0],[1,1]], 1, RowIdxs),
    RowIdxs = [0, 2].

test(rows_with_none) :-
    seek_rows_with([[0,0],[0,0]], 1, RowIdxs),
    RowIdxs = [].

test(rows_with_all) :-
    seek_rows_with([[1,0],[1,0]], 1, RowIdxs),
    RowIdxs = [0, 1].

:- end_tests(seek_rows_with).

:- begin_tests(seek_cols_with).

test(cols_with_basic) :-
    seek_cols_with([[1,0,1],[0,1,0]], 1, ColIdxs),
    ColIdxs = [0, 1, 2].

test(cols_with_single) :-
    seek_cols_with([[1,0],[1,0]], 1, ColIdxs),
    ColIdxs = [0].

test(cols_with_none) :-
    seek_cols_with([[0,0],[0,0]], 1, ColIdxs),
    ColIdxs = [].

:- end_tests(seek_cols_with).

:- begin_tests(seek_border_cells).

test(border_2x2) :-
    seek_border_cells([[a,b],[c,d]], Cells),
    Cells = [0-0, 0-1, 1-0, 1-1].

test(border_3x3) :-
    seek_border_cells([[1,2,3],[4,5,6],[7,8,9]], Cells),
    length(Cells, 8),
    \+ memberchk(1-1, Cells).

test(border_1x1) :-
    seek_border_cells([[a]], Cells),
    Cells = [0-0].

:- end_tests(seek_border_cells).

:- begin_tests(seek_interior_cells).

test(interior_3x3) :-
    seek_interior_cells([[1,2,3],[4,5,6],[7,8,9]], Cells),
    Cells = [1-1].

test(interior_2x2) :-
    seek_interior_cells([[1,2],[3,4]], Cells),
    Cells = [].

test(interior_1x1) :-
    seek_interior_cells([[a]], Cells),
    Cells = [].

test(interior_4x4) :-
    seek_interior_cells([[0,0,0,0],[0,1,1,0],[0,1,1,0],[0,0,0,0]], Cells),
    Cells = [1-1, 1-2, 2-1, 2-2].

:- end_tests(seek_interior_cells).

:- begin_tests(seek_fits).

test(fits_basic) :-
    G = [[1,2,3],[4,5,6],[7,8,9]],
    Sub = [[5,6],[8,9]],
    seek_fits(G, Sub, 1, 1).

test(fits_corner) :-
    G = [[1,2,3],[4,5,6],[7,8,9]],
    Sub = [[1,2],[4,5]],
    seek_fits(G, Sub, 0, 0).

test(fits_no_match, [fail]) :-
    G = [[1,2],[3,4]],
    seek_fits(G, [[5]], 0, 0).

test(fits_out_of_bounds, [fail]) :-
    G = [[1,2],[3,4]],
    seek_fits(G, [[1,2],[3,4]], 1, 0).

:- end_tests(seek_fits).

:- begin_tests(seek_find_sub).

test(find_sub_basic) :-
    G = [[1,1,0],[0,1,1],[1,1,0]],
    Sub = [[1,1]],
    seek_all_subs(G, Sub, Cells),
    Cells = [0-0, 1-1, 2-0].

test(find_sub_none) :-
    G = [[1,2],[3,4]],
    Sub = [[5,6]],
    seek_all_subs(G, Sub, Cells),
    Cells = [].

test(find_sub_single) :-
    G = [[1,0],[0,1]],
    Sub = [[1,0]],
    seek_all_subs(G, Sub, Cells),
    Cells = [0-0].

:- end_tests(seek_find_sub).

:- begin_tests(seek_all_subs).

test(all_subs_multiple) :-
    G = [[1,1,1],[1,1,1]],
    Sub = [[1]],
    seek_all_subs(G, Sub, Cells),
    length(Cells, 6).

test(all_subs_exact) :-
    G = [[1,2],[3,4]],
    Sub = [[1,2],[3,4]],
    seek_all_subs(G, Sub, Cells),
    Cells = [0-0].

:- end_tests(seek_all_subs).

:- begin_tests(seek_count_sub).

test(count_sub_basic) :-
    G = [[1,1,0],[0,1,1],[1,1,0]],
    Sub = [[1,1]],
    seek_count_sub(G, Sub, N),
    N = 3.

test(count_sub_zero) :-
    G = [[1,2],[3,4]],
    Sub = [[5,6]],
    seek_count_sub(G, Sub, N),
    N = 0.

test(count_sub_one) :-
    G = [[1,0],[0,0]],
    Sub = [[1]],
    seek_count_sub(G, Sub, N),
    N = 1.

:- end_tests(seek_count_sub).

:- begin_tests(seek_match_count).

test(match_count_full) :-
    G = [[1,2],[3,4]],
    Sub = [[1,2],[3,4]],
    seek_match_count(G, Sub, 0, 0, N),
    N = 4.

test(match_count_partial) :-
    G = [[1,2],[3,4]],
    Sub = [[1,9],[9,4]],
    seek_match_count(G, Sub, 0, 0, N),
    N = 2.

test(match_count_none) :-
    G = [[1,2],[3,4]],
    Sub = [[5,6],[7,8]],
    seek_match_count(G, Sub, 0, 0, N),
    N = 0.

:- end_tests(seek_match_count).

:- begin_tests(seek_best_fit).

test(best_fit_basic) :-
    G = [[1,1,0],[1,1,0],[0,0,0]],
    Sub = [[1,1],[1,1]],
    seek_best_fit(G, Sub, R0, C0),
    R0 = 0,
    C0 = 0.

test(best_fit_single_pos) :-
    G = [[0,0,0],[0,1,0],[0,0,0]],
    Sub = [[1]],
    seek_best_fit(G, Sub, R0, C0),
    R0 = 1,
    C0 = 1.

:- end_tests(seek_best_fit).

:- begin_tests(seek_find_d4).

test(d4_identity) :-
    G = [[1,2],[3,4]],
    seek_find_d4(G, G, Name),
    Name = identity.

test(d4_reflect_h) :-
    G = [[1,2],[3,4]],
    G2 = [[2,1],[4,3]],
    seek_find_d4(G, G2, Name),
    Name = reflect_h.

test(d4_reflect_v) :-
    G = [[1,2],[3,4]],
    G2 = [[3,4],[1,2]],
    seek_find_d4(G, G2, Name),
    Name = reflect_v.

test(d4_transpose) :-
    G = [[1,2],[3,4]],
    G2 = [[1,3],[2,4]],
    seek_find_d4(G, G2, Name),
    Name = transpose.

test(d4_rotate90) :-
    G = [[1,2],[3,4]],
    G2 = [[3,1],[4,2]],
    seek_find_d4(G, G2, Name),
    Name = rotate90.

test(d4_rotate180) :-
    G = [[1,2],[3,4]],
    G2 = [[4,3],[2,1]],
    seek_find_d4(G, G2, Name),
    Name = rotate180.

test(d4_rotate270) :-
    G = [[1,2],[3,4]],
    G2 = [[2,4],[1,3]],
    seek_find_d4(G, G2, Name),
    Name = rotate270.

test(d4_anti_diag) :-
    G = [[1,2],[3,4]],
    G2 = [[4,2],[3,1]],
    seek_find_d4(G, G2, Name),
    Name = anti_diag.

test(d4_fail, [fail]) :-
    G1 = [[1,2],[3,4]],
    G2 = [[9,9],[9,9]],
    seek_find_d4(G1, G2, _).

:- end_tests(seek_find_d4).

:- begin_tests(seek_upscale).

test(upscale_2x) :-
    seek_upscale([[1,2],[3,4]], 2, Scaled),
    Scaled = [[1,1,2,2],[1,1,2,2],[3,3,4,4],[3,3,4,4]].

test(upscale_1x) :-
    seek_upscale([[5,6]], 1, Scaled),
    Scaled = [[5,6]].

test(upscale_3x_single) :-
    seek_upscale([[1]], 3, Scaled),
    Scaled = [[1,1,1],[1,1,1],[1,1,1]].

:- end_tests(seek_upscale).

:- begin_tests(seek_find_scale).

test(find_scale_2) :-
    Grid1 = [[1,2],[3,4]],
    seek_upscale(Grid1, 2, Grid2),
    seek_find_scale(Grid1, Grid2, Factor),
    Factor = 2.

test(find_scale_1) :-
    Grid1 = [[1,2],[3,4]],
    seek_find_scale(Grid1, Grid1, Factor),
    Factor = 1.

test(find_scale_fail, [fail]) :-
    Grid1 = [[1,2],[3,4]],
    Grid2 = [[1,2,3],[4,5,6]],
    seek_find_scale(Grid1, Grid2, _).

:- end_tests(seek_find_scale).
