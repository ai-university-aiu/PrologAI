# The membership contract (Ledger N8)

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
  one readable line.

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
unaffected, and the arbiter re-expression. It is separate from, and does not
alter, the L4 `layer-rule`, N6 `layer-binding`, mini-regression, or conformance
gates.

## Limits, stated honestly

- The offered set must be a single input argument that is a **proper list** at call
  time. A selector whose candidates live in an assoc, a goal's solutions, or a
  field inside a compound term must first project them into a list argument. That
  follow-on gap is recorded as Ledger entry N9.
- `wrap_predicate/4` runs the postcondition on **every** solution of a
  non-deterministic predicate. For a selector (deterministic, one answer) this is
  exactly right; a non-deterministic producer that yields one bad solution among
  many will throw mid-backtracking rather than filter. That scope note is recorded
  as Ledger entry N10. The construct is aimed at selectors.
