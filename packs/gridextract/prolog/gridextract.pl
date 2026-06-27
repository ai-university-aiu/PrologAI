:- module(gridextract, [
    gxt_nonbg_cells/3,
    gxt_color_cells/3,
    gxt_bbox/4,
    gxt_crop_bbox/5,
    gxt_object_at/5,
    gxt_all_colors/3,
    gxt_color_count/4,
    gxt_largest_color/3,
    gxt_smallest_color/3,
    gxt_centered_crop/5,
    gxt_row_cells/4,
    gxt_col_cells/4,
    gxt_region_count/4,
    gxt_registry/3
]).
% gridextract.pl - Layer 236: Grid Object Extraction (gxt_* prefix).
% Fourteen predicates for collecting cells, computing bounding boxes, extracting
% crops, and building object registries from symbolic grids.
% No cross-pack dependencies.
:- use_module(library(lists), [member/2, last/2]).

% --- PRIVATE HELPERS ---

% gxt_min_list_/2: minimum value in a non-empty list of integers.
gxt_min_list_([H|T], Min) :- gxt_min_list_(T, H, Min).
gxt_min_list_([], M, M).
gxt_min_list_([H|T], Cur, Min) :-
    (H < Cur -> gxt_min_list_(T, H, Min) ; gxt_min_list_(T, Cur, Min)).

% gxt_max_list_/2: maximum value in a non-empty list of integers.
gxt_max_list_([H|T], Max) :- gxt_max_list_(T, H, Max).
gxt_max_list_([], M, M).
gxt_max_list_([H|T], Cur, Max) :-
    (H > Cur -> gxt_max_list_(T, H, Max) ; gxt_max_list_(T, Cur, Max)).

% gxt_unique_/2: remove duplicates from a sorted list (consecutive dedup).
gxt_unique_([], []).
gxt_unique_([H|T], [H|Unique]) :- gxt_unique_(T, H, Unique).
gxt_unique_([], _, []).
gxt_unique_([H|T], Prev, Result) :-
    (H = Prev ->
        gxt_unique_(T, Prev, Result)
    ;
        Result = [H|Rest],
        gxt_unique_(T, H, Rest)
    ).

% gxt_sorted_unique_/2: sort a list and remove duplicates.
gxt_sorted_unique_(List, Unique) :-
    msort(List, Sorted),
    gxt_unique_(Sorted, Unique).

% --- PUBLIC PREDICATES ---

% gxt_nonbg_cells(+Grid, +BgColor, -Cells)
% Collect all non-bg cells as a list of row-col-value triples: r(R,C,V).
% Result is in row-major order (row 0 left to right, then row 1, etc.).
gxt_nonbg_cells(Grid, Bg, Cells) :-
    length(Grid, H), H1 is H - 1,
    findall(r(R,C,V),
        (between(0, H1, R),
         nth0(R, Grid, Row),
         length(Row, W), W1 is W - 1,
         between(0, W1, C),
         nth0(C, Row, V),
         V \= Bg),
        Cells).

% gxt_color_cells(+Grid, +Color, -Cells)
% Collect all cells of a specific color as r(R,C,Color) triples.
gxt_color_cells(Grid, Color, Cells) :-
    length(Grid, H), H1 is H - 1,
    findall(r(R,C,Color),
        (between(0, H1, R),
         nth0(R, Grid, Row),
         length(Row, W), W1 is W - 1,
         between(0, W1, C),
         nth0(C, Row, Color)),
        Cells).

% gxt_bbox(+Grid, +BgColor, -BBox, -Cells)
% Compute the tight bounding box of all non-bg cells.
% BBox = bb(MinR, MinC, MaxR, MaxC).
% Cells is the list of r(R,C,V) triples within the bounding box.
% Fails if the grid has no non-bg cells.
gxt_bbox(Grid, Bg, bb(MinR,MinC,MaxR,MaxC), Cells) :-
    gxt_nonbg_cells(Grid, Bg, Cells),
    Cells \= [],
    findall(R, member(r(R,_,_), Cells), Rows),
    findall(C, member(r(_,C,_), Cells), Cols),
    gxt_min_list_(Rows, MinR),
    gxt_max_list_(Rows, MaxR),
    gxt_min_list_(Cols, MinC),
    gxt_max_list_(Cols, MaxC).

% gxt_crop_bbox(+Grid, +BgColor, +BBox, -Crop, -Offset)
% Extract the sub-grid defined by BBox = bb(R1,C1,R2,C2).
% Crop is the extracted sub-grid; Offset = off(R1, C1).
gxt_crop_bbox(Grid, _Bg, bb(R1,C1,R2,C2), Crop, off(R1,C1)) :-
    findall(CRow,
        (between(R1, R2, R),
         nth0(R, Grid, Row),
         findall(V, (between(C1, C2, C), nth0(C, Row, V)), CRow)),
        Crop).

% gxt_object_at(+Grid, +R, +C, +BgColor, -BBox)
% Find the bounding box of the connected-color region touching cell (R,C).
% Uses the color at (R,C) as the target color.
% Returns the bbox of all cells with that color that are reachable
% via 4-connectivity flood (BFS-style using findall).
% BBox = bb(MinR,MinC,MaxR,MaxC).
gxt_object_at(Grid, R, C, _Bg, bb(MinR,MinC,MaxR,MaxC)) :-
    nth0(R, Grid, Row),
    nth0(C, Row, Color),
    length(Grid, H), H1 is H - 1,
    Grid = [GRow|_], length(GRow, W), W1 is W - 1,
% Collect all cells of the same color reachable from (R,C) via 4-flood.
    gxt_flood4_(Grid, R, C, Color, H1, W1, Visited),
    findall(RR, member(p(RR,_), Visited), Rs),
    findall(CC, member(p(_,CC), Visited), Cs),
    gxt_min_list_(Rs, MinR), gxt_max_list_(Rs, MaxR),
    gxt_min_list_(Cs, MinC), gxt_max_list_(Cs, MaxC).

% gxt_flood4_/7: BFS flood fill collecting all same-color 4-connected cells.
% Uses a worklist. Returns a list of p(R,C) visited positions.
gxt_flood4_(Grid, R0, C0, Color, MaxR, MaxC, Visited) :-
    gxt_flood4_bfs_([p(R0,C0)], [], Color, Grid, MaxR, MaxC, Visited).

gxt_flood4_bfs_([], Visited, _, _, _, _, Visited) :- !.
gxt_flood4_bfs_([p(R,C)|Queue], Seen, Color, Grid, MaxR, MaxC, Visited) :-
    (member(p(R,C), Seen) ->
        gxt_flood4_bfs_(Queue, Seen, Color, Grid, MaxR, MaxC, Visited)
    ;
        nth0(R, Grid, Row), nth0(C, Row, V),
        (V = Color ->
            NewSeen = [p(R,C)|Seen],
            findall(p(NR,NC),
                (member(DR-DC, [(-1)-0, 1-0, 0-(-1), 0-1]),
                 NR is R + DR, NC is C + DC,
                 NR >= 0, NR =< MaxR, NC >= 0, NC =< MaxC,
                 \+ member(p(NR,NC), NewSeen)),
                Nbrs),
            append(Queue, Nbrs, NewQueue),
            gxt_flood4_bfs_(NewQueue, NewSeen, Color, Grid, MaxR, MaxC, Visited)
        ;
            gxt_flood4_bfs_(Queue, Seen, Color, Grid, MaxR, MaxC, Visited)
        )
    ).

% gxt_all_colors(+Grid, +BgColor, -Colors)
% Return the sorted list of unique non-bg colors present in the grid.
gxt_all_colors(Grid, Bg, Colors) :-
    findall(V,
        (member(Row, Grid), member(V, Row), V \= Bg),
        All),
    gxt_sorted_unique_(All, Colors).

% gxt_color_count(+Grid, +Color, +BgColor, -Count)
% Count the number of cells with the given Color in the grid.
gxt_color_count(Grid, Color, _Bg, Count) :-
    findall(_, (member(Row, Grid), member(Color, Row)), Found),
    length(Found, Count).

% gxt_largest_color(+Grid, +BgColor, -Color)
% Return the non-bg color with the highest cell count. If tied, the
% first in sort order wins (deterministic).
gxt_largest_color(Grid, Bg, Color) :-
    gxt_all_colors(Grid, Bg, Colors),
    findall(Count-C,
        (member(C, Colors), gxt_color_count(Grid, C, Bg, Count)),
        Pairs),
    msort(Pairs, Sorted),
    last(Sorted, _-Color).

% gxt_smallest_color(+Grid, +BgColor, -Color)
% Return the non-bg color with the lowest cell count. If tied, the
% first in sort order wins (deterministic).
gxt_smallest_color(Grid, Bg, Color) :-
    gxt_all_colors(Grid, Bg, Colors),
    findall(Count-C,
        (member(C, Colors), gxt_color_count(Grid, C, Bg, Count)),
        Pairs),
    msort(Pairs, [_-Color|_]).

% gxt_centered_crop(+Grid, +BgColor, +H, +W, -Crop)
% Extract a subgrid of height H and width W centered on the centroid of
% all non-bg cells. The centroid is computed as the mean row and column
% of all non-bg cells (rounded to nearest integer). The crop is clamped
% to the grid boundaries if the centered window would go out of bounds.
gxt_centered_crop(Grid, Bg, CropH, CropW, Crop) :-
    gxt_nonbg_cells(Grid, Bg, Cells),
    Cells \= [],
    findall(R, member(r(R,_,_), Cells), Rs),
    findall(C, member(r(_,C,_), Cells), Cs),
    length(Rs, N),
    sumlist(Rs, SumR), sumlist(Cs, SumC),
    CR is round(SumR / N), CC is round(SumC / N),
    length(Grid, GH),
    Grid = [GRow|_], length(GRow, GW),
    R1raw is CR - CropH // 2,
    C1raw is CC - CropW // 2,
    R1 is max(0, min(R1raw, GH - CropH)),
    C1 is max(0, min(C1raw, GW - CropW)),
    R2 is R1 + CropH - 1,
    C2 is C1 + CropW - 1,
    gxt_crop_bbox(Grid, Bg, bb(R1,C1,R2,C2), Crop, _).

% gxt_row_cells(+Grid, +Row, +BgColor, -Cells)
% Return all non-bg cells in a specific 0-indexed row as r(Row,C,V) triples.
gxt_row_cells(Grid, R, Bg, Cells) :-
    nth0(R, Grid, Row),
    length(Row, W), W1 is W - 1,
    findall(r(R,C,V),
        (between(0, W1, C), nth0(C, Row, V), V \= Bg),
        Cells).

% gxt_col_cells(+Grid, +Col, +BgColor, -Cells)
% Return all non-bg cells in a specific 0-indexed column as r(R,Col,V) triples.
gxt_col_cells(Grid, C, Bg, Cells) :-
    length(Grid, H), H1 is H - 1,
    findall(r(R,C,V),
        (between(0, H1, R), nth0(R, Grid, Row), nth0(C, Row, V), V \= Bg),
        Cells).

% gxt_region_count(+Grid, +Color, +BgColor, -Count)
% Count the number of distinct 4-connected regions of the given Color.
gxt_region_count(Grid, Color, _Bg, Count) :-
    gxt_color_cells(Grid, Color, Cells),
    (Cells = [] ->
        Count = 0
    ;
        length(Grid, H), H1 is H - 1,
        Grid = [GRow|_], length(GRow, W), W1 is W - 1,
        gxt_count_regions_(Cells, Grid, Color, H1, W1, 0, Count)
    ).

% gxt_count_regions_/7: count distinct connected components by flood-removing seen cells.
gxt_count_regions_([], _, _, _, _, N, N) :- !.
gxt_count_regions_([r(R,C,_)|Rest], Grid, Color, MaxR, MaxC, Acc, Count) :-
    gxt_flood4_(Grid, R, C, Color, MaxR, MaxC, Flooded),
    findall(r(RR,CC,Color), member(p(RR,CC), Flooded), FloodedCells),
    gxt_subtract_(Rest, FloodedCells, Remaining),
    Acc1 is Acc + 1,
    gxt_count_regions_(Remaining, Grid, Color, MaxR, MaxC, Acc1, Count).

% gxt_subtract_/3: remove elements of Exclude from List.
gxt_subtract_([], _, []).
gxt_subtract_([H|T], Exclude, Result) :-
    (member(H, Exclude) ->
        gxt_subtract_(T, Exclude, Result)
    ;
        Result = [H|Rest],
        gxt_subtract_(T, Exclude, Rest)
    ).

% gxt_registry(+Grid, +BgColor, -Registry)
% Build a registry of all distinct non-bg colors and their properties.
% Registry is a list of obj(Color, Count, BBox) terms, one per unique color,
% sorted by color in msort order.
% BBox = bb(MinR,MinC,MaxR,MaxC) over all cells of that color.
gxt_registry(Grid, Bg, Registry) :-
    gxt_all_colors(Grid, Bg, Colors),
    findall(obj(Color, Count, BBox),
        (member(Color, Colors),
         gxt_color_count(Grid, Color, Bg, Count),
         gxt_color_cells(Grid, Color, Cells),
         findall(R, member(r(R,_,_), Cells), Rs),
         findall(C, member(r(_,C,_), Cells), Cs),
         gxt_min_list_(Rs, MinR), gxt_max_list_(Rs, MaxR),
         gxt_min_list_(Cs, MinC), gxt_max_list_(Cs, MaxC),
         BBox = bb(MinR,MinC,MaxR,MaxC)),
        Registry).
