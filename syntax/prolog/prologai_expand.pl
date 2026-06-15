/*  PrologAI — Surface Syntax Transcompiler
    PR 1: Launcher, Distribution, and Dialect
    FR-PR01: term_expansion/2 and goal_expansion/2 rules that transcompile
    .pai source into Layer C library calls at load time, following the
    Logtalk transcompiler model.  .pl files are left completely untouched.
*/

:- module(prologai_expand, [load_pai_file/1]).

:- use_module(library(sentinels), [pai_register_sentinel/6]).

% ---------------------------------------------------------------------------
% .pai file detection helper
% ---------------------------------------------------------------------------

%  Succeeds when the file currently being loaded by the Prolog compiler
%  has the .pai extension.
current_source_is_pai :-
    prolog_load_context(source, File),
    file_name_extension(_, pai, File).

% ---------------------------------------------------------------------------
% term_expansion/2 — applies only inside .pai files
% ---------------------------------------------------------------------------

:- multifile user:term_expansion/2.

%  Expand a bare sentinel/6 fact into a load-time registration directive.
%  Surface syntax:
%      sentinel(Domain, Priority, Pattern, Objectives, Action, Doc).
%  Expands to:
%      :- pai_register_sentinel(Domain, Priority, Pattern, Objectives, Action, Doc).
user:term_expansion(sentinel(Domain, Priority, Pattern, Objectives, Action, Doc),
                    (:- pai_register_sentinel(Domain, Priority, Pattern,
                                              Objectives, Action, Doc))) :-
    current_source_is_pai,
    !.

%  Expand a bare cyclic_actor/3 declaration into a load-time registration.
%  (infrastructure only for PR 1; full actor semantics arrive in PR 6)
user:term_expansion(cyclic_actor(Name, Goal, DelayMs),
                    (:- pai_declare_actor(Name, Goal, DelayMs))) :-
    current_source_is_pai,
    !.

% ---------------------------------------------------------------------------
% goal_expansion/2 — applies only inside .pai files
% ---------------------------------------------------------------------------

:- multifile user:goal_expansion/2.

%  No goal expansions are defined in PR 1.
%  This multifile declaration makes the hook visible; specific expansions
%  are added by later work packages (PR 6, PR 8, PR 9, …).

% ---------------------------------------------------------------------------
% Explicit .pai file loader
% ---------------------------------------------------------------------------

%! load_pai_file(+Path) is det.
%  Load Path through the PrologAI expansion pipeline when it has a .pai
%  extension; load it as standard Prolog otherwise.
load_pai_file(Path) :-
    (   file_name_extension(_, pai, Path)
    ->  load_files(Path, [])
    ;   load_files(Path, [])
    ).

% ---------------------------------------------------------------------------
% Register .pai as a recognised Prolog file type so consult/1 and
% use_module/1 find and load .pai files without an explicit extension.
% ---------------------------------------------------------------------------

:- multifile user:prolog_file_type/2.
user:prolog_file_type(pai, prolog).
