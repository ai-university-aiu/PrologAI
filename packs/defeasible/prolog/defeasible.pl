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

% Declare this file as the 'defeasible' module and list its exported predicates.
:- module(defeasible, [
    % Supply 'pai_defeasible_rule/3' as the next argument to the expression above.
    pai_defeasible_rule/3,
    % Supply 'pai_defeasible_query/4' as the next argument to the expression above.
    pai_defeasible_query/4,
    % Supply 'pai_justify/2' as the next argument to the expression above.
    pai_justify/2
% Close the expression opened above.
]).

% Import [anchor_node/4] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [anchor_node/4]).
% Import [lattice_node_fact/5] from the built-in 'lattice' library.
:- use_module(library(lattice),    [lattice_node_fact/5]).
% Import [member/2, memberchk/2] from the built-in 'lists' library.
:- use_module(library(lists),      [member/2, memberchk/2]).
% Import [maplist/3] from the built-in 'apply' library.
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

% Define a clause for 'pai defeasible rule': succeed when the following conditions hold.
pai_defeasible_rule(RuleBase, default, (Head :- Cond)) :-
    % State the fact: anchor node(defeasible_rule, [RuleBase, Head, Cond], [], _).
    anchor_node(defeasible_rule, [RuleBase, Head, Cond], [], _).

% Define a clause for 'pai defeasible rule': succeed when the following conditions hold.
pai_defeasible_rule(RuleBase, exception, exc(Head, ExcCond)) :-
    % State the fact: anchor node(exception_rule, [RuleBase, Head, ExcCond], [], _).
    anchor_node(exception_rule, [RuleBase, Head, ExcCond], [], _).

% ---------------------------------------------------------------------------
% pai_defeasible_query/4
%
%   Evaluates Goal against RuleBase with Background ground facts.
%   Returns answer(yes, ProofTree) or answer(no, ProofTree).
% ---------------------------------------------------------------------------

% Define a clause for 'pai defeasible query': succeed when the following conditions hold.
pai_defeasible_query(RuleBase, Goal, Background, Answer) :-
    % Execute: ( try_exception(RuleBase, Goal, Background, ExcJust).
    ( try_exception(RuleBase, Goal, Background, ExcJust)
    % If the condition above succeeded, perform the following action.
    ->  Answer = answer(no, ExcJust)
    % Otherwise (else branch), perform the following action.
    ;   try_defaults(RuleBase, Goal, Background, DefJust)
    % If the condition above succeeded, perform the following action.
    ->  Answer = answer(yes, DefJust)
    % Otherwise (else branch), perform the following action.
    ;   Answer = answer(no, just(no, no_rule))
    % Close the expression opened above.
    ).

% Check if any exception defeats the goal
% Define a clause for 'try exception': succeed when the following conditions hold.
try_exception(RuleBase, Goal, Background, just(no, defeated_by(ExcCond, Goal), BodyJust)) :-
    % State a fact for 'lattice node fact' with the arguments listed below.
    lattice_node_fact(_, _, exception_rule, [RuleBase, ExcHead, ExcCond], _),
    % State a fact for 'copy term' with the arguments listed below.
    copy_term(exc_rule(ExcHead, ExcCond), exc_rule(EH, EC)),
    % Check that 'EH' is unifiable with 'Goal'.
    EH = Goal,
    % State a fact for 'prove bg' with the arguments listed below.
    prove_bg(EC, Background, BodyJust), !.

% Try default rules; commit after first matching rule (deterministic)
% Define a clause for 'try defaults': succeed when the following conditions hold.
try_defaults(RuleBase, Goal, Background, Just) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(H-C, lattice_node_fact(_, _, defeasible_rule, [RuleBase, H, C], _), Rules),
    % Succeed for each element 'HeadT-CondT' that is a member of the list.
    member(HeadT-CondT, Rules),
    % State a fact for 'copy term' with the arguments listed below.
    copy_term(HeadT-CondT, Head-Cond),
    % Check that 'Head' is unifiable with 'Goal'.
    Head = Goal,
    % State a fact for 'prove bg' with the arguments listed below.
    prove_bg(Cond, Background, BodyJust), !,
    % Check that 'Rule' is unifiable with '(Goal :- Cond)'.
    Rule = (Goal :- Cond),
    % Check that 'Just' is unifiable with 'just(yes, via_rule(Rule), BodyJust)'.
    Just = just(yes, via_rule(Rule), BodyJust).

% Prove a conjunction against the background (flat; no recursion into defeasible)
% State the fact: prove bg(true, _, just(yes, trivial)).
prove_bg(true, _, just(yes, trivial)).
% Define a clause for 'prove bg': succeed when the following conditions hold.
prove_bg((A, B), BG, just(yes, and(JA, JB))) :- !,
    % State a fact for 'prove bg' with the arguments listed below.
    prove_bg(A, BG, JA),
    % State the fact: prove bg(B, BG, JB).
    prove_bg(B, BG, JB).
% Define a clause for 'prove bg': succeed when the following conditions hold.
prove_bg(Goal, BG, just(yes, bg_fact(Goal))) :-
    % State the fact: memberchk(Goal, BG).
    memberchk(Goal, BG).

% ---------------------------------------------------------------------------
% pai_justify/2 — render a proof tree as a human-readable atom
% ---------------------------------------------------------------------------

% State the fact: pai justify(just(yes, trivial), "trivially true").
pai_justify(just(yes, trivial), "trivially true").
% Define a clause for 'pai justify': succeed when the following conditions hold.
pai_justify(just(yes, bg_fact(F)), Text) :-
    % Write formatted output to the current output stream.
    format(atom(Text), "background fact: ~w", [F]).
% Define a clause for 'pai justify': succeed when the following conditions hold.
pai_justify(just(yes, via_rule(H :- B), SubJust), Text) :-
    % State a fact for 'pai justify' with the arguments listed below.
    pai_justify(SubJust, Sub),
    % Write formatted output to the current output stream.
    format(atom(Text), "default rule (~w :- ~w) because ~w", [H, B, Sub]).
% Define a clause for 'pai justify': succeed when the following conditions hold.
pai_justify(just(yes, and(JA, JB)), Text) :-
    % State a fact for 'pai justify' with the arguments listed below.
    pai_justify(JA, TA),
    % State a fact for 'pai justify' with the arguments listed below.
    pai_justify(JB, TB),
    % Write formatted output to the current output stream.
    format(atom(Text), "~w; and ~w", [TA, TB]).
% State the fact: pai justify(just(no, no_rule), "no applicable rule found").
pai_justify(just(no, no_rule), "no applicable rule found").
% Define a clause for 'pai justify': succeed when the following conditions hold.
pai_justify(just(no, defeated_by(Exc, Goal), _SubJust), Text) :-
    % Write formatted output to the current output stream.
    format(atom(Text), "conclusion ~w defeated: exception condition ~w applies", [Goal, Exc]).
