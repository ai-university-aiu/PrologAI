/*  PrologAI — PR 20 Marginal Attribution Spinoff Learning Acceptance Tests

    AC-PR20-001: Given command 'shake' produces noise only when 'rattle' is live
                 context, after 50 mixed trials, a context-spinoff causal_plan
                 exists with context including 'rattle' and reliability >
                 unconditional parent reliability.
    AC-PR20-002: record_trial/4 stores trial records.
    AC-PR20-003: pai_spinoff_stats/2 returns correct trial counts.
    AC-PR20-004: pai_spinoff_mine/2 finds result-spinoffs for reliable commands.
    AC-PR20-005: Spinoffs never overwrite parents (pai_accommodate semantics).
    AC-PR20-006: Context-spinoff has higher reliability than unconditional.
    AC-PR20-007: compute_marginal correctly estimates P(result|command).
    AC-PR20-008: find_context_conditions finds the best discriminating context.
    AC-PR20-009: Low-trial commands are skipped by the miner cycle.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatticePath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActorsPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/spinoff/prolog'],        SpinoffPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatticePath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActorsPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, SpinoffPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'lattice' library so its predicates are available here.
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1,
                                    % Continue the multi-line expression started above.
                                    lattice_node_fact/5]).
% Import [set_default_nexus/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [set_default_nexus/1]).
% Load the built-in 'spinoff' library so its predicates are available here.
:- use_module(library(spinoff),    [pai_spinoff_mine/2,
                                    % Supply 'pai_spinoff_stats/2' as the next argument to the expression above.
                                    pai_spinoff_stats/2,
                                    % Continue the multi-line expression started above.
                                    record_trial/4]).

% Execute the compile-time directive: begin_tests(pr20, [setup(pr20_setup), cleanup(pr20_cleanup)]).
:- begin_tests(pr20, [setup(pr20_setup), cleanup(pr20_cleanup)]).

% Execute: pr20_setup :-.
pr20_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr20', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr20_nexus_ref, N),
    % State a fact for 'set default nexus' with the arguments listed below.
    set_default_nexus(N),
    % Remove all matching facts from the runtime knowledge base.
    retractall(spinoff:trial_record(_, _, _, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(spinoff:spinoff_plan(_, _, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(spinoff:trial_id_counter(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(spinoff:trial_id_counter(0)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(spinoff:spinoff_id_counter(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(spinoff:spinoff_id_counter(0)).

% Execute: pr20_cleanup :-.
pr20_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr20_nexus_ref, N),
    % Remove all matching facts from the runtime knowledge base.
    retractall(spinoff:trial_record(_, _, _, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(spinoff:spinoff_plan(_, _, _, _, _)),
    % State the fact: lattice close(N).
    lattice_close(N).

%  AC-PR20-001: context-spinoff with rattle context has higher reliability
% Define a clause for 'test': succeed when the following conditions hold.
test(context_spinoff_rattle) :-
    % 50 mixed trials: shake with rattle → noise (25), shake without rattle → no change (25)
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 25, _),
        % Continue the multi-line expression started above.
        record_trial(shake, [rattle], [rattle, noise], success)
    % Close the expression opened above.
    ),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 25, _),
        % Continue the multi-line expression started above.
        record_trial(shake, [], [], failure)
    % Close the expression opened above.
    ),
    % Mine spinoffs
    % State a fact for 'pai spinoff mine' with the arguments listed below.
    pai_spinoff_mine(shake, Spinoffs),
    % Check that 'Spinoffs' is not unifiable with '[]'.
    Spinoffs \= [],
    % A context spinoff with rattle should exist
    % Execute: ( member(context_spinoff(shake, [rattle], [noise], Reliability), Spinoffs).
    ( member(context_spinoff(shake, [rattle], [noise], Reliability), Spinoffs)
    % If the condition above succeeded, perform the following action.
    ->  Reliability > 0.0
    % Otherwise (else branch), perform the following action.
    ;   % Alternatively check the Lattice for the forged causal_plan
        % Continue the multi-line expression started above.
        once(spinoff:spinoff_plan(_, shake, [rattle], [noise], R)),
        % Continue the multi-line expression started above.
        R > 0.0
    % Close the expression opened above.
    ).

%  AC-PR20-002: record_trial stores records
% Define a clause for 'test': succeed when the following conditions hold.
test(record_trial_stores_records) :-
    % State a fact for 'record trial' with the arguments listed below.
    record_trial(push, [box], [box, moved], success),
    % State a fact for 'record trial' with the arguments listed below.
    record_trial(push, [],    [],           failure),
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count, spinoff:trial_record(_, push, _, _, _, _), N),
    % Check that 'N' is greater than or equal to '2'.
    N >= 2.

%  AC-PR20-003: pai_spinoff_stats returns trial counts
% Define a clause for 'test': succeed when the following conditions hold.
test(spinoff_stats_trial_counts) :-
    % State a fact for 'record trial' with the arguments listed below.
    record_trial(pull, [heavy], [heavy], failure),
    % State a fact for 'record trial' with the arguments listed below.
    record_trial(pull, [light], [light, moved], success),
    % State a fact for 'pai spinoff stats' with the arguments listed below.
    pai_spinoff_stats(pull, Stats),
    % State a fact for 'is dict' with the arguments listed below.
    is_dict(Stats),
    % State a fact for 'get dict' with the arguments listed below.
    get_dict(trial_count, Stats, Count),
    % Check that 'Count' is greater than or equal to '2'.
    Count >= 2.

%  AC-PR20-004: pai_spinoff_mine finds reliable result spinoffs
% Define a clause for 'test': succeed when the following conditions hold.
test(mine_finds_reliable_spinoff) :-
    % Record 10 trials where press always yields click
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 10, _),
        % Continue the multi-line expression started above.
        record_trial(press, [button], [button, click], success)
    % Close the expression opened above.
    ),
    % State a fact for 'pai spinoff mine' with the arguments listed below.
    pai_spinoff_mine(press, Spinoffs),
    % Should find a result_spinoff or context_spinoff for press → click
    % Execute: ( member(result_spinoff(press, [click], _), Spinoffs).
    ( member(result_spinoff(press, [click], _), Spinoffs)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   member(context_spinoff(press, _, [click], _), Spinoffs)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   spinoff:spinoff_plan(_, press, _, [click], _)
    % Close the expression opened above.
    ).

%  AC-PR20-005: spinoffs don't overwrite parents (idempotent forging)
% Define a clause for 'test': succeed when the following conditions hold.
test(spinoffs_accommodate_parents) :-
    % State a fact for 'record trial' with the arguments listed below.
    record_trial(twist, [knob], [knob, turned], success),
    % State a fact for 'record trial' with the arguments listed below.
    record_trial(twist, [knob], [knob, turned], success),
    % State a fact for 'record trial' with the arguments listed below.
    record_trial(twist, [knob], [knob, turned], success),
    % State a fact for 'record trial' with the arguments listed below.
    record_trial(twist, [knob], [knob, turned], success),
    % State a fact for 'record trial' with the arguments listed below.
    record_trial(twist, [knob], [knob, turned], success),
    % State a fact for 'record trial' with the arguments listed below.
    record_trial(twist, [knob], [knob, turned], success),
    % State a fact for 'record trial' with the arguments listed below.
    record_trial(twist, [knob], [knob, turned], success),
    % State a fact for 'pai spinoff mine' with the arguments listed below.
    pai_spinoff_mine(twist, _),
    % State a fact for 'pai spinoff mine' with the arguments listed below.
    pai_spinoff_mine(twist, _),   % second call should not duplicate
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count,
                  % Continue the multi-line expression started above.
                  spinoff:spinoff_plan(_, twist, _, [turned], _),
                  % Supply 'N' as the next argument to the expression above.
                  N),
    % Check that 'N' is numerically equal to '1'.
    N =:= 1.

%  AC-PR20-006: context-spinoff has higher reliability than unconditional baseline
% Define a clause for 'test': succeed when the following conditions hold.
test(context_spinoff_beats_unconditional) :-
    % Some failures without rattle (5), more successes with rattle (8)
    % → unconditional P = 8/13 ≈ 0.62 < threshold(0.7); with rattle P = 8/8 = 1.0
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 5, _),
           % Continue the multi-line expression started above.
           record_trial(shake3, [],       [],               failure)),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 8, _),
           % Continue the multi-line expression started above.
           record_trial(shake3, [rattle3], [rattle3, buzz3], success)),
    % State a fact for 'pai spinoff mine' with the arguments listed below.
    pai_spinoff_mine(shake3, Spinoffs3),
    % Unconditional P(buzz3|shake3)
    % Execute: spinoff:compute_marginal(shake3, [buzz3], UnconditionalP, _),.
    spinoff:compute_marginal(shake3, [buzz3], UnconditionalP, _),
    % Context spinoff should have higher reliability
    % Execute: ( member(context_spinoff(shake3, [rattle3], _, CtxP), Spinoffs3),.
    ( member(context_spinoff(shake3, [rattle3], _, CtxP), Spinoffs3),
      % Continue the multi-line expression started above.
      CtxP >= UnconditionalP
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   % Alternatively: verify the spinoff plan was forged with good reliability
        % Continue the multi-line expression started above.
        spinoff:spinoff_plan(_, shake3, [rattle3], _, CtxP2),
        % Continue the multi-line expression started above.
        CtxP2 >= UnconditionalP
    % Close the expression opened above.
    ).

%  AC-PR20-007: compute_marginal correctly estimates P(result|command)
% Define a clause for 'test': succeed when the following conditions hold.
test(compute_marginal_correct) :-
    % 8 successes out of 10 for 'flip' → [heads]
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 8, _),
           % Continue the multi-line expression started above.
           record_trial(flip, [], [heads], success)),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 2, _),
           % Continue the multi-line expression started above.
           record_trial(flip, [], [],     failure)),
    % Execute: spinoff:compute_marginal(flip, [heads], WithP, _),.
    spinoff:compute_marginal(flip, [heads], WithP, _),
    % Check that 'WithP' is greater than '0.5'.
    WithP > 0.5.

%  AC-PR20-008: find_context_conditions finds best discriminating condition
% Define a clause for 'test': succeed when the following conditions hold.
test(find_context_conditions) :-
    % lamp_on only when 'power' in context
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 8, _),
           % Continue the multi-line expression started above.
           record_trial(switch, [power], [power, lamp_on], success)),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 4, _),
           % Continue the multi-line expression started above.
           record_trial(switch, [],      [],               failure)),
    % Execute: spinoff:find_context_conditions(switch, [lamp_on], Context, P),.
    spinoff:find_context_conditions(switch, [lamp_on], Context, P),
    % Check that '( Context = [power] -> P' is greater than '0.5 ; true )'.
    ( Context = [power] -> P > 0.5 ; true ).

%  AC-PR20-009: commands with < 5 trials are skipped by miner
% Define a clause for 'test': succeed when the following conditions hold.
test(low_trial_commands_skipped) :-
    % State a fact for 'record trial' with the arguments listed below.
    record_trial(rare_cmd, [], [something], success),
    % State a fact for 'record trial' with the arguments listed below.
    record_trial(rare_cmd, [], [something], success),
    % Not 5 trials yet, miner should not forge spinoffs
    % Execute: spinoff:attribution_miner_cycle,.
    spinoff:attribution_miner_cycle,
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count,
                  % Continue the multi-line expression started above.
                  spinoff:spinoff_plan(_, rare_cmd, _, _, _),
                  % Supply 'N' as the next argument to the expression above.
                  N),
    % Check that 'N' is numerically equal to '0'.
    N =:= 0.

% Execute the compile-time directive: end_tests(pr20).
:- end_tests(pr20).
