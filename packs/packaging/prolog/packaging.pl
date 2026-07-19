% packaging — dependency KINDS, loadable pack FACES, a facade/bundle, and a
% cross-pack record registry.
% Work Package WP-436, Layer 0 (base infrastructure).
% Closes the Requirements Ledger's Theme G (packaging and dependency kinds), which the
% one-pack-per-construct arm surfaced by turning every intra-pack reference into an
% inter-pack import: ATOMIC-1, ATOMIC-2, ATOMIC-3, ATOMIC-4.
%
% PrologAI had ONE kind of dependency — a use_module import — and no way to say what
% KIND it was, so a structure-only (mint-time) reference inflated the layer graph like a
% runtime one (ATOMIC-1); a consumer had to enumerate every fine-grained pack it touched
% (ATOMIC-2); content-addressed ids were threaded by hand-exported accessors (ATOMIC-3);
% and structure and runtime were fused into one dependency face, so validating a record
% dragged in the runtime substrate (ATOMIC-4). This construct adds all four missing
% notions as first-class, queryable declarations. It is metadata about packaging, so it
% depends only on SWI-Prolog standard libraries and touches no ARC state.

% Declare the module and its public interface.
:- module(packaging,
    [ % --- Dependency kinds (ATOMIC-1) and faces (ATOMIC-4) ---
      % Declare that FromPack depends on ToPack, of a given kind (structure_only|runtime).
      packaging_declare_dependency/3,   % +FromPack, +ToPack, +Kind
      % Query the declared dependencies.
      packaging_dependency/3,           % ?FromPack, ?ToPack, ?Kind
      % Only the RUNTIME dependency targets of a pack (the layer-graph-relevant edges).
      packaging_runtime_dependencies/2, % +FromPack, -ToPacks
      % Only the STRUCTURE-ONLY (mint-time) dependency targets of a pack.
      packaging_structure_only_dependencies/2, % +FromPack, -ToPacks
      % The pack face a dependency of a given kind requires (structure|runtime).
      packaging_required_face/2,        % +Kind, -Face
      % The (ToPack, Face) requirements pulled in by loading one FACE of a pack.
      packaging_face_dependencies/3,    % +Pack, +Face, -RequiredFaces
      % --- Facade / bundle (ATOMIC-2) ---
      % Declare a named facade over a list of member packs (or nested facades).
      packaging_declare_facade/2,       % +FacadeName, +Members
      % The direct declared members of a facade.
      packaging_facade/2,               % ?FacadeName, ?Members
      % Expand a target (a pack or a facade) to its concrete pack set (recursively).
      packaging_expand/2,               % +Target, -Packs
      % --- Cross-pack record / id registry (ATOMIC-3) ---
      % Register a content-addressed record under its id and owning pack.
      packaging_register_record/3,      % +Id, +Record, +OwnerPack
      % Look up a registered record by its id.
      packaging_record/2,               % ?Id, ?Record
      % The pack that owns a registered id.
      packaging_record_owner/2          % ?Id, ?OwnerPack
    ]).

% Use the standard list library for set operations over dependency lists.
:- use_module(library(lists)).

% Declare the four registries dynamic — packaging is declared, not hard-wired.
:- dynamic packaging_dependency_fact/3.   % FromPack, ToPack, Kind
:- dynamic packaging_facade_fact/2.       % FacadeName, Members
:- dynamic packaging_record_fact/3.       % Id, Record, OwnerPack

% -- packaging_kind(?Kind): the two recognised dependency kinds.
% structure_only — needed only to mint a record (a mint-time edge, never behaviour).
% runtime        — needed to run behaviour (the edge the layer graph must count).
packaging_kind(structure_only).
packaging_kind(runtime).

% -- packaging_declare_dependency(+FromPack, +ToPack, +Kind): declare a typed dependency.
packaging_declare_dependency(FromPack, ToPack, Kind) :-
    % The kind must be one of the two recognised values.
    ( packaging_kind(Kind)
    ->  true
    ;   throw(error(domain_error(packaging_dependency_kind, Kind),
                    context(packaging_declare_dependency/3, 'a dependency kind is structure_only or runtime')))
    ),
    % Do not duplicate an identical declaration.
    ( packaging_dependency_fact(FromPack, ToPack, Kind)
    ->  true
    ;   assertz(packaging_dependency_fact(FromPack, ToPack, Kind))
    ).

% -- packaging_dependency(?FromPack, ?ToPack, ?Kind): query the declared dependencies.
packaging_dependency(FromPack, ToPack, Kind) :-
    % Enumerate the registered dependency facts.
    packaging_dependency_fact(FromPack, ToPack, Kind).

% -- packaging_runtime_dependencies(+FromPack, -ToPacks): the RUNTIME edges only.
% ATOMIC-1: the layer graph and fan-out should count runtime edges, not mint-time ones.
packaging_runtime_dependencies(FromPack, ToPacks) :-
    % Collect the targets of every runtime dependency, de-duplicated.
    findall(To, packaging_dependency_fact(FromPack, To, runtime), Raw),
    sort(Raw, ToPacks).

% -- packaging_structure_only_dependencies(+FromPack, -ToPacks): the mint-time edges only.
packaging_structure_only_dependencies(FromPack, ToPacks) :-
    % Collect the targets of every structure-only dependency, de-duplicated.
    findall(To, packaging_dependency_fact(FromPack, To, structure_only), Raw),
    sort(Raw, ToPacks).

% -- packaging_required_face(+Kind, -Face): the pack face a dependency kind requires.
% A structure-only dependency needs only the target's STRUCTURE face; a runtime
% dependency needs its RUNTIME face. This is the ATOMIC-4 face notion: a consumer can
% load ONE face and not drag in the other.
packaging_required_face(structure_only, structure).
packaging_required_face(runtime, runtime).

% -- packaging_face_dependencies(+Pack, +Face, -RequiredFaces): what loading a FACE pulls.
% Loading the STRUCTURE face pulls only the structure faces of the structure-only deps;
% loading the RUNTIME face pulls only the runtime faces of the runtime deps. So
% validating a record (the structure face) never drags in the runtime substrate.
packaging_face_dependencies(Pack, Face, RequiredFaces) :-
    % Each declared dependency whose required face matches contributes a To-Face pair.
    findall(To-ReqFace,
            ( packaging_dependency_fact(Pack, To, Kind),
              packaging_required_face(Kind, ReqFace),
              ReqFace == Face ),
            Raw),
    % De-duplicate the required-face requirements.
    sort(Raw, RequiredFaces).

% -- packaging_declare_facade(+FacadeName, +Members): declare a named bundle.
% ATOMIC-2: a consumer depends on the facade instead of enumerating every fine pack.
packaging_declare_facade(FacadeName, Members) :-
    % A facade's members must be a list.
    ( is_list(Members)
    ->  true
    ;   throw(error(type_error(list, Members),
                    context(packaging_declare_facade/2, 'a facade names a list of member packs or facades')))
    ),
    % Replace any prior declaration of this facade so a facade has one member list.
    retractall(packaging_facade_fact(FacadeName, _)),
    % Store the facade's members.
    assertz(packaging_facade_fact(FacadeName, Members)).

% -- packaging_facade(?FacadeName, ?Members): the direct members of a facade.
packaging_facade(FacadeName, Members) :-
    % Enumerate the registered facades.
    packaging_facade_fact(FacadeName, Members).

% -- packaging_expand(+Target, -Packs): expand a target to its concrete pack set.
% A plain pack expands to itself; a facade expands (recursively) to its members' packs.
packaging_expand(Target, Packs) :-
    % Expand with an empty visited set, then de-duplicate the result.
    packaging_expand_seen(Target, [], Packs0),
    sort(Packs0, Packs).

% -- packaging_expand_seen(+Target, +Seen, -Packs): expansion guarded against cycles.
packaging_expand_seen(Target, Seen, []) :-
    % A facade already being expanded is not expanded again (cycle guard).
    memberchk(Target, Seen), !.
packaging_expand_seen(Target, Seen, Packs) :-
    % A declared facade expands to the union of its members' expansions.
    packaging_facade_fact(Target, Members), !,
    % Expand each member, remembering this facade to break any cycle.
    foldl(packaging_expand_member([Target|Seen]), Members, [], Packs).
packaging_expand_seen(Pack, _Seen, [Pack]).
    % A plain pack (not a facade) expands to itself.

% -- packaging_expand_member(+Seen, +Member, +Acc0, -Acc): fold one member's expansion in.
packaging_expand_member(Seen, Member, Acc0, Acc) :-
    % Expand this member under the running visited set.
    packaging_expand_seen(Member, Seen, MemberPacks),
    % Accumulate its packs onto the running result.
    append(Acc0, MemberPacks, Acc).

% -- packaging_register_record(+Id, +Record, +OwnerPack): register a content-addressed record.
% ATOMIC-3: a cross-pack registry, so ids are looked up centrally, not threaded by hand.
packaging_register_record(Id, Record, OwnerPack) :-
    % Replace any prior registration of this id so an id maps to one record.
    retractall(packaging_record_fact(Id, _, _)),
    % Store the record and its owning pack under the id.
    assertz(packaging_record_fact(Id, Record, OwnerPack)).

% -- packaging_record(?Id, ?Record): look up a registered record by its id.
packaging_record(Id, Record) :-
    % Enumerate the registered records.
    packaging_record_fact(Id, Record, _OwnerPack).

% -- packaging_record_owner(?Id, ?OwnerPack): the pack that owns a registered id.
packaging_record_owner(Id, OwnerPack) :-
    % Read the owning pack from the record registry.
    packaging_record_fact(Id, _Record, OwnerPack).
