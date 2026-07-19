/*  PrologAI — Strict Layer Rule construct  (WP-426, Layer 0)

    THE GAP THIS CLOSES (Ledger entry L4, the keystone).
    PrologAI rests on a strict layer rule: a lower layer may not depend on a
    higher one, so the static import graph is acyclic. Until now that rule was
    honoured by convention only — no pack could DECLARE its layer, nothing could
    CHECK the rule, and no violation was ever REPORTED. The prologai-loops spike
    had to hand-build its own static checker to get any guarantee at all. This
    pack is that missing construct, made first-class.

    WHAT IT PROVIDES.
      (1) DECLARE — a pack states its layer with a `layer(N)` fact in its own
          pack.pl manifest (beside name/version/requires), so the declaration
          lives in the pack and cannot drift into an external registry.
      (2) CHECK — given the declared layers and the ACTUAL dependency graph
          (parsed from every pack's real use_module(library(...)) directives),
          find any pack that depends on a strictly-higher-layer pack. Each
          violation names the rule, both packs, both layer numbers, and the
          breaking dependency in one readable line.
      (3) ENFORCE at load time — layer_enforce(strict) throws on any violation
          (so a `:- initialization(layer_enforce(strict))` refuses to finish
          loading a violating configuration); layer_enforce(report) lists
          violations without refusing, so adoption can be incremental.
      (4) CI — bin/check_layers.sh runs the check and exits non-zero on
          violation, zero on a clean configuration.

    INCREMENTAL ADOPTION. A pack with no `layer(N)` fact is UNDECLARED, not
    violating: it is reported as a gap to fill, never an error that breaks a
    working build. Only an edge between two DECLARED packs can be a violation.

    DEPENDENCIES. This construct sits beneath everything it governs: it imports
    only SWI-Prolog standard libraries (lists, apply, pcre, readutil), never the
    Lattice, the actors pack, or any Causalontology pack.

    L5 NOTE (investigated, reported honestly). The strict rule can also be
    eroded by an upward reference carried as DATA — a lower actor holding the
    literal address of a higher one (the spike's mailbox arm did exactly this).
    A load-time IMPORT checker cannot see such a reference: it is runtime data,
    possibly computed, and never appears in the static import graph. This pack
    ships a best-effort, opt-in lint (layer_data_references/2) that flags a
    quoted literal in a lower pack's source that embeds a higher pack's name —
    it catches the concrete case the spike cited, but a dynamic or computed
    address escapes it. L5 therefore remains PARTIALLY addressed by a heuristic
    lint and, for the general case, still open. See LEDGER.md.

    PUBLIC PREDICATES
      layer_of/2             +Pack, -Layer            declared layer of a pack
      layer_declared/2       ?Pack, ?Layer            enumerate declared packs
      layer_undeclared/1     ?Pack                    packs with no layer fact
      layer_graph_violations/2  +Nodes, -Violations   the pure violation core
      layer_scan/3           +PacksDir, -Nodes, -Undeclared   build the graph
      layer_check/1          -Violations              check the repo's packs dir
      layer_check_dir/2      +PacksDir, -Violations    check a given packs dir
      layer_report/0                                  print a human report
      layer_report_dir/1     +PacksDir                print a report for a dir
      layer_enforce/1        +Mode (strict|report)    load-time enforcement
      layer_enforce_dir/2    +PacksDir, +Mode         enforce over a given dir
      layer_library_imports/2  +File, -LibNames       library imports of a file
      layer_import_specs/2   +File, -RawSpecs         raw import argument text
      layer_data_references/2  +PacksDir, -Suspects   L5 heuristic data lint
      layer_default_packs_dir/1  -PacksDir            the repo's packs directory
*/

% Declare this file as the 'layer' module and list its exported predicates.
:- module(layer, [
    % layer_of/2: the declared layer of a pack (fails if the pack is undeclared).
    layer_of/2,
    % layer_declared/2: enumerate every pack that declares a numeric layer.
    layer_declared/2,
    % layer_undeclared/1: enumerate every pack that ships no layer(N) fact.
    layer_undeclared/1,
    % layer_graph_violations/2: the pure core — upward edges from a node set.
    layer_graph_violations/2,
    % layer_scan/3: build the node set and the undeclared list from a packs dir.
    layer_scan/3,
    % layer_check/1: violations for the repository's own packs directory.
    layer_check/1,
    % layer_check_dir/2: violations for an arbitrary packs directory.
    layer_check_dir/2,
    % layer_report/0: print a readable report for the repo's packs directory.
    layer_report/0,
    % layer_report_dir/1: print a readable report for a given packs directory.
    layer_report_dir/1,
    % layer_enforce/1: enforce the rule at load time in strict or report mode.
    layer_enforce/1,
    % layer_enforce_dir/2: enforce the rule over an explicit packs directory.
    layer_enforce_dir/2,
    % layer_library_imports/2: the library(...) imports named in one source file.
    layer_library_imports/2,
    % layer_import_specs/2: the raw first-argument text of every import directive.
    layer_import_specs/2,
    % layer_data_references/2: the L5 heuristic lint over a packs directory.
    layer_data_references/2,
    % layer_data_references_files/2: the L5 heuristic lint over explicit files.
    layer_data_references_files/2,
    % layer_default_packs_dir/1: locate the repository's packs directory.
    layer_default_packs_dir/1,
    % --- Layer-to-stratum BINDING (N6, closes STRATA-3) — additive to the above ---
    % layer_pack_stratum/2: the stratum a pack declares (or 'unbound').
    layer_pack_stratum/2,
    % layer_stratum_ordinals/2: read stratum label-to-ordinal pairs from stratum records.
    layer_stratum_ordinals/2,
    % layer_bind_scan/4: build the bound-node set and the unbound-gap list.
    layer_bind_scan/4,
    % layer_binding_violations/2: the pure order-preserving binding-violation core.
    layer_binding_violations/2,
    % layer_binding_violation_line/2: render one binding violation as a readable line.
    layer_binding_violation_line/2,
    % layer_bind_check_dir/3: binding violations for a packs dir against a strata source.
    layer_bind_check_dir/3,
    % layer_bind_report_dir/2: print a readable binding report.
    layer_bind_report_dir/2,
    % layer_bind_enforce_dir/3: enforce the binding at load in strict or report mode.
    layer_bind_enforce_dir/3,
    % --- The layer construct's REACH (Wave 10 Stage 6, closes Theme E) — additive ---
    % layer_global_layer/3: a local layer plus a per-repository offset = a global coordinate.
    layer_global_layer/3,
    % layer_scan_dirs/3: union several packs directories under global coordinates.
    layer_scan_dirs/3,
    % layer_check_dirs/2: cross-repository violations over the unioned node set.
    layer_check_dirs/2,
    % layer_report_dirs/1: print a readable cross-repository report.
    layer_report_dirs/1,
    % layer_adoption/4: how many packs in a directory declare a layer (the N3 coverage report).
    layer_adoption/4,
    % layer_submodule_violations/2: the intra-pack sub-module layering + coupling check.
    layer_submodule_violations/2,
    % layer_submodule_untested/2: the intra-pack sub-modules that name no test target.
    layer_submodule_untested/2,
    % --- Binding freshness (N7, Wave 10 Stage 9) — additive to the N6 binding ---
    % layer_pack_ordinal/2: read a stratum ordinal DIRECTLY from a pack's manifest (load-safe).
    layer_pack_ordinal/2,
    % layer_binding_freshness/3: flag a pack whose manifest ordinal disagrees with the artifact.
    layer_binding_freshness/3
]).

% Import list utilities [member/2, memberchk/2, sort/4, exclude/3] from library(lists).
:- use_module(library(lists), [member/2, memberchk/2]).
% Import [exclude/3, include/3, maplist/2] from the apply library.
:- use_module(library(apply), [exclude/3, include/3, maplist/2]).
% Import [re_replace/4, re_foldl/6] from the pcre (Perl-compatible regex) library.
:- use_module(library(pcre), [re_foldl/6, re_replace/4]).
% Import [read_file_to_string/3] from the readutil library.
:- use_module(library(readutil), [read_file_to_string/3]).
% Import [json_read_dict/2] from the http/json library — used ONLY by the additive
% layer-to-stratum binding below, to read stratum ordinals from the authoritative
% structure records. It is a SWI-Prolog standard library, so this construct still
% depends on nothing but SWI stdlib (never the Lattice, actors, or a Causalontology pack).
:- use_module(library(http/json), [json_read_dict/2]).

% ---------------------------------------------------------------------------
% The pure violation core — no input/output, fully testable in isolation.
% ---------------------------------------------------------------------------

% A node is node(PackName, Layer, ImportedPackNames); Layer is an integer for a
% declared pack or the atom 'undeclared' for a pack with no layer(N) fact.

% Define layer_graph_violations/2: collect every upward inter-pack edge.
layer_graph_violations(Nodes, Violations) :-
    % Gather one violation term per edge that climbs from a lower to a higher layer.
    findall(
        % The glass-box violation term: rule name, both endpoints, and the edge.
        violation(upward_dependency,
                  from(From, FromLayer), to(To, ToLayer),
                  via(use_module(library(To)))),
        % Enumerate a declared source pack and each of the packs it imports.
        ( member(node(From, FromLayer, Imports), Nodes),
          % Only a pack with a numeric layer can be the source of a violation.
          integer(FromLayer),
          % Consider each imported pack name in turn.
          member(To, Imports),
          % Ignore a pack importing itself (an intra-pack file, not an edge).
          To \== From,
          % The imported pack must itself be declared with a numeric layer.
          layer_lookup(Nodes, To, ToLayer),
          integer(ToLayer),
          % The rule is broken exactly when the target sits strictly higher.
          ToLayer > FromLayer ),
        % Bind the collected list to Violations (empty when the graph is clean).
        Violations).

% Define layer_lookup/3: find the declared layer of a node by name.
layer_lookup(Nodes, Name, Layer) :-
    % Succeed with the layer recorded for the first node of this name.
    memberchk(node(Name, Layer, _), Nodes).

% Define layer_violation_line/2: render one violation as a readable English line.
layer_violation_line(violation(upward_dependency, from(From, FL), to(To, TL), via(Via)),
                     Line) :-
    % Render the breaking dependency term to an atom for display.
    term_to_atom(Via, ViaAtom),
    % Compose the one-line, glass-box explanation of the broken rule.
    format(atom(Line),
           "layer_rule violation: pack '~w' (layer ~w) depends on higher pack '~w' (layer ~w) via ~w",
           [From, FL, To, TL, ViaAtom]).

% ---------------------------------------------------------------------------
% Reading a single source file's imports.
% ---------------------------------------------------------------------------

% Define layer_code_text/2: read a file and drop its comments, leaving code.
% Both block comments (/* ... */) and whole-line % comments are removed, so a
% mention of use_module or a quoted address that lives in prose can never be
% mistaken for real code.
layer_code_text(File, Code) :-
    % Read the whole file into one string.
    read_file_to_string(File, Raw, []),
    % Remove every /* ... */ block comment (dot-matches-newline, global).
    re_replace("(?s)/\\*.*?\\*/"/g, "", Raw, NoBlocks),
    % Split what remains into individual lines.
    split_string(NoBlocks, "\n", "", Lines),
    % Keep only the lines that are not whole-line % comments.
    exclude(layer_is_comment_line, Lines, CodeLines),
    % Rejoin the surviving code lines with newlines into one string.
    atomic_list_concat(CodeLines, "\n", Code).

% Define layer_is_comment_line/1: true when a line's first non-space char is %.
layer_is_comment_line(Line) :-
    % Strip leading and trailing whitespace from the line.
    normalize_space(string(Trimmed), Line),
    % A comment line begins with the percent sign.
    string_concat("%", _, Trimmed).

% Define layer_library_imports/2: the library(NAME) names imported by a file.
layer_library_imports(File, Names) :-
    % Take the file's code with comment lines removed.
    layer_code_text(File, Code),
    % Fold the use_module(library(NAME)) / ensure_loaded(library(NAME)) matches,
    % converting each captured string to an atom so it unifies with pack names.
    re_foldl([M,A,[N|A]]>>(get_dict(1, M, S), atom_string(N, S)),
             "(?:use_module|ensure_loaded)\\(\\s*library\\(\\s*([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\)",
             Code, [], Raw, []),
    % Sort and deduplicate the collected library names.
    sort(Raw, Names).

% Define layer_import_specs/2: the raw first-argument text of import directives.
layer_import_specs(File, Specs) :-
    % Take the file's code with comment lines removed.
    layer_code_text(File, Code),
    % Capture the argument run after use_module( / ensure_loaded( up to , or ),
    % converting each captured string to an atom for uniform substring matching.
    re_foldl([M,A,[Spec|A]]>>(get_dict(1, M, S), atom_string(Spec, S)),
             "(?:use_module|ensure_loaded)\\(\\s*([^,\\)\\n]+)",
             Code, [], Raw, []),
    % Sort and deduplicate the raw specs.
    sort(Raw, Specs).

% ---------------------------------------------------------------------------
% Reading a pack manifest.
% ---------------------------------------------------------------------------

% Define layer_pack_layer/2: the declared layer of a pack, or 'undeclared'.
layer_pack_layer(PackDir, Layer) :-
    % Point at the pack's manifest file.
    atomic_list_concat([PackDir, '/pack.pl'], ManifestPath),
    % Fall to 'undeclared' if the manifest is missing or has no layer fact.
    ( exists_file(ManifestPath),
      layer_manifest_int(ManifestPath, layer, N)
    % A numeric layer was found: use it.
    ->  Layer = N
    % No layer fact: the pack is undeclared.
    ;   Layer = undeclared ).

% Define layer_manifest_int/3: read an integer-valued manifest fact by functor.
layer_manifest_int(ManifestPath, Functor, Int) :-
    % Take the manifest's code with comment lines removed.
    layer_code_text(ManifestPath, Code),
    % Build the pattern FUNCTOR( <digits> ) matching only the real code line.
    format(atom(Pattern), "~w\\(\\s*(\\d+)\\s*\\)", [Functor]),
    % Find the first digit run captured by the pattern.
    re_foldl([M,A,[D|A]]>>get_dict(1, M, D), Pattern, Code, [], Digits, []),
    % There must be at least one match to succeed.
    Digits = [First|_],
    % Convert the captured digit string to an integer.
    ( number_string(Int, First) -> true ; atom_number(First, Int) ).

% ---------------------------------------------------------------------------
% Building the whole graph from a packs directory.
% ---------------------------------------------------------------------------

% Define layer_scan/3: build the node set and the undeclared list from a dir.
layer_scan(PacksDir, Nodes, Undeclared) :-
    % Enumerate the immediate sub-directories of the packs directory.
    layer_pack_dirs(PacksDir, PackDirs),
    % Build the library-file-to-owning-pack map across every pack.
    layer_lib_owner_map(PackDirs, OwnerPairs),
    % Turn each pack directory into a node(Name, Layer, ImportedPacks) term.
    maplist(layer_dir_node(OwnerPairs), PackDirs, Nodes),
    % A pack whose layer is 'undeclared' is collected into the gap list.
    findall(Name,
            member(node(Name, undeclared, _), Nodes),
            UndeclaredRaw),
    % Sort the undeclared names for a stable report.
    sort(UndeclaredRaw, Undeclared).

% Define layer_pack_dirs/2: the list of pack directories under a packs dir.
layer_pack_dirs(PacksDir, PackDirs) :-
    % Build a glob for every immediate sub-directory.
    atomic_list_concat([PacksDir, '/*'], Glob),
    % Expand the glob to concrete paths.
    expand_file_name(Glob, Entries),
    % Keep only the entries that are directories containing a pack.pl.
    include(layer_is_pack_dir, Entries, PackDirs).

% Define layer_is_pack_dir/1: true when a path is a directory with a pack.pl.
layer_is_pack_dir(Path) :-
    % The path must be a directory.
    exists_directory(Path),
    % And it must contain a pack manifest.
    atomic_list_concat([Path, '/pack.pl'], Manifest),
    % Confirm the manifest file exists.
    exists_file(Manifest).

% Define layer_lib_owner_map/2: map every prolog file basename to its pack name.
layer_lib_owner_map(PackDirs, Pairs) :-
    % For each pack directory, list its prolog files as basename-owner pairs.
    findall(Base-Pack,
            ( member(Dir, PackDirs),
              % The pack's name is the directory's base name.
              file_base_name(Dir, Pack),
              % Enumerate the pack's prolog source files.
              atomic_list_concat([Dir, '/prolog/*.pl'], Glob),
              expand_file_name(Glob, Files),
              member(File, Files),
              % Reduce each file to its module base name (drop the .pl).
              file_base_name(File, FileBase),
              file_name_extension(Base, pl, FileBase) ),
            Pairs).

% Define layer_dir_node/3: build one node term for a pack directory.
layer_dir_node(OwnerPairs, Dir, node(Pack, Layer, ImportedPacks)) :-
    % The pack's name is the directory's base name.
    file_base_name(Dir, Pack),
    % Read the pack's declared layer (or 'undeclared').
    layer_pack_layer(Dir, Layer),
    % Collect every library name imported across the pack's source files.
    atomic_list_concat([Dir, '/prolog/*.pl'], Glob),
    expand_file_name(Glob, Files),
    layer_files_libraries(Files, LibNames),
    % Map each imported library name to the pack that owns it, if any.
    findall(Owner,
            ( member(Lib, LibNames),
              memberchk(Lib-Owner, OwnerPairs),
              % Exclude a pack's imports of its own files (not an inter-pack edge).
              Owner \== Pack ),
            OwnersRaw),
    % Sort and deduplicate the imported pack names.
    sort(OwnersRaw, ImportedPacks).

% Define layer_files_libraries/2: union of library imports across a file list.
layer_files_libraries(Files, LibNames) :-
    % Collect the library imports of every file into one flat list.
    findall(Name,
            ( member(File, Files),
              layer_library_imports(File, Names),
              member(Name, Names) ),
            Raw),
    % Sort and deduplicate the union.
    sort(Raw, LibNames).

% ---------------------------------------------------------------------------
% The declared / undeclared / of interface, over the repo's own packs.
% ---------------------------------------------------------------------------

% Define layer_of/2: the declared numeric layer of a pack in the repo.
layer_of(Pack, Layer) :-
    % Locate the repository's packs directory.
    layer_default_packs_dir(PacksDir),
    % Read that pack's declared layer from its manifest.
    atomic_list_concat([PacksDir, '/', Pack], Dir),
    layer_pack_layer(Dir, Layer),
    % A numeric layer is required; an undeclared pack fails here.
    integer(Layer).

% Define layer_declared/2: enumerate packs that declare a numeric layer.
layer_declared(Pack, Layer) :-
    % Scan the repository's packs directory into nodes.
    layer_default_packs_dir(PacksDir),
    layer_scan(PacksDir, Nodes, _),
    % Yield each pack whose layer is an integer.
    member(node(Pack, Layer, _), Nodes),
    integer(Layer).

% Define layer_undeclared/1: enumerate packs with no layer(N) fact.
layer_undeclared(Pack) :-
    % Scan the repository's packs directory.
    layer_default_packs_dir(PacksDir),
    layer_scan(PacksDir, _, Undeclared),
    % Yield each undeclared pack name.
    member(Pack, Undeclared).

% ---------------------------------------------------------------------------
% Check / report / enforce.
% ---------------------------------------------------------------------------

% Define layer_check/1: violations for the repository's own packs directory.
layer_check(Violations) :-
    % Locate the repository's packs directory.
    layer_default_packs_dir(PacksDir),
    % Delegate to the directory-scoped check.
    layer_check_dir(PacksDir, Violations).

% Define layer_check_dir/2: violations for an arbitrary packs directory.
layer_check_dir(PacksDir, Violations) :-
    % Build the node set for the directory.
    layer_scan(PacksDir, Nodes, _),
    % Run the pure violation core over the node set.
    layer_graph_violations(Nodes, Violations).

% Define layer_report/0: print a readable report for the repo's packs dir.
layer_report :-
    % Locate the repository's packs directory and report on it.
    layer_default_packs_dir(PacksDir),
    layer_report_dir(PacksDir).

% Define layer_report_dir/1: print declared layers, undeclared gaps, violations.
layer_report_dir(PacksDir) :-
    % Build the node set and the undeclared gap list.
    layer_scan(PacksDir, Nodes, Undeclared),
    % Compute the violations from the node set.
    layer_graph_violations(Nodes, Violations),
    % Print a header for the layer report.
    format("~n=== Strict Layer Rule report (~w) ===~n", [PacksDir]),
    % Collect the packs that declare a numeric layer, sorted by layer then name.
    findall(L-P, ( member(node(P, L, _), Nodes), integer(L) ), DeclPairs),
    keysort(DeclPairs, DeclSorted),
    % Report how many packs declare a layer.
    length(DeclSorted, DeclCount),
    format("Declared packs: ~w~n", [DeclCount]),
    % Print each declared pack with its layer.
    forall(member(L-P, DeclSorted),
           format("  layer ~w  ~w~n", [L, P])),
    % Report the undeclared packs as gaps to fill (never errors).
    length(Undeclared, UndeclCount),
    format("Undeclared packs (gaps, not violations): ~w~n", [UndeclCount]),
    % Print each violation on its own readable line, or state that none were found.
    ( Violations == []
    ->  format("Violations: 0 — the configuration honours the strict layer rule.~n", [])
    ;   length(Violations, VCount),
        format("Violations: ~w~n", [VCount]),
        forall(member(V, Violations),
               ( layer_violation_line(V, Line), format("  ~w~n", [Line]) )) ).

% Define layer_enforce/1: enforce the rule at load time (strict or report mode).
layer_enforce(Mode) :-
    % Locate the repository's packs directory to enforce over.
    layer_default_packs_dir(PacksDir),
    % Delegate to the directory-scoped enforcement over the repo's own packs.
    layer_enforce_dir(PacksDir, Mode).

% Define layer_enforce_dir/2: enforce the rule over an explicit packs directory.
% This is the sibling of layer_check_dir/2 and layer_report_dir/1: it carries the
% same strict/report enforcement but over any packs directory, so the actual
% throw-on-violation path can be exercised against a violating configuration.
layer_enforce_dir(PacksDir, Mode) :-
    % Compute the violations once for the given packs directory.
    layer_check_dir(PacksDir, Violations),
    % Print the report so the outcome is visible either way.
    layer_report_dir(PacksDir),
    % Branch on the requested enforcement mode.
    ( Mode == strict
    % Strict mode: a non-empty violation list refuses the load by throwing.
    ->  ( Violations == []
        ->  true
        ;   throw(error(layer_rule_violation(Violations), layer_enforce/1)) )
    % Report mode: never refuse; violations were already printed above.
    ;   Mode == report
    ->  true
    % Any other mode is a usage error.
    ;   throw(error(domain_error(layer_enforce_mode, Mode), layer_enforce/1)) ).

% ---------------------------------------------------------------------------
% Locating the repository's packs directory.
% ---------------------------------------------------------------------------

% Define layer_default_packs_dir/1: the packs/ directory that contains this pack.
layer_default_packs_dir(PacksDir) :-
    % Find the absolute path of this very source file.
    module_property(layer, file(Self)),
    % This file is <packs>/layer/prolog/layer.pl; climb to the prolog directory.
    file_directory_name(Self, PrologDir),
    % Climb to the layer pack directory.
    file_directory_name(PrologDir, LayerPackDir),
    % Climb once more to reach the packs directory that holds every pack.
    file_directory_name(LayerPackDir, PacksDir).

% ---------------------------------------------------------------------------
% L5 heuristic lint — an upward reference carried as DATA (best-effort).
% ---------------------------------------------------------------------------

% Define layer_data_references/2: flag a lower pack's literal that names a higher pack.
% This is a HEURISTIC, not a guarantee: it catches a quoted address literal that
% embeds a higher-layer pack's name (the concrete case the spike's mailbox arm
% showed), but a computed or dynamically built address escapes it. See LEDGER.md.
layer_data_references(PacksDir, Suspects) :-
    % Build the node set so declared layers are known.
    layer_scan(PacksDir, Nodes, _),
    % Keep only the packs that declare a numeric layer.
    findall(P-L, ( member(node(P, L, _), Nodes), integer(L) ), DeclPairs),
    % For each lower pack, scan its source for a literal naming a higher pack.
    findall(
        % A suspect names the lower pack, the higher pack, and the source file.
        data_reference(from(Low, LowL), mentions(High, HighL), file(File)),
        ( member(Low-LowL, DeclPairs),
          member(High-HighL, DeclPairs),
          % Only an upward mention (lower source naming a higher pack) is suspect.
          HighL > LowL,
          % Enumerate the lower pack's source files.
          atomic_list_concat([PacksDir, '/', Low, '/prolog/*.pl'], Glob),
          expand_file_name(Glob, Files),
          member(File, Files),
          % Flag a quoted literal in that file that embeds the higher pack's name.
          layer_file_mentions_literal(File, High) ),
        Raw),
    % Sort and deduplicate the suspect list.
    sort(Raw, Suspects).

% Define layer_data_references_files/2: the L5 heuristic lint over explicit files.
% FileSpecs is a list of dfile(Name, Layer, Path). A suspect is a lower-layer
% file that quotes a higher-layer node's name. Used to replay the spike's arms
% directly on their source, without those files needing to be packs.
layer_data_references_files(FileSpecs, Suspects) :-
    % Enumerate every ordered pair of a lower and a higher named file.
    findall(
        % The suspect names the lower file, the higher file, and the path.
        data_reference(from(Low, LowL), mentions(High, HighL), file(Path)),
        ( member(dfile(Low, LowL, Path), FileSpecs),
          member(dfile(High, HighL, _), FileSpecs),
          % Only an upward mention (lower source naming a higher node) is suspect.
          HighL > LowL,
          % Flag a quoted literal in the lower file that embeds the higher name.
          layer_file_mentions_literal(Path, High) ),
        Raw),
    % Sort and deduplicate the suspect list.
    sort(Raw, Suspects).

% Define layer_file_mentions_literal/2: true when a code line quotes a token.
layer_file_mentions_literal(File, Token) :-
    % Take the file's code with comment lines removed.
    layer_code_text(File, Code),
    % Build a pattern for the token appearing inside a single- or double-quoted
    % literal (a naive but useful sign of an address/name carried as data).
    format(atom(Pattern), "['\"][^'\"]*~w[^'\"]*['\"]", [Token]),
    % Succeed if the pattern matches anywhere in the code.
    re_foldl([_,A,[x|A]]>>true, Pattern, Code, [], Hits, []),
    % Require at least one hit.
    Hits \== [].

% ---------------------------------------------------------------------------
% Layer-to-stratum BINDING (PrologAI Ledger N6 — closes the strata arm's STRATA-3).
%
% THE GAP (STRATA-3). A pack can DECLARE its layer (the rule above, L4), and the
% Causalontology data model has strata with ordinals, but nothing binds the two:
% a pack could declare a layer that contradicts the ordinal of the stratum it
% claims to be, and L4 — which checks that layers are ORDERED correctly, not that
% a layer EQUALS the ordinal it should — would happily pass. The Wave 3 verdict's
% winning decomposition (one pack per stratum) rests on "pack layer tracks stratum
% ordinal", maintained by hand today. This construct makes that binding a checked,
% load-time invariant, exactly as L4 made the layer rule a language feature.
%
% THE RULE. It is ORDER-PRESERVING, not equality (stratum ordinals are sparse —
% 4, 6, 7, 9, 14 — while layers are dense 0,1,2,...): for any two BOUND packs,
% a lower stratum ordinal must not carry a higher layer, and two packs at the same
% ordinal must share a layer. Layer numbers need not equal ordinal numbers; the
% layer ASSIGNMENT and the stratum ORDERING must agree in direction and in ties.
%
% THE SKIP CASE. A downward reference across a large ordinal gap (a high stratum
% depending on a much lower one — the cortisol skip) is LEGAL: the binding checks
% layer/ordinal CONSISTENCY, not dependency gaps, so it never flags a legitimate
% downward skip. The upward EDGE (a low ordinal depending on a high one) is caught
% by L4, and the binding additionally stops that upward edge being disguised as
% downward by a mis-declared layer.
%
% ADOPTION IS INCREMENTAL. A pack that declares a layer but NO stratum is UNBOUND,
% reported as a gap to fill, never an error — the same stigmergic pattern L4 uses
% for undeclared layers. The declaration is one cheap fact, stratum(Label), in the
% pack.pl beside layer(N), so it cannot drift into an external registry.
% ---------------------------------------------------------------------------

% Define layer_pack_stratum/2: the stratum a pack declares in its manifest, or 'unbound'.
layer_pack_stratum(PackDir, Stratum) :-
    % Point at the pack's manifest file.
    atomic_list_concat([PackDir, '/pack.pl'], ManifestPath),
    % Read the stratum(Label) fact if present; otherwise the pack is unbound.
    ( exists_file(ManifestPath),
      layer_manifest_atom(ManifestPath, stratum, S)
    % A stratum label was declared: use it.
    ->  Stratum = S
    % No stratum fact: the pack is unbound (a gap, not an error).
    ;   Stratum = unbound ).

% Define layer_manifest_atom/3: read a whole-word-atom-valued manifest fact by functor.
% The sibling of layer_manifest_int/3 (which reads integer-valued facts like layer(2)):
% this reads an atom-valued fact like stratum(macromolecular), matching a lowercase
% snake_case word so it accepts only a valid unquoted Prolog atom.
layer_manifest_atom(ManifestPath, Functor, Atom) :-
    % Take the manifest's code with comment lines removed.
    layer_code_text(ManifestPath, Code),
    % Build the pattern FUNCTOR( <lowercase snake_case word> ) matching a real code line.
    format(atom(Pattern), "~w\\(\\s*([a-z][a-z0-9_]*)\\s*\\)", [Functor]),
    % Capture each word the pattern matches.
    re_foldl([M,A,[W|A]]>>get_dict(1, M, W), Pattern, Code, [], Words, []),
    % There must be at least one match to succeed.
    Words = [First|_],
    % Convert the captured word string to an atom.
    atom_string(Atom, First).

% Define layer_stratum_ordinals/2: read stratum Label-Ordinal pairs from a strata source.
% The StrataSource is a directory of Causalontology structure records (JSON), the
% AUTHORITATIVE place stratum ordinals already live; a pack cannot claim an ordinal
% the data disagrees with, because the ordinal is read from the record, not the pack.
layer_stratum_ordinals(StrataSource, Pairs) :-
    % Glob every JSON record file in the strata source directory.
    atomic_list_concat([StrataSource, '/*.json'], Glob),
    % Expand the glob to concrete record paths.
    expand_file_name(Glob, Files),
    % Keep the label-ordinal of every record whose kind is 'stratum'.
    findall(Label-Ordinal,
            ( member(File, Files),
              % Read the record as a dict.
              layer_read_json_dict(File, Dict),
              % Only stratum records carry a stratum ordinal (accept string or atom kind).
              get_dict(type, Dict, TypeVal), layer_is_stratum_type(TypeVal),
              % Read the stratum's label and its ordinal.
              get_dict(label, Dict, LabelVal),
              get_dict(ordinal, Dict, Ordinal),
              integer(Ordinal),
              % Normalise the label to an atom to match the pack's stratum(Label) declaration.
              ( atom(LabelVal) -> Label = LabelVal ; atom_string(Label, LabelVal) ) ),
            Raw),
    % Sort and deduplicate the pairs.
    sort(Raw, Pairs).

% Define layer_is_stratum_type/1: true when a record's type value names the stratum kind.
layer_is_stratum_type("stratum").
layer_is_stratum_type(stratum).

% Define layer_read_json_dict/2: read one JSON object file into a dict.
layer_read_json_dict(File, Dict) :-
    % Open the file, read one JSON value as a dict, and always close the stream.
    setup_call_cleanup(open(File, read, Stream),
                       json_read_dict(Stream, Dict),
                       close(Stream)).

% Define layer_bind_scan/4: build the bound-node set and the unbound-gap list.
% A bnode(Pack, Layer, Stratum, Ordinal) is a pack that declares a numeric layer AND
% a stratum whose ordinal is known from the strata source. An unbound(Pack, Layer,
% Reason) is a pack with a numeric layer but no usable stratum binding — a gap.
layer_bind_scan(PacksDir, OrdinalMap, BoundNodes, Unbound) :-
    % Enumerate the pack directories under the packs dir.
    layer_pack_dirs(PacksDir, PackDirs),
    % Collect the bound nodes: a numeric layer plus a stratum with a known ordinal.
    findall(bnode(Pack, Layer, Stratum, Ordinal),
            ( member(Dir, PackDirs),
              file_base_name(Dir, Pack),
              layer_pack_layer(Dir, Layer), integer(Layer),
              layer_pack_stratum(Dir, Stratum), Stratum \== unbound,
              memberchk(Stratum-Ordinal, OrdinalMap) ),
            BoundRaw),
    % Sort and deduplicate the bound nodes.
    sort(BoundRaw, BoundNodes),
    % Collect the unbound gaps: a numeric layer but no usable stratum binding.
    findall(unbound(Pack, Layer, Reason),
            ( member(Dir, PackDirs),
              file_base_name(Dir, Pack),
              layer_pack_layer(Dir, Layer), integer(Layer),
              layer_pack_stratum(Dir, Stratum),
              % Distinguish "no stratum declared" from "stratum ordinal unknown to the source".
              ( Stratum == unbound
              ->  Reason = no_stratum_declared
              ;   \+ memberchk(Stratum-_, OrdinalMap)
              ->  Reason = stratum_ordinal_unknown(Stratum)
              ;   fail ) ),
            UnboundRaw),
    % Sort and deduplicate the unbound gaps.
    sort(UnboundRaw, Unbound).

% Define layer_binding_violations/2: the pure order-preserving binding-violation core.
% No input/output, fully testable in isolation. A violation is any pair of bound
% packs whose LAYER order contradicts their stratum ORDINAL order, or that share an
% ordinal but not a layer.
layer_binding_violations(BoundNodes, Violations) :-
    % Gather one violation term per offending unordered pair.
    findall(
        % The glass-box violation term: both bound packs and the reason they disagree.
        binding_violation(pack(A, LA, SA, OA), pack(B, LB, SB, OB), Reason),
        ( % Enumerate an ordered pair of distinct bound packs (by name, once each).
          member(bnode(A, LA, SA, OA), BoundNodes),
          member(bnode(B, LB, SB, OB), BoundNodes),
          A @< B,
          % The pair breaks the order-preserving rule.
          layer_binding_pair_bad(OA, LA, OB, LB, Reason) ),
        Violations).

% Define layer_binding_pair_bad/5: true iff two bound packs break order-preservation.
layer_binding_pair_bad(OA, LA, OB, LB, finer_stratum_has_higher_layer) :-
    % A finer stratum (lower ordinal) must not carry a higher layer.
    OA < OB, LA > LB, !.
layer_binding_pair_bad(OA, LA, OB, LB, coarser_stratum_has_lower_layer) :-
    % A coarser stratum (higher ordinal) must not carry a lower layer.
    OA > OB, LA < LB, !.
layer_binding_pair_bad(OA, LA, OB, LB, same_stratum_ordinal_needs_same_layer) :-
    % Two packs at the same stratum ordinal must share a layer.
    OA =:= OB, LA =\= LB.

% Define layer_binding_violation_line/2: render one binding violation as a readable line.
layer_binding_violation_line(
        binding_violation(pack(A, LA, SA, OA), pack(B, LB, SB, OB), Reason), Line) :-
    % Compose the one-line, glass-box explanation naming both packs, layers, strata, and ordinals.
    format(atom(Line),
      "binding_rule violation (~w): pack '~w' (layer ~w, stratum '~w' ordinal ~w) and pack '~w' (layer ~w, stratum '~w' ordinal ~w) — the layer order contradicts the stratum ordinal order",
      [Reason, A, LA, SA, OA, B, LB, SB, OB]).

% Define layer_bind_check_dir/3: binding violations for a packs dir against a strata source.
layer_bind_check_dir(PacksDir, StrataSource, Violations) :-
    % Read the authoritative stratum ordinals.
    layer_stratum_ordinals(StrataSource, OrdinalMap),
    % Build the bound-node set for the packs directory.
    layer_bind_scan(PacksDir, OrdinalMap, BoundNodes, _),
    % Run the pure binding-violation core over the bound nodes.
    layer_binding_violations(BoundNodes, Violations).

% Define layer_bind_report_dir/2: print bound packs, unbound gaps, and binding violations.
layer_bind_report_dir(PacksDir, StrataSource) :-
    % Read the authoritative stratum ordinals.
    layer_stratum_ordinals(StrataSource, OrdinalMap),
    % Build the bound-node set and the unbound-gap list.
    layer_bind_scan(PacksDir, OrdinalMap, BoundNodes, Unbound),
    % Compute the binding violations.
    layer_binding_violations(BoundNodes, Violations),
    % Print a header for the binding report.
    format("~n=== Layer-to-Stratum Binding report (~w against strata source ~w) ===~n", [PacksDir, StrataSource]),
    % Report each bound pack with its layer, stratum, and the stratum's ordinal, sorted by ordinal.
    findall(O-b(P, L, S), member(bnode(P, L, S, O), BoundNodes), BoundPairs),
    keysort(BoundPairs, BoundSorted),
    length(BoundSorted, BoundCount),
    format("Bound packs: ~w~n", [BoundCount]),
    forall(member(O-b(P, L, S), BoundSorted),
           format("  layer ~w  stratum ~w (ordinal ~w)  ~w~n", [L, S, O, P])),
    % Report the unbound packs as gaps to fill (never errors).
    length(Unbound, UnboundCount),
    format("Unbound packs (gaps, not violations): ~w~n", [UnboundCount]),
    % Print each violation on its own readable line, or state that none were found.
    ( Violations == []
    ->  format("Binding violations: 0 — every pack's layer honours its stratum's ordinal order.~n", [])
    ;   length(Violations, VCount),
        format("Binding violations: ~w~n", [VCount]),
        forall(member(V, Violations),
               ( layer_binding_violation_line(V, Line), format("  ~w~n", [Line]) )) ).

% Define layer_bind_enforce_dir/3: enforce the binding at load time (strict or report mode).
% The sibling of layer_enforce_dir/2: strict mode throws on any binding violation (so a
% :- initialization(layer_bind_enforce_dir(...)) refuses a mis-bound configuration);
% report mode lists violations without refusing, so the binding is adopted incrementally.
layer_bind_enforce_dir(PacksDir, StrataSource, Mode) :-
    % Compute the binding violations once for the given directory and strata source.
    layer_bind_check_dir(PacksDir, StrataSource, Violations),
    % Print the report so the outcome is visible either way.
    layer_bind_report_dir(PacksDir, StrataSource),
    % Branch on the requested enforcement mode.
    ( Mode == strict
    % Strict mode: a non-empty violation list refuses the load by throwing.
    ->  ( Violations == []
        ->  true
        ;   throw(error(layer_binding_violation(Violations), layer_bind_enforce_dir/3)) )
    % Report mode: never refuse; violations were already printed above.
    ;   Mode == report
    ->  true
    % Any other mode is a usage error.
    ;   throw(error(domain_error(layer_bind_enforce_mode, Mode), layer_bind_enforce_dir/3)) ).

% ===========================================================================
% THE LAYER CONSTRUCT'S REACH  (Wave 10 Stage 6, WP-435; closes Theme E)
% ---------------------------------------------------------------------------
% Theme E had two facets. E-1 (cross-repository): the L4 scan was
% single-repository, its layer integers a per-repo namespace with no global
% coordinate, and its owner map built from one packs directory, so a
% cross-repository import was invisible (P5/P6/P7, ATOMIC-5/6/7, LOOPS-4, N3).
% E-2 (intra-pack): the construct was pack-granular, so a coarse pack's internal
% layering, coupling, and testability fell below the language's resolution
% (LOOPS-1/2/3). These additive predicates give the same pure violation core a
% longer reach — across repositories under a shared coordinate, and inside a pack
% at sub-module granularity — without changing any existing L4 or N6 behaviour.
% ===========================================================================

% -- layer_global_layer(+LocalLayer, +Offset, -GlobalLayer): the offset convention.
% A repository's local layer numbers become a GLOBAL coordinate by adding a
% per-repository offset (a base repo at offset 0, an arm stacked at offset 100),
% so P7/ATOMIC-7's per-repo namespace gains one shared axis. An undeclared layer
% stays undeclared — an offset shifts a coordinate, it does not invent one.
layer_global_layer(undeclared, _Offset, undeclared) :- !.
layer_global_layer(LocalLayer, Offset, GlobalLayer) :-
    % Only a numeric local layer has a coordinate to shift.
    integer(LocalLayer), integer(Offset),
    % The global coordinate is the local layer lifted by the repository's offset.
    GlobalLayer is LocalLayer + Offset.

% -- layer_scan_dirs(+DirSpecs, -Nodes, -Undeclared): union several packs dirs.
% DirSpecs is a list of dir(PacksDir, Offset). Every pack across every directory
% becomes one node under its GLOBAL coordinate, and the owner map is built across
% the UNION, so an import from one repository's pack to another's is resolved and
% visible (P6/ATOMIC-6). The undeclared list is the gap set across all directories.
layer_scan_dirs(DirSpecs, Nodes, Undeclared) :-
    % Pair every pack directory with the offset of the repository it belongs to.
    findall(PackDir-Offset,
            ( member(dir(Dir, Offset), DirSpecs),
              layer_pack_dirs(Dir, PackDirs),
              member(PackDir, PackDirs) ),
            PackDirOffsets),
    % Collect just the pack directories to build one owner map across all repositories.
    findall(PD, member(PD-_, PackDirOffsets), AllPackDirs),
    % Build the library-file-to-owning-pack map across the whole union.
    layer_lib_owner_map(AllPackDirs, OwnerPairs),
    % Turn each pack directory into a node under its repository's global coordinate.
    findall(node(Pack, GlobalLayer, Imports),
            ( member(PackDir-Offset, PackDirOffsets),
              layer_dir_node(OwnerPairs, PackDir, node(Pack, LocalLayer, Imports)),
              layer_global_layer(LocalLayer, Offset, GlobalLayer) ),
            Nodes),
    % A node whose global layer is 'undeclared' is a gap, collected and sorted.
    findall(Name, member(node(Name, undeclared, _), Nodes), UndeclaredRaw),
    sort(UndeclaredRaw, Undeclared).

% -- layer_check_dirs(+DirSpecs, -Violations): cross-repository violation scan.
% The SAME pure violation core (layer_graph_violations/2) runs over the unioned,
% globally-coordinated node set, so a cross-repository upward edge is now a
% first-class violation (P5/P6/P7, ATOMIC-5/6/7).
layer_check_dirs(DirSpecs, Violations) :-
    % Build the unioned node set under global coordinates.
    layer_scan_dirs(DirSpecs, Nodes, _),
    % Reuse the pure violation core — an upward edge is an upward edge, cross-repo or not.
    layer_graph_violations(Nodes, Violations).

% -- layer_report_dirs(+DirSpecs): print a readable cross-repository report.
layer_report_dirs(DirSpecs) :-
    % Scan the union and gather violations.
    layer_scan_dirs(DirSpecs, Nodes, Undeclared),
    layer_graph_violations(Nodes, Violations),
    % Count the declared nodes for the header.
    findall(P, ( member(node(P, L, _), Nodes), integer(L) ), Declared),
    length(Declared, DeclaredCount),
    length(Undeclared, UndeclaredCount),
    % Print the header naming the union's declared and undeclared counts.
    format("layer reach (cross-repository): ~w declared, ~w undeclared~n",
           [DeclaredCount, UndeclaredCount]),
    % Print each cross-repository violation, or a clean line when there are none.
    ( Violations == []
    ->  format("no cross-repository upward dependencies — the union honours the layer rule~n", [])
    ;   forall(member(V, Violations), format("  VIOLATION ~q~n", [V])) ).

% -- layer_adoption(+PacksDir, -Declared, -Total, -Fraction): the N3 coverage report.
% Adoption of the layer rule is incremental; this reports how far it has reached in a
% directory (how many packs declare a layer, out of the total), so the standing
% adoption program has a number to move rather than a prose estimate.
layer_adoption(PacksDir, Declared, Total, Fraction) :-
    % Scan the directory into nodes.
    layer_scan(PacksDir, Nodes, _),
    % The total is every pack in the directory.
    length(Nodes, Total),
    % The declared count is every pack that carries a numeric layer.
    findall(P, ( member(node(P, L, _), Nodes), integer(L) ), DeclaredPacks),
    length(DeclaredPacks, Declared),
    % The fraction is declared over total (zero for an empty directory).
    ( Total =:= 0 -> Fraction = 0.0 ; Fraction is Declared / Total ).

% -- layer_submodule_violations(+Submodules, -Violations): the intra-pack check.
% A Submodule is submodule(Name, Rank, Calls, TestTarget): a named internal region,
% its integer rank, the sub-module names it calls, and its per-sub-module test target.
% Two violations, mirroring the pack-granular rule at sub-module resolution:
%   upward_call    — a call to a strictly-HIGHER-rank sub-module (LOOPS-1); and
%   unknown_callee — a call to a sub-module NOT in the declared set, i.e. across the
%                    declared intra-pack boundary (LOOPS-2).
layer_submodule_violations(Submodules, Violations) :-
    % The set of declared sub-module names bounds the legal call targets.
    findall(N, member(submodule(N, _, _, _), Submodules), Names),
    % Gather every offending call across every declared sub-module.
    findall(Violation,
            ( member(submodule(From, FromRank, Calls, _), Submodules),
              member(To, Calls),
              layer_submodule_violation(From, FromRank, To, Names, Submodules, Violation) ),
            Violations).

% -- layer_submodule_violation(+From, +FromRank, +To, +Names, +Submodules, -Violation):
% one offending call, or fails when the call is legal.
% A call to an undeclared sub-module is a boundary crossing.
layer_submodule_violation(From, _FromRank, To, Names, _Submodules,
        violation(unknown_callee, from(From), to(To))) :-
    % The callee is not among the declared sub-modules of this pack.
    \+ memberchk(To, Names), !.
% A call to a strictly-higher-rank sub-module climbs the internal hierarchy.
layer_submodule_violation(From, FromRank, To, _Names, Submodules,
        violation(upward_call, from(From, FromRank), to(To, ToRank))) :-
    % Look up the callee's rank among the declared sub-modules.
    memberchk(submodule(To, ToRank, _, _), Submodules),
    % A violation is exactly a call that climbs to a higher rank.
    ToRank > FromRank.

% -- layer_submodule_untested(+Submodules, -Untested): the LOOPS-3 testability check.
% A sub-module whose declared test target is the atom 'none' cannot be exercised on
% its own; it is collected so a coarse pack cannot hide an untestable internal region.
layer_submodule_untested(Submodules, Untested) :-
    % Collect the name of every sub-module that names no real test target.
    findall(Name,
            member(submodule(Name, _, _, none), Submodules),
            Untested).

% ===========================================================================
% BINDING FRESHNESS  (N7, Wave 10 Stage 9; additive to the N6 binding)
% ---------------------------------------------------------------------------
% The N6 binding reads a stratum's ordinal from the Causalontology structure-record
% ARTIFACTS (the JSON records). N7 observed those artifacts could be STALE with respect
% to the pack's minting code, so a stale artifact could pass a real drift. These two
% additive predicates give both remedies the Ledger named: a LOAD-SAFE way to read an
% ordinal directly from a pack (a pack may declare stratum_ordinal(N) in its manifest,
% read without consulting any artifact), and a FRESHNESS gate that flags any pack whose
% directly-declared ordinal disagrees with the artifact-derived one — a stale artifact
% (or a mis-declared pack) caught, not silently trusted.
% ===========================================================================

% -- layer_pack_ordinal(+PackDir, -Ordinal): read a stratum ordinal directly from a manifest.
% Optional: a pack that wants a load-safe, artifact-independent ordinal declares
% stratum_ordinal(N) beside stratum(Label); this reads it straight from pack.pl.
layer_pack_ordinal(PackDir, Ordinal) :-
    % Point at the pack's manifest file.
    atomic_list_concat([PackDir, '/pack.pl'], ManifestPath),
    % The manifest must exist and carry a stratum_ordinal(N) integer fact.
    exists_file(ManifestPath),
    layer_manifest_int(ManifestPath, stratum_ordinal, Ordinal).

% -- layer_binding_freshness(+PacksDir, +StrataSource, -Drifts): flag stale artifacts.
% For every pack that declares BOTH a stratum and a direct stratum_ordinal, compare the
% direct ordinal to the artifact ordinal for that stratum; a disagreement is a drift.
layer_binding_freshness(PacksDir, StrataSource, Drifts) :-
    % Read the authoritative stratum ordinals from the record artifacts.
    layer_stratum_ordinals(StrataSource, ArtifactPairs),
    % Enumerate the pack directories.
    layer_pack_dirs(PacksDir, PackDirs),
    % Collect a drift for every pack whose declared ordinal disagrees with the artifact.
    findall(drift(Stratum, declared(DeclOrd), artifact(ArtOrd)),
            ( member(Dir, PackDirs),
              % The pack must declare a stratum.
              layer_pack_stratum(Dir, Stratum), Stratum \== unbound,
              % The pack must also declare a direct ordinal (opt-in freshness).
              layer_pack_ordinal(Dir, DeclOrd),
              % The artifact must carry an ordinal for that stratum.
              memberchk(Stratum-ArtOrd, ArtifactPairs),
              % A drift is exactly a disagreement between the two sources.
              DeclOrd =\= ArtOrd ),
            Drifts).
