% Module declaration with all fourteen public predicates.
:- module(grid_align, [
% Compute center of mass of non-bg cells as r(R, C).
    grid_align_center_of_mass/3,
% Bounding box of non-bg cells: r0(R0,C0,R1,C1) or none.
    grid_align_nonbg_bbox/3,
% Center of bounding box: r(R,C) or none.
    grid_align_bbox_center/3,
% Translate grid by (DR, DC); out-of-bounds cells become Bg.
    grid_align_translate/5,
% Count cells where both grids have non-bg at the same position.
    grid_align_overlap_count/4,
% Overlap score: common non-bg / Grid1 non-bg count (float).
    grid_align_overlap_score/4,
% Intersection-over-union of non-bg regions.
    grid_align_iou/4,
% Find the (DR,DC) offset in [-SearchR,SearchR]^2 that maximises overlap.
    grid_align_find_offset/5,
% Translate Grid2 so its centroid matches Grid1's.
    grid_align_align_centers/4,
% Translate Grid2 so its bbox center matches Grid1's.
    grid_align_align_bbox_centers/4,
% (DR,DC) vector from Grid1's centroid to Grid2's.
    grid_align_nonbg_offset/4,
% Place Grid2 at (R0,C0) on a canvas transparently.
    grid_align_place_at/6,
% Align Grid2 so that its cell (PR,PC) lands on canvas cell (QR,QC).
    grid_align_anchor_to/8,
% All (DR,DC) offsets where at least one non-bg cell overlaps.
    grid_align_match_any_offset/4
]).
% gridalign.pl - Layer 239: Grid Alignment and Shift Matching (gal_* prefix).
% Fourteen predicates for computing centers of mass, translating grids,
% finding alignment offsets, scoring overlaps, and placing grids relative
% to each other. No cross-pack dependencies.
:- use_module(library(lists), [member/2]).

% --- PRIVATE HELPERS ---

% grid_align_nonbg_cells_/3: collect all p(R,C) positions of non-bg cells in Grid.
grid_align_nonbg_cells_(Grid, Bg, Cells) :-
    length(Grid, H),
    (H > 0 ->
        Grid = [Row0|_], length(Row0, W),
        H1 is H - 1, W1 is W - 1,
        findall(p(R,C),
            (between(0, H1, R), nth0(R, Grid, Row),
             between(0, W1, C), nth0(C, Row, V), V \= Bg),
            Cells)
    ;
        Cells = []
    ).

% grid_align_floor_avg_/2: integer floor-average of a non-empty list.
grid_align_floor_avg_(List, Avg) :-
    length(List, N), N > 0,
    sumlist(List, S),
    Avg is S // N.

% grid_align_grid_size_/3: (H, W) dimensions. Returns 0,0 for empty grid.
grid_align_grid_size_([], 0, 0) :- !.
grid_align_grid_size_(Grid, H, W) :-
    length(Grid, H),
    Grid = [Row0|_], length(Row0, W).

% --- PUBLIC PREDICATES ---

% grid_align_center_of_mass(+Grid, +Bg, -r(R,C))
% r(R,C) is the integer-floor average of row and column indices of all
% non-bg cells. Fails if Grid has no non-bg cells.
grid_align_center_of_mass(Grid, Bg, r(R, C)) :-
    grid_align_nonbg_cells_(Grid, Bg, Cells),
    Cells \= [],
    findall(PR, member(p(PR,_), Cells), Rs),
    findall(PC, member(p(_,PC), Cells), Cs),
    grid_align_floor_avg_(Rs, R),
    grid_align_floor_avg_(Cs, C).

% grid_align_nonbg_bbox(+Grid, +Bg, -BBox)
% BBox = r0(R0,C0,R1,C1): tight bounding box of non-bg cells.
% BBox = none if Grid has no non-bg cells.
grid_align_nonbg_bbox(Grid, Bg, BBox) :-
    grid_align_nonbg_cells_(Grid, Bg, Cells),
    (Cells = [] ->
        BBox = none
    ;
        findall(PR, member(p(PR,_), Cells), Rs),
        findall(PC, member(p(_,PC), Cells), Cs),
        min_list(Rs, R0), max_list(Rs, R1),
        min_list(Cs, C0), max_list(Cs, C1),
        BBox = r0(R0, C0, R1, C1)
    ).

% grid_align_bbox_center(+Grid, +Bg, -Center)
% Center = r(R,C): floor center of the bounding box of non-bg cells.
% Center = none if Grid has no non-bg cells.
grid_align_bbox_center(Grid, Bg, Center) :-
    grid_align_nonbg_bbox(Grid, Bg, BBox),
    (BBox = none ->
        Center = none
    ;
        BBox = r0(R0, C0, R1, C1),
        R is (R0 + R1) // 2,
        C is (C0 + C1) // 2,
        Center = r(R, C)
    ).

% grid_align_translate(+Grid, +DR, +DC, +Bg, -Result)
% Shift every non-bg cell by (DR, DC). Cells that leave the grid boundary
% are lost. New cells entering from the boundary are Bg. Result has the
% same dimensions as Grid.
grid_align_translate(Grid, DR, DC, Bg, Result) :-
    grid_align_grid_size_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Build a set of modifications: (NewR, NewC, Value) for each in-bounds shifted cell.
    grid_align_nonbg_cells_(Grid, Bg, Cells),
    findall(p(NR,NC,V),
        (member(p(OR,OC), Cells),
         nth0(OR, Grid, Row), nth0(OC, Row, V),
         NR is OR + DR, NC is OC + DC,
         NR >= 0, NR =< H1, NC >= 0, NC =< W1),
        Mods),
    findall(NewRow,
        (between(0, H1, R),
         findall(NewV,
             (between(0, W1, C),
              (member(p(R,C,MV), Mods) -> NewV = MV ; NewV = Bg)),
             NewRow)),
        Result).

% grid_align_overlap_count(+Grid1, +Grid2, +Bg, -Count)
% Count positions (R,C) where both grids have a non-bg cell.
% Grids must have the same dimensions; extra rows/cols in Grid2 are ignored.
grid_align_overlap_count(Grid1, Grid2, Bg, Count) :-
    grid_align_grid_size_(Grid1, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(1,
        (between(0, H1, R), between(0, W1, C),
         nth0(R, Grid1, Row1), nth0(C, Row1, V1), V1 \= Bg,
         nth0(R, Grid2, Row2), nth0(C, Row2, V2), V2 \= Bg),
        Ones),
    length(Ones, Count).

% grid_align_overlap_score(+Grid1, +Grid2, +Bg, -Score)
% Score = OverlapCount / NonbgCount(Grid1), as a float.
% Score = 0.0 if Grid1 has no non-bg cells.
grid_align_overlap_score(Grid1, Grid2, Bg, Score) :-
    grid_align_nonbg_cells_(Grid1, Bg, Cells1),
    length(Cells1, N1),
    (N1 =:= 0 ->
        Score = 0.0
    ;
        grid_align_overlap_count(Grid1, Grid2, Bg, Ov),
        Score is Ov / N1
    ).

% grid_align_iou(+Grid1, +Grid2, +Bg, -IoU)
% IoU = |Intersection| / |Union| of non-bg regions. 0.0 if union is empty.
grid_align_iou(Grid1, Grid2, Bg, IoU) :-
    grid_align_grid_size_(Grid1, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(1,
        (between(0, H1, R), between(0, W1, C),
         nth0(R, Grid1, Row1), nth0(C, Row1, V1), V1 \= Bg,
         nth0(R, Grid2, Row2), nth0(C, Row2, V2), V2 \= Bg),
        InterList),
    length(InterList, InterN),
    findall(1,
        (between(0, H1, R), between(0, W1, C),
         nth0(R, Grid1, Row1), nth0(C, Row1, V1),
         nth0(R, Grid2, Row2), nth0(C, Row2, V2),
         \+ (V1 = Bg, V2 = Bg)),
        UnionList),
    length(UnionList, UnionN),
    (UnionN =:= 0 -> IoU = 0.0 ; IoU is InterN / UnionN).

% grid_align_find_offset(+Grid1, +Grid2, +Bg, +SearchR, -o(BestDR, BestDC))
% Find the (DR,DC) in [-SearchR,SearchR]^2 that maximises the overlap count
% when Grid2's non-bg cells are shifted by (DR,DC) into Grid1's coordinate space.
% Ties broken by minimum Manhattan distance |DR|+|DC|.
grid_align_find_offset(Grid1, Grid2, Bg, SearchR, o(BestDR, BestDC)) :-
    grid_align_grid_size_(Grid1, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect Grid1 non-bg positions as a set for fast lookup.
    grid_align_nonbg_cells_(Grid1, Bg, S1),
% Collect Grid2 non-bg positions with values.
    grid_align_nonbg_cells_(Grid2, Bg, S2),
    Neg is -SearchR,
    findall(cv(Ov,DR,DC),
        (between(Neg, SearchR, DR),
         between(Neg, SearchR, DC),
% Count how many Grid2 non-bg cells land on Grid1 non-bg positions.
         findall(1,
             (member(p(R2,C2), S2),
              NR is R2 + DR, NC is C2 + DC,
              NR >= 0, NR =< H1, NC >= 0, NC =< W1,
              member(p(NR,NC), S1)),
             Hits),
         length(Hits, Ov)),
        Candidates),
% Find the best candidate.
    grid_align_pick_best_offset_(Candidates, 0, 0, 0, BestDR, BestDC).

% grid_align_pick_best_offset_/6: fold over candidates, tracking best Ov and (DR,DC).
grid_align_pick_best_offset_([], _, BDR, BDC, BDR, BDC).
grid_align_pick_best_offset_([cv(Ov,DR,DC)|Rest], BestOv, BestDR, BestDC, OutDR, OutDC) :-
    Dist is abs(DR) + abs(DC),
    BestDist is abs(BestDR) + abs(BestDC),
    (   Ov > BestOv
    ;   Ov =:= BestOv, Dist < BestDist
    ) ->
        grid_align_pick_best_offset_(Rest, Ov, DR, DC, OutDR, OutDC)
    ;
        grid_align_pick_best_offset_(Rest, BestOv, BestDR, BestDC, OutDR, OutDC).

% grid_align_align_centers(+Grid1, +Grid2, +Bg, -Aligned)
% Translate Grid2 so its centroid matches Grid1's. Returns Grid2 unchanged
% if either grid has no non-bg cells.
grid_align_align_centers(Grid1, Grid2, Bg, Aligned) :-
    (   grid_align_center_of_mass(Grid1, Bg, r(R1, C1)),
        grid_align_center_of_mass(Grid2, Bg, r(R2, C2))
    ->  DR is R1 - R2, DC is C1 - C2,
        grid_align_translate(Grid2, DR, DC, Bg, Aligned)
    ;   Aligned = Grid2
    ).

% grid_align_align_bbox_centers(+Grid1, +Grid2, +Bg, -Aligned)
% Translate Grid2 so its bbox center matches Grid1's. Returns Grid2 unchanged
% if either grid has no non-bg cells.
grid_align_align_bbox_centers(Grid1, Grid2, Bg, Aligned) :-
    (   grid_align_bbox_center(Grid1, Bg, r(R1, C1)),
        grid_align_bbox_center(Grid2, Bg, r(R2, C2))
    ->  DR is R1 - R2, DC is C1 - C2,
        grid_align_translate(Grid2, DR, DC, Bg, Aligned)
    ;   Aligned = Grid2
    ).

% grid_align_nonbg_offset(+Grid1, +Grid2, +Bg, -o(DR,DC))
% (DR,DC) vector from Grid1's non-bg centroid to Grid2's. Fails if either has none.
grid_align_nonbg_offset(Grid1, Grid2, Bg, o(DR, DC)) :-
    grid_align_center_of_mass(Grid1, Bg, r(R1, C1)),
    grid_align_center_of_mass(Grid2, Bg, r(R2, C2)),
    DR is R2 - R1, DC is C2 - C1.

% grid_align_place_at(+Canvas, +Grid2, +R0, +C0, +Bg, -Result)
% Paste Grid2 onto Canvas with its top-left at (R0, C0), using transparent Bg:
% non-Bg cells in Grid2 overwrite Canvas; Bg cells leave Canvas unchanged.
% Canvas and Result have the same dimensions.
grid_align_place_at(Canvas, Grid2, R0, C0, Bg, Result) :-
    length(Canvas, CH), CH1 is CH - 1,
    Canvas = [CRow0|_], length(CRow0, CW), CW1 is CW - 1,
    length(Grid2, SH), SH1 is SH - 1,
    findall(p(GR,GC,V),
        (between(0, SH1, SR),
         nth0(SR, Grid2, SRow),
         length(SRow, SW), SW1 is SW - 1,
         between(0, SW1, SC),
         nth0(SC, SRow, V), V \= Bg,
         GR is R0 + SR, GC is C0 + SC,
         GR >= 0, GR =< CH1, GC >= 0, GC =< CW1),
        Mods),
    findall(NewRow,
        (between(0, CH1, R),
         nth0(R, Canvas, OldRow),
         findall(NewV,
             (between(0, CW1, C),
              nth0(C, OldRow, OldV),
              (member(p(R,C,MV), Mods) -> NewV = MV ; NewV = OldV)),
             NewRow)),
        Result).

% grid_align_anchor_to(+Canvas, +Grid2, +PR, +PC, +QR, +QC, +Bg, -Result)
% Translate Grid2 so that its cell at row PR, column PC aligns with
% Canvas cell at row QR, column QC, then paste transparently onto Canvas.
grid_align_anchor_to(Canvas, Grid2, PR, PC, QR, QC, Bg, Result) :-
    R0 is QR - PR, C0 is QC - PC,
    grid_align_place_at(Canvas, Grid2, R0, C0, Bg, Result).

% grid_align_match_any_offset(+Grid1, +Grid2, +Bg, -Offsets)
% Offsets is the list of o(DR,DC) values such that shifting Grid2's non-bg
% cells by (DR,DC) lands at least one on a non-bg cell of Grid1.
% Search range: DR in [-(H1-1), H1-1], DC in [-(W1-1), W1-1].
grid_align_match_any_offset(Grid1, Grid2, Bg, Offsets) :-
    grid_align_grid_size_(Grid1, H, W),
    H1 is H - 1, W1 is W - 1,
    NegH is -H1, NegW is -W1,
    grid_align_nonbg_cells_(Grid1, Bg, S1),
    grid_align_nonbg_cells_(Grid2, Bg, S2),
    findall(o(DR,DC),
        (between(NegH, H1, DR),
         between(NegW, W1, DC),
         member(p(R2,C2), S2),
         NR is R2 + DR, NC is C2 + DC,
         member(p(NR,NC), S1)),
        AllOffsets),
% Deduplicate while preserving order.
    list_to_set(AllOffsets, Offsets).
