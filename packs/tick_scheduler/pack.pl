% State the fact: name(tick_scheduler) — the ordinal-tick deferred-reactivation construct.
name(tick_scheduler).
% State the fact: version('0.1.0') — the first Wave 10 Stage 3 delivery.
version('0.1.0').
% State the fact: title naming the construct and its Work Package (WP-432, closes HIPPO-2 and CEREBELLUM-1).
title('tick_scheduler — a Lattice-backed deferred-reactivation construct on ordinal ticks: schedule and ENACT a future reactivation, measured in ticks, never seconds (WP-432)').
% State the fact: author is the PrologAI Community.
author('PrologAI Community', 'ai.university.aiu@gmail.com').
% State the fact: home points at the PrologAI repository.
home('https://github.com/ai-university-aiu/PrologAI').
% State the fact: download points at the repository releases page.
download('https://github.com/ai-university-aiu/PrologAI/releases').
% State the fact: requires the lattice store and the Causalontology vocabulary core.
requires([lattice, causal_core]).
% State the fact: layer(0) — base infrastructure atop the lattice store (also layer 0); a same-layer edge is allowed.
layer(0).
% NOTE: no stratum(...) fact — a base construct is not at a stratum, so it is UNBOUND
% under the N6 binding (a gap to fill, never a violation), as the other layer-0 packs are.
