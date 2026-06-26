% mask.pl - Layer 122: Boolean Mask Operations on 2D Grids (mk_* prefix).
% General-purpose predicates for creating, combining, and applying binary masks.
:- module(mask, [
    mk_from_val/3, mk_from_bg/3,
    mk_invert/2,
    mk_and/3, mk_or/3, mk_xor/3,
    mk_apply/4, mk_fill/4, mk_overlay/4,
    mk_where/2, mk_count/2,
    mk_any/1, mk_all/1,
    mk_extract/3
]).
% Import higher-order iteration needed for element-wise grid operations.
:- use_module(library(apply), [maplist/3, maplist/4, maplist/5]).
% Import list utilities for fallback queries.
:- use_module(library(lists), [member/2, nth0/3]).

% mk_from_val(+Grid, +V, -Mask): Mask[R][C] = 1 where Grid[R][C] = V, else 0.
mk_from_val(Grid, V, Mask) :-
% Apply per-row then per-cell conversion using nested maplist.
    maplist(mk_from_val_row_(V), Grid, Mask).
% Per-row helper for mk_from_val.
mk_from_val_row_(V, Row, MRow) :-
% Map each cell to 1 if it matches V, 0 otherwise.
    maplist(mk_from_val_cell_(V), Row, MRow).
% Per-cell helper: exact match gives 1, cut prevents fallthrough.
mk_from_val_cell_(V, V, 1) :- !.
% Non-matching cell gives 0.
mk_from_val_cell_(_, _, 0).

% mk_from_bg(+Grid, +Bg, -Mask): Mask[R][C] = 0 where Grid[R][C] = Bg, else 1.
mk_from_bg(Grid, Bg, Mask) :-
% Apply per-row then per-cell conversion; background becomes 0, others become 1.
    maplist(mk_from_bg_row_(Bg), Grid, Mask).
% Per-row helper for mk_from_bg.
mk_from_bg_row_(Bg, Row, MRow) :-
% Map each cell to 0 for background, 1 for non-background.
    maplist(mk_from_bg_cell_(Bg), Row, MRow).
% Background cell gives 0, cut prevents fallthrough.
mk_from_bg_cell_(Bg, Bg, 0) :- !.
% Non-background cell gives 1.
mk_from_bg_cell_(_, _, 1).

% mk_invert(+Mask, -Mask2): flip every bit: 1->0, 0->1.
mk_invert(Mask, Mask2) :-
% Apply per-row inversion.
    maplist(mk_invert_row_, Mask, Mask2).
% Per-row helper for mk_invert.
mk_invert_row_(Row, Row2) :-
% Flip each bit in the row.
    maplist(mk_invert_bit_, Row, Row2).
% 1 becomes 0, cut prevents fallthrough.
mk_invert_bit_(1, 0) :- !.
% Any other value (including 0) becomes 1.
mk_invert_bit_(_, 1).

% mk_and(+MaskA, +MaskB, -MaskC): MaskC[R][C] = 1 iff both A and B are 1.
mk_and(MaskA, MaskB, MaskC) :-
% Apply row-wise AND across paired rows.
    maplist(mk_and_row_, MaskA, MaskB, MaskC).
% Per-row AND using maplist/4 over three parallel rows.
mk_and_row_(RA, RB, RC) :-
    maplist(mk_and_bit_, RA, RB, RC).
% Both bits 1 gives 1, cut prevents fallthrough.
mk_and_bit_(1, 1, 1) :- !.
% Any other combination gives 0.
mk_and_bit_(_, _, 0).

% mk_or(+MaskA, +MaskB, -MaskC): MaskC[R][C] = 1 iff at least one of A, B is 1.
mk_or(MaskA, MaskB, MaskC) :-
% Apply row-wise OR across paired rows.
    maplist(mk_or_row_, MaskA, MaskB, MaskC).
% Per-row OR.
mk_or_row_(RA, RB, RC) :-
    maplist(mk_or_bit_, RA, RB, RC).
% Both bits 0 gives 0, cut prevents fallthrough.
mk_or_bit_(0, 0, 0) :- !.
% Any other combination (at least one 1) gives 1.
mk_or_bit_(_, _, 1).

% mk_xor(+MaskA, +MaskB, -MaskC): MaskC[R][C] = 1 iff exactly one of A, B is 1.
mk_xor(MaskA, MaskB, MaskC) :-
% Apply row-wise XOR across paired rows.
    maplist(mk_xor_row_, MaskA, MaskB, MaskC).
% Per-row XOR.
mk_xor_row_(RA, RB, RC) :-
    maplist(mk_xor_bit_, RA, RB, RC).
% XOR via arithmetic modulo 2; works for any integer A and B values.
mk_xor_bit_(A, B, C) :- C is (A + B) mod 2.

% mk_apply(+Grid, +Mask, +Bg, -Grid2): keep Grid[R][C] where Mask=1; else Bg.
mk_apply(Grid, Mask, Bg, Grid2) :-
% Apply row-wise: paired rows of Grid and Mask produce output rows.
    maplist(mk_apply_row_(Bg), Grid, Mask, Grid2).
% Per-row apply.
mk_apply_row_(Bg, Row, MRow, Row2) :-
    maplist(mk_apply_cell_(Bg), Row, MRow, Row2).
% Mask bit 1 keeps the original value, cut prevents fallthrough.
mk_apply_cell_(_, V, 1, V) :- !.
% Mask bit 0 replaces with background.
mk_apply_cell_(Bg, _, 0, Bg).

% mk_fill(+Grid, +Mask, +V, -Grid2): replace Grid[R][C] with V where Mask=1.
mk_fill(Grid, Mask, V, Grid2) :-
% Apply row-wise fill.
    maplist(mk_fill_row_(V), Grid, Mask, Grid2).
% Per-row fill.
mk_fill_row_(V, Row, MRow, Row2) :-
    maplist(mk_fill_cell_(V), Row, MRow, Row2).
% Mask bit 1 overwrites with V, cut prevents fallthrough.
mk_fill_cell_(V, _, 1, V) :- !.
% Mask bit 0 keeps the original cell value.
mk_fill_cell_(_, C, 0, C).

% mk_overlay(+GridA, +GridB, +Mask, -Grid2): GridB where Mask=1, GridA where Mask=0.
mk_overlay(GridA, GridB, Mask, Grid2) :-
% Combine rows from GridA, GridB, and Mask in parallel.
    maplist(mk_overlay_row_, GridA, GridB, Mask, Grid2).
% Per-row overlay; maplist/5 iterates four parallel lists.
mk_overlay_row_(RA, RB, RM, RC) :-
    maplist(mk_overlay_cell_, RA, RB, RM, RC).
% Mask bit 1 selects from GridB, cut prevents fallthrough.
mk_overlay_cell_(_, VB, 1, VB) :- !.
% Mask bit 0 selects from GridA.
mk_overlay_cell_(VA, _, 0, VA).

% mk_where(+Mask, -Cells): sorted R-C pairs of positions where Mask=1.
mk_where(Mask, Cells) :-
% Enumerate all positions; keep those where the mask bit is 1.
    length(Mask, H), H1 is H - 1,
    (Mask = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(R-C, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Mask, MRow), nth0(C, MRow, 1)
    ), Unsorted),
    sort(Unsorted, Cells).

% mk_count(+Mask, -N): count of 1-valued cells in Mask.
mk_count(Mask, N) :-
% Collect one witness per 1-cell then measure length.
    findall(_, (member(Row, Mask), member(1, Row)), Ks),
    length(Ks, N).

% mk_any(+Mask): succeeds iff at least one cell in Mask is 1.
mk_any(Mask) :-
% member/2 tries each row; member/2 on the row tries each cell.
% Cut on first 1 found.
    member(Row, Mask), member(1, Row), !.

% mk_all(+Mask): succeeds iff every cell in Mask is 1.
mk_all(Mask) :-
% forall/2 is a built-in; B =:= 1 requires the cell to be the integer 1.
    forall(member(Row, Mask), forall(member(B, Row), B =:= 1)).

% mk_extract(+Grid, +Mask, -Vals): sorted unique values from Grid at Mask=1 positions.
mk_extract(Grid, Mask, Vals) :-
% Collect Grid values at positions where the corresponding Mask cell is 1.
    length(Grid, H), H1 is H - 1,
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    findall(V, (
        between(0, H1, R), between(0, W1, C),
        nth0(R, Grid, Row), nth0(C, Row, V),
        nth0(R, Mask, MRow), nth0(C, MRow, 1)
    ), Unsorted),
    sort(Unsorted, Vals).
