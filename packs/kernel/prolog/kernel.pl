/*  PrologAI — Lattice-Resident Rewrite Rules and the Minimal Kernel  (PR 35)

    Two halves:

    Half 1 — Rewrite rules in the Lattice.
        A rewrite rule is a node_fact (relation rewrites_to, args [Pattern,
        Template, Guard]).  Because rules are node_facts they carry value
        channels, are queryable, learnable, proposable by the refiner, and
        scoped — the same compartment machinery as everything else.

    Half 2 — Minimal PrologAI Kernel interpreter.
        A small operational semantics that defines a compliant implementation.
        The reference realization maps kernel transitions onto SWI-Prolog's
        unification, substitution, and arithmetic evaluation, so compliance
        costs no fork.

    Kernel transition rules (labeled):
        rewrite  — unify expression with a rule Pattern, call Guard,
                   bind Template (unify-substitute step)
        arith    — evaluate an arithmetic expression once all sub-terms
                   are ground numbers (the evaluate-one-step rule)
        recurse  — reduce sub-terms before retrying (structural induction)

    kernel_rewrite_rule/4  — +Pattern, +Template, +Guard, -Id
    kernel_interpret/3     — +Expression, -Result, +Options
    kernel_kernel_trace/2  — +Expression, -Trace  (list of step/3 terms)
*/

% Declare this file as the 'kernel' module and list its exported predicates.
:- module(kernel, [
    % Supply 'kernel_rewrite_rule/4' as the next argument to the expression above.
    kernel_rewrite_rule/4,
    % Supply 'kernel_interpret/3' as the next argument to the expression above.
    kernel_interpret/3,
    % Supply 'kernel_kernel_trace/2' as the next argument to the expression above.
    kernel_kernel_trace/2
% Close the expression opened above.
]).

% Import [anchor_node/4] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [anchor_node/4]).
% Import [lattice_node_fact/5] from the built-in 'lattice' library.
:- use_module(library(lattice),    [lattice_node_fact/5]).
% Import [member/2, reverse/2] from the built-in 'lists' library.
:- use_module(library(lists),      [member/2, reverse/2]).

% ---------------------------------------------------------------------------
% kernel_rewrite_rule/4
%
%   Inscribe a rewrite rule as a node_fact in the default nexus.
%   Pattern, Template, and Guard share variables so unification with Pattern
%   propagates bindings into both Template and Guard via copy_term at eval.
% ---------------------------------------------------------------------------

% Define a clause for 'pai rewrite rule': succeed when the following conditions hold.
kernel_rewrite_rule(Pattern, Template, Guard, Id) :-
    % State the fact: anchor node(rewrites_to, [Pattern, Template, Guard], [], Id).
    anchor_node(rewrites_to, [Pattern, Template, Guard], [], Id).

% ---------------------------------------------------------------------------
% kernel_interpret/3
%
%   Evaluate Expression against the active rule set in the Lattice.
%   Applies rules by unify-substitute-repeat until no rule fires,
%   then evaluates arithmetic once sub-terms are reduced.
% ---------------------------------------------------------------------------

% Define a clause for 'pai interpret': succeed when the following conditions hold.
kernel_interpret(Expr, Result, _Opts) :-
    % State the fact: interp(Expr, Result, [], _RevTrace).
    interp(Expr, Result, [], _RevTrace).

% ---------------------------------------------------------------------------
% kernel_kernel_trace/2
%
%   Evaluate Expression and return a forward-order derivation Trace.
%   Each element is step(Transition, Before, After) where Transition
%   is one of: rewrite, arith, recurse.
% ---------------------------------------------------------------------------

% Define a clause for 'pai kernel trace': succeed when the following conditions hold.
kernel_kernel_trace(Expr, Trace) :-
    % State a fact for 'interp' with the arguments listed below.
    interp(Expr, _, [], RevTrace),
    % State the fact: reverse(RevTrace, Trace).
    reverse(RevTrace, Trace).

% ---------------------------------------------------------------------------
% interp/4 — core evaluator
%
%   interp(+Expr, -Result, +TraceAcc, -TraceOut)
%   TraceAcc/TraceOut: difference-list accumulator in reverse order.
% ---------------------------------------------------------------------------

% Define a clause for 'interp': succeed when the following conditions hold.
interp(Expr, Result, T0, T) :-
    % Execute: ( number(Expr).
    ( number(Expr)
    % If the condition above succeeded, perform the following action.
    ->  Result = Expr, T = T0                              % already a value
    % Otherwise (else branch), perform the following action.
    ;   match_rule(Expr, Template, T0, T1)
    % If the condition above succeeded, perform the following action.
    ->  interp(Template, Result, T1, T)                    % rewrite step
    % Otherwise (else branch), perform the following action.
    ;   compound(Expr)
    % If the condition above succeeded, perform the following action.
    ->  Expr =.. [F|Args],
        % Continue the multi-line expression started above.
        interp_list(Args, ArgsR, T0, T1),
        % Continue the multi-line expression started above.
        ExprR =.. [F|ArgsR],
        % Continue the multi-line expression started above.
        ( catch(R0 is ExprR, _, fail)
        % If the condition above succeeded, perform the following action.
        ->  Result = R0,                                   % arith step
            % Continue the multi-line expression started above.
            T = [step(arith, ExprR, R0)|T1]
        % Otherwise (else branch), perform the following action.
        ;   ExprR == Expr
        % If the condition above succeeded, perform the following action.
        ->  Result = Expr, T = T1                         % no progress
        % Otherwise (else branch), perform the following action.
        ;   interp(ExprR, Result, [step(recurse,Expr,ExprR)|T1], T)
        % Continue the multi-line expression started above.
        )                                                  % recurse step
    % Otherwise (else branch), perform the following action.
    ;   Result = Expr, T = T0                              % atom / var
    % Close the expression opened above.
    ).

% State the fact: interp list([], [], T, T).
interp_list([], [], T, T).
% Define a clause for 'interp list': succeed when the following conditions hold.
interp_list([A|As], [R|Rs], T0, T) :-
    % State a fact for 'interp' with the arguments listed below.
    interp(A, R, T0, T1),
    % State the fact: interp list(As, Rs, T1, T).
    interp_list(As, Rs, T1, T).

% ---------------------------------------------------------------------------
% match_rule/4 — find and commit to first matching rewrite rule
% ---------------------------------------------------------------------------

% Define a clause for 'match rule': succeed when the following conditions hold.
match_rule(Expr, Template, T0, [step(rewrite, Expr, Template)|T0]) :-
    % State a fact for 'lattice node fact' with the arguments listed below.
    lattice_node_fact(_, _, rewrites_to, [Pattern, Tpl, Guard], _),
    % State a fact for 'copy term' with the arguments listed below.
    copy_term(t(Pattern, Tpl, Guard), t(PatC, TplC, GuardC)),
    % Check that 'PatC' is unifiable with 'Expr'.
    PatC = Expr,
    % State a fact for 'call' with the arguments listed below.
    call(GuardC),
    % Check that 'Template' is unifiable with 'TplC'.
    Template = TplC.
