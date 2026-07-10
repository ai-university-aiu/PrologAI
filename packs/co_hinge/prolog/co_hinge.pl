/*  PrologAI — Causalontology Hinge  (WP-392, Layer 367)

    The HINGE layer of the Causalontology Master Ontology (Causalontology_v5,
    Sections 3.3 and 5): the specifically dependent continuants. Qualities
    are exhibited whenever borne; realizable entities — dispositions,
    functions, and roles — inhere in objects yet are realized in occurrents.
    The hinge belongs ontologically to the nouns, because its entities are
    continuants, but it points into the verbs, because the realization
    relation that gives realizables their meaning terminates in occurrents
    that Causalontology governs.

    Notation (Section 12): realizable(Id, Kind, Bearer) with
    realized_in(Realizable, Occurrent).

    Predicates:
      co_hinge_reset/0           -- clear the hinge layer
      co_quality_add/3           -- +Id, +Quality, +Bearer
      co_quality/3               -- ?Id, ?Quality, ?Bearer
      co_realizable_add/3        -- +Id, +Kind, +Bearer
      co_realizable/3            -- ?Id, ?Kind, ?Bearer
      co_realized_in_add/2       -- +RealizableId, +OccurrentType
      co_realized_in/2           -- ?RealizableId, ?OccurrentType
      co_bearer_realizables/2    -- +Bearer, -Realizables
      co_hinge_of_occurrent/2    -- +OccurrentType, -RealizableId
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(co_hinge, [
    % co_hinge_reset/0: clear the hinge layer.
    co_hinge_reset/0,
    % co_quality_add/3: record a quality inhering in a bearer.
    co_quality_add/3,
    % co_quality/3: query the qualities.
    co_quality/3,
    % co_realizable_add/3: record a disposition, function, or role.
    co_realizable_add/3,
    % co_realizable/3: query the realizables.
    co_realizable/3,
    % co_realized_in_add/2: the seam — a realizable realized in an occurrent.
    co_realized_in_add/2,
    % co_realized_in/2: query the realization seam.
    co_realized_in/2,
    % co_bearer_realizables/2: every realizable an object bears.
    co_bearer_realizables/2,
    % co_hinge_of_occurrent/2: the realizable an occurrent type realizes.
    co_hinge_of_occurrent/2
]).

% Import list helpers.
:- use_module(library(lists), [member/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% co_quality_/3: (Id, Quality, Bearer) — exhibited whenever borne.
:- dynamic co_quality_/3.
% co_realizable_/3: (Id, Kind, Bearer) — Kind in {disposition, function, role}.
:- dynamic co_realizable_/3.
% co_realized_in_/2: (RealizableId, OccurrentType) — the seam into the verbs.
:- dynamic co_realized_in_/2.

% Define co_hinge_reset: clear every hinge store.
co_hinge_reset :-
    % Drop the qualities.
    retractall(co_quality_(_, _, _)),
    % Drop the realizables.
    retractall(co_realizable_(_, _, _)),
    % Drop the realization seam.
    retractall(co_realized_in_(_, _)).

% ---------------------------------------------------------------------------
% Qualities
% ---------------------------------------------------------------------------

% Define co_quality_add: a quality is exhibited whenever it is borne.
co_quality_add(Id, Quality, Bearer) :-
    % Replace any previous record under this identifier.
    retractall(co_quality_(Id, _, _)),
    % Record the quality.
    assertz(co_quality_(Id, Quality, Bearer)).

% Define co_quality: query the qualities.
co_quality(Id, Quality, Bearer) :-
    % Enumerate or test the store.
    co_quality_(Id, Quality, Bearer).

% ---------------------------------------------------------------------------
% Realizables — dispositions, functions, and roles
% ---------------------------------------------------------------------------

% Define co_realizable_add: only the three lawful kinds are accepted.
co_realizable_add(Id, Kind, Bearer) :-
    % A realizable is a disposition, a function, or a role.
    memberchk(Kind, [disposition, function, role]),
    % Replace any previous record under this identifier.
    retractall(co_realizable_(Id, _, _)),
    % Record the realizable.
    assertz(co_realizable_(Id, Kind, Bearer)).

% Define co_realizable: query the realizables.
co_realizable(Id, Kind, Bearer) :-
    % Enumerate or test the store.
    co_realizable_(Id, Kind, Bearer).

% ---------------------------------------------------------------------------
% The realization seam — noun-shaped, verb-facing
% ---------------------------------------------------------------------------

% Define co_realized_in_add: tie a realizable to the occurrent realizing it.
co_realized_in_add(RealizableId, OccurrentType) :-
    % Only a recorded realizable can be realized.
    co_realizable_(RealizableId, _, _),
    % Record the seam edge once.
    (   co_realized_in_(RealizableId, OccurrentType)
    % Already present: nothing to add.
    ->  true
    % New edge: record it.
    ;   assertz(co_realized_in_(RealizableId, OccurrentType))
    ).

% Define co_realized_in: query the realization seam.
co_realized_in(RealizableId, OccurrentType) :-
    % Enumerate or test the store.
    co_realized_in_(RealizableId, OccurrentType).

% Define co_bearer_realizables: every realizable an object bears.
co_bearer_realizables(Bearer, Realizables) :-
    % Collect the realizables of this bearer with their kinds.
    findall(realizable(Id, Kind), co_realizable_(Id, Kind, Bearer), Realizables).

% Define co_hinge_of_occurrent: which realizable an occurrent type realizes.
co_hinge_of_occurrent(OccurrentType, RealizableId) :-
    % Read the seam backwards, from verb to hinge.
    co_realized_in_(RealizableId, OccurrentType).
