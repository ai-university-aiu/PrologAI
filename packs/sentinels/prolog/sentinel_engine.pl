/*  PrologAI — Sentinel Engine  (Specification Section 3.5, PR 9)

    Wires sentinel evaluation into anchor_node/4 via the post_anchor_node_hook
    multifile predicate defined in node_facts.pl.

    Evaluation phases:
      Phase 1 — logical unification of Change against each sentinel's Pattern.
      Phase 2 — semantic similarity via hash_project + cosine_similarity (>= 0.75).

    Firing order follows Priority descending; higher priority fires first.
    When a sentinel fires: Objectives are kindled, Action is called, and a
    sentinel_fired event is published on sentinel://fired.
*/

% Declare this file as the 'sentinel_engine' module and list its exported predicates.
:- module(sentinel_engine, [
    % Continue the multi-line expression started above.
    sentinels_evaluate/5,        % +Nexus, +Id, +Relation, +Args, +Referents
    % Continue the multi-line expression started above.
    sentinels_fire_threshold/1    % -Threshold (default 0.75)
% Close the expression opened above.
]).

% Load the built-in 'sentinels' library so its predicates are available here.
:- use_module(library(sentinels),      [sentinels_entry/6,
                                        % Continue the multi-line expression started above.
                                        sentinels_domain_active/1]).
% Import [kindle_node/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts),     [kindle_node/1]).
% Import [hash_project/3, cosine_similarity/3] from the built-in 'backend_prolog' library.
:- use_module(library(backend_prolog), [hash_project/3, cosine_similarity/3]).
% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),          [member/2]).

% ---------------------------------------------------------------------------
% Default similarity threshold
% ---------------------------------------------------------------------------

% Declare 'sentinels_sim_threshold/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic sentinels_sim_threshold/1.
% State the fact: sentinel sim threshold(0.75).
sentinels_sim_threshold(0.75).

% Define a clause for 'sentinel fire threshold': succeed when the following conditions hold.
sentinels_fire_threshold(T) :- sentinels_sim_threshold(T).

% ---------------------------------------------------------------------------
% Hook into anchor_node — multifile clause in node_facts module
% ---------------------------------------------------------------------------

% Execute the compile-time directive: multifile node_facts:post_anchor_node_hook/5.
:- multifile node_facts:post_anchor_node_hook/5.

% Execute: node_facts:post_anchor_node_hook(Nexus, Id, Relation, Args, Referents) :-.
node_facts:post_anchor_node_hook(Nexus, Id, Relation, Args, Referents) :-
    % State the fact: evaluate sentinels(Nexus, Id, Relation, Args, Referents).
    sentinels_evaluate(Nexus, Id, Relation, Args, Referents).

% ---------------------------------------------------------------------------
% sentinels_evaluate/5
% ---------------------------------------------------------------------------

% Define a clause for 'evaluate sentinels': succeed when the following conditions hold.
sentinels_evaluate(Nexus, Id, Relation, Args, Referents) :-
    % Check that 'Change' is unifiable with 'node_fact(Id, Relation, Args, Referents)'.
    Change = node_fact(Id, Relation, Args, Referents),
    % Collect all sentinels from active domains, sorted by priority desc
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Priority-Domain-Pattern-Objectives-Action, (
        % Continue the multi-line expression started above.
        sentinels_entry(Domain, Priority, Pattern, Objectives, Action, _),
        % Continue the multi-line expression started above.
        sentinels_domain_active(Domain)
    % Continue the multi-line expression started above.
    ), Raw),
    % Sort list 'Raw' into 'Asc', keeping duplicates.
    msort(Raw, Asc),
    % State a fact for 'reverse' with the arguments listed below.
    reverse(Asc, ByPriority),
    % State the fact: evaluate ordered(Nexus, Change, ByPriority).
    sentinels_evaluate_ordered(Nexus, Change, ByPriority).

% State the fact: evaluate ordered(_, _, []).
sentinels_evaluate_ordered(_, _, []).
% Define a clause for 'evaluate ordered': succeed when the following conditions hold.
sentinels_evaluate_ordered(Nexus, Change, [_-_-Pattern-Objectives-Action | Rest]) :-
    % Execute: ( sentinels_matches(Change, Pattern).
    ( sentinels_matches(Change, Pattern)
    % If the condition above succeeded, perform the following action.
    ->  sentinels_fire(Nexus, Change, Objectives, Action)
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ),
    % State the fact: evaluate ordered(Nexus, Change, Rest).
    sentinels_evaluate_ordered(Nexus, Change, Rest).

% ---------------------------------------------------------------------------
% Phase 1 — logical unification (non-destructive via \+\+)
% Phase 2 — semantic similarity
% ---------------------------------------------------------------------------

% Define a clause for 'matches sentinel': succeed when the following conditions hold.
sentinels_matches(Change, Pattern) :-
    % Succeed only if '\+ Change = Pattern.      % Phase 1: logical unification' cannot be proved (negation as failure).
    \+ \+ Change = Pattern.      % Phase 1: logical unification
% Define a clause for 'matches sentinel': succeed when the following conditions hold.
sentinels_matches(Change, Pattern) :-
    % State a fact for 'sentinel sim threshold' with the arguments listed below.
    sentinels_sim_threshold(Thresh),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Change, CA),
    % State a fact for 'term to atom' with the arguments listed below.
    term_to_atom(Pattern, PA),
    % State a fact for 'hash project' with the arguments listed below.
    hash_project(CA, 32, VC),
    % State a fact for 'hash project' with the arguments listed below.
    hash_project(PA, 32, VP),
    % State a fact for 'cosine similarity' with the arguments listed below.
    cosine_similarity(VC, VP, Score),
    % Check that 'Score' is greater than or equal to 'Thresh.             % Phase 2: semantic similarity'.
    Score >= Thresh.             % Phase 2: semantic similarity

% ---------------------------------------------------------------------------
% sentinels_fire/4
% ---------------------------------------------------------------------------

% Define a clause for 'fire sentinel': succeed when the following conditions hold.
sentinels_fire(_Nexus, Change, Objectives, Action) :-
    % Kindle each objective node
    % State a fact for 'maplist safe' with the arguments listed below.
    sentinels_maplist_safe(kindle_node, Objectives),
    % Execute the sentinel's action
    % State a fact for 'catch' with the arguments listed below.
    catch(call(Action), Err,
        % Continue the multi-line expression started above.
        print_message(warning,
            % Continue the multi-line expression started above.
            format("sentinel action error: ~w on change ~w", [Err, Change]))
    % Close the expression opened above.
    ),
    % Publish sentinel_fired event (non-fatal if pubsub not loaded)
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        pubsub:publish('sentinel://fired', Change),
        % Supply '_' as the next argument to the expression above.
        _,
        % Supply 'true' as the next argument to the expression above.
        true
    % Close the expression opened above.
    ).

% State the fact: maplist safe(_, []).
sentinels_maplist_safe(_, []).
% Define a clause for 'maplist safe': succeed when the following conditions hold.
sentinels_maplist_safe(Goal, [H|T]) :-
    % State a fact for 'catch' with the arguments listed below.
    catch(call(Goal, H), _, true),
    % State the fact: maplist safe(Goal, T).
    sentinels_maplist_safe(Goal, T).
