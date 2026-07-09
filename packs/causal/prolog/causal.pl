/*  PrologAI — Causal Models  (WP-383, Layer 358)

    Structural Causal Models (SCM) for the three rungs of the causal ladder:
    seeing (observation), doing (intervention), and imagining (counterfactual).

    A model is built from a list of variable declarations:

        exo(U, Default)   an exogenous (outside-caused) variable with a
                          default value used when no context supplies one.
        eq(X, Expr)       an endogenous variable X defined by a structural
                          equation Expr over other variable names.

    Expr language: numbers, variable name atoms, A + B, A - B, A * B,
    min(A,B), max(A,B), and if(Cond, Then, Else) where Cond is one of
    gt/2, lt/2, geq/2, leq/2, eqv/2, and/2, or/2, not/1.

    Contexts, evidence, interventions, and solutions are lists of
    Var-Value pairs.

    Counterfactuals follow the three-step recipe: abduction (recover the
    exogenous context that explains the evidence), action (surgically
    replace the equation of the intervened variable), and prediction
    (solve the mutilated model).

    Exported predicates:

    cf_model/2               +Decls, -SCM
    cf_variables/2           +SCM, -Vars
    cf_exogenous/2           +SCM, -Us
    cf_endogenous/2          +SCM, -Xs
    cf_parents/3             +SCM, +X, -Parents
    cf_children/3            +SCM, +X, -Children
    cf_ancestors/3           +SCM, +X, -Ancestors
    cf_descendants/3         +SCM, +X, -Descendants
    cf_path/3                +SCM, +X, +Y
    cf_dsep/4                +SCM, +X, +Y, +Zs
    cf_solve/3               +SCM, +Context, -Solution
    cf_value/4               +SCM, +Context, +X, -V
    cf_intervene/3           +SCM, +Interventions, -SCM2
    cf_do/4                  +SCM, +Interventions, +Context, -Solution
    cf_effect/5              +SCM, +Interventions, +Context, +Y, -V
    cf_abduce/4              +SCM, +Domains, +Evidence, -Context
    cf_counterfactual/6      +SCM, +Domains, +Evidence, +Interventions, +Y, -V
    cf_counterfactual_all/6  +SCM, +Domains, +Evidence, +Interventions, +Y, -Vs
    cf_but_for/5             +SCM, +Context, +X, +Alts, +Y
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(causal, [
    % cf_model/2: build and validate a structural causal model.
    cf_model/2,
    % cf_variables/2: every variable name in the model.
    cf_variables/2,
    % cf_exogenous/2: the exogenous variable names.
    cf_exogenous/2,
    % cf_endogenous/2: the endogenous variable names.
    cf_endogenous/2,
    % cf_parents/3: direct causes of a variable.
    cf_parents/3,
    % cf_children/3: direct effects of a variable.
    cf_children/3,
    % cf_ancestors/3: transitive causes of a variable.
    cf_ancestors/3,
    % cf_descendants/3: transitive effects of a variable.
    cf_descendants/3,
    % cf_path/3: directed causal path test.
    cf_path/3,
    % cf_dsep/4: d-separation test given a conditioning set.
    cf_dsep/4,
    % cf_solve/3: rung one — solve the model observationally.
    cf_solve/3,
    % cf_value/4: value of one variable in the observational solution.
    cf_value/4,
    % cf_intervene/3: rung two — graph surgery with the do-operator.
    cf_intervene/3,
    % cf_do/4: solve the model under interventions.
    cf_do/4,
    % cf_effect/5: value of one variable under interventions.
    cf_effect/5,
    % cf_abduce/4: recover exogenous contexts consistent with evidence.
    cf_abduce/4,
    % cf_counterfactual/6: rung three — determined counterfactual value.
    cf_counterfactual/6,
    % cf_counterfactual_all/6: all possible counterfactual values.
    cf_counterfactual_all/6,
    % cf_but_for/5: but-for test of actual causation.
    cf_but_for/5
]).

% Use the lists library for member/2, subtract/3, and friends.
:- use_module(library(lists)).

% ===========================================================================
% MODEL CONSTRUCTION
% ===========================================================================

% cf_model(+Decls, -SCM): build scm(Exos, Order, Eqs) from declarations.
cf_model(Decls, scm(Exos, Order, Eqs)) :-
    % Collect every exogenous declaration as a U-Default pair.
    findall(U-D, member(exo(U, D), Decls), Exos),
    % Collect every endogenous equation.
    findall(eq(X, E), member(eq(X, E), Decls), Eqs),
    % Extract the exogenous names.
    pairs_keys(Exos, Us),
    % Extract the endogenous names.
    findall(X, member(eq(X, _), Eqs), Xs),
    % Append both name lists.
    append(Us, Xs, AllNames),
    % Sort the names to detect duplicates.
    msort(AllNames, SortedNames),
    % Every declared name must be unique.
    is_set_sorted(SortedNames),
    % Every referenced variable must be declared.
    forall(
        % Take each equation in turn.
        member(eq(_, Expr), Eqs),
        % Check its referenced variables against the declared names.
        cf_refs_declared(Expr, AllNames)),
    % Order the endogenous variables so parents come before children.
    cf_topo_order(Eqs, Xs, Order).

% is_set_sorted(+Sorted): a sorted list has no adjacent duplicates.
is_set_sorted([]).
% A single element is always a set.
is_set_sorted([_]).
% Two adjacent elements must differ, then check the rest.
is_set_sorted([A, B | T]) :-
    % The pair must not be identical.
    A \== B,
    % Recurse over the remainder.
    is_set_sorted([B | T]).

% cf_refs_declared(+Expr, +Names): all variables in Expr are declared.
cf_refs_declared(Expr, Names) :-
    % Gather the variables referenced by the expression.
    cf_expr_vars(Expr, Vars),
    % Every referenced variable must appear among the declared names.
    forall(member(V, Vars), memberchk(V, Names)).

% cf_topo_order(+Eqs, +Xs, -Order): Kahn-style topological sort; fails on cycles.
cf_topo_order(Eqs, Xs, Order) :-
    % Start with no variable ordered yet.
    cf_topo(Xs, Eqs, [], RevOrder),
    % The accumulator was built newest-first, so reverse it.
    reverse(RevOrder, Order).

% cf_topo(+Pending, +Eqs, +Done, -RevOrder): move ready variables to Done.
cf_topo([], _, Done, Done).
% While variables remain, one of them must have all parents already done.
cf_topo(Pending, Eqs, Done, Order) :-
    % Pending is non-empty here.
    Pending = [_|_],
    % Select a pending variable whose endogenous parents are all done.
    select(X, Pending, Rest),
    % Look up the equation of the selected variable.
    memberchk(eq(X, Expr), Eqs),
    % Gather the variables its equation references.
    cf_expr_vars(Expr, Vars),
    % Keep only the endogenous ones (those defined by some equation).
    findall(V, (member(V, Vars), memberchk(eq(V, _), Eqs)), Deps),
    % Every endogenous dependency must already be ordered.
    forall(member(D, Deps), memberchk(D, Done)),
    % Commit to this choice — any valid topological order will do.
    !,
    % Continue with the remaining pending variables.
    cf_topo(Rest, Eqs, [X | Done], Order).

% ===========================================================================
% EXPRESSION EVALUATION
% ===========================================================================

% cf_expr_vars(+Expr, -Vars): sorted variable names referenced by Expr.
cf_expr_vars(Expr, Vars) :-
    % Collect the names with duplicates.
    cf_expr_vars_(Expr, Raw),
    % Sort and de-duplicate.
    sort(Raw, Vars).

% A number references no variables.
cf_expr_vars_(N, []) :-
    % Confirm it is a number.
    number(N),
    % Stop looking at other clauses.
    !.
% A lone atom is a variable reference.
cf_expr_vars_(A, [A]) :-
    % Confirm it is an atom.
    atom(A),
    % Stop looking at other clauses.
    !.
% An if-expression references its condition and both branches.
cf_expr_vars_(if(C, T, E), Vars) :-
    % Commit to the if shape.
    !,
    % Variables of the condition.
    cf_cond_vars_(C, V1),
    % Variables of the then-branch.
    cf_expr_vars_(T, V2),
    % Variables of the else-branch.
    cf_expr_vars_(E, V3),
    % Join all three lists.
    append([V1, V2, V3], Vars).
% Any other compound distributes over its two arguments.
cf_expr_vars_(Expr, Vars) :-
    % Decompose the binary operator term.
    Expr =.. [_, A, B],
    % Variables of the left argument.
    cf_expr_vars_(A, V1),
    % Variables of the right argument.
    cf_expr_vars_(B, V2),
    % Join the two lists.
    append(V1, V2, Vars).

% cf_cond_vars_(+Cond, -Vars): variable names referenced by a condition.
cf_cond_vars_(not(C), Vars) :-
    % Commit to the negation shape.
    !,
    % A negation references whatever its inner condition references.
    cf_cond_vars_(C, Vars).
% Conjunction and disjunction reference both sides.
cf_cond_vars_(C, Vars) :-
    % Match and/2 or or/2.
    ( C = and(A, B) ; C = or(A, B) ),
    % Commit to the connective shape.
    !,
    % Variables of the left condition.
    cf_cond_vars_(A, V1),
    % Variables of the right condition.
    cf_cond_vars_(B, V2),
    % Join the two lists.
    append(V1, V2, Vars).
% Comparisons reference the variables of their two expressions.
cf_cond_vars_(C, Vars) :-
    % Decompose the comparison term.
    C =.. [_, A, B],
    % Variables of the left expression.
    cf_expr_vars_(A, V1),
    % Variables of the right expression.
    cf_expr_vars_(B, V2),
    % Join the two lists.
    append(V1, V2, Vars).

% cf_eval(+Expr, +Env, -V): evaluate an expression in an environment.
cf_eval(N, _, N) :-
    % A number evaluates to itself.
    number(N),
    % Stop looking at other clauses.
    !.
% An atom evaluates to its bound value in the environment.
cf_eval(A, Env, V) :-
    % Confirm it is an atom.
    atom(A),
    % Commit to the variable-lookup shape.
    !,
    % Look the value up in the environment.
    memberchk(A-V, Env).
% An if-expression evaluates its condition and picks a branch.
cf_eval(if(C, T, E), Env, V) :-
    % Commit to the if shape.
    !,
    % Test the condition and choose the branch to evaluate.
    (   cf_cond(C, Env)
    % When the condition holds, evaluate the then-branch.
    ->  cf_eval(T, Env, V)
    % Otherwise evaluate the else-branch.
    ;   cf_eval(E, Env, V)
    ).
% Addition evaluates both sides and sums them.
cf_eval(A + B, Env, V) :-
    % Commit to the addition shape.
    !,
    % Evaluate the left side.
    cf_eval(A, Env, VA),
    % Evaluate the right side.
    cf_eval(B, Env, VB),
    % Add the two values.
    V is VA + VB.
% Subtraction evaluates both sides and subtracts them.
cf_eval(A - B, Env, V) :-
    % Commit to the subtraction shape.
    !,
    % Evaluate the left side.
    cf_eval(A, Env, VA),
    % Evaluate the right side.
    cf_eval(B, Env, VB),
    % Subtract the right value from the left.
    V is VA - VB.
% Multiplication evaluates both sides and multiplies them.
cf_eval(A * B, Env, V) :-
    % Commit to the multiplication shape.
    !,
    % Evaluate the left side.
    cf_eval(A, Env, VA),
    % Evaluate the right side.
    cf_eval(B, Env, VB),
    % Multiply the two values.
    V is VA * VB.
% Minimum evaluates both sides and keeps the smaller.
cf_eval(min(A, B), Env, V) :-
    % Commit to the minimum shape.
    !,
    % Evaluate the left side.
    cf_eval(A, Env, VA),
    % Evaluate the right side.
    cf_eval(B, Env, VB),
    % Keep the smaller value.
    V is min(VA, VB).
% Maximum evaluates both sides and keeps the larger.
cf_eval(max(A, B), Env, V) :-
    % Commit to the maximum shape.
    !,
    % Evaluate the left side.
    cf_eval(A, Env, VA),
    % Evaluate the right side.
    cf_eval(B, Env, VB),
    % Keep the larger value.
    V is max(VA, VB).

% cf_cond(+Cond, +Env): succeed when the condition holds in the environment.
cf_cond(gt(A, B), Env) :-
    % Evaluate the left expression.
    cf_eval(A, Env, VA),
    % Evaluate the right expression.
    cf_eval(B, Env, VB),
    % Compare the two values.
    VA > VB.
% Less-than comparison.
cf_cond(lt(A, B), Env) :-
    % Evaluate the left expression.
    cf_eval(A, Env, VA),
    % Evaluate the right expression.
    cf_eval(B, Env, VB),
    % Compare the two values.
    VA < VB.
% Greater-or-equal comparison.
cf_cond(geq(A, B), Env) :-
    % Evaluate the left expression.
    cf_eval(A, Env, VA),
    % Evaluate the right expression.
    cf_eval(B, Env, VB),
    % Compare the two values.
    VA >= VB.
% Less-or-equal comparison.
cf_cond(leq(A, B), Env) :-
    % Evaluate the left expression.
    cf_eval(A, Env, VA),
    % Evaluate the right expression.
    cf_eval(B, Env, VB),
    % Compare the two values.
    VA =< VB.
% Numeric equality comparison.
cf_cond(eqv(A, B), Env) :-
    % Evaluate the left expression.
    cf_eval(A, Env, VA),
    % Evaluate the right expression.
    cf_eval(B, Env, VB),
    % Compare the two values.
    VA =:= VB.
% Conjunction of two conditions.
cf_cond(and(A, B), Env) :-
    % The left condition must hold.
    cf_cond(A, Env),
    % The right condition must hold.
    cf_cond(B, Env).
% Disjunction of two conditions.
cf_cond(or(A, B), Env) :-
    % Either the left condition holds or the right one does.
    ( cf_cond(A, Env) -> true ; cf_cond(B, Env) ).
% Negation of a condition.
cf_cond(not(C), Env) :-
    % The inner condition must fail.
    \+ cf_cond(C, Env).

% ===========================================================================
% VARIABLE SETS AND GRAPH QUERIES
% ===========================================================================

% cf_variables(+SCM, -Vars): all variable names, exogenous then endogenous.
cf_variables(scm(Exos, Order, _), Vars) :-
    % Extract the exogenous names.
    pairs_keys(Exos, Us),
    % Append the ordered endogenous names.
    append(Us, Order, Vars).

% cf_exogenous(+SCM, -Us): the exogenous variable names.
cf_exogenous(scm(Exos, _, _), Us) :-
    % Extract the keys of the exogenous pairs.
    pairs_keys(Exos, Us).

% cf_endogenous(+SCM, -Xs): the endogenous variable names in causal order.
cf_endogenous(scm(_, Order, _), Order).

% cf_parents(+SCM, +X, -Parents): direct causes of X.
cf_parents(scm(_, _, Eqs), X, Parents) :-
    % When X has an equation, its parents are the referenced variables.
    (   memberchk(eq(X, Expr), Eqs)
    % Gather the referenced variables from the equation.
    ->  cf_expr_vars(Expr, Parents)
    % An exogenous variable has no parents inside the model.
    ;   Parents = []
    ).

% cf_children(+SCM, +X, -Children): direct effects of X.
cf_children(scm(_, _, Eqs) , X, Children) :-
    % Collect every variable whose equation references X.
    findall(Y,
        % Examine each equation in turn.
        ( member(eq(Y, Expr), Eqs),
          % Gather the variables referenced by that equation.
          cf_expr_vars(Expr, Vars),
          % Keep Y when X is among them.
          memberchk(X, Vars) ),
        Raw),
    % Sort and de-duplicate the children.
    sort(Raw, Children).

% cf_ancestors(+SCM, +X, -Ancestors): transitive closure of parents.
cf_ancestors(SCM, X, Ancestors) :-
    % Expand the frontier starting from the direct parents.
    cf_closure([X], SCM, cf_parents, [], Raw),
    % X is not its own ancestor.
    subtract(Raw, [X], NoSelf),
    % Sort the result.
    sort(NoSelf, Ancestors).

% cf_descendants(+SCM, +X, -Descendants): transitive closure of children.
cf_descendants(SCM, X, Descendants) :-
    % Expand the frontier starting from the direct children.
    cf_closure([X], SCM, cf_children, [], Raw),
    % X is not its own descendant.
    subtract(Raw, [X], NoSelf),
    % Sort the result.
    sort(NoSelf, Descendants).

% cf_closure(+Frontier, +SCM, +Step, +Seen, -All): generic reachability.
cf_closure([], _, _, Seen, Seen).
% Take the next node off the frontier.
cf_closure([N | Rest], SCM, Step, Seen, All) :-
    % Skip nodes already visited.
    (   memberchk(N, Seen)
    % Continue with the rest of the frontier.
    ->  cf_closure(Rest, SCM, Step, Seen, All)
    % Otherwise expand this node.
    ;   call(Step, SCM, N, Next),
        % Push the neighbours onto the frontier.
        append(Next, Rest, Frontier2),
        % Record the node as visited and continue.
        cf_closure(Frontier2, SCM, Step, [N | Seen], All)
    ).

% cf_path(+SCM, +X, +Y): a directed causal path runs from X to Y.
cf_path(SCM, X, Y) :-
    % Y must be among the descendants of X.
    cf_descendants(SCM, X, Ds),
    % Membership check completes the test.
    memberchk(Y, Ds).

% ===========================================================================
% D-SEPARATION
% ===========================================================================

% cf_dsep(+SCM, +X, +Y, +Zs): X and Y are d-separated given conditioning set Zs.
cf_dsep(SCM, X, Y, Zs) :-
    % Every undirected path between X and Y must be blocked by Zs.
    forall(cf_upath(SCM, X, Y, Path), cf_blocked_path(SCM, Path, Zs)).

% cf_upath(+SCM, +X, +Y, -Path): an undirected simple path from X to Y.
cf_upath(SCM, X, Y, Path) :-
    % Walk the undirected graph without revisiting nodes.
    cf_upath_walk(SCM, X, Y, [X], Rev),
    % The walk builds the path in reverse.
    reverse(Rev, Path).

% cf_upath_walk(+SCM, +N, +Y, +Visited, -RevPath): depth-first walk.
cf_upath_walk(_, Y, Y, Visited, Visited).
% Otherwise extend the walk by one undirected edge.
cf_upath_walk(SCM, N, Y, Visited, Path) :-
    % The current node is not yet the target.
    N \== Y,
    % Take any undirected neighbour of the current node.
    cf_neighbour(SCM, N, M),
    % Do not revisit a node already on the walk.
    \+ memberchk(M, Visited),
    % Continue the walk from the neighbour.
    cf_upath_walk(SCM, M, Y, [M | Visited], Path).

% cf_neighbour(+SCM, +N, -M): M is a parent or child of N.
cf_neighbour(SCM, N, M) :-
    % Gather the parents of N.
    cf_parents(SCM, N, Ps),
    % Gather the children of N.
    cf_children(SCM, N, Cs),
    % Join both neighbour lists.
    append(Ps, Cs, Ns),
    % Enumerate each neighbour.
    member(M, Ns).

% cf_blocked_path(+SCM, +Path, +Zs): some triple on the path blocks it.
cf_blocked_path(SCM, Path, Zs) :-
    % Find three consecutive nodes A, W, B on the path.
    append(_, [A, W, B | _], Path),
    % The middle node must block the flow given Zs.
    cf_blocked_triple(SCM, A, W, B, Zs),
    % One blocking triple suffices.
    !.

% cf_blocked_triple(+SCM, +A, +W, +B, +Zs): classify and test the triple.
cf_blocked_triple(SCM, A, W, B, Zs) :-
    % Is W a collider, with both arrows pointing into it?
    (   cf_edge(SCM, A, W),
        % Check the second incoming arrow.
        cf_edge(SCM, B, W)
    % A collider blocks unless W or one of its descendants is conditioned on.
    ->  \+ memberchk(W, Zs),
        % Gather the descendants of the collider.
        cf_descendants(SCM, W, Ds),
        % None of the descendants may be in the conditioning set.
        \+ ( member(D, Ds), memberchk(D, Zs) )
    % A chain or fork blocks exactly when W is conditioned on.
    ;   memberchk(W, Zs)
    ).

% cf_edge(+SCM, +From, +To): a directed edge runs From -> To.
cf_edge(SCM, From, To) :-
    % From must be among the parents of To.
    cf_parents(SCM, To, Ps),
    % Membership check completes the test.
    memberchk(From, Ps).

% ===========================================================================
% RUNG ONE — SEEING (OBSERVATIONAL SOLVING)
% ===========================================================================

% cf_solve(+SCM, +Context, -Solution): evaluate every variable.
cf_solve(scm(Exos, Order, Eqs), Context, Solution) :-
    % Bind each exogenous variable from the context or its default.
    findall(U-V,
        % Take each exogenous pair in turn.
        ( member(U-D, Exos),
          % Prefer a context value; otherwise use the default.
          ( memberchk(U-CV, Context) -> V = CV ; V = D ) ),
        Env0),
    % Evaluate the endogenous equations in causal order.
    cf_solve_order(Order, Eqs, Env0, Solution).

% cf_solve_order(+Order, +Eqs, +Env, -Solution): fold the causal order.
cf_solve_order([], _, Env, Env).
% Evaluate the next variable and extend the environment.
cf_solve_order([X | Rest], Eqs, Env, Solution) :-
    % Look up the equation of the next variable.
    memberchk(eq(X, Expr), Eqs),
    % Evaluate the equation in the current environment.
    cf_eval(Expr, Env, V),
    % Append the new binding at the end to preserve order.
    append(Env, [X-V], Env2),
    % Continue with the remaining variables.
    cf_solve_order(Rest, Eqs, Env2, Solution).

% cf_value(+SCM, +Context, +X, -V): one variable's observational value.
cf_value(SCM, Context, X, V) :-
    % Solve the whole model first.
    cf_solve(SCM, Context, Solution),
    % Read the requested variable from the solution.
    memberchk(X-V, Solution).

% ===========================================================================
% RUNG TWO — DOING (INTERVENTION)
% ===========================================================================

% cf_intervene(+SCM, +Interventions, -SCM2): graph surgery with do().
cf_intervene(SCM, [], SCM).
% Apply the first intervention, then the rest.
cf_intervene(scm(Exos, Order, Eqs), [X-V | Rest], SCM2) :-
    % The intervened variable must be endogenous.
    memberchk(eq(X, _), Eqs),
    % Cut the variable loose from its old causes.
    selectchk(eq(X, _), Eqs, eq(X, V), Eqs2),
    % Continue with the remaining interventions.
    cf_intervene(scm(Exos, Order, Eqs2), Rest, SCM2).

% cf_do(+SCM, +Interventions, +Context, -Solution): solve the mutilated model.
cf_do(SCM, Interventions, Context, Solution) :-
    % Perform the surgery.
    cf_intervene(SCM, Interventions, SCM2),
    % Solve the mutilated model in the given context.
    cf_solve(SCM2, Context, Solution).

% cf_effect(+SCM, +Interventions, +Context, +Y, -V): one variable under do().
cf_effect(SCM, Interventions, Context, Y, V) :-
    % Solve under the interventions.
    cf_do(SCM, Interventions, Context, Solution),
    % Read the requested variable from the solution.
    memberchk(Y-V, Solution).

% ===========================================================================
% RUNG THREE — IMAGINING (COUNTERFACTUALS)
% ===========================================================================

% cf_abduce(+SCM, +Domains, +Evidence, -Context): step one, abduction.
cf_abduce(SCM, Domains, Evidence, Context) :-
    % Enumerate one candidate assignment over the exogenous domains.
    cf_assign(Domains, Context),
    % Solve the model under the candidate context.
    cf_solve(SCM, Context, Solution),
    % Every piece of evidence must match the solution.
    forall(member(Var-Val, Evidence), memberchk(Var-Val, Solution)).

% cf_assign(+Domains, -Context): pick one value from each domain.
cf_assign([], []).
% Choose a value for the first variable, then the rest.
cf_assign([U-Dom | Rest], [U-V | Ctx]) :-
    % Enumerate the values of this domain.
    member(V, Dom),
    % Assign the remaining domains.
    cf_assign(Rest, Ctx).

% cf_counterfactual(+SCM, +Domains, +Evidence, +Ints, +Y, -V): determined value.
cf_counterfactual(SCM, Domains, Evidence, Interventions, Y, V) :-
    % Compute every counterfactual value the evidence allows.
    cf_counterfactual_all(SCM, Domains, Evidence, Interventions, Y, Vs),
    % The counterfactual is determined only when exactly one value remains.
    Vs = [V].

% cf_counterfactual_all(+SCM, +Domains, +Evidence, +Ints, +Y, -Vs): all values.
cf_counterfactual_all(SCM, Domains, Evidence, Interventions, Y, Vs) :-
    % Collect the counterfactual value under every consistent context.
    findall(V,
        % Abduction: recover a context consistent with the evidence.
        ( cf_abduce(SCM, Domains, Evidence, Context),
          % Action and prediction: solve the mutilated model in that context.
          cf_effect(SCM, Interventions, Context, Y, V) ),
        Raw),
    % At least one context must explain the evidence.
    Raw \== [],
    % Sort and de-duplicate the possible values.
    sort(Raw, Vs).

% cf_but_for(+SCM, +Context, +X, +Alts, +Y): X was necessary for Y's value.
cf_but_for(SCM, Context, X, Alts, Y) :-
    % Find the actual value of Y in this context.
    cf_value(SCM, Context, Y, Actual),
    % Some alternative setting of X must change Y.
    member(Alt, Alts),
    % Compute Y under the alternative intervention.
    cf_effect(SCM, [X-Alt], Context, Y, Other),
    % The but-for test passes when the value differs.
    Other =\= Actual,
    % One witnessing alternative suffices.
    !.
