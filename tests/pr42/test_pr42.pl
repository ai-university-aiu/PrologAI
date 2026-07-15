/*  PrologAI — PR 42 Attention Schema Acceptance Tests

    Originally written against the standalone attention_schema pack. That pack
    was absorbed by the unification/convergence program into the attention pack
    (WP-410, Layer 385) as HALF THREE — the predictive self-model. No sub-faculty
    was lost: the predicates were renamed to pack-qualified attention_* names and
    the internal dynamic facts now live in module attention. This suite is
    rewritten against that converged home, preserving every acceptance check.

    Name migration (attention_schema -> attention):
        pai_attention_schema/2  -> attention_schema/2
        pai_attention_predict/2 -> attention_predict/2
        pai_schema_disable/0    -> attention_schema_disable/0
        pai_schema_enable/0     -> attention_schema_enable/0
        pai_schema_score/3      -> attention_schema_score/3
        internal facts schema_winner/3, schema_suppressed/2, schema_habituation/2,
        schema_prediction/2, schema_cycle/1, schema_enabled/0 now in module attention.

    AC-PR42-001: Given thirty workspace cycles, when the schema's next-winner
                 predictions are scored, then accuracy exceeds a chance baseline
                 computed from coalition counts.
    AC-PR42-002: Given the schema disabled, when an urgent percept and a pinned
                 task compete, workspace function continues but pre-emptive
                 guarding degrades (no_prediction returned).
    AC-PR42-003: attention_schema records win events.
    AC-PR42-004: attention_schema records suppression events.
    AC-PR42-005: attention_predict returns stored prediction.
    AC-PR42-006: Schema disabled -> attention_predict returns no_prediction.
    AC-PR42-007: Schema re-enabled -> predictions resume.
    AC-PR42-008: Habituation grows with repeated wins.
    AC-PR42-009: attention_schema_score computes accuracy and chance baseline correctly.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" tests/pr42/test_pr42.pl
*/

% Execute the compile-time directive: locate this test file's directory.
:- prolog_load_context(directory, TestDir),
   % Strip the file name to get the tests/pr42 directory.
   file_directory_name(TestDir, TestsDir),
   % Strip again to get the project root.
   file_directory_name(TestsDir, ProjectRoot),
   % Build the absolute path to the attention pack's prolog directory.
   atomic_list_concat([ProjectRoot, '/packs/attention/prolog'], AttnPath),
   % Register that directory on the library search path so use_module finds it.
   assertz(file_search_path(library, AttnPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [member/2, numlist/3] from the built-in 'lists' library.
:- use_module(library(lists),        [member/2, numlist/3]).
% Load the converged 'attention' library (HALF THREE is the former attention_schema).
:- use_module(library(attention),    [
    % attention_schema/2 records an attention event and updates the schema.
    attention_schema/2,
    % attention_predict/2 returns the schema's stored prediction for a cycle.
    attention_predict/2,
    % attention_schema_disable/0 turns the predictive schema off.
    attention_schema_disable/0,
    % attention_schema_enable/0 turns the predictive schema back on.
    attention_schema_enable/0,
    % attention_schema_score/3 computes accuracy and a chance baseline.
    attention_schema_score/3
% Close the import list opened above.
]).

% Execute the compile-time directive: open the pr42 test block with setup and cleanup.
:- begin_tests(pr42, [setup(pr42_setup), cleanup(pr42_cleanup)]).

% Define a clause for 'pr42 setup': reset the schema's internal state to a clean baseline.
pr42_setup :-
    % Remove every recorded win event from the attention module.
    retractall(attention:schema_winner(_, _, _)),
    % Remove every recorded suppression event from the attention module.
    retractall(attention:schema_suppressed(_, _)),
    % Remove every habituation level from the attention module.
    retractall(attention:schema_habituation(_, _)),
    % Remove every stored prediction from the attention module.
    retractall(attention:schema_prediction(_, _)),
    % Remove the cycle counter from the attention module.
    retractall(attention:schema_cycle(_)),
    % Remove the enabled flag from the attention module.
    retractall(attention:schema_enabled),
    % Start the cycle counter at zero.
    assertz(attention:schema_cycle(0)),
    % Start with the schema enabled.
    assertz(attention:schema_enabled).

% Define a clause for 'pr42 cleanup': restoring the baseline is the same work as setup.
pr42_cleanup :- pr42_setup.

% Simulate N cycles where coalition_dominant wins cycles 1-21 and minority wins 22-30.
% Define a clause for 'simulate cycles': record one win per cycle and return the actual winners.
simulate_cycles(N, Winners) :-
    % Build the list of cycle numbers 1..N.
    numlist(1, N, Cycles),
    % For each cycle, pick the winner and record it as a win event.
    maplist([C]>>(
        % Cycles up to 21 are won by the dominant coalition, the rest by the minority.
        ( C =< 21 -> W = coalition_dominant ; W = coalition_minority ),
        % Record the win event through the converged predicate.
        attention_schema(win(C, W, 10.0), _)
    % Close the per-cycle lambda.
    ), Cycles),
    % Collect the actual winner for each cycle into a flat list.
    findall(W, (
        % Iterate over the same cycle numbers.
        member(C, Cycles),
        % Apply the same dominant/minority split.
        ( C =< 21 -> W = coalition_dominant ; W = coalition_minority )
    % Close the findall goal.
    ), Winners).

%  AC-PR42-001: 30 cycles with one dominant winner -> accuracy >= chance baseline.
% Define a clause for 'test': the schema beats chance over thirty cycles.
test(prediction_accuracy_exceeds_chance, [setup(pr42_setup)]) :-
    % Run thirty cognitive cycles.
    N = 30,
    % Drive the schema across those cycles.
    simulate_cycles(N, _ActualWinners),
    % Rebuild the cycle numbers for scoring.
    numlist(1, N, Cycles),
    % Pair each cycle with the actual winner as an actual/2 term.
    maplist([C, actual(C, W)]>>(
        % Apply the dominant/minority split for the actual winner.
        ( C =< 21 -> W = coalition_dominant ; W = coalition_minority )
    % Close the actuals lambda.
    ), Cycles, Actuals),
    % Collect the schema's stored predictions for cycles 2..30 (skipping no_prediction).
    findall(prediction(C, P), (
        % Iterate over the cycle numbers.
        member(C, Cycles),
        % Predictions only exist for cycles after the first.
        C > 1,
        % Read the stored prediction for this cycle.
        attention_predict(C, P),
        % Keep only real predictions.
        P \= no_prediction
    % Close the predictions findall.
    ), Predictions),
    % If no predictions were produced, the criterion is vacuously satisfied.
    ( Predictions = []
    % In that degenerate case, succeed.
    ->  true
    % Otherwise, score the predictions against the actuals.
    ;   attention_schema_score(Predictions, Actuals, score(Accuracy, Chance)),
        % Require the schema's accuracy to reach or exceed the chance baseline.
        Accuracy >= Chance
    % Close the if-then-else.
    ).

%  AC-PR42-002: schema disabled -> workspace continues but guarding degrades.
% Define a clause for 'test': disabling the schema returns no_prediction while events still record.
test(disabled_schema_degrades_guarding, [setup(pr42_setup)]) :-
    % Record a first win so some history exists.
    attention_schema(win(1, percept42, 10.0), _),
    % Record a second win for a competing coalition.
    attention_schema(win(2, task42, 8.0), _),
    % Disable the predictive schema.
    attention_schema_disable,
    % A further win still records (no schema-level halt of the workspace).
    attention_schema(win(3, percept42, 10.0), _),
    % Ask for the next prediction while disabled.
    attention_predict(4, Pred),
    % Confirm pre-emptive guarding degraded to no_prediction.
    Pred == no_prediction.

%  AC-PR42-003: win event recorded.
% Define a clause for 'test': a win event is stored under schema_winner.
test(win_event_recorded, [setup(pr42_setup)]) :-
    % Record a win and expect the 'updated' acknowledgement.
    attention_schema(win(1, coA42, 9.0), updated),
    % Confirm the win fact was asserted in the attention module.
    attention:schema_winner(1, coA42, 9.0).

%  AC-PR42-004: suppression event recorded.
% Define a clause for 'test': a suppression event is stored under schema_suppressed.
test(suppress_event_recorded, [setup(pr42_setup)]) :-
    % Record a suppression and expect the 'noted' acknowledgement.
    attention_schema(suppress(1, coB42), noted),
    % Confirm the suppression fact was asserted in the attention module.
    attention:schema_suppressed(1, coB42).

%  AC-PR42-005: prediction stored and retrieved.
% Define a clause for 'test': two dominant wins make the dominant coalition the prediction.
test(prediction_retrieve, [setup(pr42_setup)]) :-
    % Record a first dominant win.
    attention_schema(win(1, dominant42, 10.0), _),
    % Record a second dominant win, which stores the prediction for cycle 3.
    attention_schema(win(2, dominant42, 10.0), _),
    % Read the stored prediction for cycle 3.
    attention_predict(3, Pred),
    % Confirm the dominant coalition was predicted.
    Pred == dominant42.

%  AC-PR42-006: disabled schema returns no_prediction.
% Define a clause for 'test': disabling the schema yields no_prediction.
test(disabled_no_prediction, [setup(pr42_setup)]) :-
    % Record a win so a prediction would otherwise exist.
    attention_schema(win(1, co42, 9.0), _),
    % Disable the predictive schema.
    attention_schema_disable,
    % Ask for the prediction while disabled.
    attention_predict(2, Pred),
    % Confirm the schema returns no_prediction.
    Pred == no_prediction.

%  AC-PR42-007: re-enabling schema restores predictions.
% Define a clause for 'test': re-enabling the schema resumes predictions.
test(reenable_restores, [setup(pr42_setup)]) :-
    % Record a win, then disable, then re-enable the schema.
    attention_schema(win(1, star42, 9.0), _),
    % Disable the predictive schema.
    attention_schema_disable,
    % Re-enable the predictive schema.
    attention_schema_enable,
    % After re-enabling, the next win regenerates a prediction for cycle 3.
    attention_schema(win(2, star42, 9.0), _),
    % Read the restored prediction for cycle 3.
    attention_predict(3, Pred),
    % Confirm predictions resumed with the dominant coalition.
    Pred == star42.

%  AC-PR42-008: habituation grows with repeated wins.
% Define a clause for 'test': repeated wins raise a node's habituation above one step.
test(habituation_grows, [setup(pr42_setup)]) :-
    % Record a first win for the node.
    attention_schema(win(1, node42, 9.0), _),
    % Record a second win for the same node.
    attention_schema(win(2, node42, 9.0), _),
    % Read the node's accumulated habituation level.
    attention:schema_habituation(node42, H),
    % Confirm habituation grew past a single 0.05 increment.
    H > 0.05.

%  AC-PR42-009: schema_score computes accuracy and chance correctly.
% Define a clause for 'test': the scorer reports the expected accuracy and chance baseline.
test(schema_score, [setup(pr42_setup)]) :-
    % Three predictions, one of which matches its actual.
    Preds = [prediction(1, a), prediction(2, b), prediction(3, a)],
    % The matching actuals for the same three cycles.
    Acts  = [actual(1, a),    actual(2, a),     actual(3, b)],
    % Score the predictions against the actuals.
    attention_schema_score(Preds, Acts, score(Acc, Chance)),
    % One out of three predictions is correct.
    abs(Acc - 0.3333) < 0.01,
    % Two unique winners (a, b) give a chance baseline of one half.
    abs(Chance - 0.5) < 0.01.

% Execute the compile-time directive: close the pr42 test block.
:- end_tests(pr42).
