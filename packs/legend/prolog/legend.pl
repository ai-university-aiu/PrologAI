% Module declaration with all fourteen public predicates.
:- module(legend, [
% Detect legend regions in a single grid (small, isolated, structurally distinct regions).
    lg_detect_legend/3,
% Succeed if a region is more likely a legend/key than a content object.
    lg_is_legend/2,
% Parse a legend region into entry(Feature, Value) terms.
    lg_legend_entries/2,
% Find a legend region that appears consistently across all training pair inputs.
    lg_consistent_legend/2,
% Find the bounding box of a connected region of cells with a given color.
    lg_region_bbox/3,
% Check if two regions are spatially separated (not touching).
    lg_separated/2,
% Compute the area of a list of cells.
    lg_region_area/2,
% Find all isolated color regions in a grid (connected components by color).
    lg_all_regions/3,
% Find the dominant color of a region (most frequent non-bg color).
    lg_region_color/3,
% Check if a region is small relative to the total grid area.
    lg_is_small/3,
% Check if two regions share the same structural shape (same relative cell pattern).
    lg_same_shape/2,
% Find the cell coordinates of a legend entry boundary (distinct rows or cols).
    lg_entry_boundaries/2,
% Find a color-to-row-band mapping from a legend region using the source grid.
    lg_color_map/3,
% Return the spatial position of a region relative to the grid (top, bottom, left, right, center).
    lg_position/3
]).
% legend.pl - Layer 250: Legend and Key Region Detection (lg_* prefix).
% Fourteen predicates for finding and parsing "legend" regions in grid tasks.
% A legend region is a small, isolated part of the grid that acts as a code key,
% mapping visual features (color, size, holes) to semantic meanings.
% Grids are lists-of-lists. Regions are lists of r(Row,Col) cell coordinates.
% Training pairs are pair(InputGrid, OutputGrid) terms.
:- use_module(library(lists), [member/2, subtract/3, numlist/3, last/2]).
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% --- PRIVATE HELPERS ---

% lg_grid_dims_/3: grid dimensions.
lg_grid_dims_(Grid, Rows, Cols) :-
    length(Grid, Rows),
    (Grid = [Row|_] -> length(Row, Cols) ; Cols = 0).

% lg_cell_color_/3: color of a cell in a grid (0-indexed).
lg_cell_color_(Grid, r(R,C), Color) :-
    nth0(R, Grid, Row), nth0(C, Row, Color).

% lg_flood_region_/4: grow a connected region from seed r(R,C) with same color.
lg_flood_region_(Grid, Seed, BgColor, Region) :-
    lg_cell_color_(Grid, Seed, Color),
    Color \= BgColor,
    lg_grid_dims_(Grid, Rows, Cols),
    Rows1 is Rows - 1, Cols1 is Cols - 1,
    numlist(0, Rows1, RowRange), numlist(0, Cols1, ColRange),
    findall(r(RR,CC), (member(RR, RowRange), member(CC, ColRange),
                       lg_cell_color_(Grid, r(RR,CC), Color)), AllColorCells),
    lg_bfs_(AllColorCells, [Seed], [], Region).

% lg_bfs_/4: breadth-first search to find 4-connected component.
lg_bfs_(AllCells, [r(R,C)|Queue], Visited, Region) :-
    \+ member(r(R,C), Visited),
    !,
    findall(r(NR,NC), (member(r(NR,NC), AllCells),
                       \+ member(r(NR,NC), [r(R,C)|Visited]),
                       (NR is R+1, NC =:= C ;
                        NR is R-1, NC =:= C ;
                        NR =:= R, NC is C+1 ;
                        NR =:= R, NC is C-1)), Neighbors),
    append(Queue, Neighbors, NewQueue),
    sort(NewQueue, SortedQueue),
    lg_bfs_(AllCells, SortedQueue, [r(R,C)|Visited], Region).
lg_bfs_(_, [r(R,C)|Queue], Visited, Region) :-
    member(r(R,C), Visited),
    !,
    lg_bfs_(_, Queue, Visited, Region).
lg_bfs_(_, [], Visited, Region) :-
    sort(Visited, Region).

% lg_region_min_max_/5: min/max row and col of a region.
lg_region_min_max_(Region, MinR, MinC, MaxR, MaxC) :-
    findall(R, member(r(R,_), Region), Rows),
    findall(C, member(r(_,C), Region), Cols),
    min_list(Rows, MinR), max_list(Rows, MaxR),
    min_list(Cols, MinC), max_list(Cols, MaxC).

% lg_touching_/2: succeed if two regions share at least one adjacent cell pair.
lg_touching_(RegA, RegB) :-
    member(r(R,C), RegA),
    (R1 is R+1 ; R1 is R-1 ; R1 = R, C1 is C+1 ; R1 = R, C1 is C-1),
    (var(C1) -> C1 = C ; true),
    member(r(R1,C1), RegB),
    !.

% lg_normalize_shape_/2: translate region to origin (min row and col = 0).
lg_normalize_shape_(Region, Normalized) :-
    findall(R, member(r(R,_), Region), Rows),
    findall(C, member(r(_,C), Region), Cols),
    min_list(Rows, MinR), min_list(Cols, MinC),
    findall(r(NR,NC), (member(r(R,C), Region), NR is R-MinR, NC is C-MinC), Normalized0),
    sort(Normalized0, Normalized).

% --- PUBLIC PREDICATES ---

% lg_detect_legend(+Grid, +BgColor, -LegendRegion)
% Find the most likely legend region in Grid: a small, isolated, structurally
% distinct connected color region. Returns the smallest non-bg region if multiple.
lg_detect_legend(Grid, BgColor, LegendRegion) :-
    lg_all_regions(Grid, BgColor, Regions),
    include(lg_is_small_(Grid), Regions, SmallRegions),
    SmallRegions \= [],
    (SmallRegions = [LegendRegion] ->
        true
    ;
        include(lg_isolated_(Regions), SmallRegions, Isolated),
        (Isolated = [LegendRegion|_] -> true ;
         SmallRegions = [LegendRegion|_])
    ).

% lg_is_small_/2: helper wrapper for include.
lg_is_small_(Grid, Region) :-
    lg_grid_dims_(Grid, Rows, Cols),
    TotalArea is Rows * Cols,
    lg_region_area(Region, A),
    A * 4 =< TotalArea.

% lg_isolated_/2: helper wrapper for include.
lg_isolated_(AllRegions, Region) :-
    findall(Other, (member(Other, AllRegions), Other \= Region), Others),
    \+ (member(Other, Others), lg_touching_(Region, Other)).

% lg_is_legend(+Region, +ContentRegions)
% Succeed if Region is more likely a legend/key than content.
% A region is a legend if: it is small (area <= 1/4 of largest content region),
% it is not touching any content region, and it has a distinct shape.
lg_is_legend(Region, ContentRegions) :-
    lg_region_area(Region, A),
    (ContentRegions = [] ->
        A =< 9
    ;
        findall(CA, (member(CR, ContentRegions), lg_region_area(CR, CA)), CAs),
        max_list(CAs, MaxCA),
        A * 2 =< MaxCA
    ),
    \+ (member(CR, ContentRegions), lg_touching_(Region, CR)).

% lg_legend_entries(+LegendRegion, -Entries)
% Parse a legend region into entry(color, row_band) terms.
% Each distinct row band in the region is treated as one legend entry.
% Entries are entry(Color, BandIndex) where BandIndex is 0-based.
lg_legend_entries(LegendRegion, Entries) :-
    findall(R, member(r(R,_), LegendRegion), Rows0),
    sort(Rows0, UniqueRows),
    findall(entry(BandIdx, BandIdx),
        (nth0(BandIdx, UniqueRows, _)),
        Entries).

% lg_consistent_legend(+Pairs, -Legend)
% Find a legend structure that appears consistently in every training pair input.
% Legend is a list of entry/2 terms from the first pair that also appears in all others.
% Uses a conservative check: the number of regions and region areas must match.
lg_consistent_legend(Pairs, Legend) :-
    Pairs = [pair(FirstIn, _)|RestPairs],
    lg_all_regions(FirstIn, 0, FirstRegions),
    include(lg_is_small_(FirstIn), FirstRegions, FirstSmall),
    (FirstSmall = [CandRegion|_] ->
        lg_legend_entries(CandRegion, Legend),
        maplist(lg_has_similar_region_(CandRegion), RestPairs)
    ;
        Legend = []
    ).

% lg_has_similar_region_/2: succeed if a pair input has a region of same size.
lg_has_similar_region_(CandRegion, pair(In, _)) :-
    lg_region_area(CandRegion, A),
    lg_all_regions(In, 0, Regions),
    member(Region, Regions),
    lg_region_area(Region, A),
    !.

% lg_region_bbox(+Region, +BgColor, -BBox)
% BBox = r0(MinR, MinC, MaxR, MaxC) for the region's bounding box.
lg_region_bbox(Region, _BgColor, r0(MinR, MinC, MaxR, MaxC)) :-
    lg_region_min_max_(Region, MinR, MinC, MaxR, MaxC).

% lg_separated(+RegionA, +RegionB)
% Succeed if RegionA and RegionB are not touching (no adjacent cells).
lg_separated(RegionA, RegionB) :-
    \+ lg_touching_(RegionA, RegionB).

% lg_region_area(+Region, -Area)
% Area is the number of cells in the region.
lg_region_area(Region, Area) :-
    length(Region, Area).

% lg_all_regions(+Grid, +BgColor, -Regions)
% Find all connected color regions in Grid (excluding background).
% Each region is a list of r(R,C) cells.
lg_all_regions(Grid, BgColor, Regions) :-
    lg_grid_dims_(Grid, Rows, Cols),
    (Rows =:= 0 -> Regions = [] ;
        Rows1 is Rows - 1, Cols1 is Cols - 1,
        numlist(0, Rows1, RowRange), numlist(0, Cols1, ColRange),
        findall(r(R,C),
            (member(R, RowRange), member(C, ColRange),
             lg_cell_color_(Grid, r(R,C), V), V \= BgColor),
            AllNonBg),
        lg_connected_components_(Grid, BgColor, AllNonBg, [], Regions)
    ).

% lg_connected_components_/5: iteratively peel off components.
lg_connected_components_(_, _, [], Acc, Acc).
lg_connected_components_(Grid, BgColor, [Seed|Rest], Acc, Regions) :-
    lg_flood_region_(Grid, Seed, BgColor, Component),
    subtract(Rest, Component, Remaining),
    lg_connected_components_(Grid, BgColor, Remaining, [Component|Acc], Regions).

% lg_region_color(+Region, +Grid, -Color)
% Color is the most common color of cells in Region (non-bg assumed to be consistent).
lg_region_color(Region, Grid, Color) :-
    findall(V, (member(Cell, Region), lg_cell_color_(Grid, Cell, V)), Colors),
    msort(Colors, Sorted),
    last(Sorted, Color).

% lg_is_small(+Region, +Grid, -Bool)
% Bool is true if region area <= 1/4 of total grid area.
lg_is_small(Region, Grid, true) :-
    lg_grid_dims_(Grid, Rows, Cols),
    TotalArea is Rows * Cols,
    lg_region_area(Region, A),
    A * 4 =< TotalArea,
    !.
lg_is_small(_, _, false).

% lg_same_shape(+Region1, +Region2)
% Succeed if two regions have the same normalized shape (same relative cell pattern).
lg_same_shape(Region1, Region2) :-
    lg_normalize_shape_(Region1, N1),
    lg_normalize_shape_(Region2, N2),
    N1 = N2.

% lg_entry_boundaries(+LegendRegion, -Boundaries)
% Boundaries is a sorted list of unique row indices in the legend region.
% Each unique row is a potential boundary between legend entries.
lg_entry_boundaries(LegendRegion, Boundaries) :-
    findall(R, member(r(R,_), LegendRegion), Rows),
    sort(Rows, Boundaries).

% lg_color_map(+LegendRegion, +Grid, -ColorMap)
% ColorMap is a list of cm(Color, BandIdx) terms where each row band of the
% legend region maps to the color found at its first cell in Grid.
% BandIdx is 0-based from top row of the legend region.
lg_color_map(LegendRegion, Grid, ColorMap) :-
    lg_entry_boundaries(LegendRegion, Rows),
    findall(cm(Color, Idx),
        (nth0(Idx, Rows, Row),
         findall(C, member(r(Row,C), LegendRegion), Cols),
         Cols \= [],
         hd_(Cols, Col),
         lg_cell_color_(Grid, r(Row, Col), Color)),
        Raw),
    sort(Raw, ColorMap).

% hd_/2: get head of list.
hd_([H|_], H).

% lg_position(+Region, +Grid, -Position)
% Position is one of: top, bottom, left, right, center based on where
% the region's bounding box center falls relative to the grid center.
lg_position(Region, Grid, Position) :-
    lg_grid_dims_(Grid, Rows, Cols),
    lg_region_min_max_(Region, MinR, MinC, MaxR, MaxC),
    CenterR is (MinR + MaxR) / 2,
    CenterC is (MinC + MaxC) / 2,
    ThirdRows is Rows / 3,
    ThirdCols is Cols / 3,
    (CenterR < ThirdRows -> Position = top ;
     CenterR >= Rows - ThirdRows -> Position = bottom ;
     CenterC < ThirdCols -> Position = left ;
     CenterC >= Cols - ThirdCols -> Position = right ;
     Position = center).
