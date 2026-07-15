% Cell set: sparse set operations on R-C cell positions.
% Work Package 138, Layer 117.
:- module(cellset, [
    cellset_from_grid/3, cellset_to_grid/6, cellset_union/3, cellset_intersect/3,
    cellset_subtract/3, cellset_translate/4, cellset_bbox/5, cellset_normalize/4,
    cellset_size/2, cellset_contains/3, cellset_adjacent_bg/2, cellset_same_shape/2,
    cellset_rotate_90/3, cellset_mirror_h/3
]).
% Import list predicates from library(lists)
:- use_module(library(lists), [member/2, memberchk/2, nth0/3,
                                append/2, subtract/3,
                                min_list/2, max_list/2]).
% Import maplist/3 from library(apply)
:- use_module(library(apply), [maplist/3]).

% cellset_from_grid(+Grid, +Color, -Cells): sorted list of R-C positions where Grid cell equals Color.
cellset_from_grid(Grid, Color, Cells) :-
    % compute last row index
    length(Grid, H), H1 is H - 1,
    % compute last column index from first row; default 0 for empty
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    % collect all R-C positions matching Color
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, Color)
    ), Unsorted),
    % sort removes duplicates and gives canonical order
    sort(Unsorted, Cells).

% cellset_to_grid(+Cells, +H, +W, +Color, +Bg, -Grid): paint a sorted cell set onto an HxW grid.
cellset_to_grid(Cells, H, W, Color, Bg, Grid) :-
    % compute last row and column indices
    H1 is H - 1, W1 is W - 1,
    % build each row by testing membership for each column position
    findall(Row, (
        between(0, H1, R),
        findall(V, (
            between(0, W1, C),
            % use Color if cell is in set, else use Bg
            (memberchk(R-C, Cells) -> V = Color ; V = Bg)
        ), Row)
    ), Grid).

% cellset_union(+A, +B, -Union): sorted set union of two cell sets.
cellset_union(A, B, Union) :-
    % concatenate both lists
    append(A, B, Combined),
    % sort removes duplicates and produces canonical order
    sort(Combined, Union).

% cellset_intersect(+A, +B, -Inter): sorted set intersection of two cell sets.
cellset_intersect(A, B, Inter) :-
    % keep only members of A that also appear in B
    findall(RC, (member(RC, A), memberchk(RC, B)), Unsorted),
    % sort removes any duplicates
    sort(Unsorted, Inter).

% cellset_subtract(+A, +B, -Diff): members of A not in B, preserving sorted order.
cellset_subtract(A, B, Diff) :-
    % subtract/3 from library(lists) computes set difference
    subtract(A, B, Diff).

% cellset_translate(+Cells, +DR, +DC, -Shifted): shift every R-C in Cells by (DR, DC).
cellset_translate(Cells, DR, DC, Shifted) :-
    % apply arithmetic offset to each cell position
    maplist(cellset_add_(DR, DC), Cells, Shifted).

% Private helper: add offsets to one R-C pair.
cellset_add_(DR, DC, R-C, NR-NC) :-
    % compute new row
    NR is R + DR,
    % compute new column
    NC is C + DC.

% cellset_bbox(+Cells, -R0, -C0, -R1, -C1): bounding box of a non-empty cell set.
% Fails if Cells is empty.
cellset_bbox(Cells, R0, C0, R1, C1) :-
    % require at least one cell
    Cells = [_|_],
    % extract all row indices
    findall(R, member(R-_, Cells), Rs),
    % extract all column indices
    findall(C, member(_-C, Cells), Cs),
    % find extremes
    min_list(Rs, R0), max_list(Rs, R1),
    min_list(Cs, C0), max_list(Cs, C1).

% cellset_normalize(+Cells, -Norm, -DR, -DC): translate Cells so min row=0, min col=0.
% Returns the translation offsets DR and DC (both non-positive).
% Empty list passes through with zero offsets.
cellset_normalize([], [], 0, 0) :- !.
cellset_normalize(Cells, Norm, DR, DC) :-
    % find the top-left corner of the bounding box
    cellset_bbox(Cells, R0, C0, _, _),
    % offsets are negatives of the minimum coordinates
    DR is -R0, DC is -C0,
    % shift the cell set to the origin
    cellset_translate(Cells, DR, DC, Norm).

% cellset_size(+Cells, -N): number of cells in the set.
cellset_size(Cells, N) :-
    % length/2 counts list elements; Cells is already duplicate-free
    length(Cells, N).

% cellset_contains(+Cells, +R, +C): succeed if (R,C) is a member of the cell set.
cellset_contains(Cells, R, C) :-
    % memberchk/2 is deterministic membership test
    memberchk(R-C, Cells).

% cellset_adjacent_bg(+Cells, -Adjacent): sorted list of 4-connected background neighbors.
% A neighbor is background if it is not in Cells.
cellset_adjacent_bg(Cells, Adjacent) :-
    % enumerate all 4-connected offsets (DR, DC)
    findall(NR-NC, (
        member(R-C, Cells),
        member(DR-DC, [(-1)-0, 1-0, 0-(-1), 0-1]),
        NR is R + DR, NC is C + DC,
        % keep only cells not already in the set
        \+ memberchk(NR-NC, Cells)
    ), Unsorted),
    % sort removes duplicates from shared neighbors
    sort(Unsorted, Adjacent).

% cellset_same_shape(+A, +B): succeed if A and B have the same shape after normalization.
% Two empty sets have the same (trivial) shape.
cellset_same_shape(A, B) :-
    (   A = [], B = []
    ->  true
    ;   % normalize both sets to origin
        cellset_normalize(A, NA, _, _),
        cellset_normalize(B, NB, _, _),
        % compare structurally; both are sorted so == gives shape equality
        NA == NB
    ).

% cellset_rotate_90(+Cells, +H, -Rotated): 90-degree clockwise rotation within a grid of H rows.
% Formula: new_R = old_C, new_C = H-1-old_R.
cellset_rotate_90(Cells, H, Rotated) :-
    % compute max row index for rotation formula
    H1 is H - 1,
    % apply rotation formula to every cell
    maplist(cellset_rot90_(H1), Cells, Rotated0),
    % sort to restore canonical order after permutation
    sort(Rotated0, Rotated).

% Private helper: rotate one R-C pair 90 degrees clockwise.
cellset_rot90_(H1, R-C, NewR-NewC) :-
    % new row = old column
    NewR = C,
    % new column = max_row - old_row
    NewC is H1 - R.

% cellset_mirror_h(+Cells, +W, -Mirrored): horizontal (left-right) mirror within a grid of W columns.
% Formula: new_R = old_R, new_C = W-1-old_C.
cellset_mirror_h(Cells, W, Mirrored) :-
    % compute max column index for mirror formula
    W1 is W - 1,
    % apply mirror formula to every cell
    maplist(cellset_mirh_(W1), Cells, Mirrored0),
    % sort to restore canonical order after permutation
    sort(Mirrored0, Mirrored).

% Private helper: mirror one R-C pair horizontally.
cellset_mirh_(W1, R-C, R-NewC) :-
    % new column = max_col - old_col
    NewC is W1 - C.
