/*  PrologAI — Concept Workspace (J-Space)  (WP-388, Layer 363)

    A named workspace of the concepts the system is currently holding
    in mind, each with an activation strength and a source. Inspired by
    the 2026 interpretability finding that language models carry a
    small, sparse internal workspace of verbalizable concepts — the
    Jacobian Space (J-Space), read through the Jacobian Lens (J-Lens).
    PrologAI is glass-box by construction, so here the workspace is not
    something to be discovered with instruments: it is a first-class,
    readable, editable object.

    What the lens metaphor buys us, symbolically:

        js_reading/2      the J-Lens readout — every held concept,
                          ranked by activation strength.
        js_silent/2       concepts held in mind but never verbalized —
                          hidden-thought detection.
        js_hold/4         implant or refresh a concept.
        js_ablate/2       remove a concept; derivations that required
                          it stop going through.
        js_swap/3         exchange two concepts' strengths, changing
                          what the system reports thinking.
        js_derive/3       record that a conclusion was reached from a
                          set of held concepts — the causal trace.

    Concepts are atoms or ground terms. Strengths are non-negative
    floats. Sources say where a concept came from (percept, inference,
    implant, or any caller-chosen atom).

    Exported predicates:

    js_open/1       +Space
    js_close/1      +Space
    js_hold/4       +Space, +Concept, +Strength, +Source
    js_strength/3   +Space, +Concept, -Strength
    js_source/3     +Space, +Concept, -Source
    js_active/2     +Space, -Concepts
    js_reading/2    +Space, -Reading
    js_ablate/2     +Space, +Concept
    js_swap/3       +Space, +C1, +C2
    js_boost/3      +Space, +Concept, +Delta
    js_decay/2      +Space, +Factor
    js_capacity/2   +Space, +N
    js_verbalize/2  +Space, +Concept
    js_silent/2     +Space, -Silent
    js_monitor/3    +Space, +Concept, -Status
    js_derive/3     +Space, +Conclusion, +Required
    js_explain/3    +Space, +Conclusion, -Concepts
    js_report/2     +Space, -Report
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(jspace, [
    % js_open/1: create or reset a named workspace.
    js_open/1,
    % js_close/1: clear a workspace completely.
    js_close/1,
    % js_hold/4: implant or refresh a concept.
    js_hold/4,
    % js_strength/3: activation strength of a held concept.
    js_strength/3,
    % js_source/3: source of a held concept.
    js_source/3,
    % js_active/2: held concepts with positive strength, ranked.
    js_active/2,
    % js_reading/2: the J-Lens readout of the whole workspace.
    js_reading/2,
    % js_ablate/2: remove a concept from the workspace.
    js_ablate/2,
    % js_swap/3: exchange the strengths of two concepts.
    js_swap/3,
    % js_boost/3: add to a concept's strength.
    js_boost/3,
    % js_decay/2: scale every strength down, dropping the negligible.
    js_decay/2,
    % js_capacity/2: keep only the strongest N concepts.
    js_capacity/2,
    % js_verbalize/2: mark a held concept as spoken aloud.
    js_verbalize/2,
    % js_silent/2: held concepts never verbalized.
    js_silent/2,
    % js_monitor/3: watch one concept, present or absent.
    js_monitor/3,
    % js_derive/3: record a conclusion drawn from held concepts.
    js_derive/3,
    % js_explain/3: which concepts produced a conclusion.
    js_explain/3,
    % js_report/2: full introspection snapshot of the workspace.
    js_report/2
]).

% Use the lists library for member/2, sort/4, and friends.
:- use_module(library(lists)).

% The concept ledger: js_concept_(Space, Concept, Strength, Source).
:- dynamic js_concept_/4.
% The verbalization log: js_verbal_(Space, Concept).
:- dynamic js_verbal_/2.
% The derivation traces: js_trace_(Space, Conclusion, Concepts).
:- dynamic js_trace_/3.

% ===========================================================================
% WORKSPACE LIFECYCLE
% ===========================================================================

% js_open(+Space): create or reset a named workspace.
js_open(Space) :-
    % Opening is clearing: a fresh workspace holds nothing.
    js_close(Space).

% js_close(+Space): clear every record of the workspace.
js_close(Space) :-
    % Drop all held concepts.
    retractall(js_concept_(Space, _, _, _)),
    % Drop the verbalization log.
    retractall(js_verbal_(Space, _)),
    % Drop the derivation traces.
    retractall(js_trace_(Space, _, _)).

% ===========================================================================
% HOLDING, READING, AND EDITING CONCEPTS
% ===========================================================================

% js_hold(+Space, +Concept, +Strength, +Source): implant or refresh.
js_hold(Space, Concept, Strength, Source) :-
    % Strengths are non-negative numbers.
    number(Strength),
    % Enforce the lower bound.
    Strength >= 0.0,
    % Remove any previous entry for this concept.
    retractall(js_concept_(Space, Concept, _, _)),
    % Record the fresh entry.
    assertz(js_concept_(Space, Concept, Strength, Source)).

% js_strength(+Space, +Concept, -Strength): read one activation.
js_strength(Space, Concept, Strength) :-
    % Look the concept up; absence means failure, honestly.
    js_concept_(Space, Concept, Strength, _).

% js_source(+Space, +Concept, -Source): read one concept's origin.
js_source(Space, Concept, Source) :-
    % Look the concept up; absence means failure, honestly.
    js_concept_(Space, Concept, _, Source).

% js_reading(+Space, -Reading): ranked Concept-Strength readout.
js_reading(Space, Reading) :-
    % Collect every held concept with its strength.
    findall(S-C, js_concept_(Space, C, S, _), Raw),
    % Rank by strength, strongest first, keeping ties.
    sort(1, @>=, Raw, Ranked),
    % Flip the pairs into Concept-Strength form.
    findall(C-S, member(S-C, Ranked), Reading).

% js_active(+Space, -Concepts): positively activated concepts, ranked.
js_active(Space, Concepts) :-
    % Take the full readout.
    js_reading(Space, Reading),
    % Keep the concepts whose strength is positive.
    findall(C, ( member(C-S, Reading), S > 0.0 ), Concepts).

% js_ablate(+Space, +Concept): remove one concept entirely.
js_ablate(Space, Concept) :-
    % Drop the ledger entry.
    retractall(js_concept_(Space, Concept, _, _)),
    % Drop its verbalization marks as well.
    retractall(js_verbal_(Space, Concept)).

% js_swap(+Space, +C1, +C2): exchange the strengths of two concepts.
js_swap(Space, C1, C2) :-
    % Both concepts must currently be held.
    once(js_concept_(Space, C1, S1, Src1)),
    % Fetch the second concept.
    once(js_concept_(Space, C2, S2, Src2)),
    % Re-hold the first with the second's strength.
    js_hold(Space, C1, S2, Src1),
    % Re-hold the second with the first's strength.
    js_hold(Space, C2, S1, Src2).

% js_boost(+Space, +Concept, +Delta): add to one activation.
js_boost(Space, Concept, Delta) :-
    % The concept must currently be held.
    once(js_concept_(Space, Concept, S, Src)),
    % Raise the strength, never below zero.
    S2 is max(0.0, S + Delta),
    % Re-hold with the new strength.
    js_hold(Space, Concept, S2, Src).

% js_decay(+Space, +Factor): scale all strengths, dropping the negligible.
js_decay(Space, Factor) :-
    % Snapshot the ledger before rewriting it.
    findall(c(C, S, Src), js_concept_(Space, C, S, Src), Entries),
    % Rewrite each entry with its decayed strength.
    forall(member(c(C, S, Src), Entries),
        % Compute and apply the decay for one concept.
        ( S2 is S * Factor,
          % Negligible activations fall out of the workspace.
          (   S2 < 1.0e-6
          % Drop the faded concept.
          ->  js_ablate(Space, C)
          % Otherwise keep it at the decayed strength.
          ;   js_hold(Space, C, S2, Src)
          ) )).

% js_capacity(+Space, +N): keep only the strongest N concepts.
js_capacity(Space, N) :-
    % Take the ranked readout.
    js_reading(Space, Reading),
    % Split the ranking at the capacity.
    length(Reading, Have),
    % Nothing to do when the workspace fits.
    (   Have =< N
    % Within capacity: leave the workspace alone.
    ->  true
    % Over capacity: ablate everything below the cut.
    ;   length(Keep, N),
        % The strongest N stay.
        append(Keep, Drop, Reading),
        % Every concept below the cut is removed.
        forall(member(C-_, Drop), js_ablate(Space, C))
    ).

% ===========================================================================
% VERBALIZATION AND SILENT THOUGHTS
% ===========================================================================

% js_verbalize(+Space, +Concept): mark a held concept as spoken.
js_verbalize(Space, Concept) :-
    % Only a held concept can be verbalized.
    js_concept_(Space, Concept, _, _),
    % Record the verbalization once.
    (   js_verbal_(Space, Concept)
    % Already recorded: nothing to add.
    ->  true
    % First mention: log it.
    ;   assertz(js_verbal_(Space, Concept))
    ).

% js_silent(+Space, -Silent): active concepts never verbalized, ranked.
js_silent(Space, Silent) :-
    % Take the active ranking.
    js_active(Space, Active),
    % Keep the concepts missing from the verbalization log.
    findall(C, ( member(C, Active), \+ js_verbal_(Space, C) ), Silent).

% js_monitor(+Space, +Concept, -Status): watch for one concept.
js_monitor(Space, Concept, Status) :-
    % Check the ledger for the concept.
    (   js_concept_(Space, Concept, S, _)
    % Present: report its strength.
    ->  Status = present(S)
    % Absent: say so plainly.
    ;   Status = absent
    ).

% ===========================================================================
% DERIVATIONS — THE CAUSAL TRACE
% ===========================================================================

% js_derive(+Space, +Conclusion, +Required): conclude from held concepts.
js_derive(Space, Conclusion, Required) :-
    % Every required concept must be actively held right now.
    forall(member(C, Required),
        % Positive activation is required; ablation breaks this.
        ( js_concept_(Space, C, S, _), S > 0.0 )),
    % Record the derivation trace.
    assertz(js_trace_(Space, Conclusion, Required)).

% js_explain(+Space, +Conclusion, -Concepts): read a derivation trace.
js_explain(Space, Conclusion, Concepts) :-
    % Fetch the recorded trace.
    js_trace_(Space, Conclusion, Concepts).

% js_report(+Space, -Report): full introspection snapshot.
js_report(Space, report(Reading, Silent, Traces)) :-
    % The ranked readout of every held concept.
    js_reading(Space, Reading),
    % The held-but-unspoken concepts.
    js_silent(Space, Silent),
    % Every recorded derivation.
    findall(Conclusion-Concepts, js_trace_(Space, Conclusion, Concepts), Traces).
