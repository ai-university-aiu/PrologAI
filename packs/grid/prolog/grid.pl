/*  PrologAI — ARC-AGI Grid Perception and Manipulation  (Specification PR 56)

    A grid is a list of rows; each row is a list of integer color codes (0-9).
    Example: Grid = [[0,1,0],[1,0,1],[0,1,0]]

    All row and column indices are zero-based.

    Exported predicates:

    gd_size/3          +Grid, -Rows, -Cols
    gd_cell/4          +Grid, +R, +C, -Color
    gd_row/3           +Grid, +R, -Row
    gd_col/3           +Grid, +C, -Col
    gd_colors/2        +Grid, -ColorSet (sorted unique)
    gd_color_count/3   +Grid, +Color, -Count
    gd_color_map/3     +Grid, +Map, -Grid2
    gd_objects/3       +Grid, +Color, -Objects
    gd_connected/3     +Grid, +Color, -Components
    gd_bounding_box/3  +Cells, -TopLeft, -BottomRight
    gd_rotate90/2      +Grid, -Grid2
    gd_rotate180/2     +Grid, -Grid2
    gd_rotate270/2     +Grid, -Grid2
    gd_reflect_h/2     +Grid, -Grid2
    gd_reflect_v/2     +Grid, -Grid2
    gd_reflect_d1/2    +Grid, -Grid2
    gd_reflect_d2/2    +Grid, -Grid2
    gd_translate/5     +Grid, +DR, +DC, +Background, -Grid2
    gd_crop/6          +Grid, +R0, +C0, +R1, +C1, -Grid2
    gd_overlay/5       +Base, +Patch, +DR, +DC, -Grid2
    gd_diff/3          +Grid1, +Grid2, -Diffs
    gd_equal/2         +Grid1, +Grid2
    gd_symmetry/2      +Grid, -Axes
    gd_fill/5          +Grid, +R, +C, +Color, -Grid2
    gd_make/4          +Rows, +Cols, +Color, -Grid
    gd_set_cell/5      +Grid, +R, +C, +Color, -Grid2
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(grid, [
    % gd_size/3: query grid dimensions.
    gd_size/3,
    % gd_cell/4: access one cell by zero-based (R,C).
    gd_cell/4,
    % gd_row/3: extract one row.
    gd_row/3,
    % gd_col/3: extract one column.
    gd_col/3,
    % gd_colors/2: sorted unique color set.
    gd_colors/2,
    % gd_color_count/3: count cells of a given color.
    gd_color_count/3,
    % gd_color_map/3: remap colors via a From-To pair list.
    gd_color_map/3,
    % gd_objects/3: connected objects of a given color.
    gd_objects/3,
    % gd_connected/3: all connected components for a color.
    gd_connected/3,
    % gd_bounding_box/3: axis-aligned bounding box of a cell set.
    gd_bounding_box/3,
    % gd_rotate90/2: rotate 90 degrees clockwise.
    gd_rotate90/2,
    % gd_rotate180/2: rotate 180 degrees.
    gd_rotate180/2,
    % gd_rotate270/2: rotate 270 degrees clockwise.
    gd_rotate270/2,
    % gd_reflect_h/2: flip across horizontal axis (upside-down).
    gd_reflect_h/2,
    % gd_reflect_v/2: flip across vertical axis (left-right).
    gd_reflect_v/2,
    % gd_reflect_d1/2: transpose (main diagonal flip).
    gd_reflect_d1/2,
    % gd_reflect_d2/2: anti-diagonal flip.
    gd_reflect_d2/2,
    % gd_translate/5: shift grid by (DR, DC) with background fill.
    gd_translate/5,
    % gd_crop/6: crop inclusive rectangular sub-grid.
    gd_crop/6,
    % gd_overlay/5: overlay a patch onto a base grid at offset.
    gd_overlay/5,
    % gd_diff/3: list of differing cells between two grids.
    gd_diff/3,
    % gd_equal/2: succeed when two grids are identical.
    gd_equal/2,
    % gd_symmetry/2: detect symmetry axes.
    gd_symmetry/2,
    % gd_fill/5: flood-fill a connected region with a new color.
    gd_fill/5,
    % gd_make/4: create a uniform grid.
    gd_make/4,
    % gd_set_cell/5: set one cell and return the modified grid.
    gd_set_cell/5
]).

% Import list predicates used throughout this module.
:- use_module(library(lists),  [member/2, nth0/3, nth0/4, append/3,
                                 flatten/2, numlist/3, list_to_set/2,
                                 min_list/2, max_list/2, reverse/2]).
% Import higher-order predicates: maplist and foldl.
:- use_module(library(apply),  [maplist/2, maplist/3, foldl/4]).

% ===========================================================================
% SECTION 1 — BASIC ACCESSORS
% ===========================================================================

% gd_size(+Grid, -Rows, -Cols): bind Rows and Cols to grid dimensions.
gd_size(Grid, Rows, Cols) :-
    % Rows is the length of the outer list.
    length(Grid, Rows),
    % Derive Cols from the first row; empty grid has 0 cols.
    ( Grid = [FirstRow|_] -> length(FirstRow, Cols) ; Cols = 0 ).

% gd_cell(+Grid, +R, +C, -Color): read the color at zero-based (R, C).
gd_cell(Grid, R, C, Color) :-
    % Fetch the Rth row.
    nth0(R, Grid, Row),
    % Fetch the Cth element of that row.
    nth0(C, Row, Color).

% gd_row(+Grid, +R, -Row): extract the Rth row (zero-based).
gd_row(Grid, R, Row) :-
    % Use nth0 to retrieve the row at index R.
    nth0(R, Grid, Row).

% gd_col(+Grid, +C, -Col): extract the Cth column as a list (zero-based).
gd_col(Grid, C, Col) :-
    % Pull the Cth element from every row.
    maplist(nth0(C), Grid, Col).

% ===========================================================================
% SECTION 2 — COLOR OPERATIONS
% ===========================================================================

% gd_colors(+Grid, -ColorSet): sorted set of distinct colors in Grid.
gd_colors(Grid, ColorSet) :-
    % Flatten all rows into one list.
    flatten(Grid, Flat),
    % Remove duplicates.
    list_to_set(Flat, Raw),
    % Sort the unique values.
    msort(Raw, ColorSet).

% gd_color_count(+Grid, +Color, -Count): count occurrences of Color in Grid.
gd_color_count(Grid, Color, Count) :-
    % Flatten the grid to one list.
    flatten(Grid, Flat),
    % Collect one witness per occurrence of Color.
    findall(_, member(Color, Flat), Bag),
    % Count the witnesses.
    length(Bag, Count).

% gd_color_map(+Grid, +Map, -Grid2): apply color substitution Map to Grid.
% Map is a list of From-To pairs, e.g. [1-3, 2-4].
gd_color_map(Grid, Map, Grid2) :-
    % Apply the substitution to each row.
    maplist(map_row(Map), Grid, Grid2).

% map_row(+Map, +Row, -Row2): apply color substitution to one row.
map_row(Map, Row, Row2) :-
    % Apply the substitution to each cell.
    maplist(map_cell(Map), Row, Row2).

% map_cell(+Map, +Color, -Color2): look up Color in Map; pass through if absent.
map_cell(Map, Color, Color2) :-
    % If the pair Color-C2 exists in Map, use C2; otherwise keep original.
    ( member(Color-Color2, Map) -> true ; Color2 = Color ).

% ===========================================================================
% SECTION 3 — OBJECT EXTRACTION AND CONNECTED COMPONENTS
% ===========================================================================

% gd_objects(+Grid, +Color, -Objects): list of connected cell-sets for Color.
gd_objects(Grid, Color, Objects) :-
    % Delegate to gd_connected/3.
    gd_connected(Grid, Color, Objects).

% gd_connected(+Grid, +Color, -Components): flood-fill connected components.
gd_connected(Grid, Color, Components) :-
    % Get grid dimensions.
    gd_size(Grid, Rows, Cols),
    % Compute upper bounds before the findall goal.
    MaxR is Rows - 1,
    MaxC is Cols - 1,
    % Collect all cells that have the target color.
    findall(r(R,C), (
        between(0, MaxR, R),
        between(0, MaxC, C),
        gd_cell(Grid, R, C, Color)
    ), AllCells),
    % Partition AllCells into 4-connected components.
    extract_components(AllCells, [], Components).

% extract_components(+Remaining, +Done, -Components): iterative BFS partitioning.
extract_components([], _, []).
extract_components([Seed|Rest], Done, Components) :-
    % Skip seeds already placed in a previous component.
    ( member(Seed, Done) ->
        extract_components(Rest, Done, Components)
    ;
        % BFS from Seed over the available (unclaimed) cells.
        flood_fill_bfs([Seed], [Seed|Rest], [], Comp),
        % Record this component.
        Components = [Comp|Comps],
        % Mark component cells as done.
        append(Done, Comp, Done2),
        % Remove component cells from the remaining list.
        subtract_cells(Rest, Comp, Rest2),
        % Continue with the remaining unclaimed cells.
        extract_components(Rest2, Done2, Comps)
    ).

% flood_fill_bfs(+Queue, +Available, +Visited, -Component): BFS over Available.
flood_fill_bfs([], _, Visited, Visited).
flood_fill_bfs([r(R,C)|Queue], Available, Visited, Component) :-
    % If this cell was already visited, skip it.
    ( member(r(R,C), Visited) ->
        flood_fill_bfs(Queue, Available, Visited, Component)
    ;
        % Collect 4-connected neighbors that are available and unvisited.
        findall(r(NR,NC), (
            ( NR is R-1, NC = C
            ; NR is R+1, NC = C
            ; NR = R,    NC is C-1
            ; NR = R,    NC is C+1
            ),
            member(r(NR,NC), Available),
            \+ member(r(NR,NC), Visited)
        ), Neighbors),
        % Append new neighbors to the BFS queue.
        append(Queue, Neighbors, Queue2),
        % Mark the current cell as visited and continue.
        flood_fill_bfs(Queue2, Available, [r(R,C)|Visited], Component)
    ).

% subtract_cells(+List, +ToRemove, -Result): list difference on r(R,C) terms.
subtract_cells([], _, []).
subtract_cells([H|T], Remove, Result) :-
    % Exclude H if it is in Remove.
    ( member(H, Remove) ->
        subtract_cells(T, Remove, Result)
    ;
        subtract_cells(T, Remove, Rest),
        Result = [H|Rest]
    ).

% gd_bounding_box(+Cells, -TopLeft, -BottomRight): axis-aligned bounding box.
% TopLeft = r(MinR, MinC); BottomRight = r(MaxR, MaxC).
gd_bounding_box(Cells, r(MinR,MinC), r(MaxR,MaxC)) :-
    % Collect all row indices from the cell set.
    findall(R, member(r(R,_), Cells), Rs),
    % Collect all column indices from the cell set.
    findall(C, member(r(_,C), Cells), Cs),
    % Compute extremes.
    min_list(Rs, MinR),
    max_list(Rs, MaxR),
    min_list(Cs, MinC),
    max_list(Cs, MaxC).

% ===========================================================================
% SECTION 4 — GRID TRANSFORMATIONS
% ===========================================================================

% gd_rotate90(+Grid, -Grid2): rotate 90 degrees clockwise.
% New cell (NR, NC) = old cell (NewCols-1-NC, NR).
gd_rotate90(Grid, Grid2) :-
    % Get original dimensions.
    gd_size(Grid, Rows, Cols),
    % After 90 CW the new grid has Cols rows and Rows columns.
    NewRows is Cols,
    NewCols is Rows,
    % Pre-compute upper bounds before numlist calls.
    NR1 is NewRows - 1,
    NC1 is NewCols - 1,
    % Build row-index and column-index lists.
    numlist(0, NR1, NRs),
    numlist(0, NC1, NCs),
    % Build each row of the rotated grid.
    maplist([NR, Row]>>(
        maplist([NC, Color]>>(
            OldR is NewCols - 1 - NC,
            OldC is NR,
            gd_cell(Grid, OldR, OldC, Color)
        ), NCs, Row)
    ), NRs, Grid2).

% gd_rotate180(+Grid, -Grid2): rotate 180 degrees.
gd_rotate180(Grid, Grid2) :-
    % Compose two 90-degree clockwise rotations.
    gd_rotate90(Grid, Mid),
    gd_rotate90(Mid, Grid2).

% gd_rotate270(+Grid, -Grid2): rotate 270 degrees clockwise (= 90 counter-CW).
gd_rotate270(Grid, Grid2) :-
    % Compose three 90-degree clockwise rotations.
    gd_rotate90(Grid, M1),
    gd_rotate90(M1, M2),
    gd_rotate90(M2, Grid2).

% gd_reflect_h(+Grid, -Grid2): flip upside-down (reverse row order).
gd_reflect_h(Grid, Grid2) :-
    % Reversing the list of rows achieves the horizontal-axis flip.
    reverse(Grid, Grid2).

% gd_reflect_v(+Grid, -Grid2): flip left-right (reverse each row).
gd_reflect_v(Grid, Grid2) :-
    % Reverse each row independently.
    maplist([Row, Rev]>>(reverse(Row, Rev)), Grid, Grid2).

% gd_reflect_d1(+Grid, -Grid2): transpose (main diagonal flip).
gd_reflect_d1(Grid, Grid2) :-
    % Get the number of columns (= number of rows in the transposed grid).
    gd_size(Grid, _Rows, Cols),
    % Pre-compute upper bound before numlist.
    Cols1 is Cols - 1,
    % Build column-index list.
    numlist(0, Cols1, ColIds),
    % Each column of Grid becomes a row of Grid2.
    maplist([C, Col]>>(gd_col(Grid, C, Col)), ColIds, Grid2).

% gd_reflect_d2(+Grid, -Grid2): anti-diagonal flip.
gd_reflect_d2(Grid, Grid2) :-
    % Rotate 90 CW then flip left-right achieves the anti-diagonal flip.
    gd_rotate90(Grid, Rot),
    gd_reflect_v(Rot, Grid2).

% gd_translate(+Grid, +DR, +DC, +Background, -Grid2): shift by (DR, DC).
% Cell (R, C) in Grid2 comes from (R-DR, C-DC) in Grid, or Background.
gd_translate(Grid, DR, DC, Background, Grid2) :-
    % Get dimensions.
    gd_size(Grid, Rows, Cols),
    % Pre-compute upper bounds before numlist.
    R1 is Rows - 1,
    C1 is Cols - 1,
    % Build row and column index lists.
    numlist(0, R1, RIds),
    numlist(0, C1, CIds),
    % Build the translated grid.
    maplist([R, Row]>>(
        maplist([C, Color]>>(
            OldR is R - DR,
            OldC is C - DC,
            ( OldR >= 0, OldR < Rows, OldC >= 0, OldC < Cols ->
                gd_cell(Grid, OldR, OldC, Color)
            ;
                Color = Background
            )
        ), CIds, Row)
    ), RIds, Grid2).

% gd_crop(+Grid, +R0, +C0, +R1, +C1, -Grid2): crop inclusive rectangle.
% R0..R1 and C0..C1 are zero-based inclusive bounds.
gd_crop(Grid, R0, C0, R1, C1, Grid2) :-
    % Build row and column index lists for the crop region.
    numlist(R0, R1, RIds),
    numlist(C0, C1, CIds),
    % Extract each cell in the crop rectangle.
    maplist([R, Row]>>(
        maplist([C, Color]>>(gd_cell(Grid, R, C, Color)), CIds, Row)
    ), RIds, Grid2).

% gd_overlay(+Base, +Patch, +DR, +DC, -Grid2): overlay Patch onto Base at offset.
% Non-zero Patch cells overwrite Base; zero Patch cells are transparent.
gd_overlay(Base, Patch, DR, DC, Grid2) :-
    % Get base and patch dimensions.
    gd_size(Base, BRows, BCols),
    gd_size(Patch, PRows, PCols),
    % Pre-compute upper bounds for the base grid.
    BR1 is BRows - 1,
    BC1 is BCols - 1,
    % Build index lists for the base grid.
    numlist(0, BR1, RIds),
    numlist(0, BC1, CIds),
    % Build the result grid.
    maplist([R, Row]>>(
        maplist([C, Color]>>(
            PR is R - DR,
            PC is C - DC,
            ( PR >= 0, PR < PRows, PC >= 0, PC < PCols,
              gd_cell(Patch, PR, PC, PColor),
              PColor \= 0 ->
                Color = PColor
            ;
                gd_cell(Base, R, C, Color)
            )
        ), CIds, Row)
    ), RIds, Grid2).

% ===========================================================================
% SECTION 5 — COMPARISON AND EQUALITY
% ===========================================================================

% gd_diff(+Grid1, +Grid2, -Diffs): list of r(R,C,Old,New) for differing cells.
gd_diff(Grid1, Grid2, Diffs) :-
    % Both grids must have the same dimensions.
    gd_size(Grid1, Rows, Cols),
    gd_size(Grid2, Rows, Cols),
    % Pre-compute upper bounds before the findall.
    MaxR is Rows - 1,
    MaxC is Cols - 1,
    % Collect cells where the colors differ.
    findall(r(R,C,Old,New), (
        between(0, MaxR, R),
        between(0, MaxC, C),
        gd_cell(Grid1, R, C, Old),
        gd_cell(Grid2, R, C, New),
        Old \= New
    ), Diffs).

% gd_equal(+Grid1, +Grid2): succeed when two grids are structurally identical.
gd_equal(G, G).

% ===========================================================================
% SECTION 6 — SYMMETRY DETECTION
% ===========================================================================

% gd_symmetry(+Grid, -Axes): which symmetry axes does Grid have?
% Axes is a subset of [h, v, d1, d2].
gd_symmetry(Grid, Axes) :-
    % For each candidate axis, test whether the reflected grid equals the original.
    findall(Axis, (
        member(Axis, [h, v, d1, d2]),
        apply_reflection(Grid, Axis, Grid2),
        gd_equal(Grid, Grid2)
    ), Axes).

% apply_reflection(+Grid, +Axis, -Grid2): dispatch to the matching reflection.
apply_reflection(Grid, h,  G2) :- gd_reflect_h(Grid, G2).
apply_reflection(Grid, v,  G2) :- gd_reflect_v(Grid, G2).
apply_reflection(Grid, d1, G2) :- gd_reflect_d1(Grid, G2).
apply_reflection(Grid, d2, G2) :- gd_reflect_d2(Grid, G2).

% ===========================================================================
% SECTION 7 — FLOOD FILL AND CELL MUTATION
% ===========================================================================

% gd_fill(+Grid, +R, +C, +Color, -Grid2): replace the connected region at (R,C)
% (4-connected, matching the color at that seed cell) with Color.
gd_fill(Grid, R, C, Color, Grid2) :-
    % Find the color currently at the seed cell.
    gd_cell(Grid, R, C, OldColor),
    % Find all 4-connected components of OldColor.
    gd_connected(Grid, OldColor, Components),
    % Select the component that contains the seed cell.
    member(Comp, Components),
    member(r(R,C), Comp),
    % Replace every cell in the component with the new color.
    foldl([Cell, G0, G1]>>(
        Cell = r(CR,CC),
        gd_set_cell(G0, CR, CC, Color, G1)
    ), Comp, Grid, Grid2).

% gd_make(+Rows, +Cols, +Color, -Grid): create a uniform grid filled with Color.
gd_make(Rows, Cols, Color, Grid) :-
    % Build one row of Cols copies of Color.
    length(Row, Cols),
    maplist(=(Color), Row),
    % Build a grid of Rows copies of that row.
    length(Grid, Rows),
    maplist(=(Row), Grid).

% gd_set_cell(+Grid, +R, +C, +Color, -Grid2): functionally update one cell.
gd_set_cell(Grid, R, C, Color, Grid2) :-
    % Decompose: OldRow is row R; RestRows are all other rows in order.
    nth0(R, Grid, OldRow, RestRows),
    % Decompose OldRow: drop the cell at C; RestCells are the others in order.
    nth0(C, OldRow, _, RestCells),
    % Reconstruct NewRow with Color inserted at position C.
    nth0(C, NewRow, Color, RestCells),
    % Reconstruct Grid2 with NewRow inserted at position R.
    nth0(R, Grid2, NewRow, RestRows).
