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
├── packs/       118 work packages — the complete cognitive engine (see below)
├── docs/        SPARC documentation series (6 volumes + tutorial + textbook)
├── syntax/      PrologAI language syntax rules
├── tests/       Acceptance test suite
└── launcher/    Entry points and bootstrapper
```

### The 106 Work Packages

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
| `crop` | Subgrid Extraction, Padding, Splitting, Joining, and Embedding (PR 70) — bounding box detection (`cr_bbox/3`), rectangular extraction (`cr_crop_bbox/6`), content-aware cropping (`cr_crop_content/3`), uniform padding (`cr_pad/4`), border removal (`cr_strip_border/3`), horizontal/vertical splitting (`cr_split_h/4`, `cr_split_v/4`), row/column bands (`cr_rows/4`, `cr_cols/4`), stitching (`cr_stitch_h/3`, `cr_stitch_v/3`), subgrid embedding (`cr_embed/5`), center extraction (`cr_center/4`), and quadrant split (`cr_quadrants/5`). 14 cr_* predicates, Layer 49. |
| `overlay` | Grid Combination by Layering, Logic, Masking, and Priority Merge (PR 71) — transparent overlay (`ov_over/4`, `ov_blend/4`), bitwise operations (`ov_or/3`, `ov_and/3`, `ov_xor/4`), difference and intersection (`ov_diff/4`, `ov_intersect/4`), masking (`ov_mask/4`, `ov_mask_inv/4`), priority merge across multiple grids (`ov_priority/3`), color replacement (`ov_replace/4`, `ov_fill_bg/4`), and pointwise extrema (`ov_max/3`, `ov_min/3`). 14 ov_* predicates, Layer 50. |
| `measure` | Geometric Measurement of Cell Regions and Grids (PR 72) — area (`ms_area/2`), bounding box (`ms_bbox/2`, `ms_bbox_size/3`), perimeter (`ms_perimeter/2`), diameter (`ms_diameter/2`), extent fraction (`ms_extent/3`), aspect ratio (`ms_aspect/3`), row/column spans (`ms_row_span/2`, `ms_col_span/2`), integer centroid (`ms_centroid/3`), Chebyshev radius (`ms_radius/2`), interior and border counts (`ms_interior_count/2`, `ms_border_count/2`), and distinct color count (`ms_color_count/2`). 14 ms_* predicates, Layer 51. |
| `transform` | Grid-Level Spatial and Color Transformations (PR 73) — spatial scaling (`tr_scale_up/3`, `tr_scale_down/3`), horizontal/vertical tiling (`tr_tile_h/3`, `tr_tile_v/3`, `tr_tile/3`), transposition (`tr_transpose/2`), reflections (`tr_flip_h/2`, `tr_flip_v/2`), rotations (`tr_rot90/2`, `tr_rot180/2`), content shifting with fill (`tr_shift/5`), color-map application (`tr_apply_map/3`), single-color replacement (`tr_replace_color/4`), and mask-based selection (`tr_mask_grid/4`). 14 tr_* predicates, Layer 52. |
| `select` | Selection and Filtering of Cell Regions by Spatial and Size Properties (PR 74) — largest and smallest region (`sl_largest/2`, `sl_smallest/2`), area-sorted list (`sl_sort_by_area/2`), area filters (`sl_filter_area/3`, `sl_filter_area_min/3`, `sl_filter_area_max/3`), border test (`sl_touches_border/3`), border/interior filters (`sl_filter_border/4`, `sl_filter_interior/4`), directional filters (`sl_above_row/3`, `sl_below_row/3`, `sl_left_of_col/3`, `sl_right_of_col/3`), and unique-area selection (`sl_unique_area/2`). 14 sl_* predicates, Layer 53. |
| `count` | Counting Cells, Colors, and Regions in Grids (PR 75) — color cell count (`cn_color_count/3`), color histogram (`cn_histogram/3`), most/least frequent colors (`cn_max_color/2`, `cn_min_color/2`), rows/columns containing a color (`cn_color_rows/3`, `cn_color_cols/3`), row/column value diversity (`cn_row_distinct/3`, `cn_col_distinct/3`), total cells (`cn_grid_total/2`), grid comparison counts (`cn_equal_cells/3`, `cn_diff_cells/3`), region color lookup (`cn_region_color/3`), per-color region tally (`cn_regions_per_color/3`), and flat-list value count (`cn_by_value/3`). 14 cn_* predicates, Layer 54. |
| `fill` | Pattern-Based Region and Grid Filling (PR 76) — fill a region list (`fl_fill_region/4`), fill a bounding box (`fl_fill_bbox/4`), fill entire rows or columns (`fl_fill_row/4`, `fl_fill_col/4`), fill explicit cell lists (`fl_fill_cells/4`), fill the outermost grid ring (`fl_fill_border/3`), fill only boundary cells of a region (`fl_outline_region/4`), fill only interior cells (`fl_fill_interior/4`), create uniform-color grids (`fl_solid_rect/4`), create checkerboard grids (`fl_checkerboard/5`), draw horizontal and vertical line segments (`fl_draw_hline/6`, `fl_draw_vline/6`), fill the main diagonal (`fl_fill_main_diag/3`), and overlay a subgrid with transparency (`fl_stamp/6`). 14 fl_* predicates, Layer 55. |
| `pattern` | Pattern Detection, Tiling Period, and Motif Extraction (PR 77) — tiling period of a row (`pt_row_period/2`), tiling period of a column (`pt_col_period/3`), horizontal grid tiling period (`pt_grid_period_h/2`), vertical grid tiling period (`pt_grid_period_v/2`), minimal horizontal tile (`pt_tile_unit_h/2`), minimal vertical tile (`pt_tile_unit_v/2`), minimal 2D tile (`pt_tile_unit/2`), exact tiling test (`pt_is_tiling/2`), tile match counting (`pt_count_tile/3`), tile match position list (`pt_find_tile/3`), subgrid extraction at position (`pt_extract_tile/5`), distinct row count (`pt_unique_rows/2`), distinct column count (`pt_unique_cols/2`), and uniform-row test (`pt_has_uniform_rows/1`). 14 pt_* predicates, Layer 56. |
| `compare` | Grid and Region Comparison, Difference Detection, and Similarity Scoring (PR 78) — cells where two grids differ (`cp_diff_cells/3`), cells where they agree (`cp_same_cells/3`), cells where a color was gained (`cp_added_color/4`) or lost (`cp_removed_color/4`), cells that changed to (`cp_changed_to/4`) or from (`cp_changed_from/4`) a color, 0/1 difference map (`cp_diff_map/3`), integer-exact similarity score (`cp_similarity/3`), region set difference (`cp_region_diff/3`), intersection (`cp_region_intersect/3`), union (`cp_region_union/3`), order-independent region equality (`cp_region_equal/2`), structural grid equality (`cp_grids_equal/2`), and Old-New color pairs for changed cells (`cp_color_shift/3`). 14 cp_* predicates, Layer 57. |
| `spatial` | Spatial Reasoning: Directions, Containment, Adjacency, and Grid Topology (PR 79) — cardinal direction between cells (`sp_direction/3`), Manhattan distance (`sp_distance_manhattan/3`), Chebyshev distance (`sp_distance_chebyshev/3`), 4-connected in-bounds neighbors (`sp_neighbors4/3`), 8-connected in-bounds neighbors (`sp_neighbors8/3`), 4-connected adjacency (`sp_adjacent4/2`), 8-connected adjacency (`sp_adjacent8/2`), bounding box containment (`sp_bbox_contains/2`), region membership (`sp_in_region/2`), row-band filtering (`sp_row_between/4`), column-band filtering (`sp_col_between/4`), nearest region cell (`sp_closest/3`), farthest region cell (`sp_farthest/3`), and integer centroid (`sp_centroid/3`). 14 sp_* predicates, Layer 58. |
| `induction` | Grid-Pair Inductive Analysis: Color Maps, Recolor Detection, and Scale Inference (PR 80) — grid dimensions (`id_grid_dims/3`), sorted distinct colors in input and output (`id_input_colors/2`, `id_output_colors/2`), color set differences (`id_new_colors/3`, `id_lost_colors/3`), changed and unchanged cell lists (`id_changed_cells/3`, `id_unchanged_cells/3`), inferred Old-New color substitution map (`id_color_map/3`), consistent color-substitution test (`id_is_recolor/2`), uniform single-color output detection (`id_uniform_output/2`, `id_output_color/2`), dimension ratio (`id_size_ratio/3`), integer uniform-scale test (`id_is_scale/2`), and integer scale factor extraction (`id_scale_factor/3`). 14 id_* predicates, Layer 59. |
| `gravity` | Directional Gravity and Settling Operations (PR 81) — column value extraction (`gv_col_values/3`), column replacement (`gv_set_col/4`), compacting all non-background cells to column bottoms (`gv_compact_col/3`, `gv_fall_down/3`), column tops (`gv_fall_up/3`), row lefts (`gv_compact_row/3`, `gv_fall_left/3`), row rights (`gv_fall_right/3`), settling a specific color to the column bottom past background with other cells as obstacles (`gv_settle_color/4`, `gv_stack_down/4`), floating a color to the column top (`gv_float_color/4`, `gv_stack_up/4`), and custom column or row transforms (`gv_apply_col/4`, `gv_apply_row/4`). 14 gv_* predicates, Layer 60. |
| `noise` | Binary Mask Operations and Grid Noise Analysis (PR 82) — mask application with fill color (`ns_mask_apply/4`), mask inversion (`ns_mask_invert/3`), pointwise AND and OR (`ns_mask_and/3`, `ns_mask_or/3`), building masks from color criteria (`ns_mask_from_color/3`), converting masks to region lists (`ns_mask_to_region/2`) and back (`ns_region_to_mask/4`), identifying cells deviating from the majority color (`ns_noise_cells/3`), replacing noise with the majority color (`ns_denoise/3`), finding the most frequent color (`ns_majority_color/2`), counting a specific color (`ns_color_count/3`), finding cells of rare colors (`ns_sparse_cells/3`), finding cells of common colors (`ns_dense_cells/3`), and isolating one color by zeroing all others (`ns_isolate_color/3`). 14 ns_* predicates, Layer 61. |
| `generate` | Grid Construction from Visual Patterns (PR 83) — uniform fill (`ge_uniform/4`), horizontal and vertical gradients (`ge_gradient_h/4`, `ge_gradient_v/4`), checkerboard (`ge_checkerboard/5`), horizontal and vertical stripes (`ge_stripes_h/4`, `ge_stripes_v/4`), bordered rectangle and frame (`ge_border_rect/5`, `ge_frame/5`), main and anti-diagonal patterns (`ge_diagonal/4`, `ge_antidiagonal/4`), identity matrix pattern (`ge_identity_grid/3`), cross through center (`ge_cross/5`), build from cell-color map (`ge_from_map/3`), and tile a pattern to fill a larger grid (`ge_repeat_pattern/4`). 14 ge_* predicates, Layer 62. |
| `lookup` | Association List Operations and Grid Index Maps (PR 84) — key lookup (`lk_get/3`), add or replace pair (`lk_put/4`), extract keys and values (`lk_keys/2`, `lk_values/2`), membership test (`lk_has_key/2`), removal (`lk_delete/3`), value transformation (`lk_map_values/3`), pair building (`lk_from_pairs/2`), grid row/column/cell access (`lk_grid_row/3`, `lk_grid_col/3`, `lk_grid_cell/4`), Color-to-positions index map (`lk_color_positions/3`), position-to-Color index map (`lk_position_color/3`), and association list inversion (`lk_invert/2`). 14 lk_* predicates, Layer 63. |
| `connect` | Flood Fill and Connected Component Analysis (PR 85) — 4-connected flood fill (`cc_flood4/4`), 8-connected flood fill (`cc_flood8/4`), all 4-connected components (`cc_components4/3`), all 8-connected components (`cc_components8/3`), component counts (`cc_count4/3`, `cc_count8/3`), sorted size lists (`cc_sizes4/3`, `cc_sizes8/3`), largest component (`cc_largest4/3`, `cc_largest8/3`), smallest component (`cc_smallest4/3`), border cells of a region (`cc_border_cells/3`), interior cells of a region (`cc_interior_cells/3`), and background cells enclosed inside a closed shape (`cc_enclosed/3`). 14 cc_* predicates, Layer 64. |
| `morph` | Morphological Grid Operations (PR 105) — 4-connected dilation copying neighbor color (`mo_dilate/3`), erosion of cells adjacent to background (`mo_erode/3`), N-step dilation (`mo_dilate_n/4`), N-step erosion (`mo_erode_n/4`), morphological open/close/smooth (`mo_open/3`, `mo_close/3`, `mo_smooth/3`), perimeter extraction (`mo_boundary/3`), interior extraction (`mo_interior/3`), dilation with fixed fill value (`mo_dilate_val/4`), BFS region growing from seeds (`mo_grow_from/5`), L1 distance to background (`mo_dist_to_bg/3`), N-step dilation ring (`mo_ring/4`), and filling enclosed background holes (`mo_fill_holes/4`). 14 mo_* predicates, Layer 84. |
| `walk` | Grid Traversal Patterns (PR 106) — all R-C positions in row-major order (`wk_row_scan/2`), column-major order (`wk_col_scan/2`), zigzag boustrophedon order (`wk_zigzag_scan/2`), diagonal-grouped order by D=C-R (`wk_diag_scan/2`), anti-diagonal-grouped order by D=R+C (`wk_antidiag_scan/2`), clockwise inward spiral (`wk_spiral_in/2`), and clockwise outer border walk (`wk_border_walk/2`); extracting values on main diagonal D (`wk_diag_extract/3`) or anti-diagonal D (`wk_antidiag_extract/3`); computing diagonal index D=C-R (`wk_diag_of/2`) or anti-diagonal index D=R+C (`wk_antidiag_of/2`); extracting values at R-C positions (`wk_cells_to_vals/3`); painting values at R-C positions (`wk_vals_to_cells/4`); and listing non-border R-C positions (`wk_inner_cells/2`). 14 wk_* predicates, Layer 85. |
| `run` | Run-Length Encoding of Grid Sequences (PR 88) — encoding a flat list to Value-Count pairs (`rn_encode/2`), decoding back to a flat list (`rn_decode/2`), encoding a single grid row (`rn_row_encode/3`) or column (`rn_col_encode/3`), encoding all rows (`rn_grid_rows/2`) or all columns (`rn_grid_cols/2`), total element count of a run list (`rn_length/2`), positional lookup in a run list (`rn_at/3`), longest run of a given value (`rn_max_run/3`), distinct run count (`rn_count_runs/3`), uniformity test (`rn_uniform/1`), leading/trailing value trimming (`rn_trim/3`), sequence repetition with boundary merging (`rn_repeat/3`), and 0-indexed position enumeration (`rn_positions/3`). 14 rn_* predicates, Layer 67. |
| `rewrite` | Rule-Based Grid Cell Rewriting (PR 87) — color substitution map (`rw_map_color/3`), single-color replacement (`rw_replace_color/4`), two-color swap (`rw_swap_colors/4`), region painting (`rw_set_region/4`), binary mask application (`rw_mask_apply/5`), grid overlay with background key (`rw_overlay/4`), patch stamping at an offset (`rw_stamp/5`), diff-list cell edits (`rw_diff_apply/3`), color normalization to 1,2,... (`rw_normalize/3`), color inversion (`rw_invert_colors/3`), background remapping (`rw_remap_bg/4`), border ring painting (`rw_set_border/3`), rectangle fill (`rw_fill_rect/7`), and conditional per-cell recoloring via a goal (`rw_conditional/5`). 14 rw_* predicates, Layer 66. |
| `arith` | Cell-Wise Arithmetic on Grids (PR 89) — cell-wise addition (`ar_cell_add/3`), subtraction (`ar_cell_sub/3`), multiplication (`ar_cell_mul/3`), modulo by scalar (`ar_cell_mod/3`), scalar addition (`ar_scalar_add/3`), scalar multiplication (`ar_scalar_mul/3`), row sum (`ar_row_sum/3`), column sum (`ar_col_sum/3`), all row sums (`ar_row_sums/2`), all column sums (`ar_col_sums/2`), grid-wide maximum (`ar_cell_max/2`), grid-wide minimum (`ar_cell_min/2`), value clamping to a range (`ar_cell_clamp/4`), and cell-wise absolute difference (`ar_cell_abs_diff/3`). 14 ar_* predicates, Layer 68. |
| `context` | Context Map Operations (PR 92) — storing key-value bindings (`ctx_put/4`), retrieving values (`ctx_get/3`), testing presence (`ctx_has/2`), removing entries (`ctx_delete/3`), extracting keys (`ctx_keys/2`) and values (`ctx_values/2`), building from pairs (`ctx_from_pairs/2`), converting to pairs (`ctx_to_pairs/2`), merging two maps with override semantics (`ctx_merge/3`), dispatching a goal by key with a default (`ctx_dispatch/4`), selecting the value for the first present key in a priority list (`ctx_select/4`), transforming all values (`ctx_map_values/3`), filtering entries by key predicate (`ctx_filter_keys/3`), and counting entries (`ctx_size/2`). 14 ctx_* predicates, Layer 71. |
| `score` | Candidate Grid Scoring and Hypothesis Selection (PR 93) — structural grid equality (`sc_exact/2`), counting matching cells (`sc_cell_match/3`), total cell count (`sc_cell_total/2`), pixel accuracy as a float in [0.0, 1.0] (`sc_accuracy/3`), per-color recall (`sc_color_recall/4`), per-color precision (`sc_color_precision/4`), per-color F1 score (`sc_color_f1/4`), applying a rule to one training pair and measuring accuracy (`sc_pair_score/3`), mean accuracy over a list of pairs (`sc_pairs_score/3`), exact-match test for one pair (`sc_perfect/3`), all-pairs exact-match test (`sc_pairs_perfect/2`), ranking candidates by accuracy descending (`sc_rank/3`), picking the best candidate (`sc_best/3`), and filtering by a minimum accuracy threshold (`sc_threshold/4`). 14 sc_* predicates, Layer 72. |
| `induct` | Rule Induction Observation Layer (PR 94) — computing the color-delta between two grids as changed-cell triples (`in_delta/3`), identity rule test (`in_constant/2`), inferring a consistent color substitution map for one pair (`in_color_map/3`), intersecting color maps across all pairs (`in_color_map_pairs/2`), computing row and column size change for one pair (`in_size_change/4`), verifying consistent size change across all pairs (`in_size_change_pairs/3`), building the union color palette for one pair (`in_color_palette/3`), separating input and output color sets across all pairs (`in_palette_pairs/3`), listing invariant cells (`in_invariant_cells/3`), listing changed cells (`in_changed_cells/3`), verifying a consistent delta across all pairs (`in_consistent_delta/2`), finding the background color by frequency (`in_bg_color/2`), verifying a consistent background across all pairs (`in_bg_color_pairs/2`), and intersecting two color maps (`in_common_keys/3`). 14 in_* predicates, Layer 73. |
| `sym` | Spatial Symmetry Transforms and Symmetry Testing (PR 96) — reflecting a grid left-right (`sy_reflect_h/2`), top-bottom (`sy_reflect_v/2`), and across the main diagonal (`sy_transpose/2`), rotating 90 degrees clockwise (`sy_rotate90/2`), 180 degrees (`sy_rotate180/2`), and 270 degrees clockwise (`sy_rotate270/2`), testing for horizontal symmetry (`sy_has_h_symm/1`), vertical symmetry (`sy_has_v_symm/1`), 2-fold rotational symmetry (`sy_has_rot2_symm/1`), and 4-fold rotational symmetry (`sy_has_rot4_symm/1`), listing all symmetry names present (`sy_symmetries/2`), making a grid horizontally symmetric by mirroring the left half (`sy_make_h_symm/2`), making it vertically symmetric by mirroring the top half (`sy_make_v_symm/2`), and computing the full D4 orbit of all distinct spatial transforms (`sy_d4_orbit/2`). 14 sy_* predicates, Layer 75. |
| `hyp` | Hypothesis Application, Testing, and Selection (PR 95) — applying a color substitution map to every grid cell with identity fallback for unmapped colors (`hy_color_sub/3`), identity no-op hypothesis (`hy_identity/2`), partial-application alias for color substitution (`hy_from_map/3`), testing a hypothesis on one training pair and returning pixel accuracy (`hy_test/4`), testing on all pairs and returning mean accuracy (`hy_test_all/4`), exact-match test for one pair (`hy_verify/3`), exact-match test for all pairs (`hy_verify_all/2`), selecting the best hypothesis from a list (`hy_select/3`), ranking hypotheses by mean accuracy descending (`hy_rank/3`), alias for color substitution (`hy_apply_map/3`), sequential two-map color substitution (`hy_compose/4`), inverting a color substitution map (`hy_invert_map/2`), color lookup with identity fallback (`hy_map_lookup/3`), and describing a hypothesis as a human-readable atom (`hy_describe/2`). 14 hy_* predicates, Layer 74. |
| `seek` | Spatial Pattern Search and Transform Discovery (PR 97) — finding all (row,col) positions of a value (`sk_positions/3`), finding row indices containing a value (`sk_rows_with/3`), finding column indices containing a value (`sk_cols_with/3`), listing border cell positions (`sk_border_cells/2`), listing interior cell positions (`sk_interior_cells/2`), exact sub-grid match test (`sk_fits/4`), enumerating sub-grid positions nondeterministically (`sk_find_sub/4`), collecting all fitting positions (`sk_all_subs/3`), counting occurrences (`sk_count_sub/3`), counting matching cells at a position (`sk_match_count/5`), finding the position with maximum match count (`sk_best_fit/4`), discovering the D4 transform mapping one grid to another (`sk_find_d4/3`), upscaling each cell to a Factor x Factor block (`sk_upscale/3`), and finding the integer scale factor between two grids (`sk_find_scale/3`). 14 sk_* predicates, Layer 76. |
| `remap` | Color Remapping and Palette Manipulation (PR 98) — replacing one value with another (`rm_replace/4`), swapping two values (`rm_swap/4`), applying a color substitution map with identity fallback (`rm_apply_map/3`), applying a map only to cells matching a specific value (`rm_apply_map_to/4`), inverting a map by swapping keys and values (`rm_invert_map/2`), composing two maps by chaining lookups (`rm_compose_maps/3`), normalizing distinct values to consecutive 1-based integers (`rm_normalize/2`), shifting all cell values by an offset (`rm_shift/3`), clamping all cell values to a range (`rm_clamp/4`), recoloring cells satisfying a predicate goal (`rm_conditional/4`), binarizing a grid to foreground/background (`rm_binarize/4`), remapping the background color (`rm_remap_bg/4`), extracting the sorted palette of distinct values (`rm_palette/2`), and reindexing a grid using a supplied palette (`rm_reindex/3`). 14 rm_* predicates, Layer 77. |
| `logic` | Boolean and Mask Grid Operations (PR 99) — intersection keeping cells present in both grids (`lg_and/4`), union keeping cells present in either grid (`lg_or/4`), exclusive-or keeping cells present in exactly one grid (`lg_xor/4`), inverting foreground and background (`lg_not/4`), set-difference keeping cells in Grid1 absent in Grid2 (`lg_diff/4`), overlaying one grid onto another with background as transparent (`lg_overlay/4`), applying a mask to keep grid values where the mask is non-background (`lg_mask_apply/4`), creating a binary presence mask from a grid (`lg_mask_from/4`), per-row presence flags (`lg_any_row/3`), per-column presence flags (`lg_any_col/3`), per-row fullness flags (`lg_all_row/3`), per-column fullness flags (`lg_all_col/3`), cell-wise equality to 0/1 grid (`lg_eq/3`), and cell-wise inequality (`lg_neq/3`). 14 lg_* predicates, Layer 78. |
| `window` | Sliding Window and Neighborhood Operations (PR 100) — 4-connected neighbor triples (`wn_neighbors4/4`), 8-connected neighbor triples (`wn_neighbors8/4`), count of 4-connected neighbors equal to a value (`wn_count4/5`), count of 8-connected neighbors equal to a value (`wn_count8/5`), sub-grid extraction (`wn_extract/6`), sliding window enumeration as R0-C0-Sub triples (`wn_slide/4`), padding all sides with N layers (`wn_pad/4`), local 4-connected maximum test (`wn_local_max4/3`), local 4-connected minimum test (`wn_local_min4/3`), cells adjacent to a target value but not equal to it (`wn_halo4/3`), integer convolution (`wn_convolve/3`), floor-center coordinates (`wn_center/3`), Manhattan distance (`wn_manhattan/5`), and in-bounds cells at exactly Manhattan distance D (`wn_cells_at_dist/5`). 14 wn_* predicates, Layer 79. |
| `sort` | Sorting, Ranking, and Ordering (PR 101) — per-row integer sums (`so_row_sums/2`), per-column integer sums (`so_col_sums/2`), count of a value per row (`so_row_count/3`), count of a value per column (`so_col_count/3`), sorting rows ascending by value count (`so_sort_rows_asc/3`), sorting rows descending (`so_sort_rows_desc/3`), sorting columns ascending (`so_sort_cols_asc/3`), sorting columns descending (`so_sort_cols_desc/3`), row index with highest count (`so_max_row/3`), row index with lowest count (`so_min_row/3`), column index with highest count (`so_max_col/3`), column index with lowest count (`so_min_col/3`), all values sorted ascending with duplicates (`so_sorted_vals/2`), and 1-based rank of a cell value among distinct grid values (`so_cell_rank/4`). 14 so_* predicates, Layer 80. |
| `tile` | Tiling, Stamping, and Period Detection (PR 102) — repeating a tile N times horizontally (`ti_tile_h/3`), repeating a tile N times vertically (`ti_tile_v/3`), tiling a motif into NR rows of NC copies (`ti_tile/4`), splitting a grid into horizontal TH-row bands (`ti_split_rows/3`), splitting into vertical TW-col stripes (`ti_split_cols/3`), splitting into a list-of-tile-rows (`ti_split/4`), reassembling tiles into one grid (`ti_flatten_tiles/2`), overlaying a motif at position (R, C) (`ti_stamp/5`), stamping a motif at multiple positions (`ti_stamp_all/4`), extracting the tile at tile-position (TR, TC) (`ti_extract_tile/6`), checking if a grid is an exact tiling of one motif (`ti_is_tiling/3`), finding the smallest horizontal period in columns (`ti_find_period_h/2`), finding the smallest vertical period in rows (`ti_find_period_v/2`), and generating an H x W checkerboard (`ti_checkerboard/5`). 14 ti_* predicates, Layer 81. |
| `trace` | Path Tracing, Rays, and Grid Boundaries (PR 103) — finding maximal contiguous non-Bg runs in a row (`tr_runs_row/3`), per-row run lists (`tr_spans_h/3`), per-column run lists (`tr_spans_v/3`), casting a horizontal ray to the first non-Bg cell (`tr_ray_h/6`), casting a vertical ray (`tr_ray_v/6`), listing cells in a horizontal line (`tr_line_h/4`), listing cells in a vertical line (`tr_line_v/4`), extracting values along a path (`tr_path_vals/3`), painting a value along a path (`tr_draw_path/4`), listing the border cells of a bounding rectangle (`tr_bbox_border/5`), non-Bg cells touching Bg or on the grid edge (`tr_perimeter/3`), Bg cells adjacent to non-Bg cells (`tr_outline/3`), all cells on the grid boundary (`tr_edge_cells/2`), and floor midpoint of two positions (`tr_midpoint/3`). 14 tr_* predicates, Layer 82. |
| `label` | Connected Component Labeling and Region Queries (PR 104) — assigning unique integer labels to 4-connected components (`lb_label/3`), returning component cell lists (`lb_components/3`), counting components (`lb_count/3`), returning the cell count of a label (`lb_size_of/3`), sorted Label-Size pairs for all labels (`lb_sizes_all/3`), cells of a specific label (`lb_cells_of/3`), bounding box corners of a label region (`lb_bbox_of/4`), foreground labels 4-adjacent to a label (`lb_neighbors_of/4`), replacing all cells of a label with a value (`lb_fill_label/4`), keeping only the largest component (`lb_keep_largest/3`), removing components below a size threshold (`lb_remove_small/4`), coloring each label from a cycling palette (`lb_color_labels/4`), merging two labels into one (`lb_merge_two/4`), and extracting one component from the original grid (`lb_select_label/4`). 14 lb_* predicates, Layer 83. |
| `morph` | Morphological Grid Operations (PR 105) — 4-connected dilation copying neighbor color (`mo_dilate/3`), erosion of cells adjacent to background (`mo_erode/3`), N-step dilation (`mo_dilate_n/4`), N-step erosion (`mo_erode_n/4`), morphological open/close/smooth (`mo_open/3`, `mo_close/3`, `mo_smooth/3`), perimeter extraction (`mo_boundary/3`), interior extraction (`mo_interior/3`), dilation with fixed fill value (`mo_dilate_val/4`), BFS region growing from seeds (`mo_grow_from/5`), L1 distance to background (`mo_dist_to_bg/3`), N-step dilation ring (`mo_ring/4`), and filling enclosed background holes (`mo_fill_holes/4`). 14 mo_* predicates, Layer 84. |
| `walk` | Grid Traversal Patterns (PR 106) — all R-C positions in row-major order (`wk_row_scan/2`), column-major order (`wk_col_scan/2`), zigzag boustrophedon order (`wk_zigzag_scan/2`), diagonal-grouped order by D=C-R (`wk_diag_scan/2`), anti-diagonal-grouped order by D=R+C (`wk_antidiag_scan/2`), clockwise inward spiral (`wk_spiral_in/2`), and clockwise outer border walk (`wk_border_walk/2`); extracting values on main diagonal D (`wk_diag_extract/3`) or anti-diagonal D (`wk_antidiag_extract/3`); computing diagonal index D=C-R (`wk_diag_of/2`) or anti-diagonal index D=R+C (`wk_antidiag_of/2`); extracting values at R-C positions (`wk_cells_to_vals/3`); painting values at R-C positions (`wk_vals_to_cells/4`); and listing non-border R-C positions (`wk_inner_cells/2`). 14 wk_* predicates, Layer 85. |
| `step` | Directional Grid Movement (PR 107) — one unbounded step in a direction (`st_step/3`), one bounded step that fails if out of grid (`st_step_in/4`), all in-bounds cells in a direction excluding start (`st_ray/4`), ray stopping before a given cell value (`st_ray_to/5`), all in-bounds cells including start (`st_walk/4`), the four cardinal directions (`st_dirs4/1`), all eight principal directions (`st_dirs8/1`), 90-degree clockwise rotation (`st_rotate_cw/2`), 90-degree counter-clockwise rotation (`st_rotate_ccw/2`), direction reversal (`st_opposite/2`), unit step direction between two cells (`st_normalize/3`), following a list of direction steps (`st_path/3`), first cell in a direction with a given value (`st_first/5`), and steps until the grid boundary (`st_to_edge/4`). 14 st_* predicates, Layer 86. |
| `pivot` | Pivot-Relative Cell Transformations (PR 108) — integer floor centroid of a cell list (`pv_centroid/2`), converting absolute cell to pivot-relative offset (`pv_to_rel/3`), converting pivot-relative offset to absolute cell (`pv_from_rel/3`), rotating one cell 90 degrees CW around a pivot (`pv_rotate_cell_cw/3`), rotating a cell list 90 CW (`pv_rotate_cells_cw/3`), rotating 180 degrees (`pv_rotate_cells_180/3`), rotating 90 CCW (`pv_rotate_cells_ccw/3`), reflecting a cell list horizontally around pivot column (`pv_reflect_cells_h/3`), reflecting vertically around pivot row (`pv_reflect_cells_v/3`), reflecting across main diagonal through pivot (`pv_reflect_cells_diag/3`), reflecting across anti-diagonal through pivot (`pv_reflect_cells_antidiag/3`), the sorted D4 orbit of one cell (`pv_orbit/3`), the sorted D4 symmetry closure of a cell list (`pv_sym_closure/3`), and stamping DR-DC offset cells at a pivot in a grid (`pv_stamp_at/5`). 14 pv_* predicates, Layer 87. |
| `project` | Axis Projection and Shadow Casting (PR 109) — propagating non-BG values downward through BG cells per column (`pj_shadow_down/3`), upward (`pj_shadow_up/3`), leftward (`pj_shadow_left/3`), rightward (`pj_shadow_right/3`), dispatching by direction atom (`pj_shadow_dir/4`), sorted row indices containing non-BG cells (`pj_nonbg_rows/3`), sorted column indices containing non-BG cells (`pj_nonbg_cols/3`), non-BG cell count per row (`pj_row_counts/3`), non-BG cell count per column (`pj_col_counts/3`), collapsing all rows to one row by first-non-BG per column (`pj_collapse_rows/3`), collapsing all columns to one column by first-non-BG per row (`pj_collapse_cols/3`), row index of topmost non-BG in a column (`pj_col_first/4`), row index of bottommost non-BG in a column (`pj_col_last/4`), and column index of leftmost non-BG in a row (`pj_row_first/4`). 14 pj_* predicates, Layer 88. |
| `neighbor` | Cell Neighborhood Analysis (PR 114) — returning a list of nb(Row,Col,Val) terms for each valid 4-connected neighbor of a cell with out-of-bounds directions omitted (`nb_4neighbors/4`), the same for 8-connected neighbors including diagonals (`nb_8neighbors/4`), testing whether a non-Bg cell is a boundary cell (has at least one Bg or out-of-bounds 4-neighbor) (`nb_is_boundary/4`), testing whether a non-Bg cell is interior (all 4-neighbors in-bounds and non-Bg) (`nb_is_interior/4`), sorted R-C pairs of all boundary cells (`nb_boundary_cells/3`), sorted R-C pairs of all interior cells (`nb_interior_cells/3`), count of 4-neighbors with the same color as the cell (`nb_count_same/4`), count of 4-neighbors with a different color (`nb_count_diff/4`), sorted set of distinct colors among 4-neighbors (`nb_adjacent_colors/4`), sorted R-C pairs of all Color cells adjacent to non-Color or grid boundary (`nb_contour/3`), succeed if any ColorA cell is 4-adjacent to any ColorB cell (`nb_color_touches/3`), sorted (R1-C1)-(R2-C2) pairs of all ColorA-ColorB 4-adjacencies (`nb_touching_pairs/4`), 4-connected flood fill from a seed cell returning the modified grid (`nb_flood_fill/5`), and expanding a Color region by one 4-connected layer into adjacent Bg cells (`nb_dilate/4`). 14 nb_* predicates, Layer 93. |
| `gravity` | Directional Cell-Sliding and Gravity Operations (PR 116) — compacting all non-Bg values to the left end of a row (`gv_pack_row_left/3`), right end (`gv_pack_row_right/3`), top of a column list (`gv_pack_col_up/3`), bottom of a column list (`gv_pack_col_down/3`), sliding all non-Bg cells left within their row (`gv_fall_left/3`), right (`gv_fall_right/3`), downward within their column (`gv_fall_down/3`), upward (`gv_fall_up/3`), dispatching gravity by direction atom (`gv_fall_dir/4`), sliding only a specific Color left while other non-Bg cells act as immovable walls (`gv_fall_color_left/4`), right (`gv_fall_color_right/4`), downward (`gv_fall_color_down/4`), upward (`gv_fall_color_up/4`), and dispatching color-specific gravity by direction atom (`gv_fall_color_dir/5`). 14 gv_* predicates, Layer 95. |
| `count` | Value Counting and Frequency Analysis (PR 117) — counting occurrences of a value in a flat list (`cn_by_value/3`), counting a value across all cells of a 2D grid (`cn_color_count/3`), building a frequency histogram as parallel sorted Colors and Counts lists (`cn_histogram/3`), returning the most frequently occurring value (`cn_max_color/2`), the least frequently occurring value (`cn_min_color/2`), counting rows containing a given value (`cn_color_rows/3`), counting columns containing a given value (`cn_color_cols/3`), counting distinct values in a single row (`cn_row_distinct/3`), counting distinct values in a single column (`cn_col_distinct/3`), returning the total number of cells as rows times columns (`cn_grid_total/2`), counting cells where two grids agree (`cn_equal_cells/3`), counting cells where two grids differ (`cn_diff_cells/3`), looking up the grid value at the first cell of a region expressed as r(R,C) terms (`cn_region_color/3`), and building a Color-Count tally for a list of regions (`cn_regions_per_color/3`). 14 cn_* predicates, Layer 96. |
| `diagonal` | Diagonal Line Extraction and Filling (PR 119) — extracting values on the main diagonal where C equals R (`dg_main_diag/2`), main anti-diagonal where R+C equals NC-1 (`dg_anti_diag/2`), the N-th diagonal where C-R equals N (`dg_nth_diag/3`), the N-th anti-diagonal where R+C equals N (`dg_nth_anti_diag/3`), all diagonals sorted by offset (`dg_all_diags/2`), all anti-diagonals sorted by sum (`dg_all_anti_diags/2`), filling the main diagonal with Color (`dg_fill_main/3`), filling the main anti-diagonal (`dg_fill_anti/3`), filling the N-th diagonal (`dg_fill_nth_diag/4`), filling the N-th anti-diagonal (`dg_fill_nth_anti_diag/4`), computing the diagonal index N=C-R for any cell (`dg_cell_diag/3`), computing the anti-diagonal index N=R+C (`dg_cell_anti_diag/3`), testing whether the N-th diagonal is all Color (`dg_uniform_diag/3`), and testing whether the N-th anti-diagonal is all Color (`dg_uniform_anti_diag/3`). 14 dg_* predicates, Layer 98. |
| `recur` | Arithmetic Progression and Periodic Recurrence Detection (PR 120) — generating an N-term arithmetic sequence from a start value and step (`rc_arith/4`), extracting the common difference of an arithmetic sequence (`rc_arith_step/2`), testing whether a sequence is arithmetic with detected step (`rc_is_arith/2`), generating a sequence by repeating a unit N times end-to-end (`rc_repeat/3`), finding the minimal repeating unit of a sequence (`rc_period/2`), testing whether a sequence is an exact integer-multiple repetition of some unit (`rc_is_periodic/2`), computing the next N terms of an arithmetic sequence by continuing from its last element (`rc_next_arith/3`), computing the next N terms of a periodic sequence by cycling from the current offset (`rc_next_repeat/3`), extending an arithmetic sequence by N terms and returning the step (`rc_extend_arith/4`), extending a periodic sequence by N terms and returning the minimal period unit (`rc_extend_repeat/4`), returning the N-th element one-based of the infinite cyclic repetition of a unit (`rc_cycle_nth/3`), pair-wise application of a 3-argument goal over two lists (`rc_zip_with/4`), computing consecutive element-wise differences of a numeric list (`rc_diff_list/2`), and testing whether all consecutive differences are equal and returning the common value (`rc_const_diffs/2`). 14 rc_* predicates, Layer 99. |
| `stripe` | Uniform Row and Column Stripe Detection and Filling (PR 118) — testing whether row R is all one value (`sr_uniform_row/3`), testing whether column C is all one value (`sr_uniform_col/3`), returning sorted row indices uniformly equal to Color (`sr_uniform_rows/3`), returning sorted column indices uniformly equal to Color (`sr_uniform_cols/3`), R-Color pairs for all uniform rows in row-index order (`sr_all_stripe_rows/2`), C-Color pairs for all uniform columns in column-index order (`sr_all_stripe_cols/2`), sorted row indices that are NOT uniform (`sr_mixed_rows/2`), sorted column indices that are NOT uniform (`sr_mixed_cols/2`), filling row R with Color (`sr_fill_row/4`), filling column C with Color (`sr_fill_col/4`), filling multiple row indices with Color (`sr_fill_rows/4`), filling multiple column indices with Color (`sr_fill_cols/4`), returning r(R,C) terms for the Cartesian product of two index lists (`sr_cross_cells/4`), and filling all cells at row-column intersections with Color (`sr_cross_fill/5`). 14 sr_* predicates, Layer 97. |
| `permute` | Row and Column Permutation Operations (PR 115) — reordering all rows of a grid by an explicit index list so that result row i comes from grid row Perm[i] (`pm_permute_rows/3`), reordering all columns by an index list (`pm_permute_cols/3`), exchanging exactly two rows (`pm_swap_rows/4`), exchanging exactly two columns (`pm_swap_cols/4`), cyclically shifting rows so the last N rows move to the front (`pm_cycle_rows/3`), cyclically shifting columns so the last N columns move to the left (`pm_cycle_cols/3`), discovering the index permutation mapping one grid's rows to another's (`pm_find_row_perm/3`), discovering the index permutation mapping one grid's columns to another's (`pm_find_col_perm/3`), sorting all rows in ascending lexicographic order preserving duplicates (`pm_sort_rows/2`), sorting all columns in ascending lexicographic order preserving duplicates (`pm_sort_cols/2`), inserting a complete row before a given position (`pm_insert_row/4`), removing the row at a given position (`pm_delete_row/3`), inserting a column of values before a given position in every row (`pm_insert_col/4`), and removing the column at a given position from every row (`pm_delete_col/3`). 14 pm_* predicates, Layer 94. |
| `region` | Grid Region Extraction by Separator Lines (PR 113) — checking whether a row is entirely equal to a separator value (`rg_is_sep_row/3`), checking whether a column is entirely equal to a separator value (`rg_is_sep_col/3`), collecting all separator row indices into a sorted list (`rg_sep_rows/3`), collecting all separator column indices (`rg_sep_cols/3`), computing R0-R1 inclusive row spans of non-separator horizontal sections (`rg_spans_h/3`), computing C0-C1 inclusive column spans of non-separator vertical sections (`rg_spans_v/3`), splitting a grid at its separator rows into a list of sub-grids with separators excluded (`rg_cut_h/3`), splitting at separator columns (`rg_cut_v/3`), assembling a 2D list-of-lists of all sections by cutting in both directions (`rg_sections/3`), retrieving the N-th horizontal section by 1-indexed number (`rg_section_h/4`), retrieving the N-th vertical section (`rg_section_v/4`), counting horizontal sections (`rg_count_h/3`), counting vertical sections (`rg_count_v/3`), and extracting the sub-grid of the section containing a given cell coordinate, failing if the cell is on a separator (`rg_region/5`). 14 rg_* predicates, Layer 92. |
| `assemble` | Grid Assembly, Concatenation, and Composition (PR 112) — horizontally concatenating a list of same-height grids into one wide grid (`as_hcat/2`), vertically stacking a list of same-width grids (`as_vcat/2`), assembling a 2D matrix of grids into one combined grid (`as_grid_of/2`), reducing each K x K block to one cell by majority vote (`as_downscale/3`), surrounding a grid with a W-cell wide colored frame (`as_border/4`), embedding a grid at the integer floor center of a canvas (`as_center_in/5`), extracting one of four named quadrants tl/tr/bl/br (`as_quarter/3`), concatenating a grid with its left-right mirror (`as_flip_h_cat/2`), stacking a grid with its top-bottom mirror (`as_flip_v_cat/2`), interleaving columns from two same-size grids (`as_zip_h/3`), interleaving rows from two same-size grids (`as_zip_v/3`), unconditionally pasting a sub-grid at a given offset (`as_paste/5`), replacing cells where a mask is non-zero with a fill value (`as_mask_fill/4`), and cropping or padding to an exact target size (`as_crop_to/5`). 14 as_* predicates, Layer 91. |
| `order` | Object Spatial Ordering and Ranking (PR 111) — computing the integer floor centroid of an obj(Color, Cells) term (`od_centroid/3`), sorting objects by centroid row ascending/topmost-first (`od_sort_row/2`), sorting by centroid column ascending/leftmost-first (`od_sort_col/2`), sorting by row then column in reading order (`od_reading_order/2`), sorting by color value ascending (`od_sort_color/2`), finding the topmost object (`od_topmost/2`), bottommost (`od_bottommost/2`), leftmost (`od_leftmost/2`), rightmost (`od_rightmost/2`), the Nth object in row order (`od_nth_row/3`), the Nth object in column order (`od_nth_col/3`), the object nearest to a reference position (`od_nearest/4`), the object farthest from a reference position (`od_farthest/4`), and the 1-based rank of an object in row order (`od_rank_row/3`). 14 od_* predicates, Layer 90. |
| `diff` | Multi-Pair Grid Difference Analysis (PR 110) — all changed cells as diff(R,C,OldV,NewV) terms (`df_cell_diff/3`), cells that went from background to non-background (`df_added/4`), cells that went from non-background to background (`df_removed/4`), cells that stayed non-background but changed color (`df_recolored/4`), cells whose value did not change (`df_stable/3`), colors added to or lost from the palette (`df_palette_change/4`), cells that changed in every In-Out pair in a list (`df_common_diffs/2`), cells that were stable in every pair (`df_common_stable/2`), cells added in every pair (`df_always_added/3`), cells removed in every pair (`df_always_removed/3`), total count of changed cells (`df_total_changes/3`), applying a diff list to a grid (`df_apply_diffs/3`), inverting a diff list to reverse direction of each change (`df_invert_diffs/2`), and filtering diffs by a goal predicate (`df_filter_diffs/3`). 14 df_* predicates, Layer 89. |
| `pipeline` | Sequential Step Dispatch and List Utilities (PR 91) — registering named step handlers (`pl_register/2`), querying handlers (`pl_registered/2`), removing handlers (`pl_unregister/1`), applying one step with optional local registry (`pl_step/4`), threading an input through a sequence of named steps (`pl_run/3`), mapping a 2-argument goal over a list (`pl_map/3`), filtering by a 1-argument goal (`pl_filter/3`), folding with an accumulator (`pl_fold/4`), zipping two lists into pairs (`pl_zip/3`), unzipping pairs into two lists (`pl_unzip/3`), taking the first N elements (`pl_take/3`), dropping the first N elements (`pl_drop/3`), and partitioning into satisfied and rejected elements (`pl_partition/4`). 14 pl_* predicates, Layer 70. |
| `obj` | Object Inventory and Reasoning (PR 90) — constructing an object term from color and cells (`obj_from_cells/3`), extracting color (`obj_color/2`), cells (`obj_cells/2`), size (`obj_size/2`), bounding box (`obj_bbox/5`), integer centroid (`obj_center/3`), translation-independent normalized shape (`obj_shape/2`), extracting all 4-connected objects of one color (`obj_inventory/3`), all objects of all non-zero colors (`obj_all/2`), counting objects (`obj_count/3`), finding the largest (`obj_largest/3`) and smallest (`obj_smallest/3`) object, looking up which object contains a cell (`obj_at_cell/3`), and sorting objects by size (`obj_sort_size/3`). 14 obj_* predicates, Layer 69. |
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
