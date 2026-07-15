% scenecmp.pl - Layer 182: Scene-Level Comparison of Two Object Lists (sm_* prefix).
% Compares two lists of obj(Color, Cells) terms (Before and After) at the scene level:
% object counts, total cell counts, color sets, and form sets. Produces added/removed
% color and form inventories and a top-level change detector.
% Complements diff (grid-level) and objmatch (object-pair correspondences).
% No cross-pack dependencies.
:- module(scenecmp, [
    % scenecmp_n_objs/2: number of objects in an obj list.
    scenecmp_n_objs/2,
    % scenecmp_total_cells/2: total cell count across all objects.
    scenecmp_total_cells/2,
    % scenecmp_colors/2: sorted list of distinct colors in an obj list.
    scenecmp_colors/2,
    % scenecmp_forms/2: sorted list of distinct normalized shapes in an obj list.
    scenecmp_forms/2,
    % scenecmp_same_n_objs/2: Before and After have the same object count.
    scenecmp_same_n_objs/2,
    % scenecmp_same_total_cells/2: Before and After have the same total cell count.
    scenecmp_same_total_cells/2,
    % scenecmp_same_colors/2: Before and After have exactly the same color set.
    scenecmp_same_colors/2,
    % scenecmp_same_forms/2: Before and After have exactly the same form set.
    scenecmp_same_forms/2,
    % scenecmp_added_colors/3: colors present in After but not in Before.
    scenecmp_added_colors/3,
    % scenecmp_removed_colors/3: colors present in Before but not in After.
    scenecmp_removed_colors/3,
    % scenecmp_added_forms/3: normalized forms present in After but not in Before.
    scenecmp_added_forms/3,
    % scenecmp_removed_forms/3: normalized forms present in Before but not in After.
    scenecmp_removed_forms/3,
    % scenecmp_n_color_change/3: total count of added plus removed colors.
    scenecmp_n_color_change/3,
    % scenecmp_any_change/2: true iff color set, form set, or object count differ.
    scenecmp_any_change/2
]).

% Load list utilities.
:- use_module(library(lists), [member/2, subtract/3]).

% --- Private helpers ---------------------------------------------------------

% scenecmp_color_(+Obj, -Color): extract color.
scenecmp_color_(obj(Color, _), Color).

% scenecmp_size_(+Obj, -N): cell count.
scenecmp_size_(obj(_, Cells), N) :-
    length(Cells, N).

% scenecmp_norm_(+Obj, -Sorted): normalize to origin; sort cells.
scenecmp_norm_(obj(_, Cells), Sorted) :-
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

% scenecmp_distinct_colors_(+Objs, -Colors): sorted distinct colors.
scenecmp_distinct_colors_(Objs, Colors) :-
    findall(C, (member(O, Objs), scenecmp_color_(O, C)), All),
    sort(All, Colors).

% scenecmp_distinct_forms_(+Objs, -Forms): sorted distinct normalized forms.
scenecmp_distinct_forms_(Objs, Forms) :-
    findall(Norm, (member(O, Objs), scenecmp_norm_(O, Norm)), All),
    sort(All, Forms).

% --- Exported predicates -----------------------------------------------------

% scenecmp_n_objs(+Objs, -N): count of objects.
scenecmp_n_objs(Objs, N) :-
    length(Objs, N).

% scenecmp_total_cells(+Objs, -N): total cells across all objects.
scenecmp_total_cells(Objs, N) :-
    findall(Count, (member(O, Objs), scenecmp_size_(O, Count)), Counts),
    sum_list(Counts, N).

% scenecmp_colors(+Objs, -Colors): sorted distinct colors in the obj list.
scenecmp_colors(Objs, Colors) :-
    scenecmp_distinct_colors_(Objs, Colors).

% scenecmp_forms(+Objs, -Forms): sorted distinct normalized forms.
scenecmp_forms(Objs, Forms) :-
    scenecmp_distinct_forms_(Objs, Forms).

% scenecmp_same_n_objs(+Before, +After): both have the same number of objects.
scenecmp_same_n_objs(Before, After) :-
    length(Before, N),
    length(After, N).

% scenecmp_same_total_cells(+Before, +After): both have the same total cell count.
scenecmp_same_total_cells(Before, After) :-
    scenecmp_total_cells(Before, N),
    scenecmp_total_cells(After, N).

% scenecmp_same_colors(+Before, +After): both have exactly the same color set.
scenecmp_same_colors(Before, After) :-
    scenecmp_distinct_colors_(Before, CB),
    scenecmp_distinct_colors_(After, CB).

% scenecmp_same_forms(+Before, +After): both have exactly the same form set.
scenecmp_same_forms(Before, After) :-
    scenecmp_distinct_forms_(Before, FB),
    scenecmp_distinct_forms_(After, FB).

% scenecmp_added_colors(+Before, +After, -Added): colors in After not present in Before.
scenecmp_added_colors(Before, After, Added) :-
    scenecmp_distinct_colors_(Before, CB),
    scenecmp_distinct_colors_(After, CA),
    subtract(CA, CB, Added).

% scenecmp_removed_colors(+Before, +After, -Removed): colors in Before not present in After.
scenecmp_removed_colors(Before, After, Removed) :-
    scenecmp_distinct_colors_(Before, CB),
    scenecmp_distinct_colors_(After, CA),
    subtract(CB, CA, Removed).

% scenecmp_added_forms(+Before, +After, -Added): forms in After not present in Before.
scenecmp_added_forms(Before, After, Added) :-
    scenecmp_distinct_forms_(Before, FB),
    scenecmp_distinct_forms_(After, FA),
    subtract(FA, FB, Added).

% scenecmp_removed_forms(+Before, +After, -Removed): forms in Before not present in After.
scenecmp_removed_forms(Before, After, Removed) :-
    scenecmp_distinct_forms_(Before, FB),
    scenecmp_distinct_forms_(After, FA),
    subtract(FB, FA, Removed).

% scenecmp_n_color_change(+Before, +After, -N): |added colors| + |removed colors|.
scenecmp_n_color_change(Before, After, N) :-
    scenecmp_added_colors(Before, After, Added),
    scenecmp_removed_colors(Before, After, Removed),
    length(Added, NA),
    length(Removed, NR),
    N is NA + NR.

% scenecmp_any_change(+Before, +After): true iff scenes differ in count, color, or form.
scenecmp_any_change(Before, After) :-
    (   \+ scenecmp_same_n_objs(Before, After)
    ;   \+ scenecmp_same_colors(Before, After)
    ;   \+ scenecmp_same_forms(Before, After)
    ),
    !.
