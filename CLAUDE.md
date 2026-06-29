This repository builds PrologAI, defined by six companion volumes in the docs folder.

Always follow those documents.

The Specification (docs/PrologAI_1_Specification_v247.txt) is authoritative for what to build,

the Pseudocode (docs/PrologAI_2_Pseudocode_v239.txt) for how each work package reasons,

the Architecture (docs/PrologAI_3_Architecture_v242.txt) for where each piece lives,

the Refinement (docs/PrologAI_4_Refinement_v299.txt) for testing and safety,

the Completion (docs/PrologAI_5_Completion_v305.txt) for release,

and the Demonstration Plan (docs/PrologAI_6_Demonstration_Mentova_v4.txt) for how Mentova is born, proven, and grown on the finished platform.

Build in the dependency order given in the Architecture, Part ARCH-10.

Implement one work package (PR) per feature branch, with tests, and never modify the constitutional layer or the protected core except through explicit human review.

Element names are original to PrologAI; do not introduce source-origin terms.

SPARC DOCUMENTATION RULE: Any code change — new work package, bug fix, utility, or Mentova accomplishment that changes platform capability — must be accompanied by corresponding changes to the relevant SPARC volumes in /PrologAI/docs/. The documentation change must describe what changed and why. Each updated volume gets its minor version incremented. Code and documentation changes go in the same PR or in an explicitly linked documentation PR. See Specification Part 41, Section 41.2 for the full rule.

ARC-AGI-1 WAVE LOG RULE: After every ARC-AGI-1 wave is confirmed and merged, update /home/ccaitwo/Mentova/papers/Climbing_ARC-AGI-1.txt with: (1) a new ATTEMPT entry containing date, confirmed score, rules added with descriptions, bugs fixed, and lessons learned; (2) a new row in the COMPLETE SCORE PROGRESSION table; (3) new task IDs inserted in alphabetical order in the ALL SOLVED TASKS list; (4) a new REFERENCES entry for the wave. This update goes in the same PR as the wave code, or in the immediately following doc PR.

README UPDATE RULE: After any significant update to the PrologAI codebase — new work package, new benchmark result, new protocol support, new major documentation — update README.md in the PrologAI repository root to reflect the change. The README must always show the current state of the platform: accurate achievement numbers, current SPARC volume versions, and up-to-date capability descriptions. This update goes in the same PR as the code change.

PR MERGE RULE: After creating a PR (on either PrologAI or Mentova), merge it immediately using `gh pr merge <number> --squash --delete-branch`. No confirmation is needed for PRs that Claude authored. Do NOT auto-merge PRs opened by other contributors or external bots; those require explicit human approval before merging.

PACK REFERENCE RULE: When any new pack is added to the Data Layer, or an existing Data Layer pack is significantly modified, update docs/Pack_Reference.txt to add or update the entry for that pack. Each entry has three parts: (1) the pack name (bare word), (2) the short title (same as in README.md), (3) the full predicate-level description indented by four spaces. This update goes in the same PR as the code change.

SPARC ARCHIVE RULE: The docs/ directory must hold only the single current version of each SPARC volume (PrologAI_1 through PrologAI_6 and any other versioned docs file). When any versioned file in docs/ is replaced by a newer version, move the old file into docs/archive/ before or in the same commit that adds the new file. This applies to every file in docs/ that carries a version indicator in its name (e.g. _v123, _v4, etc.). Only one file per versioned series may exist in docs/; all prior versions live in docs/archive/. Before writing any new versioned file to docs/, scan docs/ for older versions of the same series and move them to docs/archive/ in the same operation. This keeps docs/ clean and navigable while preserving full history.
