/*  PrologAI — Causalontology Affect  (WP-412, Layer 387)

    THE_BUILDING_FILES argue that feeling is not decoration: it steers attention
    and pre-selects choices before slow deliberation, and it tells the mind
    whether it is coping. No co_ pack assigned good/bad or calm/aroused values to
    events; this pack does, on two plain axes.

    Appraising an EVENT takes two readings the rest of the system can supply:

        goal_congruence   how well the event served the current goal, in [-1, 1]
        expectedness      how expected it was, in [0, 1]

    and yields two feelings:

        valence   how good or bad it felt, in [-1, 1]  (tracks goal congruence)
        arousal   how activating it was,   in [0, 1]   (rises with surprise and
                  with the strength of the feeling)

    Every appraisal is remembered against its event key, so an option the mind is
    considering can be PRE-FLAVOURED by the feeling of the last similar outcome —
    the glass-box analogue of a somatic marker that biases choice before
    deliberation. A running TEMPERAMENT (the mean valence and arousal so far) is
    the mind's mood, and a COPING signal reads that mood as thriving, steady, or
    struggling.

    Predicates:
      tp_reset/0            -- forget all appraisals and the temperament
      tp_appraise/4         -- +Event, +GoalCongruence, +Expectedness, -appraisal(V,A)
      tp_appraisal/3        -- ?Event, ?Valence, ?Arousal   (last stored feeling)
      tp_temper/2           -- -Valence, -Arousal           (the running mood)
      tp_flavor/2           -- +Option, -Bias               (remembered valence, else 0)
      tp_prefer/3           -- +Options, -Best, -Bias        (pick the best-felt option)
      tp_coping/1           -- -Signal                      (thriving|steady|struggling)
      tp_count/1            -- -N                            (how many appraisals held)
*/

% Declare this module and its exported predicates.
:- module(co_temper, [
    % tp_reset/0: forget all appraisals and reset the temperament.
    tp_reset/0,
    % tp_appraise/4: appraise an event into valence and arousal.
    tp_appraise/4,
    % tp_appraisal/3: read the last stored feeling of an event.
    tp_appraisal/3,
    % tp_temper/2: the running mood (mean valence and arousal).
    tp_temper/2,
    % tp_flavor/2: the remembered valence of an option, else zero.
    tp_flavor/2,
    % tp_prefer/3: choose the option that feels best.
    tp_prefer/3,
    % tp_coping/1: read the mood as a coping signal.
    tp_coping/1,
    % tp_count/1: how many appraisals are held.
    tp_count/1
]).

% Use the list library.
:- use_module(library(lists)).

% affect/3 stores one event's last feeling; it changes at runtime, so it is dynamic.
:- dynamic affect/3.
% mood/3 accumulates SumValence, SumArousal, and Count for the running temperament.
:- dynamic mood/3.

% tp_reset/0: forget every stored feeling and restart the mood accumulator.
tp_reset :-
    % Remove all per-event feelings.
    retractall(affect(_,_,_)),
    % Remove any mood accumulator.
    retractall(mood(_,_,_)),
    % Seed the accumulator empty: no valence, no arousal, no samples.
    assertz(mood(0.0, 0.0, 0)).

% tp_appraise/4: turn two readings into a valence and an arousal, and remember them.
tp_appraise(Event, GoalCongruence, Expectedness, appraisal(V, A)) :-
    % Valence tracks goal congruence, clamped into the legal band.
    tp_clamp(GoalCongruence, -1, 1, V),
    % Surprise is how unexpected the event was.
    Surprise is 1 - Expectedness,
    % Arousal rises with surprise and with the strength of the feeling.
    A0 is 0.5*Surprise + 0.5*abs(V),
    % Clamp arousal into [0, 1].
    tp_clamp(A0, 0, 1, A),
    % Remember this event's feeling, replacing any earlier one.
    retractall(affect(Event, _, _)),
    assertz(affect(Event, V, A)),
    % Fold the new feeling into the running temperament.
    tp_accumulate(V, A).

% tp_appraisal/3: read back the last stored feeling of an event.
tp_appraisal(Event, V, A) :-
    % Look up the stored feeling.
    affect(Event, V, A).

% tp_temper/2: the running mood is the mean valence and mean arousal so far.
tp_temper(V, A) :-
    % Read the accumulator.
    mood(SumV, SumA, N),
    % With no samples the mood is neutral; otherwise take the means.
    ( N =:= 0
      -> V = 0.0, A = 0.0
      ;  V is SumV / N, A is SumA / N ).

% tp_flavor/2: the remembered valence of an option, or zero if never felt.
tp_flavor(Option, Bias) :-
    % Use the stored feeling if there is one, else a neutral zero.
    ( affect(Option, V, _) -> Bias = V ; Bias = 0.0 ).

% tp_prefer/3: from a list of options, choose the one that feels best.
tp_prefer(Options, Best, Bias) :-
    % A non-empty option list is required.
    Options = [_|_],
    % Pair each option with its remembered feeling.
    findall(B-O, ( member(O, Options), tp_flavor(O, B) ), Pairs),
    % Sort by feeling descending, keeping ties in list order.
    sort(1, @>=, Pairs, [Bias-Best|_]).

% tp_coping/1: read the running mood as a simple coping signal.
tp_coping(Signal) :-
    % Look at the current temperament valence.
    tp_temper(V, _),
    % A clearly positive mood is thriving; clearly negative is struggling.
    ( V >  0.2 -> Signal = thriving
    ; V < -0.2 -> Signal = struggling
    ;             Signal = steady ).

% tp_count/1: how many events have a stored feeling.
tp_count(N) :-
    % Count the affect facts.
    aggregate_all(count, affect(_,_,_), N).

% ---- small internal helpers ------------------------------------------------

% tp_accumulate/2: fold one feeling into the running mood accumulator.
tp_accumulate(V, A) :-
    % Retract the current totals.
    retract(mood(SumV, SumA, N)),
    % Add this sample.
    SumV1 is SumV + V,
    SumA1 is SumA + A,
    N1 is N + 1,
    % Re-assert the updated totals.
    assertz(mood(SumV1, SumA1, N1)).

% tp_clamp/4: constrain a value X to lie within [Lo, Hi].
tp_clamp(X, Lo, Hi, Y) :-
    % Push up to at least Lo, then down to at most Hi.
    Y0 is max(X, Lo),
    Y is min(Y0, Hi).
