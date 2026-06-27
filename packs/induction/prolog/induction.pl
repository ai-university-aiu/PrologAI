% Module declaration: induction pack, Layer 59.
:- module(induction, [
    % id_color_map/3: infer a color substitution map from input and output grids.
    id_color_map/3,
    % id_is_recolor/2: true when output is a pure color substitution of input.
    id_is_recolor/2,
    % id_uniform_output/2: true when every cell in output has the same color.
    id_uniform_output/2,
    % id_output_color/2: the single uniform color in output (fails if not uniform).
    id_output_color/2,
    % id_size_ratio/3: ratio of output dimensions to input dimensions.
    id_size_ratio/3,
    % id_is_scale/2: true when output is an integer scale of input.
    id_is_scale/2,
    % id_scale_factor/3: integer scale factor when output is a scaled input.
    id_scale_factor/3,
    % id_changed_cells/3: cells that changed value from input to output.
    id_changed_cells/3,
    % id_unchanged_cells/3: cells that kept their value from input to output.
    id_unchanged_cells/3,
    % id_input_colors/2: sorted list of distinct colors in input.
    id_input_colors/2,
    % id_output_colors/2: sorted list of distinct colors in output.
    id_output_colors/2,
    % id_new_colors/3: colors in output that were not in input.
    id_new_colors/3,
    % id_lost_colors/3: colors in input that are not in output.
    id_lost_colors/3,
    % id_grid_dims/3: rows and columns of a grid.
    id_grid_dims/3,
    % id_cross_pair_invariants/2: properties that hold for every pair in a list.
    id_cross_pair_invariants/2,
    % id_cross_pair_variants/2: properties that hold for SOME but not ALL pairs.
    id_cross_pair_variants/2
]).

% Import list and apply utilities.
:- use_module(library(lists),  [member/2, nth0/3, numlist/3, subtract/3]).
:- use_module(library(apply),  [maplist/2, maplist/3, include/3]).

% id_grid_dims(+Grid, -Rows, -Cols): dimensions of a grid.
id_grid_dims(Grid, Rows, Cols) :-
    % Count rows.
    length(Grid, Rows),
    % Count columns from first row.
    ( Rows > 0 -> Grid = [R0|_], length(R0, Cols) ; Cols = 0 ).

% id_flat_(+Grid, -Flat): flatten grid to list of values.
id_flat_(Grid, Flat) :-
    append(Grid, Flat).

% id_colors_(+Grid, -Colors): sorted distinct color values.
id_colors_(Grid, Colors) :-
    id_flat_(Grid, Flat),
    sort(Flat, Colors).

% id_input_colors(+Input, -Colors): sorted distinct colors in Input.
id_input_colors(Input, Colors) :-
    id_colors_(Input, Colors).

% id_output_colors(+Output, -Colors): sorted distinct colors in Output.
id_output_colors(Output, Colors) :-
    id_colors_(Output, Colors).

% id_new_colors(+Input, +Output, -New): colors in Output not in Input.
id_new_colors(Input, Output, New) :-
    % Get both color sets.
    id_input_colors(Input, InColors),
    id_output_colors(Output, OutColors),
    % Subtract InColors from OutColors.
    subtract(OutColors, InColors, New).

% id_lost_colors(+Input, +Output, -Lost): colors in Input not in Output.
id_lost_colors(Input, Output, Lost) :-
    % Get both color sets.
    id_input_colors(Input, InColors),
    id_output_colors(Output, OutColors),
    % Subtract OutColors from InColors.
    subtract(InColors, OutColors, Lost).

% id_all_positions_(+Rows, +Cols, -Positions): all r(R,C) in row-major order.
id_all_positions_(Rows, Cols, Positions) :-
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    findall(r(R,C), (member(R, RowIds), member(C, ColIds)), Positions).

% id_cell_val_(+Grid, +r(R,C), -V): value at cell.
id_cell_val_(Grid, r(R,C), V) :-
    nth0(R, Grid, Row), nth0(C, Row, V).

% id_cell_differs_(+In, +Out, +Cell): cell values differ.
id_cell_differs_(In, Out, Cell) :-
    id_cell_val_(In, Cell, VI),
    id_cell_val_(Out, Cell, VO),
    VI \= VO.

% id_cell_same_(+In, +Out, +Cell): cell values are equal.
id_cell_same_(In, Out, Cell) :-
    id_cell_val_(In, Cell, VI),
    id_cell_val_(Out, Cell, VO),
    VI =:= VO.

% id_changed_cells(+Input, +Output, -Changed): cells that changed value.
id_changed_cells(Input, Output, Changed) :-
    % Assume same dimensions.
    id_grid_dims(Input, Rows, Cols),
    id_all_positions_(Rows, Cols, All),
    include(id_cell_differs_(Input, Output), All, Changed).

% id_unchanged_cells(+Input, +Output, -Unchanged): cells that kept value.
id_unchanged_cells(Input, Output, Unchanged) :-
    id_grid_dims(Input, Rows, Cols),
    id_all_positions_(Rows, Cols, All),
    include(id_cell_same_(Input, Output), All, Unchanged).

% id_build_map_(+Input, +Output, +Changed, -Map): OldColor-NewColor pairs.
id_build_map_(Input, Output, Changed, Map) :-
    % Collect Old-New pairs for changed cells.
    findall(OldC-NewC,
        (member(Cell, Changed),
         id_cell_val_(Input, Cell, OldC),
         id_cell_val_(Output, Cell, NewC)),
        Pairs),
    % Remove duplicates.
    sort(Pairs, Map).

% id_color_map(+Input, +Output, -Map): inferred color substitution pairs.
id_color_map(Input, Output, Map) :-
    % Find all changed cells.
    id_changed_cells(Input, Output, Changed),
    % Build OldColor-NewColor pairs.
    id_build_map_(Input, Output, Changed, Map).

% id_map_consistent_(+Map, +Input, +Output): every cell matches the map.
id_map_consistent_(Map, Input, Output) :-
    id_grid_dims(Input, Rows, Cols),
    id_all_positions_(Rows, Cols, All),
    % No cell violates the map.
    \+ (member(Cell, All),
        id_cell_val_(Input, Cell, InV),
        id_cell_val_(Output, Cell, OutV),
        ( member(InV-Expected, Map) -> OutV \= Expected ; InV \= OutV )).

% id_is_recolor(+Input, +Output): output is a consistent color substitution.
id_is_recolor(Input, Output) :-
    % Compute the color map.
    id_color_map(Input, Output, Map),
    % Verify every cell is consistent with this map.
    id_map_consistent_(Map, Input, Output).

% id_uniform_output(+Output, ?Color): output has only one distinct color.
id_uniform_output(Output, Color) :-
    id_flat_(Output, Flat),
    % Sort to find distinct colors.
    sort(Flat, [Color]).

% id_output_color(+Output, -Color): single uniform color in output.
id_output_color(Output, Color) :-
    id_uniform_output(Output, Color).

% id_size_ratio(+Input, +Output, -Ratio): Ratio = (OutRows/InRows)-(OutCols/InCols).
id_size_ratio(Input, Output, RR-RC) :-
    id_grid_dims(Input, InR, InC),
    id_grid_dims(Output, OutR, OutC),
    % Compute ratios as exact fractions.
    InR > 0, InC > 0,
    RR is OutR / InR, RC is OutC / InC.

% id_is_scale(+Input, +Output): output is an integer scale of input.
id_is_scale(Input, Output) :-
    id_grid_dims(Input, InR, InC),
    id_grid_dims(Output, OutR, OutC),
    InR > 0, InC > 0,
    % Ratios must be equal positive integers.
    OutR mod InR =:= 0,
    OutC mod InC =:= 0,
    K is OutR // InR,
    K > 0,
    OutC // InC =:= K.

% id_scale_factor(+Input, +Output, -K): integer scale factor.
id_scale_factor(Input, Output, K) :-
    id_is_scale(Input, Output),
    id_grid_dims(Input, InR, _),
    id_grid_dims(Output, OutR, _),
    K is OutR // InR.

% id_cross_pair_invariants(+Pairs, -Invariants)
% Invariants is the sorted list of property atoms that hold for every pair in Pairs.
% Pairs is a list of pair(InGrid, OutGrid) terms.
% Property atoms tested: dims_preserved, colors_preserved, total_nonzero_preserved,
%   monotone_input, monotone_output, bg_preserved, scale_preserved.
id_cross_pair_invariants(Pairs, Invariants) :-
    AllProps = [dims_preserved, colors_preserved, total_nonzero_preserved,
                monotone_input, monotone_output, bg_preserved, scale_preserved],
    include(id_prop_holds_all_(Pairs), AllProps, Invariants).

% id_prop_holds_all_(+Pairs, +Prop): succeed if Prop holds for every pair.
id_prop_holds_all_(Pairs, Prop) :-
    forall(member(pair(In, Out), Pairs),
           id_pair_prop_(Prop, In, Out)).

% id_pair_prop_(+Prop, +In, +Out): test one property for a single pair.
id_pair_prop_(dims_preserved, In, Out) :-
    id_grid_dims(In, R, C), id_grid_dims(Out, R, C).
id_pair_prop_(colors_preserved, In, Out) :-
    id_input_colors(In, CI), id_output_colors(Out, CO), CI = CO.
id_pair_prop_(total_nonzero_preserved, In, Out) :-
    id_flat_(In, FI), include([V]>>(V \= 0), FI, NZI),
    id_flat_(Out, FO), include([V]>>(V \= 0), FO, NZO),
    length(NZI, N), length(NZO, N).
id_pair_prop_(monotone_input, In, _) :-
    id_input_colors(In, CI0), subtract(CI0, [0], CI), length(CI, 1).
id_pair_prop_(monotone_output, _, Out) :-
    id_output_colors(Out, CO0), subtract(CO0, [0], CO), length(CO, 1).
id_pair_prop_(bg_preserved, In, Out) :-
    findall(R-C, (nth0(R, In,  InRow),  nth0(C, InRow,  0)), BgIn),
    findall(R-C, (nth0(R, Out, OutRow), nth0(C, OutRow, 0)), BgOut),
    msort(BgIn, S1), msort(BgOut, S2), S1 = S2.
id_pair_prop_(scale_preserved, In, Out) :-
    id_grid_dims(In, R, C), id_grid_dims(Out, R, C).

% id_cross_pair_variants(+Pairs, -Variants)
% Variants is the sorted list of property atoms that hold for SOME but not ALL pairs.
% Properties that hold for zero pairs are excluded (they are simply absent from both lists).
id_cross_pair_variants(Pairs, Variants) :-
    AllProps = [dims_preserved, colors_preserved, total_nonzero_preserved,
                monotone_input, monotone_output, bg_preserved, scale_preserved],
    id_cross_pair_invariants(Pairs, Invariants),
    include(id_prop_holds_some_(Pairs), AllProps, HoldsSome),
    subtract(HoldsSome, Invariants, Variants).

% id_prop_holds_some_(+Pairs, +Prop): succeed if Prop holds for at least one pair.
id_prop_holds_some_(Pairs, Prop) :-
    member(pair(In, Out), Pairs),
    id_pair_prop_(Prop, In, Out),
    !.
