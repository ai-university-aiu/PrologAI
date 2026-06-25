# PrologAI Vector Backend Bake-off Results

Winner: **ruvector** (last live run: 2026-06-24, sizes [100, 1000])

RuVector scored 4.3x higher than the pure-Prolog backend.

| Backend | Score |
|---------|-------|
| ruvector | 0.2692 |
| prolog | 0.0628 |

## Notes

- Prolog backend: pure-Prolog fallback, benchmarked at <= 200 entries for CI (Continuous Integration) speed. Score: 0.0628.
- RuVector backend: HNSW (Hierarchical Navigable Small World) + SIMD (Single Instruction, Multiple Data) HTTP REST server (https://github.com/ruvnet/ruvector). Score at [100, 1000]: 0.2692. RuVector is 4.3x faster on this hardware.
- RuVector binary built from source at: ~/.prologai/ruvector/target/release/ruvector-server (default port: 6333).
- To start the server: bash packs/vector_backend/scripts/ruvector_server.sh
- To re-run the bakeoff: ?- run_bakeoff([prolog, ruvector], [100, 1000]).
- Full benchmark scales (10k, 100k, 1M entries) supported by the RuVector backend.
