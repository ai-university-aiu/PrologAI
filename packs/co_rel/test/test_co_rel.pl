/*  Tests for co_rel — Object Relations (WP-408)
    Run: swipl -p library=packs/co_rel/prolog -g run_tests -t halt packs/co_rel/test/test_co_rel.pl
*/
:- use_module('../prolog/co_rel').
:- use_module(library(lists), [member/2]).

report(Id, Goal) :-
    ( catch(Goal, E, (format("  error: ~q~n",[E]), fail)) -> V='PASS' ; V='FAIL' ),
    format("~w: ~w~n", [Id, V]).

% A little scene: a big box A (rows 1-9, cols 1-9), a small key B inside it at
% (5,5), a pusher C at (5,11) just right of A, and a follower D at (7,13).
scene([
    obj(a, cell(5,5),  bbox(1,1,9,9), 40),
    obj(b, cell(5,5),  bbox(5,5,5,5), 1),
    obj(c, cell(5,11), bbox(5,10,5,12), 3),
    obj(d, cell(7,13), bbox(7,13,7,13), 1)
]).

run_tests :-
    format("~n=== co_rel — Object Relations ===~n~n", []),
    scene([A,B,C,D]),

    % AC-RL-001: A contains B (the box encloses the key).
    report('AC-RL-001', cr_contains(A, B)),
    % AC-RL-002: B does not contain A.
    report('AC-RL-002', \+ cr_contains(B, A)),
    % AC-RL-003: C is adjacent to A (its box touches A's, expanded by one).
    report('AC-RL-003', cr_adjacent(A, C)),
    % AC-RL-004: A is left of C.
    report('AC-RL-004', cr_left_of(A, C)),
    % AC-RL-005: A and B share a centroid row.
    report('AC-RL-005', cr_aligned_row(A, B)),
    % AC-RL-006: the offset vector from C to D is (+2, +2).
    report('AC-RL-006', ( cr_vector(C, D, DR, DC), DR =:= 2, DC =:= 2 )),
    % AC-RL-007: A is larger than every other object.
    report('AC-RL-007', ( cr_larger(A, B), cr_larger(A, C), cr_larger(A, D) )),
    % AC-RL-008: the nearest object to C is D.
    report('AC-RL-008', ( scene(Objs), cr_nearest(C, Objs, N, _), N = obj(d,_,_,_) )),
    % AC-RL-009: the full relation set includes the containment and adjacency.
    report('AC-RL-009',
        ( scene(Objs2), cr_relations(Objs2, Rels),
          member(rel(contains, a, b), Rels),
          member(rel(adjacent, a, c), Rels),
          member(rel(vector, c, d, 2, 2), Rels) )),

    format("~n", []).
