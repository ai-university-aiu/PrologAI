/*  PrologAI — PR 51 Situational Awareness: Evolving Regards Acceptance Tests

    AC-PR51-001: pai_regard_kinds lists the five standing kinds in ladder order.
    AC-PR51-002: the default active standpoint is ambient_regard.
    AC-PR51-003: a proposition held under selfward_regard can be queried back.
    AC-PR51-004: pai_regard_shift changes the active standpoint.
    AC-PR51-005: pai_regard_level orders the ladder (ambient<selfward<otherward<avowed<disavowed).
    AC-PR51-006: pai_tom_attribute attributes a belief to another agent's regard.
    AC-PR51-007: pai_tom_divergence detects a false belief (self holds P, other holds not(P)).
    AC-PR51-008: pai_tom_divergence is empty when self and other agree.
    AC-PR51-009: pai_regard_reconcile integrates avowed and disavowed views.
    AC-PR51-010: pai_regard_open rejects an ungrounded otherward agent.
*/

% Execute the compile-time directive: resolve the awareness pack path and register it.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/awareness/prolog'], PackPath),
   % Add the pack's prolog directory to the library search path.
   assertz(file_search_path(library, PackPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the 'awareness' module under test.
:- use_module(library(awareness), [
    % Supply 'pai_regard_kinds/1' as the next argument to the expression above.
    pai_regard_kinds/1,
    % Supply 'pai_regard_open/1' as the next argument to the expression above.
    pai_regard_open/1,
    % Supply 'pai_regard_hold/2' as the next argument to the expression above.
    pai_regard_hold/2,
    % Supply 'pai_regard_held/2' as the next argument to the expression above.
    pai_regard_held/2,
    % Supply 'pai_regard_shift/1' as the next argument to the expression above.
    pai_regard_shift/1,
    % Supply 'pai_regard_active/1' as the next argument to the expression above.
    pai_regard_active/1,
    % Supply 'pai_regard_level/2' as the next argument to the expression above.
    pai_regard_level/2,
    % Supply 'pai_tom_attribute/2' as the next argument to the expression above.
    pai_tom_attribute/2,
    % Supply 'pai_tom_divergence/2' as the next argument to the expression above.
    pai_tom_divergence/2,
    % Supply 'pai_regard_reconcile/1' as the next argument to the expression above.
    pai_regard_reconcile/1
% Close the import list opened above.
]).

% Open the test unit named 'awareness'.
:- begin_tests(awareness).

% AC-PR51-001 — the ladder is reported in developmental order.
test(ladder_order) :-
    % Read the standing regard kinds.
    pai_regard_kinds(Kinds),
    % Confirm the exact ladder order.
    Kinds == [ambient_regard, selfward_regard, otherward_regard,
              avowed_regard, disavowed_regard].

% AC-PR51-002 — the default standpoint is ambient awareness.
test(default_active) :-
    % Query the active standpoint.
    pai_regard_active(R),
    % Confirm it defaults to ambient_regard.
    R == ambient_regard.

% AC-PR51-003 — a held proposition is queryable.
test(hold_and_query) :-
    % Hold a proposition under the self-interested regard.
    pai_regard_hold(selfward_regard, prefers(charging)),
    % Confirm it can be read back.
    pai_regard_held(selfward_regard, prefers(charging)).

% AC-PR51-004 — shifting changes the active standpoint.
test(shift_active) :-
    % Shift the standpoint to the owned (avowed) regard.
    pai_regard_shift(avowed_regard),
    % Confirm the active standpoint moved.
    pai_regard_active(avowed_regard),
    % Restore the ambient standpoint to avoid cross-test interference.
    pai_regard_shift(ambient_regard).

% AC-PR51-005 — levels strictly increase along the ladder.
test(level_ordering) :-
    % Read each level on the ladder.
    pai_regard_level(ambient_regard, L1),
    % Self-interested level.
    pai_regard_level(selfward_regard, L2),
    % Theory-of-mind level (for some agent).
    pai_regard_level(otherward_regard(alice), L3),
    % Owned level.
    pai_regard_level(avowed_regard, L4),
    % Disowned level.
    pai_regard_level(disavowed_regard, L5),
    % Confirm the indices strictly increase.
    L1 < L2, L2 < L3, L3 < L4, L4 < L5.

% AC-PR51-006 — a belief can be attributed to another mind.
test(tom_attribute) :-
    % Attribute a belief to agent alice.
    pai_tom_attribute(alice, location(ball, basket)),
    % Confirm it is held under alice's otherward regard.
    pai_regard_held(otherward_regard(alice), location(ball, basket)).

% AC-PR51-007 — a false belief is detected as a divergence.
test(tom_false_belief) :-
    % The self believes the ball is in the box.
    pai_regard_hold(selfward_regard, location(ball, box)),
    % The self also believes alice does NOT think it is in the box.
    pai_tom_attribute(bob, not(location(ball, box))),
    % Detect divergence between self and bob.
    pai_tom_divergence(bob, Divs),
    % Confirm the contradiction is surfaced.
    member(divergence(location(ball, box), not(location(ball, box))), Divs).

% AC-PR51-008 — agreement yields no divergence.
test(tom_agreement) :-
    % The self believes the sky is clear.
    pai_regard_hold(selfward_regard, weather(clear)),
    % Agent carol agrees the sky is clear.
    pai_tom_attribute(carol, weather(clear)),
    % Compute divergence with carol.
    pai_tom_divergence(carol, Divs),
    % Confirm there is no contradiction with carol.
    \+ member(divergence(weather(clear), _), Divs).

% AC-PR51-009 — reconciliation integrates owned and disowned material.
test(reconcile) :-
    % The mind owns a preference.
    pai_regard_hold(avowed_regard, values(helpfulness)),
    % The mind disowns an aversion.
    pai_regard_hold(disavowed_regard, avoids(conflict)),
    % Reconcile the two views.
    pai_regard_reconcile(Integrated),
    % Confirm the owned material is present, tagged as avowed.
    member(avowed(values(helpfulness)), Integrated),
    % Confirm the disowned material is surfaced, tagged as disavowed.
    member(disavowed(avoids(conflict)), Integrated).

% AC-PR51-010 — an ungrounded otherward agent is rejected.
test(reject_ungrounded_other, [fail]) :-
    % Attempt to open an otherward regard with an unbound agent; this must fail.
    pai_regard_open(otherward_regard(_Unbound)).

% Close the test unit named 'awareness'.
:- end_tests(awareness).
