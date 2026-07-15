/*  PrologAI — In-pack PLUnit suite for the 'frames' pack (Reference Frames
    and Voting Consensus, PR 39).

    Exercises the four exported predicates with real assertions on their
    Lattice effects and computed outputs:
        frames_frame_create/3  — inscribes a reference_frame node_fact.
        frames_frame_anchor/4  — inscribes a feature with frame + coords tags.
        frames_frame_move/3     — advances a 1-D coord and a 2-D point.
        frames_vote/4           — weighted consensus with preserved dissent,
                                  and no_consensus under a zero budget.

    Run (from repo root):
      LIB=""; for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
      swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/frames/test/test_frames.pl
*/

% Declare this file as the 'test_frames' module, exporting nothing.
:- module(test_frames, []).
% Load the built-in PLUnit test framework.
:- use_module(library(plunit)).
% Load the pack under test so its four exported predicates are available.
:- use_module(library(frames)).
% Import the Lattice reader and open/close doors used to set up a store.
:- use_module(library(lattice),   [lattice_open/2, lattice_close/1, lattice_node_fact/5]).
% Import the anchoring-target setter that frames writes through.
:- use_module(library(node_facts),[set_default_nexus/1]).
% Import list membership used by the referent-tag assertions.
:- use_module(library(lists),     [memberchk/2]).

% Open a fresh Lattice and make it the default anchoring target for the suite.
frames_test_setup :-
    % Open a named in-memory nexus and bind it to N.
    lattice_open('locus://localhost/frames_test', N),
    % Remember the nexus handle so cleanup can close the same store.
    nb_setval(frames_test_nexus, N),
    % Route all subsequent anchor_node writes into this nexus.
    set_default_nexus(N).

% Close the Lattice opened for the suite so no store is left dangling.
frames_test_cleanup :-
    % Recover the nexus handle saved during setup.
    nb_getval(frames_test_nexus, N),
    % Close that nexus.
    lattice_close(N).

% Open the 'frames' test block with shared setup and cleanup hooks.
:- begin_tests(frames, [setup(frames_test_setup), cleanup(frames_test_cleanup)]).

% frames_frame_create inscribes a reference_frame node_fact carrying its axes.
test(frame_create_inscribes) :-
    % Create a 2-D room frame and capture the new node id.
    frames_frame_create(room_test, axes(0, 1), NodeId),
    % The returned node id must be bound (a real inscription happened).
    assertion(nonvar(NodeId)),
    % The Lattice must hold a reference_frame fact for this frame with its axes.
    assertion(lattice_node_fact(_, NodeId, reference_frame, [room_test, axes(0, 1)], _)).

% frames_frame_anchor inscribes a feature tagged with its frame and coords.
test(frame_anchor_has_tags) :-
    % Create a 1-D shelf frame to anchor a feature into.
    frames_frame_create(shelf_test, axes(1), _),
    % Anchor a shelf_item feature at coordinate 3 within the shelf frame.
    frames_frame_anchor(shelf_test, coord(3), feature(shelf_item, [book_test]), NodeId),
    % Read the inscribed feature and its referent list back from the Lattice.
    lattice_node_fact(_, NodeId, shelf_item, [book_test], Refs),
    % The referents must include the owning frame tag.
    assertion(memberchk(frame(shelf_test), Refs)),
    % The referents must include the coordinate tag.
    assertion(memberchk(coords(coord(3)), Refs)).

% frames_frame_move advances a 1-D coordinate by the frame's declared step.
test(frame_move_1d) :-
    % Create a 1-D timeline frame whose step is 1.
    frames_frame_create(timeline_test, axes(1), _),
    % Move attention one step from coordinate 5.
    frames_frame_move(timeline_test, 5, New),
    % The new coordinate must be 6 (5 + step 1).
    assertion(New =:= 6).

% frames_frame_move advances a 2-D point by the frame's dx and dy.
test(frame_move_2d) :-
    % Create a 2-D grid frame stepping +1 in x and +2 in y.
    frames_frame_create(grid_test, axes(1, 2), _),
    % Move the point (3,4) one step along the grid's primary axes.
    frames_frame_move(grid_test, point(3, 4), point(X, Y)),
    % The x coordinate must advance from 3 to 4.
    assertion(X =:= 4),
    % The y coordinate must advance from 4 to 6.
    assertion(Y =:= 6).

% frames_vote elects the highest weighted conclusion and preserves dissent.
test(three_specialists_vote) :-
    % Three specialists vote; two back bird_test, one backs mammal_test.
    Voters = [
        % Specialist s1 is confident and reliable for bird_test.
        voter(s1, bird_test, 0.9, 0.8),
        % Specialist s2 backs mammal_test with lower confidence and reliability.
        voter(s2, mammal_test, 0.7, 0.6),
        % Specialist s3 adds a second, reliable vote for bird_test.
        voter(s3, bird_test, 0.5, 0.9)
    ],
    % Run the vote over the percept with a generous voter budget.
    frames_vote(Voters, percept_test, budget(10), Consensus),
    % The elected consensus must be bird_test (the highest weighted tally).
    assertion(Consensus = consensus(percept_test, bird_test, _Score, _CId)),
    % The dissenting mammal_test voter s2 must be preserved as a dissent record.
    assertion(lattice_node_fact(_, _, vote_dissent, [percept_test, s2 | _], _)).

% frames_vote returns no_consensus when the budget admits zero voters.
test(zero_budget_vote) :-
    % A single voter is supplied, but the budget will admit none of them.
    Voters = [voter(s1, cat_test, 0.9, 0.9)],
    % Run the vote with a zero budget.
    frames_vote(Voters, entity_test, budget(0), Result),
    % With no active voters the result must be exactly no_consensus.
    assertion(Result == no_consensus).

% Close the 'frames' test block.
:- end_tests(frames).
