/*  Tests for co_core fact-existence / assert-if-new  (dedup facility)

    Proves the verb layer will not be cluttered with duplicate relations:
    co_new_cro_unique reuses an existing relation, co_cro_find locates it, and
    co_cro_dedup cleans a store that already has duplicates.

    Run:
      swipl -p library=packs/co_core/prolog -g run_tests -t halt \
            packs/co_core/test/test_co_core_dedup.pl
*/

% Load the module under test.
:- use_module('../prolog/co_core').
% Aggregation for counting.
:- use_module(library(aggregate), [aggregate_all/3]).

% report(+Id, +Goal): print PASS or FAIL for one criterion.
report(Id, Goal) :-
    ( catch(Goal, E, (format("  error: ~q~n", [E]), fail))
    -> V = 'PASS' ; V = 'FAIL' ),
    format("~w: ~w~n", [Id, V]).

% count_cro(+Causes, +Effects, -N): how many stored relations have this content.
count_cro(Causes, Effects, N) :-
    aggregate_all(count, co_cro(_, Causes, Effects, _, _, _, _, _), N).

% run_tests: exercise the assert-if-new facility.
run_tests :-
    format("~n=== co_core — fact existence / assert-if-new ===~n~n", []),
    % A clean store.
    co_core_reset,
    P = prov(test, evidence, 0.7),

    % AC-DD-001: the first unique assertion creates the relation.
    report('AC-DD-001',
        ( co_new_cro_unique([a], [b], temporal(0,0,instant), sufficient, 0.7, [], P, Id1),
          ground(Id1) )),

    % AC-DD-002: a second identical assertion returns the SAME id and adds nothing.
    report('AC-DD-002',
        ( co_new_cro_unique([a], [b], temporal(0,0,instant), sufficient, 0.7, [], P, Id2),
          co_cro_find([a], [b], sufficient, Id0),
          Id2 == Id0,
          count_cro([a], [b], 1) )),

    % AC-DD-003: a genuinely different relation still inserts.
    report('AC-DD-003',
        ( co_new_cro_unique([a], [c], temporal(0,0,instant), sufficient, 0.7, [], P, Id3),
          count_cro([a], [c], 1),
          \+ co_cro_find([a], [b], sufficient, Id3) )),

    % AC-DD-004: the repeat raised the strength of the existing relation (evidence).
    report('AC-DD-004',
        ( co_cro(Idx, [a], [b], _, sufficient, S, _, _), Idx = Id0x, S > 0.7 )),

    % AC-DD-005: co_cro_dedup cleans duplicates made through the RAW door. Create
    % two identical relations with the raw co_new_cro, then dedup removes one.
    report('AC-DD-005',
        ( co_new_cro([x], [y], temporal(0,0,instant), sufficient, 0.7, [], P, _),
          co_new_cro([x], [y], temporal(0,0,instant), sufficient, 0.7, [], P, _),
          count_cro([x], [y], 2),
          co_cro_dedup(Removed), Removed >= 1,
          count_cro([x], [y], 1) )),

    format("~n", []).
