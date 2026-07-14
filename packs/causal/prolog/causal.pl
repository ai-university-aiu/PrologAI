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

    causal_model/2               +Decls, -SCM
    causal_variables/2           +SCM, -Vars
    causal_exogenous/2           +SCM, -Us
    causal_endogenous/2          +SCM, -Xs
    causal_parents/3             +SCM, +X, -Parents
    causal_children/3            +SCM, +X, -Children
    causal_ancestors/3           +SCM, +X, -Ancestors
    causal_descendants/3         +SCM, +X, -Descendants
    causal_path/3                +SCM, +X, +Y
    causal_dsep/4                +SCM, +X, +Y, +Zs
    causal_solve/3               +SCM, +Context, -Solution
    causal_value/4               +SCM, +Context, +X, -V
    causal_intervene/3           +SCM, +Interventions, -SCM2
    causal_do/4                  +SCM, +Interventions, +Context, -Solution
    causal_effect/5              +SCM, +Interventions, +Context, +Y, -V
    causal_abduce/4              +SCM, +Domains, +Evidence, -Context
    causal_counterfactual/6      +SCM, +Domains, +Evidence, +Interventions, +Y, -V
    causal_counterfactual_all/6  +SCM, +Domains, +Evidence, +Interventions, +Y, -Vs
    causal_but_for/5             +SCM, +Context, +X, +Alts, +Y
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(causal, [
    % causal_model/2: build and validate a structural causal model.
    causal_model/2,
    % causal_variables/2: every variable name in the model.
    causal_variables/2,
    % causal_exogenous/2: the exogenous variable names.
    causal_exogenous/2,
    % causal_endogenous/2: the endogenous variable names.
    causal_endogenous/2,
    % causal_parents/3: direct causes of a variable.
    causal_parents/3,
    % causal_children/3: direct effects of a variable.
    causal_children/3,
    % causal_ancestors/3: transitive causes of a variable.
    causal_ancestors/3,
    % causal_descendants/3: transitive effects of a variable.
    causal_descendants/3,
    % causal_path/3: directed causal path test.
    causal_path/3,
    % causal_dsep/4: d-separation test given a conditioning set.
    causal_dsep/4,
    % causal_solve/3: rung one — solve the model observationally.
    causal_solve/3,
    % causal_value/4: value of one variable in the observational solution.
    causal_value/4,
    % causal_intervene/3: rung two — graph surgery with the do-operator.
    causal_intervene/3,
    % causal_do/4: solve the model under interventions.
    causal_do/4,
    % causal_effect/5: value of one variable under interventions.
    causal_effect/5,
    % causal_abduce/4: recover exogenous contexts consistent with evidence.
    causal_abduce/4,
    % causal_counterfactual/6: rung three — determined counterfactual value.
    causal_counterfactual/6,
    % causal_counterfactual_all/6: all possible counterfactual values.
    causal_counterfactual_all/6,
    % causal_but_for/5: but-for test of actual causation.
    causal_but_for/5
]).

% Use the lists library for member/2, subtract/3, and friends.
:- use_module(library(lists)).

% ===========================================================================
% MODEL CONSTRUCTION
% ===========================================================================

% causal_model(+Decls, -SCM): build scm(Exos, Order, Eqs) from declarations.
causal_model(Decls, scm(Exos, Order, Eqs)) :-
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
        causal_refs_declared(Expr, AllNames)),
    % Order the endogenous variables so parents come before children.
    causal_topo_order(Eqs, Xs, Order).

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

% causal_refs_declared(+Expr, +Names): all variables in Expr are declared.
causal_refs_declared(Expr, Names) :-
    % Gather the variables referenced by the expression.
    causal_expr_vars(Expr, Vars),
    % Every referenced variable must appear among the declared names.
    forall(member(V, Vars), memberchk(V, Names)).

% causal_topo_order(+Eqs, +Xs, -Order): Kahn-style topological sort; fails on cycles.
causal_topo_order(Eqs, Xs, Order) :-
    % Start with no variable ordered yet.
    causal_topo(Xs, Eqs, [], RevOrder),
    % The accumulator was built newest-first, so reverse it.
    reverse(RevOrder, Order).

% causal_topo(+Pending, +Eqs, +Done, -RevOrder): move ready variables to Done.
causal_topo([], _, Done, Done).
% While variables remain, one of them must have all parents already done.
causal_topo(Pending, Eqs, Done, Order) :-
    % Pending is non-empty here.
    Pending = [_|_],
    % Select a pending variable whose endogenous parents are all done.
    select(X, Pending, Rest),
    % Look up the equation of the selected variable.
    memberchk(eq(X, Expr), Eqs),
    % Gather the variables its equation references.
    causal_expr_vars(Expr, Vars),
    % Keep only the endogenous ones (those defined by some equation).
    findall(V, (member(V, Vars), memberchk(eq(V, _), Eqs)), Deps),
    % Every endogenous dependency must already be ordered.
    forall(member(D, Deps), memberchk(D, Done)),
    % Commit to this choice — any valid topological order will do.
    !,
    % Continue with the remaining pending variables.
    causal_topo(Rest, Eqs, [X | Done], Order).

% ===========================================================================
% EXPRESSION EVALUATION
% ===========================================================================

% causal_expr_vars(+Expr, -Vars): sorted variable names referenced by Expr.
causal_expr_vars(Expr, Vars) :-
    % Collect the names with duplicates.
    causal_expr_vars_(Expr, Raw),
    % Sort and de-duplicate.
    sort(Raw, Vars).

% A number references no variables.
causal_expr_vars_(N, []) :-
    % Confirm it is a number.
    number(N),
    % Stop looking at other clauses.
    !.
% A lone atom is a variable reference.
causal_expr_vars_(A, [A]) :-
    % Confirm it is an atom.
    atom(A),
    % Stop looking at other clauses.
    !.
% An if-expression references its condition and both branches.
causal_expr_vars_(if(C, T, E), Vars) :-
    % Commit to the if shape.
    !,
    % Variables of the condition.
    causal_cond_vars_(C, V1),
    % Variables of the then-branch.
    causal_expr_vars_(T, V2),
    % Variables of the else-branch.
    causal_expr_vars_(E, V3),
    % Join all three lists.
    append([V1, V2, V3], Vars).
% Any other compound distributes over its two arguments.
causal_expr_vars_(Expr, Vars) :-
    % Decompose the binary operator term.
    Expr =.. [_, A, B],
    % Variables of the left argument.
    causal_expr_vars_(A, V1),
    % Variables of the right argument.
    causal_expr_vars_(B, V2),
    % Join the two lists.
    append(V1, V2, Vars).

% causal_cond_vars_(+Cond, -Vars): variable names referenced by a condition.
causal_cond_vars_(not(C), Vars) :-
    % Commit to the negation shape.
    !,
    % A negation references whatever its inner condition references.
    causal_cond_vars_(C, Vars).
% Conjunction and disjunction reference both sides.
causal_cond_vars_(C, Vars) :-
    % Match and/2 or or/2.
    ( C = and(A, B) ; C = or(A, B) ),
    % Commit to the connective shape.
    !,
    % Variables of the left condition.
    causal_cond_vars_(A, V1),
    % Variables of the right condition.
    causal_cond_vars_(B, V2),
    % Join the two lists.
    append(V1, V2, Vars).
% Comparisons reference the variables of their two expressions.
causal_cond_vars_(C, Vars) :-
    % Decompose the comparison term.
    C =.. [_, A, B],
    % Variables of the left expression.
    causal_expr_vars_(A, V1),
    % Variables of the right expression.
    causal_expr_vars_(B, V2),
    % Join the two lists.
    append(V1, V2, Vars).

% causal_eval(+Expr, +Env, -V): evaluate an expression in an environment.
causal_eval(N, _, N) :-
    % A number evaluates to itself.
    number(N),
    % Stop looking at other clauses.
    !.
% An atom evaluates to its bound value in the environment.
causal_eval(A, Env, V) :-
    % Confirm it is an atom.
    atom(A),
    % Commit to the variable-lookup shape.
    !,
    % Look the value up in the environment.
    memberchk(A-V, Env).
% An if-expression evaluates its condition and picks a branch.
causal_eval(if(C, T, E), Env, V) :-
    % Commit to the if shape.
    !,
    % Test the condition and choose the branch to evaluate.
    (   causal_cond(C, Env)
    % When the condition holds, evaluate the then-branch.
    ->  causal_eval(T, Env, V)
    % Otherwise evaluate the else-branch.
    ;   causal_eval(E, Env, V)
    ).
% Addition evaluates both sides and sums them.
causal_eval(A + B, Env, V) :-
    % Commit to the addition shape.
    !,
    % Evaluate the left side.
    causal_eval(A, Env, VA),
    % Evaluate the right side.
    causal_eval(B, Env, VB),
    % Add the two values.
    V is VA + VB.
% Subtraction evaluates both sides and subtracts them.
causal_eval(A - B, Env, V) :-
    % Commit to the subtraction shape.
    !,
    % Evaluate the left side.
    causal_eval(A, Env, VA),
    % Evaluate the right side.
    causal_eval(B, Env, VB),
    % Subtract the right value from the left.
    V is VA - VB.
% Multiplication evaluates both sides and multiplies them.
causal_eval(A * B, Env, V) :-
    % Commit to the multiplication shape.
    !,
    % Evaluate the left side.
    causal_eval(A, Env, VA),
    % Evaluate the right side.
    causal_eval(B, Env, VB),
    % Multiply the two values.
    V is VA * VB.
% Minimum evaluates both sides and keeps the smaller.
causal_eval(min(A, B), Env, V) :-
    % Commit to the minimum shape.
    !,
    % Evaluate the left side.
    causal_eval(A, Env, VA),
    % Evaluate the right side.
    causal_eval(B, Env, VB),
    % Keep the smaller value.
    V is min(VA, VB).
% Maximum evaluates both sides and keeps the larger.
causal_eval(max(A, B), Env, V) :-
    % Commit to the maximum shape.
    !,
    % Evaluate the left side.
    causal_eval(A, Env, VA),
    % Evaluate the right side.
    causal_eval(B, Env, VB),
    % Keep the larger value.
    V is max(VA, VB).

% causal_cond(+Cond, +Env): succeed when the condition holds in the environment.
causal_cond(gt(A, B), Env) :-
    % Evaluate the left expression.
    causal_eval(A, Env, VA),
    % Evaluate the right expression.
    causal_eval(B, Env, VB),
    % Compare the two values.
    VA > VB.
% Less-than comparison.
causal_cond(lt(A, B), Env) :-
    % Evaluate the left expression.
    causal_eval(A, Env, VA),
    % Evaluate the right expression.
    causal_eval(B, Env, VB),
    % Compare the two values.
    VA < VB.
% Greater-or-equal comparison.
causal_cond(geq(A, B), Env) :-
    % Evaluate the left expression.
    causal_eval(A, Env, VA),
    % Evaluate the right expression.
    causal_eval(B, Env, VB),
    % Compare the two values.
    VA >= VB.
% Less-or-equal comparison.
causal_cond(leq(A, B), Env) :-
    % Evaluate the left expression.
    causal_eval(A, Env, VA),
    % Evaluate the right expression.
    causal_eval(B, Env, VB),
    % Compare the two values.
    VA =< VB.
% Numeric equality comparison.
causal_cond(eqv(A, B), Env) :-
    % Evaluate the left expression.
    causal_eval(A, Env, VA),
    % Evaluate the right expression.
    causal_eval(B, Env, VB),
    % Compare the two values.
    VA =:= VB.
% Conjunction of two conditions.
causal_cond(and(A, B), Env) :-
    % The left condition must hold.
    causal_cond(A, Env),
    % The right condition must hold.
    causal_cond(B, Env).
% Disjunction of two conditions.
causal_cond(or(A, B), Env) :-
    % Either the left condition holds or the right one does.
    ( causal_cond(A, Env) -> true ; causal_cond(B, Env) ).
% Negation of a condition.
causal_cond(not(C), Env) :-
    % The inner condition must fail.
    \+ causal_cond(C, Env).

% ===========================================================================
% VARIABLE SETS AND GRAPH QUERIES
% ===========================================================================

% causal_variables(+SCM, -Vars): all variable names, exogenous then endogenous.
causal_variables(scm(Exos, Order, _), Vars) :-
    % Extract the exogenous names.
    pairs_keys(Exos, Us),
    % Append the ordered endogenous names.
    append(Us, Order, Vars).

% causal_exogenous(+SCM, -Us): the exogenous variable names.
causal_exogenous(scm(Exos, _, _), Us) :-
    % Extract the keys of the exogenous pairs.
    pairs_keys(Exos, Us).

% causal_endogenous(+SCM, -Xs): the endogenous variable names in causal order.
causal_endogenous(scm(_, Order, _), Order).

% causal_parents(+SCM, +X, -Parents): direct causes of X.
causal_parents(scm(_, _, Eqs), X, Parents) :-
    % When X has an equation, its parents are the referenced variables.
    (   memberchk(eq(X, Expr), Eqs)
    % Gather the referenced variables from the equation.
    ->  causal_expr_vars(Expr, Parents)
    % An exogenous variable has no parents inside the model.
    ;   Parents = []
    ).

% causal_children(+SCM, +X, -Children): direct effects of X.
causal_children(scm(_, _, Eqs) , X, Children) :-
    % Collect every variable whose equation references X.
    findall(Y,
        % Examine each equation in turn.
        ( member(eq(Y, Expr), Eqs),
          % Gather the variables referenced by that equation.
          causal_expr_vars(Expr, Vars),
          % Keep Y when X is among them.
          memberchk(X, Vars) ),
        Raw),
    % Sort and de-duplicate the children.
    sort(Raw, Children).

% causal_ancestors(+SCM, +X, -Ancestors): transitive closure of parents.
causal_ancestors(SCM, X, Ancestors) :-
    % Expand the frontier starting from the direct parents.
    causal_closure([X], SCM, causal_parents, [], Raw),
    % X is not its own ancestor.
    subtract(Raw, [X], NoSelf),
    % Sort the result.
    sort(NoSelf, Ancestors).

% causal_descendants(+SCM, +X, -Descendants): transitive closure of children.
causal_descendants(SCM, X, Descendants) :-
    % Expand the frontier starting from the direct children.
    causal_closure([X], SCM, causal_children, [], Raw),
    % X is not its own descendant.
    subtract(Raw, [X], NoSelf),
    % Sort the result.
    sort(NoSelf, Descendants).

% causal_closure(+Frontier, +SCM, +Step, +Seen, -All): generic reachability.
causal_closure([], _, _, Seen, Seen).
% Take the next node off the frontier.
causal_closure([N | Rest], SCM, Step, Seen, All) :-
    % Skip nodes already visited.
    (   memberchk(N, Seen)
    % Continue with the rest of the frontier.
    ->  causal_closure(Rest, SCM, Step, Seen, All)
    % Otherwise expand this node.
    ;   call(Step, SCM, N, Next),
        % Push the neighbours onto the frontier.
        append(Next, Rest, Frontier2),
        % Record the node as visited and continue.
        causal_closure(Frontier2, SCM, Step, [N | Seen], All)
    ).

% causal_path(+SCM, +X, +Y): a directed causal path runs from X to Y.
causal_path(SCM, X, Y) :-
    % Y must be among the descendants of X.
    causal_descendants(SCM, X, Ds),
    % Membership check completes the test.
    memberchk(Y, Ds).

% ===========================================================================
% D-SEPARATION
% ===========================================================================

% causal_dsep(+SCM, +X, +Y, +Zs): X and Y are d-separated given conditioning set Zs.
causal_dsep(SCM, X, Y, Zs) :-
    % Every undirected path between X and Y must be blocked by Zs.
    forall(causal_upath(SCM, X, Y, Path), causal_blocked_path(SCM, Path, Zs)).

% causal_upath(+SCM, +X, +Y, -Path): an undirected simple path from X to Y.
causal_upath(SCM, X, Y, Path) :-
    % Walk the undirected graph without revisiting nodes.
    causal_upath_walk(SCM, X, Y, [X], Rev),
    % The walk builds the path in reverse.
    reverse(Rev, Path).

% causal_upath_walk(+SCM, +N, +Y, +Visited, -RevPath): depth-first walk.
causal_upath_walk(_, Y, Y, Visited, Visited).
% Otherwise extend the walk by one undirected edge.
causal_upath_walk(SCM, N, Y, Visited, Path) :-
    % The current node is not yet the target.
    N \== Y,
    % Take any undirected neighbour of the current node.
    causal_neighbour(SCM, N, M),
    % Do not revisit a node already on the walk.
    \+ memberchk(M, Visited),
    % Continue the walk from the neighbour.
    causal_upath_walk(SCM, M, Y, [M | Visited], Path).

% causal_neighbour(+SCM, +N, -M): M is a parent or child of N.
causal_neighbour(SCM, N, M) :-
    % Gather the parents of N.
    causal_parents(SCM, N, Ps),
    % Gather the children of N.
    causal_children(SCM, N, Cs),
    % Join both neighbour lists.
    append(Ps, Cs, Ns),
    % Enumerate each neighbour.
    member(M, Ns).

% causal_blocked_path(+SCM, +Path, +Zs): some triple on the path blocks it.
causal_blocked_path(SCM, Path, Zs) :-
    % Find three consecutive nodes A, W, B on the path.
    append(_, [A, W, B | _], Path),
    % The middle node must block the flow given Zs.
    causal_blocked_triple(SCM, A, W, B, Zs),
    % One blocking triple suffices.
    !.

% causal_blocked_triple(+SCM, +A, +W, +B, +Zs): classify and test the triple.
causal_blocked_triple(SCM, A, W, B, Zs) :-
    % Is W a collider, with both arrows pointing into it?
    (   causal_edge(SCM, A, W),
        % Check the second incoming arrow.
        causal_edge(SCM, B, W)
    % A collider blocks unless W or one of its descendants is conditioned on.
    ->  \+ memberchk(W, Zs),
        % Gather the descendants of the collider.
        causal_descendants(SCM, W, Ds),
        % None of the descendants may be in the conditioning set.
        \+ ( member(D, Ds), memberchk(D, Zs) )
    % A chain or fork blocks exactly when W is conditioned on.
    ;   memberchk(W, Zs)
    ).

% causal_edge(+SCM, +From, +To): a directed edge runs From -> To.
causal_edge(SCM, From, To) :-
    % From must be among the parents of To.
    causal_parents(SCM, To, Ps),
    % Membership check completes the test.
    memberchk(From, Ps).

% ===========================================================================
% RUNG ONE — SEEING (OBSERVATIONAL SOLVING)
% ===========================================================================

% causal_solve(+SCM, +Context, -Solution): evaluate every variable.
causal_solve(scm(Exos, Order, Eqs), Context, Solution) :-
    % Bind each exogenous variable from the context or its default.
    findall(U-V,
        % Take each exogenous pair in turn.
        ( member(U-D, Exos),
          % Prefer a context value; otherwise use the default.
          ( memberchk(U-CV, Context) -> V = CV ; V = D ) ),
        Env0),
    % Evaluate the endogenous equations in causal order.
    causal_solve_order(Order, Eqs, Env0, Solution).

% causal_solve_order(+Order, +Eqs, +Env, -Solution): fold the causal order.
causal_solve_order([], _, Env, Env).
% Evaluate the next variable and extend the environment.
causal_solve_order([X | Rest], Eqs, Env, Solution) :-
    % Look up the equation of the next variable.
    memberchk(eq(X, Expr), Eqs),
    % Evaluate the equation in the current environment.
    causal_eval(Expr, Env, V),
    % Append the new binding at the end to preserve order.
    append(Env, [X-V], Env2),
    % Continue with the remaining variables.
    causal_solve_order(Rest, Eqs, Env2, Solution).

% causal_value(+SCM, +Context, +X, -V): one variable's observational value.
causal_value(SCM, Context, X, V) :-
    % Solve the whole model first.
    causal_solve(SCM, Context, Solution),
    % Read the requested variable from the solution.
    memberchk(X-V, Solution).

% ===========================================================================
% RUNG TWO — DOING (INTERVENTION)
% ===========================================================================

% causal_intervene(+SCM, +Interventions, -SCM2): graph surgery with do().
causal_intervene(SCM, [], SCM).
% Apply the first intervention, then the rest.
causal_intervene(scm(Exos, Order, Eqs), [X-V | Rest], SCM2) :-
    % The intervened variable must be endogenous.
    memberchk(eq(X, _), Eqs),
    % Cut the variable loose from its old causes.
    selectchk(eq(X, _), Eqs, eq(X, V), Eqs2),
    % Continue with the remaining interventions.
    causal_intervene(scm(Exos, Order, Eqs2), Rest, SCM2).

% causal_do(+SCM, +Interventions, +Context, -Solution): solve the mutilated model.
causal_do(SCM, Interventions, Context, Solution) :-
    % Perform the surgery.
    causal_intervene(SCM, Interventions, SCM2),
    % Solve the mutilated model in the given context.
    causal_solve(SCM2, Context, Solution).

% causal_effect(+SCM, +Interventions, +Context, +Y, -V): one variable under do().
causal_effect(SCM, Interventions, Context, Y, V) :-
    % Solve under the interventions.
    causal_do(SCM, Interventions, Context, Solution),
    % Read the requested variable from the solution.
    memberchk(Y-V, Solution).

% ===========================================================================
% RUNG THREE — IMAGINING (COUNTERFACTUALS)
% ===========================================================================

% causal_abduce(+SCM, +Domains, +Evidence, -Context): step one, abduction.
causal_abduce(SCM, Domains, Evidence, Context) :-
    % Enumerate one candidate assignment over the exogenous domains.
    causal_assign(Domains, Context),
    % Solve the model under the candidate context.
    causal_solve(SCM, Context, Solution),
    % Every piece of evidence must match the solution.
    forall(member(Var-Val, Evidence), memberchk(Var-Val, Solution)).

% causal_assign(+Domains, -Context): pick one value from each domain.
causal_assign([], []).
% Choose a value for the first variable, then the rest.
causal_assign([U-Dom | Rest], [U-V | Ctx]) :-
    % Enumerate the values of this domain.
    member(V, Dom),
    % Assign the remaining domains.
    causal_assign(Rest, Ctx).

% causal_counterfactual(+SCM, +Domains, +Evidence, +Ints, +Y, -V): determined value.
causal_counterfactual(SCM, Domains, Evidence, Interventions, Y, V) :-
    % Compute every counterfactual value the evidence allows.
    causal_counterfactual_all(SCM, Domains, Evidence, Interventions, Y, Vs),
    % The counterfactual is determined only when exactly one value remains.
    Vs = [V].

% causal_counterfactual_all(+SCM, +Domains, +Evidence, +Ints, +Y, -Vs): all values.
causal_counterfactual_all(SCM, Domains, Evidence, Interventions, Y, Vs) :-
    % Collect the counterfactual value under every consistent context.
    findall(V,
        % Abduction: recover a context consistent with the evidence.
        ( causal_abduce(SCM, Domains, Evidence, Context),
          % Action and prediction: solve the mutilated model in that context.
          causal_effect(SCM, Interventions, Context, Y, V) ),
        Raw),
    % At least one context must explain the evidence.
    Raw \== [],
    % Sort and de-duplicate the possible values.
    sort(Raw, Vs).

% causal_but_for(+SCM, +Context, +X, +Alts, +Y): X was necessary for Y's value.
causal_but_for(SCM, Context, X, Alts, Y) :-
    % Find the actual value of Y in this context.
    causal_value(SCM, Context, Y, Actual),
    % Some alternative setting of X must change Y.
    member(Alt, Alts),
    % Compute Y under the alternative intervention.
    causal_effect(SCM, [X-Alt], Context, Y, Other),
    % The but-for test passes when the value differs.
    Other =\= Actual,
    % One witnessing alternative suffices.
    !.
