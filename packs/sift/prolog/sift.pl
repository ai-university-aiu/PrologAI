% sift.pl - Layer 153: Object List Filtering (si_* prefix).
% Filters lists of obj(Color, Cells) terms by color, size, exact normalized form,
% size extremes, color uniqueness, and border adjacency. All predicates take an
% input list and return the subset of objects that satisfy the given predicate.
% An empty result list is a valid answer; no predicate fails due to empty output.
:- module(sift, [
    % si_by_color/3: keep only objs whose color equals Color.
    si_by_color/3,
    % si_not_color/3: keep only objs whose color differs from Color.
    si_not_color/3,
    % si_by_size/3: keep only objs with exactly N cells.
    si_by_size/3,
    % si_by_form/3: keep only objs whose origin-normalized cell list equals Form.
    si_by_form/3,
    % si_larger_than/3: keep only objs with strictly more than N cells.
    si_larger_than/3,
    % si_smaller_than/3: keep only objs with strictly fewer than N cells.
    si_smaller_than/3,
    % si_color_in/3: keep only objs whose color is a member of Colors.
    si_color_in/3,
    % si_color_not_in/3: keep only objs whose color is not a member of Colors.
    si_color_not_in/3,
    % si_max_size/2: keep all objs with the maximum cell count in the list.
    si_max_size/2,
    % si_min_size/2: keep all objs with the minimum cell count in the list.
    si_min_size/2,
    % si_unique_color/2: keep objs whose color appears exactly once in the list.
    si_unique_color/2,
    % si_shared_color/2: keep objs whose color appears more than once in the list.
    si_shared_color/2,
    % si_on_border/4: keep objs with at least one cell on the H-by-W grid border.
    si_on_border/4,
    % si_off_border/4: keep objs with no cell on the H-by-W grid border.
    si_off_border/4
]).

% Import list utilities; sort/2, findall/3, length/2 are built-ins.
:- use_module(library(lists), [member/2, memberchk/2, min_list/2, max_list/2]).

% si_norm_(+Cells, -Norm): translate cell list to origin (min row=0, min col=0), sorted.
% Private; used by si_by_form to normalize without importing from another pack.
si_norm_(Cells, Norm) :-
% Collect all row indices.
    findall(R, member(r(R,_), Cells), Rs),
% Collect all column indices.
    findall(C, member(r(_,C), Cells), Cs),
% Compute bbox top-left.
    min_list(Rs, MinR),
    min_list(Cs, MinC),
% Translate and sort.
    findall(r(NR,NC), (
        member(r(R,C), Cells),
        NR is R - MinR,
        NC is C - MinC
    ), Raw),
    sort(Raw, Norm).

% si_on_border_(+R, +C, +H, +W): succeed if r(R,C) is on the border of H-by-W grid.
% Border condition: row 0, row H-1, col 0, or col W-1.
si_on_border_(R, _, _H, _W) :- R =:= 0, !.
si_on_border_(R, _, H, _W)  :- R =:= H - 1, !.
si_on_border_(_, C, _H, _W) :- C =:= 0, !.
si_on_border_(_, C, _H, W)  :- C =:= W - 1.

% si_by_color(+Objs, +Color, -Out): keep objs matching the given color.
si_by_color(Objs, Color, Out) :-
% Select only obj terms with the specified color.
    findall(O, (member(O, Objs), O = obj(Color, _)), Out).

% si_not_color(+Objs, +Color, -Out): keep objs whose color is not Color.
si_not_color(Objs, Color, Out) :-
% Select obj terms with any color other than Color.
    findall(O, (member(O, Objs), O = obj(C, _), C \= Color), Out).

% si_by_size(+Objs, +N, -Out): keep objs with exactly N cells.
si_by_size(Objs, N, Out) :-
% Select obj terms whose cell list has exactly N elements.
    findall(O, (member(O, Objs), O = obj(_, Cells), length(Cells, N)), Out).

% si_by_form(+Objs, +Form, -Out): keep objs whose normalized cell list equals Form.
si_by_form(Objs, Form, Out) :-
% Select obj terms whose origin-normalized cell list unifies with Form.
    findall(O, (
        member(O, Objs),
        O = obj(_, Cells),
        si_norm_(Cells, Form)
    ), Out).

% si_larger_than(+Objs, +N, -Out): keep objs with strictly more than N cells.
si_larger_than(Objs, N, Out) :-
% Select obj terms with cell count > N.
    findall(O, (member(O, Objs), O = obj(_, Cells), length(Cells, S), S > N), Out).

% si_smaller_than(+Objs, +N, -Out): keep objs with strictly fewer than N cells.
si_smaller_than(Objs, N, Out) :-
% Select obj terms with cell count < N.
    findall(O, (member(O, Objs), O = obj(_, Cells), length(Cells, S), S < N), Out).

% si_color_in(+Objs, +Colors, -Out): keep objs whose color is a member of Colors.
si_color_in(Objs, Colors, Out) :-
% Select obj terms with a color appearing in the Colors list.
    findall(O, (member(O, Objs), O = obj(C, _), memberchk(C, Colors)), Out).

% si_color_not_in(+Objs, +Colors, -Out): keep objs whose color is not in Colors.
si_color_not_in(Objs, Colors, Out) :-
% Select obj terms with a color not appearing in the Colors list.
    findall(O, (member(O, Objs), O = obj(C, _), \+ memberchk(C, Colors)), Out).

% si_max_size(+Objs, -Out): keep all objs tied for the maximum cell count.
si_max_size(Objs, Out) :-
% Collect all cell counts.
    findall(S, (member(obj(_, Cells), Objs), length(Cells, S)), Ss),
% Maximum count.
    max_list(Ss, MaxS),
% Keep all objs at that count.
    findall(O, (member(O, Objs), O = obj(_, Cells), length(Cells, MaxS)), Out).

% si_min_size(+Objs, -Out): keep all objs tied for the minimum cell count.
si_min_size(Objs, Out) :-
% Collect all cell counts.
    findall(S, (member(obj(_, Cells), Objs), length(Cells, S)), Ss),
% Minimum count.
    min_list(Ss, MinS),
% Keep all objs at that count.
    findall(O, (member(O, Objs), O = obj(_, Cells), length(Cells, MinS)), Out).

% si_unique_color(+Objs, -Out): keep objs whose color appears exactly once in Objs.
si_unique_color(Objs, Out) :-
% Count objs per color.
    findall(C, member(obj(C, _), Objs), Cs0),
    sort(Cs0, Colors),
    findall(C-N, (
        member(C, Colors),
        findall(_, (member(obj(C, _), Objs)), Grp),
        length(Grp, N)
    ), ColorCounts),
% Collect colors with count = 1.
    findall(C, member(C-1, ColorCounts), UniqueColors),
% Keep objs with a unique color.
    findall(O, (member(O, Objs), O = obj(C, _), memberchk(C, UniqueColors)), Out).

% si_shared_color(+Objs, -Out): keep objs whose color appears more than once in Objs.
si_shared_color(Objs, Out) :-
% Count objs per color.
    findall(C, member(obj(C, _), Objs), Cs0),
    sort(Cs0, Colors),
    findall(C-N, (
        member(C, Colors),
        findall(_, (member(obj(C, _), Objs)), Grp),
        length(Grp, N)
    ), ColorCounts),
% Collect colors with count > 1.
    findall(C, (member(C-N, ColorCounts), N > 1), SharedColors),
% Keep objs with a shared color.
    findall(O, (member(O, Objs), O = obj(C, _), memberchk(C, SharedColors)), Out).

% si_on_border(+Objs, +H, +W, -Out): keep objs with at least one border cell.
% H = grid height (rows 0..H-1), W = grid width (cols 0..W-1).
si_on_border(Objs, H, W, Out) :-
% Select obj terms where any cell satisfies the border condition.
    findall(O, (
        member(O, Objs),
        O = obj(_, Cells),
        member(r(R, C), Cells),
        si_on_border_(R, C, H, W)
    ), Out).

% si_off_border(+Objs, +H, +W, -Out): keep objs with no cell on the grid border.
si_off_border(Objs, H, W, Out) :-
% Select obj terms where no cell satisfies the border condition.
    findall(O, (
        member(O, Objs),
        O = obj(_, Cells),
        \+ (member(r(R, C), Cells), si_on_border_(R, C, H, W))
    ), Out).
