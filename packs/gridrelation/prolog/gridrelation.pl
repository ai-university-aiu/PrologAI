% Module declaration with all fourteen public predicates.
:- module(gridrelation, [
% Succeed if ObjA and ObjB share a 4-adjacent cell edge.
    grl_touching/2,
% Succeed if ObjA and ObjB have cells within Manhattan distance N of each other.
    grl_adjacent/3,
% D is the minimum Manhattan distance between any cell of ObjA and any cell of ObjB.
    grl_min_distance/3,
% Succeed if ObjA's entire bounding box is above ObjB's entire bounding box.
    grl_above/2,
% Succeed if ObjA's entire bounding box is below ObjB's entire bounding box.
    grl_below/2,
% Succeed if ObjA's entire bounding box is to the left of ObjB's entire bounding box.
    grl_left_of/2,
% Succeed if ObjA's entire bounding box is to the right of ObjB's entire bounding box.
    grl_right_of/2,
% Succeed if ObjA's bounding box fully contains ObjB's bounding box.
    grl_bbox_contains/2,
% Succeed if ObjA's and ObjB's bounding boxes overlap.
    grl_bbox_overlap/2,
% Succeed if ObjA and ObjB share at least one identical cell position.
    grl_cells_overlap/2,
% Succeed if ObjA's and ObjB's bounding box row ranges overlap.
    grl_same_rows/2,
% Succeed if ObjA's and ObjB's bounding box column ranges overlap.
    grl_same_cols/2,
% Dir is the primary spatial direction from ObjA to ObjB based on bbox centroids.
    grl_direction/3,
% Relations is the list of all true spatial relation atoms between ObjA and ObjB.
    grl_all_relations/3
]).
% gridrelation.pl - Layer 244: Grid Object Spatial Relations (grl_* prefix).
% Fourteen predicates for computing spatial relations between ob(Color,Cells,BBox)
% object terms as produced by gridobj_all_objects/3.
:- use_module(library(lists), [member/2]).

% --- PRIVATE HELPERS ---

% grl_cells_/2: extract the Cells list from an ob/3 term.
grl_cells_(ob(_,Cells,_), Cells).

% grl_bbox_/2: extract the BBox r0(R0,C0,R1,C1) from an ob/3 term.
grl_bbox_(ob(_,_,BBox), BBox).

% grl_manhattan_/4: Manhattan distance between two cells r(RA,CA) and r(RB,CB).
grl_manhattan_(r(RA,CA), r(RB,CB), D) :-
    DR is abs(RA - RB), DC is abs(CA - CB), D is DR + DC.

% --- PUBLIC PREDICATES ---

% grl_touching(+ObjA, +ObjB)
% Succeed if ObjA and ObjB share a 4-adjacent cell edge.
% Two cells are 4-adjacent if they differ by exactly 1 in exactly one coordinate.
grl_touching(ObjA, ObjB) :-
    grl_cells_(ObjA, CellsA),
    grl_cells_(ObjB, CellsB),
    member(r(RA,CA), CellsA),
    member(r(RB,CB), CellsB),
    ( RA =:= RB, Diff is abs(CA - CB), Diff =:= 1
    ; CA =:= CB, Diff is abs(RA - RB), Diff =:= 1
    ), !.

% grl_adjacent(+ObjA, +ObjB, +N)
% Succeed if ObjA and ObjB have at least one pair of cells within Manhattan distance N.
grl_adjacent(ObjA, ObjB, N) :-
    grl_min_distance(ObjA, ObjB, D),
    D =< N.

% grl_min_distance(+ObjA, +ObjB, -D)
% D is the minimum Manhattan distance between any cell of ObjA and any cell of ObjB.
grl_min_distance(ObjA, ObjB, D) :-
    grl_cells_(ObjA, CellsA),
    grl_cells_(ObjB, CellsB),
    findall(Dist,
        ( member(CA, CellsA), member(CB, CellsB),
          grl_manhattan_(CA, CB, Dist) ),
        Dists),
    Dists \= [],
    min_list(Dists, D).

% grl_above(+ObjA, +ObjB)
% Succeed if ObjA is entirely above ObjB: ObjA's last row < ObjB's first row.
grl_above(ObjA, ObjB) :-
    grl_bbox_(ObjA, r0(_,_,R1A,_)),
    grl_bbox_(ObjB, r0(R0B,_,_,_)),
    R1A < R0B.

% grl_below(+ObjA, +ObjB)
% Succeed if ObjA is entirely below ObjB: ObjA's first row > ObjB's last row.
grl_below(ObjA, ObjB) :-
    grl_bbox_(ObjA, r0(R0A,_,_,_)),
    grl_bbox_(ObjB, r0(_,_,R1B,_)),
    R0A > R1B.

% grl_left_of(+ObjA, +ObjB)
% Succeed if ObjA is entirely left of ObjB: ObjA's last col < ObjB's first col.
grl_left_of(ObjA, ObjB) :-
    grl_bbox_(ObjA, r0(_,_,_,C1A)),
    grl_bbox_(ObjB, r0(_,C0B,_,_)),
    C1A < C0B.

% grl_right_of(+ObjA, +ObjB)
% Succeed if ObjA is entirely right of ObjB: ObjA's first col > ObjB's last col.
grl_right_of(ObjA, ObjB) :-
    grl_bbox_(ObjA, r0(_,C0A,_,_)),
    grl_bbox_(ObjB, r0(_,_,_,C1B)),
    C0A > C1B.

% grl_bbox_contains(+ObjA, +ObjB)
% Succeed if ObjA's bbox fully contains ObjB's bbox on all four sides.
grl_bbox_contains(ObjA, ObjB) :-
    grl_bbox_(ObjA, r0(R0A,C0A,R1A,C1A)),
    grl_bbox_(ObjB, r0(R0B,C0B,R1B,C1B)),
    R0A =< R0B, C0A =< C0B, R1A >= R1B, C1A >= C1B.

% grl_bbox_overlap(+ObjA, +ObjB)
% Succeed if ObjA's and ObjB's bounding boxes share any area.
% Overlap when neither A is completely above/below/left/right of B.
grl_bbox_overlap(ObjA, ObjB) :-
    grl_bbox_(ObjA, r0(R0A,C0A,R1A,C1A)),
    grl_bbox_(ObjB, r0(R0B,C0B,R1B,C1B)),
    R0A =< R1B, R0B =< R1A,
    C0A =< C1B, C0B =< C1A.

% grl_cells_overlap(+ObjA, +ObjB)
% Succeed if ObjA and ObjB share at least one identical cell position.
grl_cells_overlap(ObjA, ObjB) :-
    grl_cells_(ObjA, CellsA),
    grl_cells_(ObjB, CellsB),
    member(Cell, CellsA),
    member(Cell, CellsB), !.

% grl_same_rows(+ObjA, +ObjB)
% Succeed if ObjA's and ObjB's row ranges overlap.
grl_same_rows(ObjA, ObjB) :-
    grl_bbox_(ObjA, r0(R0A,_,R1A,_)),
    grl_bbox_(ObjB, r0(R0B,_,R1B,_)),
    R0A =< R1B, R0B =< R1A.

% grl_same_cols(+ObjA, +ObjB)
% Succeed if ObjA's and ObjB's column ranges overlap.
grl_same_cols(ObjA, ObjB) :-
    grl_bbox_(ObjA, r0(_,C0A,_,C1A)),
    grl_bbox_(ObjB, r0(_,C0B,_,C1B)),
    C0A =< C1B, C0B =< C1A.

% grl_direction(+ObjA, +ObjB, -Dir)
% Dir is the primary direction from ObjA to ObjB based on bbox centroid comparison.
% Dir is one of: above, below, left, right, overlap.
% Centroid row of Obj = (R0 + R1) // 2; centroid col = (C0 + C1) // 2.
% If abs(row difference) > abs(col difference): below or above.
% If abs(col difference) > abs(row difference): right or left.
% If row difference = 0 and col difference = 0: overlap.
% Tie (abs(DR) = abs(DC) and both nonzero): prefer vertical (below or above).
grl_direction(ObjA, ObjB, Dir) :-
    grl_bbox_(ObjA, r0(R0A,C0A,R1A,C1A)),
    grl_bbox_(ObjB, r0(R0B,C0B,R1B,C1B)),
    CRA is (R0A + R1A),
    CCA is (C0A + C1A),
    CRB is (R0B + R1B),
    CCB is (C0B + C1B),
    DR is CRB - CRA,
    DC is CCB - CCA,
    ABS_DR is abs(DR),
    ABS_DC is abs(DC),
    ( DR =:= 0, DC =:= 0 -> Dir = overlap
    ; ABS_DR >= ABS_DC ->
        ( DR > 0 -> Dir = below ; Dir = above )
    ;
        ( DC > 0 -> Dir = right ; Dir = left )
    ).

% grl_all_relations(+ObjA, +ObjB, -Relations)
% Relations is the list of all true spatial relation atoms between ObjA and ObjB.
% The possible atoms are: touching, above, below, left_of, right_of,
%   bbox_contains, bbox_overlap, cells_overlap, same_rows, same_cols.
grl_all_relations(ObjA, ObjB, Relations) :-
    findall(Rel,
        ( member(Rel-Goal,
            [ touching    - grl_touching(ObjA, ObjB)
            , above       - grl_above(ObjA, ObjB)
            , below       - grl_below(ObjA, ObjB)
            , left_of     - grl_left_of(ObjA, ObjB)
            , right_of    - grl_right_of(ObjA, ObjB)
            , bbox_contains - grl_bbox_contains(ObjA, ObjB)
            , bbox_overlap  - grl_bbox_overlap(ObjA, ObjB)
            , cells_overlap - grl_cells_overlap(ObjA, ObjB)
            , same_rows   - grl_same_rows(ObjA, ObjB)
            , same_cols   - grl_same_cols(ObjA, ObjB)
            ]),
          call(Goal) ),
        Relations).
