% multicolor: multi-color scene analysis — frequency, partition, and queries (mc_*, Layer 193)
:- module(multi_color, [
    multi_color_color_counts/2,
    multi_color_count_of_color/3,
    multi_color_color_present/2,
    multi_color_dominant_color/2,
    multi_color_rarest_color/2,
    multi_color_singleton_colors/2,
    multi_color_unique_color/2,
    multi_color_color_freq_rank/3,
    multi_color_color_partition/2,
    multi_color_pair_colors/2,
    multi_color_equal_count_pairs/2,
    multi_color_majority_color/2,
    multi_color_n_distinct_colors/2,
    multi_color_color_index/3
]).

% Load list utilities for member, subtract, append, list_to_set
:- use_module(library(lists), [member/2, subtract/3, append/3, list_to_set/2]).
% Load apply utilities for include and maplist
:- use_module(library(apply), [include/3, maplist/3]).

% multi_color_color_counts(+Scene, -Counts)
% Counts is a sorted list of Color-N pairs, one per distinct color.
% N is the number of objects of that color.
multi_color_color_counts(Scene, Counts) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors),
    findall(C-N, (member(C, Colors), multi_color_count_of_color_(Scene, C, N)), Counts).

% multi_color_count_of_color_(+Scene, +Color, -N): count objects of Color in Scene
multi_color_count_of_color_(Scene, Color, N) :-
    findall(_, (member(obj(C, _), Scene), C == Color), Matches),
    length(Matches, N).

% multi_color_count_of_color(+Scene, +Color, -N)
% N is the number of objects of Color in Scene. N=0 if Color not present.
multi_color_count_of_color(Scene, Color, N) :-
    multi_color_count_of_color_(Scene, Color, N).

% multi_color_color_present(+Scene, +Color)
% Succeed if Color appears in at least one object in Scene.
multi_color_color_present(Scene, Color) :-
    member(obj(C, _), Scene),
    C == Color,
    !.

% multi_color_dominant_color(+Scene, -Color)
% Color with the most objects. Ties broken by standard term order.
multi_color_dominant_color(Scene, Color) :-
    multi_color_color_counts(Scene, Counts),
    Counts \= [],
    findall(NegN-C, (member(C-N, Counts), NegN is -N), Keyed),
    msort(Keyed, [_-Color | _]).

% multi_color_rarest_color(+Scene, -Color)
% Color with the fewest objects. Ties broken by standard term order.
multi_color_rarest_color(Scene, Color) :-
    multi_color_color_counts(Scene, Counts),
    Counts \= [],
    findall(N-C, member(C-N, Counts), Keyed),
    msort(Keyed, [_-Color | _]).

% multi_color_singleton_colors(+Scene, -Colors)
% All colors that appear in exactly one object.
multi_color_singleton_colors(Scene, Colors) :-
    multi_color_color_counts(Scene, Counts),
    findall(C, member(C-1, Counts), Colors).

% multi_color_unique_color(+Scene, -Color)
% Backtrackable: each color that appears in exactly one object.
multi_color_unique_color(Scene, Color) :-
    multi_color_color_counts(Scene, Counts),
    member(Color-1, Counts).

% multi_color_color_freq_rank(+Scene, +N, -Color)
% The Nth most frequent color (1 = most frequent). Fails if N > number of distinct colors.
multi_color_color_freq_rank(Scene, N, Color) :-
    multi_color_color_counts(Scene, Counts),
    findall(NegCount-C, (member(C-Count, Counts), NegCount is -Count), Keyed),
    msort(Keyed, Sorted),
    findall(C, member(_-C, Sorted), Ranked),
    nth1(N, Ranked, Color).

% multi_color_color_partition(+Scene, -Groups)
% Groups is a list of Color-Objs pairs, one per distinct color.
% Objs is the list of all objects of that color.
multi_color_color_partition(Scene, Groups) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors),
    findall(C-Objs, (member(C, Colors), findall(O, (member(O, Scene), O=obj(C,_)), Objs)), Groups).

% multi_color_pair_colors(+Scene, -Pairs)
% All unordered pairs of distinct colors {C1, C2} as sorted C1-C2 terms (C1 @< C2).
multi_color_pair_colors(Scene, Pairs) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors),
    findall(C1-C2, (member(C1, Colors), member(C2, Colors), C1 @< C2), Pairs).

% multi_color_equal_count_pairs(+Scene, -Pairs)
% All unordered pairs of colors that have equal object count.
multi_color_equal_count_pairs(Scene, Pairs) :-
    multi_color_color_counts(Scene, Counts),
    findall(C1-C2,
        (member(C1-N, Counts),
         member(C2-N, Counts),
         C1 @< C2),
        Pairs).

% multi_color_majority_color(+Scene, -Color)
% Color whose object count exceeds half the total scene size.
% Fails if no such color exists.
multi_color_majority_color(Scene, Color) :-
    length(Scene, Total),
    Half is Total / 2,
    multi_color_color_counts(Scene, Counts),
    member(Color-N, Counts),
    N > Half,
    !.

% multi_color_n_distinct_colors(+Scene, -N)
% Number of distinct colors in the scene.
multi_color_n_distinct_colors(Scene, N) :-
    findall(C, member(obj(C, _), Scene), All),
    sort(All, Colors),
    length(Colors, N).

% multi_color_color_index(+Scene, +Color, -Index)
% 1-based rank of Color by descending frequency.
% The most frequent color has index 1.
multi_color_color_index(Scene, Color, Index) :-
    multi_color_color_counts(Scene, Counts),
    findall(NegN-C, (member(C-N, Counts), NegN is -N), Keyed),
    msort(Keyed, Sorted),
    findall(C, member(_-C, Sorted), Ranked),
    nth1(Index, Ranked, Color).
