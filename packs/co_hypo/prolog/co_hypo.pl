/*  PrologAI — Causalontology Hypothesis Management  (WP-406, Layer 381)

    Every analysis of what beats ARC-AGI-3 names the same failure of the losing
    agents: hypothesis drift — forming a candidate rule, then abandoning it at the
    first surprise, never committing to a correct-but-incomplete model. The winners
    generate several candidate explanations for a mechanic, score each by how well
    it predicts what was observed, and COMMIT to the best — revising only on real,
    repeated contradiction, not on noise.

    This pack is that discipline. A hypothesis is a candidate explanation for a
    model (a game). It carries a tally of supporting and contradicting evidence,
    and its score is the Laplace-smoothed fraction of evidence that supports it.
    Ranking orders the live hypotheses. Commitment is deliberately STICKY: the
    agent commits to the best hypothesis once it clears a threshold and leads its
    nearest rival by a margin, and thereafter KEEPS it — a challenger must beat the
    committed one by a WIDER switch margin (hysteresis) to take over, and the
    commitment is only abandoned outright when its score collapses below a floor.
    That hysteresis is the cure for drift: strong enough to hold a good model
    through a stray surprise, weak enough to yield when the model is truly wrong.

    Predicates:
      hy_reset/0                    clear all hypotheses
      hy_set_thresholds/3           -- +Commit, +Switch, +Abandon
      hy_propose/3                  -- +Model, +Hypothesis, -Id   (assert-if-new)
      hy_support/2                  -- +Model, +Hypothesis        (one confirming datum)
      hy_contradict/2               -- +Model, +Hypothesis        (one disconfirming datum)
      hy_score/3                    -- +Model, +Hypothesis, -Score
      hy_ranked/2                   -- +Model, -Ranked            (hyp(H,Score), best first)
      hy_best/3                     -- +Model, -Hypothesis, -Score
      hy_update_commitment/1        -- +Model                     (commit / keep / switch / drop)
      hy_committed/2                -- +Model, -Hypothesis
      hy_stale/1                    -- +Model  (committed model contradicted — re-orient)
      hy_stats/2                    -- +Model, -stats(N, Committed)
*/

% Declare this module and its hypothesis-management interface.
:- module(co_hypo, [
    % hy_reset/0: clear every hypothesis and commitment.
    hy_reset/0,
    % hy_set_thresholds/3: set the commit, switch, and abandon thresholds.
    hy_set_thresholds/3,
    % hy_propose/3: register a candidate hypothesis for a model (assert-if-new).
    hy_propose/3,
    % hy_support/2: record one confirming observation for a hypothesis.
    hy_support/2,
    % hy_contradict/2: record one disconfirming observation for a hypothesis.
    hy_contradict/2,
    % hy_score/3: a hypothesis's evidence score.
    hy_score/3,
    % hy_ranked/2: the model's hypotheses ranked best-first.
    hy_ranked/2,
    % hy_best/3: the single best hypothesis and its score.
    hy_best/3,
    % hy_update_commitment/1: decide whether to commit, keep, switch, or drop.
    hy_update_commitment/1,
    % hy_committed/2: the model's committed hypothesis, if any.
    hy_committed/2,
    % hy_stale/1: the committed hypothesis has been contradicted — re-orient.
    hy_stale/1,
    % hy_stats/2: a summary of a model's hypotheses.
    hy_stats/2,
    % hy_snapshot/2: a model's hypotheses and commitment, for persistence.
    hy_snapshot/2,
    % hy_restore/2: reload a model's hypotheses and commitment from a snapshot.
    hy_restore/2
]).

% List and aggregate helpers.
:- use_module(library(lists), [member/2, reverse/2]).
% Counting aggregation helper.
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% STATE
% ---------------------------------------------------------------------------

% hy_ev_/4: (Model, Hypothesis, Support, Contradict) — a hypothesis's evidence.
:- dynamic hy_ev_/4.
% hy_committed_/2: (Model, Hypothesis) — the model's committed hypothesis.
:- dynamic hy_committed_/2.
% hy_threshold_/3: (Commit, Switch, Abandon) — the commitment thresholds.
:- dynamic hy_threshold_/3.

% hy_reset: clear all hypotheses, commitments, and restore default thresholds.
hy_reset :-
    % Forget every hypothesis's evidence.
    retractall(hy_ev_(_, _, _, _)),
    % Forget every model's commitment.
    retractall(hy_committed_(_, _)),
    % Forget any custom thresholds.
    retractall(hy_threshold_(_, _, _)),
    % Defaults: commit at 0.70; a challenger must lead the committed hypothesis by
    % 0.15 in score to switch (hysteresis — normally reached only once the committed
    % one has been contradicted and its score has fallen); abandon a committed
    % hypothesis outright when its score collapses below 0.40.
    assertz(hy_threshold_(0.70, 0.15, 0.40)).

% hy_set_thresholds(+Commit, +Switch, +Abandon): set the commitment thresholds.
hy_set_thresholds(Commit, Switch, Abandon) :-
    % Insist all three thresholds are numbers.
    number(Commit), number(Switch), number(Abandon),
    % Drop any thresholds currently in force.
    retractall(hy_threshold_(_, _, _)),
    % Install the new thresholds.
    assertz(hy_threshold_(Commit, Switch, Abandon)).

% hy_thresholds(-Commit, -Switch, -Abandon): the current thresholds, with defaults.
hy_thresholds(Commit, Switch, Abandon) :-
    % Read the stored thresholds if present, else fall back to the built-in defaults.
    ( hy_threshold_(C, S, A) -> Commit = C, Switch = S, Abandon = A
    ; Commit = 0.70, Switch = 0.25, Abandon = 0.40 ).

% ---------------------------------------------------------------------------
% PROPOSAL AND EVIDENCE
% ---------------------------------------------------------------------------

% hy_propose(+Model, +Hypothesis, -Id): register a candidate hypothesis. If it is
% already present it is reused (no duplicate); the id is the hypothesis term.
hy_propose(Model, Hypothesis, Hypothesis) :-
    % Reuse it if it already exists, otherwise assert it with an empty tally.
    ( hy_ev_(Model, Hypothesis, _, _) -> true
    ; assertz(hy_ev_(Model, Hypothesis, 0, 0)) ).

% hy_support(+Model, +Hypothesis): record one confirming observation.
hy_support(Model, Hypothesis) :-
    % Make sure the hypothesis exists first.
    hy_propose(Model, Hypothesis, _),
    % Take its current evidence tally out.
    retract(hy_ev_(Model, Hypothesis, S, C)),
    % Increment the supporting count.
    S1 is S + 1,
    % Put the updated tally back.
    assertz(hy_ev_(Model, Hypothesis, S1, C)).

% hy_contradict(+Model, +Hypothesis): record one disconfirming observation.
hy_contradict(Model, Hypothesis) :-
    % Make sure the hypothesis exists first.
    hy_propose(Model, Hypothesis, _),
    % Take its current evidence tally out.
    retract(hy_ev_(Model, Hypothesis, S, C)),
    % Increment the contradicting count.
    C1 is C + 1,
    % Put the updated tally back.
    assertz(hy_ev_(Model, Hypothesis, S, C1)).

% hy_score(+Model, +Hypothesis, -Score): the Laplace-smoothed support fraction —
% (Support + 1) / (Support + Contradict + 2). A hypothesis with no evidence scores
% 0.5; consistent support drives it toward 1, consistent contradiction toward 0.
hy_score(Model, Hypothesis, Score) :-
    % Read the hypothesis's evidence tally.
    hy_ev_(Model, Hypothesis, S, C),
    % Compute the Laplace-smoothed support fraction.
    Score is (S + 1) / (S + C + 2).

% ---------------------------------------------------------------------------
% RANKING
% ---------------------------------------------------------------------------

% hy_ranked(+Model, -Ranked): the model's hypotheses as hyp(Hypothesis, Score),
% highest score first. Ties break by more total evidence, then term order.
hy_ranked(Model, Ranked) :-
    % Each hypothesis keyed by a sort key that puts the best first.
    findall(k(NegScore, NegEvidence) - hyp(H, Score),
        % For every hypothesis of this model,
        ( hy_ev_(Model, H, S, C),
          % compute its score,
          hy_score(Model, H, Score),
          % negate the score so a higher score sorts earlier,
          NegScore is -Score,
          % and negate the total evidence so more evidence breaks ties earlier.
          NegEvidence is -(S + C) ),
        % Collect the keyed hypotheses.
        Keyed),
    % Sort ascending by the negated keys (so highest score, most evidence, first).
    keysort(Keyed, Sorted),
    % Strip the keys, keeping only the hyp(Hypothesis, Score) values in order.
    findall(Hyp, member(_ - Hyp, Sorted), Ranked).

% hy_best(+Model, -Hypothesis, -Score): the single best hypothesis.
hy_best(Model, Hypothesis, Score) :-
    % Take the head of the ranked list.
    hy_ranked(Model, [hyp(Hypothesis, Score) | _]).

% ---------------------------------------------------------------------------
% COMMITMENT — sticky, with hysteresis, the cure for drift
% ---------------------------------------------------------------------------

% hy_update_commitment(+Model): the commitment decision. With nothing committed,
% commit the best hypothesis if it clears the commit threshold and leads its rival
% by the commit margin. With a hypothesis already committed, KEEP it unless its
% score has collapsed below the abandon floor, or a challenger leads it by the
% wider switch margin — the hysteresis that holds a good model through a surprise.
hy_update_commitment(Model) :-
    % Read the three thresholds in force.
    hy_thresholds(Commit, Switch, Abandon),
    % Get the model's hypotheses ranked best-first.
    hy_ranked(Model, Ranked),
    % Branch on whether a hypothesis is already committed.
    (   hy_committed_(Model, HC)
    % A hypothesis is already committed: decide keep / switch / drop.
    ->  hy_committed_decision(Model, HC, Ranked, Commit, Switch, Abandon)
    % Nothing committed yet: decide whether the best earns commitment.
    ;   hy_fresh_commit(Model, Ranked, Commit)
    ).

% hy_fresh_commit(+Model, +Ranked, +Commit): commit the best hypothesis when it
% clears the commit threshold and leads the runner-up by the commit lead (0.10).
hy_fresh_commit(Model, [hyp(HB, SB) | Rest], Commit) :-
    % The best must clear the commit threshold.
    SB >= Commit,
    % If there is a runner-up, the best must lead it by the commit margin.
    ( Rest = [hyp(_, SR) | _] -> SB - SR >= 0.05 ; true ),
    % Commit to this decision.
    !,
    % Record the best hypothesis as committed.
    assertz(hy_committed_(Model, HB)).
% Otherwise commit to nothing yet (keep exploring).
hy_fresh_commit(_, _, _).

% hy_committed_decision(+Model, +HC, +Ranked, +Commit, +Switch, +Abandon): keep the
% committed hypothesis, switch to a clearly-better challenger, or abandon it.
hy_committed_decision(Model, HC, Ranked, Commit, Switch, Abandon) :-
    % The committed hypothesis's current score.
    ( member(hyp(HC, SC), Ranked) -> true ; SC = 0.0 ),
    % The best challenger that is NOT the committed hypothesis.
    ( member(hyp(HCh, SCh), Ranked), HCh \== HC -> true ; HCh = none, SCh = 0.0 ),
    % Decide among collapse, switch, and keep.
    (   % Collapsed: the committed model is now worse than the abandon floor.
        SC < Abandon
    % Drop the collapsed commitment.
    ->  retractall(hy_committed_(Model, _)),
        % If a challenger is strong, adopt it at once; else re-open exploration.
        ( SCh >= Commit -> assertz(hy_committed_(Model, HCh)) ; true )
    ;   % A challenger beats it by the wider switch margin: switch.
        HCh \== none, SCh - SC >= Switch, SCh >= Commit
    % Drop the old commitment first.
    ->  retractall(hy_committed_(Model, _)),
        % Adopt the winning challenger.
        assertz(hy_committed_(Model, HCh))
    ;   % Otherwise KEEP the committed hypothesis (hysteresis holds it).
        true
    ).

% hy_committed(+Model, -Hypothesis): the model's committed hypothesis, if any.
hy_committed(Model, Hypothesis) :-
    % Read the stored commitment.
    hy_committed_(Model, Hypothesis).

% hy_stale(+Model): the committed hypothesis is under real pressure — its score has
% dropped to or below the midpoint despite being committed, a signal to re-orient
% (gather more evidence or generate new hypotheses) before it must be abandoned.
hy_stale(Model) :-
    % There must be a committed hypothesis.
    hy_committed_(Model, HC),
    % Read its current score.
    hy_score(Model, HC, SC),
    % It is stale when that score has fallen to or below the midpoint.
    SC =< 0.5.

% ---------------------------------------------------------------------------
% SUMMARY
% ---------------------------------------------------------------------------

% hy_stats(+Model, -stats(N, Committed)): how many hypotheses the model holds and
% which, if any, is committed.
hy_stats(Model, stats(N, Committed)) :-
    % Count the model's hypotheses.
    aggregate_all(count, hy_ev_(Model, _, _, _), N),
    % Report the committed hypothesis, or the atom none if there is none.
    ( hy_committed_(Model, H) -> Committed = H ; Committed = none ).

% ---------------------------------------------------------------------------
% PERSISTENCE — snapshot a model's hypotheses and commitment out, restore them in
% ---------------------------------------------------------------------------

% hy_snapshot(+Model, -state(Ev, Committed)): the model's evidence tallies as a
% ground list of ev(Hypothesis, Support, Contradict), plus the committed hypothesis
% (or the atom none). A serialisable copy of the model's whole hypothesis state, so
% a caller can write it to disk. Thresholds are global policy, not per-model, so
% they are not part of a model's snapshot.
hy_snapshot(Model, state(Ev, Committed)) :-
    % Collect every hypothesis's evidence tally as an ev/3 term.
    findall(ev(Hypothesis, S, C), hy_ev_(Model, Hypothesis, S, C), Ev),
    % Record the committed hypothesis, or the atom none if there is none.
    ( hy_committed_(Model, HC) -> Committed = HC ; Committed = none ).

% hy_restore(+Model, +state(Ev, Committed)): replace this model's hypotheses and
% commitment with the snapshot. The model's existing evidence and commitment are
% dropped first, so restore is idempotent.
hy_restore(Model, state(Ev, Committed)) :-
    % Drop the model's existing evidence.
    retractall(hy_ev_(Model, _, _, _)),
    % Drop the model's existing commitment.
    retractall(hy_committed_(Model, _)),
    % Re-assert every evidence tally from the snapshot.
    forall(member(ev(Hypothesis, S, C), Ev),
        assertz(hy_ev_(Model, Hypothesis, S, C))),
    % Restore the committed hypothesis unless the snapshot recorded none.
    ( Committed == none -> true ; assertz(hy_committed_(Model, Committed)) ).

% Install the default thresholds at load time.
:- initialization(( \+ hy_threshold_(_, _, _) -> assertz(hy_threshold_(0.70, 0.15, 0.40)) ; true )).
