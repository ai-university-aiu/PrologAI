/*  PrologAI — Nexus Integration Pack Test Suite  (WP-390)

    Acceptance tests for all nx_* predicates. Every test exercises the
    REAL predicates of both sides of a wiring — the world model's novelty,
    the curiosity error window, the agency loop, the hierarchical planner,
    the evolutionary search, the refinery scorer, the J-Space ledger, and
    the workspace broadcast-subscription list — nothing is stubbed.

    Because nexus imports other packs by library(...) alias, run this suite
    with every pack's prolog directory on the library path:

        LIB=""; for d in packs/*/prolog syntax/prolog; do LIB="$LIB -p library=$d"; done
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/nexus/test/test_nexus.pl
*/

% Declare this file as a test module so its helper predicates are qualifiable.
:- module(test_nexus, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(nexus)).

% Load the packs whose constructors and readers the tests call directly.
:- use_module(library(jspace), [js_open/1, js_strength/3, js_reading/2, js_active/2]).
:- use_module(library(planner), [ht_domain/3]).
:- use_module(library(world_model), [world_model_novelty/3]).

% ===========================================================================
% TEST FIXTURES AND CRITERION HELPERS
% ===========================================================================

% close_to(+A, +B): loose float comparison.
close_to(A, B) :-
    % Agreement to nine decimal places suffices.
    abs(A - B) < 1.0e-9.

% The travel domain shared with the planner pack tests.
travel_domain(Domain) :-
    % Assemble the domain from primitives and methods.
    ht_domain(
        % The four primitive actions.
        [prim(walk(X1, Y1), [at(me, X1), short(X1, Y1)], [at(me, Y1)], [at(me, X1)]),
         prim(call_taxi(X2), [at(me, X2)], [taxi_at(X2)], []),
         prim(ride(X3, Y3), [at(me, X3), taxi_at(X3)], [at(me, Y3)], [at(me, X3), taxi_at(X3)]),
         prim(pay, [has_cash], [paid], [has_cash])],
        % Walking is preferred; the taxi is the fall-back.
        [meth(go_by_foot, travel(X4, Y4), [short(X4, Y4)], [walk(X4, Y4)]),
         meth(go_by_taxi, travel(X5, Y5), [has_cash], [call_taxi(X5), ride(X5, Y5), pay])],
        Domain).

% Criterion helpers for the evolve-under-critique tests (module-qualified so
% the refinery scorer can call them).
% starts_with(+X, +Genome): the genome begins with X.
starts_with(X, [X | _]).
% ends_with(+X, +Genome): the genome ends with X.
ends_with(X, G) :- last(G, X).
% contains(+X, +Genome): the genome contains X somewhere.
contains(X, G) :- memberchk(X, G).

% The reasoning-operator criteria: a valid trace observes first, concludes
% last, and deduces somewhere in between.
reasoning_criteria([
    % The trace must start by observing.
    criterion(starts_observe, test_nexus:starts_with(observe)),
    % The trace must end by concluding.
    criterion(ends_conclude, test_nexus:ends_with(conclude)),
    % The trace must contain a deduction.
    criterion(has_deduce, test_nexus:contains(deduce))
]).

% ===========================================================================
% INTROSPECTION
% ===========================================================================

:- begin_tests(nexus_introspection).

% The pack describes exactly its four wirings.
test(four_wirings) :-
    % Ask for the wiring description.
    nx_wirings(Wirings),
    % There are four of them.
    length(Wirings, 4),
    % The four expected wiring keys are present.
    forall(member(K, [jspace_from_workspace, curiosity_from_world_model,
                       agency_with_planner, evolve_with_refinery]),
           memberchk(wiring(K, _), Wirings)).

:- end_tests(nexus_introspection).

% ===========================================================================
% WIRING ONE — jspace <- workspace broadcast
% ===========================================================================

:- begin_tests(nexus_workspace).

% Holding a broadcast places its winning coalition's concepts in the J-Space.
test(hold_broadcast_direct) :-
    % A fresh workspace.
    js_open(w_hold),
    % Route one broadcast through the hook the live workspace would call.
    nx_hold_broadcast(w_hold, broadcast_content(c1, goal, [find_marble, hungry], 0.7)),
    % Both concepts are now held at the broadcast salience.
    js_strength(w_hold, find_marble, S1),
    % Check the first concept's strength.
    close_to(S1, 0.7),
    % Check the second concept's strength.
    js_strength(w_hold, hungry, S2),
    % The second concept carries the same salience.
    close_to(S2, 0.7).

% Replaying an episode ranks the J-Lens readout by broadcast salience.
test(replay_ranks_by_salience) :-
    % A fresh workspace.
    js_open(w_replay),
    % Replay a two-broadcast reasoning episode.
    nx_replay_broadcasts(w_replay, [
        broadcast_content(c1, goal, [find_marble], 0.6),
        broadcast_content(c2, percept, [red_cube], 0.9)
    ]),
    % The live readout is strongest-first.
    nx_broadcast_reading(w_replay, Reading),
    % The most salient percept leads the readout.
    Reading = [red_cube-0.9 | _],
    % Both concepts are present.
    memberchk(find_marble-0.6, Reading).

% Salience outside the unit interval is clamped to a valid strength.
test(salience_clamped) :-
    % A fresh workspace.
    js_open(w_clamp),
    % A pathological broadcast with an out-of-range salience.
    nx_hold_broadcast(w_clamp, broadcast_content(c1, x, [concept], 1.7)),
    % The held strength is clamped to the maximum.
    js_strength(w_clamp, concept, S),
    % Check the clamp.
    close_to(S, 1.0).

% An empty coalition holds nothing.
test(empty_coalition) :-
    % A fresh workspace.
    js_open(w_empty),
    % A broadcast that carried no content.
    nx_hold_broadcast(w_empty, broadcast_content(c1, x, [], 0.5)),
    % The workspace remains empty.
    js_active(w_empty, []).

% Binding registers the hook on the real workspace broadcast list, and the
% workspace's own dispatch call then holds the concepts — end to end.
test(bind_subscribes_and_dispatches, [nondet]) :-
    % A fresh workspace.
    js_open(w_bind),
    % Bind the J-Space to the workspace broadcast bus.
    nx_bind_workspace(w_bind),
    % The workspace now lists our hook among its broadcast subscribers.
    workspace:broadcast_subscriber(nexus:nx_hold_broadcast(w_bind)),
    % Dispatch a broadcast exactly as workspace_cycle/0 does: call(Goal, Content).
    call(nexus:nx_hold_broadcast(w_bind),
         broadcast_content(c9, theme, [alpha, beta], 0.8)),
    % The dispatched concepts landed in the J-Space at the broadcast salience.
    js_strength(w_bind, alpha, SA),
    % Check the first dispatched concept.
    close_to(SA, 0.8),
    % Check the second dispatched concept.
    js_strength(w_bind, beta, SB),
    % The second concept carries the same salience.
    close_to(SB, 0.8).

% Binding twice is idempotent — no duplicate subscriber.
test(bind_idempotent) :-
    % A fresh workspace.
    js_open(w_idem),
    % Bind once.
    nx_bind_workspace(w_idem),
    % Bind again.
    nx_bind_workspace(w_idem),
    % Exactly one subscriber entry exists for this J-Space.
    findall(x, workspace:broadcast_subscriber(nexus:nx_hold_broadcast(w_idem)), Xs),
    % There is a single registration.
    length(Xs, 1).

:- end_tests(nexus_workspace).

% ===========================================================================
% WIRING TWO — curiosity <- world_model novelty
% ===========================================================================

:- begin_tests(nexus_curiosity).

% The novelty signal delegates faithfully to the world model.
test(novelty_signal_delegates) :-
    % Nexus and the world model must agree on the novelty of a state.
    nx_novelty_signal([[a, b]], [a, c], NX),
    % Compute the same novelty directly from the world model.
    world_model_novelty([[a, b]], [a, c], WM),
    % The two must match exactly.
    close_to(NX, WM),
    % And the value is the expected half-novel fraction.
    close_to(NX, 0.5).

% Observing novelty records it as a curiosity prediction error.
test(observe_novelty_records) :-
    % A fully novel state against no history scores one.
    nx_observe_novelty(reg_obs, [], [x, y], 0, Nov),
    % The novelty is total.
    close_to(Nov, 1.0),
    % The curiosity region now has one recorded error to learn from.
    curiosity:pai_learning_progress(reg_obs, _).

% A trajectory whose novelty falls reads as positive learning progress.
test(falling_novelty_is_progress) :-
    % Explore a trajectory that revisits familiar structure.
    nx_curiosity_explore(reg_fall, [[a, b], [a, b, c], [a, b], [a, b]], Progress),
    % Falling novelty means the region is being learned.
    Progress > 0.0,
    % The exact hand-computed progress is two thirds.
    close_to(Progress, 0.6666666666666666).

% A trajectory of unrelated novel states shows no learning progress.
test(flat_novelty_no_progress) :-
    % Every state is brand new and unlike the others.
    nx_curiosity_explore(reg_flat, [[a], [b], [c], [d]], Progress),
    % Novelty stays high and flat, so there is nothing being learned.
    close_to(Progress, 0.0).

:- end_tests(nexus_curiosity).

% ===========================================================================
% WIRING THREE — agency loop + hierarchical planner
% ===========================================================================

:- begin_tests(nexus_agency).

% The agency loop decomposes a reachable goal with the planner and finishes.
test(plan_and_run_reachable, [nondet]) :-
    % Build the travel domain.
    travel_domain(D),
    % Run the loop toward a walkable destination.
    nx_plan_and_run(D, [at(me, home), short(home, park), has_cash],
                    travel(home, park), 5, Outcome),
    % The loop finished, carrying the decomposed plan.
    Outcome = done(achieved(travel(home, park), Plan)),
    % The plan is the preferred single walk.
    Plan == [walk(home, park)].

% An unreachable goal escalates to human oversight.
test(plan_and_run_escalates, [nondet]) :-
    % Build the travel domain.
    travel_domain(D),
    % No way to travel: no walking distance and no cash.
    nx_plan_and_run(D, [at(me, home)], travel(home, park), 5, Outcome),
    % The loop escalated rather than fabricating a plan.
    Outcome == escalated(no_plan(travel(home, park))).

% A goal shape the reasoner does not understand escalates too.
test(unknown_goal_escalates) :-
    % Build the travel domain.
    travel_domain(D),
    % Ask the reasoner about a goal it has no competence for.
    nx_agency_plan_reason(D, [at(me, home)], loop_1, fly(moon), Thought, Action),
    % The thought names the impasse.
    Thought == unknown_goal(fly(moon)),
    % The action escalates.
    Action == action_escalate(unknown_goal(fly(moon))).

% A zero budget is respected: the loop exhausts before acting.
test(budget_bound) :-
    % Build the travel domain.
    travel_domain(D),
    % Run with no budget at all.
    nx_plan_and_run(D, [at(me, home), short(home, park)],
                    travel(home, park), 0, Outcome),
    % The loop stops at its safety bound.
    Outcome == budget_exhausted.

% Monitoring recovers when the world has moved out from under the plan.
test(pursue_recovers, [nondet]) :-
    % Build the travel domain.
    travel_domain(D),
    % The plan is made when the park is walkable and cash is in hand.
    PlanState = [at(me, home), short(home, park), has_cash],
    % But by execution time the walkable shortcut is gone.
    WorldState = [at(me, home), has_cash],
    % Pursue the goal, monitoring against the changed world.
    nx_pursue_and_run(D, PlanState, WorldState, travel(home, park), 5, Outcome),
    % The loop recovered by replanning to the taxi route.
    Outcome = done(achieved(travel(home, park), Plan)),
    % The recovered plan is the taxi sequence.
    Plan == [call_taxi(home), ride(home, park), pay].

% When the plan still fits the world, pursuit proceeds without replanning.
test(pursue_plan_valid, [nondet]) :-
    % Build the travel domain.
    travel_domain(D),
    % The world is exactly what the plan was made for.
    State = [at(me, home), short(home, park), has_cash],
    % Pursue the goal.
    nx_pursue_and_run(D, State, State, travel(home, park), 5, Outcome),
    % The original walking plan survives.
    Outcome == done(achieved(travel(home, park), [walk(home, park)])).

% An unrecoverable change escalates to oversight.
test(pursue_unrecoverable, [nondet]) :-
    % Build the travel domain.
    travel_domain(D),
    % The plan is made when the park is walkable.
    PlanState = [at(me, home), short(home, park)],
    % By execution time there is neither a shortcut nor cash.
    WorldState = [at(me, home)],
    % Pursue the goal.
    nx_pursue_and_run(D, PlanState, WorldState, travel(home, park), 5, Outcome),
    % Recovery is impossible, so the loop escalates.
    Outcome == escalated(cannot_recover(travel(home, park))).

:- end_tests(nexus_agency).

% ===========================================================================
% WIRING FOUR — evolve + refinery critique
% ===========================================================================

:- begin_tests(nexus_evolve).

% The fitness function scores a genome by the fraction of criteria it passes.
test(refinery_fitness_fraction) :-
    % Fetch the reasoning-operator criteria.
    reasoning_criteria(Criteria),
    % A genome that observes first and deduces but never concludes.
    nx_refinery_fitness(Criteria, [observe, deduce, branch], Score),
    % Two of the three criteria pass.
    close_to(Score, 0.6666666666666666).

% Evolution assembles a valid reasoning trace scored by refinery critique.
test(evolve_reaches_bar) :-
    % Fetch the reasoning-operator criteria.
    reasoning_criteria(Criteria),
    % Evolve under critique from seed 5: population 24, five operators long.
    nx_evolve_with_critique(Criteria, params([observe, deduce, abduce, induce, conclude, branch], 3, 0.15, 2),
                            24, 5, 80, 1.0, 5, Best, Score, Gens),
    % The perfect quality bar was reached.
    close_to(Score, 1.0),
    % It took six generations of evolution — not a lucky founder.
    Gens =:= 6,
    % The evolved trace is the deterministic winner for this seed.
    Best == [observe, deduce, observe, induce, conclude],
    % The winner has no remaining refinery issues.
    nx_critique_report(Criteria, Best, []).

% The evolutionary run is reproducible: one seed, one evolution.
test(evolve_deterministic) :-
    % Fetch the reasoning-operator criteria.
    reasoning_criteria(Criteria),
    % The operator alphabet.
    Ops = [observe, deduce, abduce, induce, conclude, branch],
    % Run once.
    nx_evolve_with_critique(Criteria, params(Ops, 3, 0.15, 2), 24, 5, 80, 1.0, 5, B1, _, G1),
    % Run again from the same seed.
    nx_evolve_with_critique(Criteria, params(Ops, 3, 0.15, 2), 24, 5, 80, 1.0, 5, B2, _, G2),
    % The winners agree.
    B1 == B2,
    % The generation counts agree.
    G1 =:= G2.

% The critique report names the criteria a failing genome still fails.
test(critique_report_names_issues) :-
    % Fetch the reasoning-operator criteria.
    reasoning_criteria(Criteria),
    % A genome that never observes and never concludes, but does deduce.
    nx_critique_report(Criteria, [branch, deduce, branch], Critique),
    % The two failing criteria are reported.
    memberchk(found_issue(starts_observe, fail), Critique),
    % The missing conclusion is also reported.
    memberchk(found_issue(ends_conclude, fail), Critique),
    % Exactly the two failures, no more.
    length(Critique, 2).

:- end_tests(nexus_evolve).
