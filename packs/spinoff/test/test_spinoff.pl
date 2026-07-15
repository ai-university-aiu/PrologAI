/*  PrologAI — Marginal Attribution Spinoff Learning Test Suite  (PR 20)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/spinoff/test/test_spinoff.pl

    Exercises the Drescher-style marginal-attribution miner on its internal
    trial log: recording trials, reading command statistics, mining reliable
    result-spinoffs, computing marginal probabilities, and discovering the
    context condition that best discriminates a rare effect.  The only Lattice
    write (anchor_node) inside the miner is wrapped in catch/3, so the whole
    suite is behavioural without an open nexus.
*/

% Declare this file as a test module.
:- module(test_spinoff, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(spinoff)).

% Clear the internal trial log and forged plans before the suite runs.
spinoff_test_reset :-
    % Drop every recorded trial from a previous load or run.
    retractall(spinoff:trial_record(_, _, _, _, _, _)),
    % Drop every forged spinoff plan.
    retractall(spinoff:spinoff_plan(_, _, _, _, _)),
    % Reset the trial id counter to zero.
    retractall(spinoff:trial_id_counter(_)),
    % Seed a fresh trial id counter.
    assertz(spinoff:trial_id_counter(0)),
    % Reset the spinoff id counter to zero.
    retractall(spinoff:spinoff_id_counter(_)),
    % Seed a fresh spinoff id counter.
    assertz(spinoff:spinoff_id_counter(0)).

% Open the test block for spinoff, clearing state once before it runs.
:- begin_tests(spinoff, [setup(spinoff_test_reset)]).

% AC-SPINOFF-001: record_trial/4 stores one trial record per call.
test(record_trial_stores_records) :-
    % Log a successful push that moves the box.
    record_trial(push, [box], [box, moved], success),
    % Log a failed push with no context.
    record_trial(push, [], [], failure),
    % Count the trials filed under the push command.
    aggregate_all(count, spinoff:trial_record(_, push, _, _, _, _), N),
    % Both push attempts were stored.
    assertion(N =:= 2).

% AC-SPINOFF-002: spinoff_spinoff_stats/2 returns a dict with the trial count.
test(spinoff_stats_reports_trial_count) :-
    % Log a failed pull on a heavy object.
    record_trial(pull, [heavy], [heavy], failure),
    % Log a successful pull on a light object.
    record_trial(pull, [light], [light, moved], success),
    % Ask the miner for the statistics of the pull command.
    spinoff_spinoff_stats(pull, Stats),
    % The statistics arrive as a dict.
    assertion(is_dict(Stats)),
    % Read the recorded trial count out of the dict.
    get_dict(trial_count, Stats, Count),
    % Both pull trials are counted.
    assertion(Count =:= 2),
    % The dict also reports how many distinct result patterns were seen.
    get_dict(unique_results, Stats, Unique),
    % Exactly one distinct change (the light object moving) was observed.
    assertion(Unique =:= 1).

% AC-SPINOFF-003: spinoff_spinoff_mine/2 forges a reliable result-spinoff.
test(mine_finds_reliable_result_spinoff) :-
    % Record ten trials where pressing the button always clicks.
    forall(between(1, 10, _),
           record_trial(press, [button], [button, click], success)),
    % Run marginal attribution over the press command.
    spinoff_spinoff_mine(press, Spinoffs),
    % Mining returns at least one spinoff.
    assertion(Spinoffs \= []),
    % The reliable click effect is captured as an unconditional result-spinoff.
    assertion(member(result_spinoff(press, [click], _), Spinoffs)),
    % The forged plan for press was inscribed with full reliability.
    once(spinoff:spinoff_plan(_, press, _, [click], R)),
    % Ten out of ten successes give a reliability of one.
    assertion(R =:= 1).

% AC-SPINOFF-004: spinoff never forges a duplicate plan (accommodate semantics).
test(mining_is_idempotent) :-
    % Record seven identical twist trials that turn the knob.
    forall(between(1, 7, _),
           record_trial(twist, [knob], [knob, turned], success)),
    % Mine the twist command once, forging the plan.
    spinoff_spinoff_mine(twist, _),
    % Mine the twist command again; it must not duplicate the plan.
    spinoff_spinoff_mine(twist, _),
    % Count the forged plans for the turned effect.
    aggregate_all(count, spinoff:spinoff_plan(_, twist, _, [turned], _), N),
    % Exactly one plan survives the second mining pass.
    assertion(N =:= 1).

% AC-SPINOFF-005: compute_marginal/4 estimates P(result | command).
test(compute_marginal_estimates_probability) :-
    % Eight flips out of ten come up heads.
    forall(between(1, 8, _),
           record_trial(flip, [], [heads], success)),
    % The other two flips change nothing.
    forall(between(1, 2, _),
           record_trial(flip, [], [], failure)),
    % Compute the marginal probability of heads with and without flipping.
    spinoff:compute_marginal(flip, [heads], WithP, WithoutP),
    % Flipping yields heads in eight of ten trials, above one half.
    assertion(WithP > 0.5),
    % No other command in this suite produces the heads change.
    assertion(WithoutP =:= 0.0).

% AC-SPINOFF-006: find_context_conditions/4 finds the discriminating condition.
test(find_context_conditions_discriminates) :-
    % The lamp turns on only when power is present in the context.
    forall(between(1, 8, _),
           record_trial(switch, [power], [power, lamp_on], success)),
    % Flipping the switch without power changes nothing.
    forall(between(1, 4, _),
           record_trial(switch, [], [], failure)),
    % Search for the context condition that best lifts reliability.
    spinoff:find_context_conditions(switch, [lamp_on], Context, P),
    % The winning context is the presence of power.
    assertion(Context == [power]),
    % Under that condition the lamp lights every time.
    assertion(P =:= 1).

% Close the test block for spinoff.
:- end_tests(spinoff).
