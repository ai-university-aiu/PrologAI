% Test suite for the tick_scheduler pack — deferred reactivation on ordinal ticks.
% These tests confirm the monotone clock, future-only scheduling, due-tick-ordered firing,
% genuine enactment via a caller goal, the consolidation-over-time closure of HIPPO-2,
% and the ordinal-only discipline that closes CEREBELLUM-1 (a wall-clock unit is refused).
% Load the tick_scheduler module under test.
:- use_module(library(tick_scheduler)).
% Load the Lattice store the scheduler lives in.
:- use_module(library(lattice)).
% Load the PLUnit testing framework.
:- use_module(library(plunit)).

% A small helper: collect a fired reactivation's label into a dynamic log (proves enactment ran).
:- dynamic tick_scheduler_test_enacted/1.
% Enact one reactivation by recording its label — the caller goal handed to advance_enact.
tick_scheduler_test_enact(reactivation(_Due, Label, _Payload)) :-
    assertz(tick_scheduler_test_enacted(Label)).

% Open the test block for the tick_scheduler pack.
:- begin_tests(tick_scheduler).

% A fresh nexus reads as tick zero, and after init has an empty schedule.
test(fresh_nexus_starts_at_zero) :-
    tick_scheduler_open('locus://tick_scheduler_zero', Nexus),
    tick_scheduler_now(Nexus, Now), assertion(Now == 0),
    tick_scheduler_pending(Nexus, Pending), assertion(Pending == []).

% The clock is monotone: advancing raises now and never lowers it.
test(clock_is_monotone) :-
    tick_scheduler_open('locus://tick_scheduler_mono', Nexus),
    tick_scheduler_advance(Nexus, 3, _),
    tick_scheduler_now(Nexus, N1), assertion(N1 == 3),
    tick_scheduler_tick(Nexus, _),
    tick_scheduler_now(Nexus, N2), assertion(N2 == 4).

% A reactivation scheduled for the future does not fire early, then fires exactly when due.
test(future_reactivation_fires_when_due) :-
    tick_scheduler_open('locus://tick_scheduler_due', Nexus),
    tick_scheduler_schedule_after(Nexus, 3, consolidate, memory_trace),
    % Advancing two ticks is not yet enough — nothing fires, the reactivation is still pending.
    tick_scheduler_advance(Nexus, 2, Fired0), assertion(Fired0 == []),
    tick_scheduler_pending(Nexus, [reactivation(3, consolidate, memory_trace)]),
    % The third tick reaches the due tick — the reactivation fires and leaves the schedule.
    tick_scheduler_tick(Nexus, Fired1),
    assertion(Fired1 == [reactivation(3, consolidate, memory_trace)]),
    tick_scheduler_pending(Nexus, []).

% Scheduling in the past or present is refused — the schedule holds only the future.
test(schedule_must_be_in_the_future, throws(error(domain_error(future_ordinal_tick, _), _))) :-
    tick_scheduler_open('locus://tick_scheduler_past', Nexus),
    tick_scheduler_advance(Nexus, 5, _),
    % Due tick 5 equals the current tick, so it is not strictly in the future — refused.
    tick_scheduler_schedule_at(Nexus, 5, late, _).

% Several reactivations fire in due-tick order when the clock jumps past all of them.
test(due_reactivations_fire_in_tick_order) :-
    tick_scheduler_open('locus://tick_scheduler_order', Nexus),
    tick_scheduler_schedule_at(Nexus, 5, third, c),
    tick_scheduler_schedule_at(Nexus, 2, first, a),
    tick_scheduler_schedule_at(Nexus, 3, second, b),
    % Jump the clock past all three; they come back ordered by due tick, not by insertion.
    tick_scheduler_advance(Nexus, 10, Fired),
    assertion(Fired == [ reactivation(2, first, a),
                         reactivation(3, second, b),
                         reactivation(5, third, c) ]).

% advance_enact ENACTS each fired reactivation by running the caller goal, in order.
% The helper and its log live in the user module, so name them there unambiguously
% (the test body runs in the plunit test module, a different module).
test(enactment_runs_the_caller_goal) :-
    retractall(user:tick_scheduler_test_enacted(_)),
    tick_scheduler_open('locus://tick_scheduler_enact', Nexus),
    tick_scheduler_schedule_after(Nexus, 1, alpha, p),
    tick_scheduler_schedule_after(Nexus, 2, beta, q),
    tick_scheduler_advance_enact(Nexus, 2, user:tick_scheduler_test_enact, Fired),
    assertion(Fired == [reactivation(1, alpha, p), reactivation(2, beta, q)]),
    % Both labels were recorded, in due-tick order — enactment genuinely ran.
    findall(L, user:tick_scheduler_test_enacted(L), Enacted),
    assertion(Enacted == [alpha, beta]).

% The consolidation-over-time closure of HIPPO-2: a consolidation is scheduled for later
% and is enacted only when the ordinal clock reaches its due tick — a real scheduler.
test(hippo2_consolidation_is_scheduled_and_enacted) :-
    retractall(user:tick_scheduler_test_enacted(_)),
    tick_scheduler_open('locus://tick_scheduler_hippo2', Nexus),
    tick_scheduler_schedule_after(Nexus, 4, consolidate_episode, trace_42),
    % Three ticks pass with no consolidation — it is genuinely deferred over time.
    tick_scheduler_advance_enact(Nexus, 3, user:tick_scheduler_test_enact, []),
    findall(L, user:tick_scheduler_test_enacted(L), None), assertion(None == []),
    % The fourth tick reaches the due tick — the consolidation is enacted.
    tick_scheduler_advance_enact(Nexus, 1, user:tick_scheduler_test_enact,
                                 [reactivation(4, consolidate_episode, trace_42)]),
    findall(L, user:tick_scheduler_test_enacted(L), Done),
    assertion(Done == [consolidate_episode]).

% The CEREBELLUM-1 closure: an ordinal (tick) unit is accepted for after-scheduling.
test(cerebellum1_ordinal_unit_accepted) :-
    tick_scheduler_open('locus://tick_scheduler_ticks_ok', Nexus),
    tick_scheduler_schedule_after_unit(Nexus, 2, ticks, adjust, gain),
    tick_scheduler_pending(Nexus, [reactivation(2, adjust, gain)]).

% The CEREBELLUM-1 closure: a wall-clock unit is REFUSED — no "seconds" distortion of a tick.
test(cerebellum1_wall_clock_unit_refused,
     throws(error(type_error(ordinal_tick_unit, seconds), _))) :-
    tick_scheduler_open('locus://tick_scheduler_secs_no', Nexus),
    tick_scheduler_schedule_after_unit(Nexus, 2, seconds, adjust, gain).

% Close the test block.
:- end_tests(tick_scheduler).
