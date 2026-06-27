:- module(gridhist, [
    ghst_row_hist/3,
    ghst_col_hist/3,
    ghst_all_row_hists/2,
    ghst_all_col_hists/2,
    ghst_modal_row/3,
    ghst_modal_col/3,
    ghst_row_count/4,
    ghst_col_count/4,
    ghst_row_entropy/3,
    ghst_col_entropy/3,
    ghst_max_row/3,
    ghst_min_row/3,
    ghst_rows_with/4,
    ghst_cols_with/4
]).
% gridhist.pl - Layer 221: Grid Histogram Analysis (ghst_* prefix).
% Provides per-row and per-column color frequency histograms, modal (most
% frequent) color lookup, color-count queries, color diversity (entropy),
% and row/column selection by color frequency.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
% Histogram format: sorted list of Color-Count pairs in ascending color order.
% No cross-pack dependencies.
:- use_module(library(lists), [nth0/3, member/2, reverse/2]).

% --- PRIVATE HELPERS ---

% Compute a sorted Color-Count histogram from a flat list of color atoms.
ghst_list_hist_(List, Hist) :-
% Sort preserving duplicates to group identical colors together.
    msort(List, Sorted),
% Count consecutive runs of each color.
    ghst_count_runs_(Sorted, Hist).

% Base case: empty list produces empty histogram.
ghst_count_runs_([], []).
% Inductive case: count the run of the head color.
ghst_count_runs_([Color|Rest], [Color-N|Hist]) :-
% Count how many consecutive elements equal Color.
    ghst_count_leading_(Rest, Color, 1, N, Remaining),
% Recurse on the remainder after the run.
    ghst_count_runs_(Remaining, Hist).

% Count leading elements equal to Target, starting with accumulator Acc.
ghst_count_leading_([], _, N, N, []).
ghst_count_leading_([V|Rest], Target, Acc, N, Remaining) :-
    (V = Target ->
% V continues the run; increment accumulator.
        Acc1 is Acc + 1,
        ghst_count_leading_(Rest, Target, Acc1, N, Remaining)
    ;
% V breaks the run; N = Acc and Remaining starts with V.
        N = Acc, Remaining = [V|Rest]
    ).

% Find the Color with the highest Count in a histogram.
% If tied, the color that appears last in the sorted histogram wins.
ghst_modal_(Hist, BestColor) :-
% Extract N-C pairs and sort so highest N is last.
    findall(N-C, member(C-N, Hist), NCs),
    msort(NCs, Sorted),
% After reverse, the first element has the highest count.
    reverse(Sorted, [_BestN-BestColor|_]).

% Extract column C from Grid as a top-to-bottom list.
ghst_col_(Grid, C, Col) :-
% Collect the C-th element from each row in order.
    findall(V, (member(Row, Grid), nth0(C, Row, V)), Col).

% --- PUBLIC PREDICATES ---

% ghst_row_hist(+Grid, +R, -Hist)
% Hist is the color frequency histogram for row R: sorted list of Color-Count pairs.
ghst_row_hist(Grid, R, Hist) :-
% Extract row R as a flat list.
    nth0(R, Grid, Row),
% Build histogram from the list.
    ghst_list_hist_(Row, Hist).

% ghst_col_hist(+Grid, +C, -Hist)
% Hist is the color frequency histogram for column C: sorted list of Color-Count pairs.
ghst_col_hist(Grid, C, Hist) :-
% Extract column C as a top-to-bottom list.
    ghst_col_(Grid, C, Col),
% Build histogram from the list.
    ghst_list_hist_(Col, Hist).

% ghst_all_row_hists(+Grid, -AllHists)
% AllHists is the list of histograms for all rows, in row-index order (row 0 first).
ghst_all_row_hists(Grid, AllHists) :-
% Compute the valid row index range.
    length(Grid, H), H1 is H - 1,
% Collect one histogram per row.
    findall(Hist, (between(0, H1, R), ghst_row_hist(Grid, R, Hist)), AllHists).

% ghst_all_col_hists(+Grid, -AllHists)
% AllHists is the list of histograms for all columns, in column-index order.
ghst_all_col_hists(Grid, AllHists) :-
% Determine the number of columns.
    (Grid = [FR|_] -> length(FR, W) ; W = 0),
    W1 is W - 1,
% Collect one histogram per column.
    findall(Hist, (between(0, W1, C), ghst_col_hist(Grid, C, Hist)), AllHists).

% ghst_modal_row(+Grid, +R, -Color)
% Color is the most frequent color in row R. Ties broken by last-in-sort order.
ghst_modal_row(Grid, R, Color) :-
% Get the row histogram.
    ghst_row_hist(Grid, R, Hist),
% Find the color with the highest count.
    ghst_modal_(Hist, Color).

% ghst_modal_col(+Grid, +C, -Color)
% Color is the most frequent color in column C. Ties broken by last-in-sort order.
ghst_modal_col(Grid, C, Color) :-
% Get the column histogram.
    ghst_col_hist(Grid, C, Hist),
% Find the color with the highest count.
    ghst_modal_(Hist, Color).

% ghst_row_count(+Grid, +R, +Color, -Count)
% Count is the number of cells in row R equal to Color.
ghst_row_count(Grid, R, Color, Count) :-
% Extract row R.
    nth0(R, Grid, Row),
% Count occurrences of Color.
    findall(1, member(Color, Row), Ones),
    length(Ones, Count).

% ghst_col_count(+Grid, +C, +Color, -Count)
% Count is the number of cells in column C equal to Color.
ghst_col_count(Grid, C, Color, Count) :-
% Extract column C.
    ghst_col_(Grid, C, Col),
% Count occurrences of Color.
    findall(1, member(Color, Col), Ones),
    length(Ones, Count).

% ghst_row_entropy(+Grid, +R, -N)
% N is the number of distinct colors in row R (color diversity measure).
ghst_row_entropy(Grid, R, N) :-
% Get the row histogram (one entry per distinct color).
    ghst_row_hist(Grid, R, Hist),
% The number of entries equals the number of distinct colors.
    length(Hist, N).

% ghst_col_entropy(+Grid, +C, -N)
% N is the number of distinct colors in column C.
ghst_col_entropy(Grid, C, N) :-
% Get the column histogram.
    ghst_col_hist(Grid, C, Hist),
% Number of entries = number of distinct colors.
    length(Hist, N).

% ghst_max_row(+Grid, +Color, -Row)
% Row is the index of the row with the highest count of Color.
% Fails if Color appears in no row. Ties resolved by highest row index.
ghst_max_row(Grid, Color, Row) :-
% Count Color in every row.
    length(Grid, H), H1 is H - 1,
    findall(N-R, (between(0, H1, R), ghst_row_count(Grid, R, Color, N), N > 0), Pairs),
% Require at least one row with Color.
    Pairs = [_|_],
% Sort ascending by count; last element has maximum count.
    msort(Pairs, Sorted),
    reverse(Sorted, [_-Row|_]).

% ghst_min_row(+Grid, +Color, -Row)
% Row is the index of the row with the smallest count of Color (count > 0).
% Fails if Color appears in no row. Ties resolved by lowest row index.
ghst_min_row(Grid, Color, Row) :-
% Count Color in every row, excluding rows where count is 0.
    length(Grid, H), H1 is H - 1,
    findall(N-R, (between(0, H1, R), ghst_row_count(Grid, R, Color, N), N > 0), Pairs),
% Require at least one row with Color.
    Pairs = [_|_],
% Sort ascending; first element has minimum count (and lowest row index on tie).
    msort(Pairs, [_-Row|_]).

% ghst_rows_with(+Grid, +Color, +N, -Rows)
% Rows is the list of row indices where Color appears at least N times.
ghst_rows_with(Grid, Color, N, Rows) :-
% Compute the valid row index range.
    length(Grid, H), H1 is H - 1,
% Collect every R where the count of Color is >= N.
    findall(R, (between(0, H1, R), ghst_row_count(Grid, R, Color, C), C >= N), Rows).

% ghst_cols_with(+Grid, +Color, +N, -Cols)
% Cols is the list of column indices where Color appears at least N times.
ghst_cols_with(Grid, Color, N, Cols) :-
% Determine the number of columns.
    (Grid = [FR|_] -> length(FR, W) ; W = 0),
    W1 is W - 1,
% Collect every C where the count of Color is >= N.
    findall(C, (between(0, W1, C), ghst_col_count(Grid, C, Color, Cnt), Cnt >= N), Cols).
