% logic - Layer 78: boolean and mask operations on grids.
% Module logic exports 14 lg_* predicates covering set-style operations
% (AND, OR, XOR, NOT, diff, overlay), mask creation and application,
% row/column presence reduction, and cell-wise equality testing.
:- module(logic, [
    % Intersection: non-Bg in both grids -> non-Bg; else Bg.
    lg_and/4,
    % Union: non-Bg in either grid -> that value; Grid1 wins on tie.
    lg_or/4,
    % Exclusive or: non-Bg in exactly one grid -> that value; else Bg.
    lg_xor/4,
    % Invert: Bg cells become Fg; non-Bg cells become Bg.
    lg_not/4,
    % Difference: non-Bg in Grid1 and Bg in Grid2 -> Grid1 value; else Bg.
    lg_diff/4,
    % Overlay: Top non-Bg overwrites Base; Bg cells in Top are transparent.
    lg_overlay/4,
    % Mask apply: keep Grid cell where Mask is non-Bg; else replace with Bg.
    lg_mask_apply/4,
    % Mask from grid: non-Bg cells become Fg; Bg cells stay Bg.
    lg_mask_from/4,
    % Row presence: 1 per row if any cell is non-Bg; else 0.
    lg_any_row/3,
    % Column presence: 1 per column if any cell is non-Bg; else 0.
    lg_any_col/3,
    % Row fullness: 1 per row if all cells are non-Bg; else 0.
    lg_all_row/3,
    % Column fullness: 1 per column if all cells are non-Bg; else 0.
    lg_all_col/3,
    % Cell-wise equality: 1 where Grid1 and Grid2 agree; else 0.
    lg_eq/3,
    % Cell-wise inequality: 1 where Grid1 and Grid2 differ; else 0.
    lg_neq/3
]).

% Load member/2 for column/row scanning.
:- use_module(library(lists), [member/2, nth0/3, numlist/3]).
% Load maplist/3 and maplist/4 for row and cell iteration.
:- use_module(library(apply), [maplist/3, maplist/4]).

% lg_and(+Grid1, +Grid2, +Bg, -Grid3)
% Grid3[r,c] = Grid1[r,c] if both Grid1 and Grid2 are non-Bg at that cell; else Bg.
lg_and(Grid1, Grid2, Bg, Grid3) :-
    % Apply AND row-wise across paired rows.
    maplist(lg_and_row_(Bg), Grid1, Grid2, Grid3).

% lg_and_row_(+Bg, +Row1, +Row2, -Row3): AND two rows cell by cell.
lg_and_row_(Bg, Row1, Row2, Row3) :-
    % Apply AND to each paired cell.
    maplist(lg_and_cell_(Bg), Row1, Row2, Row3).

% lg_and_cell_(+Bg, +C1, +C2, -C3): C3 = C1 if both non-Bg; else Bg.
lg_and_cell_(Bg, C1, C2, C3) :-
    % Both cells must be non-Bg to pass the C1 value through.
    (C1 \== Bg, C2 \== Bg -> C3 = C1 ; C3 = Bg).

% lg_or(+Grid1, +Grid2, +Bg, -Grid3)
% Grid3[r,c] = Grid1[r,c] if Grid1 non-Bg; else Grid2[r,c] if Grid2 non-Bg; else Bg.
lg_or(Grid1, Grid2, Bg, Grid3) :-
    % Apply OR row-wise across paired rows.
    maplist(lg_or_row_(Bg), Grid1, Grid2, Grid3).

% lg_or_row_(+Bg, +Row1, +Row2, -Row3): OR two rows cell by cell.
lg_or_row_(Bg, Row1, Row2, Row3) :-
    % Apply OR to each paired cell.
    maplist(lg_or_cell_(Bg), Row1, Row2, Row3).

% lg_or_cell_(+Bg, +C1, +C2, -C3): prefer C1; fall back to C2; else Bg.
lg_or_cell_(Bg, C1, C2, C3) :-
    % Grid1 non-Bg takes priority.
    (C1 \== Bg -> C3 = C1
    % Grid2 non-Bg is the fallback.
    ; C2 \== Bg -> C3 = C2
    % Both Bg: result is Bg.
    ; C3 = Bg).

% lg_xor(+Grid1, +Grid2, +Bg, -Grid3)
% Grid3[r,c] = non-Bg value if exactly one of Grid1[r,c], Grid2[r,c] is non-Bg; else Bg.
lg_xor(Grid1, Grid2, Bg, Grid3) :-
    % Apply XOR row-wise across paired rows.
    maplist(lg_xor_row_(Bg), Grid1, Grid2, Grid3).

% lg_xor_row_(+Bg, +Row1, +Row2, -Row3): XOR two rows cell by cell.
lg_xor_row_(Bg, Row1, Row2, Row3) :-
    % Apply XOR to each paired cell.
    maplist(lg_xor_cell_(Bg), Row1, Row2, Row3).

% lg_xor_cell_(+Bg, +C1, +C2, -C3): C1 if only C1 non-Bg; C2 if only C2 non-Bg; else Bg.
lg_xor_cell_(Bg, C1, C2, C3) :-
    % Only C1 is non-Bg: pass it through.
    (C1 \== Bg, C2 == Bg -> C3 = C1
    % Only C2 is non-Bg: pass it through.
    ; C1 == Bg, C2 \== Bg -> C3 = C2
    % Both non-Bg or both Bg: result is Bg.
    ; C3 = Bg).

% lg_not(+Grid, +Bg, +Fg, -Grid2)
% Grid2[r,c] = Fg if Grid[r,c] == Bg; else Bg. Inverts foreground and background.
lg_not(Grid, Bg, Fg, Grid2) :-
    % Apply NOT row-wise.
    maplist(lg_not_row_(Bg, Fg), Grid, Grid2).

% lg_not_row_(+Bg, +Fg, +Row, -Row2): NOT one row cell by cell.
lg_not_row_(Bg, Fg, Row, Row2) :-
    % Apply NOT to each cell.
    maplist(lg_not_cell_(Bg, Fg), Row, Row2).

% lg_not_cell_(+Bg, +Fg, +Cell, -Cell2): Bg -> Fg; non-Bg -> Bg.
lg_not_cell_(Bg, Fg, Cell, Cell2) :-
    % Background becomes foreground; foreground becomes background.
    (Cell == Bg -> Cell2 = Fg ; Cell2 = Bg).

% lg_diff(+Grid1, +Grid2, +Bg, -Grid3)
% Grid3[r,c] = Grid1[r,c] if Grid1 is non-Bg there and Grid2 is Bg there; else Bg.
lg_diff(Grid1, Grid2, Bg, Grid3) :-
    % Apply diff row-wise across paired rows.
    maplist(lg_diff_row_(Bg), Grid1, Grid2, Grid3).

% lg_diff_row_(+Bg, +Row1, +Row2, -Row3): subtract Row2 presence from Row1.
lg_diff_row_(Bg, Row1, Row2, Row3) :-
    % Apply diff to each paired cell.
    maplist(lg_diff_cell_(Bg), Row1, Row2, Row3).

% lg_diff_cell_(+Bg, +C1, +C2, -C3): C1 only if C1 non-Bg and C2 == Bg; else Bg.
lg_diff_cell_(Bg, C1, C2, C3) :-
    % Retain C1 only where Grid2 has no content.
    (C1 \== Bg, C2 == Bg -> C3 = C1 ; C3 = Bg).

% lg_overlay(+Base, +Top, +Bg, -Result)
% Result[r,c] = Top[r,c] if Top[r,c] non-Bg; else Base[r,c].
% Top's non-Bg cells overwrite Base; Top's Bg cells are transparent.
lg_overlay(Base, Top, Bg, Result) :-
    % Apply overlay row-wise across paired rows.
    maplist(lg_overlay_row_(Bg), Base, Top, Result).

% lg_overlay_row_(+Bg, +BaseRow, +TopRow, -ResultRow): overlay one row pair.
lg_overlay_row_(Bg, BaseRow, TopRow, ResultRow) :-
    % Apply overlay to each paired cell.
    maplist(lg_overlay_cell_(Bg), BaseRow, TopRow, ResultRow).

% lg_overlay_cell_(+Bg, +Base, +Top, -Result): Top wins if non-Bg; else keep Base.
lg_overlay_cell_(Bg, Base, Top, Result) :-
    % Top's non-Bg value overwrites Base.
    (Top \== Bg -> Result = Top ; Result = Base).

% lg_mask_apply(+Mask, +Grid, +Bg, -Grid2)
% Grid2[r,c] = Grid[r,c] where Mask[r,c] is non-Bg; else Bg.
lg_mask_apply(Mask, Grid, Bg, Grid2) :-
    % Apply mask row-wise across paired rows.
    maplist(lg_mask_apply_row_(Bg), Mask, Grid, Grid2).

% lg_mask_apply_row_(+Bg, +MaskRow, +GridRow, -Row2): apply mask to one row.
lg_mask_apply_row_(Bg, MaskRow, GridRow, Row2) :-
    % Apply mask cell-wise.
    maplist(lg_mask_apply_cell_(Bg), MaskRow, GridRow, Row2).

% lg_mask_apply_cell_(+Bg, +M, +G, -C2): keep G if M non-Bg; else Bg.
lg_mask_apply_cell_(Bg, M, G, C2) :-
    % Non-Bg mask cell passes the grid value through; Bg mask cell blocks it.
    (M \== Bg -> C2 = G ; C2 = Bg).

% lg_mask_from(+Grid, +Bg, +Fg, -Mask)
% Mask[r,c] = Fg if Grid[r,c] is non-Bg; else Bg. Creates a binary presence mask.
lg_mask_from(Grid, Bg, Fg, Mask) :-
    % Apply mask creation row-wise.
    maplist(lg_mask_from_row_(Bg, Fg), Grid, Mask).

% lg_mask_from_row_(+Bg, +Fg, +Row, -MaskRow): create mask for one row.
lg_mask_from_row_(Bg, Fg, Row, MaskRow) :-
    % Create mask cell-wise.
    maplist(lg_mask_from_cell_(Bg, Fg), Row, MaskRow).

% lg_mask_from_cell_(+Bg, +Fg, +Cell, -M): non-Bg -> Fg; Bg -> Bg.
lg_mask_from_cell_(Bg, Fg, Cell, M) :-
    % Mark presence with Fg; absence stays Bg.
    (Cell == Bg -> M = Bg ; M = Fg).

% lg_any_row(+Grid, +Bg, -Flags)
% Flags is a list with one element per row: 1 if any cell in that row is non-Bg; else 0.
lg_any_row(Grid, Bg, Flags) :-
    % Check each row independently.
    maplist(lg_any_row_flag_(Bg), Grid, Flags).

% lg_any_row_flag_(+Bg, +Row, -Flag): Flag = 1 if any cell non-Bg; else 0.
lg_any_row_flag_(Bg, Row, Flag) :-
    % member/2 inside -> backtracks to find a non-Bg cell.
    (member(Cell, Row), Cell \== Bg -> Flag = 1 ; Flag = 0).

% lg_any_col(+Grid, +Bg, -Flags)
% Flags is a list with one element per column: 1 if any cell in that column is non-Bg; else 0.
lg_any_col(Grid, Bg, Flags) :-
    % Empty grid has no columns.
    (Grid = [] -> Flags = []
    % Non-empty: enumerate column indices.
    ; Grid = [FirstRow|_],
      length(FirstRow, NCols),
      NColsM1 is NCols - 1,
      numlist(0, NColsM1, CIdxs),
      maplist(lg_any_col_flag_(Grid, Bg), CIdxs, Flags)).

% lg_any_col_flag_(+Grid, +Bg, +C, -Flag): Flag = 1 if any cell in col C non-Bg.
lg_any_col_flag_(Grid, Bg, C, Flag) :-
    % Scan all rows for col C; stop at first non-Bg cell.
    (member(Row, Grid), nth0(C, Row, Cell), Cell \== Bg -> Flag = 1 ; Flag = 0).

% lg_all_row(+Grid, +Bg, -Flags)
% Flags is a list with one element per row: 1 if all cells in that row are non-Bg; else 0.
lg_all_row(Grid, Bg, Flags) :-
    % Check each row independently.
    maplist(lg_all_row_flag_(Bg), Grid, Flags).

% lg_all_row_flag_(+Bg, +Row, -Flag): Flag = 1 if all cells non-Bg; else 0.
lg_all_row_flag_(Bg, Row, Flag) :-
    % forall succeeds vacuously on empty rows.
    (forall(member(Cell, Row), Cell \== Bg) -> Flag = 1 ; Flag = 0).

% lg_all_col(+Grid, +Bg, -Flags)
% Flags is a list with one element per column: 1 if all cells in that column are non-Bg; else 0.
lg_all_col(Grid, Bg, Flags) :-
    % Empty grid has no columns.
    (Grid = [] -> Flags = []
    % Non-empty: enumerate column indices.
    ; Grid = [FirstRow|_],
      length(FirstRow, NCols),
      NColsM1 is NCols - 1,
      numlist(0, NColsM1, CIdxs),
      maplist(lg_all_col_flag_(Grid, Bg), CIdxs, Flags)).

% lg_all_col_flag_(+Grid, +Bg, +C, -Flag): Flag = 1 if all cells in col C non-Bg.
lg_all_col_flag_(Grid, Bg, C, Flag) :-
    % forall checks every row; nth0 extracts the cell at column C.
    (forall(member(Row, Grid), (nth0(C, Row, Cell), Cell \== Bg))
    -> Flag = 1 ; Flag = 0).

% lg_eq(+Grid1, +Grid2, -BoolGrid)
% BoolGrid[r,c] = 1 if Grid1[r,c] == Grid2[r,c]; else 0.
lg_eq(Grid1, Grid2, BoolGrid) :-
    % Apply equality row-wise across paired rows.
    maplist(lg_eq_row_, Grid1, Grid2, BoolGrid).

% lg_eq_row_(+Row1, +Row2, -BoolRow): equality for one row pair.
lg_eq_row_(Row1, Row2, BoolRow) :-
    % Apply equality cell-wise.
    maplist(lg_eq_cell_, Row1, Row2, BoolRow).

% lg_eq_cell_(+C1, +C2, -B): 1 if C1 == C2; else 0.
lg_eq_cell_(C1, C2, B) :-
    % Term equality (==) covers atoms, integers, and compound terms.
    (C1 == C2 -> B = 1 ; B = 0).

% lg_neq(+Grid1, +Grid2, -BoolGrid)
% BoolGrid[r,c] = 1 if Grid1[r,c] \== Grid2[r,c]; else 0.
lg_neq(Grid1, Grid2, BoolGrid) :-
    % Apply inequality row-wise across paired rows.
    maplist(lg_neq_row_, Grid1, Grid2, BoolGrid).

% lg_neq_row_(+Row1, +Row2, -BoolRow): inequality for one row pair.
lg_neq_row_(Row1, Row2, BoolRow) :-
    % Apply inequality cell-wise.
    maplist(lg_neq_cell_, Row1, Row2, BoolRow).

% lg_neq_cell_(+C1, +C2, -B): 1 if C1 \== C2; else 0.
lg_neq_cell_(C1, C2, B) :-
    % Term inequality covers the complement of ==.
    (C1 \== C2 -> B = 1 ; B = 0).
