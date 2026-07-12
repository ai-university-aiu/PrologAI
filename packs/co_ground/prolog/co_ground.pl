/*  PrologAI — Causalontology Clue Grounding  (WP-417, Layer 392)

    Causalontology_v5 Section 10 designs a human-guided learning application in
    which a person watching an interactive game gives clues — "that looks like a
    key," "pick that up," "that looks like a lock," "that looks like a door;
    let's walk through it," "don't touch that" — and each clue is grounded into a
    Causalontology assertion tagged as a high-confidence but DEFEASIBLE human
    hint. Section 10.4 names that seam co_ground but the pack itself had not been
    built. This is that pack: a small, auditable mapping from a natural-language
    clue plus a referent to a list of Causalontology terms.

    A clue may be a phrase atom ('that looks like a key') or a list of word
    atoms; the referent is whatever the deixis "that/there" points at — a
    salient object id, or a cell the human clicked, supplied by the caller. The
    grounding is glass-box: each keyword maps to a fixed, inspectable template.

      "...key..."   -> continuant(Ref, key_like), disposition(Ref, pick_up_able),
                       disposition(Ref, opens_locks)
      "...lock..."  -> continuant(Ref, lock_like), disposition(Ref, openable_by_key),
                       goal(state(Ref, open))
      "...door..."  -> continuant(Ref, door_like), goal(traverse(Ref))
      "pick/grab/take" -> action(pickup(Ref)), priority(pickup(Ref), high)
      "hurts/dangerous/touch" -> preventive(interact(Ref)), avoid(interact(Ref))
      "good/worked" -> reinforce(recent, positive)

    Callers may add their own keyword templates. Grounding is defeasible: it is a
    high-confidence hint (co_ground marks its provenance human_hint, 0.9), and if
    intervention later contradicts it the caller's defeasible machinery revises it.

    Predicates:
      gr_reset/0            -- forget caller-added rules
      gr_rule_add/3         -- +Keyword, +RefVar, +Template  (Template mentions RefVar)
      gr_builtin/3          -- ?Keyword, ?Ref, ?Assertions    (the fixed mapping)
      gr_lookup/3           -- +Keyword, +Ref, -Assertions    (custom first, then builtin)
      gr_ground/3           -- +Clue, +Ref, -Assertions       (ground a whole clue)
      gr_is_clue/1          -- +Clue                          (does it ground to anything?)
      gr_keywords/1         -- -Keywords                      (every keyword known)
      gr_provenance/1       -- -Provenance                    (prov(human_hint, 0.9))
*/

% Declare this module and its exported predicates.
:- module(co_ground, [
    % gr_reset/0: forget caller-added grounding rules.
    gr_reset/0,
    % gr_rule_add/3: add a caller keyword template.
    gr_rule_add/3,
    % gr_builtin/3: the fixed built-in keyword mapping.
    gr_builtin/3,
    % gr_lookup/3: ground a single keyword against a referent.
    gr_lookup/3,
    % gr_ground/3: ground a whole clue against a referent.
    gr_ground/3,
    % gr_is_clue/1: whether a clue grounds to anything.
    gr_is_clue/1,
    % gr_keywords/1: every keyword the pack knows.
    gr_keywords/1,
    % gr_provenance/1: the provenance a grounded hint carries.
    gr_provenance/1
]).

% Use the list and string libraries.
:- use_module(library(lists)).

% gr_custom/3 holds caller-added templates; it changes at runtime, so it is dynamic.
:- dynamic gr_custom/3.

% gr_reset/0: forget every caller-added rule (the built-ins remain).
gr_reset :-
    % Remove all custom rules.
    retractall(gr_custom(_,_,_)).

% gr_rule_add/3: store a caller keyword template that mentions RefVar.
gr_rule_add(Keyword, RefVar, Template) :-
    % Assert it as a clause sharing RefVar between the referent slot and the body.
    assertz(gr_custom(Keyword, RefVar, Template)).

% gr_lookup/3: ground one keyword; a caller rule wins over a built-in.
gr_lookup(Keyword, Ref, Assertions) :-
    % Prefer a custom rule if one matches.
    ( gr_custom(Keyword, Ref, Assertions)
      -> true
    % Otherwise fall back to the built-in mapping.
    ;  gr_builtin(Keyword, Ref, Assertions) ).

% gr_ground/3: scan a clue for the first known keyword and ground it.
gr_ground(Clue, Ref, Assertions) :-
    % Normalise the clue into a list of lowercase word atoms.
    gr_tokens(Clue, Toks),
    % Take the first token that grounds to something; else ground to nothing.
    ( member(W, Toks), gr_lookup(W, Ref, A)
      -> Assertions = A
      ;  Assertions = [] ).

% gr_is_clue/1: a clue is a clue when it grounds to a non-empty assertion list.
gr_is_clue(Clue) :-
    % Ground it against a fresh referent and check the result is non-empty.
    gr_ground(Clue, _Ref, Assertions),
    Assertions \== [].

% gr_keywords/1: every keyword known, built-in plus custom, sorted and distinct.
gr_keywords(Keywords) :-
    % Collect built-in and custom keywords.
    findall(K, gr_builtin(K, _, _), Builtins),
    findall(K, gr_custom(K, _, _), Customs),
    % Combine and dedupe.
    append(Builtins, Customs, All),
    sort(All, Keywords).

% gr_provenance/1: a grounded hint is high-confidence but defeasible.
gr_provenance(prov(human_hint, 0.9)).

% ---- the fixed, inspectable built-in mapping (gr_builtin/3) -----------------

% A key-like object can be picked up and opens locks.
gr_builtin(key, Ref, [continuant(Ref, key_like), disposition(Ref, pick_up_able), disposition(Ref, opens_locks)]).
% A lock-like object is openable by a key and is a candidate open goal.
gr_builtin(lock, Ref, [continuant(Ref, lock_like), disposition(Ref, openable_by_key), goal(state(Ref, open))]).
% A door-like object is something to traverse.
gr_builtin(door, Ref, [continuant(Ref, door_like), goal(traverse(Ref))]).
% "pick" suggests a pickup action at high priority.
gr_builtin(pick, Ref, [action(pickup(Ref)), priority(pickup(Ref), high)]).
% "grab" is a synonym for pick.
gr_builtin(grab, Ref, [action(pickup(Ref)), priority(pickup(Ref), high)]).
% "take" is a synonym for pick.
gr_builtin(take, Ref, [action(pickup(Ref)), priority(pickup(Ref), high)]).
% "hurts" marks interacting with the referent preventive.
gr_builtin(hurts, Ref, [preventive(interact(Ref)), avoid(interact(Ref))]).
% "dangerous" also marks interaction preventive.
gr_builtin(dangerous, Ref, [preventive(interact(Ref)), avoid(interact(Ref))]).
% "touch" in a warning clue ("don't touch that") marks interaction preventive.
gr_builtin(touch, Ref, [preventive(interact(Ref)), avoid(interact(Ref))]).
% "good" is positive reinforcement on the recent path.
gr_builtin(good, _Ref, [reinforce(recent, positive)]).
% "worked" is positive reinforcement on the recent path.
gr_builtin(worked, _Ref, [reinforce(recent, positive)]).
% A wall-like object blocks movement.
gr_builtin(wall, Ref, [continuant(Ref, obstacle_like), disposition(Ref, blocks_movement)]).
% An exit-like object is something to reach.
gr_builtin(exit, Ref, [continuant(Ref, goal_like), goal(reach(Ref))]).
% A goal-like object is something to reach.
gr_builtin(goal, Ref, [continuant(Ref, goal_like), goal(reach(Ref))]).

% ---- internal --------------------------------------------------------------

% gr_tokens/2: normalise a clue (phrase atom or word list) to lowercase atoms.
gr_tokens(Clue, Toks) :-
    % A ready-made list of atoms is just lowercased element by element.
    ( is_list(Clue)
      -> findall(A, ( member(E, Clue), gr_downcase_atom(E, A) ), Toks)
    % A phrase atom or string is split on spaces and stripped of punctuation.
    ;  ( atom(Clue) -> atom_string(Clue, S) ; S = Clue ),
       split_string(S, " ", " .,!?;:'\"", Parts0),
       exclude(==(""), Parts0, Parts),
       findall(A, ( member(P, Parts), string_lower(P, L), atom_string(A, L) ), Toks) ).

% gr_downcase_atom/2: lowercase one atom (leaving non-atoms unchanged).
gr_downcase_atom(E, A) :-
    % Downcase an atom via its string form; pass anything else through.
    ( atom(E) -> string_lower(E, L), atom_string(A, L) ; A = E ).
