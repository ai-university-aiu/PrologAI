% canvas.pl - Layer 174: Grid Canvas and Object Rendering (cv_* prefix).
% Provides predicates for creating grid canvases, painting obj(Color, Cells)
% terms onto them, erasing objects, extracting objects from grids, and
% compositing subgrids. No cross-pack dependencies.
:- module(canvas, [
    cv_blank/4,
    cv_size/3,
    cv_paint/3,
    cv_paint_all/3,
    cv_paint_at/5,
    cv_paint_clip/3,
    cv_paint_bg/4,
    cv_erase/4,
    cv_extract/3,
    cv_extract_all/3,
    cv_render/5,
    cv_move/6,
    cv_stamp/3,
    cv_blit/5
]).

% Import list utilities from standard library.
:- use_module(library(lists), [member/2, nth0/3, memberchk/2]).

% ============================================================
% PRIVATE HELPERS
% ============================================================

% cv_dims_(+Grid, -H, -W): height and width of a grid (list of rows).
cv_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from the first row.
    Grid = [Row|_],
% Width = length of first row.
    length(Row, W).

% cv_paint_cells_(+Grid, +Cells, +Color, -Grid2): single-pass painting.
% For each row R and column C in Grid, if r(R,C) is in Cells the output
% value is Color; otherwise the original value is preserved.
cv_paint_cells_(Grid, Cells, Color, Grid2) :-
% Rebuild each row.
    findall(Row2,
% Enumerate rows by index.
        (nth0(R, Grid, Row),
% Rebuild each cell in the row.
         findall(V2,
             (nth0(C, Row, V),
% Paint this cell if it is in the target cell set.
              (memberchk(r(R,C), Cells) -> V2 = Color ; V2 = V)),
             Row2)),
        Grid2).

% cv_erase_cells_(+Grid, +Cells, +Bg, -Grid2): single-pass erasing.
% Cells in Cells are set to Bg; all other cells are unchanged.
cv_erase_cells_(Grid, Cells, Bg, Grid2) :-
% Rebuild each row.
    findall(Row2,
% Enumerate rows by index.
        (nth0(R, Grid, Row),
% Rebuild each cell in the row.
         findall(V2,
             (nth0(C, Row, V),
% Erase this cell if it is in the target cell set.
              (memberchk(r(R,C), Cells) -> V2 = Bg ; V2 = V)),
             Row2)),
        Grid2).

% ============================================================
% PUBLIC PREDICATES
% ============================================================

% cv_blank(+H, +W, +Bg, -Grid): create an H x W grid filled with Bg.
% Grid is represented as a list of H lists each of length W.
cv_blank(H, W, Bg, Grid) :-
% Compute upper bounds for between/3.
    H1 is H - 1,
    W1 is W - 1,
% Build H rows, each a W-element list of Bg.
    findall(Row,
        (between(0, H1, _),
         findall(Bg, between(0, W1, _), Row)),
        Grid).

% cv_size(+Grid, -H, -W): return the height H and width W of a grid.
cv_size(Grid, H, W) :-
% Delegate to private helper.
    cv_dims_(Grid, H, W).

% cv_paint(+Grid, +Obj, -Grid2): paint obj(Color, Cells) onto Grid.
% All cells listed in Obj are set to Color; other cells are unchanged.
cv_paint(Grid, obj(Color, Cells), Grid2) :-
% Single-pass update for all cells of this object.
    cv_paint_cells_(Grid, Cells, Color, Grid2).

% cv_paint_all(+Grid, +Objs, -Grid2): paint every obj in Objs onto Grid.
% Objects are painted in list order; later objects overwrite earlier ones.
cv_paint_all(Grid, [], Grid).
cv_paint_all(Grid, [Obj|Rest], Grid2) :-
% Paint the first object.
    cv_paint(Grid, Obj, Grid1),
% Continue with remaining objects.
    cv_paint_all(Grid1, Rest, Grid2).

% cv_paint_at(+Grid, +Obj, +DR, +DC, -Grid2): translate Obj by (DR,DC) then paint.
% Each cell r(R,C) in Obj is painted at r(R+DR, C+DC). No bounds checking.
cv_paint_at(Grid, obj(Color, Cells), DR, DC, Grid2) :-
% Compute shifted cell list.
    findall(r(R2,C2),
        (member(r(R,C), Cells),
         R2 is R + DR,
         C2 is C + DC),
        Cells2),
% Paint the shifted cells.
    cv_paint_cells_(Grid, Cells2, Color, Grid2).

% cv_paint_clip(+Grid, +Obj, -Grid2): paint Obj, silently skipping out-of-bounds cells.
% Only cells with 0 =< R < H and 0 =< C < W are painted.
cv_paint_clip(Grid, obj(Color, Cells), Grid2) :-
% Get grid dimensions for bounds checking.
    cv_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Keep only in-bounds cells.
    findall(r(R,C),
        (member(r(R,C), Cells),
         R >= 0, R =< H1,
         C >= 0, C =< W1),
        ClipCells),
% Paint the clipped cell set.
    cv_paint_cells_(Grid, ClipCells, Color, Grid2).

% cv_paint_bg(+Grid, +Obj, +Bg, -Grid2): paint Obj only onto cells currently equal to Bg.
% Cells in Obj whose current grid value is not Bg are left unchanged.
cv_paint_bg(Grid, obj(Color, Cells), Bg, Grid2) :-
% Filter to cells where the current value is Bg.
    findall(r(R,C),
        (member(r(R,C), Cells),
         nth0(R, Grid, Row),
         nth0(C, Row, Bg)),
        BgCells),
% Paint only the bg-valued cells.
    cv_paint_cells_(Grid, BgCells, Color, Grid2).

% cv_erase(+Grid, +Obj, +Bg, -Grid2): fill all cells of Obj with Bg in Grid.
cv_erase(Grid, obj(_, Cells), Bg, Grid2) :-
% Single-pass erase for all cells of this object.
    cv_erase_cells_(Grid, Cells, Bg, Grid2).

% cv_extract(+Grid, +Color, -Obj): extract all Color cells from Grid as obj(Color, Cells).
% Cells is a list of r(R,C) pairs in row-major order. Obj is empty if Color absent.
cv_extract(Grid, Color, obj(Color, Cells)) :-
% Collect all (R,C) positions where the grid value equals Color.
    findall(r(R,C),
        (nth0(R, Grid, Row),
         nth0(C, Row, Color)),
        Cells).

% cv_extract_all(+Grid, +Bg, -Objs): extract all non-Bg objects from Grid.
% Returns a list of obj(Color, Cells) terms, one per distinct non-Bg color.
% Colors are in sorted order; Cells lists are in row-major order.
cv_extract_all(Grid, Bg, Objs) :-
% Collect all non-bg (R, C, V) triples.
    findall(R-C-V,
        (nth0(R, Grid, Row),
         nth0(C, Row, V),
         V \= Bg),
        Triples),
% Find distinct colors.
    findall(V, member(_-_-V, Triples), AllColors0),
    sort(AllColors0, Colors),
% Build one obj per color.
    findall(obj(Color, Cells),
        (member(Color, Colors),
         findall(r(R,C), member(R-C-Color, Triples), Cells)),
        Objs).

% cv_render(+H, +W, +Bg, +Objs, -Grid): create a blank H x W canvas and paint Objs.
% Convenience predicate combining cv_blank/4 and cv_paint_all/3.
cv_render(H, W, Bg, Objs, Grid) :-
% Create blank canvas.
    cv_blank(H, W, Bg, Blank),
% Paint all objects onto it.
    cv_paint_all(Blank, Objs, Grid).

% cv_move(+Grid, +Obj, +DR, +DC, +Bg, -Grid2): erase Obj then repaint at offset (DR,DC).
% The object is removed from its original position and placed at (R+DR, C+DC).
cv_move(Grid, Obj, DR, DC, Bg, Grid2) :-
% Erase the object from its current position.
    cv_erase(Grid, Obj, Bg, Grid1),
% Repaint at the offset position (no clipping).
    cv_paint_at(Grid1, Obj, DR, DC, Grid2).

% cv_stamp(+Obj, +Bg, -Patch): extract Obj as a tight bounding-box grid.
% Patch is a minimal grid where Obj's cells hold Color and all other cells hold Bg.
% Patch dimensions equal the bounding-box height and width of Obj.
cv_stamp(obj(Color, Cells), Bg, Patch) :-
% Find bounding box of the object's cell set.
    findall(R, member(r(R,_), Cells), Rs),
    findall(C, member(r(_,C), Cells), Cs),
    min_list(Rs, MinR), max_list(Rs, MaxR),
    min_list(Cs, MinC), max_list(Cs, MaxC),
% Compute patch dimensions.
    H is MaxR - MinR + 1,
    W is MaxC - MinC + 1,
% Normalise cell positions to origin.
    findall(r(NR,NC),
        (member(r(R,C), Cells),
         NR is R - MinR,
         NC is C - MinC),
        NormCells),
% Build blank patch and paint the normalised cells.
    cv_blank(H, W, Bg, Blank),
    cv_paint_cells_(Blank, NormCells, Color, Patch).

% cv_blit(+Canvas, +Patch, +R0, +C0, -Grid2): paste Patch onto Canvas at top-left (R0,C0).
% Each cell Patch[r][c] overwrites Canvas[R0+r][C0+c]. No Bg transparency.
cv_blit(Canvas, Patch, R0, C0, Grid2) :-
% Get patch dimensions for bounds checking.
    cv_dims_(Patch, PH, PW),
    PH1 is PH - 1,
    PW1 is PW - 1,
% Rebuild each canvas cell.
    findall(Row2,
        (nth0(R, Canvas, Row),
         findall(V2,
             (nth0(C, Row, V),
% Compute patch coordinates for this canvas cell.
              PR is R - R0,
              PC is C - C0,
% Replace with patch value if within patch bounds, else keep canvas value.
              (PR >= 0, PR =< PH1, PC >= 0, PC =< PW1,
               nth0(PR, Patch, PRow),
               nth0(PC, PRow, PV) ->
                  V2 = PV
              ;
                  V2 = V)),
             Row2)),
        Grid2).
