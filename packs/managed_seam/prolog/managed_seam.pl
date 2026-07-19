% managed_seam — a first-class MANAGED cross-stratal seam construct.
% Work Package WP-433, Layer 0 (base infrastructure, atop the lattice store and the
% causal_core vocabulary). Closes the Requirements Ledger's Theme B (cross-stratal
% seams and managed skips), the program's MOST-RECURRING gap — six sightings: P1, P2,
% STRATA-2, ARBITER-2, HIPPO-3, CEREBELLUM-2, AMYGDALA-2.
%
% A process legitimately spans NON-ADJACENT strata (a hormone descends ten levels;
% consolidation rises from molecule to region). A bare skips:true boolean could not do
% three things this construct now does:
%   (a) DISTINGUISH "an intervening mechanism EXISTS but is deliberately unmodeled
%       here" from "NO mechanism exists" — the honest-ignorance distinction, carried in
%       a first-class mechanism_status of absent | unmodeled | modeled;
%   (b) MODEL the intervening mechanism as a chain of adjacent-stratum steps (status
%       modeled), checked well-formed against the Causalontology 3.0.0 Algorithm F; and
%   (c) give a cross-stratal construct that belongs to an EDGE a checkable HOME — the
%       coarsest (max-ordinal) endpoint stratum — so a stratum pack can VERIFY the home
%       rather than each arm conventionally piling the construct into a stratum.
% It also EMITS the seam as a queryable Lattice event, so a skip is visible to the
% runtime (P1/P2), not merely legible to the static structure.
%
% The well-formedness and home rules delegate to the frozen causal_core engine
% (causal_core_seam_wellformed/4, causal_core_seam_home/4); this pack is the ergonomic,
% honest-ignorance-aware, runtime-visible construct built on that vocabulary.

% Declare the module and its public interface.
:- module(managed_seam,
    [ % Build a managed seam from endpoints, a mechanism status, and an optional chain.
      managed_seam_new/5,             % +Source, +Target, +Status, +Chain, -Seam
      % The set of recognised mechanism statuses.
      managed_seam_status/1,          % ?Status
      % The glass-box English meaning of a mechanism status.
      managed_seam_status_meaning/2,  % +Status, -Meaning
      % A seam's mechanism status.
      managed_seam_mechanism_status/2,% +Seam, -Status
      % Is the seam an honest-ignorance skip (a mechanism exists but is unmodeled)?
      managed_seam_is_honest_ignorance/1, % +Seam
      % Check a seam is well-formed against a stratum model (delegates to Algorithm F).
      managed_seam_wellformed/4,      % +Seam, +OccMap, +StratumMap, -Result
      % The seam's HOME stratum — the coarsest endpoint (delegates to the home rule).
      managed_seam_home/4,            % +Seam, +OccMap, +StratumMap, -HomeStratum
      % Check a PROPOSED home equals the seam's true home (the checkable home rule).
      managed_seam_home_check/5,      % +Seam, +OccMap, +StratumMap, +ProposedHome, -Result
      % Emit a seam as a queryable Lattice event (a skip becomes visible to the runtime).
      managed_seam_emit/2,            % +Nexus, +Seam
      % Query every emitted seam event on a nexus.
      managed_seam_events/2,          % +Nexus, -Seams
      % Query emitted seam events with a given mechanism status.
      managed_seam_events_by_status/3 % +Nexus, +Status, -Seams
    ]).

% Use the Lattice store — the shared glass-box memory the seam events live in.
:- use_module(library(lattice)).
% Use the Causalontology vocabulary core — its Algorithm F well-formedness and home rule.
:- use_module(library(causal_core)).

% -- The relation name under which each emitted seam event is stored in the nexus.
managed_seam_event_relation(managed_seam_event).

% -- managed_seam_status(?Status): the three recognised mechanism statuses.
% absent    — NO intervening mechanism exists; the jump is genuinely direct.
% unmodeled — an intervening mechanism EXISTS but is deliberately not modelled here.
% modeled   — the intervening mechanism is drawn as a chain of adjacent-stratum steps.
managed_seam_status(absent).
managed_seam_status(unmodeled).
managed_seam_status(modeled).

% -- managed_seam_status_meaning(+Status, -Meaning): the glass-box English of a status.
managed_seam_status_meaning(absent,
    'no intervening mechanism exists; the cross-stratal jump is genuinely direct').
managed_seam_status_meaning(unmodeled,
    'an intervening mechanism exists but is deliberately unmodelled at this cut (honest ignorance)').
managed_seam_status_meaning(modeled,
    'the intervening mechanism is drawn as a chain of adjacent-stratum steps').

% -- managed_seam_new(+Source, +Target, +Status, +Chain, -Seam): build a managed seam.
% The chain is coupled to the status: modeled REQUIRES a non-empty chain; absent and
% unmodeled REQUIRE an empty chain. This makes the honest-ignorance distinction
% first-class AND makes the absent-plus-chain contradiction impossible to construct.
managed_seam_new(Source, Target, Status, Chain, Seam) :-
    % The status must be one of the three recognised values.
    ( managed_seam_status(Status)
    ->  true
    ;   throw(error(domain_error(managed_seam_status, Status),
                    context(managed_seam_new/5, 'status is one of absent, unmodeled, modeled')))
    ),
    % Branch on whether the mechanism is drawn (modeled) or not (absent/unmodeled).
    ( Status == modeled
    ->  % A modelled mechanism must carry a non-empty chain of intervening steps.
        ( Chain = [_|_]
        ->  Seam = seam{source: Source, target: Target, mechanism_status: modeled, chain: Chain}
        ;   throw(error(domain_error(non_empty_chain, Chain),
                        context(managed_seam_new/5, 'a modeled seam must draw a non-empty chain of adjacent-stratum steps')))
        )
    ;   % An absent or unmodeled mechanism must NOT carry a chain.
        ( Chain == []
        ->  Seam = seam{source: Source, target: Target, mechanism_status: Status}
        ;   throw(error(domain_error(empty_chain, Chain),
                        context(managed_seam_new/5, 'an absent or unmodeled seam draws no chain')))
        )
    ).

% -- managed_seam_mechanism_status(+Seam, -Status): read a seam's mechanism status.
managed_seam_mechanism_status(Seam, Status) :-
    % Read the status field and normalise it to an atom.
    get_dict(mechanism_status, Seam, Raw),
    causal_core_atomize(Raw, Status).

% -- managed_seam_is_honest_ignorance(+Seam): the seam skips a mechanism that EXISTS.
% True exactly when the status is unmodeled — the distinction a bare boolean could not draw.
managed_seam_is_honest_ignorance(Seam) :-
    managed_seam_mechanism_status(Seam, unmodeled).

% -- managed_seam_wellformed(+Seam, +OccMap, +StratumMap, -Result): Algorithm F check.
% Delegates to the frozen causal_core engine: endpoints have strata, share a scheme,
% are NON-adjacent, and any drawn chain is intervening and strictly monotone.
managed_seam_wellformed(Seam, OccMap, StratumMap, Result) :-
    causal_core_seam_wellformed(Seam, OccMap, StratumMap, Result).

% -- managed_seam_home(+Seam, +OccMap, +StratumMap, -HomeStratum): the home rule.
% Delegates to causal_core: the home is the coarsest (max-ordinal) endpoint stratum.
managed_seam_home(Seam, OccMap, StratumMap, HomeStratum) :-
    causal_core_seam_home(Seam, OccMap, StratumMap, HomeStratum).

% -- managed_seam_home_check(+Seam, +OccMap, +StratumMap, +ProposedHome, -Result):
% the CHECKABLE home rule — verify a proposed home equals the seam's true home.
% A stratum pack calls this to confirm a spanning construct belongs to it, rather than
% each arm conventionally choosing a stratum (STRATA-2).
managed_seam_home_check(Seam, OccMap, StratumMap, ProposedHome, Result) :-
    % Compute the true home — the coarsest endpoint.
    managed_seam_home(Seam, OccMap, StratumMap, TrueHome),
    % The proposed home is correct only if it equals the true home.
    ( ProposedHome == TrueHome
    ->  Result = ok(TrueHome)
    ;   Result = invalid(wrong_home(proposed(ProposedHome), true_home(TrueHome)))
    ).

% -- managed_seam_emit(+Nexus, +Seam): record the seam as a queryable Lattice event.
% This is the P1/P2 remedy: a skip is now visible to the RUNTIME (a queryable event),
% not merely legible to the static structure.
managed_seam_emit(Nexus, Seam) :-
    % Name the seam-event relation.
    managed_seam_event_relation(Relation),
    % Store the whole seam as a Lattice fact so it can be queried later.
    lattice_put(Nexus, Relation, [Seam], []).

% -- managed_seam_events(+Nexus, -Seams): every emitted seam event on this nexus.
managed_seam_events(Nexus, Seams) :-
    % Name the seam-event relation.
    managed_seam_event_relation(Relation),
    % Collect every stored seam.
    findall(Seam, lattice_get(Nexus, Relation, [Seam], []), Seams).

% -- managed_seam_events_by_status(+Nexus, +Status, -Seams): emitted seams of one status.
% This is the ARBITER-2 remedy: an unmodeled skip is queryable AS DISTINCT from an absent one.
managed_seam_events_by_status(Nexus, Status, Seams) :-
    % Collect every emitted seam.
    managed_seam_events(Nexus, All),
    % Keep only those whose mechanism status matches.
    include(managed_seam_has_status(Status), All, Seams).

% -- managed_seam_has_status(+Status, +Seam): the seam carries this mechanism status.
managed_seam_has_status(Status, Seam) :-
    % Compare the seam's status to the requested one.
    managed_seam_mechanism_status(Seam, Status).
