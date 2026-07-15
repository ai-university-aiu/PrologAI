% Module color: color mapping, palette extraction, recoloring, and color analysis.
% Layer 45. Prefix: cl_. Depends on grid pack only.
:- module(color, [
    % Extract the sorted list of distinct colors used in a grid.
    color_palette/2,
    % Count how many times a specific color appears in a grid.
    color_count/3,
    % Return a histogram: list of Color-Count pairs, sorted by color.
    color_histogram/2,
    % Test whether two grids have the same palette (same set of distinct colors).
    color_same_palette/2,
    % Replace every occurrence of OldColor with NewColor in a grid.
    color_replace/4,
    % Apply a color mapping (list of OldColor-NewColor pairs) to a grid.
    color_remap/3,
    % Return the most frequent color in a grid.
    color_dominant/2,
    % Return the least frequent color in a grid.
    color_rarest/2,
    % Filter: keep only cells of a given color; replace all others with BgColor.
    color_isolate/4,
    % Filter: remove a given color; replace with BgColor.
    color_remove/4,
    % Test whether a grid is monochromatic (contains exactly one distinct color).
    color_is_mono/1,
    % Count the number of distinct colors in a grid.
    color_color_count/2,
    % Test whether a specific color appears in a grid.
    color_has_color/2,
    % Swap two colors in a grid.
    color_swap/4
]).

% Load list utilities.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, last/2,
                                append/2, append/3, max_member/2, min_member/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, foldl/4, include/3]).
% Load grid pack.
:- use_module(library(grid)).

% color_palette(+Grid, -Palette)
% Palette is the sorted list of distinct colors appearing in Grid.
color_palette(Grid, Palette) :-
    gd_size(Grid, Rows, Cols),
    R1 is Rows - 1,
    C1 is Cols - 1,
    findall(Color,
        (   between(0, R1, R),
            between(0, C1, C),
            gd_cell(Grid, R, C, Color)
        ),
        AllColors),
    sort(AllColors, Palette).

% color_count(+Grid, +Color, -N)
% N is the number of cells in Grid with value Color.
color_count(Grid, Color, N) :-
    color_palette_cells_(Grid, Color, Cells),
    length(Cells, N).

% color_palette_cells_(Grid, Color, Cells)
% Collect all (R,C) positions in Grid where the cell color = Color.
color_palette_cells_(Grid, Color, Cells) :-
    gd_size(Grid, Rows, Cols),
    R1 is Rows - 1,
    C1 is Cols - 1,
    findall(r(R,C),
        (   between(0, R1, R),
            between(0, C1, C),
            gd_cell(Grid, R, C, Color)
        ),
        Cells).

% color_histogram(+Grid, -Hist)
% Hist is the list of Color-Count pairs for every color in the palette,
% sorted by Color.
color_histogram(Grid, Hist) :-
    color_palette(Grid, Palette),
    maplist(color_color_count_pair_(Grid), Palette, Hist).

% color_color_count_pair_(Grid, Color, Color-Count)
color_color_count_pair_(Grid, Color, Color-Count) :-
    color_count(Grid, Color, Count).

% color_same_palette(+Grid1, +Grid2)
% Succeed if Grid1 and Grid2 contain exactly the same set of distinct colors.
color_same_palette(Grid1, Grid2) :-
    color_palette(Grid1, P1),
    color_palette(Grid2, P2),
    P1 = P2.

% color_replace(+Grid, +OldColor, +NewColor, -Grid2)
% Replace every occurrence of OldColor with NewColor.
color_replace(Grid, OldColor, NewColor, Grid2) :-
    maplist(color_replace_row_(OldColor, NewColor), Grid, Grid2).

% color_replace_row_(OldColor, NewColor, Row, Row2)
color_replace_row_(OldColor, NewColor, Row, Row2) :-
    maplist(color_replace_cell_(OldColor, NewColor), Row, Row2).

% color_replace_cell_(OldColor, NewColor, Cell, Cell2)
color_replace_cell_(OldColor, NewColor, OldColor, NewColor) :- !.
color_replace_cell_(_Old, _New, Cell, Cell).

% color_remap(+Grid, +Mapping, -Grid2)
% Apply a color mapping to Grid. Mapping is a list of OldColor-NewColor pairs.
% Colors not in the mapping are left unchanged.
color_remap(Grid, Mapping, Grid2) :-
    maplist(color_remap_row_(Mapping), Grid, Grid2).

% color_remap_row_(Mapping, Row, Row2)
color_remap_row_(Mapping, Row, Row2) :-
    maplist(color_remap_cell_(Mapping), Row, Row2).

% color_remap_cell_(Mapping, Color, Color2)
color_remap_cell_(Mapping, Color, Color2) :-
    (   member(Color-Color2, Mapping)
    ->  true
    ;   Color2 = Color
    ).

% color_dominant(+Grid, -Color)
% Color is the most frequently occurring color in Grid.
% On ties, the color with the smaller integer value wins (via max_member on count).
color_dominant(Grid, Color) :-
    color_histogram(Grid, Hist),
    Hist = [_|_],
    color_max_by_count_(Hist, Color).

% color_max_by_count_(Hist, Color) - find Color with highest count.
color_max_by_count_(Hist, Color) :-
    maplist(color_swap_pair_, Hist, CountColor),
    max_member(MaxCount-Color, CountColor),
    number(MaxCount).

% color_swap_pair_(Color-Count, Count-Color)
color_swap_pair_(Color-Count, Count-Color).

% color_rarest(+Grid, -Color)
% Color is the least frequently occurring color in Grid.
color_rarest(Grid, Color) :-
    color_histogram(Grid, Hist),
    Hist = [_|_],
    maplist(color_swap_pair_, Hist, CountColor),
    min_member(MinCount-Color, CountColor),
    number(MinCount).

% color_isolate(+Grid, +Color, +BgColor, -Grid2)
% Keep cells of Color; replace all others with BgColor.
color_isolate(Grid, Color, BgColor, Grid2) :-
    maplist(color_isolate_row_(Color, BgColor), Grid, Grid2).

% color_isolate_row_(Color, BgColor, Row, Row2)
color_isolate_row_(Color, BgColor, Row, Row2) :-
    maplist(color_isolate_cell_(Color, BgColor), Row, Row2).

% color_isolate_cell_(Color, BgColor, Cell, Cell2)
color_isolate_cell_(Color, _BgColor, Color, Color) :- !.
color_isolate_cell_(_Color, BgColor, _Cell, BgColor).

% color_remove(+Grid, +Color, +BgColor, -Grid2)
% Replace all cells of Color with BgColor; keep all others.
color_remove(Grid, Color, BgColor, Grid2) :-
    color_replace(Grid, Color, BgColor, Grid2).

% color_is_mono(+Grid)
% Succeed if Grid contains exactly one distinct color.
color_is_mono(Grid) :-
    color_palette(Grid, Palette),
    Palette = [_].

% color_color_count(+Grid, -N)
% N is the number of distinct colors in Grid.
color_color_count(Grid, N) :-
    color_palette(Grid, Palette),
    length(Palette, N).

% color_has_color(+Grid, +Color)
% Succeed if Grid contains at least one cell of Color.
color_has_color(Grid, Color) :-
    gd_size(Grid, Rows, Cols),
    R1 is Rows - 1,
    C1 is Cols - 1,
    between(0, R1, R),
    between(0, C1, C),
    gd_cell(Grid, R, C, Color),
    !.

% color_swap(+Grid, +ColorA, +ColorB, -Grid2)
% Swap ColorA and ColorB: cells of ColorA become ColorB and vice versa.
color_swap(Grid, ColorA, ColorB, Grid2) :-
    maplist(color_swap_row_(ColorA, ColorB), Grid, Grid2).

% color_swap_row_(ColorA, ColorB, Row, Row2)
color_swap_row_(ColorA, ColorB, Row, Row2) :-
    maplist(color_swap_cell_(ColorA, ColorB), Row, Row2).

% color_swap_cell_(ColorA, ColorB, Cell, Cell2)
color_swap_cell_(ColorA, ColorB, ColorA, ColorB) :- !.
color_swap_cell_(ColorA, ColorB, ColorB, ColorA) :- !.
color_swap_cell_(_A, _B, Cell, Cell).
