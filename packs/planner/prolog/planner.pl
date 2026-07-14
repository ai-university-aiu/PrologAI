/*  PrologAI — Hierarchical Planner  (WP-386, Layer 361)

    Hierarchical Task Network (HTN) planning: long-horizon goals are
    expressed as compound tasks, compound tasks decompose through named
    methods into subtasks, and decomposition bottoms out in primitive
    actions that change the state. Methods are tried in the order they
    are declared, so earlier methods encode preferences; Prolog
    backtracking falls through to later methods automatically.

    A domain is built from:

        prim(Name, Pre, Add, Del)        a primitive action; Name may be
                                         a compound term with parameters.
        meth(MName, Task, Pre, Subtasks) a named decomposition method
                                         for a compound task.

    States are sorted lists of ground fluent terms, exactly as in the
    world_model pack. The depth bound counts method decompositions and
    guarantees termination even on recursive method sets.

    The plan tree (planner_task_tree/5) is the glass-box explanation of a
    plan: it shows which method was chosen for every compound task.

    Exported predicates:

    planner_domain/3       +Primitives, +Methods, -Domain
    planner_primitive/2    +Domain, +Task
    planner_compound/2     +Domain, +Task
    planner_methods_for/3  +Domain, +Task, -MethodNames
    planner_plan/5         +Domain, +State, +Tasks, +MaxDepth, -Plan
    planner_task_tree/5    +Domain, +State, +Task, +MaxDepth, -Tree
    planner_execute/4      +Domain, +State, +Plan, -FinalState
    planner_valid_plan/3   +Domain, +State, +Plan
    planner_plan_cost/2    +Plan, -Cost
    planner_monitor/4      +Domain, +State, +Plan, -Status
    planner_replan/5       +Domain, +State, +Tasks, +MaxDepth, -Plan
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(planner, [
    % planner_domain/3: assemble a planning domain.
    planner_domain/3,
    % planner_primitive/2: the task matches a primitive action.
    planner_primitive/2,
    % planner_compound/2: the task matches a decomposition method.
    planner_compound/2,
    % planner_methods_for/3: names of the methods matching a task.
    planner_methods_for/3,
    % planner_plan/5: decompose tasks into a primitive plan.
    planner_plan/5,
    % planner_task_tree/5: glass-box decomposition tree of one task.
    planner_task_tree/5,
    % planner_execute/4: run a primitive plan against a state.
    planner_execute/4,
    % planner_valid_plan/3: the plan executes from the state.
    planner_valid_plan/3,
    % planner_plan_cost/2: cost of a plan as its step count.
    planner_plan_cost/2,
    % planner_monitor/4: check a plan, reporting the first failing step.
    planner_monitor/4,
    % planner_replan/5: plan again from a new situation.
    planner_replan/5
]).

% Use the lists library for member/2, append/3, and friends.
:- use_module(library(lists)).

% ===========================================================================
% DOMAIN CONSTRUCTION AND CLASSIFICATION
% ===========================================================================

% planner_domain(+Primitives, +Methods, -Domain): assemble and check shapes.
planner_domain(Primitives, Methods, dom(Primitives, Methods)) :-
    % Every primitive must have the prim/4 shape with three lists.
    forall(member(P, Primitives),
        % Check one primitive declaration.
        ( P = prim(_, Pre, Add, Del), is_list(Pre), is_list(Add), is_list(Del) )),
    % Every method must have the meth/4 shape with two lists.
    forall(member(M, Methods),
        % Check one method declaration.
        ( M = meth(_, _, Pre, Subs), is_list(Pre), is_list(Subs) )).

% planner_primitive(+Domain, +Task): the task unifies with a primitive head.
planner_primitive(dom(Primitives, _), Task) :-
    % Search the primitive declarations.
    member(Prim, Primitives),
    % Work on a fresh copy to avoid binding the caller's task.
    copy_term(Prim, prim(Name, _, _, _)),
    % The task must unify with the primitive name.
    Task = Name,
    % One match suffices.
    !.

% planner_compound(+Domain, +Task): the task unifies with some method's task.
planner_compound(dom(_, Methods), Task) :-
    % Search the method declarations.
    member(Meth, Methods),
    % Work on a fresh copy to avoid binding the caller's task.
    copy_term(Meth, meth(_, Head, _, _)),
    % The task must unify with the method's task pattern.
    Task = Head,
    % One match suffices.
    !.

% planner_methods_for(+Domain, +Task, -MethodNames): matching method names in order.
planner_methods_for(dom(_, Methods), Task, MethodNames) :-
    % Collect the names whose task pattern unifies with the task.
    findall(MName,
        % Examine each method in declaration order.
        ( member(Meth, Methods),
          % Fresh copy so unification leaves the declaration intact.
          copy_term(Meth, meth(MName, Head, _, _)),
          % Unifiability test against the task.
          \+ Head \= Task ),
        MethodNames).

% ===========================================================================
% STATE OPERATIONS (STRIPS-STYLE)
% ===========================================================================

% planner_match_pre(+Pre, +State): unify each precondition with a state fluent.
planner_match_pre([], _).
% Match the first precondition, keeping its bindings for the rest.
planner_match_pre([P | Ps], State) :-
    % Unification here binds task and method parameters.
    member(P, State),
    % The remaining preconditions must hold under those bindings.
    planner_match_pre(Ps, State).

% planner_apply(+State, +Add, +Del, -State2): apply effects to a state.
planner_apply(State, Add, Del, State2) :-
    % Remove the deleted fluents.
    subtract(State, Del, Kept),
    % Insert the added fluents.
    append(Kept, Add, Raw),
    % Restore the canonical sorted form.
    sort(Raw, State2).

% ===========================================================================
% PLANNING BY ORDERED DECOMPOSITION
% ===========================================================================

% planner_plan(+Domain, +State, +Tasks, +MaxDepth, -Plan): the main entry point.
planner_plan(Domain, State0, Tasks, MaxDepth, Plan) :-
    % Canonicalize the start state.
    sort(State0, State),
    % Decompose the task list all the way to primitives.
    planner_decompose(Domain, State, Tasks, MaxDepth, Plan, _).

% planner_decompose(+Domain, +State, +Tasks, +Depth, -Plan, -Final): the engine.
planner_decompose(_, State, [], _, [], State).
% Handle the first task, then the rest.
planner_decompose(Domain, State, [Task | Tasks], Depth, Plan, Final) :-
    % Fetch the primitive declarations.
    Domain = dom(Primitives, _),
    % Try the task as a primitive action first.
    member(Prim, Primitives),
    % Fresh copy so the schema stays reusable.
    copy_term(Prim, prim(Name, Pre, Add, Del)),
    % The task must unify with the primitive name.
    Task = Name,
    % The preconditions must hold, binding the parameters.
    planner_match_pre(Pre, State),
    % Apply the primitive's effects.
    planner_apply(State, Add, Del, State2),
    % The bound action becomes a plan step.
    Plan = [Name | More],
    % Continue with the remaining tasks.
    planner_decompose(Domain, State2, Tasks, Depth, More, Final).
% Otherwise decompose the task through a method.
planner_decompose(Domain, State, [Task | Tasks], Depth, Plan, Final) :-
    % Depth must remain to decompose further.
    Depth > 0,
    % Fetch the method declarations.
    Domain = dom(_, Methods),
    % Try the methods in declaration order.
    member(Meth, Methods),
    % Fresh copy so the declaration stays reusable.
    copy_term(Meth, meth(_, Head, Pre, Subs)),
    % The task must unify with the method's task pattern.
    Task = Head,
    % The method's preconditions must hold, binding the parameters.
    planner_match_pre(Pre, State),
    % Count one decomposition against the depth bound.
    Depth2 is Depth - 1,
    % Splice the subtasks in front of the remaining tasks.
    append(Subs, Tasks, Tasks2),
    % Continue with the expanded task list.
    planner_decompose(Domain, State, Tasks2, Depth2, Plan, Final).

% ===========================================================================
% GLASS-BOX PLAN TREES
% ===========================================================================

% planner_task_tree(+Domain, +State, +Task, +MaxDepth, -Tree): explain one task.
planner_task_tree(Domain, State0, Task, MaxDepth, Tree) :-
    % Canonicalize the start state.
    sort(State0, State),
    % Build the tree list for the single task.
    planner_trees(Domain, State, [Task], MaxDepth, [Tree], _).

% planner_trees(+Domain, +State, +Tasks, +Depth, -Trees, -Final): tree builder.
planner_trees(_, State, [], _, [], State).
% Build the first task's tree, then the rest.
planner_trees(Domain, State, [Task | Tasks], Depth, [Tree | Trees], Final) :-
    % Fetch the primitive declarations.
    Domain = dom(Primitives, _),
    % Try the task as a primitive action first.
    member(Prim, Primitives),
    % Fresh copy so the schema stays reusable.
    copy_term(Prim, prim(Name, Pre, Add, Del)),
    % The task must unify with the primitive name.
    Task = Name,
    % The preconditions must hold, binding the parameters.
    planner_match_pre(Pre, State),
    % Apply the primitive's effects.
    planner_apply(State, Add, Del, State2),
    % A primitive is a leaf of the tree.
    Tree = primitive(Name),
    % Continue with the remaining tasks.
    planner_trees(Domain, State2, Tasks, Depth, Trees, Final).
% Otherwise decompose the task through a method, recording its name.
planner_trees(Domain, State, [Task | Tasks], Depth, [Tree | Trees], Final) :-
    % Depth must remain to decompose further.
    Depth > 0,
    % Fetch the method declarations.
    Domain = dom(_, Methods),
    % Try the methods in declaration order.
    member(Meth, Methods),
    % Fresh copy so the declaration stays reusable.
    copy_term(Meth, meth(MName, Head, Pre, Subs)),
    % The task must unify with the method's task pattern.
    Task = Head,
    % The method's preconditions must hold, binding the parameters.
    planner_match_pre(Pre, State),
    % Count one decomposition against the depth bound.
    Depth2 is Depth - 1,
    % Build the subtrees of the chosen method's subtasks.
    planner_trees(Domain, State, Subs, Depth2, SubTrees, State2),
    % Record the task, the chosen method, and the subtrees.
    Tree = tree(Task, MName, SubTrees),
    % Continue with the remaining tasks from the post-subtask state.
    planner_trees(Domain, State2, Tasks, Depth2, Trees, Final).

% ===========================================================================
% EXECUTION AND MONITORING
% ===========================================================================

% planner_execute(+Domain, +State, +Plan, -FinalState): run a primitive plan.
planner_execute(_, State, [], State).
% Execute the first step, then the rest.
planner_execute(Domain, State, [Name | Rest], Final) :-
    % Take the named primitive step.
    planner_prim_step(Domain, State, Name, State2),
    % Commit to the first binding of the named step.
    !,
    % Continue with the remaining steps.
    planner_execute(Domain, State2, Rest, Final).

% planner_prim_step(+Domain, +State, +Name, -State2): one primitive application.
planner_prim_step(dom(Primitives, _), State, Name, State2) :-
    % Search the primitive declarations.
    member(Prim, Primitives),
    % Fresh copy so the schema stays reusable.
    copy_term(Prim, prim(Name, Pre, Add, Del)),
    % The preconditions must hold in the current state.
    planner_match_pre(Pre, State),
    % Apply the effects.
    planner_apply(State, Add, Del, State2).

% planner_valid_plan(+Domain, +State, +Plan): the plan executes to the end.
planner_valid_plan(Domain, State, Plan) :-
    % Validity is successful execution.
    planner_execute(Domain, State, Plan, _).

% planner_plan_cost(+Plan, -Cost): unit cost per primitive step.
planner_plan_cost(Plan, Cost) :-
    % The cost is the number of steps.
    length(Plan, Cost).

% planner_monitor(+Domain, +State, +Plan, -Status): find the first failing step.
planner_monitor(Domain, State, Plan, Status) :-
    % Walk the plan from step one.
    planner_monitor_walk(Domain, State, Plan, 1, Status).

% planner_monitor_walk(+Domain, +State, +Plan, +I, -Status): the walk itself.
planner_monitor_walk(_, _, [], _, ok).
% Check the next step; report its index when it cannot run.
planner_monitor_walk(Domain, State, [Name | Rest], I, Status) :-
    % Attempt the named primitive step.
    (   planner_prim_step(Domain, State, Name, State2)
    % The step runs: continue with the next index.
    ->  I2 is I + 1,
        % Walk the remaining steps.
        planner_monitor_walk(Domain, State2, Rest, I2, Status)
    % The step cannot run: report where the plan breaks.
    ;   Status = fails_at(I, Name)
    ).

% planner_replan(+Domain, +State, +Tasks, +MaxDepth, -Plan): plan again.
planner_replan(Domain, State, Tasks, MaxDepth, Plan) :-
    % Replanning is planning from the new situation.
    planner_plan(Domain, State, Tasks, MaxDepth, Plan).
