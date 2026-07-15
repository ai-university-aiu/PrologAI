:- module(grid_delta, [
    grid_delta_diff_cells/3,
    grid_delta_diff_count/3,
    grid_delta_same_cells/3,
    grid_delta_changed_pairs/3,
    grid_delta_color_changes/4,
    grid_delta_changed_colors/3,
    grid_delta_apply_delta/4,
    grid_delta_diff_rows/3,
    grid_delta_diff_cols/3,
    grid_delta_compatible/2,
    grid_delta_agree_region/6,
    grid_delta_overlay/4,
    grid_delta_invert_delta/3,
    grid_delta_is_identity/2
]).
% griddelta.pl - Layer 218: Grid Delta Analysis (gdt_* prefix).
% Compares two same-size grids, extracting difference cells, change maps,
% color transitions, and supporting delta application and inversion.
% Raw grid format: list of rows, each a list of color atoms, 0-indexed.
:- use_module(library(lists), [
    nth0/3, member/2, list_to_set/2
]).

% --- PRIVATE HELPERS ---

% Grid dimensions: H rows, W columns.
grid_delta_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed).
grid_delta_cell_(Grid, R, C, V) :-
% Select row R.
    nth0(R, Grid, Row),
% Select column C.
    nth0(C, Row, V).

% Build a new H x W grid using a lambda Goal(R, C, V).
grid_delta_build_(H, W, Goal, Grid) :-
% Compute last indices.
    H1 is H - 1, W1 is W - 1,
% Collect rows.
    findall(Row,
        (between(0, H1, R),
         findall(V, (between(0, W1, C), call(Goal, R, C, V)), Row)),
        Grid).

% --- PUBLIC PREDICATES ---

% grid_delta_compatible(+G1, +G2)
% Succeeds if G1 and G2 have the same number of rows and columns.
grid_delta_compatible(G1, G2) :-
% Both grids must have same H and W.
    grid_delta_dims_(G1, H, W),
    grid_delta_dims_(G2, H, W).

% grid_delta_diff_cells(+G1, +G2, -Cells)
% Cells is the list of R-C pairs where G1 and G2 have different values.
% Row-major order. G1 and G2 must be compatible.
grid_delta_diff_cells(G1, G2, Cells) :-
% Verify compatibility.
    grid_delta_dims_(G1, H, W),
    grid_delta_dims_(G2, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect cells where values differ.
    findall(R-C,
        (between(0, H1, R),
         between(0, W1, C),
         grid_delta_cell_(G1, R, C, V1),
         grid_delta_cell_(G2, R, C, V2),
         V1 \= V2),
        Cells).

% grid_delta_diff_count(+G1, +G2, -Count)
% Count is the number of cells where G1 and G2 differ.
grid_delta_diff_count(G1, G2, Count) :-
    grid_delta_diff_cells(G1, G2, Cells),
    length(Cells, Count).

% grid_delta_same_cells(+G1, +G2, -Cells)
% Cells is the list of R-C pairs where G1 and G2 have equal values.
grid_delta_same_cells(G1, G2, Cells) :-
% Verify compatibility.
    grid_delta_dims_(G1, H, W),
    grid_delta_dims_(G2, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect cells where values agree.
    findall(R-C,
        (between(0, H1, R),
         between(0, W1, C),
         grid_delta_cell_(G1, R, C, V),
         grid_delta_cell_(G2, R, C, V)),
        Cells).

% grid_delta_changed_pairs(+G1, +G2, -Pairs)
% Pairs is the list of R-C-(OldColor->NewColor) terms for each changed cell.
grid_delta_changed_pairs(G1, G2, Pairs) :-
    grid_delta_dims_(G1, H, W),
    grid_delta_dims_(G2, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect (position, old, new) for each changed cell.
    findall(R-C-(V1->V2),
        (between(0, H1, R),
         between(0, W1, C),
         grid_delta_cell_(G1, R, C, V1),
         grid_delta_cell_(G2, R, C, V2),
         V1 \= V2),
        Pairs).

% grid_delta_color_changes(+G1, +G2, +From, -Count)
% Count is the number of cells where G1 has color From and G2 has a different color.
grid_delta_color_changes(G1, G2, From, Count) :-
    grid_delta_dims_(G1, H, W),
    grid_delta_dims_(G2, H, W),
    H1 is H - 1, W1 is W - 1,
% Count cells that changed away from From.
    findall(1,
        (between(0, H1, R),
         between(0, W1, C),
         grid_delta_cell_(G1, R, C, From),
         grid_delta_cell_(G2, R, C, V2),
         V2 \= From),
        Ones),
    length(Ones, Count).

% grid_delta_changed_colors(+G1, +G2, -Colors)
% Colors is the sorted list of distinct colors that appear as new values (in G2)
% at cells that changed from G1 to G2.
grid_delta_changed_colors(G1, G2, Colors) :-
    grid_delta_changed_pairs(G1, G2, Pairs),
% Extract the new color from each pair.
    findall(V2, member(_-_-(_->V2), Pairs), NewVals),
    list_to_set(NewVals, Colors).

% grid_delta_apply_delta(+G1, +G2, +G3, -Result)
% Apply the changes from G1→G2 to G3 to produce Result.
% For each cell where G1 and G2 differ: if G3 has G1's value at that cell,
% replace it with G2's value. Cells where G1=G2 (unchanged) are copied from G3.
grid_delta_apply_delta(G1, G2, G3, Result) :-
    grid_delta_dims_(G1, H, W),
    grid_delta_dims_(G2, H, W),
    grid_delta_dims_(G3, H, W),
% Build result by applying delta to G3.
    grid_delta_build_(H, W,
        [R, C, V]>>(grid_delta_cell_(G1, R, C, V1),
                    grid_delta_cell_(G2, R, C, V2),
                    grid_delta_cell_(G3, R, C, V3),
                    (V1 \= V2, V3 = V1 -> V = V2 ; V = V3)),
        Result).

% grid_delta_diff_rows(+G1, +G2, -Rows)
% Rows is the sorted list of row indices containing at least one changed cell.
grid_delta_diff_rows(G1, G2, Rows) :-
    grid_delta_diff_cells(G1, G2, Cells),
% Extract row indices.
    findall(R, member(R-_, Cells), Rs),
    list_to_set(Rs, Rows).

% grid_delta_diff_cols(+G1, +G2, -Cols)
% Cols is the sorted list of column indices containing at least one changed cell.
grid_delta_diff_cols(G1, G2, Cols) :-
    grid_delta_diff_cells(G1, G2, Cells),
% Extract column indices.
    findall(C, member(_-C, Cells), Cs),
    list_to_set(Cs, Cols).

% grid_delta_agree_region(+G1, +G2, +RowMin, +RowMax, +ColMin, +ColMax)
% Succeeds if G1 and G2 agree on all cells in the rectangular region
% [RowMin..RowMax] x [ColMin..ColMax].
grid_delta_agree_region(G1, G2, RowMin, RowMax, ColMin, ColMax) :-
% No cell in the region differs.
    \+ (between(RowMin, RowMax, R),
        between(ColMin, ColMax, C),
        grid_delta_cell_(G1, R, C, V1),
        grid_delta_cell_(G2, R, C, V2),
        V1 \= V2).

% grid_delta_overlay(+G1, +G2, +Marker, -Result)
% Result is G1 with cells from G2 overlaid wherever G2 is NOT Marker.
% Cells where G2 equals Marker are taken from G1 (transparent).
grid_delta_overlay(G1, G2, Marker, Result) :-
    grid_delta_dims_(G1, H, W),
    grid_delta_dims_(G2, H, W),
% Build result: use G2 where non-Marker, else G1.
    grid_delta_build_(H, W,
        [R, C, V]>>(grid_delta_cell_(G2, R, C, V2),
                    grid_delta_cell_(G1, R, C, V1),
                    (V2 \= Marker -> V = V2 ; V = V1)),
        Result).

% grid_delta_invert_delta(+G1, +G2, -Inverted)
% Inverted is a grid that is G2 with the changed cells restored to G1's values.
% Equivalent to applying the reverse delta (G2→G1) to G2.
grid_delta_invert_delta(G1, G2, Inverted) :-
    grid_delta_dims_(G1, H, W),
    grid_delta_dims_(G2, H, W),
% For each changed cell in G2, put back G1's value.
    grid_delta_build_(H, W,
        [R, C, V]>>(grid_delta_cell_(G1, R, C, V1),
                    grid_delta_cell_(G2, R, C, V2),
                    (V1 \= V2 -> V = V1 ; V = V2)),
        Inverted).

% grid_delta_is_identity(+G1, +G2)
% Succeeds if G1 and G2 are identical (no differences).
grid_delta_is_identity(G1, G2) :-
    grid_delta_diff_count(G1, G2, 0).
