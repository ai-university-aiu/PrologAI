/*  Tests for co_core fact existence — exact merge, near-duplicate variants

    Proves the nuance: only an EXACT duplicate relation is merged and strengthened,
    while a NEAR-duplicate (same core causes/effects, differing in a detail) is kept
    as a separate, linked variant with its delta recorded for attention — never
    silently merged. co_cro_dedup removes only exact duplicates, not variants.

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

    % AC-DD-005: co_cro_dedup cleans EXACT duplicates made through the RAW door.
    report('AC-DD-005',
        ( co_new_cro([x], [y], temporal(0,0,instant), sufficient, 0.7, [], P, _),
          co_new_cro([x], [y], temporal(0,0,instant), sufficient, 0.7, [], P, _),
          count_cro([x], [y], 2),
          co_cro_dedup(Removed), Removed >= 1,
          count_cro([x], [y], 1) )),

    % --- the nuance: near-duplicates are variants, not duplicates ---

    % AC-DD-006: a NEAR-duplicate — same core (m->n) but a DIFFERENT provenance —
    % is NOT merged. Both are kept, and the ids differ.
    P1 = prov(draft_one, evidence_a, 0.7),
    P2 = prov(draft_two, evidence_b, 0.7),
    report('AC-DD-006',
        ( co_new_cro_unique([m], [n], temporal(0,0,instant), sufficient, 0.7, [], P1, IdA),
          co_new_cro_unique([m], [n], temporal(0,0,instant), sufficient, 0.7, [], P2, IdB),
          IdA \== IdB,
          count_cro([m], [n], 2) )),

    % AC-DD-007: the two are linked as variants, and the delta names the field that
    % differs (the provenance) — the nugget surfaced for attention, not dropped.
    report('AC-DD-007',
        ( co_cro_variant(Canon, Var, Deltas),
          member(delta(prov, _, _), Deltas),
          ( Canon == IdA ; Canon == IdB ), ( Var == IdA ; Var == IdB ) )),

    % AC-DD-008: the nuanced door reports status directly — exact for an identical
    % assertion, variant for a detail-differing one.
    report('AC-DD-008',
        ( co_new_cro_nuanced([m], [n], temporal(0,0,instant), sufficient, 0.7, [], P1, _, S1),
          S1 = exact(_),
          co_new_cro_nuanced([m], [n], temporal(0,0,instant), preventive, 0.7, [], P1, _, S2),
          S2 = variant(_, D2), member(delta(modality, sufficient, preventive), D2) )),

    % AC-DD-009: co_cro_dedup does NOT remove variants — the near-duplicates survive.
    report('AC-DD-009',
        ( co_cro_dedup(_), count_cro([m], [n], N), N >= 2 )),

    % Show the flagged variants.
    ( co_cro_variants(V) -> true ; V = [] ),
    format("~nflagged variants: ~q~n~n", [V]).
