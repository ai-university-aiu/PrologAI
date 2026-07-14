/*  PrologAI — Active Inference Pack Test Suite  (WP-384)

    Acceptance tests for all active_inference_* predicates, including hand-computed
    numeric checks and the identity G = -(pragmatic + epistemic).

    Run with:
        swipl -g "run_tests, halt" test_actinf.pl
*/

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module('../prolog/active_inference').

% ===========================================================================
% TEST FIXTURE MODELS
% ===========================================================================

% close_to(+A, +B): loose float comparison against hand-computed values.
close_to(A, B) :-
    % Four decimal places of agreement suffice.
    abs(A - B) < 1.0e-4.

% tight(+A, +B): strict float comparison for mathematical identities.
tight(A, B) :-
    % Identities must agree to six decimal places.
    abs(A - B) < 1.0e-6.

% A two-state model with noisy observations, for numeric hand-checks.
two_state(GM) :-
    % Assemble and validate the generative model.
    active_inference_model(
        % The two hidden states.
        [s1, s2],
        % The two observations.
        [o1, o2],
        % Likelihood: each state favours its own observation.
        [lik(s1, [o1-0.8, o2-0.2]), lik(s2, [o1-0.2, o2-0.8])],
        % Transitions: stay keeps the state, flip exchanges the two.
        [trans(stay, s1, [s1-1.0]), trans(stay, s2, [s2-1.0]),
         trans(flip, s1, [s2-1.0]), trans(flip, s2, [s1-1.0])],
        % Preferences favour the first observation.
        [o1-0.9, o2-0.1],
        % A flat prior over the two states.
        [s1-0.5, s2-0.5],
        GM).

% The same two-state model with indifferent preferences, for the risk test.
two_state_flat_pref(GM) :-
    % Assemble and validate the generative model.
    active_inference_model(
        % The two hidden states.
        [s1, s2],
        % The two observations.
        [o1, o2],
        % Likelihood: each state favours its own observation.
        [lik(s1, [o1-0.8, o2-0.2]), lik(s2, [o1-0.2, o2-0.8])],
        % A single persistence action.
        [trans(stay, s1, [s1-1.0]), trans(stay, s2, [s2-1.0])],
        % Preferences exactly match the flat predictive distribution.
        [o1-0.5, o2-0.5],
        % A flat prior over the two states.
        [s1-0.5, s2-0.5],
        GM).

% The T-maze: an unknown reward side, a cue that reveals it, and two arms.
tmaze(GM) :-
    % Assemble and validate the generative model.
    active_inference_model(
        % States pair a location with the true reward side (l or r).
        [c_l, c_r, q_l, q_r, l_l, l_r, r_l, r_r],
        % The five observations.
        [blank, cue_left, cue_right, reward, no_reward],
        % Likelihood: the cue reveals the side; the arms reveal the reward.
        [lik(c_l, [blank-1.0]), lik(c_r, [blank-1.0]),
         lik(q_l, [cue_left-1.0]), lik(q_r, [cue_right-1.0]),
         lik(l_l, [reward-1.0]), lik(l_r, [no_reward-1.0]),
         lik(r_l, [no_reward-1.0]), lik(r_r, [reward-1.0])],
        % Transitions: check visits the cue; left and right enter an arm.
        [trans(check, c_l, [q_l-1.0]), trans(check, c_r, [q_r-1.0]),
         trans(left, c_l, [l_l-1.0]), trans(left, c_r, [l_r-1.0]),
         trans(left, q_l, [l_l-1.0]), trans(left, q_r, [l_r-1.0]),
         trans(left, l_l, [l_l-1.0]), trans(left, l_r, [l_r-1.0]),
         trans(left, r_l, [l_l-1.0]), trans(left, r_r, [l_r-1.0]),
         trans(right, c_l, [r_l-1.0]), trans(right, c_r, [r_r-1.0]),
         trans(right, q_l, [r_l-1.0]), trans(right, q_r, [r_r-1.0]),
         trans(right, l_l, [r_l-1.0]), trans(right, l_r, [r_r-1.0]),
         trans(right, r_l, [r_l-1.0]), trans(right, r_r, [r_r-1.0])],
        % Preferences: the agent wants the reward.
        [reward-0.85, blank-0.05, cue_left-0.04, cue_right-0.04, no_reward-0.02],
        % Prior: at the centre, reward side unknown.
        [c_l-0.5, c_r-0.5],
        GM).

% ===========================================================================
% MODEL CONSTRUCTION AND BASICS
% ===========================================================================

:- begin_tests(actinf_model).

% A well-formed model builds and reports its actions.
test(model_builds) :-
    % Build the two-state model.
    two_state(GM),
    % Ask for the distinct actions.
    active_inference_actions(GM, Actions),
    % Both actions must be present.
    Actions == [flip, stay].

% The prior is returned unchanged.
test(prior) :-
    % Build the two-state model.
    two_state(GM),
    % Read the prior back.
    active_inference_prior(GM, [s1-0.5, s2-0.5]).

% A prior that does not sum to one is rejected.
test(bad_prior_rejected, [fail]) :-
    % The prior mass here sums to 1.4.
    active_inference_model([s1, s2], [o1],
        % A trivially valid likelihood table.
        [lik(s1, [o1-1.0]), lik(s2, [o1-1.0])],
        % A single persistence action.
        [trans(stay, s1, [s1-1.0])],
        % A valid preference distribution.
        [o1-1.0],
        % The invalid prior.
        [s1-0.7, s2-0.7],
        _).

% Normalization rescales mass to one.
test(normalize) :-
    % Normalize an unnormalized pair list.
    active_inference_normalize([a-2.0, b-6.0], N),
    % Read the first mass.
    memberchk(a-PA, N),
    % Check the first mass.
    tight(PA, 0.25),
    % Read the second mass.
    memberchk(b-PB, N),
    % Check the second mass.
    tight(PB, 0.75).

% Missing keys read as zero probability.
test(prob_missing_zero) :-
    % Ask for a key that is not present.
    active_inference_prob([a-1.0], b, P),
    % The mass must be zero.
    P =:= 0.0.

:- end_tests(actinf_model).

% ===========================================================================
% PERCEPTION — BELIEF UPDATING
% ===========================================================================

:- begin_tests(actinf_perception).

% Bayes rule: a flat prior plus observation o1 concentrates on s1.
test(infer_bayes) :-
    % Build the two-state model.
    two_state(GM),
    % Update the flat prior with the first observation.
    active_inference_infer(GM, [s1-0.5, s2-0.5], o1, Post),
    % Read the posterior mass of the first state.
    memberchk(s1-P1, Post),
    % Hand computation: 0.4 / 0.5 = 0.8.
    tight(P1, 0.8).

% An impossible observation makes inference fail honestly.
test(infer_impossible, [fail]) :-
    % Build a one-state model that can never emit o2.
    active_inference_model([x], [o1, o2],
        % The state emits only the first observation.
        [lik(x, [o1-1.0, o2-0.0])],
        % A single persistence action.
        [trans(noop, x, [x-1.0])],
        % A valid preference distribution.
        [o1-1.0, o2-0.0],
        % Certainty about the single state.
        [x-1.0],
        GM),
    % The impossible observation cannot be explained.
    active_inference_infer(GM, [x-1.0], o2, _).

% The flip action swaps the belief between the two states.
test(predict_states_flip) :-
    % Build the two-state model.
    two_state(GM),
    % Push certainty about s1 through the flip action.
    active_inference_predict_states(GM, [s1-1.0], flip, Next),
    % All the mass must arrive at s2.
    memberchk(s2-P, Next),
    % Check the arrived mass.
    tight(P, 1.0).

% The predicted outcome distribution mixes the likelihood rows.
test(predict_obs) :-
    % Build the two-state model.
    two_state(GM),
    % Predict outcomes under the flat prior.
    active_inference_predict_obs(GM, [s1-0.5, s2-0.5], Qo),
    % Read the predicted mass of the first observation.
    memberchk(o1-P, Qo),
    % Hand computation: 0.5 * 0.8 + 0.5 * 0.2 = 0.5.
    tight(P, 0.5).

% Surprise of a half-expected observation is ln 2.
test(surprise) :-
    % Build the two-state model.
    two_state(GM),
    % Surprise of the first observation under the flat prior.
    active_inference_surprise(GM, [s1-0.5, s2-0.5], o1, S),
    % Hand computation: -ln(0.5) = 0.693147.
    close_to(S, 0.693147).

% Free energy with exact inference equals surprise, split into two parts.
test(free_energy_decomposition) :-
    % Build the two-state model.
    two_state(GM),
    % Compute free energy and its decomposition.
    active_inference_free_energy(GM, [s1-0.5, s2-0.5], o1, F, Complexity, Accuracy),
    % Hand computation: complexity is 0.192745.
    close_to(Complexity, 0.192745),
    % Hand computation: accuracy is -0.500402.
    close_to(Accuracy, -0.500402),
    % Free energy is complexity minus accuracy.
    tight(F, Complexity - Accuracy),
    % With exact inference, free energy equals surprise.
    active_inference_surprise(GM, [s1-0.5, s2-0.5], o1, S),
    % Compare the two quantities.
    close_to(F, S).

:- end_tests(actinf_perception).

% ===========================================================================
% ACTION — EXPECTED FREE ENERGY
% ===========================================================================

:- begin_tests(actinf_efe).

% Risk vanishes when predictions already match preferences.
test(risk_zero_when_matched) :-
    % Build the variant whose preferences equal its predictions.
    two_state_flat_pref(GM),
    % Risk of staying under the flat prior.
    active_inference_risk(GM, [s1-0.5, s2-0.5], stay, Risk),
    % The divergence must be essentially zero.
    close_to(Risk, 0.0).

% Ambiguity is the mass-weighted outcome entropy of the arrived-at states.
test(ambiguity_value) :-
    % Build the two-state model.
    two_state(GM),
    % Ambiguity of staying under the flat prior.
    active_inference_ambiguity(GM, [s1-0.5, s2-0.5], stay, Amb),
    % Hand computation: the entropy of (0.8, 0.2) is 0.500402.
    close_to(Amb, 0.500402).

% The T-maze cue is worth exactly one bit when the side is unknown.
test(epistemic_cue_one_bit) :-
    % Build the T-maze model.
    tmaze(GM),
    % Information gain of checking the cue from the flat prior.
    active_inference_epistemic(GM, [c_l-0.5, c_r-0.5], check, EV),
    % Hand computation: ln 2 = 0.693147.
    close_to(EV, 0.693147).

% The cue is worthless once the reward side is already known.
test(epistemic_vanishes_when_certain) :-
    % Build the T-maze model.
    tmaze(GM),
    % Information gain of checking when the side is known.
    active_inference_epistemic(GM, [c_l-1.0], check, EV),
    % Nothing remains to learn.
    close_to(EV, 0.0).

% Pragmatic value prefers the rewarded arm when the side is known.
test(pragmatic_prefers_reward) :-
    % Build the T-maze model.
    tmaze(GM),
    % Pragmatic value of the correct arm.
    active_inference_pragmatic(GM, [c_l-1.0], left, PVLeft),
    % Hand computation: ln(0.85) = -0.162519.
    close_to(PVLeft, -0.162519),
    % Pragmatic value of the wrong arm.
    active_inference_pragmatic(GM, [c_l-1.0], right, PVRight),
    % Hand computation: ln(0.02) = -3.912023.
    close_to(PVRight, -3.912023),
    % The correct arm must score higher.
    PVLeft > PVRight.

% The identity G = -(pragmatic + epistemic) holds for every T-maze action.
test(efe_identity) :-
    % Build the T-maze model.
    tmaze(GM),
    % The flat prior over the reward side.
    Belief = [c_l-0.5, c_r-0.5],
    % Check the identity for each action.
    forall(member(Action, [check, left, right]),
        % Compare the two computations of expected free energy.
        ( active_inference_efe_action(GM, Belief, Action, G),
          % Pragmatic value of the action.
          active_inference_pragmatic(GM, Belief, Action, PV),
          % Epistemic value of the action.
          active_inference_epistemic(GM, Belief, Action, EV),
          % The negated sum must equal G.
          Sum is -(PV + EV),
          % Enforce the identity tightly.
          tight(G, Sum) )).

% A multi-step policy accumulates expected free energy across steps.
test(efe_policy_accumulates, [nondet]) :-
    % Build the T-maze model.
    tmaze(GM),
    % The flat prior over the reward side.
    Belief = [c_l-0.5, c_r-0.5],
    % One-step expected free energy of checking.
    active_inference_efe_action(GM, Belief, check, G1),
    % Belief after checking.
    active_inference_predict_states(GM, Belief, check, Next),
    % One-step expected free energy of the follow-up.
    active_inference_efe_action(GM, Next, left, G2),
    % Two-step policy value.
    active_inference_efe(GM, Belief, [check, left], G),
    % The policy value must equal the sum of its steps.
    tight(G, G1 + G2).

:- end_tests(actinf_efe).

% ===========================================================================
% POLICY SELECTION
% ===========================================================================

:- begin_tests(actinf_policy).

% Policy enumeration covers every action sequence of the horizon.
test(policies_enumerated) :-
    % Build the two-state model.
    two_state(GM),
    % Enumerate all two-step policies over two actions.
    active_inference_policies(GM, 2, Policies),
    % There must be exactly four.
    length(Policies, 4).

% The softmax policy distribution sums to one.
test(policy_dist_sums_to_one) :-
    % Build the T-maze model.
    tmaze(GM),
    % Build the distribution at unit precision.
    active_inference_policy_dist(GM, [c_l-0.5, c_r-0.5], 1, 1.0, Dist),
    % Extract the probabilities.
    findall(P, member(_-P, Dist), Ps),
    % Sum them.
    sum_list(Ps, Sum),
    % The mass must be one.
    tight(Sum, 1.0).

% Raising the precision sharpens the policy distribution.
test(gamma_sharpens) :-
    % Build the T-maze model.
    tmaze(GM),
    % The flat prior over the reward side.
    Belief = [c_l-0.5, c_r-0.5],
    % Distribution at low precision.
    active_inference_select_policy(GM, Belief, 1, 1.0, _, PLow),
    % Distribution at high precision.
    active_inference_select_policy(GM, Belief, 1, 4.0, _, PHigh),
    % The winner's probability must grow with precision.
    PHigh > PLow.

% With the side known, the agent exploits: it selects the rewarded arm.
test(select_exploits_when_certain) :-
    % Build the T-maze model.
    tmaze(GM),
    % Select a one-step policy knowing the reward is left.
    active_inference_select_policy(GM, [c_l-1.0], 1, 4.0, Policy, _),
    % The rewarded arm wins.
    Policy == [left].

% The full cycle: observe the cue, then head to the revealed arm.
test(step_cycle) :-
    % Build the T-maze model.
    tmaze(GM),
    % At the cue location with the side still unknown.
    Belief = [q_l-0.5, q_r-0.5],
    % Perceive the left cue and choose the next action.
    active_inference_step(GM, Belief, cue_left, 1, 4.0, Action, Posterior),
    % The posterior concentrates on the left context.
    memberchk(q_l-P, Posterior),
    % Check the posterior mass.
    tight(P, 1.0),
    % The chosen action heads to the rewarded arm.
    Action == left.

:- end_tests(actinf_policy).
