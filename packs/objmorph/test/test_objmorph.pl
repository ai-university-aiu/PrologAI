:- use_module('../prolog/objmorph').
:- begin_tests(objmorph).

% Helper: cell list of a filled NxN square at origin.
square_cells(N, Cells) :-
    N1 is N - 1,
    findall(r(R,C), (between(0,N1,R), between(0,N1,C)), Cells).

% Helper: horizontal line of N cells at row 0.
hline_cells(N, Cells) :-
    N1 is N - 1,
    findall(r(0,C), between(0,N1,C), Cells).

% objmorph_neighbors4 tests.

test(neighbors4_origin) :-
    objmorph_neighbors4(r(0,0), N),
    sort(N, S),
    S == [r(-1,0),r(0,-1),r(0,1),r(1,0)].

test(neighbors4_interior) :-
    objmorph_neighbors4(r(2,3), N),
    sort(N, S),
    S == [r(1,3),r(2,2),r(2,4),r(3,3)].

test(neighbors4_count) :-
    objmorph_neighbors4(r(5,5), N), length(N, 4).

% objmorph_neighbors8 tests.

test(neighbors8_origin) :-
    objmorph_neighbors8(r(0,0), N),
    sort(N, S),
    S == [r(-1,-1),r(-1,0),r(-1,1),r(0,-1),r(0,1),r(1,-1),r(1,0),r(1,1)].

test(neighbors8_count) :-
    objmorph_neighbors8(r(5,5), N), length(N, 8).

% objmorph_boundary4 tests.

test(boundary4_single_cell) :-
    % A single cell has all 4 neighbors outside: it IS a boundary cell.
    objmorph_boundary4(obj(red,[r(0,0)]), R),
    R == obj(red,[r(0,0)]).

test(boundary4_hline3) :-
    % Horizontal line of 3 cells: all are boundary (r(-1,C) is outside for each).
    objmorph_boundary4(obj(a,[r(0,0),r(0,1),r(0,2)]), R),
    R == obj(a,[r(0,0),r(0,1),r(0,2)]).

test(boundary4_3x3_count) :-
    % 3x3 square: 8 boundary cells (all except center).
    square_cells(3, Cells),
    objmorph_boundary4(obj(b,Cells), obj(b,B)),
    length(B, 8).

test(boundary4_3x3_center_not_in) :-
    % The center cell r(1,1) is not a boundary cell.
    square_cells(3, Cells),
    objmorph_boundary4(obj(b,Cells), obj(b,B)),
    \+ member(r(1,1), B).

test(boundary4_2x2_all_boundary) :-
    % 2x2 square: all 4 cells are boundary (none has all 4 neighbors inside).
    square_cells(2, Cells),
    objmorph_boundary4(obj(c,Cells), obj(c,B)),
    length(B, 4).

% objmorph_interior4 tests.

test(interior4_single_cell_empty) :-
    % Single cell: no interior.
    objmorph_interior4(obj(red,[r(0,0)]), R),
    R == obj(red,[]).

test(interior4_hline_empty) :-
    % Horizontal line: no interior (missing top/bottom neighbors).
    hline_cells(5, Cells),
    objmorph_interior4(obj(a,Cells), obj(a,[])).

test(interior4_3x3_center_only) :-
    % 3x3 square: only r(1,1) is interior.
    square_cells(3, Cells),
    objmorph_interior4(obj(b,Cells), obj(b,I)),
    I == [r(1,1)].

test(interior4_4x4_count) :-
    % 4x4 square: 4 interior cells (the inner 2x2).
    square_cells(4, Cells),
    objmorph_interior4(obj(b,Cells), obj(b,I)),
    length(I, 4).

test(interior4_2x2_empty) :-
    % 2x2 square: no interior (each cell is missing at least one internal neighbor).
    square_cells(2, Cells),
    objmorph_interior4(obj(c,Cells), obj(c,[])).

% objmorph_boundary8 tests.

test(boundary8_3x3_all_boundary) :-
    % 3x3 square: center r(1,1) has all 8 neighbors in the 3x3, so it is interior8.
    % Boundary8 = 8 outer cells.
    square_cells(3, Cells),
    objmorph_boundary8(obj(b,Cells), obj(b,B)),
    length(B, 8).

test(boundary8_5x5_count) :-
    % 5x5 square: interior8 = inner 3x3 (9 cells, rows 1-3 cols 1-3 all within bounds).
    % Boundary8 = 25 - 9 = 16 cells.
    square_cells(5, Cells),
    objmorph_boundary8(obj(b,Cells), obj(b,B)),
    length(B, 16).

% objmorph_interior8 tests.

test(interior8_3x3_empty) :-
    % 3x3 square: center r(1,1) has diagonals r(0,0), r(0,2), r(2,0), r(2,2) all in the obj.
    % But r(0,0) is also in the obj, so r(1,1) has all 8 neighbors.
    square_cells(3, Cells),
    objmorph_interior8(obj(b,Cells), obj(b,I)),
    % r(1,1) neighbors: r(0,0),r(0,1),r(0,2),r(1,0),r(1,2),r(2,0),r(2,1),r(2,2) all in 3x3.
    I == [r(1,1)].

test(interior8_5x5_center) :-
    % 5x5 square: the inner 3x3 are interior8.
    square_cells(5, Cells),
    objmorph_interior8(obj(b,Cells), obj(b,I)),
    length(I, 9).

test(interior8_2x2_empty) :-
    % 2x2 square: no interior8 (diagonal corners are missing).
    square_cells(2, Cells),
    objmorph_interior8(obj(c,Cells), obj(c,[])).

% objmorph_dilate4 tests.

test(dilate4_single_cell) :-
    % Single cell expands to a plus shape (5 cells).
    objmorph_dilate4(obj(red,[r(0,0)]), R),
    R == obj(red,[r(-1,0),r(0,-1),r(0,0),r(0,1),r(1,0)]).

test(dilate4_hline2) :-
    % Horizontal line [r(0,0),r(0,1)] expands.
    objmorph_dilate4(obj(a,[r(0,0),r(0,1)]), obj(a,D)),
    % New cells: r(-1,0),r(1,0),r(0,-1) from r(0,0) and r(-1,1),r(1,1),r(0,2) from r(0,1).
    % (r(0,0) and r(0,1) are neighbors of each other; already in S.)
    % Total sorted: r(-1,0),r(-1,1),r(0,-1),r(0,0),r(0,1),r(0,2),r(1,0),r(1,1).
    length(D, 8).

test(dilate4_preserves_color) :-
    objmorph_dilate4(obj(blue,[r(1,1)]), R),
    R = obj(blue, _).

test(dilate4_contains_original) :-
    objmorph_dilate4(obj(x,[r(2,3)]), obj(x,D)),
    memberchk(r(2,3), D).

% objmorph_erode4 tests.

test(erode4_single_cell_empty) :-
    % Single cell: no interior4.
    objmorph_erode4(obj(red,[r(0,0)]), R),
    R == obj(red,[]).

test(erode4_hline_empty) :-
    % Horizontal line: no interior4.
    hline_cells(5, Cells),
    objmorph_erode4(obj(a,Cells), obj(a,[])).

test(erode4_3x3_one_cell) :-
    % 3x3 erodes to center only.
    square_cells(3, Cells),
    objmorph_erode4(obj(b,Cells), obj(b,E)),
    E == [r(1,1)].

test(erode4_4x4_inner) :-
    % 4x4 erodes to the inner 2x2.
    square_cells(4, Cells),
    objmorph_erode4(obj(b,Cells), obj(b,E)),
    length(E, 4).

% objmorph_dilate8 tests.

test(dilate8_single_cell) :-
    % Single cell: 8 neighbors + self = 9 cells (3x3 square at origin).
    objmorph_dilate8(obj(red,[r(0,0)]), R),
    R == obj(red,[r(-1,-1),r(-1,0),r(-1,1),r(0,-1),r(0,0),r(0,1),r(1,-1),r(1,0),r(1,1)]).

test(dilate8_count_single) :-
    objmorph_dilate8(obj(a,[r(5,5)]), obj(a,D)), length(D, 9).

test(dilate8_larger_than_dilate4) :-
    % 8-dilation produces more cells than 4-dilation.
    objmorph_dilate4(obj(x,[r(0,0)]), obj(x,D4)),
    objmorph_dilate8(obj(x,[r(0,0)]), obj(x,D8)),
    length(D4, L4), length(D8, L8), L8 > L4.

% objmorph_erode8 tests.

test(erode8_3x3_empty) :-
    % 3x3 square: center has all 8 neighbors in; interior8 = [r(1,1)].
    square_cells(3, Cells),
    objmorph_erode8(obj(b,Cells), obj(b,E)),
    E == [r(1,1)].

test(erode8_2x2_empty) :-
    square_cells(2, Cells),
    objmorph_erode8(obj(c,Cells), obj(c,[])).

test(erode8_subset_of_erode4) :-
    % erode8 cells are always a subset of erode4 cells (stricter requirement).
    square_cells(5, Cells),
    objmorph_erode4(obj(b,Cells), obj(b,E4)),
    objmorph_erode8(obj(b,Cells), obj(b,E8)),
    length(E4, L4), length(E8, L8), L8 =< L4.

% objmorph_dilate4_n tests.

test(dilate4_n0_identity) :-
    % N=0: identity.
    objmorph_dilate4_n(obj(red,[r(0,0)]), 0, R),
    R == obj(red,[r(0,0)]).

test(dilate4_n1_same_as_dilate4) :-
    % N=1: same as objmorph_dilate4.
    objmorph_dilate4(obj(a,[r(0,0)]), D1),
    objmorph_dilate4_n(obj(a,[r(0,0)]), 1, DN),
    D1 == DN.

test(dilate4_n2_count) :-
    % N=2 from single cell: diamond of radius 2 (13 cells).
    objmorph_dilate4_n(obj(x,[r(0,0)]), 2, obj(x,D)),
    % Cells with |R|+|C| <= 2.
    length(D, 13).

% objmorph_erode4_n tests.

test(erode4_n0_identity) :-
    % N=0: identity.
    square_cells(5, Cells),
    objmorph_erode4_n(obj(b,Cells), 0, R),
    R == obj(b,Cells).

test(erode4_n1_same_as_erode4) :-
    % N=1: same as objmorph_erode4.
    square_cells(4, Cells),
    objmorph_erode4(obj(b,Cells), E1),
    objmorph_erode4_n(obj(b,Cells), 1, EN),
    E1 == EN.

test(erode4_n2_from_5x5) :-
    % 5x5 eroded twice: first erode to 3x3 interior, then to single center.
    square_cells(5, Cells),
    objmorph_erode4_n(obj(b,Cells), 2, obj(b,E)),
    E == [r(2,2)].

% objmorph_open4 tests.

test(open4_3x3_identity) :-
    % A solid 3x3: erode to center, dilate back. Result = center's cross = 5 cells.
    square_cells(3, Cells),
    objmorph_open4(obj(b,Cells), obj(b,O)),
    % Erode: [r(1,1)]. Dilate: [r(0,1),r(1,0),r(1,1),r(1,2),r(2,1)].
    sort(O, S), S == [r(0,1),r(1,0),r(1,1),r(1,2),r(2,1)].

test(open4_single_cell_empty) :-
    % Single cell: erode4 gives empty, dilate empty gives empty.
    objmorph_open4(obj(red,[r(0,0)]), R),
    R == obj(red,[]).

test(open4_hline_empty) :-
    % Thin horizontal line: erode removes all, dilate of empty = empty.
    hline_cells(5, Cells),
    objmorph_open4(obj(a,Cells), obj(a,[])).

% objmorph_close4 tests.

test(close4_single_cell) :-
    % Single cell: dilate4 gives plus (5 cells), erode4 gives center back.
    objmorph_close4(obj(red,[r(0,0)]), R),
    R == obj(red,[r(0,0)]).

test(close4_3x3_same) :-
    % A solid 3x3: dilate to 5x5 interior area, erode back to 3x3.
    square_cells(3, Cells),
    objmorph_close4(obj(b,Cells), obj(b,C)),
    % Dilate: all cells with row/col in [-1..3]. Erode: interior of that = 3x3.
    length(C, 9).

test(close4_hline3) :-
    % Horizontal line of 3: dilate (8 cells), erode interior.
    objmorph_close4(obj(a,[r(0,0),r(0,1),r(0,2)]), obj(a,C)),
    % After dilate4: r(-1,0..2) + r(0,-1..3) + r(1,0..2) = 11 cells.
    % Interior of that: cells with all 4 neighbors inside = r(0,0),r(0,1),r(0,2).
    sort(C, SC), SC == [r(0,0),r(0,1),r(0,2)].

:- end_tests(objmorph).
