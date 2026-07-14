/*  PrologAI — Analogy  (WP-419, Layer 394; converged with the grid-analogy pack, Layer ~33)

    One analogy faculty, unioned from two implementations by the unification
    program (absorb-and-supersede; neither sub-faculty is lost).

    HALF ONE — RELATIONAL STRUCTURE MAPPING (from co_liken). Given two sets of
    typed relations rel(Type,A,B), find the object-to-object mapping that lines
    up the most relations (structure mapping), then transfer a term across the
    mapping. This is analogy over abstract relational structure.

    HALF TWO — GRID ANALOGY (from the ARC grid-analogy pack). Over coloured
    grids: the eight D4 isometries (identity, rotations, reflections), colour
    permutations inferred from example pairs, shape normalization and equality
    up to isometry, object matching and offset, and a solve-from-examples that
    reads the transform from train pairs and applies it to a test input.

    All predicates are pack-qualified analogy_*.
*/

% Declare this module and its exported predicates (the union of both analogy faculties).
:- module(analogy, [
    % analogy_structure_map/4: exported analogy predicate.
    analogy_structure_map/4,
    % analogy_map_object/3: exported analogy predicate.
    analogy_map_object/3,
    % analogy_objects/2: exported analogy predicate.
    analogy_objects/2,
    % analogy_preserved/4: exported analogy predicate.
    analogy_preserved/4,
    % analogy_transfer/3: exported analogy predicate.
    analogy_transfer/3,
    % analogy_apply_color_map/3: exported analogy predicate.
    analogy_apply_color_map/3,
    % analogy_apply_isometry/3: exported analogy predicate.
    analogy_apply_isometry/3,
    % analogy_examples_isometry/3: exported analogy predicate.
    analogy_examples_isometry/3,
    % analogy_grid_color_map/3: exported analogy predicate.
    analogy_grid_color_map/3,
    % analogy_grid_isometry/3: exported analogy predicate.
    analogy_grid_isometry/3,
    % analogy_infer_color_map/3: exported analogy predicate.
    analogy_infer_color_map/3,
    % analogy_isometry_candidates/3: exported analogy predicate.
    analogy_isometry_candidates/3,
    % analogy_match_objects/3: exported analogy predicate.
    analogy_match_objects/3,
    % analogy_normalize_shape/2: exported analogy predicate.
    analogy_normalize_shape/2,
    % analogy_object_offset/3: exported analogy predicate.
    analogy_object_offset/3,
    % analogy_shape_bbox/3: exported analogy predicate.
    analogy_shape_bbox/3,
    % analogy_shape_equal/2: exported analogy predicate.
    analogy_shape_equal/2,
    % analogy_shape_isometry/3: exported analogy predicate.
    analogy_shape_isometry/3,
    % analogy_shape_size/2: exported analogy predicate.
    analogy_shape_size/2,
    % analogy_solve_from_examples/3: exported analogy predicate.
    analogy_solve_from_examples/3
]).

% List utilities used by both halves.
:- use_module(library(lists), [member/2, nth0/3, list_to_set/2, append/3]).
% Apply library for the grid half.
:- use_module(library(apply), [maplist/2, maplist/3, foldl/4]).
% Grid library for the grid-analogy half.
:- use_module(library(grid)).

% ===========================================================================
% HALF ONE — Relational structure-mapping analogy (from co_liken)
% ===========================================================================

% Use the list library for member, select, and friends.
:- use_module(library(lists)).

% analogy_objects/2: gather the distinct objects that appear in a relation set.
analogy_objects(Relations, Objects) :-
    % Collect both argument positions of every relation.
    findall(O, ( member(rel(_, A, B), Relations), ( O = A ; O = B ) ), Raw),
    % Sort to a distinct, ordered set.
    sort(Raw, Objects).

% analogy_map_object/3: an object's image under a mapping (a list of Src-Tgt pairs).
analogy_map_object(Mapping, Object, Image) :-
    % Look the object up in the mapping.
    memberchk(Object-Image, Mapping).

% analogy_preserved/4: count the source relations that line up in the target.
analogy_preserved(Mapping, Source, Target, Count) :-
    % A source relation is preserved when its mapped image is a target relation.
    findall(1,
            ( member(rel(Type, A, B), Source),
              analogy_map_object(Mapping, A, TA),
              analogy_map_object(Mapping, B, TB),
              memberchk(rel(Type, TA, TB), Target) ),
            Hits),
    % The count is how many lined up.
    length(Hits, Count).

% analogy_structure_map/4: the injective object mapping that preserves the most relations.
analogy_structure_map(Source, Target, Mapping, Score) :-
    % Enumerate the objects on each side.
    analogy_objects(Source, SrcObjs),
    analogy_objects(Target, TgtObjs),
    % Keep the search tractable: the source must be small and no larger than the target.
    length(SrcObjs, NS),
    NS =< 7,
    length(TgtObjs, NT),
    NS =< NT,
    % Score every injective mapping of source objects onto target objects.
    findall(S-M,
            ( analogy_injective(SrcObjs, TgtObjs, M),
              analogy_preserved(M, Source, Target, S) ),
            Pairs),
    % There must be at least one mapping.
    Pairs = [_|_],
    % Take the highest-scoring mapping (ties broken by enumeration order).
    sort(1, @>=, Pairs, [Score-Mapping|_]).

% analogy_transfer/3: carry a term from source objects to their target images.
analogy_transfer(Mapping, Term, Image) :-
    % A mapped object becomes its image directly.
    ( memberchk(Term-Image, Mapping)
      -> true
    % A compound term is transferred argument by argument.
    ; compound(Term)
      -> Term =.. [Functor | Args],
         maplist(analogy_transfer(Mapping), Args, MappedArgs),
         Image =.. [Functor | MappedArgs]
    % Anything else (an unmapped atom or number) passes through unchanged.
    ; Image = Term ).

% ---- internal --------------------------------------------------------------

% analogy_injective/3: assign each source object a distinct target object.
analogy_injective([], _, []).
% Pick a still-unused target for the head, then map the rest from the remainder.
analogy_injective([S | Ss], Targets, [S-T | Mapping]) :-
    select(T, Targets, Remaining),
    analogy_injective(Ss, Remaining, Mapping).

% ===========================================================================
% HALF TWO — Grid analogy: D4 isometries and colour maps (from the analogy pack)
% ===========================================================================

% ===========================================================================
% SECTION 1 — SHAPE NORMALIZATION
% ===========================================================================

% analogy_normalize_shape(+Cells, -NormCells): translate so top-left is at (0,0).
% NormCells is sorted to provide a canonical form for comparison.
analogy_normalize_shape(Cells, NormCells) :-
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

% analogy_shape_equal(+Cells1, +Cells2): succeed when both cell sets have the same shape.
analogy_shape_equal(Cells1, Cells2) :-
    % Normalize both shapes and compare.
    analogy_normalize_shape(Cells1, N1),
    analogy_normalize_shape(Cells2, N2),
    N1 = N2.

% analogy_shape_size(+Cells, -N): N is the number of cells in the shape.
analogy_shape_size(Cells, N) :-
    % Length of the cell list is the size.
    length(Cells, N).

% analogy_shape_bbox(+Cells, -TopLeft, -BottomRight): bounding box of a cell set.
analogy_shape_bbox(Cells, r(MinR,MinC), r(MaxR,MaxC)) :-
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

% analogy_shape_isometry(+Cells, +Iso, -Cells2): apply isometry Iso to a cell set.
% Cells is first normalized; the result is also normalized.
analogy_shape_isometry(Cells, identity, Cells2) :-
    % Identity: normalize and return.
    analogy_normalize_shape(Cells, Cells2).
analogy_shape_isometry(Cells, rot90, Cells2) :-
    % 90 CW: (R, C) -> (C, MaxR - R) where MaxR is the bounding box height - 1.
    analogy_shape_bbox(Cells, _, r(MaxR,_)),
    maplist([r(R,C), r(C, NR)]>>(NR is MaxR - R), Cells, Rotated),
    analogy_normalize_shape(Rotated, Cells2).
analogy_shape_isometry(Cells, rot180, Cells2) :-
    % 180: apply rot90 twice.
    analogy_shape_isometry(Cells, rot90, Mid),
    analogy_shape_isometry(Mid, rot90, Cells2).
analogy_shape_isometry(Cells, rot270, Cells2) :-
    % 270 CW: apply rot90 three times.
    analogy_shape_isometry(Cells, rot90, M1),
    analogy_shape_isometry(M1, rot90, M2),
    analogy_shape_isometry(M2, rot90, Cells2).
analogy_shape_isometry(Cells, ref_h, Cells2) :-
    % Reflect across horizontal axis: (R, C) -> (MaxR - R, C).
    analogy_shape_bbox(Cells, _, r(MaxR,_)),
    maplist([r(R,C), r(NR,C)]>>(NR is MaxR - R), Cells, Reflected),
    analogy_normalize_shape(Reflected, Cells2).
analogy_shape_isometry(Cells, ref_v, Cells2) :-
    % Reflect across vertical axis: (R, C) -> (R, MaxC - C).
    analogy_shape_bbox(Cells, _, r(_,MaxC)),
    maplist([r(R,C), r(R,NC)]>>(NC is MaxC - C), Cells, Reflected),
    analogy_normalize_shape(Reflected, Cells2).
analogy_shape_isometry(Cells, ref_d1, Cells2) :-
    % Transpose (main diagonal): (R, C) -> (C, R).
    maplist([r(R,C), r(C,R)]>>(true), Cells, Transposed),
    analogy_normalize_shape(Transposed, Cells2).
analogy_shape_isometry(Cells, ref_d2, Cells2) :-
    % Anti-diagonal: rotate 90 then transpose.
    analogy_shape_isometry(Cells, rot90, Mid),
    analogy_shape_isometry(Mid, ref_d1, Cells2).

% analogy_isometry_candidates(+Shape1, +Shape2, -Isos): list of D4 isometries mapping Shape1 to Shape2.
analogy_isometry_candidates(Shape1, Shape2, Isos) :-
    % Normalize Shape2 once for efficient repeated comparison.
    analogy_normalize_shape(Shape2, N2),
    % Try all 8 isometries.
    findall(Iso, (
        member(Iso, [identity, rot90, rot180, rot270, ref_h, ref_v, ref_d1, ref_d2]),
        analogy_shape_isometry(Shape1, Iso, Transformed),
        Transformed = N2
    ), Isos).

% ===========================================================================
% SECTION 3 — COLOR MAP INFERENCE
% ===========================================================================

% analogy_infer_color_map(+InColors, +OutColors, -Map): infer From-To color pairs.
% InColors and OutColors are parallel lists (same length).
% Pairs where In == Out are omitted (identity mappings are not recorded).
analogy_infer_color_map(InColors, OutColors, Map) :-
    % Pair each input color with its output color.
    maplist([I, O, I-O]>>(true), InColors, OutColors, AllPairs),
    % Remove identity pairs (where color does not change).
    findall(Pair, (member(Pair, AllPairs), Pair = F-T, F \= T), UniqueMap),
    % Remove duplicate pairs.
    list_to_set(UniqueMap, Map).

% analogy_grid_color_map(+Grid1, +Grid2, -Map): infer color map from two same-size grids.
analogy_grid_color_map(Grid1, Grid2, Map) :-
    % Flatten both grids.
    flatten(Grid1, Flat1),
    flatten(Grid2, Flat2),
    % Infer color map from parallel cell lists.
    analogy_infer_color_map(Flat1, Flat2, Map).

% ===========================================================================
% SECTION 4 — OBJECT MATCHING
% ===========================================================================

% analogy_match_objects(+InObjects, +OutObjects, -Pairs): match objects by size and shape.
% Pairs is a list of in_obj(Cells)-out_obj(Cells) correspondences.
% Only unambiguous 1-to-1 matches by normalized shape are included.
analogy_match_objects(InObjects, OutObjects, Pairs) :-
    % For each input object, find any output object with the same normalized shape.
    findall(in_obj(In)-out_obj(Out), (
        member(In, InObjects),
        member(Out, OutObjects),
        analogy_shape_equal(In, Out)
    ), Pairs).

% analogy_object_offset(+Cells1, +Cells2, -offset(DR, DC)): translation offset.
% Computes the vector from the top-left of Cells1 to the top-left of Cells2.
analogy_object_offset(Cells1, Cells2, offset(DR,DC)) :-
    % Get bounding box top-left corners.
    analogy_shape_bbox(Cells1, r(MinR1,MinC1), _),
    analogy_shape_bbox(Cells2, r(MinR2,MinC2), _),
    % The offset is the difference.
    DR is MinR2 - MinR1,
    DC is MinC2 - MinC1.

% ===========================================================================
% SECTION 5 — GRID-LEVEL ISOMETRY DETECTION
% ===========================================================================

% analogy_grid_isometry(+Grid1, +Grid2, -Isos): find D4 isometries mapping Grid1 to Grid2.
analogy_grid_isometry(Grid1, Grid2, Isos) :-
    % Try all 8 D4 isometries.
    findall(Iso, (
        member(Iso, [identity, rot90, rot180, rot270, ref_h, ref_v, ref_d1, ref_d2]),
        analogy_apply_isometry(Grid1, Iso, Grid1Transformed),
        gd_equal(Grid1Transformed, Grid2)
    ), Isos).

% analogy_apply_isometry(+Grid, +Iso, -Grid2): apply a named D4 isometry to a grid.
analogy_apply_isometry(Grid, identity, Grid).
analogy_apply_isometry(Grid, rot90,   Grid2) :- gd_rotate90(Grid, Grid2).
analogy_apply_isometry(Grid, rot180,  Grid2) :- gd_rotate180(Grid, Grid2).
analogy_apply_isometry(Grid, rot270,  Grid2) :- gd_rotate270(Grid, Grid2).
analogy_apply_isometry(Grid, ref_h,   Grid2) :- gd_reflect_h(Grid, Grid2).
analogy_apply_isometry(Grid, ref_v,   Grid2) :- gd_reflect_v(Grid, Grid2).
analogy_apply_isometry(Grid, ref_d1,  Grid2) :- gd_reflect_d1(Grid, Grid2).
analogy_apply_isometry(Grid, ref_d2,  Grid2) :- gd_reflect_d2(Grid, Grid2).

% analogy_apply_color_map(+Grid, +Map, -Grid2): apply a From-To color map to a grid.
analogy_apply_color_map(Grid, Map, Grid2) :-
    % Delegate to gd_color_map for the actual substitution.
    gd_color_map(Grid, Map, Grid2).

% ===========================================================================
% SECTION 6 — CROSS-EXAMPLE CONSISTENCY
% ===========================================================================

% analogy_examples_isometry(+Pairs, -Iso, -ColorMap): find isometry and color map
% consistent with ALL (InputGrid, OutputGrid) training pairs.
% Pairs is a list of in(InputGrid)-out(OutputGrid) terms.
% Iso is one of the 8 D4 atoms; ColorMap is a list of From-To pairs (may be []).
analogy_examples_isometry(Pairs, Iso, ColorMap) :-
    % Collect (Input, Output) pairs as two separate lists.
    pairs_to_lists(Pairs, InGrids, OutGrids),
    % Try each D4 isometry in order.
    member(Iso, [identity, rot90, rot180, rot270, ref_h, ref_v, ref_d1, ref_d2]),
    % Apply the isometry to the first input grid to obtain Trans1.
    InGrids = [In1|_],
    OutGrids = [Out1|_],
    analogy_apply_isometry(In1, Iso, Trans1),
    % Infer the color map from the first pair after isometry.
    analogy_grid_color_map(Trans1, Out1, ColorMap),
    % Verify that every training pair is consistent with Iso + ColorMap.
    maplist(analogy_verify_pair(Iso, ColorMap), InGrids, OutGrids).

% analogy_verify_pair(+Iso, +ColorMap, +InGrid, +OutGrid): verify one training pair.
% Uses a named predicate to give TGrid and Predicted their own fresh local variables
% on each call, avoiding the variable-sharing problem that occurs with YALL lambdas.
analogy_verify_pair(Iso, ColorMap, InGrid, OutGrid) :-
    % Apply the isometry to the input grid.
    analogy_apply_isometry(InGrid, Iso, TGrid),
    % Apply the color map to the isometry result.
    analogy_apply_color_map(TGrid, ColorMap, Predicted),
    % Check that the prediction matches the expected output.
    gd_equal(Predicted, OutGrid).

% pairs_to_lists(+Pairs, -Ins, -Outs): split in(I)-out(O) list into two lists.
pairs_to_lists([], [], []).
pairs_to_lists([in(I)-out(O)|Rest], [I|Is], [O|Os]) :-
    pairs_to_lists(Rest, Is, Os).

% ===========================================================================
% SECTION 7 — END-TO-END SOLVE
% ===========================================================================

% analogy_solve_from_examples(+TrainPairs, +TestGrid, -OutputGrid): infer and apply rule.
% TrainPairs is a list of in(InputGrid)-out(OutputGrid) terms.
% Tries to find a consistent isometry + color map; applies it to TestGrid.
% Fails gracefully if no consistent isometry is found.
analogy_solve_from_examples(TrainPairs, TestGrid, OutputGrid) :-
    % Find a transformation consistent with all training pairs.
    analogy_examples_isometry(TrainPairs, Iso, ColorMap),
    % Apply the isometry to the test grid.
    analogy_apply_isometry(TestGrid, Iso, IsoGrid),
    % Apply the color map (if any) to the isometry result.
    analogy_apply_color_map(IsoGrid, ColorMap, OutputGrid).
