% posop.pl - Layer 162: Position-Based Sorting, Filtering, and Assignment for
%             Object Collections (po_* prefix).
% General-purpose predicates that operate on the spatial position of
% obj(Color, Cells) terms. "Position" is derived from the Cells list of r(R,C)
% terms: topmost row = minimum R; leftmost col = minimum C.
% Provides: position extraction, reading-order sort, row/col rank queries,
% position-threshold filtering, band filtering, and color assignment by position.
:- module(posop, [
    posop_row_of/2,
    posop_col_of/2,
    posop_row_rank/3,
    posop_col_rank/3,
    posop_reading_rank/3,
    posop_assign_by_row/3,
    posop_assign_by_col/3,
    posop_assign_reading/3,
    posop_above_row/3,
    posop_from_row/3,
    posop_left_of/3,
    posop_from_col/3,
    posop_in_row_band/4,
    posop_in_col_band/4
]).
% min_list/2 and member/2 and nth1/3 are imported; findall/3 and keysort/2 are built-ins.
:- use_module(library(lists), [member/2, nth1/3, min_list/2]).

% posop_row_of(+Obj, -Row): Row is the topmost (minimum) row index of Obj's cells.
posop_row_of(obj(_, Cells), Row) :-
% Collect all row indices from the r(R,C) cell terms.
    findall(R, member(r(R,_), Cells), Rs),
% The topmost row is the minimum row index.
    min_list(Rs, Row).

% posop_col_of(+Obj, -Col): Col is the leftmost (minimum) column index of Obj's cells.
posop_col_of(obj(_, Cells), Col) :-
% Collect all column indices from the r(R,C) cell terms.
    findall(C, member(r(_,C), Cells), Cs),
% The leftmost column is the minimum column index.
    min_list(Cs, Col).

% posop_sort_by_row_(+Objs, -Sorted): private stable sort by topmost row ascending.
% Equal topmost rows preserve the original relative order of objects.
posop_sort_by_row_(Objs, Sorted) :-
% Build Row-Obj keysort pairs; Row is each object's topmost row.
    findall(Row-O, (member(O, Objs), posop_row_of(O, Row)), Pairs),
% keysort/2 is stable ascending: equal keys preserve input order.
    keysort(Pairs, SortedPairs),
% Strip keys to recover the sorted object list.
    findall(O, member(_-O, SortedPairs), Sorted).

% posop_sort_by_col_(+Objs, -Sorted): private stable sort by leftmost col ascending.
% Equal leftmost cols preserve the original relative order of objects.
posop_sort_by_col_(Objs, Sorted) :-
% Build Col-Obj keysort pairs; Col is each object's leftmost column.
    findall(Col-O, (member(O, Objs), posop_col_of(O, Col)), Pairs),
% keysort/2 is stable ascending: equal keys preserve input order.
    keysort(Pairs, SortedPairs),
% Strip keys to recover the sorted object list.
    findall(O, member(_-O, SortedPairs), Sorted).

% posop_sort_reading_(+Objs, -Sorted): private stable reading-order sort.
% Reading order: ascending by topmost row, then ascending by leftmost col within
% equal rows. Uses compound key Row-Col so keysort sorts row-first then col-second.
posop_sort_reading_(Objs, Sorted) :-
% Build (Row-Col)-Obj pairs; Row-Col compound key sorts row-then-col.
    findall((Row-Col)-O,
            (member(O, Objs), posop_row_of(O, Row), posop_col_of(O, Col)),
            Pairs),
% keysort on Row-Col compound key produces reading order (stable).
    keysort(Pairs, SortedPairs),
% Strip keys to recover the sorted object list.
    findall(O, member(_-O, SortedPairs), Sorted).

% posop_zip_recolor_(+Objs, +Colors, -Result): private helper to recolor objects in
% parallel with a color list, truncating at the shorter of the two lists.
% Base case: object list exhausted.
posop_zip_recolor_([], _, []) :- !.
% Base case: color list exhausted.
posop_zip_recolor_(_, [], []) :- !.
% Pair each object with the next color, replacing its original color.
posop_zip_recolor_([obj(_, Cells)|Ts], [C|Tc], [obj(C, Cells)|Rs]) :-
    posop_zip_recolor_(Ts, Tc, Rs).

% posop_row_rank(+Objs, +Obj, -Rank): Rank is the 1-based position of Obj in the
% topmost-row ascending ordering of Objs. Ties preserve input order (stable sort).
posop_row_rank(Objs, Obj, Rank) :-
% Sort by topmost row and find position of Obj via nth1.
    posop_sort_by_row_(Objs, Sorted),
    nth1(Rank, Sorted, Obj).

% posop_col_rank(+Objs, +Obj, -Rank): Rank is the 1-based position of Obj in the
% leftmost-col ascending ordering of Objs. Ties preserve input order (stable sort).
posop_col_rank(Objs, Obj, Rank) :-
% Sort by leftmost col and find position of Obj via nth1.
    posop_sort_by_col_(Objs, Sorted),
    nth1(Rank, Sorted, Obj).

% posop_reading_rank(+Objs, +Obj, -Rank): Rank is the 1-based position of Obj in
% reading order (topmost row, then leftmost col) among Objs. Stable for equal keys.
posop_reading_rank(Objs, Obj, Rank) :-
% Sort in reading order and find position of Obj via nth1.
    posop_sort_reading_(Objs, Sorted),
    nth1(Rank, Sorted, Obj).

% posop_assign_by_row(+Objs, +Colors, -Result): sort Objs by topmost row ascending,
% then recolor each with the corresponding color from Colors. Truncates at shorter.
posop_assign_by_row(Objs, Colors, Result) :-
% Sort by row so the topmost object gets Colors[1], next gets Colors[2], etc.
    posop_sort_by_row_(Objs, Sorted),
% Zip sorted objects with colors and recolor each.
    posop_zip_recolor_(Sorted, Colors, Result).

% posop_assign_by_col(+Objs, +Colors, -Result): sort Objs by leftmost col ascending,
% then recolor each with the corresponding color from Colors. Truncates at shorter.
posop_assign_by_col(Objs, Colors, Result) :-
% Sort by leftmost col so the leftmost object gets Colors[1], etc.
    posop_sort_by_col_(Objs, Sorted),
% Zip sorted objects with colors and recolor each.
    posop_zip_recolor_(Sorted, Colors, Result).

% posop_assign_reading(+Objs, +Colors, -Result): sort Objs in reading order (row then
% col), then recolor each with the corresponding color from Colors.
posop_assign_reading(Objs, Colors, Result) :-
% Sort in reading order so top-left object gets Colors[1], etc.
    posop_sort_reading_(Objs, Sorted),
% Zip sorted objects with colors and recolor each.
    posop_zip_recolor_(Sorted, Colors, Result).

% posop_above_row(+Objs, +R, -Filtered): Filtered is the sub-list of Objs whose
% topmost row is strictly less than R (objects entirely above row R).
posop_above_row(Objs, R, Filtered) :-
% Keep objects whose topmost row is strictly less than R.
    findall(O, (member(O, Objs), posop_row_of(O, Row), Row < R), Filtered).

% posop_from_row(+Objs, +R, -Filtered): Filtered is the sub-list of Objs whose
% topmost row is >= R (objects at row R or below).
posop_from_row(Objs, R, Filtered) :-
% Keep objects whose topmost row is at least R.
    findall(O, (member(O, Objs), posop_row_of(O, Row), Row >= R), Filtered).

% posop_left_of(+Objs, +C, -Filtered): Filtered is the sub-list of Objs whose
% leftmost col is strictly less than C (objects entirely left of column C).
posop_left_of(Objs, C, Filtered) :-
% Keep objects whose leftmost col is strictly less than C.
    findall(O, (member(O, Objs), posop_col_of(O, Col), Col < C), Filtered).

% posop_from_col(+Objs, +C, -Filtered): Filtered is the sub-list of Objs whose
% leftmost col is >= C (objects at column C or to the right).
posop_from_col(Objs, C, Filtered) :-
% Keep objects whose leftmost col is at least C.
    findall(O, (member(O, Objs), posop_col_of(O, Col), Col >= C), Filtered).

% posop_in_row_band(+Objs, +R1, +R2, -Filtered): Filtered is the sub-list of Objs
% whose topmost row is in the inclusive range [R1, R2].
posop_in_row_band(Objs, R1, R2, Filtered) :-
% Keep objects whose topmost row falls within the band [R1, R2].
    findall(O, (member(O, Objs), posop_row_of(O, Row), Row >= R1, Row =< R2),
            Filtered).

% posop_in_col_band(+Objs, +C1, +C2, -Filtered): Filtered is the sub-list of Objs
% whose leftmost col is in the inclusive range [C1, C2].
posop_in_col_band(Objs, C1, C2, Filtered) :-
% Keep objects whose leftmost col falls within the band [C1, C2].
    findall(O, (member(O, Objs), posop_col_of(O, Col), Col >= C1, Col =< C2),
            Filtered).
