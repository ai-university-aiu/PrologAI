% Test suite for the managed_seam pack — a first-class managed cross-stratal seam.
% These tests confirm the honest-ignorance distinction (absent vs unmodeled vs modeled),
% the chain-status coupling, the Algorithm F well-formedness (non-adjacent endpoints, a
% valid intervening chain), the checkable home rule (the coarsest endpoint), and the
% queryable runtime event that makes a skip visible to the runtime. The stratum model
% mirrors the connectome's neuroendocrine strata.
% Load the managed_seam module under test.
:- use_module(library(managed_seam)).
% Load the Lattice store the seam events live in.
:- use_module(library(lattice)).
% Load the PLUnit testing framework.
:- use_module(library(plunit)).

% A stratum model: each occurrent's stratum (the OccMap causal_core consumes).
test_managed_seam_occmap(occ{
    cortisol_src: _{stratum: community},
    cortisol_tgt: _{stratum: macromolecular},
    consol_src:   _{stratum: macromolecular},
    consol_tgt:   _{stratum: region},
    cell_step:    _{stratum: cellular},
    syn_step:     _{stratum: synaptic},
    syn_occ:      _{stratum: synaptic},
    cell_occ:     _{stratum: cellular}
}).

% The stratum model: each stratum's scheme and ordinal (the StratumMap causal_core consumes).
test_managed_seam_stratummap(strat{
    macromolecular: _{scheme: neuroendocrine, ordinal: 4},
    cellular:       _{scheme: neuroendocrine, ordinal: 6},
    synaptic:       _{scheme: neuroendocrine, ordinal: 7},
    region:         _{scheme: neuroendocrine, ordinal: 9},
    community:      _{scheme: neuroendocrine, ordinal: 14}
}).

% Open the test block for the managed_seam pack.
:- begin_tests(managed_seam).

% The three mechanism statuses each carry a distinct glass-box meaning.
test(three_statuses_have_meanings) :-
    findall(S, managed_seam_status(S), Statuses),
    assertion(Statuses == [absent, unmodeled, modeled]),
    forall(member(S, Statuses),
           ( managed_seam_status_meaning(S, M), assertion(atom(M)) )).

% An unmodeled seam is honest ignorance; an absent seam is not — the distinction a boolean could not draw.
test(honest_ignorance_is_distinct_from_absent) :-
    managed_seam_new(cortisol_src, cortisol_tgt, unmodeled, [], Unmodeled),
    managed_seam_new(cortisol_src, cortisol_tgt, absent, [], Absent),
    assertion(managed_seam_is_honest_ignorance(Unmodeled)),
    assertion(\+ managed_seam_is_honest_ignorance(Absent)),
    managed_seam_mechanism_status(Unmodeled, unmodeled),
    managed_seam_mechanism_status(Absent, absent).

% A modeled seam REQUIRES a non-empty drawn chain; an absent/unmodeled seam draws none.
test(chain_is_coupled_to_status) :-
    % A modeled seam carries the drawn chain.
    managed_seam_new(consol_src, consol_tgt, modeled, [cell_step, syn_step], Modeled),
    get_dict(chain, Modeled, [cell_step, syn_step]),
    % An unmodeled seam has no chain key at all.
    managed_seam_new(cortisol_src, cortisol_tgt, unmodeled, [], Unmodeled),
    assertion(\+ get_dict(chain, Unmodeled, _)).

% Constructing an absent seam WITH a chain is refused — the contradiction is unrepresentable.
test(absent_with_chain_is_refused, throws(error(domain_error(empty_chain, _), _))) :-
    managed_seam_new(consol_src, consol_tgt, absent, [cell_step], _).

% Constructing a modeled seam WITHOUT a chain is refused — a drawn mechanism needs its steps.
test(modeled_without_chain_is_refused, throws(error(domain_error(non_empty_chain, _), _))) :-
    managed_seam_new(consol_src, consol_tgt, modeled, [], _).

% An unknown status is refused at construction.
test(unknown_status_is_refused, throws(error(domain_error(managed_seam_status, _), _))) :-
    managed_seam_new(cortisol_src, cortisol_tgt, maybe, [], _).

% A seam across NON-adjacent strata is well-formed (community 14 to macromolecular 4).
test(non_adjacent_seam_is_wellformed) :-
    test_managed_seam_occmap(OccMap), test_managed_seam_stratummap(StratumMap),
    managed_seam_new(cortisol_src, cortisol_tgt, unmodeled, [], Seam),
    managed_seam_wellformed(Seam, OccMap, StratumMap, Result),
    assertion(Result = ok(_)).

% A seam across ADJACENT strata is rejected — a seam is for NON-adjacent strata (Algorithm F, c).
test(adjacent_seam_is_rejected) :-
    test_managed_seam_occmap(OccMap), test_managed_seam_stratummap(StratumMap),
    managed_seam_new(syn_occ, cell_occ, unmodeled, [], Seam),
    managed_seam_wellformed(Seam, OccMap, StratumMap, Result),
    assertion(Result = invalid(_)).

% A modeled seam with a valid intervening, strictly-monotone chain is well-formed.
test(modeled_seam_with_valid_chain_is_wellformed) :-
    test_managed_seam_occmap(OccMap), test_managed_seam_stratummap(StratumMap),
    % macromolecular(4) to region(9), chain cellular(6) then synaptic(7): intervening and monotone.
    managed_seam_new(consol_src, consol_tgt, modeled, [cell_step, syn_step], Seam),
    managed_seam_wellformed(Seam, OccMap, StratumMap, Result),
    assertion(Result = ok(_)).

% The HOME of a seam is the coarsest (max-ordinal) endpoint stratum.
test(home_is_the_coarsest_endpoint) :-
    test_managed_seam_occmap(OccMap), test_managed_seam_stratummap(StratumMap),
    managed_seam_new(cortisol_src, cortisol_tgt, unmodeled, [], Seam),
    managed_seam_home(Seam, OccMap, StratumMap, Home),
    % community (ordinal 14) is coarser than macromolecular (ordinal 4).
    assertion(Home == community).

% The checkable home rule accepts the true home and rejects a wrong one.
test(home_check_accepts_true_rejects_wrong) :-
    test_managed_seam_occmap(OccMap), test_managed_seam_stratummap(StratumMap),
    managed_seam_new(cortisol_src, cortisol_tgt, unmodeled, [], Seam),
    managed_seam_home_check(Seam, OccMap, StratumMap, community, Ok),
    assertion(Ok = ok(community)),
    managed_seam_home_check(Seam, OccMap, StratumMap, macromolecular, Bad),
    assertion(Bad = invalid(wrong_home(_, _))).

% An emitted seam becomes a queryable runtime event, and events are distinguishable by status.
test(emitted_seams_are_queryable_by_status) :-
    lattice_open('locus://managed_seam_events', Nexus),
    managed_seam_new(cortisol_src, cortisol_tgt, unmodeled, [], Unmodeled),
    managed_seam_new(cortisol_src, cortisol_tgt, absent, [], Absent),
    managed_seam_emit(Nexus, Unmodeled),
    managed_seam_emit(Nexus, Absent),
    % Both skips are now visible to the runtime as queryable events.
    managed_seam_events(Nexus, All), assertion(length(All, 2)),
    % An unmodeled skip is queryable AS DISTINCT from an absent one.
    managed_seam_events_by_status(Nexus, unmodeled, U), assertion(length(U, 1)),
    managed_seam_events_by_status(Nexus, absent, A), assertion(length(A, 1)),
    [OnlyU] = U, assertion(managed_seam_is_honest_ignorance(OnlyU)).

% Close the test block.
:- end_tests(managed_seam).
