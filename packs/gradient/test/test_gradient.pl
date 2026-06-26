% test_gradient.pl - 42 PLUnit tests for the gradient pack (gr_* predicates).
:- use_module('../prolog/gradient.pl').

% Shared test grids.
% G3inc: 3x3 grid with increasing rows and columns.
g3inc([[1,2,3],[4,5,6],[7,8,9]]).
% G3dec: 3x3 grid with decreasing rows, increasing columns.
g3dec([[3,2,1],[6,5,4],[9,8,7]]).
% G3cdec: 3x3 grid with increasing rows, decreasing columns.
g3cdec([[7,8,9],[4,5,6],[1,2,3]]).
% G3flat: 3x3 grid with constant rows, increasing columns.
g3flat([[1,1,1],[2,2,2],[3,3,3]]).

% Tests for gr_h_diffs/2.
:- begin_tests(gr_h_diffs).
test(inc_rows) :- g3inc(G), gr_h_diffs(G, D), D = [[1,1],[1,1],[1,1]].
test(dec_rows) :- g3dec(G), gr_h_diffs(G, D), D = [[-1,-1],[-1,-1],[-1,-1]].
test(const_rows) :- g3flat(G), gr_h_diffs(G, D), D = [[0,0],[0,0],[0,0]].
:- end_tests(gr_h_diffs).

% Tests for gr_v_diffs/2.
:- begin_tests(gr_v_diffs).
test(inc_grid) :- g3inc(G), gr_v_diffs(G, D), D = [[3,3,3],[3,3,3]].
test(dec_grid) :- g3cdec(G), gr_v_diffs(G, D), D = [[-3,-3,-3],[-3,-3,-3]].
test(flat_v) :- g3flat(G), gr_v_diffs(G, D), D = [[1,1,1],[1,1,1]].
:- end_tests(gr_v_diffs).

% Tests for gr_h_mono/2.
:- begin_tests(gr_h_mono).
test(mono_inc) :- g3inc(G), gr_h_mono(G, F), F = [1,1,1].
test(mono_dec) :- g3dec(G), gr_h_mono(G, F), F = [-1,-1,-1].
test(mono_const) :- g3flat(G), gr_h_mono(G, F), F = [1,1,1].
:- end_tests(gr_h_mono).

% Tests for gr_v_mono/2.
:- begin_tests(gr_v_mono).
test(vmono_inc) :- g3inc(G), gr_v_mono(G, F), F = [1,1,1].
test(vmono_dec) :- g3cdec(G), gr_v_mono(G, F), F = [-1,-1,-1].
test(vmono_flat) :- g3flat(G), gr_v_mono(G, F), F = [1,1,1].
:- end_tests(gr_v_mono).

% Tests for gr_h_range/2.
:- begin_tests(gr_h_range).
test(range_inc) :- g3inc(G), gr_h_range(G, R), R = [2,2,2].
test(range_flat) :- g3flat(G), gr_h_range(G, R), R = [0,0,0].
test(range_dec) :- g3dec(G), gr_h_range(G, R), R = [2,2,2].
:- end_tests(gr_h_range).

% Tests for gr_v_range/2.
:- begin_tests(gr_v_range).
test(vrange_inc) :- g3inc(G), gr_v_range(G, R), R = [6,6,6].
test(vrange_flat) :- g3flat(G), gr_v_range(G, R), R = [2,2,2].
test(vrange_dec) :- g3dec(G), gr_v_range(G, R), R = [6,6,6].
:- end_tests(gr_v_range).

% Tests for gr_h_slope/2.
:- begin_tests(gr_h_slope).
test(slope_inc) :- g3inc(G), gr_h_slope(G, S), S = [2,2,2].
test(slope_dec) :- g3dec(G), gr_h_slope(G, S), S = [-2,-2,-2].
test(slope_flat) :- g3flat(G), gr_h_slope(G, S), S = [0,0,0].
:- end_tests(gr_h_slope).

% Tests for gr_v_slope/2.
:- begin_tests(gr_v_slope).
test(vslope_inc) :- g3inc(G), gr_v_slope(G, S), S = [6,6,6].
test(vslope_dec) :- g3cdec(G), gr_v_slope(G, S), S = [-6,-6,-6].
test(vslope_flat) :- g3flat(G), gr_v_slope(G, S), S = [2,2,2].
:- end_tests(gr_v_slope).

% Tests for gr_h_const/2.
:- begin_tests(gr_h_const).
test(const_inc) :- g3inc(G), gr_h_const(G, B), B = [0,0,0].
test(const_flat) :- g3flat(G), gr_h_const(G, B), B = [1,1,1].
test(const_mixed) :- gr_h_const([[1,1,2],[2,2,2],[3,3,3]], B), B = [0,1,1].
:- end_tests(gr_h_const).

% Tests for gr_v_const/2.
:- begin_tests(gr_v_const).
test(vconst_flat) :- g3flat(G), gr_v_const(G, B), B = [0,0,0].
test(vconst_inc) :- g3inc(G), gr_v_const(G, B), B = [0,0,0].
test(vconst_all) :- gr_v_const([[1,2],[1,2],[1,2]], B), B = [1,1].
:- end_tests(gr_v_const).

% Tests for gr_h_cum/2.
:- begin_tests(gr_h_cum).
test(hcum_inc) :- g3inc(G), gr_h_cum(G, C), C = [[1,3,6],[4,9,15],[7,15,24]].
test(hcum_flat) :- g3flat(G), gr_h_cum(G, C), C = [[1,2,3],[2,4,6],[3,6,9]].
test(hcum_single) :- gr_h_cum([[1],[2],[3]], C), C = [[1],[2],[3]].
:- end_tests(gr_h_cum).

% Tests for gr_v_cum/2.
:- begin_tests(gr_v_cum).
test(vcum_inc) :- g3inc(G), gr_v_cum(G, C), C = [[1,2,3],[5,7,9],[12,15,18]].
test(vcum_flat) :- g3flat(G), gr_v_cum(G, C), C = [[1,1,1],[3,3,3],[6,6,6]].
test(vcum_single) :- gr_v_cum([[1,2,3]], C), C = [[1,2,3]].
:- end_tests(gr_v_cum).

% Tests for gr_h_second/2.
:- begin_tests(gr_h_second).
test(h2nd_linear) :- g3inc(G), gr_h_second(G, D), D = [[0],[0],[0]].
test(h2nd_quad) :- gr_h_second([[1,2,4],[1,2,4],[1,2,4]], D), D = [[1],[1],[1]].
test(h2nd_flat) :- g3flat(G), gr_h_second(G, D), D = [[0],[0],[0]].
:- end_tests(gr_h_second).

% Tests for gr_v_second/2.
:- begin_tests(gr_v_second).
test(v2nd_linear) :- g3inc(G), gr_v_second(G, D), D = [[0,0,0]].
test(v2nd_quad) :- gr_v_second([[1,1,1],[2,2,2],[4,4,4],[7,7,7]], D), D = [[1,1,1],[1,1,1]].
test(v2nd_flat) :- g3flat(G), gr_v_second(G, D), D = [[0,0,0]].
:- end_tests(gr_v_second).
