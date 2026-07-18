% Declare the fixture module.
:- module(pack_sneaky_low, []).
% Import a sibling fixture pack to create a static edge for the layer rule to see.
:- use_module(library(pack_sneaky_high)).
