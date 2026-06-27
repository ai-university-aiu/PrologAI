:- module(gridframe, [
    gfr_cell_depth/4,
    gfr_frame/3,
    gfr_max_depth/2,
    gfr_frame_count/2,
    gfr_peel/2,
    gfr_all_frames/2,
    gfr_frame_uniform/3,
    gfr_frame_colors/3,
    gfr_set_frame/4,
    gfr_count_in_frame/4,
    gfr_uniform_frames/2,
    gfr_fill_frames/3,
    gfr_innermost/2,
    gfr_onion_layers/2
]).
% gridframe.pl - Layer 216: Grid Frame Analysis (gfr_* prefix).
% Treats a grid as concentric rings (frames). Frame depth D is the set of cells
% (R,C) where min(R, H-1-R, C, W-1-C) = D. Frame 0 is the outermost border.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
:- use_module(library(lists), [
    nth0/3, member/2, list_to_set/2
]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
gfr_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed); fails if out of bounds.
gfr_cell_(Grid, R, C, V) :-
% Select row R.
    nth0(R, Grid, Row),
% Select column C.
    nth0(C, Row, V).

% Build a new H x W grid using a lambda Goal(R, C, V).
gfr_build_(H, W, Goal, Grid) :-
% Compute last indices.
    H1 is H - 1, W1 is W - 1,
% Collect rows.
    findall(Row,
        (between(0, H1, R),
         findall(V, (between(0, W1, C), call(Goal, R, C, V)), Row)),
        Grid).

% Depth of cell (R,C) in an H x W grid.
% Depth = min distance to any grid border = min(R, H-1-R, C, W-1-C).
gfr_depth_(H, W, R, C, D) :-
% Distance to top and bottom borders.
    DR is min(R, H - 1 - R),
% Distance to left and right borders.
    DC is min(C, W - 1 - C),
% Depth is the closer of the two.
    D is min(DR, DC).

% Test if all elements of a list are equal.
gfr_all_eq_([]).
gfr_all_eq_([_]).
gfr_all_eq_([A, A | Rest]) :- gfr_all_eq_([A | Rest]).

% --- PUBLIC PREDICATES ---

% gfr_cell_depth(+Grid, +R, +C, -D)
% D is the frame depth of cell (R,C): its minimum distance to any grid border.
% Frame 0 = border cells; frame D = cells D steps inside the border.
gfr_cell_depth(Grid, R, C, D) :-
% Get grid dimensions.
    gfr_dims_(Grid, H, W),
% Compute depth.
    gfr_depth_(H, W, R, C, D).

% gfr_frame(+Grid, +D, -Cells)
% Cells is the list of R-C pairs at frame depth D, in row-major order.
% Frame D: all cells (R,C) where min(R,H-1-R,C,W-1-C) = D.
gfr_frame(Grid, D, Cells) :-
% Get dimensions.
    gfr_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect cells at depth D.
    findall(R-C,
        (between(0, H1, R),
         between(0, W1, C),
         gfr_depth_(H, W, R, C, D)),
        Cells).

% gfr_max_depth(+Grid, -D)
% D is the maximum frame depth: floor((min(H,W) - 1) / 2).
% For a 1x1 grid D=0; for 3x3 D=1; for 5x5 D=2; for 4x4 D=1.
gfr_max_depth(Grid, D) :-
% Get dimensions.
    gfr_dims_(Grid, H, W),
% Compute max depth from smaller dimension.
    D is (min(H, W) - 1) // 2.

% gfr_frame_count(+Grid, -N)
% N is the number of distinct frame depths (from 0 to max_depth inclusive).
gfr_frame_count(Grid, N) :-
% Max depth plus one gives frame count.
    gfr_max_depth(Grid, D),
    N is D + 1.

% gfr_peel(+Grid, -Inner)
% Inner is the (H-2)x(W-2) subgrid obtained by removing the outermost frame.
% Fails if H < 3 or W < 3.
gfr_peel(Grid, Inner) :-
% Get dimensions.
    gfr_dims_(Grid, H, W),
% Peeling requires at least 3 rows and 3 columns.
    H >= 3, W >= 3,
    H1 is H - 2, W1 is W - 2,
% Build inner grid by shifting indices by 1.
    gfr_build_(H1, W1,
        [R, C, V]>>(R1 is R + 1, C1 is C + 1, gfr_cell_(Grid, R1, C1, V)),
        Inner).

% gfr_all_frames(+Grid, -Frames)
% Frames is the list [Frame0, Frame1, ...] where each FrameD is a list of R-C pairs.
% Ordered from outermost (D=0) to innermost (D=max_depth).
gfr_all_frames(Grid, Frames) :-
% Compute max depth.
    gfr_max_depth(Grid, MaxD),
% Collect frame cell-lists in depth order.
    findall(Cells, (between(0, MaxD, D), gfr_frame(Grid, D, Cells)), Frames).

% gfr_frame_uniform(+Grid, +D, -Bool)
% Bool is yes if all cells at depth D have the same color; no otherwise.
% Fails if depth D has no cells.
gfr_frame_uniform(Grid, D, Bool) :-
% Get cells at this depth.
    gfr_frame(Grid, D, Cells),
% Depth must be non-empty.
    Cells \= [],
% Collect values of all cells in this frame.
    findall(V, (member(R-C, Cells), gfr_cell_(Grid, R, C, V)), Vals),
% Test uniformity.
    (gfr_all_eq_(Vals) -> Bool = yes ; Bool = no).

% gfr_frame_colors(+Grid, +D, -Colors)
% Colors is the sorted list of distinct colors present in frame D.
gfr_frame_colors(Grid, D, Colors) :-
% Get cells at this depth.
    gfr_frame(Grid, D, Cells),
% Collect all values.
    findall(V, (member(R-C, Cells), gfr_cell_(Grid, R, C, V)), Vals),
% Deduplicate.
    list_to_set(Vals, Colors).

% gfr_set_frame(+Grid, +D, +Color, -Result)
% Result is Grid with all cells at frame depth D replaced by Color.
gfr_set_frame(Grid, D, Color, Result) :-
% Get dimensions.
    gfr_dims_(Grid, H, W),
% Build result: replace depth-D cells, keep others.
    gfr_build_(H, W,
        [R, C, V]>>(gfr_depth_(H, W, R, C, Dep),
                    gfr_cell_(Grid, R, C, Orig),
                    (Dep =:= D -> V = Color ; V = Orig)),
        Result).

% gfr_count_in_frame(+Grid, +D, +Color, -Count)
% Count is the number of cells of Color at frame depth D.
gfr_count_in_frame(Grid, D, Color, Count) :-
% Get cells at depth D.
    gfr_frame(Grid, D, Cells),
% Count Color occurrences.
    findall(1, (member(R-C, Cells), gfr_cell_(Grid, R, C, Color)), Ones),
    length(Ones, Count).

% gfr_uniform_frames(+Grid, -Ds)
% Ds is the list of frame depths (in ascending order) for which the frame is uniform.
gfr_uniform_frames(Grid, Ds) :-
% Get max depth.
    gfr_max_depth(Grid, MaxD),
% Collect uniform depths.
    findall(D, (between(0, MaxD, D), gfr_frame_uniform(Grid, D, yes)), Ds).

% gfr_fill_frames(+Grid, +Colors, -Result)
% Result is Grid with frame D set to Colors[D] for each D.
% If Colors is shorter than frame_count, remaining frames are unchanged.
gfr_fill_frames(Grid, Colors, Result) :-
% Get dimensions.
    gfr_dims_(Grid, H, W),
% Build result: for each cell, use Colors[depth] if available.
    gfr_build_(H, W,
        [R, C, V]>>(gfr_depth_(H, W, R, C, D),
                    gfr_cell_(Grid, R, C, Orig),
                    (nth0(D, Colors, FillColor) -> V = FillColor ; V = Orig)),
        Result).

% gfr_innermost(+Grid, -Cells)
% Cells is the list of R-C pairs at the maximum frame depth.
% For odd-min-dim grids this is a single center cell; for even-min-dim it is a 2x2.
gfr_innermost(Grid, Cells) :-
% Get max depth.
    gfr_max_depth(Grid, MaxD),
% Frame at max depth.
    gfr_frame(Grid, MaxD, Cells).

% gfr_onion_layers(+Grid, -Layers)
% Layers is a list of D-Color pairs for each uniform frame depth D, in ascending order.
% Frames that are not uniform are excluded.
% A grid is a "perfect onion" if Layers has length = frame_count.
gfr_onion_layers(Grid, Layers) :-
% Get max depth.
    gfr_max_depth(Grid, MaxD),
% Collect (D, Color) for each uniform frame.
    findall(D-Color,
        (between(0, MaxD, D),
         gfr_frame(Grid, D, Cells),
         Cells \= [],
         findall(V, (member(R-C, Cells), gfr_cell_(Grid, R, C, V)), Vals),
         gfr_all_eq_(Vals),
         Vals = [Color | _]),
        Layers).
