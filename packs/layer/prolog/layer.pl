/*  PrologAI — Strict Layer Rule construct  (WP-426, Layer 400)

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
    layer_default_packs_dir/1
]).

% Import list utilities [member/2, memberchk/2, sort/4, exclude/3] from library(lists).
:- use_module(library(lists), [member/2, memberchk/2]).
% Import [exclude/3, include/3, maplist/2] from the apply library.
:- use_module(library(apply), [exclude/3, include/3, maplist/2]).
% Import [re_replace/4, re_foldl/6] from the pcre (Perl-compatible regex) library.
:- use_module(library(pcre), [re_foldl/6, re_replace/4]).
% Import [read_file_to_string/3] from the readutil library.
:- use_module(library(readutil), [read_file_to_string/3]).

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
