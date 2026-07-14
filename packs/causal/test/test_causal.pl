/*  PrologAI — Causal Pack Test Suite  (WP-383)

    Acceptance tests for all cf_* predicates.

    Run with:
        swipl -g "run_tests, halt" test_causal.pl
*/

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module('../prolog/causal').

% ===========================================================================
% TEST FIXTURE MODELS
% ===========================================================================

% The firing squad: court orders, captain signals, two riflemen fire.
squad_model(SCM) :-
    % Build the model from its declarations.
    causal_model([
        % The court order is the exogenous background condition.
        exo(court, 0),
        % The captain signals exactly when the court orders.
        eq(captain, court),
        % Rifleman A fires on the captain's signal.
        eq(rifle_a, captain),
        % Rifleman B fires on the captain's signal.
        eq(rifle_b, captain),
        % The prisoner dies when either rifleman fires.
        eq(death, max(rifle_a, rifle_b))
    ], SCM).

% The sprinkler: season drives sprinkler and rain; both wet the grass.
sprinkler_model(SCM) :-
    % Build the model from its declarations.
    causal_model([
        % Season 1 means dry season; season 0 means wet season.
        exo(season, 0),
        % The sprinkler runs in the dry season.
        eq(sprinkler, if(eqv(season, 1), 1, 0)),
        % Rain falls in the wet season.
        eq(rain, if(eqv(season, 0), 1, 0)),
        % The grass is wet when the sprinkler runs or rain falls.
        eq(wet, max(sprinkler, rain)),
        % Wet grass is slippery.
        eq(slippery, wet)
    ], SCM).

% ===========================================================================
% MODEL CONSTRUCTION AND GRAPH QUERIES
% ===========================================================================

:- begin_tests(causal_model).

% A well-formed model builds and reports its variables.
test(model_builds) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Ask for the full variable list.
    causal_variables(SCM, Vars),
    % All five variables must be present.
    msort(Vars, [captain, court, death, rifle_a, rifle_b]).

% Exogenous and endogenous variables are reported separately.
test(exo_endo_split) :-
    % Build the firing squad model.
    squad_model(SCM),
    % The only exogenous variable is the court order.
    causal_exogenous(SCM, [court]),
    % The endogenous list holds the other four variables.
    causal_endogenous(SCM, Endo),
    % Order within the list is causal, so just check the membership.
    msort(Endo, [captain, death, rifle_a, rifle_b]).

% The topological order puts causes before effects.
test(topological_order) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Ask for the endogenous order.
    causal_endogenous(SCM, Order),
    % The captain must precede rifleman A.
    nth0(IC, Order, captain),
    % Locate rifleman A in the order.
    nth0(IA, Order, rifle_a),
    % Locate the death variable in the order.
    nth0(ID, Order, death),
    % Captain comes before rifleman A.
    IC < IA,
    % Rifleman A comes before death.
    IA < ID.

% A cyclic model must be rejected.
test(cycle_rejected, [fail]) :-
    % Two variables defined in terms of each other form a cycle.
    causal_model([eq(a, b), eq(b, a)], _).

% A reference to an undeclared variable must be rejected.
test(undeclared_rejected, [fail]) :-
    % The equation references a name that no declaration introduces.
    causal_model([exo(u, 0), eq(a, zz)], _).

% A duplicated variable name must be rejected.
test(duplicate_rejected, [fail]) :-
    % The same name is declared twice.
    causal_model([exo(a, 0), eq(a, 1 + 0)], _).

% Parents are the variables referenced by an equation.
test(parents) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Death is caused directly by the two riflemen.
    causal_parents(SCM, death, Ps),
    % Check the parent set.
    msort(Ps, [rifle_a, rifle_b]).

% Children are the variables whose equations reference X.
test(children) :-
    % Build the firing squad model.
    squad_model(SCM),
    % The captain signals both riflemen.
    causal_children(SCM, captain, Cs),
    % Check the child set.
    msort(Cs, [rifle_a, rifle_b]).

% Ancestors are the transitive causes.
test(ancestors) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Everything upstream of death is an ancestor.
    causal_ancestors(SCM, death, As),
    % Check the ancestor set.
    msort(As, [captain, court, rifle_a, rifle_b]).

% Descendants are the transitive effects.
test(descendants) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Everything downstream of the court order is a descendant.
    causal_descendants(SCM, court, Ds),
    % Check the descendant set.
    msort(Ds, [captain, death, rifle_a, rifle_b]).

% A directed path exists from the court order to the death.
test(path_holds) :-
    % Build the firing squad model.
    squad_model(SCM),
    % The path runs court -> captain -> rifleman -> death.
    causal_path(SCM, court, death).

% No directed path runs between the two riflemen.
test(path_fails, [fail]) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Neither rifleman causes the other.
    causal_path(SCM, rifle_a, rifle_b).

:- end_tests(causal_model).

% ===========================================================================
% RUNG ONE — OBSERVATIONAL SOLVING
% ===========================================================================

:- begin_tests(causal_solve).

% With the court ordering, everything downstream fires.
test(solve_order_given) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Solve with the court order set to one.
    causal_solve(SCM, [court-1], Solution),
    % The captain signals.
    memberchk(captain-1, Solution),
    % Rifleman A fires.
    memberchk(rifle_a-1, Solution),
    % Rifleman B fires.
    memberchk(rifle_b-1, Solution),
    % The prisoner dies.
    memberchk(death-1, Solution).

% With no order, nothing happens.
test(solve_no_order) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Solve with the default context.
    causal_value(SCM, [], death, V),
    % The prisoner lives.
    V =:= 0.

% Arithmetic expressions evaluate inside equations.
test(solve_arithmetic) :-
    % Build a small arithmetic model.
    causal_model([exo(x, 3), eq(y, x * 2 + 1), eq(z, y - x)], SCM),
    % Read the derived value of y.
    causal_value(SCM, [], y, VY),
    % Check the multiplication and addition.
    VY =:= 7,
    % Read the derived value of z.
    causal_value(SCM, [], z, VZ),
    % Check the subtraction.
    VZ =:= 4.

% Conditional expressions choose the correct branch.
test(solve_conditional) :-
    % Build the sprinkler model.
    sprinkler_model(SCM),
    % In the dry season the sprinkler runs.
    causal_value(SCM, [season-1], sprinkler, 1),
    % In the dry season no rain falls.
    causal_value(SCM, [season-1], rain, 0),
    % The grass is still wet, through the sprinkler.
    causal_value(SCM, [season-1], wet, 1).

:- end_tests(causal_solve).

% ===========================================================================
% RUNG TWO — INTERVENTIONS
% ===========================================================================

:- begin_tests(causal_do).

% Forcing rifleman A to fire kills the prisoner even without an order.
test(do_forward_effect) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Force rifleman A with the court silent.
    causal_effect(SCM, [rifle_a-1], [court-0], death, V),
    % The prisoner dies.
    V =:= 1.

% An intervention does not travel backward against the arrows.
test(do_no_backtracking) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Force rifleman A with the court silent.
    causal_do(SCM, [rifle_a-1], [court-0], Solution),
    % The captain never signalled.
    memberchk(captain-0, Solution),
    % Rifleman B never fired.
    memberchk(rifle_b-0, Solution).

% Intervening on an exogenous variable is rejected.
test(do_exogenous_rejected, [fail]) :-
    % Build the firing squad model.
    squad_model(SCM),
    % The do-operator applies only to endogenous variables.
    causal_intervene(SCM, [court-1], _).

% Observation and intervention differ on the same variable.
test(seeing_versus_doing) :-
    % Build the sprinkler model.
    sprinkler_model(SCM),
    % Observing a running sprinkler in the wet season keeps the rain.
    causal_value(SCM, [season-0], rain, 1),
    % Forcing the sprinkler on does not stop the rain either.
    causal_effect(SCM, [sprinkler-1], [season-0], rain, 1),
    % But forcing the sprinkler in the dry season still wets the grass.
    causal_effect(SCM, [sprinkler-1], [season-1], wet, 1).

:- end_tests(causal_do).

% ===========================================================================
% D-SEPARATION
% ===========================================================================

:- begin_tests(causal_dsep).

% Conditioning on the common cause separates sprinkler and rain.
test(dsep_fork_blocked) :-
    % Build the sprinkler model.
    sprinkler_model(SCM),
    % Season is the fork between sprinkler and rain.
    causal_dsep(SCM, sprinkler, rain, [season]).

% Without conditioning, the fork leaves them connected.
test(dsep_fork_open, [fail]) :-
    % Build the sprinkler model.
    sprinkler_model(SCM),
    % The path through the season is open.
    causal_dsep(SCM, sprinkler, rain, []).

% Conditioning on the collider re-connects sprinkler and rain.
test(dsep_collider_opened, [fail]) :-
    % Build the sprinkler model.
    sprinkler_model(SCM),
    % Wet is a collider; conditioning on it opens the path.
    causal_dsep(SCM, sprinkler, rain, [season, wet]).

% Conditioning on a descendant of the collider also opens the path.
test(dsep_collider_descendant, [fail]) :-
    % Build the sprinkler model.
    sprinkler_model(SCM),
    % Slippery is downstream of the collider wet.
    causal_dsep(SCM, sprinkler, rain, [season, slippery]).

:- end_tests(causal_dsep).

% ===========================================================================
% RUNG THREE — COUNTERFACTUALS
% ===========================================================================

:- begin_tests(causal_counterfactual).

% Abduction recovers the only context that explains the evidence.
test(abduce_recovers_context, [nondet]) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Collect every context consistent with the observed death.
    findall(Ctx, causal_abduce(SCM, [court-[0, 1]], [death-1], Ctx), Ctxs),
    % Only the ordering court explains it.
    Ctxs == [[court-1]].

% The classic counterfactual: had rifleman A not fired, death still occurs.
test(counterfactual_rifleman, [nondet]) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Given the observed death, imagine rifleman A holding fire.
    causal_counterfactual(SCM, [court-[0, 1]], [death-1], [rifle_a-0], death, V),
    % Rifleman B still fires, so the prisoner still dies.
    V =:= 1.

% Had the captain not signalled, the prisoner would have lived.
test(counterfactual_captain, [nondet]) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Given the observed death, imagine the captain silent.
    causal_counterfactual(SCM, [court-[0, 1]], [death-1], [captain-0], death, V),
    % Both riflemen follow the captain, so the prisoner lives.
    V =:= 0.

% Without evidence the counterfactual is undetermined and fails honestly.
test(counterfactual_ambiguous, [fail]) :-
    % Build the firing squad model.
    squad_model(SCM),
    % No evidence constrains the court, so death has two possible values.
    causal_counterfactual(SCM, [court-[0, 1]], [], [rifle_a-0], death, _).

% The all-values form reports the full set of possibilities.
test(counterfactual_all_values, [nondet]) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Ask for every possible death value with no evidence.
    causal_counterfactual_all(SCM, [court-[0, 1]], [], [rifle_a-0], death, Vs),
    % Both outcomes remain possible.
    Vs == [0, 1].

% The captain passes the but-for test of actual causation.
test(but_for_captain, [nondet]) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Had the captain acted otherwise, death would change.
    causal_but_for(SCM, [court-1], captain, [0], death).

% A single rifleman fails the but-for test because of redundancy.
test(but_for_rifleman, [fail]) :-
    % Build the firing squad model.
    squad_model(SCM),
    % Rifleman B fires anyway, so A alone is not necessary.
    causal_but_for(SCM, [court-1], rifle_a, [0], death).

:- end_tests(causal_counterfactual).
