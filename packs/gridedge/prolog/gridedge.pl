:- module(gridedge, [
    ge_edge_cells/3,
    ge_edge_cells8/3,
    ge_is_edge/3,
    ge_boundary/4,
    ge_inner_border/3,
    ge_outer_border/3,
    ge_edge_grid/4,
    ge_edge_count/3,
    ge_neighbors_diff/4,
    ge_corners/3,
    ge_endpoints/3,
    ge_smooth_cells/3,
    ge_transition_map/2,
    ge_edge_color_count/4
]).
% gridedge.pl - Layer 211: Grid Edge and Boundary Detection - edge cells,
% boundary detection, contours, corners, endpoints, and transition maps (ge_* prefix).
% Operates on raw grid format: list of rows, each a list of color atoms, 0-indexed.
:- use_module(library(lists), [
    nth0/3, member/2
]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
ge_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed); fails if out of bounds.
ge_cell_(Grid, R, C, V) :-
% Select row R.
    nth0(R, Grid, Row),
% Select column C.
    nth0(C, Row, V).

% Build a new H x W grid using a lambda Goal(R, C, V).
ge_build_(H, W, Goal, Grid) :-
% Compute last row and column indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect rows.
    findall(Row,
        (between(0, H1, R),
         findall(V, (between(0, W1, C), call(Goal, R, C, V)), Row)),
        Grid).

% 4-connected neighbor offsets: up, down, left, right.
ge_nbr4_(R, C, NR, NC) :-
% Up.
    member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
    NR is R + DR,
    NC is C + DC.

% 8-connected neighbor offsets (all 8 directions).
ge_nbr8_(R, C, NR, NC) :-
% All 8 adjacent cells.
    member(DR-DC, [-1-(-1), -1-0, -1-1, 0-(-1), 0-1, 1-(-1), 1-0, 1-1]),
    NR is R + DR,
    NC is C + DC.

% --- EDGE DETECTION ---

% ge_edge_cells(+Grid, +FgColor, -Cells)
% Cells is the list of R-C positions of FgColor cells that have at least one
% 4-connected neighbor with a different color (boundary cells of FgColor region).
ge_edge_cells(Grid, FgColor, Cells) :-
% Get grid dimensions.
    ge_dims_(Grid, H, W),
% Compute last indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect cells that are FgColor and have at least one differently-colored neighbor.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         ge_cell_(Grid, R, C, FgColor),
         once((ge_nbr4_(R, C, NR, NC),
               ge_cell_(Grid, NR, NC, NV),
               NV \= FgColor))),
        Cells).

% ge_edge_cells8(+Grid, +FgColor, -Cells)
% Like ge_edge_cells but uses 8-connected neighbor check.
ge_edge_cells8(Grid, FgColor, Cells) :-
% Get grid dimensions.
    ge_dims_(Grid, H, W),
% Compute last indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect cells that are FgColor and have at least one 8-neighbor of different color.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         ge_cell_(Grid, R, C, FgColor),
         once((ge_nbr8_(R, C, NR, NC),
               ge_cell_(Grid, NR, NC, NV),
               NV \= FgColor))),
        Cells).

% ge_is_edge(+Grid, +R-C, -Bool)
% Bool is 'yes' if cell (R,C) is an edge cell (has a 4-connected neighbor of
% different color or is at the grid boundary with a different-color interior);
% 'no' otherwise.
ge_is_edge(Grid, R-C, Bool) :-
% Get the cell value.
    ge_cell_(Grid, R, C, V),
% Check if any 4-connected neighbor differs in color.
    (( ge_nbr4_(R, C, NR, NC),
       ge_cell_(Grid, NR, NC, NV),
       NV \= V ) ->
        Bool = yes
    ;
        Bool = no).

% ge_boundary(+Grid, +Color1, +Color2, -Cells)
% Cells is the list of Color1 R-C positions that have at least one 4-connected
% Color2 neighbor. This gives the boundary of Color1 touching Color2.
ge_boundary(Grid, Color1, Color2, Cells) :-
% Get grid dimensions.
    ge_dims_(Grid, H, W),
% Compute last indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect Color1 cells adjacent to at least one Color2 cell.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         ge_cell_(Grid, R, C, Color1),
         once((ge_nbr4_(R, C, NR, NC),
               ge_cell_(Grid, NR, NC, Color2)))),
        Cells).

% ge_inner_border(+Grid, +BgColor, -Cells)
% Cells is the list of BgColor cells in the interior of the grid that are
% adjacent (4-connected) to at least one non-BgColor cell. These are the
% BgColor cells on the inner edge of the background.
ge_inner_border(Grid, BgColor, Cells) :-
% BgColor cells adjacent to non-background is the boundary of the background region.
    ge_boundary_to_nonbg_(Grid, BgColor, Cells).

% Private: BgColor cells adjacent to any non-BgColor cell.
ge_boundary_to_nonbg_(Grid, BgColor, Cells) :-
    ge_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         ge_cell_(Grid, R, C, BgColor),
         once((ge_nbr4_(R, C, NR, NC),
               ge_cell_(Grid, NR, NC, NV),
               NV \= BgColor))),
        Cells).

% ge_outer_border(+Grid, +FgColor, -Cells)
% Cells is the list of non-FgColor positions that are 4-adjacent to at least
% one FgColor cell. These are the cells immediately outside the FgColor region.
ge_outer_border(Grid, FgColor, Cells) :-
% Get grid dimensions.
    ge_dims_(Grid, H, W),
% Compute last indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect non-FgColor cells adjacent to at least one FgColor cell.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         ge_cell_(Grid, R, C, V), V \= FgColor,
         once((ge_nbr4_(R, C, NR, NC),
               ge_cell_(Grid, NR, NC, FgColor)))),
        Cells).

% --- EDGE GRIDS ---

% ge_edge_grid(+Grid, +FgColor, +EdgeColor, -Result)
% Result is a binary grid: FgColor edge cells become EdgeColor; all other cells
% retain their original color.
ge_edge_grid(Grid, FgColor, EdgeColor, Result) :-
% Get edge cells.
    ge_edge_cells(Grid, FgColor, Edges),
% Get dimensions.
    ge_dims_(Grid, H, W),
% Build result: edge cells get EdgeColor; others keep original value.
    ge_build_(H, W,
        [R, C, V]>>(ge_cell_(Grid, R, C, GV),
                    (memberchk(R-C, Edges) -> V = EdgeColor ; V = GV)),
        Result).

% ge_edge_count(+Grid, +FgColor, -N)
% N is the number of FgColor edge cells (4-connected boundary cells).
ge_edge_count(Grid, FgColor, N) :-
% Get edge cells and count them.
    ge_edge_cells(Grid, FgColor, Cells),
    length(Cells, N).

% --- NEIGHBOR ANALYSIS ---

% ge_neighbors_diff(+Grid, +R, +C, -Neighbors)
% Neighbors is the list of R-C positions among the 4-connected neighbors of (R,C)
% that have a different color from cell (R,C).
ge_neighbors_diff(Grid, R, C, Neighbors) :-
% Get the reference cell color.
    ge_cell_(Grid, R, C, V),
% Collect 4-neighbors with different color.
    findall(NR-NC,
        (ge_nbr4_(R, C, NR, NC),
         ge_cell_(Grid, NR, NC, NV),
         NV \= V),
        Neighbors).

% ge_corners(+Grid, +FgColor, -Cells)
% Cells is the list of FgColor positions with exactly 2 or more 4-connected
% neighbors of a different color. These are the cells at corners of regions.
ge_corners(Grid, FgColor, Cells) :-
% Get grid dimensions.
    ge_dims_(Grid, H, W),
% Compute last indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect FgColor cells with 2+ differently-colored 4-neighbors.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         ge_cell_(Grid, R, C, FgColor),
         findall(1,
             (ge_nbr4_(R, C, NR, NC),
              ge_cell_(Grid, NR, NC, NV),
              NV \= FgColor),
             Diff),
         length(Diff, D), D >= 2),
        Cells).

% ge_endpoints(+Grid, +FgColor, -Cells)
% Cells is the list of FgColor positions with exactly 1 FgColor 4-neighbor.
% These are the endpoints of FgColor line segments.
ge_endpoints(Grid, FgColor, Cells) :-
% Get grid dimensions.
    ge_dims_(Grid, H, W),
% Compute last indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect FgColor cells with exactly 1 same-color 4-neighbor.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         ge_cell_(Grid, R, C, FgColor),
         findall(1,
             (ge_nbr4_(R, C, NR, NC),
              ge_cell_(Grid, NR, NC, FgColor)),
             Same),
         length(Same, 1)),
        Cells).

% ge_smooth_cells(+Grid, +FgColor, -Cells)
% Cells is the list of FgColor positions whose 4-connected in-bounds neighbors
% are all also FgColor (the interior smooth cells; no boundary contact).
ge_smooth_cells(Grid, FgColor, Cells) :-
% Get grid dimensions.
    ge_dims_(Grid, H, W),
% Compute last indices.
    H1 is H - 1,
% Compute last column index.
    W1 is W - 1,
% Collect FgColor cells with zero differently-colored in-bounds 4-neighbors.
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         ge_cell_(Grid, R, C, FgColor),
         \+ (ge_nbr4_(R, C, NR, NC),
             ge_cell_(Grid, NR, NC, NV),
             NV \= FgColor)),
        Cells).

% ge_transition_map(+Grid, -Result)
% Result is a grid where each cell value is the count (0..4) of 4-connected
% in-bounds neighbors that have a different color from the cell itself.
% Interior uniform cells have value 0; boundary cells have 1, 2, 3, or 4.
ge_transition_map(Grid, Result) :-
% Get dimensions.
    ge_dims_(Grid, H, W),
% Build result where each cell value is the neighbor-diff count.
    ge_build_(H, W,
        [R, C, V]>>(ge_cell_(Grid, R, C, GV),
                    findall(1,
                        (ge_nbr4_(R, C, NR, NC),
                         ge_cell_(Grid, NR, NC, NV),
                         NV \= GV),
                        Diffs),
                    length(Diffs, V)),
        Result).

% ge_edge_color_count(+Grid, +FgColor, +BgColor, -N)
% N is the number of FgColor edge cells that are adjacent to at least one
% BgColor cell (edges specifically facing BgColor).
ge_edge_color_count(Grid, FgColor, BgColor, N) :-
% Get the boundary of FgColor touching BgColor.
    ge_boundary(Grid, FgColor, BgColor, Cells),
% Count those cells.
    length(Cells, N).
