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
      episodic_memory_reset/0            -- forget every episode
      episodic_memory_record/4           -- +Context, +Action, +Outcome, +Valence  (store one)
      episodic_memory_record/5           -- ... , -Id                               (store, return id)
      episodic_memory_episode/6          -- ?Id, ?Context, ?Action, ?Outcome, ?Valence, ?Recency
      episodic_memory_similarity/3       -- +Cue, +Id, -Score        (Jaccard overlap in [0,1])
      episodic_memory_remind/3           -- +Cue, +K, -TopK          (best K episodes, best first)
      episodic_memory_recall/3           -- +Cue, -Id, -Score        (single best match; bumps Hits)
      episodic_memory_replay/4           -- +Id, -Action, -Outcome, -Valence
      episodic_memory_reinforce/2        -- +Id, +Delta              (nudge an episode's valence)
      episodic_memory_hits/2             -- ?Id, ?Hits
      episodic_memory_count/1            -- -N                        (how many episodes stored)
      episodic_memory_stats/1            -- -stats(Count, MeanValence)
*/

% Declare this module and list every exported predicate with its arity.
:- module(episodic_memory, [
    % episodic_memory_reset/0: forget every episode.
    episodic_memory_reset/0,
    % episodic_memory_record/4: store an episode from its four parts.
    episodic_memory_record/4,
    % episodic_memory_record/5: store an episode and return its fresh id.
    episodic_memory_record/5,
    % episodic_memory_episode/6: query stored episodes.
    episodic_memory_episode/6,
    % episodic_memory_similarity/3: score a cue against one episode's context.
    episodic_memory_similarity/3,
    % episodic_memory_remind/3: the best K episodes for a cue, best first.
    episodic_memory_remind/3,
    % episodic_memory_recall/3: the single best-matching episode, bumping its hit count.
    episodic_memory_recall/3,
    % episodic_memory_replay/4: read back what an episode did and how it turned out.
    episodic_memory_replay/4,
    % episodic_memory_reinforce/2: nudge an episode's valence by a delta.
    episodic_memory_reinforce/2,
    % episodic_memory_hits/2: how many times an episode has been recalled.
    episodic_memory_hits/2,
    % episodic_memory_count/1: how many episodes are stored.
    episodic_memory_count/1,
    % episodic_memory_stats/1: a small summary of the store.
    episodic_memory_stats/1
]).

% Use the list library for member, subtract, and friends.
:- use_module(library(lists)).
% Use gensym to mint fresh episode identifiers.
:- use_module(library(gensym)).

% episode/7 is the stored case; it changes at runtime, so declare it dynamic.
:- dynamic episode/7.
% episodic_memory_clock/1 holds the rising recency counter; declare it dynamic too.
:- dynamic episodic_memory_clock/1.

% episodic_memory_reset/0: retract every episode and restart the recency clock at zero.
episodic_memory_reset :-
    % Remove all stored episodes.
    retractall(episode(_,_,_,_,_,_,_)),
    % Remove any existing clock value.
    retractall(episodic_memory_clock(_)),
    % Seed the clock at zero.
    assertz(episodic_memory_clock(0)).

% episodic_memory_tick/1: consume the next recency stamp, advancing the clock by one.
episodic_memory_tick(Next) :-
    % Read the current clock, defaulting to zero if unset.
    ( retract(episodic_memory_clock(Now)) -> true ; Now = 0 ),
    % The next stamp is one greater.
    Next is Now + 1,
    % Store the advanced clock.
    assertz(episodic_memory_clock(Next)).

% episodic_memory_record/4: store an episode without needing its id back.
episodic_memory_record(Context, Action, Outcome, Valence) :-
    % Delegate to the id-returning form and discard the id.
    episodic_memory_record(Context, Action, Outcome, Valence, _).

% episodic_memory_record/5: store an episode and return a fresh identifier.
episodic_memory_record(Context, Action, Outcome, Valence, Id) :-
    % Normalise the context into a sorted set of distinct features.
    sort(Context, Feats),
    % Clamp the valence into the legal [-1, 1] band.
    episodic_memory_clamp(Valence, -1, 1, V),
    % Take the next recency stamp.
    episodic_memory_tick(R),
    % Mint a fresh episode identifier.
    gensym(ep_, Id),
    % Assert the new case with a zero hit count.
    assertz(episode(Id, Feats, Action, Outcome, V, R, 0)).

% episodic_memory_episode/6: expose the stored cases without the internal hit count.
episodic_memory_episode(Id, Context, Action, Outcome, Valence, Recency) :-
    % Read the underlying seven-place fact, hiding Hits.
    episode(Id, Context, Action, Outcome, Valence, Recency, _).

% episodic_memory_similarity/3: the Jaccard overlap of a cue's features with an episode's.
episodic_memory_similarity(Cue, Id, Score) :-
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

% episodic_memory_remind/3: the best K episodes for a cue, most similar first.
episodic_memory_remind(Cue, K, TopK) :-
    % Score every stored episode against the cue.
    findall(Score-Id,
            ( episode(Id, _, _, _, _, _, _),
              episodic_memory_similarity(Cue, Id, Score),
              % Ignore episodes that share nothing with the cue.
              Score > 0.0 ),
            Pairs),
    % Sort by score descending, keeping duplicates (keysort then reverse).
    sort(1, @>=, Pairs, Ranked),
    % Keep only the identifiers, dropping the scores.
    pairs_values_local(Ranked, Ids),
    % Take at most K of them.
    episodic_memory_take(Ids, K, TopK).

% episodic_memory_recall/3: the single best-matching episode, whose hit count is then bumped.
episodic_memory_recall(Cue, Id, Score) :-
    % Ask for the best one episode.
    episodic_memory_remind(Cue, 1, [Id|_]),
    % Report its similarity to the cue.
    episodic_memory_similarity(Cue, Id, Score),
    % Reward the memory for being recalled by increasing its hit count.
    episodic_memory_bump_hits(Id).

% episodic_memory_replay/4: read back what an episode did, its outcome, and its valence.
episodic_memory_replay(Id, Action, Outcome, Valence) :-
    % Look up the stored case by identifier.
    episode(Id, _, Action, Outcome, Valence, _, _).

% episodic_memory_reinforce/2: nudge an episode's valence by a delta, staying within [-1,1].
episodic_memory_reinforce(Id, Delta) :-
    % Retract the current case.
    retract(episode(Id, C, A, O, V0, R, H)),
    % Add the delta and clamp back into the legal band.
    V1 is V0 + Delta,
    episodic_memory_clamp(V1, -1, 1, V),
    % Re-assert the case with the updated valence.
    assertz(episode(Id, C, A, O, V, R, H)).

% episodic_memory_hits/2: how many times an episode has been recalled.
episodic_memory_hits(Id, Hits) :-
    % Read the hit count from the stored case.
    episode(Id, _, _, _, _, _, Hits).

% episodic_memory_count/1: how many episodes are currently stored.
episodic_memory_count(N) :-
    % Count the episode facts.
    aggregate_all(count, episode(_,_,_,_,_,_,_), N).

% episodic_memory_stats/1: a small summary — the count and the mean valence.
episodic_memory_stats(stats(Count, MeanValence)) :-
    % Count the stored episodes.
    episodic_memory_count(Count),
    % Sum every stored valence.
    findall(V, episode(_,_,_,_,V,_,_), Vs),
    sum_list(Vs, Sum),
    % Mean valence is the sum over the count; an empty store means zero.
    ( Count =:= 0 -> MeanValence = 0.0 ; MeanValence is Sum / Count ).

% ---- small internal helpers ------------------------------------------------

% episodic_memory_bump_hits/1: increment one episode's recall counter by one.
episodic_memory_bump_hits(Id) :-
    % Retract the old case.
    retract(episode(Id, C, A, O, V, R, H0)),
    % Compute the new hit count.
    H is H0 + 1,
    % Re-assert with the higher count.
    assertz(episode(Id, C, A, O, V, R, H)).

% episodic_memory_clamp/4: constrain a value X to lie within [Lo, Hi].
episodic_memory_clamp(X, Lo, Hi, Y) :-
    % First push X up to at least Lo.
    Y0 is max(X, Lo),
    % Then pull it down to at most Hi.
    Y is min(Y0, Hi).

% episodic_memory_take/3: take at most K elements from the front of a list.
episodic_memory_take(_, K, []) :-
    % Taking zero or fewer elements yields the empty list.
    K =< 0, !.
episodic_memory_take([], _, []).
    % Taking from an empty list yields the empty list.
episodic_memory_take([X|Xs], K, [X|Ys]) :-
    % Otherwise keep the head and take K-1 more from the tail.
    K > 0,
    K1 is K - 1,
    episodic_memory_take(Xs, K1, Ys).

% pairs_values_local/2: keep the value halves of a list of Key-Value pairs.
pairs_values_local([], []).
    % An empty pair list yields no values.
pairs_values_local([_-V|T], [V|Vs]) :-
    % Drop the key, keep the value, recurse on the tail.
    pairs_values_local(T, Vs).
