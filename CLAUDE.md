This repository builds PrologAI, defined by six companion volumes in the docs folder.

Always follow those documents.

The Specification (docs/PrologAI_1_Specification_v15.txt) is authoritative for what to build,

the Pseudocode (docs/PrologAI_2_Pseudocode_v8.txt) for how each work package reasons,

the Architecture (docs/PrologAI_3_Architecture_v9.txt) for where each piece lives,

the Refinement (docs/PrologAI_4_Refinement_v23.txt) for testing and safety,

the Completion (docs/PrologAI_5_Completion_v26.txt) for release,

and the Demonstration Plan (docs/PrologAI_6_Demonstration_Mentova_v4.txt) for how Mentova is born, proven, and grown on the finished platform.

Build in the dependency order given in the Architecture, Part ARCH-10.

Implement one work package (PR) per feature branch, with tests, and never modify the constitutional layer or the protected core except through explicit human review.

Element names are original to PrologAI; do not introduce source-origin terms.

SPARC DOCUMENTATION RULE: Any code change — new work package, bug fix, utility, or Mentova accomplishment that changes platform capability — must be accompanied by corresponding changes to the relevant SPARC volumes in /PrologAI/docs/. The documentation change must describe what changed and why. Each updated volume gets its minor version incremented. Code and documentation changes go in the same PR or in an explicitly linked documentation PR. See Specification Part 41, Section 41.2 for the full rule.
