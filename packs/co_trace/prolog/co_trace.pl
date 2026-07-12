/*  PrologAI — Causalontology Episodic Memory  (WP-409, Layer 384)

    THE_BUILDING_FILES argue that a mind must keep a record of past episodes it
    can be reminded of — "this reminds me of last time." The co_ family had a
    causal store (co_core) and a concept backbone (co_noun) but no memory of
    lived experience. This pack is that memory, built the Causalontology way:
    each episode is a small reified case that can be recalled by how much its
    context overlaps a present cue, replayed, and reinforced when it helps.

    An EPISODE is a case:

        episode(Id, Context, Action, Outcome, Valence, Recency, Hits)

      Context  a set (list) of feature atoms describing the situation.
      Action   what was done in that situation.
      Outcome  what followed.
      Valence  how good/bad it was, in [-1, 1].
      Recency  a monotonically rising stamp (higher = more recent); it is an
               internal counter, not a wall clock, so recall is deterministic
               and the pack stays self-contained and testable.
      Hits     how many times this episode has since been recalled — a cheap
               measure of how useful the memory has proved.

    Recall is by feature overlap: the similarity of a cue to an episode is the
    Jaccard overlap of their context sets (shared features over total distinct
    features), so the most relevant memory surfaces first. This is the
    glass-box, inspectable analogue of an associative memory.

    Predicates:
      ct_reset/0            -- forget every episode
      ct_record/4           -- +Context, +Action, +Outcome, +Valence  (store one)
      ct_record/5           -- ... , -Id                               (store, return id)
      ct_episode/6          -- ?Id, ?Context, ?Action, ?Outcome, ?Valence, ?Recency
      ct_similarity/3       -- +Cue, +Id, -Score        (Jaccard overlap in [0,1])
      ct_remind/3           -- +Cue, +K, -TopK          (best K episodes, best first)
      ct_recall/3           -- +Cue, -Id, -Score        (single best match; bumps Hits)
      ct_replay/4           -- +Id, -Action, -Outcome, -Valence
      ct_reinforce/2        -- +Id, +Delta              (nudge an episode's valence)
      ct_hits/2             -- ?Id, ?Hits
      ct_count/1            -- -N                        (how many episodes stored)
      ct_stats/1            -- -stats(Count, MeanValence)
*/

% Declare this module and list every exported predicate with its arity.
:- module(co_trace, [
    % ct_reset/0: forget every episode.
    ct_reset/0,
    % ct_record/4: store an episode from its four parts.
    ct_record/4,
    % ct_record/5: store an episode and return its fresh id.
    ct_record/5,
    % ct_episode/6: query stored episodes.
    ct_episode/6,
    % ct_similarity/3: score a cue against one episode's context.
    ct_similarity/3,
    % ct_remind/3: the best K episodes for a cue, best first.
    ct_remind/3,
    % ct_recall/3: the single best-matching episode, bumping its hit count.
    ct_recall/3,
    % ct_replay/4: read back what an episode did and how it turned out.
    ct_replay/4,
    % ct_reinforce/2: nudge an episode's valence by a delta.
    ct_reinforce/2,
    % ct_hits/2: how many times an episode has been recalled.
    ct_hits/2,
    % ct_count/1: how many episodes are stored.
    ct_count/1,
    % ct_stats/1: a small summary of the store.
    ct_stats/1
]).

% Use the list library for member, subtract, and friends.
:- use_module(library(lists)).
% Use gensym to mint fresh episode identifiers.
:- use_module(library(gensym)).

% episode/7 is the stored case; it changes at runtime, so declare it dynamic.
:- dynamic episode/7.
% ct_clock/1 holds the rising recency counter; declare it dynamic too.
:- dynamic ct_clock/1.

% ct_reset/0: retract every episode and restart the recency clock at zero.
ct_reset :-
    % Remove all stored episodes.
    retractall(episode(_,_,_,_,_,_,_)),
    % Remove any existing clock value.
    retractall(ct_clock(_)),
    % Seed the clock at zero.
    assertz(ct_clock(0)).

% ct_tick/1: consume the next recency stamp, advancing the clock by one.
ct_tick(Next) :-
    % Read the current clock, defaulting to zero if unset.
    ( retract(ct_clock(Now)) -> true ; Now = 0 ),
    % The next stamp is one greater.
    Next is Now + 1,
    % Store the advanced clock.
    assertz(ct_clock(Next)).

% ct_record/4: store an episode without needing its id back.
ct_record(Context, Action, Outcome, Valence) :-
    % Delegate to the id-returning form and discard the id.
    ct_record(Context, Action, Outcome, Valence, _).

% ct_record/5: store an episode and return a fresh identifier.
ct_record(Context, Action, Outcome, Valence, Id) :-
    % Normalise the context into a sorted set of distinct features.
    sort(Context, Feats),
    % Clamp the valence into the legal [-1, 1] band.
    ct_clamp(Valence, -1, 1, V),
    % Take the next recency stamp.
    ct_tick(R),
    % Mint a fresh episode identifier.
    gensym(ep_, Id),
    % Assert the new case with a zero hit count.
    assertz(episode(Id, Feats, Action, Outcome, V, R, 0)).

% ct_episode/6: expose the stored cases without the internal hit count.
ct_episode(Id, Context, Action, Outcome, Valence, Recency) :-
    % Read the underlying seven-place fact, hiding Hits.
    episode(Id, Context, Action, Outcome, Valence, Recency, _).

% ct_similarity/3: the Jaccard overlap of a cue's features with an episode's.
ct_similarity(Cue, Id, Score) :-
    % Normalise the cue into a set.
    sort(Cue, CueSet),
    % Fetch the episode's stored (already sorted) context.
    episode(Id, Feats, _, _, _, _, _),
    % Count the features shared by both sets.
    intersection(CueSet, Feats, Shared),
    length(Shared, NShared),
    % Count the distinct features across both sets (the union).
    union(CueSet, Feats, All),
    length(All, NAll),
    % Jaccard overlap is shared over union; an empty union scores zero.
    ( NAll =:= 0 -> Score = 0.0 ; Score is NShared / NAll ).

% ct_remind/3: the best K episodes for a cue, most similar first.
ct_remind(Cue, K, TopK) :-
    % Score every stored episode against the cue.
    findall(Score-Id,
            ( episode(Id, _, _, _, _, _, _),
              ct_similarity(Cue, Id, Score),
              % Ignore episodes that share nothing with the cue.
              Score > 0.0 ),
            Pairs),
    % Sort by score descending, keeping duplicates (keysort then reverse).
    sort(1, @>=, Pairs, Ranked),
    % Keep only the identifiers, dropping the scores.
    pairs_values_local(Ranked, Ids),
    % Take at most K of them.
    ct_take(Ids, K, TopK).

% ct_recall/3: the single best-matching episode, whose hit count is then bumped.
ct_recall(Cue, Id, Score) :-
    % Ask for the best one episode.
    ct_remind(Cue, 1, [Id|_]),
    % Report its similarity to the cue.
    ct_similarity(Cue, Id, Score),
    % Reward the memory for being recalled by increasing its hit count.
    ct_bump_hits(Id).

% ct_replay/4: read back what an episode did, its outcome, and its valence.
ct_replay(Id, Action, Outcome, Valence) :-
    % Look up the stored case by identifier.
    episode(Id, _, Action, Outcome, Valence, _, _).

% ct_reinforce/2: nudge an episode's valence by a delta, staying within [-1,1].
ct_reinforce(Id, Delta) :-
    % Retract the current case.
    retract(episode(Id, C, A, O, V0, R, H)),
    % Add the delta and clamp back into the legal band.
    V1 is V0 + Delta,
    ct_clamp(V1, -1, 1, V),
    % Re-assert the case with the updated valence.
    assertz(episode(Id, C, A, O, V, R, H)).

% ct_hits/2: how many times an episode has been recalled.
ct_hits(Id, Hits) :-
    % Read the hit count from the stored case.
    episode(Id, _, _, _, _, _, Hits).

% ct_count/1: how many episodes are currently stored.
ct_count(N) :-
    % Count the episode facts.
    aggregate_all(count, episode(_,_,_,_,_,_,_), N).

% ct_stats/1: a small summary — the count and the mean valence.
ct_stats(stats(Count, MeanValence)) :-
    % Count the stored episodes.
    ct_count(Count),
    % Sum every stored valence.
    findall(V, episode(_,_,_,_,V,_,_), Vs),
    sum_list(Vs, Sum),
    % Mean valence is the sum over the count; an empty store means zero.
    ( Count =:= 0 -> MeanValence = 0.0 ; MeanValence is Sum / Count ).

% ---- small internal helpers ------------------------------------------------

% ct_bump_hits/1: increment one episode's recall counter by one.
ct_bump_hits(Id) :-
    % Retract the old case.
    retract(episode(Id, C, A, O, V, R, H0)),
    % Compute the new hit count.
    H is H0 + 1,
    % Re-assert with the higher count.
    assertz(episode(Id, C, A, O, V, R, H)).

% ct_clamp/4: constrain a value X to lie within [Lo, Hi].
ct_clamp(X, Lo, Hi, Y) :-
    % First push X up to at least Lo.
    Y0 is max(X, Lo),
    % Then pull it down to at most Hi.
    Y is min(Y0, Hi).

% ct_take/3: take at most K elements from the front of a list.
ct_take(_, K, []) :-
    % Taking zero or fewer elements yields the empty list.
    K =< 0, !.
ct_take([], _, []).
    % Taking from an empty list yields the empty list.
ct_take([X|Xs], K, [X|Ys]) :-
    % Otherwise keep the head and take K-1 more from the tail.
    K > 0,
    K1 is K - 1,
    ct_take(Xs, K1, Ys).

% pairs_values_local/2: keep the value halves of a list of Key-Value pairs.
pairs_values_local([], []).
    % An empty pair list yields no values.
pairs_values_local([_-V|T], [V|Vs]) :-
    % Drop the key, keep the value, recurse on the tail.
    pairs_values_local(T, Vs).
