/*  PrologAI — In-pack PLUnit suite for the 'workspace' pack (Global Workspace
    Cycle — attention arbiter, coalition formation, broadcast, PR 18).

    Exercises five exported predicates with real assertions on their computed
    outputs and Lattice-driven behaviour:
        workspace_coalition_form/3     — groups live node_facts by relation and
                                         returns them sorted descending by salience.
        workspace_salience/2           — reads a coalition's stored salience,
                                         defaulting to 0.0 for an unknown id.
        workspace_pin_item/2           — a top-down pin raises a coalition's
                                         computed salience.
        workspace_broadcast_subscribe/1 + workspace_cycle/0
                                       — a subscribed goal receives the
                                         broadcast_content of the cycle winner,
                                         and the winner is habituated.

    Run (from repo root):
      LIB=""; for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
      swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/workspace/test/test_workspace.pl
*/

% Declare this file as the 'test_workspace' module, exporting nothing.
:- module(test_workspace, []).
% Load the built-in PLUnit test framework.
:- use_module(library(plunit)).
% Load the pack under test so its exported predicates are available.
:- use_module(library(workspace)).
% Import the Lattice open/close doors used to set up a store.
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1]).
% Import the anchoring-target setter and the live-fact writer/reader.
:- use_module(library(node_facts), [set_default_nexus/1, anchor_node/4, live_node_facts/2]).
% Import list helpers used by the coalition and ordering assertions.
:- use_module(library(lists),      [member/2, last/2]).

% Open a fresh Lattice, make it the anchoring target, and reset workspace state.
workspace_test_setup :-
    % Open a named in-memory nexus and bind it to N.
    lattice_open('locus://localhost/workspace_test', N),
    % Remember the nexus handle so tests and cleanup can reuse the same store.
    nb_setval(workspace_test_nexus, N),
    % Route all subsequent anchor_node writes into this nexus.
    set_default_nexus(N),
    % Clear any coalition salience scores carried over from another run.
    retractall(workspace:coalition_salience(_, _)),
    % Clear any coalition content mappings carried over from another run.
    retractall(workspace:coalition_content(_, _)),
    % Clear any habituation broadcast counts carried over from another run.
    retractall(workspace:coalition_broadcast_count(_, _)),
    % Clear any top-down pins carried over from another run.
    retractall(workspace:pinned_item(_, _)),
    % Clear any broadcast subscribers carried over from another run.
    retractall(workspace:broadcast_subscriber(_)),
    % Reset the salience floor low so a novel coalition reliably wins a cycle.
    retractall(workspace:salience_floor(_)),
    % Install the low floor value.
    assertz(workspace:salience_floor(0.01)),
    % Reset the coalition id counter so generated ids are deterministic.
    retractall(workspace:coalition_id_counter(_)),
    % Install the fresh counter seed.
    assertz(workspace:coalition_id_counter(0)).

% Close the Lattice opened for the suite so no store is left dangling.
workspace_test_cleanup :-
    % Recover the nexus handle saved during setup.
    nb_getval(workspace_test_nexus, N),
    % Close that nexus.
    lattice_close(N).

% Open the 'workspace' test block with shared setup and cleanup hooks.
:- begin_tests(workspace, [setup(workspace_test_setup), cleanup(workspace_test_cleanup)]).

% workspace_coalition_form groups live node_facts that share a relation.
test(coalition_form_groups_by_relation) :-
    % Recover the open nexus for this suite.
    nb_getval(workspace_test_nexus, Nexus),
    % Inscribe two live facts under the same relation 'alpha_rel'.
    anchor_node(alpha_rel, [a1], [], _),
    % Inscribe the second 'alpha_rel' fact so the group has two members.
    anchor_node(alpha_rel, [a2], [], _),
    % Inscribe one fact under a different relation 'beta_rel'.
    anchor_node(beta_rel,  [b1], [], _),
    % Form up to ten coalitions from the live facts in the nexus.
    workspace_coalition_form(Nexus, 10, Coalitions),
    % At least one coalition must have been formed.
    assertion(Coalitions \= []),
    % The two 'alpha_rel' facts must be grouped into a single coalition.
    once(member(_-coalition(_, alpha_rel, AlphaIds), Coalitions)),
    % That coalition must hold exactly the two anchored 'alpha_rel' ids.
    assertion(length(AlphaIds, 2)),
    % The lone 'beta_rel' fact must form its own single-member coalition.
    once(member(_-coalition(_, beta_rel, BetaIds), Coalitions)),
    % That coalition must hold exactly one id.
    assertion(length(BetaIds, 1)).

% workspace_coalition_form returns coalitions sorted descending by salience.
test(coalition_form_sorted_by_salience) :-
    % Recover the open nexus for this suite.
    nb_getval(workspace_test_nexus, Nexus),
    % Inscribe several live facts across two relations to score and rank.
    anchor_node(sort_a, [s1], [], _),
    % Add a second fact so there is more than one coalition to order.
    anchor_node(sort_b, [s2], [], _),
    % Form the coalitions with their salience scores.
    workspace_coalition_form(Nexus, 10, Coalitions),
    % Count how many coalitions were formed.
    length(Coalitions, Len),
    % There must be at least two coalitions to check an ordering.
    assertion(Len >= 2),
    % Project out just the salience score of each coalition pair.
    findall(Score, member(Score-_, Coalitions), Scores),
    % The projected scores must already be in non-increasing order.
    assertion(is_non_increasing(Scores)).

% workspace_salience defaults to 0.0 for an unknown id and reads a stored score.
test(salience_default_and_stored) :-
    % Query a coalition that has never been scored.
    workspace_salience(coalition_never_scored, DefaultScore),
    % An unknown coalition must report a salience of exactly zero.
    assertion(DefaultScore =:= 0.0),
    % Record a known salience directly into the workspace store.
    assertz(workspace:coalition_salience(coalition_known, 0.6)),
    % Read that coalition's salience back through the exported predicate.
    workspace_salience(coalition_known, KnownScore),
    % The reported score must equal the value that was stored.
    assertion(KnownScore =:= 0.6).

% workspace_pin_item raises the computed salience of a coalition.
test(pin_item_raises_salience) :-
    % Recover the open nexus for this suite.
    nb_getval(workspace_test_nexus, Nexus),
    % Inscribe one fresh live fact to serve as the coalition's content.
    anchor_node(pin_rel, [p1], [], PinId),
    % Compute the coalition's salience before any pin is applied.
    workspace:compute_salience(Nexus, coalition_pin, pin_rel, [PinId], Before),
    % Apply a strong top-down pin to that coalition.
    workspace_pin_item(coalition_pin, 100),
    % Recompute the coalition's salience now that the pin is in place.
    workspace:compute_salience(Nexus, coalition_pin, pin_rel, [PinId], After),
    % The pin must strictly raise the computed salience.
    assertion(After > Before).

% A subscribed goal receives the winner's broadcast_content during a cycle.
test(cycle_broadcasts_to_subscriber) :-
    % Start with no recorded broadcast for this test.
    nb_setval(workspace_test_bcast, none),
    % Subscribe a goal that captures whatever broadcast_content the cycle emits.
    workspace_broadcast_subscribe([Content]>>nb_setval(workspace_test_bcast, Content)),
    % Provide a fresh, novel live fact so the cycle has a coalition to broadcast.
    anchor_node(cycle_rel, [c1], [], _),
    % Confirm the fact is actually live in the nexus before cycling.
    nb_getval(workspace_test_nexus, Nexus),
    % Read the live facts and require the store to be non-empty.
    live_node_facts(Nexus, LiveIds),
    % There must be live content for a winner to be selected.
    assertion(LiveIds \= []),
    % Run one full cognitive cycle: form, select, broadcast, habituate.
    workspace_cycle,
    % Recover whatever the subscriber captured.
    nb_getval(workspace_test_bcast, Got),
    % The subscriber must have been handed the cycle's broadcast content.
    assertion(Got = broadcast_content(_, _, _, _)).

% workspace_cycle habituates the winning coalition it broadcasts.
test(cycle_habituates_winner) :-
    % Provide a fresh, novel live fact so the cycle selects a winner.
    anchor_node(habit_rel, [h1], [], _),
    % Run one full cognitive cycle.
    workspace_cycle,
    % A broadcast count must now exist for some coalition, with a positive tally.
    assertion(( workspace:coalition_broadcast_count(_, Count), Count >= 1 )).

% Close the 'workspace' test block.
:- end_tests(workspace).

% A list of numbers is non-increasing when every element is at least the next.
is_non_increasing([]).
% A single-element list is trivially non-increasing.
is_non_increasing([_]).
% A pair holds when the head is at least the second and the tail also holds.
is_non_increasing([A,B|T]) :-
    % The head must not be smaller than the following element.
    A >= B,
    % The rest of the list, starting at the second element, must also hold.
    is_non_increasing([B|T]).
