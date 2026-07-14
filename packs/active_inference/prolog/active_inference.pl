/*  PrologAI — Active Inference Engine  (WP-384, Layer 359)

    The action side of active inference. The existing prediction pack
    covers the perception side (hierarchical prediction and precision);
    this pack adds policy selection by expected free energy, so that
    goal-seeking (pragmatic value) and curiosity (epistemic value) both
    fall out of one quantity.

    A generative model is gm(States, Obs, A, B, C, D):

        States  list of hidden state names.
        Obs     list of observation names.
        A       likelihood: lik(State, [Obs-P...]) — P(o | s).
        B       transitions: trans(Action, State, [State2-P...]) —
                P(s' | s, a). A missing entry means the state persists.
        C       preferences: normalized distribution [Obs-P...] over
                the outcomes the agent wants to see.
        D       prior: normalized distribution [State-P...].

    All distributions are Name-Probability pair lists; probabilities are
    floats and each distribution sums to one within 1.0e-6.

    Key quantities (natural logarithms throughout):

        risk        KL divergence from predicted to preferred outcomes.
        ambiguity   expected outcome entropy of the arrived-at states.
        G           expected free energy = risk + ambiguity.
        pragmatic   expected log preference of predicted outcomes.
        epistemic   expected information gain about hidden states.

    The identity G = -(pragmatic + epistemic) holds and is tested.

    Exported predicates:

    active_inference_model/7           +States, +Obs, +A, +B, +C, +D, -GM
    active_inference_actions/2         +GM, -Actions
    active_inference_prior/2           +GM, -Prior
    active_inference_normalize/2       +Dist, -Normalized
    active_inference_prob/3            +Dist, +Key, -P
    active_inference_infer/4           +GM, +Belief, +Obs, -Posterior
    active_inference_predict_states/4  +GM, +Belief, +Action, -NextBelief
    active_inference_predict_obs/3     +GM, +Belief, -ObsDist
    active_inference_surprise/4        +GM, +Belief, +Obs, -Surprise
    active_inference_free_energy/6     +GM, +Prior, +Obs, -F, -Complexity, -Accuracy
    active_inference_risk/4            +GM, +Belief, +Action, -Risk
    active_inference_ambiguity/4       +GM, +Belief, +Action, -Ambiguity
    active_inference_pragmatic/4       +GM, +Belief, +Action, -Value
    active_inference_epistemic/4       +GM, +Belief, +Action, -Value
    active_inference_efe_action/4      +GM, +Belief, +Action, -G
    active_inference_efe/4             +GM, +Belief, +Policy, -G
    active_inference_policies/3        +GM, +Horizon, -Policies
    active_inference_policy_dist/5     +GM, +Belief, +Horizon, +Gamma, -Dist
    active_inference_select_policy/6   +GM, +Belief, +Horizon, +Gamma, -Policy, -P
    active_inference_act/5             +GM, +Belief, +Horizon, +Gamma, -Action
    active_inference_step/7            +GM, +Belief, +Obs, +Horizon, +Gamma, -Action, -Posterior
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(active_inference, [
    % active_inference_model/7: build and validate a generative model.
    active_inference_model/7,
    % active_inference_actions/2: the distinct action names.
    active_inference_actions/2,
    % active_inference_prior/2: the prior belief over states.
    active_inference_prior/2,
    % active_inference_normalize/2: normalize a distribution to sum one.
    active_inference_normalize/2,
    % active_inference_prob/3: probability of a key, zero when absent.
    active_inference_prob/3,
    % active_inference_infer/4: Bayesian belief update from one observation.
    active_inference_infer/4,
    % active_inference_predict_states/4: push a belief through a transition.
    active_inference_predict_states/4,
    % active_inference_predict_obs/3: predicted outcome distribution of a belief.
    active_inference_predict_obs/3,
    % active_inference_surprise/4: negative log evidence of an observation.
    active_inference_surprise/4,
    % active_inference_free_energy/6: variational free energy with its two parts.
    active_inference_free_energy/6,
    % active_inference_risk/4: KL from predicted to preferred outcomes.
    active_inference_risk/4,
    % active_inference_ambiguity/4: expected outcome entropy after an action.
    active_inference_ambiguity/4,
    % active_inference_pragmatic/4: expected log preference (goal-seeking drive).
    active_inference_pragmatic/4,
    % active_inference_epistemic/4: expected information gain (curiosity drive).
    active_inference_epistemic/4,
    % active_inference_efe_action/4: one-step expected free energy.
    active_inference_efe_action/4,
    % active_inference_efe/4: expected free energy of an action sequence.
    active_inference_efe/4,
    % active_inference_policies/3: enumerate policies to a horizon.
    active_inference_policies/3,
    % active_inference_policy_dist/5: softmax distribution over policies.
    active_inference_policy_dist/5,
    % active_inference_select_policy/6: most plausible policy and its probability.
    active_inference_select_policy/6,
    % active_inference_act/5: first action of the selected policy.
    active_inference_act/5,
    % active_inference_step/7: full perceive-then-act cycle.
    active_inference_step/7
]).

% Use the lists library for member/2, foldl/4, and friends.
:- use_module(library(lists)).

% ===========================================================================
% NUMERIC HELPERS
% ===========================================================================

% active_inference_eps(-Eps): floor used inside logarithms to avoid log of zero.
active_inference_eps(1.0e-12).

% active_inference_ln(+P, -L): natural log with the epsilon floor applied.
active_inference_ln(P, L) :-
    % Fetch the floor.
    active_inference_eps(Eps),
    % Guard the probability away from zero.
    Guarded is max(P, Eps),
    % Take the natural logarithm.
    L is log(Guarded).

% active_inference_dist_sum(+Dist, -Sum): total mass of a distribution.
active_inference_dist_sum(Dist, Sum) :-
    % Extract the probability values.
    pairs_values(Dist, Ps),
    % Add them up.
    sum_list(Ps, Sum).

% active_inference_normalize(+Dist, -Normalized): scale a distribution to sum one.
active_inference_normalize(Dist, Normalized) :-
    % Total mass of the input.
    active_inference_dist_sum(Dist, Sum),
    % A distribution with no mass cannot be normalized.
    Sum > 0.0,
    % Divide every entry by the total.
    findall(K-P2, ( member(K-P, Dist), P2 is P / Sum ), Normalized).

% active_inference_prob(+Dist, +Key, -P): probability of a key, zero when absent.
active_inference_prob(Dist, Key, P) :-
    % Use the listed value when the key is present.
    (   memberchk(Key-P0, Dist)
    % Present: return the listed probability.
    ->  P = P0
    % Absent: the probability is zero.
    ;   P = 0.0
    ).

% active_inference_dist_valid(+Dist, +Keys): entries are known, non-negative, and sum to one.
active_inference_dist_valid(Dist, Keys) :-
    % Every entry must use a known key and a non-negative probability.
    forall(member(K-P, Dist), ( memberchk(K, Keys), number(P), P >= 0.0 )),
    % Total mass of the distribution.
    active_inference_dist_sum(Dist, Sum),
    % The mass must be one within tolerance.
    abs(Sum - 1.0) < 1.0e-6.

% ===========================================================================
% MODEL CONSTRUCTION
% ===========================================================================

% active_inference_model(+States, +Obs, +A, +B, +C, +D, -GM): validate and assemble.
active_inference_model(States, Obs, A, B, C, D, gm(States, Obs, A, B, C, D)) :-
    % Every state needs a likelihood row that is a valid distribution.
    forall(member(S, States),
        % Fetch and check the row for this state.
        ( memberchk(lik(S, Row), A), active_inference_dist_valid(Row, Obs) )),
    % Every transition row must be a valid distribution over states.
    forall(member(trans(_, S, Row), B),
        % The source state must be known and the row valid.
        ( memberchk(S, States), active_inference_dist_valid(Row, States) )),
    % The preference distribution must be valid over observations.
    active_inference_dist_valid(C, Obs),
    % The prior must be valid over states.
    active_inference_dist_valid(D, States).

% active_inference_actions(+GM, -Actions): the distinct action names in B.
active_inference_actions(gm(_, _, _, B, _, _), Actions) :-
    % Collect every action name mentioned in a transition.
    findall(Act, member(trans(Act, _, _), B), Raw),
    % Sort and de-duplicate.
    sort(Raw, Actions).

% active_inference_prior(+GM, -Prior): the prior belief over states.
active_inference_prior(gm(_, _, _, _, _, D), D).

% active_inference_lik(+GM, +S, +O, -P): likelihood P(o | s).
active_inference_lik(gm(_, _, A, _, _, _), S, O, P) :-
    % Fetch the likelihood row of the state.
    memberchk(lik(S, Row), A),
    % Read the probability of the observation.
    active_inference_prob(Row, O, P).

% active_inference_trans(+GM, +Action, +S, -Row): transition row, defaulting to persistence.
active_inference_trans(gm(_, _, _, B, _, _), Action, S, Row) :-
    % Use the listed row when one exists.
    (   memberchk(trans(Action, S, Row0), B)
    % Present: take the listed distribution.
    ->  Row = Row0
    % Absent: the state persists with certainty.
    ;   Row = [S-1.0]
    ).

% ===========================================================================
% PERCEPTION — BELIEF UPDATING
% ===========================================================================

% active_inference_infer(+GM, +Belief, +Obs, -Posterior): Bayes rule over states.
active_inference_infer(GM, Belief, Obs, Posterior) :-
    % Weigh each state's mass by the likelihood of the observation.
    findall(S-W,
        % Take each belief entry in turn.
        ( member(S-P, Belief),
          % Fetch the likelihood of the observation in that state.
          active_inference_lik(GM, S, Obs, L),
          % Multiply prior mass by likelihood.
          W is P * L ),
        Weighted),
    % Normalize; failure here means the observation was impossible.
    active_inference_normalize(Weighted, Posterior).

% active_inference_predict_states(+GM, +Belief, +Action, -Next): belief after an action.
active_inference_predict_states(GM, Belief, Action, Next) :-
    % The model states give the fixed output order.
    GM = gm(States, _, _, _, _, _),
    % Compute the pushed-forward mass for every state.
    findall(S2-P2,
        % Take each destination state in turn.
        ( member(S2, States),
          % Sum incoming mass over all source states.
          active_inference_inflow(GM, Belief, Action, S2, P2) ),
        Next).

% active_inference_inflow(+GM, +Belief, +Action, +S2, -P): mass flowing into S2.
active_inference_inflow(GM, Belief, Action, S2, P) :-
    % Collect each source contribution.
    findall(Part,
        % Take each source state and its mass.
        ( member(S-PS, Belief),
          % Fetch the transition row of the source.
          active_inference_trans(GM, Action, S, Row),
          % Read the probability of arriving at S2.
          active_inference_prob(Row, S2, T),
          % Multiply mass by transition probability.
          Part is PS * T ),
        Parts),
    % Sum all contributions.
    sum_list(Parts, P).

% active_inference_predict_obs(+GM, +Belief, -ObsDist): predicted outcome distribution.
active_inference_predict_obs(GM, Belief, ObsDist) :-
    % The model observations give the fixed output order.
    GM = gm(_, Obs, _, _, _, _),
    % Mix the likelihood rows by belief mass.
    findall(O-P,
        % Take each observation in turn.
        ( member(O, Obs),
          % Sum its probability over the believed states.
          active_inference_obs_mass(GM, Belief, O, P) ),
        ObsDist).

% active_inference_obs_mass(+GM, +Belief, +O, -P): total predicted mass of one outcome.
active_inference_obs_mass(GM, Belief, O, P) :-
    % Collect each state's contribution.
    findall(Part,
        % Take each believed state and its mass.
        ( member(S-PS, Belief),
          % Fetch the likelihood of the outcome in that state.
          active_inference_lik(GM, S, O, L),
          % Multiply mass by likelihood.
          Part is PS * L ),
        Parts),
    % Sum all contributions.
    sum_list(Parts, P).

% active_inference_surprise(+GM, +Belief, +Obs, -Surprise): negative log evidence.
active_inference_surprise(GM, Belief, Obs, Surprise) :-
    % Predict the outcome distribution of the belief.
    active_inference_predict_obs(GM, Belief, ObsDist),
    % Read the probability of the actual observation.
    active_inference_prob(ObsDist, Obs, P),
    % Take the negative log.
    active_inference_ln(P, L),
    % Surprise is how unlikely the observation was.
    Surprise is -L.

% active_inference_free_energy(+GM, +Prior, +Obs, -F, -Complexity, -Accuracy): decomposition.
active_inference_free_energy(GM, Prior, Obs, F, Complexity, Accuracy) :-
    % Exact posterior after seeing the observation.
    active_inference_infer(GM, Prior, Obs, Post),
    % Complexity: how far the posterior moved from the prior.
    active_inference_kl(Post, Prior, Complexity),
    % Accuracy: expected log likelihood under the posterior.
    findall(Term,
        % Take each posterior entry in turn.
        ( member(S-Q, Post),
          % Fetch the likelihood of the observation in that state.
          active_inference_lik(GM, S, Obs, L),
          % Weight the log likelihood by posterior mass.
          active_inference_ln(L, LL),
          % Accumulate the weighted term.
          Term is Q * LL ),
        Terms),
    % Sum the accuracy terms.
    sum_list(Terms, Accuracy),
    % Free energy is complexity minus accuracy.
    F is Complexity - Accuracy.

% active_inference_kl(+P, +Q, -KL): Kullback-Leibler divergence between pair lists.
active_inference_kl(P, Q, KL) :-
    % Collect the pointwise contributions.
    findall(Term,
        % Take each entry of the first distribution.
        ( member(K-PK, P),
          % Skip zero-mass entries, which contribute nothing.
          PK > 0.0,
          % Read the matching mass in the second distribution.
          active_inference_prob(Q, K, QK),
          % Log ratio with the epsilon floor.
          active_inference_ln(PK, LP),
          % Log of the reference mass.
          active_inference_ln(QK, LQ),
          % Weighted log ratio.
          Term is PK * (LP - LQ) ),
        Terms),
    % Sum the contributions.
    sum_list(Terms, KL).

% ===========================================================================
% ACTION — EXPECTED FREE ENERGY
% ===========================================================================

% active_inference_risk(+GM, +Belief, +Action, -Risk): KL(predicted outcomes || preferences).
active_inference_risk(GM, Belief, Action, Risk) :-
    % Roll the belief forward through the action.
    active_inference_predict_states(GM, Belief, Action, Next),
    % Predict the outcomes of the arrived-at belief.
    active_inference_predict_obs(GM, Next, Qo),
    % Fetch the preference distribution.
    GM = gm(_, _, _, _, C, _),
    % Risk is the divergence from prediction to preference.
    active_inference_kl(Qo, C, Risk).

% active_inference_ambiguity(+GM, +Belief, +Action, -Ambiguity): expected outcome entropy.
active_inference_ambiguity(GM, Belief, Action, Ambiguity) :-
    % Roll the belief forward through the action.
    active_inference_predict_states(GM, Belief, Action, Next),
    % Weight each state's outcome entropy by its mass.
    findall(Term,
        % Take each arrived-at state and its mass.
        ( member(S-P, Next),
          % Entropy of the outcome distribution in that state.
          active_inference_state_entropy(GM, S, H),
          % Weight the entropy by the state mass.
          Term is P * H ),
        Terms),
    % Sum the weighted entropies.
    sum_list(Terms, Ambiguity).

% active_inference_state_entropy(+GM, +S, -H): outcome entropy of one state.
active_inference_state_entropy(GM, S, H) :-
    % Fetch the likelihood row of the state.
    GM = gm(_, _, A, _, _, _),
    % Read the row itself.
    memberchk(lik(S, Row), A),
    % Collect the entropy terms.
    findall(Term,
        % Take each outcome mass in the row.
        ( member(_-P, Row),
          % Zero mass contributes nothing.
          P > 0.0,
          % Log of the mass.
          active_inference_ln(P, L),
          % Negative mass-weighted log.
          Term is -(P * L) ),
        Terms),
    % Sum the entropy terms.
    sum_list(Terms, H).

% active_inference_pragmatic(+GM, +Belief, +Action, -Value): expected log preference.
active_inference_pragmatic(GM, Belief, Action, Value) :-
    % Roll the belief forward through the action.
    active_inference_predict_states(GM, Belief, Action, Next),
    % Predict the outcomes of the arrived-at belief.
    active_inference_predict_obs(GM, Next, Qo),
    % Fetch the preference distribution.
    GM = gm(_, _, _, _, C, _),
    % Weight each outcome's log preference by its predicted mass.
    findall(Term,
        % Take each predicted outcome mass.
        ( member(O-P, Qo),
          % Zero mass contributes nothing.
          P > 0.0,
          % Read the preference for this outcome.
          active_inference_prob(C, O, CP),
          % Log preference with the epsilon floor.
          active_inference_ln(CP, L),
          % Mass-weighted log preference.
          Term is P * L ),
        Terms),
    % Sum the weighted terms.
    sum_list(Terms, Value).

% active_inference_epistemic(+GM, +Belief, +Action, -Value): expected information gain.
active_inference_epistemic(GM, Belief, Action, Value) :-
    % Roll the belief forward through the action.
    active_inference_predict_states(GM, Belief, Action, Next),
    % Predict the marginal outcome distribution.
    active_inference_predict_obs(GM, Next, Qo),
    % Mutual information between arrived-at states and outcomes.
    findall(Term,
        % Take each state-outcome pair with joint mass.
        ( member(S-PS, Next),
          % Skip states with no mass.
          PS > 0.0,
          % Fetch the likelihood row of the state.
          active_inference_lik_row(GM, S, Row),
          % Take each outcome in the row.
          member(O-L, Row),
          % Skip zero-likelihood outcomes.
          L > 0.0,
          % Joint mass of the pair.
          J is PS * L,
          % Marginal outcome mass.
          active_inference_prob(Qo, O, QO),
          % Log of the joint mass.
          active_inference_ln(J, LJ),
          % Log of the product of marginals.
          Prod is PS * QO,
          % Guarded log of the product.
          active_inference_ln(Prod, LProd),
          % Pointwise mutual information weighted by joint mass.
          Term is J * (LJ - LProd) ),
        Terms),
    % Sum the pointwise contributions.
    sum_list(Terms, Value).

% active_inference_lik_row(+GM, +S, -Row): the likelihood row of a state.
active_inference_lik_row(gm(_, _, A, _, _, _), S, Row) :-
    % Fetch the row from the likelihood table.
    memberchk(lik(S, Row), A).

% active_inference_efe_action(+GM, +Belief, +Action, -G): one-step expected free energy.
active_inference_efe_action(GM, Belief, Action, G) :-
    % Risk: divergence from predicted to preferred outcomes.
    active_inference_risk(GM, Belief, Action, Risk),
    % Ambiguity: expected outcome entropy.
    active_inference_ambiguity(GM, Belief, Action, Amb),
    % Expected free energy is their sum.
    G is Risk + Amb.

% active_inference_efe(+GM, +Belief, +Policy, -G): expected free energy of a policy.
active_inference_efe(_, _, [], 0.0).
% Add the first action's contribution, then roll the belief and recurse.
active_inference_efe(GM, Belief, [Action | Rest], G) :-
    % One-step expected free energy of the first action.
    active_inference_efe_action(GM, Belief, Action, G1),
    % Roll the belief forward through the action.
    active_inference_predict_states(GM, Belief, Action, Next),
    % Expected free energy of the remaining actions.
    active_inference_efe(GM, Next, Rest, G2),
    % Total the two contributions.
    G is G1 + G2.

% ===========================================================================
% POLICY SELECTION
% ===========================================================================

% active_inference_policies(+GM, +Horizon, -Policies): all action sequences of the length.
active_inference_policies(GM, Horizon, Policies) :-
    % Fetch the available actions.
    active_inference_actions(GM, Actions),
    % Enumerate every sequence of the requested length.
    findall(Policy,
        % Build a list of the right length.
        ( length(Policy, Horizon),
          % Fill each slot with one of the actions.
          maplist(active_inference_pick(Actions), Policy) ),
        Policies).

% active_inference_pick(+Actions, -Action): choose one action from the list.
active_inference_pick(Actions, Action) :-
    % Enumerate the available actions.
    member(Action, Actions).

% active_inference_policy_dist(+GM, +Belief, +Horizon, +Gamma, -Dist): softmax over policies.
active_inference_policy_dist(GM, Belief, Horizon, Gamma, Dist) :-
    % Enumerate the candidate policies.
    active_inference_policies(GM, Horizon, Policies),
    % Weight each policy by the negative of its expected free energy.
    findall(Policy-W,
        % Take each policy in turn.
        ( member(Policy, Policies),
          % Expected free energy of the policy.
          active_inference_efe(GM, Belief, Policy, G),
          % Softmax weight sharpened by the precision Gamma.
          W is exp(-(Gamma * G)) ),
        Weighted),
    % Normalize the weights into a distribution.
    active_inference_normalize(Weighted, Dist).

% active_inference_select_policy(+GM, +Belief, +Horizon, +Gamma, -Policy, -P): best policy.
active_inference_select_policy(GM, Belief, Horizon, Gamma, Policy, P) :-
    % Build the softmax distribution over policies.
    active_inference_policy_dist(GM, Belief, Horizon, Gamma, Dist),
    % Start the maximum search from the first entry.
    Dist = [P0-W0 | Rest],
    % Scan for the highest-probability policy.
    foldl(active_inference_max_pair, Rest, P0-W0, Policy-P).

% active_inference_max_pair(+Candidate, +Best0, -Best): keep the higher-probability pair.
active_inference_max_pair(K-W, K0-W0, Best) :-
    % Compare the candidate weight against the incumbent.
    (   W > W0
    % The candidate wins.
    ->  Best = K-W
    % The incumbent stays.
    ;   Best = K0-W0
    ).

% active_inference_act(+GM, +Belief, +Horizon, +Gamma, -Action): first action of the winner.
active_inference_act(GM, Belief, Horizon, Gamma, Action) :-
    % Select the most plausible policy.
    active_inference_select_policy(GM, Belief, Horizon, Gamma, Policy, _),
    % Its first action is executed next.
    Policy = [Action | _].

% active_inference_step(+GM, +Belief, +Obs, +Horizon, +Gamma, -Action, -Posterior): cycle.
active_inference_step(GM, Belief, Obs, Horizon, Gamma, Action, Posterior) :-
    % Perceive: update the belief with the observation.
    active_inference_infer(GM, Belief, Obs, Posterior),
    % Act: choose the next action from the updated belief.
    active_inference_act(GM, Posterior, Horizon, Gamma, Action).
