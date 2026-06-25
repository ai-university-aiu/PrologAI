% gravity.pl - Layer 95: Directional Cell-Sliding and Gravity Operations (gv_* prefix).
% Non-Bg cells slide through background in a chosen direction until hitting a wall or boundary.
% Color-specific variants let only one color move; other non-Bg cells act as immovable walls.
:- module(gravity, [
    gv_fall_down/3, gv_fall_up/3,
    gv_fall_left/3, gv_fall_right/3,
    gv_fall_dir/4,
    gv_fall_color_down/4, gv_fall_color_up/4,
    gv_fall_color_left/4, gv_fall_color_right/4,
    gv_fall_color_dir/5,
    gv_pack_row_left/3, gv_pack_row_right/3,
    gv_pack_col_up/3, gv_pack_col_down/3
]).
% Import nth0/3 for indexed column extraction; numlist/3 for column index ranges.
:- use_module(library(lists), [nth0/3, numlist/3, append/2, append/3]).
% Import include/3 for separating Bg from non-Bg; maplist/2,3 for bulk row/column processing.
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% gv_transpose_: internal helper to transpose Grid from row-major to column-major form.
% Each column C of Grid becomes row C of the transposed result.
gv_transpose_(Grid, T) :-
% Extract the width of the grid from the first row.
    Grid = [FirstRow|_], length(FirstRow, NC), NC1 is NC - 1,
% Build the list of column indices 0 through NC-1.
    numlist(0, NC1, ColIdxs),
% For each column index C, collect all nth0(C) values across rows into Col.
    maplist([C, Col]>>(maplist([Row, V]>>(nth0(C, Row, V)), Grid, Col)), ColIdxs, T).

% gv_pack_row_left(+Row, +Bg, -Result): compact all non-Bg values to the left end.
% Bg cells are padded on the right. Relative order of non-Bg values is preserved.
gv_pack_row_left(Row, Bg, Result) :-
% Collect all non-Bg values in left-to-right order.
    include([V]>>(V \== Bg), Row, NonBg),
% Compute the number of Bg pad cells to restore the row length.
    length(Row, N), length(NonBg, NNB), NPad is N - NNB,
% Build the background padding list.
    length(Pad, NPad), maplist(=(Bg), Pad),
% Non-Bg values first (left), then Bg padding (right).
    append(NonBg, Pad, Result).

% gv_pack_row_right(+Row, +Bg, -Result): compact all non-Bg values to the right end.
% Bg cells are padded on the left. Relative order of non-Bg values is preserved.
gv_pack_row_right(Row, Bg, Result) :-
% Collect all non-Bg values in left-to-right order.
    include([V]>>(V \== Bg), Row, NonBg),
% Compute the number of Bg pad cells to restore the row length.
    length(Row, N), length(NonBg, NNB), NPad is N - NNB,
% Build the background padding list.
    length(Pad, NPad), maplist(=(Bg), Pad),
% Bg padding first (left), then non-Bg values (right).
    append(Pad, NonBg, Result).

% gv_pack_col_up(+Col, +Bg, -Result): compact all non-Bg values to the top (start).
% Bg cells are padded at the bottom. Relative order of non-Bg values is preserved.
gv_pack_col_up(Col, Bg, Result) :-
% Collect all non-Bg values in top-to-bottom order.
    include([V]>>(V \== Bg), Col, NonBg),
% Compute the number of Bg pad cells to restore the column length.
    length(Col, N), length(NonBg, NNB), NPad is N - NNB,
% Build the background padding list.
    length(Pad, NPad), maplist(=(Bg), Pad),
% Non-Bg values at top (front), Bg padding at bottom (end).
    append(NonBg, Pad, Result).

% gv_pack_col_down(+Col, +Bg, -Result): compact all non-Bg values to the bottom (end).
% Bg cells are padded at the top. Relative order of non-Bg values is preserved.
gv_pack_col_down(Col, Bg, Result) :-
% Collect all non-Bg values in top-to-bottom order.
    include([V]>>(V \== Bg), Col, NonBg),
% Compute the number of Bg pad cells to restore the column length.
    length(Col, N), length(NonBg, NNB), NPad is N - NNB,
% Build the background padding list.
    length(Pad, NPad), maplist(=(Bg), Pad),
% Bg padding at top (front), non-Bg values at bottom (end).
    append(Pad, NonBg, Result).

% gv_fall_left(+Grid, +Bg, -Result): all non-Bg cells slide left within their row.
% Each row is packed independently; no inter-row interaction.
gv_fall_left(Grid, Bg, Result) :-
% Apply left-packing to each row independently.
    maplist([Row, Res]>>(gv_pack_row_left(Row, Bg, Res)), Grid, Result).

% gv_fall_right(+Grid, +Bg, -Result): all non-Bg cells slide right within their row.
% Each row is packed independently; no inter-row interaction.
gv_fall_right(Grid, Bg, Result) :-
% Apply right-packing to each row independently.
    maplist([Row, Res]>>(gv_pack_row_right(Row, Bg, Res)), Grid, Result).

% gv_fall_down(+Grid, +Bg, -Result): all non-Bg cells fall downward within their column.
% Transposes to column-as-row form, packs right (= down), then transposes back.
gv_fall_down(Grid, Bg, Result) :-
% Transpose so each column becomes a row for uniform row-level processing.
    gv_transpose_(Grid, T),
% Pack each column (now a row) with non-Bg to the right end (= bottom in column space).
    maplist([Row, Res]>>(gv_pack_row_right(Row, Bg, Res)), T, T2),
% Transpose back to restore the original row-major orientation.
    gv_transpose_(T2, Result).

% gv_fall_up(+Grid, +Bg, -Result): all non-Bg cells rise upward within their column.
% Transposes to column-as-row form, packs left (= up), then transposes back.
gv_fall_up(Grid, Bg, Result) :-
% Transpose so each column becomes a row for uniform row-level processing.
    gv_transpose_(Grid, T),
% Pack each column (now a row) with non-Bg to the left end (= top in column space).
    maplist([Row, Res]>>(gv_pack_row_left(Row, Bg, Res)), T, T2),
% Transpose back to restore the original row-major orientation.
    gv_transpose_(T2, Result).

% gv_fall_dir(+Grid, +Bg, +Dir, -Result): dispatch gravity by direction atom.
% Dir must be one of the atoms: down, up, left, right.
gv_fall_dir(Grid, Bg, Dir, Result) :-
% Use if-then-else to dispatch deterministically on Dir.
    (Dir == down -> gv_fall_down(Grid, Bg, Result)
    ; Dir == up   -> gv_fall_up(Grid, Bg, Result)
    ; Dir == left -> gv_fall_left(Grid, Bg, Result)
    ;                gv_fall_right(Grid, Bg, Result)).

% gv_take_seg_: collect a contiguous prefix of Bg or Color cells.
% Terminates at the first cell that is neither Bg nor Color (a wall cell).
gv_take_seg_([], _, _, [], []) :- !.
gv_take_seg_([H|T], Bg, Color, [H|Seg], Rest) :-
% H is Bg or Color: include it in the current segment and continue.
    (H == Bg ; H == Color), !,
    gv_take_seg_(T, Bg, Color, Seg, Rest).
% H is a wall: the segment ends here; Rest retains H.
gv_take_seg_(L, _, _, [], L).

% gv_pack_seg_right_: pack a Bg/Color segment with Color values at the right end.
% Bg padding occupies the left portion; Color values occupy the right portion.
gv_pack_seg_right_(Seg, Bg, Color, Result) :-
% Extract Color cells from the segment.
    include([V]>>(V == Color), Seg, Colors),
% Compute the number of Bg pad cells needed to fill the segment.
    length(Seg, N), length(Colors, NC), NPad is N - NC,
    length(Pad, NPad), maplist(=(Bg), Pad),
% Bg padding first, then Color values.
    append(Pad, Colors, Result).

% gv_pack_seg_left_: pack a Bg/Color segment with Color values at the left end.
% Color values occupy the left portion; Bg padding occupies the right portion.
gv_pack_seg_left_(Seg, Bg, Color, Result) :-
% Extract Color cells from the segment.
    include([V]>>(V == Color), Seg, Colors),
% Compute the number of Bg pad cells needed to fill the segment.
    length(Seg, N), length(Colors, NC), NPad is N - NC,
    length(Pad, NPad), maplist(=(Bg), Pad),
% Color values first, then Bg padding.
    append(Colors, Pad, Result).

% gv_split_pack_right_: recursively process a row, packing Color right within each segment.
% Wall cells (neither Bg nor Color) are kept in place; they bound each gravity segment.
gv_split_pack_right_([], _, _, Acc, Acc) :- !.
gv_split_pack_right_([H|T], Bg, Color, Acc, Result) :-
    (H \== Bg, H \== Color ->
% Wall cell: append it as-is and continue with the remainder.
        append(Acc, [H], Acc2),
        gv_split_pack_right_(T, Bg, Color, Acc2, Result)
    ;
% Start of a Bg/Color segment: collect the full contiguous segment.
        gv_take_seg_([H|T], Bg, Color, Seg, Rest),
% Pack the segment with Color to the right.
        gv_pack_seg_right_(Seg, Bg, Color, Packed),
        append(Acc, Packed, Acc2),
        gv_split_pack_right_(Rest, Bg, Color, Acc2, Result)
    ).

% gv_split_pack_left_: recursively process a row, packing Color left within each segment.
% Wall cells (neither Bg nor Color) are kept in place; they bound each gravity segment.
gv_split_pack_left_([], _, _, Acc, Acc) :- !.
gv_split_pack_left_([H|T], Bg, Color, Acc, Result) :-
    (H \== Bg, H \== Color ->
% Wall cell: append it as-is and continue with the remainder.
        append(Acc, [H], Acc2),
        gv_split_pack_left_(T, Bg, Color, Acc2, Result)
    ;
% Start of a Bg/Color segment: collect the full contiguous segment.
        gv_take_seg_([H|T], Bg, Color, Seg, Rest),
% Pack the segment with Color to the left.
        gv_pack_seg_left_(Seg, Bg, Color, Packed),
        append(Acc, Packed, Acc2),
        gv_split_pack_left_(Rest, Bg, Color, Acc2, Result)
    ).

% gv_fall_color_left(+Grid, +Bg, +Color, -Result):
% Only Color cells slide left. Other non-Bg cells act as immovable walls.
% Color cells move left within each segment between wall cells.
gv_fall_color_left(Grid, Bg, Color, Result) :-
% Apply leftward color-specific gravity to each row independently.
    maplist([Row, Res]>>(gv_split_pack_left_(Row, Bg, Color, [], Res)), Grid, Result).

% gv_fall_color_right(+Grid, +Bg, +Color, -Result):
% Only Color cells slide right. Other non-Bg cells act as immovable walls.
% Color cells move right within each segment between wall cells.
gv_fall_color_right(Grid, Bg, Color, Result) :-
% Apply rightward color-specific gravity to each row independently.
    maplist([Row, Res]>>(gv_split_pack_right_(Row, Bg, Color, [], Res)), Grid, Result).

% gv_fall_color_down(+Grid, +Bg, +Color, -Result):
% Only Color cells fall downward. Other non-Bg cells act as immovable walls.
% Uses transpose to apply row-level color gravity to each column.
gv_fall_color_down(Grid, Bg, Color, Result) :-
% Transpose so columns become rows for uniform row-level processing.
    gv_transpose_(Grid, T),
% Apply rightward color-specific gravity (= downward in column space) to each column.
    maplist([Row, Res]>>(gv_split_pack_right_(Row, Bg, Color, [], Res)), T, T2),
% Transpose back to restore the original row-major orientation.
    gv_transpose_(T2, Result).

% gv_fall_color_up(+Grid, +Bg, +Color, -Result):
% Only Color cells rise upward. Other non-Bg cells act as immovable walls.
% Uses transpose to apply row-level color gravity to each column.
gv_fall_color_up(Grid, Bg, Color, Result) :-
% Transpose so columns become rows for uniform row-level processing.
    gv_transpose_(Grid, T),
% Apply leftward color-specific gravity (= upward in column space) to each column.
    maplist([Row, Res]>>(gv_split_pack_left_(Row, Bg, Color, [], Res)), T, T2),
% Transpose back to restore the original row-major orientation.
    gv_transpose_(T2, Result).

% gv_fall_color_dir(+Grid, +Bg, +Color, +Dir, -Result):
% Dispatch color-specific gravity by direction atom.
% Dir must be one of: down, up, left, right.
gv_fall_color_dir(Grid, Bg, Color, Dir, Result) :-
% Use if-then-else to dispatch deterministically on Dir.
    (Dir == down  -> gv_fall_color_down(Grid, Bg, Color, Result)
    ; Dir == up   -> gv_fall_color_up(Grid, Bg, Color, Result)
    ; Dir == left -> gv_fall_color_left(Grid, Bg, Color, Result)
    ;                gv_fall_color_right(Grid, Bg, Color, Result)).
