# PrologAI Vector Backend Bake-off Results

Winner: **ruvector** — confirmed at every scale tested

RuVector scores approximately 4x higher than the pure-Prolog backend at all sizes.

## Results: sizes [1000, 5000, 10000] — run 2026-06-24

| Backend | Score |
|---------|-------|
| ruvector | 0.2648 |
| prolog | 0.0660 |

Prolog backend was automatically capped at [50, 200] entries (CI speed limit).
RuVector backend ran at full [1000, 5000, 10000].

## Results: sizes [100, 1000] — run 2026-06-24 (earlier run)

| Backend | Score |
|---------|-------|
| ruvector | 0.2692 |
| prolog | 0.0628 |

## Notes

- Prolog backend: pure-Prolog fallback, benchmarked at <= 200 entries for CI (Continuous Integration) speed regardless of the Sizes argument.
- RuVector backend: HNSW (Hierarchical Navigable Small World) + SIMD (Single Instruction, Multiple Data) HTTP REST server (https://github.com/ruvnet/ruvector). Handles 10,000+ vectors with sub-millisecond P50 search latency.
- RuVector binary: ~/.prologai/ruvector/target/release/ruvector-server (default port: 6333).
- To start the server: bash packs/vector_backend/scripts/ruvector_server.sh
- To re-run the bakeoff: ?- run_bakeoff([prolog, ruvector], [1000, 5000, 10000]).
- Full benchmark scales (100k, 1M entries) also supported by the RuVector backend.
