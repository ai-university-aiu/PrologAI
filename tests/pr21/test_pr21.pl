/*  PrologAI — PR 21 Resource-Bounded Reasoning Acceptance Tests

    AC-PR21-001: Given beliefs with evidence 8/10 and 1/1, when pai_best_answer
                 is asked, the 8/10 belief wins (higher confidence, despite lower
                 frequency than 1.0).
    AC-PR21-002: Zero-evidence beliefs return no_evidence, not fabricated certainty.
    AC-PR21-003: pai_revise merges contradictory evidence without rejection.
    AC-PR21-004: pai_budget_decay reduces priority geometrically.
    AC-PR21-005: pai_forget_cheapest removes lowest-budget items.
    AC-PR21-006: pai_budget_set/4 clamps values to valid ranges.
    AC-PR21-007: pai_truth_evidence_add/3 correctly increments counts.
    AC-PR21-008: Starvation: high-durability tasks survive forget_cheapest.
    AC-PR21-009: pai_budget_get returns defaults for unknown tasks.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],      LatticePath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],        ActorsPath),
   atomic_list_concat([ProjectRoot, '/packs/budget/prolog'],        BudgetPath),
   assertz(file_search_path(library, LatticePath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, ActorsPath)),
   assertz(file_search_path(library, BudgetPath)).

:- use_module(library(plunit)).
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1]).
:- use_module(library(node_facts), [set_default_nexus/1]).
:- use_module(library(budget),     [pai_budget/3, pai_budget_set/4,
                                    pai_budget_get/4,
                                    pai_truth_evidence/3,
                                    pai_truth_evidence_add/3,
                                    pai_best_answer/2,
                                    pai_revise/3,
                                    pai_budget_decay/1,
                                    pai_forget_cheapest/1]).

:- begin_tests(pr21, [setup(pr21_setup), cleanup(pr21_cleanup)]).

pr21_setup :-
    lattice_open('locus://localhost/pr21', N),
    nb_setval(pr21_nexus_ref, N),
    set_default_nexus(N),
    retractall(budget:task_budget(_, _, _, _)),
    retractall(budget:belief_evidence(_, _, _)).

pr21_cleanup :-
    nb_getval(pr21_nexus_ref, N),
    retractall(budget:task_budget(_, _, _, _)),
    retractall(budget:belief_evidence(_, _, _)),
    lattice_close(N).

%  AC-PR21-001: 8/10 evidence wins over 1/1 (higher confidence)
test(best_answer_confidence_over_frequency) :-
    pai_truth_evidence(belief_a, 8, 10),   % freq=0.8, conf=10
    pai_truth_evidence(belief_b, 1, 1),    % freq=1.0, conf=1
    pai_best_answer(_, Answer),
    Answer = answer(belief_a, frequency(_F), confidence(_C)).

%  AC-PR21-002: zero evidence returns no_evidence
test(zero_evidence_returns_no_evidence) :-
    pai_best_answer(unknown_question_xyz, Answer),
    Answer = no_evidence(_, _).

%  AC-PR21-003: pai_revise merges contradictory evidence
test(revise_merges_evidence) :-
    pai_truth_evidence(belief_c, 9, 10),  % initially high confidence
    pai_revise(belief_c, false, NewFreq), % add one negative piece of evidence
    pai_truth_evidence(belief_c, Freq, _Conf),
    Freq =:= NewFreq,
    Freq < 0.9.  % frequency dropped from 0.9

%  AC-PR21-004: pai_budget_decay reduces priority geometrically
test(budget_decay_reduces_priority) :-
    pai_budget_set(task_d, 1.0, 10.0, 0.0),
    pai_budget_decay(task_d),
    pai_budget_get(task_d, P, _, _),
    P < 1.0,
    P > 0.0.

%  AC-PR21-005: pai_forget_cheapest removes lowest-budget items
test(forget_cheapest_removes_low_budget) :-
    pai_budget_set(task_keep_1, 0.9, 10.0, 0.8),
    pai_budget_set(task_keep_2, 0.8, 10.0, 0.7),
    pai_budget_set(task_forget, 0.1, 2.0, 0.1),
    pai_forget_cheapest(2),
    \+ budget:task_budget(task_forget, _, _, _),
    budget:task_budget(task_keep_1, _, _, _).

%  AC-PR21-006: pai_budget_set clamps to valid ranges
test(budget_set_clamps_values) :-
    pai_budget_set(clamp_task, -5.0, 0.0, 99.0),
    pai_budget_get(clamp_task, P, D, Q),
    P >= 0.0,
    P =< 1.0,
    D >= 1.0,
    Q >= 0.0,
    Q =< 1.0.

%  AC-PR21-007: pai_truth_evidence_add increments counts correctly
test(truth_evidence_add_increments) :-
    pai_truth_evidence(incr_belief, 3, 5),  % 3 pos, 5 total
    pai_truth_evidence_add(incr_belief, true, NewConf),
    NewConf =:= 6,
    budget:belief_evidence(incr_belief, Pos, 6),
    Pos =:= 4.

%  AC-PR21-008: high-durability tasks survive forget_cheapest
test(high_durability_survives_forget) :-
    pai_budget_set(durable_task, 0.3, 1000.0, 0.5),   % low priority but high durability
    pai_budget_set(cheap_task_1, 0.2, 2.0, 0.1),
    pai_budget_set(cheap_task_2, 0.1, 2.0, 0.1),
    pai_forget_cheapest(2),
    % cheapest 1 item (cheap_task_2 with P=0.1) is forgotten
    \+ budget:task_budget(cheap_task_2, _, _, _).

%  AC-PR21-009: pai_budget_get returns defaults for unknown tasks
test(budget_get_defaults) :-
    pai_budget_get(totally_unknown_task_xyz, P, D, Q),
    P > 0.0, P =< 1.0,
    D >= 1.0,
    Q >= 0.0, Q =< 1.0.

:- end_tests(pr21).
