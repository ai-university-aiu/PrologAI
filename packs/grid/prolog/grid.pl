/*  PrologAI — ARC-AGI Grid Perception and Manipulation  (Specification PR 56)

    A grid is a list of rows; each row is a list of integer color codes (0-9).
    Example: Grid = [[0,1,0],[1,0,1],[0,1,0]]

    All row and column indices are zero-based.

    Exported predicates:

    grid_size/3          +Grid, -Rows, -Cols
    grid_cell/4          +Grid, +R, +C, -Color
    grid_row/3           +Grid, +R, -Row
    grid_col/3           +Grid, +C, -Col
    grid_colors/2        +Grid, -ColorSet (sorted unique)
    grid_color_count/3   +Grid, +Color, -Count
    grid_color_map/3     +Grid, +Map, -Grid2
    grid_objects/3       +Grid, +Color, -Objects
    grid_connected/3     +Grid, +Color, -Components
    grid_bounding_box/3  +Cells, -TopLeft, -BottomRight
    grid_rotate90/2      +Grid, -Grid2
    grid_rotate180/2     +Grid, -Grid2
    grid_rotate270/2     +Grid, -Grid2
    grid_reflect_h/2     +Grid, -Grid2
    grid_reflect_v/2     +Grid, -Grid2
    grid_reflect_d1/2    +Grid, -Grid2
    grid_reflect_d2/2    +Grid, -Grid2
    grid_translate/5     +Grid, +DR, +DC, +Background, -Grid2
    grid_crop/6          +Grid, +R0, +C0, +R1, +C1, -Grid2
    grid_overlay/5       +Base, +Patch, +DR, +DC, -Grid2
    grid_diff/3          +Grid1, +Grid2, -Diffs
    grid_equal/2         +Grid1, +Grid2
    grid_symmetry/2      +Grid, -Axes
    grid_fill/5          +Grid, +R, +C, +Color, -Grid2
    grid_make/4          +Rows, +Cols, +Color, -Grid
    grid_set_cell/5      +Grid, +R, +C, +Color, -Grid2
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(grid, [
    % grid_size/3: query grid dimensions.
    grid_size/3,
    % grid_cell/4: access one cell by zero-based (R,C).
    grid_cell/4,
    % grid_row/3: extract one row.
    grid_row/3,
    % grid_col/3: extract one column.
    grid_col/3,
    % grid_colors/2: sorted unique color set.
    grid_colors/2,
    % grid_color_count/3: count cells of a given color.
    grid_color_count/3,
    % grid_color_map/3: remap colors via a From-To pair list.
    grid_color_map/3,
    % grid_objects/3: connected objects of a given color.
    grid_objects/3,
    % grid_connected/3: all connected components for a color.
    grid_connected/3,
    % grid_bounding_box/3: axis-aligned bounding box of a cell set.
    grid_bounding_box/3,
    % grid_rotate90/2: rotate 90 degrees clockwise.
    grid_rotate90/2,
    % grid_rotate180/2: rotate 180 degrees.
    grid_rotate180/2,
    % grid_rotate270/2: rotate 270 degrees clockwise.
    grid_rotate270/2,
    % grid_reflect_h/2: flip across horizontal axis (upside-down).
    grid_reflect_h/2,
    % grid_reflect_v/2: flip across vertical axis (left-right).
    grid_reflect_v/2,
    % grid_reflect_d1/2: transpose (main diagonal flip).
    grid_reflect_d1/2,
    % grid_reflect_d2/2: anti-diagonal flip.
    grid_reflect_d2/2,
    % grid_translate/5: shift grid by (DR, DC) with background fill.
    grid_translate/5,
    % grid_crop/6: crop inclusive rectangular sub-grid.
    grid_crop/6,
    % grid_overlay/5: overlay a patch onto a base grid at offset.
    grid_overlay/5,
    % grid_diff/3: list of differing cells between two grids.
    grid_diff/3,
    % grid_equal/2: succeed when two grids are identical.
    grid_equal/2,
    % grid_symmetry/2: detect symmetry axes.
    grid_symmetry/2,
    % grid_fill/5: flood-fill a connected region with a new color.
    grid_fill/5,
    % grid_make/4: create a uniform grid.
    grid_make/4,
    % grid_set_cell/5: set one cell and return the modified grid.
    grid_set_cell/5
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

% grid_size(+Grid, -Rows, -Cols): bind Rows and Cols to grid dimensions.
grid_size(Grid, Rows, Cols) :-
    % Rows is the length of the outer list.
    length(Grid, Rows),
    % Derive Cols from the first row; empty grid has 0 cols.
    ( Grid = [FirstRow|_] -> length(FirstRow, Cols) ; Cols = 0 ).

% grid_cell(+Grid, +R, +C, -Color): read the color at zero-based (R, C).
grid_cell(Grid, R, C, Color) :-
    % Fetch the Rth row.
    nth0(R, Grid, Row),
    % Fetch the Cth element of that row.
    nth0(C, Row, Color).

% grid_row(+Grid, +R, -Row): extract the Rth row (zero-based).
grid_row(Grid, R, Row) :-
    % Use nth0 to retrieve the row at index R.
    nth0(R, Grid, Row).

% grid_col(+Grid, +C, -Col): extract the Cth column as a list (zero-based).
grid_col(Grid, C, Col) :-
    % Pull the Cth element from every row.
    maplist(nth0(C), Grid, Col).

% ===========================================================================
% SECTION 2 — COLOR OPERATIONS
% ===========================================================================

% grid_colors(+Grid, -ColorSet): sorted set of distinct colors in Grid.
grid_colors(Grid, ColorSet) :-
    % Flatten all rows into one list.
    flatten(Grid, Flat),
    % Remove duplicates.
    list_to_set(Flat, Raw),
    % Sort the unique values.
    msort(Raw, ColorSet).

% grid_color_count(+Grid, +Color, -Count): count occurrences of Color in Grid.
grid_color_count(Grid, Color, Count) :-
    % Flatten the grid to one list.
    flatten(Grid, Flat),
    % Collect one witness per occurrence of Color.
    findall(_, member(Color, Flat), Bag),
    % Count the witnesses.
    length(Bag, Count).

% grid_color_map(+Grid, +Map, -Grid2): apply color substitution Map to Grid.
% Map is a list of From-To pairs, e.g. [1-3, 2-4].
grid_color_map(Grid, Map, Grid2) :-
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

% grid_objects(+Grid, +Color, -Objects): list of connected cell-sets for Color.
grid_objects(Grid, Color, Objects) :-
    % Delegate to grid_connected/3.
    grid_connected(Grid, Color, Objects).

% grid_connected(+Grid, +Color, -Components): flood-fill connected components.
grid_connected(Grid, Color, Components) :-
    % Get grid dimensions.
    grid_size(Grid, Rows, Cols),
    % Compute upper bounds before the findall goal.
    MaxR is Rows - 1,
    MaxC is Cols - 1,
    % Collect all cells that have the target color.
    findall(r(R,C), (
        between(0, MaxR, R),
        between(0, MaxC, C),
        grid_cell(Grid, R, C, Color)
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

% grid_bounding_box(+Cells, -TopLeft, -BottomRight): axis-aligned bounding box.
% TopLeft = r(MinR, MinC); BottomRight = r(MaxR, MaxC).
grid_bounding_box(Cells, r(MinR,MinC), r(MaxR,MaxC)) :-
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

% grid_rotate90(+Grid, -Grid2): rotate 90 degrees clockwise.
% New cell (NR, NC) = old cell (NewCols-1-NC, NR).
grid_rotate90(Grid, Grid2) :-
    % Get original dimensions.
    grid_size(Grid, Rows, Cols),
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
            grid_cell(Grid, OldR, OldC, Color)
        ), NCs, Row)
    ), NRs, Grid2).

% grid_rotate180(+Grid, -Grid2): rotate 180 degrees.
grid_rotate180(Grid, Grid2) :-
    % Compose two 90-degree clockwise rotations.
    grid_rotate90(Grid, Mid),
    grid_rotate90(Mid, Grid2).

% grid_rotate270(+Grid, -Grid2): rotate 270 degrees clockwise (= 90 counter-CW).
grid_rotate270(Grid, Grid2) :-
    % Compose three 90-degree clockwise rotations.
    grid_rotate90(Grid, M1),
    grid_rotate90(M1, M2),
    grid_rotate90(M2, Grid2).

% grid_reflect_h(+Grid, -Grid2): flip upside-down (reverse row order).
grid_reflect_h(Grid, Grid2) :-
    % Reversing the list of rows achieves the horizontal-axis flip.
    reverse(Grid, Grid2).

% grid_reflect_v(+Grid, -Grid2): flip left-right (reverse each row).
grid_reflect_v(Grid, Grid2) :-
    % Reverse each row independently.
    maplist([Row, Rev]>>(reverse(Row, Rev)), Grid, Grid2).

% grid_reflect_d1(+Grid, -Grid2): transpose (main diagonal flip).
grid_reflect_d1(Grid, Grid2) :-
    % Get the number of columns (= number of rows in the transposed grid).
    grid_size(Grid, _Rows, Cols),
    % Pre-compute upper bound before numlist.
    Cols1 is Cols - 1,
    % Build column-index list.
    numlist(0, Cols1, ColIds),
    % Each column of Grid becomes a row of Grid2.
    maplist([C, Col]>>(grid_col(Grid, C, Col)), ColIds, Grid2).

% grid_reflect_d2(+Grid, -Grid2): anti-diagonal flip.
grid_reflect_d2(Grid, Grid2) :-
    % Rotate 90 CW then flip left-right achieves the anti-diagonal flip.
    grid_rotate90(Grid, Rot),
    grid_reflect_v(Rot, Grid2).

% grid_translate(+Grid, +DR, +DC, +Background, -Grid2): shift by (DR, DC).
% Cell (R, C) in Grid2 comes from (R-DR, C-DC) in Grid, or Background.
grid_translate(Grid, DR, DC, Background, Grid2) :-
    % Get dimensions.
    grid_size(Grid, Rows, Cols),
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
                grid_cell(Grid, OldR, OldC, Color)
            ;
                Color = Background
            )
        ), CIds, Row)
    ), RIds, Grid2).

% grid_crop(+Grid, +R0, +C0, +R1, +C1, -Grid2): crop inclusive rectangle.
% R0..R1 and C0..C1 are zero-based inclusive bounds.
grid_crop(Grid, R0, C0, R1, C1, Grid2) :-
    % Build row and column index lists for the crop region.
    numlist(R0, R1, RIds),
    numlist(C0, C1, CIds),
    % Extract each cell in the crop rectangle.
    maplist([R, Row]>>(
        maplist([C, Color]>>(grid_cell(Grid, R, C, Color)), CIds, Row)
    ), RIds, Grid2).

% grid_overlay(+Base, +Patch, +DR, +DC, -Grid2): overlay Patch onto Base at offset.
% Non-zero Patch cells overwrite Base; zero Patch cells are transparent.
grid_overlay(Base, Patch, DR, DC, Grid2) :-
    % Get base and patch dimensions.
    grid_size(Base, BRows, BCols),
    grid_size(Patch, PRows, PCols),
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
              grid_cell(Patch, PR, PC, PColor),
              PColor \= 0 ->
                Color = PColor
            ;
                grid_cell(Base, R, C, Color)
            )
        ), CIds, Row)
    ), RIds, Grid2).

% ===========================================================================
% SECTION 5 — COMPARISON AND EQUALITY
% ===========================================================================

% grid_diff(+Grid1, +Grid2, -Diffs): list of r(R,C,Old,New) for differing cells.
grid_diff(Grid1, Grid2, Diffs) :-
    % Both grids must have the same dimensions.
    grid_size(Grid1, Rows, Cols),
    grid_size(Grid2, Rows, Cols),
    % Pre-compute upper bounds before the findall.
    MaxR is Rows - 1,
    MaxC is Cols - 1,
    % Collect cells where the colors differ.
    findall(r(R,C,Old,New), (
        between(0, MaxR, R),
        between(0, MaxC, C),
        grid_cell(Grid1, R, C, Old),
        grid_cell(Grid2, R, C, New),
        Old \= New
    ), Diffs).

% grid_equal(+Grid1, +Grid2): succeed when two grids are structurally identical.
grid_equal(G, G).

% ===========================================================================
% SECTION 6 — SYMMETRY DETECTION
% ===========================================================================

% grid_symmetry(+Grid, -Axes): which symmetry axes does Grid have?
% Axes is a subset of [h, v, d1, d2].
grid_symmetry(Grid, Axes) :-
    % For each candidate axis, test whether the reflected grid equals the original.
    findall(Axis, (
        member(Axis, [h, v, d1, d2]),
        apply_reflection(Grid, Axis, Grid2),
        grid_equal(Grid, Grid2)
    ), Axes).

% apply_reflection(+Grid, +Axis, -Grid2): dispatch to the matching reflection.
apply_reflection(Grid, h,  G2) :- grid_reflect_h(Grid, G2).
apply_reflection(Grid, v,  G2) :- grid_reflect_v(Grid, G2).
apply_reflection(Grid, d1, G2) :- grid_reflect_d1(Grid, G2).
apply_reflection(Grid, d2, G2) :- grid_reflect_d2(Grid, G2).

% ===========================================================================
% SECTION 7 — FLOOD FILL AND CELL MUTATION
% ===========================================================================

% grid_fill(+Grid, +R, +C, +Color, -Grid2): replace the connected region at (R,C)
% (4-connected, matching the color at that seed cell) with Color.
grid_fill(Grid, R, C, Color, Grid2) :-
    % Find the color currently at the seed cell.
    grid_cell(Grid, R, C, OldColor),
    % Find all 4-connected components of OldColor.
    grid_connected(Grid, OldColor, Components),
    % Select the component that contains the seed cell.
    member(Comp, Components),
    member(r(R,C), Comp),
    % Replace every cell in the component with the new color.
    foldl([Cell, G0, G1]>>(
        Cell = r(CR,CC),
        grid_set_cell(G0, CR, CC, Color, G1)
    ), Comp, Grid, Grid2).

% grid_make(+Rows, +Cols, +Color, -Grid): create a uniform grid filled with Color.
grid_make(Rows, Cols, Color, Grid) :-
    % Build one row of Cols copies of Color.
    length(Row, Cols),
    maplist(=(Color), Row),
    % Build a grid of Rows copies of that row.
    length(Grid, Rows),
    maplist(=(Row), Grid).

% grid_set_cell(+Grid, +R, +C, +Color, -Grid2): functionally update one cell.
grid_set_cell(Grid, R, C, Color, Grid2) :-
    % Decompose: OldRow is row R; RestRows are all other rows in order.
    nth0(R, Grid, OldRow, RestRows),
    % Decompose OldRow: drop the cell at C; RestCells are the others in order.
    nth0(C, OldRow, _, RestCells),
    % Reconstruct NewRow with Color inserted at position C.
    nth0(C, NewRow, Color, RestCells),
    % Reconstruct Grid2 with NewRow inserted at position R.
    nth0(R, Grid2, NewRow, RestRows).
