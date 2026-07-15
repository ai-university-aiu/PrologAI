:- module(grid_distance, [
    grid_distance_manhattan/5,
    grid_distance_chebyshev/5,
    grid_distance_dist_map/3,
    grid_distance_dist_map8/3,
    grid_distance_nearest_coord/5,
    grid_distance_zone/4,
    grid_distance_ring/5,
    grid_distance_voronoi/2,
    grid_distance_bfs_flood/5,
    grid_distance_recolor_by_dist/4,
    grid_distance_expand_n/4,
    grid_distance_shrink_n/4,
    grid_distance_equidistant/4,
    grid_distance_max_dist/4
]).
% griddist.pl - Layer 200: Grid Distance Transform (gd_* prefix).
% All predicates operate on raw grid format: list of rows, each a list of
% color atoms, 0-indexed (row 0 = top, col 0 = left).
% Distances are Manhattan (4-connected) unless the predicate name ends in 8
% (Chebyshev, 8-connected). Unreachable or absent-color cells get distance 9999.
:- use_module(library(lists), [
    member/2, memberchk/2, nth0/3, nth1/3,
    append/3, list_to_set/2, min_list/2, max_list/2
]).

% --- PRIVATE HELPERS ---

% Get H (rows) and W (columns) of a raw grid.
grid_distance_dims_(Grid, H, W) :-
% Bind H to the number of rows.
    length(Grid, H),
% Bind W to the column count of the first row; W=0 for empty grids.
    (H > 0 -> Grid = [Row|_], length(Row, W) ; W = 0).

% Read the cell value at (R,C) from Grid.
grid_distance_cell_(Grid, R, C, V) :-
% Access the row then the cell within it.
    nth0(R, Grid, Row),
    nth0(C, Row, V).

% Count occurrences of Value in a list.
grid_distance_count_val_([], _, 0).
grid_distance_count_val_([H|T], V, N) :-
% Recurse then add 1 if the head matches.
    grid_distance_count_val_(T, V, N0),
    (H = V -> N is N0 + 1 ; N = N0).

% Identify the background (most frequent color) in Grid.
grid_distance_background_(Grid, Bg) :-
% Collect all cell values.
    grid_distance_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
    findall(V,
        (between(0, H1, R), between(0, W1, C), grid_distance_cell_(Grid, R, C, V)),
        Vals),
% Build (NegCount)-Color pairs for sorting.
    list_to_set(Vals, Colors),
    findall(NegN-BgC,
        (member(BgC, Colors),
         grid_distance_count_val_(Vals, BgC, N),
         NegN is -N),
        Keyed),
% Most frequent color is the head after ascending sort on negative counts.
    msort(Keyed, [_-Bg|_]).

% Minimum Manhattan distance from (R,C) to any cell in Seeds (list of SR-SC pairs).
grid_distance_min_manhattan_(R, C, Seeds, MinD) :-
% Compute all pairwise Manhattan distances.
    findall(D, (member(SR-SC, Seeds), D is abs(R - SR) + abs(C - SC)), Dists),
% Return 9999 if no seeds; otherwise the minimum.
    (Dists = [] -> MinD = 9999 ; min_list(Dists, MinD)).

% Minimum Chebyshev distance from (R,C) to any cell in Seeds.
grid_distance_min_chebyshev_(R, C, Seeds, MinD) :-
% Compute max(|DR|,|DC|) for each seed.
    findall(D,
        (member(SR-SC, Seeds),
         DR is abs(R - SR),
         DC is abs(C - SC),
         D is max(DR, DC)),
        Dists),
    (Dists = [] -> MinD = 9999 ; min_list(Dists, MinD)).

% Four cardinal direction deltas for 4-connected BFS.
grid_distance_d4_([-1, 0]).
grid_distance_d4_([ 1, 0]).
grid_distance_d4_([ 0,-1]).
grid_distance_d4_([ 0, 1]).

% BFS step: expand the frontier one level, recording new cell distances.
% Queue: list of R-C-D items (cells to process at distance D from source).
% Visited: list of R-C pairs already seen (prevents re-processing).
% Acc: accumulated list of R-C-D results.
grid_distance_bfs_loop_(_, _, _, _, [], _, Acc, Acc) :- !.
grid_distance_bfs_loop_(Grid, H, W, Wall, [R-C-D|Queue], Visited, Acc, Result) :-
% Next-level distance.
    D1 is D + 1,
% Find in-bounds, unvisited, non-wall 4-connected neighbors.
    findall(NR-NC,
        (grid_distance_d4_([DR, DC]),
         NR is R + DR,
         NC is C + DC,
         NR >= 0, NR < H,
         NC >= 0, NC < W,
         \+ memberchk(NR-NC, Visited),
         grid_distance_cell_(Grid, NR, NC, NV),
         NV \= Wall),
        NewCoords0),
% Remove duplicates (e.g., when two queue items share a neighbor).
    list_to_set(NewCoords0, NewCoords),
% Build R-C-D1 items for the new frontier.
    findall(NR-NC-D1, member(NR-NC, NewCoords), NewItems),
% Extend visited, queue, and accumulated results.
    append(Visited, NewCoords, NewVisited),
    append(Queue, NewItems, NextQueue),
    append(Acc, NewItems, NewAcc),
    grid_distance_bfs_loop_(Grid, H, W, Wall, NextQueue, NewVisited, NewAcc, Result).

% Find the nearest foreground color to (R,C) from a list of FR-FC-V triples.
grid_distance_nearest_fg_color_(R, C, FgCells, Color) :-
% Compute Manhattan distance to each foreground cell.
    findall(D-V,
        (member(FR-FC-V, FgCells),
         D is abs(R - FR) + abs(C - FC)),
        DistColors),
% Pick the smallest distance; ties broken by standard term order (alphabetical).
    msort(DistColors, [_-Color|_]).

% --- EXPORTED PREDICATES ---

% grid_distance_manhattan(+R1, +C1, +R2, +C2, -D)
% D is the Manhattan (L1) distance between grid positions (R1,C1) and (R2,C2).
grid_distance_manhattan(R1, C1, R2, C2, D) :-
% Sum of absolute row and column differences.
    D is abs(R1 - R2) + abs(C1 - C2).

% grid_distance_chebyshev(+R1, +C1, +R2, +C2, -D)
% D is the Chebyshev (L-infinity) distance between (R1,C1) and (R2,C2).
% Chebyshev distance = max of absolute row and column differences.
grid_distance_chebyshev(R1, C1, R2, C2, D) :-
% Maximum of absolute row and column differences.
    DR is abs(R1 - R2),
    DC is abs(C1 - C2),
    D is max(DR, DC).

% grid_distance_dist_map(+Grid, +Color, -DistGrid)
% DistGrid is a raw grid where each cell holds the minimum Manhattan distance
% from that cell to the nearest cell whose value equals Color.
% Cells in a grid with no Color instances all receive 9999.
grid_distance_dist_map(Grid, Color, DistGrid) :-
% Collect all positions that hold Color as BFS seeds.
    grid_distance_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
    findall(SR-SC,
        (between(0, H1, SR), between(0, W1, SC), grid_distance_cell_(Grid, SR, SC, Color)),
        Seeds),
% Build the distance grid cell by cell.
    findall(Row,
        (between(0, H1, R),
         findall(D,
             (between(0, W1, C), grid_distance_min_manhattan_(R, C, Seeds, D)),
             Row)),
        DistGrid).

% grid_distance_dist_map8(+Grid, +Color, -DistGrid)
% DistGrid is a raw grid where each cell holds the minimum Chebyshev distance
% from that cell to the nearest Color cell. Absent Color gives 9999.
grid_distance_dist_map8(Grid, Color, DistGrid) :-
% Collect Color-cell positions.
    grid_distance_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
    findall(SR-SC,
        (between(0, H1, SR), between(0, W1, SC), grid_distance_cell_(Grid, SR, SC, Color)),
        Seeds),
% Build the Chebyshev distance grid.
    findall(Row,
        (between(0, H1, R),
         findall(D,
             (between(0, W1, C), grid_distance_min_chebyshev_(R, C, Seeds, D)),
             Row)),
        DistGrid).

% grid_distance_nearest_coord(+Grid, +R, +C, +Color, -Coord)
% Coord is [R2,C2] where (R2,C2) is the nearest cell to (R,C) that holds Color.
% Fails if no Color cell exists in Grid. Ties broken by standard term order.
grid_distance_nearest_coord(Grid, R, C, Color, [R2, C2]) :-
% Collect all Color cells with their distance from (R,C).
    grid_distance_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
    findall(D-NR-NC,
        (between(0, H1, NR), between(0, W1, NC),
         grid_distance_cell_(Grid, NR, NC, Color),
         D is abs(R - NR) + abs(C - NC)),
        DistCoords),
% Fail if no Color cells; otherwise pick the smallest distance.
    DistCoords \= [],
    msort(DistCoords, [_-R2-C2|_]).

% grid_distance_zone(+Grid, +Color, +N, -ZoneGrid)
% ZoneGrid is Grid with every non-Color cell within Manhattan distance N of
% any Color cell replaced by the atom zone. Color cells keep their value.
% Cells farther than N from any Color cell keep their original value.
grid_distance_zone(Grid, Color, N, ZoneGrid) :-
% Compute distance map from Color cells.
    grid_distance_dist_map(Grid, Color, DMap),
    grid_distance_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
    findall(Row,
        (between(0, H1, R),
         findall(NV,
             (between(0, W1, C),
              grid_distance_cell_(Grid, R, C, V),
              grid_distance_cell_(DMap, R, C, D),
% Color cells stay; non-Color cells within N become zone; others unchanged.
              (V = Color -> NV = Color
               ; D =< N   -> NV = zone
               ;              NV = V)),
             Row)),
        ZoneGrid).

% grid_distance_ring(+Grid, +R0, +C0, +D, -Coords)
% Coords is the list of [R,C] pairs within Grid at Manhattan distance exactly D
% from (R0,C0). Out-of-bounds positions are excluded. D=0 returns [[R0,C0]].
grid_distance_ring(Grid, R0, C0, D, Coords) :-
% Get grid bounds.
    grid_distance_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Collect all in-bounds cells at Manhattan distance exactly D.
    findall([R, C],
        (between(0, H1, R),
         between(0, W1, C),
         M is abs(R - R0) + abs(C - C0),
         M =:= D),
        Coords).

% grid_distance_voronoi(+Grid, -VGrid)
% VGrid is Grid with every background cell replaced by the color of its nearest
% non-background cell. Background is the most frequent color. Non-background
% cells keep their original value. If no foreground exists, VGrid = Grid.
grid_distance_voronoi(Grid, VGrid) :-
% Find background color.
    grid_distance_background_(Grid, Bg),
    grid_distance_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Collect all foreground (non-background) cells as FR-FC-V triples.
    findall(R-C-V,
        (between(0, H1, R), between(0, W1, C),
         grid_distance_cell_(Grid, R, C, V), V \= Bg),
        FgCells),
% Rebuild grid: background cells get nearest foreground color; others unchanged.
    findall(Row,
        (between(0, H1, R),
         findall(NV,
             (between(0, W1, C),
              grid_distance_cell_(Grid, R, C, V),
              (V = Bg, FgCells \= [] ->
                 grid_distance_nearest_fg_color_(R, C, FgCells, NV)
              ;  NV = V)),
             Row)),
        VGrid).

% grid_distance_bfs_flood(+Grid, +R0, +C0, +Wall, -DistGrid)
% DistGrid is a raw grid of BFS distances from (R0,C0) treating cells with
% value Wall as impassable. Unreachable cells and Wall cells get 9999.
% Fails if the start cell (R0,C0) itself has value Wall.
grid_distance_bfs_flood(Grid, R0, C0, Wall, DistGrid) :-
% Start cell must not be a wall.
    grid_distance_dims_(Grid, H, W),
    grid_distance_cell_(Grid, R0, C0, StartV),
    StartV \= Wall,
    H1 is H - 1,
    W1 is W - 1,
% BFS: initial queue and visited both contain the start cell at distance 0.
    grid_distance_bfs_loop_(Grid, H, W, Wall, [R0-C0-0], [R0-C0], [R0-C0-0], CellDists),
% Build the distance grid; cells not reached by BFS get 9999.
    findall(Row,
        (between(0, H1, R),
         findall(D,
             (between(0, W1, C),
              (memberchk(R-C-D0, CellDists) -> D = D0 ; D = 9999)),
             Row)),
        DistGrid).

% grid_distance_recolor_by_dist(+Grid, +Color, +Palette, -NewGrid)
% Each Color cell at Manhattan distance D from the nearest background cell is
% recolored to nth1(D, Palette, NewColor). Color cells beyond len(Palette)
% keep their original Color value. Non-Color cells are left unchanged.
grid_distance_recolor_by_dist(Grid, Color, Palette, NewGrid) :-
% Find background and compute distance from background for every cell.
    grid_distance_background_(Grid, Bg),
    grid_distance_dist_map(Grid, Bg, DMap),
    length(Palette, PLen),
    grid_distance_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
    findall(Row,
        (between(0, H1, R),
         findall(NV,
             (between(0, W1, C),
              grid_distance_cell_(Grid, R, C, V),
              grid_distance_cell_(DMap, R, C, D),
% Color cells within palette range get recolored; others keep their value.
              (V = Color ->
                 (D =< PLen -> nth1(D, Palette, NV) ; NV = Color)
              ;  NV = V)),
             Row)),
        NewGrid).

% grid_distance_expand_n(+Grid, +Color, +N, -Expanded)
% Expanded is Grid with every cell within Manhattan distance N of any Color
% cell set to Color. This is N-step morphological dilation of Color regions.
grid_distance_expand_n(Grid, Color, N, Expanded) :-
% N=0 leaves the grid unchanged.
    (N =:= 0 -> Expanded = Grid ;
% Compute minimum distance from every cell to nearest Color cell.
     grid_distance_dist_map(Grid, Color, DMap),
     grid_distance_dims_(Grid, H, W),
     H1 is H - 1,
     W1 is W - 1,
% Set every cell within distance N to Color; leave others unchanged.
     findall(Row,
         (between(0, H1, R),
          findall(NV,
              (between(0, W1, C),
               grid_distance_cell_(Grid, R, C, V),
               grid_distance_cell_(DMap, R, C, D),
               (D =< N -> NV = Color ; NV = V)),
              Row)),
         Expanded)).

% grid_distance_shrink_n(+Grid, +Color, +N, -Shrunk)
% Shrunk is Grid with every Color cell within Manhattan distance N of the
% nearest background cell replaced by the background color.
% This is N-step morphological erosion of Color regions.
grid_distance_shrink_n(Grid, Color, N, Shrunk) :-
% N=0 leaves the grid unchanged.
    (N =:= 0 -> Shrunk = Grid ;
% Find background.
     grid_distance_background_(Grid, Bg),
% Compute distance from each cell to nearest background cell.
     grid_distance_dist_map(Grid, Bg, DMap),
     grid_distance_dims_(Grid, H, W),
     H1 is H - 1,
     W1 is W - 1,
% Replace Color cells whose background distance <= N with background.
     findall(Row,
         (between(0, H1, R),
          findall(NV,
              (between(0, W1, C),
               grid_distance_cell_(Grid, R, C, V),
               grid_distance_cell_(DMap, R, C, D),
               (V = Color, D =< N -> NV = Bg ; NV = V)),
              Row)),
         Shrunk)).

% grid_distance_equidistant(+Grid, +ColorA, +ColorB, -EqGrid)
% EqGrid is Grid with every cell where the Manhattan distance to ColorA equals
% the Manhattan distance to ColorB replaced by the atom equidist.
% ColorA or ColorB cells keep their original value even if equidistant.
grid_distance_equidistant(Grid, ColorA, ColorB, EqGrid) :-
% Build one distance map per color.
    grid_distance_dist_map(Grid, ColorA, DMapA),
    grid_distance_dist_map(Grid, ColorB, DMapB),
    grid_distance_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
    findall(Row,
        (between(0, H1, R),
         findall(NV,
             (between(0, W1, C),
              grid_distance_cell_(Grid, R, C, V),
              grid_distance_cell_(DMapA, R, C, DA),
              grid_distance_cell_(DMapB, R, C, DB),
% Mark equidistant cells; ColorA/B cells are kept even when equidist holds.
              (DA =:= DB -> NV = equidist ; NV = V)),
             Row)),
        EqGrid).

% grid_distance_max_dist(+Grid, +Color, -R, -C)
% (R,C) is the position of the cell farthest (maximum Manhattan distance) from
% any Color cell in Grid. Ties resolved by row-major order (top-left wins).
% Fails if Grid contains no Color cells (all distances would be 9999).
grid_distance_max_dist(Grid, Color, R, C) :-
% Build the distance map.
    grid_distance_dist_map(Grid, Color, DMap),
    grid_distance_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Collect all finite distances (exclude 9999 = unreachable / no Color present).
    findall(D,
        (between(0, H1, R2), between(0, W1, C2),
         grid_distance_cell_(DMap, R2, C2, D), D < 9999),
        Dists),
    Dists \= [],
    max_list(Dists, MaxD),
% Return the first cell (row-major) that achieves MaxD.
    once((between(0, H1, R), between(0, W1, C), grid_distance_cell_(DMap, R, C, MaxD))).
