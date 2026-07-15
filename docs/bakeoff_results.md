# PrologAI Vector Backend Bake-off Results

Winner: **prolog**

| Backend | Score |
|---------|-------|
| prolog | 0.0697 |

## Notes

- Prolog backend: pure-Prolog fallback, benchmarked at ≤200 entries for CI speed.
- RuVector backend: HNSW + SIMD HTTP REST server (https://github.com/ruvnet/ruvector); start with scripts/ruvector_server.sh before including in bakeoff.
- Full benchmark scales (10k, 100k, 1M) supported by the RuVector backend.
- To run the RuVector bakeoff: ?- run_bakeoff([prolog, ruvector], [100, 1000]).
