/*  PrologAI — Causalontology Regulation  (WP-423, Layer 398)

    THE_BUILDING_FILES describe how a mind improves a behaviour from feedback.
    Two ideas sit at the centre. First, feedback comes in four flavours, set by
    whether the result was expected and whether it was good: a success you
    predicted is CONFIRMING, a failure you predicted is DISAPPOINTING, a success
    you did not predict is SERENDIPITOUS, and a failure you did not predict is
    SHOCKING. Second, when one behaviour both succeeds and fails, the fix is not
    to average it away but to SPLIT it — to find the feature of the situation that
    separates the wins from the losses, and refine the rule to require (or avoid)
    it. That is discrimination learning. co_learn induces causal relations and
    co_gauge watches whole strategies; this pack refines an individual behaviour.

    A behaviour is a rule:

        rule(RuleId, Action, Context)        Context a feature list, or `any`

    Feedback records the outcome and the situation it happened in:

        trial(RuleId, success|failure, ObservedContext)

    From the trials the pack derives a reliability, classifies the newest result
    into one of the four flavours, notices when a rule needs discriminating, and
    proposes the discriminating feature and a refined context.

    Predicates:
      ho_reset/0            -- forget all rules and trials
      ho_rule_add/3         -- +RuleId, +Action, +Context
      ho_rule/3             -- ?RuleId, ?Action, ?Context
      ho_feedback/3         -- +RuleId, +Outcome, +ObservedContext   (record a trial)
      ho_stats/3            -- +RuleId, -Successes, -Attempts
      ho_reliability/2      -- +RuleId, -Reliability                 (successes/attempts)
      ho_classify/3         -- +RuleId, +Outcome, -Flavour           (the four flavours)
      ho_needs_discrimination/1 -- +RuleId                           (both wins and losses)
      ho_discriminate/2     -- +RuleId, -Discriminator               (or none)
      ho_refine/3           -- +RuleId, +Discriminator, -RefinedContext
*/

% Declare this module and its exported predicates.
:- module(co_hone, [
    % ho_reset/0: forget all rules and trials.
    ho_reset/0,
    % ho_rule_add/3: register a behaviour rule.
    ho_rule_add/3,
    % ho_rule/3: query behaviour rules.
    ho_rule/3,
    % ho_feedback/3: record the outcome of one trial.
    ho_feedback/3,
    % ho_stats/3: successes and attempts for a rule.
    ho_stats/3,
    % ho_reliability/2: a rule's success rate.
    ho_reliability/2,
    % ho_classify/3: classify a result into one of the four flavours.
    ho_classify/3,
    % ho_needs_discrimination/1: a rule with both wins and losses.
    ho_needs_discrimination/1,
    % ho_discriminate/2: the feature that separates wins from losses.
    ho_discriminate/2,
    % ho_refine/3: the refined context implied by a discriminator.
    ho_refine/3
]).

% Use the list library.
:- use_module(library(lists)).

% rule/3 is a registered behaviour; it changes at runtime, so it is dynamic.
:- dynamic rule/3.
% trial/3 is one recorded outcome in its observed context; dynamic.
:- dynamic trial/3.

% ho_reset/0: forget every rule and every trial.
ho_reset :-
    % Remove all rules.
    retractall(rule(_,_,_)),
    % Remove all trials.
    retractall(trial(_,_,_)).

% ho_rule_add/3: register a behaviour rule, replacing any earlier one for the id.
ho_rule_add(RuleId, Action, Context) :-
    % Drop any previous rule under this id.
    retractall(rule(RuleId, _, _)),
    % Store the new rule.
    assertz(rule(RuleId, Action, Context)).

% ho_rule/3: expose the registered rules.
ho_rule(RuleId, Action, Context) :-
    % Read the stored rule.
    rule(RuleId, Action, Context).

% ho_feedback/3: record one trial's outcome and the situation it occurred in.
ho_feedback(RuleId, Outcome, ObservedContext) :-
    % Normalise the observed context into a sorted set.
    sort(ObservedContext, Sorted),
    % Log the trial.
    assertz(trial(RuleId, Outcome, Sorted)).

% ho_stats/3: total successes and attempts for a rule.
ho_stats(RuleId, Successes, Attempts) :-
    % Count every trial for the rule.
    aggregate_all(count, trial(RuleId, _, _), Attempts),
    % Count the successful ones.
    aggregate_all(count, trial(RuleId, success, _), Successes).

% ho_reliability/2: a rule's success rate, or zero with no attempts.
ho_reliability(RuleId, Reliability) :-
    % Gather the tallies.
    ho_stats(RuleId, Successes, Attempts),
    % Rate is successes over attempts; no attempts means a zero rate.
    ( Attempts =:= 0 -> Reliability = 0.0 ; Reliability is Successes / Attempts ).

% ho_classify/3: classify a result, given what the current reliability predicted.
ho_classify(RuleId, Outcome, Flavour) :-
    % With no history there is nothing to expect: the result is novel.
    ho_stats(RuleId, _, Attempts),
    ( Attempts =:= 0
      -> Flavour = novel
      ;  % Predict success when the rule has been more reliable than not.
         ho_reliability(RuleId, Rel),
         ( Rel >= 0.5 -> Predicted = success ; Predicted = failure ),
         % Name the flavour from the predicted and the actual outcome (one answer).
         once(ho_flavour(Predicted, Outcome, Flavour)) ).

% ho_flavour/3: the four-flavour table over predicted and actual outcome.
% A predicted success that happens is confirming.
ho_flavour(success, success, confirming).
% A predicted success that fails is shocking.
ho_flavour(success, failure, shocking).
% A predicted failure that nonetheless succeeds is serendipitous.
ho_flavour(failure, success, serendipitous).
% A predicted failure that indeed fails is disappointing.
ho_flavour(failure, failure, disappointing).

% ho_needs_discrimination/1: a rule that has both a success and a failure.
ho_needs_discrimination(RuleId) :-
    % There is at least one success,
    trial(RuleId, success, _),
    % and at least one failure — the rule is context-sensitive.
    trial(RuleId, failure, _).

% ho_discriminate/2: the feature that best separates the wins from the losses.
ho_discriminate(RuleId, Discriminator) :-
    % Prefer a feature present in every win and no loss.
    ( ho_split_feature(RuleId, success, failure, F)
      -> Discriminator = discriminator(F, present_predicts(success))
    % Else a feature present in every loss and no win.
    ; ho_split_feature(RuleId, failure, success, F)
      -> Discriminator = discriminator(F, present_predicts(failure))
    % Else nothing separates them.
    ; Discriminator = none ).

% ho_refine/3: the refined context a discriminator implies for a rule.
ho_refine(RuleId, discriminator(F, present_predicts(Which)), RefinedContext) :-
    % Start from the rule's current context (an `any` context is empty).
    ho_base_context(RuleId, Base),
    % A success-predicting feature is required; a failure-predicting one is shunned.
    ( Which == success
      -> sort([F | Base], RefinedContext)
      ;  sort([not(F) | Base], RefinedContext) ).

% ---- internal --------------------------------------------------------------

% ho_split_feature/4: a feature in every InCtx trial and no OutCtx trial.
ho_split_feature(RuleId, InOutcome, OutOutcome, Feature) :-
    % The contexts of the "in" outcome (which must be non-empty).
    ho_contexts(RuleId, InOutcome, InCtxs),
    InCtxs = [_|_],
    % The contexts of the "out" outcome.
    ho_contexts(RuleId, OutOutcome, OutCtxs),
    % Consider every feature seen under the rule, in a stable order.
    ho_all_features(RuleId, Feats),
    member(Feature, Feats),
    % It must appear in every "in" context,
    forall(member(C, InCtxs), memberchk(Feature, C)),
    % and in none of the "out" contexts.
    forall(member(C, OutCtxs), \+ memberchk(Feature, C)),
    % Commit to the first such feature.
    !.

% ho_contexts/3: the observed contexts of a rule's trials with a given outcome.
ho_contexts(RuleId, Outcome, Contexts) :-
    % Collect the contexts of matching trials.
    findall(C, trial(RuleId, Outcome, C), Contexts).

% ho_all_features/2: every distinct feature seen across a rule's trials.
ho_all_features(RuleId, Feats) :-
    % Gather features from every trial's context.
    findall(F, ( trial(RuleId, _, C), member(F, C) ), Raw),
    % Sort to a distinct, ordered set for a deterministic search.
    sort(Raw, Feats).

% ho_base_context/2: a rule's context as a list (an `any` context is empty).
ho_base_context(RuleId, Base) :-
    % Read the rule's context.
    ( rule(RuleId, _, Context) -> true ; Context = any ),
    % Treat `any` as the empty condition set; otherwise sort the list.
    ( Context == any -> Base = [] ; sort(Context, Base) ).
