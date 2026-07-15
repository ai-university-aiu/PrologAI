% objcopy.pl - Layer 177: Object Tiling and Multi-Copy Layout (tc_* prefix).
% Generates multiple copies of obj(Color, Cells) terms at computed positions.
% Covers placing an obj at an explicit top-left position, tiling in rows,
% columns, and grids, aligning and packing lists of objs, spreading at fixed
% intervals, centering within a canvas, and canvas-frame reflection.
% No cross-pack dependencies.
:- module(objcopy, [
    % objcopy_place_at/4: place an obj with its bbox top-left corner at (R0, C0).
    objcopy_place_at/4,
    % objcopy_recolor_all/3: recolor every obj in a list to a uniform color.
    objcopy_recolor_all/3,
    % objcopy_tile_row/4: N copies of Obj, spaced Step cols apart (top-left to top-left).
    objcopy_tile_row/4,
    % objcopy_tile_col/4: N copies of Obj, spaced Step rows apart.
    objcopy_tile_col/4,
    % objcopy_tile_grid/6: NR x NC grid of copies with StepR row and StepC col spacing.
    objcopy_tile_grid/6,
    % objcopy_at_positions/3: one copy of Obj per r(R,C) in Positions, placed by top-left.
    objcopy_at_positions/3,
    % objcopy_align_top/2: shift all objs so their minimum row equals the global minimum row.
    objcopy_align_top/2,
    % objcopy_align_left/2: shift all objs so their minimum col equals the global minimum col.
    objcopy_align_left/2,
    % objcopy_pack_row/5: pack Objs in a row at row R, starting at col C0, with Gap between bboxes.
    objcopy_pack_row/5,
    % objcopy_pack_col/5: pack Objs in a column at col C, starting at row R0, with Gap between bboxes.
    objcopy_pack_col/5,
    % objcopy_spread_h/4: redistribute Objs so their left edges are at C0, C0+Step, C0+2*Step,...
    objcopy_spread_h/4,
    % objcopy_spread_v/4: redistribute Objs so their top edges are at R0, R0+Step, R0+2*Step,...
    objcopy_spread_v/4,
    % objcopy_center/4: center Obj within an H x W canvas (floor division offsets).
    objcopy_center/4,
    % objcopy_flip_h/3: reflect Obj horizontally within a canvas of width W.
    objcopy_flip_h/3
]).

% Load list utilities.
:- use_module(library(lists), [member/2, min_list/2, max_list/2, nth0/3]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% objcopy_minrow_(+Obj, -R): minimum row index in Obj's cell list.
objcopy_minrow_(obj(_, Cells), R) :-
% Collect all row indices.
    findall(Row, member(r(Row,_), Cells), Rs),
% Find the minimum.
    min_list(Rs, R).

% objcopy_mincol_(+Obj, -C): minimum column index in Obj's cell list.
objcopy_mincol_(obj(_, Cells), C) :-
% Collect all col indices.
    findall(Col, member(r(_,Col), Cells), Cs),
% Find the minimum.
    min_list(Cs, C).

% objcopy_maxrow_(+Obj, -R): maximum row index in Obj's cell list.
objcopy_maxrow_(obj(_, Cells), R) :-
% Collect all row indices.
    findall(Row, member(r(Row,_), Cells), Rs),
% Find the maximum.
    max_list(Rs, R).

% objcopy_maxcol_(+Obj, -C): maximum column index in Obj's cell list.
objcopy_maxcol_(obj(_, Cells), C) :-
% Collect all col indices.
    findall(Col, member(r(_,Col), Cells), Cs),
% Find the maximum.
    max_list(Cs, C).

% objcopy_bbox_h_(+Obj, -H): bounding box height = MaxRow - MinRow + 1.
objcopy_bbox_h_(Obj, H) :-
% Get top and bottom rows.
    objcopy_minrow_(Obj, MinR),
    objcopy_maxrow_(Obj, MaxR),
% Height spans from min to max inclusive.
    H is MaxR - MinR + 1.

% objcopy_bbox_w_(+Obj, -W): bounding box width = MaxCol - MinCol + 1.
objcopy_bbox_w_(Obj, W) :-
% Get left and right cols.
    objcopy_mincol_(Obj, MinC),
    objcopy_maxcol_(Obj, MaxC),
% Width spans from min to max inclusive.
    W is MaxC - MinC + 1.

% objcopy_translate_(+Cells, +DR, +DC, -Cells2): translate all cells by (DR, DC).
objcopy_translate_(Cells, DR, DC, Cells2) :-
% Add DR to each row and DC to each col.
    findall(r(R2,C2),
        (member(r(R,C), Cells),
         R2 is R + DR,
         C2 is C + DC),
        Cells2).

% objcopy_place_at_(+Obj, +R0, +C0, -Obj2): private place_at using translate_.
objcopy_place_at_(obj(Color, Cells), R0, C0, obj(Color, Cells2)) :-
% Find current bbox top-left.
    min_list_r_(Cells, MinR),
    min_list_c_(Cells, MinC),
% Required translation.
    DR is R0 - MinR,
    DC is C0 - MinC,
% Translate all cells.
    objcopy_translate_(Cells, DR, DC, Cells2).

% min_list_r_(+Cells, -MinR): minimum row from a cell list.
min_list_r_(Cells, MinR) :-
    findall(R, member(r(R,_), Cells), Rs),
    min_list(Rs, MinR).

% min_list_c_(+Cells, -MinC): minimum col from a cell list.
min_list_c_(Cells, MinC) :-
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Cs, MinC).

% objcopy_pack_row_acc_(+Objs, +CurC, +Gap, -Objs2): accumulate row packing.
objcopy_pack_row_acc_([], _, _, []).
objcopy_pack_row_acc_([Obj|Rest], CurC, Gap, [Obj2|Rest2]) :-
% Get current object's top-left row (keep same row).
    objcopy_minrow_(Obj, R),
% Place at (R, CurC).
    objcopy_place_at_(Obj, R, CurC, Obj2),
% Advance column cursor by bbox width + gap.
    objcopy_bbox_w_(Obj, W),
    NextC is CurC + W + Gap,
% Recurse on remaining objects.
    objcopy_pack_row_acc_(Rest, NextC, Gap, Rest2).

% objcopy_pack_col_acc_(+Objs, +CurR, +Gap, -Objs2): accumulate column packing.
objcopy_pack_col_acc_([], _, _, []).
objcopy_pack_col_acc_([Obj|Rest], CurR, Gap, [Obj2|Rest2]) :-
% Get current object's top-left col (keep same col).
    objcopy_mincol_(Obj, C),
% Place at (CurR, C).
    objcopy_place_at_(Obj, CurR, C, Obj2),
% Advance row cursor by bbox height + gap.
    objcopy_bbox_h_(Obj, H),
    NextR is CurR + H + Gap,
% Recurse on remaining objects.
    objcopy_pack_col_acc_(Rest, NextR, Gap, Rest2).

% --- Exported predicates -----------------------------------------------------

% objcopy_place_at(+Obj, +R0, +C0, -Obj2): place Obj with bbox top-left at (R0, C0).
objcopy_place_at(Obj, R0, C0, Obj2) :-
% Delegate to the private helper.
    objcopy_place_at_(Obj, R0, C0, Obj2).

% objcopy_recolor_all(+Color, +Objs, -Objs2): recolor all objs in the list to Color.
objcopy_recolor_all(_, [], []).
objcopy_recolor_all(Color, [obj(_, Cells)|Rest], [obj(Color, Cells)|Rest2]) :-
% Replace the color atom, keep cells unchanged.
    objcopy_recolor_all(Color, Rest, Rest2).

% objcopy_tile_row(+Obj, +N, +Step, -Objs): N copies of Obj, top-left cols offset by Step.
% Copy I (0-indexed) has its top-left column = MinCol + I*Step.
objcopy_tile_row(Obj, N, Step, Objs) :-
% Get the original top-left row and col.
    objcopy_minrow_(Obj, R0),
    objcopy_mincol_(Obj, C0),
% Generate copies for I = 0..N-1.
    N1 is N - 1,
    findall(O,
        (between(0, N1, I),
         NewC is C0 + I * Step,
         objcopy_place_at_(Obj, R0, NewC, O)),
        Objs).

% objcopy_tile_col(+Obj, +N, +Step, -Objs): N copies of Obj, top-left rows offset by Step.
% Copy I (0-indexed) has its top-left row = MinRow + I*Step.
objcopy_tile_col(Obj, N, Step, Objs) :-
% Get the original top-left row and col.
    objcopy_minrow_(Obj, R0),
    objcopy_mincol_(Obj, C0),
% Generate copies for I = 0..N-1.
    N1 is N - 1,
    findall(O,
        (between(0, N1, I),
         NewR is R0 + I * Step,
         objcopy_place_at_(Obj, NewR, C0, O)),
        Objs).

% objcopy_tile_grid(+Obj, +NR, +NC, +StepR, +StepC, -Objs): NR x NC grid of copies.
% Copy at (I,J) has top-left row = MinRow + I*StepR, col = MinCol + J*StepC.
objcopy_tile_grid(Obj, NR, NC, StepR, StepC, Objs) :-
% Get original top-left.
    objcopy_minrow_(Obj, R0),
    objcopy_mincol_(Obj, C0),
% Row and col ranges.
    NR1 is NR - 1,
    NC1 is NC - 1,
% Generate all NR*NC copies.
    findall(O,
        (between(0, NR1, I),
         between(0, NC1, J),
         NewR is R0 + I * StepR,
         NewC is C0 + J * StepC,
         objcopy_place_at_(Obj, NewR, NewC, O)),
        Objs).

% objcopy_at_positions(+Obj, +Positions, -Objs): one copy of Obj per r(R,C) in Positions.
% Each copy's bbox top-left is placed at the corresponding r(R,C).
objcopy_at_positions(_, [], []).
objcopy_at_positions(Obj, [r(R,C)|Rest], [O|Objs]) :-
% Place this copy at (R, C).
    objcopy_place_at_(Obj, R, C, O),
% Recurse on remaining positions.
    objcopy_at_positions(Obj, Rest, Objs).

% objcopy_align_top(+Objs, -Objs2): translate all objs so their min-row equals the global min-row.
objcopy_align_top(Objs, Objs2) :-
% Collect min-row of each object.
    maplist(objcopy_minrow_, Objs, MinRows),
% Global minimum row.
    min_list(MinRows, GlobalMin),
% Translate each object by (GlobalMin - its MinRow, 0).
    maplist(objcopy_shift_to_row_(GlobalMin), Objs, Objs2).

% objcopy_shift_to_row_(+TargetRow, +Obj, -Obj2): translate Obj so its min-row = TargetRow.
objcopy_shift_to_row_(TargetRow, Obj, Obj2) :-
% Get current min-row.
    objcopy_minrow_(Obj, MinR),
% Required row shift.
    DR is TargetRow - MinR,
% Apply translation (col shift = 0).
    Obj = obj(Color, Cells),
    objcopy_translate_(Cells, DR, 0, Cells2),
    Obj2 = obj(Color, Cells2).

% objcopy_align_left(+Objs, -Objs2): translate all objs so their min-col equals the global min-col.
objcopy_align_left(Objs, Objs2) :-
% Collect min-col of each object.
    maplist(objcopy_mincol_, Objs, MinCols),
% Global minimum col.
    min_list(MinCols, GlobalMin),
% Translate each object by (0, GlobalMin - its MinCol).
    maplist(objcopy_shift_to_col_(GlobalMin), Objs, Objs2).

% objcopy_shift_to_col_(+TargetCol, +Obj, -Obj2): translate Obj so its min-col = TargetCol.
objcopy_shift_to_col_(TargetCol, Obj, Obj2) :-
% Get current min-col.
    objcopy_mincol_(Obj, MinC),
% Required col shift.
    DC is TargetCol - MinC,
% Apply translation (row shift = 0).
    Obj = obj(Color, Cells),
    objcopy_translate_(Cells, 0, DC, Cells2),
    Obj2 = obj(Color, Cells2).

% objcopy_pack_row(+Objs, +R, +C0, +Gap, -Objs2): pack Objs in a horizontal row.
% Places each obj so its top-left is at row R and its left edge follows the
% previous obj's right edge plus Gap columns.
objcopy_pack_row(Objs, R, C0, Gap, Objs2) :-
% First shift all objects to have top-left row = R (preserving column for now).
    maplist(objcopy_shift_to_row_(R), Objs, RowAligned),
% Then pack from C0 with Gap.
    objcopy_pack_row_acc_(RowAligned, C0, Gap, Objs2).

% objcopy_pack_col(+Objs, +C, +R0, +Gap, -Objs2): pack Objs in a vertical column.
% Places each obj so its top-left is at col C and its top edge follows the
% previous obj's bottom edge plus Gap rows.
objcopy_pack_col(Objs, C, R0, Gap, Objs2) :-
% First shift all objects to have top-left col = C (preserving row for now).
    maplist(objcopy_shift_to_col_(C), Objs, ColAligned),
% Then pack from R0 with Gap.
    objcopy_pack_col_acc_(ColAligned, R0, Gap, Objs2).

% objcopy_spread_h(+Objs, +C0, +Step, -Objs2): redistribute Objs at fixed col offsets.
% Obj I (0-indexed) has its left edge at C0 + I*Step; rows are unchanged.
objcopy_spread_h(Objs, C0, Step, Objs2) :-
% Generate index-obj pairs.
    length(Objs, N),
    N1 is N - 1,
    findall(O,
        (between(0, N1, I),
         nth0(I, Objs, Obj),
         objcopy_minrow_(Obj, R),
         NewC is C0 + I * Step,
         objcopy_place_at_(Obj, R, NewC, O)),
        Objs2).

% objcopy_spread_v(+Objs, +R0, +Step, -Objs2): redistribute Objs at fixed row offsets.
% Obj I (0-indexed) has its top edge at R0 + I*Step; cols are unchanged.
objcopy_spread_v(Objs, R0, Step, Objs2) :-
% Generate index-obj pairs.
    length(Objs, N),
    N1 is N - 1,
    findall(O,
        (between(0, N1, I),
         nth0(I, Objs, Obj),
         objcopy_mincol_(Obj, C),
         NewR is R0 + I * Step,
         objcopy_place_at_(Obj, NewR, C, O)),
        Objs2).

% objcopy_center(+Obj, +H, +W, -Obj2): center Obj within H x W canvas.
% Top-left offset = ((H - BH) // 2, (W - BW) // 2).
objcopy_center(Obj, H, W, Obj2) :-
% Get bounding box dimensions.
    objcopy_bbox_h_(Obj, BH),
    objcopy_bbox_w_(Obj, BW),
% Compute centering offsets using floor division.
    R0 is (H - BH) // 2,
    C0 is (W - BW) // 2,
% Place at the centered position.
    objcopy_place_at_(Obj, R0, C0, Obj2).

% objcopy_flip_h(+Obj, +W, -Obj2): reflect Obj horizontally within canvas width W.
% Each cell r(R, C) maps to r(R, W-1-C).
objcopy_flip_h(obj(Color, Cells), W, obj(Color, Cells2)) :-
% Reflect each cell's column within [0, W-1].
    findall(r(R, C2),
        (member(r(R, C), Cells),
         C2 is W - 1 - C),
        Cells2).
