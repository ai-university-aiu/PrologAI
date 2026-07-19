# Affect and the context-aware membership contract (Wave 10 Stage 2, WP-430/WP-431)

Closes the Requirements Ledger's **AMYGDALA-1**: PrologAI now has a first-class,
persisted, modulatory affective state, and the membership contract can consult it.

## `affective_state` (WP-430, layer 0)

Holds ONE affective context — a dict of a `valence`, `salience`, `mood`, and
`cortisol` tone — that persists across calls (a module-scoped held state,
glass-box) and derives a **regime** (`baseline` or `stress`) later processing
reads. API: `affective_state_get/1`, `affective_state_set/1`,
`affective_state_regime/1` (a context goal), `affective_state_modulate/1`,
`affective_state_decay/0`, `affective_state_clear/0`,
`affective_state_baseline/1`. Base infrastructure: SWI-Prolog standard libraries
only; no stratum; touches no ARC state.

## The context-aware accessor (WP-431)

`membership_contract_enforce_context(:Pred, +OutPos, :TestGoal, :ContextGoal, +Abstention, +Mode)`
declares a contract whose membership-test goal is called with **two** arguments —
the committed **output** and a **held context** that `ContextGoal` produces at
check time. So an output's legality can depend on a persisted modulatory context
(a regime, a mood) **without** smuggling that context into the output value. It is
additive: the plain-list, accessor, and once forms are unchanged, and the context
form supports both `per_solution` and `once` modes.

```prolog
% legality depends on the HELD regime, read as a second argument (not carried in the value)
stage2_legal_appraisal(appraisal(V, S), Regime) :-
    number(S), S >= 0.0, S =< 1.0, stage2_valence_in_regime(Regime, V).
:- membership_contract_enforce_context(stage2_appraise/2, 2,
        stage2_legal_appraisal, affective_state_regime, no_appraisal, once).
```

Under a held stress regime, `appraisal(appetitive, 0.8)` (whose value carries no
regime) is refused; at baseline it passes — the amygdala's smuggled-regime
workaround is unnecessary.
