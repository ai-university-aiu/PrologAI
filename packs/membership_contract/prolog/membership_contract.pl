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

    THE ACCESSOR FORM (Ledger entry N11, closes N9 / HIPPO-1, WP-427). The plain-list
    form above reads the offered set from a LIST ARGUMENT. But a growing store — the
    Wave 6 memory region's stored-memory facts on the Lattice — is not a plain list,
    and flattening it into one on every call is O(store size) per call (HIPPO-1, a
    second sighting of gap N9). The ACCESSOR FORM lets a contract name the set by a
    GOAL instead of a list argument, so a growing or streaming set can be guarded
    without materialising it:

      - THE TEST-GOAL FORM (primary; avoids materialisation). membership_contract_enforce_goal/4
        names a semi-deterministic MEMBERSHIP-TEST goal — a closure that, given a
        candidate output, SUCCEEDS if that candidate is in the set and FAILS otherwise.
        On every call the contract runs that test on the produced output: a member
        passes, the declared abstention passes, and a non-member is refused. The full
        set is NEVER built — for a fact store this is a single lookup, not an O(size)
        copy. This is the form that retires HIPPO-1's cost.

      - THE PRODUCER-GOAL FORM (convenience; still materialises). membership_contract_enforce_producer/4
        names a goal that PRODUCES the set as a list; the contract then reuses the
        plain-list check. It is offered as a convenience for a small set, but because
        it builds the whole list it does NOT avoid the cost N9 named — so the
        test-goal form, not this one, is the fix for a growing store.

      The test-goal must be a PURE membership test from the contract's point of view:
      the contract calls it as a check (call/2 with the candidate appended) and must
      not mutate the set. A membership check may run on every call, so it must be
      cheap and non-destructive. The accessor form is opt-in and additive; the
      plain-list form above is unchanged and a predicate may use either form or none.

    PUBLIC PREDICATES
      membership_contract_enforce/4   :Pred, +OutPos, +InPos, +Abstention   declare + wrap (plain-list)
      membership_contract_check/4      +Pred, +Out, +In, +Abstention         the postcondition (succeed or throw)
      membership_contract_holds/3      +Out, +In, +Abstention                boolean membership test (never throws)
      membership_contract_declared/4   ?Pred, ?OutPos, ?InPos, ?Abstention   enumerate plain-list contracts
      membership_contract_enforce_goal/4      :Pred, +OutPos, :TestGoal, +Abstention   declare + wrap (accessor, test-goal — no materialisation)
      membership_contract_enforce_producer/4  :Pred, +OutPos, :ProducerGoal, +Abstention  declare + wrap (accessor, producer — materialises)
      membership_contract_check_goal/4        +Pred, +Out, :TestGoal, +Abstention      the test-goal postcondition (succeed or throw)
      membership_contract_holds_goal/3        +Out, :TestGoal, +Abstention             boolean test-goal check (never throws)
      membership_contract_declared_goal/4     ?Pred, ?OutPos, ?Form, ?Abstention        enumerate accessor contracts (Form = test/producer)
      membership_contract_violation_line/2  +Error, -Line                    render a violation readably (both forms)
*/

% Declare the module and its public predicates.
:- module(membership_contract, [
    % membership_contract_enforce/4: declare a plain-list contract on a predicate and enforce it as a postcondition.
    membership_contract_enforce/4,
    % membership_contract_check/4: the plain-list postcondition — succeed on a member/abstention, else throw.
    membership_contract_check/4,
    % membership_contract_holds/3: a boolean plain-list membership test that never throws.
    membership_contract_holds/3,
    % membership_contract_declared/4: enumerate the predicates that declare a plain-list contract.
    membership_contract_declared/4,
    % membership_contract_enforce_goal/4: declare an ACCESSOR contract naming a membership-TEST goal (no materialisation).
    membership_contract_enforce_goal/4,
    % membership_contract_enforce_producer/4: declare an ACCESSOR contract naming a list-PRODUCER goal (materialises; convenience).
    membership_contract_enforce_producer/4,
    % membership_contract_check_goal/4: the test-goal postcondition — succeed on a member/abstention, else throw.
    membership_contract_check_goal/4,
    % membership_contract_holds_goal/3: a boolean test-goal membership check that never throws.
    membership_contract_holds_goal/3,
    % membership_contract_declared_goal/4: enumerate the predicates that declare an accessor contract.
    membership_contract_declared_goal/4,
    % membership_contract_violation_line/2: render one contract violation as a readable line (either form).
    membership_contract_violation_line/2
]).

% Import memberchk/2 from the lists library (the membership test).
:- use_module(library(lists), [memberchk/2]).
% Import wrap_predicate/4 from the prolog_wrap library — SWI's transparent per-call wrapping.
:- use_module(library(prolog_wrap), [wrap_predicate/4]).

% The registry of declared plain-list contracts, keyed by module-qualified predicate indicator.
:- dynamic membership_contract_registry/4.
% The registry of declared ACCESSOR contracts: Pred, OutPos, Form (test/producer), the readable goal label, Abstention.
:- dynamic membership_contract_goal_registry/5.

% The plain-list enforce predicate is module-transparent: it wraps a predicate in the CALLER's module.
:- meta_predicate membership_contract_enforce(:, +, +, +).
% The accessor enforce predicates take a module-qualified GOAL (a closure called with one extra argument, the candidate).
:- meta_predicate
    membership_contract_enforce_goal(:, +, 1, +),
    membership_contract_enforce_producer(:, +, 1, +),
    membership_contract_check_goal(+, +, 1, +),
    membership_contract_check_producer(+, +, 1, +),
    membership_contract_holds_goal(+, 1, +).

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

% ---------------------------------------------------------------------------
% THE ACCESSOR FORM — membership against a GOAL-described set (N11, closes N9 / HIPPO-1).
% ---------------------------------------------------------------------------

% -- membership_contract_enforce_goal(:Pred, +OutPos, :TestGoal, +Abstention):
% Declare that Pred's OutPos-th argument must satisfy the MEMBERSHIP-TEST goal TestGoal
% — a closure that succeeds when called with the candidate output appended as its last
% argument — or equal the Abstention value, and WRAP Pred so every call is checked.
% THE FULL SET IS NEVER MATERIALISED: only the test goal runs, on the single produced
% output. Idempotent: re-enforcing replaces the wrapper.
membership_contract_enforce_goal(M:Name/Arity, OutPos, TestGoal, Abstention) :-
    % Validate the predicate and output position, and bind the output argument by position.
    membership_contract_out_head(M, Name, Arity, OutPos, membership_contract_enforce_goal/4, Head, Out),
    % Derive a readable label for the test goal (the glass-box violation names it, since there is no list to print).
    membership_contract_goal_label(TestGoal, Label),
    % Record (or update) the accessor contract as a TEST-goal form in the registry.
    retractall(membership_contract_goal_registry(M:Name/Arity, _, _, _, _)),
    assertz(membership_contract_goal_registry(M:Name/Arity, OutPos, test, Label, Abstention)),
    % Wrap the predicate: on every solution, run the original then check the test-goal postcondition
    % (module-qualified so the wrapper resolves the check in this module regardless of the caller's imports).
    wrap_predicate(M:Head, membership_contract, Closure,
        ( Closure,
          membership_contract:membership_contract_check_goal(M:Name/Arity, Out, TestGoal, Abstention) )).

% -- membership_contract_enforce_producer(:Pred, +OutPos, :ProducerGoal, +Abstention):
% Declare that Pred's OutPos-th argument must be a member of the list PRODUCED by
% ProducerGoal — a closure called with the produced list appended — or equal Abstention.
% CONVENIENCE ONLY: it MATERIALISES the set on every call and reuses the plain-list check,
% so it does NOT avoid the cost N9 named; prefer the test-goal form for a growing store.
membership_contract_enforce_producer(M:Name/Arity, OutPos, ProducerGoal, Abstention) :-
    % Validate the predicate and output position, and bind the output argument by position.
    membership_contract_out_head(M, Name, Arity, OutPos, membership_contract_enforce_producer/4, Head, Out),
    % Derive a readable label for the producer goal.
    membership_contract_goal_label(ProducerGoal, Label),
    % Record (or update) the accessor contract as a PRODUCER form in the registry.
    retractall(membership_contract_goal_registry(M:Name/Arity, _, _, _, _)),
    assertz(membership_contract_goal_registry(M:Name/Arity, OutPos, producer, Label, Abstention)),
    % Wrap the predicate: on every solution, run the original then check the producer postcondition
    % (module-qualified so the internal producer check resolves regardless of the caller's imports).
    wrap_predicate(M:Head, membership_contract, Closure,
        ( Closure,
          membership_contract:membership_contract_check_producer(M:Name/Arity, Out, ProducerGoal, Abstention) )).

% -- membership_contract_out_head(+M, +Name, +Arity, +OutPos, +Ctx, -Head, -Out):
% Shared accessor-form validation: the arity and output position are valid and the
% predicate is defined; Head is a fresh skeleton with Out bound at OutPos. (The
% plain-list enforce/4 keeps its own inline validation, unchanged.)
membership_contract_out_head(M, Name, Arity, OutPos, Ctx, Head, Out) :-
    % The arity must be a positive integer.
    ( integer(Arity), Arity >= 1
    ->  true
    ;   throw(error(type_error(predicate_arity, Arity), Ctx)) ),
    % The output position must be an argument index within the arity.
    ( integer(OutPos), OutPos >= 1, OutPos =< Arity
    ->  true
    ;   throw(error(domain_error(argument_position, OutPos), Ctx)) ),
    % Build a head skeleton and bind the output argument variable at its position.
    functor(Head, Name, Arity),
    arg(OutPos, Head, Out),
    % The predicate must already be defined before it can be guarded.
    ( predicate_property(M:Head, defined)
    ->  true
    ;   throw(error(existence_error(procedure, M:Name/Arity), Ctx)) ).

% -- membership_contract_goal_label(+Goal, -Label): a readable, module-stripped, binding-free rendering of a set goal.
membership_contract_goal_label(Goal, Label) :-
    % Strip any module qualification so the label reads as the plain goal the author wrote.
    strip_module(Goal, _Module, Plain),
    % Copy it so the label carries no runtime bindings from the call site.
    copy_term(Plain, Label).

% -- membership_contract_check_goal(+Pred, +Out, :TestGoal, +Abstention): the test-goal postcondition — succeed or throw.
% Succeeds when Out is the declared abstention or the membership-test goal accepts it;
% throws a glass-box membership_contract_goal_violation otherwise. The full set is NEVER
% built — only the test goal is called on the single produced output.
membership_contract_check_goal(_Pred, Out, _TestGoal, Abstention) :-
    % The declared abstention value always satisfies the contract.
    Out == Abstention,
    !.
membership_contract_check_goal(_Pred, Out, TestGoal, _Abstention) :-
    % The output is a member exactly when the test goal accepts it (called with the output appended); no list is built.
    call(TestGoal, Out),
    !.
membership_contract_check_goal(Pred, Out, TestGoal, _Abstention) :-
    % Anything else — an output the set goal rejects — is REFUSED with a glass-box violation naming the goal.
    membership_contract_goal_label(TestGoal, Label),
    throw(error(membership_contract_goal_violation(Pred, Out, Label), membership_contract)).

% -- membership_contract_check_producer(+Pred, +Out, :ProducerGoal, +Abstention): the producer postcondition — succeed or throw.
% Materialises the set by calling the producer, then reuses the plain-list check (so a
% non-member throws the plain-list membership_contract_violation, which CAN print the list).
membership_contract_check_producer(_Pred, Out, _ProducerGoal, Abstention) :-
    % The declared abstention value always satisfies the contract.
    Out == Abstention,
    !.
membership_contract_check_producer(Pred, Out, ProducerGoal, Abstention) :-
    % Materialise the offered set as a list (the cost the test-goal form avoids), then reuse the plain-list check.
    call(ProducerGoal, List),
    membership_contract_check(Pred, Out, List, Abstention).

% -- membership_contract_holds_goal(+Out, :TestGoal, +Abstention): a boolean test-goal check that never throws.
membership_contract_holds_goal(Out, _TestGoal, Abstention) :-
    % The declared abstention satisfies the contract.
    Out == Abstention,
    !.
membership_contract_holds_goal(Out, TestGoal, _Abstention) :-
    % Otherwise the test goal must accept the output; call it once as a pure, deterministic membership test.
    once(call(TestGoal, Out)).

% -- membership_contract_declared_goal(?Pred, ?OutPos, ?Form, ?Abstention): enumerate declared accessor contracts.
membership_contract_declared_goal(Pred, OutPos, Form, Abstention) :-
    % Yield each registered accessor contract's predicate, output position, form (test/producer), and abstention.
    membership_contract_goal_registry(Pred, OutPos, Form, _Label, Abstention).

% -- membership_contract_violation_line(+Error, -Line): render a contract violation as a readable line.
membership_contract_violation_line(
        error(membership_contract_violation(Pred, Out, In), _), Line) :-
    % Compose the one-line, glass-box explanation naming the predicate, the output, and the offered set.
    format(atom(Line),
      "membership_contract violation: ~w produced ~q, which is not a member of the offered set ~q (and is not the declared abstention)",
      [Pred, Out, In]).
% Render an ACCESSOR (test-goal) violation: there is no list to print, so name the membership-test goal it failed.
membership_contract_violation_line(
        error(membership_contract_goal_violation(Pred, Out, GoalLabel), _), Line) :-
    % Compose the one-line, glass-box explanation naming the predicate, the output, and the set goal it failed.
    format(atom(Line),
      "membership_contract violation: ~w produced ~q, which the membership-test goal ~q does not accept (it is not a member of the set that goal defines, and is not the declared abstention)",
      [Pred, Out, GoalLabel]).
