/*  PrologAI — Causalontology Hierarchical Planning  (WP-404, Layer 379)

    co_plan composes a flat sequence of actions into one higher-level procedure
    relation; that is a two-level seed, not a hierarchy. This pack makes planning
    genuinely hierarchical: a plan is a TREE with as many levels of detail as the
    task needs, each high-level step expandable into a sub-plan.

    The canonical shape for playing an unknown interactive world is three levels:

        Win Game                                         (the top goal)
          Observe-Orient-Decide-Act loop                 (the method)
            see                                          (a phase)
              perceive the whole grid                    (a concrete operation)
            observe
              read the meters / locate the avatar / diff the frame
            orient
              apply priors / identify the archetype / rank objects and hazards
            decide
              predict a causal change / search the frontier / least-tried curiosity
            act
              ACTION1 ... ACTION7 / cell-select            (the environment controls)
            re-observe and update the rules
              learn the delta / update the state graph / record hazards

    The showcase is the MESH with Causalontology's own hierarchy. Causalontology
    core already reifies hierarchical decomposition: a coarse Causal Relation
    Object (CRO) may carry a mechanism sub-graph of finer CROs (co_decompose_add /
    co_mechanism), and co_hierarchy_consistent checks that the fine relations chain
    from the coarse relation's causes to its effects. This pack reifies a plan tree
    directly onto that structure: every plan node becomes a CRO, a node's children
    become its mechanism sub-graph, and the endpoints are laid out as ordered
    waypoints so the coarse "achieve this goal" relation is consistent with the
    composition of its parts. The plan hierarchy is therefore not a separate data
    structure bolted on — it IS a hierarchy of CROs, and the whole plan can be read
    back out of the causal graph alone (hp_plan_from_cros).

    Predicates:
      hp_reset/0                 clear the reified plan CROs
      hp_ooda_phases/1           -- -Phases   (the six phase names, in order)
      hp_phase_ops/2             -- +Phase, -Ops
      hp_win_plan/3              -- +Game, +Actions, -Tree
      hp_reify/2                 -- +Tree, -RootId  (mesh into Causalontology)
      hp_plan_from_cros/2        -- +RootId, -Tree  (read the plan back from CROs)
      hp_consistent/1            -- +RootId  (every level hierarchy-consistent)
      hp_render/2                -- +Tree, -Lines   (indented glass-box text)
      hp_render_json/2           -- +Tree, -Dict    (nested dict for the trace/Why)
      hp_classify_basis/3        -- +Basis, -Phase, -Leaf  (a choice's place in OODA)
*/

% Declare this module and its hierarchical-planning interface.
:- module(co_hplan, [
    % hp_reset/0: clear the reified plan CROs.
    hp_reset/0,
    % hp_ooda_phases/1: the six OODA-style phase names, in order.
    hp_ooda_phases/1,
    % hp_phase_ops/2: the concrete operations of a phase.
    hp_phase_ops/2,
    % hp_win_plan/3: build the three-level plan tree for a game.
    hp_win_plan/3,
    % hp_reify/2: reify a plan tree into the Causalontology decomposition graph.
    hp_reify/2,
    % hp_plan_from_cros/2: reconstruct a plan tree purely from the CRO graph.
    hp_plan_from_cros/2,
    % hp_consistent/1: every node's coarse relation agrees with its mechanism.
    hp_consistent/1,
    % hp_render/2: an indented, human-readable rendering of a plan tree.
    hp_render/2,
    % hp_render_json/2: a nested dict rendering for the glass-box trace and Why.
    hp_render_json/2,
    % hp_classify_basis/3: which OODA phase and concrete leaf a choice sits under.
    hp_classify_basis/3
]).

% Import the CRO store and constructor this planner reifies onto.
:- use_module(library(co_core),
    [co_new_cro/8, co_cro/8, co_decompose_add/2, co_mechanism/2,
     co_hierarchy_consistent/1]).
% Import list helpers.
:- use_module(library(lists), [member/2, memberchk/2, append/3, nth1/3]).

% ===========================================================================
% SECTION 1 — the OODA method and its concrete operations
% ===========================================================================

% hp_ooda_phases(-Phases): the six phases of the middle layer, in order — see,
% observe, orient, decide, act, and re-observe-and-update-the-rules.
hp_ooda_phases([see, observe, orient, decide, act, reobserve_update]).

% hp_phase_ops(+Phase, -Ops): the concrete operations a phase decomposes into.
% Each names a real capability the player runs, so the leaf level is not decorative.
% See: take in the entire grid.
hp_phase_ops(see, [perceive_whole_grid]).
% Observe: read what the grid says about the situation.
hp_phase_ops(observe, [read_meters, locate_avatar, diff_frame]).
% Orient: make sense of it with prior knowledge.
hp_phase_ops(orient, [apply_priors, identify_archetype, rank_objects_and_hazards]).
% Decide: choose the next action.
hp_phase_ops(decide, [predict_causal_change, search_frontier, least_tried_curiosity]).
% Act: perform an environment control (filled with the game's real actions).
hp_phase_ops(act, [perform_chosen_action]).
% Re-observe and update: learn from what followed.
hp_phase_ops(reobserve_update, [learn_delta, update_state_graph, record_hazards]).

% ===========================================================================
% SECTION 2 — building the plan tree
% ===========================================================================

% A plan node is hnode(Goal, Method, Children); a leaf has Children = [].
%
% hp_win_plan(+Game, +Actions, -Tree): the three-level plan for winning a game.
% Actions is the game's concrete control set (e.g. [action(1),...,select(x,y)]);
% when empty, the act phase keeps its generic operation.
hp_win_plan(Game, Actions, hnode(win(Game), strategy, [OodaNode])) :-
    % The OODA loop is the strategy's single method node.
    hp_ooda_phases(Phases),
    % Build one node per phase.
    findall(PhaseNode,
        ( member(Phase, Phases), hp_phase_node(Phase, Actions, PhaseNode) ),
        PhaseNodes),
    % The loop node holds the ordered phases.
    OodaNode = hnode(ooda_loop, cycle, PhaseNodes).

% hp_phase_node(+Phase, +Actions, -Node): one phase and its concrete-operation
% leaves. The act phase is special: its leaves are the game's real controls.
hp_phase_node(act, Actions, hnode(phase(act), method(act), Leaves)) :-
    % Non-empty action set: the controls become the leaves of the act phase.
    Actions \== [],
    !,
    % Each control is a primitive leaf.
    findall(hnode(control(A), primitive, []), member(A, Actions), Leaves).
% Any phase (including act with no actions) decomposes into its named operations.
hp_phase_node(Phase, _Actions, hnode(phase(Phase), method(Phase), Leaves)) :-
    % The phase's concrete operations.
    hp_phase_ops(Phase, Ops),
    % Each operation is a primitive leaf.
    findall(hnode(op(Op), primitive, []), member(Op, Ops), Leaves).

% ===========================================================================
% SECTION 3 — reifying the tree into the Causalontology hierarchy
% ===========================================================================

% hp_ctr_/1: a monotonic counter for unique waypoint terms (no randomness, so a
% run is reproducible).
:- dynamic hp_ctr_/1.

% hp_next/1: the next unique integer.
hp_next(N) :-
    % Read and remove the current value.
    ( retract(hp_ctr_(N0)) -> true ; N0 = 0 ),
    % The next value.
    N is N0 + 1,
    % Store it back.
    assertz(hp_ctr_(N)).

% hp_reset: clear every reified plan CRO and the waypoint counter, so a fresh
% plan does not inherit a previous one's nodes.
hp_reset :-
    % Retract every plan-node CRO (they carry the hplan provenance).
    retractall(co_core:co_cro_(_, _, _, _, _, _, _, prov(hplan, _, _))),
    % Drop their mechanism links.
    forall(co_mechanism(Id, _),
        ( \+ co_cro(Id, _, _, _, _, _, _, _)
        -> retractall(co_core:co_mechanism_(Id, _)) ; true )),
    % Reset the waypoint counter.
    retractall(hp_ctr_(_)),
    assertz(hp_ctr_(0)).

% hp_reify(+Tree, -RootId): reify a plan tree onto the CRO decomposition graph.
% The whole plan runs from begin(TopGoal) to end(TopGoal).
hp_reify(hnode(Goal, Method, Children), RootId) :-
    % Reify from the top goal's begin waypoint to its end waypoint.
    hp_reify_(hnode(Goal, Method, Children), RootId, begin(Goal), end(Goal)).

% hp_reify_(+Node, -Id, +Pre, +Post): reify one node as a CRO whose cause is Pre
% and whose effect is Post. An internal node lays its children out as an ordered
% chain of waypoints Pre = W0 -> W1 -> ... -> Wn = Post, so the coarse relation is
% consistent with the composition of its children (co_hierarchy_consistent holds).
hp_reify_(hnode(Goal, _Method, Children), Id, Pre, Post) :-
    % Create this node's coarse relation, tagged with the goal in its provenance.
    co_new_cro([Pre], [Post], temporal(0, 1, short), sufficient, 0.60, [],
               prov(hplan, plan_node(Goal), 0.60), Id),
    % A leaf has no mechanism.
    (   Children == []
    ->  true
    % An internal node: chain the children through fresh waypoints.
    ;   length(Children, N),
        hp_waypoints(Pre, Post, N, Points),
        % Reify each child over its waypoint slice.
        hp_reify_children(Children, Points, ChildIds),
        % Attach the children as this node's mechanism sub-graph.
        co_decompose_add(Id, ChildIds)
    ).

% hp_waypoints(+Pre, +Post, +N, -Points): the N+1 waypoints Pre, w1, ..., Post
% that split a parent's span into N ordered child slices.
hp_waypoints(Pre, Post, N, Points) :-
    % N-1 fresh interior waypoints.
    M is N - 1,
    hp_fresh_points(M, Interior),
    % The full ordered list of endpoints.
    append([Pre | Interior], [Post], Points).

% hp_fresh_points(+K, -Points): K fresh unique waypoint terms.
hp_fresh_points(0, []) :- !.
% Make one waypoint with a unique index, then recurse for the remaining ones.
hp_fresh_points(K, [wp(N) | Rest]) :-
    % One more to make.
    K > 0,
    % A unique index.
    hp_next(N),
    % The rest.
    K1 is K - 1,
    hp_fresh_points(K1, Rest).

% hp_reify_children(+Children, +Points, -ChildIds): reify each child over the
% slice between consecutive waypoints, so child i runs Points[i] -> Points[i+1].
hp_reify_children([], _, []).
% Reify the head child over its slice, then recurse over the remaining children.
hp_reify_children([Child | Rest], [P0, P1 | Ps], [Id | Ids]) :-
    % Reify this child over its slice.
    hp_reify_(Child, Id, P0, P1),
    % Continue from the next waypoint.
    hp_reify_children(Rest, [P1 | Ps], Ids).

% ===========================================================================
% SECTION 4 — reading the plan back out of the causal graph, and checking it
% ===========================================================================

% hp_plan_from_cros(+RootId, -Tree): reconstruct the plan tree using ONLY the
% Causalontology graph — a node's goal from its provenance, its children from its
% mechanism sub-graph. This proves the plan lives in the causal structure itself.
hp_plan_from_cros(Id, hnode(Goal, reified, Children)) :-
    % The goal is recorded in the node CRO's provenance (the 8th CRO field).
    co_cro(Id, _, _, _, _, _, _, prov(hplan, plan_node(Goal), _)),
    % The children are the mechanism sub-graph, if any.
    (   co_mechanism(Id, SubIds)
    ->  findall(Sub, ( member(ChildId, SubIds),
                       hp_plan_from_cros(ChildId, Sub) ), Children)
    ;   Children = []
    ).

% hp_consistent(+RootId): every internal node's coarse relation is consistent with
% the composition of its mechanism (the plan hierarchy is causally coherent).
hp_consistent(Id) :-
    % This node is consistent if it has no mechanism, or its mechanism chains.
    (   co_mechanism(Id, SubIds)
    ->  co_hierarchy_consistent(Id),
        % And every child is consistent in turn.
        forall(member(Sub, SubIds), hp_consistent(Sub))
    ;   true
    ).

% ===========================================================================
% SECTION 5 — rendering the plan for the glass box
% ===========================================================================

% hp_render(+Tree, -Lines): an indented, human-readable rendering, one atom per
% line, deepest detail most indented — the plan tree as the Why endpoint shows it.
hp_render(Tree, Lines) :-
    % Render from depth zero.
    hp_render_(Tree, 0, Lines).

% hp_render_(+Node, +Depth, -Lines): render a node and its subtree.
hp_render_(hnode(Goal, _Method, Children), Depth, [Line | Rest]) :-
    % The indentation for this depth.
    hp_indent(Depth, Pad),
    % The node's human label.
    hp_label(Goal, Label),
    % The line for this node.
    atom_concat(Pad, Label, Line),
    % Render the children one level deeper.
    Depth1 is Depth + 1,
    findall(SubLines, ( member(Child, Children),
                        hp_render_(Child, Depth1, SubLines) ), Nested),
    % Flatten the child line-lists into one list.
    append(Nested, Rest).

% hp_indent(+Depth, -Pad): two spaces per level.
hp_indent(0, '') :- !.
% Deeper levels take one level less of padding plus two more spaces.
hp_indent(Depth, Pad) :-
    % One level less.
    Depth > 0, Depth1 is Depth - 1,
    hp_indent(Depth1, Pad0),
    % Two more spaces.
    atom_concat(Pad0, '  ', Pad).

% hp_label(+Goal, -Label): a readable label for a node goal.
% The top goal reads as "Win Game: <name>".
hp_label(win(G), Label) :- !, atom_concat('Win Game: ', G, Label).
% The middle loop node carries a fixed descriptive label.
hp_label(ooda_loop, 'OODA loop (see, observe, orient, decide, act, re-observe & update rules)') :- !.
% A phase node reuses the per-phase readable name.
hp_label(phase(P), Label) :- !, hp_phase_label(P, Label).
% An operation leaf reads as "op: <name>".
hp_label(op(Op), Label) :- !, atom_concat('op: ', Op, Label).
% A control leaf reads as "control: <action term>".
hp_label(control(A), Label) :- !, term_to_atom(A, AText), atom_concat('control: ', AText, Label).
% Anything else falls back to its plain term text.
hp_label(Other, Label) :- term_to_atom(Other, Label).

% hp_phase_label(+Phase, -Label): a readable name for each OODA phase.
% See: perceive the whole grid.
hp_phase_label(see, 'see (perceive the whole grid)').
% Observe: meters, avatar, frame diff.
hp_phase_label(observe, 'observe (meters, avatar, frame diff)').
% Orient: priors, archetype, objects and hazards.
hp_phase_label(orient, 'orient (priors, archetype, objects & hazards)').
% Decide: causal change, frontier, curiosity.
hp_phase_label(decide, 'decide (causal change, frontier, curiosity)').
% Act: environment controls.
hp_phase_label(act, 'act (environment controls)').
% Re-observe and update: learn delta, graph, hazards.
hp_phase_label(reobserve_update, 're-observe & update rules (learn delta, graph, hazards)').

% hp_render_json(+Tree, -Dict): a nested dict rendering for JSON consumers (the
% agentview and the Why endpoint).
hp_render_json(hnode(Goal, Method, Children), Dict) :-
    % The goal and method as atoms.
    term_to_atom(Goal, GoalText),
    term_to_atom(Method, MethodText),
    % A readable label.
    hp_label(Goal, Label),
    % The children as nested dicts.
    findall(ChildDict, ( member(Child, Children),
                         hp_render_json(Child, ChildDict) ), ChildDicts),
    % Assemble.
    Dict = _{goal: GoalText, method: MethodText, label: Label, children: ChildDicts}.

% ===========================================================================
% SECTION 6 — locating a choice within the plan
% ===========================================================================

% hp_classify_basis(+Basis, -Phase, -Leaf): the OODA phase and concrete leaf a
% solo player's choice basis falls under, so the glass box can say which rung of
% the plan the current action came from. Defaults keep it total.
% Replaying a known winning path is acting on a settled plan.
hp_classify_basis(replay(win),           act,    control(replay_winning_path)) :- !.
% Human navigation hints are acting toward a target.
hp_classify_basis(toward(_),             act,    op(navigate_to_target)) :- !.
% Following a human hint is acting on given advice.
hp_classify_basis(human_hint(_),         act,    op(follow_human_hint)) :- !.
% Object-targeted curiosity is orienting on an object then going to it.
hp_classify_basis(explore(object(_)),    act,    op(go_to_object)) :- !.
% Trying a never-tried action is deciding by novelty.
hp_classify_basis(explore(novel),        decide, op(try_untried)) :- !.
% Causal-change ranking is deciding by predicted effect.
hp_classify_basis(explore(causal),       decide, op(predict_causal_change)) :- !.
% The state-graph frontier is deciding by systematic exploration.
hp_classify_basis(graph_explore,         decide, op(search_frontier)) :- !.
% Salient policy ranking is deciding over the full policy.
hp_classify_basis(explore(salient),      decide, op(salient_policy)) :- !.
% Least-tried is deciding by curiosity.
hp_classify_basis(curiosity,             decide, op(least_tried_curiosity)) :- !.
% Stuck-recall re-tries the highest-impact action.
hp_classify_basis(recall(biggest_effect),decide, op(recall_best_effect)) :- !.
% Anything else is a decision by default.
hp_classify_basis(_,                     decide, op(choose_action)).
