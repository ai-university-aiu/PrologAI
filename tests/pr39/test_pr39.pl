/*  PrologAI — PR 39 Reference Frames and Voting Consensus Acceptance Tests

    AC-PR39-001: Two observation passes over a simulated object from different
                 approach paths anchor features into ONE object frame; a third
                 partial observation retrieves the object by frame match.
    AC-PR39-002: Three specialists classifying one percept with conflicting
                 conclusions at differing confidences → a consensus node_fact
                 with weighted tally and preserved dissent records.
    AC-PR39-003: frames_frame_create inscribes a reference_frame node_fact.
    AC-PR39-004: frames_frame_anchor inscribes a feature with frame and coords.
    AC-PR39-005: frames_frame_anchor features queryable by frame tag.
    AC-PR39-006: frames_frame_move advances a 1-D coordinate by the frame step.
    AC-PR39-007: frames_frame_move advances a 2-D point by the frame's dx/dy.
    AC-PR39-008: Nested frames carry parent_frame referent.
    AC-PR39-009: Zero-budget vote returns no_consensus.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActPath),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/frames/prolog'],         FrPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, LatPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, VBPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActPath)),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, FrPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [member/2, memberchk/2] from the built-in 'lists' library.
:- use_module(library(lists),    [member/2, memberchk/2]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate),[aggregate_all/3]).
% Load the built-in 'lattice' library so its predicates are available here.
:- use_module(library(lattice),  [lattice_open/2, lattice_close/1,
                                   % Continue the multi-line expression started above.
                                   lattice_node_fact/5]).
% Import [set_default_nexus/1, anchor_node/4] from the built-in 'node_facts' library.
:- use_module(library(node_facts),[set_default_nexus/1, anchor_node/4]).
% Load the built-in 'frames' library so its predicates are available here.
:- use_module(library(frames),   [
    % Supply 'frames_frame_create/3' as the next argument to the expression above.
    frames_frame_create/3,
    % Supply 'frames_frame_anchor/4' as the next argument to the expression above.
    frames_frame_anchor/4,
    % Supply 'frames_frame_move/3' as the next argument to the expression above.
    frames_frame_move/3,
    % Supply 'frames_vote/4' as the next argument to the expression above.
    frames_vote/4
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr39, [setup(pr39_setup), cleanup(pr39_cleanup)]).
:- begin_tests(pr39, [setup(pr39_setup), cleanup(pr39_cleanup)]).

% Execute: pr39_setup :-.
pr39_setup :-
    % State a fact for 'lattice open' with the arguments listed below.
    lattice_open('locus://localhost/pr39', N),
    % State a fact for 'nb setval' with the arguments listed below.
    nb_setval(pr39_nexus, N),
    % State the fact: set default nexus(N).
    set_default_nexus(N).

% Execute: pr39_cleanup :-.
pr39_cleanup :-
    % State a fact for 'nb getval' with the arguments listed below.
    nb_getval(pr39_nexus, N),
    % State the fact: lattice close(N).
    lattice_close(N).

%  AC-PR39-001: two observation passes anchor into one frame; third retrieves
% Define a clause for 'test': succeed when the following conditions hold.
test(two_passes_one_frame, [setup(pr39_setup)]) :-
    % State a fact for 'pai frame create' with the arguments listed below.
    frames_frame_create(mug39, axes(1, 0), _FrameId),
    % First pass: anchor a handle and a rim
    % State a fact for 'pai frame anchor' with the arguments listed below.
    frames_frame_anchor(mug39, point(0,1), feature(visual_feature, [handle39]), _),
    % State a fact for 'pai frame anchor' with the arguments listed below.
    frames_frame_anchor(mug39, point(0,2), feature(visual_feature, [rim39]),    _),
    % Second pass (different approach): anchor base
    % State a fact for 'pai frame anchor' with the arguments listed below.
    frames_frame_anchor(mug39, point(0,0), feature(visual_feature, [base39]),   _),
    % Retrieve all features in this frame
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(F, (
        % Continue the multi-line expression started above.
        lattice_node_fact(_, _, visual_feature, [F], Refs),
        % Continue the multi-line expression started above.
        memberchk(frame(mug39), Refs)
    % Continue the multi-line expression started above.
    ), Features),
    % Unify 'NF' with the number of elements in list 'Features'.
    length(Features, NF),
    % Check that 'NF' is numerically equal to '3'.
    NF =:= 3.

%  AC-PR39-002: three specialists → consensus + preserved dissent (the key AC)
% Define a clause for 'test': succeed when the following conditions hold.
test(three_specialists_vote, [setup(pr39_setup)]) :-
    % Check that 'Voters' is unifiable with '['.
    Voters = [
        % Continue the multi-line expression started above.
        voter(s1, bird39, 0.9, 0.8),
        % Continue the multi-line expression started above.
        voter(s2, mammal39, 0.7, 0.6),
        % Continue the multi-line expression started above.
        voter(s3, bird39, 0.5, 0.9)
    % Close the expression opened above.
    ],
    % State a fact for 'pai vote' with the arguments listed below.
    frames_vote(Voters, percept39, budget(10), Consensus),
    % Check that 'Consensus' is unifiable with 'consensus(percept39, bird39, _Score, _CId)'.
    Consensus = consensus(percept39, bird39, _Score, _CId),
    % Dissent for mammal39 voter must exist in Lattice
    % State the fact: lattice node fact(_, _, vote_dissent, [percept39, s2 | _], _).
    lattice_node_fact(_, _, vote_dissent, [percept39, s2 | _], _).

%  AC-PR39-003: frames_frame_create inscribes a reference_frame node_fact
% Define a clause for 'test': succeed when the following conditions hold.
test(frame_create_inscribes, [setup(pr39_setup)]) :-
    % State a fact for 'pai frame create' with the arguments listed below.
    frames_frame_create(room39, axes(0, 1), NodeId),
    % State a fact for 'nonvar' with the arguments listed below.
    nonvar(NodeId),
    % State the fact: lattice node fact(_, NodeId, reference_frame, [room39, axes(0, 1)], _).
    lattice_node_fact(_, NodeId, reference_frame, [room39, axes(0, 1)], _).

%  AC-PR39-004: frames_frame_anchor inscribes feature with frame and coords tags
% Define a clause for 'test': succeed when the following conditions hold.
test(frame_anchor_has_tags, [setup(pr39_setup)]) :-
    % State a fact for 'pai frame create' with the arguments listed below.
    frames_frame_create(shelf39, axes(1), _),
    % State a fact for 'pai frame anchor' with the arguments listed below.
    frames_frame_anchor(shelf39, coord(3), feature(object39, [book39_a]), NodeId),
    % State a fact for 'lattice node fact' with the arguments listed below.
    lattice_node_fact(_, NodeId, object39, [book39_a], Refs),
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(frame(shelf39), Refs),
    % State the fact: memberchk(coords(coord(3)), Refs).
    memberchk(coords(coord(3)), Refs).

%  AC-PR39-005: features queryable by frame tag
% Define a clause for 'test': succeed when the following conditions hold.
test(frame_feature_query, [setup(pr39_setup)]) :-
    % State a fact for 'pai frame create' with the arguments listed below.
    frames_frame_create(desk39, axes(1), _),
    % State a fact for 'pai frame anchor' with the arguments listed below.
    frames_frame_anchor(desk39, coord(0), feature(item39, [pen39]),    _),
    % State a fact for 'pai frame anchor' with the arguments listed below.
    frames_frame_anchor(desk39, coord(1), feature(item39, [stapler39]),_),
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count, (
        % Continue the multi-line expression started above.
        lattice_node_fact(_, _, item39, _, Refs),
        % Continue the multi-line expression started above.
        memberchk(frame(desk39), Refs)
    % Continue the multi-line expression started above.
    ), Count),
    % Check that 'Count' is numerically equal to '2'.
    Count =:= 2.

%  AC-PR39-006: frames_frame_move advances 1-D coordinate by frame step
% Define a clause for 'test': succeed when the following conditions hold.
test(frame_move_1d, [setup(pr39_setup)]) :-
    % State a fact for 'pai frame create' with the arguments listed below.
    frames_frame_create(timeline39, axes(1), _),
    % State a fact for 'pai frame move' with the arguments listed below.
    frames_frame_move(timeline39, 5, New),
    % Check that 'New' is numerically equal to '6'.
    New =:= 6.

%  AC-PR39-007: frames_frame_move advances 2-D point by dx/dy
% Define a clause for 'test': succeed when the following conditions hold.
test(frame_move_2d, [setup(pr39_setup)]) :-
    % State a fact for 'pai frame create' with the arguments listed below.
    frames_frame_create(grid39, axes(1, 2), _),
    % State a fact for 'pai frame move' with the arguments listed below.
    frames_frame_move(grid39, point(3, 4), point(X, Y)),
    % Check that 'X' is numerically equal to '4, Y =:= 6'.
    X =:= 4, Y =:= 6.

%  AC-PR39-008: nested frames carry parent_frame referent
% Define a clause for 'test': succeed when the following conditions hold.
test(nested_frame, [setup(pr39_setup)]) :-
    % State a fact for 'pai frame create' with the arguments listed below.
    frames_frame_create(building39, axes(1, 0), _),
    % State a fact for 'anchor node' with the arguments listed below.
    anchor_node(reference_frame, [office39, axes(0, 1)], [parent_frame(building39)], NodeId),
    % State a fact for 'lattice node fact' with the arguments listed below.
    lattice_node_fact(_, NodeId, reference_frame, [office39, _], Refs),
    % State the fact: memberchk(parent_frame(building39), Refs).
    memberchk(parent_frame(building39), Refs).

%  AC-PR39-009: zero-budget vote returns no_consensus
% Define a clause for 'test': succeed when the following conditions hold.
test(zero_budget_vote, [setup(pr39_setup)]) :-
    % Check that 'Voters' is unifiable with '[voter(s1, cat39, 0.9, 0.9)]'.
    Voters = [voter(s1, cat39, 0.9, 0.9)],
    % State a fact for 'pai vote' with the arguments listed below.
    frames_vote(Voters, entity39, budget(0), Result),
    % Check that 'Result' is structurally identical to 'no_consensus'.
    Result == no_consensus.

% Execute the compile-time directive: end_tests(pr39).
:- end_tests(pr39).
