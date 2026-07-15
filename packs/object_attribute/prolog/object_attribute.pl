% objattr.pl - Layer 180: Object-List Aggregate Attribute Analysis (oa_* prefix).
% Computes aggregate statistics and rankings over a list of obj(Color, Cells) terms.
% Covers total cell count, per-color cell totals, object counts per color,
% distinct color count, dominant and rarest colors, unique colors, size ranking,
% position ranking, majority size, and uniformity tests (all-same color/size/form).
% Complements objfilter (which selects objects); this pack aggregates properties.
% No cross-pack dependencies.
:- module(object_attribute, [
    % object_attribute_total_cells/2: total cell count across all objects in the list.
    object_attribute_total_cells/2,
    % object_attribute_color_counts/2: Color-Count pairs for number of objs per color, sorted by color.
    object_attribute_color_counts/2,
    % object_attribute_cell_counts_by_color/2: Color-Total pairs for total cells per color, sorted by color.
    object_attribute_cell_counts_by_color/2,
    % object_attribute_n_colors/2: number of distinct colors across the object list.
    object_attribute_n_colors/2,
    % object_attribute_n_objs_of_color/3: count of objects with a specific color.
    object_attribute_n_objs_of_color/3,
    % object_attribute_dominant_color/2: color with the most total cells; first if tied.
    object_attribute_dominant_color/2,
    % object_attribute_rarest_color/2: color with the fewest total cells; first if tied.
    object_attribute_rarest_color/2,
    % object_attribute_unique_color/2: color appearing in exactly one object.
    object_attribute_unique_color/2,
    % object_attribute_size_rank/2: objects sorted by cell count descending (largest first).
    object_attribute_size_rank/2,
    % object_attribute_pos_rank/2: objects sorted by top-left position, row-major (top-left first).
    object_attribute_pos_rank/2,
    % object_attribute_majority_size/2: most frequently occurring cell count among the objects.
    object_attribute_majority_size/2,
    % object_attribute_all_same_color/1: true iff all objects share the same color.
    object_attribute_all_same_color/1,
    % object_attribute_all_same_size/1: true iff all objects have the same cell count.
    object_attribute_all_same_size/1,
    % object_attribute_all_same_form/1: true iff all objects have the same normalized shape.
    object_attribute_all_same_form/1
]).

% Load list utilities.
:- use_module(library(lists), [member/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% object_attribute_color_(+Obj, -Color): extract color from obj.
object_attribute_color_(obj(Color, _), Color).

% object_attribute_size_(+Obj, -N): cell count of obj.
object_attribute_size_(obj(_, Cells), N) :-
    length(Cells, N).

% object_attribute_norm_(+Obj, -Sorted): normalize obj to origin and sort cells.
object_attribute_norm_(obj(_, Cells), Sorted) :-
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

% object_attribute_topleft_(+Obj, -r(MinR,MinC)): top-left corner of obj's bounding box.
object_attribute_topleft_(obj(_, Cells), r(MinR, MinC)) :-
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC).

% object_attribute_count_color_(+Objs, +Color, -Count): count objs with given color.
object_attribute_count_color_(Objs, Color, Count) :-
    findall(O, (member(O, Objs), object_attribute_color_(O, Color)), Matches),
    length(Matches, Count).

% object_attribute_total_cells_color_(+Objs, +Color, -Total): total cells across objs of given color.
object_attribute_total_cells_color_(Objs, Color, Total) :-
    findall(N,
        (member(O, Objs), object_attribute_color_(O, Color), object_attribute_size_(O, N)),
        Ns),
    sum_list(Ns, Total).

% object_attribute_mode_(+List, -Mode): most frequently occurring element (msort + run-length).
object_attribute_mode_(List, Mode) :-
    msort(List, Sorted),
    object_attribute_run_max_(Sorted, Mode).

% object_attribute_run_max_(+SortedList, -Mode): find most frequent element in sorted list.
object_attribute_run_max_([X|Rest], Mode) :-
    object_attribute_run_max_acc_(Rest, X, 1, X, 1, Mode).

% object_attribute_run_max_acc_(+Rest, +Cur, +CurCount, +BestElem, +BestCount, -Mode).
object_attribute_run_max_acc_([], _, _, Best, _, Best).
object_attribute_run_max_acc_([H|T], Cur, CurCount, Best, BestCount, Mode) :-
    (   H == Cur
    ->  NewCount is CurCount + 1,
        (   NewCount > BestCount
        ->  NewBest = H, NewBestCount = NewCount
        ;   NewBest = Best, NewBestCount = BestCount
        ),
        object_attribute_run_max_acc_(T, H, NewCount, NewBest, NewBestCount, Mode)
    ;   (   1 > BestCount
        ->  NewBest = H, NewBestCount = 1
        ;   NewBest = Best, NewBestCount = BestCount
        ),
        object_attribute_run_max_acc_(T, H, 1, NewBest, NewBestCount, Mode)
    ).

% --- Exported predicates -----------------------------------------------------

% object_attribute_total_cells(+Objs, -N): total cell count across all objects.
object_attribute_total_cells(Objs, N) :-
    findall(Count, (member(O, Objs), object_attribute_size_(O, Count)), Counts),
    sum_list(Counts, N).

% object_attribute_color_counts(+Objs, -Pairs): Color-Count pairs (count of objs), sorted by color.
object_attribute_color_counts(Objs, Pairs) :-
% Collect distinct colors in sorted order.
    findall(C, (member(O, Objs), object_attribute_color_(O, C)), Colors),
    sort(Colors, Distinct),
% Count objects per color.
    findall(C-N,
        (member(C, Distinct),
         object_attribute_count_color_(Objs, C, N)),
        Pairs).

% object_attribute_cell_counts_by_color(+Objs, -Pairs): Color-Total pairs (total cells), sorted by color.
object_attribute_cell_counts_by_color(Objs, Pairs) :-
% Collect distinct colors in sorted order.
    findall(C, (member(O, Objs), object_attribute_color_(O, C)), Colors),
    sort(Colors, Distinct),
% Sum cell counts per color.
    findall(C-T,
        (member(C, Distinct),
         object_attribute_total_cells_color_(Objs, C, T)),
        Pairs).

% object_attribute_n_colors(+Objs, -N): number of distinct colors.
object_attribute_n_colors(Objs, N) :-
    findall(C, (member(O, Objs), object_attribute_color_(O, C)), Colors),
    sort(Colors, Distinct),
    length(Distinct, N).

% object_attribute_n_objs_of_color(+Objs, +Color, -N): count of objects with the given color.
object_attribute_n_objs_of_color(Objs, Color, N) :-
    object_attribute_count_color_(Objs, Color, N).

% object_attribute_dominant_color(+Objs, -Color): color with the most total cells (first if tied).
object_attribute_dominant_color(Objs, Color) :-
    object_attribute_cell_counts_by_color(Objs, Pairs),
    Pairs \= [],
% Create Total-Color pairs and sort by Total descending (negate Total).
    findall(NegT-C, (member(C-T, Pairs), NegT is -T), Keyed),
    msort(Keyed, [_-Color|_]).

% object_attribute_rarest_color(+Objs, -Color): color with the fewest total cells (first if tied).
object_attribute_rarest_color(Objs, Color) :-
    object_attribute_cell_counts_by_color(Objs, Pairs),
    Pairs \= [],
% Sort by total ascending (msort keeps original order for ties).
    findall(T-C, member(C-T, Pairs), Keyed),
    msort(Keyed, [_-Color|_]).

% object_attribute_unique_color(+Objs, -Color): color appearing in exactly one object.
% Fails if no unique color exists.
object_attribute_unique_color(Objs, Color) :-
    object_attribute_color_counts(Objs, Pairs),
    member(Color-1, Pairs).

% object_attribute_size_rank(+Objs, -Ranked): objects sorted by cell count descending.
object_attribute_size_rank(Objs, Ranked) :-
    findall(NegN-Obj, (member(Obj, Objs), object_attribute_size_(Obj, N), NegN is -N), Keyed),
    msort(Keyed, Sorted),
    findall(Obj, member(_-Obj, Sorted), Ranked).

% object_attribute_pos_rank(+Objs, -Ranked): objects sorted by top-left position, row-major ascending.
object_attribute_pos_rank(Objs, Ranked) :-
    findall(r(R,C)-Obj,
        (member(Obj, Objs), object_attribute_topleft_(Obj, r(R,C))),
        Keyed),
    msort(Keyed, Sorted),
    findall(Obj, member(_-Obj, Sorted), Ranked).

% object_attribute_majority_size(+Objs, -N): most commonly occurring cell count.
object_attribute_majority_size(Objs, N) :-
    findall(Count, (member(O, Objs), object_attribute_size_(O, Count)), Counts),
    Counts \= [],
    object_attribute_mode_(Counts, N).

% object_attribute_all_same_color(+Objs): true iff all objects share the same color.
object_attribute_all_same_color([]).
object_attribute_all_same_color([First|Rest]) :-
    object_attribute_color_(First, Color),
    maplist(object_attribute_color_eq_(Color), Rest).

% object_attribute_color_eq_(+Color, +Obj): true iff Obj has Color.
object_attribute_color_eq_(Color, Obj) :-
    object_attribute_color_(Obj, Color).

% object_attribute_all_same_size(+Objs): true iff all objects have the same cell count.
object_attribute_all_same_size([]).
object_attribute_all_same_size([First|Rest]) :-
    object_attribute_size_(First, N),
    maplist(object_attribute_size_eq_(N), Rest).

% object_attribute_size_eq_(+N, +Obj): true iff Obj has cell count N.
object_attribute_size_eq_(N, Obj) :-
    object_attribute_size_(Obj, N).

% object_attribute_all_same_form(+Objs): true iff all objects have the same normalized shape.
object_attribute_all_same_form([]).
object_attribute_all_same_form([First|Rest]) :-
    object_attribute_norm_(First, Norm),
    maplist(object_attribute_norm_eq_(Norm), Rest).

% object_attribute_norm_eq_(+Norm, +Obj): true iff Obj's normalized form equals Norm.
object_attribute_norm_eq_(Norm, Obj) :-
    object_attribute_norm_(Obj, Norm).
