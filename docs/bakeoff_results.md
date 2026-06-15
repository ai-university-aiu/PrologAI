# PrologAI Vector Backend Bake-off Results

Winner: **prolog**

| Backend | Score |
|---------|-------|
| prolog | 0.0712 |

## Notes

- Prolog backend: pure-Prolog fallback, benchmarked at ≤1000 entries.
- Rust backend (RuVector / hnswlib): not yet compiled; re-run bake-off once prologai-core is built.
- Full benchmark scales (10k, 100k, 1M) require the Rust backend.
