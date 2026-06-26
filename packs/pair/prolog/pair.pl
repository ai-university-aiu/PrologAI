% pair.pl - Layer 149: Object Pairing and Scene Correspondence (pr_* prefix).
% Operates on obj(Color, Cells) terms where Cells is a sorted list of r(R,C) terms,
% as produced by the scene pack. Provides predicates for grouping, comparing,
% and matching objects between two scene lists. The D4 canonical shape is the
% lexicographically smallest among all 8 symmetric transforms, enabling shape
% comparison that is invariant to rotation and reflection.
:- module(pair, [
    % pr_obj_shape/2: D4-canonical shape of an obj term (invariant to rotation and reflection).
    pr_obj_shape/2,
    % pr_obj_color/2: extract the color from an obj(Color, Cells) term.
    pr_obj_color/2,
    % pr_obj_size/2: number of cells in an obj term.
    pr_obj_size/2,
    % pr_shape_eq/2: succeed if two obj terms have the same D4-canonical shape.
    pr_shape_eq/2,
    % pr_color_eq/2: succeed if two obj terms have the same color.
    pr_color_eq/2,
    % pr_size_eq/2: succeed if two obj terms have the same number of cells.
    pr_size_eq/2,
    % pr_group_color/2: group a list of obj terms by color as Color-[Obj] pairs.
    pr_group_color/2,
    % pr_group_size/2: group obj terms by cell count as N-[Obj] pairs.
    pr_group_size/2,
    % pr_group_shape/2: group obj terms by D4-canonical shape as Shape-[Obj] pairs.
    pr_group_shape/2,
    % pr_unique_color/2: find the unique obj whose color appears exactly once in the list.
    pr_unique_color/2,
    % pr_unique_size/2: find the unique obj whose size appears exactly once in the list.
    pr_unique_size/2,
    % pr_match_color/3: Color-Obj1-Obj2 triples for same-color pairs across two lists.
    pr_match_color/3,
    % pr_match_size/3: N-Obj1-Obj2 triples for same-size pairs across two lists.
    pr_match_size/3,
    % pr_match_shape/3: Shape-Obj1-Obj2 triples for D4-equivalent shape pairs.
    pr_match_shape/3
]).

% Import list utilities; length/2, sort/2, findall/3 are built-ins.
:- use_module(library(lists), [member/2, min_list/2, max_list/2]).

% pr_norm_(+Cells, -Norm): translate r(R,C) list to origin (min R=0, min C=0), sorted.
% Returns [] for an empty list.
pr_norm_([], []).
pr_norm_(Cells, Norm) :-
% Guard: non-empty list.
    Cells = [_|_],
% Extract all row indices.
    findall(R, member(r(R,_), Cells), Rs),
% Extract all column indices.
    findall(C, member(r(_,C), Cells), Cs),
% Minimum row and column offsets.
    min_list(Rs, MinR),
    min_list(Cs, MinC),
% Translate every cell by the offsets and collect.
    findall(r(R2,C2), (
        member(r(R,C), Cells),
        R2 is R - MinR,
        C2 is C - MinC
    ), Raw),
% Sort to canonical row-major order.
    sort(Raw, Norm).

% pr_cell_d4_(+Op, +R, +C, +H1, +W1, -NR, -NC): one D4 operation on a cell.
% H1 = max row in normalized input, W1 = max col in normalized input.
% identity.
pr_cell_d4_(id,  R, C,  _,  _, R,  C).
% 90 degrees CW: (r,c) -> (c, H1-r).
pr_cell_d4_(r90, R, C, H1,  _, NR, NC) :- NR is C,      NC is H1 - R.
% 180 degrees: (r,c) -> (H1-r, W1-c).
pr_cell_d4_(r180,R, C, H1, W1, NR, NC) :- NR is H1 - R, NC is W1 - C.
% 270 degrees CW: (r,c) -> (W1-c, r).
pr_cell_d4_(r270,R, C,  _, W1, NR, NC) :- NR is W1 - C, NC is R.
% Horizontal flip: (r,c) -> (r, W1-c).
pr_cell_d4_(fh,  R, C,  _, W1, R,  NC) :- NC is W1 - C.
% Vertical flip: (r,c) -> (H1-r, c).
pr_cell_d4_(fv,  R, C, H1,  _, NR, C)  :- NR is H1 - R.
% Main diagonal transpose: (r,c) -> (c, r).
pr_cell_d4_(fd1, R, C,  _,  _, C,  R).
% Anti-diagonal transpose: (r,c) -> (W1-c, H1-r).
pr_cell_d4_(fd2, R, C, H1, W1, NR, NC) :- NR is W1 - C, NC is H1 - R.

% pr_min_term_(+List, -Min): minimum element under standard Prolog term order.
pr_min_term_([X], X) :- !.
pr_min_term_([X|Rest], Min) :-
% Recurse to find the minimum of the rest.
    pr_min_term_(Rest, RestMin),
% Keep the smaller element.
    ( X @< RestMin -> Min = X ; Min = RestMin ).

% pr_canon_(+Cells, -Canon): D4-canonical form of a normalized r(R,C) cell list.
% Returns the lexicographically smallest sorted cell list across all 8 D4 transforms.
pr_canon_([], []).
pr_canon_(Cells, Canon) :-
% Guard: non-empty list.
    Cells = [_|_],
% Normalize to origin first.
    pr_norm_(Cells, Norm),
% Compute max row and col of the normalized shape.
    findall(R, member(r(R,_), Norm), Rs),
    findall(C, member(r(_,C), Norm), Cs),
    max_list(Rs, H1),
    max_list(Cs, W1),
% Generate all 8 D4 transforms, each normalized to origin and sorted.
    findall(T, (
        member(Op, [id, r90, r180, r270, fh, fv, fd1, fd2]),
        findall(r(NR,NC), (
            member(r(R,C), Norm),
            pr_cell_d4_(Op, R, C, H1, W1, NR, NC)
        ), Raw),
        pr_norm_(Raw, T)
    ), Transforms),
% The canonical form is the minimum under standard term order.
    pr_min_term_(Transforms, Canon).

% pr_obj_shape(+Obj, -Shape): D4-canonical shape of an obj(Color, Cells) term.
pr_obj_shape(obj(_, Cells), Shape) :-
% Compute the canonical form of the cell list.
    pr_canon_(Cells, Shape).

% pr_obj_color(+Obj, -Color): extract the color from an obj term.
pr_obj_color(obj(Color, _), Color).

% pr_obj_size(+Obj, -N): number of cells in an obj term.
pr_obj_size(obj(_, Cells), N) :-
% N = length of the cell list.
    length(Cells, N).

% pr_shape_eq(+Obj1, +Obj2): succeed if both obj terms have the same D4-canonical shape.
pr_shape_eq(Obj1, Obj2) :-
% Compute and unify canonical shapes.
    pr_obj_shape(Obj1, Shape),
    pr_obj_shape(Obj2, Shape).

% pr_color_eq(+Obj1, +Obj2): succeed if both obj terms have the same color.
pr_color_eq(obj(Color, _), obj(Color, _)).

% pr_size_eq(+Obj1, +Obj2): succeed if both obj terms have the same number of cells.
pr_size_eq(Obj1, Obj2) :-
% Compute and unify sizes.
    pr_obj_size(Obj1, N),
    pr_obj_size(Obj2, N).

% pr_group_color(+Objs, -Groups): group obj list by color as sorted Color-[Obj] pairs.
pr_group_color(Objs, Groups) :-
% Collect all colors.
    findall(Color, (member(Obj, Objs), pr_obj_color(Obj, Color)), Colors0),
% Get distinct colors in sorted order.
    sort(Colors0, Colors),
% For each color, collect all objs with that color.
    findall(Color-Grp, (
        member(Color, Colors),
        findall(O, (member(O, Objs), pr_obj_color(O, Color)), Grp)
    ), Groups).

% pr_group_size(+Objs, -Groups): group obj list by cell count as sorted N-[Obj] pairs.
pr_group_size(Objs, Groups) :-
% Collect all sizes.
    findall(N, (member(Obj, Objs), pr_obj_size(Obj, N)), Ns0),
% Get distinct sizes in sorted order.
    sort(Ns0, Ns),
% For each size, collect all objs with that size.
    findall(N-Grp, (
        member(N, Ns),
        findall(O, (member(O, Objs), pr_obj_size(O, N)), Grp)
    ), Groups).

% pr_group_shape(+Objs, -Groups): group obj list by D4-canonical shape as Shape-[Obj] pairs.
% Groups are sorted by canonical shape under standard term order.
pr_group_shape(Objs, Groups) :-
% Collect all canonical shapes.
    findall(Shape, (member(Obj, Objs), pr_obj_shape(Obj, Shape)), Shapes0),
% Get distinct shapes in sorted order.
    sort(Shapes0, Shapes),
% For each shape, collect all objs with that canonical shape.
    findall(Shape-Grp, (
        member(Shape, Shapes),
        findall(O, (member(O, Objs), pr_obj_shape(O, Shape)), Grp)
    ), Groups).

% pr_unique_color(+Objs, -Obj): find the unique obj whose color appears exactly once.
% Fails if there is not exactly one such obj.
pr_unique_color(Objs, Obj) :-
% Group by color.
    pr_group_color(Objs, Groups),
% Collect all objs in singleton-color groups.
    findall(O, member(_-[O], Groups), Singletons),
% Succeed only when there is exactly one singleton.
    Singletons = [Obj].

% pr_unique_size(+Objs, -Obj): find the unique obj whose size appears exactly once.
% Fails if there is not exactly one such obj.
pr_unique_size(Objs, Obj) :-
% Group by size.
    pr_group_size(Objs, Groups),
% Collect all objs in singleton-size groups.
    findall(O, member(_-[O], Groups), Singletons),
% Succeed only when there is exactly one singleton.
    Singletons = [Obj].

% pr_match_color(+Objs1, +Objs2, -Pairs): Color-Obj1-Obj2 triples where both objects
% have the same color. One triple per matching pair.
pr_match_color(Objs1, Objs2, Pairs) :-
% Collect all same-color pairs.
    findall(Color-O1-O2, (
        member(O1, Objs1), pr_obj_color(O1, Color),
        member(O2, Objs2), pr_obj_color(O2, Color)
    ), Pairs).

% pr_match_size(+Objs1, +Objs2, -Pairs): N-Obj1-Obj2 triples where both objects
% have the same cell count. One triple per matching pair.
pr_match_size(Objs1, Objs2, Pairs) :-
% Collect all same-size pairs.
    findall(N-O1-O2, (
        member(O1, Objs1), pr_obj_size(O1, N),
        member(O2, Objs2), pr_obj_size(O2, N)
    ), Pairs).

% pr_match_shape(+Objs1, +Objs2, -Pairs): Shape-Obj1-Obj2 triples where both objects
% have the same D4-canonical shape. One triple per matching pair.
pr_match_shape(Objs1, Objs2, Pairs) :-
% Collect all same-shape pairs.
    findall(Shape-O1-O2, (
        member(O1, Objs1), pr_obj_shape(O1, Shape),
        member(O2, Objs2), pr_obj_shape(O2, Shape)
    ), Pairs).
