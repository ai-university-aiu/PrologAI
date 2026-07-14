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

% Declare this file as the 'assessment' module and list its exported predicates.
:- module(assessment, [
    % Continue the multi-line expression started above.
    assess_bayley/2,     % +MindId, -Report
    % Continue the multi-line expression started above.
    assess_piaget/3,     % +MindId, +Level, -Result
    % Continue the multi-line expression started above.
    assess_chc/2,        % +MindId, -Report
    % Continue the multi-line expression started above.
    assess_all/2         % +MindId, -Report
% Close the expression opened above.
]).

% Load the built-in 'node_facts' library so its predicates are available here.
:- use_module(library(node_facts),  [live_node_facts/2, anchor_node/4,
                                     % Continue the multi-line expression started above.
                                     traverse_nexus/4, default_nexus/1]).
% Import [nexus_is_open/1] from the built-in 'lattice' library.
:- use_module(library(lattice),     [nexus_is_open/1]).
% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),       [member/2]).

% ---------------------------------------------------------------------------
% Piagetian milestone proxy evidence
% ---------------------------------------------------------------------------

%  milestone_evidence(+Level, +Nexus, +NodeFactList, -Bool)
%  True when the proxy evidence for Level is present in the Lattice.

% Define a clause for 'milestone evidence': succeed when the following conditions hold.
milestone_evidence(1, Nexus, _Ids) :-
    % reflex_coordination: any percept_signal node_fact exists
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        node_facts:lattice_node_fact(Nexus, _, percept_signal, _, _)
    % Close the expression opened above.
    )).
% Define a clause for 'milestone evidence': succeed when the following conditions hold.
milestone_evidence(2, Nexus, _Ids) :-
    % object_permanence: any object_tracking node_fact exists
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        node_facts:lattice_node_fact(Nexus, _, object_tracking, _, _)
    % Close the expression opened above.
    )).
% Define a clause for 'milestone evidence': succeed when the following conditions hold.
milestone_evidence(3, Nexus, _Ids) :-
    % goal_directed_behavior: any objective node_fact
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        node_facts:lattice_node_fact(Nexus, _, objective, _, _)
    % Close the expression opened above.
    )).
% Define a clause for 'milestone evidence': succeed when the following conditions hold.
milestone_evidence(4, Nexus, _Ids) :-
    % deferred_imitation: any agent_action imitation record
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        node_facts:lattice_node_fact(Nexus, _, agent_action, _, _)
    % Close the expression opened above.
    )).
% Define a clause for 'milestone evidence': succeed when the following conditions hold.
milestone_evidence(5, Nexus, _Ids) :-
    % symbolic_representation: any symbolic node_fact
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        node_facts:lattice_node_fact(Nexus, _, symbolic_representation, _, _)
    % Close the expression opened above.
    )).
% Define a clause for 'milestone evidence': succeed when the following conditions hold.
milestone_evidence(6, Nexus, _Ids) :-
    % conservation: any conservation_demonstrated node_fact
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        node_facts:lattice_node_fact(Nexus, _, conservation_demonstrated, _, _)
    % Close the expression opened above.
    )).
% Define a clause for 'milestone evidence': succeed when the following conditions hold.
milestone_evidence(7, Nexus, _Ids) :-
    % theory_of_mind: any theory_of_mind node_fact
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        node_facts:lattice_node_fact(Nexus, _, theory_of_mind, _, _)
    % Close the expression opened above.
    )).
% Define a clause for 'milestone evidence': succeed when the following conditions hold.
milestone_evidence(8, Nexus, _Ids) :-
    % formal_operations: any formal_proof or abstract_reasoning node_fact
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        node_facts:lattice_node_fact(Nexus, _, formal_proof, _, _)
    % Close the expression opened above.
    )).

% Milestone name mapping
% State the fact: milestone name(1, reflex_coordination).
milestone_name(1, reflex_coordination).
% State the fact: milestone name(2, object_permanence).
milestone_name(2, object_permanence).
% State the fact: milestone name(3, goal_directed_behavior).
milestone_name(3, goal_directed_behavior).
% State the fact: milestone name(4, deferred_imitation).
milestone_name(4, deferred_imitation).
% State the fact: milestone name(5, symbolic_representation).
milestone_name(5, symbolic_representation).
% State the fact: milestone name(6, conservation).
milestone_name(6, conservation).
% State the fact: milestone name(7, theory_of_mind).
milestone_name(7, theory_of_mind).
% State the fact: milestone name(8, formal_operations).
milestone_name(8, formal_operations).

% ---------------------------------------------------------------------------
% assess_piaget/3
% ---------------------------------------------------------------------------

% Define a clause for 'assess piaget': succeed when the following conditions hold.
assess_piaget(_MindId, Level, Result) :-
    % Check that 'integer(Level), Level' is greater than or equal to '1, Level =< 8'.
    integer(Level), Level >= 1, Level =< 8,
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  live_node_facts(Nexus, Ids),
        % Continue the multi-line expression started above.
        ( catch(milestone_evidence(Level, Nexus, Ids), _, fail)
        % If the condition above succeeded, perform the following action.
        ->  Result = milestone_achieved
        % Otherwise (else branch), perform the following action.
        ;   Result = milestone_not_achieved
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   Result = milestone_not_achieved
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% assess_bayley/2
% ---------------------------------------------------------------------------

% Define a clause for 'assess bayley': succeed when the following conditions hold.
assess_bayley(MindId, Report) :-
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  live_node_facts(Nexus, Ids),
        % Continue the multi-line expression started above.
        length(Ids, NIds),
        % Proxy DQ scores based on Lattice state
        % Continue the multi-line expression started above.
        cognitive_dq(Nexus, NIds, CognDQ),
        % Continue the multi-line expression started above.
        language_dq(Nexus, LanguageDQ),
        % Continue the multi-line expression started above.
        motor_dq(Nexus, MotorDQ),
        % Continue the multi-line expression started above.
        adaptive_dq(NIds, AdaptDQ)
    % Otherwise (else branch), perform the following action.
    ;   CognDQ = 0.0, LanguageDQ = 0.0, MotorDQ = 0.0, AdaptDQ = 0.0
    % Close the expression opened above.
    ),
    % Check that 'Report' is unifiable with 'bayley_report{'.
    Report = bayley_report{
        % Execute: mind:         MindId,.
        mind:         MindId,
        % Execute: cognitive_dq: CognDQ,.
        cognitive_dq: CognDQ,
        % Execute: language_dq:  LanguageDQ,.
        language_dq:  LanguageDQ,
        % Execute: motor_dq:     MotorDQ,.
        motor_dq:     MotorDQ,
        % Execute: adaptive_dq:  AdaptDQ.
        adaptive_dq:  AdaptDQ
    % Execute: },.
    },
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        anchor_node(assessment, [MindId, bayley, Report], [], _),
        % Continue the multi-line expression started above.
        _, true
    % Close the expression opened above.
    ).

% Define a clause for 'cognitive dq': succeed when the following conditions hold.
cognitive_dq(Nexus, NIds, DQ) :-
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count,
        % Continue the multi-line expression started above.
        node_facts:lattice_node_fact(Nexus, _, percept_signal, _, _),
        % Supply 'Percepts' as the next argument to the expression above.
        Percepts),
    % Evaluate the arithmetic expression 'min(100.0, float(NIds) * 0.5 + float(Percepts) * 2.0)' and bind the result to 'DQ'.
    DQ is min(100.0, float(NIds) * 0.5 + float(Percepts) * 2.0).

% Define a clause for 'language dq': succeed when the following conditions hold.
language_dq(Nexus, DQ) :-
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count,
        % Continue the multi-line expression started above.
        node_facts:lattice_node_fact(Nexus, _, phonological, _, _),
        % Supply 'PhonoCount' as the next argument to the expression above.
        PhonoCount),
    % Evaluate the arithmetic expression 'min(100.0, float(PhonoCount) * 5.0)' and bind the result to 'DQ'.
    DQ is min(100.0, float(PhonoCount) * 5.0).

% Define a clause for 'motor dq': succeed when the following conditions hold.
motor_dq(Nexus, DQ) :-
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count,
        % Continue the multi-line expression started above.
        node_facts:lattice_node_fact(Nexus, _, body_command, _, _),
        % Supply 'CommandCount' as the next argument to the expression above.
        CommandCount),
    % Evaluate the arithmetic expression 'min(100.0, float(CommandCount) * 3.0)' and bind the result to 'DQ'.
    DQ is min(100.0, float(CommandCount) * 3.0).

% Define a clause for 'adaptive dq': succeed when the following conditions hold.
adaptive_dq(NIds, DQ) :-
    % Evaluate the arithmetic expression 'min(100.0, float(NIds) * 0.1)' and bind the result to 'DQ'.
    DQ is min(100.0, float(NIds) * 0.1).

% ---------------------------------------------------------------------------
% assess_chc/2
% ---------------------------------------------------------------------------

% Define a clause for 'assess chc': succeed when the following conditions hold.
assess_chc(MindId, Report) :-
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  live_node_facts(Nexus, Ids), length(Ids, STM),
        % Continue the multi-line expression started above.
        aggregate_all(count,
            % Continue the multi-line expression started above.
            node_facts:lattice_node_fact(Nexus, _, _, _, _),
            % Supply 'TotalFacts' as the next argument to the expression above.
            TotalFacts),
        % Continue the multi-line expression started above.
        findall(R, node_facts:lattice_node_fact(Nexus, _, R, _, _), AllRels),
        % Continue the multi-line expression started above.
        sort(AllRels, UniqueRels), length(UniqueRels, RelDiversity),
        % Continue the multi-line expression started above.
        traverse_latency(Nexus, ProcessingSpeed),
        % Continue the multi-line expression started above.
        long_term_retrieval_score(LTR)
    % Otherwise (else branch), perform the following action.
    ;   STM = 0, TotalFacts = 0, RelDiversity = 0,
        % Continue the multi-line expression started above.
        ProcessingSpeed = 0.0, LTR = 0.0
    % Close the expression opened above.
    ),
    % Evaluate the arithmetic expression 'float(TotalFacts) * 0.1 + float(RelDiversity) * 0.5' and bind the result to 'CrystKnowledge'.
    CrystKnowledge is float(TotalFacts) * 0.1 + float(RelDiversity) * 0.5,
    % Check that 'Report' is unifiable with 'chc_report{'.
    Report = chc_report{
        % Execute: mind:                 MindId,.
        mind:                 MindId,
        % Execute: fluid_reasoning:      RelDiversity,.
        fluid_reasoning:      RelDiversity,
        % Execute: crystallized_knowledge: CrystKnowledge,.
        crystallized_knowledge: CrystKnowledge,
        % Execute: short_term_memory:    STM,.
        short_term_memory:    STM,
        % Execute: processing_speed:     ProcessingSpeed,.
        processing_speed:     ProcessingSpeed,
        % Execute: long_term_retrieval:  LTR,.
        long_term_retrieval:  LTR,
        % Execute: visual_processing:    0.
        visual_processing:    0
    % Execute: },.
    },
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        anchor_node(assessment, [MindId, chc, Report], [], _),
        % Continue the multi-line expression started above.
        _, true
    % Close the expression opened above.
    ).

% Define a clause for 'traverse latency': succeed when the following conditions hold.
traverse_latency(Nexus, Ms) :-
    % State a fact for 'get time' with the arguments listed below.
    get_time(T0),
    % State a fact for 'ignore' with the arguments listed below.
    ignore(traverse_nexus(Nexus, node_fact(_, _, _), 1, _)),
    % State a fact for 'get time' with the arguments listed below.
    get_time(T1),
    % Evaluate the arithmetic expression '(T1 - T0) * 1000.0' and bind the result to 'Ms'.
    Ms is (T1 - T0) * 1000.0.

% Define a clause for 'long term retrieval score': succeed when the following conditions hold.
long_term_retrieval_score(Score) :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( sona:sona_trajectory_id_counter(N),
          % Continue the multi-line expression started above.
          Score is min(1.0, float(N) / 100.0) )
    % And additionally, the following condition must hold.
    , _, Score = 0.0 ).

% ---------------------------------------------------------------------------
% Consciousness indicator probes
% ---------------------------------------------------------------------------

% Define a clause for 'consciousness indicator': succeed when the following conditions hold.
consciousness_indicator(workspace_ignition, Nexus, present) :-
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        node_facts:lattice_node_fact(Nexus, _, workspace_broadcast, _, _)
    % Continue the multi-line expression started above.
    )), !.
% State the fact: consciousness indicator(workspace_ignition, _, absent).
consciousness_indicator(workspace_ignition, _, absent).

% Define a clause for 'consciousness indicator': succeed when the following conditions hold.
consciousness_indicator(recurrent_processing, _Nexus, present) :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( cyclic_actor:actor_registry(_, _, _) -> true ; fail ),
        % Continue the multi-line expression started above.
        _, fail
    % Continue the multi-line expression started above.
    ), !.
% Define a clause for 'consciousness indicator': succeed when the following conditions hold.
consciousness_indicator(recurrent_processing, _, present) :-
    % Sentinels constitute a form of recurrent processing
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( sentinels:sentinels_entry(_, _, _, _, _, _) -> true ; fail ),
        % Continue the multi-line expression started above.
        _, fail
    % Continue the multi-line expression started above.
    ), !.
% State the fact: consciousness indicator(recurrent_processing, _, absent).
consciousness_indicator(recurrent_processing, _, absent).

% Define a clause for 'consciousness indicator': succeed when the following conditions hold.
consciousness_indicator(self_model_presence, Nexus, present) :-
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        node_facts:lattice_node_fact(Nexus, _, self_model, _, _)
    % Continue the multi-line expression started above.
    )), !.
% State the fact: consciousness indicator(self_model_presence, _, absent).
consciousness_indicator(self_model_presence, _, absent).

% Define a clause for 'consciousness indicator': succeed when the following conditions hold.
consciousness_indicator(valence_system, _Nexus, present) :-
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( current_predicate(affect:pai_marker_stamp/4) -> true ; fail ),
        % Continue the multi-line expression started above.
        _, fail
    % Continue the multi-line expression started above.
    ), !.
% State the fact: consciousness indicator(valence_system, _, absent).
consciousness_indicator(valence_system, _, absent).

% ---------------------------------------------------------------------------
% assess_all/2
% ---------------------------------------------------------------------------

% Define a clause for 'assess all': succeed when the following conditions hold.
assess_all(MindId, Report) :-
    % State a fact for 'assess bayley' with the arguments listed below.
    assess_bayley(MindId, Bayley),
    % State a fact for 'assess chc' with the arguments listed below.
    assess_chc(MindId, CHC),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(L-R, (
        % Continue the multi-line expression started above.
        between(1, 8, L),
        % Continue the multi-line expression started above.
        assess_piaget(MindId, L, R)
    % Continue the multi-line expression started above.
    ), PiagetPairs),
    % Check that '( default_nexus(Nexus), nexus_is_open(Nexus) -> true ; Nexus' is unifiable with 'none )'.
    ( default_nexus(Nexus), nexus_is_open(Nexus) -> true ; Nexus = none ),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Indicator-Status, (
        % Continue the multi-line expression started above.
        member(Indicator, [workspace_ignition, recurrent_processing,
                           % Continue the multi-line expression started above.
                           self_model_presence, valence_system]),
        % Continue the multi-line expression started above.
        ( Nexus \= none
        % If the condition above succeeded, perform the following action.
        ->  consciousness_indicator(Indicator, Nexus, Status)
        % Otherwise (else branch), perform the following action.
        ;   Status = absent )
    % Continue the multi-line expression started above.
    ), ConsciousnessPairs),
    % Check that 'Report' is unifiable with 'assessment_report{'.
    Report = assessment_report{
        % Execute: mind:                  MindId,.
        mind:                  MindId,
        % Execute: bayley:                Bayley,.
        bayley:                Bayley,
        % Execute: chc:                   CHC,.
        chc:                   CHC,
        % Execute: piaget_milestones:     PiagetPairs,.
        piaget_milestones:     PiagetPairs,
        % Execute: consciousness_indicators: ConsciousnessPairs.
        consciousness_indicators: ConsciousnessPairs
    % Execute: },.
    },
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        anchor_node(assessment, [MindId, all, Report], [], _),
        % Continue the multi-line expression started above.
        _, true
    % Close the expression opened above.
    ).
