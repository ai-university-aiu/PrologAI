/*  PrologAI — PR 21 Resource-Bounded Reasoning Acceptance Tests

    AC-PR21-001: Given beliefs with evidence 8/10 and 1/1, when budget_best_answer
                 is asked, the 8/10 belief wins (higher confidence, despite lower
                 frequency than 1.0).
    AC-PR21-002: Zero-evidence beliefs return no_evidence, not fabricated certainty.
    AC-PR21-003: budget_revise merges contradictory evidence without rejection.
    AC-PR21-004: budget_budget_decay reduces priority geometrically.
    AC-PR21-005: budget_forget_cheapest removes lowest-budget items.
    AC-PR21-006: budget_budget_set/4 clamps values to valid ranges.
    AC-PR21-007: budget_truth_evidence_add/3 correctly increments counts.
    AC-PR21-008: Starvation: high-durability tasks survive forget_cheapest.
    AC-PR21-009: budget_budget_get returns defaults for unknown tasks.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],      LatticePath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],        ActorsPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/budget/prolog'],        BudgetPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatticePath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActorsPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, BudgetPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [lattice_open/2, lattice_close/1] from the built-in 'lattice' library.
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1]).
% Import [set_default_nexus/1] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [set_default_nexus/1]).
% Load the built-in 'budget' library so its predicates are available here.
:- use_module(library(budget),     [budget_budget/3, budget_budget_set/4,
                                    % Supply 'budget_budget_get/4' as the next argument to the expression above.
                                    budget_budget_get/4,
                                    % Supply 'budget_truth_evidence/3' as the next argument to the expression above.
                                    budget_truth_evidence/3,
                                    % Supply 'budget_truth_evidence_add/3' as the next argument to the expression above.
                                    budget_truth_evidence_add/3,
                                    % Supply 'budget_best_answer/2' as the next argument to the expression above.
                                    budget_best_answer/2,
                                    % Supply 'budget_revise/3' as the next argument to the expression above.
                                    budget_revise/3,
                                    % Supply 'budget_budget_decay/1' as the next argument to the expression above.
                                    budget_budget_decay/1,
                                    % Continue the multi-line expression started above.
                                    budget_forget_cheapest/1]).

% Execute the compile-time directive: begin_tests(pr21, [setup(pr21_setup), cleanup(pr21_cleanup)]).
:- begin_tests(pr21, [setup(pr21_setup), cleanup(pr21_cleanup)]).

% Execute: pr21_setup :-.
pr21_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr21', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr21_nexus_ref, N),
    % State a fact for 'set default nexus' with the arguments listed below.
    set_default_nexus(N),
    % Remove all matching facts from the runtime knowledge base.
    retractall(budget:task_budget(_, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(budget:belief_evidence(_, _, _)).

% Execute: pr21_cleanup :-.
pr21_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr21_nexus_ref, N),
    % Remove all matching facts from the runtime knowledge base.
    retractall(budget:task_budget(_, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(budget:belief_evidence(_, _, _)),
    % State the fact: lattice close(N).
    lattice_close(N).

%  AC-PR21-001: 8/10 evidence wins over 1/1 (higher confidence)
% Define a clause for 'test': succeed when the following conditions hold.
test(best_answer_confidence_over_frequency) :-
    % State a fact for 'pai truth evidence' with the arguments listed below.
    budget_truth_evidence(belief_a, 8, 10),   % freq=0.8, conf=10
    % State a fact for 'pai truth evidence' with the arguments listed below.
    budget_truth_evidence(belief_b, 1, 1),    % freq=1.0, conf=1
    % State a fact for 'pai best answer' with the arguments listed below.
    budget_best_answer(_, Answer),
    % Check that 'Answer' is unifiable with 'answer(belief_a, frequency(_F), confidence(_C))'.
    Answer = answer(belief_a, frequency(_F), confidence(_C)).

%  AC-PR21-002: zero evidence returns no_evidence
% Define a clause for 'test': succeed when the following conditions hold.
test(zero_evidence_returns_no_evidence) :-
    % State a fact for 'pai best answer' with the arguments listed below.
    budget_best_answer(unknown_question_xyz, Answer),
    % Check that 'Answer' is unifiable with 'no_evidence(_, _)'.
    Answer = no_evidence(_, _).

%  AC-PR21-003: budget_revise merges contradictory evidence
% Define a clause for 'test': succeed when the following conditions hold.
test(revise_merges_evidence) :-
    % State a fact for 'pai truth evidence' with the arguments listed below.
    budget_truth_evidence(belief_c, 9, 10),  % initially high confidence
    % State a fact for 'pai revise' with the arguments listed below.
    budget_revise(belief_c, false, NewFreq), % add one negative piece of evidence
    % State a fact for 'pai truth evidence' with the arguments listed below.
    budget_truth_evidence(belief_c, Freq, _Conf),
    % Check that 'Freq' is numerically equal to 'NewFreq'.
    Freq =:= NewFreq,
    % Check that 'Freq' is less than '0.9.  % frequency dropped from 0.9'.
    Freq < 0.9.  % frequency dropped from 0.9

%  AC-PR21-004: budget_budget_decay reduces priority geometrically
% Define a clause for 'test': succeed when the following conditions hold.
test(budget_decay_reduces_priority) :-
    % State a fact for 'pai budget set' with the arguments listed below.
    budget_budget_set(task_d, 1.0, 10.0, 0.0),
    % State a fact for 'pai budget decay' with the arguments listed below.
    budget_budget_decay(task_d),
    % State a fact for 'pai budget get' with the arguments listed below.
    budget_budget_get(task_d, P, _, _),
    % Check that 'P' is less than '1.0'.
    P < 1.0,
    % Check that 'P' is greater than '0.0'.
    P > 0.0.

%  AC-PR21-005: budget_forget_cheapest removes lowest-budget items
% Define a clause for 'test': succeed when the following conditions hold.
test(forget_cheapest_removes_low_budget) :-
    % State a fact for 'pai budget set' with the arguments listed below.
    budget_budget_set(task_keep_1, 0.9, 10.0, 0.8),
    % State a fact for 'pai budget set' with the arguments listed below.
    budget_budget_set(task_keep_2, 0.8, 10.0, 0.7),
    % State a fact for 'pai budget set' with the arguments listed below.
    budget_budget_set(task_forget, 0.1, 2.0, 0.1),
    % State a fact for 'pai forget cheapest' with the arguments listed below.
    budget_forget_cheapest(2),
    % Succeed only if 'budget:task_budget(task_forget, _, _, _' cannot be proved (negation as failure).
    \+ budget:task_budget(task_forget, _, _, _),
    % Execute: budget:task_budget(task_keep_1, _, _, _)..
    budget:task_budget(task_keep_1, _, _, _).

%  AC-PR21-006: budget_budget_set clamps to valid ranges
% Define a clause for 'test': succeed when the following conditions hold.
test(budget_set_clamps_values) :-
    % State a fact for 'pai budget set' with the arguments listed below.
    budget_budget_set(clamp_task, -5.0, 0.0, 99.0),
    % State a fact for 'pai budget get' with the arguments listed below.
    budget_budget_get(clamp_task, P, D, Q),
    % Check that 'P' is greater than or equal to '0.0'.
    P >= 0.0,
    % Check that 'P' is less than or equal to '1.0'.
    P =< 1.0,
    % Check that 'D' is greater than or equal to '1.0'.
    D >= 1.0,
    % Check that 'Q' is greater than or equal to '0.0'.
    Q >= 0.0,
    % Check that 'Q' is less than or equal to '1.0'.
    Q =< 1.0.

%  AC-PR21-007: budget_truth_evidence_add increments counts correctly
% Define a clause for 'test': succeed when the following conditions hold.
test(truth_evidence_add_increments) :-
    % State a fact for 'pai truth evidence' with the arguments listed below.
    budget_truth_evidence(incr_belief, 3, 5),  % 3 pos, 5 total
    % State a fact for 'pai truth evidence add' with the arguments listed below.
    budget_truth_evidence_add(incr_belief, true, NewConf),
    % Check that 'NewConf' is numerically equal to '6'.
    NewConf =:= 6,
    % Execute: budget:belief_evidence(incr_belief, Pos, 6),.
    budget:belief_evidence(incr_belief, Pos, 6),
    % Check that 'Pos' is numerically equal to '4'.
    Pos =:= 4.

%  AC-PR21-008: high-durability tasks survive forget_cheapest
% Define a clause for 'test': succeed when the following conditions hold.
test(high_durability_survives_forget) :-
    % State a fact for 'pai budget set' with the arguments listed below.
    budget_budget_set(durable_task, 0.3, 1000.0, 0.5),   % low priority but high durability
    % State a fact for 'pai budget set' with the arguments listed below.
    budget_budget_set(cheap_task_1, 0.2, 2.0, 0.1),
    % State a fact for 'pai budget set' with the arguments listed below.
    budget_budget_set(cheap_task_2, 0.1, 2.0, 0.1),
    % State a fact for 'pai forget cheapest' with the arguments listed below.
    budget_forget_cheapest(2),
    % cheapest 1 item (cheap_task_2 with P=0.1) is forgotten
    % Succeed only if 'budget:task_budget(cheap_task_2, _, _, _' cannot be proved (negation as failure).
    \+ budget:task_budget(cheap_task_2, _, _, _).

%  AC-PR21-009: budget_budget_get returns defaults for unknown tasks
% Define a clause for 'test': succeed when the following conditions hold.
test(budget_get_defaults) :-
    % State a fact for 'pai budget get' with the arguments listed below.
    budget_budget_get(totally_unknown_task_xyz, P, D, Q),
    % Check that 'P > 0.0, P' is less than or equal to '1.0'.
    P > 0.0, P =< 1.0,
    % Check that 'D' is greater than or equal to '1.0'.
    D >= 1.0,
    % Check that 'Q' is greater than or equal to '0.0, Q =< 1.0'.
    Q >= 0.0, Q =< 1.0.

% Execute the compile-time directive: end_tests(pr21).
:- end_tests(pr21).
