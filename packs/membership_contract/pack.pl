% State the fact: name(membership_contract) — the runtime output-member-of-input-set contract.
name(membership_contract).
% State the fact: version('1.2.0') — the once-deterministic mode is an additive minor extension.
version('1.2.0').
% State the fact: title naming the construct, its forms and modes, and the findings it closes (N8/ARBITER-1 plain-list; N11/WP-427/N9 accessor; N14/WP-428/N12 once mode).
title('The Membership Contract construct (N8, WP-427, WP-428) — a runtime output-member postcondition: a plain-list form (closes ARBITER-1), an accessor form over a goal-described set (N11, closes N9), and an opt-in once-deterministic mode (N14, closes N12/N10)').
% State the fact: author is the PrologAI Community (no AI attribution, per house rules).
author('PrologAI Community', 'ai.university.aiu@gmail.com').
% State the fact: home points at the PrologAI repository.
home('https://github.com/ai-university-aiu/PrologAI').
% State the fact: download points at the repository releases page.
download('https://github.com/ai-university-aiu/PrologAI/releases').
% State the fact: requires([]) — it imports only SWI-Prolog standard libraries (lists, prolog_wrap).
requires([]).
% State the fact: layer(0) — a general language affordance beneath every pack that produces a selection.
layer(0).
% NOTE: no stratum(...) fact — it is a language construct, not at a Causalontology stratum, so it is
% UNBOUND under the N6 binding (a gap, never a violation), like the layer and lattice packs.
