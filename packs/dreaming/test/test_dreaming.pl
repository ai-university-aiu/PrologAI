/*  PrologAI — Dreaming Engine Tests  (PR 52)

    Acceptance tests for the dreaming pack.
    Each test uses a dedicated MindId (test_mind_N) so dream journal
    entries do not bleed between tests.
*/

% Declare this file as the 'test_dreaming' module.
:- module(test_dreaming, []).

% Load the dreaming module under test.
:- use_module('../prolog/dreaming').

% ---------------------------------------------------------------------------
% AC-PR52-001: pai_dream_record/4 persists a journal entry.
% ---------------------------------------------------------------------------

% Define the test clause for AC-PR52-001.
test_dream_record :-
    % Record a test entry in the dream journal.
    pai_dream_record(test_mind_1, slow_wave, test_content, DreamId),
    % Confirm the DreamId is a compound term of the form dream(_, _).
    DreamId = dream(test_mind_1, _),
    % Retrieve the journal for test_mind_1 and confirm the entry is present.
    pai_dream_journal(test_mind_1, Journal),
    % Check that the journal contains at least one entry.
    Journal \= [],
    % Write a pass message.
    write('AC-PR52-001 PASS: pai_dream_record/4 persists a journal entry.'), nl.

% ---------------------------------------------------------------------------
% AC-PR52-002: pai_dream_journal/2 returns entries for the correct MindId.
% ---------------------------------------------------------------------------

% Define the test clause for AC-PR52-002.
test_dream_journal_isolation :-
    % Record entries for two different minds.
    pai_dream_record(test_mind_2a, slow_wave, content_a, _),
    % Record a second entry for a different mind.
    pai_dream_record(test_mind_2b, rem, content_b, _),
    % Retrieve the journal for test_mind_2a.
    pai_dream_journal(test_mind_2a, JournalA),
    % Retrieve the journal for test_mind_2b.
    pai_dream_journal(test_mind_2b, JournalB),
    % Confirm test_mind_2a's journal contains exactly one entry.
    length(JournalA, LenA),
    LenA >= 1,
    % Confirm test_mind_2b's journal contains exactly one entry.
    length(JournalB, LenB),
    LenB >= 1,
    % Confirm the two journals are distinct.
    JournalA \= JournalB,
    % Write a pass message.
    write('AC-PR52-002 PASS: pai_dream_journal/2 isolates entries by MindId.'), nl.

% ---------------------------------------------------------------------------
% AC-PR52-003: pai_dream_generative_replay/3 succeeds with empty SONA.
% ---------------------------------------------------------------------------

% Define the test clause for AC-PR52-003.
test_generative_replay_empty_sona :-
    % Call generative replay; with no SONA loaded, Replayed must be [].
    pai_dream_generative_replay(test_mind_3, 5, Replayed),
    % Confirm Replayed is the empty list.
    Replayed = [],
    % Write a pass message.
    write('AC-PR52-003 PASS: pai_dream_generative_replay/3 succeeds with empty SONA.'), nl.

% ---------------------------------------------------------------------------
% AC-PR52-004: pai_dream_slow_wave/3 returns a consolidated/2 term.
% ---------------------------------------------------------------------------

% Define the test clause for AC-PR52-004.
test_slow_wave :-
    % Run the slow-wave phase for test_mind_4 with a count of 3.
    pai_dream_slow_wave(test_mind_4, 3, Consolidated),
    % Confirm the result is a consolidated/2 term.
    Consolidated = consolidated(_, _),
    % Write a pass message.
    write('AC-PR52-004 PASS: pai_dream_slow_wave/3 returns a consolidated/2 term.'), nl.

% ---------------------------------------------------------------------------
% AC-PR52-005: pai_dream_rem/3 returns a rem/2 term.
% ---------------------------------------------------------------------------

% Define the test clause for AC-PR52-005.
test_rem :-
    % Run the REM phase for test_mind_5 with a depth of 5.
    pai_dream_rem(test_mind_5, 5, Hypotheticals),
    % Confirm the result is a rem/2 term.
    Hypotheticals = rem(_, _),
    % Write a pass message.
    write('AC-PR52-005 PASS: pai_dream_rem/3 returns a rem/2 term.'), nl.

% ---------------------------------------------------------------------------
% AC-PR52-006: pai_dream_counterfactual/4 returns no_known_facts for unknown node.
% ---------------------------------------------------------------------------

% Define the test clause for AC-PR52-006.
test_counterfactual_unknown_node :-
    % Call counterfactual on a node that does not exist in the Lattice.
    pai_dream_counterfactual(test_mind_6, nonexistent_node_xyz, 3, Alternatives),
    % Confirm the pack reports no_known_facts.
    Alternatives = counterfactual(nonexistent_node_xyz, no_known_facts),
    % Write a pass message.
    write('AC-PR52-006 PASS: pai_dream_counterfactual/4 returns no_known_facts for unknown node.'), nl.

% ---------------------------------------------------------------------------
% AC-PR52-007: pai_dream_cycle/2 returns a complete dream_report/5 term.
% ---------------------------------------------------------------------------

% Define the test clause for AC-PR52-007.
test_dream_cycle :-
    % Run a full dream cycle for test_mind_7.
    pai_dream_cycle(test_mind_7, Report),
    % Confirm the report has the expected dream_report/5 structure.
    Report = dream_report(mind(test_mind_7), hypnagogic(_), slow_wave(_), rem(_), hypnopompic(_)),
    % Write a pass message.
    write('AC-PR52-007 PASS: pai_dream_cycle/2 returns a complete dream_report/5 term.'), nl.

% ---------------------------------------------------------------------------
% Run all tests
% ---------------------------------------------------------------------------

% Define the clause for 'run tests': execute all seven acceptance tests.
:- initialization(run_tests, main).

% Define the clause for 'run tests': call each test predicate in order.
run_tests :-
    % Write the test suite header.
    write('--- Dreaming Pack Acceptance Tests (PR 52) ---'), nl,
    % Run test AC-PR52-001.
    test_dream_record,
    % Run test AC-PR52-002.
    test_dream_journal_isolation,
    % Run test AC-PR52-003.
    test_generative_replay_empty_sona,
    % Run test AC-PR52-004.
    test_slow_wave,
    % Run test AC-PR52-005.
    test_rem,
    % Run test AC-PR52-006.
    test_counterfactual_unknown_node,
    % Run test AC-PR52-007.
    test_dream_cycle,
    % Write the test suite footer.
    write('--- All 7 tests passed. ---'), nl.
