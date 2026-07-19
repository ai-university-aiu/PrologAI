/*  affective_state (WP-430, Layer 0): a first-class, persisted, modulatory AFFECTIVE STATE.

    Wave 10 Stage 2 (Theme D). The consolidated Requirements Ledger's finding
    AMYGDALA-1 is that PrologAI has no first-class construct for a PERSISTED,
    MODULATORY affective state - a valence/salience (or mood) that persists across
    stimuli and COLOURS later processing, and whose held value can make a later
    output's legality context-dependent. The amygdala had to SMUGGLE its cortisol
    regime into the committed appraisal value (appraisal(Valence, Salience, Regime))
    and carry its association and tone as ad-hoc data, precisely because no held
    affect construct existed.

    This pack is that construct. It holds ONE affective context - a dict of a
    valence, a salience, a mood, and a cortisol tone - that survives across calls
    (a module-scoped held state, glass-box and inspectable) and derives a REGIME
    (baseline or stress) that later processing reads. Paired with the membership
    contract's context-aware accessor (WP-431), a later output's legality can depend
    on this HELD context WITHOUT smuggling it into the output value.

    It is base infrastructure: it imports only SWI-Prolog standard libraries, sits
    at layer 0 beneath every region, and has no stratum (an unbound gap, as the
    other layer-0 constructs are). It stores no ARC state and touches no solving core.
*/

% Declare the module: set/read the held affective context, derive its regime, modulate, decay, and clear it.
:- module(affective_state, [
    % affective_state_baseline/1: the neutral baseline affective context.
    affective_state_baseline/1,
    % affective_state_set/1: set (replace) the held affective context.
    affective_state_set/1,
    % affective_state_get/1: read the held affective context (the baseline when none is set).
    affective_state_get/1,
    % affective_state_regime/1: the derived regime (baseline or stress) - a context goal for the membership contract.
    affective_state_regime/1,
    % affective_state_modulate/1: fold a partial update dict into the held context.
    affective_state_modulate/1,
    % affective_state_decay/0: move the held cortisol tone and salience one step toward baseline.
    affective_state_decay/0,
    % affective_state_clear/0: reset the held context to the baseline.
    affective_state_clear/0
]).

% Import SWI-Prolog dict utilities (the affective context is a dict).
:- use_module(library(dicts)).
% Import list utilities.
:- use_module(library(lists)).

% The single held affective context (module-scoped, so it PERSISTS across calls within a session).
:- dynamic affective_state_held/1.

% The cortisol tone at or above which the derived regime is STRESS (mirrors the amygdala's transduction).
affective_state_stress_threshold(0.5).
% The fraction of the distance to baseline that one decay step closes.
affective_state_decay_rate(0.5).

% -- affective_state_baseline(-Baseline): the neutral baseline affective context.
% A calm, unaroused, unstressed state: neutral valence, zero salience, calm mood, zero cortisol tone.
affective_state_baseline(_{valence: neutral, salience: 0.0, mood: calm, cortisol: 0.0}).

% -- affective_state_set(+Context): replace the held affective context with Context (a dict).
% The context must be a dict; setting it is how a region records that its affect has moved.
affective_state_set(Context) :-
    % The held context must be a dict.
    is_dict(Context),
    % Replace any prior held context with this one.
    retractall(affective_state_held(_)),
    assertz(affective_state_held(Context)).

% -- affective_state_get(-Context): read the held affective context, or the baseline if none is held.
affective_state_get(Context) :-
    % Use the held context when one is set; otherwise the baseline (so a reader never fails).
    ( affective_state_held(Held) -> Context = Held ; affective_state_baseline(Context) ).

% -- affective_state_regime(-Regime): the derived regime (baseline or stress) from the held cortisol tone.
% This is a deterministic CONTEXT GOAL: the membership contract's context-aware accessor calls it to read the
% current held context when judging a later output's legality, so the regime need not be carried in the output.
affective_state_regime(Regime) :-
    % Read the held context (baseline when unset).
    affective_state_get(Context),
    % Read its cortisol tone (defaulting to zero if the dict omits it).
    ( get_dict(cortisol, Context, Cortisol) -> true ; Cortisol = 0.0 ),
    % Read the stress threshold.
    affective_state_stress_threshold(Threshold),
    % A tone at or above the threshold is the stress regime; below it, baseline.
    ( Cortisol >= Threshold -> Regime = stress ; Regime = baseline ).

% -- affective_state_modulate(+Update): fold a partial update dict into the held context (the rest is unchanged).
% This is how an appraisal COLOURS the held state - it modulates the affect that later processing will read.
affective_state_modulate(Update) :-
    % The update must be a dict.
    is_dict(Update),
    % Read the current held context.
    affective_state_get(Context),
    % Overlay the update's pairs onto the held context (update keys win).
    put_dict(Update, Context, Context1),
    % Store the modulated context.
    affective_state_set(Context1).

% -- affective_state_decay/0: move the held cortisol tone and salience one step toward the baseline.
% Affect fades over successive steps toward calm; a region calls this between stimuli.
affective_state_decay :-
    % Read the current held context and the baseline.
    affective_state_get(Context),
    affective_state_baseline(Baseline),
    affective_state_decay_rate(Rate),
    % Read the current and baseline tones and saliences (defaulting to the baseline values when absent).
    ( get_dict(cortisol, Context, C0) -> true ; get_dict(cortisol, Baseline, C0) ),
    ( get_dict(salience, Context, S0) -> true ; get_dict(salience, Baseline, S0) ),
    get_dict(cortisol, Baseline, Cb),
    get_dict(salience, Baseline, Sb),
    % Close a fraction of the distance to baseline for each.
    C1 is C0 + Rate * (Cb - C0),
    S1 is S0 + Rate * (Sb - S0),
    % Fold the decayed tone and salience back into the held context.
    affective_state_modulate(_{cortisol: C1, salience: S1}).

% -- affective_state_clear/0: reset the held affective context to the baseline.
affective_state_clear :-
    % Read the baseline and set it as the held context.
    affective_state_baseline(Baseline),
    affective_state_set(Baseline).
