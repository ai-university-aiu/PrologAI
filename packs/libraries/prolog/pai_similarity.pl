/*  PrologAI — library/similarity  (Specification Section 3.14) */

:- module(pai_similarity, [
    pai_similar/3,
    pai_dissimilar/3,
    pai_closest_match/4,
    pai_closest_records/4,
    pai_similar_signed/3
]).

:- use_module(library(apply),  [maplist/3]).
:- use_module(library(lists),  [nth1/3]).
:- use_module(library(backend_prolog), [hash_project/3, cosine_similarity/3]).

:- dynamic pai_sim_dim/1.
pai_sim_dim(32).

pai_similar(A, B, Score) :-
    pai_sim_dim(Dim),
    hash_project(A, Dim, VA),
    hash_project(B, Dim, VB),
    cosine_similarity(VA, VB, Raw),
    Score is (Raw + 1.0) / 2.0.

pai_dissimilar(A, B, Score) :-
    pai_similar(A, B, S),
    Score is 1.0 - S.

pai_closest_match(Probe, Candidates, K, Ranked) :-
    maplist([Cand, S-Cand]>>(pai_similar(Probe, Cand, S)), Candidates, Pairs),
    msort(Pairs, Sorted),
    reverse(Sorted, Desc),
    length(Desc, Total),
    Take is min(K, Total),
    length(Ranked, Take),
    append(Ranked, _, Desc).

pai_closest_records(Probe, Records, K, Ranked) :-
    pai_closest_match(Probe, Records, K, Ranked).

pai_similar_signed(A, B, Score) :-
    pai_similar(A, B, S),
    Score is 2.0 * S - 1.0.
