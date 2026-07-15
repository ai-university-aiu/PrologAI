% shrink.pl - Layer 164: Grid Downscaling and Block Decomposition (dn_* prefix).
% Provides predicates for partitioning a 2D grid into equal-sized NxN blocks,
% testing and exploiting blocky structure (every block is a uniform color),
% shrinking a blocky grid by factor N (the inverse of ox_scale_up in objxf),
% finding the scale factor of a scaled-up grid, and downscaling obj(Color, Cells)
% terms. All predicates use 0-indexed row-column coordinates.
:- module(shrink, [
    shrink_block_dims/4,
    shrink_block_cells/4,
    shrink_block_color/5,
    shrink_block_majority/5,
    shrink_is_blocky/2,
    shrink_shrink/3,
    shrink_shrink_strict/3,
    shrink_find_scale/2,
    shrink_obj_shrink/3,
    shrink_scale_factor/3,
    shrink_uniform_blocks/3,
    shrink_mixed_blocks/3,
    shrink_block_grid/5,
    shrink_block_val/5
]).
% member/2 for cell-list iteration; nth0/3 for grid row and value access.
:- use_module(library(lists), [member/2, nth0/3, min_list/2, last/2]).

% shrink_count_: count how many times V appears in List.
shrink_count_([], _, 0).
% Matching head: add one to the count of the tail.
shrink_count_([V|T], V, N) :- !, shrink_count_(T, V, N1), N is N1 + 1.
% Non-matching head: skip it.
shrink_count_([_|T], V, N) :- shrink_count_(T, V, N).

% shrink_norm_cells_: normalize obj cells to origin (min row = 0, min col = 0).
shrink_norm_cells_(obj(_, Cells), Norm) :-
% Sort cells to get a canonical order and deduplicate.
    sort(Cells, S),
% Collect all row indices to find the minimum.
    findall(R, member(r(R,_), S), Rs), min_list(Rs, R0),
% Collect all column indices to find the minimum.
    findall(C, member(r(_,C), S), Cs), min_list(Cs, C0),
% Shift every cell so that the top-left corner is at r(0,0).
    findall(r(NR,NC), (member(r(R,C), S), NR is R - R0, NC is C - C0), Raw),
% Sort the shifted cells for canonical comparison.
    sort(Raw, Norm).

% shrink_block_dims(+Grid, +N, -BI, -BJ): count complete NxN blocks in Grid.
% BI = H // N (rows of blocks); BJ = W // N (cols of blocks). Uses integer division.
shrink_block_dims(Grid, N, BI, BJ) :-
% Grid height = number of rows.
    length(Grid, H),
% Grid width = number of columns in the first row.
    nth0(0, Grid, Row0), length(Row0, W),
% Integer division gives the count of complete blocks per axis.
    BI is H // N, BJ is W // N.

% shrink_block_cells(+N, +I, +J, -Cells): r(R,C) pairs covering block (I,J) in NxN partition.
% Block (I,J) spans rows [I*N .. I*N+N-1] and cols [J*N .. J*N+N-1].
shrink_block_cells(N, I, J, Cells) :-
% Compute first and last row of this block.
    R0 is I * N, R1 is R0 + N - 1,
% Compute first and last column of this block.
    C0 is J * N, C1 is C0 + N - 1,
% Generate every r(R,C) in the row-col range via between/3.
    findall(r(R, C), (between(R0, R1, R), between(C0, C1, C)), Cells).

% shrink_block_color(+Grid, +N, +I, +J, -Color): unique color of block (I,J).
% Fails when the block contains two or more distinct values.
shrink_block_color(Grid, N, I, J, Color) :-
% Get the cell coordinates for block (I,J).
    shrink_block_cells(N, I, J, Cells),
% Read the grid value at each cell position.
    findall(V, (member(r(R,C), Cells), nth0(R, Grid, Row), nth0(C, Row, V)), Vals),
% sort/2 deduplicates; pattern [Color] succeeds only when there is exactly one distinct value.
    sort(Vals, [Color]).

% shrink_block_majority(+Grid, +N, +I, +J, -Color): most frequent value in block (I,J).
% When two values tie for the highest count, the one with larger standard order wins.
shrink_block_majority(Grid, N, I, J, Color) :-
% Get the cell coordinates for block (I,J).
    shrink_block_cells(N, I, J, Cells),
% Collect every grid value within the block.
    findall(V, (member(r(R,C), Cells), nth0(R, Grid, Row), nth0(C, Row, V)), Vals),
% Deduplicate to obtain the set of distinct values present.
    sort(Vals, Unique),
% Count occurrences of each distinct value.
    findall(Count-V, (member(V, Unique), shrink_count_(Vals, V, Count)), Pairs),
% msort keeps duplicates; ascending order puts highest count last.
    msort(Pairs, Sorted),
% last/2 retrieves the highest-count (or tie-breaking) value.
    last(Sorted, _-Color).

% shrink_is_blocky(+Grid, +N): succeed if every complete NxN block in Grid is uniform.
% A grid is N-blocky when each NxN tile contains exactly one distinct color.
shrink_is_blocky(Grid, N) :-
% Determine the block grid dimensions.
    shrink_block_dims(Grid, N, BI, BJ),
% Require at least one complete block to exist.
    BI > 0, BJ > 0,
    Bi1 is BI - 1, Bj1 is BJ - 1,
% shrink_block_color must succeed for every (I,J) pair.
    forall((between(0, Bi1, I), between(0, Bj1, J)),
           shrink_block_color(Grid, N, I, J, _)).

% shrink_shrink(+Grid, +N, -Small): downscale Grid by N using majority vote per block.
% Small[I][J] = most frequent color in block (I,J). Never fails for valid N.
shrink_shrink(Grid, N, Small) :-
% Compute block grid dimensions.
    shrink_block_dims(Grid, N, BI, BJ),
% Require at least one block.
    BI > 0, BJ > 0,
    Bi1 is BI - 1, Bj1 is BJ - 1,
% Outer findall produces one row per block row; inner findall collects one color per block col.
    findall(Row,
            (between(0, Bi1, I),
             findall(Color, (between(0, Bj1, J), shrink_block_majority(Grid, N, I, J, Color)), Row)),
            Small).

% shrink_shrink_strict(+Grid, +N, -Small): downscale Grid by N; fail if any block is mixed.
% Identical to shrink_shrink but each block must be uniform (shrink_block_color, not majority).
shrink_shrink_strict(Grid, N, Small) :-
% Fail immediately if any block has more than one color.
    shrink_is_blocky(Grid, N),
% Compute block grid dimensions (reuse after the blocky check).
    shrink_block_dims(Grid, N, BI, BJ),
    Bi1 is BI - 1, Bj1 is BJ - 1,
% Build Small using unique-color blocks; no ambiguity since all blocks are uniform.
    findall(Row,
            (between(0, Bi1, I),
             findall(Color, (between(0, Bj1, J), shrink_block_color(Grid, N, I, J, Color)), Row)),
            Small).

% shrink_find_scale(+Grid, -N): find the smallest N >= 2 such that Grid is N-blocky.
% Tries divisors of H and W in ascending order; cuts at the first match.
shrink_find_scale(Grid, N) :-
% Get grid dimensions.
    length(Grid, H), nth0(0, Grid, Row0), length(Row0, W),
% Grid must have more than one row and one column for any scale to make sense.
    H > 1, W > 1,
% Search N from 2 upward; N must divide both H and W exactly.
    between(2, H, N),
    H mod N =:= 0, W mod N =:= 0,
% Check every block is uniform; cut prevents backtracking to larger N.
    shrink_is_blocky(Grid, N), !.

% shrink_obj_shrink(+Obj, +N, -Small): downscale an obj term by dividing all coords by N.
% Each cell r(R,C) maps to r(R//N, C//N); sort/2 deduplicates overlapping results.
shrink_obj_shrink(obj(Color, Cells), N, obj(Color, Small)) :-
% Factor must be a positive integer.
    N > 0,
% Apply integer division to every row and column coordinate.
    findall(r(NR, NC), (member(r(R,C), Cells), NR is R // N, NC is C // N), Raw),
% sort/2 removes duplicates that arise when multiple cells map to the same block.
    sort(Raw, Small).

% shrink_scale_factor(+Obj1, +Obj2, -N): smallest N >= 2 where shrinking Obj2 by N yields Obj1.
% Both objects are normalized to origin before comparison. Tries N from 2 to 30.
shrink_scale_factor(Obj1, Obj2, N) :-
% Normalize Obj1 cells to origin for canonical comparison.
    shrink_norm_cells_(Obj1, Norm1),
% Try each candidate N.
    between(2, 30, N),
% Shrink Obj2 by N.
    shrink_obj_shrink(Obj2, N, Shrunken),
% Normalize the shrunken result to origin.
    shrink_norm_cells_(Shrunken, Norm2),
% Succeed when both normalized cell sets are identical; cut for determinism.
    Norm1 == Norm2, !.

% shrink_uniform_blocks(+Grid, +N, -Pairs): I-J pairs for all uniform NxN blocks.
% A uniform block has exactly one distinct color.
shrink_uniform_blocks(Grid, N, Pairs) :-
% Determine block grid dimensions.
    shrink_block_dims(Grid, N, BI, BJ),
    Bi1 is BI - 1, Bj1 is BJ - 1,
% Collect (I,J) pairs where shrink_block_color succeeds (uniform).
    findall(I-J, (between(0, Bi1, I), between(0, Bj1, J), shrink_block_color(Grid, N, I, J, _)), Pairs).

% shrink_mixed_blocks(+Grid, +N, -Pairs): I-J pairs for all non-uniform NxN blocks.
% A mixed block contains two or more distinct colors.
shrink_mixed_blocks(Grid, N, Pairs) :-
% Determine block grid dimensions.
    shrink_block_dims(Grid, N, BI, BJ),
    Bi1 is BI - 1, Bj1 is BJ - 1,
% Collect (I,J) pairs where shrink_block_color fails (more than one color).
    findall(I-J, (between(0, Bi1, I), between(0, Bj1, J), \+ shrink_block_color(Grid, N, I, J, _)), Pairs).

% shrink_block_grid(+Grid, +N, +I, +J, -Patch): extract block (I,J) as an NxN sub-grid.
% Patch is a list of N rows, each a list of N values, in row-major order.
shrink_block_grid(Grid, N, I, J, Patch) :-
% First and last row of the block.
    R0 is I * N, R1 is R0 + N - 1,
% First and last column of the block.
    C0 is J * N, C1 is C0 + N - 1,
% For each block row, extract the relevant column slice from the grid row.
    findall(Row,
            (between(R0, R1, R), nth0(R, Grid, GRow),
             findall(V, (between(C0, C1, C), nth0(C, GRow, V)), Row)),
            Patch).

% shrink_block_val(+Grid, +N, +I, +J, -Vals): flat list of all values in block (I,J).
% Values appear in row-major order: row I*N first, then row I*N+1, and so on.
shrink_block_val(Grid, N, I, J, Vals) :-
% First and last row of the block.
    R0 is I * N, R1 is R0 + N - 1,
% First and last column of the block.
    C0 is J * N, C1 is C0 + N - 1,
% Collect values row by row, column by column within each row.
    findall(V,
            (between(R0, R1, R), nth0(R, Grid, GRow),
             between(C0, C1, C), nth0(C, GRow, V)),
            Vals).
