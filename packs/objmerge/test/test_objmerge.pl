:- use_module('../prolog/objmerge').
:- use_module(library(plunit)).

:- begin_tests(objmerge).

% --- Test fixtures ---
% dot at r(0,0) red
dot(obj(r, [r(0,0)])).
% dot at r(0,1) blue
dot_right(obj(b, [r(0,1)])).
% dot at r(1,0) green
dot_below(obj(g, [r(1,0)])).
% bar_h: horizontal bar at r(0,0)..r(0,2) red
bar_h(obj(r, [r(0,0),r(0,1),r(0,2)])).
% bar_h2: horizontal bar at r(0,2)..r(0,4) blue
bar_h2(obj(b, [r(0,2),r(0,3),r(0,4)])).
% bar_v: vertical bar at r(0,0)..r(2,0) green
bar_v(obj(g, [r(0,0),r(1,0),r(2,0)])).
% sq: 2x2 square at rows 0-1, cols 0-1 yellow
sq(obj(y, [r(0,0),r(0,1),r(1,0),r(1,1)])).
% sq_right: 2x2 square at rows 0-1, cols 2-3
sq_right(obj(b, [r(0,2),r(0,3),r(1,2),r(1,3)])).
% sq2: 2x2 square at rows 1-2, cols 1-2 (overlaps sq)
sq2(obj(p, [r(1,1),r(1,2),r(2,1),r(2,2)])).
% disconnected: two separate dots at r(0,0) and r(2,2)
disconnected(obj(r, [r(0,0),r(2,2)])).
% cross: 5-cell cross shape at r(0,2),r(1,0)..r(1,4),r(2,2)
cross(obj(r, [r(0,2),r(1,0),r(1,1),r(1,2),r(1,3),r(1,4),r(2,2)])).
% two_blobs: two separate 4-connected blobs
two_blobs(obj(b, [r(0,0),r(0,1),r(2,2),r(2,3)])).
% lshape: L-shape at r(0,0),r(1,0),r(2,0),r(2,1)
lshape(obj(p, [r(0,0),r(1,0),r(2,0),r(2,1)])).

% --- mg_union_cells/4 ---

test(union_disjoint) :-
    dot(D), dot_right(DR),
    mg_union_cells(D, DR, x, U),
    U = obj(x, Cells),
    msort(Cells, SC),
    SC == [r(0,0),r(0,1)].

test(union_overlap) :-
    bar_h(B), bar_h2(B2),
    % B: 0-2, B2: 2-4, overlap at r(0,2)
    mg_union_cells(B, B2, x, U),
    U = obj(x, Cells),
    length(Cells, 5).

test(union_self) :-
    dot(D),
    mg_union_cells(D, D, x, U),
    U = obj(x, [r(0,0)]).

% --- mg_intersect_cells/4 ---

test(intersect_overlap) :-
    bar_h(B), bar_h2(B2),
    % overlap at r(0,2) only
    mg_intersect_cells(B, B2, x, I),
    I = obj(x, [r(0,2)]).

test(intersect_disjoint) :-
    dot(D), dot_right(DR),
    mg_intersect_cells(D, DR, x, I),
    I = obj(x, []).

test(intersect_sq) :-
    sq(S), sq2(S2),
    % overlap at r(1,1) only
    mg_intersect_cells(S, S2, x, I),
    I = obj(x, [r(1,1)]).

% --- mg_diff_cells/4 ---

test(diff_partial_overlap) :-
    bar_h(B), bar_h2(B2),
    % B \ B2 = r(0,0), r(0,1)
    mg_diff_cells(B, B2, x, D),
    D = obj(x, Cells),
    msort(Cells, SC),
    SC == [r(0,0),r(0,1)].

test(diff_disjoint) :-
    dot(D1), dot_right(D2),
    mg_diff_cells(D1, D2, x, Diff),
    Diff = obj(x, [r(0,0)]).

test(diff_same) :-
    dot(D),
    mg_diff_cells(D, D, x, Diff),
    Diff = obj(x, []).

% --- mg_sym_diff_cells/4 ---

test(sym_diff_partial) :-
    bar_h(B), bar_h2(B2),
    % B \ B2 = {0,1}, B2 \ B = {3,4}; sym diff = {r(0,0),r(0,1),r(0,3),r(0,4)}
    mg_sym_diff_cells(B, B2, x, S),
    S = obj(x, Cells),
    length(Cells, 4).

test(sym_diff_disjoint) :-
    dot(D1), dot_right(D2),
    mg_sym_diff_cells(D1, D2, x, S),
    S = obj(x, Cells),
    length(Cells, 2).

test(sym_diff_same) :-
    dot(D),
    mg_sym_diff_cells(D, D, x, S),
    S = obj(x, []).

% --- mg_concat_h/4 ---

test(concat_h_gap0) :-
    dot(D), dot_below(DB),
    % D max col = 0, DB min col = 0; shift DB by (0+1+0-0)=1
    % Result: D at (0,0), DB shifted to (1,1)
    mg_concat_h(D, DB, 0, obj(r, Cells)),
    msort(Cells, SC),
    SC == [r(0,0),r(1,1)].

test(concat_h_gap1) :-
    dot(D), dot_right(DR),
    % D max col=0, DR min col=1; shift=0+1+1-1=1 -> (0,2)
    mg_concat_h(D, DR, 1, obj(r, Cells)),
    msort(Cells, SC),
    SC == [r(0,0),r(0,2)].

test(concat_h_bars) :-
    bar_h(B1), bar_h(B2),
    % B1 max col=2, B2 min col=0; shift=2+1+0-0=3 -> B2 at cols 3-5
    mg_concat_h(B1, B2, 0, obj(r, Cells)),
    length(Cells, 6),
    member(r(0,3), Cells),
    member(r(0,5), Cells).

% --- mg_concat_v/4 ---

test(concat_v_gap0) :-
    dot(D), dot_right(DR),
    % D max row=0, DR min row=0; shift=0+1+0-0=1 -> (1,1)
    mg_concat_v(D, DR, 0, obj(r, Cells)),
    msort(Cells, SC),
    SC == [r(0,0),r(1,1)].

test(concat_v_bars) :-
    bar_v(V1), bar_v(V2),
    % V1 max row=2, V2 min row=0; shift=2+1+0-0=3 -> V2 at rows 3-5
    mg_concat_v(V1, V2, 0, obj(g, Cells)),
    length(Cells, 6),
    member(r(3,0), Cells),
    member(r(5,0), Cells).

% --- mg_merge_list/3 ---

test(merge_list_basic) :-
    dot(D), dot_right(DR), dot_below(DB),
    mg_merge_list([D, DR, DB], x, M),
    M = obj(x, Cells),
    length(Cells, 3).

test(merge_list_with_overlap) :-
    dot(D), bar_h(B),
    % D at r(0,0) is also in B; union should have 3 cells
    mg_merge_list([D, B], x, M),
    M = obj(x, Cells),
    length(Cells, 3).

test(merge_list_single) :-
    dot(D),
    mg_merge_list([D], x, M),
    M = obj(x, [r(0,0)]).

% --- mg_subtract_list/4 ---

test(subtract_list_basic) :-
    bar_h(B), dot(D),
    % Remove dot (r(0,0)) from bar: leaves r(0,1) and r(0,2)
    mg_subtract_list(B, [D], x, R),
    R = obj(x, Cells),
    length(Cells, 2),
    \+ member(r(0,0), Cells).

test(subtract_list_empty) :-
    bar_h(B),
    mg_subtract_list(B, [], x, R),
    R = obj(x, Cells),
    length(Cells, 3).

% --- mg_expand_bbox/2 ---

test(expand_bbox_sq) :-
    sq(S),
    % bbox is already the full 2x2 square
    mg_expand_bbox(S, Expanded),
    Expanded = obj(y, Cells),
    msort(Cells, SC),
    SC == [r(0,0),r(0,1),r(1,0),r(1,1)].

test(expand_bbox_lshape) :-
    lshape(L),
    % L bbox: rows 0-2, cols 0-1. Expanded = 3x2 = 6 cells.
    mg_expand_bbox(L, Expanded),
    Expanded = obj(p, Cells),
    length(Cells, 6).

% --- mg_hollow_bbox/2 ---

test(hollow_bbox_sq) :-
    sq(S),
    % 2x2 square: all 4 cells are on the border
    mg_hollow_bbox(S, H),
    H = obj(y, Cells),
    length(Cells, 4).

test(hollow_bbox_3x3) :-
    % Create a 3x3 solid square
    Obj = obj(r, [r(0,0),r(0,1),r(0,2),
                  r(1,0),r(1,1),r(1,2),
                  r(2,0),r(2,1),r(2,2)]),
    mg_hollow_bbox(Obj, H),
    H = obj(r, Frame),
    % Frame has 8 border cells; center r(1,1) is excluded
    length(Frame, 8),
    \+ member(r(1,1), Frame).

% --- mg_pad/4 ---

test(pad_dot_by1) :-
    dot(D),
    % D at r(0,0); pad by 1 -> 3x3 = 9 cells, all colored x
    mg_pad(D, 1, x, P),
    P = obj(x, Cells),
    length(Cells, 9).

test(pad_dot_by2) :-
    dot(D),
    % pad by 2 -> 5x5 = 25 cells
    mg_pad(D, 2, x, P),
    P = obj(x, Cells),
    length(Cells, 25).

% --- mg_split_cc4/2 ---

test(split_cc4_connected) :-
    bar_h(B),
    % All 3 cells 4-connected, so 1 component
    mg_split_cc4(B, Parts),
    length(Parts, 1).

test(split_cc4_disconnected) :-
    disconnected(D),
    % r(0,0) and r(2,2) are not 4-connected: 2 components
    mg_split_cc4(D, Parts),
    length(Parts, 2).

test(split_cc4_cross) :-
    cross(C),
    % Cross is one 4-connected component
    mg_split_cc4(C, Parts),
    length(Parts, 1).

% --- mg_split_cc8/2 ---

test(split_cc8_connected) :-
    disconnected(D),
    % r(0,0) and r(2,2) are 8-connected via diagonal: 1 component?
    % Distance: r(0,0) to r(2,2) is not 8-adjacent in one step (need 2 steps)
    % r(0,0) -> r(1,1) -> r(2,2): but r(1,1) is not in the set
    % So still 2 components for 8-connectivity
    mg_split_cc8(D, Parts),
    length(Parts, 2).

test(split_cc8_diagonal) :-
    % Two cells that are 8-adjacent: r(0,0) and r(1,1)
    Obj = obj(r, [r(0,0), r(1,1)]),
    mg_split_cc8(Obj, Parts),
    length(Parts, 1).

test(split_cc8_two_blobs) :-
    two_blobs(TB),
    % [r(0,0),r(0,1)] and [r(2,2),r(2,3)] — not 8-adjacent to each other
    mg_split_cc8(TB, Parts),
    length(Parts, 2).

% --- mg_n_components4/2 ---

test(n_components4_one) :-
    bar_h(B),
    mg_n_components4(B, N),
    N == 1.

test(n_components4_two) :-
    disconnected(D),
    mg_n_components4(D, N),
    N == 2.

test(n_components4_sq) :-
    sq(S),
    mg_n_components4(S, N),
    N == 1.

% --- Additional tests ---

test(union_three_separate) :-
    dot(D), dot_right(DR), dot_below(DB),
    mg_union_cells(D, DR, x, U1),
    mg_union_cells(U1, DB, x, U2),
    U2 = obj(x, Cells),
    length(Cells, 3).

test(subtract_list_remove_all) :-
    bar_h(B), dot(D), dot_right(DR),
    % B has r(0,0),r(0,1),r(0,2); remove D=r(0,0) and DR=r(0,1)
    mg_subtract_list(B, [D, DR], x, R),
    R = obj(x, [r(0,2)]).

test(expand_bbox_dot) :-
    dot(D),
    % bbox of a single dot is just that dot; expanded = same
    mg_expand_bbox(D, E),
    E = obj(r, [r(0,0)]).

test(split_cc4_lshape) :-
    lshape(L),
    % L = r(0,0),r(1,0),r(2,0),r(2,1): all 4-connected, 1 component
    mg_split_cc4(L, Parts),
    length(Parts, 1).

:- end_tests(objmerge).
