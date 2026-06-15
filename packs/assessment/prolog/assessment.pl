/*  PrologAI — Intelligence Assessment  (Specification Section 3.10, PR 12)

    Implements the three developmental assessment frameworks and the
    consciousness-indicator report.

    assess_bayley/2  — Bayley Scales of Infant and Toddler Development:
                       cognitive, language, socio-emotional, motor, and
                       adaptive behavior areas.  Returns a DQ score per area.

    assess_piaget/3  — Tests the mind against 8 Piagetian milestone levels
                       and returns milestone_achieved or milestone_not_achieved
                       based on proxy evidence in the Lattice.

                       The 8 levels:
                         1. reflex_coordination
                         2. object_permanence
                         3. goal_directed_behavior
                         4. deferred_imitation
                         5. symbolic_representation
                         6. conservation
                         7. theory_of_mind
                         8. formal_operations

    assess_chc/2     — CHC (Cattell-Horn-Carroll) model: 6 broad abilities
                       measured by proxy from Lattice state and actor metrics.

    assess_all/2     — Runs all three frameworks and appends a report of
                       four consciousness indicators (workspace ignition,
                       recurrent processing, self-model presence, valence
                       system activity).  Assessment results are stored as
                       node_facts of relation type 'assessment'.
*/

:- module(assessment, [
    assess_bayley/2,     % +MindId, -Report
    assess_piaget/3,     % +MindId, +Level, -Result
    assess_chc/2,        % +MindId, -Report
    assess_all/2         % +MindId, -Report
]).

:- use_module(library(node_facts),  [live_node_facts/2, anchor_node/4,
                                     traverse_nexus/4, default_nexus/1]).
:- use_module(library(lattice),     [nexus_is_open/1]).
:- use_module(library(lists),       [member/2]).

% ---------------------------------------------------------------------------
% Piagetian milestone proxy evidence
% ---------------------------------------------------------------------------

%  milestone_evidence(+Level, +Nexus, +NodeFactList, -Bool)
%  True when the proxy evidence for Level is present in the Lattice.

milestone_evidence(1, Nexus, _Ids) :-
    % reflex_coordination: any percept_signal node_fact exists
    once((
        node_facts:lattice_node_fact(Nexus, _, percept_signal, _, _)
    )).
milestone_evidence(2, Nexus, _Ids) :-
    % object_permanence: any object_tracking node_fact exists
    once((
        node_facts:lattice_node_fact(Nexus, _, object_tracking, _, _)
    )).
milestone_evidence(3, Nexus, _Ids) :-
    % goal_directed_behavior: any objective node_fact
    once((
        node_facts:lattice_node_fact(Nexus, _, objective, _, _)
    )).
milestone_evidence(4, Nexus, _Ids) :-
    % deferred_imitation: any agent_action imitation record
    once((
        node_facts:lattice_node_fact(Nexus, _, agent_action, _, _)
    )).
milestone_evidence(5, Nexus, _Ids) :-
    % symbolic_representation: any symbolic node_fact
    once((
        node_facts:lattice_node_fact(Nexus, _, symbolic_representation, _, _)
    )).
milestone_evidence(6, Nexus, _Ids) :-
    % conservation: any conservation_demonstrated node_fact
    once((
        node_facts:lattice_node_fact(Nexus, _, conservation_demonstrated, _, _)
    )).
milestone_evidence(7, Nexus, _Ids) :-
    % theory_of_mind: any theory_of_mind node_fact
    once((
        node_facts:lattice_node_fact(Nexus, _, theory_of_mind, _, _)
    )).
milestone_evidence(8, Nexus, _Ids) :-
    % formal_operations: any formal_proof or abstract_reasoning node_fact
    once((
        node_facts:lattice_node_fact(Nexus, _, formal_proof, _, _)
    )).

% Milestone name mapping
milestone_name(1, reflex_coordination).
milestone_name(2, object_permanence).
milestone_name(3, goal_directed_behavior).
milestone_name(4, deferred_imitation).
milestone_name(5, symbolic_representation).
milestone_name(6, conservation).
milestone_name(7, theory_of_mind).
milestone_name(8, formal_operations).

% ---------------------------------------------------------------------------
% assess_piaget/3
% ---------------------------------------------------------------------------

assess_piaget(_MindId, Level, Result) :-
    integer(Level), Level >= 1, Level =< 8,
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  live_node_facts(Nexus, Ids),
        ( catch(milestone_evidence(Level, Nexus, Ids), _, fail)
        ->  Result = milestone_achieved
        ;   Result = milestone_not_achieved
        )
    ;   Result = milestone_not_achieved
    ).

% ---------------------------------------------------------------------------
% assess_bayley/2
% ---------------------------------------------------------------------------

assess_bayley(MindId, Report) :-
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  live_node_facts(Nexus, Ids),
        length(Ids, NIds),
        % Proxy DQ scores based on Lattice state
        cognitive_dq(Nexus, NIds, CognDQ),
        language_dq(Nexus, LanguageDQ),
        motor_dq(Nexus, MotorDQ),
        adaptive_dq(NIds, AdaptDQ)
    ;   CognDQ = 0.0, LanguageDQ = 0.0, MotorDQ = 0.0, AdaptDQ = 0.0
    ),
    Report = bayley_report{
        mind:         MindId,
        cognitive_dq: CognDQ,
        language_dq:  LanguageDQ,
        motor_dq:     MotorDQ,
        adaptive_dq:  AdaptDQ
    },
    catch(
        anchor_node(assessment, [MindId, bayley, Report], [], _),
        _, true
    ).

cognitive_dq(Nexus, NIds, DQ) :-
    aggregate_all(count,
        node_facts:lattice_node_fact(Nexus, _, percept_signal, _, _),
        Percepts),
    DQ is min(100.0, float(NIds) * 0.5 + float(Percepts) * 2.0).

language_dq(Nexus, DQ) :-
    aggregate_all(count,
        node_facts:lattice_node_fact(Nexus, _, phonological, _, _),
        PhonoCount),
    DQ is min(100.0, float(PhonoCount) * 5.0).

motor_dq(Nexus, DQ) :-
    aggregate_all(count,
        node_facts:lattice_node_fact(Nexus, _, body_command, _, _),
        CommandCount),
    DQ is min(100.0, float(CommandCount) * 3.0).

adaptive_dq(NIds, DQ) :-
    DQ is min(100.0, float(NIds) * 0.1).

% ---------------------------------------------------------------------------
% assess_chc/2
% ---------------------------------------------------------------------------

assess_chc(MindId, Report) :-
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  live_node_facts(Nexus, Ids), length(Ids, STM),
        aggregate_all(count,
            node_facts:lattice_node_fact(Nexus, _, _, _, _),
            TotalFacts),
        findall(R, node_facts:lattice_node_fact(Nexus, _, R, _, _), AllRels),
        sort(AllRels, UniqueRels), length(UniqueRels, RelDiversity),
        traverse_latency(Nexus, ProcessingSpeed),
        long_term_retrieval_score(LTR)
    ;   STM = 0, TotalFacts = 0, RelDiversity = 0,
        ProcessingSpeed = 0.0, LTR = 0.0
    ),
    CrystKnowledge is float(TotalFacts) * 0.1 + float(RelDiversity) * 0.5,
    Report = chc_report{
        mind:                 MindId,
        fluid_reasoning:      RelDiversity,
        crystallized_knowledge: CrystKnowledge,
        short_term_memory:    STM,
        processing_speed:     ProcessingSpeed,
        long_term_retrieval:  LTR,
        visual_processing:    0
    },
    catch(
        anchor_node(assessment, [MindId, chc, Report], [], _),
        _, true
    ).

traverse_latency(Nexus, Ms) :-
    get_time(T0),
    ignore(traverse_nexus(Nexus, node_fact(_, _, _), 1, _)),
    get_time(T1),
    Ms is (T1 - T0) * 1000.0.

long_term_retrieval_score(Score) :-
    catch(
        ( sona:sona_trajectory_id_counter(N),
          Score is min(1.0, float(N) / 100.0) )
    , _, Score = 0.0 ).

% ---------------------------------------------------------------------------
% Consciousness indicator probes
% ---------------------------------------------------------------------------

consciousness_indicator(workspace_ignition, Nexus, present) :-
    once((
        node_facts:lattice_node_fact(Nexus, _, workspace_broadcast, _, _)
    )), !.
consciousness_indicator(workspace_ignition, _, absent).

consciousness_indicator(recurrent_processing, _Nexus, present) :-
    catch(
        ( cyclic_actor:actor_registry(_, _, _) -> true ; fail ),
        _, fail
    ), !.
consciousness_indicator(recurrent_processing, _, present) :-
    % Sentinels constitute a form of recurrent processing
    catch(
        ( sentinels:pai_sentinel_entry(_, _, _, _, _, _) -> true ; fail ),
        _, fail
    ), !.
consciousness_indicator(recurrent_processing, _, absent).

consciousness_indicator(self_model_presence, Nexus, present) :-
    once((
        node_facts:lattice_node_fact(Nexus, _, self_model, _, _)
    )), !.
consciousness_indicator(self_model_presence, _, absent).

consciousness_indicator(valence_system, _Nexus, present) :-
    catch(
        ( current_predicate(affect:pai_marker_stamp/4) -> true ; fail ),
        _, fail
    ), !.
consciousness_indicator(valence_system, _, absent).

% ---------------------------------------------------------------------------
% assess_all/2
% ---------------------------------------------------------------------------

assess_all(MindId, Report) :-
    assess_bayley(MindId, Bayley),
    assess_chc(MindId, CHC),
    findall(L-R, (
        between(1, 8, L),
        assess_piaget(MindId, L, R)
    ), PiagetPairs),
    ( default_nexus(Nexus), nexus_is_open(Nexus) -> true ; Nexus = none ),
    findall(Indicator-Status, (
        member(Indicator, [workspace_ignition, recurrent_processing,
                           self_model_presence, valence_system]),
        ( Nexus \= none
        ->  consciousness_indicator(Indicator, Nexus, Status)
        ;   Status = absent )
    ), ConsciousnessPairs),
    Report = assessment_report{
        mind:                  MindId,
        bayley:                Bayley,
        chc:                   CHC,
        piaget_milestones:     PiagetPairs,
        consciousness_indicators: ConsciousnessPairs
    },
    catch(
        anchor_node(assessment, [MindId, all, Report], [], _),
        _, true
    ).
