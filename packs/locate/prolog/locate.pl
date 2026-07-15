% Pattern location: subgrid matching, row/column search, value anchor.
% Work Package 139, Layer 118.
:- module(locate, [
    locate_subgrid_at/4, locate_find_sub/4, locate_all_sub/3, locate_subgrid_count/3,
    locate_row_pattern/3, locate_all_row_pattern/3, locate_col_pattern/3,
    locate_all_col_pattern/3, locate_row_prefix/4, locate_row_suffix/3,
    locate_anchor/4, locate_row_count/3, locate_row_contains/3, locate_col_contains/3
]).
% Import list predicates needed by the module
:- use_module(library(lists), [member/2, nth0/3, append/3]).
% Import maplist/3 for per-row counting
:- use_module(library(apply), [maplist/3]).

% locate_subgrid_at(+Grid, +Sub, +R0, +C0): succeed if Sub appears at top-left (R0,C0) in Grid.
% Uses forall/2 to verify every Sub cell equals the corresponding Grid cell.
locate_subgrid_at(Grid, Sub, R0, C0) :-
    % compute last Sub row and column indices
    length(Sub, SH), SH1 is SH - 1,
    % extract Sub width from first row; 0 for empty Sub
    (Sub = [SFr|_] -> length(SFr, SW) ; SW = 0), SW1 is SW - 1,
    % every Sub position must match the Grid cell at the corresponding offset
    forall(
        (between(0, SH1, SR), between(0, SW1, SC)),
        (GR is R0 + SR, GC is C0 + SC,
         nth0(GR, Grid, GRow), nth0(GC, GRow, V),
         nth0(SR, Sub, SRow), nth0(SC, SRow, V))
    ).

% locate_find_sub(+Grid, +Sub, -R0, -C0): first row-major position where Sub matches Grid.
% Deterministic via cut after first match. Fails if Sub does not appear.
locate_find_sub(Grid, Sub, R0, C0) :-
    % compute Grid dimensions
    length(Grid, H), (Grid = [Fr|_] -> length(Fr, W) ; W = 0),
    % compute Sub dimensions
    length(Sub, SH), (Sub = [SFr|_] -> length(SFr, SW) ; SW = 0),
    % compute the last valid top-left position for Sub inside Grid
    MaxR is H - SH, MaxC is W - SW,
    % enumerate candidate positions in row-major order
    between(0, MaxR, R0),
    between(0, MaxC, C0),
    % test match and commit on the first success
    locate_subgrid_at(Grid, Sub, R0, C0), !.

% locate_all_sub(+Grid, +Sub, -Positions): list of all R0-C0 where Sub matches Grid.
locate_all_sub(Grid, Sub, Positions) :-
    % compute Grid dimensions
    length(Grid, H), (Grid = [Fr|_] -> length(Fr, W) ; W = 0),
    % compute Sub dimensions
    length(Sub, SH), (Sub = [SFr|_] -> length(SFr, SW) ; SW = 0),
    % compute last valid top-left positions
    MaxR is H - SH, MaxC is W - SW,
    % collect every matching position
    findall(R0-C0, (
        between(0, MaxR, R0), between(0, MaxC, C0),
        locate_subgrid_at(Grid, Sub, R0, C0)
    ), Positions).

% locate_subgrid_count(+Grid, +Sub, -N): count how many times Sub appears in Grid.
locate_subgrid_count(Grid, Sub, N) :-
    % collect all positions then measure the result list
    locate_all_sub(Grid, Sub, Positions),
    length(Positions, N).

% locate_row_pattern(+Grid, +Pattern, -R): first row index where row equals Pattern.
% Deterministic via cut after first match. Fails if no row matches.
locate_row_pattern(Grid, Pattern, R) :-
    % enumerate row indices from 0
    length(Grid, H), H1 is H - 1,
    between(0, H1, R),
    % unify row R with Pattern; succeeds on the first match
    nth0(R, Grid, Pattern), !.

% locate_all_row_pattern(+Grid, +Pattern, -Rows): all row indices where row equals Pattern.
locate_all_row_pattern(Grid, Pattern, Rows) :-
    % enumerate and collect matching row indices
    length(Grid, H), H1 is H - 1,
    findall(R, (between(0, H1, R), nth0(R, Grid, Pattern)), Rows).

% locate_col_pattern(+Grid, +Pattern, -C): first column index whose value list equals Pattern.
% Deterministic via cut after first match. Fails if no column matches.
locate_col_pattern(Grid, Pattern, C) :-
    % compute column range
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    % compute row range
    length(Grid, H), H1 is H - 1,
    % enumerate columns; extract each as a value list and compare with Pattern
    between(0, W1, C),
    findall(V, (between(0, H1, R), nth0(R, Grid, Row), nth0(C, Row, V)), Pattern), !.

% locate_all_col_pattern(+Grid, +Pattern, -Cols): all column indices whose value list equals Pattern.
locate_all_col_pattern(Grid, Pattern, Cols) :-
    % compute column range
    (Grid = [Fr|_] -> length(Fr, W) ; W = 0), W1 is W - 1,
    % compute row range
    length(Grid, H), H1 is H - 1,
    % collect every column whose value list unifies with Pattern
    findall(C, (
        between(0, W1, C),
        findall(V, (between(0, H1, R), nth0(R, Grid, Row), nth0(C, Row, V)), Pattern)
    ), Cols).

% locate_row_prefix(+Grid, +R, +Prefix, -Rest): decompose grid row R as Prefix ++ Rest.
% Prefix can be [] (trivially matches) or any list; Rest is bound on success.
locate_row_prefix(Grid, R, Prefix, Rest) :-
    % retrieve the row at index R
    nth0(R, Grid, Row),
    % split the row via append
    append(Prefix, Rest, Row).

% locate_row_suffix(+Grid, +R, +Suffix): succeed if grid row R ends with Suffix.
% Cut after first match: existence test only, not a generator.
locate_row_suffix(Grid, R, Suffix) :-
    % retrieve the row at index R
    nth0(R, Grid, Row),
    % find any prefix such that prefix ++ Suffix = Row; commit on first
    append(_, Suffix, Row), !.

% locate_anchor(+Grid, +V, -R, -C): succeed if exactly one cell in Grid equals V.
% Fails if V appears zero times or more than once.
locate_anchor(Grid, V, R, C) :-
    % compute Grid dimensions
    length(Grid, H), H1 is H - 1,
    (Grid = [GFr|_] -> length(GFr, W) ; W = 0), W1 is W - 1,
    % collect all R-C positions with value V
    findall(Rr-Cc, (
        between(0, H1, Rr), between(0, W1, Cc),
        nth0(Rr, Grid, Row), nth0(Cc, Row, V)
    ), Cells),
    % exactly one occurrence required; extract and unpack
    Cells = [R-C].

% locate_row_count(+Grid, +V, -Counts): list with count of V per row, one element per row.
locate_row_count(Grid, V, Counts) :-
    % apply the private counter to each row via maplist
    maplist(locate_count_in_row_(V), Grid, Counts).

% Private helper: count occurrences of V in a single row.
locate_count_in_row_(V, Row, N) :-
    % member(V, Row) backtracks once per occurrence; findall counts them
    findall(_, member(V, Row), Ks),
    % N is the number of occurrences
    length(Ks, N).

% locate_row_contains(+Grid, +V, -Rows): sorted list of row indices that contain V.
locate_row_contains(Grid, V, Rows) :-
    % compute last row index
    length(Grid, H), H1 is H - 1,
    findall(R, (
        between(0, H1, R),
        nth0(R, Grid, Row),
        % member/2 succeeds if V appears anywhere in Row
        member(V, Row)
    ), Unsorted),
    % sort removes duplicate indices if V appears multiple times in a row
    sort(Unsorted, Rows).

% locate_col_contains(+Grid, +V, -Cols): sorted list of column indices that contain V.
locate_col_contains(Grid, V, Cols) :-
    % compute dimensions
    length(Grid, H), H1 is H - 1,
    (Grid = [GFr|_] -> length(GFr, W) ; W = 0), W1 is W - 1,
    findall(C, (
        between(0, W1, C),
        between(0, H1, R),
        nth0(R, Grid, Row), nth0(C, Row, V)
    ), Unsorted),
    % sort removes duplicate column indices if V appears in multiple rows of same column
    sort(Unsorted, Cols).
