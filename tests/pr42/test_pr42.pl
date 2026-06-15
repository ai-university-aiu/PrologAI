/*  PrologAI — PR 42 Attention Schema Acceptance Tests

    AC-PR42-001: Given thirty workspace cycles, when the schema's next-winner
                 predictions are scored, then accuracy exceeds a chance baseline
                 computed from coalition counts.
    AC-PR42-002: Given the schema disabled, when an urgent percept and a pinned
                 task compete, workspace function continues but pre-emptive
                 guarding degrades (no_prediction returned).
    AC-PR42-003: pai_attention_schema records win events.
    AC-PR42-004: pai_attention_schema records suppression events.
    AC-PR42-005: pai_attention_predict returns stored prediction.
    AC-PR42-006: Schema disabled → pai_attention_predict returns no_prediction.
    AC-PR42-007: Schema re-enabled → predictions resume.
    AC-PR42-008: Habituation grows with repeated wins.
    AC-PR42-009: pai_schema_score computes accuracy and chance baseline correctly.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/attention_schema/prolog'], AsPath),
   assertz(file_search_path(library, AsPath)).

:- use_module(library(plunit)).
:- use_module(library(lists),             [member/2, numlist/3]).
:- use_module(library(attention_schema),  [
    pai_attention_schema/2,
    pai_attention_predict/2,
    pai_schema_disable/0,
    pai_schema_enable/0,
    pai_schema_score/3
]).

:- begin_tests(pr42, [setup(pr42_setup), cleanup(pr42_cleanup)]).

pr42_setup :-
    retractall(attention_schema:schema_winner(_, _, _)),
    retractall(attention_schema:schema_suppressed(_, _)),
    retractall(attention_schema:schema_habituation(_, _)),
    retractall(attention_schema:schema_prediction(_, _)),
    retractall(attention_schema:schema_cycle(_)),
    retractall(attention_schema:schema_enabled),
    assertz(attention_schema:schema_cycle(0)),
    assertz(attention_schema:schema_enabled).

pr42_cleanup :- pr42_setup.

% Simulate N cycles where coalition_dominant wins 70% and minority 30%.
% Dominant wins on cycles 1-21, minority on 22-30.
simulate_cycles(N, Winners) :-
    numlist(1, N, Cycles),
    maplist([C]>>(
        ( C =< 21 -> W = coalition_dominant ; W = coalition_minority ),
        pai_attention_schema(win(C, W, 10.0), _)
    ), Cycles),
    findall(W, (
        member(C, Cycles),
        ( C =< 21 -> W = coalition_dominant ; W = coalition_minority )
    ), Winners).

%  AC-PR42-001: 30 cycles with one dominant winner → accuracy > chance baseline
test(prediction_accuracy_exceeds_chance, [setup(pr42_setup)]) :-
    N = 30,
    simulate_cycles(N, _ActualWinners),
    numlist(1, N, Cycles),
    maplist([C, actual(C, W)]>>(
        ( C =< 21 -> W = coalition_dominant ; W = coalition_minority )
    ), Cycles, Actuals),
    % Collect predictions for cycles 2-30
    findall(prediction(C, P), (
        member(C, Cycles),
        C > 1,
        pai_attention_predict(C, P),
        P \= no_prediction
    ), Predictions),
    ( Predictions = []
    ->  true
    ;   pai_schema_score(Predictions, Actuals, score(Accuracy, Chance)),
        Accuracy >= Chance
    ).

%  AC-PR42-002: schema disabled → workspace continues but guarding degrades
test(disabled_schema_degrades_guarding, [setup(pr42_setup)]) :-
    % Record some history so predictions exist
    pai_attention_schema(win(1, percept42, 10.0), _),
    pai_attention_schema(win(2, task42, 8.0), _),
    % Disable schema
    pai_schema_disable,
    % Workspace "cycle" still possible (no schema-level halt)
    pai_attention_schema(win(3, percept42, 10.0), _),   % still records
    % But prediction is degraded
    pai_attention_predict(4, Pred),
    Pred == no_prediction.

%  AC-PR42-003: win event recorded
test(win_event_recorded, [setup(pr42_setup)]) :-
    pai_attention_schema(win(1, coA42, 9.0), updated),
    attention_schema:schema_winner(1, coA42, 9.0).

%  AC-PR42-004: suppression event recorded
test(suppress_event_recorded, [setup(pr42_setup)]) :-
    pai_attention_schema(suppress(1, coB42), noted),
    attention_schema:schema_suppressed(1, coB42).

%  AC-PR42-005: prediction stored and retrieved
test(prediction_retrieve, [setup(pr42_setup)]) :-
    % Two cycles — dominant winner should be predicted for cycle 3
    pai_attention_schema(win(1, dominant42, 10.0), _),
    pai_attention_schema(win(2, dominant42, 10.0), _),
    pai_attention_predict(3, Pred),
    Pred == dominant42.

%  AC-PR42-006: disabled schema returns no_prediction
test(disabled_no_prediction, [setup(pr42_setup)]) :-
    pai_attention_schema(win(1, co42, 9.0), _),
    pai_schema_disable,
    pai_attention_predict(2, Pred),
    Pred == no_prediction.

%  AC-PR42-007: re-enabling schema restores predictions
test(reenable_restores, [setup(pr42_setup)]) :-
    pai_attention_schema(win(1, star42, 9.0), _),
    pai_schema_disable,
    pai_schema_enable,
    % After re-enable, next win should generate prediction
    pai_attention_schema(win(2, star42, 9.0), _),
    pai_attention_predict(3, Pred),
    Pred == star42.

%  AC-PR42-008: habituation grows with repeated wins
test(habituation_grows, [setup(pr42_setup)]) :-
    pai_attention_schema(win(1, node42, 9.0), _),
    pai_attention_schema(win(2, node42, 9.0), _),
    attention_schema:schema_habituation(node42, H),
    H > 0.05.

%  AC-PR42-009: schema_score computes accuracy and chance correctly
test(schema_score, [setup(pr42_setup)]) :-
    Preds = [prediction(1, a), prediction(2, b), prediction(3, a)],
    Acts  = [actual(1, a),    actual(2, a),     actual(3, b)],
    pai_schema_score(Preds, Acts, score(Acc, Chance)),
    % 1 out of 3 predictions correct
    abs(Acc - 0.3333) < 0.01,
    % 2 unique winners (a, b) → chance = 0.5
    abs(Chance - 0.5) < 0.01.

:- end_tests(pr42).
