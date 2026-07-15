:- use_module('../prolog/gridsymm').

% Grid fixtures
% Horizontally symmetric (top = bottom): rows 0 and 2 match, row 1 is center
g3x3_hsym([[r,b,r],[x,x,x],[r,b,r]]).
% Vertically symmetric (left = right): cols 0 and 2 match
g3x3_vsym([[r,x,r],[b,x,b],[r,x,r]]).
% Fully symmetric (D4): all symmetries hold
g3x3_d4sym([[r,x,r],[x,x,x],[r,x,r]]).
% No symmetry
g3x3_none([[a,b,c],[d,e,f],[g,h,i]]).
% Main diagonal symmetric (transpose = self)
g3x3_d1sym([[r,b,g],[b,x,h],[g,h,i]]).
% Anti-diagonal symmetric: Grid[R][C] = Grid[2-C][2-R]; pairs: (0,0)↔(2,2), (0,1)↔(1,2), (1,0)↔(2,1)
g3x3_d2sym([[r,b,g],[x,e,b],[s,x,r]]).
% 180-rotation symmetric
g3x3_rot180([[r,b,x],[x,e,x],[x,b,r]]).
% 90-rotation symmetric (uniform color)
g3x3_rot90([[r,r,r],[r,r,r],[r,r,r]]).
% 2x4 grid with h-symmetry (top-bottom)
g2x4_hsym([[r,b,g,x],[r,b,g,x]]).
% 4x2 grid with v-symmetry (left-right)
g4x2_vsym([[r,r],[b,b],[g,g],[x,x]]).
% Asymmetric grid for violation detection
g3x3_asym([[r,x,x],[x,b,x],[x,x,r]]).
% Grid with partial h-symmetry (one violation)
g3x3_h_partial([[r,r,r],[x,x,x],[r,b,r]]).
% Grid with h-symmetry but NOT v-symmetry: rows differ left-to-right
g3x3_h_only([[r,b,g],[x,x,x],[r,b,g]]).
% 1x1 grid (trivially symmetric)
g1x1([[q]]).
% 2x2 grids
g2x2_sym([[r,b],[b,r]]).
g2x2_asym([[r,b],[r,b]]).

:- begin_tests(gridsymm).

% --- gridsymm_sym_h ---
test(sym_h_fully_symmetric, []) :-
    g3x3_hsym(G),
    gridsymm_sym_h(G).

test(sym_h_d4_symmetric, []) :-
    g3x3_d4sym(G),
    gridsymm_sym_h(G).

test(sym_h_fails_for_asym, [fail]) :-
    g3x3_none(G),
    gridsymm_sym_h(G).

% --- gridsymm_sym_v ---
test(sym_v_fully_symmetric, []) :-
    g3x3_vsym(G),
    gridsymm_sym_v(G).

test(sym_v_d4_symmetric, []) :-
    g3x3_d4sym(G),
    gridsymm_sym_v(G).

test(sym_v_fails_for_asym, [fail]) :-
    g3x3_none(G),
    gridsymm_sym_v(G).

% --- gridsymm_sym_d1 ---
test(sym_d1_passes, []) :-
    g3x3_d1sym(G),
    gridsymm_sym_d1(G).

test(sym_d1_fails_non_square, [fail]) :-
    g2x4_hsym(G),
    gridsymm_sym_d1(G).

test(sym_d1_fails_asym, [fail]) :-
    g3x3_none(G),
    gridsymm_sym_d1(G).

% --- gridsymm_sym_d2 ---
test(sym_d2_passes, []) :-
    g3x3_d2sym(G),
    gridsymm_sym_d2(G).

test(sym_d2_fails_asym, [fail]) :-
    g3x3_none(G),
    gridsymm_sym_d2(G).

% --- gridsymm_sym_rot90 ---
test(sym_rot90_uniform, []) :-
    g3x3_rot90(G),
    gridsymm_sym_rot90(G).

test(sym_rot90_fails_asym, [fail]) :-
    g3x3_none(G),
    gridsymm_sym_rot90(G).

test(sym_rot90_fails_non_square, [fail]) :-
    g2x4_hsym(G),
    gridsymm_sym_rot90(G).

% --- gridsymm_sym_rot180 ---
test(sym_rot180_passes, []) :-
    g3x3_rot180(G),
    gridsymm_sym_rot180(G).

test(sym_rot180_2x2_sym, []) :-
    g2x2_sym(G),
    gridsymm_sym_rot180(G).

test(sym_rot180_fails_asym, [fail]) :-
    g3x3_none(G),
    gridsymm_sym_rot180(G).

% --- gridsymm_symmetries ---
test(symmetries_d4, []) :-
    g3x3_d4sym(G),
    gridsymm_symmetries(G, Syms),
    memberchk(h, Syms), memberchk(v, Syms), memberchk(rot180, Syms).

test(symmetries_none_is_empty, []) :-
    g3x3_none(G),
    gridsymm_symmetries(G, []).

test(symmetries_h_only, []) :-
    g3x3_h_only(G),
    gridsymm_symmetries(G, Syms),
    memberchk(h, Syms),
    \+ memberchk(v, Syms).

% --- gridsymm_complete_h ---
test(complete_h_top_symmetric_result, []) :-
    G = [[r,b],[x,x]],
    gridsymm_complete_h(G, top, R),
    R = [[r,b],[r,b]].

test(complete_h_bottom_symmetric_result, []) :-
    G = [[x,x],[r,b]],
    gridsymm_complete_h(G, bottom, R),
    R = [[r,b],[r,b]].

test(complete_h_already_symmetric, []) :-
    g3x3_hsym(G),
    gridsymm_complete_h(G, top, G).

% --- gridsymm_complete_v ---
test(complete_v_left_symmetric_result, []) :-
    G = [[r,x],[b,x]],
    gridsymm_complete_v(G, left, R),
    R = [[r,r],[b,b]].

test(complete_v_right_symmetric_result, []) :-
    G = [[x,r],[x,b]],
    gridsymm_complete_v(G, right, R),
    R = [[r,r],[b,b]].

test(complete_v_already_symmetric, []) :-
    g3x3_vsym(G),
    gridsymm_complete_v(G, left, G).

% --- gridsymm_complete_rot180 ---
test(complete_rot180_fills_bg, []) :-
    G = [[r,x],[x,x]],
    gridsymm_complete_rot180(G, x, R),
    R = [[r,x],[x,r]].

test(complete_rot180_preserves_non_bg, []) :-
    G = [[r,x],[x,b]],
    gridsymm_complete_rot180(G, x, R),
    R = [[r,x],[x,b]].

test(complete_rot180_already_symmetric, []) :-
    g3x3_rot180(G),
    gridsymm_complete_rot180(G, x, G).

% --- gridsymm_violations_h ---
test(violations_h_symmetric_is_empty, []) :-
    g3x3_hsym(G),
    gridsymm_violations_h(G, []).

test(violations_h_detects_violation, []) :-
    g3x3_h_partial(G),
    gridsymm_violations_h(G, Cells),
    Cells \= [].

test(violations_h_1x1_is_empty, []) :-
    g1x1(G),
    gridsymm_violations_h(G, []).

% --- gridsymm_violations_v ---
test(violations_v_symmetric_is_empty, []) :-
    g3x3_vsym(G),
    gridsymm_violations_v(G, []).

test(violations_v_detects_violation, []) :-
    g3x3_none(G),
    gridsymm_violations_v(G, Cells),
    Cells \= [].

% --- gridsymm_violations_rot180 ---
test(violations_rot180_symmetric_is_empty, []) :-
    g3x3_rot180(G),
    gridsymm_violations_rot180(G, []).

test(violations_rot180_detects_violation, []) :-
    g3x3_none(G),
    gridsymm_violations_rot180(G, Cells),
    Cells \= [].

% --- gridsymm_score ---
test(score_h_fully_symmetric_is_1, []) :-
    g3x3_hsym(G),
    gridsymm_score(G, h, S),
    S =:= 1.0.

test(score_v_partially_symmetric, []) :-
    G = [[r,x,r],[r,x,b],[r,x,r]],
    gridsymm_score(G, v, S),
    S > 0.0,
    S < 1.0.

test(score_rot180_fully_symmetric, []) :-
    g3x3_rot180(G),
    gridsymm_score(G, rot180, S),
    S =:= 1.0.

test(score_h_1x1_is_1, []) :-
    g1x1(G),
    gridsymm_score(G, h, S),
    S =:= 1.0.

% --- Combined tests ---
test(complete_h_then_sym_h, []) :-
    G = [[r,b],[x,x]],
    gridsymm_complete_h(G, top, R),
    gridsymm_sym_h(R).

test(complete_v_then_sym_v, []) :-
    G = [[r,x],[b,x]],
    gridsymm_complete_v(G, left, R),
    gridsymm_sym_v(R).

test(sym_rot180_implies_score_1, []) :-
    g3x3_rot180(G),
    gridsymm_score(G, rot180, S),
    S =:= 1.0.

test(violations_count_correct, []) :-
    G = [[r,x],[x,r]],
    gridsymm_violations_h(G, Cells),
    length(Cells, 2).

:- end_tests(gridsymm).
