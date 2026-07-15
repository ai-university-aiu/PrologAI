% Module declaration with all fourteen public predicates.
:- module(grid_resize, [
% Scale up grid by integer factor F (each cell becomes F x F block).
    grid_resize_scale_up/3,
% Scale down by integer factor F, sampling top-left of each block.
    grid_resize_scale_down/4,
% Scale down by integer factor F using mode (most common value) of each block.
    grid_resize_scale_down_mode/4,
% Scale up by exactly 2 (shorthand for grid_resize_scale_up with F=2).
    grid_resize_double/2,
% Scale down by exactly 2, sampling top-left cell.
    grid_resize_halve/3,
% Nearest-neighbor resize to (NewH x NewW) dimensions.
    grid_resize_resize/5,
% Tile input grid to fill exactly H x W by repetition (modular wrap).
    grid_resize_tile_to/4,
% Crop to rows R0..R1 and columns C0..C1 (0-indexed, inclusive, clamped).
    grid_resize_crop/6,
% Remove N rows and columns from all four borders.
    grid_resize_border_crop/4,
% Scale to fit within H x W preserving aspect ratio, then center (letterbox).
    grid_resize_fit_in/5,
% Pad grid to H x W by centering content on a Bg canvas (no scaling).
    grid_resize_embed_in/5,
% Return grid dimensions H (rows) and W (columns).
    grid_resize_grid_size/3,
% Return H, W, and float aspect ratio W/H.
    grid_resize_aspect_ratio/4,
% Succeed if grid is square (H = W).
    grid_resize_is_square/1
]).
% gridresize.pl - Layer 241: Grid Resize and Scale Operations (grs_* prefix).
% Fourteen predicates for scaling, resizing, tiling, cropping, and fitting.
% No cross-pack dependencies. Uses built-ins only.

% --- PRIVATE HELPERS ---

% grid_resize_dims_/3: (H, W) of a grid; W=0 for empty grid.
grid_resize_dims_(Grid, H, W) :-
    length(Grid, H),
    ( H > 0 -> Grid = [Row0|_], length(Row0, W) ; W = 0 ).

% grid_resize_cell_/4: value at (R, C) in Grid.
grid_resize_cell_(Grid, R, C, V) :-
    nth0(R, Grid, Row), nth0(C, Row, V).

% grid_resize_count_/3: count occurrences of Val in list.
grid_resize_count_([], _, 0).
grid_resize_count_([H|T], Val, N) :-
    grid_resize_count_(T, Val, N0),
    ( H = Val -> N is N0 + 1 ; N = N0 ).

% grid_resize_mode_/2: most common element; on ties the msort-first value wins.
grid_resize_mode_(List, Mode) :-
    sort(List, Vals),
    findall(neg(Neg,V), (member(V, Vals), grid_resize_count_(List, V, N), Neg is -N), Keyed),
    msort(Keyed, [neg(_,Mode)|_]).

% --- PUBLIC PREDICATES ---

% grid_resize_scale_up(+Grid, +F, -Result)
% Each cell becomes an F x F block of the same value.
% Result is (H*F) x (W*F).
grid_resize_scale_up(Grid, F, Result) :-
    grid_resize_dims_(Grid, H, W),
    NewH is H * F, NewW is W * F,
    NewH1 is NewH - 1, NewW1 is NewW - 1,
    findall(Row,
        (between(0, NewH1, R),
         findall(V,
             (between(0, NewW1, C),
              SR is R // F, SC is C // F,
              grid_resize_cell_(Grid, SR, SC, V)),
             Row)),
        Result).

% grid_resize_scale_down(+Grid, +F, +Bg, -Result)
% Sample the top-left cell of each F x F block.
% Result is floor(H/F) x floor(W/F). Returns [] if result would be 0x0.
grid_resize_scale_down(Grid, F, _Bg, Result) :-
    grid_resize_dims_(Grid, H, W),
    NewH is H // F, NewW is W // F,
    ( NewH > 0, NewW > 0 ->
        NewH1 is NewH - 1, NewW1 is NewW - 1,
        findall(Row,
            (between(0, NewH1, R),
             findall(V,
                 (between(0, NewW1, C),
                  SR is R * F, SC is C * F,
                  grid_resize_cell_(Grid, SR, SC, V)),
                 Row)),
            Result)
    ;
        Result = []
    ).

% grid_resize_scale_down_mode(+Grid, +F, +Bg, -Result)
% Take the mode (most common value) of each F x F block.
% Ties broken by msort order (lexicographically first atom wins).
grid_resize_scale_down_mode(Grid, F, _Bg, Result) :-
    grid_resize_dims_(Grid, H, W),
    NewH is H // F, NewW is W // F,
    ( NewH > 0, NewW > 0 ->
        NewH1 is NewH - 1, NewW1 is NewW - 1, F1 is F - 1,
        findall(Row,
            (between(0, NewH1, R),
             findall(V,
                 (between(0, NewW1, C),
                  BR is R * F, BC is C * F,
                  BRE is BR + F1, BCE is BC + F1,
                  findall(BV,
                      (between(BR, BRE, SR), between(BC, BCE, SC),
                       SR < H, SC < W,
                       grid_resize_cell_(Grid, SR, SC, BV)),
                      Block),
                  ( Block = [] ->
                      grid_resize_cell_(Grid, BR, BC, V)
                  ;
                      grid_resize_mode_(Block, V)
                  )),
                 Row)),
            Result)
    ;
        Result = []
    ).

% grid_resize_double(+Grid, -Result)
% Scale up by factor 2. Each cell becomes a 2 x 2 block.
grid_resize_double(Grid, Result) :-
    grid_resize_scale_up(Grid, 2, Result).

% grid_resize_halve(+Grid, +Bg, -Result)
% Scale down by factor 2, sampling top-left of each 2 x 2 block.
grid_resize_halve(Grid, Bg, Result) :-
    grid_resize_scale_down(Grid, 2, Bg, Result).

% grid_resize_resize(+Grid, +NewH, +NewW, +Bg, -Result)
% Nearest-neighbor resize: Result[r][c] = Grid[floor(r*H/NewH)][floor(c*W/NewW)].
% Returns [] for NewH=0 or NewW=0. Fills with Bg if source grid is empty.
% Outer parens ensure grid_resize_dims_ runs before the if-then-else.
grid_resize_resize(Grid, NewH, NewW, Bg, Result) :-
    grid_resize_dims_(Grid, H, W),
    (   ( NewH =:= 0 ; NewW =:= 0 )
    ->  Result = []
    ;   ( H =:= 0 ; W =:= 0 )
    ->  NewH1 is NewH - 1, NewW1 is NewW - 1,
        findall(Row,
            (between(0, NewH1, _),
             findall(Bg, between(0, NewW1, _), Row)),
            Result)
    ;   NewH1 is NewH - 1, NewW1 is NewW - 1,
        findall(Row,
            (between(0, NewH1, R),
             findall(V,
                 (between(0, NewW1, C),
                  SR is (R * H) // NewH, SC is (C * W) // NewW,
                  grid_resize_cell_(Grid, SR, SC, V)),
                 Row)),
            Result)
    ).

% grid_resize_tile_to(+Grid, +H, +W, -Result)
% Tile Grid to fill exactly H x W by modular repetition.
% Result[r][c] = Grid[r mod H0][c mod W0].
% Outer parens ensure grid_resize_dims_ runs before the if-then-else.
grid_resize_tile_to(Grid, H, W, Result) :-
    grid_resize_dims_(Grid, H0, W0),
    (   ( H =:= 0 ; W =:= 0 ; H0 =:= 0 ; W0 =:= 0 )
    ->  Result = []
    ;   H1 is H - 1, W1 is W - 1,
        findall(Row,
            (between(0, H1, R),
             findall(V,
                 (between(0, W1, C),
                  SR is R mod H0, SC is C mod W0,
                  grid_resize_cell_(Grid, SR, SC, V)),
                 Row)),
            Result)
    ).

% grid_resize_crop(+Grid, +R0, +C0, +R1, +C1, -Result)
% Extract the subgrid for rows R0..R1 and cols C0..C1 (0-indexed, inclusive).
% Indices are clamped to grid bounds. Returns [] if resulting range is empty.
% Outer parens ensure grid_resize_dims_ runs before the if-then-else.
grid_resize_crop(Grid, R0, C0, R1, C1, Result) :-
    grid_resize_dims_(Grid, H, W),
    ClR0 is max(R0, 0), ClC0 is max(C0, 0),
    ClR1 is min(R1, H - 1), ClC1 is min(C1, W - 1),
    (   ( ClR0 > ClR1 ; ClC0 > ClC1 )
    ->  Result = []
    ;   findall(Row,
            (between(ClR0, ClR1, R),
             findall(V,
                 (between(ClC0, ClC1, C), grid_resize_cell_(Grid, R, C, V)),
                 Row)),
            Result)
    ).

% grid_resize_border_crop(+Grid, +N, +Bg, -Result)
% Remove N rows/columns from all four borders.
% Returns [] if grid would become empty (H <= 2N or W <= 2N).
grid_resize_border_crop(Grid, N, Bg, Result) :-
    grid_resize_dims_(Grid, H, W),
    R0 is N, C0 is N, R1 is H - N - 1, C1 is W - N - 1,
    ( R1 >= R0, C1 >= C0 ->
        grid_resize_crop(Grid, R0, C0, R1, C1, Result)
    ;
        Result = []
    ).

% grid_resize_fit_in(+Grid, +H, +W, +Bg, -Result)
% Scale Grid to fit within H x W preserving aspect ratio (letterbox).
% The scaled grid is then centered in a H x W Bg canvas.
% Outer parens ensure grid_resize_dims_ runs before the if-then-else.
grid_resize_fit_in(Grid, H, W, Bg, Result) :-
    grid_resize_dims_(Grid, H0, W0),
    (   ( H0 =:= 0 ; W0 =:= 0 )
    ->  grid_resize_embed_in(Grid, H, W, Bg, Result)
    ;   ScaleH is H / H0, ScaleW is W / W0,
        Scale is min(ScaleH, ScaleW),
        NewH is max(1, round(H0 * Scale)),
        NewW is max(1, round(W0 * Scale)),
        grid_resize_resize(Grid, NewH, NewW, Bg, Scaled),
        grid_resize_embed_in(Scaled, H, W, Bg, Result)
    ).

% grid_resize_embed_in(+Grid, +H, +W, +Bg, -Result)
% Center Grid in a H x W canvas filled with Bg.
% Grid cells are placed starting at ((H-H0)//2, (W-W0)//2).
% Grid content that would fall outside H x W is clipped.
grid_resize_embed_in(Grid, H, W, Bg, Result) :-
    grid_resize_dims_(Grid, H0, W0),
    OffR is (H - H0) // 2, OffC is (W - W0) // 2,
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        (between(0, H1, R),
         findall(V,
             (between(0, W1, C),
              SR is R - OffR, SC is C - OffC,
              ( SR >= 0, SR < H0, SC >= 0, SC < W0 ->
                  grid_resize_cell_(Grid, SR, SC, V)
              ;
                  V = Bg
              )),
             Row)),
        Result).

% grid_resize_grid_size(+Grid, -H, -W)
% H is the number of rows; W is the number of columns.
grid_resize_grid_size(Grid, H, W) :-
    grid_resize_dims_(Grid, H, W).

% grid_resize_aspect_ratio(+Grid, -H, -W, -Ratio)
% Ratio is W / H as a float. If H = 0, Ratio = 0.0.
grid_resize_aspect_ratio(Grid, H, W, Ratio) :-
    grid_resize_dims_(Grid, H, W),
    ( H =:= 0 -> Ratio = 0.0 ; Ratio is W / H ).

% grid_resize_is_square(+Grid)
% Succeeds if Grid has equal numbers of rows and columns.
grid_resize_is_square(Grid) :-
    grid_resize_dims_(Grid, H, W), H =:= W.
