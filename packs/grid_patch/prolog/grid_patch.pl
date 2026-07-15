:- module(grid_patch, [
    grid_patch_extract/6,
    grid_patch_place/5,
    grid_patch_overlay/6,
    grid_patch_match_at/4,
    grid_patch_find_all/3,
    grid_patch_count/3,
    grid_patch_scatter/4,
    grid_patch_tile_fill/4,
    grid_patch_h/2,
    grid_patch_w/2,
    grid_patch_size/3,
    grid_patch_eq/2,
    grid_patch_inpaint/7,
    grid_patch_replace_first/4
]).
% gridpatch.pl - Layer 227: Grid Patch Operations (gpt_* prefix).
% Fourteen predicates for extracting, placing, tiling, searching, and replacing
% sub-grid regions (patches). All operations are non-destructive.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% A patch is itself a grid: a list of rows, each a list of color atoms.
% No cross-pack dependencies.
:- use_module(library(lists), [nth0/3, member/2, append/3]).

% --- PRIVATE HELPERS ---

% Grid dimensions.
grid_patch_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row; zero if empty grid.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% --- PUBLIC PREDICATES ---

% grid_patch_extract(+Grid, +R0, +C0, +R1, +C1, -Patch)
% Patch is the sub-grid of Grid at rows R0..R1 and columns C0..C1 (0-indexed,
% inclusive). Equivalent to a rectangular copy operation.
grid_patch_extract(Grid, R0, C0, R1, C1, Patch) :-
% Build each row of the patch.
    findall(Row,
% Iterate source rows.
        (between(R0, R1, R), nth0(R, Grid, GRow),
% Collect cells from C0 to C1.
         findall(V, (between(C0, C1, C), nth0(C, GRow, V)), Row)),
        Patch).

% grid_patch_place(+Grid, +Patch, +R0, +C0, -Result)
% Result is Grid with Patch pasted at top-left position (R0, C0), overwriting
% the cells at the corresponding positions. Cells outside the patch are
% unchanged.
grid_patch_place(Grid, Patch, R0, C0, Result) :-
% Grid and patch sizes.
    grid_patch_dims_(Grid, H, W),
    grid_patch_dims_(Patch, PH, PW),
    H1 is H - 1, W1 is W - 1,
% Rebuild every row.
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, GRow),
% Row offset within patch.
         PR is R - R0,
         findall(V2,
             (between(0, W1, C),
% Column offset within patch.
              PC is C - C0,
              (PR >= 0, PR < PH, PC >= 0, PC < PW ->
                  nth0(PR, Patch, PRow), nth0(PC, PRow, V2)
              ;   nth0(C, GRow, V2))),
             NewRow)),
        Result).

% grid_patch_overlay(+Grid, +Patch, +R0, +C0, +TranspColor, -Result)
% Result is Grid with Patch pasted at (R0, C0) using transparency: cells in
% Patch with color TranspColor are not copied, leaving the Grid cell intact.
% Non-transparent Patch cells overwrite the Grid.
grid_patch_overlay(Grid, Patch, R0, C0, TranspColor, Result) :-
% Grid and patch sizes.
    grid_patch_dims_(Grid, H, W),
    grid_patch_dims_(Patch, PH, PW),
    H1 is H - 1, W1 is W - 1,
% Rebuild every row.
    findall(NewRow,
        (between(0, H1, R),
         nth0(R, Grid, GRow),
% Row offset within patch.
         PR is R - R0,
         findall(V2,
             (between(0, W1, C),
% Column offset within patch.
              PC is C - C0,
              (PR >= 0, PR < PH, PC >= 0, PC < PW ->
                  nth0(PR, Patch, PRow), nth0(PC, PRow, PV),
% Keep Grid cell if Patch cell is transparent.
                  (PV = TranspColor -> nth0(C, GRow, V2) ; V2 = PV)
              ;   nth0(C, GRow, V2))),
             NewRow)),
        Result).

% grid_patch_match_at(+Grid, +Patch, +R0, +C0)
% Succeeds if Patch exactly matches the sub-grid of Grid starting at (R0, C0).
% Fails if any cell differs or if the patch would extend outside the grid.
grid_patch_match_at(Grid, Patch, R0, C0) :-
% Patch dimensions.
    grid_patch_dims_(Patch, PH, PW),
    PH1 is PH - 1, PW1 is PW - 1,
% No mismatching cell exists.
    \+ (between(0, PH1, PR), between(0, PW1, PC),
        GR is R0 + PR, GC is C0 + PC,
        nth0(GR, Grid, GRow), nth0(GC, GRow, GV),
        nth0(PR, Patch, PRow), nth0(PC, PRow, PV),
        GV \= PV).

% grid_patch_find_all(+Grid, +Patch, -Positions)
% Positions is the list of R0-C0 pairs (row-major order) where Patch exactly
% matches the sub-grid of Grid starting at that position.
grid_patch_find_all(Grid, Patch, Positions) :-
% Compute valid placement range.
    grid_patch_dims_(Grid, H, W),
    grid_patch_dims_(Patch, PH, PW),
    MaxR is H - PH, MaxC is W - PW,
% Collect all matching top-left positions.
    findall(R0-C0,
        (between(0, MaxR, R0), between(0, MaxC, C0),
         grid_patch_match_at(Grid, Patch, R0, C0)),
        Positions).

% grid_patch_count(+Grid, +Patch, -Count)
% Count is the number of positions in Grid where Patch exactly matches.
grid_patch_count(Grid, Patch, Count) :-
% Use find_all and measure.
    grid_patch_find_all(Grid, Patch, Positions),
    length(Positions, Count).

% grid_patch_scatter(+Grid, +Patch, +Positions, -Result)
% Result is Grid with Patch placed (overwriting) at every R0-C0 pair in Positions.
% Placements are applied left-to-right so later positions overwrite earlier ones.
grid_patch_scatter(Grid, _, [], Grid) :- !.
% Recursive step: place patch at head position then continue.
grid_patch_scatter(Grid, Patch, [R0-C0|Rest], Result) :-
    grid_patch_place(Grid, Patch, R0, C0, Grid2),
    grid_patch_scatter(Grid2, Patch, Rest, Result).

% grid_patch_tile_fill(+Patch, +H, +W, -Grid)
% Grid is an H x W grid created by tiling Patch: cell (R,C) = Patch[R mod PH][C mod PW].
grid_patch_tile_fill(Patch, H, W, Grid) :-
% Patch period sizes.
    grid_patch_dims_(Patch, PH, PW),
    H1 is H - 1, W1 is W - 1,
% Build each row.
    findall(Row,
        (between(0, H1, R), PR is R mod PH,
         findall(V,
             (between(0, W1, C), PC is C mod PW,
              nth0(PR, Patch, PRow), nth0(PC, PRow, V)),
             Row)),
        Grid).

% grid_patch_h(+Patch, -H)
% H is the number of rows in Patch.
grid_patch_h(Patch, H) :-
    length(Patch, H).

% grid_patch_w(+Patch, -W)
% W is the number of columns in Patch (width of the first row).
grid_patch_w(Patch, W) :-
    (Patch = [Row|_] -> length(Row, W) ; W = 0).

% grid_patch_size(+Patch, -H, -W)
% H and W are the number of rows and columns of Patch.
grid_patch_size(Patch, H, W) :-
    grid_patch_dims_(Patch, H, W).

% grid_patch_eq(+Patch1, +Patch2)
% Succeeds if Patch1 and Patch2 are identical grids (same dimensions and all
% cells equal).
grid_patch_eq(P1, P2) :-
    P1 = P2.

% grid_patch_inpaint(+Grid, +R0, +C0, +R1, +C1, +Color, -Result)
% Result is Grid with every cell in the rectangle rows [R0..R1], cols [C0..C1]
% replaced by Color. Used to clear or fill a region.
grid_patch_inpaint(Grid, R0, C0, R1, C1, Color, Result) :-
% Grid dimensions.
    grid_patch_dims_(Grid, H, W),
    H1 is H - 1, W1 is W - 1,
% Rebuild every row.
    findall(NewRow,
        (between(0, H1, R), nth0(R, Grid, GRow),
         findall(V2,
             (between(0, W1, C),
              (R >= R0, R =< R1, C >= C0, C =< C1 ->
                  V2 = Color
              ;   nth0(C, GRow, V2))),
             NewRow)),
        Result).

% grid_patch_replace_first(+Grid, +OldPatch, +NewPatch, -Result)
% Result is Grid with the first (top-left, row-major) occurrence of OldPatch
% replaced by NewPatch. Fails if OldPatch does not occur in Grid.
grid_patch_replace_first(Grid, OldPatch, NewPatch, Result) :-
% Find the first matching position.
    grid_patch_find_all(Grid, OldPatch, [R0-C0|_]),
% Place NewPatch at that position.
    grid_patch_place(Grid, NewPatch, R0, C0, Result).
