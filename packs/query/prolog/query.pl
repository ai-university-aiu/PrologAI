% query.pl - Layer 152: Aggregate Queries over Object Lists (qu_* prefix).
% Operates on obj(Color, Cells) terms produced by the scene pack.
% Provides aggregate counting by color/size/exact form, extremes (most/least frequent
% color, largest/smallest object), totals, averages, uniformity tests, and enumeration
% of distinct colors and sizes. The "form" of an object is its origin-normalized cell
% list (min row=0, min col=0), which is an exact structural match, not D4-invariant.
:- module(query, [
    % qu_count_by_color/2: sorted Color-N pairs where N is the number of objs of that color.
    qu_count_by_color/2,
    % qu_count_by_size/2: sorted Size-N pairs where N is the number of objs with that cell count.
    qu_count_by_size/2,
    % qu_count_by_form/2: sorted Form-N pairs where Form is the origin-normalized cell list.
    qu_count_by_form/2,
    % qu_most_frequent_color/2: the color that appears in the most objs (smallest color on ties).
    qu_most_frequent_color/2,
    % qu_least_frequent_color/2: the color that appears in the fewest objs (smallest color on ties).
    qu_least_frequent_color/2,
    % qu_largest_obj/2: the obj with the most cells (first in input order on ties).
    qu_largest_obj/2,
    % qu_smallest_obj/2: the obj with the fewest cells (first in input order on ties).
    qu_smallest_obj/2,
    % qu_total_cells/2: total number of cells across all obj terms in the list.
    qu_total_cells/2,
    % qu_avg_size/2: floor-average cell count per obj in the list.
    qu_avg_size/2,
    % qu_all_same_color/1: succeed if every obj in the list has the same color.
    qu_all_same_color/1,
    % qu_all_same_size/1: succeed if every obj in the list has the same cell count.
    qu_all_same_size/1,
    % qu_all_same_form/1: succeed if every obj has the same origin-normalized cell list.
    qu_all_same_form/1,
    % qu_colors/2: sorted list of distinct color values appearing in the obj list.
    qu_colors/2,
    % qu_sizes/2: sorted list of distinct cell counts appearing in the obj list.
    qu_sizes/2
]).

% Import list utilities; sort/2, findall/3, length/2 are built-ins.
:- use_module(library(lists), [member/2, min_list/2, max_list/2, sum_list/2]).

% qu_norm_(+Cells, -Norm): translate cell list to origin (min row=0, min col=0), sorted.
qu_norm_(Cells, Norm) :-
% Extract all row indices.
    findall(R, member(r(R,_), Cells), Rs),
% Extract all column indices.
    findall(C, member(r(_,C), Cells), Cs),
% Find the bbox top-left.
    min_list(Rs, MinR),
    min_list(Cs, MinC),
% Translate every cell and sort.
    findall(r(R2,C2), (
        member(r(R,C), Cells),
        R2 is R - MinR,
        C2 is C - MinC
    ), Raw),
    sort(Raw, Norm).

% qu_form_(+Obj, -Form): origin-normalized cell list of an obj term.
qu_form_(obj(_, Cells), Form) :-
% Delegate to the shared normalization helper.
    qu_norm_(Cells, Form).

% qu_count_by_color(+Objs, -Counts): sorted Color-N pairs for each distinct color.
qu_count_by_color(Objs, Counts) :-
% Collect all colors.
    findall(C, (member(obj(C,_), Objs)), Cs0),
% Distinct sorted colors.
    sort(Cs0, Colors),
% For each color, count the matching objects.
    findall(C-N, (
        member(C, Colors),
        findall(O, (member(O, Objs), O = obj(C,_)), Grp),
        length(Grp, N)
    ), Counts).

% qu_count_by_size(+Objs, -Counts): sorted Size-N pairs for each distinct cell count.
qu_count_by_size(Objs, Counts) :-
% Collect all sizes.
    findall(S, (member(obj(_,Cells), Objs), length(Cells, S)), Ss0),
% Distinct sorted sizes.
    sort(Ss0, Sizes),
% For each size, count the matching objects.
    findall(S-N, (
        member(S, Sizes),
        findall(O, (member(O, Objs), O = obj(_,Cells), length(Cells, S)), Grp),
        length(Grp, N)
    ), Counts).

% qu_count_by_form(+Objs, -Counts): sorted Form-N pairs for each distinct normalized shape.
qu_count_by_form(Objs, Counts) :-
% Collect all normalized forms.
    findall(F, (member(O, Objs), qu_form_(O, F)), Fs0),
% Distinct sorted forms (sort/2 removes duplicates and sorts by term order).
    sort(Fs0, Forms),
% For each form, count the matching objects.
    findall(F-N, (
        member(F, Forms),
        findall(O, (member(O, Objs), qu_form_(O, F)), Grp),
        length(Grp, N)
    ), Counts).

% qu_most_frequent_color(+Objs, -Color): color with highest count; smallest color on ties.
qu_most_frequent_color(Objs, Color) :-
% Get Color-N pairs.
    qu_count_by_color(Objs, Counts),
% Extract all counts.
    findall(N, member(_-N, Counts), Ns),
% Maximum count.
    max_list(Ns, MaxN),
% First color with that count (Counts sorted by color, so smallest color comes first).
    member(Color-MaxN, Counts), !.

% qu_least_frequent_color(+Objs, -Color): color with lowest count; smallest color on ties.
qu_least_frequent_color(Objs, Color) :-
% Get Color-N pairs.
    qu_count_by_color(Objs, Counts),
% Extract all counts.
    findall(N, member(_-N, Counts), Ns),
% Minimum count.
    min_list(Ns, MinN),
% First color with that count (Counts sorted by color, so smallest color comes first).
    member(Color-MinN, Counts), !.

% qu_largest_obj(+Objs, -Obj): obj with the most cells; first in input order on ties.
qu_largest_obj(Objs, Obj) :-
% Build size-keyed obj pairs preserving input order.
    findall(N-O, (member(O, Objs), O = obj(_,Cells), length(Cells, N)), Pairs),
% Extract all sizes.
    findall(N, member(N-_, Pairs), Ns),
% Maximum size.
    max_list(Ns, MaxN),
% First obj in input order with that size.
    member(MaxN-Obj, Pairs), !.

% qu_smallest_obj(+Objs, -Obj): obj with the fewest cells; first in input order on ties.
qu_smallest_obj(Objs, Obj) :-
% Build size-keyed obj pairs preserving input order.
    findall(N-O, (member(O, Objs), O = obj(_,Cells), length(Cells, N)), Pairs),
% Extract all sizes.
    findall(N, member(N-_, Pairs), Ns),
% Minimum size.
    min_list(Ns, MinN),
% First obj in input order with that size.
    member(MinN-Obj, Pairs), !.

% qu_total_cells(+Objs, -N): total cells across all obj terms.
qu_total_cells(Objs, N) :-
% Collect the size of every obj.
    findall(S, (member(obj(_,Cells), Objs), length(Cells, S)), Ss),
% Sum all sizes.
    sum_list(Ss, N).

% qu_avg_size(+Objs, -N): floor-average cell count per obj (integer division).
qu_avg_size(Objs, N) :-
% Total cells.
    qu_total_cells(Objs, Total),
% Number of objs.
    length(Objs, Count),
% Floor average.
    N is Total // Count.

% qu_all_same_color(+Objs): succeed if all obj terms have the same color value.
qu_all_same_color(Objs) :-
% Collect all colors.
    findall(C, member(obj(C,_), Objs), Cs),
% After deduplication, exactly one distinct color must remain.
    sort(Cs, [_]).

% qu_all_same_size(+Objs): succeed if all obj terms have the same cell count.
qu_all_same_size(Objs) :-
% Collect all sizes.
    findall(S, (member(obj(_,Cells), Objs), length(Cells, S)), Ss),
% After deduplication, exactly one distinct size must remain.
    sort(Ss, [_]).

% qu_all_same_form(+Objs): succeed if all obj terms have the same origin-normalized cell list.
qu_all_same_form(Objs) :-
% Collect all normalized forms.
    findall(F, (member(O, Objs), qu_form_(O, F)), Fs),
% After deduplication, exactly one distinct form must remain.
    sort(Fs, [_]).

% qu_colors(+Objs, -Colors): sorted list of distinct color values in the obj list.
qu_colors(Objs, Colors) :-
% Collect all colors.
    findall(C, member(obj(C,_), Objs), Cs),
% sort/2 deduplicates and sorts.
    sort(Cs, Colors).

% qu_sizes(+Objs, -Sizes): sorted list of distinct cell counts in the obj list.
qu_sizes(Objs, Sizes) :-
% Collect all sizes.
    findall(S, (member(obj(_,Cells), Objs), length(Cells, S)), Ss),
% sort/2 deduplicates and sorts.
    sort(Ss, Sizes).
