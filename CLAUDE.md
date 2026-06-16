This repository builds PrologAI, defined by the five SPARC volumes in the docs folder.

Always follow those documents. 

The Specification (docs/PrologAI_1_Specification_Final_v12.txt) is authoritative for what to build, 

the Pseudocode (docs/PrologAI_2_Pseudocode_Final_v6.txt) for how each work package reasons, 

the Architecture (docs/PrologAI_3_Architecture_Final_v6.txt) for where each piece lives, 

the Refinement (docs/PrologAI_4_Refinement_Final_v6.txt) for testing and safety, 

and the Completion (docs/PrologAI_5_Completion_Final_v6.txt) for release.

Build in the dependency order given in the Architecture, Part ARCH-10. 

Implement one work package (PR) per feature branch, with tests, and never modify the constitutional layer or the protected core except through explicit human review.

Element names are original to PrologAI; do not introduce source-origin terms.

