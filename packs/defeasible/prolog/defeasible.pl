/*  PrologAI — Justified Defeasible Reasoning  (Specification PR 40)

    Gives the mind rigorous commonsense reasoning with defaults and exceptions
    where every conclusion carries a human-readable justification.

    Model:
        A RULE BASE holds two flavors of assertion:
          default_rule(RB, Head, Cond) — Head holds if Cond holds AND no
              exception defeats this conclusion.
          exception_rule(RB, Head, ExcCond) — defeats any default for Head
              when ExcCond holds in the background.

        Evaluation is priority-ordered: exception_rules preempt default_rules.
        If ANY matching exception is applicable, the conclusion is defeated and
        the answer is 'no'; otherwise, the highest-priority (most recently
        declared) default that fires is used and the answer is 'yes'.

        This matches Reiter-style default logic and the Closed-World
        Assumption over the exception layer, giving the canonical behaviour
        required for birds-fly/penguins-don't-fly commonsense reasoning.

    Justification tree:
        just(yes, Clause, SubTree)   — goal provable via Clause, SubTree
                                        justifies the preconditions
        just(no, defeated_by(Exc, E), just(yes,bg_fact(E),...))
                                     — goal defeated by exception Exc applied
                                        to evidence E
        just(no, no_rule)            — no applicable default rule found

    pai_justify/2 renders any just/_ term as a readable atom.

    Predicates:
        pai_defeasible_rule/3   — +RuleBase, +Type(default|exception), +Rule
        pai_defeasible_query/4  — +RuleBase, +Goal, +Background, -Answer
        pai_justify/2           — +ProofTree, -Text
*/

:- module(defeasible, [
    pai_defeasible_rule/3,
    pai_defeasible_query/4,
    pai_justify/2
]).

:- use_module(library(node_facts), [anchor_node/4]).
:- use_module(library(lattice),    [lattice_node_fact/5]).
:- use_module(library(lists),      [member/2, memberchk/2]).
:- use_module(library(apply),      [maplist/3]).

% ---------------------------------------------------------------------------
% pai_defeasible_rule/3
%
%   Type = default   → Rule = (Head :- Cond)
%   Type = exception → Rule = exc(Head, ExcCond)
%
%   Both are stored as node_facts in the active Lattice.
%   Idempotent: storing the same rule twice has no effect (anchor_node).
% ---------------------------------------------------------------------------

pai_defeasible_rule(RuleBase, default, (Head :- Cond)) :-
    anchor_node(defeasible_rule, [RuleBase, Head, Cond], [], _).

pai_defeasible_rule(RuleBase, exception, exc(Head, ExcCond)) :-
    anchor_node(exception_rule, [RuleBase, Head, ExcCond], [], _).

% ---------------------------------------------------------------------------
% pai_defeasible_query/4
%
%   Evaluates Goal against RuleBase with Background ground facts.
%   Returns answer(yes, ProofTree) or answer(no, ProofTree).
% ---------------------------------------------------------------------------

pai_defeasible_query(RuleBase, Goal, Background, Answer) :-
    ( try_exception(RuleBase, Goal, Background, ExcJust)
    ->  Answer = answer(no, ExcJust)
    ;   try_defaults(RuleBase, Goal, Background, DefJust)
    ->  Answer = answer(yes, DefJust)
    ;   Answer = answer(no, just(no, no_rule))
    ).

% Check if any exception defeats the goal
try_exception(RuleBase, Goal, Background, just(no, defeated_by(ExcCond, Goal), BodyJust)) :-
    lattice_node_fact(_, _, exception_rule, [RuleBase, ExcHead, ExcCond], _),
    copy_term(exc_rule(ExcHead, ExcCond), exc_rule(EH, EC)),
    EH = Goal,
    prove_bg(EC, Background, BodyJust), !.

% Try default rules; commit after first matching rule (deterministic)
try_defaults(RuleBase, Goal, Background, Just) :-
    findall(H-C, lattice_node_fact(_, _, defeasible_rule, [RuleBase, H, C], _), Rules),
    member(HeadT-CondT, Rules),
    copy_term(HeadT-CondT, Head-Cond),
    Head = Goal,
    prove_bg(Cond, Background, BodyJust), !,
    Rule = (Goal :- Cond),
    Just = just(yes, via_rule(Rule), BodyJust).

% Prove a conjunction against the background (flat; no recursion into defeasible)
prove_bg(true, _, just(yes, trivial)).
prove_bg((A, B), BG, just(yes, and(JA, JB))) :- !,
    prove_bg(A, BG, JA),
    prove_bg(B, BG, JB).
prove_bg(Goal, BG, just(yes, bg_fact(Goal))) :-
    memberchk(Goal, BG).

% ---------------------------------------------------------------------------
% pai_justify/2 — render a proof tree as a human-readable atom
% ---------------------------------------------------------------------------

pai_justify(just(yes, trivial), "trivially true").
pai_justify(just(yes, bg_fact(F)), Text) :-
    format(atom(Text), "background fact: ~w", [F]).
pai_justify(just(yes, via_rule(H :- B), SubJust), Text) :-
    pai_justify(SubJust, Sub),
    format(atom(Text), "default rule (~w :- ~w) because ~w", [H, B, Sub]).
pai_justify(just(yes, and(JA, JB)), Text) :-
    pai_justify(JA, TA),
    pai_justify(JB, TB),
    format(atom(Text), "~w; and ~w", [TA, TB]).
pai_justify(just(no, no_rule), "no applicable rule found").
pai_justify(just(no, defeated_by(Exc, Goal), _SubJust), Text) :-
    format(atom(Text), "conclusion ~w defeated: exception condition ~w applies", [Goal, Exc]).
