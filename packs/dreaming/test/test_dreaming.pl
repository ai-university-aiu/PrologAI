/*  PrologAI — Dreaming Engine Test Suite  (PR 52)

    Acceptance tests for the dreaming pack, standardized onto PLUnit test()
    blocks (no behaviour change from the earlier bespoke harness). Each test
    uses a dedicated MindId (test_mind_N) so dream journal entries do not bleed
    between tests.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/dreaming/test/test_dreaming.pl
*/

% Declare this file as a test module.
:- module(test_dreaming, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the dreaming module under test.
:- use_module(library(dreaming)).

% Open the dreaming acceptance test block.
:- begin_tests(dreaming).

% AC-PR52-001: dreaming_record/4 persists a journal entry.
test(dream_record) :-
    % Record a test entry in the dream journal.
    dreaming:dreaming_record(test_mind_1, slow_wave, test_content, DreamId),
    % The identifier is a dream/2 term keyed to this mind.
    assertion(DreamId = dream(test_mind_1, _)),
    % Retrieve the journal for this mind.
    dreaming:dreaming_journal(test_mind_1, Journal),
    % The journal is non-empty.
    assertion(Journal \= []).

% AC-PR52-002: dreaming_journal/2 isolates entries by MindId.
test(dream_journal_isolation) :-
    % Record an entry for the first mind.
    dreaming:dreaming_record(test_mind_2a, slow_wave, content_a, _),
    % Record an entry for a second, different mind.
    dreaming:dreaming_record(test_mind_2b, rem, content_b, _),
    % Retrieve the first mind's journal.
    dreaming:dreaming_journal(test_mind_2a, JournalA),
    % Retrieve the second mind's journal.
    dreaming:dreaming_journal(test_mind_2b, JournalB),
    % The first mind's journal has at least one entry.
    length(JournalA, LenA),
    % Confirm that length is one or more.
    assertion(LenA >= 1),
    % The second mind's journal has at least one entry.
    length(JournalB, LenB),
    % Confirm that length is one or more.
    assertion(LenB >= 1),
    % The two journals are distinct.
    assertion(JournalA \= JournalB).

% AC-PR52-003: dreaming_generative_replay/3 succeeds with empty SONA.
test(generative_replay_empty_sona) :-
    % Call generative replay; with no SONA loaded, the result is empty.
    dreaming:dreaming_generative_replay(test_mind_3, 5, Replayed),
    % Confirm the replayed list is empty.
    assertion(Replayed == []).

% AC-PR52-004: dreaming_slow_wave/3 returns a consolidated/2 term.
test(slow_wave) :-
    % Run the slow-wave phase for this mind with a count of three.
    dreaming:dreaming_slow_wave(test_mind_4, 3, Consolidated),
    % Confirm the result is a consolidated/2 term.
    assertion(Consolidated = consolidated(_, _)).

% AC-PR52-005: dreaming_rem/3 returns a rem/2 term.
test(rem) :-
    % Run the REM phase for this mind with a depth of five.
    dreaming:dreaming_rem(test_mind_5, 5, Hypotheticals),
    % Confirm the result is a rem/2 term.
    assertion(Hypotheticals = rem(_, _)).

% AC-PR52-006: dreaming_counterfactual/4 reports no_known_facts for an unknown node.
test(counterfactual_unknown_node) :-
    % Call counterfactual on a node that does not exist in the Lattice.
    dreaming:dreaming_counterfactual(test_mind_6, nonexistent_node_xyz, 3, Alternatives),
    % Confirm the pack reports no_known_facts for that node.
    assertion(Alternatives = counterfactual(nonexistent_node_xyz, no_known_facts)).

% AC-PR52-007: dreaming_cycle/2 returns a complete dream_report/5 term.
test(dream_cycle) :-
    % Run a full dream cycle for this mind.
    dreaming:dreaming_cycle(test_mind_7, Report),
    % Confirm the report has the expected dream_report/5 structure.
    assertion(Report = dream_report(mind(test_mind_7), hypnagogic(_), slow_wave(_), rem(_), hypnopompic(_))).

% Close the dreaming acceptance test block.
:- end_tests(dreaming).
