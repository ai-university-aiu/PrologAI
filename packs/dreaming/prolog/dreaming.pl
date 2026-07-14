/*  PrologAI — Dreaming Engine  (Specification PR 52)

    Three-phase idle-period dream cycle grounded in neuroscience and
    contemporary AI research:

    Phase 1 — Slow-Wave (Non-Rapid Eye Movement sleep analog):
        Generative Replay and Memory Consolidation.
        Retrieves the most important SONA (Synaptic Ontological Neural
        Aggregator) trajectories and re-absorbs them with stochastic
        perturbation, reinforcing important memories and protecting
        against catastrophic forgetting — the same problem solved by
        Elastic Weight Consolidation (EWC++) in the SONA pack.
        Runs a full attention-economy banker cycle to drive STI
        (Short-Term Importance) to LTI (Long-Term Importance)
        consolidation in the Attention pack.

    Phase 2 — REM (Rapid Eye Movement analog):
        Stochastic World-Model Exploration.
        Queries high-LTI Lattice nodes and generates hypothetical
        new node_fact relations from random pairings, exploring the
        boundary of current knowledge the way DreamerV3's Recurrent
        State-Space Model (RSSM) explores latent world-model space.
        Every hypothetical is tagged `imagined` and is never asserted
        into the observed Lattice without explicit human validation.

    Phase 3 — Hypnagogic / Hypnopompic (transition states):
        Dream Journal.
        Every dream event — slow-wave, REM, or counterfactual — is
        recorded in the dream journal with its phase, content, and a
        monotonic DreamId, giving the mind an inspectable history of
        its idle-time cognition.

    Scientific background (all implemented as symbolic analogs here):
        - Generative Replay (Shin et al., 2017): train a generator on
          past data; replay its samples to prevent forgetting.
        - Sleep Replay Consolidation (Huszar et al., 2022): unsupervised
          replay during sleep reduces catastrophic forgetting up to 38%.
        - DreamerV3 (Hafner et al., 2023): learn a world model and
          improve policy via imagined rollouts inside that model.
        - NeuroDream (Tutuncuoglu, 2025): two-step sleep framework —
          consolidation then self-modifying dreaming — for continual
          learning in neural networks.
        - Language Models Need Sleep (Xie et al., 2026): NREM-style
          pruning and REM-style novel-connection exploration.

    Predicate summary:
        dreaming_cycle/2             — +MindId, -Report
        dreaming_slow_wave/3         — +MindId, +Count, -Consolidated
        dreaming_rem/3               — +MindId, +Depth, -Hypotheticals
        dreaming_generative_replay/3 — +MindId, +Count, -Replayed
        dreaming_counterfactual/4    — +MindId, +NodeId, +Depth, -Alternatives
        dreaming_journal/2           — +MindId, -Journal
        dreaming_record/4            — +MindId, +Phase, +Content, -DreamId

    Guard: hypothetical content is always tagged `imagined` and is
    never asserted into the observed Lattice unless explicitly promoted
    by a separate validation step outside this pack.
*/

% Declare this file as the 'dreaming' module and list its exported predicates.
:- module(dreaming, [
    % Supply 'dreaming_cycle/2' as the next argument to the expression above.
    dreaming_cycle/2,             % +MindId, -Report
    % Supply 'dreaming_slow_wave/3' as the next argument to the expression above.
    dreaming_slow_wave/3,         % +MindId, +Count, -Consolidated
    % Supply 'dreaming_rem/3' as the next argument to the expression above.
    dreaming_rem/3,               % +MindId, +Depth, -Hypotheticals
    % Supply 'dreaming_generative_replay/3' as the next argument to the expression above.
    dreaming_generative_replay/3, % +MindId, +Count, -Replayed
    % Supply 'dreaming_counterfactual/4' as the next argument to the expression above.
    dreaming_counterfactual/4,    % +MindId, +NodeId, +Depth, -Alternatives
    % Supply 'dreaming_journal/2' as the next argument to the expression above.
    dreaming_journal/2,           % +MindId, -Journal
    % Supply 'dreaming_record/4' as the next argument to the expression above.
    dreaming_record/4             % +MindId, +Phase, +Content, -DreamId
% Close the expression opened above.
]).

% Import [member/2, length/2, nth1/3] from the built-in 'lists' library.
:- use_module(library(lists),     [member/2, length/2, nth1/3]).
% Import [maplist/2, maplist/3, foldl/6] from the built-in 'apply' library.
:- use_module(library(apply),     [maplist/2, maplist/3, foldl/6]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate), [aggregate_all/3]).
% Import [numlist/3] from the built-in 'lists' library.
:- use_module(library(lists),     [numlist/3]).

% Soft dependency on sona — load only if the library is available.
:- ignore(catch(use_module(library(sona),
                            [sona_retrieve/3, sona_absorb/1]),
                _,
                true)).

% Soft dependency on attention — load only if the library is available.
:- ignore(catch(use_module(library(attention),
                            [attention_level/3, attention_banker_cycle/0]),
                _,
                true)).

% Soft dependency on lattice — load only if the library is available.
:- ignore(catch(use_module(library(lattice),
                            [lattice_node_fact/5]),
                _,
                true)).

% ---------------------------------------------------------------------------
% Internal state — dream journal storage
% ---------------------------------------------------------------------------

% Declare 'dreaming_entry/4' as dynamic — its facts may be added or removed at runtime.
:- dynamic dreaming_entry/4.
%  dreaming_entry(DreamId, MindId, Phase, Content)
%  Phase in: slow_wave | rem | hypnagogic | hypnopompic | counterfactual

% Declare 'dreaming_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic dreaming_id_counter/1.
% Initialise the dream-id counter to 0.
dreaming_id_counter(0).

% ---------------------------------------------------------------------------
% dreaming_record/4
% Record one event in the dream journal under MindId.
% ---------------------------------------------------------------------------

% Define a clause for 'pai dream record': record a dream event in the journal.
dreaming_record(MindId, Phase, Content, DreamId) :-
    % Retract the current counter value.
    retract(dreaming_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Reassert the incremented counter.
    assertz(dreaming_id_counter(N1)),
    % Build the DreamId term from MindId and the new counter value.
    DreamId = dream(MindId, N1),
    % Persist the dream entry as a dynamic fact for later journal retrieval.
    assertz(dreaming_entry(DreamId, MindId, Phase, Content)).

% ---------------------------------------------------------------------------
% dreaming_journal/2
% Return all dream entries for MindId in chronological order.
% ---------------------------------------------------------------------------

% Define a clause for 'pai dream journal': collect all entries for MindId.
dreaming_journal(MindId, Journal) :-
    % Collect all dream entries for this mind into a list.
    findall(
        % Collect terms of the form 'entry(DreamId, Phase, Content)'.
        entry(DreamId, Phase, Content),
        % Find all dynamic facts matching dreaming_entry for MindId.
        dreaming_entry(DreamId, MindId, Phase, Content),
        % Bind the collected list to 'Journal'.
        Journal
    ).

% ---------------------------------------------------------------------------
% dreaming_generative_replay/3
% Retrieve the top Count SONA trajectories and replay each with a
% stochastic perturbation — adding a replay_noise tag so each
% re-absorption slightly varies the stored trace (generative replay).
% ---------------------------------------------------------------------------

% Define a clause for 'pai dream generative replay': replay SONA trajectories with noise.
dreaming_generative_replay(MindId, Count, Replayed) :-
    % Attempt to retrieve Count trajectories from SONA; fall back to empty list.
    (   catch(sona_retrieve(traj(_), Count, Trajectories), _, fail)
    ->  % Map the perturb-and-absorb operation over every retrieved trajectory.
        maplist(dreaming_perturb_and_absorb(MindId), Trajectories, Replayed)
    ;   % SONA is not loaded or has no entries; return an empty replay list.
        Replayed = []
    ).

% Define a clause for 'dream perturb and absorb': perturb one trajectory and re-absorb it.
dreaming_perturb_and_absorb(MindId, Traj, replayed(MindId, PerturbedTraj)) :-
    % Decompose the trajectory term into its functor and arguments.
    Traj =.. [F | Args],
    % Apply the arg-level perturbation to every argument.
    maplist(dreaming_perturb_arg, Args, PerturbedArgs),
    % Reconstruct the perturbed trajectory term.
    PerturbedTraj =.. [F | PerturbedArgs],
    % Re-absorb the perturbed trajectory into SONA; ignore errors if SONA absent.
    catch(sona_absorb(PerturbedTraj), _, true).

% Define a clause for 'dream perturb arg': prepend a replay-noise marker to event lists.
dreaming_perturb_arg(events(Evs), events([replay_noise(dreaming) | Evs])) :- !.
% Define a fallthrough clause for 'dream perturb arg': pass all other args through unchanged.
dreaming_perturb_arg(Arg, Arg).

% ---------------------------------------------------------------------------
% dreaming_slow_wave/3
% Slow-wave (NREM analog) phase: generative replay + banker cycle.
% 1. Replay the top Count SONA entries with perturbation.
% 2. Run one attention-economy banker cycle (STI rent, LTI consolidation).
% 3. Record the phase result in the dream journal.
% ---------------------------------------------------------------------------

% Define a clause for 'pai dream slow wave': NREM-analog consolidation phase.
dreaming_slow_wave(MindId, Count, Consolidated) :-
    % Run generative replay on the top Count SONA trajectories.
    dreaming_generative_replay(MindId, Count, Replayed),
    % Run one full attention-economy banker cycle; ignore errors if pack absent.
    catch(attention_banker_cycle, _, true),
    % Compute how many trajectories were replayed.
    length(Replayed, N),
    % Build the slow-wave content descriptor.
    Content = slow_wave(replayed(N), banker_cycle(done)),
    % Record this slow-wave event in the dream journal.
    dreaming_record(MindId, slow_wave, Content, DreamId),
    % Bind the Consolidated output term.
    Consolidated = consolidated(DreamId, Replayed).

% ---------------------------------------------------------------------------
% dreaming_rem/3
% REM (Rapid Eye Movement analog) phase: stochastic world-model exploration.
% Queries all high-LTI Lattice nodes, pairs them randomly up to Depth
% attempts, and generates hypothetical `imagined` relations between them.
% Nothing is ever asserted into the observed Lattice from this phase.
% ---------------------------------------------------------------------------

% Define a clause for 'pai dream rem': REM-analog world-model exploration phase.
dreaming_rem(MindId, Depth, Hypotheticals) :-
    % Gather all nodes with a positive LTI value from the attention pack.
    dreaming_high_lti_nodes(Nodes),
    % Generate hypothetical pairings from those nodes up to Depth attempts.
    dreaming_generate_hypotheticals(Nodes, Depth, Hyps),
    % Record this REM event in the dream journal.
    dreaming_record(MindId, rem, hypotheticals(Hyps), DreamId),
    % Bind the Hypotheticals output term.
    Hypotheticals = rem(DreamId, Hyps).

% Define a clause for 'dream high lti nodes': collect node IDs with LTI > 0.
dreaming_high_lti_nodes(Nodes) :-
    % Attempt to query the attention pack; fall back to empty list on error.
    (   catch(
            findall(
                % Collect NodeId values.
                NodeId,
                % Find all nodes where LTI value is positive.
                (   attention:attention_level(NodeId, lti, V),
                    V > 0
                ),
                Nodes0
            ),
            _,
            Nodes0 = []
        )
    ->  % Bind Nodes to the collected list.
        Nodes = Nodes0
    ;   % Fall back to empty list.
        Nodes = []
    ).

% Define the first clause for 'dream generate hypotheticals': need at least 2 nodes.
dreaming_generate_hypotheticals(Nodes, Depth, Hyps) :-
    % Confirm there are at least 2 nodes to pair.
    length(Nodes, Len),
    % Check that Len >= 2 before attempting pairings.
    Len >= 2,
    !,
    % Compute the maximum attempts as the minimum of Depth and Len squared.
    MaxAttempts is min(Depth, Len * Len),
    % Build a list of attempt indices from 1 to MaxAttempts.
    numlist(1, MaxAttempts, Indices),
    % Fold over the indices, accumulating hypothetical pairings.
    foldl(dreaming_one_hypothetical(Nodes, Len), Indices, [], Hyps).
% Define the second clause for 'dream generate hypotheticals': fewer than 2 nodes yields empty.
dreaming_generate_hypotheticals(_, _, []).

% Define the first clause for 'dream one hypothetical': attempt to form a pairing.
dreaming_one_hypothetical(Nodes, Len, _I, Acc, Acc1) :-
    % Draw a random index for the first node (0-based, then +1 for 1-based).
    I1 is random(Len) + 1,
    % Draw a random index for the second node.
    I2 is random(Len) + 1,
    % Ensure the two indices are different so we do not pair a node with itself.
    I1 \= I2,
    % Retrieve the first node by index.
    nth1(I1, Nodes, N1),
    % Retrieve the second node by index.
    nth1(I2, Nodes, N2),
    % Build the hypothetical pairing term, tagged imagined.
    Hyp = imagined(relates(N1, N2)),
    % Skip if this pairing is already in the accumulator.
    \+ member(Hyp, Acc),
    !,
    % Prepend the new hypothetical to the accumulator.
    Acc1 = [Hyp | Acc].
% Define the second clause for 'dream one hypothetical': failed attempt leaves accumulator unchanged.
dreaming_one_hypothetical(_, _, _, Acc, Acc).

% ---------------------------------------------------------------------------
% dreaming_counterfactual/4
% For a known Lattice node, hypothesize alternative relation names and
% record what those alternatives would imply — tagged `imagined`, never
% asserted into the observed Lattice.
% ---------------------------------------------------------------------------

% Define a clause for 'pai dream counterfactual': branch from a known Lattice node.
dreaming_counterfactual(MindId, NodeId, Depth, Alternatives) :-
    % Attempt to find existing Lattice facts for NodeId.
    (   catch(
            findall(
                % Collect node descriptors.
                node(NodeId, Rel, Args),
                % Query all Lattice node_facts with this NodeId.
                lattice:lattice_node_fact(_, NodeId, Rel, Args, _),
                Facts
            ),
            _,
            % Fall back to empty list if lattice pack is absent.
            Facts = []
        )
    ->  true
    ;   Facts = []
    ),
    % Branch on whether any facts were found for this node.
    (   Facts = [node(_, KnownRel, KnownArgs) | _]
    ->  % Generate counterfactual branches from the known relation.
        dreaming_counterfactual_branches(MindId, NodeId, KnownRel, KnownArgs, Depth, Alternatives)
    ;   % No known facts — report that outcome.
        Alternatives = counterfactual(NodeId, no_known_facts)
    ).

% Define a clause for 'dream counterfactual branches': generate Depth alternative relations.
dreaming_counterfactual_branches(MindId, NodeId, KnownRel, KnownArgs, Depth, counterfactual(NodeId, Branches)) :-
    % Build a list of Depth alternative relation atoms.
    dreaming_alt_relations(KnownRel, Depth, AltRels),
    % Map one-counterfactual recording over every alternative relation.
    maplist(dreaming_one_counterfactual(MindId, NodeId, KnownArgs), AltRels, Branches).

% Define a clause for 'dream alt relations': build Depth alternative relation names.
dreaming_alt_relations(BaseRel, Depth, AltRels) :-
    % Build a 1-to-Depth index list.
    numlist(1, Depth, Indices),
    % Map the naming function over the index list.
    maplist(dreaming_alt_rel(BaseRel), Indices, AltRels).

% Define a clause for 'dream alt rel': build one alternative relation name by appending _cf_N.
dreaming_alt_rel(BaseRel, N, AltRel) :-
    % Concatenate the base relation name, the suffix '_cf_', and the index number.
    atomic_list_concat([BaseRel, '_cf_', N], AltRel).

% Define a clause for 'dream one counterfactual': record one counterfactual branch.
dreaming_one_counterfactual(MindId, NodeId, Args, AltRel,
                          branch(DreamId, imagined(node(NodeId, AltRel, Args)))) :-
    % Build the content descriptor for this counterfactual branch.
    Content = counterfactual_branch(node(NodeId, AltRel, Args), tagged(imagined)),
    % Record the branch in the dream journal under the counterfactual phase.
    dreaming_record(MindId, counterfactual, Content, DreamId).

% ---------------------------------------------------------------------------
% dreaming_cycle/2
% Full idle-period dream cycle: hypnagogic → slow-wave → REM → hypnopompic.
% Default replay count: 10 SONA trajectories.
% Default REM depth: 20 hypothetical pairings.
% ---------------------------------------------------------------------------

% Define a clause for 'pai dream cycle': orchestrate all four dream phases.
dreaming_cycle(MindId, Report) :-
    % Record the hypnagogic (entering sleep) transition in the journal.
    dreaming_record(MindId, hypnagogic, entering_sleep, HypnagogicId),
    % Run the slow-wave (NREM) phase — replay and consolidate 10 SONA entries.
    dreaming_slow_wave(MindId, 10, Consolidated),
    % Run the REM phase — generate up to 20 hypothetical node pairings.
    dreaming_rem(MindId, 20, Hypotheticals),
    % Record the hypnopompic (exiting sleep) transition in the journal.
    dreaming_record(MindId, hypnopompic, exiting_sleep, HypnopompicId),
    % Assemble the complete dream report.
    Report = dream_report(
        % Identify the mind that dreamed.
        mind(MindId),
        % Record the hypnagogic journal entry ID.
        hypnagogic(HypnagogicId),
        % Include the slow-wave consolidation result.
        slow_wave(Consolidated),
        % Include the REM hypotheticals result.
        rem(Hypotheticals),
        % Record the hypnopompic journal entry ID.
        hypnopompic(HypnopompicId)
    ).
