/*  PrologAI — node_facts  (Specification Section 3.1–3.2, PR 4)

    anchor_node/4  — store a node_fact in the current nexus
    prune_node/1   — remove a node_fact by Id
    traverse_nexus/4 — dual-phase retrieval (unification + similarity)
    kindle_node/1  — raise activation; propagate to neighbors
    quench_node/1  — lower activation; quench wins over kindle
    live_node_facts/2 — Ids active within the activation window

    Id > 0 = affirmative thesis; Id < 0 = antithetic dyad.
    A node_fact's structural identity (Id,Relation,Args,Referents) is immutable.
    Activation is recorded as a timestamp + edge weight in node_activation/3.
*/

% Declare this file as the 'node_facts' module and list its exported predicates.
:- module(node_facts, [
    % Continue the multi-line expression started above.
    anchor_node/4,          % +Relation, +Args, +Referents, -Id
    % node_fact_find/4: find an existing node-fact by exact content.
    node_fact_find/4,       % +Relation, +Args, +Referents, -Id
    % anchor_node_unique/4: anchor a node-fact only if an identical one is absent.
    anchor_node_unique/4,   % +Relation, +Args, +Referents, -Id
    % node_facts_dedup/1: remove content-duplicate node-facts, keeping the first.
    node_facts_dedup/1,     % -Removed
    % Continue the multi-line expression started above.
    prune_node/1,           % +Id
    % Continue the multi-line expression started above.
    traverse_nexus/4,       % +Nexus, +Pattern, +K, -Results
    % Continue the multi-line expression started above.
    kindle_node/1,          % +Id
    % Continue the multi-line expression started above.
    quench_node/1,          % +Id
    % Continue the multi-line expression started above.
    live_node_facts/2,      % +Nexus, -Ids
    % Continue the multi-line expression started above.
    set_default_nexus/1,    % +Nexus
    % Continue the multi-line expression started above.
    default_nexus/1,        % -Nexus
    % Continue the multi-line expression started above.
    node_fact_nexus/2,      % +Id, -Nexus
    % Continue the multi-line expression started above.
    node_activation/3,      % ?Id, ?Timestamp, ?EdgeWeight
    % Continue the multi-line expression started above.
    reindex_nexus/1         % +Nexus — rebuild vector index with current embedding hook
% Close the expression opened above.
]).

% Load the built-in 'lattice' library so its predicates are available here.
:- use_module(library(lattice),        [lattice_node_fact/5,
                                        % Continue the multi-line expression started above.
                                        nexus_is_open/1]).
% Load the built-in 'vector_backend' library so its predicates are available here.
:- use_module(library(vector_backend), [vb_create/4, vb_insert/4,
                                        % Continue the multi-line expression started above.
                                        vb_search/4]).
% Import [hash_project/3] from the built-in 'backend_prolog' library.
:- use_module(library(backend_prolog), [hash_project/3]).
% Import [maplist/3] from the built-in 'apply' library.
:- use_module(library(apply),          [maplist/3]).
% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),          [member/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% Declare 'node_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic node_id_counter/1.
% State the fact: node id counter(0).
node_id_counter(0).

% Declare 'node_activation/3.     % Id, Timestamp, EdgeWeight' as dynamic — its facts may be added or removed at runtime.
:- dynamic node_activation/3.     % Id, Timestamp, EdgeWeight
% Declare 'node_quenched/2.       % Id, Timestamp' as dynamic — its facts may be added or removed at runtime.
:- dynamic node_quenched/2.       % Id, Timestamp
% Declare 'nexus_vector_index/2.  % Nexus, VecHandle' as dynamic — its facts may be added or removed at runtime.
:- dynamic nexus_vector_index/2.  % Nexus, VecHandle
% Declare 'node_id_nexus/2.       % Id, Nexus' as dynamic — its facts may be added or removed at runtime.
:- dynamic node_id_nexus/2.       % Id, Nexus

% Declare 'current_default_nexus/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic current_default_nexus/1.

% Execute the compile-time directive: nb_setval(node_fact_vec_dim, 32).
:- nb_setval(node_fact_vec_dim, 32).

% ---------------------------------------------------------------------------
% Default nexus management
% ---------------------------------------------------------------------------

% Define a clause for 'set default nexus': succeed when the following conditions hold.
set_default_nexus(Nexus) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(current_default_nexus(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(current_default_nexus(Nexus)).

% Define a clause for 'default nexus': succeed when the following conditions hold.
default_nexus(Nexus) :-
    % Execute: ( current_default_nexus(Nexus).
    ( current_default_nexus(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   throw(error(existence_error(default_nexus, none), default_nexus/1))
    % Close the expression opened above.
    ).

% Define a clause for 'node fact nexus': succeed when the following conditions hold.
node_fact_nexus(Id, Nexus) :-
    % State the fact: node id nexus(Id, Nexus).
    node_id_nexus(Id, Nexus).

% ---------------------------------------------------------------------------
% ID generation
% ---------------------------------------------------------------------------

% Define a clause for 'next node id': succeed when the following conditions hold.
next_node_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(node_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(node_id_counter(N1)),
    % Check that 'Id' is unifiable with 'N1'.
    Id = N1.

% ---------------------------------------------------------------------------
% Vector index per nexus
% ---------------------------------------------------------------------------

% Define a clause for 'ensure nexus vector index': succeed when the following conditions hold.
ensure_nexus_vector_index(Nexus, VH) :-
    % Execute: ( nexus_vector_index(Nexus, VH).
    ( nexus_vector_index(Nexus, VH)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   ( catch(nb_getval(node_fact_vec_dim, Dim), _, Dim = 32) -> true ; Dim = 32 ),
        % Continue the multi-line expression started above.
        vb_create(Dim, cosine, [capacity(10000)], VH),
        % Continue the multi-line expression started above.
        assertz(nexus_vector_index(Nexus, VH))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% anchor_node/4
% ---------------------------------------------------------------------------

% Define a clause for 'anchor node': succeed when the following conditions hold.
anchor_node(Relation, Args, Referents, Id) :-
    % State a fact for 'default nexus' with the arguments listed below.
    default_nexus(Nexus),
    % State a fact for 'nexus is open' with the arguments listed below.
    nexus_is_open(Nexus),
    % State a fact for 'next node id' with the arguments listed below.
    next_node_id(RawId),
    % Check that 'Id' is unifiable with 'RawId'.
    Id = RawId,
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % Logical index
    % Add a new fact or rule to the runtime knowledge base.
    assertz(lattice_node_fact(Nexus, Id, Relation, Args, Referents)),
    % Activation
    % Add a new fact or rule to the runtime knowledge base.
    assertz(node_activation(Id, T, 1.0)),
    % Nexus membership
    % Add a new fact or rule to the runtime knowledge base.
    assertz(node_id_nexus(Id, Nexus)),
    % Vector index
    % State a fact for 'ensure nexus vector index' with the arguments listed below.
    ensure_nexus_vector_index(Nexus, VH),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(node_fact(Relation, Args, Referents), Term),
    % Check that '( catch(nb_getval(node_fact_vec_dim, Dim), _, Dim' is unifiable with '32) -> true ; Dim = 32 )'.
    ( catch(nb_getval(node_fact_vec_dim, Dim), _, Dim = 32) -> true ; Dim = 32 ),
    % State a fact for 'compute node vec' with the arguments listed below.
    compute_node_vec(Term, Dim, Vec),
    % State a fact for 'vb insert' with the arguments listed below.
    vb_insert(VH, Id, Vec, []),
    % Post-anchor hook — calls ALL registered clauses (sentinel engine, pubsub, etc.)
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        forall(post_anchor_node_hook(Nexus, Id, Relation, Args, Referents), true),
        % Supply '_' as the next argument to the expression above.
        _,
        % Supply 'true' as the next argument to the expression above.
        true
    % Close the expression opened above.
    ).

% Execute the compile-time directive: multifile post_anchor_node_hook/5.
:- multifile post_anchor_node_hook/5.
% State a fact for 'post anchor node hook' with the arguments listed below.
post_anchor_node_hook(_, _, _, _, _).   % default: no-op (always present so predicate exists)

% ---------------------------------------------------------------------------
% FACT EXISTENCE — do not clutter the lattice with duplicate node-facts
% ---------------------------------------------------------------------------

% node_fact_find(+Relation, +Args, +Referents, -Id): the id of an existing node-
% fact with exactly this content in the default nexus, if one is present. A fact is
% the same fact when its relation, its arguments, and its referents all match.
node_fact_find(Relation, Args, Referents, Id) :-
    % The nexus new facts would be anchored into.
    default_nexus(Nexus),
    % A stored node-fact in that nexus with identical content.
    lattice_node_fact(Nexus, Id, Relation, Args, Referents),
    % The first match is enough.
    !.

% anchor_node_unique(+Relation, +Args, +Referents, -Id): the canonical assert-if-
% new front door. If an identical node-fact already exists in the default nexus,
% return its id and add nothing; otherwise anchor a new node-fact. This is what
% every ingest path should call so re-running an import never clutters the lattice.
anchor_node_unique(Relation, Args, Referents, Id) :-
    % Reuse the existing fact when present...
    (   node_fact_find(Relation, Args, Referents, Existing)
    ->  Id = Existing
    % ...otherwise anchor a genuinely new one.
    ;   anchor_node(Relation, Args, Referents, Id)
    ).

% node_facts_dedup(-Removed): remove content-duplicate node-facts across every
% nexus, keeping the first-anchored of each (Nexus, Relation, Args, Referents)
% group and pruning the rest. Removed is how many were pruned. This cleans a store
% that accumulated duplicates before the assert-if-new door was in place.
node_facts_dedup(Removed) :-
    % Every stored node-fact as a keyed record (content is the key, id the value).
    findall(k(Nexus, Relation, Args, Referents) - Id,
        lattice_node_fact(Nexus, Id, Relation, Args, Referents),
        Pairs),
    % Group by content; within a group the ids are the duplicates.
    keysort(Pairs, Sorted),
    % Collect the ids to prune (every id after the first in each content group).
    nf_dedup_collect(Sorted, none, ToPrune),
    % Prune each duplicate through the standard node deletion.
    forall(member(Pid, ToPrune), prune_node(Pid)),
    % How many were removed.
    length(ToPrune, Removed).

% nf_dedup_collect(+SortedPairs, +PrevKey, -ToPrune): walk the content-sorted pairs,
% keeping the first id of each content group and marking the rest for pruning.
nf_dedup_collect([], _, []).
nf_dedup_collect([Key - _Id | Rest], PrevKey, ToPrune) :-
    % A new content group: keep this id (the first), do not prune it.
    Key \== PrevKey, !,
    nf_dedup_collect(Rest, Key, ToPrune).
nf_dedup_collect([Key - Id | Rest], Key, [Id | ToPrune]) :-
    % A repeat of the current content group: this id is a duplicate to prune.
    nf_dedup_collect(Rest, Key, ToPrune).

% ---------------------------------------------------------------------------
% Pluggable embedding hook (PR 16)
%
%   External embedding providers register a clause for node_facts_embed_hook/2.
%   When no clause is registered, anchor_node falls back to hash_project.
%   Hook signature: node_facts_embed_hook(+TermAtom, -Vector)
% ---------------------------------------------------------------------------

% Execute the compile-time directive: multifile node_facts_embed_hook/2.
:- multifile node_facts_embed_hook/2.
% Declare 'node_facts_embed_hook/2' as dynamic — its facts may be added or removed at runtime.
:- dynamic   node_facts_embed_hook/2.

% Define a clause for 'compute node vec': succeed when the following conditions hold.
compute_node_vec(TermAtom, Dim, Vec) :-
    % Execute: ( catch(node_facts_embed_hook(TermAtom, Vec), _, fail).
    ( catch(node_facts_embed_hook(TermAtom, Vec), _, fail)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   hash_project(TermAtom, Dim, Vec)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% reindex_nexus/1 — rebuild vector index for a nexus using current hook
% ---------------------------------------------------------------------------

% Define a clause for 'reindex nexus': succeed when the following conditions hold.
reindex_nexus(Nexus) :-
    % Check that '( catch(nb_getval(node_fact_vec_dim, Dim), _, Dim' is unifiable with '32) -> true ; Dim = 32 )'.
    ( catch(nb_getval(node_fact_vec_dim, Dim), _, Dim = 32) -> true ; Dim = 32 ),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id-Rel-Args-Refs,
            % Continue the multi-line expression started above.
            lattice_node_fact(Nexus, Id, Rel, Args, Refs),
            % Supply 'Facts' as the next argument to the expression above.
            Facts),
    % Execute: ( nexus_vector_index(Nexus, OldVH).
    ( nexus_vector_index(Nexus, OldVH)
    % If the condition above succeeded, perform the following action.
    ->  retract(nexus_vector_index(Nexus, OldVH))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ),
    % State a fact for 'vb create' with the arguments listed below.
    vb_create(Dim, cosine, [capacity(10000)], NewVH),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(nexus_vector_index(Nexus, NewVH)),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(Id-Rel-Args-Refs, Facts),
        % Continue the multi-line expression started above.
        catch(
            % Continue the multi-line expression started above.
            ( term_to_atom(node_fact(Rel, Args, Refs), Term),
              % Continue the multi-line expression started above.
              compute_node_vec(Term, Dim, Vec),
              % Continue the multi-line expression started above.
              vb_insert(NewVH, Id, Vec, [])
            % Close the expression opened above.
            ),
            % Continue the multi-line expression started above.
            _, true
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% prune_node/1
% ---------------------------------------------------------------------------

% Define a clause for 'prune node': succeed when the following conditions hold.
prune_node(Id) :-
    % Execute: ( node_id_nexus(Id, Nexus).
    ( node_id_nexus(Id, Nexus)
    % If the condition above succeeded, perform the following action.
    ->  retractall(lattice_node_fact(Nexus, Id, _, _, _))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ),
    % Remove all matching facts from the runtime knowledge base.
    retractall(node_activation(Id, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(node_quenched(Id, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(node_id_nexus(Id, _)).

% ---------------------------------------------------------------------------
% traverse_nexus/4 — dual-phase: unification then similarity
% ---------------------------------------------------------------------------

% Define a clause for 'traverse nexus': succeed when the following conditions hold.
traverse_nexus(Nexus, Pattern, K, Results) :-
    % State a fact for 'nexus is open' with the arguments listed below.
    nexus_is_open(Nexus),
    % Phase 1: logical unification
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id-1.0, (
        % Continue the multi-line expression started above.
        lattice_node_fact(Nexus, Id, Rel, Args, Refs),
        % Continue the multi-line expression started above.
        node_fact(Rel, Args, Refs) = Pattern
    % Continue the multi-line expression started above.
    ), LogMatches),
    % Phase 2: vector similarity
    % Execute: ( nexus_vector_index(Nexus, VH),.
    ( nexus_vector_index(Nexus, VH),
      % Continue the multi-line expression started above.
      term_to_atom(Pattern, PatternAtom),
      % Continue the multi-line expression started above.
      ( catch(nb_getval(node_fact_vec_dim, Dim), _, Dim = 32) -> true ; Dim = 32 ),
      % Continue the multi-line expression started above.
      compute_node_vec(PatternAtom, Dim, QVec),
      % Continue the multi-line expression started above.
      vb_search(VH, QVec, K, VecResults)
    % If the condition above succeeded, perform the following action.
    ->  maplist([Score-VId, VId-Score]>>true, VecResults, VecPairs)
    % Otherwise (else branch), perform the following action.
    ;   VecPairs = []
    % Close the expression opened above.
    ),
    % Merge: score = LogicalMatch*0.6 + Semantic*0.4 + Recency*0.1
    % State the fact: merge results(Nexus, LogMatches, VecPairs, K, Results).
    merge_results(Nexus, LogMatches, VecPairs, K, Results).

% Define a clause for 'merge results': succeed when the following conditions hold.
merge_results(Nexus, LogMatches, VecPairs, K, Results) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id, lattice_node_fact(Nexus, Id, _, _, _), AllIds),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Score-Id, (
        % Continue the multi-line expression started above.
        member(Id, AllIds),
        % Continue the multi-line expression started above.
        log_score(Id, LogMatches, LS),
        % Continue the multi-line expression started above.
        vec_score(Id, VecPairs, VS),
        % Continue the multi-line expression started above.
        recency_score(Id, RS),
        % Continue the multi-line expression started above.
        Score is LS*0.6 + VS*0.4 + RS*0.1
    % Continue the multi-line expression started above.
    ), ScoredUnsorted),
    % Sort list 'ScoredUnsorted' into 'ScoredAsc', keeping duplicates.
    msort(ScoredUnsorted, ScoredAsc),
    % State a fact for 'reverse' with the arguments listed below.
    reverse(ScoredAsc, ScoredDesc),
    % State the fact: take k(K, ScoredDesc, Results).
    take_k(K, ScoredDesc, Results).

% Define a clause for 'log score': succeed when the following conditions hold.
log_score(Id, LogMatches, 1.0) :- member(Id-_, LogMatches), !.
% State the fact: log score(_, _, 0.0).
log_score(_, _, 0.0).

% Define a clause for 'vec score': succeed when the following conditions hold.
vec_score(Id, VecPairs, S) :- member(Id-S, VecPairs), !.
% State the fact: vec score(_, _, 0.0).
vec_score(_, _, 0.0).

% Define a clause for 'recency score': succeed when the following conditions hold.
recency_score(Id, S) :-
    % Execute: ( node_activation(Id, T, _).
    ( node_activation(Id, T, _)
    % If the condition above succeeded, perform the following action.
    ->  get_time(Now),
        % Continue the multi-line expression started above.
        Age is Now - T,
        % Continue the multi-line expression started above.
        S is max(0.0, 1.0 - Age / 3600.0)
    % Otherwise (else branch), perform the following action.
    ;   S = 0.0
    % Close the expression opened above.
    ).

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

% ---------------------------------------------------------------------------
% kindle_node/1 — raise activation, propagate +0.01 to neighbors
% ---------------------------------------------------------------------------

% Define a clause for 'kindle node': succeed when the following conditions hold.
kindle_node(Id) :-
    % quench wins: if quenched more recently, do not kindle
    % Execute: ( node_quenched(Id, QT),.
    ( node_quenched(Id, QT),
      % Continue the multi-line expression started above.
      node_activation(Id, AT, _),
      % Continue the multi-line expression started above.
      QT > AT
    % If the condition above succeeded, perform the following action.
    ->  true        % quench is more recent; inscribe contradiction
    % Otherwise (else branch), perform the following action.
    ;   get_time(T),
        % Continue the multi-line expression started above.
        retractall(node_activation(Id, _, _)),
        % Continue the multi-line expression started above.
        assertz(node_activation(Id, T, 1.0))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% quench_node/1 — lower activation, quench always wins
% ---------------------------------------------------------------------------

% Define a clause for 'quench node': succeed when the following conditions hold.
quench_node(Id) :-
    % State a fact for 'get time' with the arguments listed below.
    get_time(T),
    % Remove all matching facts from the runtime knowledge base.
    retractall(node_quenched(Id, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(node_quenched(Id, T)),
    % Execute: ( retract(node_activation(Id, _, W)).
    ( retract(node_activation(Id, _, W))
    % If the condition above succeeded, perform the following action.
    ->  W1 is max(0.0, W - 0.02),
        % Continue the multi-line expression started above.
        assertz(node_activation(Id, T, W1))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% live_node_facts/2 — Ids activated within the current window (3600 s)
% ---------------------------------------------------------------------------

% Define a clause for 'live node facts': succeed when the following conditions hold.
live_node_facts(Nexus, Ids) :-
    % State a fact for 'nexus is open' with the arguments listed below.
    nexus_is_open(Nexus),
    % State a fact for 'get time' with the arguments listed below.
    get_time(Now),
    % Evaluate the arithmetic expression 'Now - 3600.0' and bind the result to 'Window'.
    Window is Now - 3600.0,
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id, (
        % Continue the multi-line expression started above.
        node_id_nexus(Id, Nexus),
        % Continue the multi-line expression started above.
        node_activation(Id, T, _),
        % Continue the multi-line expression started above.
        T >= Window,
        % Continue the multi-line expression started above.
        \+ node_quenched(Id, _)
    % Continue the multi-line expression started above.
    ), Ids).
