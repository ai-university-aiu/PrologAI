% Test suite for gridalign (gal_*, Layer 239).
:- use_module('../prolog/grid_align.pl').

:- begin_tests(grid_align).

% AC-GAL-001: grid_align_center_of_mass of a single non-bg cell.
test('AC-GAL-001: center_of_mass single cell') :-
    Grid = [[b,b],[b,r]],
    grid_align_center_of_mass(Grid, b, r(R,C)),
    R = 1, C = 1.

% AC-GAL-002: grid_align_center_of_mass of four corner cells.
test('AC-GAL-002: center_of_mass four corners') :-
    Grid = [[r,b,r],[b,b,b],[r,b,r]],
    grid_align_center_of_mass(Grid, b, r(R,C)),
    R = 1, C = 1.

% AC-GAL-003: grid_align_center_of_mass of a row of three cells.
test('AC-GAL-003: center_of_mass row') :-
    Grid = [[r,r,r]],
    grid_align_center_of_mass(Grid, b, r(R,C)),
    R = 0, C = 1.

% AC-GAL-004: grid_align_nonbg_bbox basic bounding box.
test('AC-GAL-004: nonbg_bbox basic') :-
    Grid = [[b,b,b],[b,r,b],[b,b,g]],
    grid_align_nonbg_bbox(Grid, b, BBox),
    BBox = r0(1,1,2,2).

% AC-GAL-005: grid_align_nonbg_bbox all-bg grid returns none.
test('AC-GAL-005: nonbg_bbox all bg') :-
    Grid = [[b,b],[b,b]],
    grid_align_nonbg_bbox(Grid, b, none).

% AC-GAL-006: grid_align_nonbg_bbox single non-bg cell.
test('AC-GAL-006: nonbg_bbox single cell') :-
    Grid = [[b,b],[r,b]],
    grid_align_nonbg_bbox(Grid, b, r0(1,0,1,0)).

% AC-GAL-007: grid_align_bbox_center of a 3x3 center cell.
test('AC-GAL-007: bbox_center 3x3') :-
    Grid = [[b,b,b],[b,r,b],[b,b,b]],
    grid_align_bbox_center(Grid, b, r(1,1)).

% AC-GAL-008: grid_align_bbox_center returns none for all-bg grid.
test('AC-GAL-008: bbox_center all bg') :-
    Grid = [[b,b],[b,b]],
    grid_align_bbox_center(Grid, b, none).

% AC-GAL-009: grid_align_translate shifts cell right by 1.
test('AC-GAL-009: translate right 1') :-
    Grid = [[r,b,b]],
    grid_align_translate(Grid, 0, 1, b, Result),
    Result = [[b,r,b]].

% AC-GAL-010: grid_align_translate shifts cell off the right edge (becomes bg).
test('AC-GAL-010: translate off right edge') :-
    Grid = [[b,b,r]],
    grid_align_translate(Grid, 0, 1, b, Result),
    Result = [[b,b,b]].

% AC-GAL-011: grid_align_translate shifts downward by 1.
test('AC-GAL-011: translate down 1') :-
    Grid = [[r,b],[b,b]],
    grid_align_translate(Grid, 1, 0, b, Result),
    Result = [[b,b],[r,b]].

% AC-GAL-012: grid_align_translate with zero offset returns grid unchanged.
test('AC-GAL-012: translate zero') :-
    Grid = [[r,g],[y,p]],
    grid_align_translate(Grid, 0, 0, b, Result),
    Result = [[r,g],[y,p]].

% AC-GAL-013: grid_align_overlap_count with two identical grids.
test('AC-GAL-013: overlap_count identical') :-
    Grid = [[r,b],[b,g]],
    grid_align_overlap_count(Grid, Grid, b, Count),
    Count = 2.

% AC-GAL-014: grid_align_overlap_count with no overlap.
test('AC-GAL-014: overlap_count none') :-
    Grid1 = [[r,b],[b,b]],
    Grid2 = [[b,b],[b,g]],
    grid_align_overlap_count(Grid1, Grid2, b, Count),
    Count = 0.

% AC-GAL-015: grid_align_overlap_count partial overlap.
test('AC-GAL-015: overlap_count partial') :-
    Grid1 = [[r,g],[b,b]],
    Grid2 = [[r,b],[b,b]],
    grid_align_overlap_count(Grid1, Grid2, b, Count),
    Count = 1.

% AC-GAL-016: grid_align_overlap_score identical grids give 1.0.
test('AC-GAL-016: overlap_score identical') :-
    Grid = [[r,b],[b,g]],
    grid_align_overlap_score(Grid, Grid, b, Score),
    Score =:= 1.0.

% AC-GAL-017: grid_align_overlap_score no overlap gives 0.0.
test('AC-GAL-017: overlap_score zero') :-
    Grid1 = [[r,b],[b,b]],
    Grid2 = [[b,b],[b,g]],
    grid_align_overlap_score(Grid1, Grid2, b, Score),
    Score =:= 0.0.

% AC-GAL-018: grid_align_overlap_score all-bg Grid1 gives 0.0.
test('AC-GAL-018: overlap_score all-bg grid1') :-
    Grid1 = [[b,b],[b,b]],
    Grid2 = [[r,g],[y,p]],
    grid_align_overlap_score(Grid1, Grid2, b, Score),
    Score =:= 0.0.

% AC-GAL-019: grid_align_iou identical grids give 1.0.
test('AC-GAL-019: iou identical') :-
    Grid = [[r,b],[b,g]],
    grid_align_iou(Grid, Grid, b, IoU),
    IoU =:= 1.0.

% AC-GAL-020: grid_align_iou no overlap gives 0.0.
test('AC-GAL-020: iou no overlap') :-
    Grid1 = [[r,b],[b,b]],
    Grid2 = [[b,b],[b,g]],
    grid_align_iou(Grid1, Grid2, b, IoU),
    IoU =:= 0.0.

% AC-GAL-021: grid_align_iou partial overlap (1 common / 2 total) = 0.5.
test('AC-GAL-021: iou partial') :-
    Grid1 = [[r,b],[b,b]],
    Grid2 = [[r,g],[b,b]],
    grid_align_iou(Grid1, Grid2, b, IoU),
    IoU =:= 0.5.

% AC-GAL-022: grid_align_find_offset finds zero offset for identical grids.
test('AC-GAL-022: find_offset identical grids') :-
    Grid = [[b,r,b],[r,b,r],[b,r,b]],
    grid_align_find_offset(Grid, Grid, b, 2, o(DR,DC)),
    DR = 0, DC = 0.

% AC-GAL-023: grid_align_find_offset finds offset of 1 right.
test('AC-GAL-023: find_offset one right') :-
    Grid1 = [[b,r,b],[b,b,b]],
    Grid2 = [[r,b,b],[b,b,b]],
    grid_align_find_offset(Grid1, Grid2, b, 2, o(DR,DC)),
    DR = 0, DC = 1.

% AC-GAL-024: grid_align_find_offset finds offset of 1 down.
test('AC-GAL-024: find_offset one down') :-
    Grid1 = [[b,b,b],[b,r,b]],
    Grid2 = [[b,r,b],[b,b,b]],
    grid_align_find_offset(Grid1, Grid2, b, 2, o(DR,DC)),
    DR = 1, DC = 0.

% AC-GAL-025: grid_align_align_centers aligns centroids.
test('AC-GAL-025: align_centers') :-
    Grid1 = [[b,b,b],[b,r,b],[b,b,b]],
    Grid2 = [[r,b,b],[b,b,b],[b,b,b]],
    grid_align_align_centers(Grid1, Grid2, b, Aligned),
    grid_align_center_of_mass(Aligned, b, r(1,1)).

% AC-GAL-026: grid_align_align_centers returns Grid2 unchanged when Grid1 has no non-bg.
test('AC-GAL-026: align_centers no-op on all-bg grid1') :-
    Grid1 = [[b,b],[b,b]],
    Grid2 = [[r,b],[b,b]],
    grid_align_align_centers(Grid1, Grid2, b, Aligned),
    Aligned = Grid2.

% AC-GAL-027: grid_align_align_bbox_centers aligns bbox centers.
test('AC-GAL-027: align_bbox_centers') :-
    Grid1 = [[b,b,b],[b,r,b],[b,b,b]],
    Grid2 = [[r,b,b],[b,b,b],[b,b,b]],
    grid_align_align_bbox_centers(Grid1, Grid2, b, Aligned),
    grid_align_bbox_center(Aligned, b, r(1,1)).

% AC-GAL-028: grid_align_nonbg_offset computes vector from centroid1 to centroid2.
test('AC-GAL-028: nonbg_offset') :-
    Grid1 = [[r,b],[b,b]],
    Grid2 = [[b,b],[b,r]],
    grid_align_nonbg_offset(Grid1, Grid2, b, o(DR,DC)),
    DR = 1, DC = 1.

% AC-GAL-029: grid_align_nonbg_offset zero offset for same grid.
test('AC-GAL-029: nonbg_offset zero') :-
    Grid = [[b,r,b],[b,b,b]],
    grid_align_nonbg_offset(Grid, Grid, b, o(0,0)).

% AC-GAL-030: grid_align_place_at places grid at origin.
test('AC-GAL-030: place_at origin') :-
    Canvas = [[b,b,b],[b,b,b],[b,b,b]],
    Grid2 = [[r,g]],
    grid_align_place_at(Canvas, Grid2, 0, 0, b, Result),
    Result = [[r,g,b],[b,b,b],[b,b,b]].

% AC-GAL-031: grid_align_place_at places grid at (1,1).
test('AC-GAL-031: place_at offset') :-
    Canvas = [[b,b,b],[b,b,b],[b,b,b]],
    Grid2 = [[r]],
    grid_align_place_at(Canvas, Grid2, 1, 1, b, Result),
    Result = [[b,b,b],[b,r,b],[b,b,b]].

% AC-GAL-032: grid_align_place_at clips out-of-bounds cells.
test('AC-GAL-032: place_at clips') :-
    Canvas = [[b,b],[b,b]],
    Grid2 = [[r,g],[y,p]],
    grid_align_place_at(Canvas, Grid2, 1, 1, b, Result),
    Result = [[b,b],[b,r]].

% AC-GAL-033: grid_align_anchor_to aligns cell (0,0) of Grid2 to (1,1) of canvas.
test('AC-GAL-033: anchor_to (0,0) to (1,1)') :-
    Canvas = [[b,b,b],[b,b,b],[b,b,b]],
    Grid2 = [[r]],
    grid_align_anchor_to(Canvas, Grid2, 0, 0, 1, 1, b, Result),
    Result = [[b,b,b],[b,r,b],[b,b,b]].

% AC-GAL-034: grid_align_anchor_to aligns cell (1,0) of Grid2 to (0,0) of canvas.
test('AC-GAL-034: anchor_to (1,0) to (0,0)') :-
    Canvas = [[b,b],[b,b],[b,b]],
    Grid2 = [[g,g],[r,r]],
    grid_align_anchor_to(Canvas, Grid2, 1, 0, 0, 0, b, Result),
    Result = [[r,r],[b,b],[b,b]].

% AC-GAL-035: grid_align_match_any_offset finds offsets with at least one overlap.
test('AC-GAL-035: match_any_offset basic') :-
    Grid1 = [[r,b,b],[b,b,b]],
    Grid2 = [[b,b,r],[b,b,b]],
    grid_align_match_any_offset(Grid1, Grid2, b, Offsets),
    member(o(0,-2), Offsets).

% AC-GAL-036: grid_align_match_any_offset empty when no non-bg overlap possible.
test('AC-GAL-036: match_any_offset empty') :-
    Grid1 = [[r,b],[b,b]],
    Grid2 = [[b,b],[b,b]],
    grid_align_match_any_offset(Grid1, Grid2, b, Offsets),
    Offsets = [].

% AC-GAL-037: grid_align_translate negative offset (shift left).
test('AC-GAL-037: translate left 1') :-
    Grid = [[b,r,b]],
    grid_align_translate(Grid, 0, -1, b, Result),
    Result = [[r,b,b]].

% AC-GAL-038: grid_align_translate diagonal shift (1,1).
test('AC-GAL-038: translate diagonal') :-
    Grid = [[r,b,b],[b,b,b],[b,b,b]],
    grid_align_translate(Grid, 1, 1, b, Result),
    Result = [[b,b,b],[b,r,b],[b,b,b]].

% AC-GAL-039: grid_align_center_of_mass with all cells non-bg.
test('AC-GAL-039: center_of_mass all cells') :-
    Grid = [[r,g],[y,p]],
    grid_align_center_of_mass(Grid, b, r(R,C)),
    R = 0, C = 0.

% AC-GAL-040: grid_align_iou all-bg grids give 0.0.
test('AC-GAL-040: iou all bg') :-
    Grid1 = [[b,b],[b,b]],
    Grid2 = [[b,b],[b,b]],
    grid_align_iou(Grid1, Grid2, b, IoU),
    IoU =:= 0.0.

% AC-GAL-041: grid_align_overlap_count same-position non-bg cells with different colors.
test('AC-GAL-041: overlap_count different colors same pos') :-
    Grid1 = [[r,b],[b,b]],
    Grid2 = [[g,b],[b,b]],
    grid_align_overlap_count(Grid1, Grid2, b, Count),
    Count = 1.

% AC-GAL-042: grid_align_nonbg_bbox for a full non-bg grid.
test('AC-GAL-042: nonbg_bbox full grid') :-
    Grid = [[r,g],[y,p]],
    grid_align_nonbg_bbox(Grid, b, r0(0,0,1,1)).

% AC-GAL-043: integration - translate then overlap_count equals 1.
test('AC-GAL-043: integration translate and overlap') :-
    Grid1 = [[b,r,b],[b,b,b]],
    Grid2 = [[r,b,b],[b,b,b]],
    grid_align_translate(Grid2, 0, 1, b, Translated),
    grid_align_overlap_count(Grid1, Translated, b, Count),
    Count = 1.

% AC-GAL-044: integration - place_at then overlap_count.
test('AC-GAL-044: integration place_at and overlap') :-
    Canvas = [[b,b,b],[b,b,b],[b,b,b]],
    Patch = [[r]],
    grid_align_place_at(Canvas, Patch, 1, 1, b, Placed),
    Ref = [[b,b,b],[b,r,b],[b,b,b]],
    grid_align_overlap_count(Placed, Ref, b, Count),
    Count = 1.

:- end_tests(grid_align).
