% Module: co_store — an in-memory conformant store, a port of the reference
% store.py: immutable idempotent put, signed add-only provenance records,
% materialized enrichment views with contributors, retraction in default
% views, succession lineage, the resolve minimum, the deterministic
% cycle-breaking view rule, and the stigmergy gap read. Additive harness code.
% State is held in module-local dynamic predicates and cleared by co_store_reset.
:- module(co_store, [
    co_store_reset/1,        % +Enforcing
    co_put/2,                % +Obj, -Id
    co_put_record/2,         % +Record, -Id
    co_force_merge_record/2, % +Record, -Id
    co_objects_count/1,      % -N
    co_lineage/2,            % +Key, -Chain
    co_assertions_about/3,   % +Id, +IncludeRetracted, -List
    co_active_taxonomy_edges/3, % +Field, -Active, -Excluded
    co_get/3,                % +Id, +View, -Result
    co_resolve/3,            % +Text, +Lang, -Hits
    co_gaps/2,               % +Kind, -Gaps
    co_all_objects/1         % -Objs
   ]).

% Core supplies identity, semantics, refinement, conflict, partiality.
:- use_module(library(causal_core)).
% Schema validation for content objects.
:- use_module('schema_check.pl').
% Signature verification for provenance records.
:- use_module('signing.pl').
% List and sort helpers.
:- use_module(library(lists)).
:- use_module(library(apply)).

% The store's content objects, provenance records, quarantine, and mode flag.
:- dynamic co_obj/2.
:- dynamic co_rec/2.
:- dynamic co_quar/2.
:- dynamic co_enforcing_flag/1.

% The content kinds accepted by put.
co_content_kind(occurrent).       co_content_kind(causal_relation_object).
co_content_kind(continuant).      co_content_kind(realizable).
co_content_kind(stratum).         co_content_kind(bridge).
co_content_kind(port).            co_content_kind(conduit).
co_content_kind(quality).         co_content_kind(token_individual).
co_content_kind(token_occurrence).
co_content_kind(state_assertion).
co_content_kind(token_causal_claim).
% The provenance record kinds accepted by put_record.
co_record_kind(assertion).  co_record_kind(enrichment).
co_record_kind(retraction). co_record_kind(succession).

% -- co_store_reset(+Enforcing): clear the store and set the enforcement mode.
co_store_reset(Enforcing) :-
    retractall(co_obj(_,_)), retractall(co_rec(_,_)),
    retractall(co_quar(_,_)), retractall(co_enforcing_flag(_)),
    assertz(co_enforcing_flag(Enforcing)).

% -- co_put(+Obj, -Id): write a content object; idempotent; returns the id.
co_put(Obj0, Id) :-
    causal_core_infer_kind(Obj0, Kind),
    ( co_content_kind(Kind) -> true ; throw(co_error("put takes content objects")) ),
    ( get_dict(type, Obj0, _) -> Obj1 = Obj0 ; atom_string(Kind, KS), put_dict(type, Obj0, KS, Obj1) ),
    ( get_dict(id, Obj1, Id0) -> Id = Id0, Obj = Obj1
    ; causal_core_identify(Obj1, Kind, Id), put_dict(id, Obj1, Id, Obj) ),
    ( co_obj(Id, _) -> true
    ; ( co_validate_schema(Obj, Kind, OkS, WhyS),
        ( OkS == true -> true ; atomic_list_concat(WhyS, "; ", M1), throw(co_reject(M1)) ),
        causal_core_validate_semantics(Obj, Kind, WhySem),
        ( WhySem == [] -> true ; atomic_list_concat(WhySem, "; ", M2), throw(co_reject(M2)) ),
        assertz(co_obj(Id, Obj)) )
    ).

% -- co_put_record(+Record, -Id): write a signed provenance record.
co_put_record(Record, Id) :- co_put_record(Record, Id, false).
% -- co_force_merge_record(+Record, -Id): merge without the enforcement gate.
co_force_merge_record(Record, Id) :- co_put_record(Record, Id, true).

% -- co_put_record(+Record, -Id, +Force): the shared implementation.
co_put_record(Record0, Id, Force) :-
    causal_core_infer_kind(Record0, Kind),
    ( co_record_kind(Kind) -> true ; throw(co_error("put_record takes provenance records")) ),
    ( get_dict(type, Record0, _) -> Record1 = Record0 ; atom_string(Kind, KS), put_dict(type, Record0, KS, Record1) ),
    ( get_dict(id, Record1, Rid) -> true ; causal_core_identify(Record1, Kind, Rid) ),
    put_dict(id, Record1, Rid, Record), Id = Rid,
    ( co_rec(Rid, _) -> true
    ; ( ( co_verify_record(Record, Kind)
          -> true
          ;  ( assertz(co_quar(Rid, Record)), throw(co_reject("unsigned or unverifiable record: quarantined")) ) ),
        causal_core_validate_semantics(Record, Kind, WhySem),
        ( WhySem == [] -> true ; atomic_list_concat(WhySem, "; ", M2), throw(co_reject(M2)) ),
        ( Kind == retraction, \+ co_retraction_source_ok(Record)
          -> throw(co_reject("a retraction is valid only from the retracted record's source or its succession lineage"))
          ;  true ),
        ( Kind == enrichment, co_enforcing_flag(true), Force == false,
          get_dict(field, Record, FieldV), causal_core_atomize(FieldV, Field), member(Field, [subsumes, part_of]),
          co_would_cycle(Record)
          -> throw(co_reject("would create a cycle in the materialized graph"))
          ;  true ),
        assertz(co_rec(Rid, Record)) )
    ).

% -- co_objects_count(-N): number of stored content objects.
co_objects_count(N) :- aggregate_all(count, co_obj(_,_), N).

% -- co_all_objects(-Objs): every stored content object.
co_all_objects(Objs) :- findall(O, co_obj(_, O), Objs).

% -- co_records_of(+Kind, -Recs): every stored record of a kind.
co_records_of(Kind, Recs) :-
    atom_string(Kind, KS),
    findall(R, (co_rec(_, R), get_dict(type, R, T), (T == KS ; T == Kind)), Recs).

% -- co_retracted_ids(-Set): ids named by every retraction.
co_retracted_ids(Set) :-
    co_records_of(retraction, Rs),
    findall(Tid, (member(R, Rs), get_dict(retracts, R, Tid)), Set).

% -- co_retraction_source_ok(+Retraction): source is in the target's lineage.
co_retraction_source_ok(Retraction) :-
    get_dict(retracts, Retraction, Tid),
    ( co_rec(Tid, Target)
      -> ( get_dict(source, Target, TSource), co_lineage(TSource, Chain),
           get_dict(source, Retraction, RSource), memberchk(RSource, Chain) )
      ;  true  % open world: the target may arrive later
    ).

% -- co_lineage(+Key, -Chain): the succession closure containing Key.
co_lineage(Key, Chain) :-
    co_records_of(succession, Ss),
    findall(P-Sc, (member(S, Ss), get_dict(predecessor, S, P), get_dict(successor, S, Sc)), Edges),
    co_walk_back(Key, Edges, [Key], C1),
    co_walk_fwd(Key, Edges, C1, Chain).

% -- Walk predecessors back from Key.
co_walk_back(Cursor, Edges, Acc, Out) :-
    ( member(P-Cursor, Edges), \+ memberchk(P, Acc)
      -> co_walk_back(P, Edges, [P|Acc], Out) ; Out = Acc ).
% -- Walk successors forward from Key.
co_walk_fwd(Cursor, Edges, Acc, Out) :-
    ( member(Cursor-Sc, Edges), \+ memberchk(Sc, Acc)
      -> co_walk_fwd(Sc, Edges, [Sc|Acc], Out) ; Out = Acc ).

% -- co_assertions_about(+Id, +IncludeRetracted, -List).
co_assertions_about(Id, IncludeRetracted, List) :-
    co_retracted_ids(Retracted), co_records_of(assertion, As),
    findall(Out, ( member(R, As), get_dict(about, R, Id),
                   get_dict(id, R, Rid),
                   ( memberchk(Rid, Retracted)
                     -> ( IncludeRetracted == true, put_dict(retracted, R, true, Out) )
                     ;  Out = R ) ), List).

% -- co_enrichments_about(+Id, +IncludeRetracted, -List).
co_enrichments_about(Id, IncludeRetracted, List) :-
    co_retracted_ids(Retracted), co_records_of(enrichment, Es),
    findall(R, ( member(R, Es), get_dict(about, R, Id), get_dict(id, R, Rid),
                 ( memberchk(Rid, Retracted) -> IncludeRetracted == true ; true ) ), List).

% -- co_active_taxonomy_edges(+Field, -Active, -Excluded): rule 13 cycle-breaking.
co_active_taxonomy_edges(Field, Active, Excluded) :-
    co_retracted_ids(Retracted), co_records_of(enrichment, Es),
    findall(R, ( member(R, Es), get_dict(field, R, FV), causal_core_atomize(FV, Field),
                 get_dict(id, R, Rid), \+ memberchk(Rid, Retracted) ), Recs),
    co_break_cycles(Recs, [], Active, Excluded).

% -- Iteratively drop the latest cycle-completing record until acyclic.
co_break_cycles(Active0, Exc0, Active, Excluded) :-
    ( co_find_cycle_records(Active0, Cyc), Cyc \== []
      -> co_cycle_loser(Cyc, Loser), select_record(Loser, Active0, Active1),
         co_break_cycles(Active1, [Loser|Exc0], Active, Excluded)
      ;  Active = Active0, reverse(Exc0, Excluded) ).

% -- Remove a record (by id) from a list.
select_record(R, List, Rest) :-
    get_dict(id, R, Rid),
    exclude([X]>>(get_dict(id, X, Rid)), List, Rest).

% -- co_cycle_loser(+CycleRecs, -Loser): the max by (timestamp, id).
co_cycle_loser(Cyc, Loser) :-
    map_list_to_pairs(co_ts_id_key, Cyc, Keyed),
    keysort(Keyed, Sorted), last(Sorted, _-Loser).
% -- Sort key: timestamp then id, as a term comparable by standard order.
co_ts_id_key(R, k(Ts, Id)) :- get_dict(timestamp, R, Ts), get_dict(id, R, Id).

% -- co_find_cycle_records(+Recs, -Cycle): records forming one about->entry cycle.
co_find_cycle_records(Recs, Cycle) :-
    findall(About-(Entry-R), ( member(R, Recs), get_dict(about, R, About), get_dict(entry, R, Entry) ), Pairs),
    ( co_dfs_start(Pairs, Cycle) -> true ; Cycle = [] ).
% -- Try each start node for a cycle.
co_dfs_start(Pairs, Cycle) :-
    setof(N, E^R^member(N-(E-R), Pairs), Nodes),
    member(Start, Nodes), co_dfs(Start, Pairs, [], [], Cycle), !.
% -- Depth-first search tracking grey nodes and the record path.
co_dfs(Node, Pairs, Grey, PathRecs, Cycle) :-
    member(Node-(Entry-Rec), Pairs),
    ( memberchk(Entry, Grey)
      -> append(PathRecs, [Rec], Cycle)
      ;  co_dfs(Entry, Pairs, [Node|Grey], [Rec|PathRecs0], Cycle),
         PathRecs0 = PathRecs
    ).

% -- co_would_cycle(+Record): adding Record would close a subsumes/part_of cycle.
co_would_cycle(Record) :-
    co_retracted_ids(Retracted), co_records_of(enrichment, Es),
    get_dict(field, Record, FV), causal_core_atomize(FV, Field),
    findall(R, ( member(R, Es), get_dict(field, R, F2), causal_core_atomize(F2, Field),
                 get_dict(id, R, Rid), \+ memberchk(Rid, Retracted) ), Recs),
    co_find_cycle_records([Record|Recs], Cyc), Cyc \== [].

% -- co_get(+Id, +View, -Result): the object with materialized enrichment sets.
co_get(Id, View, Result) :-
    ( co_obj(Id, Obj) -> true ; Obj = none ),
    ( Obj == none -> Result = none
    ; ( ( View == history -> IncludeRetracted = true ; IncludeRetracted = false ),
        co_excluded_ids(ExcludedIds),
        co_enrichments_about(Id, IncludeRetracted, Recs),
        co_materialize(Recs, ExcludedIds, View, Enrichments),
        Result = _{object:Obj, enrichments:Enrichments} )
    ).

% -- Ids excluded by the deterministic cycle-breaking rule (both taxonomy fields).
co_excluded_ids(Ids) :-
    findall(Rid, ( member(F, [subsumes, part_of]), co_active_taxonomy_edges(F, _, Exc),
                   member(R, Exc), get_dict(id, R, Rid) ), Ids).

% -- co_materialize(+Recs, +ExcludedIds, +View, -Enrichments): group by field+entry.
co_materialize(Recs, ExcludedIds, View, Enrichments) :-
    foldl(co_materialize_rec(ExcludedIds, View), Recs, [], FieldsAcc),
    co_fields_to_dict(FieldsAcc, Enrichments).

% -- Fold one enrichment record into the accumulator of field buckets.
co_materialize_rec(ExcludedIds, View, Rec, Acc0, Acc) :-
    get_dict(id, Rec, Rid),
    ( ( memberchk(Rid, ExcludedIds), View \== history )
      -> Acc = Acc0
      ;  ( get_dict(field, Rec, FV), causal_core_atomize(FV, Field),
           get_dict(entry, Rec, Entry), co_entry_key(Entry, EKey),
           get_dict(source, Rec, Source), get_dict(timestamp, Rec, Ts),
           Contributor = _{source:Source, timestamp:Ts},
           co_add_bucket(Acc0, Field, EKey, Entry, Contributor, Acc) )
    ).

% -- A stable key for an entry (sorted pairs for dicts, the value otherwise).
co_entry_key(Entry, Key) :- ( is_dict(Entry) -> dict_pairs(Entry, _, Ps), sort(Ps, Key) ; Key = Entry ).

% -- Add a contributor to the matching (field,entry) bucket, creating it if new.
co_add_bucket(Acc0, Field, EKey, Entry, Contributor, Acc) :-
    ( select(bucket(Field, EKey, Entry, Cs), Acc0, Rest)
      -> Acc = [bucket(Field, EKey, Entry, [Contributor|Cs])|Rest]
      ;  Acc = [bucket(Field, EKey, Entry, [Contributor])|Acc0] ).

% -- Convert the bucket accumulator into a field -> list-of-buckets dict.
co_fields_to_dict(Buckets, Dict) :-
    findall(Field, member(bucket(Field,_,_,_), Buckets), Fs0), sort(Fs0, Fields),
    findall(Field-Views,
            ( member(Field, Fields),
              findall(_{entry:E, contributors:Cs2},
                      ( member(bucket(Field,_,E,Cs), Buckets), reverse(Cs, Cs2) ), Views) ),
            Pairs),
    dict_pairs(Dict, enrichments, Pairs).

% -- co_resolve(+Text, +Lang, -Hits): exact label, then alias, then nothing.
co_resolve(Text, Lang, Hits) :-
    co_canon_label(Text, WantLabel), co_norm_alias(Text, WantAlias),
    co_retracted_ids(Retracted),
    findall(Oid, ( co_obj(Oid, Obj), get_dict(type, Obj, T), (T == "occurrent" ; T == "continuant"),
                   get_dict(label, Obj, WantLabel) ), LabelHits),
    findall(Oid, ( co_obj(Oid, Obj), get_dict(type, Obj, T), (T == "occurrent" ; T == "continuant"),
                   \+ get_dict(label, Obj, WantLabel),
                   co_alias_hit(Oid, Lang, WantAlias, Retracted) ), AliasHits),
    append(LabelHits, AliasHits, Hits).

% -- An occurrent/continuant has a matching alias enrichment.
co_alias_hit(Oid, Lang, WantAlias, Retracted) :-
    co_records_of(enrichment, Es),
    member(R, Es), get_dict(about, R, Oid), get_dict(field, R, FV), causal_core_atomize(FV, aliases),
    get_dict(id, R, Rid), \+ memberchk(Rid, Retracted),
    get_dict(entry, R, Entry),
    ( Lang == any -> true ; get_dict(lang, Entry, EL), EL == Lang ),
    get_dict(text, Entry, Tx), co_norm_alias(Tx, WantAlias), !.

% -- co_canon_label(+Text, -Label): lowercase, underscores for whitespace runs.
co_canon_label(Text, Label) :-
    split_string(Text, " \t\n", " \t\n", Parts0), exclude(==(""), Parts0, Parts),
    atomic_list_concat(Parts, "_", A0), string_lower(A0, Label).
% -- co_norm_alias(+Text, -Norm): collapse whitespace, casefold.
co_norm_alias(Text, Norm) :-
    split_string(Text, " \t\n", " \t\n", Parts0), exclude(==(""), Parts0, Parts),
    atomic_list_concat(Parts, " ", A0), string_lower(A0, Norm).

% -- co_gaps(+Kind, -Gaps): the stigmergy read (kind = the atom or the anon var).
co_gaps(Kind, Gaps) :-
    co_refined_parents(Refined),
    findall(G, co_gap(Refined, G), All),
    ( var(Kind) -> Gaps = All ; include([G]>>(get_dict(kind, G, Kind)), All, Gaps) ).

% -- Parents that a valid refinement enriches (so they are not "missing_field").
co_refined_parents(Refined) :-
    findall(Pid, ( co_obj(_, Obj), get_dict(type, Obj, "causal_relation_object"), get_dict(refines, Obj, Pid),
                   co_obj(Pid, Parent), causal_core_refinement_valid(Obj, Parent, ok(_)) ), Refined).

% -- missing_field: a causal_relation_object lacking temporal or modality, not itself refined.
co_gap(Refined, _{id:Id, kind:missing_field, missing:Missing}) :-
    co_obj(Id, Obj), get_dict(type, Obj, "causal_relation_object"),
    ( \+ get_dict(temporal, Obj, _) ; \+ get_dict(modality, Obj, _) ),
    \+ memberchk(Id, Refined),
    causal_core_is_partial(Obj, _, Missing).
% inconsistent_hierarchy: a taxonomy record excluded by the cycle-breaking rule.
co_gap(_Refined, _{id:Rid, kind:inconsistent_hierarchy}) :-
    member(F, [subsumes, part_of]), co_active_taxonomy_edges(F, _, Exc),
    member(R, Exc), get_dict(id, R, Rid).
