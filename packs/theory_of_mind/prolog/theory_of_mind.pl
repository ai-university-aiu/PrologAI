/*  PrologAI — Theory of Mind  (WP-418, Layer 393; converged with the AGI-Foundations tom pack, WP-389, Layer 364)

    One theory-of-mind faculty, unioned from two implementations by the
    unification program (absorb-and-supersede; neither sub-faculty is lost).

    HALF ONE — CAUSALONTOLOGY THEORY OF MIND (from co_kin). A flat belief store
    over agents, with goal inference from observed movement (an agent that keeps
    approaching a thing is inferred to want it) and Sally-Anne false-belief
    tracking: what an agent believes can diverge from what is true.

    HALF TWO — NESTED MENTAL-MODEL THEORY OF MIND (from the AGI-Foundations tom
    pack). A recursive world model M0/M1/M2... in which an event updates who
    believes what, agents attribute (possibly false) beliefs to other agents,
    and desires and intentions are read off the model. Supports nested "A thinks
    that B thinks that ..." reasoning, mutual/common knowledge, and
    divergent-belief queries.

    All predicates are pack-qualified theory_of_mind_*.
*/

% Declare this module and its exported predicates (the union of both theory-of-mind faculties).
:- module(theory_of_mind, [
    % theory_of_mind_approach/3: exported theory-of-mind predicate.
    theory_of_mind_approach/3,
    % theory_of_mind_belief_add/2: exported theory-of-mind predicate.
    theory_of_mind_belief_add/2,
    % theory_of_mind_believes/2: exported theory-of-mind predicate.
    theory_of_mind_believes/2,
    % theory_of_mind_candidate_add/2: exported theory-of-mind predicate.
    theory_of_mind_candidate_add/2,
    % theory_of_mind_false_belief/2: exported theory-of-mind predicate.
    theory_of_mind_false_belief/2,
    % theory_of_mind_infer_goal/2: exported theory-of-mind predicate.
    theory_of_mind_infer_goal/2,
    % theory_of_mind_note_move/3: exported theory-of-mind predicate.
    theory_of_mind_note_move/3,
    % theory_of_mind_predict_next/3: exported theory-of-mind predicate.
    theory_of_mind_predict_next/3,
    % theory_of_mind_reset/0: exported theory-of-mind predicate.
    theory_of_mind_reset/0,
    % theory_of_mind_true/1: exported theory-of-mind predicate.
    theory_of_mind_true/1,
    % theory_of_mind_truth_add/1: exported theory-of-mind predicate.
    theory_of_mind_truth_add/1,
    % theory_of_mind_attribute/4: exported theory-of-mind predicate.
    theory_of_mind_attribute/4,
    % theory_of_mind_belief/3: exported theory-of-mind predicate.
    theory_of_mind_belief/3,
    % theory_of_mind_beliefs/3: exported theory-of-mind predicate.
    theory_of_mind_beliefs/3,
    % theory_of_mind_believe/4: exported theory-of-mind predicate.
    theory_of_mind_believe/4,
    % theory_of_mind_common/3: exported theory-of-mind predicate.
    theory_of_mind_common/3,
    % theory_of_mind_desire/4: exported theory-of-mind predicate.
    theory_of_mind_desire/4,
    % theory_of_mind_desires/3: exported theory-of-mind predicate.
    theory_of_mind_desires/3,
    % theory_of_mind_divergent/4: exported theory-of-mind predicate.
    theory_of_mind_divergent/4,
    % theory_of_mind_event/4: exported theory-of-mind predicate.
    theory_of_mind_event/4,
    % theory_of_mind_fact/2: exported theory-of-mind predicate.
    theory_of_mind_fact/2,
    % theory_of_mind_false_beliefs/3: exported theory-of-mind predicate.
    theory_of_mind_false_beliefs/3,
    % theory_of_mind_intend/4: exported theory-of-mind predicate.
    theory_of_mind_intend/4,
    % theory_of_mind_intentions/3: exported theory-of-mind predicate.
    theory_of_mind_intentions/3,
    % theory_of_mind_knows/3: exported theory-of-mind predicate.
    theory_of_mind_knows/3,
    % theory_of_mind_new/1: exported theory-of-mind predicate.
    theory_of_mind_new/1,
    % theory_of_mind_perspective/3: exported theory-of-mind predicate.
    theory_of_mind_perspective/3,
    % theory_of_mind_world/2: exported theory-of-mind predicate.
    theory_of_mind_world/2,
    % theory_of_mind_world_add/3: exported theory-of-mind predicate.
    theory_of_mind_world_add/3
]).

% Import list utilities used by both halves.
:- use_module(library(lists)).

% ===========================================================================
% HALF ONE — Causalontology theory of mind (goal inference + false belief)
% ===========================================================================

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

% theory_of_mind_reset/0: forget agents, targets, moves, beliefs, and truths.
theory_of_mind_reset :-
    % Remove candidate targets.
    retractall(candidate(_,_)),
    % Remove observed moves.
    retractall(move(_,_,_)),
    % Remove beliefs.
    retractall(belief(_,_)),
    % Remove truths.
    retractall(truth(_)).

% theory_of_mind_candidate_add/2: register a place the agent might be heading to.
theory_of_mind_candidate_add(Agent, TargetCell) :-
    % Store it unless it is already known.
    ( candidate(Agent, TargetCell) -> true ; assertz(candidate(Agent, TargetCell)) ).

% theory_of_mind_note_move/3: record one observed step of an agent.
theory_of_mind_note_move(Agent, FromCell, ToCell) :-
    % Append the step to the movement log.
    assertz(move(Agent, FromCell, ToCell)).

% theory_of_mind_approach/3: the net grid distance the agent closed toward a target.
theory_of_mind_approach(Agent, TargetCell, NetApproach) :-
    % The target must be one of the agent's candidates.
    candidate(Agent, TargetCell),
    % Sum, over each observed step, how much closer to the target it moved.
    findall(Delta,
            ( move(Agent, From, To),
              theory_of_mind_dist(From, TargetCell, DFrom),
              theory_of_mind_dist(To, TargetCell, DTo),
              Delta is DFrom - DTo ),
            Deltas),
    % The net approach is the total distance closed (positive means toward).
    sum_list(Deltas, NetApproach).

% theory_of_mind_infer_goal/2: the candidate the agent's moves most consistently approach.
theory_of_mind_infer_goal(Agent, TargetCell) :-
    % Score every candidate by net approach.
    findall(Net-T, theory_of_mind_approach(Agent, T, Net), Pairs),
    % There must be at least one candidate.
    Pairs = [_|_],
    % Sort by net approach descending, keeping ties, and take the best.
    sort(1, @>=, Pairs, [Best-TargetCell|_]),
    % Only claim a goal if the agent is actually moving toward it.
    Best > 0.

% theory_of_mind_predict_next/3: step one cell from Current toward the inferred goal.
theory_of_mind_predict_next(Agent, CurrentCell, NextCell) :-
    % Infer where the agent is heading.
    theory_of_mind_infer_goal(Agent, cell(GR, GC)),
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

% theory_of_mind_belief_add/2: record what an agent believes.
theory_of_mind_belief_add(Agent, Fact) :-
    % Store the belief unless it is already held.
    ( belief(Agent, Fact) -> true ; assertz(belief(Agent, Fact)) ).

% theory_of_mind_truth_add/1: record a ground-truth fact.
theory_of_mind_truth_add(Fact) :-
    % Store the truth unless it is already known.
    ( truth(Fact) -> true ; assertz(truth(Fact)) ).

% theory_of_mind_believes/2: query what an agent believes.
theory_of_mind_believes(Agent, Fact) :-
    % Read the stored belief.
    belief(Agent, Fact).

% theory_of_mind_true/1: query the ground truth.
theory_of_mind_true(Fact) :-
    % Read the stored truth.
    truth(Fact).

% theory_of_mind_false_belief/2: a belief the agent holds that the true state contradicts.
theory_of_mind_false_belief(Agent, Fact) :-
    % The agent believes it,
    belief(Agent, Fact),
    % but it is not among the truths (the mark of a false belief).
    \+ truth(Fact).

% ---- internal --------------------------------------------------------------

% theory_of_mind_dist/3: the grid (Manhattan) distance between two cells.
theory_of_mind_dist(cell(R1, C1), cell(R2, C2), D) :-
    % Sum the absolute row and column differences.
    D is abs(R1 - R2) + abs(C1 - C2).

% ===========================================================================
% HALF TWO — Nested mental-model theory of mind (recursive belief worlds)
% ===========================================================================

% Use the lists library for member/2, exclude/3, and friends.
:- use_module(library(lists)).

% ===========================================================================
% CONFLICTS AND UPSERTS
% ===========================================================================

% theory_of_mind_conflicts(+F1, +F2): the two facts cannot both be true.
theory_of_mind_conflicts(believes(A, F1), believes(A2, F2)) :-
    % Nested beliefs conflict when they are about the same believer.
    A == A2,
    % Commit to the nested-belief shape.
    !,
    % And their inner facts conflict.
    theory_of_mind_conflicts(F1, F2).
% Two-argument relations conflict on same subject, different value.
theory_of_mind_conflicts(F1, F2) :-
    % Decompose the first fact.
    F1 =.. [Name, Subject, V1],
    % Decompose the second fact.
    F2 =.. [Name, Subject2, V2],
    % Same subject term.
    Subject == Subject2,
    % Different value term.
    V1 \== V2.

% theory_of_mind_upsert(+Fact, +Facts, -Facts2): insert, replacing conflicts.
theory_of_mind_upsert(Fact, Facts, Facts2) :-
    % Drop every fact this one conflicts with or duplicates.
    exclude(theory_of_mind_displaced(Fact), Facts, Kept),
    % Append the new fact at the end.
    append(Kept, [Fact], Facts2).

% theory_of_mind_displaced(+New, +Old): the old fact must give way to the new one.
theory_of_mind_displaced(New, Old) :-
    % An exact duplicate is displaced.
    (   New == Old
    % Duplicates give way.
    ->  true
    % A conflicting fact also gives way.
    ;   theory_of_mind_conflicts(New, Old)
    ).

% ===========================================================================
% THE MODEL, THE WORLD, AND BELIEFS
% ===========================================================================

% theory_of_mind_new(-M): an empty mental model.
theory_of_mind_new(tm([], [], [], [])).

% theory_of_mind_world_add(+M, +Fact, -M2): upsert a fact into the real world.
theory_of_mind_world_add(tm(W, B, D, I), Fact, tm(W2, B, D, I)) :-
    % Replace whatever the fact conflicts with.
    theory_of_mind_upsert(Fact, W, W2).

% theory_of_mind_world(+M, -Facts): every fact of the real world.
theory_of_mind_world(tm(W, _, _, _), W).

% theory_of_mind_fact(+M, ?Fact): query the real world by unification.
theory_of_mind_fact(tm(W, _, _, _), Fact) :-
    % Enumerate or test the world facts.
    member(Fact, W).

% theory_of_mind_believe(+M, +Agent, +Fact, -M2): upsert one agent's belief.
theory_of_mind_believe(tm(W, B, D, I), Agent, Fact, tm(W, B2, D, I)) :-
    % Collect the agent's current beliefs.
    findall(F, member(bel(Agent, F), B), Own),
    % Upsert the new fact among them.
    theory_of_mind_upsert(Fact, Own, Own2),
    % Keep every other agent's beliefs untouched.
    exclude(theory_of_mind_owned_by(Agent), B, Others),
    % Rewrap the agent's revised beliefs.
    findall(bel(Agent, F2), member(F2, Own2), Wrapped),
    % Join the untouched and the revised beliefs.
    append(Others, Wrapped, B2).

% theory_of_mind_owned_by(+Agent, +Belief): the belief record belongs to the agent.
theory_of_mind_owned_by(Agent, bel(Agent2, _)) :-
    % Ownership is identity of the believer.
    Agent == Agent2.

% theory_of_mind_belief(+M, +Agent, ?Fact): query one agent's beliefs.
theory_of_mind_belief(tm(_, B, _, _), Agent, Fact) :-
    % Enumerate or test the agent's belief records.
    member(bel(Agent, Fact), B).

% theory_of_mind_beliefs(+M, +Agent, -Facts): every belief of one agent.
theory_of_mind_beliefs(tm(_, B, _, _), Agent, Facts) :-
    % Collect the facts of the agent's belief records.
    findall(F, member(bel(Agent, F), B), Facts).

% ===========================================================================
% WITNESSED EVENTS — WHERE FALSE BELIEFS ARE BORN
% ===========================================================================

% theory_of_mind_event(+M, +Fact, +Witnesses, -M2): the world changes; witnesses see it.
theory_of_mind_event(M, Fact, Witnesses, M2) :-
    % The world itself is updated first.
    theory_of_mind_world_add(M, Fact, MW),
    % Each witness revises their own belief about the fact.
    foldl(theory_of_mind_witness(Fact), Witnesses, MW, MB),
    % Each witness also saw the other witnesses seeing it.
    theory_of_mind_mutual(Fact, Witnesses, MB, M2).

% theory_of_mind_witness(+Fact, +Witness, +M, -M2): one witness updates one belief.
theory_of_mind_witness(Fact, Witness, M, M2) :-
    % Seeing is believing.
    theory_of_mind_believe(M, Witness, Fact, M2).

% theory_of_mind_mutual(+Fact, +Witnesses, +M, -M2): pairwise mutual knowledge.
theory_of_mind_mutual(Fact, Witnesses, M, M2) :-
    % Every ordered pair of distinct witnesses is updated.
    findall(W-V,
        % Take each ordered pair.
        ( member(W, Witnesses),
          % Pair it with every other witness.
          member(V, Witnesses),
          % A witness needs no belief about their own seeing here.
          W \== V ),
        Pairs),
    % Record that W believes V now believes the fact.
    foldl(theory_of_mind_mutual_one(Fact), Pairs, M, M2).

% theory_of_mind_mutual_one(+Fact, +Pair, +M, -M2): one second-order update.
theory_of_mind_mutual_one(Fact, W-V, M, M2) :-
    % W saw V watching the event, so W models V's new belief.
    theory_of_mind_believe(M, W, believes(V, Fact), M2).

% ===========================================================================
% KNOWLEDGE, FALSE BELIEFS, AND COMPARISONS
% ===========================================================================

% theory_of_mind_knows(+M, +Agent, ?Fact): knowledge is belief that is also true.
theory_of_mind_knows(M, Agent, Fact) :-
    % The agent believes the fact.
    theory_of_mind_belief(M, Agent, Fact),
    % And the world agrees.
    theory_of_mind_fact(M, Fact).

% theory_of_mind_false_beliefs(+M, +Agent, -Facts): beliefs the world contradicts.
theory_of_mind_false_beliefs(M, Agent, Facts) :-
    % Fetch the agent's beliefs.
    theory_of_mind_beliefs(M, Agent, Own),
    % Fetch the world.
    theory_of_mind_world(M, W),
    % Keep each belief that conflicts with some world fact.
    findall(F,
        % Take each belief in turn.
        ( member(F, Own),
          % It must clash with something actually true.
          member(G, W),
          % The clash test.
          theory_of_mind_conflicts(F, G) ),
        Facts).

% theory_of_mind_attribute(+M, +Observer, +Target, -Facts): modelled beliefs of another.
theory_of_mind_attribute(M, Observer, Target, Facts) :-
    % Collect what the observer believes the target believes.
    findall(F, theory_of_mind_belief(M, Observer, believes(Target, F)), Facts).

% theory_of_mind_divergent(+M, +A, +B, -Pairs): where two agents contradict each other.
theory_of_mind_divergent(M, A, B, Pairs) :-
    % Fetch the first agent's beliefs.
    theory_of_mind_beliefs(M, A, FA),
    % Fetch the second agent's beliefs.
    theory_of_mind_beliefs(M, B, FB),
    % Pair up every conflicting combination.
    findall(diverge(F1, F2),
        % Take each belief of the first agent.
        ( member(F1, FA),
          % Against each belief of the second agent.
          member(F2, FB),
          % Keep the conflicting pairs.
          theory_of_mind_conflicts(F1, F2) ),
        Pairs).

% theory_of_mind_common(+M, +Agents, -Facts): beliefs every listed agent shares.
theory_of_mind_common(M, [First | Rest], Facts) :-
    % Start from the first agent's beliefs.
    theory_of_mind_beliefs(M, First, Own),
    % Keep each belief held identically by all the others.
    findall(F,
        % Take each candidate belief.
        ( member(F, Own),
          % Every other agent must hold it too.
          forall(member(A, Rest), theory_of_mind_belief(M, A, F)) ),
        Facts).

% theory_of_mind_perspective(+M, +Agent, -M2): the world as this agent believes it.
theory_of_mind_perspective(M, Agent, tm(World2, Beliefs2, [], [])) :-
    % Fetch the agent's beliefs.
    theory_of_mind_beliefs(M, Agent, Own),
    % The agent's plain beliefs become the world of the new model.
    findall(F, ( member(F, Own), F \= believes(_, _) ), World2),
    % The agent's nested beliefs become the new model's belief store.
    findall(bel(X, F2), member(believes(X, F2), Own), Beliefs2).

% ===========================================================================
% DESIRES AND INTENTIONS
% ===========================================================================

% theory_of_mind_desire(+M, +Agent, +Goal, -M2): record a goal an agent wants.
theory_of_mind_desire(tm(W, B, D, I), Agent, Goal, tm(W, B, D2, I)) :-
    % Record each desire once.
    (   memberchk(des(Agent, Goal), D)
    % Already recorded: nothing changes.
    ->  D2 = D
    % New desire: append it.
    ;   append(D, [des(Agent, Goal)], D2)
    ).

% theory_of_mind_desires(+M, +Agent, -Goals): every recorded desire of an agent.
theory_of_mind_desires(tm(_, _, D, _), Agent, Goals) :-
    % Collect the agent's desires in order.
    findall(G, member(des(Agent, G), D), Goals).

% theory_of_mind_intend(+M, +Agent, +Act, -M2): record a committed act.
theory_of_mind_intend(tm(W, B, D, I), Agent, Act, tm(W, B, D, I2)) :-
    % Record each intention once.
    (   memberchk(int(Agent, Act), I)
    % Already recorded: nothing changes.
    ->  I2 = I
    % New intention: append it.
    ;   append(I, [int(Agent, Act)], I2)
    ).

% theory_of_mind_intentions(+M, +Agent, -Acts): every recorded intention of an agent.
theory_of_mind_intentions(tm(_, _, _, I), Agent, Acts) :-
    % Collect the agent's intentions in order.
    findall(A, member(int(Agent, A), I), Acts).
