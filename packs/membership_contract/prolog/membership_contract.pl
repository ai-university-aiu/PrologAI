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

    THE ONCE / DETERMINISTIC MODE (Ledger entry N14, closes N12 / N10, WP-428). By
    default the contract checks EVERY solution the guarded predicate produces — right
    for a predicate that yields one answer, but wrong for one that GENERATES several
    candidates on backtracking and COMMITS one (a selector that proposes then picks; a
    corrector that considers adjustments then emits one). Such a predicate wants the
    guarantee on the COMMITTED answer, not a throw partway through its backtracking.
    The ONCE mode provides exactly that: the mode-carrying enforce entry points take a
    trailing +Mode argument (per_solution — the unchanged default — or once). In once
    mode the guarded predicate commits to its FIRST solution, that committed output is
    checked for membership exactly once, and the predicate is left DETERMINISTIC (no
    choice points for the contract's sake). It commits HONESTLY to the first solution:
    if that first solution is a non-member it is refused on it (once mode is for a
    predicate whose first answer IS the committed answer, not a search-and-filter). It
    is available to BOTH the plain-list form and the accessor form; once plus the
    test-goal accessor form still materialises NO set. Opt-in and additive: a contract
    declared without a mode behaves exactly as before.

      membership_contract_enforce/5           :Pred, +OutPos, +InPos, +Abstention, +Mode      plain-list with a mode (per_solution/once)
      membership_contract_enforce_goal/5      :Pred, +OutPos, :TestGoal, +Abstention, +Mode   accessor test-goal with a mode
      membership_contract_enforce_producer/5  :Pred, +OutPos, :ProducerGoal, +Abstention, +Mode  accessor producer with a mode
      membership_contract_declared_mode/2     ?Pred, ?Mode                                     the mode (per_solution/once) a contract runs in
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
    % membership_contract_enforce/5: declare a plain-list contract with a MODE (per_solution default, or once — commit the first solution).
    membership_contract_enforce/5,
    % membership_contract_enforce_goal/5: declare an accessor test-goal contract with a MODE (per_solution or once).
    membership_contract_enforce_goal/5,
    % membership_contract_enforce_producer/5: declare an accessor producer contract with a MODE (per_solution or once).
    membership_contract_enforce_producer/5,
    % membership_contract_declared_mode/2: enumerate the mode (per_solution/once) each declared contract runs in.
    membership_contract_declared_mode/2,
    % membership_contract_enforce_context/6: declare a CONTEXT-AWARE accessor - the test goal takes (Output, HeldContext) (WP-431).
    membership_contract_enforce_context/6,
    % membership_contract_check_context/5: the context-aware postcondition — succeed on a member-in-context/abstention, else throw.
    membership_contract_check_context/5,
    % membership_contract_holds_context/4: a boolean context-aware check that never throws.
    membership_contract_holds_context/4,
    % membership_contract_violation_line/2: render one contract violation as a readable line (either form).
    membership_contract_violation_line/2,
    % --- Refinements (Wave 10 Stage 9) — additive to the above ---
    % membership_contract_holds_guarded/3: a purity-guarded (double-negation) boolean membership test (N13).
    membership_contract_holds_guarded/3,
    % membership_contract_test_deterministic/2: succeed iff the test goal is semidet on an output (N13).
    membership_contract_test_deterministic/2,
    % membership_contract_find_member/4: commit to the FIRST generated candidate that is a member (N15).
    membership_contract_find_member/4
]).

% Import memberchk/2 from the lists library (the membership test).
:- use_module(library(lists), [memberchk/2]).
% Import wrap_predicate/4 from the prolog_wrap library — SWI's transparent per-call wrapping.
:- use_module(library(prolog_wrap), [wrap_predicate/4]).

% The refinement predicates call caller-supplied goals: the test goal and the generator.
:- meta_predicate membership_contract_holds_guarded(+, 1, +).
:- meta_predicate membership_contract_test_deterministic(1, +).
:- meta_predicate membership_contract_find_member(1, 1, +, -).

% The registry of declared plain-list contracts, keyed by module-qualified predicate indicator.
:- dynamic membership_contract_registry/4.
% The registry of declared ACCESSOR contracts: Pred, OutPos, Form (test/producer), the readable goal label, Abstention.
:- dynamic membership_contract_goal_registry/5.
% The MODE a mode-carrying declaration installed: Pred, Mode. Only 'once' is recorded; a
% contract declared without a mode is per_solution by default and records no entry here.
:- dynamic membership_contract_mode_registry/2.

% The plain-list enforce predicate is module-transparent: it wraps a predicate in the CALLER's module.
:- meta_predicate membership_contract_enforce(:, +, +, +).
% The accessor enforce predicates take a module-qualified GOAL (a closure called with one extra argument, the candidate).
:- meta_predicate
    membership_contract_enforce_goal(:, +, 1, +),
    membership_contract_enforce_producer(:, +, 1, +),
    membership_contract_check_goal(+, +, 1, +),
    membership_contract_check_producer(+, +, 1, +),
    membership_contract_holds_goal(+, 1, +).
% The mode-carrying enforce predicates mirror the base ones with a trailing +Mode argument.
:- meta_predicate
    membership_contract_enforce(:, +, +, +, +),
    membership_contract_enforce_goal(:, +, 1, +, +),
    membership_contract_enforce_producer(:, +, 1, +, +).

% The context-aware accessor (WP-431): the test goal is called with (Output, Context) — two
% appended arguments — and the context goal with (Context) — one appended argument.
:- meta_predicate
    membership_contract_enforce_context(:, +, 2, 1, +, +),
    membership_contract_check_context(+, +, 2, 1, +),
    membership_contract_holds_context(+, 2, 1, +).

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

% ---------------------------------------------------------------------------
% THE ONCE / DETERMINISTIC MODE — guard the COMMITTED single answer (N14, closes N12 / N10).
% ---------------------------------------------------------------------------

% -- membership_contract_enforce(:Pred, +OutPos, +InPos, +Abstention, +Mode):
% The plain-list contract WITH A MODE. Mode is per_solution (identical to enforce/4 — the
% check fires on every solution) or once (the guarded predicate commits to its FIRST
% solution, that committed output is checked once, and the predicate is deterministic).
membership_contract_enforce(M:Name/Arity, OutPos, InPos, Abstention, Mode) :-
    % The mode must be a recognised one.
    membership_contract_valid_mode(Mode),
    % The arity must be a positive integer (same validation as the plain-list enforce/4).
    ( integer(Arity), Arity >= 1
    ->  true
    ;   throw(error(type_error(predicate_arity, Arity), membership_contract_enforce/5)) ),
    % The output and input positions must be argument indices within the arity.
    ( integer(OutPos), OutPos >= 1, OutPos =< Arity,
      integer(InPos), InPos >= 1, InPos =< Arity
    ->  true
    ;   throw(error(domain_error(argument_position, OutPos-InPos), membership_contract_enforce/5)) ),
    % Build the head skeleton and bind the output and input-set arguments by position.
    functor(Head, Name, Arity),
    arg(OutPos, Head, Out),
    arg(InPos, Head, In),
    % The predicate must already be defined before it can be guarded.
    ( predicate_property(M:Head, defined)
    ->  true
    ;   throw(error(existence_error(procedure, M:Name/Arity), membership_contract_enforce/5)) ),
    % Record the plain-list contract in the base registry (so declared/4 still enumerates it) and record its mode.
    retractall(membership_contract_registry(M:Name/Arity, _, _, _)),
    assertz(membership_contract_registry(M:Name/Arity, OutPos, InPos, Abstention)),
    membership_contract_record_mode(M:Name/Arity, Mode),
    % Install the wrapper for the requested mode, checking membership of the (committed) output.
    membership_contract_wrap_mode(M, Head, Mode,
        membership_contract:membership_contract_check(M:Name/Arity, Out, In, Abstention)).

% -- membership_contract_enforce_goal(:Pred, +OutPos, :TestGoal, +Abstention, +Mode):
% The accessor test-goal contract WITH A MODE. In once mode the committed output is checked
% against the membership-TEST goal exactly once — and, as in the per-solution test-goal form,
% the full set is NEVER materialised.
membership_contract_enforce_goal(M:Name/Arity, OutPos, TestGoal, Abstention, Mode) :-
    % The mode must be recognised.
    membership_contract_valid_mode(Mode),
    % Validate the predicate and output position and bind the output argument (shared accessor validation).
    membership_contract_out_head(M, Name, Arity, OutPos, membership_contract_enforce_goal/5, Head, Out),
    % Derive a readable label for the test goal.
    membership_contract_goal_label(TestGoal, Label),
    % Record the accessor contract (test form) in the goal registry and record its mode.
    retractall(membership_contract_goal_registry(M:Name/Arity, _, _, _, _)),
    assertz(membership_contract_goal_registry(M:Name/Arity, OutPos, test, Label, Abstention)),
    membership_contract_record_mode(M:Name/Arity, Mode),
    % Install the wrapper for the requested mode, checking the output against the test goal (no set built).
    membership_contract_wrap_mode(M, Head, Mode,
        membership_contract:membership_contract_check_goal(M:Name/Arity, Out, TestGoal, Abstention)).

% -- membership_contract_enforce_producer(:Pred, +OutPos, :ProducerGoal, +Abstention, +Mode):
% The accessor producer contract WITH A MODE. Once mode commits the first solution; the
% producer still materialises the set (the convenience trade-off is unchanged from N11).
membership_contract_enforce_producer(M:Name/Arity, OutPos, ProducerGoal, Abstention, Mode) :-
    % The mode must be recognised.
    membership_contract_valid_mode(Mode),
    % Validate the predicate and output position and bind the output argument.
    membership_contract_out_head(M, Name, Arity, OutPos, membership_contract_enforce_producer/5, Head, Out),
    % Derive a readable label for the producer goal.
    membership_contract_goal_label(ProducerGoal, Label),
    % Record the accessor contract (producer form) in the goal registry and record its mode.
    retractall(membership_contract_goal_registry(M:Name/Arity, _, _, _, _)),
    assertz(membership_contract_goal_registry(M:Name/Arity, OutPos, producer, Label, Abstention)),
    membership_contract_record_mode(M:Name/Arity, Mode),
    % Install the wrapper for the requested mode, reusing the producer postcondition.
    membership_contract_wrap_mode(M, Head, Mode,
        membership_contract:membership_contract_check_producer(M:Name/Arity, Out, ProducerGoal, Abstention)).

% ---------------------------------------------------------------------------
% THE CONTEXT-AWARE ACCESSOR (WP-431, Wave 10 Stage 2) — legality may depend on a HELD CONTEXT, closing AMYGDALA-1.
% ---------------------------------------------------------------------------

% -- membership_contract_enforce_context(:Pred, +OutPos, :TestGoal, :ContextGoal, +Abstention, +Mode):
% The CONTEXT-AWARE accessor contract. Its membership-TEST goal receives TWO arguments — the committed
% output AND a HELD CONTEXT that ContextGoal produces at check time (for example the affective_state
% pack's derived regime) — so an output's legality may depend on a persisted modulatory context WITHOUT
% smuggling that context into the committed value (the amygdala's AMYGDALA-1 workaround). The full set is
% never materialised; the abstention always passes; a non-member-in-context is refused with the same
% glass-box membership_contract_goal_violation. Mode is per_solution or once, exactly as the other forms.
membership_contract_enforce_context(M:Name/Arity, OutPos, TestGoal, ContextGoal, Abstention, Mode) :-
    % The mode must be recognised.
    membership_contract_valid_mode(Mode),
    % Validate the predicate and output position and bind the output argument (shared accessor validation).
    membership_contract_out_head(M, Name, Arity, OutPos, membership_contract_enforce_context/6, Head, Out),
    % Derive a readable label for the test goal.
    membership_contract_goal_label(TestGoal, Label),
    % Record the accessor contract (context form) in the goal registry and record its mode.
    retractall(membership_contract_goal_registry(M:Name/Arity, _, _, _, _)),
    assertz(membership_contract_goal_registry(M:Name/Arity, OutPos, context, Label, Abstention)),
    membership_contract_record_mode(M:Name/Arity, Mode),
    % Install the wrapper for the requested mode, checking the output against the test goal IN its held context.
    membership_contract_wrap_mode(M, Head, Mode,
        membership_contract:membership_contract_check_context(M:Name/Arity, Out, TestGoal, ContextGoal, Abstention)).

% -- membership_contract_check_context(+Pred, +Out, :TestGoal, :ContextGoal, +Abstention): the context postcondition.
% Succeeds when Out is the abstention, or when the test goal accepts Out IN the held context ContextGoal reads;
% throws the glass-box violation otherwise. The context is read ONCE per check, at check time, from the held state.
membership_contract_check_context(_Pred, Out, _TestGoal, _ContextGoal, Abstention) :-
    % The declared abstention value always satisfies the contract, whatever the context.
    Out == Abstention,
    !.
membership_contract_check_context(_Pred, Out, TestGoal, ContextGoal, _Abstention) :-
    % Read the HELD context once (deterministically), then the output is legal exactly when the test goal accepts it in that context.
    once(call(ContextGoal, Context)),
    call(TestGoal, Out, Context),
    !.
membership_contract_check_context(Pred, Out, TestGoal, _ContextGoal, _Abstention) :-
    % An output illegal in its held context is REFUSED with a glass-box violation naming the goal.
    membership_contract_goal_label(TestGoal, Label),
    throw(error(membership_contract_goal_violation(Pred, Out, Label), membership_contract)).

% -- membership_contract_holds_context(+Out, :TestGoal, :ContextGoal, +Abstention): a boolean context check that never throws.
membership_contract_holds_context(Out, _TestGoal, _ContextGoal, Abstention) :-
    % The declared abstention satisfies the contract.
    Out == Abstention,
    !.
membership_contract_holds_context(Out, TestGoal, ContextGoal, _Abstention) :-
    % Otherwise read the held context and require the test goal to accept the output in it, deterministically.
    once(call(ContextGoal, Context)),
    once(call(TestGoal, Out, Context)).

% -- membership_contract_valid_mode(+Mode): succeed for a recognised mode, else throw a clear error.
membership_contract_valid_mode(Mode) :-
    % Accept exactly per_solution and once; anything else is a usage error.
    ( ( Mode == per_solution ; Mode == once )
    ->  true
    ;   throw(error(domain_error(membership_contract_mode, Mode), membership_contract)) ).

% -- membership_contract_record_mode(+Pred, +Mode): remember a contract's mode (only once needs a record).
membership_contract_record_mode(Pred, Mode) :-
    % Replace any prior mode record for this predicate.
    retractall(membership_contract_mode_registry(Pred, _)),
    % Record the once mode explicitly; per_solution is the default and needs no record.
    ( Mode == once
    ->  assertz(membership_contract_mode_registry(Pred, once))
    ;   true ).

% -- membership_contract_wrap_mode(+M, +Head, +Mode, +CheckGoal): install the postcondition wrapper for a mode.
% per_solution wraps as ( original, check ) — the check fires on every solution, exactly as the base forms.
% once wraps as once(( original, check )) — the original commits to its first solution, the check runs on that
% committed output exactly once, and the predicate is left DETERMINISTIC (no choice points for the contract).
membership_contract_wrap_mode(M, Head, per_solution, CheckGoal) :-
    % Per-solution: the base wrapper shape, unchanged in behaviour.
    wrap_predicate(M:Head, membership_contract, Closure, ( Closure, CheckGoal )).
membership_contract_wrap_mode(M, Head, once, CheckGoal) :-
    % Once: commit to the first solution and check that committed output a single time, deterministically.
    wrap_predicate(M:Head, membership_contract, Closure, once(( Closure, CheckGoal ))).

% -- membership_contract_declared_mode(?Pred, ?Mode): the mode (per_solution or once) a declared contract runs in.
membership_contract_declared_mode(Pred, once) :-
    % A predicate with a recorded once mode runs in once mode.
    membership_contract_mode_registry(Pred, once).
membership_contract_declared_mode(Pred, per_solution) :-
    % Any declared contract with no recorded once mode runs in the per-solution default.
    membership_contract_any_contract(Pred),
    \+ membership_contract_mode_registry(Pred, once).

% -- membership_contract_any_contract(?Pred): true when Pred has any declared contract (plain-list or accessor).
membership_contract_any_contract(Pred) :-
    % A plain-list registry entry counts.
    membership_contract_registry(Pred, _, _, _).
membership_contract_any_contract(Pred) :-
    % An accessor registry entry counts too.
    membership_contract_goal_registry(Pred, _, _, _, _).

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

% ===========================================================================
% REFINEMENTS  (Wave 10 Stage 9; additive — N13 contract purity, N15 filtering)
% ---------------------------------------------------------------------------
% N13 (contract purity). The contract calls the test goal on every call and trusts it
% to be cheap and side-effect-free; nothing enforced it. These two additive predicates
% give the Ledger's remedies: a DOUBLE-NEGATION-GUARDED call that runs the test goal so
% it cannot bind the output or leave a choice point (side-effect-safe and deterministic
% by construction), and a DETERMINISM check a pack can run in its own tests.
% N15 (filtering mode). The once mode commits to the FIRST solution and refuses it if a
% non-member, even when a LATER solution is a member. This adds a distinct find-member
% mode as a self-contained predicate — no general solution-selection framework — that
% commits to the first GENERATED candidate that IS a member.
% ===========================================================================

% -- membership_contract_holds_guarded(+Out, :TestGoal, +Abstention): purity-guarded test (N13).
% The abstention passes. Otherwise the test goal is run under double negation, so any
% binding it attempts on Out is discarded and it can leave no choice point: it can only
% decide member-or-not, never mutate the output.
membership_contract_holds_guarded(Out, _TestGoal, Abstention) :-
    % The declared abstention is always a legal output.
    Out == Abstention, !.
membership_contract_holds_guarded(Out, TestGoal, _Abstention) :-
    % Run the test goal side-effect-safely: double negation keeps no bindings, no choicepoint.
    \+ \+ call(TestGoal, Out).

% -- membership_contract_test_deterministic(:TestGoal, +Out): the determinism check (N13).
% Succeeds when the test goal has AT MOST ONE solution on Out (it is semidet), and fails
% when it is nondeterministic — a test goal a contract can trust to be cheap and single.
membership_contract_test_deterministic(TestGoal, Out) :-
    % Collect the solutions of the test goal on this fixed output.
    findall(solution, call(TestGoal, Out), Solutions),
    % A deterministic test yields no solution (a clean fail) or exactly one.
    ( Solutions == [] -> true ; Solutions = [_] ).

% -- membership_contract_find_member(:Generator, :TestGoal, +Abstention, -Member): filtering (N15).
% Run Generator (a goal that produces a candidate output on backtracking) and commit to
% the FIRST candidate that satisfies TestGoal — the find-first-member the once mode could
% not express. If no generated candidate is a member, unify Member with the abstention.
membership_contract_find_member(Generator, TestGoal, Abstention, Member) :-
    % Search the generated candidates for the first that passes the membership test.
    ( call(Generator, Candidate), \+ \+ call(TestGoal, Candidate)
    % Commit to that first member.
    ->  Member = Candidate
    % No candidate was a member: fall back to the declared abstention.
    ;   Member = Abstention ).
