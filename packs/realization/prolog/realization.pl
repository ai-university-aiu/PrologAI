% realization — bind a grounded Causalontology STRUCTURE record to the native
% DYNAMICAL law or Lattice signal that REALIZES it, by identity.
% Work Package WP-434, Layer 0 (base infrastructure, atop the lattice store).
% Closes the Requirements Ledger's Theme C (the structure-to-dynamics seam / grounding
% fit): P1's dynamics facet, P3, P4, and STRATA-5.
%
% Every neurochemical and every computing construct is TWO things at once: a grounded
% Causalontology STRUCTURE record and a native DYNAMICAL law or variable. The grounding
% rule (ground the structure, keep the dynamics native) is correct, but the two halves
% were related only by a shared English word — nothing bound them by IDENTITY, so the
% glass box could not trace from "what a synapse computes" (structure) to "how it
% computes it" (dynamics). This construct is that binding, and it makes the trace REAL:
% the realizer must actually EXIST (a defined predicate; an open nexus), not a dangling
% label. Because the binding is itself the cross-cut, structure and dynamics need not
% share a stratum pack — which, per the grounding rule, they never can (STRATA-5).
%
% A realizer is one of:
%   native_law(PredicateIndicator)  — a named native predicate (Name/Arity or
%                                      Module:Name/Arity) that realizes the record's
%                                      transform (P1, P3).
%   lattice_signal(Nexus, Relation) — a typed signal on the Lattice that realizes the
%                                      record (P4): a value, a source port, a timestamp.

% Declare the module and its public interface.
:- module(realization,
    [ % Bind a structure record's id to the realizer that dynamically realizes it.
      realization_bind/2,            % +StructureId, +Realizer
      % Remove every binding of a structure record.
      realization_unbind/1,          % +StructureId
      % Query: a structure record's realizer(s).
      realization_realized_by/2,     % ?StructureId, ?Realizer
      % Query the inverse: what a realizer realizes.
      realization_realizes/2,        % ?Realizer, ?StructureId
      % Does the realizer actually exist (a defined predicate; an open nexus)?
      realization_realizer_exists/1, % +Realizer
      % Check a structure's binding: bound, and every realizer real.
      realization_check/2,           % +StructureId, -Result
      % Check every registered binding at once.
      realization_check_all/1,       % -Report
      % A glass-box trace from a structure record to its realizer and its existence.
      realization_trace/2,           % +StructureId, -Trace
      % Emit a typed signal on the Lattice (the P4 signal helper).
      realization_emit_signal/5,     % +Nexus, +Relation, +Value, +SourcePort, +Timestamp
      % Read the typed signals on the Lattice.
      realization_signal/5           % +Nexus, +Relation, ?Value, ?SourcePort, ?Timestamp
    ]).

% Use the Lattice store — the typed signals and the nexus-existence check live there.
:- use_module(library(lattice)).
% Use the standard list library for reporting.
:- use_module(library(lists)).

% Declare the binding registry dynamic — one fact per (structure record, realizer).
:- dynamic realization_binding/2.  % StructureId, Realizer

% -- realization_bind(+StructureId, +Realizer): register that Realizer realizes StructureId.
realization_bind(StructureId, Realizer) :-
    % The realizer must be a well-formed native_law or lattice_signal term.
    ( realization_valid_realizer(Realizer)
    ->  true
    ;   throw(error(domain_error(realization_realizer, Realizer),
                    context(realization_bind/2, 'a realizer is native_law(PredIndicator) or lattice_signal(Nexus, Relation)')))
    ),
    % Do not duplicate an identical binding.
    ( realization_binding(StructureId, Realizer)
    ->  true
    ;   assertz(realization_binding(StructureId, Realizer))
    ).

% -- realization_valid_realizer(+Realizer): the realizer term is well-formed.
% A native law names a predicate as Name/Arity or Module:Name/Arity.
realization_valid_realizer(native_law(M:N/A)) :- atom(M), atom(N), integer(A), A >= 0, !.
realization_valid_realizer(native_law(N/A)) :- atom(N), integer(A), A >= 0, !.
% A lattice signal names a nexus and a relation.
realization_valid_realizer(lattice_signal(_Nexus, Relation)) :- atom(Relation).

% -- realization_unbind(+StructureId): remove every binding of a structure record.
realization_unbind(StructureId) :-
    % Retract all realizers registered for this structure.
    retractall(realization_binding(StructureId, _)).

% -- realization_realized_by(?StructureId, ?Realizer): the binding relation.
realization_realized_by(StructureId, Realizer) :-
    % Enumerate the registered bindings.
    realization_binding(StructureId, Realizer).

% -- realization_realizes(?Realizer, ?StructureId): the inverse binding relation.
realization_realizes(Realizer, StructureId) :-
    % Enumerate the same bindings from the realizer's side.
    realization_binding(StructureId, Realizer).

% -- realization_realizer_exists(+Realizer): the realizer is REAL, not a dangling label.
% A module-qualified native law must be a defined predicate in that module.
realization_realizer_exists(native_law(M:N/A)) :- !,
    % Build a goal head of the right name and arity, then check it is defined in M.
    functor(Head, N, A),
    current_predicate(N, M:Head).
% An unqualified native law must be a visible defined predicate of that name and arity.
realization_realizer_exists(native_law(N/A)) :- !,
    % Build a goal head of the right name and arity, then check it is visible.
    functor(Head, N, A),
    current_predicate(N, Head).
% A lattice signal is real when its nexus is open (it can carry the typed signal).
realization_realizer_exists(lattice_signal(Nexus, _Relation)) :-
    % A signal can only flow through an open nexus.
    nexus_is_open(Nexus).

% -- realization_check(+StructureId, -Result): is the structure bound, and every realizer real?
realization_check(StructureId, Result) :-
    % Collect every realizer registered for this structure.
    findall(R, realization_binding(StructureId, R), Realizers),
    ( Realizers == []
    ->  % An unbound structure has no dynamics to trace to — a finding, not a crash.
        Result = invalid(unbound(StructureId))
    ;   % Partition the realizers into those that exist and those that dangle.
        exclude(realization_realizer_exists, Realizers, Dangling),
        ( Dangling == []
        ->  Result = ok(Realizers)
        ;   Result = invalid(dangling(Dangling))
        )
    ).

% -- realization_check_all(-Report): a check line for every registered binding.
realization_check_all(Report) :-
    % Gather the distinct structure ids that carry at least one binding.
    findall(S, realization_binding(S, _), Ss0),
    sort(Ss0, Ss),
    % Check each structure and pair it with its result.
    findall(S-Result, ( member(S, Ss), realization_check(S, Result) ), Report).

% -- realization_trace(+StructureId, -Trace): a glass-box trace to the dynamics.
% Each realizer becomes a trace step naming the realizer and whether it exists.
realization_trace(StructureId, Trace) :-
    % For every realizer of the structure, record the realizer and its existence.
    findall(_{realizer: R, exists: Exists},
            ( realization_binding(StructureId, R),
              ( realization_realizer_exists(R) -> Exists = true ; Exists = false ) ),
            Steps),
    % Assemble the whole trace as a dict from structure to its realizing steps.
    Trace = _{structure: StructureId, realized_by: Steps}.

% -- realization_emit_signal(+Nexus, +Relation, +Value, +SourcePort, +Timestamp):
% write a typed dynamical signal on the Lattice (the P4 remedy — a typed signal
% relation carrying a value, a source port, and a timestamp).
realization_emit_signal(Nexus, Relation, Value, SourcePort, Timestamp) :-
    % Store the typed signal as a Lattice fact under the given relation.
    lattice_put(Nexus, Relation, [Value, SourcePort, Timestamp], []).

% -- realization_signal(+Nexus, +Relation, ?Value, ?SourcePort, ?Timestamp): read signals.
realization_signal(Nexus, Relation, Value, SourcePort, Timestamp) :-
    % Unify against any typed signal stored under the relation on this nexus.
    lattice_get(Nexus, Relation, [Value, SourcePort, Timestamp], []).
