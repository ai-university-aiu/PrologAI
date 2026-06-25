/*  PrologAI — ARC-AGI Structural Analogy and Transformation Inference  (PR 57)

    Provides the analogy reasoning layer for ARC-AGI solving.  Given training
    pairs of (InputGrid, OutputGrid), this pack infers the transformation rule
    that maps inputs to outputs and applies it to test inputs.

    Key concepts:
    - Shape: a normalized set of r(R,C) cells with top-left at (0,0), sorted.
    - Isometry: one of 8 rigid motions of the D4 group (4 rotations + 4 reflections).
    - Color map: a permutation of color integers, expressed as a From-To pair list.
    - Named transform: an atom or compound describing one transformation step.

    Exported predicates:

    ay_normalize_shape/2       +Cells, -NormCells
    ay_shape_equal/2           +Cells1, +Cells2
    ay_shape_size/2            +Cells, -N
    ay_shape_bbox/3            +Cells, -TopLeft, -BottomRight
    ay_shape_isometry/3        +Cells, +Isometry, -Cells2
    ay_isometry_candidates/3   +Shape1, +Shape2, -Isometries
    ay_infer_color_map/3       +InColors, +OutColors, -Map
    ay_match_objects/3         +InObjects, +OutObjects, -Pairs
    ay_object_offset/3         +Cells1, +Cells2, -offset(DR, DC)
    ay_grid_isometry/3         +Grid1, +Grid2, -Isometries
    ay_grid_color_map/3        +Grid1, +Grid2, -Map
    ay_examples_isometry/3     +Pairs, -Isometry, -ColorMap
    ay_apply_isometry/3        +Grid, +Isometry, -Grid2
    ay_apply_color_map/3       +Grid, +Map, -Grid2
    ay_solve_from_examples/3   +TrainPairs, +TestGrid, -OutputGrid
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(analogy, [
    % ay_normalize_shape/2: translate a cell set so its top-left corner is at (0,0).
    ay_normalize_shape/2,
    % ay_shape_equal/2: succeed when two cell sets have the same normalized shape.
    ay_shape_equal/2,
    % ay_shape_size/2: number of cells in a shape.
    ay_shape_size/2,
    % ay_shape_bbox/3: bounding box of a cell set.
    ay_shape_bbox/3,
    % ay_shape_isometry/3: apply a named D4 isometry to a shape.
    ay_shape_isometry/3,
    % ay_isometry_candidates/3: find isometries mapping Shape1 to Shape2.
    ay_isometry_candidates/3,
    % ay_infer_color_map/3: infer color substitution from paired color lists.
    ay_infer_color_map/3,
    % ay_match_objects/3: match input objects to output objects by shape.
    ay_match_objects/3,
    % ay_object_offset/3: translation offset from one cell set to another.
    ay_object_offset/3,
    % ay_grid_isometry/3: find D4 isometries that map Grid1 to Grid2.
    ay_grid_isometry/3,
    % ay_grid_color_map/3: infer color map from Grid1 to Grid2.
    ay_grid_color_map/3,
    % ay_examples_isometry/3: find isometry + color map consistent with all training pairs.
    ay_examples_isometry/3,
    % ay_apply_isometry/3: apply a named D4 isometry to a grid.
    ay_apply_isometry/3,
    % ay_apply_color_map/3: apply a color map to a grid.
    ay_apply_color_map/3,
    % ay_solve_from_examples/3: infer and apply rule from training pairs to a test grid.
    ay_solve_from_examples/3
]).

% Import list predicates needed throughout this module.
:- use_module(library(lists),  [member/2, nth0/3,
                                 flatten/2, numlist/3, min_list/2, max_list/2,
                                 list_to_set/2, append/3]).
% Import higher-order predicates.
:- use_module(library(apply),  [maplist/2, maplist/3, foldl/4]).
% Import the grid pack for grid-level operations.
:- use_module(library(grid)).

% ===========================================================================
% SECTION 1 — SHAPE NORMALIZATION
% ===========================================================================

% ay_normalize_shape(+Cells, -NormCells): translate so top-left is at (0,0).
% NormCells is sorted to provide a canonical form for comparison.
ay_normalize_shape(Cells, NormCells) :-
    % Collect row indices to find the minimum row.
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    % Compute the minimum row and column.
    min_list(Rs, MinR),
    min_list(Cs, MinC),
    % Translate every cell by (-MinR, -MinC).
    maplist([r(R,C), r(NR,NC)]>>(NR is R - MinR, NC is C - MinC), Cells, Shifted),
    % Sort to get a canonical representation.
    sort(Shifted, NormCells).

% ay_shape_equal(+Cells1, +Cells2): succeed when both cell sets have the same shape.
ay_shape_equal(Cells1, Cells2) :-
    % Normalize both shapes and compare.
    ay_normalize_shape(Cells1, N1),
    ay_normalize_shape(Cells2, N2),
    N1 = N2.

% ay_shape_size(+Cells, -N): N is the number of cells in the shape.
ay_shape_size(Cells, N) :-
    % Length of the cell list is the size.
    length(Cells, N).

% ay_shape_bbox(+Cells, -TopLeft, -BottomRight): bounding box of a cell set.
ay_shape_bbox(Cells, r(MinR,MinC), r(MaxR,MaxC)) :-
    % Collect row and column values.
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    % Compute extremes.
    min_list(Rs, MinR),
    max_list(Rs, MaxR),
    min_list(Cs, MinC),
    max_list(Cs, MaxC).

% ===========================================================================
% SECTION 2 — SHAPE ISOMETRIES (D4 DIHEDRAL GROUP)
% ===========================================================================

% D4 isometry names: identity, rot90, rot180, rot270, ref_h, ref_v, ref_d1, ref_d2.

% ay_shape_isometry(+Cells, +Iso, -Cells2): apply isometry Iso to a cell set.
% Cells is first normalized; the result is also normalized.
ay_shape_isometry(Cells, identity, Cells2) :-
    % Identity: normalize and return.
    ay_normalize_shape(Cells, Cells2).
ay_shape_isometry(Cells, rot90, Cells2) :-
    % 90 CW: (R, C) -> (C, MaxR - R) where MaxR is the bounding box height - 1.
    ay_shape_bbox(Cells, _, r(MaxR,_)),
    maplist([r(R,C), r(C, NR)]>>(NR is MaxR - R), Cells, Rotated),
    ay_normalize_shape(Rotated, Cells2).
ay_shape_isometry(Cells, rot180, Cells2) :-
    % 180: apply rot90 twice.
    ay_shape_isometry(Cells, rot90, Mid),
    ay_shape_isometry(Mid, rot90, Cells2).
ay_shape_isometry(Cells, rot270, Cells2) :-
    % 270 CW: apply rot90 three times.
    ay_shape_isometry(Cells, rot90, M1),
    ay_shape_isometry(M1, rot90, M2),
    ay_shape_isometry(M2, rot90, Cells2).
ay_shape_isometry(Cells, ref_h, Cells2) :-
    % Reflect across horizontal axis: (R, C) -> (MaxR - R, C).
    ay_shape_bbox(Cells, _, r(MaxR,_)),
    maplist([r(R,C), r(NR,C)]>>(NR is MaxR - R), Cells, Reflected),
    ay_normalize_shape(Reflected, Cells2).
ay_shape_isometry(Cells, ref_v, Cells2) :-
    % Reflect across vertical axis: (R, C) -> (R, MaxC - C).
    ay_shape_bbox(Cells, _, r(_,MaxC)),
    maplist([r(R,C), r(R,NC)]>>(NC is MaxC - C), Cells, Reflected),
    ay_normalize_shape(Reflected, Cells2).
ay_shape_isometry(Cells, ref_d1, Cells2) :-
    % Transpose (main diagonal): (R, C) -> (C, R).
    maplist([r(R,C), r(C,R)]>>(true), Cells, Transposed),
    ay_normalize_shape(Transposed, Cells2).
ay_shape_isometry(Cells, ref_d2, Cells2) :-
    % Anti-diagonal: rotate 90 then transpose.
    ay_shape_isometry(Cells, rot90, Mid),
    ay_shape_isometry(Mid, ref_d1, Cells2).

% ay_isometry_candidates(+Shape1, +Shape2, -Isos): list of D4 isometries mapping Shape1 to Shape2.
ay_isometry_candidates(Shape1, Shape2, Isos) :-
    % Normalize Shape2 once for efficient repeated comparison.
    ay_normalize_shape(Shape2, N2),
    % Try all 8 isometries.
    findall(Iso, (
        member(Iso, [identity, rot90, rot180, rot270, ref_h, ref_v, ref_d1, ref_d2]),
        ay_shape_isometry(Shape1, Iso, Transformed),
        Transformed = N2
    ), Isos).

% ===========================================================================
% SECTION 3 — COLOR MAP INFERENCE
% ===========================================================================

% ay_infer_color_map(+InColors, +OutColors, -Map): infer From-To color pairs.
% InColors and OutColors are parallel lists (same length).
% Pairs where In == Out are omitted (identity mappings are not recorded).
ay_infer_color_map(InColors, OutColors, Map) :-
    % Pair each input color with its output color.
    maplist([I, O, I-O]>>(true), InColors, OutColors, AllPairs),
    % Remove identity pairs (where color does not change).
    findall(Pair, (member(Pair, AllPairs), Pair = F-T, F \= T), UniqueMap),
    % Remove duplicate pairs.
    list_to_set(UniqueMap, Map).

% ay_grid_color_map(+Grid1, +Grid2, -Map): infer color map from two same-size grids.
ay_grid_color_map(Grid1, Grid2, Map) :-
    % Flatten both grids.
    flatten(Grid1, Flat1),
    flatten(Grid2, Flat2),
    % Infer color map from parallel cell lists.
    ay_infer_color_map(Flat1, Flat2, Map).

% ===========================================================================
% SECTION 4 — OBJECT MATCHING
% ===========================================================================

% ay_match_objects(+InObjects, +OutObjects, -Pairs): match objects by size and shape.
% Pairs is a list of in_obj(Cells)-out_obj(Cells) correspondences.
% Only unambiguous 1-to-1 matches by normalized shape are included.
ay_match_objects(InObjects, OutObjects, Pairs) :-
    % For each input object, find any output object with the same normalized shape.
    findall(in_obj(In)-out_obj(Out), (
        member(In, InObjects),
        member(Out, OutObjects),
        ay_shape_equal(In, Out)
    ), Pairs).

% ay_object_offset(+Cells1, +Cells2, -offset(DR, DC)): translation offset.
% Computes the vector from the top-left of Cells1 to the top-left of Cells2.
ay_object_offset(Cells1, Cells2, offset(DR,DC)) :-
    % Get bounding box top-left corners.
    ay_shape_bbox(Cells1, r(MinR1,MinC1), _),
    ay_shape_bbox(Cells2, r(MinR2,MinC2), _),
    % The offset is the difference.
    DR is MinR2 - MinR1,
    DC is MinC2 - MinC1.

% ===========================================================================
% SECTION 5 — GRID-LEVEL ISOMETRY DETECTION
% ===========================================================================

% ay_grid_isometry(+Grid1, +Grid2, -Isos): find D4 isometries mapping Grid1 to Grid2.
ay_grid_isometry(Grid1, Grid2, Isos) :-
    % Try all 8 D4 isometries.
    findall(Iso, (
        member(Iso, [identity, rot90, rot180, rot270, ref_h, ref_v, ref_d1, ref_d2]),
        ay_apply_isometry(Grid1, Iso, Grid1Transformed),
        gd_equal(Grid1Transformed, Grid2)
    ), Isos).

% ay_apply_isometry(+Grid, +Iso, -Grid2): apply a named D4 isometry to a grid.
ay_apply_isometry(Grid, identity, Grid).
ay_apply_isometry(Grid, rot90,   Grid2) :- gd_rotate90(Grid, Grid2).
ay_apply_isometry(Grid, rot180,  Grid2) :- gd_rotate180(Grid, Grid2).
ay_apply_isometry(Grid, rot270,  Grid2) :- gd_rotate270(Grid, Grid2).
ay_apply_isometry(Grid, ref_h,   Grid2) :- gd_reflect_h(Grid, Grid2).
ay_apply_isometry(Grid, ref_v,   Grid2) :- gd_reflect_v(Grid, Grid2).
ay_apply_isometry(Grid, ref_d1,  Grid2) :- gd_reflect_d1(Grid, Grid2).
ay_apply_isometry(Grid, ref_d2,  Grid2) :- gd_reflect_d2(Grid, Grid2).

% ay_apply_color_map(+Grid, +Map, -Grid2): apply a From-To color map to a grid.
ay_apply_color_map(Grid, Map, Grid2) :-
    % Delegate to gd_color_map for the actual substitution.
    gd_color_map(Grid, Map, Grid2).

% ===========================================================================
% SECTION 6 — CROSS-EXAMPLE CONSISTENCY
% ===========================================================================

% ay_examples_isometry(+Pairs, -Iso, -ColorMap): find isometry and color map
% consistent with ALL (InputGrid, OutputGrid) training pairs.
% Pairs is a list of in(InputGrid)-out(OutputGrid) terms.
% Iso is one of the 8 D4 atoms; ColorMap is a list of From-To pairs (may be []).
ay_examples_isometry(Pairs, Iso, ColorMap) :-
    % Collect (Input, Output) pairs as two separate lists.
    pairs_to_lists(Pairs, InGrids, OutGrids),
    % Try each D4 isometry in order.
    member(Iso, [identity, rot90, rot180, rot270, ref_h, ref_v, ref_d1, ref_d2]),
    % Apply the isometry to the first input grid to obtain Trans1.
    InGrids = [In1|_],
    OutGrids = [Out1|_],
    ay_apply_isometry(In1, Iso, Trans1),
    % Infer the color map from the first pair after isometry.
    ay_grid_color_map(Trans1, Out1, ColorMap),
    % Verify that every training pair is consistent with Iso + ColorMap.
    maplist(ay_verify_pair(Iso, ColorMap), InGrids, OutGrids).

% ay_verify_pair(+Iso, +ColorMap, +InGrid, +OutGrid): verify one training pair.
% Uses a named predicate to give TGrid and Predicted their own fresh local variables
% on each call, avoiding the variable-sharing problem that occurs with YALL lambdas.
ay_verify_pair(Iso, ColorMap, InGrid, OutGrid) :-
    % Apply the isometry to the input grid.
    ay_apply_isometry(InGrid, Iso, TGrid),
    % Apply the color map to the isometry result.
    ay_apply_color_map(TGrid, ColorMap, Predicted),
    % Check that the prediction matches the expected output.
    gd_equal(Predicted, OutGrid).

% pairs_to_lists(+Pairs, -Ins, -Outs): split in(I)-out(O) list into two lists.
pairs_to_lists([], [], []).
pairs_to_lists([in(I)-out(O)|Rest], [I|Is], [O|Os]) :-
    pairs_to_lists(Rest, Is, Os).

% ===========================================================================
% SECTION 7 — END-TO-END SOLVE
% ===========================================================================

% ay_solve_from_examples(+TrainPairs, +TestGrid, -OutputGrid): infer and apply rule.
% TrainPairs is a list of in(InputGrid)-out(OutputGrid) terms.
% Tries to find a consistent isometry + color map; applies it to TestGrid.
% Fails gracefully if no consistent isometry is found.
ay_solve_from_examples(TrainPairs, TestGrid, OutputGrid) :-
    % Find a transformation consistent with all training pairs.
    ay_examples_isometry(TrainPairs, Iso, ColorMap),
    % Apply the isometry to the test grid.
    ay_apply_isometry(TestGrid, Iso, IsoGrid),
    % Apply the color map (if any) to the isometry result.
    ay_apply_color_map(IsoGrid, ColorMap, OutputGrid).
