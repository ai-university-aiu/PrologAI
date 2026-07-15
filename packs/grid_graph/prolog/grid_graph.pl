:- module(grid_graph, [
    grid_graph_adj_colors/2,
    grid_graph_adj_of/3,
    grid_graph_adj_graph/2,
    grid_graph_are_adj/3,
    grid_graph_color_degree/3,
    grid_graph_shared_border/4,
    grid_graph_border_length/4,
    grid_graph_isolated_colors/2,
    grid_graph_enclosed_colors/3,
    grid_graph_spanning_h/2,
    grid_graph_spanning_v/2,
    grid_graph_merge_colors/4,
    grid_graph_color_components/3,
    grid_graph_component_cells/3
]).
% gridgraph.pl - Layer 214: Grid Region Adjacency Graph (ggr_* prefix).
% Computes adjacency structure between distinct color regions in a raw grid.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% A "region" is the set of all cells of a given color (may be disconnected).
:- use_module(library(lists), [
    nth0/3, member/2, append/3, list_to_set/2, subtract/3
]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
grid_graph_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed); fails if out of bounds.
grid_graph_cell_(Grid, R, C, V) :-
% Select row R.
    nth0(R, Grid, Row),
% Select column C.
    nth0(C, Row, V).

% Generate one 4-connected neighbor.
grid_graph_nbr4_(R, C, NR, NC) :-
% One of four cardinal directions.
    member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
    NR is R + DR,
    NC is C + DC.

% Collect all distinct colors in Grid.
grid_graph_colors_(Grid, Colors) :-
% Flatten all rows and extract unique colors.
    findall(V, (member(Row, Grid), member(V, Row)), All),
    list_to_set(All, Colors).

% BFS through same-color cells from a seed.
grid_graph_bfs_same_(_, [], _, Visited, Visited).
grid_graph_bfs_same_(Grid, [RC|Queue], Color, Visited, Result) :-
    (memberchk(RC, Visited) ->
        grid_graph_bfs_same_(Grid, Queue, Color, Visited, Result)
    ;
        RC = R-C,
        NewVisited = [RC|Visited],
        findall(NR-NC,
            (grid_graph_nbr4_(R, C, NR, NC),
             grid_graph_cell_(Grid, NR, NC, Color),
             \+ memberchk(NR-NC, NewVisited)),
            Nbrs),
        append(Queue, Nbrs, NewQueue),
        grid_graph_bfs_same_(Grid, NewQueue, Color, NewVisited, Result)).

% --- PUBLIC PREDICATES ---

% grid_graph_adj_colors(+Grid, -Pairs)
% Pairs is the sorted list of C1-C2 pairs (C1 @< C2) where Color C1 and
% Color C2 regions have at least one 4-connected boundary between them.
grid_graph_adj_colors(Grid, Pairs) :-
% Collect all border pairs.
    grid_graph_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(P,
        (between(0, H1, R), between(0, W1, C),
         grid_graph_cell_(Grid, R, C, V),
         once((grid_graph_nbr4_(R, C, NR, NC),
               grid_graph_cell_(Grid, NR, NC, NV),
               NV \= V,
               (V @< NV -> P = V-NV ; P = NV-V)))),
        RawPairs),
    list_to_set(RawPairs, Pairs).

% grid_graph_adj_of(+Grid, +Color, -Neighbors)
% Neighbors is the sorted list of distinct colors 4-adjacent to Color.
grid_graph_adj_of(Grid, Color, Neighbors) :-
% Find all cells of Color with a differently-colored neighbor.
    grid_graph_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NV,
        (between(0, H1, R), between(0, W1, C),
         grid_graph_cell_(Grid, R, C, Color),
         grid_graph_nbr4_(R, C, NR, NC),
         grid_graph_cell_(Grid, NR, NC, NV),
         NV \= Color),
        RawNbrs),
    list_to_set(RawNbrs, Neighbors).

% grid_graph_adj_graph(+Grid, -Graph)
% Graph is a list of (Color, Neighbors) pairs for every distinct color.
% Each entry: (Color, SortedDistinctNeighbors).
grid_graph_adj_graph(Grid, Graph) :-
% Get all colors.
    grid_graph_colors_(Grid, Colors),
% Build adjacency list for each color.
    findall(Color-Nbrs,
        (member(Color, Colors),
         grid_graph_adj_of(Grid, Color, Nbrs)),
        Graph).

% grid_graph_are_adj(+Grid, +C1, +C2)
% Succeeds if Color C1 and Color C2 share at least one 4-connected boundary.
grid_graph_are_adj(Grid, C1, C2) :-
    C1 \= C2,
% Find one C1 cell adjacent to a C2 cell.
    grid_graph_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    once((between(0, H1, R), between(0, W1, C),
          grid_graph_cell_(Grid, R, C, C1),
          grid_graph_nbr4_(R, C, NR, NC),
          grid_graph_cell_(Grid, NR, NC, C2))).

% grid_graph_color_degree(+Grid, +Color, -N)
% N is the number of distinct colors 4-adjacent to Color.
grid_graph_color_degree(Grid, Color, N) :-
% Count distinct neighbors.
    grid_graph_adj_of(Grid, Color, Neighbors),
    length(Neighbors, N).

% grid_graph_shared_border(+Grid, +C1, +C2, -Cells)
% Cells is the list of C1 positions that have at least one 4-adjacent C2 neighbor.
grid_graph_shared_border(Grid, C1, C2, Cells) :-
    C1 \= C2,
% Collect C1 cells touching C2.
    grid_graph_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         grid_graph_cell_(Grid, R, C, C1),
         once((grid_graph_nbr4_(R, C, NR, NC),
               grid_graph_cell_(Grid, NR, NC, C2)))),
        Cells).

% grid_graph_border_length(+Grid, +C1, +C2, -N)
% N is the count of C1 cells that have at least one 4-adjacent C2 neighbor.
grid_graph_border_length(Grid, C1, C2, N) :-
% Count shared border cells.
    grid_graph_shared_border(Grid, C1, C2, Cells),
    length(Cells, N).

% grid_graph_isolated_colors(+Grid, -Colors)
% Colors is the list of colors that have no differently-colored 4-adjacent neighbor.
% A color is isolated if every in-bounds 4-neighbor of every cell of that color
% has the same color (including grid boundary cells where there are no out-of-bounds neighbors).
grid_graph_isolated_colors(Grid, Colors) :-
% Get all colors.
    grid_graph_colors_(Grid, AllColors),
% Isolated colors have degree 0.
    findall(C,
        (member(C, AllColors),
         grid_graph_color_degree(Grid, C, 0)),
        Colors).

% grid_graph_enclosed_colors(+Grid, -InnerColors, +OuterColor)
% InnerColors is the list of colors C such that:
%   (1) No cell of C is on the grid border (row 0, last row, col 0, last col).
%   (2) Every non-C 4-neighbor of every C cell has color OuterColor.
% This defines C as "enclosed by OuterColor".
grid_graph_enclosed_colors(Grid, InnerColors, OuterColor) :-
% Get grid dimensions.
    grid_graph_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Get all colors except OuterColor.
    grid_graph_colors_(Grid, AllColors),
    subtract(AllColors, [OuterColor], InnerCandidates),
% Check each candidate.
    findall(C,
        (member(C, InnerCandidates),
% Condition 1: no cell of C on the border.
         \+ (between(0, H1, R), between(0, W1, C2),
             (R =:= 0 ; R =:= H1 ; C2 =:= 0 ; C2 =:= W1),
             grid_graph_cell_(Grid, R, C2, C)),
% Condition 2: every non-C neighbor of a C cell is OuterColor.
         \+ (between(0, H1, R), between(0, W1, C2),
             grid_graph_cell_(Grid, R, C2, C),
             grid_graph_nbr4_(R, C2, NR, NC),
             grid_graph_cell_(Grid, NR, NC, NV),
             NV \= C, NV \= OuterColor)),
        InnerColors).

% grid_graph_spanning_h(+Grid, -Colors)
% Colors is the list of colors that have at least one cell in column 0
% AND at least one cell in the last column.
grid_graph_spanning_h(Grid, Colors) :-
% Get dimensions.
    grid_graph_dims_(Grid, H, _W),
    H1 is H - 1,
    grid_graph_dims_(Grid, _, W),
    W1 is W - 1,
% Find colors on both left and right borders.
    findall(C,
        (member(Row, Grid), member(C, Row),
         once((between(0, H1, R), grid_graph_cell_(Grid, R, 0, C))),
         once((between(0, H1, R2), grid_graph_cell_(Grid, R2, W1, C)))),
        RawColors),
    list_to_set(RawColors, Colors).

% grid_graph_spanning_v(+Grid, -Colors)
% Colors is the list of colors that have at least one cell in row 0
% AND at least one cell in the last row.
grid_graph_spanning_v(Grid, Colors) :-
% Get dimensions.
    grid_graph_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Find colors in first and last row.
    findall(C,
        (member(Row, Grid), member(C, Row),
         once((between(0, W1, C2), grid_graph_cell_(Grid, 0, C2, C))),
         once((between(0, W1, C3), grid_graph_cell_(Grid, H1, C3, C)))),
        RawColors),
    list_to_set(RawColors, Colors).

% grid_graph_merge_colors(+Grid, +FromColor, +ToColor, -Result)
% Result is Grid with every occurrence of FromColor replaced by ToColor.
grid_graph_merge_colors(Grid, FromColor, ToColor, Result) :-
% Map over all rows and cells.
    maplist([Row, NewRow]>>(
        maplist([V, NV]>>(V = FromColor -> NV = ToColor ; NV = V), Row, NewRow)),
        Grid, Result).

% grid_graph_color_components(+Grid, +Color, -N)
% N is the number of distinct 4-connected components of Color in Grid.
grid_graph_color_components(Grid, Color, N) :-
% Find all Color cells.
    grid_graph_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         grid_graph_cell_(Grid, R, C, Color)),
        AllCells),
% Count components by BFS.
    grid_graph_count_components_(Grid, AllCells, Color, 0, N).

% Count connected components by iterating BFS over unvisited cells.
grid_graph_count_components_(_, [], _, N, N).
grid_graph_count_components_(Grid, [RC|Rest], Color, Acc, N) :-
% BFS from RC to find its whole component.
    grid_graph_bfs_same_(Grid, [RC], Color, [], Component),
% Remove component cells from remaining.
    subtract(Rest, Component, Remaining),
    Acc1 is Acc + 1,
    grid_graph_count_components_(Grid, Remaining, Color, Acc1, N).

% grid_graph_component_cells(+Grid, +Color, -Components)
% Components is a list of cell-lists; each inner list is one 4-connected
% component of Color. Components are ordered by first cell in row-major order.
grid_graph_component_cells(Grid, Color, Components) :-
% Find all Color cells in row-major order.
    grid_graph_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         grid_graph_cell_(Grid, R, C, Color)),
        AllCells),
% Partition into components.
    grid_graph_partition_components_(Grid, AllCells, Color, [], Components).

% Partition Color cells into connected components.
grid_graph_partition_components_(_, [], _, Acc, Rev) :-
% Reverse accumulator for row-major order.
    reverse(Acc, Rev).
grid_graph_partition_components_(Grid, [RC|Rest], Color, Acc, Components) :-
% BFS from RC to find its component.
    grid_graph_bfs_same_(Grid, [RC], Color, [], Component),
% Remove component from remaining cells.
    subtract(Rest, Component, Remaining),
    grid_graph_partition_components_(Grid, Remaining, Color, [Component|Acc], Components).
