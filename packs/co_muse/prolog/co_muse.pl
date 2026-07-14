/*  PrologAI — Causalontology Imagination  (WP-421, Layer 396)

    THE_BUILDING_FILES describe a mind that thinks before it acts: it runs
    imagined actions against its model, watches what would happen, and keeps the
    useful discoveries — all without touching the real world. Crucially, the
    imagined must never be mistaken for the observed: a mind keeps parallel
    "realities" (what is observed, what is desired, what is expected, what is
    merely imagined, what is recalled) so that a hypothetical never contaminates
    fact. world_model can already roll a plan forward inside its model; this pack adds
    the missing part — the quarantined imagination and the discipline that only a
    deliberate choice, never the act of imagining, writes into observed reality.

    A REALITY is a named partition of facts:

        observed   what the agent has actually perceived (ground fact)
        desired    the goals it wants to be true
        expected   what it predicts will happen
        imagined   scenarios it is trying out offline
        recalled   what it has pulled back from memory

    Imagining rolls a start state forward through a caller-supplied transition
    relation, recording each visited state in the imagined reality — so a "what
    if" is explored fully yet stays sealed off from observed fact until the
    caller explicitly promotes a finding.

    Predicates:
      mu_reset/0            -- clear every reality and the transition model
      mu_realities/1        -- -Names        (the five standard partitions)
      mu_assert/2           -- +Reality, +Fact         (place a fact in a partition)
      mu_holds/2            -- ?Reality, ?Fact
      mu_clear/1            -- +Reality                 (empty one partition)
      mu_transition_add/3   -- +State, +Action, +NextState   (a known transition)
      mu_imagine/3          -- +Start, +ActionSeq, -Trajectory   (roll forward, seal in imagined)
      mu_reaches/3          -- +Start, +ActionSeq, -EndState
      mu_evaluate/3         -- +Trajectory, +GoalState, -Score      (1.0 if reached, else 0.0)
      mu_steps_to/3         -- +Trajectory, +GoalState, -Steps      (index of the goal)
      mu_best_plan/4        -- +Start, +CandidateSeqs, +GoalState, -BestSeq   (fewest steps to goal)
      mu_quarantined/1      -- ?Fact          (in imagined but not in observed)
      mu_promote/3          -- +FromReality, +Fact, +ToReality   (a deliberate copy across)
*/

% Declare this module and its exported predicates.
:- module(co_muse, [
    % mu_reset/0: clear all realities and the transition model.
    mu_reset/0,
    % mu_realities/1: the five standard reality partitions.
    mu_realities/1,
    % mu_assert/2: place a fact in a named reality.
    mu_assert/2,
    % mu_holds/2: query the facts in a reality.
    mu_holds/2,
    % mu_clear/1: empty one reality partition.
    mu_clear/1,
    % mu_transition_add/3: record a known state-action-next transition.
    mu_transition_add/3,
    % mu_imagine/3: roll a start state forward, sealing the path in imagined.
    mu_imagine/3,
    % mu_reaches/3: the final state a sequence reaches from a start.
    mu_reaches/3,
    % mu_evaluate/3: score a trajectory against a goal state.
    mu_evaluate/3,
    % mu_steps_to/3: how many steps a trajectory takes to reach a goal.
    mu_steps_to/3,
    % mu_best_plan/4: the candidate sequence that reaches the goal soonest.
    mu_best_plan/4,
    % mu_quarantined/1: facts imagined but not observed.
    mu_quarantined/1,
    % mu_promote/3: deliberately copy a fact from one reality to another.
    mu_promote/3
]).

% Use the list library.
:- use_module(library(lists)).

% fact/2 holds one fact in one reality; it changes at runtime, so it is dynamic.
:- dynamic fact/2.
% transition/3 is a known state-action-next step used for imagining; dynamic.
:- dynamic transition/3.

% mu_reset/0: forget every stored fact and every transition.
mu_reset :-
    % Remove all facts from all realities.
    retractall(fact(_,_)),
    % Remove the transition model.
    retractall(transition(_,_,_)).

% mu_realities/1: the five standard reality partitions.
mu_realities([observed, desired, expected, imagined, recalled]).

% mu_assert/2: place a fact in a named reality, without duplication.
mu_assert(Reality, Fact) :-
    % Store it unless the same fact already sits in that reality.
    ( fact(Reality, Fact) -> true ; assertz(fact(Reality, Fact)) ).

% mu_holds/2: query the facts held in a reality.
mu_holds(Reality, Fact) :-
    % Read the stored fact.
    fact(Reality, Fact).

% mu_clear/1: empty one reality partition.
mu_clear(Reality) :-
    % Remove every fact tagged with that reality.
    retractall(fact(Reality, _)).

% mu_transition_add/3: record a known transition for imagining.
mu_transition_add(State, Action, NextState) :-
    % Store it unless the same transition is already known.
    ( transition(State, Action, NextState) -> true
    ; assertz(transition(State, Action, NextState)) ).

% mu_imagine/3: roll a start state forward through a sequence, sealing the path.
mu_imagine(Start, ActionSeq, Trajectory) :-
    % Walk the sequence from the start, collecting the states visited.
    mu_roll(Start, ActionSeq, States),
    % The trajectory begins at the start and continues through those states.
    Trajectory = [Start | States],
    % Seal every visited state into the imagined reality (quarantined from fact).
    forall(member(S, Trajectory), mu_assert(imagined, visited(S))).

% mu_roll/3: follow the transitions for each action, stopping if one is unknown.
mu_roll(_, [], []) :-
    % An empty remaining sequence visits no further states (committed).
    !.
mu_roll(State, [Action | Rest], Visited) :-
    % Take the known transition for this state and action if there is one.
    ( transition(State, Action, Next)
      -> % Record the next state and keep rolling from it.
         Visited = [Next | More],
         mu_roll(Next, Rest, More)
      ;  % No transition is known: imagining halts here.
         Visited = [] ).

% mu_reaches/3: the final state reached by a sequence from a start.
mu_reaches(Start, ActionSeq, EndState) :-
    % Imagine the trajectory and take its last state.
    mu_imagine(Start, ActionSeq, Trajectory),
    last(Trajectory, EndState).

% mu_evaluate/3: score a trajectory as 1.0 if it reaches the goal, else 0.0.
mu_evaluate(Trajectory, GoalState, Score) :-
    % A reached goal scores one; an unreached goal scores zero.
    ( memberchk(GoalState, Trajectory) -> Score = 1.0 ; Score = 0.0 ).

% mu_steps_to/3: how many steps into the trajectory the goal first appears.
mu_steps_to(Trajectory, GoalState, Steps) :-
    % Find the position of the goal (zero-based: the start is step zero).
    nth0(Steps, Trajectory, GoalState),
    % Commit to the first occurrence.
    !.

% mu_best_plan/4: the candidate sequence that reaches the goal in fewest steps.
mu_best_plan(Start, CandidateSeqs, GoalState, BestSeq) :-
    % Score each candidate that actually reaches the goal by its step count.
    findall(Steps-Seq,
            ( member(Seq, CandidateSeqs),
              mu_imagine(Start, Seq, Traj),
              mu_steps_to(Traj, GoalState, Steps) ),
            Reaching),
    % At least one candidate must reach the goal.
    Reaching = [_|_],
    % Prefer the fewest steps, breaking ties by enumeration order.
    keysort(Reaching, [_-BestSeq | _]).

% mu_quarantined/1: a fact imagined but not observed — sealed off from fact.
mu_quarantined(Fact) :-
    % It is present in the imagined reality,
    fact(imagined, Fact),
    % but absent from the observed reality.
    \+ fact(observed, Fact).

% mu_promote/3: a deliberate, auditable copy of a fact from one reality to another.
mu_promote(FromReality, Fact, ToReality) :-
    % The fact must actually be held in the source reality (commit to it).
    fact(FromReality, Fact),
    !,
    % Copy it into the destination reality (imagining never does this by itself).
    mu_assert(ToReality, Fact).
