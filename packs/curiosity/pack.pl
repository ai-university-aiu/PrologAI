% State the fact: this pack is named curiosity.
name(curiosity).
% State the fact: this is version 1.0.0.
version('1.0.0').
% State the fact: the title carries the work-package number and the convergence.
title('PrologAI Curiosity — a novelty-seeking, loop-avoiding exploration policy over an interactive grid game, converged with intrinsic motivation by learning progress: error per region, progress tracking, habituation, and self-proposed frontier tasks (WP-398)').
% State the fact: the author and contact address.
author('PrologAI Community', 'ai.university.aiu@gmail.com').
% State the fact: the project home page.
home('https://github.com/ai-university-aiu/PrologAI').
% State the fact: where releases are downloaded from.
download('https://github.com/ai-university-aiu/PrologAI/releases').
% State the fact: this pack needs the grid, gridobj, and causal libraries plus node facts.
requires([causal_core, causal_learning, grid, gridobj]).
