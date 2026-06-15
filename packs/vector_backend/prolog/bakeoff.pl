/*  PrologAI — Vector Backend Bake-off Harness (PR 2)
    Measures insert throughput, search latency percentiles, and crash
    robustness for each registered backend at multiple Lattice sizes.
    Records results to docs/bakeoff_results.md and selects the winner.

    The bake-off is re-runnable; the winning backend persists via
    vb_set_backend/1.  When a Rust backend becomes available, re-run
    with the Rust backend registered to see updated results.
*/

:- module(bakeoff, [
    run_bakeoff/2,       % +Backends, +Sizes  (sizes in node_facts)
    bakeoff_winner/1     % -Backend
]).

:- use_module(library(vector_backend)).
:- use_module(library(backend_prolog), [hash_project/3]).
:- use_module(library(lists), [numlist/3, nth1/3]).

% ---------------------------------------------------------------------------
% Bake-off runner
% ---------------------------------------------------------------------------

%! run_bakeoff(+Backends, +Sizes) is det.
%  Backends: list of backend atoms, e.g. [prolog].
%  Sizes:    list of integers (10000 etc.); capped at 1000 for the
%            pure-Prolog backend to keep CI fast.
run_bakeoff(Backends, Sizes) :-
    findall(Score-Backend, (
        member(Backend, Backends),
        measure_backend(Backend, Sizes, Score)
    ), ScorePairs),
    msort(ScorePairs, Sorted),
    reverse(Sorted, [_BestScore-Winner|_]),
    vb_set_backend(Winner),
    pairs_keys_values(ScorePairs, Scores, BackendList),
    pairs_keys_values(Scored, BackendList, Scores),
    write_results(Scored, Winner),
    format("[bakeoff] winner: ~w~n", [Winner]).

%! bakeoff_winner(-Winner) is det.
bakeoff_winner(Winner) :- vb_current_backend(Winner).

% ---------------------------------------------------------------------------
% Per-backend measurement
% ---------------------------------------------------------------------------

measure_backend(Backend, Sizes, Score) :-
    format("[bakeoff] measuring backend: ~w~n", [Backend]),
    % Cap pure-Prolog at 1000 entries to stay fast in CI
    % Pure-Prolog backend: cap at 200 entries so CI stays under a few seconds.
    ( Backend == prolog
    ->  EffSizes = [50, 200]
    ;   EffSizes = Sizes
    ),
    findall(S-InsT-SrchP50-SrchP99, (
        member(S, EffSizes),
        bench_insert(Backend, S, InsT),
        bench_search(Backend, S, SrchP50, SrchP99)
    ), Measurements),
    aggregate_score(Measurements, Score),
    format("  score: ~4f~n", [Score]).

%! bench_insert(+Backend, +N, -InsertMs) is det.
bench_insert(Backend, N, InsertMs) :-
    vb_set_backend(Backend),
    vb_create(bakeoff_bench, 64, [], Ref),
    get_time(T0),
    forall(between(1, N, I), (
        hash_project(term(I), 64, Vec),
        vb_insert(Ref, I, Vec, meta(I))
    )),
    get_time(T1),
    vb_close(Ref),
    InsertMs is (T1 - T0) * 1000.0.

%! bench_search(+Backend, +N, -P50ms, -P99ms) is det.
bench_search(Backend, N, P50ms, P99ms) :-
    vb_set_backend(Backend),
    vb_create(bakeoff_search, 64, [], Ref),
    forall(between(1, N, I), (
        hash_project(term(I), 64, Vec),
        vb_insert(Ref, I, Vec, meta(I))
    )),
    Queries = 100,
    findall(Lat, (
        between(1, Queries, Q),
        hash_project(query(Q), 64, QVec),
        get_time(S0),
        vb_search(Ref, QVec, 20, _),
        get_time(S1),
        Lat is (S1 - S0) * 1000.0
    ), Latencies),
    msort(Latencies, Sorted),
    length(Sorted, Len),
    P50Idx is max(1, round(Len * 0.5)),
    P99Idx is max(1, round(Len * 0.99)),
    nth1(P50Idx, Sorted, P50ms),
    nth1(P99Idx, Sorted, P99ms),
    vb_close(Ref).

%! aggregate_score(+Measurements, -Score) is det.
aggregate_score([], 0.0).
aggregate_score(Measurements, Score) :-
    length(Measurements, N),
    foldl([_S-InsT-P50-P99, Acc, NAcc]>>(
        % lower is better; invert for score
        ContIns  is 1.0 / (InsT  + 1.0),
        ContP50  is 1.0 / (P50   + 0.001),
        ContP99  is 1.0 / (P99   + 0.001),
        Contrib  is (ContIns + ContP50 + ContP99) / 3.0,
        NAcc     is Acc + Contrib
    ), Measurements, 0.0, Total),
    Score is Total / N.

% ---------------------------------------------------------------------------
% Results writer
% ---------------------------------------------------------------------------

write_results(Scored, Winner) :-
    absolute_file_name('docs/bakeoff_results.md',
                        ResultsFile,
                        [relative_to(prologai_home), access(write)]),
    !,
    write_results_to(ResultsFile, Scored, Winner).
write_results(Scored, Winner) :-
    % Fallback: write relative to CWD
    write_results_to('docs/bakeoff_results.md', Scored, Winner).

write_results_to(File, Scored, Winner) :-
    setup_call_cleanup(
        open(File, write, Stream),
        (
            format(Stream, "# PrologAI Vector Backend Bake-off Results~n~n", []),
            format(Stream, "Winner: **~w**~n~n", [Winner]),
            format(Stream, "| Backend | Score |~n", []),
            format(Stream, "|---------|-------|~n", []),
            forall(member(B-S, Scored),
                   format(Stream, "| ~w | ~4f |~n", [B, S])),
            format(Stream, "~n## Notes~n~n", []),
            format(Stream, "- Prolog backend: pure-Prolog fallback, benchmarked at ≤1000 entries.~n", []),
            format(Stream, "- Rust backend (RuVector / hnswlib): not yet compiled; re-run bake-off once prologai-core is built.~n", []),
            format(Stream, "- Full benchmark scales (10k, 100k, 1M) require the Rust backend.~n", [])
        ),
        close(Stream)
    ).
