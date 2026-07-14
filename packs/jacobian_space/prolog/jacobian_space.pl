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

        jacobian_space_reading/2      the J-Lens readout — every held concept,
                          ranked by activation strength.
        jacobian_space_silent/2       concepts held in mind but never verbalized —
                          hidden-thought detection.
        jacobian_space_hold/4         implant or refresh a concept.
        jacobian_space_ablate/2       remove a concept; derivations that required
                          it stop going through.
        jacobian_space_swap/3         exchange two concepts' strengths, changing
                          what the system reports thinking.
        jacobian_space_derive/3       record that a conclusion was reached from a
                          set of held concepts — the causal trace.

    Concepts are atoms or ground terms. Strengths are non-negative
    floats. Sources say where a concept came from (percept, inference,
    implant, or any caller-chosen atom).

    Exported predicates:

    jacobian_space_open/1       +Space
    jacobian_space_close/1      +Space
    jacobian_space_hold/4       +Space, +Concept, +Strength, +Source
    jacobian_space_strength/3   +Space, +Concept, -Strength
    jacobian_space_source/3     +Space, +Concept, -Source
    jacobian_space_active/2     +Space, -Concepts
    jacobian_space_reading/2    +Space, -Reading
    jacobian_space_ablate/2     +Space, +Concept
    jacobian_space_swap/3       +Space, +C1, +C2
    jacobian_space_boost/3      +Space, +Concept, +Delta
    jacobian_space_decay/2      +Space, +Factor
    jacobian_space_capacity/2   +Space, +N
    jacobian_space_verbalize/2  +Space, +Concept
    jacobian_space_silent/2     +Space, -Silent
    jacobian_space_monitor/3    +Space, +Concept, -Status
    jacobian_space_derive/3     +Space, +Conclusion, +Required
    jacobian_space_explain/3    +Space, +Conclusion, -Concepts
    jacobian_space_report/2     +Space, -Report
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(jacobian_space, [
    % jacobian_space_open/1: create or reset a named workspace.
    jacobian_space_open/1,
    % jacobian_space_close/1: clear a workspace completely.
    jacobian_space_close/1,
    % jacobian_space_hold/4: implant or refresh a concept.
    jacobian_space_hold/4,
    % jacobian_space_strength/3: activation strength of a held concept.
    jacobian_space_strength/3,
    % jacobian_space_source/3: source of a held concept.
    jacobian_space_source/3,
    % jacobian_space_active/2: held concepts with positive strength, ranked.
    jacobian_space_active/2,
    % jacobian_space_reading/2: the J-Lens readout of the whole workspace.
    jacobian_space_reading/2,
    % jacobian_space_ablate/2: remove a concept from the workspace.
    jacobian_space_ablate/2,
    % jacobian_space_swap/3: exchange the strengths of two concepts.
    jacobian_space_swap/3,
    % jacobian_space_boost/3: add to a concept's strength.
    jacobian_space_boost/3,
    % jacobian_space_decay/2: scale every strength down, dropping the negligible.
    jacobian_space_decay/2,
    % jacobian_space_capacity/2: keep only the strongest N concepts.
    jacobian_space_capacity/2,
    % jacobian_space_verbalize/2: mark a held concept as spoken aloud.
    jacobian_space_verbalize/2,
    % jacobian_space_silent/2: held concepts never verbalized.
    jacobian_space_silent/2,
    % jacobian_space_monitor/3: watch one concept, present or absent.
    jacobian_space_monitor/3,
    % jacobian_space_derive/3: record a conclusion drawn from held concepts.
    jacobian_space_derive/3,
    % jacobian_space_explain/3: which concepts produced a conclusion.
    jacobian_space_explain/3,
    % jacobian_space_report/2: full introspection snapshot of the workspace.
    jacobian_space_report/2
]).

% Use the lists library for member/2, sort/4, and friends.
:- use_module(library(lists)).

% The concept ledger: jacobian_space_concept_(Space, Concept, Strength, Source).
:- dynamic jacobian_space_concept_/4.
% The verbalization log: jacobian_space_verbal_(Space, Concept).
:- dynamic jacobian_space_verbal_/2.
% The derivation traces: jacobian_space_trace_(Space, Conclusion, Concepts).
:- dynamic jacobian_space_trace_/3.

% ===========================================================================
% WORKSPACE LIFECYCLE
% ===========================================================================

% jacobian_space_open(+Space): create or reset a named workspace.
jacobian_space_open(Space) :-
    % Opening is clearing: a fresh workspace holds nothing.
    jacobian_space_close(Space).

% jacobian_space_close(+Space): clear every record of the workspace.
jacobian_space_close(Space) :-
    % Drop all held concepts.
    retractall(jacobian_space_concept_(Space, _, _, _)),
    % Drop the verbalization log.
    retractall(jacobian_space_verbal_(Space, _)),
    % Drop the derivation traces.
    retractall(jacobian_space_trace_(Space, _, _)).

% ===========================================================================
% HOLDING, READING, AND EDITING CONCEPTS
% ===========================================================================

% jacobian_space_hold(+Space, +Concept, +Strength, +Source): implant or refresh.
jacobian_space_hold(Space, Concept, Strength, Source) :-
    % Strengths are non-negative numbers.
    number(Strength),
    % Enforce the lower bound.
    Strength >= 0.0,
    % Remove any previous entry for this concept.
    retractall(jacobian_space_concept_(Space, Concept, _, _)),
    % Record the fresh entry.
    assertz(jacobian_space_concept_(Space, Concept, Strength, Source)).

% jacobian_space_strength(+Space, +Concept, -Strength): read one activation.
jacobian_space_strength(Space, Concept, Strength) :-
    % Look the concept up; absence means failure, honestly.
    jacobian_space_concept_(Space, Concept, Strength, _).

% jacobian_space_source(+Space, +Concept, -Source): read one concept's origin.
jacobian_space_source(Space, Concept, Source) :-
    % Look the concept up; absence means failure, honestly.
    jacobian_space_concept_(Space, Concept, _, Source).

% jacobian_space_reading(+Space, -Reading): ranked Concept-Strength readout.
jacobian_space_reading(Space, Reading) :-
    % Collect every held concept with its strength.
    findall(S-C, jacobian_space_concept_(Space, C, S, _), Raw),
    % Rank by strength, strongest first, keeping ties.
    sort(1, @>=, Raw, Ranked),
    % Flip the pairs into Concept-Strength form.
    findall(C-S, member(S-C, Ranked), Reading).

% jacobian_space_active(+Space, -Concepts): positively activated concepts, ranked.
jacobian_space_active(Space, Concepts) :-
    % Take the full readout.
    jacobian_space_reading(Space, Reading),
    % Keep the concepts whose strength is positive.
    findall(C, ( member(C-S, Reading), S > 0.0 ), Concepts).

% jacobian_space_ablate(+Space, +Concept): remove one concept entirely.
jacobian_space_ablate(Space, Concept) :-
    % Drop the ledger entry.
    retractall(jacobian_space_concept_(Space, Concept, _, _)),
    % Drop its verbalization marks as well.
    retractall(jacobian_space_verbal_(Space, Concept)).

% jacobian_space_swap(+Space, +C1, +C2): exchange the strengths of two concepts.
jacobian_space_swap(Space, C1, C2) :-
    % Both concepts must currently be held.
    once(jacobian_space_concept_(Space, C1, S1, Src1)),
    % Fetch the second concept.
    once(jacobian_space_concept_(Space, C2, S2, Src2)),
    % Re-hold the first with the second's strength.
    jacobian_space_hold(Space, C1, S2, Src1),
    % Re-hold the second with the first's strength.
    jacobian_space_hold(Space, C2, S1, Src2).

% jacobian_space_boost(+Space, +Concept, +Delta): add to one activation.
jacobian_space_boost(Space, Concept, Delta) :-
    % The concept must currently be held.
    once(jacobian_space_concept_(Space, Concept, S, Src)),
    % Raise the strength, never below zero.
    S2 is max(0.0, S + Delta),
    % Re-hold with the new strength.
    jacobian_space_hold(Space, Concept, S2, Src).

% jacobian_space_decay(+Space, +Factor): scale all strengths, dropping the negligible.
jacobian_space_decay(Space, Factor) :-
    % Snapshot the ledger before rewriting it.
    findall(c(C, S, Src), jacobian_space_concept_(Space, C, S, Src), Entries),
    % Rewrite each entry with its decayed strength.
    forall(member(c(C, S, Src), Entries),
        % Compute and apply the decay for one concept.
        ( S2 is S * Factor,
          % Negligible activations fall out of the workspace.
          (   S2 < 1.0e-6
          % Drop the faded concept.
          ->  jacobian_space_ablate(Space, C)
          % Otherwise keep it at the decayed strength.
          ;   jacobian_space_hold(Space, C, S2, Src)
          ) )).

% jacobian_space_capacity(+Space, +N): keep only the strongest N concepts.
jacobian_space_capacity(Space, N) :-
    % Take the ranked readout.
    jacobian_space_reading(Space, Reading),
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
        forall(member(C-_, Drop), jacobian_space_ablate(Space, C))
    ).

% ===========================================================================
% VERBALIZATION AND SILENT THOUGHTS
% ===========================================================================

% jacobian_space_verbalize(+Space, +Concept): mark a held concept as spoken.
jacobian_space_verbalize(Space, Concept) :-
    % Only a held concept can be verbalized.
    jacobian_space_concept_(Space, Concept, _, _),
    % Record the verbalization once.
    (   jacobian_space_verbal_(Space, Concept)
    % Already recorded: nothing to add.
    ->  true
    % First mention: log it.
    ;   assertz(jacobian_space_verbal_(Space, Concept))
    ).

% jacobian_space_silent(+Space, -Silent): active concepts never verbalized, ranked.
jacobian_space_silent(Space, Silent) :-
    % Take the active ranking.
    jacobian_space_active(Space, Active),
    % Keep the concepts missing from the verbalization log.
    findall(C, ( member(C, Active), \+ jacobian_space_verbal_(Space, C) ), Silent).

% jacobian_space_monitor(+Space, +Concept, -Status): watch for one concept.
jacobian_space_monitor(Space, Concept, Status) :-
    % Check the ledger for the concept.
    (   jacobian_space_concept_(Space, Concept, S, _)
    % Present: report its strength.
    ->  Status = present(S)
    % Absent: say so plainly.
    ;   Status = absent
    ).

% ===========================================================================
% DERIVATIONS — THE CAUSAL TRACE
% ===========================================================================

% jacobian_space_derive(+Space, +Conclusion, +Required): conclude from held concepts.
jacobian_space_derive(Space, Conclusion, Required) :-
    % Every required concept must be actively held right now.
    forall(member(C, Required),
        % Positive activation is required; ablation breaks this.
        ( jacobian_space_concept_(Space, C, S, _), S > 0.0 )),
    % Record the derivation trace.
    assertz(jacobian_space_trace_(Space, Conclusion, Required)).

% jacobian_space_explain(+Space, +Conclusion, -Concepts): read a derivation trace.
jacobian_space_explain(Space, Conclusion, Concepts) :-
    % Fetch the recorded trace.
    jacobian_space_trace_(Space, Conclusion, Concepts).

% jacobian_space_report(+Space, -Report): full introspection snapshot.
jacobian_space_report(Space, report(Reading, Silent, Traces)) :-
    % The ranked readout of every held concept.
    jacobian_space_reading(Space, Reading),
    % The held-but-unspoken concepts.
    jacobian_space_silent(Space, Silent),
    % Every recorded derivation.
    findall(Conclusion-Concepts, jacobian_space_trace_(Space, Conclusion, Concepts), Traces).
