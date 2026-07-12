/*  PrologAI — Causalontology Theory of Mind  (WP-418, Layer 393)

    THE_BUILDING_FILES list theory of mind — reasoning from another agent's point
    of view, including that it may hold a false belief — as a faculty a complete
    mind needs. The wider ecosystem has a non-Causalontology "tom" pack; this is
    the Causalontology-native version, kept small and glass-box.

    It does two things. First, it infers another agent's GOAL from behaviour: the
    caller registers candidate target cells and reports the agent's observed
    steps (from-cell to to-cell), and the pack picks the target the agent's moves
    most consistently approach, measured by net reduction in grid (Manhattan)
    distance. From that inferred goal it PREDICTS the agent's next step. Second,
    it tracks BELIEFS separately from truth, so it can name a FALSE BELIEF — a
    thing the agent believes that the true state contradicts — which is the
    classic marker of theory of mind (the Sally-Anne test: Sally believes the
    ball is where she left it, though it has since been moved).

    A cell is written cell(Row, Col).

    Predicates:
      kn_reset/0            -- forget all agents, targets, moves, beliefs, truths
      kn_candidate_add/2    -- +Agent, +TargetCell   (a place the agent might want)
      kn_note_move/3        -- +Agent, +FromCell, +ToCell
      kn_approach/3         -- +Agent, +TargetCell, -NetApproach  (distance closed)
      kn_infer_goal/2       -- +Agent, -TargetCell   (the best-approached candidate)
      kn_predict_next/3     -- +Agent, +CurrentCell, -NextCell   (one step toward goal)
      kn_belief_add/2       -- +Agent, +Fact
      kn_truth_add/1        -- +Fact
      kn_believes/2         -- ?Agent, ?Fact
      kn_true/1             -- ?Fact
      kn_false_belief/2     -- ?Agent, ?Fact   (believed but not true)
*/

% Declare this module and its exported predicates.
:- module(co_kin, [
    % kn_reset/0: forget everything.
    kn_reset/0,
    % kn_candidate_add/2: register a possible target of an agent.
    kn_candidate_add/2,
    % kn_note_move/3: record one observed step of an agent.
    kn_note_move/3,
    % kn_approach/3: how much net distance the agent closed toward a target.
    kn_approach/3,
    % kn_infer_goal/2: the candidate the agent most consistently approaches.
    kn_infer_goal/2,
    % kn_predict_next/3: the agent's likely next step toward its inferred goal.
    kn_predict_next/3,
    % kn_belief_add/2: record what an agent believes.
    kn_belief_add/2,
    % kn_truth_add/1: record a ground truth.
    kn_truth_add/1,
    % kn_believes/2: query beliefs.
    kn_believes/2,
    % kn_true/1: query truths.
    kn_true/1,
    % kn_false_belief/2: a belief the true state contradicts.
    kn_false_belief/2
]).

% Use the list library.
:- use_module(library(lists)).

% candidate/2 is a possible target of an agent; dynamic.
:- dynamic candidate/2.
% move/3 is one observed step From->To of an agent; dynamic.
:- dynamic move/3.
% belief/2 is what an agent believes; dynamic.
:- dynamic belief/2.
% truth/1 is a ground-truth fact; dynamic.
:- dynamic truth/1.

% kn_reset/0: forget agents, targets, moves, beliefs, and truths.
kn_reset :-
    % Remove candidate targets.
    retractall(candidate(_,_)),
    % Remove observed moves.
    retractall(move(_,_,_)),
    % Remove beliefs.
    retractall(belief(_,_)),
    % Remove truths.
    retractall(truth(_)).

% kn_candidate_add/2: register a place the agent might be heading to.
kn_candidate_add(Agent, TargetCell) :-
    % Store it unless it is already known.
    ( candidate(Agent, TargetCell) -> true ; assertz(candidate(Agent, TargetCell)) ).

% kn_note_move/3: record one observed step of an agent.
kn_note_move(Agent, FromCell, ToCell) :-
    % Append the step to the movement log.
    assertz(move(Agent, FromCell, ToCell)).

% kn_approach/3: the net grid distance the agent closed toward a target.
kn_approach(Agent, TargetCell, NetApproach) :-
    % The target must be one of the agent's candidates.
    candidate(Agent, TargetCell),
    % Sum, over each observed step, how much closer to the target it moved.
    findall(Delta,
            ( move(Agent, From, To),
              kn_dist(From, TargetCell, DFrom),
              kn_dist(To, TargetCell, DTo),
              Delta is DFrom - DTo ),
            Deltas),
    % The net approach is the total distance closed (positive means toward).
    sum_list(Deltas, NetApproach).

% kn_infer_goal/2: the candidate the agent's moves most consistently approach.
kn_infer_goal(Agent, TargetCell) :-
    % Score every candidate by net approach.
    findall(Net-T, kn_approach(Agent, T, Net), Pairs),
    % There must be at least one candidate.
    Pairs = [_|_],
    % Sort by net approach descending, keeping ties, and take the best.
    sort(1, @>=, Pairs, [Best-TargetCell|_]),
    % Only claim a goal if the agent is actually moving toward it.
    Best > 0.

% kn_predict_next/3: step one cell from Current toward the inferred goal.
kn_predict_next(Agent, CurrentCell, NextCell) :-
    % Infer where the agent is heading.
    kn_infer_goal(Agent, cell(GR, GC)),
    % Read the current position.
    CurrentCell = cell(R, C),
    % Compute the row and column gaps to the goal.
    DR is GR - R,
    DC is GC - C,
    % Move along whichever axis has the larger remaining gap.
    ( DR =:= 0, DC =:= 0
      -> NextCell = cell(R, C)                       % already there
    ; abs(DR) >= abs(DC)
      -> Step is sign(DR), NR is R + Step, NextCell = cell(NR, C)
    ;  Step is sign(DC), NC is C + Step, NextCell = cell(R, NC) ).

% kn_belief_add/2: record what an agent believes.
kn_belief_add(Agent, Fact) :-
    % Store the belief unless it is already held.
    ( belief(Agent, Fact) -> true ; assertz(belief(Agent, Fact)) ).

% kn_truth_add/1: record a ground-truth fact.
kn_truth_add(Fact) :-
    % Store the truth unless it is already known.
    ( truth(Fact) -> true ; assertz(truth(Fact)) ).

% kn_believes/2: query what an agent believes.
kn_believes(Agent, Fact) :-
    % Read the stored belief.
    belief(Agent, Fact).

% kn_true/1: query the ground truth.
kn_true(Fact) :-
    % Read the stored truth.
    truth(Fact).

% kn_false_belief/2: a belief the agent holds that the true state contradicts.
kn_false_belief(Agent, Fact) :-
    % The agent believes it,
    belief(Agent, Fact),
    % but it is not among the truths (the mark of a false belief).
    \+ truth(Fact).

% ---- internal --------------------------------------------------------------

% kn_dist/3: the grid (Manhattan) distance between two cells.
kn_dist(cell(R1, C1), cell(R2, C2), D) :-
    % Sum the absolute row and column differences.
    D is abs(R1 - R2) + abs(C1 - C2).
