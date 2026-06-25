% test_walk.pl - PLUnit acceptance tests for the walk pack (wk_* predicates).
% 42 tests: 3 per predicate for all 14 exported predicates.
:- use_module('../prolog/walk.pl').

% Begin the walk test suite.
:- begin_tests(walk).

% --- wk_row_scan/2 ---

% wk_row_scan of a 2x3 grid yields cells in row-major order.
test(row_scan_2x3) :-
    % Row 0 left-to-right then Row 1 left-to-right.
    wk_row_scan([[1,2,3],[4,5,6]], Cells),
    % Verify the complete row-major sequence.
    Cells = [0-0,0-1,0-2,1-0,1-1,1-2].

% wk_row_scan of a 2x2 grid yields four cells in row-major order.
test(row_scan_2x2) :-
    % Two rows of two columns each.
    wk_row_scan([[a,b],[c,d]], Cells),
    % Verify row-major ordering.
    Cells = [0-0,0-1,1-0,1-1].

% wk_row_scan of a 1x1 grid yields a single cell.
test(row_scan_1x1) :-
    % Single-cell grid.
    wk_row_scan([[z]], Cells),
    % Only one cell exists.
    Cells = [0-0].

% --- wk_col_scan/2 ---

% wk_col_scan of a 2x3 grid yields cells in column-major order.
test(col_scan_2x3) :-
    % Column 0 top-to-bottom then Column 1 then Column 2.
    wk_col_scan([[1,2,3],[4,5,6]], Cells),
    % Verify column-major sequence.
    Cells = [0-0,1-0,0-1,1-1,0-2,1-2].

% wk_col_scan of a 2x2 grid yields four cells column by column.
test(col_scan_2x2) :-
    % Two columns each of two rows.
    wk_col_scan([[a,b],[c,d]], Cells),
    % Column 0 first then Column 1.
    Cells = [0-0,1-0,0-1,1-1].

% wk_col_scan of a 1x1 grid yields a single cell.
test(col_scan_1x1) :-
    % Single-cell grid.
    wk_col_scan([[z]], Cells),
    % Only one cell at (0,0).
    Cells = [0-0].

% --- wk_zigzag_scan/2 ---

% wk_zigzag_scan of a 2x3 grid alternates left-right and right-left.
test(zigzag_scan_2x3) :-
    % Row 0 goes L→R; Row 1 goes R→L.
    wk_zigzag_scan([[1,2,3],[4,5,6]], Cells),
    % Verify the boustrophedon sequence.
    Cells = [0-0,0-1,0-2,1-2,1-1,1-0].

% wk_zigzag_scan of a 3x2 grid reverses direction on each row.
test(zigzag_scan_3x2) :-
    % Row 0 L→R, Row 1 R→L, Row 2 L→R.
    wk_zigzag_scan([[1,2],[3,4],[5,6]], Cells),
    % Verify three-row zigzag.
    Cells = [0-0,0-1,1-1,1-0,2-0,2-1].

% wk_zigzag_scan of a single row returns left-to-right (even row 0).
test(zigzag_scan_1x3) :-
    % Single row is always left-to-right.
    wk_zigzag_scan([[a,b,c]], Cells),
    % No reversal for single row.
    Cells = [0-0,0-1,0-2].

% --- wk_diag_scan/2 ---

% wk_diag_scan of a 3x3 grid groups cells by main diagonal.
test(diag_scan_3x3) :-
    % Diagonals D from -2 to 2; cells ordered top-to-bottom within each.
    wk_diag_scan([[1,2,3],[4,5,6],[7,8,9]], Cells),
    % D=-2: (2,0); D=-1: (1,0),(2,1); D=0: (0,0),(1,1),(2,2); D=1: (0,1),(1,2); D=2: (0,2).
    Cells = [2-0,1-0,2-1,0-0,1-1,2-2,0-1,1-2,0-2].

% wk_diag_scan of a 2x2 grid gives three diagonals.
test(diag_scan_2x2) :-
    % D=-1: (1,0); D=0: (0,0),(1,1); D=1: (0,1).
    wk_diag_scan([[a,b],[c,d]], Cells),
    % Verify diagonal grouping for 2x2.
    Cells = [1-0,0-0,1-1,0-1].

% wk_diag_scan of a 1x1 grid yields a single cell.
test(diag_scan_1x1) :-
    % Only diagonal D=0 exists containing (0,0).
    wk_diag_scan([[x]], Cells),
    % Single cell on the main diagonal.
    Cells = [0-0].

% --- wk_antidiag_scan/2 ---

% wk_antidiag_scan of a 3x3 grid groups cells by anti-diagonal.
test(antidiag_scan_3x3) :-
    % D from 0 to 4; cells ordered top-to-bottom within each anti-diagonal.
    wk_antidiag_scan([[1,2,3],[4,5,6],[7,8,9]], Cells),
    % D=0:(0,0); D=1:(0,1),(1,0); D=2:(0,2),(1,1),(2,0); D=3:(1,2),(2,1); D=4:(2,2).
    Cells = [0-0,0-1,1-0,0-2,1-1,2-0,1-2,2-1,2-2].

% wk_antidiag_scan of a 1x1 grid yields a single cell.
test(antidiag_scan_1x1) :-
    % Only anti-diagonal D=0 contains (0,0).
    wk_antidiag_scan([[q]], Cells),
    % Single cell.
    Cells = [0-0].

% wk_antidiag_scan of a 2x3 grid yields 4 anti-diagonals.
test(antidiag_scan_2x3) :-
    % D=0:(0,0); D=1:(0,1),(1,0); D=2:(0,2),(1,1); D=3:(1,2).
    wk_antidiag_scan([[1,2,3],[4,5,6]], Cells),
    % Verify 2x3 anti-diagonal ordering.
    Cells = [0-0,0-1,1-0,0-2,1-1,1-2].

% --- wk_spiral_in/2 ---

% wk_spiral_in of a 3x3 grid visits outer ring then center.
test(spiral_in_3x3) :-
    % Outer ring clockwise from (0,0), then center (1,1).
    wk_spiral_in([[1,2,3],[4,5,6],[7,8,9]], Cells),
    % Ring: (0,0),(0,1),(0,2),(1,2),(2,2),(2,1),(2,0),(1,0); center: (1,1).
    Cells = [0-0,0-1,0-2,1-2,2-2,2-1,2-0,1-0,1-1].

% wk_spiral_in of a 2x3 grid has no inner ring after peeling the border.
test(spiral_in_2x3) :-
    % All cells are on the outer ring of a 2x3 grid.
    wk_spiral_in([[1,2,3],[4,5,6]], Cells),
    % The single ring covers all 6 cells.
    Cells = [0-0,0-1,0-2,1-2,1-1,1-0].

% wk_spiral_in of a 1x3 grid visits cells left to right.
test(spiral_in_1x3) :-
    % Single row; the ring is just the row itself.
    wk_spiral_in([[a,b,c]], Cells),
    % All three cells in top-row order.
    Cells = [0-0,0-1,0-2].

% --- wk_border_walk/2 ---

% wk_border_walk of a 3x3 grid visits the 8 border cells clockwise.
test(border_walk_3x3) :-
    % Starting at (0,0) clockwise; center (1,1) is excluded.
    wk_border_walk([[1,2,3],[4,5,6],[7,8,9]], Cells),
    % Top row, right column, bottom row reversed, left column reversed.
    Cells = [0-0,0-1,0-2,1-2,2-2,2-1,2-0,1-0].

% wk_border_walk of a 2x3 grid covers all 6 cells.
test(border_walk_2x3) :-
    % No interior cells in a 2x3 grid.
    wk_border_walk([[a,b,c],[d,e,f]], Cells),
    % All 6 cells in clockwise order.
    Cells = [0-0,0-1,0-2,1-2,1-1,1-0].

% wk_border_walk of a 1x1 grid yields a single cell.
test(border_walk_1x1) :-
    % The single cell is its own border.
    wk_border_walk([[x]], Cells),
    % Only (0,0).
    Cells = [0-0].

% --- wk_diag_extract/3 ---

% wk_diag_extract of D=0 (main diagonal) of a 3x3 grid.
test(diag_extract_d0) :-
    % Main diagonal contains (0,0),(1,1),(2,2).
    wk_diag_extract([[1,2,3],[4,5,6],[7,8,9]], 0, Vals),
    % Values are 1, 5, 9.
    Vals = [1,5,9].

% wk_diag_extract of D=1 (one step above main) of a 3x3 grid.
test(diag_extract_d1) :-
    % D=1 diagonal contains (0,1),(1,2).
    wk_diag_extract([[1,2,3],[4,5,6],[7,8,9]], 1, Vals),
    % Values are 2, 6.
    Vals = [2,6].

% wk_diag_extract of D=-1 (one step below main) of a 3x3 grid.
test(diag_extract_dm1) :-
    % D=-1 diagonal contains (1,0),(2,1).
    wk_diag_extract([[1,2,3],[4,5,6],[7,8,9]], -1, Vals),
    % Values are 4, 8.
    Vals = [4,8].

% --- wk_antidiag_extract/3 ---

% wk_antidiag_extract of D=2 (main anti-diagonal) of a 3x3 grid.
test(antidiag_extract_d2) :-
    % Anti-diagonal D=2 contains (0,2),(1,1),(2,0).
    wk_antidiag_extract([[1,2,3],[4,5,6],[7,8,9]], 2, Vals),
    % Values are 3, 5, 7.
    Vals = [3,5,7].

% wk_antidiag_extract of D=0 (top-left corner only) of a 3x3 grid.
test(antidiag_extract_d0) :-
    % Anti-diagonal D=0 contains only (0,0).
    wk_antidiag_extract([[1,2,3],[4,5,6],[7,8,9]], 0, Vals),
    % Single value at top-left.
    Vals = [1].

% wk_antidiag_extract of D=4 (bottom-right corner only) of a 3x3 grid.
test(antidiag_extract_d4) :-
    % Anti-diagonal D=4 contains only (2,2).
    wk_antidiag_extract([[1,2,3],[4,5,6],[7,8,9]], 4, Vals),
    % Single value at bottom-right.
    Vals = [9].

% --- wk_diag_of/2 ---

% wk_diag_of returns 0 for the top-left corner cell.
test(diag_of_origin) :-
    % Cell (0,0): C - R = 0 - 0 = 0.
    wk_diag_of(0-0, D),
    % Main diagonal index is 0.
    D =:= 0.

% wk_diag_of returns a positive value when column exceeds row.
test(diag_of_positive) :-
    % Cell (1,3): D = 3 - 1 = 2.
    wk_diag_of(1-3, D),
    % Diagonal index is 2 (above main diagonal).
    D =:= 2.

% wk_diag_of returns a negative value when row exceeds column.
test(diag_of_negative) :-
    % Cell (2,0): D = 0 - 2 = -2.
    wk_diag_of(2-0, D),
    % Diagonal index is -2 (below main diagonal).
    D =:= -2.

% --- wk_antidiag_of/2 ---

% wk_antidiag_of returns 0 for the top-left corner cell.
test(antidiag_of_origin) :-
    % Cell (0,0): D = 0 + 0 = 0.
    wk_antidiag_of(0-0, D),
    % First anti-diagonal.
    D =:= 0.

% wk_antidiag_of sums row and column indices.
test(antidiag_of_sum) :-
    % Cell (1,3): D = 1 + 3 = 4.
    wk_antidiag_of(1-3, D),
    % Anti-diagonal index is 4.
    D =:= 4.

% wk_antidiag_of for a cell at (2,2) also gives 4.
test(antidiag_of_center) :-
    % Cell (2,2): D = 2 + 2 = 4.
    wk_antidiag_of(2-2, D),
    % Same anti-diagonal as (1,3).
    D =:= 4.

% --- wk_cells_to_vals/3 ---

% wk_cells_to_vals extracts three values at specified positions.
test(cells_to_vals_three) :-
    % Extract corners and center of a 3x3 grid.
    wk_cells_to_vals([[1,2,3],[4,5,6],[7,8,9]], [0-0,2-2,1-1], Vals),
    % Values at top-left, bottom-right, and center.
    Vals = [1,9,5].

% wk_cells_to_vals extracts two off-diagonal values.
test(cells_to_vals_two) :-
    % Extract (0,1) and (1,0) from a 3x3 grid.
    wk_cells_to_vals([[1,2,3],[4,5,6],[7,8,9]], [0-1,1-0], Vals),
    % Values are 2 and 4.
    Vals = [2,4].

% wk_cells_to_vals of empty cell list returns empty value list.
test(cells_to_vals_empty) :-
    % No cells to extract.
    wk_cells_to_vals([[1,2],[3,4]], [], Vals),
    % Result is empty.
    Vals = [].

% --- wk_vals_to_cells/4 ---

% wk_vals_to_cells paints a single cell.
test(vals_to_cells_one) :-
    % Paint center (1,1) of a 3x3 grid with value 9.
    wk_vals_to_cells([[1,2,3],[4,5,6],[7,8,9]], [1-1], [0], Result),
    % Only center changes.
    Result = [[1,2,3],[4,0,6],[7,8,9]].

% wk_vals_to_cells paints two cells.
test(vals_to_cells_two) :-
    % Paint (0,0) with 8 and (2,2) with 8.
    wk_vals_to_cells([[1,2,3],[4,5,6],[7,8,9]], [0-0,2-2], [8,8], Result),
    % Two corners change.
    Result = [[8,2,3],[4,5,6],[7,8,8]].

% wk_vals_to_cells with empty lists returns the grid unchanged.
test(vals_to_cells_empty) :-
    % No cells to paint.
    wk_vals_to_cells([[1,2],[3,4]], [], [], Result),
    % Grid is unchanged.
    Result = [[1,2],[3,4]].

% --- wk_inner_cells/2 ---

% wk_inner_cells of a 3x3 grid returns only the center cell.
test(inner_cells_3x3) :-
    % Only (1,1) is non-border in a 3x3 grid.
    wk_inner_cells([[1,2,3],[4,5,6],[7,8,9]], Cells),
    % Single inner cell at center.
    Cells = [1-1].

% wk_inner_cells of a 4x4 grid returns four inner cells.
test(inner_cells_4x4) :-
    % Inner rows 1-2 and inner columns 1-2.
    wk_inner_cells([[0,0,0,0],[0,1,2,0],[0,3,4,0],[0,0,0,0]], Cells),
    % Four inner cells in row-major order.
    Cells = [1-1,1-2,2-1,2-2].

% wk_inner_cells of a 2x3 grid returns empty (no inner rows).
test(inner_cells_2x3) :-
    % A 2-row grid has no non-border rows.
    wk_inner_cells([[1,2,3],[4,5,6]], Cells),
    % No inner cells.
    Cells = [].

% End the walk test suite.
:- end_tests(walk).
