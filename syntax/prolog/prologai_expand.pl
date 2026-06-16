/*  PrologAI — Surface Syntax Transcompiler
    PR 1: Launcher, Distribution, and Dialect
    FR-PR01: term_expansion/2 and goal_expansion/2 rules that transcompile
    .pai source into Layer C library calls at load time, following the
    Logtalk transcompiler model.  .pl files are left completely untouched.
*/

% Declare this file as the 'prologai_expand' module, making [load_pai_file/1] available to other modules.
:- module(prologai_expand, [load_pai_file/1]).

% Import [pai_register_sentinel/6] from the built-in 'sentinels' library.
:- use_module(library(sentinels), [pai_register_sentinel/6]).

% ---------------------------------------------------------------------------
% .pai file detection helper
% ---------------------------------------------------------------------------

%  Succeeds when the file currently being loaded by the Prolog compiler
%  has the .pai extension.
% Execute: current_source_is_pai :-.
current_source_is_pai :-
    % State a fact for 'prolog load context' with the arguments listed below.
    prolog_load_context(source, File),
    % State the fact: file name extension(_, pai, File).
    file_name_extension(_, pai, File).

% ---------------------------------------------------------------------------
% term_expansion/2 — applies only inside .pai files
% ---------------------------------------------------------------------------

% Execute the compile-time directive: multifile user:term_expansion/2.
:- multifile user:term_expansion/2.

%  Expand a bare sentinel/6 fact into a load-time registration directive.
%  Surface syntax:
%      sentinel(Domain, Priority, Pattern, Objectives, Action, Doc).
%  Expands to:
%      :- pai_register_sentinel(Domain, Priority, Pattern, Objectives, Action, Doc).
% Execute: user:term_expansion(sentinel(Domain, Priority, Pattern, Objectives, Action, Doc),.
user:term_expansion(sentinel(Domain, Priority, Pattern, Objectives, Action, Doc),
                    % Continue the multi-line expression started above.
                    (:- pai_register_sentinel(Domain, Priority, Pattern,
                                              % Continue the multi-line expression started above.
                                              Objectives, Action, Doc))) :-
    % Call the goal 'current_source_is_pai'.
    current_source_is_pai,
    % Commit to this clause — discard all remaining choice points (cut).
    !.

%  Expand a bare cyclic_actor/3 declaration into a load-time registration.
%  (infrastructure only for PR 1; full actor semantics arrive in PR 6)
% Execute: user:term_expansion(cyclic_actor(Name, Goal, DelayMs),.
user:term_expansion(cyclic_actor(Name, Goal, DelayMs),
                    % Continue the multi-line expression started above.
                    (:- pai_declare_actor(Name, Goal, DelayMs))) :-
    % Call the goal 'current_source_is_pai'.
    current_source_is_pai,
    % Commit to this clause — discard all remaining choice points (cut).
    !.

% ---------------------------------------------------------------------------
% goal_expansion/2 — applies only inside .pai files
% ---------------------------------------------------------------------------

% Execute the compile-time directive: multifile user:goal_expansion/2.
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
% Define a clause for 'load pai file': succeed when the following conditions hold.
load_pai_file(Path) :-
    % Execute: (   file_name_extension(_, pai, Path).
    (   file_name_extension(_, pai, Path)
    % If the condition above succeeded, perform the following action.
    ->  load_files(Path, [])
    % Otherwise (else branch), perform the following action.
    ;   load_files(Path, [])
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% Register .pai as a recognised Prolog file type so consult/1 and
% use_module/1 find and load .pai files without an explicit extension.
% ---------------------------------------------------------------------------

% Execute the compile-time directive: multifile user:prolog_file_type/2.
:- multifile user:prolog_file_type/2.
% Execute: user:prolog_file_type(pai, prolog)..
user:prolog_file_type(pai, prolog).
