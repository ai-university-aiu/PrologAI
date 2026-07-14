/*  PrologAI — Causalontology Lore  (WP-424, Layer 399)

    THE_BUILDING_FILES describe a mind that does not just remember episodes but
    learns their lessons: it notices when a kind of situation keeps recurring (a
    "theme"), pairs problems with the responses that worked (a "lesson"), and
    distils a piece of standing advice (a "maxim"). co_trace stores individual
    experience-cases and concept_formation groups objects into concepts; this pack sits
    above experience and turns repetition into guidance.

    An experience is a situation, the response taken, and how it turned out:

        experience(Situation, Response, Result)     Result = good | bad

    A THEME is a situation-pattern that recurs (seen at least twice). A LESSON is
    a response that a matching past situation tried, and its result — where a past
    situation "matches" the present one when its features are all present now
    (the pattern applies). A MAXIM is the standing advice for a theme: do the
    response that most often turned out good, or, if none did, avoid the one most
    associated with a bad result.

    Predicates:
      lore_reset/0            -- forget all experience
      lore_record/3           -- +Situation, +Response, +Result
      lore_experience/3       -- ?Situation, ?Response, ?Result
      lore_theme/2            -- ?Situation, -Count      (recurring situations, Count >= 2)
      lore_lesson/3           -- +CurrentSituation, -Response, -Result  (matching past lessons)
      lore_responses/2        -- +CurrentSituation, -Ranked   (resp(R,GoodFraction,Total), best first)
      lore_advise/3           -- +CurrentSituation, -Response, -Confidence  (best response)
      lore_maxim/2            -- ?Situation, -Maxim    (do(R) | avoid(R) for a theme)
      lore_count/1            -- -N                     (how many experiences recorded)
*/

% Declare this module and its exported predicates.
:- module(lore, [
    % lore_reset/0: forget all experience.
    lore_reset/0,
    % lore_record/3: record one experience.
    lore_record/3,
    % lore_experience/3: query recorded experience.
    lore_experience/3,
    % lore_theme/2: recurring situations and how often they recur.
    lore_theme/2,
    % lore_lesson/3: the lessons of past situations matching the present one.
    lore_lesson/3,
    % lore_responses/2: the responses for a situation, ranked by success.
    lore_responses/2,
    % lore_advise/3: the response that most often turned out good.
    lore_advise/3,
    % lore_maxim/2: the standing advice for a recurring theme.
    lore_maxim/2,
    % lore_count/1: how many experiences are recorded.
    lore_count/1
]).

% Use the list library.
:- use_module(library(lists)).
% Use the ordered-set library for subset matching over sorted feature lists.
:- use_module(library(ordsets)).

% experience/3 is one recorded experience; it changes at runtime, so it is dynamic.
:- dynamic experience/3.

% lore_reset/0: forget every recorded experience.
lore_reset :-
    % Remove all experiences.
    retractall(experience(_,_,_)).

% lore_record/3: record one experience, normalising its situation to a sorted set.
lore_record(Situation, Response, Result) :-
    % Normalise the situation features into a sorted set.
    sort(Situation, Sorted),
    % Log the experience (repetition is meaningful, so duplicates are kept).
    assertz(experience(Sorted, Response, Result)).

% lore_experience/3: expose the recorded experiences.
lore_experience(Situation, Response, Result) :-
    % Read the stored experience.
    experience(Situation, Response, Result).

% lore_theme/2: a situation that recurs, with how many times it has been seen.
lore_theme(Situation, Count) :-
    % Consider each distinct recorded situation.
    setof(S, R^Res^experience(S, R, Res), Situations),
    member(Situation, Situations),
    % Count how often it recurs.
    aggregate_all(count, experience(Situation, _, _), Count),
    % A theme is a situation seen at least twice.
    Count >= 2.

% lore_lesson/3: a response a matching past situation tried, and its result.
lore_lesson(CurrentSituation, Response, Result) :-
    % Normalise the present situation.
    sort(CurrentSituation, Current),
    % A past experience matches when its pattern is present now.
    experience(Past, Response, Result),
    ord_subset(Past, Current).

% lore_responses/2: the responses for a situation, ranked by their success fraction.
lore_responses(CurrentSituation, Ranked) :-
    % Normalise the present situation.
    sort(CurrentSituation, Current),
    % The distinct responses tried in matching past situations.
    setof(R, lore_matching_response(Current, R), Responses),
    % Score each response by how often it turned out good.
    findall(GoodFrac-resp(R, GoodFrac, Total),
            ( member(R, Responses),
              lore_response_stats(Current, R, Good, Total),
              GoodFrac is Good / Total ),
            Scored),
    % Sort by success fraction descending, keeping ties.
    sort(1, @>=, Scored, SortedPairs),
    % Drop the sort keys, keeping the resp/3 records.
    findall(Resp, member(_-Resp, SortedPairs), Ranked).

% lore_advise/3: the response that most often turned out good, with its confidence.
lore_advise(CurrentSituation, Response, Confidence) :-
    % Rank the responses and take the best.
    lore_responses(CurrentSituation, [resp(Response, Confidence, _) | _]).

% lore_maxim/2: the standing advice for a recurring theme.
lore_maxim(Situation, Maxim) :-
    % A given situation is normalised and checked once; an unbound one enumerates.
    ( ground(Situation)
      -> sort(Situation, Key), once(lore_theme(Key, _))
      ;  Key = Situation, lore_theme(Key, _) ),
    % Rank its responses.
    lore_responses(Key, Ranked),
    Ranked = [resp(Best, BestFrac, _) | _],
    % Advise doing the best response if it usually works, else avoiding the worst.
    ( BestFrac > 0.5
      -> Maxim = do(Best)
      ;  last(Ranked, resp(Worst, _, _)),
         Maxim = avoid(Worst) ).

% lore_count/1: how many experiences have been recorded.
lore_count(N) :-
    % Count the experience facts.
    aggregate_all(count, experience(_,_,_), N).

% ---- internal --------------------------------------------------------------

% lore_matching_response/2: a response tried in a past situation matching Current.
lore_matching_response(Current, Response) :-
    % A matching past experience contributes its response.
    experience(Past, Response, _),
    ord_subset(Past, Current).

% lore_response_stats/4: good and total counts for a response across matches.
lore_response_stats(Current, Response, Good, Total) :-
    % Count matching experiences with this response that turned out good.
    aggregate_all(count,
                  ( experience(Past, Response, good), ord_subset(Past, Current) ),
                  Good),
    % Count all matching experiences with this response.
    aggregate_all(count,
                  ( experience(Past, Response, _), ord_subset(Past, Current) ),
                  Total).
