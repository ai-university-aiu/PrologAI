/*  PrologAI — Causalontology Regulation  (WP-423, Layer 398)

    THE_BUILDING_FILES describe how a mind improves a behaviour from feedback.
    Two ideas sit at the centre. First, feedback comes in four flavours, set by
    whether the result was expected and whether it was good: a success you
    predicted is CONFIRMING, a failure you predicted is DISAPPOINTING, a success
    you did not predict is SERENDIPITOUS, and a failure you did not predict is
    SHOCKING. Second, when one behaviour both succeeds and fails, the fix is not
    to average it away but to SPLIT it — to find the feature of the situation that
    separates the wins from the losses, and refine the rule to require (or avoid)
    it. That is discrimination learning. causal_learning induces causal relations and
    co_gauge watches whole strategies; this pack refines an individual behaviour.

    A behaviour is a rule:

        rule(RuleId, Action, Context)        Context a feature list, or `any`

    Feedback records the outcome and the situation it happened in:

        trial(RuleId, success|failure, ObservedContext)

    From the trials the pack derives a reliability, classifies the newest result
    into one of the four flavours, notices when a rule needs discriminating, and
    proposes the discriminating feature and a refined context.

    Predicates:
      regulation_reset/0            -- forget all rules and trials
      regulation_rule_add/3         -- +RuleId, +Action, +Context
      regulation_rule/3             -- ?RuleId, ?Action, ?Context
      regulation_feedback/3         -- +RuleId, +Outcome, +ObservedContext   (record a trial)
      regulation_stats/3            -- +RuleId, -Successes, -Attempts
      regulation_reliability/2      -- +RuleId, -Reliability                 (successes/attempts)
      regulation_classify/3         -- +RuleId, +Outcome, -Flavour           (the four flavours)
      regulation_needs_discrimination/1 -- +RuleId                           (both wins and losses)
      regulation_discriminate/2     -- +RuleId, -Discriminator               (or none)
      regulation_refine/3           -- +RuleId, +Discriminator, -RefinedContext
*/

% Declare this module and its exported predicates.
:- module(regulation, [
    % regulation_reset/0: forget all rules and trials.
    regulation_reset/0,
    % regulation_rule_add/3: register a behaviour rule.
    regulation_rule_add/3,
    % regulation_rule/3: query behaviour rules.
    regulation_rule/3,
    % regulation_feedback/3: record the outcome of one trial.
    regulation_feedback/3,
    % regulation_stats/3: successes and attempts for a rule.
    regulation_stats/3,
    % regulation_reliability/2: a rule's success rate.
    regulation_reliability/2,
    % regulation_classify/3: classify a result into one of the four flavours.
    regulation_classify/3,
    % regulation_needs_discrimination/1: a rule with both wins and losses.
    regulation_needs_discrimination/1,
    % regulation_discriminate/2: the feature that separates wins from losses.
    regulation_discriminate/2,
    % regulation_refine/3: the refined context implied by a discriminator.
    regulation_refine/3
]).

% Use the list library.
:- use_module(library(lists)).

% rule/3 is a registered behaviour; it changes at runtime, so it is dynamic.
:- dynamic rule/3.
% trial/3 is one recorded outcome in its observed context; dynamic.
:- dynamic trial/3.

% regulation_reset/0: forget every rule and every trial.
regulation_reset :-
    % Remove all rules.
    retractall(rule(_,_,_)),
    % Remove all trials.
    retractall(trial(_,_,_)).

% regulation_rule_add/3: register a behaviour rule, replacing any earlier one for the id.
regulation_rule_add(RuleId, Action, Context) :-
    % Drop any previous rule under this id.
    retractall(rule(RuleId, _, _)),
    % Store the new rule.
    assertz(rule(RuleId, Action, Context)).

% regulation_rule/3: expose the registered rules.
regulation_rule(RuleId, Action, Context) :-
    % Read the stored rule.
    rule(RuleId, Action, Context).

% regulation_feedback/3: record one trial's outcome and the situation it occurred in.
regulation_feedback(RuleId, Outcome, ObservedContext) :-
    % Normalise the observed context into a sorted set.
    sort(ObservedContext, Sorted),
    % Log the trial.
    assertz(trial(RuleId, Outcome, Sorted)).

% regulation_stats/3: total successes and attempts for a rule.
regulation_stats(RuleId, Successes, Attempts) :-
    % Count every trial for the rule.
    aggregate_all(count, trial(RuleId, _, _), Attempts),
    % Count the successful ones.
    aggregate_all(count, trial(RuleId, success, _), Successes).

% regulation_reliability/2: a rule's success rate, or zero with no attempts.
regulation_reliability(RuleId, Reliability) :-
    % Gather the tallies.
    regulation_stats(RuleId, Successes, Attempts),
    % Rate is successes over attempts; no attempts means a zero rate.
    ( Attempts =:= 0 -> Reliability = 0.0 ; Reliability is Successes / Attempts ).

% regulation_classify/3: classify a result, given what the current reliability predicted.
regulation_classify(RuleId, Outcome, Flavour) :-
    % With no history there is nothing to expect: the result is novel.
    regulation_stats(RuleId, _, Attempts),
    ( Attempts =:= 0
      -> Flavour = novel
      ;  % Predict success when the rule has been more reliable than not.
         regulation_reliability(RuleId, Rel),
         ( Rel >= 0.5 -> Predicted = success ; Predicted = failure ),
         % Name the flavour from the predicted and the actual outcome (one answer).
         once(regulation_flavour(Predicted, Outcome, Flavour)) ).

% regulation_flavour/3: the four-flavour table over predicted and actual outcome.
% A predicted success that happens is confirming.
regulation_flavour(success, success, confirming).
% A predicted success that fails is shocking.
regulation_flavour(success, failure, shocking).
% A predicted failure that nonetheless succeeds is serendipitous.
regulation_flavour(failure, success, serendipitous).
% A predicted failure that indeed fails is disappointing.
regulation_flavour(failure, failure, disappointing).

% regulation_needs_discrimination/1: a rule that has both a success and a failure.
regulation_needs_discrimination(RuleId) :-
    % There is at least one success,
    trial(RuleId, success, _),
    % and at least one failure — the rule is context-sensitive.
    trial(RuleId, failure, _).

% regulation_discriminate/2: the feature that best separates the wins from the losses.
regulation_discriminate(RuleId, Discriminator) :-
    % Prefer a feature present in every win and no loss.
    ( regulation_split_feature(RuleId, success, failure, F)
      -> Discriminator = discriminator(F, present_predicts(success))
    % Else a feature present in every loss and no win.
    ; regulation_split_feature(RuleId, failure, success, F)
      -> Discriminator = discriminator(F, present_predicts(failure))
    % Else nothing separates them.
    ; Discriminator = none ).

% regulation_refine/3: the refined context a discriminator implies for a rule.
regulation_refine(RuleId, discriminator(F, present_predicts(Which)), RefinedContext) :-
    % Start from the rule's current context (an `any` context is empty).
    regulation_base_context(RuleId, Base),
    % A success-predicting feature is required; a failure-predicting one is shunned.
    ( Which == success
      -> sort([F | Base], RefinedContext)
      ;  sort([not(F) | Base], RefinedContext) ).

% ---- internal --------------------------------------------------------------

% regulation_split_feature/4: a feature in every InCtx trial and no OutCtx trial.
regulation_split_feature(RuleId, InOutcome, OutOutcome, Feature) :-
    % The contexts of the "in" outcome (which must be non-empty).
    regulation_contexts(RuleId, InOutcome, InCtxs),
    InCtxs = [_|_],
    % The contexts of the "out" outcome.
    regulation_contexts(RuleId, OutOutcome, OutCtxs),
    % Consider every feature seen under the rule, in a stable order.
    regulation_all_features(RuleId, Feats),
    member(Feature, Feats),
    % It must appear in every "in" context,
    forall(member(C, InCtxs), memberchk(Feature, C)),
    % and in none of the "out" contexts.
    forall(member(C, OutCtxs), \+ memberchk(Feature, C)),
    % Commit to the first such feature.
    !.

% regulation_contexts/3: the observed contexts of a rule's trials with a given outcome.
regulation_contexts(RuleId, Outcome, Contexts) :-
    % Collect the contexts of matching trials.
    findall(C, trial(RuleId, Outcome, C), Contexts).

% regulation_all_features/2: every distinct feature seen across a rule's trials.
regulation_all_features(RuleId, Feats) :-
    % Gather features from every trial's context.
    findall(F, ( trial(RuleId, _, C), member(F, C) ), Raw),
    % Sort to a distinct, ordered set for a deterministic search.
    sort(Raw, Feats).

% regulation_base_context/2: a rule's context as a list (an `any` context is empty).
regulation_base_context(RuleId, Base) :-
    % Read the rule's context.
    ( rule(RuleId, _, Context) -> true ; Context = any ),
    % Treat `any` as the empty condition set; otherwise sort the list.
    ( Context == any -> Base = [] ; sort(Context, Base) ).
