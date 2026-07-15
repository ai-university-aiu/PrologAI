:- use_module('../prolog/object_transform.pl').
:- use_module(library(plunit)).

% Fixture objects.
%   dot: single cell at (0,0).
%   hline: two cells in a horizontal row.
%   vline: two cells in a vertical column.
%   corner: L-shaped 3-cell object.
%   sq2x2: 2x2 square.
%   sq3x3: 3x3 filled square.
%   offset: object not at origin (rows 2-3, cols 3-4).

dot(obj(red,   [r(0,0)])).
hline(obj(blue,  [r(0,0), r(0,1)])).
vline(obj(green, [r(0,0), r(1,0)])).
corner(obj(yellow, [r(0,0), r(0,1), r(1,0)])).   % L-shape top-left corner
sq2x2(obj(white,   [r(0,0), r(0,1), r(1,0), r(1,1)])).
sq3x3(obj(black,   [r(0,0),r(0,1),r(0,2),
                    r(1,0),r(1,1),r(1,2),
                    r(2,0),r(2,1),r(2,2)])).
offset(obj(cyan, [r(2,3), r(2,4), r(3,3)])).     % L-shape at offset (2,3)

% Two overlapping objects for set algebra tests.
left_half(obj(a,  [r(0,0), r(0,1), r(1,0), r(1,1)])).
right_half(obj(b, [r(0,1), r(0,2), r(1,1), r(1,2)])).

:- begin_tests(object_transform_bbox).

test(dot)    :- dot(O), object_transform_bbox(O, 0, 0, 0, 0).
test(hline)  :- hline(O), object_transform_bbox(O, 0, 0, 0, 1).
test(vline)  :- vline(O), object_transform_bbox(O, 0, 0, 1, 0).
test(sq2x2)  :- sq2x2(O), object_transform_bbox(O, 0, 0, 1, 1).
test(offset) :- offset(O), object_transform_bbox(O, 2, 3, 3, 4).

:- end_tests(object_transform_bbox).

:- begin_tests(object_transform_size).

test(dot_1x1)      :- dot(O),    object_transform_size(O, 1, 1).
test(hline_1x2)    :- hline(O),  object_transform_size(O, 1, 2).
test(vline_2x1)    :- vline(O),  object_transform_size(O, 2, 1).
test(sq2x2_2x2)    :- sq2x2(O),  object_transform_size(O, 2, 2).
test(sq3x3_3x3)    :- sq3x3(O),  object_transform_size(O, 3, 3).
test(offset_2x2)   :- offset(O), object_transform_size(O, 2, 2).

:- end_tests(object_transform_size).

:- begin_tests(object_transform_translate).

test(translate_positive) :-
    dot(D), object_transform_translate(D, 3, 5, obj(red, [r(3,5)])).

test(translate_negative) :-
    offset(O), object_transform_translate(O, -2, -3, Moved),
    Moved = obj(cyan, Cells),
    sort(Cells, Sorted),
    sort([r(0,0), r(0,1), r(1,0)], Expected),
    Sorted = Expected.

test(translate_zero) :-
    hline(H), object_transform_translate(H, 0, 0, H).

test(translate_preserves_color) :-
    corner(C), object_transform_translate(C, 1, 1, obj(yellow, _)).

:- end_tests(object_transform_translate).

:- begin_tests(object_transform_to_origin).

test(already_at_origin) :-
    dot(D), object_transform_to_origin(D, obj(red, [r(0,0)])).

test(offset_to_origin) :-
    offset(O), object_transform_to_origin(O, Norm),
    Norm = obj(cyan, Cells),
    sort(Cells, Sorted),
    sort([r(0,0), r(0,1), r(1,0)], Expected),
    Sorted = Expected.

test(vline_to_origin) :-
    vline(V), object_transform_to_origin(V, obj(green, [r(0,0), r(1,0)])).

test(color_preserved) :-
    offset(O), object_transform_to_origin(O, obj(cyan, _)).

:- end_tests(object_transform_to_origin).

:- begin_tests(object_transform_recolor).

test(recolor_dot) :-
    dot(D), object_transform_recolor(D, purple, obj(purple, [r(0,0)])).

test(recolor_sq2x2) :-
    sq2x2(S), object_transform_recolor(S, orange, obj(orange, _)),
    object_transform_recolor(S, orange, obj(_, Cells)),
    Cells = [r(0,0), r(0,1), r(1,0), r(1,1)].

test(recolor_preserves_cells) :-
    corner(C),
    object_transform_recolor(C, new_color, obj(_, Cells)),
    corner(obj(_, Cells)).

:- end_tests(object_transform_recolor).

:- begin_tests(object_transform_rot90).

% hline [r(0,0),r(0,1)]: bbox R0=0,C0=0,R1=0,C1=1,H=1.
% r(0,0): Lr=0,Lc=0 -> NR=0+0=0, NC=0+(1-1)-0=0 -> r(0,0)
% r(0,1): Lr=0,Lc=1 -> NR=0+1=1, NC=0+0-0=0 -> r(1,0)
% hline rotated 90 CW = vline.
test(hline_to_vline) :-
    hline(H), object_transform_rot90(H, obj(blue, Rotated)),
    sort(Rotated, S), sort([r(0,0),r(1,0)], E), S = E.

% vline [r(0,0),r(1,0)]: bbox R0=0,C0=0,R1=1,H=2.
% r(0,0): Lr=0,Lc=0 -> NR=0, NC=0+(2-1)-0=1 -> r(0,1)
% r(1,0): Lr=1,Lc=0 -> NR=0, NC=0+(2-1)-1=0 -> r(0,0)
% vline rotated 90 CW = hline.
test(vline_to_hline) :-
    vline(V), object_transform_rot90(V, obj(green, Rotated)),
    sort(Rotated, S), sort([r(0,0),r(0,1)], E), S = E.

% sq2x2 rotates to itself (all 4 cells stay in 2x2).
test(sq2x2_invariant) :-
    sq2x2(S), object_transform_rot90(S, obj(white, Rotated)),
    sort(Rotated, RS),
    sort([r(0,0),r(0,1),r(1,0),r(1,1)], E), RS = E.

% dot rotates to itself.
test(dot_invariant) :-
    dot(D), object_transform_rot90(D, obj(red, [r(0,0)])).

% corner L-shape: [r(0,0),r(0,1),r(1,0)] -> rot90 CW.
% bbox: R0=0,C0=0,R1=1,C1=1,H=2.
% r(0,0): Lr=0,Lc=0 -> NR=0,NC=1 -> r(0,1)
% r(0,1): Lr=0,Lc=1 -> NR=1,NC=1 -> r(1,1)
% r(1,0): Lr=1,Lc=0 -> NR=0,NC=0 -> r(0,0)
% Result: r(0,0), r(0,1), r(1,1) — L rotated.
test(corner_rot90) :-
    corner(C), object_transform_rot90(C, obj(yellow, Rotated)),
    sort(Rotated, S),
    sort([r(0,0),r(0,1),r(1,1)], E), S = E.

:- end_tests(object_transform_rot90).

:- begin_tests(object_transform_rot180).

% hline [r(0,0),r(0,1)]: bbox R0=0,R1=0,C0=0,C1=1.
% r(0,0) -> r(0+0-0,0+1-0)=r(0,1); r(0,1)->r(0,0). Back to hline.
test(hline_double_rot) :-
    hline(H), object_transform_rot180(H, obj(blue, Rotated)),
    sort(Rotated, S), sort([r(0,0),r(0,1)], E), S = E.

% sq2x2 invariant under 180.
test(sq2x2_180) :-
    sq2x2(S), object_transform_rot180(S, obj(white, Rotated)),
    sort(Rotated, RS),
    sort([r(0,0),r(0,1),r(1,0),r(1,1)], E), RS = E.

% dot invariant.
test(dot_180) :-
    dot(D), object_transform_rot180(D, obj(red, [r(0,0)])).

% rot90 twice equals rot180.
test(rot90_twice_eq_rot180) :-
    corner(C),
    object_transform_rot90(C, Once), object_transform_rot90(Once, Twice),
    Twice = obj(yellow, TwiceCells),
    object_transform_rot180(C, Direct),
    Direct = obj(yellow, DirectCells),
    sort(TwiceCells, TS), sort(DirectCells, DS), TS = DS.

:- end_tests(object_transform_rot180).

:- begin_tests(object_transform_rot270).

% rot270 = rot90 three times.
test(rot270_eq_rot90_thrice) :-
    corner(C),
    object_transform_rot90(C, R1), object_transform_rot90(R1, R2), object_transform_rot90(R2, R3),
    R3 = obj(yellow, ThriceCells),
    object_transform_rot270(C, Direct),
    Direct = obj(yellow, DirectCells),
    sort(ThriceCells, TS), sort(DirectCells, DS), TS = DS.

% hline -> rot270 = vline (same as rot90 for symmetric hline).
test(hline_rot270) :-
    hline(H), object_transform_rot270(H, obj(blue, Rotated)),
    sort(Rotated, S), sort([r(0,0),r(1,0)], E), S = E.

% dot invariant.
test(dot_270) :-
    dot(D), object_transform_rot270(D, obj(red, [r(0,0)])).

% Four rotations of corner cover 4 distinct shapes.
test(four_rotations_distinct) :-
    corner(C),
    object_transform_rot90(C, R1), object_transform_rot180(C, R2), object_transform_rot270(C, R3),
    R1 = obj(_, Cells1), R2 = obj(_, Cells2), R3 = obj(_, Cells3),
    corner(obj(_, Cells0)),
    sort(Cells0, S0), sort(Cells1, S1), sort(Cells2, S2), sort(Cells3, S3),
    S0 \= S1, S0 \= S2, S0 \= S3, S1 \= S2, S1 \= S3, S2 \= S3.

:- end_tests(object_transform_rot270).

:- begin_tests(object_transform_reflect_h).

% hline [r(0,0),r(0,1)]: bbox R0=0,R1=0. NR = 0+0-R = 0. Unchanged.
test(hline_reflect_h_same) :-
    hline(H), object_transform_reflect_h(H, obj(blue, Reflected)),
    sort(Reflected, S), sort([r(0,0),r(0,1)], E), S = E.

% vline [r(0,0),r(1,0)]: bbox R0=0,R1=1.
% r(0,0) -> NR=0+1-0=1 -> r(1,0); r(1,0) -> NR=0 -> r(0,0). Swapped = vline.
test(vline_reflect_h_same) :-
    vline(V), object_transform_reflect_h(V, obj(green, Reflected)),
    sort(Reflected, S), sort([r(0,0),r(1,0)], E), S = E.

% corner [r(0,0),r(0,1),r(1,0)]: reflect h: r(0,*)-> r(1,*); r(1,*)-> r(0,*).
% Result: [r(1,0),r(1,1),r(0,0)] = [r(0,0),r(1,0),r(1,1)].
test(corner_reflect_h) :-
    corner(C), object_transform_reflect_h(C, obj(yellow, Reflected)),
    sort(Reflected, S),
    sort([r(0,0), r(1,0), r(1,1)], E), S = E.

% reflect_h twice = identity.
test(reflect_h_twice_identity) :-
    corner(C),
    object_transform_reflect_h(C, Once), object_transform_reflect_h(Once, Twice),
    Twice = obj(yellow, TwiceCells),
    corner(obj(yellow, OrigCells)),
    sort(TwiceCells, TS), sort(OrigCells, OS), TS = OS.

:- end_tests(object_transform_reflect_h).

:- begin_tests(object_transform_reflect_v).

% vline [r(0,0),r(1,0)]: bbox C0=0,C1=0. NC = 0+0-C = 0. Unchanged.
test(vline_reflect_v_same) :-
    vline(V), object_transform_reflect_v(V, obj(green, Reflected)),
    sort(Reflected, S), sort([r(0,0),r(1,0)], E), S = E.

% hline [r(0,0),r(0,1)]: bbox C0=0,C1=1.
% r(0,0) -> NC=0+1-0=1 -> r(0,1); r(0,1)->NC=0->r(0,0). Swapped = hline.
test(hline_reflect_v_same) :-
    hline(H), object_transform_reflect_v(H, obj(blue, Reflected)),
    sort(Reflected, S), sort([r(0,0),r(0,1)], E), S = E.

% corner [r(0,0),r(0,1),r(1,0)]: reflect v: r(*,0)->r(*,1); r(*,1)->r(*,0).
% Result: [r(0,1),r(0,0),r(1,1)] = [r(0,0),r(0,1),r(1,1)].
test(corner_reflect_v) :-
    corner(C), object_transform_reflect_v(C, obj(yellow, Reflected)),
    sort(Reflected, S),
    sort([r(0,0), r(0,1), r(1,1)], E), S = E.

% reflect_v twice = identity.
test(reflect_v_twice_identity) :-
    corner(C),
    object_transform_reflect_v(C, Once), object_transform_reflect_v(Once, Twice),
    Twice = obj(yellow, TwiceCells),
    corner(obj(yellow, OrigCells)),
    sort(TwiceCells, TS), sort(OrigCells, OS), TS = OS.

:- end_tests(object_transform_reflect_v).

:- begin_tests(object_transform_merge).

% Merge two non-overlapping objects.
test(merge_non_overlapping) :-
    hline(H), vline(V),
    object_transform_merge(H, V, obj(blue, Merged)),
    sort(Merged, S),
    sort([r(0,0),r(0,1),r(1,0)], E), S = E.

% Merge uses first object's color.
test(merge_uses_first_color) :-
    left_half(L), right_half(R),
    object_transform_merge(L, R, obj(a, _)).

% Merge of overlapping objects deduplicates.
test(merge_deduplicates) :-
    left_half(L), right_half(R),
    object_transform_merge(L, R, obj(a, Merged)),
    % left=[r(0,0),r(0,1),r(1,0),r(1,1)], right=[r(0,1),r(0,2),r(1,1),r(1,2)].
    % Union = [r(0,0),r(0,1),r(0,2),r(1,0),r(1,1),r(1,2)].
    sort(Merged, S),
    sort([r(0,0),r(0,1),r(0,2),r(1,0),r(1,1),r(1,2)], E), S = E.

% Merge with self = self.
test(merge_self) :-
    corner(C), object_transform_merge(C, C, obj(yellow, Merged)),
    corner(obj(yellow, OrigCells)),
    sort(Merged, MS), sort(OrigCells, OS), MS = OS.

:- end_tests(object_transform_merge).

:- begin_tests(object_transform_diff).

% left_half minus right_half = left column only: r(0,0), r(1,0).
test(difference_left_minus_right) :-
    left_half(L), right_half(R),
    object_transform_diff(L, R, obj(a, Diff)),
    sort(Diff, S),
    sort([r(0,0), r(1,0)], E), S = E.

% right_half minus left_half = right column only: r(0,2), r(1,2).
test(difference_right_minus_left) :-
    left_half(L), right_half(R),
    object_transform_diff(R, L, obj(b, Diff)),
    sort(Diff, S),
    sort([r(0,2), r(1,2)], E), S = E.

% diff with non-overlapping = unchanged.
test(difference_non_overlapping) :-
    hline(H), vline(V),
    % hline=[r(0,0),r(0,1)], vline=[r(0,0),r(1,0)]. diff = [r(0,1)].
    object_transform_diff(H, V, obj(blue, Diff)),
    sort(Diff, S), sort([r(0,1)], E), S = E.

% diff with self = empty.
test(difference_self_empty) :-
    sq2x2(S), object_transform_diff(S, S, obj(white, [])).

:- end_tests(object_transform_diff).

:- begin_tests(object_transform_intersect).

% left_half intersect right_half = shared column: r(0,1), r(1,1).
test(intersect_overlap) :-
    left_half(L), right_half(R),
    object_transform_intersect(L, R, obj(a, Intersection)),
    sort(Intersection, S),
    sort([r(0,1), r(1,1)], E), S = E.

% intersect non-overlapping = empty (hline and vline share r(0,0)).
test(intersect_hline_vline) :-
    hline(H), vline(V),
    object_transform_intersect(H, V, obj(blue, Intersection)),
    sort(Intersection, S), sort([r(0,0)], E), S = E.

% intersect with self = self.
test(intersect_self) :-
    corner(C),
    object_transform_intersect(C, C, obj(yellow, Intersection)),
    corner(obj(yellow, OrigCells)),
    sort(Intersection, IS), sort(OrigCells, OS), IS = OS.

% merge/diff/intersect satisfy inclusion-exclusion: |L union R| = |L| + |R| - |L inter R|.
test(inclusion_exclusion) :-
    left_half(L), right_half(R),
    object_transform_merge(L, R, obj(_, Merged)), length(Merged, NM),
    left_half(obj(_, LC)), length(LC, NL),
    right_half(obj(_, RC)), length(RC, NR),
    object_transform_intersect(L, R, obj(_, Inter)), length(Inter, NI),
    NM =:= NL + NR - NI.

:- end_tests(object_transform_intersect).

:- begin_tests(object_transform_scale_up).

% dot scaled by 2: r(0,0) -> r(0,0),r(0,1),r(1,0),r(1,1).
test(dot_scale_2) :-
    dot(D), object_transform_scale_up(D, 2, obj(red, Scaled)),
    sort(Scaled, S),
    sort([r(0,0),r(0,1),r(1,0),r(1,1)], E), S = E.

% scale by 1 = identity.
test(scale_1_identity) :-
    corner(C), object_transform_scale_up(C, 1, obj(yellow, Scaled)),
    corner(obj(yellow, OrigCells)),
    sort(Scaled, SS), sort(OrigCells, OS), SS = OS.

% hline [r(0,0),r(0,1)] scaled by 2: each cell -> 2x2 block.
% r(0,0) -> r(0,0),r(0,1),r(1,0),r(1,1); r(0,1) -> r(0,2),r(0,3),r(1,2),r(1,3).
test(hline_scale_2) :-
    hline(H), object_transform_scale_up(H, 2, obj(blue, Scaled)),
    length(Scaled, 8).

% scale preserves color.
test(scale_preserves_color) :-
    vline(V), object_transform_scale_up(V, 3, obj(green, _)).

% cell count after scaling = original count * Factor * Factor.
test(cell_count_after_scale) :-
    sq2x2(S), object_transform_scale_up(S, 3, obj(_, Scaled)),
    length(Scaled, N),
    N =:= 4 * 3 * 3.

:- end_tests(object_transform_scale_up).
