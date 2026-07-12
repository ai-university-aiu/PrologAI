/*  PrologAI — Causalontology Attention & Broadcast  (WP-410, Layer 385)

    THE_BUILDING_FILES place a single integrating rhythm at the centre of a mind:
    many specialists offer things that might matter, one spotlight scores them,
    a bounded few are held "in mind" at once, and exactly one winner is broadcast
    to the whole system each cognitive cycle. That single-winner broadcast is the
    heartbeat around which learning and action organise.

    This pack is that spotlight, as glass-box PrologAI. A specialist OFFERS an
    item with three plain numbers:

        novelty    how surprising it is (prediction error), in [0, 1]
        relevance  how much it bears on the current goal, in [0, 1]
        affect     how emotionally charged it is, in [-1, 1]

    Salience is a transparent weighted sum, and because both a strong good and a
    strong bad feeling grab attention, affect contributes by its magnitude:

        salience = Wn*novelty + Wr*relevance + Wa*abs(affect)

    The weights are inspectable facts the caller may set. The WORKING SET is the
    best K items — what the mind is holding right now — and the BROADCAST is the
    single most salient item, the one winner the rest of the system reads.

    Predicates:
      sl_reset/0            -- forget every offered item and restore default weights
      sl_set_weights/3      -- +Wnovelty, +Wrelevance, +Waffect
      sl_weights/3          -- ?Wnovelty, ?Wrelevance, ?Waffect
      sl_offer/4            -- +Item, +Novelty, +Relevance, +Affect
      sl_score/2            -- ?Item, -Salience
      sl_candidates/1       -- -Pairs                 (Salience-Item, best first)
      sl_working_set/2      -- +K, -Items             (the best K items in mind)
      sl_broadcast/2        -- -Item, -Salience       (the single winner)
      sl_forget/1           -- +Item                  (drop one candidate)
      sl_count/1            -- -N                      (how many candidates offered)
*/

% Declare this module and its exported predicates.
:- module(co_salience, [
    % sl_reset/0: clear all items and reset the weights.
    sl_reset/0,
    % sl_set_weights/3: set the three salience weights.
    sl_set_weights/3,
    % sl_weights/3: read the three salience weights.
    sl_weights/3,
    % sl_offer/4: a specialist offers a candidate item with its three signals.
    sl_offer/4,
    % sl_score/2: the salience of an offered item.
    sl_score/2,
    % sl_candidates/1: all candidates as Salience-Item pairs, best first.
    sl_candidates/1,
    % sl_working_set/2: the best K items currently in mind.
    sl_working_set/2,
    % sl_broadcast/2: the single most salient winner.
    sl_broadcast/2,
    % sl_forget/1: drop one candidate.
    sl_forget/1,
    % sl_count/1: how many candidates have been offered.
    sl_count/1
]).

% Use the list library for take-style helpers.
:- use_module(library(lists)).

% cand/4 stores one offered candidate; it changes at runtime, so it is dynamic.
:- dynamic cand/4.
% weight/3 stores the three salience weights; dynamic so the caller may tune it.
:- dynamic weight/3.

% sl_reset/0: forget every candidate and restore the default weights.
sl_reset :-
    % Remove all candidates.
    retractall(cand(_,_,_,_)),
    % Remove any existing weights.
    retractall(weight(_,_,_)),
    % Restore a sensible default: novelty and relevance weigh 1.0, affect 0.5.
    assertz(weight(1.0, 1.0, 0.5)).

% sl_set_weights/3: replace the three salience weights.
sl_set_weights(Wn, Wr, Wa) :-
    % Drop the old weights.
    retractall(weight(_,_,_)),
    % Store the new ones.
    assertz(weight(Wn, Wr, Wa)).

% sl_weights/3: read the current weights, defaulting if somehow unset.
sl_weights(Wn, Wr, Wa) :-
    % Read them, or fall back to the defaults.
    ( weight(Wn0, Wr0, Wa0) -> Wn = Wn0, Wr = Wr0, Wa = Wa0
    ; Wn = 1.0, Wr = 1.0, Wa = 0.5 ).

% sl_offer/4: a specialist offers a candidate with its three signal values.
sl_offer(Item, Novelty, Relevance, Affect) :-
    % A re-offer of the same item replaces the earlier one.
    retractall(cand(Item, _, _, _)),
    % Store the candidate's three signals.
    assertz(cand(Item, Novelty, Relevance, Affect)).

% sl_score/2: compute an item's salience from its signals and the weights.
sl_score(Item, Salience) :-
    % Fetch the candidate's three signals.
    cand(Item, Novelty, Relevance, Affect),
    % Read the current weights.
    sl_weights(Wn, Wr, Wa),
    % Affect grabs attention by its magnitude, whichever its sign.
    AbsAffect is abs(Affect),
    % Salience is the transparent weighted sum.
    Salience is Wn*Novelty + Wr*Relevance + Wa*AbsAffect.

% sl_candidates/1: every candidate as a Salience-Item pair, most salient first.
sl_candidates(Pairs) :-
    % Score each stored candidate.
    findall(S-Item, ( cand(Item, _, _, _), sl_score(Item, S) ), Raw),
    % Sort by score descending, keeping ties (both remain).
    sort(1, @>=, Raw, Pairs).

% sl_working_set/2: the best K items the mind is holding right now.
sl_working_set(K, Items) :-
    % Rank all candidates.
    sl_candidates(Pairs),
    % Keep only the items, dropping the scores.
    findall(Item, member(_-Item, Pairs), All),
    % Take at most K from the front.
    sl_take(All, K, Items).

% sl_broadcast/2: the single most salient item and its score.
sl_broadcast(Item, Salience) :-
    % Rank all candidates and take the head.
    sl_candidates([Salience-Item|_]).

% sl_forget/1: drop one candidate from the pool.
sl_forget(Item) :-
    % Remove any candidate matching the item.
    retractall(cand(Item, _, _, _)).

% sl_count/1: how many candidates are currently offered.
sl_count(N) :-
    % Count the candidate facts.
    aggregate_all(count, cand(_,_,_,_), N).

% ---- small internal helper -------------------------------------------------

% sl_take/3: take at most K elements from the front of a list.
sl_take(_, K, []) :-
    % Taking zero or fewer yields the empty list.
    K =< 0, !.
% Taking from an empty list yields the empty list.
sl_take([], _, []) :- !.
% Otherwise keep the head and take K-1 more from the tail.
sl_take([X|Xs], K, [X|Ys]) :-
    K1 is K - 1,
    sl_take(Xs, K1, Ys).
