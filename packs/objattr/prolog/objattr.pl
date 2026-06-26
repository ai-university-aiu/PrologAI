% objattr.pl - Layer 180: Object-List Aggregate Attribute Analysis (oa_* prefix).
% Computes aggregate statistics and rankings over a list of obj(Color, Cells) terms.
% Covers total cell count, per-color cell totals, object counts per color,
% distinct color count, dominant and rarest colors, unique colors, size ranking,
% position ranking, majority size, and uniformity tests (all-same color/size/form).
% Complements objfilter (which selects objects); this pack aggregates properties.
% No cross-pack dependencies.
:- module(objattr, [
    % oa_total_cells/2: total cell count across all objects in the list.
    oa_total_cells/2,
    % oa_color_counts/2: Color-Count pairs for number of objs per color, sorted by color.
    oa_color_counts/2,
    % oa_cell_counts_by_color/2: Color-Total pairs for total cells per color, sorted by color.
    oa_cell_counts_by_color/2,
    % oa_n_colors/2: number of distinct colors across the object list.
    oa_n_colors/2,
    % oa_n_objs_of_color/3: count of objects with a specific color.
    oa_n_objs_of_color/3,
    % oa_dominant_color/2: color with the most total cells; first if tied.
    oa_dominant_color/2,
    % oa_rarest_color/2: color with the fewest total cells; first if tied.
    oa_rarest_color/2,
    % oa_unique_color/2: color appearing in exactly one object.
    oa_unique_color/2,
    % oa_size_rank/2: objects sorted by cell count descending (largest first).
    oa_size_rank/2,
    % oa_pos_rank/2: objects sorted by top-left position, row-major (top-left first).
    oa_pos_rank/2,
    % oa_majority_size/2: most frequently occurring cell count among the objects.
    oa_majority_size/2,
    % oa_all_same_color/1: true iff all objects share the same color.
    oa_all_same_color/1,
    % oa_all_same_size/1: true iff all objects have the same cell count.
    oa_all_same_size/1,
    % oa_all_same_form/1: true iff all objects have the same normalized shape.
    oa_all_same_form/1
]).

% Load list utilities.
:- use_module(library(lists), [member/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% oa_color_(+Obj, -Color): extract color from obj.
oa_color_(obj(Color, _), Color).

% oa_size_(+Obj, -N): cell count of obj.
oa_size_(obj(_, Cells), N) :-
    length(Cells, N).

% oa_norm_(+Obj, -Sorted): normalize obj to origin and sort cells.
oa_norm_(obj(_, Cells), Sorted) :-
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

% oa_topleft_(+Obj, -r(MinR,MinC)): top-left corner of obj's bounding box.
oa_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% oa_count_color_(+Objs, +Color, -Count): count objs with given color.
oa_count_color_(Objs, Color, Count) :-
    findall(O, (member(O, Objs), oa_color_(O, Color)), Matches),
    length(Matches, Count).

% oa_total_cells_color_(+Objs, +Color, -Total): total cells across objs of given color.
oa_total_cells_color_(Objs, Color, Total) :-
    findall(N,
        (member(O, Objs), oa_color_(O, Color), oa_size_(O, N)),
        Ns),
    sum_list(Ns, Total).

% oa_mode_(+List, -Mode): most frequently occurring element (msort + run-length).
oa_mode_(List, Mode) :-
    msort(List, Sorted),
    oa_run_max_(Sorted, Mode).

% oa_run_max_(+SortedList, -Mode): find most frequent element in sorted list.
oa_run_max_([X|Rest], Mode) :-
    oa_run_max_acc_(Rest, X, 1, X, 1, Mode).

% oa_run_max_acc_(+Rest, +Cur, +CurCount, +BestElem, +BestCount, -Mode).
oa_run_max_acc_([], _, _, Best, _, Best).
oa_run_max_acc_([H|T], Cur, CurCount, Best, BestCount, Mode) :-
    (   H == Cur
    ->  NewCount is CurCount + 1,
        (   NewCount > BestCount
        ->  NewBest = H, NewBestCount = NewCount
        ;   NewBest = Best, NewBestCount = BestCount
        ),
        oa_run_max_acc_(T, H, NewCount, NewBest, NewBestCount, Mode)
    ;   (   1 > BestCount
        ->  NewBest = H, NewBestCount = 1
        ;   NewBest = Best, NewBestCount = BestCount
        ),
        oa_run_max_acc_(T, H, 1, NewBest, NewBestCount, Mode)
    ).

% --- Exported predicates -----------------------------------------------------

% oa_total_cells(+Objs, -N): total cell count across all objects.
oa_total_cells(Objs, N) :-
    findall(Count, (member(O, Objs), oa_size_(O, Count)), Counts),
    sum_list(Counts, N).

% oa_color_counts(+Objs, -Pairs): Color-Count pairs (count of objs), sorted by color.
oa_color_counts(Objs, Pairs) :-
% Collect distinct colors in sorted order.
    findall(C, (member(O, Objs), oa_color_(O, C)), Colors),
    sort(Colors, Distinct),
% Count objects per color.
    findall(C-N,
        (member(C, Distinct),
         oa_count_color_(Objs, C, N)),
        Pairs).

% oa_cell_counts_by_color(+Objs, -Pairs): Color-Total pairs (total cells), sorted by color.
oa_cell_counts_by_color(Objs, Pairs) :-
% Collect distinct colors in sorted order.
    findall(C, (member(O, Objs), oa_color_(O, C)), Colors),
    sort(Colors, Distinct),
% Sum cell counts per color.
    findall(C-T,
        (member(C, Distinct),
         oa_total_cells_color_(Objs, C, T)),
        Pairs).

% oa_n_colors(+Objs, -N): number of distinct colors.
oa_n_colors(Objs, N) :-
    findall(C, (member(O, Objs), oa_color_(O, C)), Colors),
    sort(Colors, Distinct),
    length(Distinct, N).

% oa_n_objs_of_color(+Objs, +Color, -N): count of objects with the given color.
oa_n_objs_of_color(Objs, Color, N) :-
    oa_count_color_(Objs, Color, N).

% oa_dominant_color(+Objs, -Color): color with the most total cells (first if tied).
oa_dominant_color(Objs, Color) :-
    oa_cell_counts_by_color(Objs, Pairs),
    Pairs \= [],
% Create Total-Color pairs and sort by Total descending (negate Total).
    findall(NegT-C, (member(C-T, Pairs), NegT is -T), Keyed),
    msort(Keyed, [_-Color|_]).

% oa_rarest_color(+Objs, -Color): color with the fewest total cells (first if tied).
oa_rarest_color(Objs, Color) :-
    oa_cell_counts_by_color(Objs, Pairs),
    Pairs \= [],
% Sort by total ascending (msort keeps original order for ties).
    findall(T-C, member(C-T, Pairs), Keyed),
    msort(Keyed, [_-Color|_]).

% oa_unique_color(+Objs, -Color): color appearing in exactly one object.
% Fails if no unique color exists.
oa_unique_color(Objs, Color) :-
    oa_color_counts(Objs, Pairs),
    member(Color-1, Pairs).

% oa_size_rank(+Objs, -Ranked): objects sorted by cell count descending.
oa_size_rank(Objs, Ranked) :-
    findall(NegN-Obj, (member(Obj, Objs), oa_size_(Obj, N), NegN is -N), Keyed),
    msort(Keyed, Sorted),
    findall(Obj, member(_-Obj, Sorted), Ranked).

% oa_pos_rank(+Objs, -Ranked): objects sorted by top-left position, row-major ascending.
oa_pos_rank(Objs, Ranked) :-
    findall(r(R,C)-Obj,
        (member(Obj, Objs), oa_topleft_(Obj, r(R,C))),
        Keyed),
    msort(Keyed, Sorted),
    findall(Obj, member(_-Obj, Sorted), Ranked).

% oa_majority_size(+Objs, -N): most commonly occurring cell count.
oa_majority_size(Objs, N) :-
    findall(Count, (member(O, Objs), oa_size_(O, Count)), Counts),
    Counts \= [],
    oa_mode_(Counts, N).

% oa_all_same_color(+Objs): true iff all objects share the same color.
oa_all_same_color([]).
oa_all_same_color([First|Rest]) :-
    oa_color_(First, Color),
    maplist(oa_color_eq_(Color), Rest).

% oa_color_eq_(+Color, +Obj): true iff Obj has Color.
oa_color_eq_(Color, Obj) :-
    oa_color_(Obj, Color).

% oa_all_same_size(+Objs): true iff all objects have the same cell count.
oa_all_same_size([]).
oa_all_same_size([First|Rest]) :-
    oa_size_(First, N),
    maplist(oa_size_eq_(N), Rest).

% oa_size_eq_(+N, +Obj): true iff Obj has cell count N.
oa_size_eq_(N, Obj) :-
    oa_size_(Obj, N).

% oa_all_same_form(+Objs): true iff all objects have the same normalized shape.
oa_all_same_form([]).
oa_all_same_form([First|Rest]) :-
    oa_norm_(First, Norm),
    maplist(oa_norm_eq_(Norm), Rest).

% oa_norm_eq_(+Norm, +Obj): true iff Obj's normalized form equals Norm.
oa_norm_eq_(Norm, Obj) :-
    oa_norm_(Obj, Norm).
