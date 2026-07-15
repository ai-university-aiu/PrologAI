/*  PrologAI — Situational Awareness: Evolving Regards  (Specification PR 51)

    The Building Sentient Beings vision (section 3.2.4 and Figures 16-17) holds
    that situational awareness is engineered, not assumed, and that it develops
    through a ladder of viewpoints: from an initial general awareness, to a
    self-interested view, to the views of other minds (theory of mind), to an
    owned view of one's own preferences and responsibility, and finally to a
    disowned view of one's aversions and blind spots.

    PrologAI names each viewpoint a REGARD, and gives every level an original
    name so no imported (source-origin) vocabulary enters the platform:

        ambient_regard      — the initial, undifferentiated general awareness;
                              the default standpoint of a freshly booted mind.
        selfward_regard     — the view from self-awareness and self-interest.
        otherward_regard(A) — a view attributed to another mind A (theory of
                              mind); one is opened per modelled agent on demand.
        avowed_regard       — the owned view: consciousness, preferences, and
                              responsibility (what the mind claims as its own).
        disavowed_regard    — the disowned view: ignorance, aversions, and the
                              freedom the mind does not yet integrate.

    A proposition can be HELD under a regard, so the same content may be believed
    from one standpoint and denied from another.  The mind has one ACTIVE regard
    at a time — the standpoint it currently reasons from — beginning at
    ambient_regard.  Theory-of-mind perspective taking attributes propositions to
    an other's regard and detects DIVERGENCE (the other holding the negation of
    what the self holds), the computational core of false-belief reasoning.
    Reconciliation integrates the avowed and disavowed regards into one coherent
    self-account, surfacing disowned material rather than leaving it hidden.

    Negation convention: a proposition P and the term not(P) are contradictories.

    Predicates:
        awareness_regard_kinds/1       — -Kinds            (ladder order)
        awareness_regard_open/1        — +Regard
        awareness_regard_hold/2        — +Regard, +Prop
        awareness_regard_held/2        — +Regard, -Prop
        awareness_regard_shift/1       — +Regard
        awareness_regard_active/1      — -Regard
        awareness_regard_level/2       — +Regard, -Level
        awareness_tom_attribute/2      — +Agent, +Prop
        awareness_tom_divergence/2     — +Agent, -Divergences
        awareness_regard_reconcile/1   — -Integrated
*/

% Declare this file as the 'awareness' module and list its exported predicates.
:- module(awareness, [
    % Continue the multi-line expression started above.
    awareness_regard_kinds/1,         % -Kinds (ladder order)
    % Continue the multi-line expression started above.
    awareness_regard_open/1,          % +Regard
    % Continue the multi-line expression started above.
    awareness_regard_hold/2,          % +Regard, +Prop
    % Continue the multi-line expression started above.
    awareness_regard_held/2,          % +Regard, -Prop
    % Continue the multi-line expression started above.
    awareness_regard_shift/1,         % +Regard
    % Continue the multi-line expression started above.
    awareness_regard_active/1,        % -Regard
    % Continue the multi-line expression started above.
    awareness_regard_level/2,         % +Regard, -Level
    % Continue the multi-line expression started above.
    awareness_tom_attribute/2,        % +Agent, +Prop
    % Continue the multi-line expression started above.
    awareness_tom_divergence/2,       % +Agent, -Divergences
    % Supply 'awareness_regard_reconcile/1' as the next argument to the expression above.
    awareness_regard_reconcile/1      % -Integrated
% Close the expression opened above.
]).

% Import [member/2, append/3] from the built-in 'lists' library.
:- use_module(library(lists), [member/2, append/3]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% Declare 'regard/1' as dynamic — the set of opened regards (viewpoints).
:- dynamic regard/1.
% Declare 'held/2' as dynamic — Regard, Prop (a proposition held under a regard).
:- dynamic held/2.
% Declare 'active_regard/1' as dynamic — the single current standpoint.
:- dynamic active_regard/1.

% ---------------------------------------------------------------------------
% The ladder of standing regard kinds, with developmental level indices
% ---------------------------------------------------------------------------

% State the fact: ambient general awareness is developmental level one.
regard_kind_level(ambient_regard, 1).
% State the fact: the self-interested view is developmental level two.
regard_kind_level(selfward_regard, 2).
% State the fact: theory-of-mind views of others are developmental level three.
regard_kind_level(otherward_regard, 3).
% State the fact: the owned view is developmental level four.
regard_kind_level(avowed_regard, 4).
% State the fact: the disowned view is developmental level five.
regard_kind_level(disavowed_regard, 5).

% ---------------------------------------------------------------------------
% Initialization — open the agent-independent standing regards and set default
% ---------------------------------------------------------------------------

% Execute the initialization directive once the module has loaded.
:- initialization(awareness_bootstrap).

% Define 'awareness_bootstrap': open the standing regards and seed the default standpoint.
awareness_bootstrap :-
    % Open the ambient general-awareness regard.
    ensure_regard(ambient_regard),
    % Open the self-interested regard.
    ensure_regard(selfward_regard),
    % Open the owned (avowed) regard.
    ensure_regard(avowed_regard),
    % Open the disowned (disavowed) regard.
    ensure_regard(disavowed_regard),
    % Seed the active standpoint at ambient awareness if none is set yet.
    ( active_regard(_) -> true ; assertz(active_regard(ambient_regard)) ).

% Define 'ensure_regard': open a regard if it is not already open.
ensure_regard(Regard) :-
    % If the regard already exists, do nothing; otherwise record it.
    ( regard(Regard) -> true ; assertz(regard(Regard)) ).

% ---------------------------------------------------------------------------
% awareness_regard_kinds/1 — the ladder of standing kinds, in developmental order
% ---------------------------------------------------------------------------

% Define 'awareness_regard_kinds': return the standing regard kinds in ladder order.
awareness_regard_kinds([ambient_regard, selfward_regard, otherward_regard,
                  avowed_regard, disavowed_regard]).

% ---------------------------------------------------------------------------
% awareness_regard_open/1 — ensure a regard (standing or otherward(Agent)) exists
% ---------------------------------------------------------------------------

% Define 'awareness_regard_open': open the given regard, validating its kind.
awareness_regard_open(Regard) :-
    % Confirm the regard is a recognised viewpoint before opening it.
    valid_regard(Regard),
    % Open it (idempotent).
    ensure_regard(Regard),
    % Commit deterministically.
    !.

% Define 'valid_regard' for otherward_regard(Agent) — any ground agent is allowed.
valid_regard(otherward_regard(Agent)) :-
    % Require the agent term to be ground so the viewpoint is well-identified.
    ground(Agent),
    % Commit deterministically.
    !.
% Define 'valid_regard' for the standing kinds — accept any kind with a level.
valid_regard(Regard) :-
    % Confirm the regard names a known standing kind.
    regard_kind_level(Regard, _Level).

% ---------------------------------------------------------------------------
% awareness_regard_hold/2 — hold a proposition under a regard
% ---------------------------------------------------------------------------

% Define 'awareness_regard_hold': record Prop as held under Regard.
awareness_regard_hold(Regard, Prop) :-
    % Open the regard if necessary (validates the kind too).
    awareness_regard_open(Regard),
    % Avoid storing a duplicate of the same held proposition.
    ( held(Regard, Prop) -> true ; assertz(held(Regard, Prop)) ),
    % Commit deterministically.
    !.

% ---------------------------------------------------------------------------
% awareness_regard_held/2 — query propositions held under a regard
% ---------------------------------------------------------------------------

% Define 'awareness_regard_held': enumerate the propositions held under Regard.
awareness_regard_held(Regard, Prop) :-
    % Retrieve a stored held proposition for this regard.
    held(Regard, Prop).

% ---------------------------------------------------------------------------
% awareness_regard_shift/1 — set the active standpoint
% ---------------------------------------------------------------------------

% Define 'awareness_regard_shift': make Regard the active standpoint.
awareness_regard_shift(Regard) :-
    % Open the regard if necessary (validates the kind too).
    awareness_regard_open(Regard),
    % Remove any previous active standpoint.
    retractall(active_regard(_)),
    % Install the new active standpoint.
    assertz(active_regard(Regard)),
    % Commit deterministically.
    !.

% ---------------------------------------------------------------------------
% awareness_regard_active/1 — query the active standpoint
% ---------------------------------------------------------------------------

% Define 'awareness_regard_active': read the current standpoint, defaulting to ambient.
awareness_regard_active(Regard) :-
    % If an active standpoint is set, return it; otherwise default to ambient.
    ( active_regard(R) -> Regard = R ; Regard = ambient_regard ),
    % Commit deterministically.
    !.

% ---------------------------------------------------------------------------
% awareness_regard_level/2 — the developmental level index of a regard
% ---------------------------------------------------------------------------

% Define 'awareness_regard_level' for otherward_regard(Agent) — level of the others tier.
awareness_regard_level(otherward_regard(_Agent), Level) :-
    % Look up the level for the otherward tier.
    regard_kind_level(otherward_regard, Level),
    % Commit deterministically.
    !.
% Define 'awareness_regard_level' for a standing regard — its tabled level.
awareness_regard_level(Regard, Level) :-
    % Look up the level directly for the standing kind.
    regard_kind_level(Regard, Level),
    % Commit deterministically.
    !.

% ---------------------------------------------------------------------------
% awareness_tom_attribute/2 — attribute a proposition to another mind (theory of mind)
% ---------------------------------------------------------------------------

% Define 'awareness_tom_attribute': hold Prop under Agent's otherward regard.
awareness_tom_attribute(Agent, Prop) :-
    % Hold the attributed proposition under the agent's own viewpoint.
    awareness_regard_hold(otherward_regard(Agent), Prop),
    % Commit deterministically.
    !.

% ---------------------------------------------------------------------------
% awareness_tom_divergence/2 — propositions where self and other contradict each other
% ---------------------------------------------------------------------------

% Define 'awareness_tom_divergence': collect contradictions between self and Agent.
awareness_tom_divergence(Agent, Divergences) :-
    % Find every self-held / other-held pair that contradict one another.
    findall(divergence(SelfProp, OtherProp),
            % The self holds SelfProp from its self-interested view.
            ( held(selfward_regard, SelfProp),
              % The agent's attributed view holds OtherProp.
              held(otherward_regard(Agent), OtherProp),
              % The two propositions are contradictories.
              contradicts(SelfProp, OtherProp)
            ),
            % Collect the raw divergence list.
            Divergences0),
    % Sort to remove duplicates and give a stable order.
    sort(Divergences0, Divergences),
    % Commit deterministically.
    !.

% Define 'contradicts' — P and not(P) are contradictories (first orientation).
contradicts(P, not(P)) :-
    % Commit deterministically for this orientation.
    !.
% Define 'contradicts' — not(P) and P are contradictories (second orientation).
contradicts(not(P), P) :-
    % Commit deterministically for this orientation.
    !.

% ---------------------------------------------------------------------------
% awareness_regard_reconcile/1 — integrate the avowed and disavowed views
% ---------------------------------------------------------------------------

% Define 'awareness_regard_reconcile': merge owned and disowned views into one account.
awareness_regard_reconcile(Integrated) :-
    % Collect every proposition held under the owned (avowed) regard.
    findall(avowed(P), held(avowed_regard, P), Avowed),
    % Collect every proposition held under the disowned (disavowed) regard.
    findall(disavowed(Q), held(disavowed_regard, Q), Disavowed),
    % Append the disowned material onto the owned material.
    append(Avowed, Disavowed, Combined),
    % Sort to give a stable, duplicate-free integrated self-account.
    sort(Combined, Integrated),
    % Commit deterministically.
    !.
