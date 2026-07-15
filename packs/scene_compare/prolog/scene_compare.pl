% scenecmp.pl - Layer 182: Scene-Level Comparison of Two Object Lists (sm_* prefix).
% Compares two lists of obj(Color, Cells) terms (Before and After) at the scene level:
% object counts, total cell counts, color sets, and form sets. Produces added/removed
% color and form inventories and a top-level change detector.
% Complements diff (grid-level) and objmatch (object-pair correspondences).
% No cross-pack dependencies.
:- module(scene_compare, [
    % scene_compare_n_objs/2: number of objects in an obj list.
    scene_compare_n_objs/2,
    % scene_compare_total_cells/2: total cell count across all objects.
    scene_compare_total_cells/2,
    % scene_compare_colors/2: sorted list of distinct colors in an obj list.
    scene_compare_colors/2,
    % scene_compare_forms/2: sorted list of distinct normalized shapes in an obj list.
    scene_compare_forms/2,
    % scene_compare_same_n_objs/2: Before and After have the same object count.
    scene_compare_same_n_objs/2,
    % scene_compare_same_total_cells/2: Before and After have the same total cell count.
    scene_compare_same_total_cells/2,
    % scene_compare_same_colors/2: Before and After have exactly the same color set.
    scene_compare_same_colors/2,
    % scene_compare_same_forms/2: Before and After have exactly the same form set.
    scene_compare_same_forms/2,
    % scene_compare_added_colors/3: colors present in After but not in Before.
    scene_compare_added_colors/3,
    % scene_compare_removed_colors/3: colors present in Before but not in After.
    scene_compare_removed_colors/3,
    % scene_compare_added_forms/3: normalized forms present in After but not in Before.
    scene_compare_added_forms/3,
    % scene_compare_removed_forms/3: normalized forms present in Before but not in After.
    scene_compare_removed_forms/3,
    % scene_compare_n_color_change/3: total count of added plus removed colors.
    scene_compare_n_color_change/3,
    % scene_compare_any_change/2: true iff color set, form set, or object count differ.
    scene_compare_any_change/2
]).

% Load list utilities.
:- use_module(library(lists), [member/2, subtract/3]).

% --- Private helpers ---------------------------------------------------------

% scene_compare_color_(+Obj, -Color): extract color.
scene_compare_color_(obj(Color, _), Color).

% scene_compare_size_(+Obj, -N): cell count.
scene_compare_size_(obj(_, Cells), N) :-
    length(Cells, N).

% scene_compare_norm_(+Obj, -Sorted): normalize to origin; sort cells.
scene_compare_norm_(obj(_, Cells), Sorted) :-
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

% scene_compare_distinct_colors_(+Objs, -Colors): sorted distinct colors.
scene_compare_distinct_colors_(Objs, Colors) :-
    findall(C, (member(O, Objs), scene_compare_color_(O, C)), All),
    sort(All, Colors).

% scene_compare_distinct_forms_(+Objs, -Forms): sorted distinct normalized forms.
scene_compare_distinct_forms_(Objs, Forms) :-
    findall(Norm, (member(O, Objs), scene_compare_norm_(O, Norm)), All),
    sort(All, Forms).

% --- Exported predicates -----------------------------------------------------

% scene_compare_n_objs(+Objs, -N): count of objects.
scene_compare_n_objs(Objs, N) :-
    length(Objs, N).

% scene_compare_total_cells(+Objs, -N): total cells across all objects.
scene_compare_total_cells(Objs, N) :-
    findall(Count, (member(O, Objs), scene_compare_size_(O, Count)), Counts),
    sum_list(Counts, N).

% scene_compare_colors(+Objs, -Colors): sorted distinct colors in the obj list.
scene_compare_colors(Objs, Colors) :-
    scene_compare_distinct_colors_(Objs, Colors).

% scene_compare_forms(+Objs, -Forms): sorted distinct normalized forms.
scene_compare_forms(Objs, Forms) :-
    scene_compare_distinct_forms_(Objs, Forms).

% scene_compare_same_n_objs(+Before, +After): both have the same number of objects.
scene_compare_same_n_objs(Before, After) :-
    length(Before, N),
    length(After, N).

% scene_compare_same_total_cells(+Before, +After): both have the same total cell count.
scene_compare_same_total_cells(Before, After) :-
    scene_compare_total_cells(Before, N),
    scene_compare_total_cells(After, N).

% scene_compare_same_colors(+Before, +After): both have exactly the same color set.
scene_compare_same_colors(Before, After) :-
    scene_compare_distinct_colors_(Before, CB),
    scene_compare_distinct_colors_(After, CB).

% scene_compare_same_forms(+Before, +After): both have exactly the same form set.
scene_compare_same_forms(Before, After) :-
    scene_compare_distinct_forms_(Before, FB),
    scene_compare_distinct_forms_(After, FB).

% scene_compare_added_colors(+Before, +After, -Added): colors in After not present in Before.
scene_compare_added_colors(Before, After, Added) :-
    scene_compare_distinct_colors_(Before, CB),
    scene_compare_distinct_colors_(After, CA),
    subtract(CA, CB, Added).

% scene_compare_removed_colors(+Before, +After, -Removed): colors in Before not present in After.
scene_compare_removed_colors(Before, After, Removed) :-
    scene_compare_distinct_colors_(Before, CB),
    scene_compare_distinct_colors_(After, CA),
    subtract(CB, CA, Removed).

% scene_compare_added_forms(+Before, +After, -Added): forms in After not present in Before.
scene_compare_added_forms(Before, After, Added) :-
    scene_compare_distinct_forms_(Before, FB),
    scene_compare_distinct_forms_(After, FA),
    subtract(FA, FB, Added).

% scene_compare_removed_forms(+Before, +After, -Removed): forms in Before not present in After.
scene_compare_removed_forms(Before, After, Removed) :-
    scene_compare_distinct_forms_(Before, FB),
    scene_compare_distinct_forms_(After, FA),
    subtract(FB, FA, Removed).

% scene_compare_n_color_change(+Before, +After, -N): |added colors| + |removed colors|.
scene_compare_n_color_change(Before, After, N) :-
    scene_compare_added_colors(Before, After, Added),
    scene_compare_removed_colors(Before, After, Removed),
    length(Added, NA),
    length(Removed, NR),
    N is NA + NR.

% scene_compare_any_change(+Before, +After): true iff scenes differ in count, color, or form.
scene_compare_any_change(Before, After) :-
    (   \+ scene_compare_same_n_objs(Before, After)
    ;   \+ scene_compare_same_colors(Before, After)
    ;   \+ scene_compare_same_forms(Before, After)
    ),
    !.
