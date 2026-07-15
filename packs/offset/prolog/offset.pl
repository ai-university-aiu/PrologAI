% offset.pl - Layer 112: Grid Shifting and Circular Rolling (od_* prefix).
% Provides predicates for shifting grids in four directions with background fill,
% circular (rolling) shifts in four directions, single-row equivalents, shifting
% one specific color within a grid, and inferring the shift between two grids.
:- module(offset, [
    offset_shift_row/4,
    offset_shift_row_left/4,
    offset_roll_row/3,
    offset_shift_right/4,
    offset_shift_left/4,
    offset_shift_down/4,
    offset_shift_up/4,
    offset_shift_dir/5,
    offset_roll_right/3,
    offset_roll_left/3,
    offset_roll_down/3,
    offset_roll_up/3,
    offset_shift_color/6,
    offset_infer_shift/5
]).
% Import list utilities.
:- use_module(library(lists), [member/2, nth0/3, append/3]).
% Import higher-order mapping.
:- use_module(library(apply), [maplist/3]).

% offset_shift_row(+Row, +N, +Bg, -Shifted): Shifted is Row shifted right by N cells.
% The leftmost N positions become Bg; the last N elements of Row are dropped.
% For N=0, Shifted = Row.
offset_shift_row(Row, N, Bg, Shifted) :-
    length(Row, W),
    WN is W - N,
% Extract the first WN elements to keep (the last N elements are discarded).
    length(Keep, WN),
    append(Keep, _, Row),
% Build N background cells to prepend.
    findall(Bg, between(1, N, _), BgCells),
% Prepend the background cells before the kept elements.
    append(BgCells, Keep, Shifted).

% offset_shift_row_left(+Row, +N, +Bg, -Shifted): Shifted is Row shifted left by N cells.
% The rightmost N positions become Bg; the first N elements of Row are dropped.
% For N=0, Shifted = Row.
offset_shift_row_left(Row, N, Bg, Shifted) :-
    length(Row, W),
    WN is W - N,
% Skip the first N elements.
    length(Skip, N),
    append(Skip, Keep, Row),
% Keep has the remaining WN elements; force the length constraint.
    length(Keep, WN),
% Build N background cells to append.
    findall(Bg, between(1, N, _), BgCells),
% Append background cells after the kept elements.
    append(Keep, BgCells, Shifted).

% offset_roll_row(+Row, +N, -Rolled): Rolled is Row circular-shifted right by N.
% The last N elements wrap around to become the first N elements.
% N is reduced modulo the row length.
offset_roll_row(Row, N, Rolled) :-
    length(Row, W),
% Normalize N to [0, W-1].
    PN is N mod W,
% The split point: prefix has W-PN elements, suffix (the wrapped tail) has PN.
    Split is W - PN,
    length(Prefix, Split),
    append(Prefix, Suffix, Row),
% Place the suffix before the prefix.
    append(Suffix, Prefix, Rolled).

% offset_shift_right(+Grid, +N, +Bg, -Shifted): Shifted is Grid with each row
% shifted right by N cells. Leftmost N columns become Bg; last N columns lost.
offset_shift_right(Grid, N, Bg, Shifted) :-
% Apply offset_shift_row to every row using a YALL lambda.
    maplist([Row, S]>>(offset_shift_row(Row, N, Bg, S)), Grid, Shifted).

% offset_shift_left(+Grid, +N, +Bg, -Shifted): Shifted is Grid with each row
% shifted left by N cells. Rightmost N columns become Bg; first N columns lost.
offset_shift_left(Grid, N, Bg, Shifted) :-
% Apply offset_shift_row_left to every row.
    maplist([Row, S]>>(offset_shift_row_left(Row, N, Bg, S)), Grid, Shifted).

% offset_shift_down(+Grid, +N, +Bg, -Shifted): Shifted is Grid with content shifted
% downward by N rows. The top N rows become Bg rows; the bottom N rows are lost.
offset_shift_down(Grid, N, Bg, Shifted) :-
    length(Grid, H),
    HN is H - N,
% Extract the first HN rows to keep (the last N rows are discarded).
    length(Keep, HN),
    append(Keep, _, Grid),
% Determine column count for background rows.
    Grid = [FirstRow|_],
    length(FirstRow, W),
% Build N background rows each of width W.
    findall(BgRow, (
        between(1, N, _),
        findall(Bg, between(1, W, _), BgRow)
    ), BgRows),
% Prepend background rows above the kept rows.
    append(BgRows, Keep, Shifted).

% offset_shift_up(+Grid, +N, +Bg, -Shifted): Shifted is Grid with content shifted
% upward by N rows. The bottom N rows become Bg rows; the top N rows are lost.
offset_shift_up(Grid, N, Bg, Shifted) :-
    Grid = [FirstRow|_],
    length(FirstRow, W),
% Skip the first N rows.
    length(Skip, N),
    append(Skip, Keep, Grid),
% Build N background rows each of width W.
    findall(BgRow, (
        between(1, N, _),
        findall(Bg, between(1, W, _), BgRow)
    ), BgRows),
% Append background rows below the kept rows.
    append(Keep, BgRows, Shifted).

% offset_shift_dir(+Grid, +Dir, +N, +Bg, -Shifted): dispatch shift by direction atom.
% Dir must be one of: right, left, down, up. Uses if-then-else for determinism.
offset_shift_dir(Grid, Dir, N, Bg, Shifted) :-
    (   Dir = right -> offset_shift_right(Grid, N, Bg, Shifted)
    ;   Dir = left  -> offset_shift_left(Grid, N, Bg, Shifted)
    ;   Dir = down  -> offset_shift_down(Grid, N, Bg, Shifted)
    ;   Dir = up    -> offset_shift_up(Grid, N, Bg, Shifted)
    ).

% offset_roll_right(+Grid, +N, -Rolled): Rolled is Grid with each row circular-shifted
% right by N positions (the last N cells of each row wrap to the front).
offset_roll_right(Grid, N, Rolled) :-
    maplist([Row, R]>>(offset_roll_row(Row, N, R)), Grid, Rolled).

% offset_roll_left(+Grid, +N, -Rolled): Rolled is Grid with each row circular-shifted
% left by N positions (the first N cells of each row wrap to the end).
offset_roll_left(Grid, N, Rolled) :-
    maplist([Row, R]>>(offset_roll_left_row_(Row, N, R)), Grid, Rolled).

% offset_roll_left_row_: circular left-shift a single row by N.
offset_roll_left_row_(Row, N, Rolled) :-
    length(Row, W),
    PN is N mod W,
% Take the first PN elements as the part that wraps to the end.
    length(Prefix, PN),
    append(Prefix, Suffix, Row),
    append(Suffix, Prefix, Rolled).

% offset_roll_down(+Grid, +N, -Rolled): Rolled is Grid with rows circular-shifted
% downward by N (the last N rows wrap to the top).
offset_roll_down(Grid, N, Rolled) :-
    length(Grid, H),
    PN is N mod H,
% Split at H-PN: the prefix (first H-PN rows) stays, suffix wraps to front.
    Split is H - PN,
    length(Prefix, Split),
    append(Prefix, Suffix, Grid),
    append(Suffix, Prefix, Rolled).

% offset_roll_up(+Grid, +N, -Rolled): Rolled is Grid with rows circular-shifted
% upward by N (the first N rows wrap to the bottom).
offset_roll_up(Grid, N, Rolled) :-
    length(Grid, H),
    PN is N mod H,
% The first PN rows wrap to the end.
    length(Prefix, PN),
    append(Prefix, Suffix, Grid),
    append(Suffix, Prefix, Rolled).

% offset_shift_color(+Grid, +Color, +DR, +DC, +Bg, -Result): Result is Grid with
% all cells equal to Color translated by (DR rows, DC columns). Vacated cells
% become Bg; out-of-bounds translated cells are clipped (lost). Other colors
% are unchanged. If a non-Color cell is displaced to by the shifted Color, the
% Color takes priority.
offset_shift_color(Grid, Color, DR, DC, Bg, Result) :-
    length(Grid, H), H1 is H - 1,
    Grid = [FirstRow|_], length(FirstRow, W), W1 is W - 1,
    findall(Row, (
        between(0, H1, R),
        findall(V, (
            between(0, W1, C),
% Compute the source position for this output cell.
            SR is R - DR, SC is C - DC,
            (   SR >= 0, SR =< H1, SC >= 0, SC =< W1,
                nth0(SR, Grid, SrcRow), nth0(SC, SrcRow, Color)
% Source position is in bounds and holds Color: paint Color here.
            ->  V = Color
            ;   nth0(R, Grid, CurRow), nth0(C, CurRow, CurV),
% No shifted Color lands here: keep non-Color cells, replace Color with Bg.
                (CurV =:= Color -> V = Bg ; V = CurV)
            )
        ), Row)
    ), Result).

% offset_infer_shift(+GridA, +GridB, +Bg, -DR, -DC): DR and DC are the row and column
% displacement such that shifting GridA by (DR, DC) produces GridB. Positive DR
% means downward, positive DC means rightward. Tries all integer offsets up to
% grid dimensions and commits to the first match.
offset_infer_shift(GridA, GridB, Bg, DR, DC) :-
    length(GridA, H), H1 is H - 1, NH is -(H - 1),
    GridA = [FirstRowA|_], length(FirstRowA, W), W1 is W - 1, NW is -(W - 1),
    between(NH, H1, DR),
    between(NW, W1, DC),
% Apply the candidate shift and test if it produces GridB.
    offset_apply_shift_(GridA, DR, DC, Bg, GridB),
    !.

% offset_apply_shift_: apply a signed (DR, DC) shift to Grid using Bg as fill.
offset_apply_shift_(Grid, DR, DC, Bg, Result) :-
    (   DR > 0
    ->  offset_shift_down(Grid, DR, Bg, T1)
    ;   DR < 0
    ->  AbsDR is -DR, offset_shift_up(Grid, AbsDR, Bg, T1)
    ;   T1 = Grid
    ),
    (   DC > 0
    ->  offset_shift_right(T1, DC, Bg, Result)
    ;   DC < 0
    ->  AbsDC is -DC, offset_shift_left(T1, AbsDC, Bg, Result)
    ;   Result = T1
    ).
