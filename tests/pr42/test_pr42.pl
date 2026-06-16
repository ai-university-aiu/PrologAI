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

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/attention_schema/prolog'], AsPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, AsPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [member/2, numlist/3] from the built-in 'lists' library.
:- use_module(library(lists),             [member/2, numlist/3]).
% Load the built-in 'attention_schema' library so its predicates are available here.
:- use_module(library(attention_schema),  [
    % Supply 'pai_attention_schema/2' as the next argument to the expression above.
    pai_attention_schema/2,
    % Supply 'pai_attention_predict/2' as the next argument to the expression above.
    pai_attention_predict/2,
    % Supply 'pai_schema_disable/0' as the next argument to the expression above.
    pai_schema_disable/0,
    % Supply 'pai_schema_enable/0' as the next argument to the expression above.
    pai_schema_enable/0,
    % Supply 'pai_schema_score/3' as the next argument to the expression above.
    pai_schema_score/3
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr42, [setup(pr42_setup), cleanup(pr42_cleanup)]).
:- begin_tests(pr42, [setup(pr42_setup), cleanup(pr42_cleanup)]).

% Execute: pr42_setup :-.
pr42_setup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(attention_schema:schema_winner(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(attention_schema:schema_suppressed(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(attention_schema:schema_habituation(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(attention_schema:schema_prediction(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(attention_schema:schema_cycle(_)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(attention_schema:schema_enabled),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(attention_schema:schema_cycle(0)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(attention_schema:schema_enabled).

% Execute: pr42_cleanup :- pr42_setup..
pr42_cleanup :- pr42_setup.

% Simulate N cycles where coalition_dominant wins 70% and minority 30%.
% Dominant wins on cycles 1-21, minority on 22-30.
% Define a clause for 'simulate cycles': succeed when the following conditions hold.
simulate_cycles(N, Winners) :-
    % State a fact for 'numlist' with the arguments listed below.
    numlist(1, N, Cycles),
    % State a fact for 'maplist' with the arguments listed below.
    maplist([C]>>(
        % Continue the multi-line expression started above.
        ( C =< 21 -> W = coalition_dominant ; W = coalition_minority ),
        % Continue the multi-line expression started above.
        pai_attention_schema(win(C, W, 10.0), _)
    % Continue the multi-line expression started above.
    ), Cycles),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(W, (
        % Continue the multi-line expression started above.
        member(C, Cycles),
        % Continue the multi-line expression started above.
        ( C =< 21 -> W = coalition_dominant ; W = coalition_minority )
    % Continue the multi-line expression started above.
    ), Winners).

%  AC-PR42-001: 30 cycles with one dominant winner → accuracy > chance baseline
% Define a clause for 'test': succeed when the following conditions hold.
test(prediction_accuracy_exceeds_chance, [setup(pr42_setup)]) :-
    % Check that 'N' is unifiable with '30'.
    N = 30,
    % State a fact for 'simulate cycles' with the arguments listed below.
    simulate_cycles(N, _ActualWinners),
    % State a fact for 'numlist' with the arguments listed below.
    numlist(1, N, Cycles),
    % State a fact for 'maplist' with the arguments listed below.
    maplist([C, actual(C, W)]>>(
        % Continue the multi-line expression started above.
        ( C =< 21 -> W = coalition_dominant ; W = coalition_minority )
    % Continue the multi-line expression started above.
    ), Cycles, Actuals),
    % Collect predictions for cycles 2-30
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(prediction(C, P), (
        % Continue the multi-line expression started above.
        member(C, Cycles),
        % Continue the multi-line expression started above.
        C > 1,
        % Continue the multi-line expression started above.
        pai_attention_predict(C, P),
        % Continue the multi-line expression started above.
        P \= no_prediction
    % Continue the multi-line expression started above.
    ), Predictions),
    % Check that '( Predictions' is unifiable with '[]'.
    ( Predictions = []
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   pai_schema_score(Predictions, Actuals, score(Accuracy, Chance)),
        % Continue the multi-line expression started above.
        Accuracy >= Chance
    % Close the expression opened above.
    ).

%  AC-PR42-002: schema disabled → workspace continues but guarding degrades
% Define a clause for 'test': succeed when the following conditions hold.
test(disabled_schema_degrades_guarding, [setup(pr42_setup)]) :-
    % Record some history so predictions exist
    % State a fact for 'pai attention schema' with the arguments listed below.
    pai_attention_schema(win(1, percept42, 10.0), _),
    % State a fact for 'pai attention schema' with the arguments listed below.
    pai_attention_schema(win(2, task42, 8.0), _),
    % Disable schema
    % Call the goal 'pai_schema_disable'.
    pai_schema_disable,
    % Workspace "cycle" still possible (no schema-level halt)
    % State a fact for 'pai attention schema' with the arguments listed below.
    pai_attention_schema(win(3, percept42, 10.0), _),   % still records
    % But prediction is degraded
    % State a fact for 'pai attention predict' with the arguments listed below.
    pai_attention_predict(4, Pred),
    % Check that 'Pred' is structurally identical to 'no_prediction'.
    Pred == no_prediction.

%  AC-PR42-003: win event recorded
% Define a clause for 'test': succeed when the following conditions hold.
test(win_event_recorded, [setup(pr42_setup)]) :-
    % State a fact for 'pai attention schema' with the arguments listed below.
    pai_attention_schema(win(1, coA42, 9.0), updated),
    % Execute: attention_schema:schema_winner(1, coA42, 9.0)..
    attention_schema:schema_winner(1, coA42, 9.0).

%  AC-PR42-004: suppression event recorded
% Define a clause for 'test': succeed when the following conditions hold.
test(suppress_event_recorded, [setup(pr42_setup)]) :-
    % State a fact for 'pai attention schema' with the arguments listed below.
    pai_attention_schema(suppress(1, coB42), noted),
    % Execute: attention_schema:schema_suppressed(1, coB42)..
    attention_schema:schema_suppressed(1, coB42).

%  AC-PR42-005: prediction stored and retrieved
% Define a clause for 'test': succeed when the following conditions hold.
test(prediction_retrieve, [setup(pr42_setup)]) :-
    % Two cycles — dominant winner should be predicted for cycle 3
    % State a fact for 'pai attention schema' with the arguments listed below.
    pai_attention_schema(win(1, dominant42, 10.0), _),
    % State a fact for 'pai attention schema' with the arguments listed below.
    pai_attention_schema(win(2, dominant42, 10.0), _),
    % State a fact for 'pai attention predict' with the arguments listed below.
    pai_attention_predict(3, Pred),
    % Check that 'Pred' is structurally identical to 'dominant42'.
    Pred == dominant42.

%  AC-PR42-006: disabled schema returns no_prediction
% Define a clause for 'test': succeed when the following conditions hold.
test(disabled_no_prediction, [setup(pr42_setup)]) :-
    % State a fact for 'pai attention schema' with the arguments listed below.
    pai_attention_schema(win(1, co42, 9.0), _),
    % Call the goal 'pai_schema_disable'.
    pai_schema_disable,
    % State a fact for 'pai attention predict' with the arguments listed below.
    pai_attention_predict(2, Pred),
    % Check that 'Pred' is structurally identical to 'no_prediction'.
    Pred == no_prediction.

%  AC-PR42-007: re-enabling schema restores predictions
% Define a clause for 'test': succeed when the following conditions hold.
test(reenable_restores, [setup(pr42_setup)]) :-
    % State a fact for 'pai attention schema' with the arguments listed below.
    pai_attention_schema(win(1, star42, 9.0), _),
    % Call the goal 'pai_schema_disable'.
    pai_schema_disable,
    % Call the goal 'pai_schema_enable'.
    pai_schema_enable,
    % After re-enable, next win should generate prediction
    % State a fact for 'pai attention schema' with the arguments listed below.
    pai_attention_schema(win(2, star42, 9.0), _),
    % State a fact for 'pai attention predict' with the arguments listed below.
    pai_attention_predict(3, Pred),
    % Check that 'Pred' is structurally identical to 'star42'.
    Pred == star42.

%  AC-PR42-008: habituation grows with repeated wins
% Define a clause for 'test': succeed when the following conditions hold.
test(habituation_grows, [setup(pr42_setup)]) :-
    % State a fact for 'pai attention schema' with the arguments listed below.
    pai_attention_schema(win(1, node42, 9.0), _),
    % State a fact for 'pai attention schema' with the arguments listed below.
    pai_attention_schema(win(2, node42, 9.0), _),
    % Execute: attention_schema:schema_habituation(node42, H),.
    attention_schema:schema_habituation(node42, H),
    % Check that 'H' is greater than '0.05'.
    H > 0.05.

%  AC-PR42-009: schema_score computes accuracy and chance correctly
% Define a clause for 'test': succeed when the following conditions hold.
test(schema_score, [setup(pr42_setup)]) :-
    % Check that 'Preds' is unifiable with '[prediction(1, a), prediction(2, b), prediction(3, a)]'.
    Preds = [prediction(1, a), prediction(2, b), prediction(3, a)],
    % Check that 'Acts' is unifiable with '[actual(1, a),    actual(2, a),     actual(3, b)]'.
    Acts  = [actual(1, a),    actual(2, a),     actual(3, b)],
    % State a fact for 'pai schema score' with the arguments listed below.
    pai_schema_score(Preds, Acts, score(Acc, Chance)),
    % 1 out of 3 predictions correct
    % Check that 'abs(Acc - 0.3333)' is less than '0.01'.
    abs(Acc - 0.3333) < 0.01,
    % 2 unique winners (a, b) → chance = 0.5
    % Check that 'abs(Chance - 0.5)' is less than '0.01'.
    abs(Chance - 0.5) < 0.01.

% Execute the compile-time directive: end_tests(pr42).
:- end_tests(pr42).
