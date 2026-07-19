# The packaging construct — dependency kinds, faces, facades, and a record registry (Wave 10 Stage 7, WP-436)

Closes the Requirements Ledger's **Theme G** (packaging and dependency kinds): ATOMIC-1,
ATOMIC-2, ATOMIC-3, ATOMIC-4. PrologAI had ONE kind of dependency — a `use_module`
import — and no way to say what KIND it was; the one-pack-per-construct arm surfaced the
cost when its high pack count turned every intra-pack reference into an inter-pack import.

## Dependency kinds (ATOMIC-1)

A dependency is declared with a **kind**:

- `structure_only` — needed only to mint a record (a mint-time edge, never behaviour).
- `runtime` — needed to run behaviour (the edge the layer graph must count).

`packaging_runtime_dependencies/2` returns only the runtime targets, so the layer graph
and import fan-out are not inflated by mint-time-only edges.

## Loadable pack faces (ATOMIC-4)

A dependency's kind maps to the target pack **face** it needs
(`packaging_required_face/2`: `structure_only → structure`, `runtime → runtime`).
`packaging_face_dependencies/3` returns only the requirements that loading one face
pulls, so validating a record (the structure face) never drags in the runtime substrate.

## Facade / bundle (ATOMIC-2)

`packaging_declare_facade/2` names a bundle of packs (or nested facades);
`packaging_expand/2` expands a target to its concrete pack set, recursively and
cycle-safely. A consumer names the bundle instead of enumerating every fine-grained pack.

## Cross-pack record registry (ATOMIC-3)

`packaging_register_record/3`, `packaging_record/2`, and `packaging_record_owner/2` look
up a content-addressed record and its owning pack by id, so ids are not threaded by
hand-exported accessors and coupling does not concentrate at the interfaces.

## Interface

| Predicate | Meaning |
|-----------|---------|
| `packaging_declare_dependency(+From, +To, +Kind)` | Declare a typed dependency (`structure_only`/`runtime`). |
| `packaging_dependency(?From, ?To, ?Kind)` | Query the declared dependencies. |
| `packaging_runtime_dependencies(+From, -Tos)` | Only the runtime targets. |
| `packaging_structure_only_dependencies(+From, -Tos)` | Only the mint-time targets. |
| `packaging_required_face(+Kind, -Face)` | The face a kind requires. |
| `packaging_face_dependencies(+Pack, +Face, -RequiredFaces)` | What loading one face pulls. |
| `packaging_declare_facade(+Name, +Members)` | Declare a bundle. |
| `packaging_facade(?Name, ?Members)` | The direct members of a facade. |
| `packaging_expand(+Target, -Packs)` | Expand a pack or facade to its concrete set. |
| `packaging_register_record(+Id, +Record, +OwnerPack)` | Register a content-addressed record. |
| `packaging_record(?Id, ?Record)` | Look up a record by id. |
| `packaging_record_owner(?Id, ?OwnerPack)` | The owning pack of an id. |

Base infrastructure at layer 0; depends only on SWI-Prolog standard libraries; touches
no ARC state.
