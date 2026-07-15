% sceneinv.pl - Layer 194: Scene Invariant Detection across Training Pairs (si_* prefix).
% Analyses lists of Before-After pairs to detect structural properties that hold
% across ALL examples: constant object count, constant color set, preserved cell count.
% Pairs are represented as Before-After where each is a list of obj(Color, Cells) terms.
% No cross-pack dependencies.
:- module(scene_invariant, [
    % scene_invariant_n_before/2: object count in the Before scene of one pair.
    scene_invariant_n_before/2,
    % scene_invariant_n_after/2: object count in the After scene of one pair.
    scene_invariant_n_after/2,
    % scene_invariant_all_n_before/2: list of Before object counts for all pairs.
    scene_invariant_all_n_before/2,
    % scene_invariant_all_n_after/2: list of After object counts for all pairs.
    scene_invariant_all_n_after/2,
    % scene_invariant_const_n_before/2: Before object count is constant across all pairs.
    scene_invariant_const_n_before/2,
    % scene_invariant_const_n_after/2: After object count is constant across all pairs.
    scene_invariant_const_n_after/2,
    % scene_invariant_n_preserved/1: Before and After have the same object count in every pair.
    scene_invariant_n_preserved/1,
    % scene_invariant_colors_before/2: sorted distinct colors in the Before scene of one pair.
    scene_invariant_colors_before/2,
    % scene_invariant_colors_after/2: sorted distinct colors in the After scene of one pair.
    scene_invariant_colors_after/2,
    % scene_invariant_const_colors_before/2: Before color set is constant across all pairs.
    scene_invariant_const_colors_before/2,
    % scene_invariant_const_colors_after/2: After color set is constant across all pairs.
    scene_invariant_const_colors_after/2,
    % scene_invariant_colors_preserved/1: Before and After have the same color set in every pair.
    scene_invariant_colors_preserved/1,
    % scene_invariant_total_cells_before/2: total cell count across all Before objects in one pair.
    scene_invariant_total_cells_before/2,
    % scene_invariant_cells_preserved/1: total cell count is the same in Before and After for every pair.
    scene_invariant_cells_preserved/1
]).

% Import list utilities.
:- use_module(library(lists), [member/2, list_to_set/2, sum_list/2]).
% Import higher-order utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% scene_invariant_n_before(+Pair, -N): N is the number of objects in the Before scene.
% Pair must be Before-After where Before is a list of obj terms.
scene_invariant_n_before(Before-_, N) :-
% Count obj terms in Before by measuring list length.
    length(Before, N).

% scene_invariant_n_after(+Pair, -N): N is the number of objects in the After scene.
scene_invariant_n_after(_-After, N) :-
% Count obj terms in After by measuring list length.
    length(After, N).

% scene_invariant_all_n_before(+Pairs, -Ns): Ns is the list of Before object counts, one per pair.
scene_invariant_all_n_before(Pairs, Ns) :-
% Map scene_invariant_n_before over every pair to collect all counts.
    maplist(scene_invariant_n_before, Pairs, Ns).

% scene_invariant_all_n_after(+Pairs, -Ns): Ns is the list of After object counts, one per pair.
scene_invariant_all_n_after(Pairs, Ns) :-
% Map scene_invariant_n_after over every pair to collect all counts.
    maplist(scene_invariant_n_after, Pairs, Ns).

% scene_invariant_const_n_before(+Pairs, -N): N is constant across all Before scenes.
% Fails if Pairs is empty or counts are not all equal.
scene_invariant_const_n_before(Pairs, N) :-
% Reject empty list: no invariant can be claimed.
    Pairs \= [],
% Collect all Before counts.
    scene_invariant_all_n_before(Pairs, Ns),
% list_to_set collapses duplicates; a single element means all values are equal.
    list_to_set(Ns, [N]).

% scene_invariant_const_n_after(+Pairs, -N): N is constant across all After scenes.
% Fails if Pairs is empty or counts are not all equal.
scene_invariant_const_n_after(Pairs, N) :-
% Reject empty list.
    Pairs \= [],
% Collect all After counts.
    scene_invariant_all_n_after(Pairs, Ns),
% Single-element set means all values are equal.
    list_to_set(Ns, [N]).

% scene_invariant_n_preserved(+Pairs): object count is the same in Before and After for every pair.
% Succeeds vacuously for empty Pairs.
scene_invariant_n_preserved(Pairs) :-
% Check each pair individually via the helper.
    maplist(scene_invariant_n_pair_equal_, Pairs).

% scene_invariant_n_pair_equal_(+Pair): Before and After of Pair have the same object count.
scene_invariant_n_pair_equal_(Before-After) :-
% Use the same length variable N for both sides to enforce equality.
    length(Before, N),
    length(After, N).

% scene_invariant_colors_before(+Pair, -Colors): sorted distinct colors in Before.
scene_invariant_colors_before(Before-_, Colors) :-
% Collect all Color atoms from obj(Color, _) terms.
    findall(C, member(obj(C, _), Before), All),
% sort/2 removes duplicates and sorts ascending.
    sort(All, Colors).

% scene_invariant_colors_after(+Pair, -Colors): sorted distinct colors in After.
scene_invariant_colors_after(_-After, Colors) :-
% Collect all Color atoms from obj(Color, _) terms.
    findall(C, member(obj(C, _), After), All),
% sort/2 removes duplicates and sorts ascending.
    sort(All, Colors).

% scene_invariant_const_colors_before(+Pairs, -Colors): Before color set is constant across all pairs.
% Fails if Pairs is empty or color sets differ between pairs.
scene_invariant_const_colors_before(Pairs, Colors) :-
% Reject empty list.
    Pairs \= [],
% Collect sorted color sets for every pair's Before scene.
    maplist(scene_invariant_colors_before, Pairs, AllColors),
% list_to_set on a list of lists: single element means all sets are equal.
    list_to_set(AllColors, [Colors]).

% scene_invariant_const_colors_after(+Pairs, -Colors): After color set is constant across all pairs.
% Fails if Pairs is empty or color sets differ between pairs.
scene_invariant_const_colors_after(Pairs, Colors) :-
% Reject empty list.
    Pairs \= [],
% Collect sorted color sets for every pair's After scene.
    maplist(scene_invariant_colors_after, Pairs, AllColors),
% Single-element set means all color sets are equal.
    list_to_set(AllColors, [Colors]).

% scene_invariant_colors_preserved(+Pairs): Before and After have the same color set in every pair.
% Succeeds vacuously for empty Pairs.
scene_invariant_colors_preserved(Pairs) :-
% Check each pair individually via the helper.
    maplist(scene_invariant_colors_pair_equal_, Pairs).

% scene_invariant_colors_pair_equal_(+Pair): Before and After of Pair have the same color set.
scene_invariant_colors_pair_equal_(Before-After) :-
% Build sorted color set for Before.
    findall(C, member(obj(C, _), Before), AllB),
    sort(AllB, ColorsB),
% Build sorted color set for After.
    findall(C, member(obj(C, _), After), AllA),
    sort(AllA, ColorsA),
% Identical sets means colors are preserved.
    ColorsB == ColorsA.

% scene_invariant_total_cells_before(+Pair, -N): total cell count across all Before objects.
scene_invariant_total_cells_before(Before-_, N) :-
% Collect the cell-list length for each object.
    findall(Len, (member(obj(_, Cells), Before), length(Cells, Len)), Lens),
% Sum all lengths to get the total.
    sum_list(Lens, N).

% scene_invariant_cells_preserved(+Pairs): total cell count is the same in Before and After for every pair.
% Succeeds vacuously for empty Pairs.
scene_invariant_cells_preserved(Pairs) :-
% Check each pair individually via the helper.
    maplist(scene_invariant_cells_pair_equal_, Pairs).

% scene_invariant_cells_pair_equal_(+Pair): total cell count same in Before and After.
scene_invariant_cells_pair_equal_(Before-After) :-
% Compute total cells in Before.
    findall(L, (member(obj(_, Cells), Before), length(Cells, L)), LensB),
    sum_list(LensB, N),
% Compute total cells in After and require equality.
    findall(L, (member(obj(_, Cells), After), length(Cells, L)), LensA),
    sum_list(LensA, N).
