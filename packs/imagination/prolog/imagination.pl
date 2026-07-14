/*  PrologAI — Imagination  (WP-421, Layer 396; converged with the daydream and imagination packs)

    One imagination faculty, unioned from three implementations by the
    unification program (absorb-and-supersede; no sub-faculty is lost). The
    Lattice-integrated dream engine (the dreaming pack) is deliberately kept
    separate, as it depends on the live Lattice, sona, and attention.

    HALF ONE — QUARANTINED REALITIES (from co_muse). Five walled-off realities
    (observed, desired, expected, imagined, recalled) each hold their own facts
    and a transition model, so the mind can simulate "what if" without polluting
    what it believes; a promotion discipline moves a fact from imagined to
    observed only on purpose.

    HALF TWO — MIND-WANDERING (from the daydream pack). A daydream is steered
    from a seed episode toward a control goal, produces a product, and can be
    terminated by a worsen-emotion guard.

    HALF THREE — MINDSCAPE / REVERIE / TABLEAU (from the imagination pack). A
    mindscape holds figures seen from a vantage; a tableau grounds elements; a
    reverie renders a sequence of frames from an imaginative reality.

    All predicates are pack-qualified imagination_*.
*/

% Declare this module and its exported predicates (the union of the three imagination faculties).
:- module(imagination, [
    % imagination_assert/2: exported imagination predicate.
    imagination_assert/2,
    % imagination_best_plan/4: exported imagination predicate.
    imagination_best_plan/4,
    % imagination_clear/1: exported imagination predicate.
    imagination_clear/1,
    % imagination_evaluate/3: exported imagination predicate.
    imagination_evaluate/3,
    % imagination_holds/2: exported imagination predicate.
    imagination_holds/2,
    % imagination_imagine/3: exported imagination predicate.
    imagination_imagine/3,
    % imagination_promote/3: exported imagination predicate.
    imagination_promote/3,
    % imagination_quarantined/1: exported imagination predicate.
    imagination_quarantined/1,
    % imagination_reaches/3: exported imagination predicate.
    imagination_reaches/3,
    % imagination_realities/1: exported imagination predicate.
    imagination_realities/1,
    % imagination_reset/0: exported imagination predicate.
    imagination_reset/0,
    % imagination_steps_to/3: exported imagination predicate.
    imagination_steps_to/3,
    % imagination_transition_add/3: exported imagination predicate.
    imagination_transition_add/3,
    % imagination_control_goal/2: exported imagination predicate.
    imagination_control_goal/2,
    % imagination_daydream_product/2: exported imagination predicate.
    imagination_daydream_product/2,
    % imagination_daydream_steer/2: exported imagination predicate.
    imagination_daydream_steer/2,
    % imagination_daydream_terminate/1: exported imagination predicate.
    imagination_daydream_terminate/1,
    % imagination_imagine_fresh/4: exported imagination predicate.
    imagination_imagine_fresh/4,
    % imagination_mindscape_clear/1: exported imagination predicate.
    imagination_mindscape_clear/1,
    % imagination_mindscape_new/2: exported imagination predicate.
    imagination_mindscape_new/2,
    % imagination_mindscape_reality/2: exported imagination predicate.
    imagination_mindscape_reality/2,
    % imagination_reverie_frames/2: exported imagination predicate.
    imagination_reverie_frames/2,
    % imagination_reverie_render/3: exported imagination predicate.
    imagination_reverie_render/3,
    % imagination_tableau_add/3: exported imagination predicate.
    imagination_tableau_add/3,
    % imagination_tableau_ground/3: exported imagination predicate.
    imagination_tableau_ground/3
]).

% List utilities used by all three halves.
:- use_module(library(lists)).

% ===========================================================================
% HALF ONE — Quarantined realities (from co_muse)
% ===========================================================================


% fact/2 holds one fact in one reality; it changes at runtime, so it is dynamic.
:- dynamic fact/2.
% transition/3 is a known state-action-next step used for imagining; dynamic.
:- dynamic transition/3.

% imagination_reset/0: forget every stored fact and every transition.
imagination_reset :-
    % Remove all facts from all realities.
    retractall(fact(_,_)),
    % Remove the transition model.
    retractall(transition(_,_,_)).

% imagination_realities/1: the five standard reality partitions.
imagination_realities([observed, desired, expected, imagined, recalled]).

% imagination_assert/2: place a fact in a named reality, without duplication.
imagination_assert(Reality, Fact) :-
    % Store it unless the same fact already sits in that reality.
    ( fact(Reality, Fact) -> true ; assertz(fact(Reality, Fact)) ).

% imagination_holds/2: query the facts held in a reality.
imagination_holds(Reality, Fact) :-
    % Read the stored fact.
    fact(Reality, Fact).

% imagination_clear/1: empty one reality partition.
imagination_clear(Reality) :-
    % Remove every fact tagged with that reality.
    retractall(fact(Reality, _)).

% imagination_transition_add/3: record a known transition for imagining.
imagination_transition_add(State, Action, NextState) :-
    % Store it unless the same transition is already known.
    ( transition(State, Action, NextState) -> true
    ; assertz(transition(State, Action, NextState)) ).

% imagination_imagine/3: roll a start state forward through a sequence, sealing the path.
imagination_imagine(Start, ActionSeq, Trajectory) :-
    % Walk the sequence from the start, collecting the states visited.
    imagination_roll(Start, ActionSeq, States),
    % The trajectory begins at the start and continues through those states.
    Trajectory = [Start | States],
    % Seal every visited state into the imagined reality (quarantined from fact).
    forall(member(S, Trajectory), imagination_assert(imagined, visited(S))).

% imagination_roll/3: follow the transitions for each action, stopping if one is unknown.
imagination_roll(_, [], []) :-
    % An empty remaining sequence visits no further states (committed).
    !.
imagination_roll(State, [Action | Rest], Visited) :-
    % Take the known transition for this state and action if there is one.
    ( transition(State, Action, Next)
      -> % Record the next state and keep rolling from it.
         Visited = [Next | More],
         imagination_roll(Next, Rest, More)
      ;  % No transition is known: imagining halts here.
         Visited = [] ).

% imagination_reaches/3: the final state reached by a sequence from a start.
imagination_reaches(Start, ActionSeq, EndState) :-
    % Imagine the trajectory and take its last state.
    imagination_imagine(Start, ActionSeq, Trajectory),
    last(Trajectory, EndState).

% imagination_evaluate/3: score a trajectory as 1.0 if it reaches the goal, else 0.0.
imagination_evaluate(Trajectory, GoalState, Score) :-
    % A reached goal scores one; an unreached goal scores zero.
    ( memberchk(GoalState, Trajectory) -> Score = 1.0 ; Score = 0.0 ).

% imagination_steps_to/3: how many steps into the trajectory the goal first appears.
imagination_steps_to(Trajectory, GoalState, Steps) :-
    % Find the position of the goal (zero-based: the start is step zero).
    nth0(Steps, Trajectory, GoalState),
    % Commit to the first occurrence.
    !.

% imagination_best_plan/4: the candidate sequence that reaches the goal in fewest steps.
imagination_best_plan(Start, CandidateSeqs, GoalState, BestSeq) :-
    % Score each candidate that actually reaches the goal by its step count.
    findall(Steps-Seq,
            ( member(Seq, CandidateSeqs),
              imagination_imagine(Start, Seq, Traj),
              imagination_steps_to(Traj, GoalState, Steps) ),
            Reaching),
    % At least one candidate must reach the goal.
    Reaching = [_|_],
    % Prefer the fewest steps, breaking ties by enumeration order.
    keysort(Reaching, [_-BestSeq | _]).

% imagination_quarantined/1: a fact imagined but not observed — sealed off from fact.
imagination_quarantined(Fact) :-
    % It is present in the imagined reality,
    fact(imagined, Fact),
    % but absent from the observed reality.
    \+ fact(observed, Fact).

% imagination_promote/3: a deliberate, auditable copy of a fact from one reality to another.
imagination_promote(FromReality, Fact, ToReality) :-
    % The fact must actually be held in the source reality (commit to it).
    fact(FromReality, Fact),
    !,
    % Copy it into the destination reality (imagining never does this by itself).
    imagination_assert(ToReality, Fact).

% ===========================================================================
% HALF TWO — Mind-wandering (from the daydream pack)
% ===========================================================================


% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% Declare 'active_daydream/3.   % DaydreamId, ControlGoal, Valence' as dynamic — its facts may be added or removed at runtime.
:- dynamic active_daydream/3.   % DaydreamId, ControlGoal, Valence
% Declare 'daydream_product/3.  % DaydreamId, Product, Tag(imagined|validated)' as dynamic — its facts may be added or removed at runtime.
:- dynamic daydream_product/3.  % DaydreamId, Product, Tag(imagined|validated)
% Declare 'daydream_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic daydream_id_counter/1.
% State the fact: daydream id counter(0).
daydream_id_counter(0).

% Define a clause for 'next daydream id': succeed when the following conditions hold.
next_daydream_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(daydream_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(daydream_id_counter(N1)),
    % State the fact: atomic list concat([daydream_, N1], Id).
    atomic_list_concat([daydream_, N1], Id).

% ---------------------------------------------------------------------------
% Control-goal trigger mapping
%
%   Episode = episode(Valence, Arousal, Cause, Outcome)
%     Cause   = self | other(Agent) | unknown
%     Outcome = failure | success | planned
% ---------------------------------------------------------------------------

% Define a clause for 'pai control goal': succeed when the following conditions hold.
imagination_control_goal(episode(V, _A, Cause, Outcome), ControlGoal) :-
    % State the fact: select control goal(V, Cause, Outcome, ControlGoal).
    select_control_goal(V, Cause, Outcome, ControlGoal).

% Define a clause for 'select control goal': succeed when the following conditions hold.
select_control_goal(V, _Cause, failure, rationalization) :-
    % Check that 'V' is less than '-0.3, !'.
    V < -0.3, !.
% Define a clause for 'select control goal': succeed when the following conditions hold.
select_control_goal(V, other(_), failure, reprisal_fantasy) :-
    % Check that 'V' is less than '0.0, !'.
    V < 0.0, !.
% Define a clause for 'select control goal': succeed when the following conditions hold.
select_control_goal(_V, _Cause, failure, reversal) :- !.
% Define a clause for 'select control goal': succeed when the following conditions hold.
select_control_goal(_V, _Cause, success, reversal) :- !.
% Define a clause for 'select control goal': succeed when the following conditions hold.
select_control_goal(_V, _Cause, planned, preparation) :- !.
% State a fact for 'select control goal' with the arguments listed below.
select_control_goal(_V, _Cause, _Out,   preparation).  % default: preparation

% ---------------------------------------------------------------------------
% imagination_daydream_steer/2
%
%   Open a daydream, generate a useful product, write it back tagged
%   `imagined`.  Returns a product term describing what was produced.
%
%   Episode carries initial valence; the product contains a new_valence
%   that must be >= original (worsen-emotion guard).
%   reprisal_fantasy products are tagged never_execute.
% ---------------------------------------------------------------------------

% Define a clause for 'pai daydream steer': succeed when the following conditions hold.
imagination_daydream_steer(Episode, DaydreamProduct) :-
    % State a fact for 'pai control goal' with the arguments listed below.
    imagination_control_goal(Episode, ControlGoal),
    % Check that 'Episode' is unifiable with 'episode(Valence, Arousal, _Cause, _Outcome)'.
    Episode = episode(Valence, Arousal, _Cause, _Outcome),
    % State a fact for 'next daydream id' with the arguments listed below.
    next_daydream_id(DId),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(active_daydream(DId, ControlGoal, Valence)),
    % State a fact for 'run daydream' with the arguments listed below.
    run_daydream(DId, ControlGoal, Valence, Arousal, Product),
    % Check that 'Product' is unifiable with 'product(_, NewValence, _)'.
    Product = product(_, NewValence, _),
    % Worsen-emotion guard: only keep the product if emotion improves
    % Check that '( NewValence' is greater than or equal to 'Valence'.
    ( NewValence >= Valence
    % If the condition above succeeded, perform the following action.
    ->  tag_product(DId, ControlGoal, Product),
        % Continue the multi-line expression started above.
        DaydreamProduct = product(DId, ControlGoal, Product)
    % Otherwise (else branch), perform the following action.
    ;   retract(active_daydream(DId, ControlGoal, Valence)),
        % Continue the multi-line expression started above.
        imagination_daydream_terminate(DId),
        % Continue the multi-line expression started above.
        DaydreamProduct = terminated(DId, worsened_emotion)
    % Close the expression opened above.
    ).

% State a fact for 'run daydream' with the arguments listed below.
run_daydream(DId, rationalization, Valence, _Arousal,
             % Continue the multi-line expression started above.
             product(strategy(reframe_outcome), NewValence, imagined)) :-
    % Evaluate the arithmetic expression 'min(0.0, Valence + 0.3)' and bind the result to 'NewValence'.
    NewValence is min(0.0, Valence + 0.3),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(daydream_product(DId,
            % Continue the multi-line expression started above.
            strategy(reframe_outcome, from(Valence), to(NewValence)),
            % Supply 'imagined' as the next argument to the expression above.
            imagined)).

% State a fact for 'run daydream' with the arguments listed below.
run_daydream(DId, reprisal_fantasy, Valence, _Arousal,
             % Continue the multi-line expression started above.
             product(fantasy(imagined_redress), NewValence, never_execute)) :-
    % Evaluate the arithmetic expression 'Valence + 0.4' and bind the result to 'NewValence'.
    NewValence is Valence + 0.4,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(daydream_product(DId,
            % Continue the multi-line expression started above.
            fantasy(imagined_redress, never_execute),
            % Supply 'never_execute' as the next argument to the expression above.
            never_execute)).

% State a fact for 'run daydream' with the arguments listed below.
run_daydream(DId, reversal, Valence, _Arousal,
             % Continue the multi-line expression started above.
             product(strategy(learn_from_reversal), NewValence, imagined)) :-
    % Evaluate the arithmetic expression 'Valence + 0.2' and bind the result to 'NewValence'.
    NewValence is Valence + 0.2,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(daydream_product(DId,
            % Continue the multi-line expression started above.
            strategy(learn_from_reversal),
            % Supply 'imagined' as the next argument to the expression above.
            imagined)).

% State a fact for 'run daydream' with the arguments listed below.
run_daydream(DId, preparation, Valence, _Arousal,
             % Continue the multi-line expression started above.
             product(scenario(rehearsal), NewValence, imagined)) :-
    % Evaluate the arithmetic expression 'Valence + 0.1' and bind the result to 'NewValence'.
    NewValence is Valence + 0.1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(daydream_product(DId,
            % Continue the multi-line expression started above.
            scenario(rehearsal),
            % Supply 'imagined' as the next argument to the expression above.
            imagined)).

% Define a clause for 'tag product': succeed when the following conditions hold.
tag_product(_DId, reprisal_fantasy, _Product) :- !.   % never_execute, no extra action
% State the fact: tag product(_DId, _ControlGoal, _Product).
tag_product(_DId, _ControlGoal, _Product).

% ---------------------------------------------------------------------------
% imagination_daydream_terminate/1
% ---------------------------------------------------------------------------

% Define a clause for 'pai daydream terminate': succeed when the following conditions hold.
imagination_daydream_terminate(DaydreamId) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(active_daydream(DaydreamId, _, _)).

% ---------------------------------------------------------------------------
% imagination_daydream_product/2
% ---------------------------------------------------------------------------

% Define a clause for 'pai daydream product': succeed when the following conditions hold.
imagination_daydream_product(DaydreamId, Product) :-
    % State the fact: daydream product(DaydreamId, Product, _Tag).
    daydream_product(DaydreamId, Product, _Tag).

% ===========================================================================
% HALF THREE — Mindscape / reverie / tableau (from the imagination pack)
% ===========================================================================


% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% Declare 'mindscape/2' as dynamic — MindscapeId, Reality.
:- dynamic mindscape/2.
% Declare 'tableau/2' as dynamic — TableauId, MindscapeId.
:- dynamic tableau/2.
% Declare 'tableau_element/4' as dynamic — TableauId, Kind, Ref, Props.
:- dynamic tableau_element/4.
% Declare 'reverie/3' as dynamic — ReverieId, MindscapeId, Frames.
:- dynamic reverie/3.
% Declare 'id_counter/1' as dynamic — the monotonic unique-id source.
:- dynamic id_counter/1.

% State the fact: the imaginative realities allowed for a mindscape.
imaginative_reality(imagined).
% State the fact: a hypothetical reality is also imaginative (sandboxed).
imaginative_reality(hypothetical).
% State the fact: a recalled reality is imaginative for replay purposes.
imaginative_reality(recalled).

% Define a clause for 'valid_kind': vantage is a legal element kind.
valid_kind(vantage).
% Define a clause for 'valid_kind': figure is a legal element kind.
valid_kind(figure).
% Define a clause for 'valid_kind': motif is a legal element kind.
valid_kind(motif).

% ---------------------------------------------------------------------------
% next_id/1 — allocate a fresh unique id (guarded critical section)
% ---------------------------------------------------------------------------

% Define 'next_id': produce the next integer id, advancing the counter.
next_id(Id) :-
    % Use a mutex so concurrent mechanisms never receive duplicate ids.
    with_mutex(imagination_ids, next_id_unlocked(Id)).

% Define 'next_id_unlocked' for the case where a counter already exists.
next_id_unlocked(Id) :-
    % Check that a current counter value is present.
    retract(id_counter(N)),
    % Compute the next value by adding one.
    Id is N + 1,
    % Store the advanced counter back.
    assertz(id_counter(Id)),
    % Cut to commit to this clause.
    !.
% Define 'next_id_unlocked' for the first allocation when no counter exists.
next_id_unlocked(1) :-
    % Seed the counter at one.
    assertz(id_counter(1)).

% ---------------------------------------------------------------------------
% imagination_mindscape_new/2 — create a compartmentalized canvas in a sandboxed reality
% ---------------------------------------------------------------------------

% Define 'imagination_mindscape_new': create a new mindscape held in Reality.
imagination_mindscape_new(Reality, MindscapeId) :-
    % GUARD — accept the reality only if it is an imaginative (non-observed) one.
    imaginative_reality(Reality),
    % Allocate a fresh id for the mindscape.
    next_id(N),
    % Build a readable identifier atom for the mindscape.
    atom_concat(mindscape_, N, MindscapeId),
    % Record the new mindscape and its reality.
    assertz(mindscape(MindscapeId, Reality)),
    % Commit to this mindscape deterministically.
    !.

% ---------------------------------------------------------------------------
% imagination_mindscape_reality/2 — query the sandbox reality of a mindscape
% ---------------------------------------------------------------------------

% Define 'imagination_mindscape_reality': look up the reality a mindscape lives in.
imagination_mindscape_reality(MindscapeId, Reality) :-
    % Retrieve the stored mindscape fact.
    mindscape(MindscapeId, Reality),
    % Commit to the single stored reality deterministically.
    !.

% ---------------------------------------------------------------------------
% imagination_tableau_add/3 — bind a list of elements into a tableau on a mindscape
% ---------------------------------------------------------------------------

% Define 'imagination_tableau_add': place a tableau of Elements onto MindscapeId.
imagination_tableau_add(MindscapeId, Elements, TableauId) :-
    % Confirm the target mindscape exists before binding anything.
    mindscape(MindscapeId, _),
    % Confirm every element is well-formed before committing.
    forall(member(El, Elements), valid_element(El)),
    % Allocate a fresh id for the tableau.
    next_id(N),
    % Build a readable identifier atom for the tableau.
    atom_concat(tableau_, N, TableauId),
    % Record the tableau and its owning mindscape.
    assertz(tableau(TableauId, MindscapeId)),
    % Store each element of the tableau as its own fact.
    store_elements(TableauId, Elements),
    % Commit to this tableau deterministically.
    !.

% Define 'valid_element': an element is element(Kind, Ref, Props) with a legal kind.
valid_element(element(Kind, _Ref, Props)) :-
    % Check the kind is one of vantage, figure, or motif.
    valid_kind(Kind),
    % Check the properties form a proper list.
    is_list(Props),
    % Commit deterministically.
    !.

% Define 'store_elements' for the empty list — nothing left to store.
store_elements(_TableauId, []).
% Define 'store_elements' for a non-empty list — store the head, recurse on the tail.
store_elements(TableauId, [element(Kind, Ref, Props) | Rest]) :-
    % Assert this element under its tableau.
    assertz(tableau_element(TableauId, Kind, Ref, Props)),
    % Continue with the remaining elements.
    store_elements(TableauId, Rest).

% ---------------------------------------------------------------------------
% imagination_tableau_ground/3 — reuse a perceived object as a figure on a tableau
% ---------------------------------------------------------------------------

% Define 'imagination_tableau_ground': add a grounded figure referencing a percept.
imagination_tableau_ground(TableauId, Percept, Percept) :-
    % Confirm the tableau exists before grounding into it.
    tableau(TableauId, _),
    % Record a figure element that references the perceived object.
    assertz(tableau_element(TableauId, figure, Percept, [grounded(true), pos(0, 0)])),
    % Commit to this grounding deterministically.
    !.

% ---------------------------------------------------------------------------
% imagination_reverie_render/3 — render a mindscape's tableaux into a Steps-frame reverie
% ---------------------------------------------------------------------------

% Define 'imagination_reverie_render': produce a reverie of Steps frames for a mindscape.
imagination_reverie_render(MindscapeId, Steps, ReverieId) :-
    % Confirm the mindscape exists.
    mindscape(MindscapeId, Reality),
    % GUARD — never render into the observed reality (defensive; impossible by construction).
    Reality \== observed,
    % Require at least one frame.
    integer(Steps),
    % Require the step count to be positive.
    Steps >= 1,
    % Collect the vantage (camera) for this mindscape, defaulting if absent.
    mindscape_vantage(MindscapeId, Vantage),
    % Collect all figure elements belonging to this mindscape.
    mindscape_figures(MindscapeId, Figures),
    % Compute the last frame index.
    Last is Steps - 1,
    % Build the list of frame indices from 0 to Last.
    numlist(0, Last, Indices),
    % Render every frame index into a frame term.
    render_frames(Indices, Vantage, Figures, Frames),
    % Allocate a fresh id for the reverie.
    next_id(N),
    % Build a readable identifier atom for the reverie.
    atom_concat(reverie_, N, ReverieId),
    % Store the rendered reverie.
    assertz(reverie(ReverieId, MindscapeId, Frames)),
    % Commit to this reverie deterministically.
    !.

% Define 'mindscape_vantage' — find the first vantage across the mindscape's tableaux.
mindscape_vantage(MindscapeId, Vantage) :-
    % Succeed if some tableau of this mindscape carries a vantage element.
    tableau(TableauId, MindscapeId),
    % Read that vantage's reference as the camera angle.
    tableau_element(TableauId, vantage, Vantage, _Props),
    % Commit to the first vantage found.
    !.
% Define 'mindscape_vantage' fallback — no vantage was placed, so use a default.
mindscape_vantage(_MindscapeId, default_vantage).

% Define 'mindscape_figures' — gather every figure element across the mindscape.
mindscape_figures(MindscapeId, Figures) :-
    % Collect figure(Ref, Props) for each figure element under each tableau.
    findall(figure(Ref, Props),
            % For each tableau of this mindscape that carries a figure element.
            ( tableau(TableauId, MindscapeId),
              % Read the figure element's reference and properties.
              tableau_element(TableauId, figure, Ref, Props)
            ),
            % Bind the assembled list of figures.
            Figures).

% Define 'render_frames' for the empty index list — no more frames.
render_frames([], _Vantage, _Figures, []).
% Define 'render_frames' for a non-empty index list — render head frame, recurse.
render_frames([F | Rest], Vantage, Figures, [frame(F, Vantage, States) | More]) :-
    % Compute every figure's state at frame index F.
    figure_states_at(Figures, F, States),
    % Render the remaining frames.
    render_frames(Rest, Vantage, Figures, More).

% Define 'figure_states_at' for the empty figure list — no states.
figure_states_at([], _F, []).
% Define 'figure_states_at' for a non-empty figure list — state head, recurse.
figure_states_at([figure(Ref, Props) | Rest], F, [figure(Ref, pos(Xf, Yf)) | More]) :-
    % Read the starting X position from the figure's properties, default 0.
    prop_value(Props, pos_x, 0, X0),
    % Read the starting Y position from the figure's properties, default 0.
    prop_value(Props, pos_y, 0, Y0),
    % Read the X velocity from the figure's properties, default 0.
    prop_value(Props, vel_x, 0, Dx),
    % Read the Y velocity from the figure's properties, default 0.
    prop_value(Props, vel_y, 0, Dy),
    % Advance the X position kinematically by velocity times frame index.
    Xf is X0 + Dx * F,
    % Advance the Y position kinematically by velocity times frame index.
    Yf is Y0 + Dy * F,
    % Compute the remaining figure states.
    figure_states_at(Rest, F, More).

% Define 'prop_value' — read a scalar from a property list with named accessors.
prop_value(Props, pos_x, Default, V) :-
    % If the props carry pos(X,_), take X; otherwise the default.
    ( member(pos(X, _), Props) -> V = X ; V = Default ), !.
% Define 'prop_value' for pos_y — read the Y of a pos(_,Y) term.
prop_value(Props, pos_y, Default, V) :-
    % If the props carry pos(_,Y), take Y; otherwise the default.
    ( member(pos(_, Y), Props) -> V = Y ; V = Default ), !.
% Define 'prop_value' for vel_x — read the DX of a vel(DX,_) term.
prop_value(Props, vel_x, Default, V) :-
    % If the props carry vel(DX,_), take DX; otherwise the default.
    ( member(vel(Dx, _), Props) -> V = Dx ; V = Default ), !.
% Define 'prop_value' for vel_y — read the DY of a vel(_,DY) term.
prop_value(Props, vel_y, Default, V) :-
    % If the props carry vel(_,DY), take DY; otherwise the default.
    ( member(vel(_, Dy), Props) -> V = Dy ; V = Default ), !.

% ---------------------------------------------------------------------------
% imagination_reverie_frames/2 — query the frames of a rendered reverie
% ---------------------------------------------------------------------------

% Define 'imagination_reverie_frames': retrieve the frame list of a reverie.
imagination_reverie_frames(ReverieId, Frames) :-
    % Look up the stored reverie record.
    reverie(ReverieId, _MindscapeId, Frames),
    % Commit to the single stored reverie deterministically.
    !.

% ---------------------------------------------------------------------------
% imagination_mindscape_clear/1 — empty a canvas of its tableaux, elements, and reveries
% ---------------------------------------------------------------------------

% Define 'imagination_mindscape_clear': remove everything drawn on a mindscape.
imagination_mindscape_clear(MindscapeId) :-
    % Confirm the mindscape exists.
    mindscape(MindscapeId, _),
    % Remove each tableau's elements, then the tableau itself.
    forall(tableau(TableauId, MindscapeId),
           % Retract the elements of this tableau and the tableau fact.
           ( retractall(tableau_element(TableauId, _, _, _)),
             % Retract the tableau itself.
             retractall(tableau(TableauId, MindscapeId))
           )),
    % Remove any reveries rendered from this mindscape.
    retractall(reverie(_, MindscapeId, _)),
    % Commit deterministically.
    !.

% ---------------------------------------------------------------------------
% imagination_imagine_fresh/4 — convenience: new mindscape + one tableau + render
% ---------------------------------------------------------------------------

% Define 'imagination_imagine_fresh': imagine an entirely new scene end to end.
imagination_imagine_fresh(Reality, Elements, Steps, ReverieId) :-
    % Create a fresh compartmentalized mindscape in the given reality.
    imagination_mindscape_new(Reality, MindscapeId),
    % Bind the supplied elements into a single tableau on it.
    imagination_tableau_add(MindscapeId, Elements, _TableauId),
    % Render the mindscape into a reverie of the requested length.
    imagination_reverie_render(MindscapeId, Steps, ReverieId),
    % Commit deterministically.
    !.
