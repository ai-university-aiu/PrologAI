/*  PrologAI — library/collections  (Specification Section 3.14)
    Dicts are implemented as mutable global stores keyed by a dict_ref/1 term.
*/

:- module(pai_collections, [
    pai_dict_create/2,         % +Pairs, -DictRef
    pai_dict_get/3,            % +DictRef, +Key, -Value
    pai_dict_put/3,            % +DictRef, +Key, +Value  (mutates in place)
    pai_dict_keys/2,           % +DictRef, -Keys
    pai_dict_values/2,         % +DictRef, -Values
    pai_dict_entries/2,        % +DictRef, -Pairs
    pai_dict_cut/2,            % +DictRef, +Key          (removes key)
    pai_enumeration_create/3,
    pai_enum_value/3,
    pai_enum_name/3,
    pai_enum_keys/2,
    pai_keyword_group_create/2,
    pai_keyword_group_member/2,
    pai_keyword_group_members/2
]).

:- use_module(library(apply), [foldl/4]).

% ---------------------------------------------------------------------------
% Dictionary (global-store backed to support /2 and /3 mutation predicates)
% ---------------------------------------------------------------------------

:- dynamic pai_dict_store/2.   % dict_ref(Id), Pairs
:- dynamic pai_dict_id_counter/1.
pai_dict_id_counter(0).

next_dict_id(Ref) :-
    retract(pai_dict_id_counter(N)),
    N1 is N + 1,
    assertz(pai_dict_id_counter(N1)),
    Ref = dict_ref(N1).

pai_dict_create(Pairs, Ref) :-
    next_dict_id(Ref),
    assertz(pai_dict_store(Ref, Pairs)).

pai_dict_get(Ref, Key, Value) :-
    pai_dict_store(Ref, Pairs),
    member(Key-Value, Pairs), !.

pai_dict_put(Ref, Key, Value) :-
    retract(pai_dict_store(Ref, Pairs)),
    exclude([K-_]>>(K == Key), Pairs, Pruned),
    assertz(pai_dict_store(Ref, [Key-Value | Pruned])).

pai_dict_keys(Ref, Keys) :-
    pai_dict_store(Ref, Pairs),
    pairs_keys(Pairs, Keys).

pai_dict_values(Ref, Values) :-
    pai_dict_store(Ref, Pairs),
    pairs_values(Pairs, Values).

pai_dict_entries(Ref, Pairs) :-
    pai_dict_store(Ref, Pairs).

pai_dict_cut(Ref, Key) :-
    retract(pai_dict_store(Ref, Pairs)),
    exclude([K-_]>>(K == Key), Pairs, NewPairs),
    assertz(pai_dict_store(Ref, NewPairs)).

% ---------------------------------------------------------------------------
% Enumeration
% ---------------------------------------------------------------------------

:- dynamic pai_enum_entry/3.

pai_enumeration_create(Name, Keys, _Opts) :-
    retractall(pai_enum_entry(Name, _, _)),
    foldl([Key, Idx, Idx1]>>(
        assertz(pai_enum_entry(Name, Key, Idx)),
        Idx1 is Idx + 1
    ), Keys, 0, _).

pai_enum_value(EnumName, Key, Ordinal) :-
    pai_enum_entry(EnumName, Key, Ordinal).

pai_enum_name(EnumName, Key, Ordinal) :-
    pai_enum_entry(EnumName, Key, Ordinal).

pai_enum_keys(EnumName, Keys) :-
    findall(K, pai_enum_entry(EnumName, K, _), Keys).

% ---------------------------------------------------------------------------
% Keyword groups
% ---------------------------------------------------------------------------

:- dynamic pai_kw_group/2.

pai_keyword_group_create(Name, Members) :-
    retractall(pai_kw_group(Name, _)),
    assertz(pai_kw_group(Name, Members)).

pai_keyword_group_member(Name, Member) :-
    pai_kw_group(Name, Members),
    member(Member, Members), !.

pai_keyword_group_members(Name, Members) :-
    pai_kw_group(Name, Members).

:- use_module(library(lists), [member/2, exclude/3, pairs_keys/2, pairs_values/2]).
