% PLUnit tests for the measure pack (ms_* predicates).
:- use_module(library(plunit)).
:- use_module(library(measure)).

% Helper regions.
% Single cell.
single_cell([r(2,3)]).
% Horizontal line of 3.
hline([r(1,0), r(1,1), r(1,2)]).
% Vertical line of 3.
vline([r(0,1), r(1,1), r(2,1)]).
% 2x2 filled square.
square2([[0,1],[0,1]]).
square2_region([r(0,0), r(0,1), r(1,0), r(1,1)]).
% L-shape: 3 cells.
lshape([r(0,0), r(1,0), r(1,1)]).
% 3x3 filled square region (used for interior/border tests).
sq3([r(0,0),r(0,1),r(0,2),r(1,0),r(1,1),r(1,2),r(2,0),r(2,1),r(2,2)]).

:- begin_tests(measure_area).

test(area_single) :-
    single_cell(R), ms_area(R, N), N =:= 1.

test(area_hline) :-
    hline(R), ms_area(R, N), N =:= 3.

test(area_square) :-
    square2_region(R), ms_area(R, N), N =:= 4.

test(area_lshape) :-
    lshape(R), ms_area(R, N), N =:= 3.

:- end_tests(measure_area).

:- begin_tests(measure_bbox).

test(bbox_single) :-
    single_cell(R), ms_bbox(R, bbox(2,3,2,3)).

test(bbox_hline) :-
    hline(R), ms_bbox(R, bbox(1,0,1,2)).

test(bbox_vline) :-
    vline(R), ms_bbox(R, bbox(0,1,2,1)).

test(bbox_square) :-
    square2_region(R), ms_bbox(R, bbox(0,0,1,1)).

test(bbox_lshape) :-
    lshape(R), ms_bbox(R, bbox(0,0,1,1)).

:- end_tests(measure_bbox).

:- begin_tests(measure_bbox_size).

test(bbox_size_single) :-
    single_cell(R), ms_bbox_size(R, W, H), W =:= 1, H =:= 1.

test(bbox_size_hline) :-
    hline(R), ms_bbox_size(R, W, H), W =:= 3, H =:= 1.

test(bbox_size_vline) :-
    vline(R), ms_bbox_size(R, W, H), W =:= 1, H =:= 3.

test(bbox_size_square) :-
    square2_region(R), ms_bbox_size(R, W, H), W =:= 2, H =:= 2.

:- end_tests(measure_bbox_size).

:- begin_tests(measure_perimeter).

test(perimeter_single) :-
    single_cell(R), ms_perimeter(R, P), P =:= 4.

test(perimeter_hline) :-
    % [r(1,0), r(1,1), r(1,2)]: each end has 3 exposed, middle has 2.
    hline(R), ms_perimeter(R, P), P =:= 8.

test(perimeter_square2) :-
    % 2x2 square: 4 cells each with 2 exposed edges = 8.
    square2_region(R), ms_perimeter(R, P), P =:= 8.

test(perimeter_sq3) :-
    % 3x3 square: interior cell (1,1) has 0 exposed; 8 border cells have 1-3 each.
    sq3(R), ms_perimeter(R, P), P =:= 12.

:- end_tests(measure_perimeter).

:- begin_tests(measure_diameter).

test(diameter_single) :-
    single_cell(R), ms_diameter(R, D), D =:= 0.

test(diameter_hline) :-
    % hline spans (1,0) to (1,2): max distance = 2.
    hline(R), ms_diameter(R, D), D =:= 2.

test(diameter_square2) :-
    % 2x2: max distance between corners = (0,0) to (1,1) = 2.
    square2_region(R), ms_diameter(R, D), D =:= 2.

test(diameter_vline) :-
    % vline (0,1) to (2,1): max = 2.
    vline(R), ms_diameter(R, D), D =:= 2.

:- end_tests(measure_diameter).

:- begin_tests(measure_extent).

test(extent_single) :-
    single_cell(R), ms_extent(R, N, D), N =:= 1, D =:= 1.

test(extent_hline) :-
    % area=3, bbox=3x1=3; extent = 3/3 = 1.
    hline(R), ms_extent(R, N, D), N =:= 3, D =:= 3.

test(extent_lshape) :-
    % area=3, bbox=2x2=4; extent = 3/4.
    lshape(R), ms_extent(R, N, D), N =:= 3, D =:= 4.

test(extent_square) :-
    % area=4, bbox=2x2=4; extent = 4/4 = 1.
    square2_region(R), ms_extent(R, N, D), N =:= 4, D =:= 4.

:- end_tests(measure_extent).

:- begin_tests(measure_aspect).

test(aspect_square) :-
    square2_region(R), ms_aspect(R, N, D), N =:= 2, D =:= 2.

test(aspect_hline) :-
    % W=3, H=1: max=3, min=1.
    hline(R), ms_aspect(R, N, D), N =:= 3, D =:= 1.

test(aspect_vline) :-
    % W=1, H=3: max=3, min=1.
    vline(R), ms_aspect(R, N, D), N =:= 3, D =:= 1.

test(aspect_single) :-
    single_cell(R), ms_aspect(R, N, D), N =:= 1, D =:= 1.

:- end_tests(measure_aspect).

:- begin_tests(measure_row_span).

test(row_span_single) :-
    single_cell(R), ms_row_span(R, S), S =:= 1.

test(row_span_hline) :-
    hline(R), ms_row_span(R, S), S =:= 1.

test(row_span_vline) :-
    vline(R), ms_row_span(R, S), S =:= 3.

test(row_span_lshape) :-
    lshape(R), ms_row_span(R, S), S =:= 2.

:- end_tests(measure_row_span).

:- begin_tests(measure_col_span).

test(col_span_single) :-
    single_cell(R), ms_col_span(R, S), S =:= 1.

test(col_span_hline) :-
    hline(R), ms_col_span(R, S), S =:= 3.

test(col_span_vline) :-
    vline(R), ms_col_span(R, S), S =:= 1.

test(col_span_lshape) :-
    lshape(R), ms_col_span(R, S), S =:= 2.

:- end_tests(measure_col_span).

:- begin_tests(measure_centroid).

test(centroid_single) :-
    single_cell(R), ms_centroid(R, AvgR, AvgC), AvgR =:= 2, AvgC =:= 3.

test(centroid_hline) :-
    % hline: rows all 1, cols 0,1,2 -> avg col = 1.
    hline(R), ms_centroid(R, AR, AC), AR =:= 1, AC =:= 1.

test(centroid_square2) :-
    % 2x2: rows 0,0,1,1 = avg 0; cols 0,1,0,1 = avg 0.
    square2_region(R), ms_centroid(R, AR, AC), AR =:= 0, AC =:= 0.

test(centroid_vline) :-
    % vline: rows 0,1,2 -> avg 1; col always 1.
    vline(R), ms_centroid(R, AR, AC), AR =:= 1, AC =:= 1.

:- end_tests(measure_centroid).

:- begin_tests(measure_radius).

test(radius_single) :-
    single_cell(R), ms_radius(R, Rad), Rad =:= 0.

test(radius_hline) :-
    % centroid = (1,1); Chebyshev dist to (1,0) or (1,2) = 1.
    hline(R), ms_radius(R, Rad), Rad =:= 1.

test(radius_vline) :-
    % centroid = (1,1); dist to (0,1) or (2,1) = 1.
    vline(R), ms_radius(R, Rad), Rad =:= 1.

test(radius_square2) :-
    % centroid = (0,0); dist to (1,1) = max(1,1) = 1.
    square2_region(R), ms_radius(R, Rad), Rad =:= 1.

:- end_tests(measure_radius).

:- begin_tests(measure_interior).

test(interior_single) :-
    % Single cell has no neighbors -> 0 interior.
    single_cell(R), ms_interior_count(R, N), N =:= 0.

test(interior_hline) :-
    % Middle cell has left+right neighbor in region but not top/bottom -> 0 interior.
    hline(R), ms_interior_count(R, N), N =:= 0.

test(interior_sq3) :-
    % 3x3 square: only center cell (1,1) has all 4 neighbors in region.
    sq3(R), ms_interior_count(R, N), N =:= 1.

test(interior_square2) :-
    % 2x2 square: no cell has all 4 neighbors (edge cells at most have 2).
    square2_region(R), ms_interior_count(R, N), N =:= 0.

:- end_tests(measure_interior).

:- begin_tests(measure_border).

test(border_single) :-
    single_cell(R), ms_border_count(R, N), N =:= 1.

test(border_hline) :-
    hline(R), ms_border_count(R, N), N =:= 3.

test(border_sq3) :-
    % 3x3: 8 border cells, 1 interior.
    sq3(R), ms_border_count(R, N), N =:= 8.

test(border_interior_sum) :-
    % border + interior = area.
    sq3(R), ms_area(R, A), ms_border_count(R, B), ms_interior_count(R, I),
    A =:= B + I.

:- end_tests(measure_border).

:- begin_tests(measure_color_count).

test(color_count_one) :-
    ms_color_count([[0,0],[0,0]], N), N =:= 1.

test(color_count_two) :-
    ms_color_count([[0,1],[0,1]], N), N =:= 2.

test(color_count_all_different) :-
    ms_color_count([[1,2],[3,4]], N), N =:= 4.

test(color_count_arc) :-
    ms_color_count([[0,1,2],[3,4,5],[6,7,8]], N), N =:= 9.

:- end_tests(measure_color_count).
