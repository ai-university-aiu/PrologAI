:- module(griddelta, [
    gdt_diff_cells/3,
    gdt_diff_count/3,
    gdt_same_cells/3,
    gdt_changed_pairs/3,
    gdt_color_changes/4,
    gdt_changed_colors/3,
    gdt_apply_delta/4,
    gdt_diff_rows/3,
    gdt_diff_cols/3,
    gdt_compatible/2,
    gdt_agree_region/6,
    gdt_overlay/4,
    gdt_invert_delta/3,
    gdt_is_identity/2
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
gdt_dims_(Grid, H, W) :-
% Count rows.
    length(Grid, H),
% Count columns from first row.
    (H > 0 -> Grid = [FR|_], length(FR, W) ; W = 0).

% Cell value at row R, column C (0-indexed).
gdt_cell_(Grid, R, C, V) :-
% Select row R.
    nth0(R, Grid, Row),
% Select column C.
    nth0(C, Row, V).

% Build a new H x W grid using a lambda Goal(R, C, V).
gdt_build_(H, W, Goal, Grid) :-
% Compute last indices.
    H1 is H - 1, W1 is W - 1,
% Collect rows.
    findall(Row,
        (between(0, H1, R),
         findall(V, (between(0, W1, C), call(Goal, R, C, V)), Row)),
        Grid).

% --- PUBLIC PREDICATES ---

% gdt_compatible(+G1, +G2)
% Succeeds if G1 and G2 have the same number of rows and columns.
gdt_compatible(G1, G2) :-
% Both grids must have same H and W.
    gdt_dims_(G1, H, W),
    gdt_dims_(G2, H, W).

% gdt_diff_cells(+G1, +G2, -Cells)
% Cells is the list of R-C pairs where G1 and G2 have different values.
% Row-major order. G1 and G2 must be compatible.
gdt_diff_cells(G1, G2, Cells) :-
% Verify compatibility.
    gdt_dims_(G1, H, W),
    gdt_dims_(G2, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect cells where values differ.
    findall(R-C,
        (between(0, H1, R),
         between(0, W1, C),
         gdt_cell_(G1, R, C, V1),
         gdt_cell_(G2, R, C, V2),
         V1 \= V2),
        Cells).

% gdt_diff_count(+G1, +G2, -Count)
% Count is the number of cells where G1 and G2 differ.
gdt_diff_count(G1, G2, Count) :-
    gdt_diff_cells(G1, G2, Cells),
    length(Cells, Count).

% gdt_same_cells(+G1, +G2, -Cells)
% Cells is the list of R-C pairs where G1 and G2 have equal values.
gdt_same_cells(G1, G2, Cells) :-
% Verify compatibility.
    gdt_dims_(G1, H, W),
    gdt_dims_(G2, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect cells where values agree.
    findall(R-C,
        (between(0, H1, R),
         between(0, W1, C),
         gdt_cell_(G1, R, C, V),
         gdt_cell_(G2, R, C, V)),
        Cells).

% gdt_changed_pairs(+G1, +G2, -Pairs)
% Pairs is the list of R-C-(OldColor->NewColor) terms for each changed cell.
gdt_changed_pairs(G1, G2, Pairs) :-
    gdt_dims_(G1, H, W),
    gdt_dims_(G2, H, W),
    H1 is H - 1, W1 is W - 1,
% Collect (position, old, new) for each changed cell.
    findall(R-C-(V1->V2),
        (between(0, H1, R),
         between(0, W1, C),
         gdt_cell_(G1, R, C, V1),
         gdt_cell_(G2, R, C, V2),
         V1 \= V2),
        Pairs).

% gdt_color_changes(+G1, +G2, +From, -Count)
% Count is the number of cells where G1 has color From and G2 has a different color.
gdt_color_changes(G1, G2, From, Count) :-
    gdt_dims_(G1, H, W),
    gdt_dims_(G2, H, W),
    H1 is H - 1, W1 is W - 1,
% Count cells that changed away from From.
    findall(1,
        (between(0, H1, R),
         between(0, W1, C),
         gdt_cell_(G1, R, C, From),
         gdt_cell_(G2, R, C, V2),
         V2 \= From),
        Ones),
    length(Ones, Count).

% gdt_changed_colors(+G1, +G2, -Colors)
% Colors is the sorted list of distinct colors that appear as new values (in G2)
% at cells that changed from G1 to G2.
gdt_changed_colors(G1, G2, Colors) :-
    gdt_changed_pairs(G1, G2, Pairs),
% Extract the new color from each pair.
    findall(V2, member(_-_-(_->V2), Pairs), NewVals),
    list_to_set(NewVals, Colors).

% gdt_apply_delta(+G1, +G2, +G3, -Result)
% Apply the changes from G1→G2 to G3 to produce Result.
% For each cell where G1 and G2 differ: if G3 has G1's value at that cell,
% replace it with G2's value. Cells where G1=G2 (unchanged) are copied from G3.
gdt_apply_delta(G1, G2, G3, Result) :-
    gdt_dims_(G1, H, W),
    gdt_dims_(G2, H, W),
    gdt_dims_(G3, H, W),
% Build result by applying delta to G3.
    gdt_build_(H, W,
        [R, C, V]>>(gdt_cell_(G1, R, C, V1),
                    gdt_cell_(G2, R, C, V2),
                    gdt_cell_(G3, R, C, V3),
                    (V1 \= V2, V3 = V1 -> V = V2 ; V = V3)),
        Result).

% gdt_diff_rows(+G1, +G2, -Rows)
% Rows is the sorted list of row indices containing at least one changed cell.
gdt_diff_rows(G1, G2, Rows) :-
    gdt_diff_cells(G1, G2, Cells),
% Extract row indices.
    findall(R, member(R-_, Cells), Rs),
    list_to_set(Rs, Rows).

% gdt_diff_cols(+G1, +G2, -Cols)
% Cols is the sorted list of column indices containing at least one changed cell.
gdt_diff_cols(G1, G2, Cols) :-
    gdt_diff_cells(G1, G2, Cells),
% Extract column indices.
    findall(C, member(_-C, Cells), Cs),
    list_to_set(Cs, Cols).

% gdt_agree_region(+G1, +G2, +RowMin, +RowMax, +ColMin, +ColMax)
% Succeeds if G1 and G2 agree on all cells in the rectangular region
% [RowMin..RowMax] x [ColMin..ColMax].
gdt_agree_region(G1, G2, RowMin, RowMax, ColMin, ColMax) :-
% No cell in the region differs.
    \+ (between(RowMin, RowMax, R),
        between(ColMin, ColMax, C),
        gdt_cell_(G1, R, C, V1),
        gdt_cell_(G2, R, C, V2),
        V1 \= V2).

% gdt_overlay(+G1, +G2, +Marker, -Result)
% Result is G1 with cells from G2 overlaid wherever G2 is NOT Marker.
% Cells where G2 equals Marker are taken from G1 (transparent).
gdt_overlay(G1, G2, Marker, Result) :-
    gdt_dims_(G1, H, W),
    gdt_dims_(G2, H, W),
% Build result: use G2 where non-Marker, else G1.
    gdt_build_(H, W,
        [R, C, V]>>(gdt_cell_(G2, R, C, V2),
                    gdt_cell_(G1, R, C, V1),
                    (V2 \= Marker -> V = V2 ; V = V1)),
        Result).

% gdt_invert_delta(+G1, +G2, -Inverted)
% Inverted is a grid that is G2 with the changed cells restored to G1's values.
% Equivalent to applying the reverse delta (G2→G1) to G2.
gdt_invert_delta(G1, G2, Inverted) :-
    gdt_dims_(G1, H, W),
    gdt_dims_(G2, H, W),
% For each changed cell in G2, put back G1's value.
    gdt_build_(H, W,
        [R, C, V]>>(gdt_cell_(G1, R, C, V1),
                    gdt_cell_(G2, R, C, V2),
                    (V1 \= V2 -> V = V1 ; V = V2)),
        Inverted).

% gdt_is_identity(+G1, +G2)
% Succeeds if G1 and G2 are identical (no differences).
gdt_is_identity(G1, G2) :-
    gdt_diff_count(G1, G2, 0).
