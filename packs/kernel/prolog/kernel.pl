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

    pai_rewrite_rule/4  — +Pattern, +Template, +Guard, -Id
    pai_interpret/3     — +Expression, -Result, +Options
    pai_kernel_trace/2  — +Expression, -Trace  (list of step/3 terms)
*/

:- module(kernel, [
    pai_rewrite_rule/4,
    pai_interpret/3,
    pai_kernel_trace/2
]).

:- use_module(library(node_facts), [anchor_node/4]).
:- use_module(library(lattice),    [lattice_node_fact/5]).
:- use_module(library(lists),      [member/2, reverse/2]).

% ---------------------------------------------------------------------------
% pai_rewrite_rule/4
%
%   Inscribe a rewrite rule as a node_fact in the default nexus.
%   Pattern, Template, and Guard share variables so unification with Pattern
%   propagates bindings into both Template and Guard via copy_term at eval.
% ---------------------------------------------------------------------------

pai_rewrite_rule(Pattern, Template, Guard, Id) :-
    anchor_node(rewrites_to, [Pattern, Template, Guard], [], Id).

% ---------------------------------------------------------------------------
% pai_interpret/3
%
%   Evaluate Expression against the active rule set in the Lattice.
%   Applies rules by unify-substitute-repeat until no rule fires,
%   then evaluates arithmetic once sub-terms are reduced.
% ---------------------------------------------------------------------------

pai_interpret(Expr, Result, _Opts) :-
    interp(Expr, Result, [], _RevTrace).

% ---------------------------------------------------------------------------
% pai_kernel_trace/2
%
%   Evaluate Expression and return a forward-order derivation Trace.
%   Each element is step(Transition, Before, After) where Transition
%   is one of: rewrite, arith, recurse.
% ---------------------------------------------------------------------------

pai_kernel_trace(Expr, Trace) :-
    interp(Expr, _, [], RevTrace),
    reverse(RevTrace, Trace).

% ---------------------------------------------------------------------------
% interp/4 — core evaluator
%
%   interp(+Expr, -Result, +TraceAcc, -TraceOut)
%   TraceAcc/TraceOut: difference-list accumulator in reverse order.
% ---------------------------------------------------------------------------

interp(Expr, Result, T0, T) :-
    ( number(Expr)
    ->  Result = Expr, T = T0                              % already a value
    ;   match_rule(Expr, Template, T0, T1)
    ->  interp(Template, Result, T1, T)                    % rewrite step
    ;   compound(Expr)
    ->  Expr =.. [F|Args],
        interp_list(Args, ArgsR, T0, T1),
        ExprR =.. [F|ArgsR],
        ( catch(R0 is ExprR, _, fail)
        ->  Result = R0,                                   % arith step
            T = [step(arith, ExprR, R0)|T1]
        ;   ExprR == Expr
        ->  Result = Expr, T = T1                         % no progress
        ;   interp(ExprR, Result, [step(recurse,Expr,ExprR)|T1], T)
        )                                                  % recurse step
    ;   Result = Expr, T = T0                              % atom / var
    ).

interp_list([], [], T, T).
interp_list([A|As], [R|Rs], T0, T) :-
    interp(A, R, T0, T1),
    interp_list(As, Rs, T1, T).

% ---------------------------------------------------------------------------
% match_rule/4 — find and commit to first matching rewrite rule
% ---------------------------------------------------------------------------

match_rule(Expr, Template, T0, [step(rewrite, Expr, Template)|T0]) :-
    lattice_node_fact(_, _, rewrites_to, [Pattern, Tpl, Guard], _),
    copy_term(t(Pattern, Tpl, Guard), t(PatC, TplC, GuardC)),
    PatC = Expr,
    call(GuardC),
    Template = TplC.
