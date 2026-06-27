:- module(gridmask, [
    gm_overlay/5,
    gm_union/4,
    gm_intersect/5,
    gm_difference/5,
    gm_invert/4,
    gm_mask_apply/5,
    gm_extract/4,
    gm_stamp/5,
    gm_compare/4,
    gm_equal/2,
    gm_sub/6,
    gm_paste/6,
    gm_border_mask/3,
    gm_color_mask/4
]).
% gridmask.pl - Layer 206: Grid Mask Operations - Boolean overlay, union,
% intersection, difference, inversion, masked extraction, sub-grid operations,
% and border/color masks (gm_* prefix).
% All predicates operate on raw grid format: list of rows, each row a list of
% color atoms, 0-indexed. Two grids can only be combined if they have the same
% dimensions (same H and W).
:- use_module(library(lists), [
    nth0/3, member/2, memberchk/2, append/2, append/3
]).

% --- PRIVATE HELPERS ---

% Grid dimensions.
gm_dims_(Grid, H, W) :-
    length(Grid, H),
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at (R, C).
gm_cell_(Grid, R, C, V) :-
    nth0(R, Grid, Row), nth0(C, Row, V).

% Build a new grid H x W by mapping f(R, C) -> V.
% Goal is called as call(Goal, R, C, V).
gm_build_(H, W, Goal, Grid) :-
    H1 is H - 1, W1 is W - 1,
    findall(Row,
        (between(0, H1, R),
         findall(V, (between(0, W1, C), call(Goal, R, C, V)), Row)),
        Grid).

% --- EXPORTED PREDICATES ---

% gm_overlay(+GridA, +GridB, +BgColor, +FgColor, -Result)
% Result[r][c] = GridB[r][c] if GridB[r][c] \= BgColor, else GridA[r][c].
% GridB is overlaid on top of GridA: non-BgColor cells of GridB "show through"
% onto GridA. Both grids must have the same dimensions.
gm_overlay(GridA, GridB, BgColor, _FgColor, Result) :-
    gm_dims_(GridA, H, W),
    gm_build_(H, W,
        [R, C, V]>>(gm_cell_(GridB, R, C, VB),
                    (VB \= BgColor -> V = VB ; gm_cell_(GridA, R, C, V))),
        Result).

% gm_union(+GridA, +GridB, +BgColor, -Result)
% Result[r][c] = FgColor if either GridA[r][c] or GridB[r][c] is not BgColor,
% else BgColor. Produces a boolean union of the non-background regions.
% The non-background color in Result is taken from GridA; cells where both are
% BgColor remain BgColor.
gm_union(GridA, GridB, BgColor, Result) :-
    gm_dims_(GridA, H, W),
    gm_build_(H, W,
        [R, C, V]>>(gm_cell_(GridA, R, C, VA), gm_cell_(GridB, R, C, VB),
                    (VA \= BgColor -> V = VA ;
                     VB \= BgColor -> V = VB ;
                     V = BgColor)),
        Result).

% gm_intersect(+GridA, +GridB, +BgColor, +FgColor, -Result)
% Result[r][c] = FgColor if both GridA[r][c] and GridB[r][c] are not BgColor,
% else BgColor. Produces the intersection of the two non-background regions.
gm_intersect(GridA, GridB, BgColor, FgColor, Result) :-
    gm_dims_(GridA, H, W),
    gm_build_(H, W,
        [R, C, V]>>(gm_cell_(GridA, R, C, VA), gm_cell_(GridB, R, C, VB),
                    (VA \= BgColor, VB \= BgColor -> V = FgColor ; V = BgColor)),
        Result).

% gm_difference(+GridA, +GridB, +BgColor, +BgOut, -Result)
% Result[r][c] = GridA[r][c] if GridB[r][c] = BgColor, else BgOut.
% Removes from GridA the cells that are non-BgColor in GridB (set subtraction).
gm_difference(GridA, GridB, BgColor, BgOut, Result) :-
    gm_dims_(GridA, H, W),
    gm_build_(H, W,
        [R, C, V]>>(gm_cell_(GridA, R, C, VA), gm_cell_(GridB, R, C, VB),
                    (VB = BgColor -> V = VA ; V = BgOut)),
        Result).

% gm_invert(+Grid, +BgColor, +FgColor, -Result)
% Result[r][c] = BgColor if Grid[r][c] \= BgColor, else FgColor.
% Swaps foreground and background: non-Bg becomes Bg, Bg becomes Fg.
gm_invert(Grid, BgColor, FgColor, Result) :-
    gm_dims_(Grid, H, W),
    gm_build_(H, W,
        [R, C, V]>>(gm_cell_(Grid, R, C, VO),
                    (VO \= BgColor -> V = BgColor ; V = FgColor)),
        Result).

% gm_mask_apply(+Grid, +Mask, +BgColor, +FillColor, -Result)
% Where Mask[r][c] = BgColor: Result[r][c] = FillColor (masked out).
% Where Mask[r][c] \= BgColor: Result[r][c] = Grid[r][c] (kept).
% The Mask controls which cells of Grid are visible; masked cells become FillColor.
gm_mask_apply(Grid, Mask, BgColor, FillColor, Result) :-
    gm_dims_(Grid, H, W),
    gm_build_(H, W,
        [R, C, V]>>(gm_cell_(Mask, R, C, VM),
                    (VM \= BgColor -> gm_cell_(Grid, R, C, V) ; V = FillColor)),
        Result).

% gm_extract(+Grid, +Cells, +BgColor, -Result)
% Result is a copy of Grid where every cell NOT in the list Cells is set to
% BgColor. Cells is a list of R-C coordinates (same format as region_cells).
gm_extract(Grid, Cells, BgColor, Result) :-
    gm_dims_(Grid, H, W),
    gm_build_(H, W,
        [R, C, V]>>(memberchk(R-C, Cells) -> gm_cell_(Grid, R, C, V) ; V = BgColor),
        Result).

% gm_stamp(+Grid, +Stamp, +OriginR, +OriginC, -Result)
% Paste Stamp onto Grid with its top-left at (OriginR, OriginC). Stamp cells
% that lie outside Grid bounds are silently ignored. Result has the same
% dimensions as Grid.
gm_stamp(Grid, Stamp, OR, OC, Result) :-
    gm_dims_(Grid, H, W),
    gm_dims_(Stamp, SH, SW),
    gm_build_(H, W,
        [R, C, V]>>(SR is R - OR, SC is C - OC,
                    (SR >= 0, SR < SH, SC >= 0, SC < SW ->
                        gm_cell_(Stamp, SR, SC, V)
                    ;
                        gm_cell_(Grid, R, C, V))),
        Result).

% gm_compare(+GridA, +GridB, +BgColor, -Diff)
% Diff is the list of R-C coordinates where GridA and GridB differ.
% Both grids must have the same dimensions.
gm_compare(GridA, GridB, _BgColor, Diff) :-
    gm_dims_(GridA, H, W),
    H1 is H - 1, W1 is W - 1,
    findall(R-C,
        (between(0, H1, R),
         between(0, W1, C),
         gm_cell_(GridA, R, C, VA),
         gm_cell_(GridB, R, C, VB),
         VA \= VB),
        Diff).

% gm_equal(+GridA, +GridB)
% Succeeds if GridA and GridB have identical dimensions and all cells match.
gm_equal(GridA, GridB) :-
    GridA = GridB.

% gm_sub(+Grid, +R0, +C0, +Height, +Width, -Sub)
% Sub is the Height x Width sub-grid of Grid starting at (R0, C0).
% Fails if the sub-grid extends outside Grid bounds.
gm_sub(Grid, R0, C0, Height, Width, Sub) :-
    gm_dims_(Grid, H, W),
    R0 >= 0, C0 >= 0,
    R1 is R0 + Height - 1, R1 < H,
    C1 is C0 + Width - 1, C1 < W,
    Height1 is Height - 1, Width1 is Width - 1,
    findall(Row,
        (between(0, Height1, DR),
         R is R0 + DR,
         findall(V,
             (between(0, Width1, DC),
              C is C0 + DC,
              gm_cell_(Grid, R, C, V)),
             Row)),
        Sub).

% gm_paste(+Grid, +Patch, +R0, +C0, +BgColor, -Result)
% Result is Grid with Patch pasted at (R0, C0). Only Patch cells whose color
% differs from BgColor replace the corresponding Grid cell; BgColor patch cells
% leave Grid unchanged (transparent paste).
gm_paste(Grid, Patch, R0, C0, BgColor, Result) :-
    gm_dims_(Grid, H, W),
    gm_dims_(Patch, _PH, _PW),
    gm_build_(H, W,
        [R, C, V]>>(PR is R - R0, PC is C - C0,
                    (PR >= 0, PC >= 0,
                     catch(gm_cell_(Patch, PR, PC, VP), _, fail),
                     VP \= BgColor ->
                        V = VP
                    ;
                        gm_cell_(Grid, R, C, V))),
        Result).

% gm_border_mask(+Grid, +N, -Mask)
% Mask is a binary grid (same dimensions as Grid) where border cells within N
% layers deep are marked with the atom 'border' and interior cells are 'interior'.
gm_border_mask(Grid, N, Mask) :-
    gm_dims_(Grid, H, W),
    gm_build_(H, W,
        [R, C, V]>>((R < N ; R >= H - N ; C < N ; C >= W - N) ->
                        V = border
                    ;
                        V = interior),
        Mask).

% gm_color_mask(+Grid, +Color, +FgColor, -Mask)
% Mask is a binary grid where cells matching Color become FgColor and all
% others become the atom 'bg'. Useful for generating a selection mask for
% a specific color.
gm_color_mask(Grid, Color, FgColor, Mask) :-
    gm_dims_(Grid, H, W),
    gm_build_(H, W,
        [R, C, V]>>(gm_cell_(Grid, R, C, GV),
                    (GV = Color -> V = FgColor ; V = bg)),
        Mask).
