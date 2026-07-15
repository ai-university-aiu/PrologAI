/*  PrologAI — Analogy Test Suite  (WP-419; converged with the grid-analogy pack)

    The union proof: the relational structure-mapping half (from co_liken) and
    the grid D4-isometry / colour-map half (from the analogy pack) both pass
    under the one converged pack's pack-qualified names.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/analogy/test/test_analogy.pl
*/

% Declare this file as a test module.
:- module(test_analogy, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the grid library used by the grid-analogy half.
:- use_module(library(grid)).
% Load the converged module under test.
:- use_module(library(analogy)).

:- begin_tests(analogy_structure).

% The distinct objects of a relation set are gathered and sorted.
test(objects) :-
    analogy:analogy_objects([rel(above, a, b), rel(above, b, c)], Objs),
    assertion(Objs == [a, b, c]).

% A stacking situation maps onto another stacking situation.
test(best_mapping_stack) :-
    Source = [rel(above, a, b), rel(above, b, c)],
    Target = [rel(above, x, y), rel(above, y, z)],
    analogy:analogy_structure_map(Source, Target, Map, Score),
    assertion(Score =:= 2),
    assertion(Map == [a-x, b-y, c-z]).

% The count of preserved relations matches the mapping's score.
test(preserved_count) :-
    Source = [rel(above, a, b), rel(above, b, c)],
    Target = [rel(above, x, y), rel(above, y, z)],
    analogy:analogy_preserved([a-x, b-y, c-z], Source, Target, C),
    assertion(C =:= 2).

% The solar-system to atom analogy maps sun->nucleus and planet->electron.
test(solar_system_to_atom) :-
    Source = [rel(orbits, planet, sun), rel(heavier, sun, planet)],
    Target = [rel(orbits, electron, nucleus), rel(heavier, nucleus, electron)],
    analogy:analogy_structure_map(Source, Target, Map, Score),
    assertion(Score =:= 2),
    assertion(analogy:analogy_map_object(Map, sun, nucleus)),
    assertion(analogy:analogy_map_object(Map, planet, electron)).

% A known rule about the source transfers to the target objects.
test(transfer_rule) :-
    Source = [rel(orbits, planet, sun), rel(heavier, sun, planet)],
    Target = [rel(orbits, electron, nucleus), rel(heavier, nucleus, electron)],
    analogy:analogy_structure_map(Source, Target, Map, _),
    % A source rule "the sun pulls the planet" transfers across the mapping.
    analogy:analogy_transfer(Map, pulls(sun, planet), Transferred),
    assertion(Transferred == pulls(nucleus, electron)).

% A target missing a relation yields a lower best score.
test(partial_match) :-
    Source = [rel(above, a, b), rel(above, b, c)],
    % Same three objects, but only one relation is "above"; the other differs.
    Target = [rel(above, x, y), rel(near, y, z)],
    analogy:analogy_structure_map(Source, Target, _, Score),
    assertion(Score =:= 1).

% An atom or number that is not an object passes through transfer unchanged.
test(transfer_passthrough) :-
    Map = [a-x],
    analogy:analogy_transfer(Map, cost(a, 5, fixed), T),
    assertion(T == cost(x, 5, fixed)).

% Close the test block.
:- end_tests(analogy_structure).

% ===========================================================================
% SECTION AC-AY-001 — SHAPE NORMALIZATION
% ===========================================================================
:- begin_tests(analogy_normalize).

% AC-AY-001-a: normalize translates top-left to (0,0).
test(normalize_basic) :-
    % Cells with top-left at (2,3).
    Cells = [r(2,3), r(2,4), r(3,3)],
    % After normalization, top-left is at (0,0).
    analogy_normalize_shape(Cells, Norm),
    % The normalized form should have these cells.
    sort([r(0,0), r(0,1), r(1,0)], Expected),
    Norm = Expected.

% AC-AY-001-b: shape_equal succeeds for same shape at different positions.
test(shape_equal_translated) :-
    % Two L-shapes at different positions.
    S1 = [r(0,0), r(1,0), r(1,1)],
    S2 = [r(3,5), r(4,5), r(4,6)],
    % They are the same shape.
    analogy_shape_equal(S1, S2).

% AC-AY-001-c: shape_size counts cells.
test(shape_size) :-
    % A 3-cell shape.
    Cells = [r(0,0), r(0,1), r(1,0)],
    analogy_shape_size(Cells, 3).

% AC-AY-001-d: shape_bbox returns correct extremes.
test(shape_bbox) :-
    % Cells spanning rows 1-3 and cols 2-4.
    Cells = [r(1,2), r(2,4), r(3,2)],
    analogy_shape_bbox(Cells, r(1,2), r(3,4)).

:- end_tests(analogy_normalize).

% ===========================================================================
% SECTION AC-AY-002 — SHAPE ISOMETRIES
% ===========================================================================
:- begin_tests(analogy_isometry).

% AC-AY-002-a: identity isometry returns normalized shape unchanged.
test(isometry_identity, nondet) :-
    % A horizontal bar.
    Cells = [r(0,0), r(0,1), r(0,2)],
    analogy_shape_isometry(Cells, identity, Norm),
    % Identity should return the sorted cells as-is (already normalized).
    sort(Cells, Sorted),
    Norm = Sorted.

% AC-AY-002-b: rot90 applied 4 times returns original shape.
test(isometry_rot90_4x, nondet) :-
    % An L-shaped cell set.
    Cells = [r(0,0), r(1,0), r(1,1)],
    analogy_normalize_shape(Cells, N0),
    analogy_shape_isometry(N0, rot90, N1),
    analogy_shape_isometry(N1, rot90, N2),
    analogy_shape_isometry(N2, rot90, N3),
    analogy_shape_isometry(N3, rot90, N4),
    % Four rotations return to the original normalized shape.
    N4 = N0.

% AC-AY-002-c: ref_h applied twice returns original shape.
test(isometry_ref_h_twice, nondet) :-
    % Any asymmetric shape.
    Cells = [r(0,0), r(0,1), r(1,0)],
    analogy_normalize_shape(Cells, N0),
    analogy_shape_isometry(N0, ref_h, N1),
    analogy_shape_isometry(N1, ref_h, N2),
    N2 = N0.

% AC-AY-002-d: ref_d1 transposes row and column.
test(isometry_ref_d1, nondet) :-
    % A horizontal bar of 3 cells at row 0.
    Cells = [r(0,0), r(0,1), r(0,2)],
    analogy_shape_isometry(Cells, ref_d1, Transposed),
    % After transpose it should be a vertical bar of 3 cells.
    sort([r(0,0), r(1,0), r(2,0)], Expected),
    Transposed = Expected.

% AC-AY-002-e: isometry_candidates finds the correct isometry.
test(isometry_candidates_rot90, nondet) :-
    % A shape and its 90-degree rotation.
    S1 = [r(0,0), r(0,1), r(0,2)],
    % Compute the 90-degree rotation.
    analogy_shape_isometry(S1, rot90, S2),
    % The candidates should include rot90.
    analogy_isometry_candidates(S1, S2, Isos),
    member(rot90, Isos).

:- end_tests(analogy_isometry).

% ===========================================================================
% SECTION AC-AY-003 — COLOR MAP INFERENCE
% ===========================================================================
:- begin_tests(analogy_color_map).

% AC-AY-003-a: infer_color_map produces correct From-To pairs.
test(infer_color_map_basic) :-
    % Input colors map to output colors.
    InColors  = [1, 2, 3],
    OutColors = [4, 5, 6],
    analogy_infer_color_map(InColors, OutColors, Map),
    % Map should contain all three substitutions.
    sort([1-4, 2-5, 3-6], Expected),
    sort(Map, SortedMap),
    SortedMap = Expected.

% AC-AY-003-b: infer_color_map omits identity pairs.
test(infer_color_map_identity_omitted) :-
    % Color 2 maps to itself; only 1->3 should appear.
    InColors  = [1, 2],
    OutColors = [3, 2],
    analogy_infer_color_map(InColors, OutColors, Map),
    % Only the non-identity pair is included.
    Map = [1-3].

% AC-AY-003-c: grid_color_map infers map from two grids.
test(grid_color_map) :-
    % A 2x2 grid where all 1s become 2s.
    G1 = [[1,0],[0,1]],
    G2 = [[2,0],[0,2]],
    analogy_grid_color_map(G1, G2, Map),
    % Map should be [1-2].
    Map = [1-2].

:- end_tests(analogy_color_map).

% ===========================================================================
% SECTION AC-AY-004 — OBJECT MATCHING
% ===========================================================================
:- begin_tests(analogy_match).

% AC-AY-004-a: match_objects finds pairs with same shape.
test(match_objects_shape, nondet) :-
    % Two input objects.
    In1 = [r(0,0), r(0,1)],
    In2 = [r(0,0), r(1,0)],
    % Two output objects (same shapes, different positions).
    Out1 = [r(2,2), r(2,3)],
    Out2 = [r(3,3), r(4,3)],
    % Find matches.
    analogy_match_objects([In1, In2], [Out1, Out2], Pairs),
    % In1 matches Out1 (both horizontal 2-cell bars).
    member(in_obj(In1)-out_obj(Out1), Pairs).

% AC-AY-004-b: object_offset computes translation vector.
test(object_offset) :-
    % Object at (0,0) to (1,2): offset is (1,2).
    Cells1 = [r(0,0), r(0,1)],
    Cells2 = [r(1,2), r(1,3)],
    analogy_object_offset(Cells1, Cells2, offset(1,2)).

:- end_tests(analogy_match).

% ===========================================================================
% SECTION AC-AY-005 — GRID ISOMETRY DETECTION
% ===========================================================================
:- begin_tests(analogy_grid_iso).

% AC-AY-005-a: identity isometry detected.
test(grid_iso_identity) :-
    % A grid is its own identity transform.
    G = [[1,2],[3,4]],
    analogy_grid_isometry(G, G, Isos),
    member(identity, Isos).

% AC-AY-005-b: rot90 detected correctly.
test(grid_iso_rot90, nondet) :-
    % A 2x2 grid and its 90-degree rotation.
    G1 = [[1,2],[3,4]],
    grid_rotate90(G1, G2),
    analogy_grid_isometry(G1, G2, Isos),
    member(rot90, Isos).

% AC-AY-005-c: apply_isometry works for all 8 isometries.
test(apply_all_isometries, nondet) :-
    % A 3x3 grid.
    G = [[1,2,3],[4,5,6],[7,8,9]],
    % All 8 isometries should apply without error.
    member(Iso, [identity, rot90, rot180, rot270, ref_h, ref_v, ref_d1, ref_d2]),
    analogy_apply_isometry(G, Iso, _G2).

% AC-AY-005-d: apply_color_map delegates to grid_color_map.
test(apply_color_map) :-
    % A grid with colors 1 and 2.
    G = [[1,2],[2,1]],
    % Apply map: 1->3, 2->4.
    analogy_apply_color_map(G, [1-3, 2-4], G2),
    G2 = [[3,4],[4,3]].

:- end_tests(analogy_grid_iso).

% ===========================================================================
% SECTION AC-AY-006 — END-TO-END SOLVE
% ===========================================================================
:- begin_tests(analogy_solve).

% AC-AY-006-a: solve with pure rot90 rule.
test(solve_rot90, nondet) :-
    % Training: input rotated 90 degrees gives output.
    G1in  = [[1,0],[0,2]],
    grid_rotate90(G1in, G1out),
    G2in  = [[0,1],[2,0]],
    grid_rotate90(G2in, G2out),
    % Training pairs.
    Train = [in(G1in)-out(G1out), in(G2in)-out(G2out)],
    % Test grid.
    GTest = [[1,2],[3,4]],
    % Expected output.
    grid_rotate90(GTest, Expected),
    % Solve.
    analogy_solve_from_examples(Train, GTest, Predicted),
    grid_equal(Predicted, Expected).

% AC-AY-006-b: solve with pure color-map rule.
test(solve_color_map, nondet) :-
    % Training: all 1s become 3s.
    G1in  = [[1,0],[0,1]],
    G1out = [[3,0],[0,3]],
    G2in  = [[1,1],[0,0]],
    G2out = [[3,3],[0,0]],
    Train = [in(G1in)-out(G1out), in(G2in)-out(G2out)],
    GTest = [[0,1],[1,0]],
    GExpected = [[0,3],[3,0]],
    analogy_solve_from_examples(Train, GTest, Predicted),
    grid_equal(Predicted, GExpected).

% AC-AY-006-c: solve with rot90 + color swap rule.
test(solve_iso_plus_color, nondet) :-
    % Training: rotate 90 CW AND swap 1->2.
    G1in = [[1,0],[0,0]],
    grid_rotate90(G1in, G1rot),
    grid_color_map(G1rot, [1-2], G1out),
    Train = [in(G1in)-out(G1out)],
    GTest = [[0,0],[1,0]],
    grid_rotate90(GTest, GTestRot),
    grid_color_map(GTestRot, [1-2], Expected),
    analogy_solve_from_examples(Train, GTest, Predicted),
    grid_equal(Predicted, Expected).

:- end_tests(analogy_solve).
