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

:- module(appraisal, [
    pai_causal_model/1,
    pai_appraise/3,
    pai_cope_select/3,
    pai_emotion_from_appraisal/2,
    pai_appraisal_decay/0
]).

:- use_module(library(lists),     [member/2, memberchk/2]).
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

:- dynamic causal_event/4.     % Id, Type(past|future|planned), Desc, Likelihood
:- dynamic causal_link/2.      % CauseId, EffectId
:- dynamic appraisal_record/5. % EventId, Desirability, Attribution, Controllability, Intensity
:- dynamic event_id_counter/1.
event_id_counter(0).

controllability_threshold(0.5).  % above this → problem-focused
emotion_decay_rate(0.1).

next_event_id(Id) :-
    retract(event_id_counter(N)),
    N1 is N + 1,
    assertz(event_id_counter(N1)),
    Id = N1.

% ---------------------------------------------------------------------------
% pai_causal_model/1
%
%   Assert an event into the causal interpretation.
%   Event = event(Type, Desc, Likelihood) | causal_link(CauseDesc, EffectDesc)
% ---------------------------------------------------------------------------

pai_causal_model(event(Type, Desc, Likelihood)) :-
    next_event_id(Id),
    assertz(causal_event(Id, Type, Desc, Likelihood)).

pai_causal_model(causal_link(CauseDesc, EffectDesc)) :-
    ( causal_event(CId, _, CauseDesc, _) -> true ; CId = unknown ),
    ( causal_event(EId, _, EffectDesc, _) -> true ; EId = unknown ),
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

pai_appraise(Event, Goals, Appraisal) :-
    event_desirability(Event, Goals, Desirability),
    event_likelihood(Event, Likelihood),
    event_attribution(Event, Attribution),
    event_controllability(Event, Attribution, Controllability),
    Intensity is abs(Desirability) * Likelihood,
    Appraisal = appraisal(Event, Desirability, Likelihood,
                           Attribution, Controllability, Intensity),
    % Record for later retrieval and decay
    ( causal_event(Id, _, Event, _)
    ->  retractall(appraisal_record(Id, _, _, _, _)),
        assertz(appraisal_record(Id, Desirability, Attribution,
                                  Controllability, Intensity))
    ;   true
    ).

event_desirability(Event, Goals, Desirability) :-
    ( memberchk(goal(Event, positive), Goals)
    ->  Desirability = 1.0
    ;   memberchk(goal(Event, negative), Goals)
    ->  Desirability = -1.0
    ;   Desirability = 0.0
    ).

event_likelihood(Event, Likelihood) :-
    ( causal_event(_, _, Event, L)
    ->  Likelihood = L
    ;   Likelihood = 0.5
    ).

event_attribution(Event, Attribution) :-
    ( causal_event(Id, past, Event, _)
    ->  ( causal_link(self, Id) -> Attribution = self ; Attribution = other )
    ;   causal_event(_, future, Event, _)
    ->  Attribution = self   % agent plans future events; default = self
    ;   Attribution = unknown
    ).

event_controllability(Event, Attribution, Controllability) :-
    ( causal_event(_, future, Event, _)
    ->  % Future events: controllable when attributed to self
        ( Attribution = self -> Controllability = 0.8 ; Controllability = 0.3 )
    ;   % Past events: uncontrollable (already happened)
        Controllability = 0.2
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

pai_cope_select(Appraisal, Opts, CopingStrategy) :-
    Appraisal = appraisal(Event, Desirability, _Likelihood,
                           _Attribution, Controllability, _Intensity),
    controllability_threshold(Threshold),
    ( Controllability >= Threshold
    ->  CopingStrategy = problem_focused(plan_action(Event))
    ;   % Emotion-focused: never deny safety-critical facts
        ( memberchk(safety_critical(Event), Opts)
        ->  % Can re-appraise desirability magnitude but not the fact itself
            NewD is Desirability * 0.7,
            CopingStrategy = emotion_focused(adjust_desirability(Event, NewD))
        ;   CopingStrategy = emotion_focused(re_appraise(Event))
        )
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

pai_emotion_from_appraisal(Appraisal, Emotion) :-
    Appraisal = appraisal(_, Desirability, _, Attribution, _, Intensity),
    ( Desirability > 0.0, Attribution = self   -> Emotion = pride(Intensity)
    ; Desirability > 0.0                       -> Emotion = admiration(Intensity)
    ; Desirability < 0.0, Attribution = self   -> Emotion = shame(Intensity)
    ; Desirability < 0.0                       -> Emotion = anger(Intensity)
    ;                                             Emotion = neutral(0.0)
    ).

% ---------------------------------------------------------------------------
% pai_appraisal_decay/0 — decay all recorded emotion intensities
% ---------------------------------------------------------------------------

pai_appraisal_decay :-
    emotion_decay_rate(Rate),
    findall(Id-D-A-C-I, appraisal_record(Id, D, A, C, I), All),
    forall(
        member(Id-D-A-C-I, All),
        ( retract(appraisal_record(Id, D, A, C, I)),
          NewI is max(0.0, I * (1.0 - Rate)),
          assertz(appraisal_record(Id, D, A, C, NewI))
        )
    ).
