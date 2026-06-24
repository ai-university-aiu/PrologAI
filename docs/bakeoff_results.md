# PrologAI Vector Backend Bake-off Results

Winner: **prolog** (last run: prolog backend only; RuVector server not running)

| Backend | Score |
|---------|-------|
| prolog | 0.0712 |

## Notes

- Prolog backend: pure-Prolog fallback, benchmarked at <= 200 entries for CI (Continuous Integration) speed.
- RuVector backend: HNSW (Hierarchical Navigable Small World) + SIMD (Single Instruction, Multiple Data) HTTP REST server (https://github.com/ruvnet/ruvector). Start with `bash packs/vector_backend/scripts/ruvector_server.sh` before including ruvector in the bakeoff.
- Full benchmark scales (10k, 100k, 1M) supported by the RuVector backend.
- To run the RuVector bakeoff: `?- run_bakeoff([prolog, ruvector], [100, 1000]).`
- When the RuVector server is not running, the ruvector backend degrades gracefully and scores 0.0 (all HTTP calls are caught and return empty results). Re-run the bakeoff with the server active to get a valid comparison.
