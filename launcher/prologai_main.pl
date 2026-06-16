/*  PrologAI — Launcher Bootstrap Module
    PR 1: Launcher, Distribution, and Dialect
    FR-PR01: preload packs, install bootstrap ontology, print banner, set flags.
*/

% Declare this file as the 'prologai_main' module and list its exported predicates.
:- module(prologai_main, [
    % Supply 'start_prologai/0' as the next argument to the expression above.
    start_prologai/0,
    % Supply 'print_prologai_banner/0' as the next argument to the expression above.
    print_prologai_banner/0,
    % Supply 'install_bootstrap_ontology/0' as the next argument to the expression above.
    install_bootstrap_ontology/0
% Close the expression opened above.
]).

% Load the built-in 'prologai_expand' library so its predicates are available here.
:- use_module(library(prologai_expand)).
% Load the built-in 'sentinels' library so its predicates are available here.
:- use_module(library(sentinels)).

% Set prologai_version flag at module-load time (AC-SYS-005, FR-PR01).
% dialect remains swi — SWI-Prolog sets it and we must not override (AC-SYS-006).
% Execute the compile-time directive: ( current_prolog_flag(prologai_version, _).
:- ( current_prolog_flag(prologai_version, _)
   % If the condition above succeeded, perform the following action.
   -> true
   % Otherwise (else branch), perform the following action.
   ;  create_prolog_flag(prologai_version, '1.0.0',
                         % Continue the multi-line expression started above.
                         [access(read_only), keep(true)])
   % Close the expression opened above.
   ).

%! start_prologai is det.
%  Entry point: print banner, install bootstrap ontology, enter the
%  interactive top level (FR-PR01, AC-PR01-001).
% Execute: start_prologai :-.
start_prologai :-
    % Call the goal 'print_prologai_banner'.
    print_prologai_banner,
    % Call the goal 'install_bootstrap_ontology'.
    install_bootstrap_ontology,
    % State the zero-argument fact 'prolog'.
    prolog.

%! print_prologai_banner is det.
%  "PrologAI" on the first line followed by the SWI-Prolog attribution
%  line as required by the BSD-2 license notice obligation (FR-PR01).
% Execute: print_prologai_banner :-.
print_prologai_banner :-
    % Write formatted output to the current output stream.
    format("PrologAI 1.0.0 -- A Cognitive Architecture Programming Platform~n"),
    % State a fact for 'current prolog flag' with the arguments listed below.
    current_prolog_flag(version_data, swi(Major, Minor, Patch, _)),
    % Write formatted output to the current output stream.
    format("Built on SWI-Prolog ~w.~w.~w (http://www.swi-prolog.org)~n",
           % Continue the multi-line expression started above.
           [Major, Minor, Patch]).

%! install_bootstrap_ontology is det.
%  Installs the initial bootstrap node_facts into the Lattice.
%  Stub for PR 1: the Lattice (PR 3-4) is not yet available.
%  Full implementation is added when pack lattice is built.
% Execute: install_bootstrap_ontology :- true..
install_bootstrap_ontology :- true.
