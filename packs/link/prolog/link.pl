% link.pl - Layer 158: Object-to-Object Correspondence Linking (lk_* prefix).
% Builds and manipulates correspondence links between pairs of obj(Color, Cells)
% terms. A link is an O1-O2 pair where O1 comes from one object list and O2 from
% another. Provides predicates for building links by position, proximity, color,
% size, and form; extracting sources and targets; filtering; and applying
% correspondence (transferring color or cells from one side to the other).
:- module(link, [
    % lk_by_position/3: link lists element-wise by index (zip); truncates at shorter.
    lk_by_position/3,
    % lk_by_nearest/3: each obj in Objs1 linked to its nearest obj in Objs2 (centroid).
    lk_by_nearest/3,
    % lk_by_color/3: all O1-O2 pairs sharing the same color atom.
    lk_by_color/3,
    % lk_by_size/3: all O1-O2 pairs with the same cell count.
    lk_by_size/3,
    % lk_by_form/3: all O1-O2 pairs with the same origin-normalized form.
    lk_by_form/3,
    % lk_source/2: extract the O1 (left) object from each link.
    lk_source/2,
    % lk_target/2: extract the O2 (right) object from each link.
    lk_target/2,
    % lk_invert/2: swap O1 and O2 in every link.
    lk_invert/2,
    % lk_count/2: number of links.
    lk_count/2,
    % lk_apply_color/2: recolor each O1 with O2's color; preserve O1's cells.
    lk_apply_color/2,
    % lk_apply_cells/2: replace O1's cells with O2's cells; keep O1's color.
    lk_apply_cells/2,
    % lk_filter_same_color/2: keep only links where O1 and O2 have the same color.
    lk_filter_same_color/2,
    % lk_filter_diff_color/2: keep only links where O1 and O2 have different colors.
    lk_filter_diff_color/2,
    % lk_unlinked/3: objects from a list not appearing as O1 in any link.
    lk_unlinked/3
]).

% Import list utilities; length/2, sort/2, findall/3 are built-ins.
:- use_module(library(lists), [member/2, min_list/2, sum_list/2]).

% lk_by_position(+Objs1, +Objs2, -Links): zip two lists element-wise by index.
% The Nth link is Objs1[N]-Objs2[N]. Stops at the shorter list.
lk_by_position([], _, []) :- !.
lk_by_position(_, [], []) :- !.
lk_by_position([O1|T1], [O2|T2], [O1-O2|Links]) :-
% Recursively zip the tails.
    lk_by_position(T1, T2, Links).

% lk_by_nearest(+Objs1, +Objs2, -Links): each obj in Objs1 linked to its nearest in Objs2.
% Nearest is by Manhattan centroid distance. Ties broken by first in Objs2.
% Produces one link per object in Objs1; fails silently if Objs2 is empty.
lk_by_nearest(_, [], []) :- !.
lk_by_nearest(Objs1, Objs2, Links) :-
% For each O1, find the nearest O2 and build the link.
    findall(O1-Nearest, (
        member(O1, Objs1),
        lk_nearest_(O1, Objs2, Nearest)
    ), Links).

% lk_nearest_(+Ref, +Objs, -Nearest): private helper; nearest in Objs to Ref.
lk_nearest_(Ref, Objs, Nearest) :-
% Compute centroid distance from Ref to every candidate.
    lk_centroid_(Ref, R1, C1),
    findall(D-O, (
        member(O, Objs),
        lk_centroid_(O, R2, C2),
        D is abs(R1-R2) + abs(C1-C2)
    ), Pairs),
% Find minimum distance.
    findall(D, member(D-_, Pairs), Ds),
    min_list(Ds, MinD),
% Take first candidate at minimum distance; cut stops after first success.
    member(MinD-Nearest, Pairs), !.

% lk_centroid_(+Obj, -R, -C): integer-truncated centroid of an obj term.
lk_centroid_(obj(_,Cells), R, C) :-
% Sum row values and divide by cell count.
    findall(Rr, member(r(Rr,_), Cells), Rs),
    sum_list(Rs, SumR),
% Sum column values and divide by cell count.
    findall(Cc, member(r(_,Cc), Cells), Cs),
    sum_list(Cs, SumC),
    length(Cells, N),
    R is SumR // N,
    C is SumC // N.

% lk_by_color(+Objs1, +Objs2, -Links): all O1-O2 pairs sharing the same color atom.
% Produces the sorted Cartesian product filtered by equal color.
lk_by_color(Objs1, Objs2, Links) :-
% Pair every O1 with every O2 that has the same color.
    findall(O1-O2, (
        member(O1, Objs1), O1 = obj(C,_),
        member(O2, Objs2), O2 = obj(C,_)
    ), Links0),
    sort(Links0, Links).

% lk_by_size(+Objs1, +Objs2, -Links): all O1-O2 pairs with the same cell count.
lk_by_size(Objs1, Objs2, Links) :-
% Pair every O1 with every O2 that has the same number of cells.
    findall(O1-O2, (
        member(O1, Objs1), O1 = obj(_,Cells1), length(Cells1, N),
        member(O2, Objs2), O2 = obj(_,Cells2), length(Cells2, N)
    ), Links0),
    sort(Links0, Links).

% lk_by_form(+Objs1, +Objs2, -Links): all O1-O2 pairs sharing the same normalized form.
% Normalized form: translate to origin (min row=0, min col=0), then sort.
lk_by_form(Objs1, Objs2, Links) :-
% Pair every O1 with every O2 that has the same normalized cell list.
    findall(O1-O2, (
        member(O1, Objs1), O1 = obj(_,C1), lk_norm_(C1, F),
        member(O2, Objs2), O2 = obj(_,C2), lk_norm_(C2, F)
    ), Links0),
    sort(Links0, Links).

% lk_norm_(+Cells, -Form): origin-normalized sorted cell list.
lk_norm_(Cells, Form) :-
    findall(R, member(r(R,_), Cells), Rs), min_list(Rs, MinR),
    findall(C, member(r(_,C), Cells), Cs), min_list(Cs, MinC),
    findall(r(R2,C2), (
        member(r(R,C), Cells),
        R2 is R - MinR,
        C2 is C - MinC
    ), Form0),
    sort(Form0, Form).

% lk_source(+Links, -Sources): list of O1 from each O1-O2 link, in link order.
lk_source(Links, Sources) :-
% Extract the left element of each pair.
    findall(O1, member(O1-_, Links), Sources).

% lk_target(+Links, -Targets): list of O2 from each O1-O2 link, in link order.
lk_target(Links, Targets) :-
% Extract the right element of each pair.
    findall(O2, member(_-O2, Links), Targets).

% lk_invert(+Links, -Inverted): swap O1 and O2 in every link.
lk_invert(Links, Inverted) :-
% Build O2-O1 pairs from each O1-O2 link.
    findall(O2-O1, member(O1-O2, Links), Inverted).

% lk_count(+Links, -N): number of links.
lk_count(Links, N) :-
% Count is the list length.
    length(Links, N).

% lk_apply_color(+Links, -Result): recolor each O1 with O2's color; keep O1's cells.
% Result is a list of obj(O2Color, O1Cells) terms in link order.
lk_apply_color(Links, Result) :-
% For each link, pair O1's cells with O2's color.
    findall(obj(C2,Cells1), member(obj(_,Cells1)-obj(C2,_), Links), Result).

% lk_apply_cells(+Links, -Result): replace O1's cells with O2's cells; keep O1's color.
% Result is a list of obj(O1Color, O2Cells) terms in link order.
lk_apply_cells(Links, Result) :-
% For each link, pair O1's color with O2's cells.
    findall(obj(C1,Cells2), member(obj(C1,_)-obj(_,Cells2), Links), Result).

% lk_filter_same_color(+Links, -Same): keep links where O1 and O2 share the same color.
lk_filter_same_color(Links, Same) :-
% Keep pairs where both color atoms are identical.
    findall(O1-O2, (member(O1-O2, Links), O1 = obj(C,_), O2 = obj(C,_)), Same).

% lk_filter_diff_color(+Links, -Diff): keep links where O1 and O2 have different colors.
lk_filter_diff_color(Links, Diff) :-
% Keep pairs where color atoms differ.
    findall(O1-O2, (
        member(O1-O2, Links),
        O1 = obj(C1,_), O2 = obj(C2,_), C1 \= C2
    ), Diff).

% lk_unlinked(+Objs, +Links, -Unlinked): objects from Objs not appearing as O1 in any link.
lk_unlinked(Objs, Links, Unlinked) :-
% Keep objects that do not match any link's source (by exact term equality).
    findall(O, (member(O, Objs), \+ member(O-_, Links)), Unlinked).
