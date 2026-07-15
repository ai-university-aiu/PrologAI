:- use_module('../prolog/shrink').
:- begin_tests(shrink).

% Grid helpers used across tests.
% g2x2: 2x2 uniform grid (all 1s).
g2x2([[1,1],[1,1]]).
% g4x4b2: 4x4 grid where each 2x2 block is uniform.
g4x4b2([[1,1,2,2],[1,1,2,2],[3,3,4,4],[3,3,4,4]]).
% g6x6b2: 6x6 grid where each 2x2 block is uniform.
g6x6b2([[a,a,b,b,c,c],[a,a,b,b,c,c],[d,d,e,e,f,f],[d,d,e,e,f,f],[g,g,h,h,i,i],[g,g,h,h,i,i]]).
% g4x4b2m: 4x4 grid with block (0,0) mixed (contains both 1 and 2).
g4x4b2m([[1,2,3,3],[2,1,3,3],[5,5,6,6],[5,5,6,6]]).
% g2x2mix: 2x2 grid with two colors (not blocky for N=2).
g2x2mix([[1,2],[1,1]]).
% g6x6b3: 6x6 grid where each 3x3 block is uniform (2 rows x 2 cols of blocks).
g6x6b3([[p,p,p,q,q,q],[p,p,p,q,q,q],[p,p,p,q,q,q],[r,r,r,s,s,s],[r,r,r,s,s,s],[r,r,r,s,s,s]]).

% shrink_block_dims tests.

test(block_dims_4x4_n2) :-
    g4x4b2(G), shrink_block_dims(G, 2, BI, BJ), BI =:= 2, BJ =:= 2.

test(block_dims_6x6_n2) :-
    g6x6b2(G), shrink_block_dims(G, 2, BI, BJ), BI =:= 3, BJ =:= 3.

test(block_dims_6x6_n3) :-
    g6x6b2(G), shrink_block_dims(G, 3, BI, BJ), BI =:= 2, BJ =:= 2.

test(block_dims_4x4_n4) :-
    g4x4b2(G), shrink_block_dims(G, 4, BI, BJ), BI =:= 1, BJ =:= 1.

% shrink_block_cells tests.

test(block_cells_n2_00) :-
    shrink_block_cells(2, 0, 0, Cells),
    sort(Cells, S),
    S == [r(0,0),r(0,1),r(1,0),r(1,1)].

test(block_cells_n2_01) :-
    shrink_block_cells(2, 0, 1, Cells),
    sort(Cells, S),
    S == [r(0,2),r(0,3),r(1,2),r(1,3)].

test(block_cells_n2_11) :-
    shrink_block_cells(2, 1, 1, Cells),
    sort(Cells, S),
    S == [r(2,2),r(2,3),r(3,2),r(3,3)].

test(block_cells_n3_00) :-
    shrink_block_cells(3, 0, 0, Cells), length(Cells, 9).

% shrink_block_color tests.

test(block_color_4x4_00) :-
    g4x4b2(G), shrink_block_color(G, 2, 0, 0, C), C == 1.

test(block_color_4x4_01) :-
    g4x4b2(G), shrink_block_color(G, 2, 0, 1, C), C == 2.

test(block_color_4x4_10) :-
    g4x4b2(G), shrink_block_color(G, 2, 1, 0, C), C == 3.

test(block_color_4x4_11) :-
    g4x4b2(G), shrink_block_color(G, 2, 1, 1, C), C == 4.

test(block_color_mixed_fails, [fail]) :-
    g4x4b2m(G), shrink_block_color(G, 2, 0, 0, _).

test(block_color_6x6_12) :-
    g6x6b2(G), shrink_block_color(G, 2, 1, 2, C), C == f.

% shrink_block_majority tests.

test(block_majority_uniform) :-
    g4x4b2(G), shrink_block_majority(G, 2, 0, 0, C), C == 1.

test(block_majority_mixed) :-
    % block (0,0) of g2x2mix has [1,2,1,1] = 1 appears 3 times.
    g2x2mix(G), shrink_block_majority(G, 2, 0, 0, C), C == 1.

test(block_majority_tie) :-
    % Grid where block (0,0) has 2 ones and 2 twos: tie goes to 2 (larger in standard order).
    shrink_block_majority([[1,2],[2,1]], 2, 0, 0, C), C == 2.

test(block_majority_6x6) :-
    g6x6b2(G), shrink_block_majority(G, 2, 2, 2, C), C == i.

% shrink_is_blocky tests.

test(is_blocky_4x4_n2) :-
    g4x4b2(G), shrink_is_blocky(G, 2).

test(is_blocky_6x6_n2) :-
    g6x6b2(G), shrink_is_blocky(G, 2).

test(is_blocky_fails_mixed, [fail]) :-
    g4x4b2m(G), shrink_is_blocky(G, 2).

test(is_blocky_fails_2x2mix, [fail]) :-
    g2x2mix(G), shrink_is_blocky(G, 2).

% shrink_shrink tests.

test(shrink_4x4_n2) :-
    g4x4b2(G), shrink_shrink(G, 2, S), S == [[1,2],[3,4]].

test(shrink_6x6_n2) :-
    g6x6b2(G), shrink_shrink(G, 2, S), S == [[a,b,c],[d,e,f],[g,h,i]].

test(shrink_majority_vote) :-
    % Grid with one mixed block: majority vote used for block (0,0).
    shrink_shrink([[1,2,3,3],[2,1,3,3],[5,5,6,6],[5,5,6,6]], 2, S),
    % Block (0,0) has [1,2,2,1] -> tie -> larger wins; blocks (0,1),(1,0),(1,1) are uniform.
    S = [[_,3],[5,6]].

test(shrink_6x6_n3) :-
    g6x6b3(G), shrink_shrink(G, 3, S), S == [[p,q],[r,s]].

% shrink_shrink_strict tests.

test(shrink_strict_4x4) :-
    g4x4b2(G), shrink_shrink_strict(G, 2, S), S == [[1,2],[3,4]].

test(shrink_strict_6x6) :-
    g6x6b2(G), shrink_shrink_strict(G, 2, S), S == [[a,b,c],[d,e,f],[g,h,i]].

test(shrink_strict_fails_mixed, [fail]) :-
    g4x4b2m(G), shrink_shrink_strict(G, 2, _).

% shrink_find_scale tests.

test(find_scale_4x4) :-
    g4x4b2(G), shrink_find_scale(G, N), N =:= 2.

test(find_scale_6x6) :-
    g6x6b2(G), shrink_find_scale(G, N), N =:= 2.

test(find_scale_not_blocky, [fail]) :-
    shrink_find_scale([[1,2],[3,4]], _).

test(find_scale_n3) :-
    % 6x6 grid where each 3x3 block is uniform.
    G = [[r,r,r,g,g,g],[r,r,r,g,g,g],[r,r,r,g,g,g],[b,b,b,w,w,w],[b,b,b,w,w,w],[b,b,b,w,w,w]],
    shrink_find_scale(G, N), N =:= 3.

% shrink_obj_shrink tests.

test(object_shrink_2x2_block) :-
    % 2x2 block at origin all maps to r(0,0).
    shrink_obj_shrink(obj(red,[r(0,0),r(0,1),r(1,0),r(1,1)]), 2, R),
    R == obj(red,[r(0,0)]).

test(object_shrink_offset_block) :-
    % 2x2 block at rows 2-3, cols 4-5.
    shrink_obj_shrink(obj(blue,[r(2,4),r(2,5),r(3,4),r(3,5)]), 2, R),
    R == obj(blue,[r(1,2)]).

test(object_shrink_l_shape) :-
    % L-shape scaled by 2: cells at r(0,0) r(0,1) r(0,2) r(0,3) r(2,0) r(2,1).
    shrink_obj_shrink(obj(x,[r(0,0),r(0,1),r(0,2),r(0,3),r(2,0),r(2,1)]), 2, R),
    % r(0,0)//2=r(0,0), r(0,1)//2=r(0,0), r(0,2)//2=r(0,1), r(0,3)//2=r(0,1),
    % r(2,0)//2=r(1,0), r(2,1)//2=r(1,0).  Sort+dedup = [r(0,0),r(0,1),r(1,0)].
    R == obj(x,[r(0,0),r(0,1),r(1,0)]).

test(object_shrink_n1) :-
    % Factor 1: coords unchanged.
    shrink_obj_shrink(obj(a,[r(3,5),r(3,6)]), 1, R),
    R == obj(a,[r(3,5),r(3,6)]).

% shrink_scale_factor tests.

test(scale_factor_dot) :-
    % A single cell obj scaled by 3 gives a 3x3 block.
    Obj1 = obj(x,[r(0,0)]),
    findall(r(R,C),(between(0,2,R),between(0,2,C)),Block),
    Obj2 = obj(x,Block),
    shrink_scale_factor(Obj1, Obj2, N), N =:= 3.

test(scale_factor_hline) :-
    % Horizontal line [r(0,0),r(0,1)] scaled by 2 gives 4 cells in a 1x2 grid of 2x2 blocks.
    Obj1 = obj(a,[r(0,0),r(0,1)]),
    Obj2 = obj(a,[r(0,0),r(0,1),r(0,2),r(0,3),r(1,0),r(1,1),r(1,2),r(1,3)]),
    shrink_scale_factor(Obj1, Obj2, N), N =:= 2.

test(scale_factor_l_shape) :-
    % L = [r(0,0),r(0,1),r(1,0)]; scaled by 2.
    Obj1 = obj(c,[r(0,0),r(0,1),r(1,0)]),
    Obj2 = obj(c,[r(0,0),r(0,1),r(0,2),r(0,3),
                   r(1,0),r(1,1),r(1,2),r(1,3),
                   r(2,0),r(2,1),r(3,0),r(3,1)]),
    shrink_scale_factor(Obj1, Obj2, N), N =:= 2.

% shrink_uniform_blocks tests.

test(uniform_blocks_all) :-
    g4x4b2(G), shrink_uniform_blocks(G, 2, Pairs),
    sort(Pairs, S),
    S == [0-0,0-1,1-0,1-1].

test(uniform_blocks_partial) :-
    g4x4b2m(G), shrink_uniform_blocks(G, 2, Pairs),
    sort(Pairs, S),
    % Blocks (0,1),(1,0),(1,1) are uniform; (0,0) is mixed.
    S == [0-1,1-0,1-1].

test(uniform_blocks_none) :-
    shrink_uniform_blocks([[1,2],[3,4]], 2, Pairs), Pairs == [].

% shrink_mixed_blocks tests.

test(mixed_blocks_none) :-
    g4x4b2(G), shrink_mixed_blocks(G, 2, Pairs), Pairs == [].

test(mixed_blocks_one) :-
    g4x4b2m(G), shrink_mixed_blocks(G, 2, Pairs),
    sort(Pairs, S), S == [0-0].

test(mixed_blocks_all) :-
    % 4x4 grid where every 2x2 block has two colors.
    G = [[1,2,1,2],[2,1,2,1],[1,2,1,2],[2,1,2,1]],
    shrink_mixed_blocks(G, 2, Pairs), sort(Pairs, S),
    S == [0-0,0-1,1-0,1-1].

% shrink_block_grid tests.

test(block_grid_00) :-
    g4x4b2(G), shrink_block_grid(G, 2, 0, 0, P),
    P == [[1,1],[1,1]].

test(block_grid_11) :-
    g4x4b2(G), shrink_block_grid(G, 2, 1, 1, P),
    P == [[4,4],[4,4]].

test(block_grid_6x6_22) :-
    g6x6b2(G), shrink_block_grid(G, 2, 2, 2, P),
    P == [[i,i],[i,i]].

% shrink_block_val tests.

test(block_val_uniform) :-
    g4x4b2(G), shrink_block_val(G, 2, 0, 0, Vals), Vals == [1,1,1,1].

test(block_val_mixed) :-
    g2x2mix(G), shrink_block_val(G, 2, 0, 0, Vals), Vals == [1,2,1,1].

test(block_val_count) :-
    g6x6b2(G), shrink_block_val(G, 2, 1, 1, Vals), length(Vals, 4).

:- end_tests(shrink).
