% objattr.pl - Layer 180: Object-List Aggregate Attribute Analysis (oa_* prefix).
% Computes aggregate statistics and rankings over a list of obj(Color, Cells) terms.
% Covers total cell count, per-color cell totals, object counts per color,
% distinct color count, dominant and rarest colors, unique colors, size ranking,
% position ranking, majority size, and uniformity tests (all-same color/size/form).
% Complements objfilter (which selects objects); this pack aggregates properties.
% No cross-pack dependencies.
:- module(objattr, [
    % objattr_total_cells/2: total cell count across all objects in the list.
    objattr_total_cells/2,
    % objattr_color_counts/2: Color-Count pairs for number of objs per color, sorted by color.
    objattr_color_counts/2,
    % objattr_cell_counts_by_color/2: Color-Total pairs for total cells per color, sorted by color.
    objattr_cell_counts_by_color/2,
    % objattr_n_colors/2: number of distinct colors across the object list.
    objattr_n_colors/2,
    % objattr_n_objs_of_color/3: count of objects with a specific color.
    objattr_n_objs_of_color/3,
    % objattr_dominant_color/2: color with the most total cells; first if tied.
    objattr_dominant_color/2,
    % objattr_rarest_color/2: color with the fewest total cells; first if tied.
    objattr_rarest_color/2,
    % objattr_unique_color/2: color appearing in exactly one object.
    objattr_unique_color/2,
    % objattr_size_rank/2: objects sorted by cell count descending (largest first).
    objattr_size_rank/2,
    % objattr_pos_rank/2: objects sorted by top-left position, row-major (top-left first).
    objattr_pos_rank/2,
    % objattr_majority_size/2: most frequently occurring cell count among the objects.
    objattr_majority_size/2,
    % objattr_all_same_color/1: true iff all objects share the same color.
    objattr_all_same_color/1,
    % objattr_all_same_size/1: true iff all objects have the same cell count.
    objattr_all_same_size/1,
    % objattr_all_same_form/1: true iff all objects have the same normalized shape.
    objattr_all_same_form/1
]).

% Load list utilities.
:- use_module(library(lists), [member/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% objattr_color_(+Obj, -Color): extract color from obj.
objattr_color_(obj(Color, _), Color).

% objattr_size_(+Obj, -N): cell count of obj.
objattr_size_(obj(_, Cells), N) :-
    length(Cells, N).

% objattr_norm_(+Obj, -Sorted): normalize obj to origin and sort cells.
objattr_norm_(obj(_, Cells), Sorted) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC),
    findall(r(NR,NC),
        (member(r(R,C), Cells),
         NR is R - MinR,
         NC is C - MinC),
        Raw),
    sort(Raw, Sorted).

% objattr_topleft_(+Obj, -r(MinR,MinC)): top-left corner of obj's bounding box.
objattr_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% objattr_count_color_(+Objs, +Color, -Count): count objs with given color.
objattr_count_color_(Objs, Color, Count) :-
    findall(O, (member(O, Objs), objattr_color_(O, Color)), Matches),
    length(Matches, Count).

% objattr_total_cells_color_(+Objs, +Color, -Total): total cells across objs of given color.
objattr_total_cells_color_(Objs, Color, Total) :-
    findall(N,
        (member(O, Objs), objattr_color_(O, Color), objattr_size_(O, N)),
        Ns),
    sum_list(Ns, Total).

% objattr_mode_(+List, -Mode): most frequently occurring element (msort + run-length).
objattr_mode_(List, Mode) :-
    msort(List, Sorted),
    objattr_run_max_(Sorted, Mode).

% objattr_run_max_(+SortedList, -Mode): find most frequent element in sorted list.
objattr_run_max_([X|Rest], Mode) :-
    objattr_run_max_acc_(Rest, X, 1, X, 1, Mode).

% objattr_run_max_acc_(+Rest, +Cur, +CurCount, +BestElem, +BestCount, -Mode).
objattr_run_max_acc_([], _, _, Best, _, Best).
objattr_run_max_acc_([H|T], Cur, CurCount, Best, BestCount, Mode) :-
    (   H == Cur
    ->  NewCount is CurCount + 1,
        (   NewCount > BestCount
        ->  NewBest = H, NewBestCount = NewCount
        ;   NewBest = Best, NewBestCount = BestCount
        ),
        objattr_run_max_acc_(T, H, NewCount, NewBest, NewBestCount, Mode)
    ;   (   1 > BestCount
        ->  NewBest = H, NewBestCount = 1
        ;   NewBest = Best, NewBestCount = BestCount
        ),
        objattr_run_max_acc_(T, H, 1, NewBest, NewBestCount, Mode)
    ).

% --- Exported predicates -----------------------------------------------------

% objattr_total_cells(+Objs, -N): total cell count across all objects.
objattr_total_cells(Objs, N) :-
    findall(Count, (member(O, Objs), objattr_size_(O, Count)), Counts),
    sum_list(Counts, N).

% objattr_color_counts(+Objs, -Pairs): Color-Count pairs (count of objs), sorted by color.
objattr_color_counts(Objs, Pairs) :-
% Collect distinct colors in sorted order.
    findall(C, (member(O, Objs), objattr_color_(O, C)), Colors),
    sort(Colors, Distinct),
% Count objects per color.
    findall(C-N,
        (member(C, Distinct),
         objattr_count_color_(Objs, C, N)),
        Pairs).

% objattr_cell_counts_by_color(+Objs, -Pairs): Color-Total pairs (total cells), sorted by color.
objattr_cell_counts_by_color(Objs, Pairs) :-
% Collect distinct colors in sorted order.
    findall(C, (member(O, Objs), objattr_color_(O, C)), Colors),
    sort(Colors, Distinct),
% Sum cell counts per color.
    findall(C-T,
        (member(C, Distinct),
         objattr_total_cells_color_(Objs, C, T)),
        Pairs).

% objattr_n_colors(+Objs, -N): number of distinct colors.
objattr_n_colors(Objs, N) :-
    findall(C, (member(O, Objs), objattr_color_(O, C)), Colors),
    sort(Colors, Distinct),
    length(Distinct, N).

% objattr_n_objs_of_color(+Objs, +Color, -N): count of objects with the given color.
objattr_n_objs_of_color(Objs, Color, N) :-
    objattr_count_color_(Objs, Color, N).

% objattr_dominant_color(+Objs, -Color): color with the most total cells (first if tied).
objattr_dominant_color(Objs, Color) :-
    objattr_cell_counts_by_color(Objs, Pairs),
    Pairs \= [],
% Create Total-Color pairs and sort by Total descending (negate Total).
    findall(NegT-C, (member(C-T, Pairs), NegT is -T), Keyed),
    msort(Keyed, [_-Color|_]).

% objattr_rarest_color(+Objs, -Color): color with the fewest total cells (first if tied).
objattr_rarest_color(Objs, Color) :-
    objattr_cell_counts_by_color(Objs, Pairs),
    Pairs \= [],
% Sort by total ascending (msort keeps original order for ties).
    findall(T-C, member(C-T, Pairs), Keyed),
    msort(Keyed, [_-Color|_]).

% objattr_unique_color(+Objs, -Color): color appearing in exactly one object.
% Fails if no unique color exists.
objattr_unique_color(Objs, Color) :-
    objattr_color_counts(Objs, Pairs),
    member(Color-1, Pairs).

% objattr_size_rank(+Objs, -Ranked): objects sorted by cell count descending.
objattr_size_rank(Objs, Ranked) :-
    findall(NegN-Obj, (member(Obj, Objs), objattr_size_(Obj, N), NegN is -N), Keyed),
    msort(Keyed, Sorted),
    findall(Obj, member(_-Obj, Sorted), Ranked).

% objattr_pos_rank(+Objs, -Ranked): objects sorted by top-left position, row-major ascending.
objattr_pos_rank(Objs, Ranked) :-
    findall(r(R,C)-Obj,
        (member(Obj, Objs), objattr_topleft_(Obj, r(R,C))),
        Keyed),
    msort(Keyed, Sorted),
    findall(Obj, member(_-Obj, Sorted), Ranked).

% objattr_majority_size(+Objs, -N): most commonly occurring cell count.
objattr_majority_size(Objs, N) :-
    findall(Count, (member(O, Objs), objattr_size_(O, Count)), Counts),
    Counts \= [],
    objattr_mode_(Counts, N).

% objattr_all_same_color(+Objs): true iff all objects share the same color.
objattr_all_same_color([]).
objattr_all_same_color([First|Rest]) :-
    objattr_color_(First, Color),
    maplist(objattr_color_eq_(Color), Rest).

% objattr_color_eq_(+Color, +Obj): true iff Obj has Color.
objattr_color_eq_(Color, Obj) :-
    objattr_color_(Obj, Color).

% objattr_all_same_size(+Objs): true iff all objects have the same cell count.
objattr_all_same_size([]).
objattr_all_same_size([First|Rest]) :-
    objattr_size_(First, N),
    maplist(objattr_size_eq_(N), Rest).

% objattr_size_eq_(+N, +Obj): true iff Obj has cell count N.
objattr_size_eq_(N, Obj) :-
    objattr_size_(Obj, N).

% objattr_all_same_form(+Objs): true iff all objects have the same normalized shape.
objattr_all_same_form([]).
objattr_all_same_form([First|Rest]) :-
    objattr_norm_(First, Norm),
    maplist(objattr_norm_eq_(Norm), Rest).

% objattr_norm_eq_(+Norm, +Obj): true iff Obj's normalized form equals Norm.
objattr_norm_eq_(Norm, Obj) :-
    objattr_norm_(Obj, Norm).
