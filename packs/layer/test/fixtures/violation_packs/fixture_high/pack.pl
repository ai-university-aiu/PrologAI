% State the fact: name(fixture_high) — a test-only fixture pack, not a real pack.
name(fixture_high).
% State the fact: version('1.0.0').
version('1.0.0').
% State the fact: title('Layer-rule test fixture: the layer-5 pack that fixture_low illegally imports').
title('Layer-rule test fixture: the layer-5 pack that fixture_low illegally imports').
% State the fact: layer(5) — this pack sits above fixture_low, so the import from it is upward.
layer(5).
