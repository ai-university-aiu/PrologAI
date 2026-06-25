:- use_module('../prolog/enclosure').

:- begin_tests(enclosure).

% en_border_cells/2 tests

% 3x3 ring: 8 perimeter cells returned in sorted order.
test(border_cells_3x3) :-
    en_border_cells([[1,1,1],[1,0,1],[1,1,1]], Cells),
    Cells = [0-0,0-1,0-2,1-0,1-2,2-0,2-1,2-2].

% 1x3 grid (single row): all three cells lie on the border.
test(border_cells_1x3) :-
    en_border_cells([[0,1,0]], Cells),
    Cells = [0-0,0-1,0-2].

% 2x2 grid: all four cells are border cells.
test(border_cells_2x2) :-
    en_border_cells([[0,1],[1,0]], Cells),
    Cells = [0-0,0-1,1-0,1-1].

% en_outer_cells/3 tests

% All border cells are wall (value 1); no Bg cell is reachable from the border.
test(outer_cells_enclosed) :-
    en_outer_cells([[1,1,1],[1,0,1],[1,1,1]], 0, Outer),
    Outer = [].

% Two border Bg cells separated by a wall; each is a separate outer region.
test(outer_cells_separated) :-
    en_outer_cells([[0,1,0]], 0, Outer),
    Outer = [0-0,0-2].

% All border cells are Bg; BFS from them reaches all 8 perimeter cells.
test(outer_cells_all_border) :-
    en_outer_cells([[0,0,0],[0,1,0],[0,0,0]], 0, Outer),
    sort(Outer, S),
    S = [0-0,0-1,0-2,1-0,1-2,2-0,2-1,2-2].

% en_inner_cells/3 tests

% 3x3 ring of walls enclosing exactly one Bg cell at (1,1).
test(inner_cells_one) :-
    en_inner_cells([[1,1,1],[1,0,1],[1,1,1]], 0, Inner),
    Inner = [1-1].

% No enclosed Bg cells when background touches the border.
test(inner_cells_none) :-
    en_inner_cells([[0,1,0]], 0, Inner),
    Inner = [].

% 4x4 ring enclosing a 2x2 block of Bg cells.
test(inner_cells_four) :-
    en_inner_cells([[1,1,1,1],[1,0,0,1],[1,0,0,1],[1,1,1,1]], 0, Inner),
    Inner = [1-1,1-2,2-1,2-2].

% en_is_inner/4 tests

% The sole enclosed cell (1,1) is correctly identified as inner.
test(is_inner_yes) :-
    en_is_inner([[1,1,1],[1,0,1],[1,1,1]], 1, 1, 0).

% An outer Bg cell on the border is not inner.
test(is_inner_outer, [fail]) :-
    en_is_inner([[0,1,0]], 0, 0, 0).

% A wall cell (value not equal to Bg) cannot be inner.
test(is_inner_wall, [fail]) :-
    en_is_inner([[1,1,1],[1,0,1],[1,1,1]], 0, 0, 0).

% en_is_outer/4 tests

% A border Bg cell is correctly identified as outer.
test(is_outer_yes) :-
    en_is_outer([[0,1,0]], 0, 0, 0).

% An enclosed Bg cell is not outer.
test(is_outer_inner, [fail]) :-
    en_is_outer([[1,1,1],[1,0,1],[1,1,1]], 1, 1, 0).

% A wall cell (value not equal to Bg) cannot be outer.
test(is_outer_wall, [fail]) :-
    en_is_outer([[1,1,1],[1,0,1],[1,1,1]], 0, 0, 0).

% en_fill_inner/4 tests

% Fill the single enclosed cell with Color 2.
test(fill_inner_one) :-
    en_fill_inner([[1,1,1],[1,0,1],[1,1,1]], 0, 2, Out),
    Out = [[1,1,1],[1,2,1],[1,1,1]].

% No enclosed cells; grid is returned unchanged.
test(fill_inner_none) :-
    en_fill_inner([[0,1,0]], 0, 2, Out),
    Out = [[0,1,0]].

% Fill four enclosed cells in a 4x4 ring with Color 3.
test(fill_inner_four) :-
    en_fill_inner([[1,1,1,1],[1,0,0,1],[1,0,0,1],[1,1,1,1]], 0, 3, Out),
    Out = [[1,1,1,1],[1,3,3,1],[1,3,3,1],[1,1,1,1]].

% en_inner_count/3 tests

% One enclosed cell gives count 1.
test(inner_count_one) :-
    en_inner_count([[1,1,1],[1,0,1],[1,1,1]], 0, N), N = 1.

% No enclosed cells gives count 0.
test(inner_count_zero) :-
    en_inner_count([[0,1,0]], 0, N), N = 0.

% Four enclosed cells gives count 4.
test(inner_count_four) :-
    en_inner_count([[1,1,1,1],[1,0,0,1],[1,0,0,1],[1,1,1,1]], 0, N), N = 4.

% en_has_inner/2 tests

% Grid with an enclosed cell succeeds.
test(has_inner_yes) :-
    en_has_inner([[1,1,1],[1,0,1],[1,1,1]], 0).

% Grid with no enclosed cells fails.
test(has_inner_no, [fail]) :-
    en_has_inner([[0,1,0]], 0).

% Grid with four enclosed cells succeeds.
test(has_inner_four) :-
    en_has_inner([[1,1,1,1],[1,0,0,1],[1,0,0,1],[1,1,1,1]], 0).

% en_inner_components/3 tests

% One enclosed cell forms one singleton component.
test(inner_comps_one) :-
    en_inner_components([[1,1,1],[1,0,1],[1,1,1]], 0, Comps),
    Comps = [[1-1]].

% No enclosed cells gives the empty component list.
test(inner_comps_none) :-
    en_inner_components([[0,1,0]], 0, Comps),
    Comps = [].

% Two enclosed cells separated by a wall form two singleton components.
test(inner_comps_two) :-
    en_inner_components([[1,1,1,1,1],[1,0,1,0,1],[1,1,1,1,1]], 0, Comps),
    Comps = [[1-1],[1-3]].

% en_outer_components/3 tests

% No outer Bg cells means no outer components.
test(outer_comps_none) :-
    en_outer_components([[1,1,1],[1,0,1],[1,1,1]], 0, Comps),
    Comps = [].

% Two border Bg cells separated by a wall form two singleton outer components.
test(outer_comps_two) :-
    en_outer_components([[0,1,0]], 0, Comps),
    Comps = [[0-0],[0-2]].

% All border Bg cells in a 3x3 grid with inner wall form one connected component.
test(outer_comps_one) :-
    en_outer_components([[0,0,0],[0,1,0],[0,0,0]], 0, Comps),
    Comps = [Comp1],
    sort(Comp1, S),
    S = [0-0,0-1,0-2,1-0,1-2,2-0,2-1,2-2].

% en_fill_hole/6 tests

% Fill the single enclosed hole at (1,1) with Color 2.
test(fill_hole_one) :-
    en_fill_hole([[1,1,1],[1,0,1],[1,1,1]], 0, 1, 1, 2, Out),
    Out = [[1,1,1],[1,2,1],[1,1,1]].

% Fill the 2x2 inner region from (1,1) with Color 3.
test(fill_hole_four) :-
    en_fill_hole([[1,1,1,1],[1,0,0,1],[1,0,0,1],[1,1,1,1]], 0, 1, 1, 3, Out),
    Out = [[1,1,1,1],[1,3,3,1],[1,3,3,1],[1,1,1,1]].

% (0,0) is an outer Bg cell, not an inner cell; fill_hole fails.
test(fill_hole_fail, [fail]) :-
    en_fill_hole([[0,1,0]], 0, 0, 0, 2, _).

% en_boundary_cells/3 tests

% Single Color cell surrounded by non-Color on all in-bounds sides: boundary.
test(boundary_cells_surrounded) :-
    en_boundary_cells([[0,0,0],[0,1,0],[0,0,0]], 1, Cells),
    Cells = [1-1].

% Single Color cell in a 1x3 row: fewer than 4 in-bounds neighbors, so boundary.
test(boundary_cells_1x3) :-
    en_boundary_cells([[0,1,0]], 1, Cells),
    Cells = [0-1].

% 3x3 all-Color grid: center has all Color neighbors (interior); 8 perimeter cells are boundary.
test(boundary_cells_solid) :-
    en_boundary_cells([[1,1,1],[1,1,1],[1,1,1]], 1, Cells),
    Cells = [0-0,0-1,0-2,1-0,1-2,2-0,2-1,2-2].

% en_interior_cells/3 tests

% 3x3 all-Color grid: only the center (1,1) has all 4 in-bounds Color neighbors.
test(interior_cells_center) :-
    en_interior_cells([[1,1,1],[1,1,1],[1,1,1]], 1, Cells),
    Cells = [1-1].

% 1x3 row: no cell has 4 in-bounds neighbors; no interior cells.
test(interior_cells_none_small) :-
    en_interior_cells([[0,1,0]], 1, Cells),
    Cells = [].

% 3x3 ring of Color 1 with center 0: no Color cell has all 4 Color neighbors.
test(interior_cells_none_ring) :-
    en_interior_cells([[1,1,1],[1,0,1],[1,1,1]], 1, Cells),
    Cells = [].

% en_is_surrounded/4 tests

% Center cell (1,1) in 3x3 ring: all 4 in-bounds neighbors are WallColor 1.
test(is_surrounded_center) :-
    en_is_surrounded([[1,1,1],[1,0,1],[1,1,1]], 1, 1, 1).

% Corner cell (0,0): 2 in-bounds neighbors are WallColor 1; 2 out-of-bounds.
test(is_surrounded_corner) :-
    en_is_surrounded([[1,1,1],[1,0,1],[1,1,1]], 0, 0, 1).

% Cell (0,1): its in-bounds neighbor (1,1) has value 0, not WallColor 1; fails.
test(is_surrounded_no, [fail]) :-
    en_is_surrounded([[1,1,1],[1,0,1],[1,1,1]], 0, 1, 1).

:- end_tests(enclosure).
