:- use_module('../prolog/xform').

:- begin_tests(xform).

% xform_recolor/3 tests.
test(recolor_basic) :-
    xform_recolor(obj(1, [r(0,0), r(0,1)]), 5, obj(5, [r(0,0), r(0,1)])).

test(recolor_single) :-
    xform_recolor(obj(3, [r(2,4)]), 0, obj(0, [r(2,4)])).

test(recolor_same) :-
    xform_recolor(obj(7, [r(0,0), r(1,1)]), 7, obj(7, [r(0,0), r(1,1)])).

% xform_translate/3 tests.
test(translate_right) :-
    xform_translate(obj(1, [r(0,0), r(0,1)]), r(0,3), Out),
    Out = obj(1, [r(0,3), r(0,4)]).

test(translate_down) :-
    xform_translate(obj(2, [r(0,0)]), r(2,0), Out),
    Out = obj(2, [r(2,0)]).

test(translate_diagonal) :-
    xform_translate(obj(3, [r(1,1), r(1,2), r(2,1)]), r(2,3), Out),
    Out = obj(3, [r(3,4), r(3,5), r(4,4)]).

% xform_normalize/2 tests.
test(normalize_at_origin) :-
    xform_normalize(obj(1, [r(0,0), r(0,1)]), Out),
    Out = obj(1, [r(0,0), r(0,1)]).

test(normalize_offset) :-
    xform_normalize(obj(2, [r(3,4), r(3,5), r(4,4)]), Out),
    Out = obj(2, [r(0,0), r(0,1), r(1,0)]).

test(normalize_single) :-
    xform_normalize(obj(5, [r(7,3)]), Out),
    Out = obj(5, [r(0,0)]).

% xform_d4/3 tests.
test(d4_id) :-
    xform_d4(obj(1, [r(0,0), r(0,1)]), id, Out),
    Out = obj(1, [r(0,0), r(0,1)]).

test(d4_r90_hpair) :-
    % horizontal pair at r(0,0), r(0,1): r90 -> vertical pair at same top-left
    xform_d4(obj(1, [r(0,0), r(0,1)]), r90, Out),
    Out = obj(1, [r(0,0), r(1,0)]).

test(d4_fh) :-
    % L-shape: r(0,0), r(1,0), r(1,1). fh flips horizontally.
    % normalized H1=1, W1=1. fh: (R,C) -> (R, 1-C)
    % r(0,0)->(0,1), r(1,0)->(1,1), r(1,1)->(1,0). Sorted: r(0,1),r(1,0),r(1,1).
    xform_d4(obj(2, [r(0,0), r(1,0), r(1,1)]), fh, Out),
    Out = obj(2, [r(0,1), r(1,0), r(1,1)]).

% xform_same_cells/2 tests.
test(same_cells_basic) :-
    xform_same_cells(obj(1, [r(0,0), r(0,1)]), obj(5, [r(0,0), r(0,1)])).

test(same_cells_single) :-
    xform_same_cells(obj(3, [r(2,3)]), obj(7, [r(2,3)])).

test(same_cells_fail, [fail]) :-
    xform_same_cells(obj(1, [r(0,0)]), obj(2, [r(0,1)])).

% xform_cell_offset/3 tests.
test(cell_offset_right) :-
    xform_cell_offset(obj(1, [r(0,0), r(0,1)]), obj(1, [r(0,3), r(0,4)]), Off),
    Off = r(0,3).

test(cell_offset_down) :-
    xform_cell_offset(obj(2, [r(1,1)]), obj(2, [r(4,1)]), Off),
    Off = r(3,0).

test(cell_offset_diagonal) :-
    xform_cell_offset(obj(1, [r(0,0), r(1,0)]), obj(1, [r(2,3), r(3,3)]), Off),
    Off = r(2,3).

% xform_is_recolor/2 tests.
test(is_recolor_basic) :-
    xform_is_recolor(obj(1, [r(0,0), r(0,1)]), obj(5, [r(0,0), r(0,1)])).

test(is_recolor_single) :-
    xform_is_recolor(obj(3, [r(2,3)]), obj(7, [r(2,3)])).

test(is_recolor_fail_same_color, [fail]) :-
    xform_is_recolor(obj(4, [r(0,0)]), obj(4, [r(0,0)])).

% xform_cells_added/3 tests.
test(cells_added_basic) :-
    Obj1 = obj(1, [r(0,0), r(0,1)]),
    Obj2 = obj(1, [r(0,0), r(0,1), r(0,2)]),
    xform_cells_added(Obj1, Obj2, Added),
    Added = [r(0,2)].

test(cells_added_none) :-
    Obj1 = obj(1, [r(0,0), r(0,1)]),
    Obj2 = obj(2, [r(0,0), r(0,1)]),
    xform_cells_added(Obj1, Obj2, Added),
    Added = [].

test(cells_added_two) :-
    Obj1 = obj(1, [r(0,0)]),
    Obj2 = obj(1, [r(0,0), r(0,1), r(1,0)]),
    xform_cells_added(Obj1, Obj2, Added),
    Added = [r(0,1), r(1,0)].

% xform_cells_removed/3 tests.
test(cells_removed_basic) :-
    Obj1 = obj(1, [r(0,0), r(0,1), r(0,2)]),
    Obj2 = obj(1, [r(0,0), r(0,1)]),
    xform_cells_removed(Obj1, Obj2, Removed),
    Removed = [r(0,2)].

test(cells_removed_none) :-
    Obj1 = obj(1, [r(0,0)]),
    Obj2 = obj(2, [r(0,0), r(0,1)]),
    xform_cells_removed(Obj1, Obj2, Removed),
    Removed = [].

test(cells_removed_all) :-
    Obj1 = obj(1, [r(0,0), r(1,1)]),
    Obj2 = obj(1, [r(5,5)]),
    xform_cells_removed(Obj1, Obj2, Removed),
    Removed = [r(0,0), r(1,1)].

% xform_cells_kept/3 tests.
test(cells_kept_partial) :-
    Obj1 = obj(1, [r(0,0), r(0,1), r(0,2)]),
    Obj2 = obj(2, [r(0,1), r(0,2), r(0,3)]),
    xform_cells_kept(Obj1, Obj2, Kept),
    Kept = [r(0,1), r(0,2)].

test(cells_kept_none) :-
    Obj1 = obj(1, [r(0,0)]),
    Obj2 = obj(1, [r(1,1)]),
    xform_cells_kept(Obj1, Obj2, Kept),
    Kept = [].

test(cells_kept_all) :-
    Obj1 = obj(1, [r(0,0), r(0,1)]),
    Obj2 = obj(3, [r(0,0), r(0,1)]),
    xform_cells_kept(Obj1, Obj2, Kept),
    Kept = [r(0,0), r(0,1)].

% xform_overlap_count/3 tests.
test(overlap_two) :-
    xform_overlap_count(
        obj(1, [r(0,0), r(0,1), r(0,2)]),
        obj(2, [r(0,1), r(0,2), r(0,3)]), N),
    N = 2.

test(overlap_zero) :-
    xform_overlap_count(obj(1, [r(0,0)]), obj(2, [r(1,1)]), N),
    N = 0.

test(overlap_full) :-
    xform_overlap_count(
        obj(1, [r(0,0), r(0,1)]),
        obj(2, [r(0,0), r(0,1)]), N),
    N = 2.

% xform_any_d4/3 tests.
test(any_d4_id) :-
    xform_any_d4(obj(1, [r(0,0), r(0,1)]), obj(2, [r(0,0), r(0,1)]), Op),
    Op = id.

test(any_d4_r90) :-
    % horizontal pair [r(0,0),r(0,1)] -> vertical pair [r(0,0),r(1,0)] via r90
    xform_any_d4(obj(1, [r(0,0), r(0,1)]), obj(2, [r(0,0), r(1,0)]), Op),
    Op = r90.

test(any_d4_fv) :-
    % L-shape [r(0,0),r(1,0),r(1,1)]: fv -> (H1-R,C): r(0,0)->(1,0), r(1,0)->(0,0), r(1,1)->(0,1)
    % sorted: [r(0,0),r(0,1),r(1,0)]
    xform_any_d4(obj(1, [r(0,0), r(1,0), r(1,1)]),
              obj(2, [r(0,0), r(0,1), r(1,0)]), Op),
    memberchk(Op, [r90, fv]).

% xform_scale_factor/3 tests.
test(scale_2x) :-
    Obj1 = obj(1, [r(0,0), r(0,1)]),
    Obj2 = obj(1, [r(0,0), r(0,1), r(0,2), r(0,3)]),
    xform_scale_factor(Obj1, Obj2, N),
    N = 2.

test(scale_1x) :-
    xform_scale_factor(obj(1, [r(0,0), r(1,0)]), obj(2, [r(0,0), r(0,1)]), N),
    N = 1.

test(scale_fail, [fail]) :-
    xform_scale_factor(obj(1, [r(0,0), r(0,1)]), obj(2, [r(0,0), r(0,1), r(0,2)]), _).

% xform_merge/3 tests.
test(merge_basic) :-
    Obj1 = obj(3, [r(0,0), r(0,1)]),
    Obj2 = obj(3, [r(1,0), r(1,1)]),
    xform_merge(Obj1, Obj2, Out),
    Out = obj(3, [r(0,0), r(0,1), r(1,0), r(1,1)]).

test(merge_overlap) :-
    Obj1 = obj(2, [r(0,0), r(0,1)]),
    Obj2 = obj(2, [r(0,1), r(0,2)]),
    xform_merge(Obj1, Obj2, Out),
    Out = obj(2, [r(0,0), r(0,1), r(0,2)]).

test(merge_single) :-
    xform_merge(obj(5, [r(0,0)]), obj(5, [r(1,1)]), Out),
    Out = obj(5, [r(0,0), r(1,1)]).

:- end_tests(xform).
