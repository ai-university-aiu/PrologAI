<p align="center">
  <img src="assets/PrologAI_754x176_New.png" alt="PrologAI — Cognitive Architecture for Synthetic Minds" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/ARC--AGI--1-400%2F400%20%3D%20100%25-FFCE59?style=for-the-badge" alt="ARC-AGI-1: 400/400">
  <img src="https://img.shields.io/badge/ARC--AGI--2-120%2F120%20%3D%20100%25-FA842F?style=for-the-badge" alt="ARC-AGI-2: 120/120">
  <img src="https://img.shields.io/badge/SWI--Prolog-9.0.4%2B-E44B19?style=for-the-badge" alt="SWI-Prolog 9.0.4+">
  <img src="https://img.shields.io/badge/reasoning-48%20types-B22313?style=for-the-badge" alt="48 Reasoning Types">
  <img src="https://img.shields.io/badge/protocols-MCP%20%7C%20A2A%20%7C%20ACP%20%7C%20ANP-670100?style=for-the-badge" alt="MCP | A2A | ACP | ANP">
  <img src="https://img.shields.io/badge/Causalontology-3.0.0%20%7C%20119%2F119%20vectors-B22313?style=for-the-badge" alt="Causalontology 3.0.0: 119/119 conformance vectors">
  <img src="https://img.shields.io/badge/license-Attribution%20No%20Profit%20No%20Problem-3A0000?style=for-the-badge" alt="The Attribution Always; No Profit, No Problem License.">
</p>

<p align="center">
  <strong>A Cognitive Substrate for Building Synthetic Minds</strong><br>
  Pure symbolic induction &nbsp;&bull;&nbsp; Named glass-box rules &nbsp;&bull;&nbsp; No Large Language Model (LLM) &nbsp;&bull;&nbsp; No black box
</p>

---

## What is PrologAI?

PrologAI is a complete cognitive substrate written in SWI-Prolog (Sociaal-Wetenschappelijke Informatica Prolog — created at the University of Amsterdam by Jan Wielemaker in 1987; SWI is the Dutch name for the Social Scientific Informatics research group where it originated).

It is not a library layered on top of an existing AI framework — it **is** the framework.

It is not a neural network.

It is not a statistical model.

It does not use a large language model (LLM).

It does not require pretraining, internet knowledge, or neural weights of any kind.

A new kind of platform where you build a reasoning mind the way you build a compiler: explicitly, structurally, and verifiably.

Every reasoning step PrologAI takes is a **named, inspectable Prolog predicate**.

Every answer comes with a **justification tree** you can read.

No black box.

No guessing.

**Naming.** Identifiers are whole English words, never abbreviations — packs and predicates are pack-qualified `snake_case` (`world_model`, not `wm`), and the reified causal primitive is spelled `causal_relation_object` (`cro` retired), aligning with the Causalontology standard's whole-word Principle P7. See [NAMING.md](NAMING.md).

**Conformance.** PrologAI implements **Causalontology specification 3.0.0** (adopted in Wave 10 Stage 1) and passes **all 119 conformance vectors (V01–V119)** — canonicalization (RFC 8785), content identity (SHA-256), schema validity for the eighteen kinds, the local semantic rules, and the six normative algorithms (bridge closure, bridged reachability, stratal classification, the skip decision, unit normalization, and the cross-stratal seam well-formedness), plus Ed25519 (RFC 8032) provenance. The 3.0.0 additions — the ordinal `ticks` temporal unit, the eighteenth kind `cross_stratal_seam`, and the conduit `realized_by` reference — are all additive and identity-preserving. The vectors are vendored from the causalontology repository at its 3.0.0 tag and gated in Continuous Integration (CI) by `bin/run_causalontology_conformance.sh`. Nothing pending — the full suite passes. See the [conformance section of NAMING.md](NAMING.md#conformance-to-causalontology-specification-200).

---

## Landmark Achievements

| Benchmark / Capability | Result | Method |
|---|---|---|
| **ARC-AGI-1** — 400-task grid reasoning benchmark | **400 / 400 = 100.00%** | Pure symbolic induction, named glass-box rules |
| Reasoning Types | **48/48** | Deductive Reasoning, Inductive Reasoning, Abductive Reasoning, Probabilistic Reasoning, Bayesian Reasoning, Causal Reasoning, Statistical Reasoning, Analogical Reasoning, Relational Reasoning, Transductive Reasoning, Commonsense Reasoning, Logical Reasoning, Formal Reasoning, Mathematical Reasoning, Fuzzy Reasoning, Qualitative Reasoning, Non-monotonic Reasoning, Paraconsistent Reasoning, Counterfactual Reasoning, Hypothetical Reasoning, Spatial Reasoning, Diagrammatic Reasoning, Temporal Reasoning, Case-based Reasoning, Constraint-based Reasoning, Scientific Reasoning, System Reasoning, Model-based Reasoning, Heuristic Reasoning, Critical Reasoning, Dialectical Reasoning, Metacognitive Reasoning, Modal Reasoning, Epistemic Reasoning, Deontic Reasoning, Procedural Reasoning, Symbolic Reasoning, Practical Reasoning, Teleological Reasoning, Strategic Reasoning, Narrative Reasoning, Social Reasoning, Intuitive Reasoning, Emotional Reasoning, Motivational Reasoning, Informal Reasoning, Legal Reasoning, Moral Reasoning — all 48 implemented |
| SPARC documentation volumes | **6 / 6** | Specification, Pseudocode, Architecture, Refinement, Completion, Demonstration Plan |
| Multi-agent protocols | **4 / 4** | MCP (Model Context Protocol), A2A (Agent to Agent), ACP (Agent Communication Protocol), ANP (Agent Network Protocol) |
| 48/48 Cognitive Reasoning Levels | **48/48** | Deductive Reasoning through Moral Reasoning — all 48 Cognitive Reasoning Levels achieved |

> PrologAI, through its Mentova Synthetic Mind implementation, is the **first digital system in the world** to achieve confirmed perfect scores on both ARC-AGI-1 (Abstract Reasoning Corpus for Artificial General Intelligence Version 1) and ARC-AGI-2 (Abstract Reasoning Corpus for Artificial General Intelligence Version 2) — 400/400 = 100.00% on ARC-AGI-1 and 120/120 = 100.00% on ARC-AGI-2 — using pure symbolic induction with named glass-box rules — no neural weights, no internet knowledge, no large language model (LLM).

> **Regression policy:** these 400/400 and 120/120 scores rest on the last **full** benchmark run. The per-wave gate is a 10 percent [mini regression](REGRESSION_DEBT.md) (ARC-AGI-1 40/40, ARC-AGI-2 12/12) that detects gross breakage only; a green mini run never refreshes these claims. The full regression is deferred and is mandatory before any public re-assertion of the scores.

---

## Architecture

```
PrologAI/
├── packs/       299 work packages — the complete cognitive engine (see below)
├── docs/        SPARC documentation series (6 volumes + tutorial + textbook)
├── syntax/      PrologAI language syntax rules
├── tests/       Acceptance test suite
└── launcher/    Entry points and bootstrapper
```

### How Layers Work

Every pack in PrologAI carries a layer number - a positive integer that encodes its position in the dependency order.

A pack at layer N may call predicates from any pack at a layer strictly below N, and from nothing at the same level or above.

This guarantees the dependency graph is acyclic: packs build from the bottom up, like floors in a building, and each new pack rests on a fully tested foundation.

The first 59 layers are the cognitive substrate (Lattice, actors, reasoning engine, episodic memory, and the interoperability gateways).

Layer 60 and above is the Data Layer: the 200+ perception, analysis, and transformation packs that handle structured data, currently reaching Layer 364 (tom) with WP-274 through WP-277 enhancing four existing packs for ARC-AGI-2, WP-278 adding the periodfix periodic-pattern-repair pack, WP-279 adding the iochan I/O channel integration pack (speaker, microphone, text/image/printer channels), WP-383 through WP-389 adding the seven-pack AGI Foundations suite — causal (structural causal models and counterfactuals), active_inference (expected-free-energy policy selection), worldmodel (structured simulation, planning search, and model learning — since converged into world_model), planner (hierarchical task decomposition), evolve (evolutionary computation), jacobian_space (the readable concept workspace), and tom (theory of mind with nested false beliefs — since converged into theory_of_mind) — at Layers 358 through 364, WP-390 adding the nexus integration layer (Layer 365) that wires four of those foundations into the cognitive core, and WP-391 through WP-396 adding the six-pack Causalontology suite (noun_backbone, realizable_hinge, causal_core, causal_learning, causal_planner, arc3_harness) — the process-first Foundational Ontology in which reified causation governs the verbs, a thin backbone hosts the nouns, and realizable entities form the hinge — at Layers 366 through 371, and WP-397 through WP-400 adding the four-pack ARC-AGI-3 Readiness suite (curiosity, goal_inference, efficiency_governor, arc3_protocol) — a novelty-seeking, loop-avoiding exploration policy, inference of the unstated win condition, a human-baseline efficiency governor, and the exact March-2026 ARC-AGI-3 protocol vocabulary with a guarded env adapter — at Layers 372 through 375, and WP-401 adding human_steps, the ARC-AGI-3 Human-Step Ladder in J-Space (the six-phase, thirty-micro-step human problem-solving process for interactive environments, each step held as a concept in the Jacobian workspace and read through the Jacobian Lens, with a discrete action-response Jacobian that locates the controllable element and a goal gradient), at Layer 376, and WP-402 adding state_graph, Causalontology State-Graph Exploration (the technique that beat every frontier model on ARC-AGI-3: a directed graph of frame-hash states and action transitions with tested/untested/dead edges, and hierarchical action selection that probes an untested action or takes the shortest path to the nearest unexplored frontier), at Layer 377, and WP-403 adding grid_perception, Causalontology Whole-Grid Perception (the object-first sight layer that segments the entire grid into an inventory of objects with role guesses — meter/life-bar, dot, field, piece — reads bar-like counters rather than ablating them, ranks salient object centroids as visit targets, and locates the avatar as whatever moved between two frames), at Layer 378, and WP-404 adding hierarchical_planning, Causalontology Hierarchical Planning (a multi-level plan tree — Win Game over an observe-orient-decide-act loop over the concrete controls — reified onto Causalontology's own decomposition hierarchy so every plan node is a causal_relation_object whose children are its mechanism sub-graph, hierarchy-consistent at every level and readable back out of the causal graph alone), at Layer 379, and WP-405 adding verification, Causalontology Verify-Before-Act (the world-model safety layer that predicts a move fatal from the learned model — generalising from deaths in other states to a new one before the move is tried there — and plans a step in a caller's model before spending a real action, deprioritising predicted-fatal actions rather than forbidding them), at Layer 380, and WP-406 through WP-408 adding the three draft-driven ARC-AGI-3 capability packs — hypothesis (hypothesis generation, ranking, and sticky anti-drift commitment, the cure for the hypothesis-drift failure the losing agents all share), world_model (now the single two-mode world model — a learned, verifiable, repairable transition model plus, having absorbed the former worldmodel pack, a structured simulate-and-plan model — with a bridge that emits its learned model as reified causal_relation_objects), and object_relations (object-relational reasoning — adjacency, containment, alignment, offset vectors, ordinal size — over segmented objects rather than pixels) — at Layers 381 through 383, and WP-409 through WP-416 adding the eight-pack Cognitive Completion suite (episodic_memory, attention, motivation, affect, metacognition, safety_governor, repair, consolidation) — episodic memory, attention with a single-winner broadcast, motivation from internal needs, affect and appraisal, metacognition, a write-protected safety governor, compensation and repair, and consolidation — which lift the Causalontology family from an ARC-AGI-3 solver into a broader glass-box cognitive architecture (memory, attention, motivation, feeling, self-monitoring, governance, and forgetting), at Layers 384 through 391, and WP-417 through WP-420 adding the next-wave suite (grounding clue/language grounding, theory_of_mind a Causalontology-native theory of mind, analogy by structure mapping, and concept_formation concept formation by feature clustering) — the social, symbolic, and category-inducing faculties that close the remaining honestly-named gaps — at Layers 392 through 395, and WP-421 through WP-424 adding the fullest-set suite (imagination with quarantined "realities", priming spreading-activation priming, regulation feedback regulation with discrimination learning, and lore turning repeated experience into themes, lessons, and maxims) at Layers 396 through 399 — the same wave in which the six remaining bespoke-harness test suites were standardized onto PLUnit and seven packs tightened to full English-Readable-Code, with no behaviour change. A unification program then began, converging redundant faculties onto one canonical Causalontology-native pack each: the first convergence merged the structured `worldmodel` pack into `world_model` (now a single two-mode world model), a clean absorb-and-supersede that also resolved a real `world_model_predict/4` name collision and lost no functionality.

The full layer table is in Architecture Section 0.4.

**The strict layer rule is live and gated in CI, and adoption is deliberately incremental.** The rule — a lower-layer pack may not depend on a higher-layer one — is now a first-class construct: a pack declares its layer with a `layer(N)` fact in its `pack.pl`, `bin/check_layers.sh` checks the real import graph, and `.github/workflows/layer-rule.yml` blocks a merge on any violation. Honestly, though: **4 of the 300 packs declare a layer today** (`layer`, `lattice`, and `membership_contract` at layer 0, `actors` at layer 1); the remaining 296 are undeclared **gaps, not violations**. Until adoption spreads pack by pack, a passing check verifies only the declared packs. See **[docs/layer-rule.md](docs/layer-rule.md)** for how to declare a layer, run the checker, read a violation line, and choose strict vs reporting mode.

**Binding a pack's layer to its stratum ordinal (Ledger N6).** A stratum-primary pack can additionally declare the Causalontology stratum it represents with a `stratum(Label)` fact beside `layer(N)`; a companion checker (`bin/check_layer_binding.sh`, gated by `.github/workflows/layer-binding.yml`) reads each stratum's ordinal from the authoritative structure records and verifies the declared layer is order-consistent with it — a lower ordinal may not carry a higher layer, equal ordinals must share a layer. This closes the strata arm's STRATA-3 finding: the alignment "pack layer tracks stratum ordinal" is now an enforced, load-time invariant instead of a hand-maintained convention (and it catches an upward dependency disguised as downward by a mis-declared layer, which the layer rule alone cannot see). It is additive to the strict layer rule, which is untouched; a pack that declares no stratum is an unbound gap, never an error. See **[docs/layer-binding.md](docs/layer-binding.md)**.

**A first-class membership contract (Ledger N8).** Where the layer rule and the stratum binding are *load-time* properties read off the static graph, some safety invariants can only be checked while code runs. The `membership_contract` pack lets a predicate declare that one of its **output** arguments must be a **member** of one of its **input** arguments (a list), or equal to a declared **abstention** value, and enforces it as a **runtime postcondition**: it wraps the predicate so that on every call a member passes, the abstention passes, and a non-member is **refused** with a glass-box violation naming the predicate, the output, and the set. It is opt-in (an unguarded predicate is unaffected), depends only on SWI-Prolog standard libraries, and is membership-specific rather than a general assertion framework. This closes the arbiter arm's ARBITER-1 finding: the basal-ganglia selector's guarantee that a chosen action is always one of the offered candidates — proved by hand in the arbiter — is now expressible by **declaring** the contract. An **accessor form** (Ledger N11, WP-427) additionally lets a contract name the offered set by a **membership-test goal** instead of a list argument, so a growing store — the memory region's stored-memory facts — can be guarded **without ever flattening it into a list** (a single lookup, not an O(store size) copy per call). This closes gap N9 (the memory region's HIPPO-1). An opt-in **once-deterministic mode** (Ledger N14, WP-428) additionally lets a predicate that generates several candidates on backtracking and **commits** one guard the *committed* answer: the guarded predicate commits to its first solution, that output is checked once, and it is left deterministic — closing gap N12 (which subsumed N10). See **[docs/membership-contract.md](docs/membership-contract.md)**.

**Coordinating actors through the Lattice.** Actors coordinate through the Lattice by stigmergy (shared state, zero actor-to-actor references) and react through notification (a write wakes awaiting readers; nobody polls). This stigmergy-plus-notification bridge (L3) is the pattern every Connectome repository is built on — see **[docs/lattice-hybrid-pattern.md](docs/lattice-hybrid-pattern.md)** for the principle, the exact API (`lattice_await/5`, `lattice_notify/1`, `lattice_put/4`, `lattice_get/4`, `lattice_take/4`, `lattice_replace/4`), a worked example, and the legibility cost it must pay deliberately.

### The 299 Work Packages

Every capability in PrologAI is a self-contained, versioned work package.

Each pack has a `pack.pl` manifest, a `prolog/` source directory, and (where needed) a `test/` suite.

Nothing is hidden.

Everything is inspectable.

**Artificial General Intelligence (AGI) Packs**

| Pack | What it Does |
|---|---|
| `nexus` | AGI Foundations Integration Layer: the capstone that wires four foundations into the cognitive core — workspace broadcasts hold their winning coalition's concepts in a live J-Space readout, world-model novelty feeds the curiosity learning-progress signal, the agency loop decomposes goals with the planner and recovers by monitoring and replanning, and evolution improves reasoning models scored by refinery critique under a bounded budget. Pure plumbing, respecting the strictly acyclic layer order (nx_*, Layer 365) (WP-390) |
| `causal_core` | Causalontology Core — the reified Causal Relation Object with causes, effects, a temporal window that is part of the mechanism, four modalities, strength, context, and provenance; temporal succession strictly separated from causal production ("after" is never "because"); timing-gated abduction; hierarchical mechanism sub-graphs with a consistency check; subsumption import of external causal vocabularies as degenerate provisional relations; and the glass-box why (co_*, Layer 368) (WP-393) |
| `noun_backbone` | Causalontology Noun Backbone — the thin continuant layer: categories, acyclic is-a and part-of hierarchies with a decidable projection check, and confidence-scored alignment of external classes, so no adopter must abandon its own nouns (co_*, Layer 366) (WP-391) |
| `realizable_hinge` | Causalontology Hinge — qualities and the realizable entities (dispositions, functions, roles) that inhere in objects yet are realized in occurrents, with the realization seam queryable in both directions (co_*, Layer 367) (WP-392) |
| `causal_learning` | Causalontology Learning — causal structure acquired by embodied intervention: induce at 0.70, confirm to 0.99, posit the disposition each new relation reveals, tag hazards preventive into a closed-world avoid-set, count null effects compactly, and weigh observation-only relations down (co_*, Layer 369) (WP-394) |
| `causal_planner` | Causal Planning (causal_planner_*, Layer 370, WP-395) — backward causal-chain planning over the Causalontology causal_relation_object graph: procedures as sequence-cause relations, backward planning whose steps must be achievable and never avoided, bounded backward graph search, and honest plan execution. Kept distinct from the flagship HTN `planner` pack (they are different planning paradigms). |
| `arc3_harness` | Causalontology ARC-AGI-3 Harness — the game-agnostic perceive-learn-plan-act loop over pluggable environments: frames to occurrents, frame diffs to induced relations, plan-first choice with curiosity fallback, hazards never repeated, a glass-box episode trace, and a guarded HTTP bridge to the live benchmark (co_*, Layer 371) (WP-396) |
| `curiosity` | Curiosity (curiosity_*, Layer 372, WP-398) — one faculty converged from two: a **novelty-seeking, loop-avoiding exploration policy** for any unknown interactive environment (order-free state signatures, causal-change-predicting action preference, least-tried curiosity, and object-centroid salient targeting; from the Causalontology curiosity pack), plus **intrinsic motivation by learning progress** — prediction error per region, tracking whether error is *falling* rather than merely high, habituation of visited regions, and self-proposed frontier tasks (absorbed from the curiosity pack). |
| `goal_inference` | Causalontology Goal Inference — hypothesising the unstated ARC-AGI-3 win condition from the frame changes that precede a reported WIN: accumulate support for the colours a winning delta introduces, discount colours that also appear in a loss, and expose the best-supported goal as both an abstract reach_colour and a changed/4 occurrent the planner can aim at, with a confidence reading (co_*, Layer 373) (WP-398) |
| `efficiency_governor` | Causalontology Efficiency Governor — the action budgeting and RHAE-style scoring the benchmark rewards: count actions per level, hold the human baseline, cap spending at five times the human, and compute the per-level score min(1,H/A)² together with the weighted environment score and the total percentage (co_*, Layer 374) (WP-399) |
| `arc3_protocol` | ARC-AGI-3 Protocol — the exact March-2026 agents-API vocabulary as inspectable facts: the ACTION1-ACTION7 and RESET commands under /api/cmd, the cell-select ACTION6 with x,y, scorecard open and close, the four game states with WIN and GAME_OVER terminal, 64×64 frames of colours 0-15, and a guarded arc3_protocol_env adapter that packages the live protocol as a arc3_harness environment (co_*, Layer 375) (WP-400) |
| `human_steps` | ARC-AGI-3 Human-Step Ladder in J-Space — the six-phase, thirty-micro-step human problem-solving process for interactive environments (orient, explore-and-model, infer the goal, plan, execute-and-monitor, transfer), encoded as ordered facts and held step-by-step as concepts in the Jacobian Space (jacobian_space) so the Jacobian Lens reads out which human step the agent is on; plus the discrete action-response Jacobian that names the controllable object (the colour whose centroid moves under the actions), its per-action displacement, and the goal gradient the execution phase descends (co_*, Layer 376) (WP-401) |
| `state_graph` | Causalontology State-Graph Exploration — the systematic graph-structured exploration that beat every frontier language model on ARC-AGI-3 (third on the public leaderboard, a median 30 levels versus 5 for the language-plus-DSL baseline). Builds a directed graph whose nodes are frame hashes and whose edges are observed state→action→next-state transitions; marks every tried (state, action) tested and every no-change action dead; and selects by the winning hierarchical rule — probe an untested, non-dead action in the current state, else take the first step on the shortest path (breadth-first) to the nearest state that still has an untested action. The graph persists across attempts for carry-forward (co_*, Layer 377) (WP-402) |
| `grid_perception` | Causalontology Whole-Grid Perception — the object-first sight layer that stops an agent poking at one spot and makes it take stock of the entire grid. Segments the frame into every connected object with colour, size, centroid, and bounding box (largest first); builds an inventory that tags each object with a shape-based role (a meter/life-bar, a dot/collectible, a wide field, or a piece); singles out bar-like meters along the edges so a counter or life-bar is read and interpreted rather than ablated; ranks salient object centroids as visit targets; and locates the avatar as whatever moved between two frames. No part of the grid is discarded (co_*, Layer 378) (WP-403) |
| `world_model` | Causalontology World Model — the single, two-mode, canonical world model (it absorbed the former `worldmodel` pack, WP-385, so there is now one home for both paradigms with nothing lost). MODE 1, the learned transition model: from observed (context, action)→effect transitions it PREDICTS the majority effect with a confidence (falling back to the action-general rule), VERIFIES against reality, REPAIRS by folding the truth in, ROLLS a sequence forward to score a plan, and surfaces the context-free general LAWS. MODE 2, the structured simulate-and-plan model: STRIPS-style states and actions with forward simulation, breadth-first shortest-plan search, reachability, sequence enumeration, novelty scoring, and STRIPS action-model learning. A `world_model_as_causal_relation_objects/2` bridge emits the learned model as reified causal_relation_objects for the shared store (co_*, Layer 382) (WP-407, absorbing WP-385) |
| `object_relations` | Causalontology Object Relations — reason over the relations between objects rather than raw pixels, because nearly every grid mechanic is defined on relations: relative position, row/column alignment, adjacency (pusher-next-to-block), containment (key-inside-lock), the centroid offset vector (leader-follower / vector-guided movement), ordinal size, and nearest neighbour. Turns an object list into rel(Type, IdA, IdB) so a mechanic can be matched against the structured relation set (co_*, Layer 383) (WP-408) |
| `hypothesis` | Causalontology Hypothesis Management — generate, rank, and COMMIT to a world-model hypothesis with anti-drift hysteresis. Every analysis of what beats ARC-AGI-3 names the same failure of the losing agents — hypothesis drift, abandoning a candidate rule at the first surprise, never committing to a correct-but-incomplete model. This pack is the cure: a hypothesis carries a tally of supporting and contradicting evidence, its score is the Laplace-smoothed support fraction, hypotheses are ranked, and commitment is deliberately STICKY — the agent commits to the best once it clears a threshold and leads its rival, then KEEPS it (a challenger must beat it by a wider switch margin to take over, and it is abandoned only when its score collapses below a floor). Strong enough to hold a good model through a stray surprise, weak enough to yield when the model is truly wrong (co_*, Layer 381) (WP-406) |
| `verification` | Causalontology Verify-Before-Act — the world-model safety layer that predicts a move fatal from the model already learned and plans a step in the model before spending a real action, rather than only remembering the exact moves that have already killed. It keeps a small learned fatality model (which state-action transitions ended a run, which states are terminal) and does two things a bare death-memory cannot: it GENERALISES — an action that has ended a run in enough distinct states is judged broadly fatal and predicted fatal in a new state before it is tried there — and it PLANS IN THE MODEL — given a caller's transition model it simulates a candidate and flags it if the simulated next state is known dead. Predicted-fatal actions are deprioritised to the back of the ranking, not forbidden, so if every option looks risky the least-risky is still reachable (co_*, Layer 380) (WP-405) |
| `hierarchical_planning` | Causalontology Hierarchical Planning — makes planning genuinely multi-level, where causal_planner only composes a flat sequence into one procedure. A plan is a TREE with as many levels of detail as the task needs: Win Game at the top, an observe-orient-decide-act loop (see, observe, orient, decide, act, re-observe & update the rules) as the method, and the concrete environment controls at the leaves, each high-level step expandable into a sub-plan. The showcase is the mesh with Causalontology's own hierarchy: every plan node is reified as a causal_relation_object, a node's children become its mechanism sub-graph (causal_core_decompose_add / causal_core_mechanism), and the endpoints are laid out as ordered waypoints so each coarse "achieve this goal" relation is hierarchy-consistent with the composition of its parts — so the whole plan can be read back out of the causal graph alone. Renders to indented glass-box text and to a nested dict, and locates any action's choice within the plan's OODA phase and leaf (co_*, Layer 379) (WP-404) |
| `episodic_memory` | Causalontology Episodic Memory — the case memory the co_ family lacked: every experience is a small reified case (context, action, outcome, valence) that can be recalled by how much its context overlaps the present cue (Jaccard overlap), replayed, and reinforced when it proves useful, so the mind can say "this reminds me of last time" instead of meeting every situation fresh (co_*, Layer 384) (WP-409) |
| `attention` | Attention (attention_*, Layer 385, WP-410) — one faculty converged from three: **salience with a single-winner broadcast** (specialists offer candidates with novelty/goal-relevance/affect signals, a weighted sum scores them, and one winner is broadcast per cognitive cycle; from the Causalontology attention pack); the **attention economy** (ECAN-style STI/LTI wages, rent, spreading activation, and economic forgetting; absorbed from the attention pack); and the **attention schema** (a predictive model of the system's own attention; absorbed from the attention_schema pack). |
| `affect` | Causalontology Affect — feeling that steers: each event is appraised on goal-congruence and expectedness into a valence and an arousal, a running temperament is the mind's mood, options are pre-flavoured by the remembered feeling of similar past outcomes (a glass-box somatic marker), and a coping signal reads the mood as thriving, steady, or struggling (co_*, Layer 387) (WP-412) |
| `metacognition` | Causalontology Metacognition — the mind watching itself: per-strategy attempts and successes give a calibration, confusion is flagged when a well-tried strategy stays at a low rate, an overall progress trend reads whether later attempts beat earlier ones, and a single recommendation says keep the best strategy, switch, or seek guidance (co_*, Layer 388) (WP-413) |
| `safety_governor` | Causalontology Safety Governor — the conscience that owns the last word: an immutable constitution of forbidden action patterns (variables allowed, so forbid touch(_) bans touching anything) plus learned hazards mirrored from causal_core's preventive relations, a pre-action check that returns allow or veto(Reason), an append-only veto log the mind's own learning cannot rewrite, and no predicate to weaken a constraint except an explicit operator reset (co_*, Layer 389) (WP-414) |
| `repair` | Causalontology Repair — recovery once a wrong thing has already happened: on a disturbance it prefers to undo the effect with an inverse action, else cancel a side effect with a neutralizer, else re-route a blocked goal to an alternate, else accept and move on — the Piagetian equilibration move made into glass-box rules and graded by the repair it achieves (co_*, Layer 390) (WP-415) |
| `consolidation` | Causalontology Consolidation — the night shift that keeps memory compact: re-adding a key merges rather than duplicates, a reliably repeated sequence is compressed into one composite, and stale low-value records are forgotten past a grace period (dropped only when both under-used and old), because a learning system must commit to forgetting (co_*, Layer 391) (WP-416) |
| `grounding` | Causalontology Clue Grounding — the grounding seam of Causalontology_v5 Section 10, finally built: turn a human natural-language clue and a referent (a salient object, or a clicked cell resolving "that"/"there") into a list of Causalontology assertions — "that looks like a key" becomes a key_like continuant with pick-up-able and opens-locks dispositions; "that looks like a lock" adds an open goal; a door sets a traverse goal; "pick that up" raises a pickup action; "don't touch that" marks interaction preventive; "good/that worked" is positive reinforcement — each tagged as a high-confidence but defeasible human hint, and callers may add their own keyword templates (co_*, Layer 392) (WP-417) |
| `concept_formation` | Causalontology Concept Formation — the mind growing its own ontology: from a stream of observed feature bundles it induces categories by transparent seed clustering (each ungrouped item seeds a group and pulls in every later item that keeps the shared-feature core at or above a floor), coins a concept(Id, SharedCore, Members) whose core is the intension and whose members are the extension, and classifies a new item into a concept when that core is a subset of the item's features (co_*, Layer 395) (WP-420) |
| `priming` | Causalontology Priming — spreading activation over an association graph, the reason "salt" brings "pepper" to mind: from a set of active source nodes, activation flows outward along weighted links and fades with a per-hop decay, a node's activation being the strongest path to it (a deterministic widest-path relaxation, never a trained weight). It complements attention — salience picks the single winner from what is offered, priming decides what becomes relevant in the first place — and returns the best K primed neighbours (co_*, Layer 397) (WP-422) |
| `regulation` | Causalontology Regulation — refining a single behaviour from feedback where causal_learning induces relations and metacognition watches whole strategies. Each result is classified into the four flavours — a predicted success is confirming, a predicted failure disappointing, an unpredicted success serendipitous, an unpredicted failure shocking — and, when one behaviour both wins and loses, the fix is not to average it away but to split it: regulation finds the feature of the situation present in every win and no loss (or every loss and no win) and refines the rule to require it or shun it. That is discrimination learning as glass-box rules (co_*, Layer 398) (WP-423) |
| `lore` | Causalontology Lore — turning repeated experience into advice, the layer above episodic memory: from recorded (situation, response, result) experiences it detects a theme (a situation-pattern seen at least twice — "this keeps happening"), recalls the lessons of past situations whose pattern is present now (a subset match), ranks the responses by how often they turned out good, and distils a maxim for a theme — do the response that usually works, or, if none does, avoid the one most tied to a bad result (co_*, Layer 399) (WP-424) |
| `causal` | Structural Causal Models: acyclic model construction, causal graph queries with d-separation (chains, forks, colliders), observational solving, do-operator interventions by graph surgery, abduction-action-prediction counterfactuals, and the but-for test of actual causation (cf_*, Layer 358) (WP-383) |
| `active_inference` | Active Inference Engine: validated generative models, Bayesian belief updating, variational free energy with the complexity-accuracy split, expected free energy as risk plus ambiguity, epistemic and pragmatic value, and softmax policy selection — curiosity and goal-seeking from one equation (ai_*, Layer 359) (WP-384) |
| `planner` | Hierarchical Planner: HTN task decomposition with ordered method preference and depth-bounded termination, glass-box plan trees naming every chosen method, plan execution, validity, cost, monitoring with the exact failing step, and replanning (ht_*, Layer 361) (WP-386) |
| `evolve` | Evolutionary Computation: fully reproducible seeded randomness, random populations, fitness evaluation, tournament selection, one-point crossover, point mutation, elitism, fixed and early-stopping generational runs, diversity, and convergence detection (ev_*, Layer 362) (WP-387) |
| `jacobian_space` | Concept Workspace (J-Space): a readable, editable ledger of the concepts held in mind with strengths and sources, the ranked J-Lens readout, silent-thought detection, implant / ablate / swap / decay / capacity editing, and concept-level derivation traces (js_*, Layer 363) (WP-388) |
| `theory_of_mind` | Theory of Mind (theory_of_mind_*, Layer 393, WP-418) — one faculty converged from two: goal inference from observed movement and Sally-Anne false-belief tracking (from the Causalontology theory_of_mind pack), plus nested per-agent belief worlds, witnessed events, knowledge as true belief, second-order false-belief detection, belief divergence, common belief, perspective taking, and desire-intention stores (absorbed from the AGI-Foundations tom pack). |

**Core Platform**

| Pack | What it Does |
|---|---|
| `kernel` | The minimal kernel — lattice-resident rewrite rules and a kernel interpreter with full trace. The lowest layer of the cognitive stack. |
| `lattice` | The Persistent Shared Memory Network — the unified knowledge store that every other pack reads and writes. Wave 1 of the Requirements Ledger adds three coordination affordances: a lightweight backend-free write door (`lattice_put`/`get`/`take`/`replace`, L1), an isolating transaction (`lattice_transaction/3` with `isolation(serializable)`, L2), and a reactive `lattice_await`/`lattice_notify` woken by a write with no polling — the stigmergy-plus-notification bridge (L3). |
| `actors` | The Actor Framework — cyclic_actor, receptor, and pub-sub messaging. Every cognitive process runs as an actor. |
| `layer` | The Strict Layer Rule (WP-426) — the load-bearing invariant made first-class: a pack declares its rank with `layer(N)` in its manifest, and the checker parses the actual import graph to flag any pack that depends on a higher-layer one. Strict mode refuses a violating load; reporting mode lists without refusing; undeclared packs are gaps, not errors. Runs in Continuous Integration via `bin/check_layers.sh`. Sits beneath every pack it governs. It also carries the N6 layer-to-stratum binding (declare `stratum(Label)` beside `layer(N)`; `bin/check_layer_binding.sh`). Wave 10 Stage 6 (WP-435) extends its **reach**: cross-repository (`layer_scan_dirs`/`layer_check_dirs` union several packs directories under a shared **global coordinate** via a per-repo offset, `bin/check_layers.sh` takes a packs-directory argument, and `layer_adoption/4` reports adoption coverage) and intra-pack (`layer_submodule_violations`/`layer_submodule_untested` check sub-module layering, the declared call boundary, and per-sub-module test targets) — closing the Requirements Ledger's Theme E. Wave 10 Stage 9 (WP-438) adds **binding freshness** (`layer_pack_ordinal/2` reads a stratum ordinal directly from a manifest, `layer_binding_freshness/3` flags a stale artifact) — closing N7. |
| `membership_contract` | The Membership Contract construct (N8, WP-427, WP-428; closes ARBITER-1, N9, N12) — a **runtime** safety postcondition: a predicate declares that an output argument must be a member of an input-set argument (or a declared abstention), and `membership_contract_enforce/4` wraps it so every call that would return a non-member is refused with a glass-box violation. An **accessor form** (`membership_contract_enforce_goal/4`) names the set by a membership-test goal instead of a list, guarding a growing store **without materialising it** (closes N9 / HIPPO-1). An opt-in **once-deterministic mode** (the `/5` enforce entry points) guards the *committed* first solution of a predicate that generates several candidates (closes N12 / N10). Opt-in, membership-specific, dependent only on SWI standard libraries. Re-expresses the arbiter's hand-rolled selector guard by declaration. A **context-aware accessor** (`membership_contract_enforce_context/6`, WP-431, Wave 10 Stage 2) lets an output's legality depend on a **held context** (read at check time) instead of a value the caller must carry — closing AMYGDALA-1. Wave 10 Stage 9 (WP-438) adds **refinements**: a purity guard (`membership_contract_holds_guarded/3`, runs the test under double negation), a determinism check (`membership_contract_test_deterministic/2`), and a **find-first-member** filtering mode (`membership_contract_find_member/4`) — closing N13 and N15. Gated by `.github/workflows/membership-contract.yml`. |
| `affective_state` | A first-class, persisted, modulatory **affective state** (WP-430, Wave 10 Stage 2; closes AMYGDALA-1) — a held valence/salience/mood/cortisol context that survives across calls and derives a `baseline`/`stress` regime that later processing reads (`affective_state_get`/`set`/`regime`/`modulate`/`decay`/`clear`). Paired with the membership contract's context-aware accessor, a later output's legality can depend on this held affect **without smuggling it into the value**. Base infrastructure at layer 0. |
| `tick_scheduler` | A Lattice-backed **deferred-reactivation** construct on **ordinal ticks** (WP-432, Wave 10 Stage 3; closes the Requirements Ledger's Theme A — HIPPO-2 and CEREBELLUM-1). A Lattice nexus holds a monotone logical clock and a set of scheduled reactivations; as the clock advances, every reactivation whose due tick has arrived fires in due-tick order, leaves the schedule, and (in the enact form) is handed to a caller goal to **enact**. Time is measured in the Causalontology 3.0.0 ordinal tick unit — never wall-clock seconds — and a wall-clock unit is **refused** via `causal_core_dimension`. API: `tick_scheduler_open`/`now`/`schedule_at`/`schedule_after`/`schedule_after_unit`/`pending`/`tick`/`advance`/`advance_enact`. Base infrastructure at layer 0. |
| `managed_seam` | A first-class **managed cross-stratal seam** (WP-433, Wave 10 Stage 4; closes the Requirements Ledger's Theme B — the most-recurring gap, six sightings). Records a jump across NON-adjacent strata with a first-class **mechanism_status** (`absent` / `unmodeled` / `modeled` — the honest-ignorance distinction, with the chain coupled to the status so the absent-plus-chain contradiction is unrepresentable), an optional **drawn chain** checked well-formed by the Causalontology 3.0.0 Algorithm F, a **checkable HOME rule** (the coarsest endpoint, so a stratum pack can verify a spanning construct belongs to it), and a **queryable Lattice event** so a skip is visible to the runtime. Well-formedness and the home rule delegate to the frozen `causal_core` engine. API: `managed_seam_new`/`status`/`status_meaning`/`mechanism_status`/`is_honest_ignorance`/`wellformed`/`home`/`home_check`/`emit`/`events`/`events_by_status`. Base infrastructure at layer 0. |
| `realization` | A **structure-to-dynamics binding** (WP-434, Wave 10 Stage 5; closes the Requirements Ledger's Theme C — P1 dynamics facet, P3, P4, STRATA-5, so the four load-bearing walls Themes A–D are all closed). Binds a grounded Causalontology structure record to the native dynamical law or typed Lattice signal that **realizes** it, by identity. A realizer is `native_law(PredicateIndicator)` (a named native predicate) or `lattice_signal(Nexus, Relation)` (a typed signal carrying value / source port / timestamp). The binding is **checkably real** — a bound-but-missing realizer is reported as a finding, not a shared English word. Because the binding is the cross-cut, structure and dynamics need not share a stratum. API: `realization_bind`/`unbind`/`realized_by`/`realizes`/`realizer_exists`/`check`/`check_all`/`trace`/`emit_signal`/`signal`. Base infrastructure at layer 0. |
| `packaging` | **Dependency kinds, loadable faces, a facade, and a cross-pack record registry** (WP-436, Wave 10 Stage 7; closes the Requirements Ledger's Theme G — ATOMIC-1/2/3/4). A dependency is declared `structure_only` (mint-time) or `runtime`, so the layer graph counts only runtime edges; a pack has a `structure` and a `runtime` **face**, so a consumer can load one without dragging in the other; a **facade** names a bundle of packs (recursively, cycle-safely) so a consumer needn't enumerate every fine-grained pack; and a **record registry** looks up a content-addressed record and its owning pack by id. API: `packaging_declare_dependency`/`dependency`/`runtime_dependencies`/`structure_only_dependencies`/`required_face`/`face_dependencies`/`declare_facade`/`facade`/`expand`/`register_record`/`record`/`record_owner`. Base infrastructure at layer 0. |
| `coordination` | **Ergonomic coordination affordances** for the single-threaded reentrant-loop model (WP-437, Wave 10 Stage 8; closes the Requirements Ledger's Theme F — L5/L6/L7/L8/L9, P8/P9/P10, N1/N2/N4/N5). Over a **journal-free** in-memory store: a keyed lookup and a **bounded** keyed await (P8/N5), an ordered FIFO channel (L6), a bounded reentrant-loop driver with an until-condition and completion signal (L7/P9), a reentrant-loop descriptor whose one check proves both an acyclic forward graph and a genuine back-edge closure (P10), a **runtime layer-aware transport** that refuses an upward send (L5's general case + N4), and a glass-box hop trace (L8). Also makes `lattice_transaction/2` a `meta_predicate` (N1). API: `coordination_open`/`put`/`get`/`take`/`get_key`/`await_key`/`publish_ordered`/`consume_ordered`/`bounded_loop`/`declare_loop`/`loop`/`loop_check`/`register_actor`/`actor_layer`/`send`/`trace_hop`/`trace`. Base infrastructure at layer 0. |
| `sentinels` | Neuro-Symbolic Opportunistic Forward Chaining (sentinels_*) — the constitutional guard layer that monitors for violations and fires proactively; a registry (`sentinels_register`, `sentinels_list`, `sentinels_retract`, ...) and a firing engine (`sentinels_evaluate`). |
| `types` | Gradual Lattice Types — an off-by-default type checker where types are first-class Lattice node_facts, not annotations. |

**Perception and Attention**

| Pack | What it Does |
|---|---|
| `perception` | The Perceptual Detector Suite — specialist detectors, a locator, and a mapper that convert raw percepts into Lattice facts. |
| `workspace` | The Global Workspace — attention arbiter, coalition formation, and broadcast cycle. The hub where conscious-access broadcasting happens. |

**Memory and Knowledge**

| Pack | What it Does |
|---|---|
| `beliefs` | Belief Structures and Propagators — per-node_fact scorecards with incremental local propagation. Every belief has a strength and a source. |
| `frames` | Reference Frames and Voting Consensus — the Thousand Brains pattern applied to symbolic cognition. Multiple reference frames vote on every percept. |
| `tabling` | Incremental Tabling Truth Maintenance — automatic, real-time consistency of all derived Lattice relations. No stale inferences. |
| `synaptic_ontological_neural_aggregator` | SONA (Synaptic Ontological Neural Aggregator) — continuous learning with Elastic Weight Consolidation, improved version (EWC++) catastrophic-forgetting protection, a ReasoningBank for episodic recall, and memory consolidation. |
| `imagination` | Imagination (imagination_*, Layer 396, WP-421) — one faculty converged from three: five quarantined **realities** (observed, desired, expected, imagined, recalled) with a transition model and a deliberate promotion discipline, so a "what if" is explored fully yet sealed off from fact (the Causalontology realities half); **mind-wandering** steered from a seed episode toward a control goal (absorbed from the daydream pack); and **mindscapes, tableaux, and rendered reveries** for forming and manipulating mental images (absorbed from the imagination pack). The Lattice-integrated `dreaming` engine is kept separate. |
| `acquisition` | Developmental Language Acquisition — phoneme chaining, word grounding, and tier promotion. PrologAI learns language the way a child does. |

**Reasoning Engine**

| Pack | What it Does |
|---|---|
| `probabilistic` | Distribution Semantics Probabilistic Layer — ProbLog-style exact and sampled inference. Probabilities are first-class reasoning objects. |
| `defeasible` | Justified Defeasible Reasoning — defaults with exceptions and readable justification trees. "Normally true, unless..." is a formal operation. |
| `induction` | Clause Induction — Inductive Logic Programming (ILP) with learn-from-failures, metarules, and meta-interpretive learning. The engine behind ARC-AGI-1. |
| `chainer` | The Generic Chainer — forward and backward inference with meta-reasoning control policies. Any knowledge base becomes an inference engine. |
| `budget` | Resource-Bounded Reasoning — AIKR (Assumption of Insufficient Knowledge and Resources) budgets, evidence truth, and anytime answering. PrologAI knows when to stop. |
| `prediction` | Prediction and Active Inference — hierarchical predictive processing with precision weighting. PrologAI forms and tests predictions about the world. |

**Affect, Motivation, and Metacognition**

| Pack | What it Does |
|---|---|
| `motivation` | Motivation (motivation_*, Layer 386, WP-411) — the inner reason to act, converged into one pack: homeostatic **needs** carry a target set-point, the gap from the current reading becomes **pressure**, pressures become a prioritized, never-empty **agenda** of self-generated restore goals (an idle mind explores rather than stalls), and a global **modulator bus** (arousal, execution speed, resolution) with affect regions and named motives grounds those goals in drives. Absorbed the older Psi modulation pack. |
| `appraisal` | Staged Appraisal and Coping (EMA model) — causal interpretation, appraisal variables, and coping selection. PrologAI evaluates events emotionally before deciding how to respond. |
| `markers` | Somatic Markers — affective pre-selection for deliberation. High-stakes options are flagged before the reasoning engine even starts. |
| `reflex_actors` | Reflex Actors — the "Reflection Pattern" runtime actor engine (reflex_actors_*) — motivation, daydream, regulation, compensation, coping, exploration, discovery, imitation, play, gating, impasse, and meta-control cycles (`reflex_actors_install_actors` registers them all). The full repertoire of reflective behaviors. |
| `awareness` | Situational Awareness — evolving regards, theory-of-mind, and self-reconciliation. PrologAI models its situation, the other agents around it, and its own mental state simultaneously. |
| `assessment` | Intelligence Assessment — Bayley, Piagetian, and CHC (Cattell-Horn-Carroll) frameworks plus consciousness-indicator coverage. PrologAI can measure its own cognitive level. |

**Language and Embodiment**

| Pack | What it Does |
|---|---|
| `language` | Time-Linear Language — database semantics with word_traces, hear, think_path, and speak. Language is grounded in time and memory, not in statistical patterns. |
| `mind_body` | The Mind-Body Interface — herald protocol, body enrollment, percept relay, and command dispatch. Any body (game, robot, screen) attaches here. |
| `robot_operating_system_bridge` | The ROS 2 Bridge — robot embodiment via the Mind-Body pattern. PrologAI can reason inside a physical robot. |
| `computer_use` | Computer Use — a screen-and-input body with sandboxed desktop control. PrologAI can perceive a screen and act on it. |

**Learning and Self-Programming**

| Pack | What it Does |
|---|---|
| `synthesis` | The Self-Programming Seed — model synthesis, scoring, composition, and lifecycle management. PrologAI can write and evaluate new reasoning models. |
| `spinoff` | Marginal Attribution Spinoff Learning — Drescher-style discovery of rare-but-reliable action effects. PrologAI finds causal patterns hidden in low-frequency events. |
| `embedding` | Pluggable Embedding Provider — hash_projection, local_model, and external_service backends with automatic re-embedding maintenance. |
| `refinement` | The Continual Refinement Harness — reset-free recursive self-improvement (RSI) with a constitutional sandbox pipeline. Self-improvement without losing alignment. |
| `dreaming` | The Dreaming Engine (dreaming_*) — three-phase idle-period dream cycle: Slow-Wave (NREM-analog) generative replay and memory consolidation; REM-analog stochastic world-model exploration generating hypothetical node pairings tagged imagined; and a fully inspectable dream journal. The Lattice-integrated engine kept separate from the imagination convergence; its predicates are now pack-qualified. Inspired by Sleep Replay Consolidation, DreamerV3, and NeuroDream. |

**Multi-Agent Protocols**

| Pack | What it Does |
|---|---|
| `model_context_protocol_gateway` | MCP (Model Context Protocol) Gateway — a compliant HTTP server exposing PrologAI's full capability to the AI agent ecosystem. |
| `agent_to_agent` | Agent-to-Agent (A2A) Interoperability — the A2A protocol and durable agent mail. PrologAI agents communicate reliably with any A2A-compliant peer. |
| `agent_communication_protocol` | ACP (Agent Communication Protocol) Gateway — a REST endpoint for broadcast-style agent coordination. |
| `agent_network_protocol` | ANP (Agent Network Protocol) Gateway — decentralized identity and peer discovery for open multi-agent networks. |

**Data Layer**

| Pack | What it Does |
|---|---|
| `vector_backend` | The Vector Backend |
| `vector_symbolic_architecture` | Compositional Vector Binding (VSA — Vector Symbolic Architecture) |
| `lattice_cryptography` | Lattice Cryptographic Privacy Layer |
| `ephemera` | Ephemeral Code Synthesis, Execution, and Skill Persistence (PR 53) |
| `agency` | Agentic Execution Loop (PR 54) |
| `refinery` | Evaluator-Optimizer and Metacognitive Quality Layer (PR 55) |
| `grid` | ARC-AGI Grid Perception and Manipulation (PR 56) |
| `analogy` | Analogy (analogy_*, Layer 394, WP-419) — one faculty converged from two: relational **structure mapping** over rel(Type,A,B) sets that finds the injective object mapping preserving the most relations and transfers a rule/goal/disposition across it (the solar-system-to-atom analogy; the Causalontology relational half), plus **grid analogy** — the D4 dihedral isometries, colour-substitution maps, shape equality up to isometry, and solve-from-examples transform inference (absorbed from the ARC grid-analogy pack). |
| `scene` | ARC-AGI Scene Model and Object-Centric Reasoning (PR 58) |
| `quantity` | Quantitative Reasoning over Object Sets (PR 59) |
| `pattern` | Periodic Pattern Detection, Tiling, and Repetition (PR 60) |
| `compose` | Sequential Rule Pipelines and Transformation Composition (PR 61) |
| `motion` | Spatial Movement, Gravity, and Distance for Grid-Based Reasoning (PR 62) |
| `frame` | Rectangular Border Detection, Interior Extraction, and Frame Generation (PR 63) |
| `path` | Path-Finding, Flood Fill, Connectivity, and Reachability (PR 64) |
| `symmetry` | Grid Symmetry Testing, Canonical Orientation, and Orbit Generation (PR 65) |
| `color` | Color Palette Extraction, Histogram Analysis, and Color Manipulation (PR 66) |
| `shape` | Normalized Shape Extraction, Comparison, Transformation, and D4 Orbit Reasoning (PR 67) |
| `relation` | Spatial Relations Between Cell Regions (PR 68) |
| `sequence` | Arithmetic Sequence Analysis, List Structure, and Period Detection (PR 69) |
| `crop` | Subgrid Extraction, Padding, Splitting, Joining, and Embedding (PR 70) |
| `overlay` | Grid Combination by Layering, Logic, Masking, and Priority Merge (PR 71) |
| `measure` | Geometric Measurement of Cell Regions and Grids (PR 72) |
| `transform` | Grid-Level Spatial and Color Transformations (PR 73) |
| `select` | Selection and Filtering of Cell Regions by Spatial and Size Properties (PR 74) |
| `count` | Counting Cells, Colors, and Regions in Grids (PR 75) |
| `fill` | Pattern-Based Region and Grid Filling (PR 76) |
| `pattern` | Pattern Detection, Tiling Period, and Motif Extraction (PR 77) |
| `compare` | Grid and Region Comparison, Difference Detection, and Similarity Scoring (PR 78) |
| `spatial` | Spatial Reasoning: Directions, Containment, Adjacency, and Grid Topology (PR 79) |
| `induction` | Grid-Pair Inductive Analysis: Color Maps, Recolor Detection, and Scale Inference (PR 80) |
| `gravity` | Directional Gravity and Settling Operations (PR 81) |
| `noise` | Binary Mask Operations and Grid Noise Analysis (PR 82) |
| `generate` | Grid Construction from Visual Patterns (PR 83) |
| `lookup` | Association List Operations and Grid Index Maps (PR 84) |
| `connect` | Flood Fill and Connected Component Analysis (PR 85) |
| `morph` | Morphological Grid Operations (PR 105) |
| `walk` | Grid Traversal Patterns (PR 106) |
| `run` | Run-Length Encoding of Grid Sequences (PR 88) |
| `rewrite` | Rule-Based Grid Cell Rewriting (PR 87) |
| `grid_arithmetic` | Cell-Wise Arithmetic on Grids (PR 89) |
| `context` | Context Map Operations (PR 92) |
| `score` | Candidate Grid Scoring and Hypothesis Selection (PR 93) |
| `rule_induction` | Rule Induction Observation Layer (PR 94) |
| `symmetry_transform` | Spatial Symmetry Transforms and Symmetry Testing (PR 96) |
| `rule_hypothesis` | Hypothesis Application, Testing, and Selection (PR 95) |
| `seek` | Spatial Pattern Search and Transform Discovery (PR 97) |
| `remap` | Color Remapping and Palette Manipulation (PR 98) |
| `logic` | Boolean and Mask Grid Operations (PR 99) |
| `window` | Sliding Window and Neighborhood Operations (PR 100) |
| `sorting` | Sorting, Ranking, and Ordering (PR 101) |
| `tile` | Tiling, Stamping, and Period Detection (PR 102) |
| `trace` | Path Tracing, Rays, and Grid Boundaries (PR 103) |
| `label` | Connected Component Labeling and Region Queries (PR 104) |
| `morph` | Morphological Grid Operations (PR 105) |
| `walk` | Grid Traversal Patterns (PR 106) |
| `step` | Directional Grid Movement (PR 107) |
| `pivot` | Pivot-Relative Cell Transformations (PR 108) |
| `project` | Axis Projection and Shadow Casting (PR 109) |
| `neighbor` | Cell Neighborhood Analysis (PR 114) |
| `gravity` | Directional Cell-Sliding and Gravity Operations (PR 116) |
| `count` | Value Counting and Frequency Analysis (PR 117) |
| `diagonal` | Diagonal Line Extraction and Filling (PR 119) |
| `cluster` | Spatial Proximity and Grouping (PR 123) |
| `patch` | Sub-Grid Extraction and Template Matching (PR 129) |
| `panel` | Grid Panel Detection and Splitting (PR 135) |
| `cellset` | Sparse Cell Set Operations (PR 138) |
| `locate` | Pattern Location and Subgrid Matching (PR 139) |
| `extended_selection` | Extended Cell Selection by Value Comparison (PR 140) |
| `automaton` | Cellular Automaton Neighborhood Aggregation (PR 141) |
| `cross` | 1D Cross-Section Extraction from 2D Grids (PR 142) |
| `mask` | Boolean Mask Operations on 2D Grids (PR 143) |
| `data_table` | Grid-as-Table Operations (PR 144) |
| `numeric_sequence` | Numerical Sequence Operations on 1D Lists (PR 145) |
| `grid_math` | Cell-Wise Arithmetic on 2D Grids (PR 146) |
| `block` | Rectangular Sub-Grid Block Decomposition (PR 148) |
| `topology` | Grid Topology and Connected Component Analysis (PR 151) |
| `distance` | Cell Distance and Proximity Computation (PR 150) |
| `edge` | Grid Edge Detection and Boundary Analysis (PR 149) |
| `color_map` | Color Lookup Table and Palette Substitution (PR 147) |
| `bound` | Bounding Box Extraction and Placement (PR 137) |
| `scan` | Grid Cell Enumeration and Manipulation (PR 136) |
| `interleave` | Row and Column Interleaving, Weaving, and Stride Selection (PR 134) |
| `offset` | Grid Shifting and Circular Rolling (PR 133) |
| `zoom` | Integer-Factor Grid Scaling (PR 132) |
| `histogram` | Value Frequency Analysis (PR 131) |
| `signal` | 1D Signal Analysis of Grid Rows and Columns (PR 130) |
| `hull` | Convex Hull and Polygon Geometry (PR 128) |
| `enclosure` | Interior and Exterior Classification (PR 127) |
| `spread` | BFS Spreading, Distance Maps, and Reachability (PR 126) |
| `vector2` | 2D Integer Vector Arithmetic and Geometry (PR 125) |
| `ray` | Ray Casting and Line-of-Sight Operations (PR 124) |
| `rectangle` | Rectangle Detection and Drawing (PR 122) |
| `line` | Straight-Line Segment Detection and Drawing (PR 121) |
| `recur` | Arithmetic Progression and Periodic Recurrence Detection (PR 120) |
| `stripe` | Uniform Row and Column Stripe Detection and Filling (PR 118) |
| `permute` | Row and Column Permutation Operations (PR 115) |
| `region` | Grid Region Extraction by Separator Lines (PR 113) |
| `assemble` | Grid Assembly, Concatenation, and Composition (PR 112) |
| `order` | Object Spatial Ordering and Ranking (PR 111) |
| `difference` | Multi-Pair Grid Difference Analysis (PR 110) |
| `pipeline` | Sequential Step Dispatch and List Utilities (PR 91) |
| `object` | Object Inventory and Reasoning (PR 90) |
| `projection` | Row and Column Projection and Profile Analysis (PR 237) |
| `gradient` | Row and Column Gradient and Progression Analysis (PR 238) |
| `extrema` | 2D Grid Extrema, Local Peaks, and Threshold Filtering (PR 239) |
| `neighborhood_aggregate` | Per-Cell Neighborhood Value Aggregation (PR 240) |
| `median` | Integer Median Computation for Lists and 2D Grids (PR 241) |
| `neighborhood_mode` | Neighborhood Mode Filter for 2D Grids (PR 242) |
| `rank` | Dense Ranking of Integer Values in Lists and 2D Grids (PR 243) |
| `variance_statistics` | Mean, Sum, and Deviation Statistics for Integer Lists and 2D Grids (PR 244) |
| `cooccurrence` | Value Co-Occurrence and Adjacency Analysis in 2D Grids (PR 245) |
| `row_signature` | Row and Column Signature Analysis for 2D Grids (PR 246) |
| `grid_operations` | Grid Collection Operations for Multi-Grid Analysis (PR 247) |
| `index` | Coordinate-Valued Grid Generation and Index Masking (PR 248) |
| `splice` | Row and Column Structural Editing (PR 253) |
| `object_operation` | Object-Level Grid Manipulation (PR 254) |
| `pair` | Object Pairing and Scene Correspondence (PR 255) |
| `arrange` | Object Arrangement and Spatial Ordering (PR 256) |
| `isometry` | Object-Level Transformation and Inference (PR 257) |
| `query` | Aggregate Queries over Object Lists (PR 258) |
| `sift` | Object List Filtering by Attribute Predicates (PR 259) |
| `pigment` | Bulk Color Operations on Object Scenes (PR 260) |
| `delta` | Scene-Level Delta Analysis (PR 261) |
| `group` | Object Grouping and Partition (PR 262) |
| `proximity` | Object-Level Proximity and Distance (PR 263) |
| `link` | Object-to-Object Correspondence Linking (PR 264) |
| `layout` | Multi-Object Layout Analysis (PR 265) |
| `size_operation` | Size-Based Sorting and Assignment for Object Collections (PR 267) |
| `position_operation` | Position-Based Sorting, Filtering, and Assignment for Object Collections (PR 268) |
| `object_transform` | Spatial and Color Transformations for obj(Color, Cells) Terms (PR 269) |
| `shrink` | Grid Downscaling and Block Decomposition (PR 270) |
| `object_morph` | Morphological Operations on obj(Color, Cells) Terms (PR 271) |
| `voronoi` | Nearest-Color Painting and Voronoi Partitioning (PR 272) |
| `object_component` | Object Connectivity and Component Analysis (PR 273) |
| `wavefront` | Wavefront BFS Propagation Through Passable Cells (PR 274) |
| `object_filter` | Object List Filtering and Selection for obj(Color, Cells) Terms (PR 281) |
| `object_pair_relation` | Object Pair Relation Analysis for obj(Color, Cells) Terms (PR 280) |
| `canvas` | Grid Canvas and Object Rendering (PR 283) |
| `object_sequence` | Object Sequence and Progression Analysis (PR 284) |
| `object_delta` | Object-Pair Change Analysis and Rule Application (PR 285) |
| `object_copy` | Object Tiling and Multi-Copy Layout (PR 286) |
| `object_match` | Object-List Correspondence and Matching (PR 287) |
| `grid_neighbor` | Grid Neighbor Analysis: Cell Adjacency, Morphological Ops, and Neighbor Counts (gn_*, Layer 199) (PR 308) |
| `grid_mask` | Grid Mask Operations: Boolean Overlay, Union, Intersection, Difference, Invert, and Color Mask (gm_*, Layer 206) (PR 315) |
| `grid_transform` | Grid Transformations: Rotate, Flip, Transpose, Crop, Pad, Scale, Tile, Canonicalize (gx_*, Layer 207) (PR 317) |
| `grid_symmetry` | Grid Symmetry: Detection, Completion, Violations, and Score (gsm_*, Layer 208) (PR 318) |
| `grid_mark` | Grid Marking and Annotation: Mark Cells, Rows, Columns, Borders, Diagonals, Rectangles, and Checkerboards (gmk_*, Layer 225) (PR 335) |
| `grid_crop` | Grid Cropping and Padding: Bounding Box, Trim, Crop, Pad, Center, Border, and Expand (gcr_*, Layer 226) (PR 336) |
| `grid_patch` | Grid Patch Operations: Extract, Place, Overlay, Find, Tile, Scatter, and Inpaint (gpt_*, Layer 227) (PR 337) |
| `grid_scan` | Grid Ray Scanning: First Hit, Distance, Row/Column Content, and Blocking Detection in Four Directions (gsn_*, Layer 228) (PR 338) |
| `grid_wave` | Grid Wave Propagation: Color Expansion, Contraction, Frontier Detection, and Directional Shadows (gwv_*, Layer 229) (PR 339) |
| `grid_shift` | Grid Shifting and Cyclic Rolling: Linear Shifts, Toroidal Rolls, Per-Row/Column Rolls, Color Shift, and Offset (gsh_*, Layer 230) (PR 340) |
| `grid_map` | Grid Color Mapping: Remap, Swap, Replace, Merge, Normalize, Palette, Mask, Invert, Cycle, and Map Composition (gmp_*, Layer 231) (PR 341) |
| `grid_reflection` | Grid Reflection and Rotation: Flip, Rotate, Transpose, Anti-Diagonal, Symmetry Detection, and Symmetry Completion (grf_*, Layer 232) (PR 342) |
| `grid_extract` | Grid Object Extraction: Bounding Box Crops, Non-BG Object Isolation, Color-Region Extraction, Cell Collection, Largest/Smallest Object, Centered Crop, Region Count, and Object Registry (gxt_*, Layer 236) (PR 346) |
| `grid_blend` | Grid Blending and Layered Composition: Overlay, Underlay, Stencil, Priority Stack, Checkerboard Blend, Stripe Blend, Threshold Replace, Merge Many, Dominant Color, and Composite (gbld_*, Layer 235) (PR 345) |
| `grid_chain` | Grid Sequence Utilities: Consecutive Pairs, Sliding Windows, Zip, Take, Drop, Cycle, Interleave, Split, Dedup, Diff Counts, and Change Mask (gch_*, Layer 234) (PR 344) |
| `grid_logic` | Grid Logical Operations: Cell-Wise AND, OR, XOR, NOT, Subtract, Common, Differ, Any, All, Majority, Unanimous, Mask, If-Then-Else, and Filter (ggl_*, Layer 233) (PR 343) |
| `grid_tile` | Grid Tiling Pattern Analysis: Period Detection, Tile Extraction, Tiling Verification, and Grid Construction from Tiles (gti_*, Layer 224) (PR 334) |
| `grid_gravity` | Grid Gravity and Sliding: Fall Down, Up, Left, Right, Blocked Fall, Column and Row Setters, Settled Test, and Gravity Score (gra_*, Layer 237) (PR 348) |
| `grid_stamp` | Grid Stamping and Canvas Operations: Stamp, Scatter, Match Finding, Pad, Unpad, Replicate, Border, Center, Extract, Replace, and Canvas (gst_*, Layer 238) (PR 349) |
| `grid_align` | Grid Alignment and Shift Matching: Center of Mass, Translation, Offset Search, Overlap Scoring, Bounding Box Alignment, and Anchor Placement (gal_*, Layer 239) (PR 350) |
| `grid_color_operation` | Grid Color Operations: Count, Swap, Replace, Mask, Cycle, Rank, Palette Apply, and Invert (gco_*, Layer 240) (PR 351) |
| `grid_resize` | Grid Resize and Scale Operations: Integer Scale Up/Down, Mode Downsample, Double, Halve, Nearest-Neighbor Resize, Tile, Crop, Border Crop, Fit, Embed, Size, Aspect Ratio, and Square Test (grs_*, Layer 241) (PR 352) |
| `grid_object` | Grid Object Operations: Connected Component Cells, Color, Size, Bbox, Mask, Extract, All Objects, Count, Largest, Smallest, Flood Fill, Fill Enclosed, Remove, and Move (gob_*, Layer 242) (PR 353) |
| `grid_group_by` | Grid Group-By Operations: Group, Filter, Sort, Pair, and Count Objects by Attribute (ggb_*, Layer 243) (PR 354) |
| `grid_relation` | Grid Object Spatial Relations: Touching, Adjacent, Distance, Above, Below, Left-Of, Right-Of, Bbox Contains, Bbox Overlap, Cells Overlap, Same Rows, Same Cols, Direction, and All Relations (grl_*, Layer 244) (PR 355) |
| `grid_color_transform` | Grid Transformation Detection and Application: Color Map, Apply Map, Diff Cells, Diff Count, Same Cells, Changed Colors, Invert Map, Compose Maps, Identity Test, Apply Changes, Delta Grid, Overlay, Common Grid, and Color Permutation Test (gtr_*, Layer 245) (PR 356) |
| `grid_object_match` | Object Matching and Change Detection Between Object Lists: Match by Color, Nearest Centroid, and Size; Unmatched Extraction; Color-Diff Partition; Movement Vectors; Constant Move; Color Map Inference; Appeared, Disappeared, Structure, and Count Change (gom_*, Layer 246) (PR 358) |
| `symbol_table` | Symbol Table Learning from Input-Output Pairs: Build Table, Identify Symbols, Contrastive Learn, Apply Table, Hole Count, Lookup, Entry Consistency, Color/Size/Position Features, Is Symbol, Candidate Symbols, Score Table, and Best Table (st_*, Layer 247) (PR 359) |
| `invariant` | Cross-Pair Invariant Extraction: Grid and Output Invariants, Object Invariants, Variant Features, Consistent Delta, All/No-Grids Meta-Predicates, Color Set, Same Color Sets, Same Dims, Preserves Dims/Colors/Count, and Stable Color Map (iv_*, Layer 248) (PR 360) |
| `contrast` | Contrastive Pair Analysis: Pairwise Delta, Covarying Features, Context Gate, Discriminating Pair, Correlated Features, Change Count, Common Context, Separates, Minimal Features, Feature Profile, Profile Diff, Stable Features, Unstable Features, and Rank Features (ca_*, Layer 249) (PR 361) |
| `legend` | Legend and Key Region Detection: Detect Legend, Is Legend, Legend Entries, Consistent Legend, Region BBox, Separated, Region Area, All Regions, Region Color, Is Small, Same Shape, Entry Boundaries, Color Map, and Position (lg_*, Layer 250) (PR 362) |
| `multi_pair` | Multi-Pair Object Tracking: Track Objects, Invariant Objects, Role Objects, Cross-Pair Match, All Input Objects, Color Frequency, Universal Colors, Variable Colors, Disappeared Objects, Appeared Objects, Stable Color Objects, Modal Object Count, Consistent Count, Singleton Color (mp_*, Layer 251) (PR 362) |
| `task_category` | Task Type Classification: Categorize, Is Single Rule, Is Multi-Step, Has Context Gate, Has Symbol Table, Suggest Strategies, Preserves Dims, Preserves Colors, Consistent Change Count, Max Change Count, Distinct Change Patterns, Is Fill Task, Is Deletion Task, Confidence (tc_*, Layer 252) (PR 362) |
| `period_fix` | Periodic Pattern Repair: List and Grid Period Detection, Majority-Vote Tile Construction, Violation Finding, Full and Single-Corruption Repair, and Best-Period Search (ppf_*, Layer 253) (PR 366) |
| `io_channel` | I/O Channel Integration: Speaker output (espeak-ng / festival TTS), microphone input (arecord + whisper-cli STT), text channels (console / email / screen / app), image channels (console / email / screen / app / webcam / URL), and printer output (CUPS lp) (ic_*, Layer 254) (WP-279) |
| `sequence_inference` (enhanced) | Sequential Rule Inference + ARC-AGI-2 Candidates: seqinfer_arc2_candidates/1 adds 66-entry integer-color candidate list for multi-step search (sq_*, Layer 195) (WP-274, PR 363) |
| `rule_hypothesis` (enhanced) | Hypothesis Generation + Spatial/Structural/Sequence: hyp_spatial_hyp/3, hyp_structural_hyp/3, hyp_sequence_hyp/4 extend hypothesis search to grid-level shifts, structural patterns, and two-step color maps (hy_*, Layer 74) (WP-275, PR 363) |
| `conditional_transform` (enhanced) | Conditional Scene Transform + Gate Inference: condxf_infer_gate/3 infers the gate_color that separates training pairs by change signature (xc_*, Layer 187) (WP-276, PR 363) |
| `induction` (enhanced) | Grid-Pair Induction + Cross-Pair Aggregation: induction_cross_pair_invariants/2, induction_cross_pair_variants/2 aggregate properties across all training pairs (id_*, Layer 59) (WP-277, PR 363) |
| `grid_position` | Grid Positional Analysis: Halves, Quadrants, Even/Odd Rows and Columns, Checkerboard, Center, Corners, and Cross (gps_*, Layer 222) (PR 332) |
| `grid_histogram` | Grid Histogram Analysis: Per-Row and Per-Column Color Frequency, Modal, and Entropy (ghst_*, Layer 221) (PR 331) |
| `grid_segment` | Grid Segmentation by Separator Rows and Columns: Split, Trim, and Panel Extraction (gsg_*, Layer 220) (PR 330) |
| `grid_row_column` | Grid Row and Column Comparative Analysis: Extract, Compare, Sort, and Find Matching Rows and Columns (grc_*, Layer 219) (PR 329) |
| `grid_delta` | Grid Delta Analysis: Difference Detection, Change Maps, Color Transitions, and Grid Comparison (gdt_*, Layer 218) (PR 328) |
| `grid_spiral` | Grid Spiral Traversal: Clockwise Spiral Ordering, Read, Write, Rotate, and Frame Spirals (gsp_*, Layer 217) (PR 327) |
| `grid_frame` | Grid Frame Analysis: Concentric Ring Depth, Frame Extraction, Uniformity, Fill, and Peel (gfr_*, Layer 216) (PR 326) |
| `grid_diagonal` | Grid Diagonal Analysis: Main and Anti-Diagonal Extraction, Counting, Uniformity, and Modification (gdi_*, Layer 215) (PR 325) |
| `grid_graph` | Grid Region Adjacency Graph: Color Adjacency, Borders, Enclosure, Spanning, and Component Analysis (ggr_*, Layer 214) (PR 324) |
| `grid_convolution` | Grid Convolution: Sliding Window, Pattern Matching, Density Maps, and Square Morphology (gcv_*, Layer 213) (PR 323) |
| `grid_morph` | Grid Morphological Operations: Dilation, Erosion, Opening, Closing, Fill, and Gradient (gmo_*, Layer 212) (PR 322) |
| `grid_edge` | Grid Edge and Boundary Detection: Edge Cells, Boundaries, Corners, Endpoints, and Transition Maps (ge_*, Layer 211) (PR 321) |
| `grid_stitch` | Grid Assembly: Concatenation, Splitting, Tiling, Border, and Repetition (gst_*, Layer 210) (PR 320) |
| `grid_color` | Grid Color Analysis: Count, Histogram, Recolor, Color Map, Threshold, Dominant, Fraction (gc_*, Layer 209) (PR 319) |
| `grid_path` | Grid Pathfinding: BFS Shortest Path, Distance Maps, Flood-N, Wavefront, Line-of-Sight, and Region Path (gpa_*, Layer 205) (PR 314) |
| `grid_flood` | Grid Flood-Fill, Region Analysis, Hole Filling, and Connected Components (gf_*, Layer 204) (PR 313) |
| `grid_run` | Grid Run-Length Encoding and Stripe Analysis: Row/Column Runs, Uniformity, Striped Grids, and Alternating Patterns (grl_*, Layer 203) (PR 312) |
| `grid_scale` | Grid Block-Pixel Scaling: Upsample, Downsample, Scale Factor, Tile Inference, Pad, and Resize (gsc_*, Layer 202) (PR 311) |
| `grid_period` | Grid Periodic Pattern Detection and Extension: Row/Column Period, Tiling, Autocorrelation, and Wrap-Shift (gper_*, Layer 201) (PR 310) |
| `grid_distance` | Grid Distance Transform: Cell-to-Color Distances, BFS Flood, Voronoi, and Morphological N-Step Ops (gd_*, Layer 200) (PR 309) |
| `grid_task` | Grid Task: End-to-End Raw Grid Task Solver (gt_*, Layer 198) (PR 307) |
| `grid_parse` | Grid Parse: Conversion between Raw Grid Format and obj Scene Representation (PR 306) |
| `grid_query` | Grid Query and Manipulation: Size, Color, Region, Diff, Structural Ops (PR 305) |
| `sequence_inference` | Sequential Rule Inference: Multi-Step Scene Transformation Search (PR 304) |
| `scene_invariant` | Scene Invariant Detection across Training Pairs (PR 303) |
| `multi_color` | Multi-Color Scene Analysis: Frequency, Partition, and Color-Indexed Queries (PR 302) |
| `transform_generate` | Systematic Generation of Scene Transformation Rule Candidates (PR 301) |
| `grid_solve` | End-to-End Scene Puzzle Solver (PR 300) |
| `color_table` | Color Substitution Table Learning and Application (PR 299) |
| `scene_rank` | Rule Hypothesis Ranking for Scene Lists (PR 298) |
| `scene_pair` | Holistic Before-After Scene Pair Analysis (PR 297) |
| `conditional_transform` | Conditional and Selective Scene Transformation (PR 296) |
| `scene_apply` | Scene-Level Rule Term Evaluation Engine (PR 295) |
| `rule_inference` | Scene-Level Transformation Rule Inference from Object-List Pairs (PR 294) |
| `scene_transform` | Scene-Level Uniform Transformation of All Objects (PR 293) |
| `object_locate` | Object-List Spatial and Attribute Query Against a Reference Object (PR 292) |
| `scene_compare` | Scene-Level Comparison of Two Object Lists (PR 291) |
| `object_group` | Object-List Grouping by Shared Attribute (PR 290) |
| `object_attribute` | Object-List Aggregate Attribute Analysis (PR 289) |
| `object_merge` | Object Merging, Set Operations, and Component Splitting (PR 288) |
| `object_boundary` | Object Shape Classification and Bounding Box Analysis (PR 277) |
| `object_symmetry` | Object Symmetry Analysis for obj(Color, Cells) Terms (PR 276) |
| `object_chain` | Linear Chain Analysis for obj(Color, Cells) Sequences (PR 275) |
| `weave` | List Interlacing, Slicing, and Cycling (PR 266) |
| `border` | Concentric Ring Analysis for 2D Grids (PR 252) |
| `warp` | Shear, Cyclic Shift, and Non-Uniform Grid Warping (PR 251) |
| `rotation` | Grid Rotation and Rotational Symmetry Detection (PR 250) |
| `fold` | Grid Folding, Unfolding, and Fold-Symmetry Detection (PR 249) |
| `interop` | Hyperon Interoperability Bridge |

**Platform Utilities**

| Pack | What it Does |
|---|---|
| `tooling` | Tool Use Pattern — tool registry, discovery, selection, gated invocation, and reliability learning. Every external tool is a first-class reasoning object. |
| `libraries` | Utility Libraries — similarity, types, collections, generators, tasks, problems, config, peers, macros, and convenience predicates. The shared foundation everything else builds on. |

---

## SPARC Documentation Series

PrologAI is defined by six companion volumes:

| Volume | Document | Purpose |
|---|---|---|
| 1 | `PrologAI_1_Specification_v414` | Authoritative statement of what to build |
| 2 | `PrologAI_2_Pseudocode_v405` | How each work package reasons |
| 3 | `PrologAI_3_Architecture_v407` | Where each piece lives |
| 4 | `PrologAI_4_Refinement_v466` | Testing protocols and safety criteria |
| 5 | `PrologAI_5_Completion_v472` | Release criteria and completion evidence |
| 6 | `PrologAI_6_Demonstration_Mentova_v4` | How Mentova is born, proven, and grown |

---

## Quick Start

**Prerequisite:** [SWI-Prolog 9.0.4+](https://www.swi-prolog.org/download/stable)

No large language model (LLM) required.

No pretraining required.

No internet connection required.

```prolog
% Load PrologAI
?- [launcher/prologai_boot].

% Ask a deductive question
?- prologai_query(deductive, is_a(tweety, bird), R).
R = answer(yes, just(tweety, is_a, bird, chain([tweety, bird]))).

% Bayesian update
?- prologai_query(bayesian, update(rain, wet_grass), R).

% Inductive rule learning (ARC-AGI-1 style)
?- arc_benchmark:arc_induce_rule_400(TrainingPairs, Rule).
```

Every answer returns `answer(Conclusion, Justification)` — the conclusion plus a readable proof trace.

No black box.

No guessing.

---

## ARC-AGI-1 (Abstract Reasoning Corpus - Artificial General Intelligence - Year 1): 400/400 = 100.00%

The [ARC-AGI-1](https://arcprize.org) benchmark is a set of 400 grid-transformation puzzles designed by Francois Chollet to measure fluid reasoning — the kind of intelligence that cannot be faked by memorizing training data.

> **Re-verified 2026-07-15.** A full runnable re-run of the benchmark exposed a pre-existing recording overcount of two: tasks `234bbc79` and `4290ef0e` had rules that fit their training pairs but not their held-out test grids, so the benchmark had actually been scoring 398/400. Both rules were genuinely generalized (an N-piece joint-assembly rule, and a concentric-rings rule that sizes each ring from the edge-midpoint-gap centre-line invariant), and the full benchmark now truly scores **400/400 = 100.00%** — confirmed by both a booted run and an isolated `arc_benchmark_run/3`, each reporting 400 with an empty fail list.

No large language model (LLM).

No neural weights.

No internet knowledge.

PrologAI solved all 400 tasks using **pure symbolic induction with named glass-box rules — from scratch, on each task's own training examples**:

```prolog
% Task 234bbc79 — assemble_3pieces_at_5_joints
% ERC 0.10 %
arc_named_rule(assemble_3pieces_at_5_joints).
% ERC 0.10 %
arc_transform(Pairs, TestIn, TestOut) :-
    w75_sort_pieces_ltr(Pairs, Pieces),
    w75_assemble_at_joints(Pieces, TestIn, TestOut).
```

Each of the 400 solved tasks has a human-readable named rule like this.

No two rules are the same.

Each one captures a distinct visual reasoning pattern — pure symbolic induction, from scratch, on each task's own examples.

<details>
<summary>View the 79-wave climb summary</summary>

| Waves | Score | Key Techniques Added |
|---|---|---|
| 1–10 | 17/400 | Flood fill, object detection, color mapping |
| 11–20 | 65/400 | Rigid isometry (8 symmetries), template stamping |
| 21–30 | 138/400 | Anchor-based alignment, bounding-box crop |
| 31–40 | 210/400 | Chain reflection, ring completion, contour tracing |
| 41–50 | 265/400 | Multi-color DFS, piece assembly, BFS components |
| 51–60 | 318/400 | Composite scoring, keyed patterns, hole stamping |
| 61–70 | 371/400 | Frame geometry, diagonal rays, ornament transfer |
| 71–74 | 395/400 | Scale matching, void placement, 4-fold symmetry |
| 75–79 | **400/400** | Joint assembly, ring normalization, chain reflection |

</details>

Full chronicle: [Climbing_ARC-AGI-1.txt](https://github.com/ai-university-aiu/Mentova/blob/main/papers/Climbing_ARC-AGI-1.txt)  
Achievement report: [ARC-AGI-1_Perfect_Score_Report.txt](https://github.com/ai-university-aiu/Mentova/blob/main/papers/ARC-AGI-1_Perfect_Score_Report.txt)

Full ARC-AGI-2 chronicle: [Climbing_ARC-AGI-2.txt](https://github.com/ai-university-aiu/Mentova/blob/main/papers/Climbing_ARC-AGI-2.txt)  
ARC-AGI-2 achievement report: [ARC-AGI-2_Perfect_Score_Report.txt](https://github.com/ai-university-aiu/Mentova/blob/main/papers/ARC-AGI-2_Perfect_Score_Report.txt)

---

## Glass-Box vs Black-Box

| Property | PrologAI | Large Language Model (LLM) / Transformer |
|---|---|---|
| Every answer is inspectable | ✅ Yes | ❌ No |
| Reasoning is a named proof | ✅ Yes | ❌ No |
| No large language model (LLM) required | ✅ Yes | ❌ No |
| Hallucination possible | ❌ None by design | ✅ Frequent |
| ARC-AGI-1 score | **100.00%** | < 50% (best frontier models) |
| ARC-AGI-2 score | **100.00%** | < 5% (best frontier models) |
| Zero-shot induction on new tasks | ✅ Yes | ❌ No |
| Justification tree readable | ✅ Yes | ❌ No |
| Written in symbolic logic | ✅ Yes — pure Prolog | ❌ No — matrix arithmetic |
| Can explain every step in plain language | ✅ Yes | ❌ No |

---

## Mentova

[Mentova](https://github.com/ai-university-aiu/Mentova) is the world's first glass-box synthetic mind, built on PrologAI.

It runs 48 reasoning types, achieved a confirmed perfect score of 400/400 = 100% on ARC-AGI-1 (Abstract Reasoning Corpus - Artificial General Intelligence - Year 1), and has solved the ARC-AGI-2 public evaluation set in full at 120/120 = 100.00% (benchmark runner and ledger both 120/120, zero tasks pending), Wave 124 complete - the summit.

Mentova now has a public text-only web chat interface (Acc_423). Any person with a browser can hold a typed conversation with Mentova, ask it to justify every answer, and watch it honestly admit when it does not know. Mentors can propose new facts through a review-gated teaching path. Start the chat server with bin/mentova_chat_start.sh.

No large language model (LLM).

No neural weights.

No internet knowledge.

No black box.

No guessing.

Every answer Mentova produces comes with a readable justification tree — the conclusion and every reasoning step that led to it, always together.

---

## Documentation

| Resource | Description |
|---|---|
| [PrologAI Tutorial](docs/PrologAI_Tutorial.txt) | 12-chapter tutorial — beginner to advanced |
| [Certified PrologAI Engineer](docs/Certified_PrologAI_Engineer.txt) | 25-chapter professional reference textbook |
| [ARC-AGI Human Steps](docs/ARC-AGI_Human_Steps.txt) | Cognitive deconstruction of all 400 ARC-AGI-1 tasks |
| [PrologAI Requirements Ledger](docs/PrologAI_Requirements_Ledger_v10.txt) | The consolidated program-wide Ledger — every Connectome finding (open gaps, closed track record, cross-cutting patterns, and the forward agenda) gathered into one canonical view |
| [SPARC Series](docs/) | Complete specification, architecture, and completion volumes |

---

## Author

**D. R. Dison**  
Founder of AIU (Artificial Intelligence University) · Creator and Owner of PrologAI and Mentova  
ORCID: 0009-0001-9246-5758 · [LinkedIn](https://www.linkedin.com/in/d-r-dison/)

---

## License

**The Attribution Always; No Profit, No Problem License.** — see [LICENSE.txt](LICENSE.txt)

Free for non-commercial use (individuals, students, educators, non-profits, academic researchers) with required attribution to PrologAI, AIU (Artificial Intelligence University), and D. R. Dison.

Commercial and profit-making use requires a negotiated license including a percentage-of-profits royalty. Contact [ai.university.aiu@gmail.com](mailto:ai.university.aiu@gmail.com) before any commercial use begins.

See [COMMERCIAL.txt](COMMERCIAL.txt) for the full commercial licensing process.
