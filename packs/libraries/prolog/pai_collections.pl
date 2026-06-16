/*  PrologAI — library/collections  (Specification Section 3.14)
    Dicts are implemented as mutable global stores keyed by a dict_ref/1 term.
*/

% Declare this file as the 'pai_collections' module and list its exported predicates.
:- module(pai_collections, [
    % Continue the multi-line expression started above.
    pai_dict_create/2,         % +Pairs, -DictRef
    % Continue the multi-line expression started above.
    pai_dict_get/3,            % +DictRef, +Key, -Value
    % Continue the multi-line expression started above.
    pai_dict_put/3,            % +DictRef, +Key, +Value  (mutates in place)
    % Continue the multi-line expression started above.
    pai_dict_keys/2,           % +DictRef, -Keys
    % Continue the multi-line expression started above.
    pai_dict_values/2,         % +DictRef, -Values
    % Continue the multi-line expression started above.
    pai_dict_entries/2,        % +DictRef, -Pairs
    % Continue the multi-line expression started above.
    pai_dict_cut/2,            % +DictRef, +Key          (removes key)
    % Supply 'pai_enumeration_create/3' as the next argument to the expression above.
    pai_enumeration_create/3,
    % Supply 'pai_enum_value/3' as the next argument to the expression above.
    pai_enum_value/3,
    % Supply 'pai_enum_name/3' as the next argument to the expression above.
    pai_enum_name/3,
    % Supply 'pai_enum_keys/2' as the next argument to the expression above.
    pai_enum_keys/2,
    % Supply 'pai_keyword_group_create/2' as the next argument to the expression above.
    pai_keyword_group_create/2,
    % Supply 'pai_keyword_group_member/2' as the next argument to the expression above.
    pai_keyword_group_member/2,
    % Supply 'pai_keyword_group_members/2' as the next argument to the expression above.
    pai_keyword_group_members/2
% Close the expression opened above.
]).

% Import [foldl/4] from the built-in 'apply' library.
:- use_module(library(apply), [foldl/4]).

% ---------------------------------------------------------------------------
% Dictionary (global-store backed to support /2 and /3 mutation predicates)
% ---------------------------------------------------------------------------

% Declare 'pai_dict_store/2.   % dict_ref(Id), Pairs' as dynamic — its facts may be added or removed at runtime.
:- dynamic pai_dict_store/2.   % dict_ref(Id), Pairs
% Declare 'pai_dict_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic pai_dict_id_counter/1.
% State the fact: pai dict id counter(0).
pai_dict_id_counter(0).

% Define a clause for 'next dict id': succeed when the following conditions hold.
next_dict_id(Ref) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(pai_dict_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_dict_id_counter(N1)),
    % Check that 'Ref' is unifiable with 'dict_ref(N1)'.
    Ref = dict_ref(N1).

% Define a clause for 'pai dict create': succeed when the following conditions hold.
pai_dict_create(Pairs, Ref) :-
    % State a fact for 'next dict id' with the arguments listed below.
    next_dict_id(Ref),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_dict_store(Ref, Pairs)).

% Define a clause for 'pai dict get': succeed when the following conditions hold.
pai_dict_get(Ref, Key, Value) :-
    % State a fact for 'pai dict store' with the arguments listed below.
    pai_dict_store(Ref, Pairs),
    % Succeed for each element 'Key-Value' that is a member of the list.
    member(Key-Value, Pairs), !.

% Define a clause for 'pai dict put': succeed when the following conditions hold.
pai_dict_put(Ref, Key, Value) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(pai_dict_store(Ref, Pairs)),
    % Check that 'exclude([K-_]>>(K' is structurally identical to 'Key), Pairs, Pruned)'.
    exclude([K-_]>>(K == Key), Pairs, Pruned),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_dict_store(Ref, [Key-Value | Pruned])).

% Define a clause for 'pai dict keys': succeed when the following conditions hold.
pai_dict_keys(Ref, Keys) :-
    % State a fact for 'pai dict store' with the arguments listed below.
    pai_dict_store(Ref, Pairs),
    % State the fact: pairs keys(Pairs, Keys).
    pairs_keys(Pairs, Keys).

% Define a clause for 'pai dict values': succeed when the following conditions hold.
pai_dict_values(Ref, Values) :-
    % State a fact for 'pai dict store' with the arguments listed below.
    pai_dict_store(Ref, Pairs),
    % State the fact: pairs values(Pairs, Values).
    pairs_values(Pairs, Values).

% Define a clause for 'pai dict entries': succeed when the following conditions hold.
pai_dict_entries(Ref, Pairs) :-
    % State the fact: pai dict store(Ref, Pairs).
    pai_dict_store(Ref, Pairs).

% Define a clause for 'pai dict cut': succeed when the following conditions hold.
pai_dict_cut(Ref, Key) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(pai_dict_store(Ref, Pairs)),
    % Check that 'exclude([K-_]>>(K' is structurally identical to 'Key), Pairs, NewPairs)'.
    exclude([K-_]>>(K == Key), Pairs, NewPairs),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_dict_store(Ref, NewPairs)).

% ---------------------------------------------------------------------------
% Enumeration
% ---------------------------------------------------------------------------

% Declare 'pai_enum_entry/3' as dynamic — its facts may be added or removed at runtime.
:- dynamic pai_enum_entry/3.

% Define a clause for 'pai enumeration create': succeed when the following conditions hold.
pai_enumeration_create(Name, Keys, _Opts) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pai_enum_entry(Name, _, _)),
    % State a fact for 'foldl' with the arguments listed below.
    foldl([Key, Idx, Idx1]>>(
        % Continue the multi-line expression started above.
        assertz(pai_enum_entry(Name, Key, Idx)),
        % Continue the multi-line expression started above.
        Idx1 is Idx + 1
    % Continue the multi-line expression started above.
    ), Keys, 0, _).

% Define a clause for 'pai enum value': succeed when the following conditions hold.
pai_enum_value(EnumName, Key, Ordinal) :-
    % State the fact: pai enum entry(EnumName, Key, Ordinal).
    pai_enum_entry(EnumName, Key, Ordinal).

% Define a clause for 'pai enum name': succeed when the following conditions hold.
pai_enum_name(EnumName, Key, Ordinal) :-
    % State the fact: pai enum entry(EnumName, Key, Ordinal).
    pai_enum_entry(EnumName, Key, Ordinal).

% Define a clause for 'pai enum keys': succeed when the following conditions hold.
pai_enum_keys(EnumName, Keys) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(K, pai_enum_entry(EnumName, K, _), Keys).

% ---------------------------------------------------------------------------
% Keyword groups
% ---------------------------------------------------------------------------

% Declare 'pai_kw_group/2' as dynamic — its facts may be added or removed at runtime.
:- dynamic pai_kw_group/2.

% Define a clause for 'pai keyword group create': succeed when the following conditions hold.
pai_keyword_group_create(Name, Members) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pai_kw_group(Name, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(pai_kw_group(Name, Members)).

% Define a clause for 'pai keyword group member': succeed when the following conditions hold.
pai_keyword_group_member(Name, Member) :-
    % State a fact for 'pai kw group' with the arguments listed below.
    pai_kw_group(Name, Members),
    % Succeed for each element 'Member' that is a member of the list.
    member(Member, Members), !.

% Define a clause for 'pai keyword group members': succeed when the following conditions hold.
pai_keyword_group_members(Name, Members) :-
    % State the fact: pai kw group(Name, Members).
    pai_kw_group(Name, Members).

% Import [member/2, exclude/3, pairs_keys/2, pairs_values/2] from the built-in 'lists' library.
:- use_module(library(lists), [member/2, exclude/3, pairs_keys/2, pairs_values/2]).
