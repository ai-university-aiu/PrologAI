% delta.pl - Layer 155: Scene-Level Delta Analysis (dl_* prefix).
% Compares two object scenes (lists of obj(Color, Cells) terms) and computes
% what changed: objects added, removed, recolored, or left unchanged.
% Uses exact cell-set equality for matching: two objects match iff they have
% the same Cells list. Enables learning what transformation was applied to a
% scene, which is the first step in solving multi-step ARC-AGI-2 tasks.
:- module(delta, [
    % dl_added/3: objects in Scene2 whose cell set does not appear in Scene1.
    dl_added/3,
    % dl_removed/3: objects in Scene1 whose cell set does not appear in Scene2.
    dl_removed/3,
    % dl_matched/3: Obj1-Obj2 pairs sharing identical cell sets across scenes.
    dl_matched/3,
    % dl_recolored/3: From-To color pairs where cell sets match but colors differ.
    dl_recolored/3,
    % dl_unchanged/3: objects with identical color and cells in both scenes.
    dl_unchanged/3,
    % dl_color_gain/3: colors in Scene2 not present in Scene1.
    dl_color_gain/3,
    % dl_color_loss/3: colors in Scene1 not present in Scene2.
    dl_color_loss/3,
    % dl_count_diff/3: object count change; N = length(S2) - length(S1).
    dl_count_diff/3,
    % dl_size_diff/3: total cell count change; N = total_cells(S2) - total_cells(S1).
    dl_size_diff/3,
    % dl_is_added_only/2: succeeds iff no objects were removed or recolored.
    dl_is_added_only/2,
    % dl_is_removed_only/2: succeeds iff no objects were added or recolored.
    dl_is_removed_only/2,
    % dl_is_recolor_only/2: succeeds iff no objects were added or removed.
    dl_is_recolor_only/2,
    % dl_is_stable/2: succeeds iff the two scenes are identical.
    dl_is_stable/2,
    % dl_scene_diff/3: compute all delta components as a delta/4 compound term.
    dl_scene_diff/3
]).

% Import list utilities; length/2, findall/3, sort/2 are built-ins.
:- use_module(library(lists), [member/2, sum_list/2]).

% dl_added(+S1, +S2, -Added): collect objects in S2 with no cell-set match in S1.
dl_added(S1, S2, Added) :-
% For each object in S2, extract its cell set.
    findall(O2, (
        member(O2, S2),
% Bind Cells from O2.
        O2 = obj(_, Cells),
% Succeed only when no object in S1 has the same cell set.
        \+ member(obj(_, Cells), S1)
    ), Added).

% dl_removed(+S1, +S2, -Removed): collect objects in S1 with no cell-set match in S2.
dl_removed(S1, S2, Removed) :-
% For each object in S1, extract its cell set.
    findall(O1, (
        member(O1, S1),
% Bind Cells from O1.
        O1 = obj(_, Cells),
% Succeed only when no object in S2 has the same cell set.
        \+ member(obj(_, Cells), S2)
    ), Removed).

% dl_matched(+S1, +S2, -Pairs): list of O1-O2 pairs sharing identical cell sets.
% An object in S1 matches an object in S2 iff they have exactly the same Cells list.
% Deduplicates with sort/2.
dl_matched(S1, S2, Pairs) :-
% Collect all cross-scene pairs with identical cell sets.
    findall(O1-O2, (
        member(O1, S1),
% Bind Cells from O1.
        O1 = obj(_, Cells),
        member(O2, S2),
% Unify Cells into O2; succeeds only if O2 has exactly these Cells.
        O2 = obj(_, Cells)
    ), Pairs0),
% Deduplicate; standard order handles nested terms correctly.
    sort(Pairs0, Pairs).

% dl_recolored(+S1, +S2, -Changes): sorted From-To color pairs for matched objects
% whose color changed between scenes.
dl_recolored(S1, S2, Changes) :-
% Collect From-To pairs where S1 and S2 share cell sets but differ in color.
    findall(C1-C2, (
        member(obj(C1, Cells), S1),
        member(obj(C2, Cells), S2),
% Only include pairs where the color actually changed.
        C1 \= C2
    ), Changes0),
% Deduplicate.
    sort(Changes0, Changes).

% dl_unchanged(+S1, +S2, -Objs): objects with identical color AND cells in both scenes.
dl_unchanged(S1, S2, Objs) :-
% Collect objects that appear verbatim in both lists.
    findall(O, (
        member(O, S1),
% Unify requires O to appear (with same color+cells) in S2.
        member(O, S2)
    ), Objs0),
% Deduplicate.
    sort(Objs0, Objs).

% dl_color_gain(+S1, +S2, -Colors): colors present in S2 but not in S1.
dl_color_gain(S1, S2, Colors) :-
% Build the color palette of S1.
    findall(C, member(obj(C,_), S1), Cs1),
    sort(Cs1, Pal1),
% Build the color palette of S2.
    findall(C, member(obj(C,_), S2), Cs2),
    sort(Cs2, Pal2),
% Retain colors in Pal2 that are absent from Pal1.
    findall(C, (member(C, Pal2), \+ member(C, Pal1)), Colors).

% dl_color_loss(+S1, +S2, -Colors): colors present in S1 but not in S2.
dl_color_loss(S1, S2, Colors) :-
% Build the color palette of S1.
    findall(C, member(obj(C,_), S1), Cs1),
    sort(Cs1, Pal1),
% Build the color palette of S2.
    findall(C, member(obj(C,_), S2), Cs2),
    sort(Cs2, Pal2),
% Retain colors in Pal1 that are absent from Pal2.
    findall(C, (member(C, Pal1), \+ member(C, Pal2)), Colors).

% dl_count_diff(+S1, +S2, -N): N is the change in object count; N = |S2| - |S1|.
% Positive means S2 has more objects; negative means fewer.
dl_count_diff(S1, S2, N) :-
% Count objects in S1 and S2.
    length(S1, N1),
    length(S2, N2),
% Difference.
    N is N2 - N1.

% dl_size_diff(+S1, +S2, -N): N is the change in total cell count; N = cells(S2) - cells(S1).
% Positive means S2 uses more cells; negative means fewer.
dl_size_diff(S1, S2, N) :-
% Collect cell counts for each object in S1.
    findall(Sz, (member(obj(_,Cells), S1), length(Cells, Sz)), Szs1),
    sum_list(Szs1, Total1),
% Collect cell counts for each object in S2.
    findall(Sz, (member(obj(_,Cells), S2), length(Cells, Sz)), Szs2),
    sum_list(Szs2, Total2),
% Net change.
    N is Total2 - Total1.

% dl_is_added_only(+S1, +S2): succeeds iff the only change was new objects being added.
% No removals and no recolorings occurred.
dl_is_added_only(S1, S2) :-
% Verify nothing was removed.
    dl_removed(S1, S2, []),
% Verify nothing was recolored.
    dl_recolored(S1, S2, []).

% dl_is_removed_only(+S1, +S2): succeeds iff the only change was objects being removed.
% No additions and no recolorings occurred.
dl_is_removed_only(S1, S2) :-
% Verify nothing was added.
    dl_added(S1, S2, []),
% Verify nothing was recolored.
    dl_recolored(S1, S2, []).

% dl_is_recolor_only(+S1, +S2): succeeds iff no objects were added or removed.
% The two scenes have the same set of cell positions; only colors may differ.
dl_is_recolor_only(S1, S2) :-
% Verify no additions.
    dl_added(S1, S2, []),
% Verify no removals.
    dl_removed(S1, S2, []).

% dl_is_stable(+S1, +S2): succeeds iff the two scenes are identical.
% No additions, removals, or recolorings occurred.
dl_is_stable(S1, S2) :-
% Verify no additions.
    dl_added(S1, S2, []),
% Verify no removals.
    dl_removed(S1, S2, []),
% Verify no recolorings.
    dl_recolored(S1, S2, []).

% dl_scene_diff(+S1, +S2, -Delta): compute all four delta components in one call.
% Delta = delta(Added, Removed, Recolored, Unchanged).
dl_scene_diff(S1, S2, delta(Added, Removed, Recolored, Unchanged)) :-
% Compute added objects.
    dl_added(S1, S2, Added),
% Compute removed objects.
    dl_removed(S1, S2, Removed),
% Compute recolor changes.
    dl_recolored(S1, S2, Recolored),
% Compute unchanged objects.
    dl_unchanged(S1, S2, Unchanged).
