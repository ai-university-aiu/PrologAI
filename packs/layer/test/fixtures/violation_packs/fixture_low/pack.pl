% State the fact: name(fixture_low) — a test-only fixture pack, not a real pack.
name(fixture_low).
% State the fact: version('1.0.0').
version('1.0.0').
% State the fact: title('Layer-rule test fixture: a layer-0 pack that illegally imports a layer-5 pack').
title('Layer-rule test fixture: a layer-0 pack that illegally imports a layer-5 pack').
% State the fact: layer(0) — this pack sits at the base; importing anything higher is a violation.
layer(0).
