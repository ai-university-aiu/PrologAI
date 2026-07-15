/*  PrologAI — Developmental Language Acquisition  (Specification PR 31)

    Acquires language bottom-up using the same coordination machinery as
    everything else.  Three stages:

    Stage 1 — Phoneme chaining:
        Phoneme percepts activated in series are linked by tandem relations;
        branching transitions become choices; categories over them yield
        word-formation rules.

    Stage 2 — Word grounding:
        Words ground to coincident percepts via acquisition_ground/3; words heard
        before their referents persist ungrounded, ready to ground later;
        homophones carry context in their choice gates.

    Stage 3 — Tier promotion:
        The same chaining reapplies one tier up: phonemes → words → phrases
        → events → episodes → scenarios → frames → lessons → themes → maxims;
        symbolisms form where a signifier in present_zone repeatedly evokes
        a signified in recalled or imagined zone (metaphor_actor).

    Invariant: the pipeline runs entirely on the coordination specialist
    roster — language is acquired by the same machinery as everything else.

    Predicates:
        acquisition_chain_phonemes/2    — +PhonemeList, -WordCandidates
        acquisition_ground/3            — +WordForm, +PerceptRef, -GroundingId
        acquisition_symbolize/3         — +Signifier, +Signified, -SymbolismId
        acquisition_chain_promote/2     — +Units, -NextTierUnits
        acquisition_word_of/2           — +Sequence, -WordForm (query)
        acquisition_grounding_of/2      — +WordForm, -PerceptRef (query)
*/

% Declare this file as the 'acquisition' module and list its exported predicates.
:- module(acquisition, [
    % Supply 'acquisition_chain_phonemes/2' as the next argument to the expression above.
    acquisition_chain_phonemes/2,
    % Supply 'acquisition_ground/3' as the next argument to the expression above.
    acquisition_ground/3,
    % Supply 'acquisition_symbolize/3' as the next argument to the expression above.
    acquisition_symbolize/3,
    % Supply 'acquisition_chain_promote/2' as the next argument to the expression above.
    acquisition_chain_promote/2,
    % Supply 'acquisition_word_of/2' as the next argument to the expression above.
    acquisition_word_of/2,
    % Supply 'acquisition_grounding_of/2' as the next argument to the expression above.
    acquisition_grounding_of/2
% Close the expression opened above.
]).

% Import [member/2, append/3] from the built-in 'lists' library.
:- use_module(library(lists), [member/2, append/3]).
% Import [aggregate_all/3] from the built-in 'aggregate' library.
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% Declare 'phoneme_chain/3.   % ChainId, PhonemeList, Count' as dynamic — its facts may be added or removed at runtime.
:- dynamic phoneme_chain/3.   % ChainId, PhonemeList, Count
% Declare 'word_form/3.       % ChainId, WordForm, Count' as dynamic — its facts may be added or removed at runtime.
:- dynamic word_form/3.       % ChainId, WordForm, Count
% Declare 'word_grounding/3.  % WordForm, PerceptRef, GroundingId' as dynamic — its facts may be added or removed at runtime.
:- dynamic word_grounding/3.  % WordForm, PerceptRef, GroundingId
% Declare 'symbolism/4.       % Id, Signifier, Signified, Count' as dynamic — its facts may be added or removed at runtime.
:- dynamic symbolism/4.       % Id, Signifier, Signified, Count
% Declare 'tier_unit/3.       % TierId, Tier, UnitList' as dynamic — its facts may be added or removed at runtime.
:- dynamic tier_unit/3.       % TierId, Tier, UnitList
% Declare 'acquisition_id_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic acquisition_id_counter/1.
% State the fact: acquisition id counter(0).
acquisition_id_counter(0).

% Define a clause for 'next acq id': succeed when the following conditions hold.
next_acq_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(acquisition_id_counter(N)),
    % Evaluate the arithmetic expression 'N + 1' and bind the result to 'N1'.
    N1 is N + 1,
    % Add a new fact or rule to the runtime knowledge base.
    assertz(acquisition_id_counter(N1)),
    % Check that 'Id' is unifiable with 'N1'.
    Id = N1.

% Minimum observations before promoting phoneme chain to word
% State the fact: promotion threshold(3).
promotion_threshold(3).

% ---------------------------------------------------------------------------
% acquisition_chain_phonemes/2
%
%   Given a list of phoneme atoms in arrival order, record the chain and
%   promote it to a word candidate when count >= promotion_threshold.
%
%   WordCandidates: list of word(Form, Count) for promoted chains.
% ---------------------------------------------------------------------------

% Define a clause for 'pai chain phonemes': succeed when the following conditions hold.
acquisition_chain_phonemes(PhonemeList, WordCandidates) :-
    % Canonicalize: join phonemes to a form atom
    % State a fact for 'atomic list concat' with the arguments listed below.
    atomic_list_concat(PhonemeList, '-', Form),
    % Record or increment the chain
    % Execute: ( retract(phoneme_chain(ChainId, PhonemeList, Count)).
    ( retract(phoneme_chain(ChainId, PhonemeList, Count))
    % If the condition above succeeded, perform the following action.
    ->  NewCount is Count + 1,
        % Continue the multi-line expression started above.
        assertz(phoneme_chain(ChainId, PhonemeList, NewCount))
    % Otherwise (else branch), perform the following action.
    ;   next_acq_id(ChainId),
        % Continue the multi-line expression started above.
        NewCount = 1,
        % Continue the multi-line expression started above.
        assertz(phoneme_chain(ChainId, PhonemeList, NewCount))
    % Close the expression opened above.
    ),
    % Check promotion threshold
    % State a fact for 'promotion threshold' with the arguments listed below.
    promotion_threshold(Thresh),
    % Check that '( NewCount' is greater than or equal to 'Thresh'.
    ( NewCount >= Thresh
    % If the condition above succeeded, perform the following action.
    ->  ( retract(word_form(ChainId, Form, _))
        % If the condition above succeeded, perform the following action.
        ->  assertz(word_form(ChainId, Form, NewCount))
        % Otherwise (else branch), perform the following action.
        ;   assertz(word_form(ChainId, Form, NewCount))
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        WordCandidates = [word(Form, NewCount)]
    % Otherwise (else branch), perform the following action.
    ;   WordCandidates = []
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% acquisition_ground/3
%
%   Ground a word form to a percept reference.
%   Words heard before their referents persist ungrounded (no error).
%   Multiple groundings are allowed (homophones carry context).
% ---------------------------------------------------------------------------

% Define a clause for 'pai ground': succeed when the following conditions hold.
acquisition_ground(WordForm, PerceptRef, GroundingId) :-
    % Check if already grounded to this percept
    % Execute: ( word_grounding(WordForm, PerceptRef, ExId).
    ( word_grounding(WordForm, PerceptRef, ExId)
    % If the condition above succeeded, perform the following action.
    ->  GroundingId = ExId
    % Otherwise (else branch), perform the following action.
    ;   next_acq_id(GroundingId),
        % Continue the multi-line expression started above.
        assertz(word_grounding(WordForm, PerceptRef, GroundingId))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% acquisition_symbolize/3
%
%   Record that Signifier (in present_zone) evokes Signified
%   (in recalled/imagined zone).  After repeated co-occurrence,
%   a symbolism/metaphor link is established.
% ---------------------------------------------------------------------------

% Define a clause for 'pai symbolize': succeed when the following conditions hold.
acquisition_symbolize(Signifier, Signified, SymbolismId) :-
    % Execute: ( retract(symbolism(ExId, Signifier, Signified, Count)).
    ( retract(symbolism(ExId, Signifier, Signified, Count))
    % If the condition above succeeded, perform the following action.
    ->  NewCount is Count + 1,
        % Continue the multi-line expression started above.
        assertz(symbolism(ExId, Signifier, Signified, NewCount)),
        % Continue the multi-line expression started above.
        SymbolismId = ExId
    % Otherwise (else branch), perform the following action.
    ;   next_acq_id(SymbolismId),
        % Continue the multi-line expression started above.
        assertz(symbolism(SymbolismId, Signifier, Signified, 1))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% acquisition_chain_promote/2
%
%   Apply the same chaining logic one tier up:
%     phonemes → words → phrases → events → episodes → …
%
%   Units: list of unit(Form, Count) at current tier
%   NextTierUnits: list of promoted units at the next tier
% ---------------------------------------------------------------------------

% Define a clause for 'pai chain promote': succeed when the following conditions hold.
acquisition_chain_promote(Units, NextTierUnits) :-
    % Join unit forms to build a higher-tier unit
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(F, member(unit(F, _), Units), Forms),
    % State a fact for 'atomic list concat' with the arguments listed below.
    atomic_list_concat(Forms, '+', CompositeForm),
    % State a fact for 'next acq id' with the arguments listed below.
    next_acq_id(TierId),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(tier_unit(TierId, composite, Forms)),
    % Check that 'NextTierUnits' is unifiable with '[unit(CompositeForm, 1)]'.
    NextTierUnits = [unit(CompositeForm, 1)].

% ---------------------------------------------------------------------------
% acquisition_word_of/2 — query: given a phoneme sequence, find the word form
% ---------------------------------------------------------------------------

% Define a clause for 'pai word of': succeed when the following conditions hold.
acquisition_word_of(Sequence, WordForm) :-
    % State a fact for 'atomic list concat' with the arguments listed below.
    atomic_list_concat(Sequence, '-', WordForm),
    % State the fact: word form(_, WordForm, _).
    word_form(_, WordForm, _).

% ---------------------------------------------------------------------------
% acquisition_grounding_of/2 — query: find percept refs for a word form
% ---------------------------------------------------------------------------

% Define a clause for 'pai grounding of': succeed when the following conditions hold.
acquisition_grounding_of(WordForm, PerceptRef) :-
    % State the fact: word grounding(WordForm, PerceptRef, _).
    word_grounding(WordForm, PerceptRef, _).
