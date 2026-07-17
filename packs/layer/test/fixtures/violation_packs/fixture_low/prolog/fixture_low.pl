% Declare this fixture file as the 'fixture_low' module, exporting nothing.
:- module(fixture_low, []).
% Deliberately import the higher-layer fixture pack to create an upward edge.
% This line is only ever TEXT-SCANNED by the layer checker; it is never loaded,
% so library(fixture_high) need not resolve on the library path.
:- use_module(library(fixture_high)).
