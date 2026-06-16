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

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/attention/prolog'], AttPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, AttPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate), [aggregate_all/3]).
% Load the built-in 'attention' library so its predicates are available here.
:- use_module(library(attention), [
    % Supply 'pai_attention/3' as the next argument to the expression above.
    pai_attention/3,
    % Supply 'pai_wage/3' as the next argument to the expression above.
    pai_wage/3,
    % Supply 'pai_attention_spread/2' as the next argument to the expression above.
    pai_attention_spread/2,
    % Supply 'pai_banker_cycle/0' as the next argument to the expression above.
    pai_banker_cycle/0,
    % Supply 'pai_attention_metrics/1' as the next argument to the expression above.
    pai_attention_metrics/1,
    % Supply 'pai_evict_lowest_lti/1' as the next argument to the expression above.
    pai_evict_lowest_lti/1,
    % Supply 'pai_attention_link/2' as the next argument to the expression above.
    pai_attention_link/2
% Close the expression opened above.
]).

% Execute: reset_attention :-.
reset_attention :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(attention:attention_value(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(attention:banker_reserve(_)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(attention:co_activation_edge(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(attention:protected_node(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(attention:banker_reserve(1000.0)).

% Execute the compile-time directive: begin_tests(pr32).
:- begin_tests(pr32).

%  AC-PR32-001: contributor LTI > idle LTI after 100 cycles; idle evicted first
% Define a clause for 'test': succeed when the following conditions hold.
test(contributor_outlasts_idle, [setup(reset_attention)]) :-
    % State a fact for 'pai wage' with the arguments listed below.
    pai_wage(contributor32, 1.0, _),
    % State a fact for 'pai attention' with the arguments listed below.
    pai_attention(idle32, sti, 0.0),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, 100, _), pai_banker_cycle),
    % State a fact for 'pai attention' with the arguments listed below.
    pai_attention(contributor32, lti, ContLTI),
    % State a fact for 'pai attention' with the arguments listed below.
    pai_attention(idle32, lti, IdleLTI),
    % Check that 'ContLTI' is greater than 'IdleLTI'.
    ContLTI > IdleLTI,
    % State a fact for 'pai evict lowest lti' with the arguments listed below.
    pai_evict_lowest_lti(1),
    % Succeed only if 'attention:attention_value(idle32, _, _' cannot be proved (negation as failure).
    \+ attention:attention_value(idle32, _, _),
    % State the fact: once(attention:attention_value(contributor32, _, _)).
    once(attention:attention_value(contributor32, _, _)).

%  AC-PR32-002: total STI + reserve = circulation_cap immediately after wage
% Define a clause for 'test': succeed when the following conditions hold.
test(conservation_sti_plus_reserve, [setup(reset_attention)]) :-
    % State a fact for 'pai wage' with the arguments listed below.
    pai_wage(cons32, 1.0, _),
    % State a fact for 'pai attention metrics' with the arguments listed below.
    pai_attention_metrics(metrics(TotalSTI, _, Reserve)),
    % Evaluate the arithmetic expression 'TotalSTI + Reserve' and bind the result to 'Sum'.
    Sum is TotalSTI + Reserve,
    % Check that 'abs(Sum - 1000.0)' is less than '0.01'.
    abs(Sum - 1000.0) < 0.01.

%  AC-PR32-003: conservation holds after one banker cycle
% Define a clause for 'test': succeed when the following conditions hold.
test(conservation_after_cycle, [setup(reset_attention)]) :-
    % State a fact for 'pai wage' with the arguments listed below.
    pai_wage(cycle32, 2.0, _),
    % Call the goal 'pai_banker_cycle'.
    pai_banker_cycle,
    % State a fact for 'pai attention metrics' with the arguments listed below.
    pai_attention_metrics(metrics(TotalSTI, _, Reserve)),
    % Evaluate the arithmetic expression 'TotalSTI + Reserve' and bind the result to 'Sum'.
    Sum is TotalSTI + Reserve,
    % Check that 'abs(Sum - 1000.0)' is less than '0.01'.
    abs(Sum - 1000.0) < 0.01.

%  AC-PR32-004: wages deduct ActualSTI from reserve exactly
% Define a clause for 'test': succeed when the following conditions hold.
test(wages_from_reserve, [setup(reset_attention)]) :-
    % Execute: attention:banker_reserve(R0),.
    attention:banker_reserve(R0),
    % State a fact for 'pai wage' with the arguments listed below.
    pai_wage(wage32, 2.0, credits(ActualSTI, _)),
    % Execute: attention:banker_reserve(R1),.
    attention:banker_reserve(R1),
    % Evaluate the arithmetic expression 'R0 - R1' and bind the result to 'Diff'.
    Diff is R0 - R1,
    % Check that 'abs(Diff - ActualSTI)' is less than '0.001'.
    abs(Diff - ActualSTI) < 0.001.

%  AC-PR32-005: rent decays STI by sti_rent_rate per banker cycle
% Define a clause for 'test': succeed when the following conditions hold.
test(rent_decays_sti, [setup(reset_attention)]) :-
    % State a fact for 'pai attention' with the arguments listed below.
    pai_attention(rent32, sti, 100.0),
    % Call the goal 'pai_banker_cycle'.
    pai_banker_cycle,
    % State a fact for 'pai attention' with the arguments listed below.
    pai_attention(rent32, sti, NewSTI),
    % Evaluate the arithmetic expression '100.0 * (1.0 - 0.05)' and bind the result to 'ExpectedSTI'.
    ExpectedSTI is 100.0 * (1.0 - 0.05),
    % Check that 'abs(NewSTI - ExpectedSTI)' is less than '0.001'.
    abs(NewSTI - ExpectedSTI) < 0.001.

%  AC-PR32-006: pai_attention_spread transfers STI fraction to neighbors
% Define a clause for 'test': succeed when the following conditions hold.
test(spread_transfers_sti, [setup(reset_attention)]) :-
    % State a fact for 'pai attention' with the arguments listed below.
    pai_attention(src32, sti, 100.0),
    % State a fact for 'pai attention' with the arguments listed below.
    pai_attention(nbr32, sti, 0.0),
    % State a fact for 'pai attention spread' with the arguments listed below.
    pai_attention_spread(src32, [nbr32]),
    % State a fact for 'pai attention' with the arguments listed below.
    pai_attention(nbr32, sti, NbrSTI),
    % Check that 'NbrSTI' is greater than '0.0'.
    NbrSTI > 0.0.

%  AC-PR32-007: pai_evict_lowest_lti removes lowest-LTI non-protected nodes
% Define a clause for 'test': succeed when the following conditions hold.
test(evict_lowest_lti, [setup(reset_attention)]) :-
    % State a fact for 'pai attention' with the arguments listed below.
    pai_attention(ev_hi32, lti, 20.0),
    % State a fact for 'pai attention' with the arguments listed below.
    pai_attention(ev_lo32, lti,  5.0),
    % State a fact for 'pai attention' with the arguments listed below.
    pai_attention(ev_md32, lti, 10.0),
    % State a fact for 'pai evict lowest lti' with the arguments listed below.
    pai_evict_lowest_lti(1),
    % State a fact for 'once' with the arguments listed below.
    once(attention:attention_value(ev_hi32, _, _)),
    % Succeed only if 'attention:attention_value(ev_lo32, _, _' cannot be proved (negation as failure).
    \+ attention:attention_value(ev_lo32, _, _),
    % Succeed only if 'attention:attention_value(ev_md32, _, _' cannot be proved (negation as failure).
    \+ attention:attention_value(ev_md32, _, _).

%  AC-PR32-008: pai_attention_metrics returns non-negative totals
% Define a clause for 'test': succeed when the following conditions hold.
test(metrics_non_negative, [setup(reset_attention)]) :-
    % State a fact for 'pai attention' with the arguments listed below.
    pai_attention(ma32, sti, 50.0),
    % State a fact for 'pai attention' with the arguments listed below.
    pai_attention(mb32, sti, 30.0),
    % State a fact for 'pai attention metrics' with the arguments listed below.
    pai_attention_metrics(metrics(TotalSTI, TotalLTI, Reserve)),
    % Check that 'TotalSTI' is greater than or equal to '0.0'.
    TotalSTI >= 0.0,
    % Check that 'TotalLTI' is greater than or equal to '0.0'.
    TotalLTI >= 0.0,
    % Check that 'Reserve' is greater than or equal to '0.0'.
    Reserve >= 0.0,
    % Check that 'abs(TotalSTI - 80.0)' is less than '0.01'.
    abs(TotalSTI - 80.0) < 0.01.

%  AC-PR32-009: pai_attention_link is idempotent — no duplicate edges stored
% Define a clause for 'test': succeed when the following conditions hold.
test(attention_link_idempotent, [setup(reset_attention)]) :-
    % State a fact for 'pai attention link' with the arguments listed below.
    pai_attention_link(la32, lb32),
    % State a fact for 'pai attention link' with the arguments listed below.
    pai_attention_link(la32, lb32),
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count, attention:co_activation_edge(la32, lb32), Count),
    % Check that 'Count' is numerically equal to '1'.
    Count =:= 1.

% Execute the compile-time directive: end_tests(pr32).
:- end_tests(pr32).
