% pigment.pl - Layer 154: Bulk Color Operations on Object Scenes (pg_* prefix).
% Provides scene-level color manipulation: recoloring by rule, applying color tables,
% inferring color tables from example pairs, zip-recoloring, majority/minority/unique
% color targeting, and color table utilities. Operates on obj(Color, Cells) lists.
:- module(pigment, [
    % pigment_recolor_all/3: set every obj in the scene to a fixed color.
    pigment_recolor_all/3,
    % pigment_recolor_one/4: change all objs with color From to color To; keep others unchanged.
    pigment_recolor_one/4,
    % pigment_swap/4: swap colors C1 and C2 throughout the scene.
    pigment_swap/4,
    % pigment_apply_table/3: apply a From-To color table; objs not in table keep their color.
    pigment_apply_table/3,
    % pigment_apply_table_strict/3: apply table; keep only objs whose color has a table entry.
    pigment_apply_table_strict/3,
    % pigment_infer_table/3: infer color table from two scenes with identical cell structures.
    pigment_infer_table/3,
    % pigment_zip_recolor/3: recolor each obj with the corresponding color from a Colors list.
    pigment_zip_recolor/3,
    % pigment_majority_to/3: recolor all objs sharing the most frequent color to a new color.
    pigment_majority_to/3,
    % pigment_minority_to/3: recolor all objs sharing the least frequent color to a new color.
    pigment_minority_to/3,
    % pigment_unique_to/3: recolor objs whose color appears exactly once to a new color.
    pigment_unique_to/3,
    % pigment_shared_to/3: recolor objs whose color appears more than once to a new color.
    pigment_shared_to/3,
    % pigment_invert_table/2: produce the inverse mapping by swapping From and To in each pair.
    pigment_invert_table/2,
    % pigment_table_from/2: sorted list of From colors appearing in the table.
    pigment_table_from/2,
    % pigment_consistent/1: succeed if no From color maps to two different To colors.
    pigment_consistent/1
]).

% Import list utilities; findall/3, sort/2, length/2 are built-ins.
:- use_module(library(lists), [member/2, memberchk/2, min_list/2, max_list/2]).

% pigment_count_by_color_(+Objs, -Counts): private helper producing sorted Color-N pairs.
pigment_count_by_color_(Objs, Counts) :-
    findall(C, member(obj(C,_), Objs), Cs0),
    sort(Cs0, Colors),
    findall(C-N, (
        member(C, Colors),
        findall(_, member(obj(C,_), Objs), Grp),
        length(Grp, N)
    ), Counts).

% pigment_recolor_all(+Objs, +Color, -Out): set every obj's color to Color.
pigment_recolor_all(Objs, Color, Out) :-
% Replace each obj's color with Color, keeping the cell list unchanged.
    findall(obj(Color, Cells), member(obj(_, Cells), Objs), Out).

% pigment_recolor_one(+Objs, +From, +To, -Out): change color From to To everywhere.
pigment_recolor_one(Objs, From, To, Out) :-
% For each obj: if color = From replace with To, else keep original.
    findall(O, (
        member(obj(C, Cells), Objs),
        (C =:= From -> O = obj(To, Cells) ; O = obj(C, Cells))
    ), Out).

% pigment_swap(+Objs, +C1, +C2, -Out): exchange colors C1 and C2 throughout the scene.
pigment_swap(Objs, C1, C2, Out) :-
% Apply a two-way color exchange via nested if-then-else.
    findall(O, (
        member(obj(C, Cells), Objs),
        (   C =:= C1 -> O = obj(C2, Cells)
        ;   C =:= C2 -> O = obj(C1, Cells)
        ;   O = obj(C, Cells)
        )
    ), Out).

% pigment_apply_table(+Objs, +Table, -Out): apply color table; keep color if not in table.
% Table is a list of From-To pairs (e.g. [1-5, 2-6]).
pigment_apply_table(Objs, Table, Out) :-
% For each obj: look up its color in the table; use new color if found, else original.
    findall(O, (
        member(obj(C, Cells), Objs),
        (memberchk(C-New, Table) -> O = obj(New, Cells) ; O = obj(C, Cells))
    ), Out).

% pigment_apply_table_strict(+Objs, +Table, -Out): apply table; exclude objs not in table.
pigment_apply_table_strict(Objs, Table, Out) :-
% Keep only objs whose color has a mapping in the table; apply the mapping.
    findall(obj(New, Cells), (
        member(obj(C, Cells), Objs),
        memberchk(C-New, Table)
    ), Out).

% pigment_infer_table(+Objs1, +Objs2, -Table): infer color mapping from same-cell obj pairs.
% For each pair of obj terms with identical cell sets, record OldColor-NewColor.
% Deduplicates with sort/2. Fails if no matching pairs exist.
pigment_infer_table(Objs1, Objs2, Table) :-
% Collect all color-change pairs from obj terms with identical cell sets.
    findall(C1-C2, (
        member(obj(C1, Cells), Objs1),
        member(obj(C2, Cells), Objs2)
    ), Pairs0),
% Remove duplicates and sort for a canonical table.
    sort(Pairs0, Table).

% pigment_zip_recolor(+Objs, +Colors, -Out): recolor each obj with the matching Colors list entry.
% Stops when either list ends (truncation semantics).
pigment_zip_recolor([], _, []) :- !.
pigment_zip_recolor(_, [], []) :- !.
pigment_zip_recolor([obj(_, Cells)|Os], [C|Cs], [obj(C, Cells)|Rest]) :-
% Pair each obj with the next color in the list.
    pigment_zip_recolor(Os, Cs, Rest).

% pigment_majority_to(+Objs, +Color, -Out): recolor all majority-color objs to Color.
% Majority color = most frequent; smallest color on ties.
pigment_majority_to(Objs, Color, Out) :-
% Build color counts.
    pigment_count_by_color_(Objs, Counts),
% Maximum count.
    findall(N, member(_-N, Counts), Ns),
    max_list(Ns, MaxN),
% Majority color: first in sorted counts at max count (smallest color on ties).
    member(MajorC-MaxN, Counts), !,
% Recolor majority-colored objs, keep others.
    findall(O, (
        member(obj(C, Cells), Objs),
        (C =:= MajorC -> O = obj(Color, Cells) ; O = obj(C, Cells))
    ), Out).

% pigment_minority_to(+Objs, +Color, -Out): recolor all minority-color objs to Color.
% Minority color = least frequent; smallest color on ties.
pigment_minority_to(Objs, Color, Out) :-
% Build color counts.
    pigment_count_by_color_(Objs, Counts),
% Minimum count.
    findall(N, member(_-N, Counts), Ns),
    min_list(Ns, MinN),
% Minority color: first in sorted counts at min count (smallest color on ties).
    member(MinorC-MinN, Counts), !,
% Recolor minority-colored objs, keep others.
    findall(O, (
        member(obj(C, Cells), Objs),
        (C =:= MinorC -> O = obj(Color, Cells) ; O = obj(C, Cells))
    ), Out).

% pigment_unique_to(+Objs, +Color, -Out): recolor objs with a unique color to Color.
% An obj has a unique color if that color appears exactly once in Objs.
pigment_unique_to(Objs, Color, Out) :-
% Build color counts and collect unique colors.
    pigment_count_by_color_(Objs, Counts),
    findall(C, member(C-1, Counts), UniqueColors),
% Recolor objs with a unique color, keep others.
    findall(O, (
        member(obj(C, Cells), Objs),
        (memberchk(C, UniqueColors) -> O = obj(Color, Cells) ; O = obj(C, Cells))
    ), Out).

% pigment_shared_to(+Objs, +Color, -Out): recolor objs with a shared color to Color.
% A color is shared if it appears more than once in Objs.
pigment_shared_to(Objs, Color, Out) :-
% Build color counts and collect shared colors.
    pigment_count_by_color_(Objs, Counts),
    findall(C, (member(C-N, Counts), N > 1), SharedColors),
% Recolor objs with a shared color, keep others.
    findall(O, (
        member(obj(C, Cells), Objs),
        (memberchk(C, SharedColors) -> O = obj(Color, Cells) ; O = obj(C, Cells))
    ), Out).

% pigment_invert_table(+Table, -Inv): produce the inverse by swapping each From-To pair.
pigment_invert_table(Table, Inv) :-
% Swap every From-To pair to To-From.
    findall(To-From, member(From-To, Table), Inv).

% pigment_table_from(+Table, -Froms): sorted list of From colors in the table.
pigment_table_from(Table, Froms) :-
% Collect From values and deduplicate with sort/2.
    findall(F, member(F-_, Table), Fs),
    sort(Fs, Froms).

% pigment_consistent(+Table): succeed if no From color maps to two different To colors.
pigment_consistent(Table) :-
% For every pair of entries with the same From, the To must also match.
    \+ (member(F-T1, Table), member(F-T2, Table), T1 \= T2).
