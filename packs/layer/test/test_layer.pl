/*  PrologAI — Strict Layer Rule test suite  (WP-426)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/layer/test/test_layer.pl

    Covers: the pure violation core; declared/undeclared reading from real
    manifests; strict and report enforcement; and the SPIKE-ARM REPLAY — the two
    arms of the frozen prologai-loops spike, snapshotted read-only under
    fixtures/, checked by construct to have ZERO upward static edges (reproducing
    what the spike proved by hand), plus the L5 heuristic data-reference lint
    distinguishing the mailbox arm (one upward reference carried as data) from
    the stigmergy arm (none).
*/

% Declare this file as a test module.
:- module(test_layer, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(layer)).
% Import member/2 and friends for building node sets in tests.
:- use_module(library(lists), [member/2]).

% Compute the absolute path of a fixture file relative to this test file.
% Bind ThisDir to the directory holding this test source.
fixture(Rel, Abs) :-
    % Find this test file's own path.
    module_property(test_layer, file(Self)),
    % Take the directory that contains it.
    file_directory_name(Self, Dir),
    % Join the fixtures-relative path onto that directory.
    atomic_list_concat([Dir, '/fixtures/', Rel], Abs).

% Open the test block for the layer construct.
:- begin_tests(layer).

% AC-L4-001: the pure core detects a deliberate upward dependency.
test(detects_upward_violation) :-
    % A base pack at layer 0 imports a cortex pack at layer 3 (forbidden).
    Nodes = [node(base, 0, [cortex]), node(cortex, 3, [])],
    % Run the pure violation core.
    layer_graph_violations(Nodes, Violations),
    % Exactly one violation is reported, naming both endpoints and layers.
    assertion(Violations == [violation(upward_dependency,
                                       from(base, 0), to(cortex, 3),
                                       via(use_module(library(cortex))))]).

% AC-L4-002: a purely downward configuration is clean.
test(downward_is_clean) :-
    % A high pack importing a low pack is allowed.
    Nodes = [node(cortex, 3, [base]), node(base, 0, [])],
    % The core reports no violations.
    layer_graph_violations(Nodes, Violations),
    % The clean configuration passes.
    assertion(Violations == []).

% AC-L4-003: importing an UNDECLARED pack is never a violation.
test(undeclared_target_is_not_a_violation) :-
    % A base pack imports a widget pack that declares no layer.
    Nodes = [node(base, 0, [widget]), node(widget, undeclared, [])],
    % The core reports no violation for the undeclared edge.
    layer_graph_violations(Nodes, Violations),
    % Undeclared is a gap, not an error.
    assertion(Violations == []).

% AC-L4-004: a same-pack (self) import is not counted as an inter-pack edge.
test(self_import_ignored) :-
    % A pack that lists itself among its imports (an intra-pack file).
    Nodes = [node(base, 0, [base])],
    % No violation arises from a pack importing its own files.
    layer_graph_violations(Nodes, Violations),
    % Self edges are ignored.
    assertion(Violations == []).

% AC-L4-005: the real repository configuration is clean.
test(repo_is_clean) :-
    % Check the repository's own packs directory.
    layer_check(Violations),
    % The adopted declarations honour the strict layer rule.
    assertion(Violations == []).

% AC-L4-006: the adopted packs declare the layers we set.
test(adopted_declarations_present) :-
    % The layer pack itself sits at layer 0.
    assertion(layer_of(layer, 0)),
    % The Lattice is base infrastructure at layer 0.
    assertion(layer_of(lattice, 0)),
    % The actor framework is one layer above at layer 1.
    assertion(layer_of(actors, 1)).

% AC-L4-007: an undeclared pack is reported as a gap, not a violation.
test(undeclared_reported_as_gap) :-
    % Locate the packs directory and scan it.
    layer_default_packs_dir(Dir),
    layer_scan(Dir, _Nodes, Undeclared),
    % There are undeclared packs (adoption is incremental).
    assertion(Undeclared \== []),
    % A representative core pack that we did NOT declare is in the gap list.
    assertion(memberchk(grid, Undeclared)).

% AC-L4-008: report mode never refuses, even with a violation present.
% (Enforcement over the real repo is clean, so we assert report mode succeeds.)
test(enforce_report_succeeds) :-
    % Report mode prints and always succeeds on a clean repo.
    assertion(layer_enforce(report)).

% AC-L4-009: strict mode succeeds on the clean repo (no throw).
test(enforce_strict_clean_succeeds) :-
    % Strict mode succeeds because the repository is clean.
    assertion(catch(layer_enforce(strict), _, fail)).

% AC-L4-010: strict mode THROWS when run against a REAL violating configuration.
% This exercises the actual enforcement path — layer_enforce_dir/2 in strict mode
% over a packs directory that holds a genuine upward edge — not merely the pure
% core. The fixture packs (fixture_low at layer 0 importing fixture_high at layer
% 5) live read-only under fixtures/violation_packs/.
test(strict_throws_on_violation,
     [throws(error(layer_rule_violation(_), _))]) :-
    % Point at the violating fixture packs directory.
    fixture(violation_packs, ViolatingDir),
    % Strict enforcement over a violating configuration must refuse by throwing.
    layer_enforce_dir(ViolatingDir, strict).

% AC-L4-010b: the SAME violating configuration really is a violation (pure core).
% Kept separate so the throw test above is anchored to a configuration the
% checker independently confirms is violating, naming both endpoints and layers.
test(violating_fixture_is_a_violation) :-
    % Point at the violating fixture packs directory.
    fixture(violation_packs, ViolatingDir),
    % The directory-scoped check reports the violation list for that directory.
    layer_check_dir(ViolatingDir, Violations),
    % Exactly the one deliberate upward edge is found (layer 0 → layer 5).
    assertion(Violations == [violation(upward_dependency,
                                       from(fixture_low, 0),
                                       to(fixture_high, 5),
                                       via(use_module(library(fixture_high))))]).

% AC-L4-010c: report mode over the SAME violating configuration does NOT throw.
% It reports the violation without refusing, so incremental adoption never breaks
% a build even where a real upward edge already exists.
test(report_does_not_throw_on_violation) :-
    % Point at the violating fixture packs directory.
    fixture(violation_packs, ViolatingDir),
    % Report mode succeeds (never throws) even with a violation present.
    assertion(catch(layer_enforce_dir(ViolatingDir, report), _, fail)).

% AC-L4-011 (SPIKE REPLAY): the mailbox arm has ZERO upward static import edges.
test(replay_mailbox_zero_upward_edges) :-
    % Build a node per actor file, at its biological layer, with imported roles.
    replay_nodes(arm_mailbox, mbx, Nodes),
    % Run the pure violation core over the reconstructed graph.
    layer_graph_violations(Nodes, Violations),
    % The static import graph is acyclic and layer-respecting: no upward edges.
    assertion(Violations == []),
    % And there are no inter-actor import edges at all (the spike's core finding).
    assertion(inter_actor_edges(Nodes, 0)).

% AC-L4-012 (SPIKE REPLAY): the stigmergy arm has ZERO upward static import edges.
test(replay_stigmergy_zero_upward_edges) :-
    % Build a node per actor file for the stigmergy arm.
    replay_nodes(arm_stigmergy, stg, Nodes),
    % Run the pure violation core.
    layer_graph_violations(Nodes, Violations),
    % No upward edges — reproduced by construct, not by hand.
    assertion(Violations == []),
    % No inter-actor import edges either.
    assertion(inter_actor_edges(Nodes, 0)).

% AC-L4-013 (L5): the mailbox arm carries ONE upward reference as DATA.
test(l5_mailbox_flags_data_reference) :-
    % Describe the three mailbox actor files with their biological layers.
    fixture('arm_mailbox/mbx_cortex.pl', C),
    fixture('arm_mailbox/mbx_striatum.pl', S),
    fixture('arm_mailbox/mbx_thalamus.pl', T),
    Files = [dfile(cortex, 3, C), dfile(striatum, 2, S), dfile(thalamus, 1, T)],
    % Run the heuristic data-reference lint.
    layer_data_references_files(Files, Suspects),
    % The relay (layer 1) quotes the origin 'cortex' (layer 3): flagged.
    assertion(member(data_reference(from(thalamus, 1),
                                    mentions(cortex, 3), file(_)), Suspects)).

% AC-L4-014 (L5): the stigmergy arm carries NO upward reference as DATA.
test(l5_stigmergy_flags_nothing) :-
    % Describe the three stigmergy actor files with their biological layers.
    fixture('arm_stigmergy/stg_cortex.pl', C),
    fixture('arm_stigmergy/stg_striatum.pl', S),
    fixture('arm_stigmergy/stg_thalamus.pl', T),
    Files = [dfile(cortex, 3, C), dfile(striatum, 2, S), dfile(thalamus, 1, T)],
    % Run the heuristic data-reference lint.
    layer_data_references_files(Files, Suspects),
    % Stigmergy names no one in data: the lint finds nothing.
    assertion(Suspects == []).

% Close the test block.
:- end_tests(layer).

% ---------------------------------------------------------------------------
% Replay helpers — reconstruct the spike arm's static graph from its source.
% ---------------------------------------------------------------------------

% The three actor roles and their biological layers (higher number = higher).
role_layer(cortex, 3).
role_layer(striatum, 2).
role_layer(thalamus, 1).

% Build one node per actor file: node(Role, Layer, ImportedRoles).
% Arm is the fixture sub-directory; Prefix is the file-name prefix (mbx/stg).
replay_nodes(Arm, Prefix, Nodes) :-
    % For each role, locate its file and extract the roles it imports.
    findall(node(Role, Layer, ImportedRoles),
            ( role_layer(Role, Layer),
              atomic_list_concat([Arm, '/', Prefix, '_', Role, '.pl'], Rel),
              fixture(Rel, Path),
              % Read the raw import specs (comment-stripped) of the file.
              layer_import_specs(Path, Specs),
              % Keep the roles whose name appears in an import spec (there are none).
              findall(Other,
                      ( role_layer(Other, _),
                        Other \== Role,
                        member(Spec, Specs),
                        sub_atom(Spec, _, _, _, Other) ),
                      ImportedRolesRaw),
              sort(ImportedRolesRaw, ImportedRoles) ),
            Nodes).

% Count the inter-actor import edges across a node set (should be zero).
inter_actor_edges(Nodes, Count) :-
    % Collect one marker per edge whose target is also an actor role.
    findall(edge,
            ( member(node(From, _, Imports), Nodes),
              member(To, Imports),
              role_layer(To, _),
              To \== From ),
            Edges),
    % The number of such edges.
    length(Edges, Count).

% ---------------------------------------------------------------------------
% Layer-to-stratum BINDING tests (N6 — closes STRATA-3).
%
% Fixtures under fixtures/binding/:
%   strata/     three stratum records (low ordinal 4, mid 7, high 14)
%   consistent/ layers 1/2/3 bound to low/mid/high; pack_high (ord 14) imports
%               pack_low (ord 4) — a legitimate DOWNWARD SKIP across the gap
%   upward/     pack_ulow (ord 4, layer 1) imports pack_uhigh (ord 14, layer 3)
%               — an UPWARD edge (L4 must fail; the binding is still consistent)
%   misbound/   pack_sneaky_high mis-declares layer 0 for the ordinal-14 stratum,
%               DISGUISING an upward dependency as downward: L4 is fooled and
%               passes, but the BINDING catches the layer/ordinal contradiction
%   unbound/    a pack with a layer but no stratum — an unbound gap, not an error
% ---------------------------------------------------------------------------

% Open the test block for the binding construct.
:- begin_tests(layer_binding).

% AC-N6-001: stratum ordinals are read from the authoritative structure records.
test(reads_stratum_ordinals) :-
    % Locate the strata-source fixture directory.
    fixture('binding/strata', Strata),
    % Read the label-to-ordinal pairs.
    layer_stratum_ordinals(Strata, Pairs),
    % The three declared strata and their ordinals are recovered exactly.
    assertion(memberchk(low_stratum-4, Pairs)),
    assertion(memberchk(mid_stratum-7, Pairs)),
    assertion(memberchk(high_stratum-14, Pairs)).

% AC-N6-002: a consistent layer/stratum configuration PASSES the binding check.
test(consistent_config_passes) :-
    % Point at the consistent packs directory and the strata source.
    fixture('binding/consistent', Packs), fixture('binding/strata', Strata),
    % The binding check reports no violations.
    layer_bind_check_dir(Packs, Strata, Violations),
    assertion(Violations == []),
    % Strict enforcement succeeds (does not throw) on the consistent configuration.
    assertion(catch(layer_bind_enforce_dir(Packs, Strata, strict), _, fail)).

% AC-N6-003: a legitimate DOWNWARD SKIP (high ordinal depending on low) passes both.
test(downward_skip_passes_binding_and_layer_rule) :-
    % The consistent fixture has pack_high (stratum ordinal 14) importing pack_low (ordinal 4).
    fixture('binding/consistent', Packs), fixture('binding/strata', Strata),
    % The binding check passes (the layers honour the ordinals).
    layer_bind_check_dir(Packs, Strata, BindViolations),
    assertion(BindViolations == []),
    % And the L4 layer rule passes too (the skip is a downward edge: layer 3 -> layer 1).
    layer_check_dir(Packs, LayerViolations),
    assertion(LayerViolations == []).

% AC-N6-004: a deliberate BINDING VIOLATION is detected, readable, and refused in strict mode.
test(binding_violation_detected_and_refused) :-
    % Point at the mis-bound packs directory and the strata source.
    fixture('binding/misbound', Packs), fixture('binding/strata', Strata),
    % The binding check reports at least one violation.
    layer_bind_check_dir(Packs, Strata, Violations),
    assertion(Violations \== []),
    % The violation renders a readable one-line explanation naming the reason.
    Violations = [V|_], layer_binding_violation_line(V, Line),
    assertion(sub_atom(Line, _, _, _, 'binding_rule violation')),
    % Strict enforcement over the violating configuration refuses by throwing.
    assertion(\+ catch(layer_bind_enforce_dir(Packs, Strata, strict), _, fail)).

% AC-N6-005: an UPWARD edge fails the L4 layer rule while the binding stays consistent.
test(upward_edge_fails_layer_rule_binding_clean) :-
    % Point at the upward packs directory and the strata source.
    fixture('binding/upward', Packs), fixture('binding/strata', Strata),
    % The L4 layer rule catches the upward edge (a low layer importing a higher one).
    layer_check_dir(Packs, LayerViolations),
    assertion(LayerViolations \== []),
    % The binding check is clean: the two packs' layers are consistent with their ordinals.
    layer_bind_check_dir(Packs, Strata, BindViolations),
    assertion(BindViolations == []).

% AC-N6-006: the BINDING catches an upward dependency DISGUISED as downward by a mis-declared
% layer — exactly the loophole L4 alone cannot see. This is the reason the binding must exist.
test(binding_catches_disguised_upward_that_fools_layer_rule) :-
    % The mis-bound fixture disguises an ordinal-upward dependency as a layer-downward one.
    fixture('binding/misbound', Packs), fixture('binding/strata', Strata),
    % L4 is FOOLED: the mis-declared layers make the edge look downward, so it passes.
    layer_check_dir(Packs, LayerViolations),
    assertion(LayerViolations == []),
    % The BINDING catches the disguise: a coarse stratum was given a lower layer than a fine one.
    layer_bind_check_dir(Packs, Strata, BindViolations),
    assertion(BindViolations \== []).

% AC-N6-007: an UNBOUND pack (a layer but no stratum) is a gap, not a violation.
test(unbound_pack_is_a_gap_not_an_error) :-
    % Point at the unbound packs directory and the strata source.
    fixture('binding/unbound', Packs), fixture('binding/strata', Strata),
    % Read the ordinals and scan the unbound directory.
    layer_stratum_ordinals(Strata, Ord),
    layer_bind_scan(Packs, Ord, Bound, Unbound),
    % No pack is bound (none declares a stratum).
    assertion(Bound == []),
    % The layer-declaring pack with no stratum is reported as an unbound gap.
    assertion(memberchk(unbound(pack_nostratum, 2, no_stratum_declared), Unbound)),
    % And there is no binding violation — an unbound pack never breaks the build.
    layer_bind_check_dir(Packs, Strata, Violations),
    assertion(Violations == []).

% AC-N6-008: report mode over a violating configuration lists but does NOT throw.
test(report_mode_does_not_throw_on_violation) :-
    % Point at the mis-bound packs directory and the strata source.
    fixture('binding/misbound', Packs), fixture('binding/strata', Strata),
    % Report mode succeeds (never throws) even with a binding violation present.
    assertion(catch(layer_bind_enforce_dir(Packs, Strata, report), _, fail)).

% AC-N6-009: the pure binding-violation core detects a contradiction and clears a clean set.
test(pure_binding_core) :-
    % A fine stratum (ordinal 4) given a HIGHER layer than a coarse stratum (ordinal 14) is bad.
    Bad = [bnode(a, 3, s_fine, 4), bnode(b, 1, s_coarse, 14)],
    layer_binding_violations(Bad, BadV),
    assertion(BadV \== []),
    % A monotonic assignment (ordinal up, layer up) is clean.
    Good = [bnode(a, 1, s_fine, 4), bnode(b, 3, s_coarse, 14)],
    layer_binding_violations(Good, GoodV),
    assertion(GoodV == []),
    % Two packs at the same ordinal must share a layer.
    Tie = [bnode(a, 1, s_x, 7), bnode(b, 2, s_x, 7)],
    layer_binding_violations(Tie, TieV),
    assertion(TieV \== []).

% Close the binding test block.
:- end_tests(layer_binding).

% ---------------------------------------------------------------------------
% THE LAYER CONSTRUCT'S REACH (Wave 10 Stage 6, WP-435; closes Theme E)
% ---------------------------------------------------------------------------

% Load filesystem helpers for building throwaway fixture repositories.
:- use_module(library(filesex)).

% Build a fixture pack under BaseDir: a pack.pl manifest (name, version, optional layer)
% and a prolog/<Pack>.pl module that use_module(library(...)) each of its imports.
test_layer_make_fixture_pack(BaseDir, Pack, Layer, Imports) :-
    format(atom(PackDir), '~w/~w', [BaseDir, Pack]),
    format(atom(PrologDir), '~w/prolog', [PackDir]),
    make_directory_path(PrologDir),
    format(atom(ManifestPath), '~w/pack.pl', [PackDir]),
    setup_call_cleanup(open(ManifestPath, write, MS),
        ( format(MS, 'name(~w).~n', [Pack]),
          format(MS, "version('0.0.1').~n", []),
          ( integer(Layer) -> format(MS, 'layer(~w).~n', [Layer]) ; true ) ),
        close(MS)),
    format(atom(ModPath), '~w/~w.pl', [PrologDir, Pack]),
    setup_call_cleanup(open(ModPath, write, ModS),
        ( format(ModS, ':- module(~w, []).~n', [Pack]),
          forall(member(Imp, Imports),
                 format(ModS, ':- use_module(library(~w)).~n', [Imp])) ),
        close(ModS)).

% Make a unique throwaway base directory for one test's fixture repositories.
test_layer_tmp_base(Base) :-
    tmp_file(layer_reach, Base),
    make_directory_path(Base).

% Open the reach test block.
:- begin_tests(layer_reach).

% The offset convention lifts a local layer to a global coordinate; undeclared stays undeclared.
test(global_layer_offsets_a_coordinate) :-
    layer_global_layer(5, 100, G), assertion(G == 105),
    layer_global_layer(0, 0, G0), assertion(G0 == 0),
    layer_global_layer(undeclared, 100, U), assertion(U == undeclared).

% A cross-repository upward edge that per-repo namespaces HIDE is caught under a global coordinate.
test(cross_repo_global_coordinate_catches_hidden_upward_edge) :-
    test_layer_tmp_base(Base),
    format(atom(RepoA), '~w/repoA', [Base]), format(atom(RepoB), '~w/repoB', [Base]),
    make_directory_path(RepoA), make_directory_path(RepoB),
    % repoA's a_pack is local layer 5 and imports repoB's b_pack (local layer 2).
    test_layer_make_fixture_pack(RepoA, a_pack, 5, [b_pack]),
    test_layer_make_fixture_pack(RepoB, b_pack, 2, []),
    % Per-repo namespaces (both offset 0): 5 -> 2 looks downward, so NO violation is seen.
    layer_check_dirs([dir(RepoA, 0), dir(RepoB, 0)], V0),
    assertion(V0 == []),
    % Under a global coordinate (repoB stacked at +100): a_pack 5 -> b_pack 102, an UPWARD edge.
    layer_check_dirs([dir(RepoA, 0), dir(RepoB, 100)], V1),
    assertion(V1 \== []).

% Scanning one directory as a single-element union equals the plain single-dir scan (reduction).
test(single_dir_union_reduces_to_plain_scan) :-
    test_layer_tmp_base(Base),
    format(atom(Repo), '~w/solo', [Base]), make_directory_path(Repo),
    test_layer_make_fixture_pack(Repo, only_pack, 1, []),
    layer_check_dirs([dir(Repo, 0)], V), assertion(V == []),
    layer_scan_dirs([dir(Repo, 0)], Nodes, _),
    assertion(memberchk(node(only_pack, 1, _), Nodes)).

% The adoption report counts declared packs out of the total (the N3 coverage number).
test(adoption_reports_a_coverage_number) :-
    test_layer_tmp_base(Base),
    format(atom(Repo), '~w/adopt', [Base]), make_directory_path(Repo),
    test_layer_make_fixture_pack(Repo, declared_one, 0, []),
    test_layer_make_fixture_pack(Repo, declared_two, 1, []),
    test_layer_make_fixture_pack(Repo, undeclared_one, none, []),
    layer_adoption(Repo, Declared, Total, Fraction),
    assertion(Declared == 2), assertion(Total == 3),
    assertion(Fraction < 1.0).

% Intra-pack: a call to a strictly-higher-rank sub-module is an upward-call violation (LOOPS-1).
% Convention: a higher rank is more abstract; a call must go to an equal-or-lower rank.
test(submodule_upward_call_is_flagged) :-
    % A pipeline whose calls descend the ranks (3 -> 2 -> 1) is clean.
    Subs = [ submodule(intake, 3, [compare], t_intake),
             submodule(compare, 2, [guard], t_compare),
             submodule(guard, 1, [], t_guard) ],
    layer_submodule_violations(Subs, V),
    assertion(V == []),
    % Now make guard(1) call intake(3): an upward call inside the pack.
    Bad = [ submodule(guard, 1, [intake], t_guard),
            submodule(intake, 3, [], t_intake) ],
    layer_submodule_violations(Bad, BadV),
    assertion(memberchk(violation(upward_call, from(guard, 1), to(intake, 3)), BadV)).

% Intra-pack: a call to a sub-module OUTSIDE the declared set crosses the boundary (LOOPS-2).
test(submodule_unknown_callee_is_flagged) :-
    Subs = [ submodule(intake, 1, [ghost], t_intake) ],   % ghost is not a declared sub-module
    layer_submodule_violations(Subs, V),
    assertion(memberchk(violation(unknown_callee, from(intake), to(ghost)), V)).

% Intra-pack: a sub-module that names no test target is reported untestable (LOOPS-3).
test(submodule_without_test_target_is_reported) :-
    Subs = [ submodule(intake, 1, [], t_intake),
             submodule(compare, 2, [], none) ],
    layer_submodule_untested(Subs, Untested),
    assertion(Untested == [compare]).

% Close the reach test block.
:- end_tests(layer_reach).

% ---------------------------------------------------------------------------
% BINDING FRESHNESS (N7, Wave 10 Stage 9)
% ---------------------------------------------------------------------------

% Build a stratum fixture pack that declares a stratum and (optionally) a direct ordinal.
test_layer_make_stratum_pack(BaseDir, Pack, Stratum, Ordinal) :-
    format(atom(PackDir), '~w/~w', [BaseDir, Pack]),
    format(atom(PrologDir), '~w/prolog', [PackDir]),
    make_directory_path(PrologDir),
    format(atom(ManifestPath), '~w/pack.pl', [PackDir]),
    setup_call_cleanup(open(ManifestPath, write, MS),
        ( format(MS, 'name(~w).~n', [Pack]),
          format(MS, "version('0.0.1').~n", []),
          format(MS, 'stratum(~w).~n', [Stratum]),
          ( integer(Ordinal) -> format(MS, 'stratum_ordinal(~w).~n', [Ordinal]) ; true ) ),
        close(MS)),
    format(atom(ModPath), '~w/~w.pl', [PrologDir, Pack]),
    setup_call_cleanup(open(ModPath, write, ModS),
        format(ModS, ':- module(~w, []).~n', [Pack]), close(ModS)).

% Write one Causalontology stratum record (a JSON artifact) into a strata source directory.
test_layer_write_stratum_record(StrataDir, Label, Ordinal) :-
    make_directory_path(StrataDir),
    format(atom(Path), '~w/~w.json', [StrataDir, Label]),
    setup_call_cleanup(open(Path, write, S),
        format(S, '{"type":"stratum","label":"~w","ordinal":~w}~n', [Label, Ordinal]),
        close(S)).

% Open the freshness test block.
:- begin_tests(layer_freshness).

% A pack's direct stratum ordinal is read straight from its manifest (load-safe, no artifact).
test(pack_ordinal_read_directly) :-
    test_layer_tmp_base(Base),
    format(atom(Repo), '~w/direct', [Base]), make_directory_path(Repo),
    test_layer_make_stratum_pack(Repo, region_pack, region, 9),
    format(atom(PackDir), '~w/region_pack', [Repo]),
    layer_pack_ordinal(PackDir, Ordinal),
    assertion(Ordinal == 9).

% A pack that declares no direct ordinal simply has none (the read fails, not errors).
test(pack_without_direct_ordinal_fails) :-
    test_layer_tmp_base(Base),
    format(atom(Repo), '~w/nodirect', [Base]), make_directory_path(Repo),
    test_layer_make_stratum_pack(Repo, plain_pack, region, none),
    format(atom(PackDir), '~w/plain_pack', [Repo]),
    assertion(\+ layer_pack_ordinal(PackDir, _)).

% A pack whose direct ordinal disagrees with the artifact is flagged as a drift (stale artifact).
test(stale_artifact_is_flagged) :-
    test_layer_tmp_base(Base),
    format(atom(Repo), '~w/packs', [Base]), make_directory_path(Repo),
    format(atom(Strata), '~w/strata', [Base]),
    % The pack declares stratum region at ordinal 99, but the artifact says 9 — a drift.
    test_layer_make_stratum_pack(Repo, region_pack, region, 99),
    test_layer_write_stratum_record(Strata, region, 9),
    layer_binding_freshness(Repo, Strata, Drifts),
    assertion(Drifts == [drift(region, declared(99), artifact(9))]).

% A pack whose direct ordinal agrees with the artifact shows no drift.
test(fresh_artifact_shows_no_drift) :-
    test_layer_tmp_base(Base),
    format(atom(Repo), '~w/packs', [Base]), make_directory_path(Repo),
    format(atom(Strata), '~w/strata', [Base]),
    test_layer_make_stratum_pack(Repo, region_pack, region, 9),
    test_layer_write_stratum_record(Strata, region, 9),
    layer_binding_freshness(Repo, Strata, Drifts),
    assertion(Drifts == []).

% Close the freshness test block.
:- end_tests(layer_freshness).
