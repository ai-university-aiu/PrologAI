/*  PrologAI — the Membership Contract construct  (Ledger entry N8, closes ARBITER-1)

    THE GAP THIS CLOSES (ARBITER-1, from the Wave 4 safety layer connectome-arbiter).
    The arbiter's basal-ganglia selector must never emit an action nobody offered
    — its output must always be a member of its input candidate set (or an explicit
    abstention). It proved that property holds, but only by HAND: a guard predicate,
    a throwing emit step, and a standalone adversarial battery, each output routed
    through them by an author who remembered to. A SECOND selector, written without
    the habit, would carry no protection at all, because PrologAI had no way to say
    "the output of this predicate MUST be a member of this input set" and enforce it.

    WHAT THIS PROVIDES. An opt-in CONTRACT declared on a predicate — a designated
    OUTPUT argument must be a member of a designated INPUT set argument (a list), or
    a declared, explicit ABSTENTION value. It is enforced as a RUNTIME POSTCONDITION:

      - RUNTIME, NOT LOAD-TIME — this is the key difference from the strict layer
        rule (L4) and the layer-to-stratum binding (N6), both of which are load-time
        properties checkable from the static graph. Membership depends on the actual
        input and the actual output on a given call, so it can only be checked when
        the guarded predicate produces a result. The contract wraps the predicate
        (SWI-Prolog's wrap_predicate/4) so that on EVERY solution the postcondition
        runs: a member passes, the declared abstention passes, and a NON-member is
        refused with a glass-box error naming the predicate, the output, and the set
        it was not a member of. The guarded predicate cannot return a non-member.

      - OPT-IN / INCREMENTAL — a predicate with NO contract is UNGUARDED, not
        violating: it behaves exactly as today. Nothing is checked until a predicate
        opts in with membership_contract_enforce/4 (the same adoption pattern L4 uses
        for undeclared layers and N6 for unbound packs).

      - GLASS-BOX — a violation is a readable error (membership_contract_violation_line/2).

    SCOPE. It is about MEMBERSHIP specifically — output is a member of a named input
    set — not a general assertion framework or a type system. Kept deliberately tight.

    DEPENDENCIES. It imports only SWI-Prolog standard libraries (lists, prolog_wrap),
    never the Lattice, the actors pack, any Causalontology pack, or the arbiter — it
    is a general language affordance usable by any pack that produces a selection from
    a candidate set. Its declared layer(0) has no intra-repo edge.

    PUBLIC PREDICATES
      membership_contract_enforce/4   :Pred, +OutPos, +InPos, +Abstention   declare + wrap
      membership_contract_check/4      +Pred, +Out, +In, +Abstention         the postcondition (succeed or throw)
      membership_contract_holds/3      +Out, +In, +Abstention                boolean membership test (never throws)
      membership_contract_declared/4   ?Pred, ?OutPos, ?InPos, ?Abstention   enumerate declared contracts
      membership_contract_violation_line/2  +Error, -Line                    render a violation readably
*/

% Declare the module and its public predicates.
:- module(membership_contract, [
    % membership_contract_enforce/4: declare a contract on a predicate and enforce it as a postcondition.
    membership_contract_enforce/4,
    % membership_contract_check/4: the postcondition itself — succeed on a member/abstention, else throw.
    membership_contract_check/4,
    % membership_contract_holds/3: a boolean membership test that never throws.
    membership_contract_holds/3,
    % membership_contract_declared/4: enumerate the predicates that declare a contract.
    membership_contract_declared/4,
    % membership_contract_violation_line/2: render one contract violation as a readable line.
    membership_contract_violation_line/2
]).

% Import memberchk/2 from the lists library (the membership test).
:- use_module(library(lists), [memberchk/2]).
% Import wrap_predicate/4 from the prolog_wrap library — SWI's transparent per-call wrapping.
:- use_module(library(prolog_wrap), [wrap_predicate/4]).

% The registry of declared contracts, keyed by module-qualified predicate indicator.
:- dynamic membership_contract_registry/4.

% The enforce predicate is module-transparent: it wraps a predicate in the CALLER's module.
:- meta_predicate membership_contract_enforce(:, +, +, +).

% ---------------------------------------------------------------------------
% Declaring and enforcing a contract.
% ---------------------------------------------------------------------------

% -- membership_contract_enforce(:Pred, +OutPos, +InPos, +Abstention):
% Declare that predicate Pred's OutPos-th argument must be a member of its InPos-th
% argument (a list), or equal to the Abstention value, and WRAP Pred so every call
% is checked. Idempotent: re-enforcing updates the contract and replaces the wrapper.
membership_contract_enforce(M:Name/Arity, OutPos, InPos, Abstention) :-
    % The arity must be a positive integer.
    ( integer(Arity), Arity >= 1
    ->  true
    ;   throw(error(type_error(predicate_arity, Arity), membership_contract_enforce/4)) ),
    % The output and input positions must be argument indices within the arity.
    ( integer(OutPos), OutPos >= 1, OutPos =< Arity,
      integer(InPos), InPos >= 1, InPos =< Arity
    ->  true
    ;   throw(error(domain_error(argument_position, OutPos-InPos), membership_contract_enforce/4)) ),
    % Build a head skeleton so the output and input arguments can be named by position.
    functor(Head, Name, Arity),
    % Bind the output argument variable at its position.
    arg(OutPos, Head, Out),
    % Bind the input-set argument variable at its position.
    arg(InPos, Head, In),
    % The predicate must already be defined before it can be guarded.
    ( predicate_property(M:Head, defined)
    ->  true
    ;   throw(error(existence_error(procedure, M:Name/Arity), membership_contract_enforce/4)) ),
    % Record (or update) the contract in the registry so it can be introspected.
    retractall(membership_contract_registry(M:Name/Arity, _, _, _)),
    assertz(membership_contract_registry(M:Name/Arity, OutPos, InPos, Abstention)),
    % Wrap the predicate: on every solution, run the original then check the postcondition.
    wrap_predicate(M:Head, membership_contract, Closure,
        ( Closure,
          membership_contract_check(M:Name/Arity, Out, In, Abstention) )).

% -- membership_contract_declared(?Pred, ?OutPos, ?InPos, ?Abstention): enumerate declared contracts.
membership_contract_declared(Pred, OutPos, InPos, Abstention) :-
    % Yield each registered contract term.
    membership_contract_registry(Pred, OutPos, InPos, Abstention).

% ---------------------------------------------------------------------------
% The postcondition — the pure check, and its boolean sibling.
% ---------------------------------------------------------------------------

% -- membership_contract_check(+Pred, +Out, +In, +Abstention): the postcondition — succeed or throw.
% Succeeds when Out is the declared abstention or a member of the input set In;
% throws a glass-box membership_contract_violation otherwise. It NEVER endorses a
% non-member — refusing (throwing) is the only outcome for one.
membership_contract_check(_Pred, Out, _In, Abstention) :-
    % The declared abstention value always satisfies the contract (choosing nothing is legal).
    Out == Abstention,
    !.
membership_contract_check(Pred, _Out, In, _Abstention) :-
    % The input set must be a proper list; a non-list is a contract usage error, not a member/non-member.
    \+ is_list(In),
    !,
    throw(error(membership_contract_input_not_a_list(Pred, In), membership_contract)).
membership_contract_check(_Pred, Out, In, _Abstention) :-
    % An output that is a member of the offered input set satisfies the contract.
    memberchk(Out, In),
    !.
membership_contract_check(Pred, Out, In, _Abstention) :-
    % Anything else — an output nobody offered — is REFUSED with a glass-box violation.
    throw(error(membership_contract_violation(Pred, Out, In), membership_contract)).

% -- membership_contract_holds(+Out, +In, +Abstention): a boolean membership test that never throws.
membership_contract_holds(Out, _In, Abstention) :-
    % The declared abstention satisfies the contract.
    Out == Abstention,
    !.
membership_contract_holds(Out, In, _Abstention) :-
    % Otherwise the output must be a member of the input set (a proper list).
    is_list(In),
    memberchk(Out, In).

% -- membership_contract_violation_line(+Error, -Line): render a contract violation as a readable line.
membership_contract_violation_line(
        error(membership_contract_violation(Pred, Out, In), _), Line) :-
    % Compose the one-line, glass-box explanation naming the predicate, the output, and the offered set.
    format(atom(Line),
      "membership_contract violation: ~w produced ~q, which is not a member of the offered set ~q (and is not the declared abstention)",
      [Pred, Out, In]).
