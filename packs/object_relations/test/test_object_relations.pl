/*  PrologAI — Causalontology Object Relations Test Suite  (WP-408)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/object_relations/test/test_object_relations.pl
*/

% Declare this file as a test module.
:- module(test_object_relations, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(object_relations)).
% Load the list helper used by the relation-set test.
:- use_module(library(lists), [member/2]).

% A little scene: a big box A (rows 1-9, cols 1-9), a small key B inside it at
% (5,5), a pusher C at (5,11) just right of A, and a follower D at (7,13).
scene([
    obj(a, cell(5,5),  bbox(1,1,9,9), 40),
    obj(b, cell(5,5),  bbox(5,5,5,5), 1),
    obj(c, cell(5,11), bbox(5,10,5,12), 3),
    obj(d, cell(7,13), bbox(7,13,7,13), 1)
]).

% Open the test block for object_relations.
:- begin_tests(object_relations).

% AC-RL-001: A contains B (the box encloses the key).
test(contains_box_encloses_key) :-
    % Bind the four scene objects.
    scene([A, B, _C, _D]),
    % The big box encloses the key.
    assertion(object_relations_contains(A, B)).

% AC-RL-002: B does not contain A.
test(containment_is_directional) :-
    % Bind the four scene objects.
    scene([A, B, _C, _D]),
    % The key does not enclose the box.
    assertion(\+ object_relations_contains(B, A)).

% AC-RL-003: C is adjacent to A (its box touches A's, expanded by one).
test(adjacent_pusher_touches_box) :-
    % Bind the four scene objects.
    scene([A, _B, C, _D]),
    % The pusher is adjacent to the box.
    assertion(object_relations_adjacent(A, C)).

% AC-RL-004: A is left of C.
test(left_of_by_centroid) :-
    % Bind the four scene objects.
    scene([A, _B, C, _D]),
    % The box's centroid is left of the pusher's.
    assertion(object_relations_left_of(A, C)).

% AC-RL-005: A and B share a centroid row.
test(aligned_row_shared) :-
    % Bind the four scene objects.
    scene([A, B, _C, _D]),
    % The box and the key are on the same centroid row.
    assertion(object_relations_aligned_row(A, B)).

% AC-RL-006: the offset vector from C to D is (+2, +2).
test(vector_offset_c_to_d) :-
    % Bind the four scene objects.
    scene([_A, _B, C, D]),
    % Compute the centroid offset from the pusher to the follower.
    object_relations_vector(C, D, DR, DC),
    % It moves down two rows.
    assertion(DR =:= 2),
    % And right two columns.
    assertion(DC =:= 2).

% AC-RL-007: A is larger than every other object.
test(larger_than_all_others) :-
    % Bind the four scene objects.
    scene([A, B, C, D]),
    % The box has more cells than the key.
    assertion(object_relations_larger(A, B)),
    % More than the pusher.
    assertion(object_relations_larger(A, C)),
    % And more than the follower.
    assertion(object_relations_larger(A, D)).

% AC-RL-008: the nearest object to C is D.
test(nearest_neighbour_of_c) :-
    % The whole scene as a candidate set.
    scene(Objs),
    % Bind the pusher object.
    scene([_A, _B, C, _D]),
    % Find the object nearest to the pusher.
    object_relations_nearest(C, Objs, N, _Dist),
    % It is the follower.
    assertion(N = obj(d, _, _, _)).

% AC-RL-009: the full relation set includes the containment and adjacency.
test(relation_set_contains_key_relations) :-
    % The whole scene.
    scene(Objs),
    % Enumerate every relation over the objects.
    object_relations_relations(Objs, Rels),
    % The box contains the key.
    assertion(member(rel(contains, a, b), Rels)),
    % The box is adjacent to the pusher.
    assertion(member(rel(adjacent, a, c), Rels)),
    % The pusher-to-follower offset vector is present.
    assertion(member(rel(vector, c, d, 2, 2), Rels)).

% Close the test block.
:- end_tests(object_relations).
