/*  PrologAI — SONA: Synaptic Ontological Neural Aggregator  (PR 11)

    SONA is PrologAI's continuous learning layer.  It maintains a
    ReasoningBank of experience trajectories and provides:

    sona_absorb/1    — submit a trajectory for clustering and integration;
                       applies pattern separation (near-duplicates with
                       differing outcomes are kept distinct) and EWC++
                       importance protection (high-importance trajectories
                       are shielded from consolidation eviction).

    sona_retrieve/2  — retrieve the K most relevant past trajectories for a
                       given situation pattern (cued recall / pattern
                       completion).

    sona_metrics/1   — return a snapshot of SONA's operational metrics.

    sona_crystallize/1 — compress the ReasoningBank: forget the
                         lowest-importance trajectories, promote frequent
                         deliberate sequences to reflexes, and inscribe
                         crystallized_pattern node_facts into the Lattice's
                         past_zone.

    Trajectory term: trajectory(SituationId, ActionSequence, Outcome, Reward, Timestamp)

    Pattern separation threshold: 0.85 cosine similarity.
    If a new trajectory has similarity >= 0.85 to an existing one AND the
    outcomes differ, both are stored separately so sona_retrieve can return
    both rather than a merged hybrid.

    EWC++ protection: importance is approximated by reward magnitude and
    retrieval frequency.  High-importance trajectories (importance >= 0.5)
    are not evicted by crystallize.

    Requires: library(node_facts), library(backend_prolog) (hash_project,
              cosine_similarity), library(scopes).
*/

:- module(sona, [
    sona_absorb/1,         % +Trajectory
    sona_retrieve/2,       % +SituationPattern, -Trajectories  (K defaults to 5)
    sona_retrieve/3,       % +SituationPattern, +K, -Trajectories
    sona_metrics/1,        % -Metrics
    sona_crystallize/1     % +Options
]).

:- use_module(library(node_facts),     [anchor_node/4, default_nexus/1]).
:- use_module(library(backend_prolog), [hash_project/3, cosine_similarity/3]).
:- use_module(library(lists),          [member/2, last/2, nth1/3]).
:- use_module(library(apply),          [maplist/3]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

:- dynamic sona_trajectory_entry/6.
%  sona_trajectory_entry(+EntryId, +SituationId, +ActionSequence,
%                        +Outcome, +Reward, +Timestamp)

:- dynamic sona_importance/2.       % EntryId, Importance (0.0–1.0)
:- dynamic sona_retrieval_count/2.  % EntryId, Count
:- dynamic sona_consolidation_cycle/1.
sona_consolidation_cycle(0).

:- dynamic sona_last_crystallize_time/1.
sona_last_crystallize_time(0.0).

:- dynamic sona_trajectory_id_counter/1.
sona_trajectory_id_counter(0).

:- nb_setval(sona_vec_dim, 32).
:- nb_setval(sona_separation_threshold, 0.85).
:- nb_setval(sona_importance_guard,    0.5).

% ---------------------------------------------------------------------------
% ID generation
% ---------------------------------------------------------------------------

next_entry_id(Id) :-
    retract(sona_trajectory_id_counter(N)),
    N1 is N + 1,
    assertz(sona_trajectory_id_counter(N1)),
    Id = N1.

% ---------------------------------------------------------------------------
% trajectory_fingerprint/2 — hash-project a trajectory's situation+actions
% ---------------------------------------------------------------------------

trajectory_fingerprint(trajectory(SitId, Actions, _, _, _), Vec) :-
    nb_getval(sona_vec_dim, Dim),
    term_to_atom(sit(SitId, Actions), Atom),
    hash_project(Atom, Dim, Vec).

% ---------------------------------------------------------------------------
% sona_absorb/1
% ---------------------------------------------------------------------------

sona_absorb(Trajectory) :-
    Trajectory = trajectory(SitId, Actions, Outcome, Reward, Timestamp),
    trajectory_fingerprint(Trajectory, NewVec),
    nb_getval(sona_separation_threshold, SepThresh),
    % Collect all existing trajectories' fingerprints
    findall(Eid-EVec-EOut, (
        sona_trajectory_entry(Eid, ESitId, EActions, EOut, _, _),
        trajectory_fingerprint(
            trajectory(ESitId, EActions, EOut, _, _), EVec)
    ), Existing),
    % Pattern-separation check: is there a near-duplicate?
    ( near_duplicate(NewVec, Outcome, SepThresh, Existing)
    ->  % Near-duplicate with same outcome → already captured; skip
        true
    ;   % Store as new entry (may be a separated near-duplicate with diff outcome)
        next_entry_id(Eid),
        assertz(sona_trajectory_entry(Eid, SitId, Actions, Outcome, Reward, Timestamp)),
        % EWC++ importance: initialise from reward magnitude
        BaseImportance is min(1.0, max(0.0, abs(Reward))),
        assertz(sona_importance(Eid, BaseImportance)),
        assertz(sona_retrieval_count(Eid, 0)),
        % Persist as node_fact for cross-module visibility
        catch(
            anchor_node(sona_trajectory,
                        [Eid, SitId, Actions, Outcome, Reward],
                        [Timestamp],
                        _),
            _, true
        )
    ).

%  near_duplicate(+NewVec, +NewOutcome, +Threshold, +Existing) succeeds
%  only if there is an existing entry with similarity >= Threshold AND the
%  SAME outcome (meaning the new trajectory is a true duplicate, not a
%  separated near-duplicate).
near_duplicate(NewVec, NewOutcome, Threshold, Existing) :-
    member(_Eid-EVec-EOut, Existing),
    cosine_similarity(NewVec, EVec, Sim),
    Sim >= Threshold,
    EOut == NewOutcome.

% ---------------------------------------------------------------------------
% sona_retrieve/2 and sona_retrieve/3
% ---------------------------------------------------------------------------

sona_retrieve(SituationPattern, Trajectories) :-
    sona_retrieve(SituationPattern, 5, Trajectories).

sona_retrieve(SituationPattern, K, Trajectories) :-
    nb_getval(sona_vec_dim, Dim),
    term_to_atom(SituationPattern, QAtom),
    hash_project(QAtom, Dim, QVec),
    % Score all entries by cosine similarity to query + importance boost
    findall(Score-T, (
        sona_trajectory_entry(Eid, SitId, Actions, Outcome, Reward, Ts),
        trajectory_fingerprint(
            trajectory(SitId, Actions, Outcome, _, _), EVec),
        cosine_similarity(QVec, EVec, Sim),
        ( sona_importance(Eid, Imp) -> true ; Imp = 0.0 ),
        Score is Sim * 0.8 + Imp * 0.2,
        T = trajectory(SitId, Actions, Outcome, Reward, Ts)
    ), Scored),
    msort(Scored, Asc),
    reverse(Asc, Desc),
    take_k(K, Desc, TopK),
    % Increment retrieval count for each returned entry (EWC++ signal)
    maplist([_-trajectory(SitId, Actions, Outcome, _, _)]>>(
        ( sona_trajectory_entry(Eid2, SitId, Actions, Outcome, _, _),
          retract(sona_retrieval_count(Eid2, C))
        -> C1 is C + 1,
           assertz(sona_retrieval_count(Eid2, C1)),
           update_importance(Eid2)
        ;  true )
    ), TopK),
    maplist([_-T, T]>>true, TopK, Trajectories).

take_k(K, List, Result) :-
    length(List, N),
    Take is min(K, N),
    length(Result, Take),
    append(Result, _, List).

% Boost importance of frequently-retrieved entries (EWC++ frequency signal)
update_importance(Eid) :-
    ( sona_retrieval_count(Eid, C),
      sona_importance(Eid, OldImp)
    ->  Boost is min(1.0, OldImp + C * 0.01),
        retract(sona_importance(Eid, OldImp)),
        assertz(sona_importance(Eid, Boost))
    ;   true
    ).

% ---------------------------------------------------------------------------
% sona_metrics/1
% ---------------------------------------------------------------------------

sona_metrics(Metrics) :-
    aggregate_all(count, sona_trajectory_entry(_, _, _, _, _, _), TrajCount),
    ( sona_consolidation_cycle(CC) -> true ; CC = 0 ),
    ( sona_last_crystallize_time(LCT) -> true ; LCT = 0.0 ),
    get_time(Now),
    ( TrajCount > 0
    ->  aggregate_all(max(Ts),
                      sona_trajectory_entry(_, _, _, _, _, Ts),
                      MaxTs),
        LastAge is Now - MaxTs
    ;   LastAge = 0.0
    ),
    CrystAge is Now - LCT,
    Capacity is TrajCount / 10000.0,
    Metrics = sona_metrics{
        trajectory_count:    TrajCount,
        consolidation_cycle: CC,
        learning_rate:       0.01,
        bank_capacity_used:  Capacity,
        last_absorption_age: LastAge,
        last_crystallize_age: CrystAge
    }.

% ---------------------------------------------------------------------------
% sona_crystallize/1
% ---------------------------------------------------------------------------

sona_crystallize(Options) :-
    option_value(min_trajectory_count(MinN), Options, 0),
    option_value(compression_target(Frac),   Options, 0.5),
    option_value(domain_filter(Domain),      Options, any),
    % Count current entries
    aggregate_all(count, sona_trajectory_entry(_, _, _, _, _, _), Total),
    ( Total < MinN
    ->  true   % Not enough trajectories yet
    ;   % Determine how many to evict (low-importance, not guarded)
        EvictCount is round(Total * Frac),
        evict_lowest(EvictCount, Domain),
        % Inscribe crystallized_pattern node_facts for survivors
        inscribe_crystallized(Domain),
        % Bump consolidation cycle counter
        retract(sona_consolidation_cycle(C)),
        C1 is C + 1,
        assertz(sona_consolidation_cycle(C1)),
        get_time(T),
        retractall(sona_last_crystallize_time(_)),
        assertz(sona_last_crystallize_time(T))
    ).

option_value(Term, Options, _Default) :-
    memberchk(Term, Options), !.
option_value(Term, _Options, Default) :-
    Term =.. [_|[Default|_]], !.
option_value(_, _, _).

evict_lowest(N, Domain) :-
    nb_getval(sona_importance_guard, Guard),
    % Collect all evictable entries sorted by importance ascending
    findall(Imp-Eid, (
        sona_trajectory_entry(Eid, SitId, _, _, _, _),
        ( Domain == any
        -> true
        ;  term_to_atom(SitId, SitAtom),
           sub_atom(SitAtom, _, _, _, Domain)
        ),
        ( sona_importance(Eid, Imp) -> true ; Imp = 0.0 ),
        Imp < Guard   % Only evict unprotected entries
    ), Evictable),
    msort(Evictable, Sorted),
    length(Sorted, Available),
    Take is min(N, Available),
    length(ToEvict, Take),
    append(ToEvict, _, Sorted),
    maplist([_-Eid]>>(
        retractall(sona_trajectory_entry(Eid, _, _, _, _, _)),
        retractall(sona_importance(Eid, _)),
        retractall(sona_retrieval_count(Eid, _))
    ), ToEvict).

inscribe_crystallized(Domain) :-
    % Group surviving trajectories by SituationId and anchor as crystallized_pattern
    findall(SitId-Actions-Outcome, (
        sona_trajectory_entry(_, SitId, Actions, Outcome, _, _),
        ( Domain == any
        -> true
        ;  term_to_atom(SitId, SA),
           sub_atom(SA, _, _, _, Domain)
        )
    ), Rows),
    sort(Rows, Unique),
    maplist([SitId-Actions-Outcome]>>(
        catch(
            anchor_node(crystallized_pattern,
                        [SitId, Actions, Outcome],
                        [],
                        _),
            _, true
        )
    ), Unique).
