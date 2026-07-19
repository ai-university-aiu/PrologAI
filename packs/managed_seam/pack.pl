% State the fact: name(managed_seam) — the managed cross-stratal seam construct.
name(managed_seam).
% State the fact: version('0.1.0') — the first Wave 10 Stage 4 delivery.
version('0.1.0').
% State the fact: title naming the construct and its Work Package (WP-433, closes Theme B).
title('managed_seam — a first-class managed cross-stratal seam: honest-ignorance status, a drawn chain, a checkable home rule, and a queryable runtime event (WP-433)').
% State the fact: author is the PrologAI Community.
author('PrologAI Community', 'ai.university.aiu@gmail.com').
% State the fact: home points at the PrologAI repository.
home('https://github.com/ai-university-aiu/PrologAI').
% State the fact: download points at the repository releases page.
download('https://github.com/ai-university-aiu/PrologAI/releases').
% State the fact: requires the lattice store and the Causalontology vocabulary core.
requires([lattice, causal_core]).
% State the fact: layer(0) — base infrastructure atop the layer-0 lattice; a same-layer edge is allowed.
layer(0).
% NOTE: no stratum(...) fact — a cross-stratal (edge) construct is BY DEFINITION not at a
% single stratum, so it is UNBOUND under the N6 binding (a gap to fill, never a violation).
% Its home is the coarsest endpoint, computed per seam by managed_seam_home/4, not a pack fact.
