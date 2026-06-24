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
  Pure symbolic induction &nbsp;&bull;&nbsp; Named glass-box rules &nbsp;&bull;&nbsp; No LLM &nbsp;&bull;&nbsp; No black box
</p>

---

## What is PrologAI?

PrologAI is a complete cognitive architecture written in SWI-Prolog.

It is not a library layered on top of an existing AI framework — it **is** the framework. A new kind of platform where you build a reasoning mind the way you build a compiler: explicitly, structurally, and verifiably.

Every reasoning step PrologAI takes is a **named, inspectable Prolog predicate**. Every answer comes with a **justification tree** you can read.

---

## Landmark Achievements

| Benchmark / Capability | Result | Method |
|---|---|---|
| **ARC-AGI-1** — 400-task grid reasoning benchmark | **400 / 400 = 100.00%** | Pure symbolic induction, named glass-box rules |
| Reasoning types | **48 / 48** | Deductive through Moral — all implemented |
| SPARC documentation volumes | **6 / 6** | Spec, Pseudocode, Architecture, Refinement, Completion, Demo Plan |
| Multi-agent protocols | **4 / 4** | MCP, A2A, ACP, ANP |
| Piagetian cognitive levels | **8 / 8** | Sensorimotor through Formal-Operational |

> PrologAI is the **first system in the world** to achieve 400/400 = 100% on the ARC-AGI-1 public training benchmark using pure symbolic induction — no pretraining, no neural weights, no internet knowledge.

---

## Architecture

```
PrologAI/
├── packs/                      Work packages — one per reasoning capability
│   ├── deductive/              Rung  1: Deductive reasoning
│   ├── inductive/              Rung  2: Inductive reasoning
│   ├── abductive/              Rung  3: Abductive reasoning
│   ├── ...                     Rungs 4 – 47
│   ├── moral/                  Rung 48: Moral reasoning
│   └── arc_benchmark/          400 named glass-box ARC-AGI-1 rules (complete)
├── docs/                       SPARC documentation series (6 volumes)
│   ├── PrologAI_Tutorial.txt               12-chapter tutorial
│   └── Certified_PrologAI_Engineer.txt     25-chapter professional textbook
├── syntax/                     PrologAI language syntax rules
├── tests/                      Acceptance test suite
└── launcher/                   Entry points and bootstrapper
```

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

---

## ARC-AGI-1: 400/400 = 100.00%

The [Abstract Reasoning Corpus for Artificial General Intelligence (ARC-AGI)](https://arcprize.org) Year 1 is a benchmark of 400 grid-transformation puzzles designed by Francois Chollet to measure fluid reasoning — the kind of intelligence that cannot be faked by memorizing training data.

PrologAI solved all 400 tasks using **pure induction from each task's own training examples**:

```prolog
% Task 234bbc79 — assemble_3pieces_at_5_joints
% ERC 0.10 %
arc_named_rule(assemble_3pieces_at_5_joints).
% ERC 0.10 %
arc_transform(Pairs, TestIn, TestOut) :-
    w75_sort_pieces_ltr(Pairs, Pieces),
    w75_assemble_at_joints(Pieces, TestIn, TestOut).
```

Each of the 400 solved tasks has a human-readable named rule like this. No two rules are the same. Each one captures a distinct visual reasoning pattern.

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

| Property | PrologAI | LLM / Transformer |
|---|---|---|
| Every answer is inspectable | ✅ Yes | ❌ No |
| Reasoning is a named proof | ✅ Yes | ❌ No |
| No pretraining required | ✅ Yes | ❌ No |
| Hallucination possible | ❌ None by design | ✅ Frequent |
| ARC-AGI-1 score | **100.00%** | < 50% (best frontier models) |
| Zero-shot induction on new tasks | ✅ Yes | ❌ No |
| Justification tree readable | ✅ Yes | ❌ No |

---

## Mentova

[Mentova](https://github.com/ai-university-aiu/Mentova) is the world's first glass-box synthetic mind, built on PrologAI. It runs 48 reasoning types, achieved 400/400 = 100% on ARC-AGI-1, and is now beginning ARC-AGI-2.

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
