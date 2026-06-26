% scenecmp.pl - Layer 182: Scene-Level Comparison of Two Object Lists (sm_* prefix).
% Compares two lists of obj(Color, Cells) terms (Before and After) at the scene level:
% object counts, total cell counts, color sets, and form sets. Produces added/removed
% color and form inventories and a top-level change detector.
% Complements diff (grid-level) and objmatch (object-pair correspondences).
% No cross-pack dependencies.
:- module(scenecmp, [
    % sm_n_objs/2: number of objects in an obj list.
    sm_n_objs/2,
    % sm_total_cells/2: total cell count across all objects.
    sm_total_cells/2,
    % sm_colors/2: sorted list of distinct colors in an obj list.
    sm_colors/2,
    % sm_forms/2: sorted list of distinct normalized shapes in an obj list.
    sm_forms/2,
    % sm_same_n_objs/2: Before and After have the same object count.
    sm_same_n_objs/2,
    % sm_same_total_cells/2: Before and After have the same total cell count.
    sm_same_total_cells/2,
    % sm_same_colors/2: Before and After have exactly the same color set.
    sm_same_colors/2,
    % sm_same_forms/2: Before and After have exactly the same form set.
    sm_same_forms/2,
    % sm_added_colors/3: colors present in After but not in Before.
    sm_added_colors/3,
    % sm_removed_colors/3: colors present in Before but not in After.
    sm_removed_colors/3,
    % sm_added_forms/3: normalized forms present in After but not in Before.
    sm_added_forms/3,
    % sm_removed_forms/3: normalized forms present in Before but not in After.
    sm_removed_forms/3,
    % sm_n_color_change/3: total count of added plus removed colors.
    sm_n_color_change/3,
    % sm_any_change/2: true iff color set, form set, or object count differ.
    sm_any_change/2
]).

% Load list utilities.
:- use_module(library(lists), [member/2, subtract/3]).

% --- Private helpers ---------------------------------------------------------

% sm_color_(+Obj, -Color): extract color.
sm_color_(obj(Color, _), Color).

% sm_size_(+Obj, -N): cell count.
sm_size_(obj(_, Cells), N) :-
    length(Cells, N).

% sm_norm_(+Obj, -Sorted): normalize to origin; sort cells.
sm_norm_(obj(_, Cells), Sorted) :-
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

% sm_distinct_colors_(+Objs, -Colors): sorted distinct colors.
sm_distinct_colors_(Objs, Colors) :-
    findall(C, (member(O, Objs), sm_color_(O, C)), All),
    sort(All, Colors).

% sm_distinct_forms_(+Objs, -Forms): sorted distinct normalized forms.
sm_distinct_forms_(Objs, Forms) :-
    findall(Norm, (member(O, Objs), sm_norm_(O, Norm)), All),
    sort(All, Forms).

% --- Exported predicates -----------------------------------------------------

% sm_n_objs(+Objs, -N): count of objects.
sm_n_objs(Objs, N) :-
    length(Objs, N).

% sm_total_cells(+Objs, -N): total cells across all objects.
sm_total_cells(Objs, N) :-
    findall(Count, (member(O, Objs), sm_size_(O, Count)), Counts),
    sum_list(Counts, N).

% sm_colors(+Objs, -Colors): sorted distinct colors in the obj list.
sm_colors(Objs, Colors) :-
    sm_distinct_colors_(Objs, Colors).

% sm_forms(+Objs, -Forms): sorted distinct normalized forms.
sm_forms(Objs, Forms) :-
    sm_distinct_forms_(Objs, Forms).

% sm_same_n_objs(+Before, +After): both have the same number of objects.
sm_same_n_objs(Before, After) :-
    length(Before, N),
    length(After, N).

% sm_same_total_cells(+Before, +After): both have the same total cell count.
sm_same_total_cells(Before, After) :-
    sm_total_cells(Before, N),
    sm_total_cells(After, N).

% sm_same_colors(+Before, +After): both have exactly the same color set.
sm_same_colors(Before, After) :-
    sm_distinct_colors_(Before, CB),
    sm_distinct_colors_(After, CB).

% sm_same_forms(+Before, +After): both have exactly the same form set.
sm_same_forms(Before, After) :-
    sm_distinct_forms_(Before, FB),
    sm_distinct_forms_(After, FB).

% sm_added_colors(+Before, +After, -Added): colors in After not present in Before.
sm_added_colors(Before, After, Added) :-
    sm_distinct_colors_(Before, CB),
    sm_distinct_colors_(After, CA),
    subtract(CA, CB, Added).

% sm_removed_colors(+Before, +After, -Removed): colors in Before not present in After.
sm_removed_colors(Before, After, Removed) :-
    sm_distinct_colors_(Before, CB),
    sm_distinct_colors_(After, CA),
    subtract(CB, CA, Removed).

% sm_added_forms(+Before, +After, -Added): forms in After not present in Before.
sm_added_forms(Before, After, Added) :-
    sm_distinct_forms_(Before, FB),
    sm_distinct_forms_(After, FA),
    subtract(FA, FB, Added).

% sm_removed_forms(+Before, +After, -Removed): forms in Before not present in After.
sm_removed_forms(Before, After, Removed) :-
    sm_distinct_forms_(Before, FB),
    sm_distinct_forms_(After, FA),
    subtract(FB, FA, Removed).

% sm_n_color_change(+Before, +After, -N): |added colors| + |removed colors|.
sm_n_color_change(Before, After, N) :-
    sm_added_colors(Before, After, Added),
    sm_removed_colors(Before, After, Removed),
    length(Added, NA),
    length(Removed, NR),
    N is NA + NR.

% sm_any_change(+Before, +After): true iff scenes differ in count, color, or form.
sm_any_change(Before, After) :-
    (   \+ sm_same_n_objs(Before, After)
    ;   \+ sm_same_colors(Before, After)
    ;   \+ sm_same_forms(Before, After)
    ),
    !.
