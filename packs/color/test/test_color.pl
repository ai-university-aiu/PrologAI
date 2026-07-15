% PLUnit tests for the color pack (cl_* predicates).
:- use_module(library(plunit)).
:- use_module(library(grid)).
:- use_module(library(color)).

% Grid fixtures.
% A 3x3 grid with three distinct colors.
three_color(Grid) :-
    Grid = [[1,2,3],
            [2,3,1],
            [3,1,2]].

% A 2x2 grid with one color.
mono(Grid) :-
    Grid = [[5,5],[5,5]].

% A 3x3 grid with background 0 and two foreground colors.
bg_grid(Grid) :-
    Grid = [[0,1,0],
            [1,0,2],
            [0,2,0]].

% A 4x4 grid where 1 is dominant (8 cells) and 2 is rare (2 cells).
dominant_grid(Grid) :-
    Grid = [[1,1,1,1],
            [1,1,1,1],
            [2,0,0,2],
            [0,0,0,0]].

:- begin_tests(color_palette).

test(palette_three) :-
    three_color(G),
    color_palette(G, P),
    P = [1,2,3].

test(palette_mono) :-
    mono(G),
    color_palette(G, P),
    P = [5].

test(palette_with_bg) :-
    bg_grid(G),
    color_palette(G, P),
    P = [0,1,2].

:- end_tests(color_palette).

:- begin_tests(color_count).

test(count_1) :-
    three_color(G),
    color_count(G, 1, N),
    N =:= 3.

test(count_bg) :-
    bg_grid(G),
    color_count(G, 0, N),
    N =:= 5.

test(count_absent) :-
    mono(G),
    color_count(G, 9, N),
    N =:= 0.

:- end_tests(color_count).

:- begin_tests(color_histogram).

test(histogram_three) :-
    three_color(G),
    color_histogram(G, Hist),
    Hist = [1-3, 2-3, 3-3].

test(histogram_bg) :-
    bg_grid(G),
    color_histogram(G, Hist),
    Hist = [0-5, 1-2, 2-2].

:- end_tests(color_histogram).

:- begin_tests(color_same_palette).

test(same_palette_yes) :-
    three_color(G),
    color_same_palette(G, G).

test(same_palette_no, [fail]) :-
    three_color(G),
    mono(H),
    color_same_palette(G, H).

:- end_tests(color_same_palette).

:- begin_tests(color_replace).

test(replace_basic) :-
    mono(G),
    color_replace(G, 5, 9, G2),
    G2 = [[9,9],[9,9]].

test(replace_absent) :-
    mono(G),
    color_replace(G, 0, 9, G2),
    G2 = G.

test(replace_one_color) :-
    bg_grid(G),
    color_replace(G, 1, 9, G2),
    color_count(G2, 1, N),
    N =:= 0,
    color_count(G2, 9, N9),
    N9 =:= 2.

:- end_tests(color_replace).

:- begin_tests(color_remap).

test(remap_single) :-
    mono(G),
    color_remap(G, [5-7], G2),
    G2 = [[7,7],[7,7]].

test(remap_two) :-
    bg_grid(G),
    color_remap(G, [1-9, 2-8], G2),
    color_count(G2, 9, N9),
    color_count(G2, 8, N8),
    N9 =:= 2,
    N8 =:= 2.

test(remap_identity) :-
    three_color(G),
    color_remap(G, [], G2),
    G2 = G.

:- end_tests(color_remap).

:- begin_tests(color_dominant).

test(dominant_basic) :-
    dominant_grid(G),
    color_dominant(G, Color),
    Color =:= 1.

test(dominant_mono) :-
    mono(G),
    color_dominant(G, Color),
    Color =:= 5.

:- end_tests(color_dominant).

:- begin_tests(color_rarest).

test(rarest_basic) :-
    dominant_grid(G),
    % Grid has 8 ones, 4 zeros, 2 twos. Rarest = 2.
    color_rarest(G, Color),
    Color =:= 2.

test(rarest_mono) :-
    mono(G),
    color_rarest(G, Color),
    Color =:= 5.

:- end_tests(color_rarest).

:- begin_tests(color_isolate).

test(isolate_color1) :-
    bg_grid(G),
    color_isolate(G, 1, 0, G2),
    color_count(G2, 1, N1),
    N1 =:= 2,
    color_count(G2, 2, N2),
    N2 =:= 0.

test(isolate_bg_unchanged) :-
    bg_grid(G),
    color_isolate(G, 0, 9, G2),
    % Only 0s remain; 1s and 2s become 9.
    color_count(G2, 0, N0),
    N0 =:= 5,
    color_count(G2, 1, N1),
    N1 =:= 0.

:- end_tests(color_isolate).

:- begin_tests(color_remove).

test(remove_bg) :-
    bg_grid(G),
    color_remove(G, 0, 9, G2),
    color_count(G2, 0, N),
    N =:= 0,
    color_count(G2, 9, N9),
    N9 =:= 5.

test(remove_absent) :-
    mono(G),
    color_remove(G, 0, 9, G2),
    G2 = G.

:- end_tests(color_remove).

:- begin_tests(color_is_mono).

test(is_mono_yes) :-
    mono(G),
    color_is_mono(G).

test(is_mono_no, [fail]) :-
    three_color(G),
    color_is_mono(G).

:- end_tests(color_is_mono).

:- begin_tests(color_color_count).

test(count_three) :-
    three_color(G),
    color_color_count(G, N),
    N =:= 3.

test(count_one) :-
    mono(G),
    color_color_count(G, N),
    N =:= 1.

:- end_tests(color_color_count).

:- begin_tests(color_has_color).

test(has_yes) :-
    three_color(G),
    color_has_color(G, 2).

test(has_no, [fail]) :-
    mono(G),
    color_has_color(G, 9).

:- end_tests(color_has_color).

:- begin_tests(color_swap).

test(swap_basic) :-
    Grid = [[1,2],[2,1]],
    color_swap(Grid, 1, 2, G2),
    G2 = [[2,1],[1,2]].

test(swap_with_other) :-
    bg_grid(G),
    color_swap(G, 1, 2, G2),
    % bg_grid has [0,1,0],[1,0,2],[0,2,0].
    % After swap: [0,2,0],[2,0,1],[0,1,0].
    G2 = [[0,2,0],[2,0,1],[0,1,0]].

test(swap_absent) :-
    mono(G),
    color_swap(G, 1, 9, G2),
    G2 = G.

:- end_tests(color_swap).
