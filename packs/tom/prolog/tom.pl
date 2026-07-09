/*  PrologAI — Theory of Mind  (WP-389, Layer 364)

    Modelling other minds: what each agent believes, desires, and
    intends, including beliefs about other agents' beliefs to any
    nesting depth. The pack passes the classic Sally-Anne false-belief
    test, including the second-order question (where does Anne think
    Sally will look?), because witnessed events update the beliefs of
    the witnesses — and their beliefs about each other — while leaving
    absent agents' beliefs untouched.

    The mental model is a pure term, tm(World, Beliefs, Desires,
    Intentions):

        World       list of facts that are actually true.
        Beliefs     list of bel(Agent, Fact); Fact may itself be
                    believes(Agent2, Fact2), nested arbitrarily deep.
        Desires     list of des(Agent, Goal).
        Intentions  list of int(Agent, Act).

    Two facts conflict when they are the same two-argument relation
    about the same subject with different values — loc(marble, basket)
    conflicts with loc(marble, box). Upserting a fact replaces whatever
    it conflicts with, which is how belief revision happens.

    Exported predicates:

    tm_new/1            -M
    tm_world_add/3      +M, +Fact, -M2
    tm_world/2          +M, -Facts
    tm_fact/2           +M, ?Fact
    tm_believe/4        +M, +Agent, +Fact, -M2
    tm_belief/3         +M, +Agent, ?Fact
    tm_beliefs/3        +M, +Agent, -Facts
    tm_event/4          +M, +Fact, +Witnesses, -M2
    tm_knows/3          +M, +Agent, ?Fact
    tm_false_beliefs/3  +M, +Agent, -Facts
    tm_attribute/4      +M, +Observer, +Target, -Facts
    tm_divergent/4      +M, +A, +B, -Pairs
    tm_common/3         +M, +Agents, -Facts
    tm_perspective/3    +M, +Agent, -M2
    tm_desire/4         +M, +Agent, +Goal, -M2
    tm_desires/3        +M, +Agent, -Goals
    tm_intend/4         +M, +Agent, +Act, -M2
    tm_intentions/3     +M, +Agent, -Acts
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(tom, [
    % tm_new/1: an empty mental model.
    tm_new/1,
    % tm_world_add/3: upsert a fact into the real world.
    tm_world_add/3,
    % tm_world/2: every fact of the real world.
    tm_world/2,
    % tm_fact/2: query the real world.
    tm_fact/2,
    % tm_believe/4: upsert one agent's belief.
    tm_believe/4,
    % tm_belief/3: query one agent's beliefs.
    tm_belief/3,
    % tm_beliefs/3: every belief of one agent.
    tm_beliefs/3,
    % tm_event/4: a witnessed event updates world and witnesses.
    tm_event/4,
    % tm_knows/3: knowledge as true belief.
    tm_knows/3,
    % tm_false_beliefs/3: beliefs contradicting the world.
    tm_false_beliefs/3,
    % tm_attribute/4: what one agent thinks another believes.
    tm_attribute/4,
    % tm_divergent/4: where two agents' beliefs contradict.
    tm_divergent/4,
    % tm_common/3: beliefs shared by every listed agent.
    tm_common/3,
    % tm_perspective/3: re-seat the model inside one agent's head.
    tm_perspective/3,
    % tm_desire/4: record a goal an agent wants.
    tm_desire/4,
    % tm_desires/3: every recorded desire of an agent.
    tm_desires/3,
    % tm_intend/4: record an act an agent has committed to.
    tm_intend/4,
    % tm_intentions/3: every recorded intention of an agent.
    tm_intentions/3
]).

% Use the lists library for member/2, exclude/3, and friends.
:- use_module(library(lists)).

% ===========================================================================
% CONFLICTS AND UPSERTS
% ===========================================================================

% tm_conflicts(+F1, +F2): the two facts cannot both be true.
tm_conflicts(believes(A, F1), believes(A2, F2)) :-
    % Nested beliefs conflict when they are about the same believer.
    A == A2,
    % Commit to the nested-belief shape.
    !,
    % And their inner facts conflict.
    tm_conflicts(F1, F2).
% Two-argument relations conflict on same subject, different value.
tm_conflicts(F1, F2) :-
    % Decompose the first fact.
    F1 =.. [Name, Subject, V1],
    % Decompose the second fact.
    F2 =.. [Name, Subject2, V2],
    % Same subject term.
    Subject == Subject2,
    % Different value term.
    V1 \== V2.

% tm_upsert(+Fact, +Facts, -Facts2): insert, replacing conflicts.
tm_upsert(Fact, Facts, Facts2) :-
    % Drop every fact this one conflicts with or duplicates.
    exclude(tm_displaced(Fact), Facts, Kept),
    % Append the new fact at the end.
    append(Kept, [Fact], Facts2).

% tm_displaced(+New, +Old): the old fact must give way to the new one.
tm_displaced(New, Old) :-
    % An exact duplicate is displaced.
    (   New == Old
    % Duplicates give way.
    ->  true
    % A conflicting fact also gives way.
    ;   tm_conflicts(New, Old)
    ).

% ===========================================================================
% THE MODEL, THE WORLD, AND BELIEFS
% ===========================================================================

% tm_new(-M): an empty mental model.
tm_new(tm([], [], [], [])).

% tm_world_add(+M, +Fact, -M2): upsert a fact into the real world.
tm_world_add(tm(W, B, D, I), Fact, tm(W2, B, D, I)) :-
    % Replace whatever the fact conflicts with.
    tm_upsert(Fact, W, W2).

% tm_world(+M, -Facts): every fact of the real world.
tm_world(tm(W, _, _, _), W).

% tm_fact(+M, ?Fact): query the real world by unification.
tm_fact(tm(W, _, _, _), Fact) :-
    % Enumerate or test the world facts.
    member(Fact, W).

% tm_believe(+M, +Agent, +Fact, -M2): upsert one agent's belief.
tm_believe(tm(W, B, D, I), Agent, Fact, tm(W, B2, D, I)) :-
    % Collect the agent's current beliefs.
    findall(F, member(bel(Agent, F), B), Own),
    % Upsert the new fact among them.
    tm_upsert(Fact, Own, Own2),
    % Keep every other agent's beliefs untouched.
    exclude(tm_owned_by(Agent), B, Others),
    % Rewrap the agent's revised beliefs.
    findall(bel(Agent, F2), member(F2, Own2), Wrapped),
    % Join the untouched and the revised beliefs.
    append(Others, Wrapped, B2).

% tm_owned_by(+Agent, +Belief): the belief record belongs to the agent.
tm_owned_by(Agent, bel(Agent2, _)) :-
    % Ownership is identity of the believer.
    Agent == Agent2.

% tm_belief(+M, +Agent, ?Fact): query one agent's beliefs.
tm_belief(tm(_, B, _, _), Agent, Fact) :-
    % Enumerate or test the agent's belief records.
    member(bel(Agent, Fact), B).

% tm_beliefs(+M, +Agent, -Facts): every belief of one agent.
tm_beliefs(tm(_, B, _, _), Agent, Facts) :-
    % Collect the facts of the agent's belief records.
    findall(F, member(bel(Agent, F), B), Facts).

% ===========================================================================
% WITNESSED EVENTS — WHERE FALSE BELIEFS ARE BORN
% ===========================================================================

% tm_event(+M, +Fact, +Witnesses, -M2): the world changes; witnesses see it.
tm_event(M, Fact, Witnesses, M2) :-
    % The world itself is updated first.
    tm_world_add(M, Fact, MW),
    % Each witness revises their own belief about the fact.
    foldl(tm_witness(Fact), Witnesses, MW, MB),
    % Each witness also saw the other witnesses seeing it.
    tm_mutual(Fact, Witnesses, MB, M2).

% tm_witness(+Fact, +Witness, +M, -M2): one witness updates one belief.
tm_witness(Fact, Witness, M, M2) :-
    % Seeing is believing.
    tm_believe(M, Witness, Fact, M2).

% tm_mutual(+Fact, +Witnesses, +M, -M2): pairwise mutual knowledge.
tm_mutual(Fact, Witnesses, M, M2) :-
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
    foldl(tm_mutual_one(Fact), Pairs, M, M2).

% tm_mutual_one(+Fact, +Pair, +M, -M2): one second-order update.
tm_mutual_one(Fact, W-V, M, M2) :-
    % W saw V watching the event, so W models V's new belief.
    tm_believe(M, W, believes(V, Fact), M2).

% ===========================================================================
% KNOWLEDGE, FALSE BELIEFS, AND COMPARISONS
% ===========================================================================

% tm_knows(+M, +Agent, ?Fact): knowledge is belief that is also true.
tm_knows(M, Agent, Fact) :-
    % The agent believes the fact.
    tm_belief(M, Agent, Fact),
    % And the world agrees.
    tm_fact(M, Fact).

% tm_false_beliefs(+M, +Agent, -Facts): beliefs the world contradicts.
tm_false_beliefs(M, Agent, Facts) :-
    % Fetch the agent's beliefs.
    tm_beliefs(M, Agent, Own),
    % Fetch the world.
    tm_world(M, W),
    % Keep each belief that conflicts with some world fact.
    findall(F,
        % Take each belief in turn.
        ( member(F, Own),
          % It must clash with something actually true.
          member(G, W),
          % The clash test.
          tm_conflicts(F, G) ),
        Facts).

% tm_attribute(+M, +Observer, +Target, -Facts): modelled beliefs of another.
tm_attribute(M, Observer, Target, Facts) :-
    % Collect what the observer believes the target believes.
    findall(F, tm_belief(M, Observer, believes(Target, F)), Facts).

% tm_divergent(+M, +A, +B, -Pairs): where two agents contradict each other.
tm_divergent(M, A, B, Pairs) :-
    % Fetch the first agent's beliefs.
    tm_beliefs(M, A, FA),
    % Fetch the second agent's beliefs.
    tm_beliefs(M, B, FB),
    % Pair up every conflicting combination.
    findall(diverge(F1, F2),
        % Take each belief of the first agent.
        ( member(F1, FA),
          % Against each belief of the second agent.
          member(F2, FB),
          % Keep the conflicting pairs.
          tm_conflicts(F1, F2) ),
        Pairs).

% tm_common(+M, +Agents, -Facts): beliefs every listed agent shares.
tm_common(M, [First | Rest], Facts) :-
    % Start from the first agent's beliefs.
    tm_beliefs(M, First, Own),
    % Keep each belief held identically by all the others.
    findall(F,
        % Take each candidate belief.
        ( member(F, Own),
          % Every other agent must hold it too.
          forall(member(A, Rest), tm_belief(M, A, F)) ),
        Facts).

% tm_perspective(+M, +Agent, -M2): the world as this agent believes it.
tm_perspective(M, Agent, tm(World2, Beliefs2, [], [])) :-
    % Fetch the agent's beliefs.
    tm_beliefs(M, Agent, Own),
    % The agent's plain beliefs become the world of the new model.
    findall(F, ( member(F, Own), F \= believes(_, _) ), World2),
    % The agent's nested beliefs become the new model's belief store.
    findall(bel(X, F2), member(believes(X, F2), Own), Beliefs2).

% ===========================================================================
% DESIRES AND INTENTIONS
% ===========================================================================

% tm_desire(+M, +Agent, +Goal, -M2): record a goal an agent wants.
tm_desire(tm(W, B, D, I), Agent, Goal, tm(W, B, D2, I)) :-
    % Record each desire once.
    (   memberchk(des(Agent, Goal), D)
    % Already recorded: nothing changes.
    ->  D2 = D
    % New desire: append it.
    ;   append(D, [des(Agent, Goal)], D2)
    ).

% tm_desires(+M, +Agent, -Goals): every recorded desire of an agent.
tm_desires(tm(_, _, D, _), Agent, Goals) :-
    % Collect the agent's desires in order.
    findall(G, member(des(Agent, G), D), Goals).

% tm_intend(+M, +Agent, +Act, -M2): record a committed act.
tm_intend(tm(W, B, D, I), Agent, Act, tm(W, B, D, I2)) :-
    % Record each intention once.
    (   memberchk(int(Agent, Act), I)
    % Already recorded: nothing changes.
    ->  I2 = I
    % New intention: append it.
    ;   append(I, [int(Agent, Act)], I2)
    ).

% tm_intentions(+M, +Agent, -Acts): every recorded intention of an agent.
tm_intentions(tm(_, _, _, I), Agent, Acts) :-
    % Collect the agent's intentions in order.
    findall(A, member(int(Agent, A), I), Acts).
