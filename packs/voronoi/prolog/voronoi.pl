% voronoi.pl - Layer 166: Nearest-Color Painting and Voronoi Partitioning (vn_* prefix).
% Provides nearest-color queries on 2D integer-or-atom grids: for any background
% cell find the color and Manhattan distance of the nearest non-background cell;
% paint all background cells with their nearest color; compute the distance
% transform; partition background cells into per-color Voronoi regions; locate
% equidistant boundary cells (Voronoi edges); and expand color regions by N steps.
% All predicates treat the background as a distinguished value passed as Bg.
:- module(voronoi, [
    vn_non_bg_cells/3,
    vn_non_bg_colors/3,
    vn_nearest_dist/5,
    vn_nearest_color/5,
    vn_paint_bg/3,
    vn_dist_map/3,
    vn_region_cells/4,
    vn_regions/3,
    vn_max_dist/3,
    vn_at_dist/4,
    vn_within_dist/4,
    vn_medial/3,
    vn_expand1/4,
    vn_expand_n/5
]).
% member/2, nth0/3, min_list/2, max_list/2, append/3 from library(lists).
:- use_module(library(lists), [member/2, nth0/3, min_list/2, max_list/2, append/3]).

% vn_non_bg_cells(+Grid, +Bg, -Cells): sorted list of r(R,C) positions whose
% value differs from Bg. These are the "sources" for nearest-color computations.
vn_non_bg_cells(Grid, Bg, Cells) :-
% Collect every grid cell whose value is not the background.
    findall(r(R,C),
            (nth0(R, Grid, Row), nth0(C, Row, V), V \= Bg),
            Raw),
    sort(Raw, Cells).

% vn_non_bg_colors(+Grid, +Bg, -Colors): sorted list of distinct values in Grid
% that are not equal to Bg.
vn_non_bg_colors(Grid, Bg, Colors) :-
% Gather all non-Bg values and deduplicate.
    findall(V,
            (nth0(_, Grid, Row), nth0(_, Row, V), V \= Bg),
            Raw),
    sort(Raw, Colors).

% vn_nearest_dist(+Grid, +Bg, +R, +C, -Dist): minimum Manhattan distance from
% position r(R,C) to any non-background cell. Fails if no non-Bg cells exist.
vn_nearest_dist(Grid, Bg, R, C, Dist) :-
% Collect distance to every non-Bg cell.
    findall(D,
            (nth0(NR, Grid, Row), nth0(NC, Row, V), V \= Bg,
             D is abs(NR-R) + abs(NC-C)),
            Dists),
% Pick the minimum distance.
    min_list(Dists, Dist).

% vn_nearest_color(+Grid, +Bg, +R, +C, -Color): color of the closest non-Bg
% cell to r(R,C) by Manhattan distance. When two cells are equidistant the one
% first in standard term order wins.
vn_nearest_color(Grid, Bg, R, C, Color) :-
% Build D-V pairs for every non-Bg cell.
    findall(D-V,
            (nth0(NR, Grid, Row), nth0(NC, Row, V), V \= Bg,
             D is abs(NR-R) + abs(NC-C)),
            Pairs),
% Sort ascending; smallest distance (then smallest V) is first.
    sort(Pairs, [_-Color|_]).

% vn_paint_bg(+Grid, +Bg, -Painted): replace every Bg cell with the color of
% the nearest non-Bg cell. Non-Bg cells are left unchanged. Same dimensions.
vn_paint_bg(Grid, Bg, Painted) :-
% Build each row: for non-Bg cells keep value; for Bg cells find nearest color.
    findall(PRow,
            (nth0(R, Grid, GRow),
             findall(New,
                     (nth0(C, GRow, V),
                      (V \= Bg -> New = V
                               ;  vn_nearest_color(Grid, Bg, R, C, New))),
                     PRow)),
            Painted).

% vn_dist_map(+Grid, +Bg, -DGrid): replace each cell value with the Manhattan
% distance to the nearest non-Bg cell. Non-Bg cells get distance 0.
vn_dist_map(Grid, Bg, DGrid) :-
% Pre-collect all non-Bg cells so we don't re-scan Grid for each cell.
    vn_non_bg_cells(Grid, Bg, NonBg),
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

% vn_region_cells(+Grid, +Bg, +Color, -Cells): sorted list of Bg cells whose
% nearest non-Bg color is Color.
vn_region_cells(Grid, Bg, Color, Cells) :-
% Keep Bg cells where the nearest color matches.
    findall(r(R,C),
            (nth0(R, Grid, Row), nth0(C, Row, Bg),
             vn_nearest_color(Grid, Bg, R, C, Color)),
            Raw),
    sort(Raw, Cells).

% vn_regions(+Grid, +Bg, -Pairs): sorted list of Color-[Cells] pairs covering
% all distinct non-Bg colors; Cells is the Voronoi region of that color.
vn_regions(Grid, Bg, Pairs) :-
% Enumerate colors then build one pair per color.
    vn_non_bg_colors(Grid, Bg, Colors),
    findall(Color-Cells,
            (member(Color, Colors),
             vn_region_cells(Grid, Bg, Color, Cells)),
            Pairs).

% vn_max_dist(+Grid, +Bg, -MaxDist): maximum distance of any Bg cell from
% its nearest non-Bg cell. Fails if Grid contains no Bg cells.
vn_max_dist(Grid, Bg, MaxDist) :-
% Collect distances of all Bg cells.
    findall(D,
            (nth0(R, Grid, Row), nth0(C, Row, Bg),
             vn_nearest_dist(Grid, Bg, R, C, D)),
            Dists),
% Require at least one Bg cell and return the maximum.
    Dists \= [],
    max_list(Dists, MaxDist).

% vn_at_dist(+Grid, +Bg, +D, -Cells): sorted list of Bg cells at Manhattan
% distance exactly D from the nearest non-Bg cell.
vn_at_dist(Grid, Bg, D, Cells) :-
    findall(r(R,C),
            (nth0(R, Grid, Row), nth0(C, Row, Bg),
             vn_nearest_dist(Grid, Bg, R, C, D)),
            Raw),
    sort(Raw, Cells).

% vn_within_dist(+Grid, +Bg, +D, -Cells): sorted list of Bg cells at Manhattan
% distance =< D from the nearest non-Bg cell.
vn_within_dist(Grid, Bg, D, Cells) :-
    findall(r(R,C),
            (nth0(R, Grid, Row), nth0(C, Row, Bg),
             vn_nearest_dist(Grid, Bg, R, C, Dist),
             Dist =< D),
            Raw),
    sort(Raw, Cells).

% vn_medial(+Grid, +Bg, -Cells): sorted list of Bg cells that are equidistant
% from non-Bg cells of two or more distinct colors. These are the Voronoi edge
% cells (the medial axis of the partition).
vn_medial(Grid, Bg, Cells) :-
    findall(r(R,C),
            (nth0(R, Grid, Row), nth0(C, Row, Bg),
% Find the minimum distance to any non-Bg cell.
             vn_nearest_dist(Grid, Bg, R, C, MinD),
% Collect all non-Bg colors that achieve that minimum distance.
             findall(V,
                     (nth0(NR, Grid, NRow), nth0(NC, NRow, V), V \= Bg,
                      MinD =:= abs(NR-R)+abs(NC-C)),
                     Vs),
% Medial iff at least two distinct colors are tied for nearest.
             sort(Vs, [_,_|_])),
            Raw),
    sort(Raw, Cells).

% vn_expand1(+Grid, +Bg, +Color, -Cells): sorted list of Bg cells that are
% 4-connected to at least one non-Bg cell of Color. These are the Bg cells
% one step away from the Color region.
vn_expand1(Grid, Bg, Color, Cells) :-
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

% vn_expand_n(+Grid, +Bg, +Color, +N, -Cells): sorted list of Bg cells reachable
% by expanding the Color region N steps outward through background cells.
% Uses Manhattan distance: a Bg cell is included if there exists a Color cell
% at Manhattan distance =< N.
vn_expand_n(Grid, Bg, Color, N, Cells) :-
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
