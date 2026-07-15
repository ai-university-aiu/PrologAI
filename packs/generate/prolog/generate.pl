% Module declaration: generate pack, Layer 62.
:- module(generate, [
    % generate_uniform/4: create a Rows x Cols grid filled with a single color.
    generate_uniform/4,
    % generate_gradient_h/4: horizontal gradient: column C gets color C (mod Colors).
    generate_gradient_h/4,
    % generate_gradient_v/4: vertical gradient: row R gets color R (mod Colors).
    generate_gradient_v/4,
    % generate_checkerboard/5: checkerboard pattern alternating two colors.
    generate_checkerboard/5,
    % generate_stripes_h/4: horizontal stripes repeating a list of colors.
    generate_stripes_h/4,
    % generate_stripes_v/4: vertical stripes repeating a list of colors.
    generate_stripes_v/4,
    % generate_border_rect/5: rectangle filled with one color, interior another.
    generate_border_rect/5,
    % generate_diagonal/4: main diagonal cells get DiagColor, others get BG.
    generate_diagonal/4,
    % generate_antidiagonal/4: anti-diagonal cells get DiagColor, others get BG.
    generate_antidiagonal/4,
    % generate_frame/5: only the outermost ring gets FrameColor, interior BG.
    generate_frame/5,
    % generate_cross/5: row and column through center get CrossColor, others BG.
    generate_cross/5,
    % generate_identity_grid/3: N x N grid; diagonal=1, off-diagonal=0.
    generate_identity_grid/3,
    % generate_from_map/3: build a grid from a list of r(R,C)-Color pairs.
    generate_from_map/3,
    % generate_repeat_pattern/4: tile a pattern grid to fill Rows x Cols.
    generate_repeat_pattern/4
]).

% Import list and apply utilities.
:- use_module(library(lists),  [member/2, nth0/3, numlist/3]).
:- use_module(library(apply),  [maplist/2, maplist/3]).

% generate_uniform(+Rows, +Cols, +Color, -Grid): fill a Rows x Cols grid with Color.
generate_uniform(Rows, Cols, Color, Grid) :-
    % Build a single row of Cols copies of Color.
    length(Row, Cols), maplist(=(Color), Row),
    % Repeat for Rows rows.
    length(Grid, Rows), maplist(=(Row), Grid).

% generate_gradient_h(+Rows, +Cols, +NColors, -Grid): column C gets color C mod NColors.
generate_gradient_h(Rows, Cols, NColors, Grid) :-
    % Build one gradient row.
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(generate_col_mod_(NColors), ColIds, GradRow),
    % Same row for every row.
    length(Grid, Rows), maplist(=(GradRow), Grid).

% generate_col_mod_(+NColors, +C, -Color): color for column C.
generate_col_mod_(NColors, C, Color) :-
    Color is C mod NColors.

% generate_gradient_v(+Rows, +Cols, +NColors, -Grid): row R gets color R mod NColors.
generate_gradient_v(Rows, Cols, NColors, Grid) :-
    % Build each row independently based on its index.
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    maplist(generate_row_uniform_(Cols, NColors), RowIds, Grid).

% generate_row_uniform_(+Cols, +NColors, +R, -Row): uniform row with color R mod NColors.
generate_row_uniform_(Cols, NColors, R, Row) :-
    Color is R mod NColors,
    length(Row, Cols), maplist(=(Color), Row).

% generate_checkerboard(+Rows, +Cols, +C0, +C1, -Grid): alternating C0 and C1.
generate_checkerboard(Rows, Cols, C0, C1, Grid) :-
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1e is Cols - 1, numlist(0, C1e, ColIds) ; ColIds = [] ),
    maplist(generate_checker_row_(ColIds, C0, C1), RowIds, Grid).

% generate_checker_row_(+ColIds, +C0, +C1, +R, -Row): one checker row.
generate_checker_row_(ColIds, C0, C1, R, Row) :-
    maplist(generate_checker_cell_(R, C0, C1), ColIds, Row).

% generate_checker_cell_(+R, +C0, +C1, +C, -Color): checker cell color.
generate_checker_cell_(R, C0, C1, C, Color) :-
    ( (R + C) mod 2 =:= 0 -> Color = C0 ; Color = C1 ).

% generate_stripes_h(+Rows, +Cols, +Colors, -Grid): horizontal stripes cycling Colors.
generate_stripes_h(Rows, Cols, Colors, Grid) :-
    % Row R gets Colors[R mod len(Colors)].
    length(Colors, NC),
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    maplist(generate_stripe_h_row_(Cols, Colors, NC), RowIds, Grid).

% generate_stripe_h_row_(+Cols, +Colors, +NC, +R, -Row): one horizontal stripe row.
generate_stripe_h_row_(Cols, Colors, NC, R, Row) :-
    Idx is R mod NC,
    nth0(Idx, Colors, Color),
    length(Row, Cols), maplist(=(Color), Row).

% generate_stripes_v(+Rows, +Cols, +Colors, -Grid): vertical stripes cycling Colors.
generate_stripes_v(Rows, Cols, Colors, Grid) :-
    % Column C gets Colors[C mod len(Colors)].
    length(Colors, NC),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(generate_col_color_(Colors, NC), ColIds, StripeRow),
    % All rows are the same stripe row.
    length(Grid, Rows), maplist(=(StripeRow), Grid).

% generate_col_color_(+Colors, +NC, +C, -Color): color for column C.
generate_col_color_(Colors, NC, C, Color) :-
    Idx is C mod NC,
    nth0(Idx, Colors, Color).

% generate_border_rect(+Rows, +Cols, +BorderColor, +FillColor, -Grid): border+fill rect.
generate_border_rect(Rows, Cols, BorderColor, FillColor, Grid) :-
    MaxR is Rows - 1, MaxC is Cols - 1,
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(generate_border_row_(ColIds, BorderColor, FillColor, MaxR, MaxC), RowIds, Grid).

% generate_border_row_(+ColIds, +BC, +FC, +MaxR, +MaxC, +R, -Row): one border row.
generate_border_row_(ColIds, BC, FC, MaxR, MaxC, R, Row) :-
    maplist(generate_border_cell_(R, BC, FC, MaxR, MaxC), ColIds, Row).

% generate_border_cell_(+R, +BC, +FC, +MaxR, +MaxC, +C, -Color): border or fill.
generate_border_cell_(R, BC, _FC, MaxR, MaxC, C, BC) :-
    ( R =:= 0 ; R =:= MaxR ; C =:= 0 ; C =:= MaxC ), !.
generate_border_cell_(_R, _BC, FC, _MaxR, _MaxC, _C, FC).

% generate_diagonal(+Rows, +Cols, +DiagColor, -Grid): main diagonal vs BG.
% BG is always 0 in this pack for simplicity.
generate_diagonal(Rows, Cols, DiagColor, Grid) :-
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(generate_diag_row_(ColIds, DiagColor), RowIds, Grid).

% generate_diag_row_(+ColIds, +DiagColor, +R, -Row): one diagonal row.
generate_diag_row_(ColIds, DiagColor, R, Row) :-
    maplist(generate_diag_cell_(R, DiagColor), ColIds, Row).

% generate_diag_cell_(+R, +DiagColor, +C, -Color): on main diagonal?
generate_diag_cell_(R, DiagColor, C, DiagColor) :- R =:= C, !.
generate_diag_cell_(_R, _DiagColor, _C, 0).

% generate_antidiagonal(+Rows, +Cols, +DiagColor, -Grid): anti-diagonal.
generate_antidiagonal(Rows, Cols, DiagColor, Grid) :-
    MaxC is Cols - 1,
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(generate_antidiag_row_(ColIds, DiagColor, MaxC), RowIds, Grid).

% generate_antidiag_row_(+ColIds, +DiagColor, +MaxC, +R, -Row): one anti-diagonal row.
generate_antidiag_row_(ColIds, DiagColor, MaxC, R, Row) :-
    maplist(generate_antidiag_cell_(R, DiagColor, MaxC), ColIds, Row).

% generate_antidiag_cell_(+R, +DiagColor, +MaxC, +C, -Color): on anti-diagonal?
generate_antidiag_cell_(R, DiagColor, MaxC, C, DiagColor) :- R + C =:= MaxC, !.
generate_antidiag_cell_(_R, _DiagColor, _MaxC, _C, 0).

% generate_frame(+Rows, +Cols, +FrameColor, +BG, -Grid): outermost ring only.
generate_frame(Rows, Cols, FrameColor, BG, Grid) :-
    MaxR is Rows - 1, MaxC is Cols - 1,
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(generate_frame_row_(ColIds, FrameColor, BG, MaxR, MaxC), RowIds, Grid).

% generate_frame_row_(+ColIds, +FC, +BG, +MaxR, +MaxC, +R, -Row): one frame row.
generate_frame_row_(ColIds, FC, BG, MaxR, MaxC, R, Row) :-
    maplist(generate_frame_cell_(R, FC, BG, MaxR, MaxC), ColIds, Row).

% generate_frame_cell_(+R, +FC, +BG, +MaxR, +MaxC, +C, -Color): frame or bg.
generate_frame_cell_(R, FC, _BG, MaxR, MaxC, C, FC) :-
    ( R =:= 0 ; R =:= MaxR ; C =:= 0 ; C =:= MaxC ), !.
generate_frame_cell_(_R, _FC, BG, _MaxR, _MaxC, _C, BG).

% generate_cross(+Rows, +Cols, +CrossColor, +BG, -Grid): cross through center.
generate_cross(Rows, Cols, CrossColor, BG, Grid) :-
    MidR is Rows // 2, MidC is Cols // 2,
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(generate_cross_row_(ColIds, CrossColor, BG, MidR, MidC), RowIds, Grid).

% generate_cross_row_(+ColIds, +CC, +BG, +MidR, +MidC, +R, -Row): one cross row.
generate_cross_row_(ColIds, CC, BG, MidR, MidC, R, Row) :-
    maplist(generate_cross_cell_(R, CC, BG, MidR, MidC), ColIds, Row).

% generate_cross_cell_(+R, +CC, +BG, +MidR, +MidC, +C, -Color): on cross?
generate_cross_cell_(R, CC, _BG, MidR, _MidC, _C, CC) :- R =:= MidR, !.
generate_cross_cell_(_R, CC, _BG, _MidR, MidC, C, CC) :- C =:= MidC, !.
generate_cross_cell_(_R, _CC, BG, _MidR, _MidC, _C, BG).

% generate_identity_grid(+N, +One, -Grid): N x N grid; diagonal=One, off-diag=0.
generate_identity_grid(N, One, Grid) :-
    generate_diagonal(N, N, One, Grid).

% generate_from_map(+RowsCols, +Map, -Grid): build grid from r(R,C)-Color pairs.
% RowsCols = Rows-Cols. Default color is 0.
generate_from_map(Rows-Cols, Map, Grid) :-
    % Start with all-zero grid.
    generate_uniform(Rows, Cols, 0, Zero),
    % Set each cell from the map.
    foldl_map_(Map, Zero, Grid).

% foldl_map_(+Map, +G, -G2): set each r(R,C)-Color pair in G.
foldl_map_([], G, G).
foldl_map_([r(R,C)-Color|Rest], G, G2) :-
    generate_set_cell_(G, r(R,C), Color, G1),
    foldl_map_(Rest, G1, G2).

% generate_set_cell_(+Grid, +r(R,C), +V, -Result): set one cell.
generate_set_cell_(Grid, r(R,C), V, Result) :-
    length(Pre, R),
    append(Pre, [OldRow|Suf], Grid),
    length(PreC, C),
    append(PreC, [_|SufC], OldRow),
    append(PreC, [V|SufC], NewRow),
    append(Pre, [NewRow|Suf], Result).

% generate_repeat_pattern(+Pattern, +Rows, +Cols, -Grid): tile Pattern to Rows x Cols.
generate_repeat_pattern(Pattern, Rows, Cols, Grid) :-
    % Determine pattern dimensions.
    length(Pattern, PRows), Pattern = [PRow0|_], length(PRow0, PCols),
    % Build each output row.
    ( Rows > 0 -> R1 is Rows - 1, numlist(0, R1, RowIds) ; RowIds = [] ),
    maplist(generate_pattern_row_(Pattern, PRows, PCols, Cols), RowIds, Grid).

% generate_pattern_row_(+Pattern, +PRows, +PCols, +Cols, +R, -Row): one tiled row.
generate_pattern_row_(Pattern, PRows, PCols, Cols, R, Row) :-
    % Which pattern row to use.
    PR is R mod PRows,
    nth0(PR, Pattern, PRow),
    % Build the output row by cycling the pattern row.
    ( Cols > 0 -> C1 is Cols - 1, numlist(0, C1, ColIds) ; ColIds = [] ),
    maplist(generate_pattern_cell_(PRow, PCols), ColIds, Row).

% generate_pattern_cell_(+PRow, +PCols, +C, -Color): tiled column value.
generate_pattern_cell_(PRow, PCols, C, Color) :-
    PC is C mod PCols,
    nth0(PC, PRow, Color).
