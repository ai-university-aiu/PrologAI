:- module(gridgraph, [
    ggr_adj_colors/2,
    ggr_adj_of/3,
    ggr_adj_graph/2,
    ggr_are_adj/3,
    ggr_color_degree/3,
    ggr_shared_border/4,
    ggr_border_length/4,
    ggr_isolated_colors/2,
    ggr_enclosed_colors/3,
    ggr_spanning_h/2,
    ggr_spanning_v/2,
    ggr_merge_colors/4,
    ggr_color_components/3,
    ggr_component_cells/3
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
ggr_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed); fails if out of bounds.
ggr_cell_(Grid, R, C, V) :-
% Select row R.
    nth0(R, Grid, Row),
% Select column C.
    nth0(C, Row, V).

% Generate one 4-connected neighbor.
ggr_nbr4_(R, C, NR, NC) :-
% One of four cardinal directions.
    member(DR-DC, [-1-0, 1-0, 0-(-1), 0-1]),
    NR is R + DR,
    NC is C + DC.

% Collect all distinct colors in Grid.
ggr_colors_(Grid, Colors) :-
% Flatten all rows and extract unique colors.
    findall(V, (member(Row, Grid), member(V, Row)), All),
    list_to_set(All, Colors).

% BFS through same-color cells from a seed.
ggr_bfs_same_(_, [], _, Visited, Visited).
ggr_bfs_same_(Grid, [RC|Queue], Color, Visited, Result) :-
    (memberchk(RC, Visited) ->
        ggr_bfs_same_(Grid, Queue, Color, Visited, Result)
    ;
        RC = R-C,
        NewVisited = [RC|Visited],
        findall(NR-NC,
            (ggr_nbr4_(R, C, NR, NC),
             ggr_cell_(Grid, NR, NC, Color),
             \+ memberchk(NR-NC, NewVisited)),
            Nbrs),
        append(Queue, Nbrs, NewQueue),
        ggr_bfs_same_(Grid, NewQueue, Color, NewVisited, Result)).

% --- PUBLIC PREDICATES ---

% ggr_adj_colors(+Grid, -Pairs)
% Pairs is the sorted list of C1-C2 pairs (C1 @< C2) where Color C1 and
% Color C2 regions have at least one 4-connected boundary between them.
ggr_adj_colors(Grid, Pairs) :-
% Collect all border pairs.
    ggr_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(P,
        (between(0, H1, R), between(0, W1, C),
         ggr_cell_(Grid, R, C, V),
         once((ggr_nbr4_(R, C, NR, NC),
               ggr_cell_(Grid, NR, NC, NV),
               NV \= V,
               (V @< NV -> P = V-NV ; P = NV-V)))),
        RawPairs),
    list_to_set(RawPairs, Pairs).

% ggr_adj_of(+Grid, +Color, -Neighbors)
% Neighbors is the sorted list of distinct colors 4-adjacent to Color.
ggr_adj_of(Grid, Color, Neighbors) :-
% Find all cells of Color with a differently-colored neighbor.
    ggr_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(NV,
        (between(0, H1, R), between(0, W1, C),
         ggr_cell_(Grid, R, C, Color),
         ggr_nbr4_(R, C, NR, NC),
         ggr_cell_(Grid, NR, NC, NV),
         NV \= Color),
        RawNbrs),
    list_to_set(RawNbrs, Neighbors).

% ggr_adj_graph(+Grid, -Graph)
% Graph is a list of (Color, Neighbors) pairs for every distinct color.
% Each entry: (Color, SortedDistinctNeighbors).
ggr_adj_graph(Grid, Graph) :-
% Get all colors.
    ggr_colors_(Grid, Colors),
% Build adjacency list for each color.
    findall(Color-Nbrs,
        (member(Color, Colors),
         ggr_adj_of(Grid, Color, Nbrs)),
        Graph).

% ggr_are_adj(+Grid, +C1, +C2)
% Succeeds if Color C1 and Color C2 share at least one 4-connected boundary.
ggr_are_adj(Grid, C1, C2) :-
    C1 \= C2,
% Find one C1 cell adjacent to a C2 cell.
    ggr_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    once((between(0, H1, R), between(0, W1, C),
          ggr_cell_(Grid, R, C, C1),
          ggr_nbr4_(R, C, NR, NC),
          ggr_cell_(Grid, NR, NC, C2))).

% ggr_color_degree(+Grid, +Color, -N)
% N is the number of distinct colors 4-adjacent to Color.
ggr_color_degree(Grid, Color, N) :-
% Count distinct neighbors.
    ggr_adj_of(Grid, Color, Neighbors),
    length(Neighbors, N).

% ggr_shared_border(+Grid, +C1, +C2, -Cells)
% Cells is the list of C1 positions that have at least one 4-adjacent C2 neighbor.
ggr_shared_border(Grid, C1, C2, Cells) :-
    C1 \= C2,
% Collect C1 cells touching C2.
    ggr_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         ggr_cell_(Grid, R, C, C1),
         once((ggr_nbr4_(R, C, NR, NC),
               ggr_cell_(Grid, NR, NC, C2)))),
        Cells).

% ggr_border_length(+Grid, +C1, +C2, -N)
% N is the count of C1 cells that have at least one 4-adjacent C2 neighbor.
ggr_border_length(Grid, C1, C2, N) :-
% Count shared border cells.
    ggr_shared_border(Grid, C1, C2, Cells),
    length(Cells, N).

% ggr_isolated_colors(+Grid, -Colors)
% Colors is the list of colors that have no differently-colored 4-adjacent neighbor.
% A color is isolated if every in-bounds 4-neighbor of every cell of that color
% has the same color (including grid boundary cells where there are no out-of-bounds neighbors).
ggr_isolated_colors(Grid, Colors) :-
% Get all colors.
    ggr_colors_(Grid, AllColors),
% Isolated colors have degree 0.
    findall(C,
        (member(C, AllColors),
         ggr_color_degree(Grid, C, 0)),
        Colors).

% ggr_enclosed_colors(+Grid, -InnerColors, +OuterColor)
% InnerColors is the list of colors C such that:
%   (1) No cell of C is on the grid border (row 0, last row, col 0, last col).
%   (2) Every non-C 4-neighbor of every C cell has color OuterColor.
% This defines C as "enclosed by OuterColor".
ggr_enclosed_colors(Grid, InnerColors, OuterColor) :-
% Get grid dimensions.
    ggr_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Get all colors except OuterColor.
    ggr_colors_(Grid, AllColors),
    subtract(AllColors, [OuterColor], InnerCandidates),
% Check each candidate.
    findall(C,
        (member(C, InnerCandidates),
% Condition 1: no cell of C on the border.
         \+ (between(0, H1, R), between(0, W1, C2),
             (R =:= 0 ; R =:= H1 ; C2 =:= 0 ; C2 =:= W1),
             ggr_cell_(Grid, R, C2, C)),
% Condition 2: every non-C neighbor of a C cell is OuterColor.
         \+ (between(0, H1, R), between(0, W1, C2),
             ggr_cell_(Grid, R, C2, C),
             ggr_nbr4_(R, C2, NR, NC),
             ggr_cell_(Grid, NR, NC, NV),
             NV \= C, NV \= OuterColor)),
        InnerColors).

% ggr_spanning_h(+Grid, -Colors)
% Colors is the list of colors that have at least one cell in column 0
% AND at least one cell in the last column.
ggr_spanning_h(Grid, Colors) :-
% Get dimensions.
    ggr_dims_(Grid, H, _W),
    H1 is H - 1,
    ggr_dims_(Grid, _, W),
    W1 is W - 1,
% Find colors on both left and right borders.
    findall(C,
        (member(Row, Grid), member(C, Row),
         once((between(0, H1, R), ggr_cell_(Grid, R, 0, C))),
         once((between(0, H1, R2), ggr_cell_(Grid, R2, W1, C)))),
        RawColors),
    list_to_set(RawColors, Colors).

% ggr_spanning_v(+Grid, -Colors)
% Colors is the list of colors that have at least one cell in row 0
% AND at least one cell in the last row.
ggr_spanning_v(Grid, Colors) :-
% Get dimensions.
    ggr_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Find colors in first and last row.
    findall(C,
        (member(Row, Grid), member(C, Row),
         once((between(0, W1, C2), ggr_cell_(Grid, 0, C2, C))),
         once((between(0, W1, C3), ggr_cell_(Grid, H1, C3, C)))),
        RawColors),
    list_to_set(RawColors, Colors).

% ggr_merge_colors(+Grid, +FromColor, +ToColor, -Result)
% Result is Grid with every occurrence of FromColor replaced by ToColor.
ggr_merge_colors(Grid, FromColor, ToColor, Result) :-
% Map over all rows and cells.
    maplist([Row, NewRow]>>(
        maplist([V, NV]>>(V = FromColor -> NV = ToColor ; NV = V), Row, NewRow)),
        Grid, Result).

% ggr_color_components(+Grid, +Color, -N)
% N is the number of distinct 4-connected components of Color in Grid.
ggr_color_components(Grid, Color, N) :-
% Find all Color cells.
    ggr_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         ggr_cell_(Grid, R, C, Color)),
        AllCells),
% Count components by BFS.
    ggr_count_components_(Grid, AllCells, Color, 0, N).

% Count connected components by iterating BFS over unvisited cells.
ggr_count_components_(_, [], _, N, N).
ggr_count_components_(Grid, [RC|Rest], Color, Acc, N) :-
% BFS from RC to find its whole component.
    ggr_bfs_same_(Grid, [RC], Color, [], Component),
% Remove component cells from remaining.
    subtract(Rest, Component, Remaining),
    Acc1 is Acc + 1,
    ggr_count_components_(Grid, Remaining, Color, Acc1, N).

% ggr_component_cells(+Grid, +Color, -Components)
% Components is a list of cell-lists; each inner list is one 4-connected
% component of Color. Components are ordered by first cell in row-major order.
ggr_component_cells(Grid, Color, Components) :-
% Find all Color cells in row-major order.
    ggr_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R), between(0, W1, C),
         ggr_cell_(Grid, R, C, Color)),
        AllCells),
% Partition into components.
    ggr_partition_components_(Grid, AllCells, Color, [], Components).

% Partition Color cells into connected components.
ggr_partition_components_(_, [], _, Acc, Rev) :-
% Reverse accumulator for row-major order.
    reverse(Acc, Rev).
ggr_partition_components_(Grid, [RC|Rest], Color, Acc, Components) :-
% BFS from RC to find its component.
    ggr_bfs_same_(Grid, [RC], Color, [], Component),
% Remove component from remaining cells.
    subtract(Rest, Component, Remaining),
    ggr_partition_components_(Grid, Remaining, Color, [Component|Acc], Components).
