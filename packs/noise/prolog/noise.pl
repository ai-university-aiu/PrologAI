% Module declaration: noise pack, Layer 61.
:- module(noise, [
    % noise_mask_apply/4: apply a binary mask to a grid, replacing masked cells.
    noise_mask_apply/4,
    % noise_mask_invert/3: invert a binary mask (0->1, 1->0).
    noise_mask_invert/3,
    % noise_mask_and/3: bitwise AND of two same-size binary masks.
    noise_mask_and/3,
    % noise_mask_or/3: bitwise OR of two same-size binary masks.
    noise_mask_or/3,
    % noise_mask_from_color/3: build a binary mask: 1 where grid has color, 0 elsewhere.
    noise_mask_from_color/3,
    % noise_mask_to_region/2: convert a binary mask to a list of r(R,C) cells (mask=1).
    noise_mask_to_region/2,
    % noise_region_to_mask/4: convert a region list to a binary mask grid.
    noise_region_to_mask/4,
    % noise_noise_cells/3: list of r(R,C) cells that differ from the majority color.
    noise_noise_cells/3,
    % noise_denoise/3: replace noise cells with the majority color.
    noise_denoise/3,
    % noise_majority_color/2: most frequent color in a grid.
    noise_majority_color/2,
    % noise_color_count/3: count occurrences of a color in a grid.
    noise_color_count/3,
    % noise_sparse_cells/3: cells whose color appears fewer than N times total.
    noise_sparse_cells/3,
    % noise_dense_cells/3: cells whose color appears N or more times total.
    noise_dense_cells/3,
    % noise_isolate_color/3: set all non-Color cells to BG, keep Color cells.
    noise_isolate_color/3
]).

% Import list and apply utilities.
% msort/2 is a SWI-Prolog built-in, not imported from library(lists).
:- use_module(library(lists),  [member/2, nth0/3, numlist/3]).
:- use_module(library(apply),  [maplist/2, maplist/3, include/3, foldl/4]).

% noise_grid_dims_(+Grid, -Rows, -Cols): dimensions of a grid.
noise_grid_dims_(Grid, Rows, Cols) :-
    % Count rows.
    length(Grid, Rows),
    % Count columns from first row.
    ( Rows > 0 -> Grid = [R0|_], length(R0, Cols) ; Cols = 0 ).

% noise_flat_(+Grid, -Flat): flatten grid to a list of values.
noise_flat_(Grid, Flat) :-
    append(Grid, Flat).

% noise_cell_val_(+Grid, +r(R,C), -V): value at a cell.
noise_cell_val_(Grid, r(R,C), V) :-
    nth0(R, Grid, Row), nth0(C, Row, V).

% noise_set_cell_(+Grid, +r(R,C), +V, -Result): set a cell value.
noise_set_cell_(Grid, r(R,C), V, Result) :-
    % Build prefix rows and modified row.
    length(PreRows, R),
    append(PreRows, [OldRow|SufRows], Grid),
    % Build prefix cols and modified col within the row.
    length(PreCols, C),
    append(PreCols, [_|SufCols], OldRow),
    append(PreCols, [V|SufCols], NewRow),
    append(PreRows, [NewRow|SufRows], Result).

% noise_all_positions_(+Rows, +Cols, -Positions): all r(R,C) positions.
noise_all_positions_(Rows, Cols, Positions) :-
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    findall(r(R,C), (member(R, RowIds), member(C, ColIds)), Positions).

% noise_mask_apply(+Grid, +Mask, +FillColor, -Result): replace cells where Mask=1 with FillColor.
noise_mask_apply(Grid, Mask, FillColor, Result) :-
    % Apply row by row.
    maplist(noise_mask_apply_row_(FillColor), Grid, Mask, Result).

% noise_mask_apply_row_(+FillColor, +GRow, +MRow, -RRow): mask one row.
noise_mask_apply_row_(FillColor, GRow, MRow, RRow) :-
    maplist(noise_mask_cell_(FillColor), GRow, MRow, RRow).

% noise_mask_cell_(+Fill, +GV, +MV, -RV): apply mask to one cell.
noise_mask_cell_(Fill, _GV, 1, Fill) :- !.
noise_mask_cell_(_Fill, GV, 0, GV).

% noise_mask_invert(+Mask, +Rows, -Inverted): flip 0<->1 in mask.
noise_mask_invert(Mask, _Rows, Inverted) :-
    maplist(noise_invert_row_, Mask, Inverted).

% noise_invert_row_(+Row, -Inverted): flip each cell in a mask row.
noise_invert_row_(Row, Inverted) :-
    maplist(noise_flip_bit_, Row, Inverted).

% noise_flip_bit_(+B, -F): 0->1, 1->0.
noise_flip_bit_(0, 1) :- !.
noise_flip_bit_(1, 0).

% noise_mask_and(+Mask1, +Mask2, -Result): pointwise AND of two binary masks.
noise_mask_and(Mask1, Mask2, Result) :-
    maplist(noise_and_row_, Mask1, Mask2, Result).

% noise_and_row_(+R1, +R2, -R): AND two mask rows.
noise_and_row_(R1, R2, R) :-
    maplist(noise_and_bit_, R1, R2, R).

% noise_and_bit_(+A, +B, -C): C = A AND B.
noise_and_bit_(1, 1, 1) :- !.
noise_and_bit_(_, _, 0).

% noise_mask_or(+Mask1, +Mask2, -Result): pointwise OR of two binary masks.
noise_mask_or(Mask1, Mask2, Result) :-
    maplist(noise_or_row_, Mask1, Mask2, Result).

% noise_or_row_(+R1, +R2, -R): OR two mask rows.
noise_or_row_(R1, R2, R) :-
    maplist(noise_or_bit_, R1, R2, R).

% noise_or_bit_(+A, +B, -C): C = A OR B.
noise_or_bit_(0, 0, 0) :- !.
noise_or_bit_(_, _, 1).

% noise_mask_from_color(+Grid, +Color, -Mask): 1 where Grid cell equals Color.
noise_mask_from_color(Grid, Color, Mask) :-
    maplist(noise_color_mask_row_(Color), Grid, Mask).

% noise_color_mask_row_(+Color, +Row, -MRow): 1 for Color cells, 0 for others.
noise_color_mask_row_(Color, Row, MRow) :-
    maplist(noise_color_mask_cell_(Color), Row, MRow).

% noise_color_mask_cell_(+Color, +V, -M): 1 if V=Color, else 0.
noise_color_mask_cell_(Color, V, 1) :- V =:= Color, !.
noise_color_mask_cell_(_Color, _V, 0).

% noise_mask_to_region(+Mask, -Region): list of r(R,C) where Mask=1.
noise_mask_to_region(Mask, Region) :-
    % Enumerate all positions and keep those where mask=1.
    noise_grid_dims_(Mask, Rows, Cols),
    noise_all_positions_(Rows, Cols, All),
    include(noise_mask_is_one_(Mask), All, Region).

% noise_mask_is_one_(+Mask, +r(R,C)): mask value at r(R,C) is 1.
noise_mask_is_one_(Mask, r(R,C)) :-
    nth0(R, Mask, Row), nth0(C, Row, 1).

% noise_region_to_mask(+Region, +Rows, +Cols, -Mask): build mask from region list.
noise_region_to_mask(Region, Rows, Cols, Mask) :-
    % Start with all-zero mask.
    noise_zero_mask_(Rows, Cols, ZeroMask),
    % Set 1 for each region cell.
    foldl(noise_set_mask_cell_, Region, ZeroMask, Mask).

% noise_zero_mask_(+Rows, +Cols, -Mask): create an all-zero mask.
noise_zero_mask_(Rows, Cols, Mask) :-
    % Build a zero row.
    length(ZeroRow, Cols), maplist(=(0), ZeroRow),
    % Repeat for all rows.
    length(Mask, Rows), maplist(=(ZeroRow), Mask).

% noise_set_mask_cell_(+r(R,C), +MaskIn, -MaskOut): set cell r(R,C) to 1.
noise_set_mask_cell_(r(R,C), MaskIn, MaskOut) :-
    noise_set_cell_(MaskIn, r(R,C), 1, MaskOut).

% noise_color_count(+Grid, +Color, -Count): occurrences of Color in Grid.
noise_color_count(Grid, Color, Count) :-
    noise_flat_(Grid, Flat),
    include(noise_eq_(Color), Flat, ColorCells),
    length(ColorCells, Count).

% noise_eq_(+X, +Y): Y =:= X.
noise_eq_(X, Y) :- Y =:= X, !.

% noise_majority_color(+Grid, -Color): the most frequent color in Grid.
noise_majority_color(Grid, Color) :-
    % Flatten and count all colors.
    noise_flat_(Grid, Flat),
    % Sort to get unique colors.
    sort(Flat, Colors),
    % Count each color.
    findall(Count-C, (member(C, Colors), include(noise_eq_(C), Flat, Cs), length(Cs, Count)), Pairs),
    % Sort by count descending (msort then last).
    msort(Pairs, Sorted),
    % Pick the color with the highest count.
    last(Sorted, _-Color).

% noise_noise_cells(+Grid, +BG, -Cells): cells whose color is not the majority color.
noise_noise_cells(Grid, _BG, Cells) :-
    % Find the dominant color.
    noise_majority_color(Grid, MajColor),
    % All positions where value differs from majority.
    noise_grid_dims_(Grid, Rows, Cols),
    noise_all_positions_(Rows, Cols, All),
    include(noise_not_majority_(Grid, MajColor), All, Cells).

% noise_not_majority_(+Grid, +MajColor, +r(R,C)): cell value != MajColor.
noise_not_majority_(Grid, MajColor, r(R,C)) :-
    nth0(R, Grid, Row), nth0(C, Row, V),
    V =\= MajColor.

% noise_denoise(+Grid, +BG, -Result): replace non-majority cells with the majority color.
noise_denoise(Grid, _BG, Result) :-
    % Find majority color.
    noise_majority_color(Grid, MajColor),
    % Replace non-majority cells with majority color.
    maplist(noise_denoise_row_(MajColor), Grid, Result).

% noise_denoise_row_(+MajColor, +Row, -Clean): replace non-majority values with MajColor.
noise_denoise_row_(MajColor, Row, Clean) :-
    maplist(noise_denoise_cell_(MajColor), Row, Clean).

% noise_denoise_cell_(+Maj, +V, -R): keep V if equal to Maj, else use Maj.
noise_denoise_cell_(Maj, V, Maj) :- V =\= Maj, !.
noise_denoise_cell_(_Maj, V, V).

% noise_sparse_cells(+Grid, +N, -Cells): r(R,C) cells whose color appears fewer than N times.
noise_sparse_cells(Grid, N, Cells) :-
    noise_grid_dims_(Grid, Rows, Cols),
    noise_all_positions_(Rows, Cols, All),
    include(noise_color_sparse_(Grid, N), All, Cells).

% noise_color_sparse_(+Grid, +N, +r(R,C)): color at r(R,C) occurs fewer than N times.
noise_color_sparse_(Grid, N, r(R,C)) :-
    nth0(R, Grid, Row), nth0(C, Row, V),
    noise_color_count(Grid, V, Count),
    Count < N.

% noise_dense_cells(+Grid, +N, -Cells): r(R,C) cells whose color appears N or more times.
noise_dense_cells(Grid, N, Cells) :-
    noise_grid_dims_(Grid, Rows, Cols),
    noise_all_positions_(Rows, Cols, All),
    include(noise_color_dense_(Grid, N), All, Cells).

% noise_color_dense_(+Grid, +N, +r(R,C)): color at r(R,C) occurs N or more times.
noise_color_dense_(Grid, N, r(R,C)) :-
    nth0(R, Grid, Row), nth0(C, Row, V),
    noise_color_count(Grid, V, Count),
    Count >= N.

% noise_isolate_color(+Grid, +Color, +BG) -> Result (3-arg helper).
% noise_isolate_color(+Grid, +Color, -Result): keep Color cells; set others to BG.
% Note: Color and BG are distinct; signature is Grid, Color, Result with BG=0 implied.
% Actual predicate uses 4 args but exported as 3-arg with BG inferred from context.
% Public interface: noise_isolate_color(+Grid, +Color, -Result) uses BG=0 as default.
noise_isolate_color(Grid, Color, Result) :-
    % Default background is 0.
    maplist(noise_isolate_row_(Color, 0), Grid, Result).

% noise_isolate_row_(+Color, +BG, +Row, -NewRow): keep Color, replace others with BG.
noise_isolate_row_(Color, BG, Row, NewRow) :-
    maplist(noise_isolate_cell_(Color, BG), Row, NewRow).

% noise_isolate_cell_(+Color, +BG, +V, -R): keep V if Color, else BG.
noise_isolate_cell_(Color, _BG, V, V) :- V =:= Color, !.
noise_isolate_cell_(_Color, BG, _V, BG).
