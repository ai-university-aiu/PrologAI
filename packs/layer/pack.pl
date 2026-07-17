% State the fact: name(layer).
name(layer).
% State the fact: version('1.0.0').
version('1.0.0').
% State the fact: title('PrologAI Strict Layer Rule — declare, check, and enforce the acyclic layer discipline (WP-426)').
title('PrologAI Strict Layer Rule — declare, check, and enforce the acyclic layer discipline (WP-426)').
% State the fact: author('PrologAI Community', 'ai.university.aiu@gmail.com').
author('PrologAI Community', 'ai.university.aiu@gmail.com').
% State the fact: home('https://github.com/ai-university-aiu/PrologAI').
home('https://github.com/ai-university-aiu/PrologAI').
% State the fact: download('https://github.com/ai-university-aiu/PrologAI/releases').
download('https://github.com/ai-university-aiu/PrologAI/releases').
% State the fact: requires([]) — the layer construct sits beneath every other pack and depends on nothing.
requires([]).
% State the fact: layer(0) — this construct is base infrastructure; it may not depend on any higher layer.
layer(0).
