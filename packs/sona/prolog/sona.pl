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

% Declare this file as the 'sona' module and list its exported predicates.
:- module(sona, [
    % Continue the multi-line expression started above.
    sona_absorb/1,         % +Trajectory
    % Continue the multi-line expression started above.
    sona_retrieve/2,       % +SituationPattern, -Trajectories  (K defaults to 5)
    % Continue the multi-line expression started above.
    sona_retrieve/3,       % +SituationPattern, +K, -Trajectories
    % Continue the multi-line expression started above.
    sona_metrics/1,        % -Metrics
    % Continue the multi-line expression started above.
    sona_crystallize/1     % +Options
% Close the expression opened above.
]).

% Import [anchor_node/4, default_nexus/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts),     [anchor_node/4, default_nexus/1]).
% Import [hash_project/3, cosine_similarity/3] from the built-in 'backend_prolog' library.
:- use_module(library(backend_prolog), [hash_project/3, cosine_similarity/3]).
% Import [member/2, last/2, nth1/3] from the built-in 'lists' library.
:- use_module(library(lists),          [member/2, last/2, nth1/3]).
% Import [maplist/3] from the built-in 'apply' library.
:- use_module(library(apply),          [maplist/3]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% Declare 'sona_trajectory_entry/6' as dynamic — its facts may be added or removed at runtime.
:- dynamic sona_trajectory_entry/6.
%  sona_trajectory_entry(+EntryId, +SituationId, +ActionSequence,
%                        +Outcome, +Reward, +Timestamp)

% Declare 'sona_importance/2.       % EntryId, Importance (0.0–1.0)' as dynamic — its facts may be added or removed at runtime.
:- dynamic sona_importance/2.       % EntryId, Importance (0.0–1.0)
% Declare 'sona_retrieval_count/2.  % EntryId, Count' as dynamic — its facts may be added or removed at runtime.
:- dynamic sona_retrieval_count/2.  % EntryId, Count
% Declare 'sona_consolidation_cycle/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic sona_consolidation_cycle/1.
% State the fact: sona consolidation cycle(0).
sona_consolidation_cycle(0).

% Declare 'sona_last_crystallize_time/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic sona_last_crystallize_time/1.
% State the fact: sona last crystallize time(0.0).
sona_last_crystallize_time(0.0).

% Declare 'sona_trajectory_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic sona_trajectory_id_counter/1.
% State the fact: sona trajectory id counter(0).
sona_trajectory_id_counter(0).

% Execute the compile-time directive: nb_setval(sona_vec_dim, 32).
:- nb_setval(sona_vec_dim, 32).
% Execute the compile-time directive: nb_setval(sona_separation_threshold, 0.85).
:- nb_setval(sona_separation_threshold, 0.85).
% Execute the compile-time directive: nb_setval(sona_importance_guard,    0.5).
:- nb_setval(sona_importance_guard,    0.5).

% ---------------------------------------------------------------------------
% ID generation
% ---------------------------------------------------------------------------

% Define a clause for 'next entry id': succeed when the following conditions hold.
next_entry_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(sona_trajectory_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(sona_trajectory_id_counter(N1)),
    % Check that 'Id' is unifiable with 'N1'.
    Id = N1.

% ---------------------------------------------------------------------------
% trajectory_fingerprint/2 — hash-project a trajectory's situation+actions
% ---------------------------------------------------------------------------

% Define a clause for 'trajectory fingerprint': succeed when the following conditions hold.
trajectory_fingerprint(trajectory(SitId, Actions, _, _, _), Vec) :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(sona_vec_dim, Dim),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(sit(SitId, Actions), Atom),
    % State the fact: hash project(Atom, Dim, Vec).
    hash_project(Atom, Dim, Vec).

% ---------------------------------------------------------------------------
% sona_absorb/1
% ---------------------------------------------------------------------------

% Define a clause for 'sona absorb': succeed when the following conditions hold.
sona_absorb(Trajectory) :-
    % Check that 'Trajectory' is unifiable with 'trajectory(SitId, Actions, Outcome, Reward, Timestamp)'.
    Trajectory = trajectory(SitId, Actions, Outcome, Reward, Timestamp),
    % State a fact for 'trajectory fingerprint' with the arguments listed below.
    trajectory_fingerprint(Trajectory, NewVec),
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(sona_separation_threshold, SepThresh),
    % Collect all existing trajectories' fingerprints
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Eid-EVec-EOut, (
        % Continue the multi-line expression started above.
        sona_trajectory_entry(Eid, ESitId, EActions, EOut, _, _),
        % Continue the multi-line expression started above.
        trajectory_fingerprint(
            % Continue the multi-line expression started above.
            trajectory(ESitId, EActions, EOut, _, _), EVec)
    % Continue the multi-line expression started above.
    ), Existing),
    % Pattern-separation check: is there a near-duplicate?
    % Execute: ( near_duplicate(NewVec, Outcome, SepThresh, Existing).
    ( near_duplicate(NewVec, Outcome, SepThresh, Existing)
    % If the condition above succeeded, perform the following action.
    ->  % Near-duplicate with same outcome → already captured; skip
        % Supply 'true' as the next argument to the expression above.
        true
    % Otherwise (else branch), perform the following action.
    ;   % Store as new entry (may be a separated near-duplicate with diff outcome)
        % Continue the multi-line expression started above.
        next_entry_id(Eid),
        % Continue the multi-line expression started above.
        assertz(sona_trajectory_entry(Eid, SitId, Actions, Outcome, Reward, Timestamp)),
        % EWC++ importance: initialise from reward magnitude
        % Continue the multi-line expression started above.
        BaseImportance is min(1.0, max(0.0, abs(Reward))),
        % Continue the multi-line expression started above.
        assertz(sona_importance(Eid, BaseImportance)),
        % Continue the multi-line expression started above.
        assertz(sona_retrieval_count(Eid, 0)),
        % Persist as node_fact for cross-module visibility
        % Continue the multi-line expression started above.
        catch(
            % Continue the multi-line expression started above.
            anchor_node(sona_trajectory,
                        % Continue the multi-line expression started above.
                        [Eid, SitId, Actions, Outcome, Reward],
                        % Continue the multi-line expression started above.
                        [Timestamp],
                        % Supply '_' as the next argument to the expression above.
                        _),
            % Continue the multi-line expression started above.
            _, true
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

%  near_duplicate(+NewVec, +NewOutcome, +Threshold, +Existing) succeeds
%  only if there is an existing entry with similarity >= Threshold AND the
%  SAME outcome (meaning the new trajectory is a true duplicate, not a
%  separated near-duplicate).
% Define a clause for 'near duplicate': succeed when the following conditions hold.
near_duplicate(NewVec, NewOutcome, Threshold, Existing) :-
    % Succeed for each element '_Eid-EVec-EOut' that is a member of the list.
    member(_Eid-EVec-EOut, Existing),
    % State a fact for 'cosine similarity' with the arguments listed below.
    cosine_similarity(NewVec, EVec, Sim),
    % Check that 'Sim' is greater than or equal to 'Threshold'.
    Sim >= Threshold,
    % Check that 'EOut' is structurally identical to 'NewOutcome'.
    EOut == NewOutcome.

% ---------------------------------------------------------------------------
% sona_retrieve/2 and sona_retrieve/3
% ---------------------------------------------------------------------------

% Define a clause for 'sona retrieve': succeed when the following conditions hold.
sona_retrieve(SituationPattern, Trajectories) :-
    % State the fact: sona retrieve(SituationPattern, 5, Trajectories).
    sona_retrieve(SituationPattern, 5, Trajectories).

% Define a clause for 'sona retrieve': succeed when the following conditions hold.
sona_retrieve(SituationPattern, K, Trajectories) :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(sona_vec_dim, Dim),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(SituationPattern, QAtom),
    % State a fact for 'hash project' with the arguments listed below.
    hash_project(QAtom, Dim, QVec),
    % Score all entries by cosine similarity to query + importance boost
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Score-T, (
        % Continue the multi-line expression started above.
        sona_trajectory_entry(Eid, SitId, Actions, Outcome, Reward, Ts),
        % Continue the multi-line expression started above.
        trajectory_fingerprint(
            % Continue the multi-line expression started above.
            trajectory(SitId, Actions, Outcome, _, _), EVec),
        % Continue the multi-line expression started above.
        cosine_similarity(QVec, EVec, Sim),
        % Continue the multi-line expression started above.
        ( sona_importance(Eid, Imp) -> true ; Imp = 0.0 ),
        % Continue the multi-line expression started above.
        Score is Sim * 0.8 + Imp * 0.2,
        % Continue the multi-line expression started above.
        T = trajectory(SitId, Actions, Outcome, Reward, Ts)
    % Continue the multi-line expression started above.
    ), Scored),
    % Sort list 'Scored' into 'Asc', keeping duplicates.
    msort(Scored, Asc),
    % State a fact for 'reverse' with the arguments listed below.
    reverse(Asc, Desc),
    % State a fact for 'take k' with the arguments listed below.
    take_k(K, Desc, TopK),
    % Increment retrieval count for each returned entry (EWC++ signal)
    % State a fact for 'maplist' with the arguments listed below.
    maplist([_-trajectory(SitId, Actions, Outcome, _, _)]>>(
        % Continue the multi-line expression started above.
        ( sona_trajectory_entry(Eid2, SitId, Actions, Outcome, _, _),
          % Continue the multi-line expression started above.
          retract(sona_retrieval_count(Eid2, C))
        % If the condition above succeeded, perform the following action.
        -> C1 is C + 1,
           % Continue the multi-line expression started above.
           assertz(sona_retrieval_count(Eid2, C1)),
           % Continue the multi-line expression started above.
           update_importance(Eid2)
        % Otherwise (else branch), perform the following action.
        ;  true )
    % Continue the multi-line expression started above.
    ), TopK),
    % State the fact: maplist([_-T, T]>>true, TopK, Trajectories).
    maplist([_-T, T]>>true, TopK, Trajectories).

% Define a clause for 'take k': succeed when the following conditions hold.
take_k(K, List, Result) :-
    % Unify 'N' with the number of elements in list 'List'.
    length(List, N),
    % Evaluate the arithmetic expression 'min(K, N)' and bind the result to 'Take'.
    Take is min(K, N),
    % Unify 'Take' with the number of elements in list 'Result'.
    length(Result, Take),
    % Unify the third argument with the concatenation of the first two lists.
    append(Result, _, List).

% Boost importance of frequently-retrieved entries (EWC++ frequency signal)
% Define a clause for 'update importance': succeed when the following conditions hold.
update_importance(Eid) :-
    % Execute: ( sona_retrieval_count(Eid, C),.
    ( sona_retrieval_count(Eid, C),
      % Continue the multi-line expression started above.
      sona_importance(Eid, OldImp)
    % If the condition above succeeded, perform the following action.
    ->  Boost is min(1.0, OldImp + C * 0.01),
        % Continue the multi-line expression started above.
        retract(sona_importance(Eid, OldImp)),
        % Continue the multi-line expression started above.
        assertz(sona_importance(Eid, Boost))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% sona_metrics/1
% ---------------------------------------------------------------------------

% Define a clause for 'sona metrics': succeed when the following conditions hold.
sona_metrics(Metrics) :-
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count, sona_trajectory_entry(_, _, _, _, _, _), TrajCount),
    % Check that '( sona_consolidation_cycle(CC) -> true ; CC' is unifiable with '0 )'.
    ( sona_consolidation_cycle(CC) -> true ; CC = 0 ),
    % Check that '( sona_last_crystallize_time(LCT) -> true ; LCT' is unifiable with '0.0 )'.
    ( sona_last_crystallize_time(LCT) -> true ; LCT = 0.0 ),
    % State a fact for 'get time' with the arguments listed below.
    get_time(Now),
    % Check that '( TrajCount' is greater than '0'.
    ( TrajCount > 0
    % If the condition above succeeded, perform the following action.
    ->  aggregate_all(max(Ts),
                      % Continue the multi-line expression started above.
                      sona_trajectory_entry(_, _, _, _, _, Ts),
                      % Supply 'MaxTs' as the next argument to the expression above.
                      MaxTs),
        % Continue the multi-line expression started above.
        LastAge is Now - MaxTs
    % Otherwise (else branch), perform the following action.
    ;   LastAge = 0.0
    % Close the expression opened above.
    ),
    % Evaluate the arithmetic expression 'Now - LCT' and bind the result to 'CrystAge'.
    CrystAge is Now - LCT,
    % Evaluate the arithmetic expression 'TrajCount / 10000.0' and bind the result to 'Capacity'.
    Capacity is TrajCount / 10000.0,
    % Check that 'Metrics' is unifiable with 'sona_metrics{'.
    Metrics = sona_metrics{
        % Execute: trajectory_count:    TrajCount,.
        trajectory_count:    TrajCount,
        % Execute: consolidation_cycle: CC,.
        consolidation_cycle: CC,
        % Execute: learning_rate:       0.01,.
        learning_rate:       0.01,
        % Execute: bank_capacity_used:  Capacity,.
        bank_capacity_used:  Capacity,
        % Execute: last_absorption_age: LastAge,.
        last_absorption_age: LastAge,
        % Execute: last_crystallize_age: CrystAge.
        last_crystallize_age: CrystAge
    % Execute: }..
    }.

% ---------------------------------------------------------------------------
% sona_crystallize/1
% ---------------------------------------------------------------------------

% Define a clause for 'sona crystallize': succeed when the following conditions hold.
sona_crystallize(Options) :-
    % State a fact for 'option value' with the arguments listed below.
    option_value(min_trajectory_count(MinN), Options, 0),
    % State a fact for 'option value' with the arguments listed below.
    option_value(compression_target(Frac),   Options, 0.5),
    % State a fact for 'option value' with the arguments listed below.
    option_value(domain_filter(Domain),      Options, any),
    % Count current entries
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count, sona_trajectory_entry(_, _, _, _, _, _), Total),
    % Check that '( Total' is less than 'MinN'.
    ( Total < MinN
    % If the condition above succeeded, perform the following action.
    ->  true   % Not enough trajectories yet
    % Otherwise (else branch), perform the following action.
    ;   % Determine how many to evict (low-importance, not guarded)
        % Continue the multi-line expression started above.
        EvictCount is round(Total * Frac),
        % Continue the multi-line expression started above.
        evict_lowest(EvictCount, Domain),
        % Inscribe crystallized_pattern node_facts for survivors
        % Continue the multi-line expression started above.
        inscribe_crystallized(Domain),
        % Bump consolidation cycle counter
        % Continue the multi-line expression started above.
        retract(sona_consolidation_cycle(C)),
        % Continue the multi-line expression started above.
        C1 is C + 1,
        % Continue the multi-line expression started above.
        assertz(sona_consolidation_cycle(C1)),
        % Continue the multi-line expression started above.
        get_time(T),
        % Continue the multi-line expression started above.
        retractall(sona_last_crystallize_time(_)),
        % Continue the multi-line expression started above.
        assertz(sona_last_crystallize_time(T))
    % Close the expression opened above.
    ).

% Define a clause for 'option value': succeed when the following conditions hold.
option_value(Term, Options, _Default) :-
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(Term, Options), !.
% Define a clause for 'option value': succeed when the following conditions hold.
option_value(Term, _Options, Default) :-
    % Execute: Term =.. [_|[Default|_]], !..
    Term =.. [_|[Default|_]], !.
% State the fact: option value(_, _, _).
option_value(_, _, _).

% Define a clause for 'evict lowest': succeed when the following conditions hold.
evict_lowest(N, Domain) :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(sona_importance_guard, Guard),
    % Collect all evictable entries sorted by importance ascending
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Imp-Eid, (
        % Continue the multi-line expression started above.
        sona_trajectory_entry(Eid, SitId, _, _, _, _),
        % Continue the multi-line expression started above.
        ( Domain == any
        % If the condition above succeeded, perform the following action.
        -> true
        % Otherwise (else branch), perform the following action.
        ;  term_to_atom(SitId, SitAtom),
           % Continue the multi-line expression started above.
           sub_atom(SitAtom, _, _, _, Domain)
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        ( sona_importance(Eid, Imp) -> true ; Imp = 0.0 ),
        % Continue the multi-line expression started above.
        Imp < Guard   % Only evict unprotected entries
    % Continue the multi-line expression started above.
    ), Evictable),
    % Sort list 'Evictable' into 'Sorted', keeping duplicates.
    msort(Evictable, Sorted),
    % Unify 'Available' with the number of elements in list 'Sorted'.
    length(Sorted, Available),
    % Evaluate the arithmetic expression 'min(N, Available)' and bind the result to 'Take'.
    Take is min(N, Available),
    % Unify 'Take' with the number of elements in list 'ToEvict'.
    length(ToEvict, Take),
    % Unify the third argument with the concatenation of the first two lists.
    append(ToEvict, _, Sorted),
    % State a fact for 'maplist' with the arguments listed below.
    maplist([_-Eid]>>(
        % Continue the multi-line expression started above.
        retractall(sona_trajectory_entry(Eid, _, _, _, _, _)),
        % Continue the multi-line expression started above.
        retractall(sona_importance(Eid, _)),
        % Continue the multi-line expression started above.
        retractall(sona_retrieval_count(Eid, _))
    % Continue the multi-line expression started above.
    ), ToEvict).

% Define a clause for 'inscribe crystallized': succeed when the following conditions hold.
inscribe_crystallized(Domain) :-
    % Group surviving trajectories by SituationId and anchor as crystallized_pattern
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(SitId-Actions-Outcome, (
        % Continue the multi-line expression started above.
        sona_trajectory_entry(_, SitId, Actions, Outcome, _, _),
        % Continue the multi-line expression started above.
        ( Domain == any
        % If the condition above succeeded, perform the following action.
        -> true
        % Otherwise (else branch), perform the following action.
        ;  term_to_atom(SitId, SA),
           % Continue the multi-line expression started above.
           sub_atom(SA, _, _, _, Domain)
        % Close the expression opened above.
        )
    % Continue the multi-line expression started above.
    ), Rows),
    % Sort list 'Rows' into 'Unique', removing duplicates.
    sort(Rows, Unique),
    % State a fact for 'maplist' with the arguments listed below.
    maplist([SitId-Actions-Outcome]>>(
        % Continue the multi-line expression started above.
        catch(
            % Continue the multi-line expression started above.
            anchor_node(crystallized_pattern,
                        % Continue the multi-line expression started above.
                        [SitId, Actions, Outcome],
                        % Continue the multi-line expression started above.
                        [],
                        % Supply '_' as the next argument to the expression above.
                        _),
            % Continue the multi-line expression started above.
            _, true
        % Close the expression opened above.
        )
    % Continue the multi-line expression started above.
    ), Unique).
