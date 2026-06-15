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

:- module(markers, [
    pai_marker_stamp/2,      % +Plan, +episode(Valence, Arousal)
    pai_marker_of/2,         % +Plan, -marker(MeanV, MeanA, Count)
    pai_marker_filter/3,     % +Candidates, +Opts, -Filtered
    pai_marker_decay/0,
    pai_marker_override/2    % +Plan, +ExplicitEvidence
]).

:- use_module(library(lists),     [member/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

:- dynamic plan_marker/4.       % Plan, MeanValence, MeanArousal, Count
:- dynamic marker_override/2.   % Plan, ExplicitEvidence

marker_decay_rate(0.05).
prune_threshold(-0.5).
boost_threshold(0.5).           % used as sort key (higher = earlier in result)

% ---------------------------------------------------------------------------
% pai_marker_stamp/2
% ---------------------------------------------------------------------------

pai_marker_stamp(Plan, episode(Valence, Arousal)) :-
    ( retract(plan_marker(Plan, OldV, OldA, N))
    ->  N1 is N + 1,
        Alpha is 1.0 / N1,
        NewV is OldV + Alpha * (Valence - OldV),
        NewA is OldA + Alpha * (Arousal  - OldA)
    ;   N1 = 1,
        NewV = Valence,
        NewA = Arousal
    ),
    assertz(plan_marker(Plan, NewV, NewA, N1)).

% ---------------------------------------------------------------------------
% pai_marker_of/2
% ---------------------------------------------------------------------------

pai_marker_of(Plan, marker(MeanV, MeanA, Count)) :-
    ( plan_marker(Plan, MeanV, MeanA, Count)
    ->  true
    ;   MeanV = 0.0, MeanA = 0.0, Count = 0
    ).

% ---------------------------------------------------------------------------
% pai_marker_filter/3
%
%   Opts:
%     override(Plan) — ignore marker for this specific plan
%     min_count(N)   — only apply marker if at least N stamps exist
% ---------------------------------------------------------------------------

pai_marker_filter(Candidates, Opts, Filtered) :-
    min_count_opt(Opts, MinCount),
    prune_threshold(PruneT),
    % Build scored pairs, omitting pruned candidates
    findall(Score-C, (
        member(C, Candidates),
        extract_plan(C, Plan),
        \+ prune_candidate(Plan, Opts, MinCount, PruneT),
        candidate_marker_score(Plan, Opts, MinCount, Score)
    ), Scored),
    msort(Scored, Asc),
    pairs_values_desc(Asc, Filtered).

prune_candidate(Plan, Opts, MinCount, PruneT) :-
    \+ has_override(Plan, Opts),
    plan_marker(Plan, MeanV, _, Count),
    Count >= MinCount,
    MeanV < PruneT.

candidate_marker_score(Plan, Opts, MinCount, Score) :-
    ( \+ has_override(Plan, Opts),
      plan_marker(Plan, MeanV, _, Count),
      Count >= MinCount
    ->  Score = MeanV
    ;   Score = 0.0
    ).

extract_plan(C, Plan) :-
    ( C = candidate(Plan, _) -> true ; Plan = C ).

pairs_values_desc(Pairs, Values) :-
    length(Pairs, N),
    length(Values, N),
    pairs_values_desc_(Pairs, N, Values).

pairs_values_desc_(_, 0, []) :- !.
pairs_values_desc_(Pairs, N, [Last|Rest]) :-
    N > 0,
    N1 is N - 1,
    nth1(N, Pairs, _-Last),
    pairs_values_desc_(Pairs, N1, Rest).

has_override(Plan, Opts) :-
    ( memberchk(override(Plan), Opts)
    ->  true
    ;   marker_override(Plan, _)
    ).

min_count_opt(Opts, N) :-
    ( memberchk(min_count(N), Opts) -> true ; N = 1 ).

% ---------------------------------------------------------------------------
% pai_marker_decay/0
% ---------------------------------------------------------------------------

pai_marker_decay :-
    marker_decay_rate(Rate),
    findall(P-V-A-N, plan_marker(P, V, A, N), All),
    forall(
        member(P-V-A-N, All),
        ( retract(plan_marker(P, V, A, N)),
          NewV is V * (1.0 - Rate),
          NewA is A * (1.0 - Rate),
          assertz(plan_marker(P, NewV, NewA, N))
        )
    ).

% ---------------------------------------------------------------------------
% pai_marker_override/2
% ---------------------------------------------------------------------------

pai_marker_override(Plan, ExplicitEvidence) :-
    retractall(marker_override(Plan, _)),
    assertz(marker_override(Plan, ExplicitEvidence)).
