/*  PrologAI — Causalontology Clue Grounding  (WP-417, Layer 392)

    Causalontology_v5 Section 10 designs a human-guided learning application in
    which a person watching an interactive game gives clues — "that looks like a
    key," "pick that up," "that looks like a lock," "that looks like a door;
    let's walk through it," "don't touch that" — and each clue is grounded into a
    Causalontology assertion tagged as a high-confidence but DEFEASIBLE human
    hint. Section 10.4 names that seam grounding but the pack itself had not been
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
    high-confidence hint (grounding marks its provenance human_hint, 0.9), and if
    intervention later contradicts it the caller's defeasible machinery revises it.

    Predicates:
      grounding_reset/0            -- forget caller-added rules
      grounding_rule_add/3         -- +Keyword, +RefVar, +Template  (Template mentions RefVar)
      grounding_builtin/3          -- ?Keyword, ?Ref, ?Assertions    (the fixed mapping)
      grounding_lookup/3           -- +Keyword, +Ref, -Assertions    (custom first, then builtin)
      grounding_ground/3           -- +Clue, +Ref, -Assertions       (ground a whole clue)
      grounding_is_clue/1          -- +Clue                          (does it ground to anything?)
      grounding_keywords/1         -- -Keywords                      (every keyword known)
      grounding_provenance/1       -- -Provenance                    (prov(human_hint, 0.9))
*/

% Declare this module and its exported predicates.
:- module(grounding, [
    % grounding_reset/0: forget caller-added grounding rules.
    grounding_reset/0,
    % grounding_rule_add/3: add a caller keyword template.
    grounding_rule_add/3,
    % grounding_builtin/3: the fixed built-in keyword mapping.
    grounding_builtin/3,
    % grounding_lookup/3: ground a single keyword against a referent.
    grounding_lookup/3,
    % grounding_ground/3: ground a whole clue against a referent.
    grounding_ground/3,
    % grounding_is_clue/1: whether a clue grounds to anything.
    grounding_is_clue/1,
    % grounding_keywords/1: every keyword the pack knows.
    grounding_keywords/1,
    % grounding_provenance/1: the provenance a grounded hint carries.
    grounding_provenance/1
]).

% Use the list and string libraries.
:- use_module(library(lists)).

% grounding_custom/3 holds caller-added templates; it changes at runtime, so it is dynamic.
:- dynamic grounding_custom/3.

% grounding_reset/0: forget every caller-added rule (the built-ins remain).
grounding_reset :-
    % Remove all custom rules.
    retractall(grounding_custom(_,_,_)).

% grounding_rule_add/3: store a caller keyword template that mentions RefVar.
grounding_rule_add(Keyword, RefVar, Template) :-
    % Assert it as a clause sharing RefVar between the referent slot and the body.
    assertz(grounding_custom(Keyword, RefVar, Template)).

% grounding_lookup/3: ground one keyword; a caller rule wins over a built-in.
grounding_lookup(Keyword, Ref, Assertions) :-
    % Prefer a custom rule if one matches.
    ( grounding_custom(Keyword, Ref, Assertions)
      -> true
    % Otherwise fall back to the built-in mapping.
    ;  grounding_builtin(Keyword, Ref, Assertions) ).

% grounding_ground/3: scan a clue for the first known keyword and ground it.
grounding_ground(Clue, Ref, Assertions) :-
    % Normalise the clue into a list of lowercase word atoms.
    grounding_tokens(Clue, Toks),
    % Take the first token that grounds to something; else ground to nothing.
    ( member(W, Toks), grounding_lookup(W, Ref, A)
      -> Assertions = A
      ;  Assertions = [] ).

% grounding_is_clue/1: a clue is a clue when it grounds to a non-empty assertion list.
grounding_is_clue(Clue) :-
    % Ground it against a fresh referent and check the result is non-empty.
    grounding_ground(Clue, _Ref, Assertions),
    Assertions \== [].

% grounding_keywords/1: every keyword known, built-in plus custom, sorted and distinct.
grounding_keywords(Keywords) :-
    % Collect built-in and custom keywords.
    findall(K, grounding_builtin(K, _, _), Builtins),
    findall(K, grounding_custom(K, _, _), Customs),
    % Combine and dedupe.
    append(Builtins, Customs, All),
    sort(All, Keywords).

% grounding_provenance/1: a grounded hint is high-confidence but defeasible.
grounding_provenance(prov(human_hint, 0.9)).

% ---- the fixed, inspectable built-in mapping (grounding_builtin/3) -----------------

% A key-like object can be picked up and opens locks.
grounding_builtin(key, Ref, [continuant(Ref, key_like), disposition(Ref, pick_up_able), disposition(Ref, opens_locks)]).
% A lock-like object is openable by a key and is a candidate open goal.
grounding_builtin(lock, Ref, [continuant(Ref, lock_like), disposition(Ref, openable_by_key), goal(state(Ref, open))]).
% A door-like object is something to traverse.
grounding_builtin(door, Ref, [continuant(Ref, door_like), goal(traverse(Ref))]).
% "pick" suggests a pickup action at high priority.
grounding_builtin(pick, Ref, [action(pickup(Ref)), priority(pickup(Ref), high)]).
% "grab" is a synonym for pick.
grounding_builtin(grab, Ref, [action(pickup(Ref)), priority(pickup(Ref), high)]).
% "take" is a synonym for pick.
grounding_builtin(take, Ref, [action(pickup(Ref)), priority(pickup(Ref), high)]).
% "hurts" marks interacting with the referent preventive.
grounding_builtin(hurts, Ref, [preventive(interact(Ref)), avoid(interact(Ref))]).
% "dangerous" also marks interaction preventive.
grounding_builtin(dangerous, Ref, [preventive(interact(Ref)), avoid(interact(Ref))]).
% "touch" in a warning clue ("don't touch that") marks interaction preventive.
grounding_builtin(touch, Ref, [preventive(interact(Ref)), avoid(interact(Ref))]).
% "good" is positive reinforcement on the recent path.
grounding_builtin(good, _Ref, [reinforce(recent, positive)]).
% "worked" is positive reinforcement on the recent path.
grounding_builtin(worked, _Ref, [reinforce(recent, positive)]).
% A wall-like object blocks movement.
grounding_builtin(wall, Ref, [continuant(Ref, obstacle_like), disposition(Ref, blocks_movement)]).
% An exit-like object is something to reach.
grounding_builtin(exit, Ref, [continuant(Ref, goal_like), goal(reach(Ref))]).
% A goal-like object is something to reach.
grounding_builtin(goal, Ref, [continuant(Ref, goal_like), goal(reach(Ref))]).

% ---- internal --------------------------------------------------------------

% grounding_tokens/2: normalise a clue (phrase atom or word list) to lowercase atoms.
grounding_tokens(Clue, Toks) :-
    % A ready-made list of atoms is just lowercased element by element.
    ( is_list(Clue)
      -> findall(A, ( member(E, Clue), grounding_downcase_atom(E, A) ), Toks)
    % A phrase atom or string is split on spaces and stripped of punctuation.
    ;  ( atom(Clue) -> atom_string(Clue, S) ; S = Clue ),
       split_string(S, " ", " .,!?;:'\"", Parts0),
       exclude(==(""), Parts0, Parts),
       findall(A, ( member(P, Parts), string_lower(P, L), atom_string(A, L) ), Toks) ).

% grounding_downcase_atom/2: lowercase one atom (leaving non-atoms unchanged).
grounding_downcase_atom(E, A) :-
    % Downcase an atom via its string form; pass anything else through.
    ( atom(E) -> string_lower(E, L), atom_string(A, L) ; A = E ).
