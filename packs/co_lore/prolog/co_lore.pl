/*  PrologAI — Causalontology Lore  (WP-424, Layer 399)

    THE_BUILDING_FILES describe a mind that does not just remember episodes but
    learns their lessons: it notices when a kind of situation keeps recurring (a
    "theme"), pairs problems with the responses that worked (a "lesson"), and
    distils a piece of standing advice (a "maxim"). co_trace stores individual
    experience-cases and co_forge groups objects into concepts; this pack sits
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
      lo_reset/0            -- forget all experience
      lo_record/3           -- +Situation, +Response, +Result
      lo_experience/3       -- ?Situation, ?Response, ?Result
      lo_theme/2            -- ?Situation, -Count      (recurring situations, Count >= 2)
      lo_lesson/3           -- +CurrentSituation, -Response, -Result  (matching past lessons)
      lo_responses/2        -- +CurrentSituation, -Ranked   (resp(R,GoodFraction,Total), best first)
      lo_advise/3           -- +CurrentSituation, -Response, -Confidence  (best response)
      lo_maxim/2            -- ?Situation, -Maxim    (do(R) | avoid(R) for a theme)
      lo_count/1            -- -N                     (how many experiences recorded)
*/

% Declare this module and its exported predicates.
:- module(co_lore, [
    % lo_reset/0: forget all experience.
    lo_reset/0,
    % lo_record/3: record one experience.
    lo_record/3,
    % lo_experience/3: query recorded experience.
    lo_experience/3,
    % lo_theme/2: recurring situations and how often they recur.
    lo_theme/2,
    % lo_lesson/3: the lessons of past situations matching the present one.
    lo_lesson/3,
    % lo_responses/2: the responses for a situation, ranked by success.
    lo_responses/2,
    % lo_advise/3: the response that most often turned out good.
    lo_advise/3,
    % lo_maxim/2: the standing advice for a recurring theme.
    lo_maxim/2,
    % lo_count/1: how many experiences are recorded.
    lo_count/1
]).

% Use the list library.
:- use_module(library(lists)).
% Use the ordered-set library for subset matching over sorted feature lists.
:- use_module(library(ordsets)).

% experience/3 is one recorded experience; it changes at runtime, so it is dynamic.
:- dynamic experience/3.

% lo_reset/0: forget every recorded experience.
lo_reset :-
    % Remove all experiences.
    retractall(experience(_,_,_)).

% lo_record/3: record one experience, normalising its situation to a sorted set.
lo_record(Situation, Response, Result) :-
    % Normalise the situation features into a sorted set.
    sort(Situation, Sorted),
    % Log the experience (repetition is meaningful, so duplicates are kept).
    assertz(experience(Sorted, Response, Result)).

% lo_experience/3: expose the recorded experiences.
lo_experience(Situation, Response, Result) :-
    % Read the stored experience.
    experience(Situation, Response, Result).

% lo_theme/2: a situation that recurs, with how many times it has been seen.
lo_theme(Situation, Count) :-
    % Consider each distinct recorded situation.
    setof(S, R^Res^experience(S, R, Res), Situations),
    member(Situation, Situations),
    % Count how often it recurs.
    aggregate_all(count, experience(Situation, _, _), Count),
    % A theme is a situation seen at least twice.
    Count >= 2.

% lo_lesson/3: a response a matching past situation tried, and its result.
lo_lesson(CurrentSituation, Response, Result) :-
    % Normalise the present situation.
    sort(CurrentSituation, Current),
    % A past experience matches when its pattern is present now.
    experience(Past, Response, Result),
    ord_subset(Past, Current).

% lo_responses/2: the responses for a situation, ranked by their success fraction.
lo_responses(CurrentSituation, Ranked) :-
    % Normalise the present situation.
    sort(CurrentSituation, Current),
    % The distinct responses tried in matching past situations.
    setof(R, lo_matching_response(Current, R), Responses),
    % Score each response by how often it turned out good.
    findall(GoodFrac-resp(R, GoodFrac, Total),
            ( member(R, Responses),
              lo_response_stats(Current, R, Good, Total),
              GoodFrac is Good / Total ),
            Scored),
    % Sort by success fraction descending, keeping ties.
    sort(1, @>=, Scored, SortedPairs),
    % Drop the sort keys, keeping the resp/3 records.
    findall(Resp, member(_-Resp, SortedPairs), Ranked).

% lo_advise/3: the response that most often turned out good, with its confidence.
lo_advise(CurrentSituation, Response, Confidence) :-
    % Rank the responses and take the best.
    lo_responses(CurrentSituation, [resp(Response, Confidence, _) | _]).

% lo_maxim/2: the standing advice for a recurring theme.
lo_maxim(Situation, Maxim) :-
    % A given situation is normalised and checked once; an unbound one enumerates.
    ( ground(Situation)
      -> sort(Situation, Key), once(lo_theme(Key, _))
      ;  Key = Situation, lo_theme(Key, _) ),
    % Rank its responses.
    lo_responses(Key, Ranked),
    Ranked = [resp(Best, BestFrac, _) | _],
    % Advise doing the best response if it usually works, else avoiding the worst.
    ( BestFrac > 0.5
      -> Maxim = do(Best)
      ;  last(Ranked, resp(Worst, _, _)),
         Maxim = avoid(Worst) ).

% lo_count/1: how many experiences have been recorded.
lo_count(N) :-
    % Count the experience facts.
    aggregate_all(count, experience(_,_,_), N).

% ---- internal --------------------------------------------------------------

% lo_matching_response/2: a response tried in a past situation matching Current.
lo_matching_response(Current, Response) :-
    % A matching past experience contributes its response.
    experience(Past, Response, _),
    ord_subset(Past, Current).

% lo_response_stats/4: good and total counts for a response across matches.
lo_response_stats(Current, Response, Good, Total) :-
    % Count matching experiences with this response that turned out good.
    aggregate_all(count,
                  ( experience(Past, Response, good), ord_subset(Past, Current) ),
                  Good),
    % Count all matching experiences with this response.
    aggregate_all(count,
                  ( experience(Past, Response, _), ord_subset(Past, Current) ),
                  Total).
