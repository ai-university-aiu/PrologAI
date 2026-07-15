:- use_module('../prolog/grid_diagonal').

% Grid fixtures
% 3x3 uniform grids
g3x3_all_r([[r,r,r],[r,r,r],[r,r,r]]).
% 3x3 with r diagonal (identity-like pattern)
g3x3_diag([[r,x,x],[x,r,x],[x,x,r]]).
% 3x3 anti-diagonal pattern
g3x3_anti([[x,x,r],[x,r,x],[r,x,x]]).
% 4x4 grid
g4x4([[a,b,c,d],[e,f,g,h],[i,j,k,l],[m,n,o,p]]).
% 2x3 grid (non-square)
g2x3([[r,r,x],[x,r,r]]).
% 3x2 grid (non-square)
g3x2([[r,x],[r,r],[x,r]]).
% 3x3 checkerboard
g3x3_checker([[r,x,r],[x,r,x],[r,x,r]]).

:- begin_tests(grid_diagonal).

% --- grid_diagonal_trace ---
test(trace_3x3_diag, []) :-
    g3x3_diag(G),
    grid_diagonal_trace(G, Vals),
    Vals = [r, r, r].

test(trace_3x3_all_r, []) :-
    g3x3_all_r(G),
    grid_diagonal_trace(G, [r, r, r]).

test(trace_4x4, []) :-
    g4x4(G),
    % Main diagonal: (0,0)=a,(1,1)=f,(2,2)=k,(3,3)=p
    grid_diagonal_trace(G, [a, f, k, p]).

test(trace_2x3, []) :-
    g2x3(G),
    % Main diagonal: (0,0)=r,(1,1)=r (length = min(2,3) = 2)
    grid_diagonal_trace(G, [r, r]).

% --- grid_diagonal_main_diag ---
test(main_diag_k0, []) :-
    g4x4(G),
    grid_diagonal_main_diag(G, 0, [a, f, k, p]).

test(main_diag_k1, []) :-
    g4x4(G),
    % K=1: (0,1)=b,(1,2)=g,(2,3)=l
    grid_diagonal_main_diag(G, 1, [b, g, l]).

test(main_diag_km1, []) :-
    g4x4(G),
    % K=-1: (1,0)=e,(2,1)=j,(3,2)=o
    grid_diagonal_main_diag(G, -1, [e, j, o]).

test(main_diag_corner_k3, []) :-
    g4x4(G),
    % K=3: only cell (0,3)=d
    grid_diagonal_main_diag(G, 3, [d]).

test(main_diag_corner_km3, []) :-
    g4x4(G),
    % K=-3: only cell (3,0)=m
    grid_diagonal_main_diag(G, -3, [m]).

% --- grid_diagonal_anti_diag ---
test(anti_diag_k0, []) :-
    g4x4(G),
    % K=0: only (0,0)=a
    grid_diagonal_anti_diag(G, 0, [a]).

test(anti_diag_k3, []) :-
    g4x4(G),
    % K=3: (0,3)=d,(1,2)=g,(2,1)=j,(3,0)=m (C ascending: 0,1,2,3 -> R=3,2,1,0)
    % Actually C in [max(0,3-3),min(3,3)] = [0,3] → C=0,1,2,3, R=3,2,1,0
    grid_diagonal_anti_diag(G, 3, [m, j, g, d]).

test(anti_diag_k1, []) :-
    g4x4(G),
    % K=1: C in [0,1], R=1,0 → (1,0)=e,(0,1)=b
    grid_diagonal_anti_diag(G, 1, [e, b]).

test(anti_diag_3x3, []) :-
    g3x3_anti(G),
    % K=2: (0,2)=r,(1,1)=r,(2,0)=r -> anti-diagonal of r's
    grid_diagonal_anti_diag(G, 2, [r, r, r]).

% --- grid_diagonal_all_main_diags ---
test(all_main_diags_count_3x3, []) :-
    g3x3_all_r(G),
    grid_diagonal_all_main_diags(G, Diags),
    % K from -2 to 2: 5 diagonals
    length(Diags, 5).

test(all_main_diags_4x4_count, []) :-
    g4x4(G),
    grid_diagonal_all_main_diags(G, Diags),
    % K from -3 to 3: 7 diagonals
    length(Diags, 7).

% --- grid_diagonal_all_anti_diags ---
test(all_anti_diags_count_3x3, []) :-
    g3x3_all_r(G),
    grid_diagonal_all_anti_diags(G, Diags),
    % K from 0 to 4: 5 anti-diagonals
    length(Diags, 5).

test(all_anti_diags_4x4_count, []) :-
    g4x4(G),
    grid_diagonal_all_anti_diags(G, Diags),
    % K from 0 to 6: 7 anti-diagonals
    length(Diags, 7).

% --- grid_diagonal_main_count ---
test(main_count_k0_all_r, []) :-
    g3x3_diag(G),
    grid_diagonal_main_count(G, 0, r, 3).

test(main_count_k1_diag, []) :-
    g3x3_diag(G),
    % K=1: (0,1)=x,(1,2)=x -> 0 r's
    grid_diagonal_main_count(G, 1, r, 0).

test(main_count_uniform, []) :-
    g3x3_all_r(G),
    grid_diagonal_main_count(G, 0, r, 3).

% --- grid_diagonal_anti_count ---
test(anti_count_k2_anti_diag, []) :-
    g3x3_anti(G),
    % K=2 is the anti-diagonal of r's
    grid_diagonal_anti_count(G, 2, r, 3).

test(anti_count_k0, []) :-
    g3x3_diag(G),
    % K=0: only (0,0)=r -> 1 r
    grid_diagonal_anti_count(G, 0, r, 1).

% --- grid_diagonal_main_uniform ---
test(main_uniform_k0_diag_yes, []) :-
    g3x3_diag(G),
    grid_diagonal_main_uniform(G, 0, yes).

test(main_uniform_k1_no, []) :-
    g3x3_checker(G),
    % K=1: (0,1)=x,(1,2)=x -> uniform x -> yes?
    % g3x3_checker = [[r,x,r],[x,r,x],[r,x,r]]
    % K=1: (0,1)=x,(1,2)=x -> [x,x] -> uniform yes
    grid_diagonal_main_uniform(G, 1, yes).

test(main_uniform_k0_checker, []) :-
    g3x3_checker(G),
    % K=0: (0,0)=r,(1,1)=r,(2,2)=r -> uniform yes
    grid_diagonal_main_uniform(G, 0, yes).

test(main_uniform_mixed_no, []) :-
    g3x3_anti(G),
    % K=0: (0,0)=x,(1,1)=r,(2,2)=x -> not uniform
    grid_diagonal_main_uniform(G, 0, no).

% --- grid_diagonal_anti_uniform ---
test(anti_uniform_k2_yes, []) :-
    g3x3_anti(G),
    % K=2: anti-diagonal of r's -> yes
    grid_diagonal_anti_uniform(G, 2, yes).

test(anti_uniform_k0_single_yes, []) :-
    g3x3_diag(G),
    % K=0: only (0,0)=r -> uniform yes
    grid_diagonal_anti_uniform(G, 0, yes).

test(anti_uniform_k1_no, []) :-
    g3x3_anti(G),
    % K=1: (0,1)=x,(1,0)=x -> uniform yes
    grid_diagonal_anti_uniform(G, 1, yes).

% --- grid_diagonal_set_main_diag ---
test(set_main_diag_k0, []) :-
    g3x3_all_r(G),
    % Set K=0 to x -> only main diagonal changes
    grid_diagonal_set_main_diag(G, 0, x, Result),
    nth0(0, Result, Row0), nth0(0, Row0, x),
    nth0(1, Result, Row1), nth0(1, Row1, x),
    nth0(2, Result, Row2), nth0(2, Row2, x).

test(set_main_diag_preserves_off, []) :-
    g3x3_all_r(G),
    grid_diagonal_set_main_diag(G, 0, x, Result),
    % Off-diagonal cells remain r
    nth0(0, Result, Row0), nth0(1, Row0, r).

% --- grid_diagonal_set_anti_diag ---
test(set_anti_diag_k2, []) :-
    g3x3_all_r(G),
    grid_diagonal_set_anti_diag(G, 2, x, Result),
    % K=2: (0,2),(1,1),(2,0) become x
    nth0(0, Result, Row0), nth0(2, Row0, x),
    nth0(1, Result, Row1), nth0(1, Row1, x),
    nth0(2, Result, Row2), nth0(0, Row2, x).

% --- grid_diagonal_uniform_main_diags ---
test(uniform_main_diags_all_r, []) :-
    g3x3_all_r(G),
    grid_diagonal_uniform_main_diags(G, Ks),
    % All 5 main diagonals of a uniform grid are uniform
    length(Ks, 5).

test(uniform_main_diags_diag_r, []) :-
    g3x3_diag(G),
    grid_diagonal_uniform_main_diags(G, Ks),
    % K=0 is [r,r,r] (yes); K=1 is [x,x] (yes); K=-1 is [x,x] (yes)
    % K=2 is [x] (yes); K=-2 is [x] (yes) -> all 5 are uniform
    length(Ks, 5).

% --- grid_diagonal_uniform_anti_diags ---
test(uniform_anti_diags_all_r, []) :-
    g3x3_all_r(G),
    grid_diagonal_uniform_anti_diags(G, Ks),
    % All 5 anti-diagonals of a uniform grid are uniform
    length(Ks, 5).

test(uniform_anti_diags_anti_r, []) :-
    g3x3_anti(G),
    % g3x3_anti = [[x,x,r],[x,r,x],[r,x,x]]
    % K=0: [x] yes; K=1: [x,x] yes; K=2: [r,r,r] yes; K=3: [x,x] yes; K=4: [x] yes
    grid_diagonal_uniform_anti_diags(G, Ks),
    length(Ks, 5).

% --- grid_diagonal_diag_length ---
test(diag_length_k0_square, []) :-
    g3x3_all_r(G),
    grid_diagonal_diag_length(G, 0, 3).

test(diag_length_k1, []) :-
    g3x3_all_r(G),
    grid_diagonal_diag_length(G, 1, 2).

test(diag_length_k2, []) :-
    g3x3_all_r(G),
    grid_diagonal_diag_length(G, 2, 1).

test(diag_length_4x4_k0, []) :-
    g4x4(G),
    grid_diagonal_diag_length(G, 0, 4).

test(diag_length_2x3_k0, []) :-
    g2x3(G),
    grid_diagonal_diag_length(G, 0, 2).

% --- Combined tests ---
test(trace_is_main_diag_0, []) :-
    g4x4(G),
    grid_diagonal_trace(G, T),
    grid_diagonal_main_diag(G, 0, T).

test(all_diags_total_cells, []) :-
    g3x3_all_r(G),
    grid_diagonal_all_main_diags(G, Diags),
    findall(N, (member(D, Diags), length(D, N)), Ns),
    % 1+2+3+2+1 = 9 = total cells
    sumlist(Ns, 9).

test(set_and_retrieve, []) :-
    g3x3_all_r(G),
    grid_diagonal_set_main_diag(G, 0, x, R),
    grid_diagonal_main_diag(R, 0, [x, x, x]).

:- end_tests(grid_diagonal).
