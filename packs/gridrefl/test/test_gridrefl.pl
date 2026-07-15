:- use_module('../prolog/gridrefl').

% Test grids:
%   g3    = [[1,2,3],[4,5,6],[7,8,9]]      standard 3x3 numeric
%   g2    = [[a,b],[c,d]]                  2x2
%   sym_h = [[1,2,1],[3,4,3],[5,6,5]]      horizontally symmetric (each row palindrome)
%   sym_v = [[1,2,3],[4,5,6],[1,2,3]]      vertically symmetric (row 0 = row 2)
%   sym_d = [[1,2,3],[2,4,5],[3,5,6]]      diagonally symmetric (= its own transpose)
%   sym_a = [[1,2,3],[4,5,2],[4,4,1]]      anti-diagonally symmetric
%   full  = [[1,2,1],[3,4,3],[1,2,1]]      both h-sym and v-sym
%   asym  = [[r,b],[b,g]]                  asymmetric 2x2

:- begin_tests(gridrefl).

% --- gridrefl_flip_h ---

test('AC-GRF-001: flip_h reverses each row') :-
    gridrefl_flip_h([[1,2,3],[4,5,6]], R),
    R = [[3,2,1],[6,5,4]].

test('AC-GRF-002: flip_h on 2x2') :-
    gridrefl_flip_h([[a,b],[c,d]], R),
    R = [[b,a],[d,c]].

test('AC-GRF-003: flip_h twice is identity') :-
    gridrefl_flip_h([[1,2,3],[4,5,6],[7,8,9]], R1),
    gridrefl_flip_h(R1, R2),
    R2 = [[1,2,3],[4,5,6],[7,8,9]].

% --- gridrefl_flip_v ---

test('AC-GRF-004: flip_v reverses row order') :-
    gridrefl_flip_v([[1,2],[3,4],[5,6]], R),
    R = [[5,6],[3,4],[1,2]].

test('AC-GRF-005: flip_v on g3') :-
    gridrefl_flip_v([[1,2,3],[4,5,6],[7,8,9]], R),
    R = [[7,8,9],[4,5,6],[1,2,3]].

test('AC-GRF-006: flip_v twice is identity') :-
    gridrefl_flip_v([[1,2,3],[4,5,6],[7,8,9]], R1),
    gridrefl_flip_v(R1, R2),
    R2 = [[1,2,3],[4,5,6],[7,8,9]].

% --- gridrefl_rot90 ---

test('AC-GRF-007: rot90 clockwise on g3') :-
    gridrefl_rot90([[1,2,3],[4,5,6],[7,8,9]], R),
    R = [[7,4,1],[8,5,2],[9,6,3]].

test('AC-GRF-008: rot90 on 2x2') :-
    gridrefl_rot90([[a,b],[c,d]], R),
    R = [[c,a],[d,b]].

test('AC-GRF-009: four rot90 steps return identity') :-
    G = [[1,2,3],[4,5,6],[7,8,9]],
    gridrefl_rot90(G, R1), gridrefl_rot90(R1, R2), gridrefl_rot90(R2, R3), gridrefl_rot90(R3, R4),
    R4 = G.

% --- gridrefl_rot180 ---

test('AC-GRF-010: rot180 on g3') :-
    gridrefl_rot180([[1,2,3],[4,5,6],[7,8,9]], R),
    R = [[9,8,7],[6,5,4],[3,2,1]].

test('AC-GRF-011: rot180 on 2x2') :-
    gridrefl_rot180([[a,b],[c,d]], R),
    R = [[d,c],[b,a]].

test('AC-GRF-012: rot180 twice is identity') :-
    gridrefl_rot180([[1,2,3],[4,5,6],[7,8,9]], R1),
    gridrefl_rot180(R1, R2),
    R2 = [[1,2,3],[4,5,6],[7,8,9]].

% --- gridrefl_rot270 ---

test('AC-GRF-013: rot270 clockwise on g3') :-
    gridrefl_rot270([[1,2,3],[4,5,6],[7,8,9]], R),
    R = [[3,6,9],[2,5,8],[1,4,7]].

test('AC-GRF-014: rot270 on 2x2') :-
    gridrefl_rot270([[a,b],[c,d]], R),
    R = [[b,d],[a,c]].

test('AC-GRF-015: rot90 then rot270 is identity') :-
    G = [[1,2,3],[4,5,6],[7,8,9]],
    gridrefl_rot90(G, R90),
    gridrefl_rot270(R90, Back),
    Back = G.

% --- gridrefl_transpose ---

test('AC-GRF-016: transpose on g3') :-
    gridrefl_transpose([[1,2,3],[4,5,6],[7,8,9]], T),
    T = [[1,4,7],[2,5,8],[3,6,9]].

test('AC-GRF-017: transpose on 2x3') :-
    gridrefl_transpose([[a,b,c],[d,e,f]], T),
    T = [[a,d],[b,e],[c,f]].

test('AC-GRF-018: transpose twice is identity') :-
    gridrefl_transpose([[1,2,3],[4,5,6],[7,8,9]], T1),
    gridrefl_transpose(T1, T2),
    T2 = [[1,2,3],[4,5,6],[7,8,9]].

% --- gridrefl_antidiag ---

test('AC-GRF-019: antidiag on g3') :-
    gridrefl_antidiag([[1,2,3],[4,5,6],[7,8,9]], R),
    R = [[9,6,3],[8,5,2],[7,4,1]].

test('AC-GRF-020: antidiag on 2x2') :-
    gridrefl_antidiag([[a,b],[c,d]], R),
    R = [[d,b],[c,a]].

test('AC-GRF-021: antidiag twice is identity') :-
    gridrefl_antidiag([[1,2,3],[4,5,6],[7,8,9]], R1),
    gridrefl_antidiag(R1, R2),
    R2 = [[1,2,3],[4,5,6],[7,8,9]].

% --- gridrefl_is_sym_h ---

test('AC-GRF-022: sym_h succeeds for palindrome rows') :-
    gridrefl_is_sym_h([[1,2,1],[3,4,3],[5,6,5]]).

test('AC-GRF-023: sym_h fails for non-symmetric grid') :-
    \+ gridrefl_is_sym_h([[1,2,3],[4,5,6],[7,8,9]]).

test('AC-GRF-024: sym_h succeeds for 2x2 palindrome') :-
    gridrefl_is_sym_h([[a,a],[b,b]]).

% --- gridrefl_is_sym_v ---

test('AC-GRF-025: sym_v succeeds when first and last rows equal') :-
    gridrefl_is_sym_v([[1,2,3],[4,5,6],[1,2,3]]).

test('AC-GRF-026: sym_v fails for asymmetric row order') :-
    \+ gridrefl_is_sym_v([[1,2,3],[4,5,6],[7,8,9]]).

test('AC-GRF-027: sym_v succeeds for single row') :-
    gridrefl_is_sym_v([[a,b,c]]).

% --- gridrefl_is_sym_d ---

test('AC-GRF-028: sym_d succeeds for diagonally symmetric grid') :-
    gridrefl_is_sym_d([[1,2,3],[2,4,5],[3,5,6]]).

test('AC-GRF-029: sym_d fails for non-symmetric grid') :-
    \+ gridrefl_is_sym_d([[1,2,3],[4,5,6],[7,8,9]]).

test('AC-GRF-030: sym_d succeeds for 2x2 symmetric') :-
    gridrefl_is_sym_d([[a,b],[b,d]]).

% --- gridrefl_is_sym_a ---

test('AC-GRF-031: sym_a succeeds for anti-diagonally symmetric grid') :-
% sym_a = [[1,2,3],[4,5,2],[4,4,1]] was verified above.
    gridrefl_is_sym_a([[1,2,3],[4,5,2],[4,4,1]]).

test('AC-GRF-032: sym_a fails for non-anti-symmetric grid') :-
    \+ gridrefl_is_sym_a([[1,2,3],[4,5,6],[7,8,9]]).

test('AC-GRF-033: sym_a succeeds for 2x2 anti-diagonal') :-
% [[a,b],[b,a]] is anti-diag-sym: antidiag([[a,b],[b,a]]) = [[a,b],[b,a]]
    gridrefl_is_sym_a([[a,b],[b,a]]).

% --- gridrefl_sym_axes ---

test('AC-GRF-034: sym_axes of fully h+v symmetric grid returns [h,v]') :-
    gridrefl_sym_axes([[1,2,1],[3,4,3],[1,2,1]], Axes),
    Axes = [h,v].

test('AC-GRF-035: sym_axes of asymmetric grid returns []') :-
    gridrefl_sym_axes([[1,2,3],[4,5,6],[7,8,9]], Axes),
    Axes = [].

test('AC-GRF-036: sym_axes of diagonally symmetric grid contains d') :-
    gridrefl_sym_axes([[1,2,3],[2,4,5],[3,5,6]], Axes),
    member(d, Axes).

% --- gridrefl_make_sym_h ---

test('AC-GRF-037: make_sym_h fills bg cells from mirror') :-
    gridrefl_make_sym_h([[r,b,b],[b,b,g]], b, R),
    R = [[r,b,r],[g,b,g]].

test('AC-GRF-038: make_sym_h on already-symmetric grid is identity') :-
    gridrefl_make_sym_h([[1,2,1],[3,4,3]], z, R),
    R = [[1,2,1],[3,4,3]].

test('AC-GRF-039: make_sym_h on all-bg grid stays all-bg') :-
    gridrefl_make_sym_h([[b,b,b],[b,b,b]], b, R),
    R = [[b,b,b],[b,b,b]].

% --- gridrefl_make_sym_v ---

test('AC-GRF-040: make_sym_v fills bg rows from mirror') :-
    gridrefl_make_sym_v([[r,g],[b,b],[b,g]], b, R),
    R = [[r,g],[b,b],[r,g]].

test('AC-GRF-041: make_sym_v on already-symmetric grid is identity') :-
    gridrefl_make_sym_v([[a,b],[c,d],[a,b]], z, R),
    R = [[a,b],[c,d],[a,b]].

test('AC-GRF-042: make_sym_v on all-bg grid stays all-bg') :-
    gridrefl_make_sym_v([[b,b],[b,b],[b,b]], b, R),
    R = [[b,b],[b,b],[b,b]].

% --- combined ---

test('AC-GRF-043: rot90 = transpose then flip_h') :-
    G = [[1,2,3],[4,5,6],[7,8,9]],
    gridrefl_rot90(G, R1),
    gridrefl_transpose(G, T), gridrefl_flip_h(T, R2),
    R1 = R2.

test('AC-GRF-044: rot90 + rot90 = rot180') :-
    G = [[1,2,3],[4,5,6],[7,8,9]],
    gridrefl_rot90(G, R90), gridrefl_rot90(R90, R180a),
    gridrefl_rot180(G, R180b),
    R180a = R180b.

:- end_tests(gridrefl).
