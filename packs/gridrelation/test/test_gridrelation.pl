% Test suite for gridrelation (grl_*, Layer 244).
:- use_module('../prolog/gridrelation.pl').

:- begin_tests(gridrelation).

% Canonical ob/3 terms for tests.
% ObjA: r, row 0 col 0 (single cell)
% ObjB: b, row 0 col 2 (single cell, right of ObjA, separated by 1 gap)
% ObjC: g, row 2 col 0 (single cell, below ObjA)
% ObjD: r, row 0 col 1 (single cell, directly right of ObjA = touching)
% ObjE: b, 2x2 block at rows 1-2 cols 1-2 (larger object)
% ObjF: r, row 1 col 0 (single cell, directly below ObjA = touching)
obja(ob(r, [r(0,0)], r0(0,0,0,0))).
objb(ob(b, [r(0,2)], r0(0,2,0,2))).
objc(ob(g, [r(2,0)], r0(2,0,2,0))).
objd(ob(r, [r(0,1)], r0(0,1,0,1))).
obje(ob(b, [r(1,1),r(1,2),r(2,1),r(2,2)], r0(1,1,2,2))).
objf(ob(r, [r(1,0)], r0(1,0,1,0))).

% AC-GRL-001: grl_touching: adjacent cells (horizontal) succeed.
test('AC-GRL-001: touching horizontal') :-
    obja(A), objd(D),
    grl_touching(A, D).

% AC-GRL-002: grl_touching: adjacent cells (vertical) succeed.
test('AC-GRL-002: touching vertical') :-
    obja(A), objf(F),
    grl_touching(A, F).

% AC-GRL-003: grl_touching: non-adjacent cells fail.
test('AC-GRL-003: not touching gap', [fail]) :-
    obja(A), objb(B),
    grl_touching(A, B).

% AC-GRL-004: grl_adjacent: distance-1 objects adjacent with N=1.
test('AC-GRL-004: adjacent N=1') :-
    obja(A), objd(D),
    grl_adjacent(A, D, 1).

% AC-GRL-005: grl_adjacent: gap-2 objects adjacent with N=2.
test('AC-GRL-005: adjacent N=2 gap') :-
    obja(A), objb(B),
    grl_adjacent(A, B, 2).

% AC-GRL-006: grl_adjacent: gap-2 objects not adjacent with N=1.
test('AC-GRL-006: not adjacent N=1', [fail]) :-
    obja(A), objb(B),
    grl_adjacent(A, B, 1).

% AC-GRL-007: grl_min_distance: touching objects have distance 1.
test('AC-GRL-007: min_distance touching') :-
    obja(A), objd(D),
    grl_min_distance(A, D, 1).

% AC-GRL-008: grl_min_distance: gap-1 objects have distance 2.
test('AC-GRL-008: min_distance gap1') :-
    obja(A), objb(B),
    grl_min_distance(A, B, 2).

% AC-GRL-009: grl_min_distance: diagonal objects.
test('AC-GRL-009: min_distance diagonal') :-
    obja(A), obje(E),
    % ObjA at (0,0), ObjE closest cell at (1,1): dist = 1+1 = 2
    grl_min_distance(A, E, 2).

% AC-GRL-010: grl_above: ObjA above ObjC (row 0 vs row 2).
test('AC-GRL-010: above basic') :-
    obja(A), objc(C),
    grl_above(A, C).

% AC-GRL-011: grl_above: fails when same row.
test('AC-GRL-011: above fails same row', [fail]) :-
    obja(A), objb(B),
    grl_above(A, B).

% AC-GRL-012: grl_above: fails when ObjA is below ObjB.
test('AC-GRL-012: above fails reversed', [fail]) :-
    objc(C), obja(A),
    grl_above(C, A).

% AC-GRL-013: grl_below: ObjC below ObjA.
test('AC-GRL-013: below basic') :-
    objc(C), obja(A),
    grl_below(C, A).

% AC-GRL-014: grl_below: fails when same row.
test('AC-GRL-014: below fails same row', [fail]) :-
    objb(B), obja(A),
    grl_below(B, A).

% AC-GRL-015: grl_left_of: ObjA left of ObjB.
test('AC-GRL-015: left_of basic') :-
    obja(A), objb(B),
    grl_left_of(A, B).

% AC-GRL-016: grl_left_of: fails when same column.
test('AC-GRL-016: left_of fails same col', [fail]) :-
    obja(A), objc(C),
    grl_left_of(A, C).

% AC-GRL-017: grl_right_of: ObjB right of ObjA.
test('AC-GRL-017: right_of basic') :-
    objb(B), obja(A),
    grl_right_of(B, A).

% AC-GRL-018: grl_right_of: fails when same column.
test('AC-GRL-018: right_of fails same col', [fail]) :-
    objc(C), obja(A),
    grl_right_of(C, A).

% AC-GRL-019: grl_bbox_contains: large object contains small.
test('AC-GRL-019: bbox_contains basic') :-
    BigObj = ob(x, [r(0,0),r(0,1),r(0,2),r(1,0),r(1,1),r(1,2)], r0(0,0,1,2)),
    SmallObj = ob(y, [r(0,1)], r0(0,1,0,1)),
    grl_bbox_contains(BigObj, SmallObj).

% AC-GRL-020: grl_bbox_contains: equal bbox contains itself.
test('AC-GRL-020: bbox_contains equal') :-
    obja(A),
    grl_bbox_contains(A, A).

% AC-GRL-021: grl_bbox_contains: fails when not contained.
test('AC-GRL-021: bbox_contains fails', [fail]) :-
    obja(A), obje(E),
    grl_bbox_contains(A, E).

% AC-GRL-022: grl_bbox_overlap: overlapping bboxes succeed.
test('AC-GRL-022: bbox_overlap basic') :-
    ObjP = ob(r, [r(0,0),r(1,0)], r0(0,0,1,0)),
    ObjQ = ob(b, [r(1,0),r(2,0)], r0(1,0,2,0)),
    grl_bbox_overlap(ObjP, ObjQ).

% AC-GRL-023: grl_bbox_overlap: non-overlapping bboxes fail.
test('AC-GRL-023: bbox_overlap fails', [fail]) :-
    obja(A), objc(C),
    grl_bbox_overlap(A, C).

% AC-GRL-024: grl_bbox_overlap: multi-cell objects sharing a common column.
test('AC-GRL-024: bbox_overlap shared col') :-
    ObjP = ob(r, [r(0,0),r(0,1)], r0(0,0,0,1)),
    ObjQ = ob(b, [r(0,1),r(0,2)], r0(0,1,0,2)),
    grl_bbox_overlap(ObjP, ObjQ).

% AC-GRL-025: grl_cells_overlap: disjoint cells fail.
test('AC-GRL-025: cells_overlap fails disjoint', [fail]) :-
    obja(A), objb(B),
    grl_cells_overlap(A, B).

% AC-GRL-026: grl_cells_overlap: same cell succeeds.
test('AC-GRL-026: cells_overlap same cell') :-
    O = ob(r, [r(0,0)], r0(0,0,0,0)),
    grl_cells_overlap(O, O).

% AC-GRL-027: grl_cells_overlap: shared cell in multi-cell objects.
test('AC-GRL-027: cells_overlap shared cell') :-
    ObjP = ob(r, [r(0,0),r(1,0)], r0(0,0,1,0)),
    ObjQ = ob(b, [r(1,0),r(2,0)], r0(1,0,2,0)),
    grl_cells_overlap(ObjP, ObjQ).

% AC-GRL-028: grl_same_rows: objects on same row succeed.
test('AC-GRL-028: same_rows basic') :-
    obja(A), objb(B),
    grl_same_rows(A, B).

% AC-GRL-029: grl_same_rows: objects on different non-overlapping rows fail.
test('AC-GRL-029: same_rows fails', [fail]) :-
    obja(A), objc(C),
    grl_same_rows(A, C).

% AC-GRL-030: grl_same_rows: adjacent row ranges share no rows (row 0 vs row 1).
test('AC-GRL-030: same_rows adjacent rows') :-
    obja(A), objf(F),
    % ObjA row 0-0, ObjF row 1-1 — no overlap
    \+ grl_same_rows(A, F).

% AC-GRL-031: grl_same_cols: objects in same column succeed.
test('AC-GRL-031: same_cols basic') :-
    obja(A), objc(C),
    grl_same_cols(A, C).

% AC-GRL-032: grl_same_cols: objects in different columns fail.
test('AC-GRL-032: same_cols fails', [fail]) :-
    obja(A), objb(B),
    grl_same_cols(A, B).

% AC-GRL-033: grl_same_cols: touching columns share no columns (col 0 vs col 1).
test('AC-GRL-033: same_cols adjacent cols') :-
    obja(A), objd(D),
    % ObjA col 0-0, ObjD col 1-1 — no overlap... wait
    % Actually: C0A=0, C1A=0, C0D=1, C1D=1
    % Condition: C0A =< C1D (0 =< 1 yes) and C0D =< C1A (1 =< 0 no) → fail
    \+ grl_same_cols(A, D).

% AC-GRL-034: grl_direction: B is to the right of A.
test('AC-GRL-034: direction right') :-
    obja(A), objb(B),
    grl_direction(A, B, right).

% AC-GRL-035: grl_direction: C is below A.
test('AC-GRL-035: direction below') :-
    obja(A), objc(C),
    grl_direction(A, C, below).

% AC-GRL-036: grl_direction: A is above C.
test('AC-GRL-036: direction above') :-
    objc(C), obja(A),
    grl_direction(C, A, above).

% AC-GRL-037: grl_direction: same object gives overlap.
test('AC-GRL-037: direction overlap') :-
    obja(A),
    grl_direction(A, A, overlap).

% AC-GRL-038: grl_all_relations: touching objects include touching.
test('AC-GRL-038: all_relations touching') :-
    obja(A), objd(D),
    grl_all_relations(A, D, Rels),
    memberchk(touching, Rels).

% AC-GRL-039: grl_all_relations: above objects include above and left_of.
test('AC-GRL-039: all_relations above and same col') :-
    obja(A), objc(C),
    grl_all_relations(A, C, Rels),
    memberchk(above, Rels),
    memberchk(same_cols, Rels).

% AC-GRL-040: grl_all_relations: disjoint objects include left_of and same_rows.
test('AC-GRL-040: all_relations left and same row') :-
    obja(A), objb(B),
    grl_all_relations(A, B, Rels),
    memberchk(left_of, Rels),
    memberchk(same_rows, Rels),
    \+ memberchk(touching, Rels).

% AC-GRL-041: integration - touching implies adjacent with N=1.
test('AC-GRL-041: integration touching implies adjacent') :-
    obja(A), objd(D),
    grl_touching(A, D),
    grl_adjacent(A, D, 1).

% AC-GRL-042: integration - above implies not same_rows.
test('AC-GRL-042: integration above not same_rows') :-
    obja(A), objc(C),
    grl_above(A, C),
    \+ grl_same_rows(A, C).

% AC-GRL-043: integration - direction consistent with left_of.
test('AC-GRL-043: integration direction left consistent') :-
    objb(B), obja(A),
    grl_left_of(A, B),
    grl_direction(A, B, right).

% AC-GRL-044: integration - all_relations for identical object has bbox_contains.
test('AC-GRL-044: integration self contains self') :-
    obja(A),
    grl_all_relations(A, A, Rels),
    memberchk(bbox_contains, Rels),
    memberchk(cells_overlap, Rels),
    memberchk(same_rows, Rels),
    memberchk(same_cols, Rels).

:- end_tests(gridrelation).
