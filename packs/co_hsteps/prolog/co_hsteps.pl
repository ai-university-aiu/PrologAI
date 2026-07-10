/*  PrologAI — ARC-AGI-3 Human-Step Ladder in J-Space  (WP-401, Layer 376)

    A human dropped into an ARC-AGI-3 game with no instructions does not flail.
    They follow a recognisable process: orient to the frame, probe the controls
    to see what they move, build a model of the mechanics, infer the unstated
    goal, plan an efficient route, execute while monitoring, then carry what
    they learned into the next level. The ARC Prize human study (458 people,
    first-run, one attempt each) confirmed this explore-then-execute shape.

    This pack makes that process a first-class, inspectable object. It encodes
    the six phases and thirty micro-steps of the human ladder as ordered facts,
    and it holds the step the agent is currently on as a concept in a J-Space
    workspace (the jspace pack — the Jacobian Space, read through the Jacobian
    Lens), so that at any moment the J-Lens readout says which human step the
    agent is executing and why. Walking the ladder leaves a glass-box trace of
    the whole human process in the workspace.

    The pack also supplies the concrete mechanism behind the probe phase (Phase
    II): the discrete action-response Jacobian. Given the transitions observed
    by trying each action, hs_sensitivity/2 reports how much each action changes
    the frame; hs_controllable/2 finds the object the agent controls (the colour
    whose centroid moves most under the actions — the human "which thing do I
    move?" step); hs_jacobian/3 is the column of partial derivatives of that
    object's position with respect to each action; and hs_goal_gradient/4 ranks
    the actions by how much they move the controllable toward a goal cell — the
    discrete gradient the execution phase descends.

    The six phases:
      1  Initial Environmental Orientation
      2  Structured Exploration and Mechanics Discovery
      3  Goal Inference and Objective Discovery
      4  World Model Formation and Planning
      5  Execution and Adaptive Monitoring
      6  Level Progression and Carry-Forward Learning

    Predicates:
      hs_phase/2         -- ?PhaseId, ?Name
      hs_step/3          -- ?StepId, ?PhaseId, ?Description
      hs_ladder/1        -- -StepIds  (all thirty, in order)
      hs_phase_of/2      -- +StepId, -PhaseId
      hs_phase_capability/2 -- ?PhaseId, ?Capability  (the suite pack per phase)
      hs_reset/1         -- +Space  (open the J-Space and enter the first step)
      hs_enter/2         -- +Space, +StepId  (hold this step, decay the rest)
      hs_current/2       -- +Space, -StepId  (the strongest held step)
      hs_advance/2       -- +Space, -StepId  (step to the next in the ladder)
      hs_reading/2       -- +Space, -Reading (the J-Lens readout)
      hs_sensitivity/2   -- +Transitions, -Sensitivity  (change count per action)
      hs_controllable/2  -- +Transitions, -Colour  (the object the agent controls)
      hs_jacobian/3      -- +Transitions, +Colour, -Jacobian (displacement per action)
      hs_goal_gradient/4 -- +Jacobian, +FromCell, +GoalCell, -RankedActions
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(co_hsteps, [
    % hs_phase/2: a phase and its name.
    hs_phase/2,
    % hs_step/3: a micro-step, its phase, and its description.
    hs_step/3,
    % hs_ladder/1: all thirty step ids in order.
    hs_ladder/1,
    % hs_phase_of/2: the phase a step belongs to.
    hs_phase_of/2,
    % hs_phase_capability/2: the suite capability each phase draws on.
    hs_phase_capability/2,
    % hs_reset/1: open the J-Space workspace at the first step.
    hs_reset/1,
    % hs_enter/2: hold a step as the active concept in J-Space.
    hs_enter/2,
    % hs_current/2: the step currently held strongest.
    hs_current/2,
    % hs_advance/2: move to the next step in the ladder.
    hs_advance/2,
    % hs_reading/2: the J-Lens readout of the workspace.
    hs_reading/2,
    % hs_sensitivity/2: how much each action changes the frame.
    hs_sensitivity/2,
    % hs_controllable/2: the object the agent controls.
    hs_controllable/2,
    % hs_jacobian/3: the controllable's displacement per action.
    hs_jacobian/3,
    % hs_goal_gradient/4: actions ranked by progress toward a goal cell.
    hs_goal_gradient/4
]).

% Import the J-Space concept workspace (the Jacobian Space and its Lens).
:- use_module(library(jspace),
    [js_open/1, js_hold/4, js_active/2, js_reading/2, js_decay/2]).
% Import grid measurement and cell access for the Jacobian.
:- use_module(library(grid), [gd_size/3, gd_cell/4, gd_diff/3, gd_colors/2]).
% Import list helpers.
:- use_module(library(lists), [member/2, nth0/3, sum_list/2]).

% ---------------------------------------------------------------------------
% The phases
% ---------------------------------------------------------------------------

% Phase one: getting oriented to a novel environment with no instructions.
hs_phase(1, 'Initial Environmental Orientation').
% Phase two: probing the controls and building a model of the mechanics.
hs_phase(2, 'Structured Exploration and Mechanics Discovery').
% Phase three: working out the unstated goal from environmental cues.
hs_phase(3, 'Goal Inference and Objective Discovery').
% Phase four: turning the model and goal into a plan.
hs_phase(4, 'World Model Formation and Planning').
% Phase five: carrying out the plan while watching for surprises.
hs_phase(5, 'Execution and Adaptive Monitoring').
% Phase six: carrying what was learned into the next level.
hs_phase(6, 'Level Progression and Carry-Forward Learning').

% hs_phase_capability(?PhaseId, ?Capability): the suite pack each phase leans on.
% Orientation is perception of the grid.
hs_phase_capability(1, perception).
% Exploration is the exploration policy and this pack's Jacobian.
hs_phase_capability(2, co_explore).
% Goal inference is the goal inferencer.
hs_phase_capability(3, co_goalinfer).
% Planning is the planner under the efficiency governor.
hs_phase_capability(4, co_plan).
% Execution spends actions under the efficiency governor.
hs_phase_capability(5, co_effic).
% Transfer carries learned relations forward across levels.
hs_phase_capability(6, co_core).

% ---------------------------------------------------------------------------
% The thirty micro-steps
% ---------------------------------------------------------------------------

% Phase one steps.
% Observe the opening frame with no context and ask what matters.
hs_step('I.1', 1, 'Observe the initial frame with no context; scan regions, objects, colours').
% Notice which actions are available.
hs_step('I.2', 1, 'Notice the available action interface and its labels').
% Commit to exploring before trying to win.
hs_step('I.3', 1, 'Activate the explore-before-solve strategy; act deliberately, not randomly').

% Phase two steps.
% Take one tentative action to see how the world responds.
hs_step('II.1', 2, 'Make a tentative first action purely to observe the response').
% Compare the new frame to the old to characterise the effect.
hs_step('II.2', 2, 'Observe the consequences by comparing the new frame to the previous one').
% Record the effect as a remembered rule.
hs_step('II.3', 2, 'Encode the state change into memory as when-I-did-X-then-Y').
% Choose the next action to be maximally informative.
hs_step('II.4', 2, 'Choose the next exploratory action strategically for information').
% Vary the actions across contexts.
hs_step('II.5', 2, 'Systematically vary actions across positions and objects').
% Look for context-dependent effects.
hs_step('II.6', 2, 'Discover conditional behaviours that depend on context').
% Find the boundaries, obstacles, and penalty states.
hs_step('II.7', 2, 'Detect environmental constraints, boundaries, and penalty states').
% Integrate everything into a working world model.
hs_step('II.8', 2, 'Build an internal world model of actions, objects, constraints, and rules').

% Phase three steps.
% Look for what success might look like.
hs_step('III.1', 3, 'Scan for goal-related cues that stand out from the grid').
% Generate candidate goals.
hs_step('III.2', 3, 'Hypothesise potential goals from the environment structure').
% Test the goal hypotheses with targeted actions.
hs_step('III.3', 3, 'Test goal hypotheses through targeted actions').
% Recognise progress feedback.
hs_step('III.4', 3, 'Recognise progress indicators and partial success').
% Learn what failure looks like.
hs_step('III.5', 3, 'Detect failure states and anti-goals').
% Confirm the goal into a clear objective.
hs_step('III.6', 3, 'Confirm the goal and formulate a clear objective statement').

% Phase four steps.
% Measure the gap between now and the goal.
hs_step('IV.1', 4, 'Assess the current state relative to the goal; identify the differences').
% Break the goal into sub-goals.
hs_step('IV.2', 4, 'Identify sub-goals and milestones').
% Generate candidate action sequences.
hs_step('IV.3', 4, 'Generate candidate action sequences using the world model').
% Choose the feasible, efficient plan.
hs_step('IV.4', 4, 'Evaluate candidate plans for feasibility and efficiency; prepare contingencies').

% Phase five steps.
% Carry out the plan.
hs_step('V.1', 5, 'Execute the planned actions step by step').
% Check each result against prediction.
hs_step('V.2', 5, 'Monitor each action result against the prediction; count the actions').
% Update the model when a prediction fails.
hs_step('V.3', 5, 'Update the world model when predictions fail').
% Re-plan from the new state if needed.
hs_step('V.4', 5, 'Re-plan adaptively from the new state when the discrepancy is large').
% Notice the win and stop.
hs_step('V.5', 5, 'Recognise when the goal is achieved and stop acting').

% Phase six steps.
% Observe the next level's opening.
hs_step('VI.1', 6, 'Observe the new level initial state; note similarities and differences').
% Assume the old mechanics still hold.
hs_step('VI.2', 6, 'Transfer mechanics knowledge forward from previous levels').
% Find the new twist.
hs_step('VI.3', 6, 'Identify new mechanics introduced in the current level').
% Get more efficient with accumulated understanding.
hs_step('VI.4', 6, 'Achieve efficiency over time as understanding accumulates').

% Define hs_ladder: all thirty step ids in their canonical order.
hs_ladder(['I.1','I.2','I.3',
           'II.1','II.2','II.3','II.4','II.5','II.6','II.7','II.8',
           'III.1','III.2','III.3','III.4','III.5','III.6',
           'IV.1','IV.2','IV.3','IV.4',
           'V.1','V.2','V.3','V.4','V.5',
           'VI.1','VI.2','VI.3','VI.4']).

% Define hs_phase_of: the phase a step belongs to.
hs_phase_of(StepId, PhaseId) :-
    % Read it straight from the step fact.
    hs_step(StepId, PhaseId, _).

% ---------------------------------------------------------------------------
% Holding the current step in J-Space (the Jacobian Lens over the process)
% ---------------------------------------------------------------------------

% Define hs_reset: open a fresh J-Space workspace at the first step.
hs_reset(Space) :-
    % Clear the workspace.
    js_open(Space),
    % Enter the first step of the ladder.
    hs_enter(Space, 'I.1').

% Define hs_enter: hold a step as the active concept, decaying the earlier ones.
hs_enter(Space, StepId) :-
    % The step must be a real one.
    hs_step(StepId, _, _),
    % Fade the previously held steps so the current one dominates the readout.
    js_decay(Space, 0.5),
    % Hold the current step at full strength, sourced as a human step.
    js_hold(Space, hstep(StepId), 1.0, human_step).

% Define hs_current: the step currently held strongest in the workspace.
hs_current(Space, StepId) :-
    % Take the ranked active concepts.
    js_active(Space, Concepts),
    % The first held step, being the strongest, is the current one.
    once(( member(hstep(StepId), Concepts) )).

% Define hs_advance: move to the next step in the ladder and hold it.
hs_advance(Space, Next) :-
    % Find the current step.
    hs_current(Space, Current),
    % The ordered ladder.
    hs_ladder(Ladder),
    % The current step's position.
    nth0(I, Ladder, Current),
    % The next position.
    I1 is I + 1,
    % There must be a next step.
    nth0(I1, Ladder, Next),
    % Hold it.
    hs_enter(Space, Next).

% Define hs_reading: the J-Lens readout of the workspace.
hs_reading(Space, Reading) :-
    % Delegate to the Jacobian Lens of the jspace pack.
    js_reading(Space, Reading).

% ---------------------------------------------------------------------------
% The discrete action-response Jacobian (Phase II made concrete)
% ---------------------------------------------------------------------------
% A transition is t(Action, Frame0, Frame1): the frame before and after one
% action. The Jacobian is assembled from a list of such transitions, one per
% action tried from the same starting state.

% Define hs_sensitivity: how many cells each action changed.
hs_sensitivity(Transitions, Sensitivity) :-
    % Pair each action with the size of its frame change.
    findall(sens(Action, N),
        % Take each transition.
        ( member(t(Action, F0, F1), Transitions),
          % The differing cells between the two frames.
          gd_diff(F0, F1, Diffs),
          % How many cells changed.
          length(Diffs, N) ),
        Sensitivity).

% Define hs_controllable: the object colour the agent controls.
% The controllable object is the non-background colour whose centre of mass
% moves the most across the tried actions.
hs_controllable(Transitions, Colour) :-
    % There must be a transition to look at.
    Transitions = [t(_, F0, _) | _],
    % The candidate colours are those present, minus the background zero.
    gd_colors(F0, Colours0),
    % Drop the background.
    findall(C, ( member(C, Colours0), C =\= 0 ), Candidates),
    % Score each candidate by the total motion of its centroid.
    findall(Motion-C,
        % Take each candidate colour.
        ( member(C, Candidates),
          % Its total centroid motion across all transitions.
          hs_total_motion(Transitions, C, Motion) ),
        Scored),
    % Keep only colours that actually moved.
    findall(M-C, ( member(M-C, Scored), M > 0 ), Moving),
    % There must be at least one moving object.
    Moving \== [],
    % Order by motion descending, then colour ascending.
    hs_pick_best(Moving, Colour).

% hs_total_motion(+Transitions, +Colour, -Motion): summed centroid displacement.
hs_total_motion(Transitions, Colour, Motion) :-
    % Sum the per-transition displacement magnitudes.
    findall(D,
        % Take each transition.
        ( member(t(_, F0, F1), Transitions),
          % The colour must be present in both frames to have a displacement.
          hs_centroid(F0, Colour, R0, C0),
          % And after.
          hs_centroid(F1, Colour, R1, C1),
          % The Manhattan displacement of the centroid.
          D is abs(R1 - R0) + abs(C1 - C0) ),
        Ds),
    % Total them.
    sum_list(Ds, Motion).

% hs_pick_best(+MotionColourPairs, -Colour): the colour with the most motion.
hs_pick_best(Pairs, Colour) :-
    % Turn each pair into a sort key that orders by motion descending.
    findall(key(NegM, C)-C, ( member(M-C, Pairs), NegM is -M ), Keyed),
    % Order by the key: least NegM (largest motion) first, then colour.
    msort(Keyed, [_-Colour | _]).

% Define hs_jacobian: the controllable object's displacement per action.
% Each entry jac(Action, DR, DC) is the partial derivative of the object's
% (row, column) position with respect to that action.
hs_jacobian(Transitions, Colour, Jacobian) :-
    % Build one displacement entry per transition where the colour is present.
    findall(jac(Action, DR, DC),
        % Take each transition.
        ( member(t(Action, F0, F1), Transitions),
          % The centroid before.
          hs_centroid(F0, Colour, R0, C0),
          % The centroid after.
          hs_centroid(F1, Colour, R1, C1),
          % The row displacement.
          DR is R1 - R0,
          % The column displacement.
          DC is C1 - C0 ),
        Jacobian).

% Define hs_goal_gradient: actions ranked by progress toward a goal cell.
% Descending this gradient is the execution phase's move choice.
hs_goal_gradient(Jacobian, cell(FR, FC), cell(GR, GC), Ranked) :-
    % Score each action by the distance to the goal after its displacement.
    findall(Dist-Action,
        % Take each Jacobian entry.
        ( member(jac(Action, DR, DC), Jacobian),
          % The resulting row.
          NR is FR + DR,
          % The resulting column.
          NC is FC + DC,
          % The Manhattan distance from there to the goal.
          Dist is abs(GR - NR) + abs(GC - NC) ),
        Scored),
    % Order by resulting distance, nearest first.
    keysort(Scored, Sorted),
    % Drop the distances, keeping the ordered actions.
    findall(A, member(_-A, Sorted), Ranked).

% hs_centroid(+Frame, +Colour, -R, -C): the rounded centre of mass of a colour.
hs_centroid(Frame, Colour, R, C) :-
    % Measure the frame.
    gd_size(Frame, Rows, Cols),
    % The last row and column indices.
    MaxR is Rows - 1, MaxC is Cols - 1,
    % Collect every cell carrying the colour.
    findall(RR-CC,
        % Enumerate the cells.
        ( between(0, MaxR, RR), between(0, MaxC, CC),
          % Read the cell and keep the matches.
          gd_cell(Frame, RR, CC, Colour) ),
        Cells),
    % The colour must appear at least once.
    Cells \== [],
    % Gather the row coordinates.
    findall(RR, member(RR-_, Cells), RRs),
    % Gather the column coordinates.
    findall(CC, member(_-CC, Cells), CCs),
    % Count them.
    length(Cells, N),
    % Sum the rows.
    sum_list(RRs, SR),
    % Sum the columns.
    sum_list(CCs, SC),
    % The rounded mean row.
    R is round(SR / N),
    % The rounded mean column.
    C is round(SC / N).
