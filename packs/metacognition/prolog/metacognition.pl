/*  PrologAI — Causalontology Metacognition  (WP-413, Layer 388)

    A mind must watch itself work. THE_BUILDING_FILES insist on a reflective loop
    that tracks how well each strategy is doing, notices the tell-tale of being
    stuck — error that stays high while nothing improves — and decides whether to
    keep going, switch approach, or ask for help. The co_ family had an efficiency
    governor (efficiency_governor) but no self-monitor of this kind; this pack is it.

    The system reports the OUTCOME of each attempt under a named strategy:

        attempt(Strategy, success)   or   attempt(Strategy, failure)

    From the log this pack derives:

      calibration   a strategy's success rate, successes over attempts
      confusion     a strategy with enough attempts and a rate at or below a
                    low threshold — it is failing and not improving
      progress      the trend across all attempts in order: are later attempts
                    succeeding more than earlier ones (improving), the same
                    (flat), or fewer (declining)?

    and a single RECOMMENDATION: use the best-calibrated strategy if one is good
    enough; otherwise, if the mind has tried and is not progressing, seek
    guidance; otherwise explore.

    Predicates:
      metacognition_reset/0            -- forget the log, restore default thresholds
      metacognition_set_thresholds/3   -- +MinAttempts, +ConfusionRate, +GoodRate
      metacognition_thresholds/3       -- ?MinAttempts, ?ConfusionRate, ?GoodRate
      metacognition_attempt/2          -- +Strategy, +Outcome   (Outcome = success | failure)
      metacognition_stats/3            -- ?Strategy, -Attempts, -Successes
      metacognition_calibration/2      -- +Strategy, -Rate      (successes/attempts, 0 if none)
      metacognition_best_strategy/2    -- -Strategy, -Rate       (best-calibrated tried strategy)
      metacognition_confused/1         -- ?Strategy             (enough attempts, low rate)
      metacognition_progress/1         -- -Trend                (improving | flat | declining)
      metacognition_recommend/1        -- -Recommendation        (use(S) | seek_guidance | explore)
      metacognition_count/1            -- -N                     (total attempts logged)
*/

% Declare this module and its exported predicates.
:- module(metacognition, [
    % metacognition_reset/0: forget the log and restore thresholds.
    metacognition_reset/0,
    % metacognition_set_thresholds/3: set the three metacognitive thresholds.
    metacognition_set_thresholds/3,
    % metacognition_thresholds/3: read the three thresholds.
    metacognition_thresholds/3,
    % metacognition_attempt/2: record the outcome of one attempt.
    metacognition_attempt/2,
    % metacognition_stats/3: attempts and successes for a strategy.
    metacognition_stats/3,
    % metacognition_calibration/2: a strategy's success rate.
    metacognition_calibration/2,
    % metacognition_best_strategy/2: the best-calibrated tried strategy.
    metacognition_best_strategy/2,
    % metacognition_confused/1: strategies failing without progress.
    metacognition_confused/1,
    % metacognition_progress/1: the overall learning trend.
    metacognition_progress/1,
    % metacognition_recommend/1: keep, switch, or seek guidance.
    metacognition_recommend/1,
    % metacognition_count/1: total attempts logged.
    metacognition_count/1
]).

% Use the list library.
:- use_module(library(lists)).

% outcome/3 logs Seq, Strategy, Won(1/0); it grows at runtime, so it is dynamic.
:- dynamic outcome/3.
% metacognition_seq/1 is the rising sequence counter for ordering the log.
:- dynamic metacognition_seq/1.
% thresholds/3 holds MinAttempts, ConfusionRate, GoodRate; dynamic for tuning.
:- dynamic thresholds/3.

% metacognition_reset/0: clear the log, restart the counter, restore default thresholds.
metacognition_reset :-
    % Remove the whole outcome log.
    retractall(outcome(_,_,_)),
    % Remove the counter.
    retractall(metacognition_seq(_)),
    % Seed the counter at zero.
    assertz(metacognition_seq(0)),
    % Remove any thresholds.
    retractall(thresholds(_,_,_)),
    % Defaults: need 3 attempts to judge; <=0.34 is confused; >=0.6 is good.
    assertz(thresholds(3, 0.34, 0.6)).

% metacognition_set_thresholds/3: replace the three thresholds.
metacognition_set_thresholds(Min, Conf, Good) :-
    % Drop the old thresholds.
    retractall(thresholds(_,_,_)),
    % Store the new ones.
    assertz(thresholds(Min, Conf, Good)).

% metacognition_thresholds/3: read the thresholds, defaulting if unset.
metacognition_thresholds(Min, Conf, Good) :-
    % Read them or fall back to the defaults.
    ( thresholds(M, C, G) -> Min = M, Conf = C, Good = G
    ; Min = 3, Conf = 0.34, Good = 0.6 ).

% metacognition_tick/1: consume the next sequence stamp.
metacognition_tick(Next) :-
    % Read and advance the counter.
    retract(metacognition_seq(Now)),
    Next is Now + 1,
    assertz(metacognition_seq(Next)).

% metacognition_attempt/2: record one attempt's outcome under a strategy.
metacognition_attempt(Strategy, Outcome) :-
    % Map the symbolic outcome onto a one-or-zero win flag.
    ( Outcome == success -> Won = 1 ; Won = 0 ),
    % Stamp it with the next sequence number.
    metacognition_tick(Seq),
    % Log the outcome.
    assertz(outcome(Seq, Strategy, Won)).

% metacognition_stats/3: total attempts and successes for a strategy.
metacognition_stats(Strategy, Attempts, Successes) :-
    % A strategy is any that appears in the log.
    ( var(Strategy) -> outcome(_, Strategy, _) ; true ),
    % Count its attempts.
    aggregate_all(count, outcome(_, Strategy, _), Attempts),
    % Sum its wins.
    aggregate_all(sum(W), outcome(_, Strategy, W), Successes).

% metacognition_calibration/2: a strategy's success rate, or zero with no attempts.
metacognition_calibration(Strategy, Rate) :-
    % Gather its attempts and successes.
    metacognition_stats(Strategy, Attempts, Successes),
    % Rate is successes over attempts; no attempts means a zero rate.
    ( Attempts =:= 0 -> Rate = 0.0 ; Rate is Successes / Attempts ).

% metacognition_best_strategy/2: the tried strategy with the highest success rate.
metacognition_best_strategy(Strategy, Rate) :-
    % Rank every distinct tried strategy by its rate.
    findall(R-S,
            ( setof(St, A^W^outcome(A, St, W), Strategies),
              member(S, Strategies),
              metacognition_calibration(S, R) ),
            Pairs),
    % There must be at least one tried strategy.
    Pairs = [_|_],
    % Sort by rate descending, keeping ties, and take the head.
    sort(1, @>=, Pairs, [Rate-Strategy|_]).

% metacognition_confused/1: a strategy with enough attempts and a rate at or below the low mark.
metacognition_confused(Strategy) :-
    % Read the min-attempts and confusion thresholds.
    metacognition_thresholds(Min, Conf, _),
    % Consider each distinct tried strategy.
    setof(St, A^W^outcome(A, St, W), Strategies),
    member(Strategy, Strategies),
    % It must have been tried enough to judge.
    metacognition_stats(Strategy, Attempts, _),
    Attempts >= Min,
    % Its success rate must be at or below the confusion threshold.
    metacognition_calibration(Strategy, Rate),
    Rate =< Conf.

% metacognition_progress/1: compare the earlier and later halves of the ordered log.
metacognition_progress(Trend) :-
    % Collect wins in sequence order.
    findall(W, ( order_key(K), outcome(K, _, W) ), Wins),
    % Judge the trend from the two halves.
    metacognition_trend(Wins, Trend).

% metacognition_recommend/1: keep the best strategy, seek guidance, or explore.
metacognition_recommend(Recommendation) :-
    % Read the good-rate threshold.
    metacognition_thresholds(_, _, Good),
    % Prefer a strategy that is good enough.
    ( metacognition_best_strategy(S, Rate), Rate >= Good
      -> Recommendation = use(S)
    % Otherwise, if the mind has tried and is not improving, ask for help.
    ; metacognition_count(N), N > 0, metacognition_progress(Trend), Trend \== improving
      -> Recommendation = seek_guidance
    % Otherwise there is nothing to lean on yet: explore.
    ; Recommendation = explore ).

% metacognition_count/1: how many attempts are logged in total.
metacognition_count(N) :-
    % Count the outcome facts.
    aggregate_all(count, outcome(_,_,_), N).

% ---- small internal helpers ------------------------------------------------

% order_key/1: enumerate the log's sequence stamps in ascending order.
order_key(K) :-
    % Collect and sort the distinct stamps, then hand them out one by one.
    findall(S, outcome(S, _, _), Ss),
    sort(Ss, Sorted),
    member(K, Sorted).

% metacognition_trend/2: improving, flat, or declining across the ordered win list.
metacognition_trend(Wins, Trend) :-
    % A trend needs at least two data points.
    length(Wins, L),
    ( L < 2
      -> Trend = flat
      ;  Half is L // 2,
         % Split into an earlier half and a later half.
         length(First, Half),
         append(First, Second, Wins),
         % Compare their average success.
         metacognition_mean(First, M1),
         metacognition_mean(Second, M2),
         % A clear rise is improving; a clear fall is declining; else flat.
         ( M2 > M1 + 0.05 -> Trend = improving
         ; M2 < M1 - 0.05 -> Trend = declining
         ;                    Trend = flat ) ).

% metacognition_mean/2: the mean of a list of numbers, zero for the empty list.
metacognition_mean([], 0.0).
% A non-empty list averages its sum over its length.
metacognition_mean([X|Xs], Mean) :-
    sum_list([X|Xs], Sum),
    length([X|Xs], N),
    Mean is Sum / N.
