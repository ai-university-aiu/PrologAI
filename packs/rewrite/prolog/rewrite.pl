% Module declaration: rewrite pack, Layer 66.
:- module(rewrite, [
    % rw_map_color/3: apply a color substitution map to all grid cells.
    rw_map_color/3,
    % rw_replace_color/4: replace every cell equal to Old with New.
    rw_replace_color/4,
    % rw_swap_colors/4: swap ColorA and ColorB throughout a grid.
    rw_swap_colors/4,
    % rw_set_region/4: set every cell in a region list to a color.
    rw_set_region/4,
    % rw_mask_apply/5: where Mask[R][C]=MaskVal set Fill; else keep original.
    rw_mask_apply/5,
    % rw_overlay/4: paste Grid2 onto Grid1; non-BG cells of Grid2 overwrite.
    rw_overlay/4,
    % rw_stamp/5: paste a patch into a grid at a top-left offset.
    rw_stamp/5,
    % rw_diff_apply/3: apply a list of r(R,C)-Color cell edits to a grid.
    rw_diff_apply/3,
    % rw_normalize/3: renumber distinct non-BG colors to 1,2,... in row-major order.
    rw_normalize/3,
    % rw_invert_colors/3: replace each color V with MaxColor - V.
    rw_invert_colors/3,
    % rw_remap_bg/4: replace all OldBG cells with NewBG.
    rw_remap_bg/4,
    % rw_set_border/3: set every cell on the outermost ring to a color.
    rw_set_border/3,
    % rw_fill_rect/7: fill a rectangular region with a color.
    rw_fill_rect/7,
    % rw_conditional/5: per-cell conditional recolor based on a goal.
    rw_conditional/5
]).

% Import list utilities; msort/length/forall are built-ins, not imported.
:- use_module(library(lists), [member/2, nth0/3, numlist/3]).
% Import higher-order apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% meta_predicate: Goal in rw_conditional is a 3-arg closure called as call(Goal,R,C,V).
:- meta_predicate rw_conditional(+, 3, +, +, -).

% rw_map_color(+Grid, +Map, -Grid2).
% Map is a list of OldColor-NewColor pairs.
% Each cell V is replaced by its mapped value, or kept if not in Map.
rw_map_color(Grid, Map, Grid2) :-
    % Apply row-level mapping to every row in the grid.
    maplist(rw_map_row_(Map), Grid, Grid2).

% rw_map_row_(+Map, +Row, -Row2): apply cell mapping to one row.
rw_map_row_(Map, Row, Row2) :-
    % Apply cell-level mapping to every cell in the row.
    maplist(rw_map_cell_(Map), Row, Row2).

% rw_map_cell_(+Map, +V, -V2): look up V in Map; keep V if absent.
rw_map_cell_(Map, V, V2) :-
    % If V has a mapping, use it; otherwise keep V unchanged.
    ( member(V-V2, Map) -> true ; V2 = V ).

% rw_replace_color(+Grid, +Old, +New, -Grid2).
% Replace every cell equal to Old with New; all others unchanged.
rw_replace_color(Grid, Old, New, Grid2) :-
    % Delegate to rw_map_color with a single-entry map.
    rw_map_color(Grid, [Old-New], Grid2).

% rw_swap_colors(+Grid, +ColorA, +ColorB, -Grid2).
% Cells with ColorA become ColorB and vice versa; others unchanged.
rw_swap_colors(Grid, A, B, Grid2) :-
    % Apply cell-level swap to every cell in every row.
    maplist(maplist(rw_swap_cell_(A, B)), Grid, Grid2).

% rw_swap_cell_(+A, +B, +V, -V2): three-way swap conditional.
rw_swap_cell_(A, B, V, V2) :-
    % A maps to B, B maps to A, anything else stays unchanged.
    ( V =:= A -> V2 = B
    ; V =:= B -> V2 = A
    ; V2 = V
    ).

% rw_set_region(+Grid, +Region, +Color, -Grid2).
% Region is a list of r(R,C) cells. Set all of them to Color.
rw_set_region(Grid, Region, Color, Grid2) :-
    % Convert the region to a diff list of r(R,C)-Color pairs.
    rw_region_to_diff_(Region, Color, Diff),
    % Apply the diff to the grid.
    rw_diff_apply(Grid, Diff, Grid2).

% rw_region_to_diff_(+Region, +Color, -Diff): build diff from region.
rw_region_to_diff_([], _, []).
rw_region_to_diff_([r(R,C)|Rest], Color, [r(R,C)-Color|Diff]) :-
    % Prepend one r(R,C)-Color entry and recurse on the rest.
    rw_region_to_diff_(Rest, Color, Diff).

% rw_mask_apply(+Grid, +Mask, +MaskVal, +Fill, -Grid2).
% Where Mask[R][C] =:= MaskVal, Grid2[R][C] = Fill.
% Where Mask[R][C] =/= MaskVal, Grid2[R][C] = Grid[R][C].
% Mask and Grid must have identical dimensions.
rw_mask_apply(Grid, Mask, MaskVal, Fill, Grid2) :-
    % Pairwise combine corresponding rows from Grid and Mask.
    maplist(rw_mask_row_(MaskVal, Fill), Grid, Mask, Grid2).

% rw_mask_row_(+MaskVal, +Fill, +Row, +MRow, -Row2): mask one row.
rw_mask_row_(MaskVal, Fill, Row, MRow, Row2) :-
    % Pairwise combine corresponding cells from Row and MRow.
    maplist(rw_mask_cell_(MaskVal, Fill), Row, MRow, Row2).

% rw_mask_cell_(+MaskVal, +Fill, +V, +MV, -V2): apply mask to one cell.
rw_mask_cell_(MaskVal, Fill, V, MV, V2) :-
    % If the mask cell matches MaskVal, set Fill; else keep original value.
    ( MV =:= MaskVal -> V2 = Fill ; V2 = V ).

% rw_overlay(+Grid1, +Grid2, +BG, -Grid3).
% Where Grid2[R][C] =/= BG, Grid3[R][C] = Grid2[R][C].
% Where Grid2[R][C] =:= BG, Grid3[R][C] = Grid1[R][C].
rw_overlay(Grid1, Grid2, BG, Grid3) :-
    % Pairwise combine corresponding rows from Grid1 and Grid2.
    maplist(rw_overlay_row_(BG), Grid1, Grid2, Grid3).

% rw_overlay_row_(+BG, +Row1, +Row2, -Row3): overlay one row.
rw_overlay_row_(BG, Row1, Row2, Row3) :-
    % Pairwise combine corresponding cells from Row1 and Row2.
    maplist(rw_overlay_cell_(BG), Row1, Row2, Row3).

% rw_overlay_cell_(+BG, +V1, +V2, -V3): overlay one cell.
rw_overlay_cell_(BG, V1, V2, V3) :-
    % Non-BG cells from Grid2 win; BG cells reveal Grid1.
    ( V2 =\= BG -> V3 = V2 ; V3 = V1 ).

% rw_stamp(+Grid, +Patch, +OffR, +OffC, -Grid2).
% Paste Patch into Grid with Patch's top-left corner at (OffR, OffC).
% Patch cells whose translated coordinates fall outside Grid are ignored.
rw_stamp(Grid, Patch, OffR, OffC, Grid2) :-
    % Build a diff by translating each Patch cell's coordinates.
    findall(r(R,C)-V,
        ( nth0(PR, Patch, PRow),
          nth0(PC, PRow, V),
          R is PR + OffR,
          C is PC + OffC ),
        Diff),
    % Apply the translated diff to the grid.
    rw_diff_apply(Grid, Diff, Grid2).

% rw_diff_apply(+Grid, +Diff, -Grid2).
% Diff is a list of r(R,C)-Color pairs.
% For each grid cell (RI, CI): use the Color from the first matching Diff entry,
% or keep the original value if no entry matches.
% Out-of-bounds r(R,C) entries in Diff are silently ignored.
rw_diff_apply(Grid, Diff, Grid2) :-
    % Compute row count and row index range.
    length(Grid, Rows),
    RowsM1 is Rows - 1,
    numlist(0, RowsM1, RIs),
    % Compute column count from first row; 0 if grid is empty.
    ( Grid = [FR|_] -> length(FR, Cols) ; Cols = 0 ),
    ColsM1 is Cols - 1,
    % Rebuild each row by looking up each cell in the Diff list.
    findall(NewRow,
        ( member(RI, RIs),
          nth0(RI, Grid, OldRow),
          numlist(0, ColsM1, CIs),
          findall(Cell,
            ( member(CI, CIs),
              nth0(CI, OldRow, OldVal),
              ( member(r(RI,CI)-NewVal, Diff) -> Cell = NewVal ; Cell = OldVal )
            ),
            NewRow)
        ),
        Grid2).

% rw_normalize(+Grid, +BG, -Grid2).
% Scan Grid in row-major order. Collect distinct non-BG colors in first-occurrence order.
% Map them to 1, 2, 3, ... BG cells are left unchanged.
rw_normalize(Grid, BG, Grid2) :-
    % Collect all non-BG cell values in row-major traversal order.
    findall(V, (member(Row, Grid), member(V, Row), V =\= BG), Vs),
    % Remove duplicates, keeping first-occurrence ordering.
    rw_unique_order_(Vs, [], Colors),
    % Build a substitution map: each original color maps to 1, 2, ...
    rw_build_remap_(Colors, 1, Map),
    % Apply the map; BG has no entry so it stays unchanged.
    rw_map_color(Grid, Map, Grid2).

% rw_unique_order_(+Vs, +Seen, -Unique): deduplicate preserving order.
rw_unique_order_([], _, []).
rw_unique_order_([V|Vs], Seen, Colors) :-
    % Skip V if already seen; otherwise include it and mark as seen.
    ( member(V, Seen) ->
        rw_unique_order_(Vs, Seen, Colors)
    ;   Colors = [V|Rest],
        rw_unique_order_(Vs, [V|Seen], Rest)
    ).

% rw_build_remap_(+Colors, +N, -Map): pair each color with N, N+1, ...
rw_build_remap_([], _, []).
rw_build_remap_([Old|Rest], N, [Old-N|Map]) :-
    % Pair the current color with N, then recurse with N+1.
    N1 is N + 1,
    rw_build_remap_(Rest, N1, Map).

% rw_invert_colors(+Grid, +MaxColor, -Grid2).
% Replace each cell value V with MaxColor - V.
rw_invert_colors(Grid, Max, Grid2) :-
    % Apply arithmetic complement to every cell in every row.
    maplist(maplist(rw_invert_cell_(Max)), Grid, Grid2).

% rw_invert_cell_(+Max, +V, -V2): complement one cell value.
rw_invert_cell_(Max, V, V2) :-
    % Subtract V from Max to get the inverted color.
    V2 is Max - V.

% rw_remap_bg(+Grid, +OldBG, +NewBG, -Grid2).
% Replace all cells equal to OldBG with NewBG; others unchanged.
rw_remap_bg(Grid, OldBG, NewBG, Grid2) :-
    % Delegate to rw_replace_color for background remapping.
    rw_replace_color(Grid, OldBG, NewBG, Grid2).

% rw_set_border(+Grid, +Color, -Grid2).
% Set every cell on the outermost ring to Color.
% The outermost ring = row 0, last row, column 0, last column.
rw_set_border(Grid, Color, Grid2) :-
    % Compute row count and column count.
    length(Grid, Rows),
    ( Grid = [FR|_] -> length(FR, Cols) ; Cols = 0 ),
    % Compute the index of the last row and last column.
    Rows1 is Rows - 1,
    Cols1 is Cols - 1,
    numlist(0, Rows1, Rs),
    numlist(0, Cols1, Cs),
    % Collect all r(R,C) cells on row 0, last row, col 0, or last col.
    findall(r(R,C),
        ( member(R, Rs), member(C, Cs),
          ( R =:= 0 ; R =:= Rows1 ; C =:= 0 ; C =:= Cols1 ) ),
        BorderCells),
    % Set all border cells to Color.
    rw_set_region(Grid, BorderCells, Color, Grid2).

% rw_fill_rect(+Grid, +R1, +C1, +R2, +C2, +Color, -Grid2).
% Fill every cell (R,C) where R1 =< R =< R2 and C1 =< C =< C2 with Color.
rw_fill_rect(Grid, R1, C1, R2, C2, Color, Grid2) :-
    % Build the list of row indices within the rectangle.
    numlist(R1, R2, Rs),
    % Build the list of column indices within the rectangle.
    numlist(C1, C2, Cs),
    % Cross-product to get every r(R,C) cell in the rectangular region.
    findall(r(R,C), (member(R, Rs), member(C, Cs)), Region),
    % Set the entire rectangular region to Color.
    rw_set_region(Grid, Region, Color, Grid2).

% rw_conditional(+Grid, +Goal, +ColorTrue, +ColorFalse, -Grid2).
% For each cell at (R, C) with value V, call Goal(R, C, V).
% If Goal succeeds, Grid2[R][C] = ColorTrue; else Grid2[R][C] = ColorFalse.
rw_conditional(Grid, Goal, ColorTrue, ColorFalse, Grid2) :-
    % Build the row index range.
    length(Grid, Rows),
    RowsM1 is Rows - 1,
    numlist(0, RowsM1, RIs),
    % Rebuild each row by applying the conditional test to each cell.
    findall(Row2,
        ( member(RI, RIs),
          nth0(RI, Grid, Row),
          length(Row, Cols),
          ColsM1 is Cols - 1,
          numlist(0, ColsM1, CIs),
          findall(Cell,
            ( member(CI, CIs),
              nth0(CI, Row, V),
              ( call(Goal, RI, CI, V) -> Cell = ColorTrue ; Cell = ColorFalse )
            ),
            Row2)
        ),
        Grid2).
