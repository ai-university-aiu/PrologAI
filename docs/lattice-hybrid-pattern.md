# The Lattice Hybrid Pattern — stigmergy for state, notification for reactivity

*Every Connectome repository is built on this pattern. Read this before you wire
two actors together through the Lattice.*

---

## The principle in one breath

Two independent needs, met by two independent mechanisms that never touch:

- **Stigmergy for STATE.** Actors coordinate by reading and writing shared facts
  in the Lattice. They never address one another. An actor writes what it knows;
  another actor independently chooses to read it. Actor-to-actor references stay
  at **zero**, no matter how many actors join.
- **Notification for REACTIVITY.** A write into the Lattice *wakes* any reader
  that is awaiting a matching fact. Nobody polls, nobody spins a CPU. The write
  is the signal.

The bridge between the two is the whole pattern: coordination flows through the
environment (stigmergy), and a write triggers a wake-up (notification). You get
decoupling *and* responsiveness without choosing one over the other.

---

## Why this pattern exists (the evidence)

This is not a design chosen from taste. It is the honest end state of a spike
that built the same reentrant loop two ways and compared them. The spike is
frozen and read-only at `prologai-loops` (see its `RESULT.md`, answered
2026-07-17). Its findings, in plain terms:

- **Stigmergy wins on coupling and on the spirit of the strict layer rule.** It
  removes the upward reference *entirely*: a lower actor writes a number and
  names no one, so there is nothing for the layer rule to have to forgive. For a
  140-construct Connectome, "zero actor-to-actor references" is the property
  that survives scale.
- **The mailbox (direct addressing) wins on legibility and on fit.** You can
  read the return hop straight off the trace (`thalamus -> cortex`), and a
  mailbox maps cleanly onto the actors pack as it stands today. But it keeps the
  upward reference alive as a hard-coded address inside the lowest actor — the
  exact silent erosion the strict layer rule exists to prevent (Ledger **L5**).
- **The honest end state is the bridge, not a winner.** Pure stigmergy at scale
  means every actor polling, which undermines "survives 140 constructs" on
  performance even as it wins on coupling. So the recommendation is: keep
  stigmergy for state (the decoupled substrate) **and** add a Lattice-write →
  notification path for reactivity. Implement the reactive await as the bridge
  between the two arms rather than picking one wholesale.

That bridge is exactly what the Lattice affordances L1, L2, and L3 delivered,
and what the API below exposes.

---

## The API (exact arities)

All six predicates are exported from the base `lattice` module. None of them
loads the vector-embedding backend, so a coordination write never drags in the
similarity index.

| Predicate | Signature | What it does | When to use it |
|---|---|---|---|
| `lattice_put/4` | `+Nexus, +Relation, +Args, +Referents` | Write a coordination fact. Also **notifies** awaiting readers. | The normal stigmergic write: leave state in the environment. |
| `lattice_get/4` | `+Nexus, ?Relation, ?Args, ?Referents` | Peek — read a matching fact without removing it. | Read shared state without consuming it. |
| `lattice_take/4` | `+Nexus, ?Relation, ?Args, ?Referents` | Read **and remove** one matching fact. Also **notifies**. | A one-shot token that a single reader should consume. |
| `lattice_replace/4` | `+Nexus, +Relation, +Args, +Referents` | Keep exactly **one** fact per relation (overwrite). Also **notifies**. | A bounded blackboard cell — the latest value only (e.g. current phase). |
| `lattice_await/5` | `+Nexus, +Relation, +Timeout, -Args, -Referents` | Block with **no CPU** until a fact matching `Relation` exists, or until `Timeout` seconds elapse. Returns immediately if the fact is already present; fails on timeout. | Subscribe to a change instead of polling for it. |
| `lattice_notify/1` | `+Nexus` | Wake every reader awaiting on this nexus. | You rarely call this by hand — every `put`/`take`/`replace` already calls it. Use it only for a bespoke write path. |

A waiter registers itself *before* its first existence check, so a write that
lands in the gap between "start awaiting" and "first look" is never lost.

---

## A minimal worked example — reader awaits, writer writes, reader wakes

```prolog
% Open one shared coordination nexus (backend-free, no vector index).
lattice_open('locus://localhost/heartbeat', Nexus),

% READER: in its own thread, block until a 'ready' fact appears (up to 5 s).
% It awaits a PATTERN — the relation name 'ready' — never a writer's address.
thread_create(
    ( lattice_await(Nexus, ready, 5, Args, _Referents)
    ->  format("reader woke: ~w~n", [Args])   % prints: reader woke: [go]
    ;   format("reader timed out~n", []) ),
    _Reader, [detached(true)]),

% WRITER: a moment later, drop the fact into the Lattice.
% The write itself wakes the awaiting reader — no poll loop anywhere.
sleep(0.2),
lattice_put(Nexus, ready, [go], []).
```

The reader never learns who the writer is. It asked the environment for a
`ready` fact; the environment (via the write's notification) woke it the instant
one arrived.

---

## The rule that must not be lost

**A reader awaits a PATTERN, never an address.** In the example the reader awaits
the relation `ready`, not "the writer" and not any thread or actor identifier.
This is the single discipline that keeps actor-to-actor references at zero. The
moment a reader awaits a specific sender, you have re-introduced the coupling
(and the upward-reference hazard) that stigmergy was chosen to remove. Await the
*fact you need*, not the *actor that produces it*.

---

## The legibility cost — paid honestly, on purpose

Stigmergy buys decoupling by **hiding the return edge**. Because every actor's
input arrives from "the environment", a trace of a stigmergic loop reads
`lattice -> cortex` for *every* hop — the reentrant edge that closes the loop is
implicit. In the spike, reentry had to be *proved* from hop ordering and a lap
counter, not simply read off the trace. The mailbox arm, by contrast, printed
the closing hop directly.

This is a real trade. The pattern gives up some glass-box legibility — the
property PrologAI values most — in exchange for coupling that survives scale.
The debt is not free and it is not hidden: **repositories built on this pattern
MUST narrate their loops explicitly.** When you close a loop through the Lattice,
add the narration the trace can no longer give you — log which fact each actor
read, which it wrote, and why this hop follows the last. Pay the legibility debt
deliberately; do not let the decoupling quietly cost you the audit trail.

---

## See also

- [`docs/layer-rule.md`](layer-rule.md) — the strict layer rule this pattern
  lives under, and why demoting the reentrant edge out of the static import
  graph keeps the rule intact.
- `LEDGER.md` — Wave 1 entries **L1**, **L2**, **L3** (the affordances) and
  **L5** (the upward-reference hazard the mailbox arm carries).
- `prologai-loops/RESULT.md` — the frozen spike's verdict and full comparison
  (read-only; nothing may depend on it).
