/*  PrologAI — Somatic Markers: Affective Pre-Selection  (Specification PR 24)

    At episode close the prevailing valence and arousal are stamped onto the
    episode.  Stamps aggregate per causal_plan and per situation_prototype as
    running weighted statistics.  Before deliberation, candidates are filtered:
    strongly negative markers prune candidates; strongly positive markers boost
    them; deliberation may override any marker when explicit evidence contradicts
    it (the override flag).

    Aggregation uses exponential moving average:
        mean_v' = mean_v + α·(valence  - mean_v)
        mean_a' = mean_a + α·(arousal  - mean_a)
    where α = 1/episode_count (consistent with count-weighted mean).

    Markers decay each cycle toward neutral (0.0) at a configurable rate.

    Predicates:
        pai_marker_stamp/2      — +Plan, +episode(Valence,Arousal)
        pai_marker_of/2         — +Plan, -marker(MeanV,MeanA,Count)
        pai_marker_filter/3     — +Candidates, +Opts, -Filtered
        pai_marker_decay/0      — tick: decay all markers toward neutral
        pai_marker_override/2   — +Plan, +ExplicitEvidence (inhibit marker)
*/

% Declare this file as the 'markers' module and list its exported predicates.
:- module(markers, [
    % Continue the multi-line expression started above.
    pai_marker_stamp/2,      % +Plan, +episode(Valence, Arousal)
    % Continue the multi-line expression started above.
    pai_marker_of/2,         % +Plan, -marker(MeanV, MeanA, Count)
    % Continue the multi-line expression started above.
    pai_marker_filter/3,     % +Candidates, +Opts, -Filtered
    % Supply 'pai_marker_decay/0' as the next argument to the expression above.
    pai_marker_decay/0,
    % Continue the multi-line expression started above.
    pai_marker_override/2    % +Plan, +ExplicitEvidence
% Close the expression opened above.
]).

% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),     [member/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% Declare 'plan_marker/4.       % Plan, MeanValence, MeanArousal, Count' as dynamic — its facts may be added or removed at runtime.
:- dynamic plan_marker/4.       % Plan, MeanValence, MeanArousal, Count
% Declare 'marker_override/2.   % Plan, ExplicitEvidence' as dynamic — its facts may be added or removed at runtime.
:- dynamic marker_override/2.   % Plan, ExplicitEvidence

% State the fact: marker decay rate(0.05).
marker_decay_rate(0.05).
% State the fact: prune threshold(-0.5).
prune_threshold(-0.5).
% Check that 'boost_threshold(0.5).           % used as sort key (higher' is unifiable with 'earlier in result)'.
boost_threshold(0.5).           % used as sort key (higher = earlier in result)

% ---------------------------------------------------------------------------
% pai_marker_stamp/2
% ---------------------------------------------------------------------------

% Define a clause for 'pai marker stamp': succeed when the following conditions hold.
pai_marker_stamp(Plan, episode(Valence, Arousal)) :-
    % Execute: ( retract(plan_marker(Plan, OldV, OldA, N)).
    ( retract(plan_marker(Plan, OldV, OldA, N))
    % If the condition above succeeded, perform the following action.
    ->  N1 is N + 1,
        % Continue the multi-line expression started above.
        Alpha is 1.0 / N1,
        % Continue the multi-line expression started above.
        NewV is OldV + Alpha * (Valence - OldV),
        % Continue the multi-line expression started above.
        NewA is OldA + Alpha * (Arousal  - OldA)
    % Otherwise (else branch), perform the following action.
    ;   N1 = 1,
        % Continue the multi-line expression started above.
        NewV = Valence,
        % Continue the multi-line expression started above.
        NewA = Arousal
    % Close the expression opened above.
    ),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(plan_marker(Plan, NewV, NewA, N1)).

% ---------------------------------------------------------------------------
% pai_marker_of/2
% ---------------------------------------------------------------------------

% Define a clause for 'pai marker of': succeed when the following conditions hold.
pai_marker_of(Plan, marker(MeanV, MeanA, Count)) :-
    % Execute: ( plan_marker(Plan, MeanV, MeanA, Count).
    ( plan_marker(Plan, MeanV, MeanA, Count)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   MeanV = 0.0, MeanA = 0.0, Count = 0
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_marker_filter/3
%
%   Opts:
%     override(Plan) — ignore marker for this specific plan
%     min_count(N)   — only apply marker if at least N stamps exist
% ---------------------------------------------------------------------------

% Define a clause for 'pai marker filter': succeed when the following conditions hold.
pai_marker_filter(Candidates, Opts, Filtered) :-
    % State a fact for 'min count opt' with the arguments listed below.
    min_count_opt(Opts, MinCount),
    % State a fact for 'prune threshold' with the arguments listed below.
    prune_threshold(PruneT),
    % Build scored pairs, omitting pruned candidates
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Score-C, (
        % Continue the multi-line expression started above.
        member(C, Candidates),
        % Continue the multi-line expression started above.
        extract_plan(C, Plan),
        % Continue the multi-line expression started above.
        \+ prune_candidate(Plan, Opts, MinCount, PruneT),
        % Continue the multi-line expression started above.
        candidate_marker_score(Plan, Opts, MinCount, Score)
    % Continue the multi-line expression started above.
    ), Scored),
    % Sort list 'Scored' into 'Asc', keeping duplicates.
    msort(Scored, Asc),
    % State the fact: pairs values desc(Asc, Filtered).
    pairs_values_desc(Asc, Filtered).

% Define a clause for 'prune candidate': succeed when the following conditions hold.
prune_candidate(Plan, Opts, MinCount, PruneT) :-
    % Succeed only if 'has_override(Plan, Opts' cannot be proved (negation as failure).
    \+ has_override(Plan, Opts),
    % State a fact for 'plan marker' with the arguments listed below.
    plan_marker(Plan, MeanV, _, Count),
    % Check that 'Count' is greater than or equal to 'MinCount'.
    Count >= MinCount,
    % Check that 'MeanV' is less than 'PruneT'.
    MeanV < PruneT.

% Define a clause for 'candidate marker score': succeed when the following conditions hold.
candidate_marker_score(Plan, Opts, MinCount, Score) :-
    % Execute: ( \+ has_override(Plan, Opts),.
    ( \+ has_override(Plan, Opts),
      % Continue the multi-line expression started above.
      plan_marker(Plan, MeanV, _, Count),
      % Continue the multi-line expression started above.
      Count >= MinCount
    % If the condition above succeeded, perform the following action.
    ->  Score = MeanV
    % Otherwise (else branch), perform the following action.
    ;   Score = 0.0
    % Close the expression opened above.
    ).

% Define a clause for 'extract plan': succeed when the following conditions hold.
extract_plan(C, Plan) :-
    % Check that '( C' is unifiable with 'candidate(Plan, _) -> true ; Plan = C )'.
    ( C = candidate(Plan, _) -> true ; Plan = C ).

% Define a clause for 'pairs values desc': succeed when the following conditions hold.
pairs_values_desc(Pairs, Values) :-
    % Unify 'N' with the number of elements in list 'Pairs'.
    length(Pairs, N),
    % Unify 'N' with the number of elements in list 'Values'.
    length(Values, N),
    % State the fact: pairs values desc (Pairs, N, Values).
    pairs_values_desc_(Pairs, N, Values).

% Define a clause for 'pairs values desc ': succeed when the following conditions hold.
pairs_values_desc_(_, 0, []) :- !.
% Define a clause for 'pairs values desc ': succeed when the following conditions hold.
pairs_values_desc_(Pairs, N, [Last|Rest]) :-
    % Check that 'N' is greater than '0'.
    N > 0,
    % Evaluate the arithmetic expression 'N - 1' and bind the result to 'N1'.
    N1 is N - 1,
    % Retrieve the element at the specified one-based position from the list.
    nth1(N, Pairs, _-Last),
    % State the fact: pairs values desc (Pairs, N1, Rest).
    pairs_values_desc_(Pairs, N1, Rest).

% Define a clause for 'has override': succeed when the following conditions hold.
has_override(Plan, Opts) :-
    % Execute: ( memberchk(override(Plan), Opts).
    ( memberchk(override(Plan), Opts)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   marker_override(Plan, _)
    % Close the expression opened above.
    ).

% Define a clause for 'min count opt': succeed when the following conditions hold.
min_count_opt(Opts, N) :-
    % Check that '( memberchk(min_count(N), Opts) -> true ; N' is unifiable with '1 )'.
    ( memberchk(min_count(N), Opts) -> true ; N = 1 ).

% ---------------------------------------------------------------------------
% pai_marker_decay/0
% ---------------------------------------------------------------------------

% Execute: pai_marker_decay :-.
pai_marker_decay :-
    % State a fact for 'marker decay rate' with the arguments listed below.
    marker_decay_rate(Rate),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(P-V-A-N, plan_marker(P, V, A, N), All),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(P-V-A-N, All),
        % Continue the multi-line expression started above.
        ( retract(plan_marker(P, V, A, N)),
          % Continue the multi-line expression started above.
          NewV is V * (1.0 - Rate),
          % Continue the multi-line expression started above.
          NewA is A * (1.0 - Rate),
          % Continue the multi-line expression started above.
          assertz(plan_marker(P, NewV, NewA, N))
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_marker_override/2
% ---------------------------------------------------------------------------

% Define a clause for 'pai marker override': succeed when the following conditions hold.
pai_marker_override(Plan, ExplicitEvidence) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(marker_override(Plan, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(marker_override(Plan, ExplicitEvidence)).
