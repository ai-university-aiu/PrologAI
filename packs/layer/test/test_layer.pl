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
