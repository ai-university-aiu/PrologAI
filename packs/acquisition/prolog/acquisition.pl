/*  PrologAI — Developmental Language Acquisition  (Specification PR 31)

    Acquires language bottom-up using the same coordination machinery as
    everything else.  Three stages:

    Stage 1 — Phoneme chaining:
        Phoneme percepts activated in series are linked by tandem relations;
        branching transitions become choices; categories over them yield
        word-formation rules.

    Stage 2 — Word grounding:
        Words ground to coincident percepts via pai_ground/3; words heard
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
        pai_chain_phonemes/2    — +PhonemeList, -WordCandidates
        pai_ground/3            — +WordForm, +PerceptRef, -GroundingId
        pai_symbolize/3         — +Signifier, +Signified, -SymbolismId
        pai_chain_promote/2     — +Units, -NextTierUnits
        pai_word_of/2           — +Sequence, -WordForm (query)
        pai_grounding_of/2      — +WordForm, -PerceptRef (query)
*/

:- module(acquisition, [
    pai_chain_phonemes/2,
    pai_ground/3,
    pai_symbolize/3,
    pai_chain_promote/2,
    pai_word_of/2,
    pai_grounding_of/2
]).

:- use_module(library(lists), [member/2, append/3]).
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

:- dynamic phoneme_chain/3.   % ChainId, PhonemeList, Count
:- dynamic word_form/3.       % ChainId, WordForm, Count
:- dynamic word_grounding/3.  % WordForm, PerceptRef, GroundingId
:- dynamic symbolism/4.       % Id, Signifier, Signified, Count
:- dynamic tier_unit/3.       % TierId, Tier, UnitList
:- dynamic acquisition_id_counter/1.
acquisition_id_counter(0).

next_acq_id(Id) :-
    retract(acquisition_id_counter(N)),
    N1 is N + 1,
    assertz(acquisition_id_counter(N1)),
    Id = N1.

% Minimum observations before promoting phoneme chain to word
promotion_threshold(3).

% ---------------------------------------------------------------------------
% pai_chain_phonemes/2
%
%   Given a list of phoneme atoms in arrival order, record the chain and
%   promote it to a word candidate when count >= promotion_threshold.
%
%   WordCandidates: list of word(Form, Count) for promoted chains.
% ---------------------------------------------------------------------------

pai_chain_phonemes(PhonemeList, WordCandidates) :-
    % Canonicalize: join phonemes to a form atom
    atomic_list_concat(PhonemeList, '-', Form),
    % Record or increment the chain
    ( retract(phoneme_chain(ChainId, PhonemeList, Count))
    ->  NewCount is Count + 1,
        assertz(phoneme_chain(ChainId, PhonemeList, NewCount))
    ;   next_acq_id(ChainId),
        NewCount = 1,
        assertz(phoneme_chain(ChainId, PhonemeList, NewCount))
    ),
    % Check promotion threshold
    promotion_threshold(Thresh),
    ( NewCount >= Thresh
    ->  ( retract(word_form(ChainId, Form, _))
        ->  assertz(word_form(ChainId, Form, NewCount))
        ;   assertz(word_form(ChainId, Form, NewCount))
        ),
        WordCandidates = [word(Form, NewCount)]
    ;   WordCandidates = []
    ).

% ---------------------------------------------------------------------------
% pai_ground/3
%
%   Ground a word form to a percept reference.
%   Words heard before their referents persist ungrounded (no error).
%   Multiple groundings are allowed (homophones carry context).
% ---------------------------------------------------------------------------

pai_ground(WordForm, PerceptRef, GroundingId) :-
    % Check if already grounded to this percept
    ( word_grounding(WordForm, PerceptRef, ExId)
    ->  GroundingId = ExId
    ;   next_acq_id(GroundingId),
        assertz(word_grounding(WordForm, PerceptRef, GroundingId))
    ).

% ---------------------------------------------------------------------------
% pai_symbolize/3
%
%   Record that Signifier (in present_zone) evokes Signified
%   (in recalled/imagined zone).  After repeated co-occurrence,
%   a symbolism/metaphor link is established.
% ---------------------------------------------------------------------------

pai_symbolize(Signifier, Signified, SymbolismId) :-
    ( retract(symbolism(ExId, Signifier, Signified, Count))
    ->  NewCount is Count + 1,
        assertz(symbolism(ExId, Signifier, Signified, NewCount)),
        SymbolismId = ExId
    ;   next_acq_id(SymbolismId),
        assertz(symbolism(SymbolismId, Signifier, Signified, 1))
    ).

% ---------------------------------------------------------------------------
% pai_chain_promote/2
%
%   Apply the same chaining logic one tier up:
%     phonemes → words → phrases → events → episodes → …
%
%   Units: list of unit(Form, Count) at current tier
%   NextTierUnits: list of promoted units at the next tier
% ---------------------------------------------------------------------------

pai_chain_promote(Units, NextTierUnits) :-
    % Join unit forms to build a higher-tier unit
    findall(F, member(unit(F, _), Units), Forms),
    atomic_list_concat(Forms, '+', CompositeForm),
    next_acq_id(TierId),
    assertz(tier_unit(TierId, composite, Forms)),
    NextTierUnits = [unit(CompositeForm, 1)].

% ---------------------------------------------------------------------------
% pai_word_of/2 — query: given a phoneme sequence, find the word form
% ---------------------------------------------------------------------------

pai_word_of(Sequence, WordForm) :-
    atomic_list_concat(Sequence, '-', WordForm),
    word_form(_, WordForm, _).

% ---------------------------------------------------------------------------
% pai_grounding_of/2 — query: find percept refs for a word form
% ---------------------------------------------------------------------------

pai_grounding_of(WordForm, PerceptRef) :-
    word_grounding(WordForm, PerceptRef, _).
