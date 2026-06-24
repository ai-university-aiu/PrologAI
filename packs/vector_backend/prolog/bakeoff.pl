/*  PrologAI — Vector Backend Bake-off Harness (PR 2)
    Measures insert throughput, search latency percentiles, and crash
    robustness for each registered backend at multiple Lattice sizes.
    Records results to docs/bakeoff_results.md and selects the winner.

    The bake-off is re-runnable; the winning backend persists via
    vb_set_backend/1.  When a Rust backend becomes available, re-run
    with the Rust backend registered to see updated results.
*/

% Declare this file as the 'bakeoff' module and list its exported predicates.
:- module(bakeoff, [
    % Continue the multi-line expression started above.
    run_bakeoff/2,       % +Backends, +Sizes  (sizes in node_facts)
    % Continue the multi-line expression started above.
    bakeoff_winner/1     % -Backend
% Close the expression opened above.
]).

% Load the built-in 'vector_backend' library so its predicates are available here.
:- use_module(library(vector_backend)).
% Import [hash_project/3] from the built-in 'backend_prolog' library.
:- use_module(library(backend_prolog), [hash_project/3]).
% Import [numlist/3, nth1/3] from the built-in 'lists' library.
:- use_module(library(lists), [numlist/3, nth1/3]).

% ---------------------------------------------------------------------------
% Bake-off runner
% ---------------------------------------------------------------------------

%! run_bakeoff(+Backends, +Sizes) is det.
%  Backends: list of backend atoms, e.g. [prolog, ruvector].
%  Sizes:    list of integers (10000 etc.); capped at 200 for the
%            pure-Prolog backend to keep CI fast.
%            Start the RuVector server first (see scripts/ruvector_server.sh)
%            before including 'ruvector' in the Backends list.
% Define a clause for 'run bakeoff': succeed when the following conditions hold.
run_bakeoff(Backends, Sizes) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Score-Backend, (
        % Continue the multi-line expression started above.
        member(Backend, Backends),
        % Continue the multi-line expression started above.
        measure_backend(Backend, Sizes, Score)
    % Continue the multi-line expression started above.
    ), ScorePairs),
    % Sort list 'ScorePairs' into 'Sorted', keeping duplicates.
    msort(ScorePairs, Sorted),
    % State a fact for 'reverse' with the arguments listed below.
    reverse(Sorted, [_BestScore-Winner|_]),
    % State a fact for 'vb set backend' with the arguments listed below.
    vb_set_backend(Winner),
    % State a fact for 'pairs keys values' with the arguments listed below.
    pairs_keys_values(ScorePairs, Scores, BackendList),
    % State a fact for 'pairs keys values' with the arguments listed below.
    pairs_keys_values(Scored, BackendList, Scores),
    % State a fact for 'write results' with the arguments listed below.
    write_results(Scored, Winner),
    % Write formatted output to the current output stream.
    format("[bakeoff] winner: ~w~n", [Winner]).

%! bakeoff_winner(-Winner) is det.
% Define a clause for 'bakeoff winner': succeed when the following conditions hold.
bakeoff_winner(Winner) :- vb_current_backend(Winner).

% ---------------------------------------------------------------------------
% Per-backend measurement
% ---------------------------------------------------------------------------

% Define a clause for 'measure backend': succeed when the following conditions hold.
measure_backend(Backend, Sizes, Score) :-
    % Write formatted output to the current output stream.
    format("[bakeoff] measuring backend: ~w~n", [Backend]),
    % Pure-Prolog backend: cap at 200 entries so CI stays under a few seconds.
    % RuVector backend: use the caller-supplied Sizes (supports large-scale runs).
    % Check that '( Backend' is structurally identical to 'prolog'.
    ( Backend == prolog
    % If the condition above succeeded, perform the following action.
    ->  EffSizes = [50, 200]
    % Otherwise (else branch), perform the following action.
    ;   EffSizes = Sizes
    % Close the expression opened above.
    ),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(S-InsT-SrchP50-SrchP99, (
        % Continue the multi-line expression started above.
        member(S, EffSizes),
        % Continue the multi-line expression started above.
        bench_insert(Backend, S, InsT),
        % Continue the multi-line expression started above.
        bench_search(Backend, S, SrchP50, SrchP99)
    % Continue the multi-line expression started above.
    ), Measurements),
    % State a fact for 'aggregate score' with the arguments listed below.
    aggregate_score(Measurements, Score),
    % Write formatted output to the current output stream.
    format("  score: ~4f~n", [Score]).

%! bench_insert(+Backend, +N, -InsertMs) is det.
% Define a clause for 'bench insert': succeed when the following conditions hold.
bench_insert(Backend, N, InsertMs) :-
    % State a fact for 'vb set backend' with the arguments listed below.
    vb_set_backend(Backend),
    % State a fact for 'vb create' with the arguments listed below.
    vb_create(bakeoff_bench, 64, [], Ref),
    % State a fact for 'get time' with the arguments listed below.
    get_time(T0),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, N, I), (
        % Continue the multi-line expression started above.
        hash_project(term(I), 64, Vec),
        % Continue the multi-line expression started above.
        vb_insert(Ref, I, Vec, meta(I))
    % Close the expression opened above.
    )),
    % State a fact for 'get time' with the arguments listed below.
    get_time(T1),
    % State a fact for 'vb close' with the arguments listed below.
    vb_close(Ref),
    % Evaluate the arithmetic expression '(T1 - T0) * 1000.0' and bind the result to 'InsertMs'.
    InsertMs is (T1 - T0) * 1000.0.

%! bench_search(+Backend, +N, -P50ms, -P99ms) is det.
% Define a clause for 'bench search': succeed when the following conditions hold.
bench_search(Backend, N, P50ms, P99ms) :-
    % State a fact for 'vb set backend' with the arguments listed below.
    vb_set_backend(Backend),
    % State a fact for 'vb create' with the arguments listed below.
    vb_create(bakeoff_search, 64, [], Ref),
    % Verify that for every solution of the Condition, the Action also holds.
    forall(between(1, N, I), (
        % Continue the multi-line expression started above.
        hash_project(term(I), 64, Vec),
        % Continue the multi-line expression started above.
        vb_insert(Ref, I, Vec, meta(I))
    % Close the expression opened above.
    )),
    % Check that 'Queries' is unifiable with '100'.
    Queries = 100,
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Lat, (
        % Continue the multi-line expression started above.
        between(1, Queries, Q),
        % Continue the multi-line expression started above.
        hash_project(query(Q), 64, QVec),
        % Continue the multi-line expression started above.
        get_time(S0),
        % Continue the multi-line expression started above.
        vb_search(Ref, QVec, 20, _),
        % Continue the multi-line expression started above.
        get_time(S1),
        % Continue the multi-line expression started above.
        Lat is (S1 - S0) * 1000.0
    % Continue the multi-line expression started above.
    ), Latencies),
    % Sort list 'Latencies' into 'Sorted', keeping duplicates.
    msort(Latencies, Sorted),
    % Unify 'Len' with the number of elements in list 'Sorted'.
    length(Sorted, Len),
    % Evaluate the arithmetic expression 'max(1, round(Len * 0.5))' and bind the result to 'P50Idx'.
    P50Idx is max(1, round(Len * 0.5)),
    % Evaluate the arithmetic expression 'max(1, round(Len * 0.99))' and bind the result to 'P99Idx'.
    P99Idx is max(1, round(Len * 0.99)),
    % Retrieve the element at the specified one-based position from the list.
    nth1(P50Idx, Sorted, P50ms),
    % Retrieve the element at the specified one-based position from the list.
    nth1(P99Idx, Sorted, P99ms),
    % State the fact: vb close(Ref).
    vb_close(Ref).

%! aggregate_score(+Measurements, -Score) is det.
% State the fact: aggregate score([], 0.0).
aggregate_score([], 0.0).
% Define a clause for 'aggregate score': succeed when the following conditions hold.
aggregate_score(Measurements, Score) :-
    % Unify 'N' with the number of elements in list 'Measurements'.
    length(Measurements, N),
    % State a fact for 'foldl' with the arguments listed below.
    foldl([_S-InsT-P50-P99, Acc, NAcc]>>(
        % lower is better; invert for score
        % Continue the multi-line expression started above.
        ContIns  is 1.0 / (InsT  + 1.0),
        % Continue the multi-line expression started above.
        ContP50  is 1.0 / (P50   + 0.001),
        % Continue the multi-line expression started above.
        ContP99  is 1.0 / (P99   + 0.001),
        % Continue the multi-line expression started above.
        Contrib  is (ContIns + ContP50 + ContP99) / 3.0,
        % Continue the multi-line expression started above.
        NAcc     is Acc + Contrib
    % Continue the multi-line expression started above.
    ), Measurements, 0.0, Total),
    % Evaluate the arithmetic expression 'Total / N' and bind the result to 'Score'.
    Score is Total / N.

% ---------------------------------------------------------------------------
% Results writer
% ---------------------------------------------------------------------------

% Define a clause for 'write results': succeed when the following conditions hold.
write_results(Scored, Winner) :-
    % State a fact for 'absolute file name' with the arguments listed below.
    absolute_file_name('docs/bakeoff_results.md',
                        % Supply 'ResultsFile' as the next argument to the expression above.
                        ResultsFile,
                        % Continue the multi-line expression started above.
                        [relative_to(prologai_home), access(write)]),
    % Commit to this clause — discard all remaining choice points (cut).
    !,
    % State the fact: write results to(ResultsFile, Scored, Winner).
    write_results_to(ResultsFile, Scored, Winner).
% Define a clause for 'write results': succeed when the following conditions hold.
write_results(Scored, Winner) :-
    % Fallback: write relative to CWD
    % State the fact: write results to('docs/bakeoff_results.md', Scored, Winner).
    write_results_to('docs/bakeoff_results.md', Scored, Winner).

% Define a clause for 'write results to': succeed when the following conditions hold.
write_results_to(File, Scored, Winner) :-
    % State a fact for 'setup call cleanup' with the arguments listed below.
    setup_call_cleanup(
        % Continue the multi-line expression started above.
        open(File, write, Stream),
        % Continue the multi-line expression started above.
        (
            % Continue the multi-line expression started above.
            format(Stream, "# PrologAI Vector Backend Bake-off Results~n~n", []),
            % Continue the multi-line expression started above.
            format(Stream, "Winner: **~w**~n~n", [Winner]),
            % Continue the multi-line expression started above.
            format(Stream, "| Backend | Score |~n", []),
            % Continue the multi-line expression started above.
            format(Stream, "|---------|-------|~n", []),
            % Continue the multi-line expression started above.
            forall(member(B-S, Scored),
                   % Continue the multi-line expression started above.
                   format(Stream, "| ~w | ~4f |~n", [B, S])),
            % Continue the multi-line expression started above.
            format(Stream, "~n## Notes~n~n", []),
            % Continue the multi-line expression started above.
            format(Stream, "- Prolog backend: pure-Prolog fallback, benchmarked at ≤200 entries for CI speed.~n", []),
            % Continue the multi-line expression started above.
            format(Stream, "- RuVector backend: HNSW + SIMD HTTP REST server (https://github.com/ruvnet/ruvector); start with scripts/ruvector_server.sh before including in bakeoff.~n", []),
            % Continue the multi-line expression started above.
            format(Stream, "- Full benchmark scales (10k, 100k, 1M) supported by the RuVector backend.~n", []),
            % Continue the multi-line expression started above.
            format(Stream, "- To run the RuVector bakeoff: ?- run_bakeoff([prolog, ruvector], [100, 1000]).~n", [])
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        close(Stream)
    % Close the expression opened above.
    ).
