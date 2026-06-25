% Module declaration: noise pack, Layer 61.
:- module(noise, [
    % ns_mask_apply/4: apply a binary mask to a grid, replacing masked cells.
    ns_mask_apply/4,
    % ns_mask_invert/3: invert a binary mask (0->1, 1->0).
    ns_mask_invert/3,
    % ns_mask_and/3: bitwise AND of two same-size binary masks.
    ns_mask_and/3,
    % ns_mask_or/3: bitwise OR of two same-size binary masks.
    ns_mask_or/3,
    % ns_mask_from_color/3: build a binary mask: 1 where grid has color, 0 elsewhere.
    ns_mask_from_color/3,
    % ns_mask_to_region/2: convert a binary mask to a list of r(R,C) cells (mask=1).
    ns_mask_to_region/2,
    % ns_region_to_mask/4: convert a region list to a binary mask grid.
    ns_region_to_mask/4,
    % ns_noise_cells/3: list of r(R,C) cells that differ from the majority color.
    ns_noise_cells/3,
    % ns_denoise/3: replace noise cells with the majority color.
    ns_denoise/3,
    % ns_majority_color/2: most frequent color in a grid.
    ns_majority_color/2,
    % ns_color_count/3: count occurrences of a color in a grid.
    ns_color_count/3,
    % ns_sparse_cells/3: cells whose color appears fewer than N times total.
    ns_sparse_cells/3,
    % ns_dense_cells/3: cells whose color appears N or more times total.
    ns_dense_cells/3,
    % ns_isolate_color/3: set all non-Color cells to BG, keep Color cells.
    ns_isolate_color/3
]).

% Import list and apply utilities.
% msort/2 is a SWI-Prolog built-in, not imported from library(lists).
:- use_module(library(lists),  [member/2, nth0/3, numlist/3]).
:- use_module(library(apply),  [maplist/2, maplist/3, include/3, foldl/4]).

% ns_grid_dims_(+Grid, -Rows, -Cols): dimensions of a grid.
ns_grid_dims_(Grid, Rows, Cols) :-
    % Count rows.
    length(Grid, Rows),
    % Count columns from first row.
    ( Rows > 0 -> Grid = [R0|_], length(R0, Cols) ; Cols = 0 ).

% ns_flat_(+Grid, -Flat): flatten grid to a list of values.
ns_flat_(Grid, Flat) :-
    append(Grid, Flat).

% ns_cell_val_(+Grid, +r(R,C), -V): value at a cell.
ns_cell_val_(Grid, r(R,C), V) :-
    nth0(R, Grid, Row), nth0(C, Row, V).

% ns_set_cell_(+Grid, +r(R,C), +V, -Result): set a cell value.
ns_set_cell_(Grid, r(R,C), V, Result) :-
    % Build prefix rows and modified row.
    length(PreRows, R),
    append(PreRows, [OldRow|SufRows], Grid),
    % Build prefix cols and modified col within the row.
    length(PreCols, C),
    append(PreCols, [_|SufCols], OldRow),
    append(PreCols, [V|SufCols], NewRow),
    append(PreRows, [NewRow|SufRows], Result).

% ns_all_positions_(+Rows, +Cols, -Positions): all r(R,C) positions.
ns_all_positions_(Rows, Cols, Positions) :-
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    findall(r(R,C), (member(R, RowIds), member(C, ColIds)), Positions).

% ns_mask_apply(+Grid, +Mask, +FillColor, -Result): replace cells where Mask=1 with FillColor.
ns_mask_apply(Grid, Mask, FillColor, Result) :-
    % Apply row by row.
    maplist(ns_mask_apply_row_(FillColor), Grid, Mask, Result).

% ns_mask_apply_row_(+FillColor, +GRow, +MRow, -RRow): mask one row.
ns_mask_apply_row_(FillColor, GRow, MRow, RRow) :-
    maplist(ns_mask_cell_(FillColor), GRow, MRow, RRow).

% ns_mask_cell_(+Fill, +GV, +MV, -RV): apply mask to one cell.
ns_mask_cell_(Fill, _GV, 1, Fill) :- !.
ns_mask_cell_(_Fill, GV, 0, GV).

% ns_mask_invert(+Mask, +Rows, -Inverted): flip 0<->1 in mask.
ns_mask_invert(Mask, _Rows, Inverted) :-
    maplist(ns_invert_row_, Mask, Inverted).

% ns_invert_row_(+Row, -Inverted): flip each cell in a mask row.
ns_invert_row_(Row, Inverted) :-
    maplist(ns_flip_bit_, Row, Inverted).

% ns_flip_bit_(+B, -F): 0->1, 1->0.
ns_flip_bit_(0, 1) :- !.
ns_flip_bit_(1, 0).

% ns_mask_and(+Mask1, +Mask2, -Result): pointwise AND of two binary masks.
ns_mask_and(Mask1, Mask2, Result) :-
    maplist(ns_and_row_, Mask1, Mask2, Result).

% ns_and_row_(+R1, +R2, -R): AND two mask rows.
ns_and_row_(R1, R2, R) :-
    maplist(ns_and_bit_, R1, R2, R).

% ns_and_bit_(+A, +B, -C): C = A AND B.
ns_and_bit_(1, 1, 1) :- !.
ns_and_bit_(_, _, 0).

% ns_mask_or(+Mask1, +Mask2, -Result): pointwise OR of two binary masks.
ns_mask_or(Mask1, Mask2, Result) :-
    maplist(ns_or_row_, Mask1, Mask2, Result).

% ns_or_row_(+R1, +R2, -R): OR two mask rows.
ns_or_row_(R1, R2, R) :-
    maplist(ns_or_bit_, R1, R2, R).

% ns_or_bit_(+A, +B, -C): C = A OR B.
ns_or_bit_(0, 0, 0) :- !.
ns_or_bit_(_, _, 1).

% ns_mask_from_color(+Grid, +Color, -Mask): 1 where Grid cell equals Color.
ns_mask_from_color(Grid, Color, Mask) :-
    maplist(ns_color_mask_row_(Color), Grid, Mask).

% ns_color_mask_row_(+Color, +Row, -MRow): 1 for Color cells, 0 for others.
ns_color_mask_row_(Color, Row, MRow) :-
    maplist(ns_color_mask_cell_(Color), Row, MRow).

% ns_color_mask_cell_(+Color, +V, -M): 1 if V=Color, else 0.
ns_color_mask_cell_(Color, V, 1) :- V =:= Color, !.
ns_color_mask_cell_(_Color, _V, 0).

% ns_mask_to_region(+Mask, -Region): list of r(R,C) where Mask=1.
ns_mask_to_region(Mask, Region) :-
    % Enumerate all positions and keep those where mask=1.
    ns_grid_dims_(Mask, Rows, Cols),
    ns_all_positions_(Rows, Cols, All),
    include(ns_mask_is_one_(Mask), All, Region).

% ns_mask_is_one_(+Mask, +r(R,C)): mask value at r(R,C) is 1.
ns_mask_is_one_(Mask, r(R,C)) :-
    nth0(R, Mask, Row), nth0(C, Row, 1).

% ns_region_to_mask(+Region, +Rows, +Cols, -Mask): build mask from region list.
ns_region_to_mask(Region, Rows, Cols, Mask) :-
    % Start with all-zero mask.
    ns_zero_mask_(Rows, Cols, ZeroMask),
    % Set 1 for each region cell.
    foldl(ns_set_mask_cell_, Region, ZeroMask, Mask).

% ns_zero_mask_(+Rows, +Cols, -Mask): create an all-zero mask.
ns_zero_mask_(Rows, Cols, Mask) :-
    % Build a zero row.
    length(ZeroRow, Cols), maplist(=(0), ZeroRow),
    % Repeat for all rows.
    length(Mask, Rows), maplist(=(ZeroRow), Mask).

% ns_set_mask_cell_(+r(R,C), +MaskIn, -MaskOut): set cell r(R,C) to 1.
ns_set_mask_cell_(r(R,C), MaskIn, MaskOut) :-
    ns_set_cell_(MaskIn, r(R,C), 1, MaskOut).

% ns_color_count(+Grid, +Color, -Count): occurrences of Color in Grid.
ns_color_count(Grid, Color, Count) :-
    ns_flat_(Grid, Flat),
    include(ns_eq_(Color), Flat, ColorCells),
    length(ColorCells, Count).

% ns_eq_(+X, +Y): Y =:= X.
ns_eq_(X, Y) :- Y =:= X, !.

% ns_majority_color(+Grid, -Color): the most frequent color in Grid.
ns_majority_color(Grid, Color) :-
    % Flatten and count all colors.
    ns_flat_(Grid, Flat),
    % Sort to get unique colors.
    sort(Flat, Colors),
    % Count each color.
    findall(Count-C, (member(C, Colors), include(ns_eq_(C), Flat, Cs), length(Cs, Count)), Pairs),
    % Sort by count descending (msort then last).
    msort(Pairs, Sorted),
    % Pick the color with the highest count.
    last(Sorted, _-Color).

% ns_noise_cells(+Grid, +BG, -Cells): cells whose color is not the majority color.
ns_noise_cells(Grid, _BG, Cells) :-
    % Find the dominant color.
    ns_majority_color(Grid, MajColor),
    % All positions where value differs from majority.
    ns_grid_dims_(Grid, Rows, Cols),
    ns_all_positions_(Rows, Cols, All),
    include(ns_not_majority_(Grid, MajColor), All, Cells).

% ns_not_majority_(+Grid, +MajColor, +r(R,C)): cell value != MajColor.
ns_not_majority_(Grid, MajColor, r(R,C)) :-
    nth0(R, Grid, Row), nth0(C, Row, V),
    V =\= MajColor.

% ns_denoise(+Grid, +BG, -Result): replace non-majority cells with the majority color.
ns_denoise(Grid, _BG, Result) :-
    % Find majority color.
    ns_majority_color(Grid, MajColor),
    % Replace non-majority cells with majority color.
    maplist(ns_denoise_row_(MajColor), Grid, Result).

% ns_denoise_row_(+MajColor, +Row, -Clean): replace non-majority values with MajColor.
ns_denoise_row_(MajColor, Row, Clean) :-
    maplist(ns_denoise_cell_(MajColor), Row, Clean).

% ns_denoise_cell_(+Maj, +V, -R): keep V if equal to Maj, else use Maj.
ns_denoise_cell_(Maj, V, Maj) :- V =\= Maj, !.
ns_denoise_cell_(_Maj, V, V).

% ns_sparse_cells(+Grid, +N, -Cells): r(R,C) cells whose color appears fewer than N times.
ns_sparse_cells(Grid, N, Cells) :-
    ns_grid_dims_(Grid, Rows, Cols),
    ns_all_positions_(Rows, Cols, All),
    include(ns_color_sparse_(Grid, N), All, Cells).

% ns_color_sparse_(+Grid, +N, +r(R,C)): color at r(R,C) occurs fewer than N times.
ns_color_sparse_(Grid, N, r(R,C)) :-
    nth0(R, Grid, Row), nth0(C, Row, V),
    ns_color_count(Grid, V, Count),
    Count < N.

% ns_dense_cells(+Grid, +N, -Cells): r(R,C) cells whose color appears N or more times.
ns_dense_cells(Grid, N, Cells) :-
    ns_grid_dims_(Grid, Rows, Cols),
    ns_all_positions_(Rows, Cols, All),
    include(ns_color_dense_(Grid, N), All, Cells).

% ns_color_dense_(+Grid, +N, +r(R,C)): color at r(R,C) occurs N or more times.
ns_color_dense_(Grid, N, r(R,C)) :-
    nth0(R, Grid, Row), nth0(C, Row, V),
    ns_color_count(Grid, V, Count),
    Count >= N.

% ns_isolate_color(+Grid, +Color, +BG) -> Result (3-arg helper).
% ns_isolate_color(+Grid, +Color, -Result): keep Color cells; set others to BG.
% Note: Color and BG are distinct; signature is Grid, Color, Result with BG=0 implied.
% Actual predicate uses 4 args but exported as 3-arg with BG inferred from context.
% Public interface: ns_isolate_color(+Grid, +Color, -Result) uses BG=0 as default.
ns_isolate_color(Grid, Color, Result) :-
    % Default background is 0.
    maplist(ns_isolate_row_(Color, 0), Grid, Result).

% ns_isolate_row_(+Color, +BG, +Row, -NewRow): keep Color, replace others with BG.
ns_isolate_row_(Color, BG, Row, NewRow) :-
    maplist(ns_isolate_cell_(Color, BG), Row, NewRow).

% ns_isolate_cell_(+Color, +BG, +V, -R): keep V if Color, else BG.
ns_isolate_cell_(Color, _BG, V, V) :- V =:= Color, !.
ns_isolate_cell_(_Color, BG, _V, BG).
