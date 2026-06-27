:- use_module('../prolog/gridextract').

:- begin_tests(gridextract).

% --- gxt_nonbg_cells/3 ---

test('AC-GXT-001: gxt_nonbg_cells returns all non-bg cells') :-
    Grid = [[r,b,g],[b,b,b],[b,b,r]],
    gxt_nonbg_cells(Grid, b, Cells),
    Cells = [r(0,0,r), r(0,2,g), r(2,2,r)].

test('AC-GXT-002: gxt_nonbg_cells on all-bg grid returns empty') :-
    gxt_nonbg_cells([[b,b],[b,b]], b, []).

test('AC-GXT-003: gxt_nonbg_cells single non-bg cell') :-
    gxt_nonbg_cells([[b,r],[b,b]], b, [r(0,1,r)]).

% --- gxt_color_cells/3 ---

test('AC-GXT-004: gxt_color_cells returns all cells of given color') :-
    Grid = [[r,b],[b,r]],
    gxt_color_cells(Grid, r, [r(0,0,r), r(1,1,r)]).

test('AC-GXT-005: gxt_color_cells returns empty when color absent') :-
    gxt_color_cells([[r,g],[g,r]], b, []).

test('AC-GXT-006: gxt_color_cells single cell') :-
    gxt_color_cells([[b,g],[b,b]], g, [r(0,1,g)]).

% --- gxt_bbox/4 ---

test('AC-GXT-007: gxt_bbox correct bounding box for scattered cells') :-
    Grid = [[b,b,b],[b,r,b],[b,b,b]],
    gxt_bbox(Grid, b, bb(1,1,1,1), [r(1,1,r)]).

test('AC-GXT-008: gxt_bbox spanning rows and columns') :-
    Grid = [[r,b,b],[b,b,b],[b,b,g]],
    gxt_bbox(Grid, b, bb(0,0,2,2), _).

test('AC-GXT-009: gxt_bbox fails on all-bg grid', [fail]) :-
    gxt_bbox([[b,b],[b,b]], b, _, _).

% --- gxt_crop_bbox/5 ---

test('AC-GXT-010: gxt_crop_bbox extracts correct sub-grid') :-
    Grid = [[r,g,b],[b,y,b],[b,b,b]],
    gxt_crop_bbox(Grid, b, bb(0,0,1,1), [[r,g],[b,y]], off(0,0)).

test('AC-GXT-011: gxt_crop_bbox offset is preserved') :-
    Grid = [[b,b,b],[b,r,g],[b,b,b]],
    gxt_crop_bbox(Grid, b, bb(1,1,1,2), [[r,g]], off(1,1)).

test('AC-GXT-012: gxt_crop_bbox single cell') :-
    Grid = [[b,b,b],[b,r,b],[b,b,b]],
    gxt_crop_bbox(Grid, b, bb(1,1,1,1), [[r]], off(1,1)).

% --- gxt_object_at/5 ---

test('AC-GXT-013: gxt_object_at returns bbox of single isolated cell') :-
    Grid = [[b,b,b],[b,r,b],[b,b,b]],
    gxt_object_at(Grid, 1, 1, b, bb(1,1,1,1)).

test('AC-GXT-014: gxt_object_at returns bbox of 2-cell horizontal object') :-
    Grid = [[b,b,b],[r,r,b],[b,b,b]],
    gxt_object_at(Grid, 1, 0, b, bb(1,0,1,1)).

test('AC-GXT-015: gxt_object_at ignores same-color disconnected object') :-
    Grid = [[r,b,r],[b,b,b],[b,b,b]],
    % Starting at (0,0): only the r at (0,0) is connected (4-connectivity)
    gxt_object_at(Grid, 0, 0, b, bb(0,0,0,0)).

% --- gxt_all_colors/3 ---

test('AC-GXT-016: gxt_all_colors returns sorted unique colors') :-
    Grid = [[r,g],[b,r]],
    gxt_all_colors(Grid, b, [g,r]).

test('AC-GXT-017: gxt_all_colors returns empty for all-bg grid') :-
    gxt_all_colors([[b,b],[b,b]], b, []).

test('AC-GXT-018: gxt_all_colors single color') :-
    gxt_all_colors([[r,b],[r,r]], b, [r]).

% --- gxt_color_count/4 ---

test('AC-GXT-019: gxt_color_count counts all occurrences') :-
    gxt_color_count([[r,g],[r,r]], r, b, 3).

test('AC-GXT-020: gxt_color_count returns 0 when color absent') :-
    gxt_color_count([[r,g],[g,r]], b, b, 0).

test('AC-GXT-021: gxt_color_count single occurrence') :-
    gxt_color_count([[b,b],[b,r]], r, b, 1).

% --- gxt_largest_color/3 ---

test('AC-GXT-022: gxt_largest_color returns color with most cells') :-
    Grid = [[r,r],[r,g]],
    gxt_largest_color(Grid, b, r).

test('AC-GXT-023: gxt_largest_color with single color') :-
    gxt_largest_color([[r,r],[r,r]], b, r).

test('AC-GXT-024: gxt_largest_color among multiple colors') :-
    Grid = [[r,g,g],[b,b,b],[b,b,b]],
    gxt_largest_color(Grid, b, g).

% --- gxt_smallest_color/3 ---

test('AC-GXT-025: gxt_smallest_color returns color with fewest cells') :-
    Grid = [[r,r],[r,g]],
    gxt_smallest_color(Grid, b, g).

test('AC-GXT-026: gxt_smallest_color single color') :-
    gxt_smallest_color([[r,r],[r,r]], b, r).

test('AC-GXT-027: gxt_smallest_color among multiple colors') :-
    Grid = [[r,g,g],[b,b,b],[b,b,b]],
    gxt_smallest_color(Grid, b, r).

% --- gxt_centered_crop/5 ---

test('AC-GXT-028: gxt_centered_crop centered on single-cell object') :-
    Grid = [[b,b,b,b,b],[b,b,b,b,b],[b,b,r,b,b],[b,b,b,b,b],[b,b,b,b,b]],
    % centroid at (2,2); crop 3×3 centered: rows 1-3, cols 1-3
    gxt_centered_crop(Grid, b, 3, 3, [[b,b,b],[b,r,b],[b,b,b]]).

test('AC-GXT-029: gxt_centered_crop clamps at grid boundary') :-
    Grid = [[r,b,b],[b,b,b],[b,b,b]],
    % centroid at (0,0); crop 3×3 would go to (-1,-1); clamp to (0,0)
    gxt_centered_crop(Grid, b, 3, 3, [[r,b,b],[b,b,b],[b,b,b]]).

test('AC-GXT-030: gxt_centered_crop 1×1 crop at centroid cell') :-
    Grid = [[b,b,b],[b,r,b],[b,b,b]],
    gxt_centered_crop(Grid, b, 1, 1, [[r]]).

% --- gxt_row_cells/4 ---

test('AC-GXT-031: gxt_row_cells returns non-bg cells in row') :-
    Grid = [[r,b,g],[b,b,b]],
    gxt_row_cells(Grid, 0, b, [r(0,0,r), r(0,2,g)]).

test('AC-GXT-032: gxt_row_cells empty row returns empty') :-
    Grid = [[b,b],[r,r]],
    gxt_row_cells(Grid, 0, b, []).

test('AC-GXT-033: gxt_row_cells second row') :-
    Grid = [[b,b],[r,b]],
    gxt_row_cells(Grid, 1, b, [r(1,0,r)]).

% --- gxt_col_cells/4 ---

test('AC-GXT-034: gxt_col_cells returns non-bg cells in column') :-
    Grid = [[r,b],[b,b],[g,b]],
    gxt_col_cells(Grid, 0, b, [r(0,0,r), r(2,0,g)]).

test('AC-GXT-035: gxt_col_cells empty column returns empty') :-
    Grid = [[b,r],[b,r]],
    gxt_col_cells(Grid, 0, b, []).

test('AC-GXT-036: gxt_col_cells second column') :-
    Grid = [[b,r],[b,b]],
    gxt_col_cells(Grid, 1, b, [r(0,1,r)]).

% --- gxt_region_count/4 ---

test('AC-GXT-037: gxt_region_count single connected region') :-
    Grid = [[r,r],[r,b]],
    gxt_region_count(Grid, r, b, 1).

test('AC-GXT-038: gxt_region_count two disconnected regions') :-
    Grid = [[r,b,r],[b,b,b]],
    gxt_region_count(Grid, r, b, 2).

test('AC-GXT-039: gxt_region_count color absent returns 0') :-
    Grid = [[r,r],[r,r]],
    gxt_region_count(Grid, g, b, 0).

% --- gxt_registry/3 ---

test('AC-GXT-040: gxt_registry builds entry for each color') :-
    Grid = [[r,b],[b,g]],
    gxt_registry(Grid, b, Registry),
    Registry = [obj(g, 1, bb(1,1,1,1)), obj(r, 1, bb(0,0,0,0))].

test('AC-GXT-041: gxt_registry empty grid returns empty registry') :-
    gxt_registry([[b,b],[b,b]], b, []).

test('AC-GXT-042: gxt_registry bbox spans all cells of a color') :-
    Grid = [[r,b,r],[b,b,b],[r,b,b]],
    gxt_registry(Grid, b, [obj(r, 3, bb(0,0,2,2))]).

% --- integration tests ---

test('AC-GXT-043: nonbg_cells → bbox → crop round-trip') :-
    Grid = [[b,b,b],[b,r,g],[b,g,r]],
    gxt_bbox(Grid, b, BBox, _),
    gxt_crop_bbox(Grid, b, BBox, Crop, _),
    Crop = [[r,g],[g,r]].

test('AC-GXT-044: largest_color and smallest_color are different when counts differ') :-
    Grid = [[r,r,r],[g,b,b],[b,b,b]],
    gxt_largest_color(Grid, b, r),
    gxt_smallest_color(Grid, b, g),
    r \= g.

:- end_tests(gridextract).
