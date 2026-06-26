% Object List Filtering and Selection (of_*, Layer 173)
% Predicates for filtering, selecting, and partitioning a list of
% obj(Color, Cells) terms by color, size, and shape criteria.
% All shape tests are implemented inline with private helpers so this
% pack has no cross-pack dependencies.
:- module(objfilter, [
    of_by_color/3,
    of_not_color/3,
    of_exact_size/3,
    of_min_size/3,
    of_max_size/3,
    of_is_rect/2,
    of_is_hline/2,
    of_is_vline/2,
    of_is_single/2,
    of_is_hollow/2,
    of_largest/2,
    of_smallest/2,
    of_filter/3,
    of_partition/4
]).

:- use_module(library(lists), [member/2, min_list/2, max_list/2]).
:- use_module(library(apply), [include/3, exclude/3, partition/4]).

:- meta_predicate of_filter(+, 1, -).
:- meta_predicate of_partition(+, 1, -, -).

% of_size_(+Obj, -N): private; number of cells in Obj
of_size_(obj(_, Cells), N) :-
    % delegate to built-in length on the cell list
    length(Cells, N).

% of_bbox_(+Obj, -MinR, -MinC, -MaxR, -MaxC): private; bounding box of Obj
of_bbox_(obj(_, Cells), MinR, MinC, MaxR, MaxC) :-
    % collect all row indices then compute extremes
    findall(R, member(r(R,_), Cells), Rs),
    % collect all column indices then compute extremes
    findall(C, member(r(_,C), Cells), Cs),
    % bounding box row and column extremes
    min_list(Rs, MinR), max_list(Rs, MaxR),
    min_list(Cs, MinC), max_list(Cs, MaxC).

% of_is_rect_(+Obj): private; true when cell count equals bounding box area
of_is_rect_(Obj) :-
    % cell count must equal H * W; no holes means all bbox cells are occupied
    of_size_(Obj, N),
    of_bbox_(Obj, MinR, MinC, MaxR, MaxC),
    N =:= (MaxR - MinR + 1) * (MaxC - MinC + 1).

% of_is_hline_(+Obj): private; true when all cells share the same row
of_is_hline_(Obj) :-
    % bounding box height of 1 means all cells in one row
    of_bbox_(Obj, MinR, _, MaxR, _),
    MinR =:= MaxR.

% of_is_vline_(+Obj): private; true when all cells share the same column
of_is_vline_(Obj) :-
    % bounding box width of 1 means all cells in one column
    of_bbox_(Obj, _, MinC, _, MaxC),
    MinC =:= MaxC.

% of_is_single_(+Obj): private; true when Obj has exactly one cell
of_is_single_(Obj) :-
    % exactly 1 cell
    of_size_(Obj, 1).

% of_is_hollow_(+Obj): private; true when cell count is less than bbox area
of_is_hollow_(Obj) :-
    % at least one cell in the bbox is absent from the object
    of_size_(Obj, N),
    of_bbox_(Obj, MinR, MinC, MaxR, MaxC),
    N < (MaxR - MinR + 1) * (MaxC - MinC + 1).

% of_largest_acc_(+Rest, +BestN, +BestObj, -Result): private accumulator for of_largest
of_largest_acc_([], _, Best, Best).
of_largest_acc_([H|T], BestN, BestObj, Result) :-
    % compare current head size against running best
    of_size_(H, N),
    (   N > BestN
    ->  of_largest_acc_(T, N, H, Result)
    ;   of_largest_acc_(T, BestN, BestObj, Result)
    ).

% of_smallest_acc_(+Rest, +BestN, +BestObj, -Result): private accumulator for of_smallest
of_smallest_acc_([], _, Best, Best).
of_smallest_acc_([H|T], BestN, BestObj, Result) :-
    % compare current head size against running best
    of_size_(H, N),
    (   N < BestN
    ->  of_smallest_acc_(T, N, H, Result)
    ;   of_smallest_acc_(T, BestN, BestObj, Result)
    ).

% of_by_color(+Objs, +Color, -Filtered): objects whose color equals Color
% Preserves original list order.
of_by_color(Objs, Color, Filtered) :-
    % findall keeps ordering; match is exact color unification
    findall(O, (member(O, Objs), O = obj(Color, _)), Filtered).

% of_not_color(+Objs, +Color, -Filtered): objects whose color is not Color
% Preserves original list order.
of_not_color(Objs, Color, Filtered) :-
    % keep objects whose color differs from Color
    findall(O, (member(O, Objs), O = obj(C, _), C \= Color), Filtered).

% of_exact_size(+Objs, +N, -Filtered): objects with exactly N cells
of_exact_size(Objs, N, Filtered) :-
    % length check via private helper
    findall(O, (member(O, Objs), of_size_(O, N)), Filtered).

% of_min_size(+Objs, +N, -Filtered): objects with at least N cells
of_min_size(Objs, N, Filtered) :-
    % keep objects where M >= N
    findall(O, (member(O, Objs), of_size_(O, M), M >= N), Filtered).

% of_max_size(+Objs, +N, -Filtered): objects with at most N cells
of_max_size(Objs, N, Filtered) :-
    % keep objects where M =< N
    findall(O, (member(O, Objs), of_size_(O, M), M =< N), Filtered).

% of_is_rect(+Objs, -Filtered): objects whose cell count equals their bbox area
% A solid rectangle has no holes; every bbox position is occupied.
of_is_rect(Objs, Filtered) :-
    % private of_is_rect_ implements the test
    findall(O, (member(O, Objs), of_is_rect_(O)), Filtered).

% of_is_hline(+Objs, -Filtered): objects where all cells lie in a single row
% Includes single-cell objects (bbox height = 1) and horizontal bars.
of_is_hline(Objs, Filtered) :-
    % private of_is_hline_ checks bounding box height = 1
    findall(O, (member(O, Objs), of_is_hline_(O)), Filtered).

% of_is_vline(+Objs, -Filtered): objects where all cells lie in a single column
% Includes single-cell objects (bbox width = 1) and vertical bars.
of_is_vline(Objs, Filtered) :-
    % private of_is_vline_ checks bounding box width = 1
    findall(O, (member(O, Objs), of_is_vline_(O)), Filtered).

% of_is_single(+Objs, -Filtered): objects with exactly one cell
of_is_single(Objs, Filtered) :-
    % single-cell test: length = 1
    findall(O, (member(O, Objs), of_is_single_(O)), Filtered).

% of_is_hollow(+Objs, -Filtered): objects with at least one hole inside their bbox
% A hole is a bbox position not occupied by the object. L-shapes and frames qualify.
of_is_hollow(Objs, Filtered) :-
    % private of_is_hollow_ compares cell count to bbox area
    findall(O, (member(O, Objs), of_is_hollow_(O)), Filtered).

% of_largest(+Objs, -Obj): the object with the most cells
% When two objects have the same size, the first in the list is returned.
% Fails when Objs is empty.
of_largest([H|T], Largest) :-
    % initialize accumulator with head
    of_size_(H, N),
    of_largest_acc_(T, N, H, Largest).

% of_smallest(+Objs, -Obj): the object with the fewest cells
% When two objects have the same size, the first in the list is returned.
% Fails when Objs is empty.
of_smallest([H|T], Smallest) :-
    % initialize accumulator with head
    of_size_(H, N),
    of_smallest_acc_(T, N, H, Smallest).

% of_filter(+Objs, :Goal, -Filtered): include objects satisfying Goal
% Goal is called as call(Goal, Obj); objects where Goal succeeds are kept.
of_filter(Objs, Goal, Filtered) :-
    % delegate to SWI-Prolog include/3 from library(apply)
    include(Goal, Objs, Filtered).

% of_partition(+Objs, :Goal, -In, -Out): split Objs by Goal
% In receives objects where call(Goal, Obj) succeeds;
% Out receives objects where it fails. Order within each group is preserved.
of_partition(Objs, Goal, In, Out) :-
    % delegate to SWI-Prolog partition/4 from library(apply)
    partition(Goal, Objs, In, Out).
