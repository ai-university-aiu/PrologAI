% State the fact: name(coordination) — the coordination-ergonomics construct.
name(coordination).
% State the fact: version('0.1.0') — the first Wave 10 Stage 8 delivery.
version('0.1.0').
% State the fact: title naming the construct and its Work Package (WP-437, closes Theme F).
title('coordination — ergonomic coordination affordances for the single-threaded reentrant-loop model: a journal-free store with keyed await, an ordered channel, a bounded loop driver, a loop descriptor, a runtime layer-aware transport, and a hop trace (WP-437)').
% State the fact: author is the PrologAI Community.
author('PrologAI Community', 'ai.university.aiu@gmail.com').
% State the fact: home points at the PrologAI repository.
home('https://github.com/ai-university-aiu/PrologAI').
% State the fact: download points at the repository releases page.
download('https://github.com/ai-university-aiu/PrologAI/releases').
% State the fact: requires([]) — the coordination store depends only on SWI-Prolog standard libraries.
requires([]).
% State the fact: layer(0) — base infrastructure; the coordination affordances depend on nothing higher.
layer(0).
% NOTE: no stratum(...) fact — a coordination construct is not at a stratum, so it is UNBOUND
% under the N6 binding (a gap to fill, never a violation), as the other layer-0 packs are.
