This repository builds PrologAI, defined by six companion volumes in the docs folder.

Always follow those documents.

The Specification (docs/PrologAI_1_Specification_Final_v13.txt) is authoritative for what to build,

the Pseudocode (docs/PrologAI_2_Pseudocode_Final_v7.txt) for how each work package reasons,

the Architecture (docs/PrologAI_3_Architecture_Final_v7.txt) for where each piece lives,

the Refinement (docs/PrologAI_4_Refinement_Final_v7.txt) for testing and safety,

the Completion (docs/PrologAI_5_Completion_Final_v6.txt) for release,

and the Demonstration Plan (docs/PrologAI_6_Demonstration_Mentova_v3.txt) for how Mentova is born, proven, and grown on the finished platform.

Build in the dependency order given in the Architecture, Part ARCH-10.

Implement one work package (PR) per feature branch, with tests, and never modify the constitutional layer or the protected core except through explicit human review.

Element names are original to PrologAI; do not introduce source-origin terms.

