:- module(gridblend, [
    gridblend_overlay/4,
    gridblend_underlay/4,
    gridblend_stencil/4,
    gridblend_priority/3,
    gridblend_checker_blend/5,
    gridblend_stripe_blend/5,
    gridblend_threshold_replace/5,
    gridblend_merge_many/3,
    gridblend_dominant/3,
    gridblend_composite/4
]).
% gridblend.pl - Layer 235: Grid Blending and Layered Composition (gbld_* prefix).
% Ten predicates for overlaying, underlaying, stencil masking, priority reduction,
% checkerboard and stripe blending, threshold replacement, multi-grid merging,
% dominant-color voting, and mode-dispatched composite reduction.
% All operations treat one color (BgColor) as transparent/absent.
% No cross-pack dependencies.
:- use_module(library(lists), [member/2, nth0/3]).

% --- PRIVATE HELPERS ---

% gridblend_overlay_rows_/4: Top over Bottom row by row.
% Non-bg cells in Top win; bg cells reveal Bottom.
gridblend_overlay_rows_([], [], _, []).
gridblend_overlay_rows_([R1|T1], [R2|T2], Bg, [NR|Rest]) :-
    gridblend_overlay_cells_(R1, R2, Bg, NR),
    gridblend_overlay_rows_(T1, T2, Bg, Rest).

% gridblend_overlay_cells_/4: cell-level overlay.
gridblend_overlay_cells_([], [], _, []).
gridblend_overlay_cells_([V1|T1], [V2|T2], Bg, [V|Vs]) :-
% Top wins when non-bg; else Bottom's value shows.
    (V1 \= Bg -> V = V1 ; V = V2),
    gridblend_overlay_cells_(T1, T2, Bg, Vs).

% gridblend_underlay_rows_/4: Bottom over Top row by row.
% Non-bg cells in Bottom win; bg cells reveal Top.
gridblend_underlay_rows_([], [], _, []).
gridblend_underlay_rows_([R1|T1], [R2|T2], Bg, [NR|Rest]) :-
    gridblend_underlay_cells_(R1, R2, Bg, NR),
    gridblend_underlay_rows_(T1, T2, Bg, Rest).

% gridblend_underlay_cells_/4: cell-level underlay.
gridblend_underlay_cells_([], [], _, []).
gridblend_underlay_cells_([V1|T1], [V2|T2], Bg, [V|Vs]) :-
% Bottom wins when non-bg; else Top's value shows.
    (V2 \= Bg -> V = V2 ; V = V1),
    gridblend_underlay_cells_(T1, T2, Bg, Vs).

% gridblend_stencil_rows_/4: keep Source only at stencil-match positions.
gridblend_stencil_rows_([], [], _, []).
gridblend_stencil_rows_([SR|ST], [MR|MT], SC, [NR|Rest]) :-
    gridblend_stencil_cells_(SR, MR, SC, NR),
    gridblend_stencil_rows_(ST, MT, SC, Rest).

% gridblend_stencil_cells_/4: pass source cell through when mask = SC; else SC.
gridblend_stencil_cells_([], [], _, []).
gridblend_stencil_cells_([SV|ST], [MV|MT], SC, [V|Vs]) :-
% Keep source where mask = StencilColor; use StencilColor as the "erase" value.
    (MV = SC -> V = SV ; V = SC),
    gridblend_stencil_cells_(ST, MT, SC, Vs).

% gridblend_checker_rows_/6: blend by checkerboard parity (R+C) mod 2.
% BgColor is passed through for API consistency but not used in cell selection.
gridblend_checker_rows_([], [], _, _, _, []).
gridblend_checker_rows_([R1|T1], [R2|T2], Bg, Parity, RowIdx, [NR|Rest]) :-
    length(R1, W), W1 is W - 1,
    findall(V,
        (between(0, W1, C),
         nth0(C, R1, A), nth0(C, R2, B),
         Chk is (RowIdx + C) mod 2,
         (Chk =:= Parity -> V = A ; V = B)),
        NR),
    NextRow is RowIdx + 1,
    gridblend_checker_rows_(T1, T2, Bg, Parity, NextRow, Rest).

% gridblend_stripe_rows_/5: blend by horizontal row stripes.
gridblend_stripe_rows_([], [], _, _, _, []).
gridblend_stripe_rows_([R1|T1], [R2|T2], StripeW, Bg, RowIdx, [NR|Rest]) :-
    Stripe is (RowIdx // StripeW) mod 2,
    gridblend_overlay_cells_(R1, R2, Bg, Over12),
    gridblend_overlay_cells_(R2, R1, Bg, Over21),
% Even stripe: Grid1 on top of Grid2; odd stripe: Grid2 on top of Grid1.
    (Stripe =:= 0 -> NR = Over12 ; NR = Over21),
    NextRow is RowIdx + 1,
    gridblend_stripe_rows_(T1, T2, StripeW, Bg, NextRow, Rest).

% gridblend_mode_/2: find the most frequent value in a non-empty list.
% Uses msort to group equal values; scans for the longest run.
gridblend_mode_([], none).
gridblend_mode_([H|T], Mode) :-
    msort([H|T], Sorted),
    gridblend_best_run_(Sorted, H, 1, H, 1, Mode).

% gridblend_best_run_/6: (Remaining, CurVal, CurLen, BestVal, BestLen, Mode).
gridblend_best_run_([], Cur, CurLen, Best, BestLen, Mode) :-
    (CurLen > BestLen -> Mode = Cur ; Mode = Best).
gridblend_best_run_([H|T], Cur, CurLen, Best, BestLen, Mode) :-
    (H = Cur ->
        NewLen is CurLen + 1,
        (NewLen > BestLen ->
            gridblend_best_run_(T, H, NewLen, H, NewLen, Mode)
        ;
            gridblend_best_run_(T, H, NewLen, Best, BestLen, Mode)
        )
    ;
        (CurLen > BestLen ->
            gridblend_best_run_(T, H, 1, Cur, CurLen, Mode)
        ;
            gridblend_best_run_(T, H, 1, Best, BestLen, Mode)
        )
    ).

% gridblend_nonbg_/2: helper for include/3 to filter non-bg cells.
gridblend_nonbg_(Bg, V) :- V \= Bg.

% --- PUBLIC PREDICATES ---

% gridblend_overlay(+Top, +Bottom, +BgColor, -Result)
% Place Top over Bottom. Non-bg cells in Top always show; bg cells in Top
% are transparent and reveal the corresponding cell from Bottom.
gridblend_overlay(Top, Bottom, Bg, Result) :-
    gridblend_overlay_rows_(Top, Bottom, Bg, Result).

% gridblend_underlay(+Top, +Bottom, +BgColor, -Result)
% Place Top under Bottom. Non-bg cells in Bottom always show; bg cells in
% Bottom are transparent and reveal the corresponding cell from Top.
gridblend_underlay(Top, Bottom, Bg, Result) :-
    gridblend_underlay_rows_(Top, Bottom, Bg, Result).

% gridblend_stencil(+Source, +Stencil, +StencilColor, -Result)
% Keep Source's cell value only at positions where Stencil = StencilColor.
% Positions where Stencil /= StencilColor become StencilColor in Result.
% (StencilColor acts as both the selection trigger and the "erased" fill value.)
gridblend_stencil(Source, Stencil, SC, Result) :-
    gridblend_stencil_rows_(Source, Stencil, SC, Result).

% gridblend_priority(+Grids, +BgColor, -Result)
% Reduce a list of grids with priority layering: the first grid is topmost.
% At each position, the first non-bg value encountered wins.
gridblend_priority([], _, []).
gridblend_priority([G], _, G) :- !.
gridblend_priority([G1|Rest], Bg, Result) :-
    gridblend_priority(Rest, Bg, RRest),
    gridblend_overlay(G1, RRest, Bg, Result).

% gridblend_checker_blend(+Grid1, +Grid2, +BgColor, +Parity, -Result)
% Blend two grids using checkerboard position parity.
% Positions where (R+C) mod 2 = Parity take from Grid1; all others from Grid2.
% Parity must be 0 or 1.
gridblend_checker_blend(Grid1, Grid2, Bg, Parity, Result) :-
    gridblend_checker_rows_(Grid1, Grid2, Bg, Parity, 0, Result).

% gridblend_stripe_blend(+Grid1, +Grid2, +BgColor, +StripeWidth, -Result)
% Blend two grids using horizontal row stripes of StripeWidth rows each.
% Even-numbered stripe bands (0, 2, 4, ...) use Grid1; odd bands use Grid2.
% Within each band, Grid1/Grid2 is overlaid on the other (non-bg wins).
gridblend_stripe_blend(Grid1, Grid2, Bg, StripeW, Result) :-
    gridblend_stripe_rows_(Grid1, Grid2, StripeW, Bg, 0, Result).

% gridblend_threshold_replace(+Grid, +Threshold, +ReplaceColor, +BgColor, -Result)
% For each row in Grid: count non-bg cells.
% If count >= Threshold, replace every non-bg cell in that row with ReplaceColor.
% If count < Threshold, the row is unchanged.
gridblend_threshold_replace(Grid, Threshold, RC, Bg, Result) :-
    findall(NR,
        (member(Row, Grid),
         include(gridblend_nonbg_(Bg), Row, NonBg),
         length(NonBg, Count),
         (Count >= Threshold ->
             findall(V, (member(C, Row), (C \= Bg -> V = RC ; V = Bg)), NR)
         ;
             NR = Row
         )),
        Result).

% gridblend_merge_many(+Grids, +BgColor, -Result)
% Reduce a list of grids by accumulating from bottom to top.
% The first grid in the list is the bottom layer; the last is on top.
% Equivalent to left-fold: earlier grids form the base, later ones overlay.
gridblend_merge_many([], _, []).
gridblend_merge_many([G], _, G) :- !.
gridblend_merge_many(Grids, Bg, Result) :-
    Grids = [_|_],
    last(Grids, Last),
    length(Grids, N), N1 is N - 1,
    length(Rest, N1), append(Rest, [Last], Grids),
    gridblend_merge_many(Rest, Bg, RRest),
    gridblend_overlay(Last, RRest, Bg, Result).

% gridblend_dominant(+Grids, +BgColor, -Result)
% At each cell position, take the most frequent non-bg value across all grids.
% Ties are broken by the sort order of msort (deterministic).
% Positions where all grids are bg → bg.
gridblend_dominant([], _, []).
gridblend_dominant([G], _, G) :- !.
gridblend_dominant(Grids, Bg, Result) :-
    Grids = [G1|_],
    length(G1, H), H1 is H - 1,
    G1 = [R1|_], length(R1, W), W1 is W - 1,
    findall(NRow,
        (between(0, H1, R),
         findall(V,
             (between(0, W1, C),
              findall(Val, (member(G, Grids), nth0(R, G, GRow), nth0(C, GRow, Val), Val \= Bg), Vals),
              (Vals = [] -> V = Bg ; gridblend_mode_(Vals, Mode), (Mode = none -> V = Bg ; V = Mode))),
             NRow)),
        Result).

% gridblend_composite(+Grids, +BgColor, +Mode, -Result)
% Reduce a list of grids to one according to Mode:
%   overlay   - first grid is topmost (priority layering)
%   underlay  - last grid is topmost (merge_many: first is base)
%   dominant  - most frequent non-bg value per cell
gridblend_composite(Grids, Bg, overlay, Result) :- !,
    gridblend_priority(Grids, Bg, Result).
gridblend_composite(Grids, Bg, underlay, Result) :- !,
    gridblend_merge_many(Grids, Bg, Result).
gridblend_composite(Grids, Bg, dominant, Result) :- !,
    gridblend_dominant(Grids, Bg, Result).
