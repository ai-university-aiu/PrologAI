% State the fact: name(packaging) — the dependency-kinds, faces, facade, and record-registry construct.
name(packaging).
% State the fact: version('0.1.0') — the first Wave 10 Stage 7 delivery.
version('0.1.0').
% State the fact: title naming the construct and its Work Package (WP-436, closes Theme G).
title('packaging — dependency kinds (structure-only vs runtime), loadable pack faces, a facade/bundle, and a cross-pack record registry (WP-436)').
% State the fact: author is the PrologAI Community.
author('PrologAI Community', 'ai.university.aiu@gmail.com').
% State the fact: home points at the PrologAI repository.
home('https://github.com/ai-university-aiu/PrologAI').
% State the fact: download points at the repository releases page.
download('https://github.com/ai-university-aiu/PrologAI/releases').
% State the fact: requires([]) — packaging metadata depends only on SWI-Prolog standard libraries.
requires([]).
% State the fact: layer(0) — base infrastructure; a packaging declaration governs, and depends on, nothing higher.
layer(0).
% NOTE: no stratum(...) fact — a packaging construct is not at a stratum, so it is UNBOUND
% under the N6 binding (a gap to fill, never a violation), as the other layer-0 packs are.
