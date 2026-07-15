% Module declaration: induction pack, Layer 59.
:- module(induction, [
    % induction_color_map/3: infer a color substitution map from input and output grids.
    induction_color_map/3,
    % induction_is_recolor/2: true when output is a pure color substitution of input.
    induction_is_recolor/2,
    % induction_uniform_output/2: true when every cell in output has the same color.
    induction_uniform_output/2,
    % induction_output_color/2: the single uniform color in output (fails if not uniform).
    induction_output_color/2,
    % induction_size_ratio/3: ratio of output dimensions to input dimensions.
    induction_size_ratio/3,
    % induction_is_scale/2: true when output is an integer scale of input.
    induction_is_scale/2,
    % induction_scale_factor/3: integer scale factor when output is a scaled input.
    induction_scale_factor/3,
    % induction_changed_cells/3: cells that changed value from input to output.
    induction_changed_cells/3,
    % induction_unchanged_cells/3: cells that kept their value from input to output.
    induction_unchanged_cells/3,
    % induction_input_colors/2: sorted list of distinct colors in input.
    induction_input_colors/2,
    % induction_output_colors/2: sorted list of distinct colors in output.
    induction_output_colors/2,
    % induction_new_colors/3: colors in output that were not in input.
    induction_new_colors/3,
    % induction_lost_colors/3: colors in input that are not in output.
    induction_lost_colors/3,
    % induction_grid_dims/3: rows and columns of a grid.
    induction_grid_dims/3,
    % induction_cross_pair_invariants/2: properties that hold for every pair in a list.
    induction_cross_pair_invariants/2,
    % induction_cross_pair_variants/2: properties that hold for SOME but not ALL pairs.
    induction_cross_pair_variants/2
]).

% Import list and apply utilities.
:- use_module(library(lists),  [member/2, nth0/3, numlist/3, subtract/3]).
:- use_module(library(apply),  [maplist/2, maplist/3, include/3]).

% induction_grid_dims(+Grid, -Rows, -Cols): dimensions of a grid.
induction_grid_dims(Grid, Rows, Cols) :-
    % Count rows.
    length(Grid, Rows),
    % Count columns from first row.
    ( Rows > 0 -> Grid = [R0|_], length(R0, Cols) ; Cols = 0 ).

% induction_flat_(+Grid, -Flat): flatten grid to list of values.
induction_flat_(Grid, Flat) :-
    append(Grid, Flat).

% induction_colors_(+Grid, -Colors): sorted distinct color values.
induction_colors_(Grid, Colors) :-
    induction_flat_(Grid, Flat),
    sort(Flat, Colors).

% induction_input_colors(+Input, -Colors): sorted distinct colors in Input.
induction_input_colors(Input, Colors) :-
    induction_colors_(Input, Colors).

% induction_output_colors(+Output, -Colors): sorted distinct colors in Output.
induction_output_colors(Output, Colors) :-
    induction_colors_(Output, Colors).

% induction_new_colors(+Input, +Output, -New): colors in Output not in Input.
induction_new_colors(Input, Output, New) :-
    % Get both color sets.
    induction_input_colors(Input, InColors),
    induction_output_colors(Output, OutColors),
    % Subtract InColors from OutColors.
    subtract(OutColors, InColors, New).

% induction_lost_colors(+Input, +Output, -Lost): colors in Input not in Output.
induction_lost_colors(Input, Output, Lost) :-
    % Get both color sets.
    induction_input_colors(Input, InColors),
    induction_output_colors(Output, OutColors),
    % Subtract OutColors from InColors.
    subtract(InColors, OutColors, Lost).

% induction_all_positions_(+Rows, +Cols, -Positions): all r(R,C) in row-major order.
induction_all_positions_(Rows, Cols, Positions) :-
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    findall(r(R,C), (member(R, RowIds), member(C, ColIds)), Positions).

% induction_cell_val_(+Grid, +r(R,C), -V): value at cell.
induction_cell_val_(Grid, r(R,C), V) :-
    nth0(R, Grid, Row), nth0(C, Row, V).

% induction_cell_differs_(+In, +Out, +Cell): cell values differ.
induction_cell_differs_(In, Out, Cell) :-
    induction_cell_val_(In, Cell, VI),
    induction_cell_val_(Out, Cell, VO),
    VI \= VO.

% induction_cell_same_(+In, +Out, +Cell): cell values are equal.
induction_cell_same_(In, Out, Cell) :-
    induction_cell_val_(In, Cell, VI),
    induction_cell_val_(Out, Cell, VO),
    VI =:= VO.

% induction_changed_cells(+Input, +Output, -Changed): cells that changed value.
induction_changed_cells(Input, Output, Changed) :-
    % Assume same dimensions.
    induction_grid_dims(Input, Rows, Cols),
    induction_all_positions_(Rows, Cols, All),
    include(induction_cell_differs_(Input, Output), All, Changed).

% induction_unchanged_cells(+Input, +Output, -Unchanged): cells that kept value.
induction_unchanged_cells(Input, Output, Unchanged) :-
    induction_grid_dims(Input, Rows, Cols),
    induction_all_positions_(Rows, Cols, All),
    include(induction_cell_same_(Input, Output), All, Unchanged).

% induction_build_map_(+Input, +Output, +Changed, -Map): OldColor-NewColor pairs.
induction_build_map_(Input, Output, Changed, Map) :-
    % Collect Old-New pairs for changed cells.
    findall(OldC-NewC,
        (member(Cell, Changed),
         induction_cell_val_(Input, Cell, OldC),
         induction_cell_val_(Output, Cell, NewC)),
        Pairs),
    % Remove duplicates.
    sort(Pairs, Map).

% induction_color_map(+Input, +Output, -Map): inferred color substitution pairs.
induction_color_map(Input, Output, Map) :-
    % Find all changed cells.
    induction_changed_cells(Input, Output, Changed),
    % Build OldColor-NewColor pairs.
    induction_build_map_(Input, Output, Changed, Map).

% induction_map_consistent_(+Map, +Input, +Output): every cell matches the map.
induction_map_consistent_(Map, Input, Output) :-
    induction_grid_dims(Input, Rows, Cols),
    induction_all_positions_(Rows, Cols, All),
    % No cell violates the map.
    \+ (member(Cell, All),
        induction_cell_val_(Input, Cell, InV),
        induction_cell_val_(Output, Cell, OutV),
        ( member(InV-Expected, Map) -> OutV \= Expected ; InV \= OutV )).

% induction_is_recolor(+Input, +Output): output is a consistent color substitution.
induction_is_recolor(Input, Output) :-
    % Compute the color map.
    induction_color_map(Input, Output, Map),
    % Verify every cell is consistent with this map.
    induction_map_consistent_(Map, Input, Output).

% induction_uniform_output(+Output, ?Color): output has only one distinct color.
induction_uniform_output(Output, Color) :-
    induction_flat_(Output, Flat),
    % Sort to find distinct colors.
    sort(Flat, [Color]).

% induction_output_color(+Output, -Color): single uniform color in output.
induction_output_color(Output, Color) :-
    induction_uniform_output(Output, Color).

% induction_size_ratio(+Input, +Output, -Ratio): Ratio = (OutRows/InRows)-(OutCols/InCols).
induction_size_ratio(Input, Output, RR-RC) :-
    induction_grid_dims(Input, InR, InC),
    induction_grid_dims(Output, OutR, OutC),
    % Compute ratios as exact fractions.
    InR > 0, InC > 0,
    RR is OutR / InR, RC is OutC / InC.

% induction_is_scale(+Input, +Output): output is an integer scale of input.
induction_is_scale(Input, Output) :-
    induction_grid_dims(Input, InR, InC),
    induction_grid_dims(Output, OutR, OutC),
    InR > 0, InC > 0,
    % Ratios must be equal positive integers.
    OutR mod InR =:= 0,
    OutC mod InC =:= 0,
    K is OutR // InR,
    K > 0,
    OutC // InC =:= K.

% induction_scale_factor(+Input, +Output, -K): integer scale factor.
induction_scale_factor(Input, Output, K) :-
    induction_is_scale(Input, Output),
    induction_grid_dims(Input, InR, _),
    induction_grid_dims(Output, OutR, _),
    K is OutR // InR.

% induction_cross_pair_invariants(+Pairs, -Invariants)
% Invariants is the sorted list of property atoms that hold for every pair in Pairs.
% Pairs is a list of pair(InGrid, OutGrid) terms.
% Property atoms tested: dims_preserved, colors_preserved, total_nonzero_preserved,
%   monotone_input, monotone_output, bg_preserved, scale_preserved.
induction_cross_pair_invariants(Pairs, Invariants) :-
    AllProps = [dims_preserved, colors_preserved, total_nonzero_preserved,
                monotone_input, monotone_output, bg_preserved, scale_preserved],
    include(induction_prop_holds_all_(Pairs), AllProps, Invariants).

% induction_prop_holds_all_(+Pairs, +Prop): succeed if Prop holds for every pair.
induction_prop_holds_all_(Pairs, Prop) :-
    forall(member(pair(In, Out), Pairs),
           induction_pair_prop_(Prop, In, Out)).

% induction_pair_prop_(+Prop, +In, +Out): test one property for a single pair.
induction_pair_prop_(dims_preserved, In, Out) :-
    induction_grid_dims(In, R, C), induction_grid_dims(Out, R, C).
induction_pair_prop_(colors_preserved, In, Out) :-
    induction_input_colors(In, CI), induction_output_colors(Out, CO), CI = CO.
induction_pair_prop_(total_nonzero_preserved, In, Out) :-
    induction_flat_(In, FI), include([V]>>(V \= 0), FI, NZI),
    induction_flat_(Out, FO), include([V]>>(V \= 0), FO, NZO),
    length(NZI, N), length(NZO, N).
induction_pair_prop_(monotone_input, In, _) :-
    induction_input_colors(In, CI0), subtract(CI0, [0], CI), length(CI, 1).
induction_pair_prop_(monotone_output, _, Out) :-
    induction_output_colors(Out, CO0), subtract(CO0, [0], CO), length(CO, 1).
induction_pair_prop_(bg_preserved, In, Out) :-
    findall(R-C, (nth0(R, In,  InRow),  nth0(C, InRow,  0)), BgIn),
    findall(R-C, (nth0(R, Out, OutRow), nth0(C, OutRow, 0)), BgOut),
    msort(BgIn, S1), msort(BgOut, S2), S1 = S2.
induction_pair_prop_(scale_preserved, In, Out) :-
    induction_grid_dims(In, R, C), induction_grid_dims(Out, R, C).

% induction_cross_pair_variants(+Pairs, -Variants)
% Variants is the sorted list of property atoms that hold for SOME but not ALL pairs.
% Properties that hold for zero pairs are excluded (they are simply absent from both lists).
induction_cross_pair_variants(Pairs, Variants) :-
    AllProps = [dims_preserved, colors_preserved, total_nonzero_preserved,
                monotone_input, monotone_output, bg_preserved, scale_preserved],
    induction_cross_pair_invariants(Pairs, Invariants),
    include(induction_prop_holds_some_(Pairs), AllProps, HoldsSome),
    subtract(HoldsSome, Invariants, Variants).

% induction_prop_holds_some_(+Pairs, +Prop): succeed if Prop holds for at least one pair.
induction_prop_holds_some_(Pairs, Prop) :-
    member(pair(In, Out), Pairs),
    induction_pair_prop_(Prop, In, Out),
    !.
