:- module(gridseg, [
    gsg_is_sep_row/3,
    gsg_is_sep_col/3,
    gsg_sep_rows/3,
    gsg_sep_cols/3,
    gsg_split_h/3,
    gsg_split_v/3,
    gsg_segment_count_h/3,
    gsg_segment_count_v/3,
    gsg_panels/3,
    gsg_panel_count/3,
    gsg_trim_h/3,
    gsg_trim_v/3,
    gsg_trim/3,
    gsg_sep_color/2
]).
% gridseg.pl - Layer 220: Grid Segmentation by Separator Rows and Columns (gsg_* prefix).
% Detects uniform-color separator rows and columns, splits a grid into
% non-separator segments, extracts rectangular panels, and trims border separators.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% A "separator row" is a row whose every cell has the same color.
% A "separator column" is a column whose every cell has the same color.
% Consecutive separators count as one separator boundary (no empty segments).
% No cross-pack dependencies.
:- use_module(library(lists), [nth0/3, member/2, append/2, append/3, list_to_set/2]).

% --- PRIVATE HELPERS ---

% Test if a list is uniform (all elements equal to Color).
gsg_uniform_([], _).
gsg_uniform_([Color|Rest], Color) :-
% Every element must equal the head color.
    gsg_uniform_(Rest, Color).

% Extract column C from Grid as a top-to-bottom list.
gsg_col_(Grid, C, Col) :-
% Collect the C-th element from each row.
    findall(V, (member(Row, Grid), nth0(C, Row, V)), Col).

% Transpose a grid: each column becomes a row.
gsg_transpose_([], []).
gsg_transpose_(Grid, Trans) :-
% Build one column-as-row for each column index.
    Grid = [FR|_], length(FR, W),
    W1 is W - 1,
    findall(Col, (between(0, W1, C), gsg_col_(Grid, C, Col)), Trans).

% Split a list of rows at uniform-Color rows; accumulate segments.
% Consecutive uniform rows are treated as one boundary (no empty segments).
gsg_split_rows_([], _, Acc, Segs) :-
% Flush the last segment when the input is exhausted.
    (Acc = [] -> Segs = [] ; reverse(Acc, S), Segs = [S]).
gsg_split_rows_([Row|Rest], Color, Acc, Segs) :-
    (Row = [Color|_], gsg_uniform_(Row, Color) ->
        % This row is a separator.
        (Acc = [] ->
            % No accumulated segment yet: just skip.
            gsg_split_rows_(Rest, Color, [], Segs)
        ;
            % End current segment and start fresh.
            reverse(Acc, S),
            gsg_split_rows_(Rest, Color, [], RestSegs),
            Segs = [S|RestSegs]
        )
    ;
        % This row is content: accumulate it.
        gsg_split_rows_(Rest, Color, [Row|Acc], Segs)
    ).

% Drop leading uniform-Color rows from a list of rows.
gsg_drop_sep_([], _, []).
gsg_drop_sep_([Row|Rest], Color, Result) :-
    (Row = [Color|_], gsg_uniform_(Row, Color) ->
% This row is a separator: skip it.
        gsg_drop_sep_(Rest, Color, Result)
    ;
% First non-separator row: stop dropping.
        Result = [Row|Rest]
    ).

% --- PUBLIC PREDICATES ---

% gsg_is_sep_row(+Grid, +R, ?Color)
% Succeeds if row R of Grid is entirely Color (a separator row).
% Binds Color when uninstantiated.
gsg_is_sep_row(Grid, R, Color) :-
% Extract the row.
    nth0(R, Grid, Row),
% Row must be non-empty and all cells equal Color.
    Row = [Color|Rest],
% Verify all remaining cells match.
    gsg_uniform_(Rest, Color).

% gsg_is_sep_col(+Grid, +C, ?Color)
% Succeeds if column C of Grid is entirely Color (a separator column).
% Binds Color when uninstantiated.
gsg_is_sep_col(Grid, C, Color) :-
% Extract the column as a list.
    gsg_col_(Grid, C, Col),
% Column must be non-empty and all cells equal Color.
    Col = [Color|Rest],
% Verify all remaining cells match.
    gsg_uniform_(Rest, Color).

% gsg_sep_rows(+Grid, +Color, -Rows)
% Rows is the sorted list of row indices that are entirely Color.
gsg_sep_rows(Grid, Color, Rows) :-
% Compute the valid row index range.
    length(Grid, H), H1 is H - 1,
% Collect every R (bounded) where the row is a separator.
    findall(R, (between(0, H1, R), gsg_is_sep_row(Grid, R, Color)), Rows).

% gsg_sep_cols(+Grid, +Color, -Cols)
% Cols is the sorted list of column indices that are entirely Color.
gsg_sep_cols(Grid, Color, Cols) :-
% Compute the valid column index range.
    (Grid = [FR|_] -> length(FR, W) ; W = 0),
    W1 is W - 1,
% Collect every C (bounded) where the column is a separator.
    findall(C, (between(0, W1, C), gsg_is_sep_col(Grid, C, Color)), Cols).

% gsg_split_h(+Grid, +Color, -Segments)
% Segments is the list of non-empty sub-grids between separator rows of Color.
% Consecutive separator rows count as a single boundary.
gsg_split_h(Grid, Color, Segments) :-
% Delegate to the accumulator-based helper.
    gsg_split_rows_(Grid, Color, [], Segments).

% gsg_split_v(+Grid, +Color, -Segments)
% Segments is the list of non-empty sub-grids between separator columns of Color.
% Uses transpose-split-transpose.
gsg_split_v(Grid, Color, Segments) :-
% Transpose so columns become rows.
    gsg_transpose_(Grid, Trans),
% Split the transposed grid horizontally.
    gsg_split_h(Trans, Color, TSegs),
% Transpose each segment back to column orientation.
    maplist(gsg_transpose_, TSegs, Segments).

% gsg_segment_count_h(+Grid, +Color, -N)
% N is the number of horizontal segments (groups of rows between separator rows).
gsg_segment_count_h(Grid, Color, N) :-
    gsg_split_h(Grid, Color, Segs),
    length(Segs, N).

% gsg_segment_count_v(+Grid, +Color, -N)
% N is the number of vertical segments (groups of columns between separator cols).
gsg_segment_count_v(Grid, Color, N) :-
    gsg_split_v(Grid, Color, Segs),
    length(Segs, N).

% gsg_panels(+Grid, +Color, -Panels)
% Panels is the flat list of rectangular sub-grids obtained by splitting
% Grid at both separator rows and separator columns of Color.
% Panels are ordered row-major (left-to-right within each row group,
% then top-to-bottom across row groups).
gsg_panels(Grid, Color, Panels) :-
% Split into horizontal row segments.
    gsg_split_h(Grid, Color, RowSegs),
% For each row segment, split vertically to get a row of panels.
    maplist([Seg, SubPanels]>>(gsg_split_v(Seg, Color, SubPanels)), RowSegs, Panel2D),
% Flatten one level to get a single list.
    append(Panel2D, Panels).

% gsg_panel_count(+Grid, +Color, -N)
% N is the total number of panels after splitting by both separator rows and cols.
gsg_panel_count(Grid, Color, N) :-
    gsg_panels(Grid, Color, Panels),
    length(Panels, N).

% gsg_trim_h(+Grid, +Color, -Trimmed)
% Trimmed is Grid with leading and trailing separator rows of Color removed.
gsg_trim_h(Grid, Color, Trimmed) :-
% Remove separator rows from the top.
    gsg_drop_sep_(Grid, Color, Front),
% Reverse, remove separator rows from the bottom (now the top), then reverse back.
    reverse(Front, RevFront),
    gsg_drop_sep_(RevFront, Color, RevTrimmed),
    reverse(RevTrimmed, Trimmed).

% gsg_trim_v(+Grid, +Color, -Trimmed)
% Trimmed is Grid with leading and trailing separator columns of Color removed.
gsg_trim_v(Grid, Color, Trimmed) :-
% Transpose so columns become rows.
    gsg_transpose_(Grid, Trans),
% Trim leading and trailing separator rows (originally columns).
    gsg_trim_h(Trans, Color, TrimmedTrans),
% Transpose back to restore row orientation.
    gsg_transpose_(TrimmedTrans, Trimmed).

% gsg_trim(+Grid, +Color, -Trimmed)
% Trimmed is Grid with all border separator rows and columns of Color removed.
gsg_trim(Grid, Color, Trimmed) :-
% Trim separator rows from top and bottom.
    gsg_trim_h(Grid, Color, TrimH),
% Trim separator columns from left and right.
    gsg_trim_v(TrimH, Color, Trimmed).

% gsg_sep_color(+Grid, -Color)
% Succeeds if exactly one color is used as a separator row or column in Grid.
% Binds Color to that unique separator color. Fails if zero or multiple colors.
gsg_sep_color(Grid, Color) :-
% Collect all colors used in separator rows.
    length(Grid, H), H1 is H - 1,
    findall(C, (between(0, H1, R), gsg_is_sep_row(Grid, R, C)), RowColors),
% Collect all colors used in separator columns.
    (Grid = [FR|_] -> length(FR, W) ; W = 0),
    W1 is W - 1,
    findall(C, (between(0, W1, Col), gsg_is_sep_col(Grid, Col, C)), ColColors),
% Combine and deduplicate.
    append(RowColors, ColColors, AllColors),
    list_to_set(AllColors, [Color]).
