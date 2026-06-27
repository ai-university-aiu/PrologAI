:- use_module('../prolog/gridframe').

% Grid fixtures
% 1x1 grid
g1x1([[r]]).
% 3x3 plain grid (distinct values per cell)
g3x3([[a,b,c],[d,e,f],[g,h,i]]).
% 3x3 ring: frame 0 = r, frame 1 (center) = x
g3x3_rx([[r,r,r],[r,x,r],[r,r,r]]).
% 4x4 plain grid
g4x4([[a,b,c,d],[e,f,g,h],[i,j,k,l],[m,n,o,p]]).
% 5x5 onion: frame 0 = r, frame 1 = x, frame 2 (center) = b
g5x5_onion([[r,r,r,r,r],[r,x,x,x,r],[r,x,b,x,r],[r,x,x,x,r],[r,r,r,r,r]]).
% 5x5 plain grid
g5x5([[a,b,c,d,e],[f,g,h,i,j],[k,l,m,n,o],[p,q,r,s,t],[u,v,w,x,y]]).
% 2x4 grid (thin; all cells at depth 0)
g2x4([[r,r,r,r],[x,x,x,x]]).
% 3x4 grid: frame 0 = r, frame 1 = x,x
g3x4([[r,r,r,r],[r,x,x,r],[r,r,r,r]]).

:- begin_tests(gridframe).

% --- gfr_cell_depth ---
test(cell_depth_corner_3x3, []) :-
    g3x3(G),
    % Corner (0,0): min(0,2,0,2) = 0
    gfr_cell_depth(G, 0, 0, 0).

test(cell_depth_center_3x3, []) :-
    g3x3(G),
    % Center (1,1): min(1,1,1,1) = 1
    gfr_cell_depth(G, 1, 1, 1).

test(cell_depth_corner_5x5, []) :-
    g5x5(G),
    % Corner (0,0): depth = 0
    gfr_cell_depth(G, 0, 0, 0).

test(cell_depth_center_5x5, []) :-
    g5x5(G),
    % Center (2,2): min(2,2,2,2) = 2
    gfr_cell_depth(G, 2, 2, 2).

% --- gfr_frame cell counts ---
test(frame0_3x3_count, []) :-
    g3x3(G),
    gfr_frame(G, 0, Cells),
    % 3x3 border: 8 cells
    length(Cells, 8).

test(frame1_3x3_count, []) :-
    g3x3(G),
    gfr_frame(G, 1, Cells),
    % 3x3 center: 1 cell
    length(Cells, 1).

test(frame0_5x5_count, []) :-
    g5x5(G),
    gfr_frame(G, 0, Cells),
    % 5x5 border: 16 cells
    length(Cells, 16).

test(frame1_5x5_count, []) :-
    g5x5(G),
    gfr_frame(G, 1, Cells),
    % 5x5 inner ring: 8 cells
    length(Cells, 8).

test(frame2_5x5_count, []) :-
    g5x5(G),
    gfr_frame(G, 2, Cells),
    % 5x5 center: 1 cell
    length(Cells, 1).

% --- gfr_max_depth ---
test(max_depth_3x3, []) :-
    g3x3(G),
    gfr_max_depth(G, 1).

test(max_depth_5x5, []) :-
    g5x5(G),
    gfr_max_depth(G, 2).

test(max_depth_4x4, []) :-
    g4x4(G),
    gfr_max_depth(G, 1).

test(max_depth_2x4, []) :-
    g2x4(G),
    % min(2,4)=2; (2-1)//2=0
    gfr_max_depth(G, 0).

% --- gfr_frame_count ---
test(frame_count_3x3, []) :-
    g3x3(G),
    gfr_frame_count(G, 2).

test(frame_count_5x5, []) :-
    g5x5(G),
    gfr_frame_count(G, 3).

test(frame_count_1x1, []) :-
    g1x1(G),
    gfr_frame_count(G, 1).

% --- gfr_peel ---
test(peel_3x3_size, []) :-
    g3x3_rx(G),
    gfr_peel(G, Inner),
    % 3x3 peeled = 1x1
    length(Inner, 1),
    Inner = [[x]].

test(peel_5x5_size, []) :-
    g5x5(G),
    gfr_peel(G, Inner),
    % 5x5 peeled = 3x3
    length(Inner, 3),
    Inner = [R0|_], length(R0, 3).

test(peel_5x5_onion_content, []) :-
    g5x5_onion(G),
    gfr_peel(G, Inner),
    % Peeled inner grid should be the 3x3 with x and b
    Inner = [[x,x,x],[x,b,x],[x,x,x]].

test(peel_3x4_content, []) :-
    g3x4(G),
    gfr_peel(G, Inner),
    % 3x4 peeled = 1x2
    Inner = [[x,x]].

% --- gfr_all_frames ---
test(all_frames_3x3_count, []) :-
    g3x3(G),
    gfr_all_frames(G, Frames),
    % 2 frames (depth 0 and depth 1)
    length(Frames, 2).

test(all_frames_5x5_count, []) :-
    g5x5(G),
    gfr_all_frames(G, Frames),
    % 3 frames (depth 0, 1, 2)
    length(Frames, 3).

% --- gfr_frame_uniform ---
test(frame_uniform_0_rx_yes, []) :-
    g3x3_rx(G),
    % Frame 0 of g3x3_rx: all r -> yes
    gfr_frame_uniform(G, 0, yes).

test(frame_uniform_1_rx_yes, []) :-
    g3x3_rx(G),
    % Frame 1 of g3x3_rx: center = x -> yes
    gfr_frame_uniform(G, 1, yes).

test(frame_uniform_0_onion_yes, []) :-
    g5x5_onion(G),
    gfr_frame_uniform(G, 0, yes).

test(frame_uniform_1_onion_yes, []) :-
    g5x5_onion(G),
    gfr_frame_uniform(G, 1, yes).

test(frame_uniform_0_3x3_no, []) :-
    g3x3(G),
    % Frame 0 of g3x3: border has a,b,c,d,f,g,h,i -> not uniform
    gfr_frame_uniform(G, 0, no).

% --- gfr_frame_colors ---
test(frame_colors_0_rx, []) :-
    g3x3_rx(G),
    gfr_frame_colors(G, 0, Colors),
    Colors = [r].

test(frame_colors_2_onion, []) :-
    g5x5_onion(G),
    gfr_frame_colors(G, 2, Colors),
    Colors = [b].

test(frame_colors_0_3x3_many, []) :-
    g3x3(G),
    gfr_frame_colors(G, 0, Colors),
    % g3x3 border has a,b,c,d,f,g,h,i = 8 distinct colors
    length(Colors, 8).

% --- gfr_set_frame ---
test(set_frame_0_border, []) :-
    g3x3_rx(G),
    gfr_set_frame(G, 0, y, Result),
    % Border becomes y
    nth0(0, Result, Row0), nth0(0, Row0, y),
    nth0(0, Result, Row0b), nth0(1, Row0b, y),
    % Center stays x
    nth0(1, Result, Row1), nth0(1, Row1, x).

test(set_frame_1_center, []) :-
    g3x3_rx(G),
    gfr_set_frame(G, 1, y, Result),
    % Center becomes y
    nth0(1, Result, Row1), nth0(1, Row1, y),
    % Border stays r
    nth0(0, Result, Row0), nth0(0, Row0, r).

% --- gfr_count_in_frame ---
test(count_in_frame_r_f0_rx, []) :-
    g3x3_rx(G),
    % Frame 0 has 8 r cells
    gfr_count_in_frame(G, 0, r, 8).

test(count_in_frame_r_f1_rx, []) :-
    g3x3_rx(G),
    % Frame 1 has 0 r cells (center is x)
    gfr_count_in_frame(G, 1, r, 0).

test(count_in_frame_r_f0_onion, []) :-
    g5x5_onion(G),
    % Frame 0 has 16 r cells
    gfr_count_in_frame(G, 0, r, 16).

% --- gfr_uniform_frames ---
test(uniform_frames_rx, []) :-
    g3x3_rx(G),
    % Both frames are uniform
    gfr_uniform_frames(G, [0, 1]).

test(uniform_frames_onion, []) :-
    g5x5_onion(G),
    % All three frames are uniform
    gfr_uniform_frames(G, [0, 1, 2]).

test(uniform_frames_3x3, []) :-
    g3x3(G),
    % Only center (depth 1) is uniform (single cell)
    gfr_uniform_frames(G, [1]).

% --- gfr_fill_frames ---
test(fill_frames_3x3, []) :-
    g3x3(G),
    gfr_fill_frames(G, [r, x], Result),
    % Frame 0 becomes r, frame 1 becomes x
    Result = [[r,r,r],[r,x,r],[r,r,r]].

test(fill_frames_5x5, []) :-
    g5x5(G),
    gfr_fill_frames(G, [r, x, b], Result),
    % Frame 0 = r, frame 1 = x, frame 2 = b -> onion pattern
    Result = [[r,r,r,r,r],[r,x,x,x,r],[r,x,b,x,r],[r,x,x,x,r],[r,r,r,r,r]].

% --- gfr_innermost ---
test(innermost_3x3, []) :-
    g3x3(G),
    gfr_innermost(G, Cells),
    % Center cell (1,1)
    length(Cells, 1),
    Cells = [1-1].

test(innermost_5x5, []) :-
    g5x5(G),
    gfr_innermost(G, Cells),
    % Center cell (2,2)
    length(Cells, 1),
    Cells = [2-2].

% --- gfr_onion_layers ---
test(onion_layers_rx, []) :-
    g3x3_rx(G),
    gfr_onion_layers(G, Layers),
    Layers = [0-r, 1-x].

test(onion_layers_onion, []) :-
    g5x5_onion(G),
    gfr_onion_layers(G, Layers),
    Layers = [0-r, 1-x, 2-b].

:- end_tests(gridframe).
