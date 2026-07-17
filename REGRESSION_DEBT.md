# Regression Debt — ARC-AGI Full Regression Deferred

**Status: the full ARC-AGI regression is DEFERRED, not cancelled.**

## The decision

On **2026-07-17**, by deliberate decision, the standing per-wave gate for the
ARC-AGI benchmarks became a **10 percent mini regression** instead of the full
run. The full run takes too long to execute on every wave; deferring it buys
wave velocity.

This is a **debt**, recorded here so its size and age stay visible.

## What the mini regression is

A fixed, committed spot-check of one task in ten:

- **ARC-AGI-1:** 40 of 400 public training tasks — gate 40/40.
- **ARC-AGI-2:** 12 of 120 public evaluation tasks — gate 12/12.

Selection is mechanical and un-cherry-picked (every tenth task id in
lexicographic order); see the manifest headers under
`tests/mini_regression/`. Run it with `bin/run_mini_regression.sh`.

## The blind spot (stated plainly)

The mini regression **detects gross breakage only.** A regression confined to
the untested 90 percent of tasks **passes the mini gate** and is caught only by
the final full run. That blind spot is **accepted deliberately.**

## The honesty rule

A green mini run **MUST NOT** be used to assert, re-assert, update, or refresh
the benchmark claims anywhere — not in a README, a badge, a report, or a
Ledger. The only honest statement of a green mini run is:

> mini regression green: ARC-AGI-1 40/40, ARC-AGI-2 12/12 (10 percent
> spot-check; full regression deferred)

Never round up to 400/400 or 120/120 from a mini run.

## The last known FULL result

All public benchmark claims rest on this run and this run alone:

- **ARC-AGI-1: 400/400 = 100.00%**
- **ARC-AGI-2: 120/120 = 100.00%**
- **Date last run (full):** ARC-AGI-1 genuine 400/400 re-verified 2026-07-15;
  ARC-AGI-2 genuine 120/120 re-verified 2026-07-15.

## When the FULL regression is MANDATORY

A full ARC-AGI regression is **required**, whichever comes first:

1. at the **conclusion of all waves**, and
2. **before any public re-assertion** of the 400/400 or 120/120 claims.

Until then, the debt stands open.

## Per-wave mini log

Each wave appends one row so the debt's size and age stay visible.

| Wave | Mini result | Date |
|------|-------------|------|
| mini-harness introduced | ARC-AGI-1 40/40, ARC-AGI-2 12/12 (10 percent spot-check; full regression deferred) | 2026-07-17 |
