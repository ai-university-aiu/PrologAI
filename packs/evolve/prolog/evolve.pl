/*  PrologAI — Evolutionary Computation  (WP-387, Layer 362)

    Population-based search inspired by biological evolution: candidate
    genomes compete on a fitness measure, the best are selected, and
    variations of them — built by crossover and mutation — form the next
    generation. Evolution is the one process known to have produced
    general intelligence, and this pack gives PrologAI that search
    strategy as a glass-box, fully deterministic tool.

    A genome is a list of genes drawn from an alphabet. Fitness is any
    caller-supplied goal called as call(Goal, Genome, Score) where a
    larger Score is better. All randomness flows through an explicit
    linear congruential generator seed, so every run is reproducible:
    the same seed always yields the same evolution.

    Parameters are packed as params(Alphabet, TournamentK, MutationRate,
    EliteCount).

    Exported predicates:

    evolve_next/2            +Seed, -Seed2
    evolve_rand_float/3      +Seed, -F, -Seed2
    evolve_rand_int/4        +Seed, +N, -I, -Seed2
    evolve_random_genome/5   +Alphabet, +Length, +Seed, -Genome, -Seed2
    evolve_population/6      +Alphabet, +Length, +Size, +Seed, -Pop, -Seed2
    evolve_evaluate/3        :Goal, +Pop, -Scored
    evolve_best/3            +Scored, -Genome, -Score
    evolve_mean_fitness/2    +Scored, -Mean
    evolve_tournament/5      +Scored, +K, +Seed, -Winner, -Seed2
    evolve_crossover/5       +G1, +G2, +Seed, -Child, -Seed2
    evolve_mutate/6          +Genome, +Alphabet, +Rate, +Seed, -Mutant, -Seed2
    evolve_elite/3           +Scored, +N, -Elites
    evolve_next_generation/6 :Goal, +Scored, +Params, +Seed, -Pop2, -Seed2
    evolve_run/8             :Goal, +Params, +Size, +Length, +Gens, +Seed, -Best, -Score
    evolve_run_until/10      :Goal, +Params, +Size, +Length, +MaxGens, +Target, +Seed, -Best, -Score, -Gens
    evolve_diversity/2       +Pop, -Diversity
    evolve_converged/2       +Scored, +Threshold
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(evolve, [
    % evolve_next/2: advance the deterministic random seed.
    evolve_next/2,
    % evolve_rand_float/3: uniform float in [0, 1).
    evolve_rand_float/3,
    % evolve_rand_int/4: uniform integer in [0, N).
    evolve_rand_int/4,
    % evolve_random_genome/5: one random genome over an alphabet.
    evolve_random_genome/5,
    % evolve_population/6: a whole random population.
    evolve_population/6,
    % evolve_evaluate/3: score every genome with the fitness goal.
    evolve_evaluate/3,
    % evolve_best/3: the highest-scoring genome.
    evolve_best/3,
    % evolve_mean_fitness/2: mean score of a scored population.
    evolve_mean_fitness/2,
    % evolve_tournament/5: tournament selection of one parent.
    evolve_tournament/5,
    % evolve_crossover/5: one-point crossover of two parents.
    evolve_crossover/5,
    % evolve_mutate/6: per-gene mutation at a given rate.
    evolve_mutate/6,
    % evolve_elite/3: the top genomes, preserved unchanged.
    evolve_elite/3,
    % evolve_next_generation/6: elites plus offspring form the next population.
    evolve_next_generation/6,
    % evolve_run/8: full evolutionary loop for a fixed generation count.
    evolve_run/8,
    % evolve_run_until/10: evolutionary loop with a target-score early stop.
    evolve_run_until/10,
    % evolve_diversity/2: fraction of distinct genomes.
    evolve_diversity/2,
    % evolve_converged/2: the population has collapsed below a diversity bar.
    evolve_converged/2
]).

% Use the lists library for member/2, nth0/3, and friends.
:- use_module(library(lists)).

% Fitness goals are caller-module closures taking a genome and a score.
:- meta_predicate evolve_evaluate(2, +, -).
% The next-generation builder re-evaluates offspring with the same goal.
:- meta_predicate evolve_next_generation(2, +, +, +, -, -).
% The fixed-length run drives the whole loop with the fitness goal.
:- meta_predicate evolve_run(2, +, +, +, +, +, -, -).
% The early-stopping run drives the whole loop with the fitness goal.
:- meta_predicate evolve_run_until(2, +, +, +, +, +, +, -, -, -).

% ===========================================================================
% DETERMINISTIC RANDOMNESS
% ===========================================================================

% evolve_next(+Seed, -Seed2): one step of the linear congruential generator.
evolve_next(Seed, Seed2) :-
    % The classic glibc multiplier and increment, modulo two to the 31.
    Seed2 is (Seed * 1103515245 + 12345) mod 2147483648.

% evolve_rand_float(+Seed, -F, -Seed2): uniform float in [0, 1).
evolve_rand_float(Seed, F, Seed2) :-
    % Advance the generator.
    evolve_next(Seed, Seed2),
    % Scale the new seed into the unit interval.
    F is Seed2 / 2147483648.0.

% evolve_rand_int(+Seed, +N, -I, -Seed2): uniform integer in [0, N).
evolve_rand_int(Seed, N, I, Seed2) :-
    % The range must be positive.
    N > 0,
    % Advance the generator.
    evolve_next(Seed, Seed2),
    % Reduce the new seed into the range.
    I is Seed2 mod N.

% evolve_rand_nth(+List, +Seed, -Item, -Seed2): pick one element uniformly.
evolve_rand_nth(List, Seed, Item, Seed2) :-
    % Size of the list.
    length(List, N),
    % Draw an index.
    evolve_rand_int(Seed, N, I, Seed2),
    % Fetch the element at the drawn index.
    nth0(I, List, Item).

% ===========================================================================
% GENOMES AND POPULATIONS
% ===========================================================================

% evolve_random_genome(+Alphabet, +Length, +Seed, -Genome, -Seed2): one genome.
evolve_random_genome(_, 0, Seed, [], Seed) :-
    % An empty genome consumes no randomness beyond none.
    !.
% Draw one gene, then the rest.
evolve_random_genome(Alphabet, Length, Seed, [Gene | Genes], Seed2) :-
    % Length is positive here.
    Length > 0,
    % Draw the first gene from the alphabet.
    evolve_rand_nth(Alphabet, Seed, Gene, Seed1),
    % One fewer gene remains.
    Length1 is Length - 1,
    % Draw the remaining genes.
    evolve_random_genome(Alphabet, Length1, Seed1, Genes, Seed2).

% evolve_population(+Alphabet, +Length, +Size, +Seed, -Pop, -Seed2): Size genomes.
evolve_population(_, _, 0, Seed, [], Seed) :-
    % An empty population consumes no randomness.
    !.
% Draw one genome, then the rest.
evolve_population(Alphabet, Length, Size, Seed, [G | Gs], Seed2) :-
    % Size is positive here.
    Size > 0,
    % Draw the first genome.
    evolve_random_genome(Alphabet, Length, Seed, G, Seed1),
    % One fewer genome remains.
    Size1 is Size - 1,
    % Draw the remaining genomes.
    evolve_population(Alphabet, Length, Size1, Seed1, Gs, Seed2).

% evolve_evaluate(:Goal, +Pop, -Scored): score every genome.
evolve_evaluate(Goal, Pop, Scored) :-
    % Pair each genome with its fitness score.
    findall(G-S,
        % Take each genome in turn.
        ( member(G, Pop),
          % Ask the caller's fitness goal for the score.
          call(Goal, G, S) ),
        Scored).

% evolve_sorted(+Scored, -Sorted): sort by score, best first, keeping ties.
evolve_sorted(Scored, Sorted) :-
    % Sort on the value slot of the pairs, descending, without merging.
    sort(2, @>=, Scored, Sorted).

% evolve_best(+Scored, -Genome, -Score): the highest-scoring genome.
evolve_best(Scored, Genome, Score) :-
    % Sort best-first.
    evolve_sorted(Scored, Sorted),
    % Take the front pair.
    Sorted = [Genome-Score | _].

% evolve_mean_fitness(+Scored, -Mean): mean score of the population.
evolve_mean_fitness(Scored, Mean) :-
    % Extract the scores.
    pairs_values(Scored, Ss),
    % Total the scores.
    sum_list(Ss, Sum),
    % Count the population.
    length(Ss, N),
    % A population must be non-empty.
    N > 0,
    % Average the scores.
    Mean is Sum / N.

% ===========================================================================
% GENETIC OPERATORS
% ===========================================================================

% evolve_tournament(+Scored, +K, +Seed, -Winner, -Seed2): best of K random picks.
evolve_tournament(Scored, K, Seed, Winner, Seed2) :-
    % Draw K contestants with replacement.
    evolve_contestants(Scored, K, Seed, Contestants, Seed2),
    % The best contestant wins the tournament.
    evolve_best(Contestants, Winner, _).

% evolve_contestants(+Scored, +K, +Seed, -Picked, -Seed2): K random entries.
evolve_contestants(_, 0, Seed, [], Seed) :-
    % No contestants remain to draw.
    !.
% Draw one contestant, then the rest.
evolve_contestants(Scored, K, Seed, [C | Cs], Seed2) :-
    % K is positive here.
    K > 0,
    % Draw one scored entry uniformly.
    evolve_rand_nth(Scored, Seed, C, Seed1),
    % One fewer contestant remains.
    K1 is K - 1,
    % Draw the remaining contestants.
    evolve_contestants(Scored, K1, Seed1, Cs, Seed2).

% evolve_crossover(+G1, +G2, +Seed, -Child, -Seed2): one-point crossover.
evolve_crossover(G1, G2, Seed, Child, Seed2) :-
    % Length of the parents.
    length(G1, N),
    % Genomes shorter than two genes cannot be cut.
    (   N < 2
    % Too short: the child is a copy of the first parent.
    ->  Child = G1,
        % No randomness is consumed.
        Seed2 = Seed
    % Otherwise choose a cut point strictly inside the genome.
    ;   Cut is N - 1,
        % Draw the cut offset in [0, N-2].
        evolve_rand_int(Seed, Cut, I0, Seed2),
        % Shift to a cut position in [1, N-1].
        I is I0 + 1,
        % Take the head of the first parent.
        length(Head, I),
        % Split the first parent at the cut.
        append(Head, _, G1),
        % Split the second parent at the same cut.
        length(Skip, I),
        % Keep the tail of the second parent.
        append(Skip, Tail, G2),
        % Join head and tail into the child.
        append(Head, Tail, Child)
    ).

% evolve_mutate(+Genome, +Alphabet, +Rate, +Seed, -Mutant, -Seed2): point mutation.
evolve_mutate([], _, _, Seed, [], Seed).
% Decide the first gene, then the rest.
evolve_mutate([G | Gs], Alphabet, Rate, Seed, [M | Ms], Seed2) :-
    % Draw the mutation coin for this gene.
    evolve_rand_float(Seed, F, Seed1),
    % Mutate when the coin lands under the rate.
    (   F < Rate
    % Mutation: replace the gene with a random alphabet pick.
    ->  evolve_rand_nth(Alphabet, Seed1, M, SeedNext)
    % No mutation: the gene survives unchanged.
    ;   M = G,
        % The seed advances only by the coin toss.
        SeedNext = Seed1
    ),
    % Continue with the remaining genes.
    evolve_mutate(Gs, Alphabet, Rate, SeedNext, Ms, Seed2).

% evolve_elite(+Scored, +N, -Elites): the top N genomes, best first.
evolve_elite(Scored, N, Elites) :-
    % Sort best-first.
    evolve_sorted(Scored, Sorted),
    % Extract the genomes in rank order.
    pairs_keys(Sorted, Ranked),
    % Keep at most N of them.
    length(Ranked, Have),
    % Never take more than the population holds.
    Take is min(N, Have),
    % Slice the front of the ranking.
    length(Elites, Take),
    % The elites are that front slice.
    append(Elites, _, Ranked).

% ===========================================================================
% GENERATIONS
% ===========================================================================

% evolve_next_generation(:Goal, +Scored, +Params, +Seed, -Pop2, -Seed2): step.
evolve_next_generation(_, Scored, params(Alphabet, K, Rate, EliteN), Seed, Pop2, Seed2) :-
    % Preserve the elites unchanged.
    evolve_elite(Scored, EliteN, Elites),
    % The new population keeps the old size.
    length(Scored, Size),
    % The rest of the population is bred.
    Need is Size - EliteN,
    % Breed the offspring.
    evolve_offspring(Scored, Alphabet, K, Rate, Need, Seed, Children, Seed2),
    % Elites and children together form the next generation.
    append(Elites, Children, Pop2).

% evolve_offspring(+Scored, +Alphabet, +K, +Rate, +N, +Seed, -Children, -Seed2).
evolve_offspring(_, _, _, _, 0, Seed, [], Seed) :-
    % No offspring remain to breed.
    !.
% Breed one child, then the rest.
evolve_offspring(Scored, Alphabet, K, Rate, N, Seed, [Child | Children], Seed2) :-
    % N is positive here.
    N > 0,
    % Select the first parent by tournament.
    evolve_tournament(Scored, K, Seed, P1, Seed1),
    % Select the second parent by tournament.
    evolve_tournament(Scored, K, Seed1, P2, SeedA),
    % Cross the parents.
    evolve_crossover(P1, P2, SeedA, Raw, SeedB),
    % Mutate the child.
    evolve_mutate(Raw, Alphabet, Rate, SeedB, Child, SeedC),
    % One fewer child remains.
    N1 is N - 1,
    % Breed the remaining children.
    evolve_offspring(Scored, Alphabet, K, Rate, N1, SeedC, Children, Seed2).

% evolve_run(:Goal, +Params, +Size, +Length, +Gens, +Seed, -Best, -Score): loop.
evolve_run(Goal, Params, Size, Length, Gens, Seed, Best, Score) :-
    % Unpack the alphabet for population creation.
    Params = params(Alphabet, _, _, _),
    % Create the founding population.
    evolve_population(Alphabet, Length, Size, Seed, Pop, Seed1),
    % Score the founders.
    evolve_evaluate(Goal, Pop, Scored),
    % Record the founding champion.
    evolve_best(Scored, B0, S0),
    % Iterate the generations, tracking the best ever seen.
    evolve_loop(Goal, Params, Scored, Gens, Seed1, B0-S0, Best-Score).

% evolve_loop(:Goal, +Params, +Scored, +N, +Seed, +BestSoFar, -Best): iterate.
evolve_loop(_, _, _, 0, _, Best, Best) :-
    % No generations remain.
    !.
% Breed, score, and track the champion, then recurse.
evolve_loop(Goal, Params, Scored, N, Seed, B0-S0, Best) :-
    % N is positive here.
    N > 0,
    % Breed the next generation.
    evolve_next_generation(Goal, Scored, Params, Seed, Pop2, Seed2),
    % Score the new generation.
    evolve_evaluate(Goal, Pop2, Scored2),
    % Find the new generation's champion.
    evolve_best(Scored2, B1, S1),
    % Keep whichever champion scores higher.
    (   S1 > S0
    % The newcomer takes the crown.
    ->  BS = B1-S1
    % The old champion keeps the crown.
    ;   BS = B0-S0
    ),
    % One fewer generation remains.
    N1 is N - 1,
    % Continue the loop.
    evolve_loop(Goal, Params, Scored2, N1, Seed2, BS, Best).

% evolve_run_until(:Goal, +Params, +Size, +Length, +MaxGens, +Target, +Seed,
%              -Best, -Score, -Gens): stop early at the target score.
evolve_run_until(Goal, Params, Size, Length, MaxGens, Target, Seed, Best, Score, Gens) :-
    % Unpack the alphabet for population creation.
    Params = params(Alphabet, _, _, _),
    % Create the founding population.
    evolve_population(Alphabet, Length, Size, Seed, Pop, Seed1),
    % Score the founders.
    evolve_evaluate(Goal, Pop, Scored),
    % Record the founding champion.
    evolve_best(Scored, B0, S0),
    % Iterate until the target is met or the budget runs out.
    evolve_until(Goal, Params, Scored, MaxGens, Target, Seed1, B0-S0, 0, Best-Score, Gens).

% evolve_until(:Goal, +Params, +Scored, +Left, +Target, +Seed, +BestSoFar,
%          +Done, -Best, -Gens): the early-stopping loop.
evolve_until(_, _, _, _, Target, _, B-S, Done, B-S, Done) :-
    % Stop as soon as the champion reaches the target.
    S >= Target,
    % Commit to the early stop.
    !.
% Stop when the generation budget is spent.
evolve_until(_, _, _, 0, _, _, Best, Done, Best, Done) :-
    % Commit to the budget stop.
    !.
% Otherwise breed one more generation and re-check.
evolve_until(Goal, Params, Scored, Left, Target, Seed, B0-S0, Done, Best, Gens) :-
    % Breed the next generation.
    evolve_next_generation(Goal, Scored, Params, Seed, Pop2, Seed2),
    % Score the new generation.
    evolve_evaluate(Goal, Pop2, Scored2),
    % Find the new generation's champion.
    evolve_best(Scored2, B1, S1),
    % Keep whichever champion scores higher.
    (   S1 > S0
    % The newcomer takes the crown.
    ->  BS = B1-S1
    % The old champion keeps the crown.
    ;   BS = B0-S0
    ),
    % One fewer generation remains in the budget.
    Left1 is Left - 1,
    % One more generation has been run.
    Done1 is Done + 1,
    % Continue the loop.
    evolve_until(Goal, Params, Scored2, Left1, Target, Seed2, BS, Done1, Best, Gens).

% ===========================================================================
% POPULATION MEASURES
% ===========================================================================

% evolve_diversity(+Pop, -Diversity): fraction of distinct genomes.
evolve_diversity(Pop, Diversity) :-
    % Count the population.
    length(Pop, N),
    % An empty population has no diversity.
    (   N =:= 0
    % Guard against division by zero.
    ->  Diversity = 0.0
    % Otherwise count the distinct genomes.
    ;   sort(Pop, Distinct),
        % Size of the distinct set.
        length(Distinct, D),
        % The diversity is the distinct fraction.
        Diversity is D / N
    ).

% evolve_converged(+Scored, +Threshold): diversity has collapsed to the bar.
evolve_converged(Scored, Threshold) :-
    % Extract the genomes.
    pairs_keys(Scored, Pop),
    % Measure their diversity.
    evolve_diversity(Pop, Diversity),
    % Converged when diversity is at or below the bar.
    Diversity =< Threshold.
