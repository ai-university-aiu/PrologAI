% Test suite for the affective_state pack — a persisted, modulatory affective state.
% These tests confirm the held context persists across calls, the regime derives from the cortisol tone,
% modulation colours the state, and decay/clear return it toward baseline.
% Load the affective_state module under test.
:- use_module(library(affective_state)).
% Load the PLUnit testing framework.
:- use_module(library(plunit)).

% Open the test block for the affective_state pack.
:- begin_tests(affective_state).

% Before each test, clear the held state so tests do not leak into one another.
:- dynamic did_setup/0.

% A freshly-cleared state reads as the baseline, and the baseline regime is calm/baseline.
test(baseline_is_neutral) :-
    affective_state_clear,
    affective_state_get(C),
    assertion(get_dict(valence, C, neutral)),
    assertion(get_dict(cortisol, C, 0.0)),
    affective_state_regime(R), assertion(R == baseline).

% Setting a stressed context PERSISTS across a later read, and derives the stress regime.
test(held_context_persists_and_derives_stress_regime) :-
    affective_state_set(_{valence: threat, salience: 0.8, mood: anxious, cortisol: 0.8}),
    affective_state_get(C), assertion(get_dict(valence, C, threat)),
    affective_state_regime(R), assertion(R == stress).

% Modulation folds a partial update into the held state, leaving the rest unchanged.
test(modulate_folds_update) :-
    affective_state_clear,
    affective_state_modulate(_{cortisol: 0.7}),
    affective_state_get(C),
    assertion(get_dict(cortisol, C, 0.7)),
    assertion(get_dict(valence, C, neutral)),   % unchanged from baseline
    affective_state_regime(R), assertion(R == stress).

% Decay moves the cortisol tone toward baseline; enough steps return the regime to baseline.
test(decay_returns_toward_baseline) :-
    affective_state_set(_{valence: threat, salience: 1.0, mood: anxious, cortisol: 1.0}),
    affective_state_decay, affective_state_decay, affective_state_decay,
    affective_state_get(C), get_dict(cortisol, C, Cortisol),
    assertion(Cortisol < 0.5),
    affective_state_regime(R), assertion(R == baseline).

% Clear resets to the baseline regardless of the prior state.
test(clear_resets_to_baseline) :-
    affective_state_set(_{valence: appetitive, salience: 0.9, mood: eager, cortisol: 0.9}),
    affective_state_clear,
    affective_state_get(C), affective_state_baseline(B),
    % Compare by content (dict tags are anonymous, so ==/2 on whole dicts would compare tags too).
    dict_pairs(C, _, CP), dict_pairs(B, _, BP),
    assertion(CP == BP).

% Close the test block.
:- end_tests(affective_state).
