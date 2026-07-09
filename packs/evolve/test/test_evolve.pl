/*  PrologAI — Evolutionary Computation Pack Test Suite  (WP-387)

    Acceptance tests for all ev_* predicates. The OneMax problem —
    evolve a genome of all ones — provides the end-to-end check, and
    the explicit seed makes every expectation exact and reproducible.

    Run with:
        swipl -g "run_tests, halt" test_evolve.pl
*/

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module('../prolog/evolve').

% ===========================================================================
% TEST FIXTURE FITNESS
% ===========================================================================

% The OneMax fitness: the score of a binary genome is its sum.
onemax(G, S) :-
    % Count the ones by summing the genes.
    sum_list(G, S).

% The standard parameter set used across the end-to-end tests.
std_params(params([0, 1], 3, 0.05, 2)).

% ===========================================================================
% DETERMINISTIC RANDOMNESS
% ===========================================================================

:- begin_tests(evolve_random).

% The generator is deterministic: one seed, one successor.
test(lcg_deterministic) :-
    % Advance the seed twice from the same start.
    ev_next(42, A),
    % Repeat the same step.
    ev_next(42, B),
    % Both steps agree.
    A =:= B.

% Random floats stay inside the unit interval.
test(float_in_unit_interval) :-
    % Draw one float.
    ev_rand_float(7, F, _),
    % Lower bound check.
    F >= 0.0,
    % Upper bound check.
    F < 1.0.

% Random integers stay inside the requested range.
test(int_in_range) :-
    % Draw one integer below five.
    ev_rand_int(7, 5, I, _),
    % Lower bound check.
    I >= 0,
    % Upper bound check.
    I < 5.

% A random genome has the right length and alphabet.
test(random_genome_shape) :-
    % Draw a genome of eight binary genes.
    ev_random_genome([0, 1], 8, 42, G, _),
    % Length check.
    length(G, 8),
    % Every gene comes from the alphabet.
    forall(member(Gene, G), memberchk(Gene, [0, 1])).

% The same seed always draws the same genome.
test(genome_reproducible) :-
    % Draw a genome once.
    ev_random_genome([a, b, c], 6, 99, G1, _),
    % Draw again from the same seed.
    ev_random_genome([a, b, c], 6, 99, G2, _),
    % The draws are identical.
    G1 == G2.

% A population has the right size and member lengths.
test(population_shape) :-
    % Draw a population of five four-gene genomes.
    ev_population([0, 1], 4, 5, 11, Pop, _),
    % Size check.
    length(Pop, 5),
    % Every genome has four genes.
    forall(member(G, Pop), length(G, 4)).

:- end_tests(evolve_random).

% ===========================================================================
% FITNESS, SELECTION, AND OPERATORS
% ===========================================================================

:- begin_tests(evolve_operators).

% Evaluation pairs every genome with its score.
test(evaluate) :-
    % Score two known genomes.
    ev_evaluate(onemax, [[1, 1, 0], [0, 0, 0]], Scored),
    % The scores follow the fitness definition.
    Scored == [[1, 1, 0]-2, [0, 0, 0]-0].

% The best genome carries the highest score.
test(best) :-
    % Rank a small scored population.
    ev_best([[0]-0, [1]-1, [0]-0], G, S),
    % The champion is the genome of ones.
    G == [1],
    % Its score is the maximum.
    S =:= 1.

% The mean fitness averages the scores.
test(mean_fitness) :-
    % Average two scores.
    ev_mean_fitness([[1, 1]-2, [0, 0]-0], Mean),
    % Check the average.
    abs(Mean - 1.0) < 1.0e-9.

% Tournament selection returns a member of the population.
test(tournament_member) :-
    % A three-genome scored population.
    Scored = [[0, 0]-0, [1, 0]-1, [1, 1]-2],
    % Run one tournament of three picks.
    ev_tournament(Scored, 3, 5, Winner, _),
    % The winner is one of the candidate genomes.
    memberchk(Winner-_, Scored).

% One-point crossover splices a head of one parent onto a tail of the other.
test(crossover_structure) :-
    % Two maximally distinct parents.
    ev_crossover([a, a, a, a], [b, b, b, b], 3, Child, _),
    % The child preserves the parents' length.
    length(Child, 4),
    % The child is a run of a-genes followed by a run of b-genes.
    append(Head, Tail, Child),
    % The head comes entirely from the first parent.
    forall(member(X, Head), X == a),
    % The tail comes entirely from the second parent.
    forall(member(Y, Tail), Y == b),
    % The cut is strictly inside, so both parents contribute.
    Head \== [],
    % The tail is also non-empty.
    Tail \== [],
    % Commit to the first split.
    !.

% A zero mutation rate leaves the genome untouched.
test(mutate_rate_zero) :-
    % Mutate at rate zero.
    ev_mutate([1, 0, 1], [0, 1], 0.0, 9, M, _),
    % Nothing changed.
    M == [1, 0, 1].

% A rate of one with a one-letter alphabet rewrites every gene.
test(mutate_rate_one) :-
    % Mutate at rate one with only x available.
    ev_mutate([y, y, y], [x], 1.0, 9, M, _),
    % Every gene became x.
    M == [x, x, x].

% Elites are the top genomes in rank order.
test(elite_top_two) :-
    % Rank a three-genome scored population.
    ev_elite([[0]-0, [1, 1]-2, [1]-1], 2, Elites),
    % The two best genomes survive, best first.
    Elites == [[1, 1], [1]].

% Asking for more elites than exist returns the whole ranking.
test(elite_overask) :-
    % Ask for five elites from a two-genome population.
    ev_elite([[0]-0, [1]-1], 5, Elites),
    % Both genomes are returned.
    length(Elites, 2).

:- end_tests(evolve_operators).

% ===========================================================================
% GENERATIONS AND FULL RUNS
% ===========================================================================

:- begin_tests(evolve_runs).

% The next generation preserves the population size and its elites.
test(next_generation_shape) :-
    % Score a founding population.
    ev_population([0, 1], 6, 10, 21, Pop, Seed1),
    % Evaluate the founders.
    ev_evaluate(onemax, Pop, Scored),
    % Breed the next generation.
    std_params(Params),
    % One generational step.
    ev_next_generation(onemax, Scored, Params, Seed1, Pop2, _),
    % The size is preserved.
    length(Pop2, 10),
    % The champion survives unchanged among the elites.
    ev_best(Scored, Champion, _),
    % Elitism carried it over.
    memberchk(Champion, Pop2).

% Thirty generations solve OneMax perfectly from a founding best of six.
test(run_solves_onemax) :-
    % Fetch the standard parameters.
    std_params(Params),
    % The founding champion scores six of twelve.
    ev_run(onemax, Params, 24, 12, 0, 42, _, S0),
    % Verify the founding score.
    S0 =:= 6,
    % Thirty generations of evolution.
    ev_run(onemax, Params, 24, 12, 30, 42, Best, S),
    % The perfect genome was found.
    S =:= 12,
    % It is literally all ones.
    Best == [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1].

% Evolution is reproducible: the same seed yields the same champion.
test(run_deterministic) :-
    % Fetch the standard parameters.
    std_params(Params),
    % First run.
    ev_run(onemax, Params, 24, 12, 30, 42, B1, S1),
    % Second identical run.
    ev_run(onemax, Params, 24, 12, 30, 42, B2, S2),
    % The champions agree.
    B1 == B2,
    % The scores agree.
    S1 =:= S2.

% The early-stopping run reaches the target in seven generations.
test(run_until_early_stop) :-
    % Fetch the standard parameters.
    std_params(Params),
    % Evolve until the perfect score, budget sixty.
    ev_run_until(onemax, Params, 24, 12, 60, 12, 42, _, S, Gens),
    % The target was reached.
    S =:= 12,
    % It took exactly seven generations under this seed.
    Gens =:= 7.

% Diversity is the fraction of distinct genomes.
test(diversity) :-
    % Two distinct genomes among three.
    ev_diversity([[a], [a], [b]], D),
    % Check the fraction.
    abs(D - 0.6666666666666666) < 1.0e-9.

% Convergence holds when diversity falls to the threshold.
test(converged) :-
    % A fully collapsed scored population.
    ev_converged([[a]-1, [a]-1, [a]-1, [a]-1], 0.25).

% A diverse population has not converged.
test(not_converged, [fail]) :-
    % Four distinct genomes.
    ev_converged([[a]-1, [b]-1, [c]-1, [d]-1], 0.25).

:- end_tests(evolve_runs).
