% fold.pl - Layer 143: Grid Folding, Unfolding, and Fold-Symmetry Detection (fd_* prefix).
% Provides predicates for splitting a grid into two halves, overlaying two halves,
% folding the bottom or right half onto the top or left half (as in paper origami),
% unfolding a half-grid into a symmetric full grid, testing fold symmetry around an
% arbitrary row or column, finding fold lines, detecting marked fold rows/columns, and
% applying a double fold (row then column). These operations arise naturally in visual
% reasoning tasks where a pattern is the result of folding a larger symmetric grid.
:- module(fold, [
    % fd_split_h/4: split Grid into Top (rows 0..R) and Bottom (rows R+1..H-1).
    fd_split_h/4,
    % fd_split_v/4: split Grid into Left (cols 0..C) and Right (cols C+1..W-1).
    fd_split_v/4,
    % fd_overlay/4: Out[R][C] = A[R][C] if A[R][C] != Bg, else B[R][C].
    fd_overlay/4,
    % fd_fold_h/4: fold bottom half up over top; crease after row R.
    fd_fold_h/4,
    % fd_fold_v/4: fold right half left over left; crease after col C.
    fd_fold_v/4,
    % fd_unfold_h/2: create symmetric full grid by stacking Half with reversed Half.
    fd_unfold_h/2,
    % fd_unfold_v/2: create symmetric full grid by joining Half with its L-R mirror.
    fd_unfold_v/2,
    % fd_sym_h/2: succeed if Grid is symmetric around row R.
    fd_sym_h/2,
    % fd_sym_v/2: succeed if Grid is symmetric around column C.
    fd_sym_v/2,
    % fd_find_fold_h/2: find row R around which Grid is horizontally symmetric.
    fd_find_fold_h/2,
    % fd_find_fold_v/2: find col C around which Grid is vertically symmetric.
    fd_find_fold_v/2,
    % fd_mark_row/3: R is the unique row where every cell equals V.
    fd_mark_row/3,
    % fd_mark_col/3: C is the unique column where every cell equals V.
    fd_mark_col/3,
    % fd_fold_both/5: fold at row R then fold the result at column C.
    fd_fold_both/5
]).

% Import list utilities for splitting, membership, and indexing.
:- use_module(library(lists), [member/2, nth0/3, append/2, append/3, reverse/2]).
% Import higher-order utilities for row-level mapping.
:- use_module(library(apply), [maplist/2, maplist/3, maplist/4]).

% fd_split_h(+Grid, +R, -Top, -Bottom): split Grid horizontally at row R.
% Top contains rows 0..R (length R+1); Bottom contains rows R+1..H-1.
% Uses list prefix of length R+1 to split Grid.
fd_split_h(Grid, R, Top, Bottom) :-
    % Bind Top to a list of exactly R+1 elements.
    R1 is R + 1,
    % length/2 with known second arg creates a list of that length.
    length(Top, R1),
    % append/3 splits Grid into the R+1 prefix and the remaining rows.
    append(Top, Bottom, Grid).

% fd_split_v(+Grid, +C, -Left, -Right): split Grid vertically at column C.
% Left contains columns 0..C; Right contains columns C+1..W-1.
% Each row is split independently using a column prefix of length C+1.
fd_split_v(Grid, C, Left, Right) :-
    % Column count for each left sub-row.
    C1 is C + 1,
    % Apply the row split to every row in parallel.
    maplist(fd_split_row_(C1), Grid, Left, Right).

% fd_split_row_(+C1, +Row, -LeftRow, -RightRow): split Row at column C (0-indexed).
% LeftRow has C1 = C+1 elements; RightRow has the remaining elements.
fd_split_row_(C1, Row, LeftRow, RightRow) :-
    % Bind LeftRow to exactly C1 elements.
    length(LeftRow, C1),
    % Append splits Row at that prefix boundary.
    append(LeftRow, RightRow, Row).

% fd_overlay(+A, +B, +Bg, -Out): cell-by-cell overlay of two same-size grids.
% Out[R][C] = A[R][C] when A[R][C] != Bg; otherwise Out[R][C] = B[R][C].
% A takes priority: non-background cells of A cover corresponding cells in B.
fd_overlay(A, B, Bg, Out) :-
    % Apply row-level overlay across both grids simultaneously.
    maplist(fd_overlay_row_(Bg), A, B, Out).

% fd_overlay_row_(+Bg, +RowA, +RowB, -RowOut): overlay two rows.
fd_overlay_row_(Bg, RowA, RowB, RowOut) :-
    % Apply cell-level overlay across both rows simultaneously.
    maplist(fd_overlay_cell_(Bg), RowA, RowB, RowOut).

% fd_overlay_cell_(+Bg, +VA, +VB, -V): A-cell wins unless it equals background.
fd_overlay_cell_(Bg, VA, _VB, VA) :-
    % Non-background A-cell takes priority.
    VA \= Bg,
    % Cut prevents the fallback clause from executing.
    !.
% fd_overlay_cell_ fallback: A is background so B-cell is used.
fd_overlay_cell_(_Bg, _VA, VB, VB).

% fd_fold_h(+Grid, +R, +Bg, -Out): fold the bottom half of Grid upward.
% Crease is after row R; Left half = rows 0..R; Bottom half = rows R+1..H-1.
% Row at position I in Out is fd_overlay(Top[I], Bottom[R-I], Bg).
% For each column position I of Top (0..R), if K = R-I < length(Bottom)
% then overlay Top[I] with Bottom[K]; otherwise keep Top[I] unchanged.
% The output has the same height as Top (R+1 rows).
fd_fold_h(Grid, R, Bg, Out) :-
    % Split Grid into Top and Bottom halves.
    fd_split_h(Grid, R, Top, Bottom),
    % Get Bottom's height for bounds checking.
    length(Bottom, HB),
    % Get Top's height for row iteration.
    length(Top, HT),
    % Maximum row index in Top.
    HT1 is HT - 1,
    % Build each output row by overlay or passthrough.
    findall(OutRow, (
        between(0, HT1, I),
        nth0(I, Top, TopRow),
        % K = R - I: index into Bottom (row nearest fold = 0, farthest = HB-1).
        K is R - I,
        ( K >= 0, K < HB ->
            nth0(K, Bottom, BotRow),
            fd_overlay_row_(Bg, TopRow, BotRow, OutRow)
        ;
            OutRow = TopRow
        )
    ), Out).

% fd_fold_v(+Grid, +C, +Bg, -Out): fold the right half of Grid leftward.
% Crease is after column C; Left half = cols 0..C; Right half = cols C+1..W-1.
% For column position I of Left, if K = C-I < length(Right_row) then overlay
% Left[row][I] with Right[row][K]; otherwise keep Left[row][I] unchanged.
% The output has the same width as Left (C+1 columns).
fd_fold_v(Grid, C, Bg, Out) :-
    % Split Grid into Left and Right halves.
    fd_split_v(Grid, C, Left, Right),
    % Get Right half's column count for bounds checking (from first row).
    ( Right = [RFR|_] -> length(RFR, WR) ; WR = 0 ),
    % Get Left half's column count for iteration (from first row).
    ( Left = [LFR|_] -> length(LFR, WL) ; WL = 0 ),
    % Apply column-level fold to every row independently.
    maplist(fd_fold_row_v_(WL, WR, C, Bg), Left, Right, Out).

% fd_fold_row_v_(+WL, +WR, +C, +Bg, +LRow, +RRow, -OutRow): fold one row.
fd_fold_row_v_(WL, WR, C, Bg, LRow, RRow, OutRow) :-
    % Maximum left column index.
    WL1 is WL - 1,
    % Build each output column by overlay or passthrough.
    findall(V, (
        between(0, WL1, I),
        nth0(I, LRow, LV),
        % K = C - I: index into Right row (col nearest fold = 0).
        K is C - I,
        ( K >= 0, K < WR ->
            nth0(K, RRow, RV),
            fd_overlay_cell_(Bg, LV, RV, V)
        ;
            V = LV
        )
    ), OutRow).

% fd_unfold_h(+Half, -Grid): create a symmetric full grid from a top half.
% Grid = vcat(Half, reverse_rows(Half)): Half stacked above upside-down Half.
% The result has 2 * height(Half) rows; the fold axis is between the last
% row of Half and the first row of the reversed Half.
fd_unfold_h(Half, Grid) :-
    % Reverse the row order of Half.
    reverse(Half, RevHalf),
    % Stack Half on top and reversed Half below.
    append(Half, RevHalf, Grid).

% fd_unfold_v(+Half, -Grid): create a symmetric full grid from a left half.
% Grid = hcat(Half, lr_mirror(Half)): Half joined with its left-right mirror.
% The result has 2 * width(Half) columns; symmetry is around the fold axis.
fd_unfold_v(Half, Grid) :-
    % Mirror each row (reverse its elements) and join with the original row.
    maplist(fd_mirror_row_, Half, Grid).

% fd_mirror_row_(+LeftRow, -FullRow): join LeftRow with its reverse.
fd_mirror_row_(LeftRow, FullRow) :-
    % Reverse LeftRow to form the right half.
    reverse(LeftRow, RevRow),
    % Concatenate to form the full symmetric row.
    append(LeftRow, RevRow, FullRow).

% fd_sym_h(+Grid, +R): succeed if Grid is symmetric under folding with crease after row R.
% Mirror formula: row I reflects to row (2*R + 1 - I). This is the between-rows formula:
% the crease sits between rows R and R+1, so row 0 maps to row 2R+1, row R maps to row R+1, etc.
% This matches fd_fold_h semantics exactly: Bottom[K] = Grid[R+1+K] = Grid[2R+1-I] for K=R-I.
fd_sym_h(Grid, R) :-
    % Get grid height for iteration and bounds checking.
    length(Grid, H),
    % Maximum row index.
    H1 is H - 1,
    % Check every row against its mirror counterpart across the crease.
    forall(
        between(0, H1, I),
        ( IR is 2 * R + 1 - I,
          ( IR >= 0, IR =< H1 ->
              nth0(I, Grid, RowI),
              nth0(IR, Grid, RowIR),
              RowI == RowIR
          ;
              true
          )
        )
    ).

% fd_sym_v(+Grid, +C): succeed if Grid is symmetric under folding with crease after col C.
% Mirror formula: col J reflects to col (2*C + 1 - J). This matches fd_fold_v semantics:
% Right[K] = col (C+1+K) = col (2C+1-J) for K=C-J. Crease sits between cols C and C+1.
fd_sym_v(Grid, C) :-
    % Get grid dimensions.
    length(Grid, H),
    H1 is H - 1,
    ( Grid = [FR|_] -> length(FR, W) ; W = 0 ),
    W1 is W - 1,
    % Check every column position against its mirror counterpart across the crease.
    forall(
        ( between(0, H1, R), between(0, W1, J) ),
        ( JC is 2 * C + 1 - J,
          ( JC >= 0, JC =< W1 ->
              nth0(R, Grid, Row),
              nth0(J, Row, VJ),
              nth0(JC, Row, VJC),
              VJ == VJC
          ;
              true
          )
        )
    ).

% fd_find_fold_h(+Grid, -R): find a row R around which Grid is symmetric.
% Tries R = 0, 1, ..., H-1 and returns the first R that satisfies fd_sym_h.
% Fails if no such R exists.
fd_find_fold_h(Grid, R) :-
    % Get height for iteration range.
    length(Grid, H),
    % Maximum row index.
    H1 is H - 1,
    % Try each row and stop at the first success.
    between(0, H1, R),
    fd_sym_h(Grid, R),
    !.

% fd_find_fold_v(+Grid, -C): find a column C around which Grid is symmetric.
% Tries C = 0, 1, ..., W-1 and returns the first C that satisfies fd_sym_v.
% Fails if no such C exists.
fd_find_fold_v(Grid, C) :-
    % Get column count for iteration range.
    ( Grid = [FR|_] -> length(FR, W) ; W = 0 ),
    % Maximum column index.
    W1 is W - 1,
    % Try each column and stop at the first success.
    between(0, W1, C),
    fd_sym_v(Grid, C),
    !.

% fd_mark_row(+Grid, +V, -R): R is the first row where every cell equals V.
% Useful for identifying fold-marker rows (e.g., an all-separator row).
fd_mark_row(Grid, V, R) :-
    % Get height for iteration.
    length(Grid, H),
    % Maximum row index.
    H1 is H - 1,
    % Find the first row satisfying the all-V condition.
    between(0, H1, R),
    nth0(R, Grid, Row),
    forall(member(Cell, Row), Cell == V),
    !.

% fd_mark_col(+Grid, +V, -C): C is the first column where every cell equals V.
fd_mark_col(Grid, V, C) :-
    % Get dimensions.
    ( Grid = [FR|_] -> length(FR, W) ; W = 0 ),
    % Maximum column index.
    W1 is W - 1,
    % Find the first column satisfying the all-V condition.
    between(0, W1, C),
    forall(
        member(Row, Grid),
        ( nth0(C, Row, Cell), Cell == V )
    ),
    !.

% fd_fold_both(+Grid, +R, +C, +Bg, -Out): fold at row R then fold the result at column C.
% First applies fd_fold_h to fold the bottom half up (keeping width unchanged).
% Then applies fd_fold_v to fold the right half left on the horizontal result.
% The final output has height R+1 and width C+1.
fd_fold_both(Grid, R, C, Bg, Out) :-
    % First fold: bottom half up over top, result has R+1 rows.
    fd_fold_h(Grid, R, Bg, FoldedH),
    % Second fold: right half over left, result has C+1 cols.
    fd_fold_v(FoldedH, C, Bg, Out).
