/*  PrologAI — Staged Appraisal and Coping (EMA)  (Specification PR 26)

    Implements the EMA (Emotion and Adaptation) cognitive appraisal model:

    Stage 1 — Causal interpretation: a pai_causal_model/1 is maintained over
    events recording past/future events, causal links, agenda, and likelihoods.

    Stage 2 — Appraisal: per event, four variables are computed:
        desirability    — how well the event serves active goals [−1, 1]
        likelihood      — estimated probability [0, 1]
        attribution     — who caused the event (self | other | unknown)
        controllability — how much the agent can influence the outcome [0, 1]

    Stage 3 — Emotion: appraisal variables map to an emotion instance with
    intensity; intensities aggregate into mood; intensity decays over time.

    Stage 4 — Coping:
        high controllability → problem-focused coping (plan to change the world)
        low  controllability → emotion-focused coping (re-appraise or adjust
                               desirability; NEVER denies safety-critical facts)

    Predicates:
        pai_causal_model/1      — +Event  (assert into causal interpretation)
        pai_appraise/3          — +Event, +Goals, -Appraisal
        pai_cope_select/3       — +Appraisal, +Opts, -CopingStrategy
        pai_emotion_from_appraisal/2  — +Appraisal, -Emotion(intensity)
        pai_appraisal_decay/0   — tick: decay emotion intensities
*/

% Declare this file as the 'appraisal' module and list its exported predicates.
:- module(appraisal, [
    % Supply 'pai_causal_model/1' as the next argument to the expression above.
    pai_causal_model/1,
    % Supply 'pai_appraise/3' as the next argument to the expression above.
    pai_appraise/3,
    % Supply 'pai_cope_select/3' as the next argument to the expression above.
    pai_cope_select/3,
    % Supply 'pai_emotion_from_appraisal/2' as the next argument to the expression above.
    pai_emotion_from_appraisal/2,
    % Supply 'pai_appraisal_decay/0' as the next argument to the expression above.
    pai_appraisal_decay/0
% Close the expression opened above.
]).

% Import [member/2, memberchk/2] from the built-in 'lists' library.
:- use_module(library(lists),     [member/2, memberchk/2]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% Declare 'causal_event/4.     % Id, Type(past|future|planned), Desc, Likelihood' as dynamic — its facts may be added or removed at runtime.
:- dynamic causal_event/4.     % Id, Type(past|future|planned), Desc, Likelihood
% Declare 'causal_link/2.      % CauseId, EffectId' as dynamic — its facts may be added or removed at runtime.
:- dynamic causal_link/2.      % CauseId, EffectId
% Declare 'appraisal_record/5. % EventId, Desirability, Attribution, Controllability, Intensity' as dynamic — its facts may be added or removed at runtime.
:- dynamic appraisal_record/5. % EventId, Desirability, Attribution, Controllability, Intensity
% Declare 'event_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic event_id_counter/1.
% State the fact: event id counter(0).
event_id_counter(0).

% State a fact for 'controllability threshold' with the arguments listed below.
controllability_threshold(0.5).  % above this → problem-focused
% State the fact: emotion decay rate(0.1).
emotion_decay_rate(0.1).

% Define a clause for 'next event id': succeed when the following conditions hold.
next_event_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(event_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(event_id_counter(N1)),
    % Check that 'Id' is unifiable with 'N1'.
    Id = N1.

% ---------------------------------------------------------------------------
% pai_causal_model/1
%
%   Assert an event into the causal interpretation.
%   Event = event(Type, Desc, Likelihood) | causal_link(CauseDesc, EffectDesc)
% ---------------------------------------------------------------------------

% Define a clause for 'pai causal model': succeed when the following conditions hold.
pai_causal_model(event(Type, Desc, Likelihood)) :-
    % State a fact for 'next event id' with the arguments listed below.
    next_event_id(Id),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(causal_event(Id, Type, Desc, Likelihood)).

% Define a clause for 'pai causal model': succeed when the following conditions hold.
pai_causal_model(causal_link(CauseDesc, EffectDesc)) :-
    % Check that '( causal_event(CId, _, CauseDesc, _) -> true ; CId' is unifiable with 'unknown )'.
    ( causal_event(CId, _, CauseDesc, _) -> true ; CId = unknown ),
    % Check that '( causal_event(EId, _, EffectDesc, _) -> true ; EId' is unifiable with 'unknown )'.
    ( causal_event(EId, _, EffectDesc, _) -> true ; EId = unknown ),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(causal_link(CId, EId)).

% ---------------------------------------------------------------------------
% pai_appraise/3
%
%   Appraise an event against a list of active Goals.
%   Goals: list of goal(Desc, Polarity) where Polarity = positive | negative.
%
%   Desirability: +1 if event matches a positive goal, -1 if negative, 0 else.
%   Likelihood:   from causal_event, or 0.5 default.
%   Attribution:  event_attribution/2 rule (below).
%   Controllability: depends on attribution and type.
%
%   Returns: appraisal(Event, Desirability, Likelihood, Attribution,
%                       Controllability, Intensity)
%   Intensity = abs(Desirability) * Likelihood
% ---------------------------------------------------------------------------

% Define a clause for 'pai appraise': succeed when the following conditions hold.
pai_appraise(Event, Goals, Appraisal) :-
    % State a fact for 'event desirability' with the arguments listed below.
    event_desirability(Event, Goals, Desirability),
    % State a fact for 'event likelihood' with the arguments listed below.
    event_likelihood(Event, Likelihood),
    % State a fact for 'event attribution' with the arguments listed below.
    event_attribution(Event, Attribution),
    % State a fact for 'event controllability' with the arguments listed below.
    event_controllability(Event, Attribution, Controllability),
    % Evaluate the arithmetic expression 'abs(Desirability) * Likelihood' and bind the result to 'Intensity'.
    Intensity is abs(Desirability) * Likelihood,
    % Check that 'Appraisal' is unifiable with 'appraisal(Event, Desirability, Likelihood'.
    Appraisal = appraisal(Event, Desirability, Likelihood,
                           % Continue the multi-line expression started above.
                           Attribution, Controllability, Intensity),
    % Record for later retrieval and decay
    % Execute: ( causal_event(Id, _, Event, _).
    ( causal_event(Id, _, Event, _)
    % If the condition above succeeded, perform the following action.
    ->  retractall(appraisal_record(Id, _, _, _, _)),
        % Continue the multi-line expression started above.
        assertz(appraisal_record(Id, Desirability, Attribution,
                                  % Continue the multi-line expression started above.
                                  Controllability, Intensity))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% Define a clause for 'event desirability': succeed when the following conditions hold.
event_desirability(Event, Goals, Desirability) :-
    % Execute: ( memberchk(goal(Event, positive), Goals).
    ( memberchk(goal(Event, positive), Goals)
    % If the condition above succeeded, perform the following action.
    ->  Desirability = 1.0
    % Otherwise (else branch), perform the following action.
    ;   memberchk(goal(Event, negative), Goals)
    % If the condition above succeeded, perform the following action.
    ->  Desirability = -1.0
    % Otherwise (else branch), perform the following action.
    ;   Desirability = 0.0
    % Close the expression opened above.
    ).

% Define a clause for 'event likelihood': succeed when the following conditions hold.
event_likelihood(Event, Likelihood) :-
    % Execute: ( causal_event(_, _, Event, L).
    ( causal_event(_, _, Event, L)
    % If the condition above succeeded, perform the following action.
    ->  Likelihood = L
    % Otherwise (else branch), perform the following action.
    ;   Likelihood = 0.5
    % Close the expression opened above.
    ).

% Define a clause for 'event attribution': succeed when the following conditions hold.
event_attribution(Event, Attribution) :-
    % Execute: ( causal_event(Id, past, Event, _).
    ( causal_event(Id, past, Event, _)
    % If the condition above succeeded, perform the following action.
    ->  ( causal_link(self, Id) -> Attribution = self ; Attribution = other )
    % Otherwise (else branch), perform the following action.
    ;   causal_event(_, future, Event, _)
    % If the condition above succeeded, perform the following action.
    ->  Attribution = self   % agent plans future events; default = self
    % Otherwise (else branch), perform the following action.
    ;   Attribution = unknown
    % Close the expression opened above.
    ).

% Define a clause for 'event controllability': succeed when the following conditions hold.
event_controllability(Event, Attribution, Controllability) :-
    % Execute: ( causal_event(_, future, Event, _).
    ( causal_event(_, future, Event, _)
    % If the condition above succeeded, perform the following action.
    ->  % Future events: controllable when attributed to self
        % Continue the multi-line expression started above.
        ( Attribution = self -> Controllability = 0.8 ; Controllability = 0.3 )
    % Otherwise (else branch), perform the following action.
    ;   % Past events: uncontrollable (already happened)
        % Continue the multi-line expression started above.
        Controllability = 0.2
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_cope_select/3
%
%   Opts: [safety_critical(Event)] → emotion-focused coping may not deny that event
%
%   CopingStrategy:
%     problem_focused(plan_action(Event))    — plan to change the world
%     emotion_focused(re_appraise(Event))    — shift attention / re-appraise
%     emotion_focused(adjust_desirability(Event, NewD)) — adjust goal weight
% ---------------------------------------------------------------------------

% Define a clause for 'pai cope select': succeed when the following conditions hold.
pai_cope_select(Appraisal, Opts, CopingStrategy) :-
    % Check that 'Appraisal' is unifiable with 'appraisal(Event, Desirability, _Likelihood'.
    Appraisal = appraisal(Event, Desirability, _Likelihood,
                           % Continue the multi-line expression started above.
                           _Attribution, Controllability, _Intensity),
    % State a fact for 'controllability threshold' with the arguments listed below.
    controllability_threshold(Threshold),
    % Check that '( Controllability' is greater than or equal to 'Threshold'.
    ( Controllability >= Threshold
    % If the condition above succeeded, perform the following action.
    ->  CopingStrategy = problem_focused(plan_action(Event))
    % Otherwise (else branch), perform the following action.
    ;   % Emotion-focused: never deny safety-critical facts
        % Continue the multi-line expression started above.
        ( memberchk(safety_critical(Event), Opts)
        % If the condition above succeeded, perform the following action.
        ->  % Can re-appraise desirability magnitude but not the fact itself
            % Continue the multi-line expression started above.
            NewD is Desirability * 0.7,
            % Continue the multi-line expression started above.
            CopingStrategy = emotion_focused(adjust_desirability(Event, NewD))
        % Otherwise (else branch), perform the following action.
        ;   CopingStrategy = emotion_focused(re_appraise(Event))
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_emotion_from_appraisal/2
%
%   Map appraisal to an emotion label and intensity.
%   Simplified OCC-style mapping:
%     Desirability > 0, Attribution=self  → pride(Intensity)
%     Desirability > 0, Attribution=other → admiration(Intensity)
%     Desirability < 0, Attribution=self  → shame(Intensity)
%     Desirability < 0, Attribution=other → anger(Intensity)
%     Desirability = 0                    → neutral(0.0)
% ---------------------------------------------------------------------------

% Define a clause for 'pai emotion from appraisal': succeed when the following conditions hold.
pai_emotion_from_appraisal(Appraisal, Emotion) :-
    % Check that 'Appraisal' is unifiable with 'appraisal(_, Desirability, _, Attribution, _, Intensity)'.
    Appraisal = appraisal(_, Desirability, _, Attribution, _, Intensity),
    % Check that '( Desirability' is greater than '0.0, Attribution = self   -> Emotion = pride(Intensity)'.
    ( Desirability > 0.0, Attribution = self   -> Emotion = pride(Intensity)
    % Otherwise (else branch), perform the following action.
    ; Desirability > 0.0                       -> Emotion = admiration(Intensity)
    % Otherwise (else branch), perform the following action.
    ; Desirability < 0.0, Attribution = self   -> Emotion = shame(Intensity)
    % Otherwise (else branch), perform the following action.
    ; Desirability < 0.0                       -> Emotion = anger(Intensity)
    % Otherwise (else branch), perform the following action.
    ;                                             Emotion = neutral(0.0)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_appraisal_decay/0 — decay all recorded emotion intensities
% ---------------------------------------------------------------------------

% Execute: pai_appraisal_decay :-.
pai_appraisal_decay :-
    % State a fact for 'emotion decay rate' with the arguments listed below.
    emotion_decay_rate(Rate),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id-D-A-C-I, appraisal_record(Id, D, A, C, I), All),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        member(Id-D-A-C-I, All),
        % Continue the multi-line expression started above.
        ( retract(appraisal_record(Id, D, A, C, I)),
          % Continue the multi-line expression started above.
          NewI is max(0.0, I * (1.0 - Rate)),
          % Continue the multi-line expression started above.
          assertz(appraisal_record(Id, D, A, C, NewI))
        % Close the expression opened above.
        )
    % Close the expression opened above.
    ).
