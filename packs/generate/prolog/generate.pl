% Module declaration: generate pack, Layer 62.
:- module(generate, [
    % ge_uniform/4: create a Rows x Cols grid filled with a single color.
    ge_uniform/4,
    % ge_gradient_h/4: horizontal gradient: column C gets color C (mod Colors).
    ge_gradient_h/4,
    % ge_gradient_v/4: vertical gradient: row R gets color R (mod Colors).
    ge_gradient_v/4,
    % ge_checkerboard/5: checkerboard pattern alternating two colors.
    ge_checkerboard/5,
    % ge_stripes_h/4: horizontal stripes repeating a list of colors.
    ge_stripes_h/4,
    % ge_stripes_v/4: vertical stripes repeating a list of colors.
    ge_stripes_v/4,
    % ge_border_rect/5: rectangle filled with one color, interior another.
    ge_border_rect/5,
    % ge_diagonal/4: main diagonal cells get DiagColor, others get BG.
    ge_diagonal/4,
    % ge_antidiagonal/4: anti-diagonal cells get DiagColor, others get BG.
    ge_antidiagonal/4,
    % ge_frame/5: only the outermost ring gets FrameColor, interior BG.
    ge_frame/5,
    % ge_cross/5: row and column through center get CrossColor, others BG.
    ge_cross/5,
    % ge_identity_grid/3: N x N grid; diagonal=1, off-diagonal=0.
    ge_identity_grid/3,
    % ge_from_map/3: build a grid from a list of r(R,C)-Color pairs.
    ge_from_map/3,
    % ge_repeat_pattern/4: tile a pattern grid to fill Rows x Cols.
    ge_repeat_pattern/4
]).

% Import list and apply utilities.
:- use_module(library(lists),  [member/2, nth0/3, numlist/3]).
:- use_module(library(apply),  [maplist/2, maplist/3]).

% ge_uniform(+Rows, +Cols, +Color, -Grid): fill a Rows x Cols grid with Color.
ge_uniform(Rows, Cols, Color, Grid) :-
    % Build a single row of Cols copies of Color.
    length(Row, Cols), maplist(=(Color), Row),
    % Repeat for Rows rows.
    length(Grid, Rows), maplist(=(Row), Grid).

% ge_gradient_h(+Rows, +Cols, +NColors, -Grid): column C gets color C mod NColors.
ge_gradient_h(Rows, Cols, NColors, Grid) :-
    % Build one gradient row.
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(ge_col_mod_(NColors), ColIds, GradRow),
    % Same row for every row.
    length(Grid, Rows), maplist(=(GradRow), Grid).

% ge_col_mod_(+NColors, +C, -Color): color for column C.
ge_col_mod_(NColors, C, Color) :-
    Color is C mod NColors.

% ge_gradient_v(+Rows, +Cols, +NColors, -Grid): row R gets color R mod NColors.
ge_gradient_v(Rows, Cols, NColors, Grid) :-
    % Build each row independently based on its index.
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    maplist(ge_row_uniform_(Cols, NColors), RowIds, Grid).

% ge_row_uniform_(+Cols, +NColors, +R, -Row): uniform row with color R mod NColors.
ge_row_uniform_(Cols, NColors, R, Row) :-
    Color is R mod NColors,
    length(Row, Cols), maplist(=(Color), Row).

% ge_checkerboard(+Rows, +Cols, +C0, +C1, -Grid): alternating C0 and C1.
ge_checkerboard(Rows, Cols, C0, C1, Grid) :-
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1e is Cols - 1, numlist(0, C1e, ColIds) ; ColIds = [] ),
    maplist(ge_checker_row_(ColIds, C0, C1), RowIds, Grid).

% ge_checker_row_(+ColIds, +C0, +C1, +R, -Row): one checker row.
ge_checker_row_(ColIds, C0, C1, R, Row) :-
    maplist(ge_checker_cell_(R, C0, C1), ColIds, Row).

% ge_checker_cell_(+R, +C0, +C1, +C, -Color): checker cell color.
ge_checker_cell_(R, C0, C1, C, Color) :-
    ( (R + C) mod 2 =:= 0 -> Color = C0 ; Color = C1 ).

% ge_stripes_h(+Rows, +Cols, +Colors, -Grid): horizontal stripes cycling Colors.
ge_stripes_h(Rows, Cols, Colors, Grid) :-
    % Row R gets Colors[R mod len(Colors)].
    length(Colors, NC),
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    maplist(ge_stripe_h_row_(Cols, Colors, NC), RowIds, Grid).

% ge_stripe_h_row_(+Cols, +Colors, +NC, +R, -Row): one horizontal stripe row.
ge_stripe_h_row_(Cols, Colors, NC, R, Row) :-
    Idx is R mod NC,
    nth0(Idx, Colors, Color),
    length(Row, Cols), maplist(=(Color), Row).

% ge_stripes_v(+Rows, +Cols, +Colors, -Grid): vertical stripes cycling Colors.
ge_stripes_v(Rows, Cols, Colors, Grid) :-
    % Column C gets Colors[C mod len(Colors)].
    length(Colors, NC),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(ge_col_color_(Colors, NC), ColIds, StripeRow),
    % All rows are the same stripe row.
    length(Grid, Rows), maplist(=(StripeRow), Grid).

% ge_col_color_(+Colors, +NC, +C, -Color): color for column C.
ge_col_color_(Colors, NC, C, Color) :-
    Idx is C mod NC,
    nth0(Idx, Colors, Color).

% ge_border_rect(+Rows, +Cols, +BorderColor, +FillColor, -Grid): border+fill rect.
ge_border_rect(Rows, Cols, BorderColor, FillColor, Grid) :-
    MaxR is Rows - 1, MaxC is Cols - 1,
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(ge_border_row_(ColIds, BorderColor, FillColor, MaxR, MaxC), RowIds, Grid).

% ge_border_row_(+ColIds, +BC, +FC, +MaxR, +MaxC, +R, -Row): one border row.
ge_border_row_(ColIds, BC, FC, MaxR, MaxC, R, Row) :-
    maplist(ge_border_cell_(R, BC, FC, MaxR, MaxC), ColIds, Row).

% ge_border_cell_(+R, +BC, +FC, +MaxR, +MaxC, +C, -Color): border or fill.
ge_border_cell_(R, BC, _FC, MaxR, MaxC, C, BC) :-
    ( R =:= 0 ; R =:= MaxR ; C =:= 0 ; C =:= MaxC ), !.
ge_border_cell_(_R, _BC, FC, _MaxR, _MaxC, _C, FC).

% ge_diagonal(+Rows, +Cols, +DiagColor, -Grid): main diagonal vs BG.
% BG is always 0 in this pack for simplicity.
ge_diagonal(Rows, Cols, DiagColor, Grid) :-
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(ge_diag_row_(ColIds, DiagColor), RowIds, Grid).

% ge_diag_row_(+ColIds, +DiagColor, +R, -Row): one diagonal row.
ge_diag_row_(ColIds, DiagColor, R, Row) :-
    maplist(ge_diag_cell_(R, DiagColor), ColIds, Row).

% ge_diag_cell_(+R, +DiagColor, +C, -Color): on main diagonal?
ge_diag_cell_(R, DiagColor, C, DiagColor) :- R =:= C, !.
ge_diag_cell_(_R, _DiagColor, _C, 0).

% ge_antidiagonal(+Rows, +Cols, +DiagColor, -Grid): anti-diagonal.
ge_antidiagonal(Rows, Cols, DiagColor, Grid) :-
    MaxC is Cols - 1,
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(ge_antidiag_row_(ColIds, DiagColor, MaxC), RowIds, Grid).

% ge_antidiag_row_(+ColIds, +DiagColor, +MaxC, +R, -Row): one anti-diagonal row.
ge_antidiag_row_(ColIds, DiagColor, MaxC, R, Row) :-
    maplist(ge_antidiag_cell_(R, DiagColor, MaxC), ColIds, Row).

% ge_antidiag_cell_(+R, +DiagColor, +MaxC, +C, -Color): on anti-diagonal?
ge_antidiag_cell_(R, DiagColor, MaxC, C, DiagColor) :- R + C =:= MaxC, !.
ge_antidiag_cell_(_R, _DiagColor, _MaxC, _C, 0).

% ge_frame(+Rows, +Cols, +FrameColor, +BG, -Grid): outermost ring only.
ge_frame(Rows, Cols, FrameColor, BG, Grid) :-
    MaxR is Rows - 1, MaxC is Cols - 1,
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(ge_frame_row_(ColIds, FrameColor, BG, MaxR, MaxC), RowIds, Grid).

% ge_frame_row_(+ColIds, +FC, +BG, +MaxR, +MaxC, +R, -Row): one frame row.
ge_frame_row_(ColIds, FC, BG, MaxR, MaxC, R, Row) :-
    maplist(ge_frame_cell_(R, FC, BG, MaxR, MaxC), ColIds, Row).

% ge_frame_cell_(+R, +FC, +BG, +MaxR, +MaxC, +C, -Color): frame or bg.
ge_frame_cell_(R, FC, _BG, MaxR, MaxC, C, FC) :-
    ( R =:= 0 ; R =:= MaxR ; C =:= 0 ; C =:= MaxC ), !.
ge_frame_cell_(_R, _FC, BG, _MaxR, _MaxC, _C, BG).

% ge_cross(+Rows, +Cols, +CrossColor, +BG, -Grid): cross through center.
ge_cross(Rows, Cols, CrossColor, BG, Grid) :-
    MidR is Rows // 2, MidC is Cols // 2,
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(ge_cross_row_(ColIds, CrossColor, BG, MidR, MidC), RowIds, Grid).

% ge_cross_row_(+ColIds, +CC, +BG, +MidR, +MidC, +R, -Row): one cross row.
ge_cross_row_(ColIds, CC, BG, MidR, MidC, R, Row) :-
    maplist(ge_cross_cell_(R, CC, BG, MidR, MidC), ColIds, Row).

% ge_cross_cell_(+R, +CC, +BG, +MidR, +MidC, +C, -Color): on cross?
ge_cross_cell_(R, CC, _BG, MidR, _MidC, _C, CC) :- R =:= MidR, !.
ge_cross_cell_(_R, CC, _BG, _MidR, MidC, C, CC) :- C =:= MidC, !.
ge_cross_cell_(_R, _CC, BG, _MidR, _MidC, _C, BG).

% ge_identity_grid(+N, +One, -Grid): N x N grid; diagonal=One, off-diag=0.
ge_identity_grid(N, One, Grid) :-
    ge_diagonal(N, N, One, Grid).

% ge_from_map(+RowsCols, +Map, -Grid): build grid from r(R,C)-Color pairs.
% RowsCols = Rows-Cols. Default color is 0.
ge_from_map(Rows-Cols, Map, Grid) :-
    % Start with all-zero grid.
    ge_uniform(Rows, Cols, 0, Zero),
    % Set each cell from the map.
    foldl_map_(Map, Zero, Grid).

% foldl_map_(+Map, +G, -G2): set each r(R,C)-Color pair in G.
foldl_map_([], G, G).
foldl_map_([r(R,C)-Color|Rest], G, G2) :-
    ge_set_cell_(G, r(R,C), Color, G1),
    foldl_map_(Rest, G1, G2).

% ge_set_cell_(+Grid, +r(R,C), +V, -Result): set one cell.
ge_set_cell_(Grid, r(R,C), V, Result) :-
    length(Pre, R),
    append(Pre, [OldRow|Suf], Grid),
    length(PreC, C),
    append(PreC, [_|SufC], OldRow),
    append(PreC, [V|SufC], NewRow),
    append(Pre, [NewRow|Suf], Result).

% ge_repeat_pattern(+Pattern, +Rows, +Cols, -Grid): tile Pattern to Rows x Cols.
ge_repeat_pattern(Pattern, Rows, Cols, Grid) :-
    % Determine pattern dimensions.
    length(Pattern, PRows), Pattern = [PRow0|_], length(PRow0, PCols),
    % Build each output row.
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    maplist(ge_pattern_row_(Pattern, PRows, PCols, Cols), RowIds, Grid).

% ge_pattern_row_(+Pattern, +PRows, +PCols, +Cols, +R, -Row): one tiled row.
ge_pattern_row_(Pattern, PRows, PCols, Cols, R, Row) :-
    % Which pattern row to use.
    PR is R mod PRows,
    nth0(PR, Pattern, PRow),
    % Build the output row by cycling the pattern row.
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(ge_pattern_cell_(PRow, PCols), ColIds, Row).

% ge_pattern_cell_(+PRow, +PCols, +C, -Color): tiled column value.
ge_pattern_cell_(PRow, PCols, C, Color) :-
    PC is C mod PCols,
    nth0(PC, PRow, Color).
