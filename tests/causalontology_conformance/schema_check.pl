% Module: co_schema — JSON-Schema validation for the seventeen Causalontology
% 2.0.0 kinds, a faithful port of the reference schema.py. It interprets the
% exact JSON-Schema keyword subset the seventeen schemas use (type, const,
% enum, pattern, required, properties, additionalProperties, items, minItems,
% minLength, minimum, maximum, oneOf, local $ref, and cross-file $ref) over the
% vendored spec/schema/*.schema.json copies. This is additive harness code; it
% imports none of the ARC grid/ILP/sequence packs.
:- module(co_schema, [
    % co_validate_schema/4: structural validity of an object against its kind.
    co_validate_schema/4,
    % co_schema_dir/1: the directory holding the vendored schema files.
    co_schema_dir/1
   ]).

% Read JSON schema files as dicts.
:- use_module(library(http/json)).
% Use Perl-compatible regular expressions for the "pattern" keyword.
:- use_module(library(pcre)).
% List utilities.
:- use_module(library(lists)).
% String helpers.
:- use_module(library(apply)).

% Memoize loaded schema files across a run.
:- dynamic co_schema_cache/2.

% -- co_schema_dir(-Dir): the vendored schema directory next to this file.
co_schema_dir(Dir) :-
    % Locate this source file's directory.
    source_file(co_schema_dir(_), Self),
    % Take its directory.
    file_directory_name(Self, Here),
    % The schemas live in the sibling schema/ folder.
    atomic_list_concat([Here, '/schema'], Dir).

% -- co_schema_file(+Kind, -File): the schema filename for each kind.
% occurrent.
co_schema_file(occurrent, 'occurrent.schema.json').
% causal_relation_object.
co_schema_file(causal_relation_object, 'causal_relation_object.schema.json').
% continuant.
co_schema_file(continuant, 'continuant.schema.json').
% realizable.
co_schema_file(realizable, 'realizable.schema.json').
% stratum.
co_schema_file(stratum, 'stratum.schema.json').
% bridge.
co_schema_file(bridge, 'bridge.schema.json').
% port.
co_schema_file(port, 'port.schema.json').
% conduit.
co_schema_file(conduit, 'conduit.schema.json').
% quality.
co_schema_file(quality, 'quality.schema.json').
% token_individual keeps the reserved 1.0.0 file name individual.schema.json.
co_schema_file(token_individual, 'individual.schema.json').
% token_occurrence keeps token.schema.json.
co_schema_file(token_occurrence, 'token.schema.json').
% state_assertion keeps state.schema.json.
co_schema_file(state_assertion, 'state.schema.json').
% token_causal_claim.
co_schema_file(token_causal_claim, 'token_causal_claim.schema.json').
% assertion.
co_schema_file(assertion, 'assertion.schema.json').
% enrichment.
co_schema_file(enrichment, 'enrichment.schema.json').
% retraction.
co_schema_file(retraction, 'retraction.schema.json').
% succession.
co_schema_file(succession, 'succession.schema.json').

% -- co_load_file(+File, -Root): load and cache one schema file as a dict.
co_load_file(File, Root) :-
    % Return the cached copy when present.
    ( co_schema_cache(File, Root) -> true
    % Otherwise read it from the schema directory and cache it.
    ; ( co_schema_dir(Dir), atomic_list_concat([Dir, '/', File], Path),
        open(Path, read, S), json_read_dict(S, Root), close(S),
        assertz(co_schema_cache(File, Root)) )
    ).

% -- co_load_schema(+Kind, -Root): the root schema dict for a kind.
co_load_schema(Kind, Root) :-
    % Map the kind to its file, then load it.
    co_schema_file(Kind, File), co_load_file(File, Root).

% -- co_validate_schema(+Obj, +Kind, -Ok, -Errors): structural validity.
co_validate_schema(Obj, Kind, Ok, Errors) :-
    % Load the kind's schema as the root.
    co_load_schema(Kind, Root),
    % Collect every structural error from the root path "$".
    findall(E, co_check(Obj, Root, Root, "$", E), Errors),
    % Valid exactly when no error was collected.
    ( Errors == [] -> Ok = true ; Ok = false ).

% -- co_resolve(+Schema, +Root, -Schema2, -Root2): follow $ref chains.
co_resolve(Schema, Root, SchemaOut, RootOut) :-
    % A $ref node is resolved; anything else is already concrete.
    ( is_dict(Schema), get_dict('$ref', Schema, Ref)
      -> co_resolve_ref(Ref, Root, S1, R1), co_resolve(S1, R1, SchemaOut, RootOut)
      ;  SchemaOut = Schema, RootOut = Root
    ).

% -- co_resolve_ref(+Ref, +Root, -Schema, -Root2): resolve one $ref.
co_resolve_ref(Ref, Root, Schema, Root) :-
    % A local pointer begins with '#/'.
    sub_atom_or_string(Ref, 0, 2, _, "#/"), !,
    % Strip the leading '#/' and navigate from the current root.
    sub_string_after(Ref, 2, Pointer), co_navigate(Root, Pointer, Schema).
co_resolve_ref(Ref, _Root, Schema, RootOut) :-
    % A cross-file reference to a sibling schema on the canonical host.
    Base = "https://causalontology.org/schema/",
    sub_atom_or_string(Ref, 0, _, _, Base), !,
    % Remove the base to get "<file>#/<pointer>" (pointer may be absent).
    atom_length(Base, BL), sub_string_after(Ref, BL, Rest),
    ( split_hash(Rest, FileS, Pointer)
      -> ( atom_string(FileA, FileS), co_load_file(FileA, RootOut),
           ( Pointer == "" -> Schema = RootOut ; co_navigate(RootOut, Pointer, Schema) ) )
      ;  ( atom_string(FileA, Rest), co_load_file(FileA, RootOut), Schema = RootOut )
    ).

% -- split_hash(+S, -Before, -After): split "<file>#/<ptr>" at the '#/'.
split_hash(S, Before, After) :-
    % Find the "#/" separator and split around it.
    sub_string(S, B, _, A, "#/"), !,
    sub_string(S, 0, B, _, Before), sub_string_after(S, _, After0),
    string_length(S, L), APos is L - A, sub_string(S, APos, A, 0, After).

% -- co_navigate(+Doc, +Pointer, -Node): walk a JSON pointer like "$defs/croId".
co_navigate(Node, "", Node) :- !.
% Split the pointer on '/', then descend one token at a time.
co_navigate(Doc, Pointer, Node) :-
    % Break the pointer into slash-separated parts.
    split_string(Pointer, "/", "", Parts0),
    % Drop empty parts (leading slash or doubled slashes).
    exclude(==(""), Parts0, Parts),
    % Descend through the parts.
    co_descend(Parts, Doc, Node).

% -- co_descend(+Parts, +Node, -Out): follow each pointer token.
co_descend([], Node, Node).
% Descend one dict/array level per token.
co_descend([P|Ps], Node, Out) :-
    % A dict token indexes by the atom key.
    ( is_dict(Node) -> atom_string(K, P), get_dict(K, Node, Next)
    % An array token indexes by integer position.
    ; is_list(Node) -> number_string(I, P), nth0(I, Node, Next)
    ),
    co_descend(Ps, Next, Out).

% ---------------------------------------------------------------------------
% co_check(+Value, +Schema, +Root, +Path, -Error): enumerate structural errors.
% Each solution is one error string; findall gathers them all.
% ---------------------------------------------------------------------------

% oneOf: exactly one branch must validate; otherwise a single error.
co_check(Value, Schema0, Root0, Path, Error) :-
    co_resolve(Schema0, Root0, Schema, Root),
    get_dict(oneOf, Schema, Branches), !,
    % Count how many branches accept the value with no error.
    aggregate_all(count, co_branch_ok(Value, Branches, Root, Path), N),
    % Exactly one passing branch is required.
    N =\= 1,
    format(string(Error), "~w: matches ~w of the oneOf branches (need exactly 1)", [Path, N]).
% Every non-oneOf keyword is checked by co_check_kw.
co_check(Value, Schema0, Root0, Path, Error) :-
    co_resolve(Schema0, Root0, Schema, Root),
    \+ get_dict(oneOf, Schema, _),
    co_check_kw(Value, Schema, Root, Path, Error).

% -- co_branch_ok(+Value, +Branches, +Root, +Path): a branch with zero errors.
co_branch_ok(Value, Branches, Root, Path) :-
    % Choose a branch.
    member(Sub, Branches),
    % It is ok when it yields no error for the value.
    \+ co_check(Value, Sub, Root, Path, _).

% -- co_check_kw: type mismatch (with the bool-is-not-number guard).
co_check_kw(Value, Schema, _Root, Path, Error) :-
    get_dict(type, Schema, T),
    \+ co_type_ok(T, Value),
    format(string(Error), "~w: expected ~w", [Path, T]).
% const mismatch.
co_check_kw(Value, Schema, _Root, Path, Error) :-
    get_dict(const, Schema, C), \+ co_equal(Value, C),
    format(string(Error), "~w: must equal ~w", [Path, C]).
% enum mismatch.
co_check_kw(Value, Schema, _Root, Path, Error) :-
    get_dict(enum, Schema, Es), \+ ( member(E, Es), co_equal(Value, E) ),
    format(string(Error), "~w: ~w not in enumeration", [Path, Value]).
% pattern mismatch (strings only).
co_check_kw(Value, Schema, _Root, Path, Error) :-
    get_dict(pattern, Schema, P), string_or_atom(Value),
    to_string(Value, VS), to_string(P, PS),
    \+ re_match(PS, VS),
    format(string(Error), "~w: ~w does not match ~w", [Path, VS, PS]).
% minLength (strings only).
co_check_kw(Value, Schema, _Root, Path, Error) :-
    get_dict(minLength, Schema, Min), string_or_atom(Value),
    to_string(Value, VS), string_length(VS, L), L < Min,
    format(string(Error), "~w: shorter than minLength", [Path]).
% minimum (numbers only, bool excluded).
co_check_kw(Value, Schema, _Root, Path, Error) :-
    get_dict(minimum, Schema, Min), number(Value), \+ is_bool(Value), Value < Min,
    format(string(Error), "~w: below minimum ~w", [Path, Min]).
% maximum (numbers only, bool excluded).
co_check_kw(Value, Schema, _Root, Path, Error) :-
    get_dict(maximum, Schema, Max), number(Value), \+ is_bool(Value), Value > Max,
    format(string(Error), "~w: above maximum ~w", [Path, Max]).
% minItems (arrays only).
co_check_kw(Value, Schema, _Root, Path, Error) :-
    is_list(Value), get_dict(minItems, Schema, Min), length(Value, L), L < Min,
    format(string(Error), "~w: fewer than ~w items", [Path, Min]).
% items: validate each element against the item schema.
co_check_kw(Value, Schema, Root, Path, Error) :-
    is_list(Value), get_dict(items, Schema, ItemSchema),
    nth0(I, Value, Item),
    format(string(SubPath), "~w[~w]", [Path, I]),
    co_check(Item, ItemSchema, Root, SubPath, Error).
% required: each required property must be present.
co_check_kw(Value, Schema, _Root, Path, Error) :-
    is_dict(Value), get_dict(required, Schema, Reqs),
    member(Req, Reqs), atom_string(ReqA, Req), \+ get_dict(ReqA, Value, _),
    format(string(Error), "~w: required property '~w' missing", [Path, Req]).
% additionalProperties:false — no key outside the declared properties.
co_check_kw(Value, Schema, _Root, Path, Error) :-
    is_dict(Value), get_dict(additionalProperties, Schema, false),
    ( get_dict(properties, Schema, Props) -> true ; Props = _{} ),
    dict_pairs(Value, _, Pairs), member(K-_, Pairs), \+ get_dict(K, Props, _),
    format(string(Error), "~w: additional property '~w'", [Path, K]).
% properties: validate each present property against its subschema.
co_check_kw(Value, Schema, Root, Path, Error) :-
    is_dict(Value), get_dict(properties, Schema, Props),
    dict_pairs(Props, _, PropPairs), member(K-Sub, PropPairs), get_dict(K, Value, PV),
    format(string(SubPath), "~w.~w", [Path, K]),
    co_check(PV, Sub, Root, SubPath, Error).

% -- co_type_ok(+TypeName, +Value): JSON type test with bool/number separation.
co_type_ok("object", V) :- is_dict(V).
% array.
co_type_ok("array", V) :- is_list(V).
% string.
co_type_ok("string", V) :- string(V) ; ( atom(V), \+ is_bool(V), V \== [] ).
% number excludes booleans.
co_type_ok("number", V) :- number(V), \+ is_bool(V).
% integer.
co_type_ok("integer", V) :- integer(V).
% boolean is the atom true or false.
co_type_ok("boolean", V) :- is_bool(V).

% -- is_bool(+V): the JSON booleans are the atoms true and false.
is_bool(true).
is_bool(false).

% -- co_equal(+A, +B): equality across string/atom encodings and numbers.
co_equal(A, B) :- A == B, !.
% Compare a string against an atom by their text.
co_equal(A, B) :- string_or_atom(A), string_or_atom(B), to_string(A, S), to_string(B, S).

% -- helpers: string/atom predicates and conversions.
string_or_atom(X) :- string(X), !.
% An atom that is not a JSON boolean also counts as text.
string_or_atom(X) :- atom(X), \+ is_bool(X).
% to_string/2 renders a string or atom as a string.
to_string(X, S) :- ( string(X) -> S = X ; atom_string(X, S) ).

% -- sub_atom_or_string(+Whole, +Before, +Len, +After, +Sub): text prefix test.
sub_atom_or_string(Whole, B, L, A, Sub) :-
    to_string(Whole, WS), ( string(Sub) -> SS = Sub ; atom_string(Sub, SS) ),
    sub_string(WS, B, L, A, SS).

% -- sub_string_after(+S, ?Before, -After): the suffix of S after Before chars.
sub_string_after(S, Before, After) :-
    to_string(S, WS), string_length(WS, L),
    ( var(Before) -> true ; true ),
    ( integer(Before) -> Len is L - Before, sub_string(WS, Before, Len, 0, After)
    ; sub_string(WS, _, _, 0, After) ).
