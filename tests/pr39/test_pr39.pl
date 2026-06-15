/*  PrologAI — PR 39 Reference Frames and Voting Consensus Acceptance Tests

    AC-PR39-001: Two observation passes over a simulated object from different
                 approach paths anchor features into ONE object frame; a third
                 partial observation retrieves the object by frame match.
    AC-PR39-002: Three specialists classifying one percept with conflicting
                 conclusions at differing confidences → a consensus node_fact
                 with weighted tally and preserved dissent records.
    AC-PR39-003: pai_frame_create inscribes a reference_frame node_fact.
    AC-PR39-004: pai_frame_anchor inscribes a feature with frame and coords.
    AC-PR39-005: pai_frame_anchor features queryable by frame tag.
    AC-PR39-006: pai_frame_move advances a 1-D coordinate by the frame step.
    AC-PR39-007: pai_frame_move advances a 2-D point by the frame's dx/dy.
    AC-PR39-008: Nested frames carry parent_frame referent.
    AC-PR39-009: Zero-budget vote returns no_consensus.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/lattice/prolog'],        LatPath),
   atomic_list_concat([ProjectRoot, '/packs/vector_backend/prolog'], VBPath),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'],         ActPath),
   atomic_list_concat([ProjectRoot, '/packs/frames/prolog'],         FrPath),
   assertz(file_search_path(library, LatPath)),
   assertz(file_search_path(library, VBPath)),
   assertz(file_search_path(library, ActPath)),
   assertz(file_search_path(library, FrPath)).

:- use_module(library(plunit)).
:- use_module(library(lists),    [member/2, memberchk/2]).
:- use_module(library(aggregate),[aggregate_all/3]).
:- use_module(library(lattice),  [lattice_open/2, lattice_close/1,
                                   lattice_node_fact/5]).
:- use_module(library(node_facts),[set_default_nexus/1, anchor_node/4]).
:- use_module(library(frames),   [
    pai_frame_create/3,
    pai_frame_anchor/4,
    pai_frame_move/3,
    pai_vote/4
]).

:- begin_tests(pr39, [setup(pr39_setup), cleanup(pr39_cleanup)]).

pr39_setup :-
    lattice_open('locus://localhost/pr39', N),
    nb_setval(pr39_nexus, N),
    set_default_nexus(N).

pr39_cleanup :-
    nb_getval(pr39_nexus, N),
    lattice_close(N).

%  AC-PR39-001: two observation passes anchor into one frame; third retrieves
test(two_passes_one_frame, [setup(pr39_setup)]) :-
    pai_frame_create(mug39, axes(1, 0), _FrameId),
    % First pass: anchor a handle and a rim
    pai_frame_anchor(mug39, point(0,1), feature(visual_feature, [handle39]), _),
    pai_frame_anchor(mug39, point(0,2), feature(visual_feature, [rim39]),    _),
    % Second pass (different approach): anchor base
    pai_frame_anchor(mug39, point(0,0), feature(visual_feature, [base39]),   _),
    % Retrieve all features in this frame
    findall(F, (
        lattice_node_fact(_, _, visual_feature, [F], Refs),
        memberchk(frame(mug39), Refs)
    ), Features),
    length(Features, NF),
    NF =:= 3.

%  AC-PR39-002: three specialists → consensus + preserved dissent (the key AC)
test(three_specialists_vote, [setup(pr39_setup)]) :-
    Voters = [
        voter(s1, bird39, 0.9, 0.8),
        voter(s2, mammal39, 0.7, 0.6),
        voter(s3, bird39, 0.5, 0.9)
    ],
    pai_vote(Voters, percept39, budget(10), Consensus),
    Consensus = consensus(percept39, bird39, _Score, _CId),
    % Dissent for mammal39 voter must exist in Lattice
    lattice_node_fact(_, _, vote_dissent, [percept39, s2 | _], _).

%  AC-PR39-003: pai_frame_create inscribes a reference_frame node_fact
test(frame_create_inscribes, [setup(pr39_setup)]) :-
    pai_frame_create(room39, axes(0, 1), NodeId),
    nonvar(NodeId),
    lattice_node_fact(_, NodeId, reference_frame, [room39, axes(0, 1)], _).

%  AC-PR39-004: pai_frame_anchor inscribes feature with frame and coords tags
test(frame_anchor_has_tags, [setup(pr39_setup)]) :-
    pai_frame_create(shelf39, axes(1), _),
    pai_frame_anchor(shelf39, coord(3), feature(object39, [book39_a]), NodeId),
    lattice_node_fact(_, NodeId, object39, [book39_a], Refs),
    memberchk(frame(shelf39), Refs),
    memberchk(coords(coord(3)), Refs).

%  AC-PR39-005: features queryable by frame tag
test(frame_feature_query, [setup(pr39_setup)]) :-
    pai_frame_create(desk39, axes(1), _),
    pai_frame_anchor(desk39, coord(0), feature(item39, [pen39]),    _),
    pai_frame_anchor(desk39, coord(1), feature(item39, [stapler39]),_),
    aggregate_all(count, (
        lattice_node_fact(_, _, item39, _, Refs),
        memberchk(frame(desk39), Refs)
    ), Count),
    Count =:= 2.

%  AC-PR39-006: pai_frame_move advances 1-D coordinate by frame step
test(frame_move_1d, [setup(pr39_setup)]) :-
    pai_frame_create(timeline39, axes(1), _),
    pai_frame_move(timeline39, 5, New),
    New =:= 6.

%  AC-PR39-007: pai_frame_move advances 2-D point by dx/dy
test(frame_move_2d, [setup(pr39_setup)]) :-
    pai_frame_create(grid39, axes(1, 2), _),
    pai_frame_move(grid39, point(3, 4), point(X, Y)),
    X =:= 4, Y =:= 6.

%  AC-PR39-008: nested frames carry parent_frame referent
test(nested_frame, [setup(pr39_setup)]) :-
    pai_frame_create(building39, axes(1, 0), _),
    anchor_node(reference_frame, [office39, axes(0, 1)], [parent_frame(building39)], NodeId),
    lattice_node_fact(_, NodeId, reference_frame, [office39, _], Refs),
    memberchk(parent_frame(building39), Refs).

%  AC-PR39-009: zero-budget vote returns no_consensus
test(zero_budget_vote, [setup(pr39_setup)]) :-
    Voters = [voter(s1, cat39, 0.9, 0.9)],
    pai_vote(Voters, entity39, budget(0), Result),
    Result == no_consensus.

:- end_tests(pr39).
