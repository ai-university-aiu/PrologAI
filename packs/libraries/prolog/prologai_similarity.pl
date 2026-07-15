/*  PrologAI — library/similarity  (Specification Section 3.14) */

% Declare this file as the 'prologai_similarity' module and list its exported predicates.
:- module(prologai_similarity, [
    % Supply 'prologai_similar/3' as the next argument to the expression above.
    prologai_similar/3,
    % Supply 'prologai_dissimilar/3' as the next argument to the expression above.
    prologai_dissimilar/3,
    % Supply 'prologai_closest_match/4' as the next argument to the expression above.
    prologai_closest_match/4,
    % Supply 'prologai_closest_records/4' as the next argument to the expression above.
    prologai_closest_records/4,
    % Supply 'prologai_similar_signed/3' as the next argument to the expression above.
    prologai_similar_signed/3
% Close the expression opened above.
]).

% Import [maplist/3] from the built-in 'apply' library.
:- use_module(library(apply),  [maplist/3]).
% Import [nth1/3] from the built-in 'lists' library.
:- use_module(library(lists),  [nth1/3]).
% Import [hash_project/3, cosine_similarity/3] from the built-in 'backend_prolog' library.
:- use_module(library(backend_prolog), [hash_project/3, cosine_similarity/3]).

% Declare 'prologai_sim_dim/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic prologai_sim_dim/1.
% State the fact: pai sim dim(32).
prologai_sim_dim(32).

% Define a clause for 'pai similar': succeed when the following conditions hold.
prologai_similar(A, B, Score) :-
    % State a fact for 'pai sim dim' with the arguments listed below.
    prologai_sim_dim(Dim),
    % State a fact for 'hash project' with the arguments listed below.
    hash_project(A, Dim, VA),
    % State a fact for 'hash project' with the arguments listed below.
    hash_project(B, Dim, VB),
    % State a fact for 'cosine similarity' with the arguments listed below.
    cosine_similarity(VA, VB, Raw),
    % Evaluate the arithmetic expression '(Raw + 1.0) / 2.0' and bind the result to 'Score'.
    Score is (Raw + 1.0) / 2.0.

% Define a clause for 'pai dissimilar': succeed when the following conditions hold.
prologai_dissimilar(A, B, Score) :-
    % State a fact for 'pai similar' with the arguments listed below.
    prologai_similar(A, B, S),
    % Evaluate the arithmetic expression '1.0 - S' and bind the result to 'Score'.
    Score is 1.0 - S.

% Define a clause for 'pai closest match': succeed when the following conditions hold.
prologai_closest_match(Probe, Candidates, K, Ranked) :-
    % State a fact for 'maplist' with the arguments listed below.
    maplist([Cand, S-Cand]>>(prologai_similar(Probe, Cand, S)), Candidates, Pairs),
    % Sort list 'Pairs' into 'Sorted', keeping duplicates.
    msort(Pairs, Sorted),
    % State a fact for 'reverse' with the arguments listed below.
    reverse(Sorted, Desc),
    % Unify 'Total' with the number of elements in list 'Desc'.
    length(Desc, Total),
    % Evaluate the arithmetic expression 'min(K, Total)' and bind the result to 'Take'.
    Take is min(K, Total),
    % Unify 'Take' with the number of elements in list 'Ranked'.
    length(Ranked, Take),
    % Unify the third argument with the concatenation of the first two lists.
    append(Ranked, _, Desc).

% Define a clause for 'pai closest records': succeed when the following conditions hold.
prologai_closest_records(Probe, Records, K, Ranked) :-
    % State the fact: pai closest match(Probe, Records, K, Ranked).
    prologai_closest_match(Probe, Records, K, Ranked).

% Define a clause for 'pai similar signed': succeed when the following conditions hold.
prologai_similar_signed(A, B, Score) :-
    % State a fact for 'pai similar' with the arguments listed below.
    prologai_similar(A, B, S),
    % Evaluate the arithmetic expression '2.0 * S - 1.0' and bind the result to 'Score'.
    Score is 2.0 * S - 1.0.
