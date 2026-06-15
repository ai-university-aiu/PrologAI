/*  PrologAI — Launcher Bootstrap Module
    PR 1: Launcher, Distribution, and Dialect
    FR-PR01: preload packs, install bootstrap ontology, print banner, set flags.
*/

:- module(prologai_main, [
    start_prologai/0,
    print_prologai_banner/0,
    install_bootstrap_ontology/0
]).

:- use_module(library(prologai_expand)).
:- use_module(library(sentinels)).

% Set prologai_version flag at module-load time (AC-SYS-005, FR-PR01).
% dialect remains swi — SWI-Prolog sets it and we must not override (AC-SYS-006).
:- ( current_prolog_flag(prologai_version, _)
   -> true
   ;  create_prolog_flag(prologai_version, '1.0.0',
                         [access(read_only), keep(true)])
   ).

%! start_prologai is det.
%  Entry point: print banner, install bootstrap ontology, enter the
%  interactive top level (FR-PR01, AC-PR01-001).
start_prologai :-
    print_prologai_banner,
    install_bootstrap_ontology,
    prolog.

%! print_prologai_banner is det.
%  "PrologAI" on the first line followed by the SWI-Prolog attribution
%  line as required by the BSD-2 license notice obligation (FR-PR01).
print_prologai_banner :-
    format("PrologAI 1.0.0 -- A Cognitive Architecture Programming Platform~n"),
    current_prolog_flag(version_data, swi(Major, Minor, Patch, _)),
    format("Built on SWI-Prolog ~w.~w.~w (http://www.swi-prolog.org)~n",
           [Major, Minor, Patch]).

%! install_bootstrap_ontology is det.
%  Installs the initial bootstrap node_facts into the Lattice.
%  Stub for PR 1: the Lattice (PR 3-4) is not yet available.
%  Full implementation is added when pack lattice is built.
install_bootstrap_ontology :- true.
