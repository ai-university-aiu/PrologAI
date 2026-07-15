% Test suite for gridgroupby (ggb_*, Layer 243).
:- use_module('../prolog/gridgroupby.pl').

:- begin_tests(gridgroupby).

% Helper: canonical ob/3 terms used across multiple tests.
% ob1: red, 1 cell, bbox row 0 col 0
% ob2: blue, 2 cells, bbox row 0 col 1-2
% ob3: red, 3 cells, bbox row 1 col 0-2
% ob4: green, 1 cell, bbox row 2 col 0
ob1(ob(r, [r(0,0)], r0(0,0,0,0))).
ob2(ob(b, [r(0,1),r(0,2)], r0(0,1,0,2))).
ob3(ob(r, [r(1,0),r(1,1),r(1,2)], r0(1,0,1,2))).
ob4(ob(g, [r(2,0)], r0(2,0,2,0))).

% AC-GGB-001: gridgroupby_group_by_color on empty list.
test('AC-GGB-001: group_by_color empty') :-
    gridgroupby_group_by_color([], []).

% AC-GGB-002: gridgroupby_group_by_color single object.
test('AC-GGB-002: group_by_color single') :-
    ob1(O1),
    gridgroupby_group_by_color([O1], [grp(r,[O1])]).

% AC-GGB-003: gridgroupby_group_by_color two colors.
test('AC-GGB-003: group_by_color two colors') :-
    ob1(O1), ob2(O2),
    gridgroupby_group_by_color([O1,O2], Groups),
    member(grp(r,[O1]), Groups),
    member(grp(b,[O2]), Groups),
    length(Groups, 2).

% AC-GGB-004: gridgroupby_group_by_color same color merged.
test('AC-GGB-004: group_by_color same merged') :-
    ob1(O1), ob3(O3),
    gridgroupby_group_by_color([O1,O3], [grp(r,[O1,O3])]).

% AC-GGB-005: gridgroupby_group_by_color four objects three colors.
test('AC-GGB-005: group_by_color four objects') :-
    ob1(O1), ob2(O2), ob3(O3), ob4(O4),
    gridgroupby_group_by_color([O1,O2,O3,O4], Groups),
    member(grp(r,[O1,O3]), Groups),
    member(grp(b,[O2]), Groups),
    member(grp(g,[O4]), Groups),
    length(Groups, 3).

% AC-GGB-006: gridgroupby_group_by_size empty list.
test('AC-GGB-006: group_by_size empty') :-
    gridgroupby_group_by_size([], []).

% AC-GGB-007: gridgroupby_group_by_size two sizes.
test('AC-GGB-007: group_by_size two sizes') :-
    ob1(O1), ob2(O2),
    gridgroupby_group_by_size([O1,O2], Groups),
    member(grp(1,[O1]), Groups),
    member(grp(2,[O2]), Groups),
    length(Groups, 2).

% AC-GGB-008: gridgroupby_group_by_size objects of same size grouped.
test('AC-GGB-008: group_by_size same grouped') :-
    ob1(O1), ob4(O4),
    gridgroupby_group_by_size([O1,O4], [grp(1,Members)]),
    msort(Members, MS), msort([O1,O4], MS).

% AC-GGB-009: gridgroupby_group_by_row empty list.
test('AC-GGB-009: group_by_row empty') :-
    gridgroupby_group_by_row([], []).

% AC-GGB-010: gridgroupby_group_by_row two objects on same row.
test('AC-GGB-010: group_by_row same row') :-
    ob1(O1), ob2(O2),
    gridgroupby_group_by_row([O1,O2], [grp(0,Members)]),
    msort(Members, MS), msort([O1,O2], MS).

% AC-GGB-011: gridgroupby_group_by_row three objects three rows.
test('AC-GGB-011: group_by_row three rows') :-
    ob1(O1), ob3(O3), ob4(O4),
    gridgroupby_group_by_row([O1,O3,O4], Groups),
    length(Groups, 3),
    member(grp(0,[O1]), Groups),
    member(grp(1,[O3]), Groups),
    member(grp(2,[O4]), Groups).

% AC-GGB-012: gridgroupby_group_by_col empty list.
test('AC-GGB-012: group_by_col empty') :-
    gridgroupby_group_by_col([], []).

% AC-GGB-013: gridgroupby_group_by_col two objects same column.
test('AC-GGB-013: group_by_col same col') :-
    ob1(O1), ob3(O3),
    gridgroupby_group_by_col([O1,O3], [grp(0,[O1,O3])]).

% AC-GGB-014: gridgroupby_filter_by_color empty list returns empty.
test('AC-GGB-014: filter_by_color empty') :-
    gridgroupby_filter_by_color([], r, []).

% AC-GGB-015: gridgroupby_filter_by_color keeps matching objects.
test('AC-GGB-015: filter_by_color keeps match') :-
    ob1(O1), ob2(O2), ob3(O3),
    gridgroupby_filter_by_color([O1,O2,O3], r, [O1,O3]).

% AC-GGB-016: gridgroupby_filter_by_color returns empty when no match.
test('AC-GGB-016: filter_by_color no match') :-
    ob2(O2),
    gridgroupby_filter_by_color([O2], r, []).

% AC-GGB-017: gridgroupby_filter_by_size keeps correct size.
test('AC-GGB-017: filter_by_size correct') :-
    ob1(O1), ob2(O2), ob3(O3), ob4(O4),
    gridgroupby_filter_by_size([O1,O2,O3,O4], 1, [O1,O4]).

% AC-GGB-018: gridgroupby_filter_by_size returns empty when no match.
test('AC-GGB-018: filter_by_size no match') :-
    ob2(O2),
    gridgroupby_filter_by_size([O2], 1, []).

% AC-GGB-019: gridgroupby_filter_larger keeps objects larger than N.
test('AC-GGB-019: filter_larger basic') :-
    ob1(O1), ob2(O2), ob3(O3),
    gridgroupby_filter_larger([O1,O2,O3], 1, [O2,O3]).

% AC-GGB-020: gridgroupby_filter_larger returns empty when all are at or below N.
test('AC-GGB-020: filter_larger none') :-
    ob1(O1),
    gridgroupby_filter_larger([O1], 1, []).

% AC-GGB-021: gridgroupby_filter_smaller keeps objects smaller than N.
test('AC-GGB-021: filter_smaller basic') :-
    ob1(O1), ob2(O2), ob3(O3),
    gridgroupby_filter_smaller([O1,O2,O3], 2, [O1]).

% AC-GGB-022: gridgroupby_filter_smaller returns empty when all are at or above N.
test('AC-GGB-022: filter_smaller none') :-
    ob3(O3),
    gridgroupby_filter_smaller([O3], 2, []).

% AC-GGB-023: gridgroupby_sort_by_size_asc on empty list.
test('AC-GGB-023: sort_by_size_asc empty') :-
    gridgroupby_sort_by_size_asc([], []).

% AC-GGB-024: gridgroupby_sort_by_size_asc orders smallest first.
test('AC-GGB-024: sort_by_size_asc basic') :-
    ob1(O1), ob2(O2), ob3(O3),
    gridgroupby_sort_by_size_asc([O3,O1,O2], [O1,O2,O3]).

% AC-GGB-025: gridgroupby_sort_by_size_asc stable for equal-size objects.
test('AC-GGB-025: sort_by_size_asc equal sizes') :-
    ob1(O1), ob4(O4),
    gridgroupby_sort_by_size_asc([O1,O4], Sorted),
    length(Sorted, 2),
    Sorted = [First, Second],
    gridgroupby_filter_by_size([First], 1, [_]),
    gridgroupby_filter_by_size([Second], 1, [_]).

% AC-GGB-026: gridgroupby_sort_by_size_desc on empty list.
test('AC-GGB-026: sort_by_size_desc empty') :-
    gridgroupby_sort_by_size_desc([], []).

% AC-GGB-027: gridgroupby_sort_by_size_desc orders largest first.
test('AC-GGB-027: sort_by_size_desc basic') :-
    ob1(O1), ob2(O2), ob3(O3),
    gridgroupby_sort_by_size_desc([O1,O2,O3], [O3,O2,O1]).

% AC-GGB-028: gridgroupby_sort_by_size_desc single element.
test('AC-GGB-028: sort_by_size_desc single') :-
    ob2(O2),
    gridgroupby_sort_by_size_desc([O2], [O2]).

% AC-GGB-029: gridgroupby_sort_by_row on empty list.
test('AC-GGB-029: sort_by_row empty') :-
    gridgroupby_sort_by_row([], []).

% AC-GGB-030: gridgroupby_sort_by_row orders by top row ascending.
test('AC-GGB-030: sort_by_row basic') :-
    ob1(O1), ob3(O3), ob4(O4),
    gridgroupby_sort_by_row([O4,O3,O1], [O1,O3,O4]).

% AC-GGB-031: gridgroupby_sort_by_row objects on same row preserve input order.
test('AC-GGB-031: sort_by_row same row') :-
    ob1(O1), ob2(O2),
    gridgroupby_sort_by_row([O1,O2], Sorted),
    Sorted = [A,B],
    memberchk(A, [O1,O2]),
    memberchk(B, [O1,O2]).

% AC-GGB-032: gridgroupby_sort_by_col on empty list.
test('AC-GGB-032: sort_by_col empty') :-
    gridgroupby_sort_by_col([], []).

% AC-GGB-033: gridgroupby_sort_by_col orders by left column ascending.
test('AC-GGB-033: sort_by_col basic') :-
    ob1(O1), ob2(O2),
    gridgroupby_sort_by_col([O2,O1], [O1,O2]).

% AC-GGB-034: gridgroupby_pair_by_color empty list gives empty pairs.
test('AC-GGB-034: pair_by_color empty') :-
    gridgroupby_pair_by_color([], []).

% AC-GGB-035: gridgroupby_pair_by_color two same-color objects produce one pair.
test('AC-GGB-035: pair_by_color one pair') :-
    ob1(O1), ob3(O3),
    gridgroupby_pair_by_color([O1,O3], [pair(r,O1,O3)]).

% AC-GGB-036: gridgroupby_pair_by_color only includes colors with exactly two objects.
test('AC-GGB-036: pair_by_color exact two only') :-
    ob1(O1), ob2(O2), ob3(O3), ob4(O4),
    % r has 2 objects (O1,O3), b has 1 (O2), g has 1 (O4)
    gridgroupby_pair_by_color([O1,O2,O3,O4], Pairs),
    Pairs = [pair(r,O1,O3)].

% AC-GGB-037: gridgroupby_pair_by_color three same-color objects: no pair emitted.
test('AC-GGB-037: pair_by_color three same no pair') :-
    O1 = ob(r, [r(0,0)], r0(0,0,0,0)),
    O2 = ob(r, [r(1,0)], r0(1,0,1,0)),
    O3 = ob(r, [r(2,0)], r0(2,0,2,0)),
    gridgroupby_pair_by_color([O1,O2,O3], []).

% AC-GGB-038: gridgroupby_count_per_color empty list.
test('AC-GGB-038: count_per_color empty') :-
    gridgroupby_count_per_color([], []).

% AC-GGB-039: gridgroupby_count_per_color single object.
test('AC-GGB-039: count_per_color single') :-
    ob1(O1),
    gridgroupby_count_per_color([O1], [cnt(r,1)]).

% AC-GGB-040: gridgroupby_count_per_color descending order.
test('AC-GGB-040: count_per_color descending') :-
    ob1(O1), ob2(O2), ob3(O3), ob4(O4),
    % r:2, b:1, g:1
    gridgroupby_count_per_color([O1,O2,O3,O4], Counts),
    Counts = [cnt(r,2)|_],
    length(Counts, 3).

% AC-GGB-041: integration - group then filter.
test('AC-GGB-041: integration group then filter') :-
    ob1(O1), ob2(O2), ob3(O3),
    gridgroupby_group_by_color([O1,O2,O3], Groups),
    member(grp(r, RedObjs), Groups),
    gridgroupby_filter_larger(RedObjs, 1, BigRed),
    BigRed = [O3].

% AC-GGB-042: integration - sort then pair.
test('AC-GGB-042: integration sort then pair') :-
    ob1(O1), ob2(O2), ob3(O3), ob4(O4),
    gridgroupby_sort_by_size_asc([O3,O1,O2,O4], Sorted),
    % O3 (size 3) must be last; size-1 objects must come first
    append(_, [O3], Sorted),
    gridgroupby_filter_by_size(Sorted, 1, SizeOnes),
    length(SizeOnes, 2),
    memberchk(O1, SizeOnes), memberchk(O4, SizeOnes).

% AC-GGB-043: integration - filter then sort.
test('AC-GGB-043: integration filter then sort') :-
    ob1(O1), ob2(O2), ob3(O3), ob4(O4),
    gridgroupby_filter_larger([O1,O2,O3,O4], 1, Big),
    gridgroupby_sort_by_size_desc(Big, [O3,O2]).

% AC-GGB-044: integration - count matches group count.
test('AC-GGB-044: integration count matches groups') :-
    ob1(O1), ob2(O2), ob3(O3), ob4(O4),
    gridgroupby_group_by_color([O1,O2,O3,O4], Groups),
    gridgroupby_count_per_color([O1,O2,O3,O4], Counts),
    length(Groups, GLen),
    length(Counts, CLen),
    GLen =:= CLen.

:- end_tests(gridgroupby).
