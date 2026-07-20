THIS REPOSITORY IS PrologAI

PrologAI is a glass-box cognitive-architecture programming language and platform for
building synthetic minds. Its flagship implementation is Mentova
(https://github.com/ai-university-aiu/Mentova), the world's first synthetic mind written in
PrologAI.

This CONSTITUTION.md holds PrologAI's own repository-specific rules. The organization-wide
policies that apply to every ai-university-aiu repository (attribution, authorship,
copyright, published-works notice, English Readable Code, whole-word naming, branch-and-pull-
request discipline, six-file documentation, archive, style) live in the one organization
CLAUDE.md at /home/ccaitwo/CLAUDE.md. The rules below are how PrologAI applies and extends
those policies, plus the tooling and file paths specific to this repository.


ENGLISH-READABLE CODE (ERC) RULE

Every line of code in every .pl file carries one % comment immediately above it, in plain
English. This applies to modules, tests, pack.pl manifests, and code blocks quoted in
papers. See docs/English_Readable_Code_Specification_v2.txt.


SPARC DOCUMENTATION RULE

Every code change must include SPARC document changes in docs/ recording what changed and
why. Each affected volume gets its version incremented (new file: copy of the previous
version plus the appended section; never edit the line-1 internal header). Every appended
section ends with a SPARC: footer naming all five new versions. The Dated State Log at the
end of this file is updated in the same change when the platform's headline state moves.


ARCHIVE RULE

Old versions of versioned documents never stay in docs/. Whenever a new version of a
versioned document is created (SPARC volumes, Demonstration Plan, Readiness Analysis,
Building_AGI, ERC Specification, or any future versioned series), move the superseded version
into docs/archive/ with git mv IN THE SAME CHANGE. Additionally, on every document update,
sweep docs/ for stragglers: for each series, if more than one version is present, move all
but the highest version into docs/archive/. Only the latest version of each series may live
in docs/. (Enforced repo-wide on 2026-07-09: 362 old versions archived, PR #498.) The same
rule applies in the Mentova repository (docs/archive/ and mentova-chat-docs/archive/;
enforced 2026-07-10, Mentova PR #461).


TUTORIAL UPDATE RULE

Every code change must update docs/PrologAI_Tutorial.txt AND the docs/tutorial/ multi-file
tutorial. A new pack gets: a one-line entry in the single-file tutorial's pack index block
(after the newest WP entry), a full chapter appended at the end of the single file, and a
matching ChNNN_*.txt file in docs/tutorial/.


PACK REFERENCE RULE

Update docs/Pack_Reference.txt whenever a Data Layer pack is added or significantly
modified: bare pack name, title line with prefix and layer, then one indented line per
public predicate.


README UPDATE RULE

README.md in the repository root must be updated on every significant platform change, in
the same PR as the code: work package counts, layer narrative, and a table row per new pack.


PACK LAYOUT

    packs/<name>/pack.pl              manifest (name, version, title with
                                      WP number, author, home, download,
                                      requires), ERC-commented
    packs/<name>/prolog/<name>.pl     the module; pack-qualified whole-word
                                      snake_case predicates (see NAMING
                                      CONVENTION RULE); header block with WP
                                      and Layer numbers
    packs/<name>/test/test_<name>.pl  PLUnit suite; run with
                                      swipl -g "run_tests, halt" test_<name>.pl


SIX-FILE REPOSITORY DOCUMENTATION RULE (adopted 2026-07-18, Wave 7)

Every GitHub repository that contains FUNCTIONAL CODE - new repositories from their first
commit, and existing repositories as a one-time catch-up - carries a docs/ folder holding
these six files, where [reponame] is the repository's own name:

    [reponame]_1_Specification_v1.txt
    [reponame]_2_Pseudocode_v1.txt
    [reponame]_3_Architecture_v1.txt
    [reponame]_4_Refinement_v1.txt
    [reponame]_5_Completion_v1.txt
    [reponame]_6_Demonstration_v1.txt

The first five are the SPARC files - Specification, Pseudocode, Architecture, Refinement,
Completion - the planning-through-completion methodology: Specification states what the
repository must do (functional and non-functional requirements, objectives, constraints,
acceptance criteria); Pseudocode gives the logic of the main flows; Architecture gives the
structure (packs, layers, substrate, interfaces, a text diagram); Refinement gives the
testing story (checkers, batteries, gates, bugs found and fixed); Completion gives delivered
status in honest form (the mini-regression as 40/40 and 12/12, never rounded to 400/400, and
the pinned PrologAI commit). The sixth, Demonstration, is not a SPARC phase - it is a plan or
outline of intentions for how the code will be demonstrated: what to run, what it shows, and
what a viewer should conclude.

The Pseudocode file (file 2) is written in English-Readable-Code (ERC), per
docs/English_Readable_Code_Specification_v2.txt - Primitive operations preferred, Composite
operations expanded to primitives, Library operations referenced by their documented
interface.

These files are versioned, so the SPARC DOCUMENTATION RULE and ARCHIVE RULE above apply to
them: a material change to a repository increments the affected file's version (copy the
previous version and append; the line-1 internal header is NEVER edited - only the filename
version advances), and every superseded version is moved into that repository's docs/archive
with git mv in the same change. Each file's line-1 internal header names the repository, the
file, and version 1, and that header is never edited on later bumps.

THE NO-FUNCTIONAL-CODE EXCEPTION. A repository that contains NO functional code - a
data-structure or standard, such as causalontology - is exempt from the six-file rule. It
instead carries a single English technical specification file in its repository root (its
"standalone" specification). causalontology already satisfies this with its standalone
design document; no six-file set is required for it.

This rule is the standing definition of done for a functional-code repository's
documentation. It composes with, and does not replace, the existing per-construct
documentation discipline (a docs/<construct>.md page, a README paragraph and Core Platform
table row, a LEDGER.md entry, and a CI workflow). See NAMING.md for the whole-word identifier
rule and REGRESSION_DEBT.md for the benchmark-honesty rule and the mini-regression gate; the
living LEDGER.md continues the frozen spike's Ledger. Spell each acronym out in full on first
use per document with the acronym in parentheses, the bare acronym thereafter, and keep
external proper names verbatim (Ed25519, SWI-Prolog, SQLite, Git).


NAMING CONVENTION RULE (adopted 2026-07-13)

The "co_" prefix is being retired: Causalontology is the global architecture (the
data-structure language every pack speaks), not a subset marked by prefix.

(1) Pack names. All pack names are lowercase snake_case, using whole words, not
abbreviations, for clarity (world_model, not worldmodel, wm, or WorldModel). The directory,
the module, and the manifest name are identical:
    packs/world_model/  ,  :- module(world_model, ...)  ,  name(world_model).  ,
    referenced as use_module(library(world_model)).
Rationale: only lowercase snake_case is a valid unquoted Prolog atom (a leading uppercase
reads as a variable); it is filesystem-portable; and it matches the SWI-Prolog stdlib idiom.

(2) Predicate names. Predicates use pack-qualified whole-word snake_case:
world_model_predict/4, not wm_predict/4. This is self-documenting and makes every predicate
name globally unique, killing the cross-pack collisions that terse prefixes caused
(wm_predict/4, lk_invert/2, ob/3). Clarity is preferred over brevity.

(3) Migration. The rename is folded into the unification/convergence program: each faculty
converges to one canonical pack that receives its clean whole-word name and pack-qualified
predicates in the same change (dir + module + pack.pl + every use_module/library()/requires
+ all callers in both repos + docs + the collision linter). Clean rename, no aliases (private
pre-release). Data-Layer packs not part of a convergence pair are renamed in their own
passes.

(4) NO TERSE PREFIXES - UNIVERSAL AND PERMANENT. This rule is not limited to the co_ family
or to convergences: EVERY predicate in EVERY pack, new or existing, must be prefixed with the
pack's full whole-word name (fill_flood/4, not fl_flood/4; grid_size/3, not gd_size/3).
Two-letter and abbreviated predicate prefixes are BANNED (gd_, ay_, sc_, wm_, cf_, ai_, js_,
ht_, ev_, nx_, pai_, and every other terse stub). The reason is proven, not stylistic: terse
prefixes collide across packs - wm_ meant BOTH world-model AND wallpaper-motif; lk_ means
BOTH link AND lookup; two-letter stubs are already shared by dozens of pack pairs - and they
are opaque to anyone new to the codebase. A NEW pack MUST ship pack-qualified from its first
commit; there is no grace period and no "temporary" short prefix. Pack NAMES are likewise
whole words, never abbreviations (active_inference, not actinf; jacobian_space, not jspace) -
with the one allowance that a branded concept name may persist in PROSE while its code
identifiers are pack-qualified (the "J-Space" concept stays in the papers; the pack and
predicates are jacobian_space / jacobian_space_). The one former branded abbreviation in the
causal packs, CRO (the Causal Relation Object), is a deliberate exception to that allowance:
it is now spelled out in full as causal_relation_object everywhere - the cro/8 functor, the
causal_core_ and world_model_ predicates, and prose alike - aligning with Causalontology
2.0.0's whole-word Principle P7 (every identifier scheme is one whole English word). No
cro/CRO abbreviation survives in code or prose.

(6) PACK NAMES ARE WHOLE WORDS - NO ABBREVIATIONS, NO CONCATENATIONS. A pack's directory,
module, and manifest name is whole English words joined by underscores: arithmetic, not
arith; automaton, not autom; object_group, not objgroup; grid_blend, not gridblend. Two
failure modes are both banned - the abbreviation (a truncated or acronym segment: arith, sym,
obj, hyp, vsa) and the un-underscored concatenation (two whole words jammed together:
gridblend, colortable, multipair). Even established EXTERNAL-standard acronyms are expanded in
the pack and predicate identifiers, not only ad-hoc in-house abbreviations: agent_to_agent
(not a2a), agent_communication_protocol (not acp), agent_network_protocol (not anp),
model_context_protocol_gateway (not mcp_gateway), robot_operating_system_bridge (not
ros_bridge), vector_symbolic_architecture (not vsa), synaptic_ontological_neural_aggregator
(not sona) - the acronym may still appear in PROSE and paper titles as the recognized name,
but never as the code identifier. When an expanded name would collide with an existing
whole-word pack, the new pack takes a distinct whole-word name (the D4 transform pack became
isometry because transform was taken; gridxform and gridtransform became grid_transform and
grid_color_transform). A whole-word name must ALSO not collide with an SWI-Prolog
standard-library module: arith expanded to grid_arithmetic, not arithmetic, because
library(arithmetic) is SWI stdlib and a same-named pack on the library path shadows it
(breaking arithmetic_function/1). When renaming a pack, also migrate module-qualified goal
calls of the form oldpack:Goal to newpack:Goal - the executor's exact-name map must include an
oldpack: to newpack: substitution, not only library()/module()/path forms.

(5) ENFORCEMENT. bin/check_pack_naming.sh runs five merge-blocking checks and reports
colliding prefixes: (a) PREDICATE PREFIX - every pack's predicates carry its own whole-word
name; (b) MINORITY STRAGGLER - a pack may not hide a SECOND terse or retired prefix beneath
its dominant one (the check that catches a pai_ or lc_ cluster surviving under a correct
dominant prefix, the gap that the old dominant-only scan missed); (c) PACK NAME - the name is
whole words, never an abbreviation stem or an un-underscored concatenation; (d) SWI-STDLIB
SHADOW - the name must not equal an SWI-Prolog standard-library module (arithmetic, sort,
table), which a same-named pack shadows on the library path (queried live from the installed
SWI, with a hardcoded core fallback); (e) TEST PRESENCE - every pack ships an in-pack
test/test_<name>.pl, or it never enters the per-pack regression and can rot invisibly (the
lattice_cryptography stack-overflow lived undetected exactly this way - no in-pack test, not
in the regression). Run it before merging any new or renamed pack, and a violation is a merge
blocker. A NEW pack MUST ship with its in-pack PLUnit test from its first commit. The
DATA-LAYER DE-JAMMING PROGRAM (output/DeJam_Data_Layer_Plan.txt) is the standing effort that
brings the legacy Data-Layer packs still on terse prefixes into line, in waves - the
exclusive-prefix packs batched first, then the collision-prefix pairs handled individually
(each pack taking its own whole-word predicates so the shared stub is dissolved). De-jamming
a legacy pack is the same operation as the co_ renames: prefix -> packname_ by exact-name
substitution, migrate every caller in both repos and every hardcoded packs/OLD/prolog path
string - INCLUDING the tests/ acceptance suites (tests/prNN), which live OUTSIDE packs/ and
are not in the per-pack regression, so a rename sweep that only touches packs/ + docs/ +
Mentova silently leaves them stale (reconciled 2026-07-15 after a reflex_actors rename
surfaced years of accumulated tests/ drift) - keep tests green, bump SPARC, and - for short
prefixes especially (ai_ is also the word "AI", js_ is also "JavaScript") - match against the
pack's real predicate whitelist, never a blanket prefix sweep in caller or Mentova files.


WORK PACKAGE AND LAYER NUMBERING

WP numbers and Layer numbers are a single global counter shared by PrologAI packs and Mentova
ARC waves. Take the next free numbers; never reuse. Pack titles carry (WP-NNN).


BRANCH AND PR RULES

Every new work package uses a feature/ branch and a PR; no direct pushes to main. After
creating a PR that you authored, merge it immediately with:
gh pr merge <number> --squash --delete-branch. Do NOT auto-merge PRs opened by other
contributors or external bots.


ARC WAVE LOG RULE (when running ARC benchmark waves)

After every wave: add an ATTEMPT entry (date, score, rules, bugs, lessons), a score table
row, solved task IDs, and a reference in the climbing log in the Mentova repository.


DATED STATE LOG (Not a commandment.)

This section is a dated historical snapshot of the platform's state, not a rule. It records
where PrologAI stood at the date shown. It is informational only; update it when the
platform's headline state moves, and do not treat it as a commandment.

STATE OF 2026-07-12

315 work packages. WP-383 through WP-389 are the AGI Foundations suite (causal,
active_inference, worldmodel, planner, evolve, jacobian_space, tom) at Layers 358 through
364; WP-390 is the nexus integration layer (Layer 365) that wires four of those foundations
into the cognitive core (workspace, curiosity, agency, refinery); WP-391 through WP-396 are
the Causalontology suite (noun_backbone, realizable_hinge, causal_core, causal_learning,
causal_planner, arc3_harness) at Layers 366 through 371 - the process-first Foundational
Ontology from Causalontology_v5, sharing the co_ family prefix; WP-397 through WP-400 are the
ARC-AGI-3 Readiness suite (curiosity, goal_inference, efficiency_governor, arc3_protocol) at
Layers 372 through 375 - exploration policy, unstated-goal inference, an efficiency governor,
and the exact March-2026 ARC-AGI-3 protocol vocabulary, carrying the arc3_harness harness the
last mile to the interactive benchmark; WP-401 is human_steps (Layer 376), the ARC-AGI-3
Human-Step Ladder in J-Space - the six-phase, thirty-micro-step human process for interactive
games, each step held as a concept in the jacobian_space Jacobian workspace and read through
the Jacobian Lens, with a discrete action-response Jacobian that names the controllable
object and a goal gradient; WP-402 is state_graph (Layer 377), Causalontology State-Graph
Exploration - the technique that beat every frontier model on ARC-AGI-3: a directed graph of
frame-hash states and action transitions with tested/untested/dead edges, and hierarchical
action selection that probes an untested action or takes the shortest path to the nearest
unexplored frontier. WP-403 through WP-408 are the draft-driven ARC-AGI-3 capability packs
(grid_perception whole-grid perception, hierarchical_planning hierarchical planning,
verification verify-before-act, hypothesis hypothesis commitment, world_model world model,
object_relations object relations) at Layers 378 through 383. WP-409 through WP-416 are the
Cognitive Completion suite (episodic_memory episodic memory, attention with a single-winner
broadcast, motivation from internal needs, affect affect and appraisal, metacognition
metacognition, safety_governor a write-protected safety governor, repair compensation and
repair, consolidation consolidation) at Layers 384 through 391 - the wave that lifts the co_
family from an ARC-AGI-3 solver into a broader glass-box cognitive architecture, each pack
renamed away from the source concept names in THE_BUILDING_FILES while keeping the idea and
the CAS. WP-417 through WP-420 are the next-wave suite (grounding clue/language grounding -
the grounding seam of Causalontology_v5 Section 10; theory_of_mind a Causalontology-native
theory of mind with goal inference from movement and false-belief tracking; analogy by
structure mapping over rel(Type,A,B) sets with rule transfer; concept_formation concept
formation by seed clustering of feature bundles) at Layers 392 through 395, closing the
social, symbolic, and category-inducing gaps the Cognitive Completion gap analysis named.
WP-421 through WP-424 are the fullest-set suite (imagination with quarantined
observed/desired/expected/imagined/recalled realities; priming spreading-activation priming
by widest-path relaxation; regulation feedback regulation with the four flavours and
discrimination learning; lore turning repeated experience into themes, lessons, and maxims)
at Layers 396 through 399. In the same wave the six remaining bespoke-harness test suites
(hierarchical_planning, hypothesis, object_relations, grid_perception, verification,
world_model) were standardized onto PLUnit test() blocks and seven packs (those six plus
state_graph) tightened to full English-Readable-Code, verified comment-only with no behaviour
change. All 34 co_ packs pass on the full library path. A UNIFICATION PROGRAM then began
(PrologAI = the cognitive architecture; Causalontology = the data-structure language every
part should speak; the Lattice / APEX_MIND nexus = the one shared store). Its convergence
pattern is absorb-and-supersede: merge a redundant older pack into the canonical co_ pack
(union of both, plus Causalontology structure), union the test suites, migrate all callers
across both repos, verify zero references, then delete the older pack (clean delete, no shim -
private pre-release system). The first convergence merged the structured worldmodel pack
(WP-385) into world_model, which is now a single two-mode world model (learned transition
tallies + STRIPS simulate-and-plan) with a world_model_as_causal_relation_objects/2
causal_relation_object bridge; this also resolved the real world_model_predict/4 name
collision. Renames/deletions are tracked in output/co_Convergence_Ledger_1.txt. As the
reference implementation of the NAMING CONVENTION RULE, the world_model pack (formerly co_wm)
is the first pack converted to the new convention: renamed co_wm to world_model and its wm_
predicates to world_model_, with all callers migrated in both repositories and every test
green (world_model 30, snapshot/restore, nexus 22, imagination 9, planner 18). Cross-pack
tests run with every packs/*/prolog on the library path. Companion Mentova accomplishments:
Acc_424 (AGI Foundations end to end), Acc_425 (fact refinery), Acc_426 (Causalontology
runnable core + mentova_arc_agi_3_chat); the ARC-AGI-3 Readiness suite is companioned by
Mentova's autonomous ARC-AGI-3 agent driver and the preparation dossier
docs/ARC-AGI-3_Preparation_v1.txt (no score claimed until measured). A PACK-NAME EXPANSION
program then de-jammed the pack NAMES themselves: 117 packs whose directory/module/manifest
name was an abbreviation (arith, obj, hyp, sym) or an un-underscored concatenation
(gridblend, colortable, multipair) were renamed to whole words (grid_arithmetic, object,
grid_blend), the seven branded acronyms expanded in code while the acronym persists in prose
(a2a to agent_to_agent, mcp_gateway to model_context_protocol_gateway, vsa to
vector_symbolic_architecture, sona to synaptic_ontological_neural_aggregator), and six
collision expansions given distinct names (the D4 pack became isometry;
gridxform/gridtransform became grid_transform/grid_color_transform). The retired pai_ project
prefix was finished in the same program: the libraries pack's shared utilities became the
sanctioned prologai_ namespace (prologai_collections/types/similarity/convenience) and every
remaining own-pai_ straggler was pack-qualified. bin/check_pack_naming.sh gained PACK-NAME,
MINORITY-STRAGGLER, and SWI-STDLIB-SHADOW checks; the last surfaced two more shadows (sort
became sorting, table became data_table). It now reports zero violations across all packs;
the per-pack regression now covers 303 packs (every pack has an in-pack test), all green.
WAVE 10 (the nine-stage Requirements-Ledger-closing program) is COMPLETE: the whole
consolidated PrologAI Requirements Ledger (docs/PrologAI_Requirements_Ledger_v10.txt) is
closed, 57 of 57 findings, none open, none partial. Its nine serial gated stages delivered,
adopting Causalontology 3.0.0 (WP-429) and then six new Layer-0 language constructs -
affective_state (WP-430, a persisted modulatory affect), tick_scheduler (WP-432, deferred
reactivation on ordinal ticks), managed_seam (WP-433, a managed cross-stratal seam),
realization (WP-434, a structure-to-dynamics binding), packaging (WP-436, dependency
kinds/faces/facade/record-registry), and coordination (WP-437, coordination ergonomics) -
plus additive extensions of membership_contract (WP-431 context-aware accessor, WP-438
purity/find-member refinements), layer (WP-435 cross-repository and intra-pack reach, WP-438
binding freshness), and lattice (the N1 meta_predicate). Every stage kept the mini-regression
40/40 and 12/12 and Causalontology conformance 119/119 green; the full ARC-AGI-1 (400/400)
and ARC-AGI-2 (120/120) regression was re-run at the wave's end with no regression. Current
SPARC versions: Specification v423, Pseudocode v414, Architecture v416, Refinement v475,
Completion v481. CAUSALONTOLOGY 2.0.0 CONFORMANCE (WP-425): PrologAI declares and passes the
Causalontology specification 3.0.0 conformance suite - all 119 vectors (V01-V119, adopted in
Wave 10 Stage 1), vendored from the causalontology repo at 3.0.0 under
tests/causalontology_conformance/ (vectors + the eighteen schemas). The reusable engine
(RFC 8785 canonicalization, SHA-256 identity for all seventeen kinds, the local semantic
rules, and the five Section-12 algorithms) lives in the causal_core vocab pack; the
JSON-schema interpreter, the pure-Prolog Ed25519 (RFC 8032) signing layer, and the in-memory
conformant store are additive harness layers under tests/ that import none of the ARC
grid/ILP/sequence packs. Run with bin/run_causalontology_conformance.sh (exit 0 iff 119/119);
gated in CI by .github/workflows/causalontology-conformance.yml. ARC-AGI-1 (400/400) and
ARC-AGI-2 (120/120) were run before and after with no regression. ARC-AGI-1: 400/400 =
100.00%. ARC-AGI-2: 120/120 = 100.00%. ARC-AGI-1's score was independently re-verified on
2026-07-15 by a full runnable re-run: it exposed a pre-existing recording overcount of
exactly two - tasks 234bbc79 and 4290ef0e had rules that fit their training pairs but not
their held-out test grids, so the benchmark actually scored 398/400 and had done so since the
waves 75-79 commit (NOT a regression from the whole-word rename program). Both rules were
genuinely generalized: assemble_3pieces_at_5_joints (its length(Comps0,3) guard) became the
N-piece assemble_pieces_at_5_joints, and assemble_concentric_rings was rewritten to size each
ring from the edge-midpoint-gap centre-line invariant plus four-fold reflection about its own
centre. The full benchmark now genuinely scores 400/400 = 100.00% (booted run and isolated
arc_benchmark_run/3 both report 400, empty fail list). Mentova SPARC bumped to Specification
v358, Pseudocode v350, Architecture v351, Refinement v415, Completion v421; Mentova
Climbing_ARC-AGI-1.txt carries the correction.
