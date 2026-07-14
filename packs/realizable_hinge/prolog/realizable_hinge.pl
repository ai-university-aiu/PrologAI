/*  PrologAI — Causalontology Hinge  (WP-392, Layer 367)

    The HINGE layer of the Causalontology Foundational Ontology (Causalontology_v5,
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
      realizable_hinge_reset/0           -- clear the hinge layer
      realizable_hinge_quality_add/3           -- +Id, +Quality, +Bearer
      realizable_hinge_quality/3               -- ?Id, ?Quality, ?Bearer
      realizable_hinge_realizable_add/3        -- +Id, +Kind, +Bearer
      realizable_hinge_realizable/3            -- ?Id, ?Kind, ?Bearer
      realizable_hinge_realized_in_add/2       -- +RealizableId, +OccurrentType
      realizable_hinge_realized_in/2           -- ?RealizableId, ?OccurrentType
      realizable_hinge_bearer_realizables/2    -- +Bearer, -Realizables
      realizable_hinge_of_occurrent/2    -- +OccurrentType, -RealizableId
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(realizable_hinge, [
    % realizable_hinge_reset/0: clear the hinge layer.
    realizable_hinge_reset/0,
    % realizable_hinge_quality_add/3: record a quality inhering in a bearer.
    realizable_hinge_quality_add/3,
    % realizable_hinge_quality/3: query the qualities.
    realizable_hinge_quality/3,
    % realizable_hinge_realizable_add/3: record a disposition, function, or role.
    realizable_hinge_realizable_add/3,
    % realizable_hinge_realizable/3: query the realizables.
    realizable_hinge_realizable/3,
    % realizable_hinge_realized_in_add/2: the seam — a realizable realized in an occurrent.
    realizable_hinge_realized_in_add/2,
    % realizable_hinge_realized_in/2: query the realization seam.
    realizable_hinge_realized_in/2,
    % realizable_hinge_bearer_realizables/2: every realizable an object bears.
    realizable_hinge_bearer_realizables/2,
    % realizable_hinge_of_occurrent/2: the realizable an occurrent type realizes.
    realizable_hinge_of_occurrent/2
]).

% Import list helpers.
:- use_module(library(lists), [member/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% realizable_hinge_quality_/3: (Id, Quality, Bearer) — exhibited whenever borne.
:- dynamic realizable_hinge_quality_/3.
% realizable_hinge_realizable_/3: (Id, Kind, Bearer) — Kind in {disposition, function, role}.
:- dynamic realizable_hinge_realizable_/3.
% realizable_hinge_realized_in_/2: (RealizableId, OccurrentType) — the seam into the verbs.
:- dynamic realizable_hinge_realized_in_/2.

% Define realizable_hinge_reset: clear every hinge store.
realizable_hinge_reset :-
    % Drop the qualities.
    retractall(realizable_hinge_quality_(_, _, _)),
    % Drop the realizables.
    retractall(realizable_hinge_realizable_(_, _, _)),
    % Drop the realization seam.
    retractall(realizable_hinge_realized_in_(_, _)).

% ---------------------------------------------------------------------------
% Qualities
% ---------------------------------------------------------------------------

% Define realizable_hinge_quality_add: a quality is exhibited whenever it is borne.
realizable_hinge_quality_add(Id, Quality, Bearer) :-
    % Replace any previous record under this identifier.
    retractall(realizable_hinge_quality_(Id, _, _)),
    % Record the quality.
    assertz(realizable_hinge_quality_(Id, Quality, Bearer)).

% Define realizable_hinge_quality: query the qualities.
realizable_hinge_quality(Id, Quality, Bearer) :-
    % Enumerate or test the store.
    realizable_hinge_quality_(Id, Quality, Bearer).

% ---------------------------------------------------------------------------
% Realizables — dispositions, functions, and roles
% ---------------------------------------------------------------------------

% Define realizable_hinge_realizable_add: only the three lawful kinds are accepted.
realizable_hinge_realizable_add(Id, Kind, Bearer) :-
    % A realizable is a disposition, a function, or a role.
    memberchk(Kind, [disposition, function, role]),
    % Replace any previous record under this identifier.
    retractall(realizable_hinge_realizable_(Id, _, _)),
    % Record the realizable.
    assertz(realizable_hinge_realizable_(Id, Kind, Bearer)).

% Define realizable_hinge_realizable: query the realizables.
realizable_hinge_realizable(Id, Kind, Bearer) :-
    % Enumerate or test the store.
    realizable_hinge_realizable_(Id, Kind, Bearer).

% ---------------------------------------------------------------------------
% The realization seam — noun-shaped, verb-facing
% ---------------------------------------------------------------------------

% Define realizable_hinge_realized_in_add: tie a realizable to the occurrent realizing it.
realizable_hinge_realized_in_add(RealizableId, OccurrentType) :-
    % Only a recorded realizable can be realized.
    realizable_hinge_realizable_(RealizableId, _, _),
    % Record the seam edge once.
    (   realizable_hinge_realized_in_(RealizableId, OccurrentType)
    % Already present: nothing to add.
    ->  true
    % New edge: record it.
    ;   assertz(realizable_hinge_realized_in_(RealizableId, OccurrentType))
    ).

% Define realizable_hinge_realized_in: query the realization seam.
realizable_hinge_realized_in(RealizableId, OccurrentType) :-
    % Enumerate or test the store.
    realizable_hinge_realized_in_(RealizableId, OccurrentType).

% Define realizable_hinge_bearer_realizables: every realizable an object bears.
realizable_hinge_bearer_realizables(Bearer, Realizables) :-
    % Collect the realizables of this bearer with their kinds.
    findall(realizable(Id, Kind), realizable_hinge_realizable_(Id, Kind, Bearer), Realizables).

% Define realizable_hinge_of_occurrent: which realizable an occurrent type realizes.
realizable_hinge_of_occurrent(OccurrentType, RealizableId) :-
    % Read the seam backwards, from verb to hinge.
    realizable_hinge_realized_in_(RealizableId, OccurrentType).
