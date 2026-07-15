% voronoi.pl - Layer 166: Nearest-Color Painting and Voronoi Partitioning (vn_* prefix).
% Provides nearest-color queries on 2D integer-or-atom grids: for any background
% cell find the color and Manhattan distance of the nearest non-background cell;
% paint all background cells with their nearest color; compute the distance
% transform; partition background cells into per-color Voronoi regions; locate
% equidistant boundary cells (Voronoi edges); and expand color regions by N steps.
% All predicates treat the background as a distinguished value passed as Bg.
:- module(voronoi, [
    voronoi_non_bg_cells/3,
    voronoi_non_bg_colors/3,
    voronoi_nearest_dist/5,
    voronoi_nearest_color/5,
    voronoi_paint_bg/3,
    voronoi_dist_map/3,
    voronoi_region_cells/4,
    voronoi_regions/3,
    voronoi_max_dist/3,
    voronoi_at_dist/4,
    voronoi_within_dist/4,
    voronoi_medial/3,
    voronoi_expand1/4,
    voronoi_expand_n/5
]).
% member/2, nth0/3, min_list/2, max_list/2, append/3 from library(lists).
:- use_module(library(lists), [member/2, nth0/3, min_list/2, max_list/2, append/3]).

% voronoi_non_bg_cells(+Grid, +Bg, -Cells): sorted list of r(R,C) positions whose
% value differs from Bg. These are the "sources" for nearest-color computations.
voronoi_non_bg_cells(Grid, Bg, Cells) :-
% Collect every grid cell whose value is not the background.
    findall(r(R,C),
            (nth0(R, Grid, Row), nth0(C, Row, V), V \= Bg),
            Raw),
    sort(Raw, Cells).

% voronoi_non_bg_colors(+Grid, +Bg, -Colors): sorted list of distinct values in Grid
% that are not equal to Bg.
voronoi_non_bg_colors(Grid, Bg, Colors) :-
% Gather all non-Bg values and deduplicate.
    findall(V,
            (nth0(_, Grid, Row), nth0(_, Row, V), V \= Bg),
            Raw),
    sort(Raw, Colors).

% voronoi_nearest_dist(+Grid, +Bg, +R, +C, -Dist): minimum Manhattan distance from
% position r(R,C) to any non-background cell. Fails if no non-Bg cells exist.
voronoi_nearest_dist(Grid, Bg, R, C, Dist) :-
% Collect distance to every non-Bg cell.
    findall(D,
            (nth0(NR, Grid, Row), nth0(NC, Row, V), V \= Bg,
             D is abs(NR-R) + abs(NC-C)),
            Dists),
% Pick the minimum distance.
    min_list(Dists, Dist).

% voronoi_nearest_color(+Grid, +Bg, +R, +C, -Color): color of the closest non-Bg
% cell to r(R,C) by Manhattan distance. When two cells are equidistant the one
% first in standard term order wins.
voronoi_nearest_color(Grid, Bg, R, C, Color) :-
% Build D-V pairs for every non-Bg cell.
    findall(D-V,
            (nth0(NR, Grid, Row), nth0(NC, Row, V), V \= Bg,
             D is abs(NR-R) + abs(NC-C)),
            Pairs),
% Sort ascending; smallest distance (then smallest V) is first.
    sort(Pairs, [_-Color|_]).

% voronoi_paint_bg(+Grid, +Bg, -Painted): replace every Bg cell with the color of
% the nearest non-Bg cell. Non-Bg cells are left unchanged. Same dimensions.
voronoi_paint_bg(Grid, Bg, Painted) :-
% Build each row: for non-Bg cells keep value; for Bg cells find nearest color.
    findall(PRow,
            (nth0(R, Grid, GRow),
             findall(New,
                     (nth0(C, GRow, V),
                      (V \= Bg -> New = V
                               ;  voronoi_nearest_color(Grid, Bg, R, C, New))),
                     PRow)),
            Painted).

% voronoi_dist_map(+Grid, +Bg, -DGrid): replace each cell value with the Manhattan
% distance to the nearest non-Bg cell. Non-Bg cells get distance 0.
voronoi_dist_map(Grid, Bg, DGrid) :-
% Pre-collect all non-Bg cells so we don't re-scan Grid for each cell.
    voronoi_non_bg_cells(Grid, Bg, NonBg),
% Build each row of the distance grid.
    findall(DRow,
            (nth0(R, Grid, GRow),
             findall(D,
                     (nth0(C, GRow, V),
                      (V \= Bg
                       -> D = 0
                       ;  findall(Dist,
                                  (member(r(NR,NC), NonBg),
                                   Dist is abs(NR-R)+abs(NC-C)),
                                  Dists),
                          min_list(Dists, D))),
                     DRow)),
            DGrid).

% voronoi_region_cells(+Grid, +Bg, +Color, -Cells): sorted list of Bg cells whose
% nearest non-Bg color is Color.
voronoi_region_cells(Grid, Bg, Color, Cells) :-
% Keep Bg cells where the nearest color matches.
    findall(r(R,C),
            (nth0(R, Grid, Row), nth0(C, Row, Bg),
             voronoi_nearest_color(Grid, Bg, R, C, Color)),
            Raw),
    sort(Raw, Cells).

% voronoi_regions(+Grid, +Bg, -Pairs): sorted list of Color-[Cells] pairs covering
% all distinct non-Bg colors; Cells is the Voronoi region of that color.
voronoi_regions(Grid, Bg, Pairs) :-
% Enumerate colors then build one pair per color.
    voronoi_non_bg_colors(Grid, Bg, Colors),
    findall(Color-Cells,
            (member(Color, Colors),
             voronoi_region_cells(Grid, Bg, Color, Cells)),
            Pairs).

% voronoi_max_dist(+Grid, +Bg, -MaxDist): maximum distance of any Bg cell from
% its nearest non-Bg cell. Fails if Grid contains no Bg cells.
voronoi_max_dist(Grid, Bg, MaxDist) :-
% Collect distances of all Bg cells.
    findall(D,
            (nth0(R, Grid, Row), nth0(C, Row, Bg),
             voronoi_nearest_dist(Grid, Bg, R, C, D)),
            Dists),
% Require at least one Bg cell and return the maximum.
    Dists \= [],
    max_list(Dists, MaxDist).

% voronoi_at_dist(+Grid, +Bg, +D, -Cells): sorted list of Bg cells at Manhattan
% distance exactly D from the nearest non-Bg cell.
voronoi_at_dist(Grid, Bg, D, Cells) :-
    findall(r(R,C),
            (nth0(R, Grid, Row), nth0(C, Row, Bg),
             voronoi_nearest_dist(Grid, Bg, R, C, D)),
            Raw),
    sort(Raw, Cells).

% voronoi_within_dist(+Grid, +Bg, +D, -Cells): sorted list of Bg cells at Manhattan
% distance =< D from the nearest non-Bg cell.
voronoi_within_dist(Grid, Bg, D, Cells) :-
    findall(r(R,C),
            (nth0(R, Grid, Row), nth0(C, Row, Bg),
             voronoi_nearest_dist(Grid, Bg, R, C, Dist),
             Dist =< D),
            Raw),
    sort(Raw, Cells).

% voronoi_medial(+Grid, +Bg, -Cells): sorted list of Bg cells that are equidistant
% from non-Bg cells of two or more distinct colors. These are the Voronoi edge
% cells (the medial axis of the partition).
voronoi_medial(Grid, Bg, Cells) :-
    findall(r(R,C),
            (nth0(R, Grid, Row), nth0(C, Row, Bg),
% Find the minimum distance to any non-Bg cell.
             voronoi_nearest_dist(Grid, Bg, R, C, MinD),
% Collect all non-Bg colors that achieve that minimum distance.
             findall(V,
                     (nth0(NR, Grid, NRow), nth0(NC, NRow, V), V \= Bg,
                      MinD =:= abs(NR-R)+abs(NC-C)),
                     Vs),
% Medial iff at least two distinct colors are tied for nearest.
             sort(Vs, [_,_|_])),
            Raw),
    sort(Raw, Cells).

% voronoi_expand1(+Grid, +Bg, +Color, -Cells): sorted list of Bg cells that are
% 4-connected to at least one non-Bg cell of Color. These are the Bg cells
% one step away from the Color region.
voronoi_expand1(Grid, Bg, Color, Cells) :-
% Pre-collect the Color cells for neighbor checking.
    findall(r(R,C),
            (nth0(R, Grid, Row), nth0(C, Row, Color), Color \= Bg),
            ColorCells),
% A Bg cell is in the expansion if any Color cell is an orthogonal neighbor.
    findall(r(BR,BC),
            (nth0(BR, Grid, BRow), nth0(BC, BRow, Bg),
             member(r(CR,CC), ColorCells),
             (BR =:= CR, abs(BC-CC) =:= 1 ;
              BC =:= CC, abs(BR-CR) =:= 1)),
            Raw),
    sort(Raw, Cells).

% voronoi_expand_n(+Grid, +Bg, +Color, +N, -Cells): sorted list of Bg cells reachable
% by expanding the Color region N steps outward through background cells.
% Uses Manhattan distance: a Bg cell is included if there exists a Color cell
% at Manhattan distance =< N.
voronoi_expand_n(Grid, Bg, Color, N, Cells) :-
% Collect all cells of Color in Grid.
    findall(r(CR,CC),
            (nth0(CR, Grid, CRow), nth0(CC, CRow, Color), Color \= Bg),
            ColorCells),
% A Bg cell is within N steps if its nearest Color cell is at distance =< N.
    findall(r(BR,BC),
            (nth0(BR, Grid, BRow), nth0(BC, BRow, Bg),
             member(r(CR,CC), ColorCells),
             D is abs(BR-CR)+abs(BC-CC),
             D =< N),
            Raw),
    sort(Raw, Cells).
