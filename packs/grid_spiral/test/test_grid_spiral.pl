:- use_module('../prolog/grid_spiral').

% Grid fixtures
% 1x1 grid
g1x1([[a]]).
% 2x2 grid
g2x2([[a,b],[c,d]]).
% 3x3 plain grid
g3x3([[a,b,c],[d,e,f],[g,h,i]]).
% 3x3 checkerboard
g3x3_checker([[r,x,r],[x,r,x],[r,x,r]]).
% 3x3 all-r
g3x3_r([[r,r,r],[r,r,r],[r,r,r]]).
% 4x4 plain grid
g4x4([[a,b,c,d],[e,f,g,h],[i,j,k,l],[m,n,o,p]]).
% 5x5 onion pattern
g5x5_onion([[r,r,r,r,r],[r,x,x,x,r],[r,x,b,x,r],[r,x,x,x,r],[r,r,r,r,r]]).
% 2x4 grid
g2x4([[a,b,c,d],[e,f,g,h]]).
% 1x3 single row
g1x3([[a,b,c]]).

:- begin_tests(grid_spiral).

% --- grid_spiral_spiral ---
test(spiral_3x3_length, []) :-
    g3x3(G),
    grid_spiral_spiral(G, Cells),
    % 3x3 = 9 cells
    length(Cells, 9).

test(spiral_3x3_first, []) :-
    g3x3(G),
    grid_spiral_spiral(G, Cells),
    % First cell is top-left (0,0)
    Cells = [0-0|_].

test(spiral_3x3_last, []) :-
    g3x3(G),
    grid_spiral_spiral(G, Cells),
    % Last cell is center (1,1)
    last(Cells, 1-1).

test(spiral_1x1, []) :-
    g1x1(G),
    grid_spiral_spiral(G, [0-0]).

test(spiral_2x2, []) :-
    g2x2(G),
    % Clockwise: top-left, top-right, bottom-right, bottom-left
    grid_spiral_spiral(G, [0-0, 0-1, 1-1, 1-0]).

% --- grid_spiral_read_spiral ---
test(read_3x3, []) :-
    g3x3(G),
    % Clockwise: (0,0)=a,(0,1)=b,(0,2)=c,(1,2)=f,(2,2)=i,(2,1)=h,(2,0)=g,(1,0)=d,(1,1)=e
    grid_spiral_read_spiral(G, [a, b, c, f, i, h, g, d, e]).

test(read_1x1, []) :-
    g1x1(G),
    grid_spiral_read_spiral(G, [a]).

test(read_checker, []) :-
    g3x3_checker(G),
    % Spiral: (0,0)=r,(0,1)=x,(0,2)=r,(1,2)=x,(2,2)=r,(2,1)=x,(2,0)=r,(1,0)=x,(1,1)=r
    grid_spiral_read_spiral(G, [r, x, r, x, r, x, r, x, r]).

% --- grid_spiral_write_spiral ---
test(write_spiral_partial, []) :-
    g3x3(G),
    % Write only 2 values: (0,0) and (0,1) change, rest unchanged
    grid_spiral_write_spiral(G, [r, x], Result),
    nth0(0, Result, Row0), nth0(0, Row0, r),
    nth0(0, Result, Row0b), nth0(1, Row0b, x),
    % (0,2) unchanged = c
    nth0(0, Result, Row0c), nth0(2, Row0c, c).

test(write_spiral_full_3x3, []) :-
    g3x3(G),
    % Write all 9 values as p (overwrites everything)
    grid_spiral_write_spiral(G, [p,p,p,p,p,p,p,p,p], Result),
    Result = [[p,p,p],[p,p,p],[p,p,p]].

% --- grid_spiral_spiral_length ---
test(spiral_length_3x3, []) :-
    g3x3(G),
    grid_spiral_spiral_length(G, 9).

test(spiral_length_2x4, []) :-
    g2x4(G),
    grid_spiral_spiral_length(G, 8).

test(spiral_length_1x1, []) :-
    g1x1(G),
    grid_spiral_spiral_length(G, 1).

% --- grid_spiral_spiral_index ---
test(spiral_index_corner, []) :-
    g3x3(G),
    % Top-left corner is index 0
    grid_spiral_spiral_index(G, 0, 0, 0).

test(spiral_index_center, []) :-
    g3x3(G),
    % Center (1,1) is last = index 8
    grid_spiral_spiral_index(G, 1, 1, 8).

test(spiral_index_2x2_last, []) :-
    g2x2(G),
    % (1,0) is last in 2x2 spiral = index 3
    grid_spiral_spiral_index(G, 1, 0, 3).

% --- grid_spiral_nth_spiral ---
test(nth_spiral_0, []) :-
    g3x3(G),
    % Position 0 = (0,0)
    grid_spiral_nth_spiral(G, 0, 0, 0).

test(nth_spiral_last, []) :-
    g3x3(G),
    % Position 8 = center (1,1)
    grid_spiral_nth_spiral(G, 8, 1, 1).

% --- grid_spiral_frame_spiral ---
test(frame_spiral_0_3x3_count, []) :-
    g3x3(G),
    grid_spiral_frame_spiral(G, 0, Cells),
    % Outer frame of 3x3 = 8 cells
    length(Cells, 8).

test(frame_spiral_1_3x3_count, []) :-
    g3x3(G),
    grid_spiral_frame_spiral(G, 1, Cells),
    % Center frame of 3x3 = 1 cell
    length(Cells, 1),
    Cells = [1-1].

test(frame_spiral_0_2x2_count, []) :-
    g2x2(G),
    grid_spiral_frame_spiral(G, 0, Cells),
    % Entire 2x2 is one frame = 4 cells
    length(Cells, 4).

test(frame_spiral_0_3x3_first, []) :-
    g3x3(G),
    grid_spiral_frame_spiral(G, 0, Cells),
    Cells = [0-0|_].

test(frame_spiral_0_3x3_order, []) :-
    g3x3(G),
    % Frame 0 traversal: top-row then right col then bottom-row then left col
    grid_spiral_frame_spiral(G, 0, [0-0, 0-1, 0-2, 1-2, 2-2, 2-1, 2-0, 1-0]).

% --- grid_spiral_all_frame_spirals ---
test(all_frame_spirals_3x3, []) :-
    g3x3(G),
    grid_spiral_all_frame_spirals(G, Spirals),
    length(Spirals, 2).

test(all_frame_spirals_5x5, []) :-
    g5x5_onion(G),
    grid_spiral_all_frame_spirals(G, Spirals),
    length(Spirals, 3).

% --- grid_spiral_spiral_uniform ---
test(spiral_uniform_1x1, []) :-
    g1x1(G),
    grid_spiral_spiral_uniform(G, yes).

test(spiral_uniform_all_r, []) :-
    g3x3_r(G),
    grid_spiral_spiral_uniform(G, yes).

test(spiral_uniform_3x3_no, []) :-
    g3x3(G),
    grid_spiral_spiral_uniform(G, no).

% --- grid_spiral_spiral_reversed ---
test(spiral_reversed_1x1, []) :-
    g1x1(G),
    grid_spiral_spiral_reversed(G, [0-0]).

test(spiral_reversed_3x3_first, []) :-
    g3x3(G),
    grid_spiral_spiral_reversed(G, [1-1|_]).

test(spiral_reversed_3x3_last, []) :-
    g3x3(G),
    grid_spiral_spiral_reversed(G, Rev),
    last(Rev, 0-0).

% --- grid_spiral_spiral_count ---
test(spiral_count_r_checker, []) :-
    g3x3_checker(G),
    % Checkerboard has 5 r's
    grid_spiral_spiral_count(G, r, 5).

test(spiral_count_x_checker, []) :-
    g3x3_checker(G),
    % Checkerboard has 4 x's
    grid_spiral_spiral_count(G, x, 4).

test(spiral_count_1x1, []) :-
    g1x1(G),
    grid_spiral_spiral_count(G, a, 1).

% --- grid_spiral_fill_spiral ---
test(fill_spiral_alias, []) :-
    g3x3(G),
    % grid_spiral_fill_spiral is alias for grid_spiral_write_spiral
    grid_spiral_fill_spiral(G, [r,r,r,r,r,r,r,r,r], Result),
    Result = [[r,r,r],[r,r,r],[r,r,r]].

% --- grid_spiral_rotate_spiral ---
test(rotate_by_0, []) :-
    g3x3(G),
    % Rotate by 0 = identity
    grid_spiral_rotate_spiral(G, 0, Result),
    Result = [[a,b,c],[d,e,f],[g,h,i]].

test(rotate_by_length, []) :-
    g3x3(G),
    % Rotate by 9 (= full cycle mod 9 = 0) = identity
    grid_spiral_rotate_spiral(G, 9, Result),
    Result = [[a,b,c],[d,e,f],[g,h,i]].

test(rotate_checker_inverts, []) :-
    % Rotate checker by 1: each r shifts to where x was and vice versa
    % Read: [r,x,r,x,r,x,r,x,r], shift left by 1 = [x,r,x,r,x,r,x,r,r]
    % After write: (0,0)=x,(0,1)=r,(0,2)=x,(1,2)=r,(2,2)=x,(2,1)=r,(2,0)=x,(1,0)=r,(1,1)=r
    g3x3_checker(G),
    grid_spiral_rotate_spiral(G, 1, Result),
    nth0(0, Result, Row0), nth0(0, Row0, x),
    nth0(0, Result, Row0b), nth0(1, Row0b, r).

% --- grid_spiral_spiral_slice ---
test(spiral_slice_first_3, []) :-
    g3x3(G),
    % Positions 0..2 = top row
    grid_spiral_spiral_slice(G, 0, 2, [0-0, 0-1, 0-2]).

test(spiral_slice_last_1, []) :-
    g3x3(G),
    % Position 8 = center
    grid_spiral_spiral_slice(G, 8, 8, [1-1]).

% Combined
test(read_write_roundtrip, []) :-
    g4x4(G),
    grid_spiral_read_spiral(G, Vals),
    grid_spiral_write_spiral(G, Vals, Result),
    % Writing back the read values gives original
    Result = G.

test(spiral_covers_all_cells, []) :-
    g3x3(G),
    grid_spiral_spiral(G, Cells),
    % All 9 distinct cells covered
    list_to_set(Cells, Set),
    length(Set, 9).

test(spiral_1x3, []) :-
    g1x3(G),
    % Single row: left to right = [0-0, 0-1, 0-2]
    grid_spiral_spiral(G, [0-0, 0-1, 0-2]).

test(frame_spiral_0_5x5_count, []) :-
    g5x5_onion(G),
    grid_spiral_frame_spiral(G, 0, Cells),
    % Outer frame of 5x5 = 16 cells
    length(Cells, 16).

:- end_tests(grid_spiral).
