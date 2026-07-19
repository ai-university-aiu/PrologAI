# The membership contract (Ledger N8; accessor form N11; once mode N14)

This construct lets a predicate declare that one of its **output** arguments must
be a **member** of one of its **input** arguments (a list) — or equal to a
declared **abstention** value — and enforces that as a **runtime postcondition**.
It closes the arbiter arm's finding ARBITER-1, promoting a safety property that
used to be hand-rolled into a first-class, declarable, glass-box-enforced one.

## Why it exists

The Wave 4 safety layer (`connectome-arbiter`) built a basal-ganglia action
selector with one non-negotiable invariant: it must never emit an action nobody
offered. Its output is always a **member of the offered candidate set**, or an
explicit **no-selection**. The arbiter proved that property holds — a 532-attempt
adversarial battery, zero escapes — but only **by hand**: a guard predicate, a
throwing emit step, and a standalone checker, with every output routed through
them by an author who remembered to.

That is fragile. A **second** selector, written later by someone without the
habit, would carry no protection at all, because PrologAI had no way to **say**
"the output of this predicate must be a member of this input set" and have the
system enforce it. The membership invariant is a behavioural **safety** property —
the same class of thing the strict layer rule (L4) and the layer-to-stratum
binding (N6) promoted from convention to a checked invariant, but about a value
produced at runtime rather than about the static dependency graph.

## Load-time versus runtime — the key difference from L4 and N6

L4 and N6 are **load-time** properties: whether a pack depends on a higher layer,
or whether a pack's layer contradicts its stratum ordinal, can be read off the
static graph before anything runs. Membership cannot. Whether an output is a
member of an input set depends on the **actual input** and the **actual output**
on a **given call**, so it can only be checked **when the predicate produces a
result**. That is why this construct is a **runtime postcondition**, not a linter:
it is the program's first invariant that is checked as code executes, not as code
loads.

## Declaring a contract

A predicate opts in with one declaration, naming the output argument position, the
input-set argument position, and the value that means "chose nothing":

```prolog
% A selector: argument 1 is the offered set, argument 3 is the chosen output.
region_action_select(_OfferedActions, Preference, Preference).

% Enforce the contract: argument 3 (output) must be a member of argument 1 (the
% offered set), or equal to the declared abstention no_selection.
:- membership_contract_enforce(region_action_select/3, 3, 1, no_selection).
```

After this declaration, every call to `region_action_select/3` is checked. The
predicate itself is unchanged; the contract is layered on top of it.

## What the contract does on each call

The construct wraps the predicate with SWI-Prolog's `wrap_predicate/4`, so on
**every solution** the postcondition runs and there are exactly three outcomes:

- the output is the declared **abstention** (`no_selection`) → **passes** (choosing
  nothing is always legal);
- the output is a **member** of the offered input set → **passes**;
- the output is **anything else** → **refused** with a glass-box error naming the
  predicate, the offending output, and the set it was not a member of.

The guarded predicate **cannot return a non-member**. A refusal looks like:

```
membership_contract violation: region_action_select/3 produced teleport, which is
not a member of the offered set [reach,grasp] (and is not the declared abstention)
```

rendered from the thrown term by `membership_contract_violation_line/2`.

## Opt-in — an unguarded predicate is unaffected

A predicate with **no** contract is **unguarded**, not violating: it behaves
exactly as it does today, with nothing checked. Nothing happens until a predicate
opts in with `membership_contract_enforce/4`. This is the same incremental-adoption
model L4 uses for undeclared layers and N6 for unbound packs: adding the construct
to a codebase changes nothing until a predicate declares a contract, and predicates
can be brought under contract one at a time.

## Membership-specific, not a framework

The construct is deliberately tight. It is about **membership** — an output is a
member of a named input set — not a general assertion framework, a contract DSL,
or a type system. It does one property well and glass-box.

## The arbiter's guard, re-expressed by declaration

The point of closing ARBITER-1 is that the arbiter's guarantee no longer needs to
be hand-rolled. A future selector obtains the arbiter's exact property — a
selection must be a member of the offered candidates, with an explicit no-selection
allowed — **purely by declaring the contract**, with no guard predicate, no
throwing emit, and no bespoke battery:

```prolog
region_action_select([reach, grasp, withdraw], withdraw, S).  % S = withdraw   (member — passes)
region_action_select([reach, grasp], no_selection, S).        % S = no_selection (abstention — passes)
region_action_select([reach, grasp], phantom, S).             % refused — glass-box violation
```

This is demonstrated PrologAI-side by the test `arbiter_guarantee_by_declaration`
in `packs/membership_contract/test/test_membership_contract.pl`. The frozen
`connectome-arbiter` repository is **not** touched by this construct.

## The public predicates (from `library(membership_contract)`)

- `membership_contract_enforce/4` — `:Pred, +OutPos, +InPos, +Abstention`: declare
  the contract on a predicate and wrap it so every call is checked.
- `membership_contract_check/4` — `+Pred, +Out, +In, +Abstention`: the pure
  postcondition — succeeds on a member or the abstention, throws the glass-box
  violation on a non-member.
- `membership_contract_holds/3` — `+Out, +In, +Abstention`: a **boolean**
  membership test that **never throws** (true for a member or the abstention,
  false otherwise).
- `membership_contract_declared/4` — `?Pred, ?OutPos, ?InPos, ?Abstention`:
  enumerate the declared contracts (introspection).
- `membership_contract_violation_line/2` — `+Error, -Line`: render a violation as
  one readable line (both the plain-list and the accessor form).

## The accessor form — membership against a goal-described set (Ledger N11, closes N9)

The plain-list form above reads the offered set from a **list argument**. But a
growing store — the Wave 6 memory region's stored-memory facts on the Lattice — is
**not** a plain list, and flattening it into one on every call is O(store size) per
call (recorded as N9, second-sighted as the memory region's HIPPO-1). The **accessor
form** lets a contract name the set by a **goal** instead of a list argument, so a
growing or streaming set can be guarded without materialising it.

**The test-goal form (primary — avoids materialisation).** You name a
semi-deterministic **membership-test goal**: a closure that, given a candidate
output appended as its last argument, **succeeds** if that candidate is in the set
and **fails** otherwise. For a recall over a fact store:

```prolog
% the membership-test goal — a single fact lookup, not a list build
stored_pattern_member(Pattern) :- stored_pattern(Pattern).

% recall's output (argument 2) must satisfy the test goal, or be the abstention no_recall
:- membership_contract_enforce_goal(store_recall/2, 2, stored_pattern_member, no_recall).
```

On every call the contract runs `call(stored_pattern_member, Out)` on the produced
output: a member passes, `no_recall` passes, and a non-member is **refused**. The
**full set is never built** — for a fact store this is a single lookup, not an
O(store size) copy. This is the form that retires HIPPO-1's cost, and it even guards
membership of an **infinite** set (for example the positive even integers) that no
list could hold.

**The producer form (convenience — still materialises).**
`membership_contract_enforce_producer/4` names a goal that **produces** the set as a
list; the contract then reuses the plain-list check. Because it builds the whole
list, it does **not** avoid the cost N9 named — so for a growing store, prefer the
test-goal form. It is offered only for a small set.

**The violation, when there is no list to print.** A test-goal refusal throws
`membership_contract_goal_violation(Pred, Out, GoalLabel)`, and
`membership_contract_violation_line/2` renders it naming the set **goal** rather than
a list — for example: *"…store_recall/2 produced [never,stored], which the
membership-test goal stored_pattern_member does not accept (it is not a member of the
set that goal defines, and is not the declared abstention)."* So "why did this call
fail?" still has a readable answer.

**Purity and adoption.** The test goal is called as a **pure membership test** (with
the candidate appended); the contract must not mutate the set, and the goal should be
cheap and non-destructive because it may run on every call. The accessor form is
**opt-in and additive** — the plain-list form is unchanged, and a predicate may use
either form or neither.

**The accessor predicates.**

- `membership_contract_enforce_goal/4` — `:Pred, +OutPos, :TestGoal, +Abstention`:
  declare the test-goal form (no materialisation).
- `membership_contract_enforce_producer/4` — `:Pred, +OutPos, :ProducerGoal,
  +Abstention`: declare the producer form (materialises; convenience).
- `membership_contract_check_goal/4` — `+Pred, +Out, :TestGoal, +Abstention`: the
  pure test-goal postcondition (succeed or throw).
- `membership_contract_holds_goal/3` — `+Out, :TestGoal, +Abstention`: a **boolean**
  test-goal check that **never throws**.
- `membership_contract_declared_goal/4` — `?Pred, ?OutPos, ?Form, ?Abstention`:
  enumerate accessor contracts (`Form` is `test` or `producer`).

## The once-deterministic mode (Ledger N14, closes N12 / N10)

By default the contract checks **every** solution the guarded predicate produces.
That is right for a predicate that yields one answer (the memory region's recall is
deterministic, so this "did not bite" there). But a predicate that **generates**
several candidates on backtracking and then **commits** one — a selector that
proposes, compares, and picks; a corrector that considers adjustments and emits one
— wants the guarantee on the **committed** answer, not a throw partway through its
backtracking. That was gap N12 (which subsumed N10).

**Once mode** provides it. The enforce entry points gain a mode-carrying `/5` form
with a trailing `+Mode` argument — `per_solution` (the unchanged default) or `once`:

```prolog
% a selector that proposes candidates on backtracking and commits the first (top) one
propose(_Allowed, Choice) :- member(Choice, [top, second, third]).

% guard the COMMITTED output: argument 2 must be a member of argument 1, once mode
:- membership_contract_enforce(propose/2, 2, 1, no_choice, once).
```

In once mode the guarded predicate **commits to its first solution**, that committed
output is checked for membership **exactly once**, and the predicate is left
**deterministic** (no choice points for the contract's sake). `propose([top, second,
third], C)` now returns `C = top` and **only** `top` — a `findall` yields
`[top]`, not `[top, second, third]`. A member passes, the declared abstention passes,
and a non-member is refused with the same glass-box violation as the base form.

**It commits honestly to the first solution.** If the first solution is a non-member,
once mode refuses it — *even if a later solution would have been a member*. Once mode
is for a predicate whose first answer **is** the committed answer (a selector that has
already chosen, a corrector that has already computed its adjustment). It is **not** a
find-the-first-member search over solutions; that is a different, larger feature and
is deliberately not built.

**Both forms, no materialisation.** Once mode is available to the plain-list form
(`membership_contract_enforce/5`) and to the accessor form
(`membership_contract_enforce_goal/5`, `membership_contract_enforce_producer/5`).
Once **plus** the test-goal accessor form still materialises **no set**: the
committed output is checked against the membership-test goal exactly once, with no
list built.

**The mode predicates.**

- `membership_contract_enforce/5` — `:Pred, +OutPos, +InPos, +Abstention, +Mode`:
  the plain-list form with a mode.
- `membership_contract_enforce_goal/5` — `:Pred, +OutPos, :TestGoal, +Abstention,
  +Mode`: the accessor test-goal form with a mode (no materialisation).
- `membership_contract_enforce_producer/5` — `:Pred, +OutPos, :ProducerGoal,
  +Abstention, +Mode`: the accessor producer form with a mode.
- `membership_contract_declared_mode/2` — `?Pred, ?Mode`: the mode (`per_solution`
  or `once`) a declared contract runs in.

Opt-in and additive: a contract declared **without** a mode (the `/4` entry points)
behaves exactly as before — per solution.

## Dependencies

The construct imports **only** SWI-Prolog standard libraries (`lists` for
`memberchk/2`, `prolog_wrap` for `wrap_predicate/4`). It depends on **nothing**
else — not the Lattice, not the actors pack, not any Causalontology pack, and not
the arbiter. It is a general language affordance usable by any pack that produces a
selection from a candidate set. Its manifest declares `layer(0)` and **no**
stratum, so it is unbound under N6 (a gap, never a violation) and has no intra-repo
layer edge.

## Continuous Integration

The construct is gated by the additive workflow
`.github/workflows/membership-contract.yml`, which runs the PLUnit suite
`packs/membership_contract/test/test_membership_contract.pl`. Because membership is
a runtime property, the suite **is** the gate: it exercises a member passing, the
abstention passing, a non-member being refused, an unguarded predicate being
unaffected, and the arbiter re-expression — and, since the accessor form, the
eleven accessor tests too (the test-goal member/abstention/non-member cases, the
no-materialisation proof, the infinite-set case, the producer form, and the
hippocampus re-expression), and the nine once-mode tests (commit-to-first
determinism, the per-solution default unchanged, non-member-first refusal, once
plus the accessor form with no materialisation, and the selector-like
re-expression). The workflow runs the whole suite file, so all twenty-nine tests —
the plain-list, accessor, and once-mode blocks — are gated together. It is
separate from, and does not alter, the L4 `layer-rule`, N6 `layer-binding`,
mini-regression, or conformance gates.

## Limits, stated honestly

- The **plain-list** form requires the offered set to be a single input argument
  that is a **proper list** at call time. That follow-on gap (N9) is now **closed**
  by the **accessor form** above (Ledger N11): a set that lives elsewhere — a store
  on the Lattice, a set of facts, a computed or infinite collection — is guarded by
  naming a membership-test goal, with no list ever built. The plain-list and
  test-goal forms are the supported set; the producer form is a materialising
  convenience, not the fix.
- `wrap_predicate/4` runs the postcondition on **every** solution of a
  non-deterministic predicate. For a selector (deterministic, one answer) this is
  exactly right; a non-deterministic producer that yields one bad solution among
  many will throw mid-backtracking rather than filter. That scope note is recorded
  as Ledger entry N10. The construct is aimed at selectors.
