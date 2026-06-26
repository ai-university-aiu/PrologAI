% objmerge.pl - Layer 179: Object Merging, Set Operations, and Component Splitting (mg_* prefix).
% Provides cell-set operations (union, intersection, difference, symmetric difference)
% on obj(Color, Cells) terms; horizontal and vertical concatenation; list-level union
% and subtraction; bounding-box fill and hollow-frame generation; cell padding;
% and splitting of objects into 4-connected and 8-connected components.
% No cross-pack dependencies.
:- module(objmerge, [
    % mg_union_cells/4: cell union of two objs with a new color.
    mg_union_cells/4,
    % mg_intersect_cells/4: cell intersection of two objs with a new color.
    mg_intersect_cells/4,
    % mg_diff_cells/4: cells in O1 but not O2, with a new color.
    mg_diff_cells/4,
    % mg_sym_diff_cells/4: symmetric difference of cells, with a new color.
    mg_sym_diff_cells/4,
    % mg_concat_h/4: O1 cells and O2 cells combined; O2 placed immediately right of O1 bbox.
    mg_concat_h/4,
    % mg_concat_v/4: O1 cells and O2 cells combined; O2 placed immediately below O1 bbox.
    mg_concat_v/4,
    % mg_merge_list/3: union of all cells in a list of objs, single new color.
    mg_merge_list/3,
    % mg_subtract_list/4: remove all cells of any obj in RemoveList from Base.
    mg_subtract_list/4,
    % mg_expand_bbox/2: fill the bounding box of Obj with Obj's color.
    mg_expand_bbox/2,
    % mg_hollow_bbox/2: replace Obj with only the 1-cell-wide outer frame of its bbox.
    mg_hollow_bbox/2,
    % mg_pad/4: add P rows/cols of Color cells around the bounding box of Obj.
    mg_pad/4,
    % mg_split_cc4/2: split Obj into a list of 4-connected component objs.
    mg_split_cc4/2,
    % mg_split_cc8/2: split Obj into a list of 8-connected component objs.
    mg_split_cc8/2,
    % mg_n_components4/2: count the number of 4-connected components.
    mg_n_components4/2
]).

% Load list utilities.
:- use_module(library(lists), [member/2, subtract/3, intersection/3, union/3, append/3]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% mg_cells_(+Obj, -Cells): extract cell list from an obj term.
mg_cells_(obj(_, Cells), Cells).

% mg_color_(+Obj, -Color): extract color from an obj term.
mg_color_(obj(Color, _), Color).

% mg_maxrow_(+Obj, -R): maximum row in Obj.
mg_maxrow_(obj(_, Cells), R) :-
    findall(Row, member(r(Row,_), Cells), Rs),
    max_list(Rs, R).

% mg_maxcol_(+Obj, -C): maximum col in Obj.
mg_maxcol_(obj(_, Cells), C) :-
    findall(Col, member(r(_,Col), Cells), Cs),
    max_list(Cs, C).

% mg_minrow_(+Obj, -R): minimum row in Obj.
mg_minrow_(obj(_, Cells), R) :-
    findall(Row, member(r(Row,_), Cells), Rs),
    min_list(Rs, R).

% mg_mincol_(+Obj, -C): minimum col in Obj.
mg_mincol_(obj(_, Cells), C) :-
    findall(Col, member(r(_,Col), Cells), Cs),
    min_list(Cs, C).

% mg_translate_(+Cells, +DR, +DC, -Cells2): translate all cells by (DR, DC).
mg_translate_(Cells, DR, DC, Cells2) :-
    findall(r(R2,C2),
        (member(r(R,C), Cells),
         R2 is R + DR,
         C2 is C + DC),
        Cells2).

% mg_neighbors4_(+r(R,C), -Neighbors): 4-connected neighbor positions.
mg_neighbors4_(r(R,C), [r(R1,C), r(R2,C), r(R,C1), r(R,C2)]) :-
    R1 is R - 1, R2 is R + 1,
    C1 is C - 1, C2 is C + 1.

% mg_neighbors8_(+r(R,C), -Neighbors): 8-connected neighbor positions.
mg_neighbors8_(r(R,C), Neighbors) :-
    R1 is R-1, R2 is R+1,
    C1 is C-1, C2 is C+1,
    Neighbors = [r(R1,C1),r(R1,C),r(R1,C2),
                 r(R,C1),          r(R,C2),
                 r(R2,C1),r(R2,C),r(R2,C2)].

% mg_bfs_(+Queue, +CellSet, +Visited, -Component, -Remaining):
% BFS flood-fill using NeighborPred. CellSet is sorted.
mg_bfs_([], _, Visited, Visited, _).
mg_bfs_([Cell|Queue], CellSet, Visited, Component, NeighborPred) :-
    call(NeighborPred, Cell, Nbrs),
% Find unvisited neighbors in the cell set.
    findall(N,
        (member(N, Nbrs),
         memberchk(N, CellSet),
         \+ memberchk(N, Visited)),
        NewCells),
    append(Queue, NewCells, Queue2),
    append(Visited, NewCells, Visited2),
    mg_bfs_(Queue2, CellSet, Visited2, Component, NeighborPred).

% mg_components_(+Remaining, +Color, +NeighborPred, -Parts):
% Extract all connected components by iterating BFS until no cells remain.
mg_components_([], _, _, []).
mg_components_([First|Rest], Color, NeighborPred, [obj(Color,Comp)|Parts]) :-
% Seed the BFS from First.
    mg_bfs_([First], [First|Rest], [First], Comp, NeighborPred),
% Cells not in this component remain.
    subtract([First|Rest], Comp, Remaining),
    mg_components_(Remaining, Color, NeighborPred, Parts).

% --- Exported predicates -----------------------------------------------------

% mg_union_cells(+O1, +O2, +Color, -Merged): cell union with Color.
mg_union_cells(O1, O2, Color, obj(Color, Union)) :-
    mg_cells_(O1, C1),
    mg_cells_(O2, C2),
% Sort both lists and take union (eliminates duplicates).
    sort(C1, SC1),
    sort(C2, SC2),
    union(SC1, SC2, Union).

% mg_intersect_cells(+O1, +O2, +Color, -Result): cell intersection with Color.
mg_intersect_cells(O1, O2, Color, obj(Color, Isect)) :-
    mg_cells_(O1, C1),
    mg_cells_(O2, C2),
    sort(C1, SC1),
    sort(C2, SC2),
    intersection(SC1, SC2, Isect).

% mg_diff_cells(+O1, +O2, +Color, -Result): cells in O1 but not O2.
mg_diff_cells(O1, O2, Color, obj(Color, Diff)) :-
    mg_cells_(O1, C1),
    mg_cells_(O2, C2),
    sort(C1, SC1),
    sort(C2, SC2),
    subtract(SC1, SC2, Diff).

% mg_sym_diff_cells(+O1, +O2, +Color, -Result): symmetric difference of cells.
mg_sym_diff_cells(O1, O2, Color, obj(Color, SymDiff)) :-
    mg_cells_(O1, C1),
    mg_cells_(O2, C2),
    sort(C1, SC1),
    sort(C2, SC2),
% SymDiff = (SC1 \ SC2) ++ (SC2 \ SC1).
    subtract(SC1, SC2, OnlyIn1),
    subtract(SC2, SC1, OnlyIn2),
    append(OnlyIn1, OnlyIn2, SymDiff).

% mg_concat_h(+O1, +O2, +Gap, -Merged): O2 placed right of O1 bbox, cells combined.
% O2's left edge is placed at O1's right edge + 1 + Gap.
% The merged obj uses O1's color.
mg_concat_h(O1, O2, Gap, obj(Color, MergedCells)) :-
    mg_color_(O1, Color),
    mg_cells_(O1, C1),
    mg_maxcol_(O1, MaxC1),
    mg_mincol_(O2, MinC2),
% Shift O2 so its left edge is at MaxC1 + 1 + Gap.
    DC is MaxC1 + 1 + Gap - MinC2,
    mg_cells_(O2, C2),
    mg_translate_(C2, 0, DC, C2Shifted),
    append(C1, C2Shifted, MergedCells).

% mg_concat_v(+O1, +O2, +Gap, -Merged): O2 placed below O1 bbox, cells combined.
% O2's top edge is placed at O1's bottom edge + 1 + Gap.
% The merged obj uses O1's color.
mg_concat_v(O1, O2, Gap, obj(Color, MergedCells)) :-
    mg_color_(O1, Color),
    mg_cells_(O1, C1),
    mg_maxrow_(O1, MaxR1),
    mg_minrow_(O2, MinR2),
% Shift O2 so its top edge is at MaxR1 + 1 + Gap.
    DR is MaxR1 + 1 + Gap - MinR2,
    mg_cells_(O2, C2),
    mg_translate_(C2, DR, 0, C2Shifted),
    append(C1, C2Shifted, MergedCells).

% mg_merge_list(+Objs, +Color, -Merged): union of all cells in Objs, colored Color.
mg_merge_list(Objs, Color, obj(Color, Union)) :-
% Collect all cells from all objects.
    findall(Cell,
        (member(Obj, Objs),
         mg_cells_(Obj, Cells),
         member(Cell, Cells)),
        AllCells),
% Remove duplicates via sort.
    sort(AllCells, Union).

% mg_subtract_list(+Base, +RemoveList, +Color, -Result):
% Remove all cells of any obj in RemoveList from Base's cell set.
mg_subtract_list(Base, RemoveList, Color, obj(Color, Result)) :-
    mg_cells_(Base, BaseCells),
% Collect all cells to remove.
    findall(Cell,
        (member(Obj, RemoveList),
         mg_cells_(Obj, Cells),
         member(Cell, Cells)),
        ToRemove),
    sort(BaseCells, SBase),
    sort(ToRemove, SRemove),
    subtract(SBase, SRemove, Result).

% mg_expand_bbox(+Obj, -Expanded): fill the bounding box with Obj's color.
mg_expand_bbox(Obj, obj(Color, FilledCells)) :-
    mg_color_(Obj, Color),
    mg_minrow_(Obj, MinR), mg_maxrow_(Obj, MaxR),
    mg_mincol_(Obj, MinC), mg_maxcol_(Obj, MaxC),
% Generate all cells within the bounding box.
    findall(r(R,C),
        (between(MinR, MaxR, R),
         between(MinC, MaxC, C)),
        FilledCells).

% mg_hollow_bbox(+Obj, -Hollow): replace Obj with the 1-cell-wide frame of its bbox.
mg_hollow_bbox(Obj, obj(Color, Frame)) :-
    mg_color_(Obj, Color),
    mg_minrow_(Obj, MinR), mg_maxrow_(Obj, MaxR),
    mg_mincol_(Obj, MinC), mg_maxcol_(Obj, MaxC),
% Frame = all cells on the border of the bounding box.
% Sort to remove duplicates produced when corner cells match multiple conditions.
    findall(r(R,C),
        (between(MinR, MaxR, R),
         between(MinC, MaxC, C),
         (R =:= MinR ; R =:= MaxR ; C =:= MinC ; C =:= MaxC)),
        Raw),
    sort(Raw, Frame).

% mg_pad(+Obj, +P, +Color, -Padded): add P rows/cols of Color cells around bbox of Obj.
% The padded cells fill the border ring from (MinR-P,MinC-P) to (MaxR+P,MaxC+P),
% and the original cells are included, all recolored to Color.
mg_pad(Obj, P, Color, obj(Color, PaddedCells)) :-
    mg_minrow_(Obj, MinR), mg_maxrow_(Obj, MaxR),
    mg_mincol_(Obj, MinC), mg_maxcol_(Obj, MaxC),
    PR is MinR - P, QR is MaxR + P,
    PC is MinC - P, QC is MaxC + P,
    findall(r(R,C),
        (between(PR, QR, R),
         between(PC, QC, C)),
        PaddedCells).

% mg_split_cc4(+Obj, -Parts): split Obj into 4-connected component objs.
mg_split_cc4(Obj, Parts) :-
    mg_color_(Obj, Color),
    mg_cells_(Obj, Cells),
    sort(Cells, SortedCells),
    mg_components_(SortedCells, Color, mg_neighbors4_, Parts).

% mg_split_cc8(+Obj, -Parts): split Obj into 8-connected component objs.
mg_split_cc8(Obj, Parts) :-
    mg_color_(Obj, Color),
    mg_cells_(Obj, Cells),
    sort(Cells, SortedCells),
    mg_components_(SortedCells, Color, mg_neighbors8_, Parts).

% mg_n_components4(+Obj, -N): count the number of 4-connected components.
mg_n_components4(Obj, N) :-
    mg_split_cc4(Obj, Parts),
    length(Parts, N).
