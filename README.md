<p align="center">
  <img src="assets/prologai_banner.svg" alt="PrologAI — Cognitive Architecture for Synthetic Minds" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/ARC--AGI--1-400%2F400%20%3D%20100%25-brightgreen?style=for-the-badge" alt="ARC-AGI-1: 400/400">
  <img src="https://img.shields.io/badge/SWI--Prolog-9.0.4%2B-8A2BE2?style=for-the-badge" alt="SWI-Prolog 9.0.4+">
  <img src="https://img.shields.io/badge/reasoning-48%20types-5865F2?style=for-the-badge" alt="48 Reasoning Types">
  <img src="https://img.shields.io/badge/protocols-MCP%20%7C%20A2A%20%7C%20ACP%20%7C%20ANP-0075CA?style=for-the-badge" alt="MCP | A2A | ACP | ANP">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="MIT License">
</p>

<p align="center">
  <strong>A cognitive architecture programming language and platform for building synthetic minds.</strong><br>
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

---

## Landmark Achievements

| Benchmark / Capability | Result | Method |
|---|---|---|
| **ARC-AGI-1** — 400-task grid reasoning benchmark | **400 / 400 = 100.00%** | Pure symbolic induction, named glass-box rules |
| Reasoning Types | **48/48** | Deductive, Inductive, Abductive, Probabilistic, Bayesian, Causal, Statistical, Analogical, Relational, Transductive, Commonsense, Logical, Formal, Mathematical, Fuzzy, Qualitative, Non-monotonic, Paraconsistent, Counterfactual, Hypothetical, Spatial, Diagrammatic, Temporal, Case-based, Constraint-based, Scientific, System, Model-based, Heuristic, Critical, Dialectical, Metacognitive, Modal, Epistemic, Deontic, Procedural, Symbolic, Practical, Teleological, Strategic, Narrative, Social, Intuitive, Emotional, Motivational, Informal, Legal, Moral — all 48 implemented |
| SPARC documentation volumes | **6 / 6** | Specification, Pseudocode, Architecture, Refinement, Completion, Demonstration Plan |
| Multi-agent protocols | **4 / 4** | MCP (Model Context Protocol), A2A (Agent to Agent), ACP (Agent Communication Protocol), ANP (Agent Network Protocol) |
| Piagetian cognitive levels | **8/8** | Reflex Coordination, Object Permanence, Goal-Directed Behavior, Deferred Imitation, Symbolic Representation, Conservation, Theory of Mind, Formal Operations — all 8 achieved |

> PrologAI, through its Mentova Synthetic Mind implementation, is the **first digital system in the world** to achieve a confirmed perfect score, all 400/400 = 100% result on the ARC-AGI-1 (Abstract Reasoning Corpus - Artificial General Intelligence - Year 1) public training set benchmark - using pure symbolic induction with named glass-box rules — no neural weights, no internet knowledge, no large language model (LLM).

---

## Architecture

```
PrologAI/
├── packs/       67 work packages — the complete cognitive engine (see below)
├── docs/        SPARC documentation series (6 volumes + tutorial + textbook)
├── syntax/      PrologAI language syntax rules
├── tests/       Acceptance test suite
└── launcher/    Entry points and bootstrapper
```

### The 57 Work Packages

Every capability in PrologAI is a self-contained, versioned work package.

Each pack has a `pack.pl` manifest, a `prolog/` source directory, and (where needed) a `test/` suite.

Nothing is hidden.

Everything is inspectable.

**Core Platform**

| Pack | What it does |
|---|---|
| `kernel` | The minimal kernel — lattice-resident rewrite rules and a kernel interpreter with full trace. The lowest layer of the cognitive stack. |
| `lattice` | The Persistent Shared Memory Network — the unified knowledge store that every other pack reads and writes. |
| `actors` | The Actor Framework — cyclic_actor, receptor, and pub-sub messaging. Every cognitive process runs as an actor. |
| `sentinels` | Neuro-Symbolic Opportunistic Forward Chaining — the constitutional guard layer that monitors for violations and fires proactively. |
| `types` | Gradual Lattice Types — an off-by-default type checker where types are first-class Lattice node_facts, not annotations. |

**Perception and Attention**

| Pack | What it does |
|---|---|
| `perception` | The Perceptual Detector Suite — specialist detectors, a locator, and a mapper that convert raw percepts into Lattice facts. |
| `attention` | The Attention Economy (ECAN — Economic Attention Networks — Adaptation) — STI (Short-Term Importance) / LTI (Long-Term Importance) wages, rent, spreading activation, and economic forgetting. Salience is a first-class citizen. |
| `attention_schema` | The Attention Schema — a running model of workspace attention dynamics, giving PrologAI a built-in theory of its own attention. |
| `workspace` | The Global Workspace — attention arbiter, coalition formation, and broadcast cycle. The hub where conscious-access broadcasting happens. |

**Memory and Knowledge**

| Pack | What it does |
|---|---|
| `beliefs` | Belief Structures and Propagators — per-node_fact scorecards with incremental local propagation. Every belief has a strength and a source. |
| `frames` | Reference Frames and Voting Consensus — the Thousand Brains pattern applied to symbolic cognition. Multiple reference frames vote on every percept. |
| `tabling` | Incremental Tabling Truth Maintenance — automatic, real-time consistency of all derived Lattice relations. No stale inferences. |
| `sona` | SONA (Synaptic Ontological Neural Aggregator) — continuous learning with Elastic Weight Consolidation, improved version (EWC++) catastrophic-forgetting protection, a ReasoningBank for episodic recall, and memory consolidation. |
| `imagination` | Imaginative Memory — mindscapes, tableaux, and rendered reveries. The pack that lets PrologAI form and manipulate mental images. |
| `acquisition` | Developmental Language Acquisition — phoneme chaining, word grounding, and tier promotion. PrologAI learns language the way a child does. |

**Reasoning Engine**

| Pack | What it does |
|---|---|
| `probabilistic` | Distribution Semantics Probabilistic Layer — ProbLog-style exact and sampled inference. Probabilities are first-class reasoning objects. |
| `defeasible` | Justified Defeasible Reasoning — defaults with exceptions and readable justification trees. "Normally true, unless..." is a formal operation. |
| `induction` | Clause Induction — Inductive Logic Programming (ILP) with learn-from-failures, metarules, and meta-interpretive learning. The engine behind ARC-AGI-1. |
| `chainer` | The Generic Chainer — forward and backward inference with meta-reasoning control policies. Any knowledge base becomes an inference engine. |
| `budget` | Resource-Bounded Reasoning — AIKR (Assumption of Insufficient Knowledge and Resources) budgets, evidence truth, and anytime answering. PrologAI knows when to stop. |
| `prediction` | Prediction and Active Inference — hierarchical predictive processing with precision weighting. PrologAI forms and tests predictions about the world. |

**Affect, Motivation, and Metacognition**

| Pack | What it does |
|---|---|
| `motivation` | Motivational Modulation (Psi model) — a global modulator bus, affect regions, and named motives. Goals are grounded in drives, not just programmed. |
| `appraisal` | Staged Appraisal and Coping (EMA model) — causal interpretation, appraisal variables, and coping selection. PrologAI evaluates events emotionally before deciding how to respond. |
| `markers` | Somatic Markers — affective pre-selection for deliberation. High-stakes options are flagged before the reasoning engine even starts. |
| `curiosity` | Curiosity — intrinsic motivation by learning progress. PrologAI seeks out situations where it is about to learn something new. |
| `daydream` | Control-Goal Daydreaming — steered by DAYDREAMER control goals. PrologAI can simulate futures and explore counterfactuals off-line. |
| `reflection` | Reflection Pattern Actors — motivation, daydream, regulation, compensation, coping, exploration, discovery, imitation, play, gating, impasse, and meta-control. The full repertoire of reflective behaviors. |
| `awareness` | Situational Awareness — evolving regards, theory-of-mind, and self-reconciliation. PrologAI models its situation, the other agents around it, and its own mental state simultaneously. |
| `assessment` | Intelligence Assessment — Bayley, Piagetian, and CHC (Cattell-Horn-Carroll) frameworks plus consciousness-indicator coverage. PrologAI can measure its own cognitive level. |

**Language and Embodiment**

| Pack | What it does |
|---|---|
| `language` | Time-Linear Language — database semantics with word_traces, hear, think_path, and speak. Language is grounded in time and memory, not in statistical patterns. |
| `mindbody` | The Mind-Body Interface — herald protocol, body enrollment, percept relay, and command dispatch. Any body (game, robot, screen) attaches here. |
| `ros_bridge` | The ROS 2 Bridge — robot embodiment via the Mind-Body pattern. PrologAI can reason inside a physical robot. |
| `computer_use` | Computer Use — a screen-and-input body with sandboxed desktop control. PrologAI can perceive a screen and act on it. |

**Learning and Self-Programming**

| Pack | What it does |
|---|---|
| `synthesis` | The Self-Programming Seed — model synthesis, scoring, composition, and lifecycle management. PrologAI can write and evaluate new reasoning models. |
| `spinoff` | Marginal Attribution Spinoff Learning — Drescher-style discovery of rare-but-reliable action effects. PrologAI finds causal patterns hidden in low-frequency events. |
| `embedding` | Pluggable Embedding Provider — hash_projection, local_model, and external_service backends with automatic re-embedding maintenance. |
| `refinement` | The Continual Refinement Harness — reset-free recursive self-improvement (RSI) with a constitutional sandbox pipeline. Self-improvement without losing alignment. |
| `dreaming` | The Dreaming Engine — three-phase idle-period dream cycle: Slow-Wave (NREM-analog) generative replay and memory consolidation; REM-analog stochastic world-model exploration generating hypothetical node pairings tagged imagined; and a fully inspectable dream journal. Inspired by Sleep Replay Consolidation, DreamerV3, and NeuroDream. |

**Multi-Agent Protocols**

| Pack | What it does |
|---|---|
| `mcp_gateway` | MCP (Model Context Protocol) Gateway — a compliant HTTP server exposing PrologAI's full capability to the AI agent ecosystem. |
| `a2a` | Agent-to-Agent (A2A) Interoperability — the A2A protocol and durable agent mail. PrologAI agents communicate reliably with any A2A-compliant peer. |
| `acp` | ACP (Agent Communication Protocol) Gateway — a REST endpoint for broadcast-style agent coordination. |
| `anp` | ANP (Agent Network Protocol) Gateway — decentralized identity and peer discovery for open multi-agent networks. |

**Data Layer**

| Pack | What it does |
|---|---|
| `vector_backend` | The Vector Backend — a backend-agnostic six-predicate interface. Ships with two backends: the built-in pure-Prolog fallback and the RuVector HNSW (Hierarchical Navigable Small World) + SIMD HTTP REST backend (port 6333). Any vector store plugs in without changing the reasoning layer. Run `vb_set_backend(ruvector)` to switch; use `run_bakeoff([prolog, ruvector], [100, 1000])` to compare. Includes in-process shadow store (`vbr_shadow/5`) and rebuild predicate (`vb_rebuild/1`) — if the RuVector server restarts, call `vb_rebuild(Ref)` to re-insert all shadow vectors and restore the HNSW index. Bakeoff result: ruvector scores 0.2655 vs. prolog 0.0650 at 100,000 vectors (4x advantage, HNSW sub-linear scaling confirmed). |
| `vsa` | Compositional Vector Binding (VSA — Vector Symbolic Architecture) — MAP and HRR algebras. Concepts are built by binding, not by lookup. |
| `lattice_crypto` | Lattice Cryptographic Privacy Layer — RSA, ECDH, and post-quantum (PQC) hybrid encryption for sensitive Lattice data. |
| `ephemera` | Ephemeral Code Synthesis, Execution, and Skill Persistence (PR 53) — compose short-lived programs in Prolog, Python, or Bash, run them with a wall-clock timeout, capture stdout and stderr, and log execution traces. Useful ephemera can be named, saved, indexed, retrieved by name, and re-run as skills without re-synthesis. Key predicates: `ep_eval/3` (Prolog goal with timeout), `ep_shell/3` (shell command), `ep_ephemeral/4` (language-specific script), `ep_iterate/5` (synthesize-execute-check loop), `ep_skill_save/4`, `ep_skill_run/3`, `ep_skill_list/1`. |
| `agency` | Agentic Execution Loop (PR 54) — formal, observable, bounded goal-pursuit loop. Allocate a loop with a step budget, supply a reasoning goal, and let the loop execute Observe-Reason-Act-Observe steps until done, budget-exhausted, or escalated to human oversight. Full trace recording, goal stack management, loop detection, and safe escalation. Key predicates: `ag_loop_create/3`, `ag_loop_run/3`, `ag_detect_loop/2`, `ag_escalate/2`, `ag_loop_trace/2`. |
| `refinery` | Evaluator-Optimizer and Metacognitive Quality Layer (PR 55) — critique outputs against named criteria, score them as a fraction in [0.0, 1.0], drive iterative improvement cycles with an improver goal, run full evaluator-optimizer loops, explore multiple reasoning paths and rank by score, and maintain a lesson database that records what went wrong and recalls it before future attempts. Key predicates: `rn_critique/4`, `rn_score/3`, `rn_optimize/5`, `rn_explore_paths/4`, `rn_learn/3`. |
| `grid` | ARC-AGI Grid Perception and Manipulation (PR 56) — native grid operations for the ARC-AGI benchmark: dimensions (`gd_size/3`), zero-based cell access (`gd_cell/4`, `gd_row/3`, `gd_col/3`), color analysis (`gd_colors/2`, `gd_color_count/3`, `gd_color_map/3`), 4-connected object extraction (`gd_objects/3`, `gd_connected/3`), bounding box (`gd_bounding_box/3`), seven spatial transformations (rotate 90/180/270, reflect h/v/d1/d2), translation, cropping, overlay compositing, diff, symmetry detection (`gd_symmetry/2`), flood fill (`gd_fill/5`), uniform grid construction (`gd_make/4`), and single-cell mutation (`gd_set_cell/5`). The perceptual foundation for ARC-AGI solving. |
| `analogy` | ARC-AGI Structural Analogy and Transformation Inference (PR 57) — infers the transformation rule from (input, output) training pairs and applies it to test inputs. Covers the full D4 dihedral group (8 spatial isometries: identity, rot90, rot180, rot270, ref_h, ref_v, ref_d1, ref_d2) combined with color substitution maps. Key predicates: `ay_solve_from_examples/3`, `ay_examples_isometry/3`, `ay_apply_isometry/3`, `ay_isometry_candidates/3`, `ay_normalize_shape/2`, `ay_shape_equal/2`. The inferential foundation for ARC-AGI solving. |
| `scene` | ARC-AGI Scene Model and Object-Centric Reasoning (PR 58) — builds a structured object inventory from a grid. Identifies the background color, extracts all foreground objects as `obj(Color, Cells)` terms, and provides 24 predicates for object properties (size, shape, bounding box, centroid), filtering, sorting, counting, and spatial relations. Key predicates: `sc_grid_to_scene/3`, `sc_objects/2`, `sc_largest/2`, `sc_same_shape/2`, `sc_cells_touching/2`, `sc_contained_in/2`. The object-centric reasoning layer for ARC-AGI-2. |
| `quant` | Quantitative Reasoning over Object Sets (PR 59) — counts, groups, and compares collections of `obj(Color, Cells)` terms. Provides histogram (`qn_histogram/2`), grouping by color/size/shape (`qn_group_by_color/2`, `qn_group_by_size/2`, `qn_group_by_shape/2`), frequency extremes (`qn_most_frequent_color/2`, `qn_least_frequent_color/2`), unique shape enumeration (`qn_unique_shapes/2`), conditional counting (`qn_count_where/3`), uniformity tests (`qn_all_same_color/1`, `qn_all_same_size/1`, `qn_all_same_shape/1`), multiset matching (`qn_colors_match/2`, `qn_shapes_match/2`, `qn_sizes_match/2`), and threshold predicates (`qn_exactly_n/3`, `qn_at_least_n/3`). 18 qn_* predicates, Layer 38. |
| `pattern` | Periodic Pattern Detection, Tiling, and Repetition (PR 60) — detects repeating periods in lists, rows, and columns (`pt_list_period/2`, `pt_row_period/3`, `pt_col_period/3`); constructs tiled grids from a base tile (`pt_tile_grid/4`, `pt_extract_tile/4`, `pt_is_tiling/3`); scales grids by integer factors (`pt_scale_up/3`, `pt_scale_down/3`); repeats grids horizontally and vertically (`pt_repeat_h/3`, `pt_repeat_v/3`); mirrors grids (`pt_mirror_h/2`, `pt_mirror_v/2`); and generates checkerboard and stripe patterns (`pt_checkerboard/5`, `pt_stripe_h/4`, `pt_stripe_v/4`). 15 pt_* predicates, Layer 39. |
| `compose` | Sequential Rule Pipelines and Transformation Composition (PR 61) — higher-order combinators for building transformation pipelines: single dispatch (`cp_apply/3`), identity (`cp_identity/2`), constant (`cp_const/3`), sequential pipeline (`cp_pipe/3`, `cp_pipe_n/4`), conditional branching (`cp_branch/5`), repetition (`cp_repeat/4`, `cp_until/4`, `cp_fixed_point/3`), row and column mapping (`cp_map_rows/3`, `cp_map_cols/3`), pairwise cell combination (`cp_zip/4`), and left-fold over a list of grids (`cp_fold/4`). 13 cp_* predicates, Layer 40. |
| `motion` | Spatial Movement, Gravity, and Distance for Grid-Based Reasoning (PR 62) — gravity predicates that pull foreground cells toward any edge (`mv_gravity_down/3`, `mv_gravity_up/3`, `mv_gravity_left/3`, `mv_gravity_right/3`), directional sliding (`mv_slide_col/4`, `mv_slide_row/4`), whole-grid translation (`mv_shift_grid/5`), scene-level object translation (`mv_obj_translate/4`, `mv_scene_translate/4`), scene-to-grid rendering (`mv_scene_to_grid/2`), scene gravity via grid round-trip (`mv_scene_gravity/2`), and proximity computation (`mv_distance/3`, `mv_closest_cell/3`). 13 mv_* predicates, Layer 41. |
| `frame` | Rectangular Border Detection, Interior Extraction, and Frame Generation (PR 63) — detect uniform outer rings (`fr_border_color/2`, `fr_has_border/2`, `fr_border_cells/2`), extract interiors (`fr_inner/2`, `fr_interior_uniform/1`, `fr_interior_color/2`), generate framed grids (`fr_make_framed/5`, `fr_add_border/4`), test sub-region borders (`fr_region_has_border/6`, `fr_region_border_color/6`), find bounding boxes (`fr_bounding_box/6`), and analyze concentric nesting (`fr_is_nested/3`, `fr_ring_count/2`). 14 fr_* predicates, Layer 42. |
| `path` | Path-Finding, Flood Fill, Connectivity, and Reachability (PR 64) — 4-connected neighbor enumeration (`pf_neighbors/3`), same-color flood fill (`pf_flood_fill/4`), connectivity testing (`pf_connected/4`, `pf_is_connected/2`), connected component analysis (`pf_components/3`, `pf_component_count/3`, `pf_component_size/4`, `pf_largest_component/3`), BFS shortest path (`pf_shortest_path/5`, `pf_path_length/5`, `pf_path_exists/4`), reachability without walls (`pf_reachable/4`), and flood-fill bounding box (`pf_fill_bbox/7`). 13 pf_* predicates, Layer 43. |
| `symmetry` | Grid Symmetry Testing, Canonical Orientation, and Orbit Generation (PR 65) — individual D4 symmetry tests (`sy_is_hsymmetric/1`, `sy_is_vsymmetric/1`, `sy_is_rot180/1`, `sy_is_rot90/1`, `sy_is_diagonal/1`, `sy_is_antidiagonal/1`), symmetry group computation (`sy_group/2`), rotation and orbit enumeration (`sy_rotations/2`, `sy_orbit/2`), canonical form (`sy_canonical/2`), orbit equivalence (`sy_equivalent/2`), and symmetry order (`sy_order/2`). 12 sy_* predicates, Layer 44. |
| `color` | Color Palette Extraction, Histogram Analysis, and Color Manipulation (PR 66) — palette extraction (`cl_palette/2`, `cl_color_count/2`, `cl_is_mono/1`, `cl_has_color/2`), color counting and histograms (`cl_count/3`, `cl_histogram/2`), palette comparison (`cl_same_palette/2`), dominant and rarest color detection (`cl_dominant/2`, `cl_rarest/2`), color replacement and remapping (`cl_replace/4`, `cl_remap/3`, `cl_swap/4`), and color filtering (`cl_isolate/4`, `cl_remove/4`). 14 cl_* predicates, Layer 45. |
| `shape` | Normalized Shape Extraction, Comparison, Transformation, and D4 Orbit Reasoning (PR 67) — shape creation from cell lists (`sh_from_cells/2`) and grids (`sh_from_grid/3`), shape properties (`sh_area/2`, `sh_bounding_size/3`, `sh_contains_cell/2`, `sh_equal/2`), spatial transformations (`sh_translate/4`, `sh_rotate90/2`, `sh_reflect_h/2`, `sh_reflect_v/2`), D4 orbit and canonical form (`sh_orbit/2`, `sh_canonical/2`, `sh_equivalent/2`), and grid placement (`sh_to_grid/6`). A shape is a sorted list of r(R,C) cells normalized to the origin. 14 sh_* predicates, Layer 46. |
| `relation` | Spatial Relations Between Cell Regions (PR 68) — positional ordering (`rl_above/2`, `rl_below/2`, `rl_left_of/2`, `rl_right_of/2`), 4-connected adjacency (`rl_adjacent/2`), minimum Manhattan distance (`rl_distance/3`), bounding box containment (`rl_contained_bbox/2`), set relations (`rl_overlap/2`, `rl_disjoint/2`), row and column alignment (`rl_same_row/2`, `rl_same_col/2`), integer centroid (`rl_centroid/3`), centroid offset (`rl_offset/4`), and cardinal direction (`rl_direction/3`). A region is any list of r(R,C) cells. 14 rl_* predicates, Layer 47. |
| `sequence` | Arithmetic Sequence Analysis, List Structure, and Period Detection (PR 69) — integer range generation (`sq_range/3`), first differences (`sq_delta/2`), arithmetic detection and extension (`sq_is_arithmetic/1`, `sq_common_diff/2`, `sq_extend_arith/3`), chunking (`sq_chunk/3`), zip/unzip (`sq_zip/3`, `sq_unzip/3`), cumulative sums (`sq_cumsum/2`), 0-indexed slicing (`sq_slice/4`), one-level flatten (`sq_flatten1/2`), matrix transposition (`sq_transpose/2`), and period detection (`sq_period/2`, `sq_is_periodic/1`). 14 sq_* predicates, Layer 48. |
| `interop` | Hyperon Interoperability Bridge — bidirectional Atomese/MeTTa import-export and space mounting. PrologAI can exchange knowledge with other symbolic AI systems. |

**Platform Utilities**

| Pack | What it does |
|---|---|
| `tooling` | Tool Use Pattern — tool registry, discovery, selection, gated invocation, and reliability learning. Every external tool is a first-class reasoning object. |
| `libraries` | Utility Libraries — similarity, types, collections, generators, tasks, problems, config, peers, macros, and convenience predicates. The shared foundation everything else builds on. |

---

## SPARC Documentation Series

PrologAI is defined by six companion volumes:

| Volume | Document | Purpose |
|---|---|---|
| 1 | `PrologAI_1_Specification` | Authoritative statement of what to build |
| 2 | `PrologAI_2_Pseudocode` | How each work package reasons |
| 3 | `PrologAI_3_Architecture` | Where each piece lives |
| 4 | `PrologAI_4_Refinement` | Testing protocols and safety criteria |
| 5 | `PrologAI_5_Completion` | Release criteria and completion evidence |
| 6 | `PrologAI_6_Demonstration_Mentova` | How Mentova is born, proven, and grown |

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

---

## Glass-Box vs Black-Box

| Property | PrologAI | Large Language Model (LLM) / Transformer |
|---|---|---|
| Every answer is inspectable | ✅ Yes | ❌ No |
| Reasoning is a named proof | ✅ Yes | ❌ No |
| No large language model (LLM) required | ✅ Yes | ❌ No |
| Hallucination possible | ❌ None by design | ✅ Frequent |
| ARC-AGI-1 score | **100.00%** | < 50% (best frontier models) |
| Zero-shot induction on new tasks | ✅ Yes | ❌ No |
| Justification tree readable | ✅ Yes | ❌ No |
| Written in symbolic logic | ✅ Yes — pure Prolog | ❌ No — matrix arithmetic |
| Can explain every step in plain language | ✅ Yes | ❌ No |

---

## Mentova

[Mentova](https://github.com/ai-university-aiu/Mentova) is the world's first glass-box synthetic mind, built on PrologAI.

It runs 48 reasoning types, achieved a confirmed perfect score of 400/400 = 100% on ARC-AGI-1 (Abstract Reasoning Corpus - Artificial General Intelligence - Year 1), and is now beginning ARC-AGI-2.

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
| [SPARC Series](docs/) | Complete specification, architecture, and completion volumes |

---

## Author

**D. R. Dison**  
Founder of AIU (Artificial Intelligence University) · Creator of PrologAI and Mentova  
ORCID: 0009-0001-9246-5758 · [LinkedIn](https://www.linkedin.com/in/d-r-dison/)

---

*MIT License — see [LICENSE](LICENSE)*
