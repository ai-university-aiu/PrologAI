% Module declaration: morph pack, Layer 65.
:- module(morph, [
    % mo_dilate4/4: expand a color into adjacent background cells (4-connected).
    mo_dilate4/4,
    % mo_dilate8/4: expand a color into adjacent background cells (8-connected).
    mo_dilate8/4,
    % mo_erode4/4: shrink a color by removing cells with non-color 4-neighbors.
    mo_erode4/4,
    % mo_erode8/4: shrink a color by removing cells with non-color 8-neighbors.
    mo_erode8/4,
    % mo_dilate4_n/5: dilate 4-connected N times.
    mo_dilate4_n/5,
    % mo_erode4_n/5: erode 4-connected N times.
    mo_erode4_n/5,
    % mo_open4/4: morphological open = erode once then dilate once.
    mo_open4/4,
    % mo_close4/4: morphological close = dilate once then erode once.
    mo_close4/4,
    % mo_boundary4/3: color cells that have at least one non-color 4-neighbor.
    mo_boundary4/3,
    % mo_boundary8/3: color cells that have at least one non-color 8-neighbor.
    mo_boundary8/3,
    % mo_ring4/4: background cells with at least one color 4-neighbor.
    mo_ring4/4,
    % mo_fill_holes4/4: fill background cells enclosed inside color with color.
    mo_fill_holes4/4,
    % mo_pad/3: add a one-cell border of PadColor around the entire grid.
    mo_pad/3,
    % mo_unpad/2: remove one cell from all four sides of the grid.
    mo_unpad/2
]).

% Import list and apply utilities.
:- use_module(library(lists), [member/2, nth0/3, numlist/3]).
:- use_module(library(apply), [maplist/2, maplist/3]).

% mo_grid_dims_(+Grid, -Rows, -Cols): grid dimensions.
mo_grid_dims_(Grid, Rows, Cols) :-
    % Count rows.
    length(Grid, Rows),
    % Get column count from first row; 0 for empty grid.
    ( Rows > 0 -> Grid = [R0|_], length(R0, Cols) ; Cols = 0 ).

% mo_row_col_lists_(+Rows, +Cols, -Rs, -Cs): build row and column index lists.
mo_row_col_lists_(Rows, Cols, Rs, Cs) :-
    % Row indices 0..Rows-1.
    ( Rows > 0 -> R1 is Rows-1, numlist(0, R1, Rs) ; Rs = [] ),
    % Column indices 0..Cols-1.
    ( Cols > 0 -> C1 is Cols-1, numlist(0, C1, Cs) ; Cs = [] ).

% mo_has_color4_(+R, +C, +Grid, +Rows, +Cols, +Color)
% True if any 4-connected in-bounds neighbor of (R,C) has Color.
mo_has_color4_(R, C, Grid, Rows, Cols, Color) :-
    % Compute neighbor coordinates.
    R1 is R+1, R2 is R-1, C1 is C+1, C2 is C-1,
    % Check each 4-neighbor; cut after first match.
    member(r(NR,NC), [r(R1,C), r(R2,C), r(R,C1), r(R,C2)]),
    NR >= 0, NR < Rows, NC >= 0, NC < Cols,
    nth0(NR, Grid, NRow), nth0(NC, NRow, V), V =:= Color, !.

% mo_has_color8_(+R, +C, +Grid, +Rows, +Cols, +Color)
% True if any 8-connected in-bounds neighbor of (R,C) has Color.
mo_has_color8_(R, C, Grid, Rows, Cols, Color) :-
    % Compute cardinal and diagonal neighbor coordinates.
    R1 is R+1, R2 is R-1, C1 is C+1, C2 is C-1,
    % Check all 8 neighbors; cut after first match.
    member(r(NR,NC), [r(R1,C), r(R2,C), r(R,C1), r(R,C2),
                      r(R1,C1), r(R1,C2), r(R2,C1), r(R2,C2)]),
    NR >= 0, NR < Rows, NC >= 0, NC < Cols,
    nth0(NR, Grid, NRow), nth0(NC, NRow, V), V =:= Color, !.

% mo_all4_color_(+R, +C, +Grid, +Rows, +Cols, +Color)
% True if ALL in-bounds 4-neighbors of (R,C) have Color (OOB counts as not-Color).
mo_all4_color_(R, C, Grid, Rows, Cols, Color) :-
    % Compute neighbor coordinates.
    R1 is R+1, R2 is R-1, C1 is C+1, C2 is C-1,
    % Every neighbor must be in-bounds and have Color.
    forall(member(r(NR,NC), [r(R1,C), r(R2,C), r(R,C1), r(R,C2)]),
           ( NR >= 0, NR < Rows, NC >= 0, NC < Cols,
             nth0(NR, Grid, NRow), nth0(NC, NRow, V), V =:= Color )).

% mo_all8_color_(+R, +C, +Grid, +Rows, +Cols, +Color)
% True if ALL in-bounds 8-neighbors of (R,C) have Color (OOB counts as not-Color).
mo_all8_color_(R, C, Grid, Rows, Cols, Color) :-
    % Compute all 8 neighbor coordinates.
    R1 is R+1, R2 is R-1, C1 is C+1, C2 is C-1,
    % Every neighbor must be in-bounds and have Color.
    forall(member(r(NR,NC), [r(R1,C), r(R2,C), r(R,C1), r(R,C2),
                              r(R1,C1), r(R1,C2), r(R2,C1), r(R2,C2)]),
           ( NR >= 0, NR < Rows, NC >= 0, NC < Cols,
             nth0(NR, Grid, NRow), nth0(NC, NRow, V), V =:= Color )).

% mo_dilate4_cell_(+Grid, +Rows, +Cols, +R, +C, +Color, +BG, -Out)
% Compute output color for cell (R,C) under 4-connected dilation.
mo_dilate4_cell_(Grid, Rows, Cols, R, C, Color, BG, Out) :-
    % Get current cell value.
    nth0(R, Grid, Row), nth0(C, Row, V),
    % If already Color, keep it.
    ( V =:= Color -> Out = Color
    % If BG and has a Color 4-neighbor, expand to Color.
    ; V =:= BG, mo_has_color4_(R, C, Grid, Rows, Cols, Color) -> Out = Color
    % Otherwise leave unchanged.
    ; Out = V
    ).

% mo_dilate8_cell_(+Grid, +Rows, +Cols, +R, +C, +Color, +BG, -Out)
% Compute output color for cell (R,C) under 8-connected dilation.
mo_dilate8_cell_(Grid, Rows, Cols, R, C, Color, BG, Out) :-
    % Get current cell value.
    nth0(R, Grid, Row), nth0(C, Row, V),
    % If already Color, keep it.
    ( V =:= Color -> Out = Color
    % If BG and has a Color 8-neighbor, expand to Color.
    ; V =:= BG, mo_has_color8_(R, C, Grid, Rows, Cols, Color) -> Out = Color
    % Otherwise leave unchanged.
    ; Out = V
    ).

% mo_erode4_cell_(+Grid, +Rows, +Cols, +R, +C, +Color, +BG, -Out)
% Compute output color for cell (R,C) under 4-connected erosion.
mo_erode4_cell_(Grid, Rows, Cols, R, C, Color, BG, Out) :-
    % Get current cell value.
    nth0(R, Grid, Row), nth0(C, Row, V),
    % Only Color cells can be eroded.
    ( V =:= Color ->
        % Keep if ALL 4-neighbors are Color; otherwise erode to BG.
        ( mo_all4_color_(R, C, Grid, Rows, Cols, Color) -> Out = Color ; Out = BG )
    % Non-Color cells unchanged.
    ; Out = V
    ).

% mo_erode8_cell_(+Grid, +Rows, +Cols, +R, +C, +Color, +BG, -Out)
% Compute output color for cell (R,C) under 8-connected erosion.
mo_erode8_cell_(Grid, Rows, Cols, R, C, Color, BG, Out) :-
    % Get current cell value.
    nth0(R, Grid, Row), nth0(C, Row, V),
    % Only Color cells can be eroded.
    ( V =:= Color ->
        % Keep if ALL 8-neighbors are Color; otherwise erode to BG.
        ( mo_all8_color_(R, C, Grid, Rows, Cols, Color) -> Out = Color ; Out = BG )
    % Non-Color cells unchanged.
    ; Out = V
    ).

% mo_rebuild_(+Grid, +Rows, +Cols, +CellPred, -Grid2)
% Rebuild a grid by applying CellPred(R, C, OldVal, NewVal) to each cell.
% Uses findall to construct rows and cells.
mo_rebuild_(Grid, Rows, Cols, CellPred, Grid2) :-
    % Build row index list.
    mo_row_col_lists_(Rows, Cols, Rs, Cs),
    % For each row, compute cells.
    findall(NewRow,
        (member(R, Rs),
         findall(Cell, (member(C, Cs), call(CellPred, Grid, Rows, Cols, R, C, Cell)), NewRow)),
        Grid2).

% mo_dilate4(+Grid, +Color, +BG, -Grid2)
% Grid2 is Grid with Color expanded one step into adjacent BG cells (4-connected).
mo_dilate4(Grid, Color, BG, Grid2) :-
    % Get grid dimensions.
    mo_grid_dims_(Grid, Rows, Cols),
    % Rebuild using dilation cell rule.
    mo_rebuild_(Grid, Rows, Cols, mo_dilate4_cell_wrap_(Color, BG), Grid2).

% mo_dilate4_cell_wrap_(+Color, +BG, +Grid, +Rows, +Cols, +R, +C, -Out)
% Wrapper to add Color and BG to mo_dilate4_cell_ for use in mo_rebuild_.
mo_dilate4_cell_wrap_(Color, BG, Grid, Rows, Cols, R, C, Out) :-
    mo_dilate4_cell_(Grid, Rows, Cols, R, C, Color, BG, Out).

% mo_dilate8(+Grid, +Color, +BG, -Grid2)
% Grid2 is Grid with Color expanded one step into adjacent BG cells (8-connected).
mo_dilate8(Grid, Color, BG, Grid2) :-
    % Get grid dimensions.
    mo_grid_dims_(Grid, Rows, Cols),
    % Rebuild using 8-connected dilation cell rule.
    mo_rebuild_(Grid, Rows, Cols, mo_dilate8_cell_wrap_(Color, BG), Grid2).

% mo_dilate8_cell_wrap_(+Color, +BG, +Grid, +Rows, +Cols, +R, +C, -Out)
mo_dilate8_cell_wrap_(Color, BG, Grid, Rows, Cols, R, C, Out) :-
    mo_dilate8_cell_(Grid, Rows, Cols, R, C, Color, BG, Out).

% mo_erode4(+Grid, +Color, +BG, -Grid2)
% Grid2 is Grid with Color cells removed if any 4-neighbor is non-Color.
mo_erode4(Grid, Color, BG, Grid2) :-
    % Get grid dimensions.
    mo_grid_dims_(Grid, Rows, Cols),
    % Rebuild using erosion cell rule.
    mo_rebuild_(Grid, Rows, Cols, mo_erode4_cell_wrap_(Color, BG), Grid2).

% mo_erode4_cell_wrap_(+Color, +BG, +Grid, +Rows, +Cols, +R, +C, -Out)
mo_erode4_cell_wrap_(Color, BG, Grid, Rows, Cols, R, C, Out) :-
    mo_erode4_cell_(Grid, Rows, Cols, R, C, Color, BG, Out).

% mo_erode8(+Grid, +Color, +BG, -Grid2)
% Grid2 is Grid with Color cells removed if any 8-neighbor is non-Color.
mo_erode8(Grid, Color, BG, Grid2) :-
    % Get grid dimensions.
    mo_grid_dims_(Grid, Rows, Cols),
    % Rebuild using 8-connected erosion cell rule.
    mo_rebuild_(Grid, Rows, Cols, mo_erode8_cell_wrap_(Color, BG), Grid2).

% mo_erode8_cell_wrap_(+Color, +BG, +Grid, +Rows, +Cols, +R, +C, -Out)
mo_erode8_cell_wrap_(Color, BG, Grid, Rows, Cols, R, C, Out) :-
    mo_erode8_cell_(Grid, Rows, Cols, R, C, Color, BG, Out).

% mo_dilate4_n(+Grid, +Color, +BG, +N, -Grid2)
% Grid2 is Grid after N rounds of 4-connected dilation.
mo_dilate4_n(Grid, _Color, _BG, 0, Grid) :- !.
mo_dilate4_n(Grid, Color, BG, N, Grid2) :-
    % N > 0: dilate once then recurse.
    N > 0,
    mo_dilate4(Grid, Color, BG, Grid1),
    N1 is N - 1,
    mo_dilate4_n(Grid1, Color, BG, N1, Grid2).

% mo_erode4_n(+Grid, +Color, +BG, +N, -Grid2)
% Grid2 is Grid after N rounds of 4-connected erosion.
mo_erode4_n(Grid, _Color, _BG, 0, Grid) :- !.
mo_erode4_n(Grid, Color, BG, N, Grid2) :-
    % N > 0: erode once then recurse.
    N > 0,
    mo_erode4(Grid, Color, BG, Grid1),
    N1 is N - 1,
    mo_erode4_n(Grid1, Color, BG, N1, Grid2).

% mo_open4(+Grid, +Color, +BG, -Grid2)
% Morphological open: erode once then dilate once. Removes small protrusions.
mo_open4(Grid, Color, BG, Grid2) :-
    % Erode first.
    mo_erode4(Grid, Color, BG, Grid1),
    % Then dilate.
    mo_dilate4(Grid1, Color, BG, Grid2).

% mo_close4(+Grid, +Color, +BG, -Grid2)
% Morphological close: dilate once then erode once. Fills small gaps.
mo_close4(Grid, Color, BG, Grid2) :-
    % Dilate first.
    mo_dilate4(Grid, Color, BG, Grid1),
    % Then erode.
    mo_erode4(Grid1, Color, BG, Grid2).

% mo_boundary4(+Grid, +Color, -Cells)
% Cells is the list of Color cells that have at least one non-Color 4-neighbor.
mo_boundary4(Grid, Color, Cells) :-
    % Get grid dimensions and index lists.
    mo_grid_dims_(Grid, Rows, Cols),
    mo_row_col_lists_(Rows, Cols, Rs, Cs),
    % Collect Color cells that are NOT fully surrounded by Color.
    findall(r(R,C),
        ( member(R, Rs), member(C, Cs),
          nth0(R, Grid, Row), nth0(C, Row, V), V =:= Color,
          \+ mo_all4_color_(R, C, Grid, Rows, Cols, Color) ),
        Cells).

% mo_boundary8(+Grid, +Color, -Cells)
% Cells is the list of Color cells that have at least one non-Color 8-neighbor.
mo_boundary8(Grid, Color, Cells) :-
    % Get grid dimensions and index lists.
    mo_grid_dims_(Grid, Rows, Cols),
    mo_row_col_lists_(Rows, Cols, Rs, Cs),
    % Collect Color cells not fully surrounded in 8-directions.
    findall(r(R,C),
        ( member(R, Rs), member(C, Cs),
          nth0(R, Grid, Row), nth0(C, Row, V), V =:= Color,
          \+ mo_all8_color_(R, C, Grid, Rows, Cols, Color) ),
        Cells).

% mo_ring4(+Grid, +Color, +BG, -Cells)
% Cells is the list of BG cells that are 4-adjacent to at least one Color cell.
mo_ring4(Grid, Color, BG, Cells) :-
    % Get grid dimensions and index lists.
    mo_grid_dims_(Grid, Rows, Cols),
    mo_row_col_lists_(Rows, Cols, Rs, Cs),
    % Collect BG cells that have a Color 4-neighbor.
    findall(r(R,C),
        ( member(R, Rs), member(C, Cs),
          nth0(R, Grid, Row), nth0(C, Row, V), V =:= BG,
          mo_has_color4_(R, C, Grid, Rows, Cols, Color) ),
        Cells).

% mo_flood_bg_(+Stack, +Grid, +Rows, +Cols, +BG, +Seen, -Result)
% DFS flood fill through BG cells; accumulates visited cells.
mo_flood_bg_([], _, _, _, _, Seen, Seen).
mo_flood_bg_([r(R,C)|Stack], Grid, Rows, Cols, BG, Seen, Result) :-
    % If already visited, skip.
    ( memberchk(r(R,C), Seen) ->
        mo_flood_bg_(Stack, Grid, Rows, Cols, BG, Seen, Result)
    % If in bounds and is BG, expand 4-neighbors.
    ; R >= 0, R < Rows, C >= 0, C < Cols,
      nth0(R, Grid, Row), nth0(C, Row, V), V =:= BG ->
        R1 is R+1, R2 is R-1, C1 is C+1, C2 is C-1,
        append([r(R1,C),r(R2,C),r(R,C1),r(R,C2)], Stack, Stack1),
        mo_flood_bg_(Stack1, Grid, Rows, Cols, BG, [r(R,C)|Seen], Result)
    % Out of bounds or non-BG: skip.
    ;   mo_flood_bg_(Stack, Grid, Rows, Cols, BG, Seen, Result)
    ).

% mo_multi_flood_bg_(+Seeds, +Grid, +Rows, +Cols, +BG, +Seen, -Result)
% Flood from multiple seed cells; accumulates visited set across all floods.
mo_multi_flood_bg_([], _, _, _, _, Seen, Seen).
mo_multi_flood_bg_([Seed|Seeds], Grid, Rows, Cols, BG, Seen, Result) :-
    % Flood from one seed into the accumulated Seen.
    mo_flood_bg_([Seed], Grid, Rows, Cols, BG, Seen, Seen1),
    % Continue with remaining seeds.
    mo_multi_flood_bg_(Seeds, Grid, Rows, Cols, BG, Seen1, Result).

% mo_set_cell_(+GridIn, +R, +C, +Color, -GridOut)
% Return a copy of GridIn with cell (R,C) set to Color.
mo_set_cell_(GridIn, R, C, Color, GridOut) :-
    % Split grid at row R.
    length(Pre, R), append(Pre, [OldRow|Suf], GridIn),
    % Split row at column C.
    length(PreC, C), append(PreC, [_|SufC], OldRow),
    % Reconstruct row with new color.
    append(PreC, [Color|SufC], NewRow),
    % Reconstruct grid with new row.
    append(Pre, [NewRow|Suf], GridOut).

% mo_set_cells_(+Cells, +Color, +GridIn, -GridOut)
% Set all cells in the Cells list to Color in the grid.
mo_set_cells_([], _, Grid, Grid).
mo_set_cells_([r(R,C)|Rest], Color, Grid, Grid2) :-
    % Set one cell, then recurse.
    mo_set_cell_(Grid, R, C, Color, Grid1),
    mo_set_cells_(Rest, Color, Grid1, Grid2).

% mo_fill_holes4(+Grid, +Color, +BG, -Grid2)
% Grid2 is Grid with all BG cells enclosed inside Color filled with Color.
mo_fill_holes4(Grid, Color, BG, Grid2) :-
    % Get grid dimensions and index lists.
    mo_grid_dims_(Grid, Rows, Cols),
    mo_row_col_lists_(Rows, Cols, Rs, Cs),
    % Find BG cells on the grid border as flood seeds.
    findall(r(R,C),
        ( member(R, Rs), member(C, Cs),
          nth0(R, Grid, Row), nth0(C, Row, V), V =:= BG,
          ( R =:= 0 ; R =:= Rows-1 ; C =:= 0 ; C =:= Cols-1 ) ),
        BorderBG),
    % Flood fill from border BG seeds to find all exterior BG cells.
    mo_multi_flood_bg_(BorderBG, Grid, Rows, Cols, BG, [], Reachable),
    % BG cells not reachable from border are enclosed holes.
    findall(r(R,C),
        ( member(R, Rs), member(C, Cs),
          nth0(R, Grid, Row), nth0(C, Row, V), V =:= BG,
          \+ memberchk(r(R,C), Reachable) ),
        Holes),
    % Fill holes with Color.
    mo_set_cells_(Holes, Color, Grid, Grid2).

% mo_pad_row_(+PadColor, +Row, -PaddedRow)
% Add PadColor to both ends of a row.
mo_pad_row_(PadColor, Row, PaddedRow) :-
    % Prepend PadColor.
    append([PadColor|Row], [PadColor], PaddedRow).

% mo_pad(+Grid, +PadColor, -Grid2)
% Grid2 is Grid with a one-cell border of PadColor added on all four sides.
mo_pad(Grid, PadColor, Grid2) :-
    % Get column count to build pad row width.
    mo_grid_dims_(Grid, _Rows, Cols),
    % New width = Cols + 2 (one pad cell on each side).
    Cols2 is Cols + 2,
    % Build a uniform pad row.
    length(PadRow, Cols2), maplist(=(PadColor), PadRow),
    % Pad each existing row.
    maplist(mo_pad_row_(PadColor), Grid, PaddedRows),
    % Sandwich: top pad row, padded rows, bottom pad row.
    append([PadRow|PaddedRows], [PadRow], Grid2).

% mo_drop_last_(+List, -Init)
% Init is List without its last element.
mo_drop_last_([_], []) :- !.
mo_drop_last_([H|T], [H|T2]) :-
    mo_drop_last_(T, T2).

% mo_unpad_row_(+PaddedRow, -Row)
% Remove the first and last element of PaddedRow.
mo_unpad_row_(PaddedRow, Row) :-
    % Remove first element.
    PaddedRow = [_|Rest],
    % Remove last element.
    mo_drop_last_(Rest, Row).

% mo_unpad(+Grid, -Grid2)
% Grid2 is Grid with the outermost ring of cells removed from all four sides.
mo_unpad(Grid, Grid2) :-
    % Remove top row.
    Grid = [_|Rest],
    % Remove bottom row.
    mo_drop_last_(Rest, Inner),
    % Remove first and last column from each remaining row.
    maplist(mo_unpad_row_, Inner, Grid2).
