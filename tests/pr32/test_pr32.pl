/*  PrologAI — PR 32 Attention Economy (ECAN) Acceptance Tests

    AC-PR32-001: Contributor node's LTI outlasts idle node's LTI after 100
                 banker cycles; pai_evict_lowest_lti removes idle first.
    AC-PR32-002: total STI + reserve = circulation_cap immediately after wage.
    AC-PR32-003: Conservation holds after one banker cycle.
    AC-PR32-004: Wages deduct ActualSTI from reserve exactly.
    AC-PR32-005: Rent decays node STI by sti_rent_rate each banker cycle.
    AC-PR32-006: pai_attention_spread transfers STI fraction to neighbors.
    AC-PR32-007: pai_evict_lowest_lti removes lowest-LTI non-protected nodes.
    AC-PR32-008: pai_attention_metrics returns non-negative totals.
    AC-PR32-009: pai_attention_link is idempotent — no duplicate edges.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/attention/prolog'], AttPath),
   assertz(file_search_path(library, AttPath)).

:- use_module(library(plunit)).
:- use_module(library(aggregate), [aggregate_all/3]).
:- use_module(library(attention), [
    pai_attention/3,
    pai_wage/3,
    pai_attention_spread/2,
    pai_banker_cycle/0,
    pai_attention_metrics/1,
    pai_evict_lowest_lti/1,
    pai_attention_link/2
]).

reset_attention :-
    retractall(attention:attention_value(_, _, _)),
    retractall(attention:banker_reserve(_)),
    retractall(attention:co_activation_edge(_, _)),
    retractall(attention:protected_node(_)),
    assertz(attention:banker_reserve(1000.0)).

:- begin_tests(pr32).

%  AC-PR32-001: contributor LTI > idle LTI after 100 cycles; idle evicted first
test(contributor_outlasts_idle, [setup(reset_attention)]) :-
    pai_wage(contributor32, 1.0, _),
    pai_attention(idle32, sti, 0.0),
    forall(between(1, 100, _), pai_banker_cycle),
    pai_attention(contributor32, lti, ContLTI),
    pai_attention(idle32, lti, IdleLTI),
    ContLTI > IdleLTI,
    pai_evict_lowest_lti(1),
    \+ attention:attention_value(idle32, _, _),
    once(attention:attention_value(contributor32, _, _)).

%  AC-PR32-002: total STI + reserve = circulation_cap immediately after wage
test(conservation_sti_plus_reserve, [setup(reset_attention)]) :-
    pai_wage(cons32, 1.0, _),
    pai_attention_metrics(metrics(TotalSTI, _, Reserve)),
    Sum is TotalSTI + Reserve,
    abs(Sum - 1000.0) < 0.01.

%  AC-PR32-003: conservation holds after one banker cycle
test(conservation_after_cycle, [setup(reset_attention)]) :-
    pai_wage(cycle32, 2.0, _),
    pai_banker_cycle,
    pai_attention_metrics(metrics(TotalSTI, _, Reserve)),
    Sum is TotalSTI + Reserve,
    abs(Sum - 1000.0) < 0.01.

%  AC-PR32-004: wages deduct ActualSTI from reserve exactly
test(wages_from_reserve, [setup(reset_attention)]) :-
    attention:banker_reserve(R0),
    pai_wage(wage32, 2.0, credits(ActualSTI, _)),
    attention:banker_reserve(R1),
    Diff is R0 - R1,
    abs(Diff - ActualSTI) < 0.001.

%  AC-PR32-005: rent decays STI by sti_rent_rate per banker cycle
test(rent_decays_sti, [setup(reset_attention)]) :-
    pai_attention(rent32, sti, 100.0),
    pai_banker_cycle,
    pai_attention(rent32, sti, NewSTI),
    ExpectedSTI is 100.0 * (1.0 - 0.05),
    abs(NewSTI - ExpectedSTI) < 0.001.

%  AC-PR32-006: pai_attention_spread transfers STI fraction to neighbors
test(spread_transfers_sti, [setup(reset_attention)]) :-
    pai_attention(src32, sti, 100.0),
    pai_attention(nbr32, sti, 0.0),
    pai_attention_spread(src32, [nbr32]),
    pai_attention(nbr32, sti, NbrSTI),
    NbrSTI > 0.0.

%  AC-PR32-007: pai_evict_lowest_lti removes lowest-LTI non-protected nodes
test(evict_lowest_lti, [setup(reset_attention)]) :-
    pai_attention(ev_hi32, lti, 20.0),
    pai_attention(ev_lo32, lti,  5.0),
    pai_attention(ev_md32, lti, 10.0),
    pai_evict_lowest_lti(1),
    once(attention:attention_value(ev_hi32, _, _)),
    \+ attention:attention_value(ev_lo32, _, _),
    \+ attention:attention_value(ev_md32, _, _).

%  AC-PR32-008: pai_attention_metrics returns non-negative totals
test(metrics_non_negative, [setup(reset_attention)]) :-
    pai_attention(ma32, sti, 50.0),
    pai_attention(mb32, sti, 30.0),
    pai_attention_metrics(metrics(TotalSTI, TotalLTI, Reserve)),
    TotalSTI >= 0.0,
    TotalLTI >= 0.0,
    Reserve >= 0.0,
    abs(TotalSTI - 80.0) < 0.01.

%  AC-PR32-009: pai_attention_link is idempotent — no duplicate edges stored
test(attention_link_idempotent, [setup(reset_attention)]) :-
    pai_attention_link(la32, lb32),
    pai_attention_link(la32, lb32),
    aggregate_all(count, attention:co_activation_edge(la32, lb32), Count),
    Count =:= 1.

:- end_tests(pr32).
