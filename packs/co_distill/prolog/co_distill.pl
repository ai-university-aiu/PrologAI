/*  PrologAI — Causalontology Consolidation  (WP-416, Layer 391)

    THE_BUILDING_FILES are blunt: you cannot build a learning system without
    committing to forgetting. Left alone, a mind's memory grows without bound and
    slows to a crawl. Consolidation is the night shift that keeps memory compact:
    it merges duplicates, compresses a reliably repeated sequence into a single
    composite, and forgets stale, unused, low-value material — but only past a
    grace period, so nothing important is dropped abruptly. No co_ pack did this;
    this one does.

    It keeps a small store of records:

        rec(Key, Value, Uses, Recency)

      Key      the record's identity; re-adding the same key MERGES — it bumps
               the use count and refreshes the value and recency (dedup).
      Value    the payload.
      Uses     how many times the record has been added or touched — its value.
      Recency  a rising stamp (higher = fresher); an internal counter, not a
               clock, so consolidation is deterministic and testable.

    Forgetting drops a record only when it is BOTH low-value (Uses below a floor)
    AND stale (Recency below a grace cutoff), so a fresh-but-unused record is
    spared by the grace period and a well-used old record is spared by its value.

    Predicates:
      di_reset/0            -- empty the store, restart the recency clock
      di_add/2              -- +Key, +Value   (insert, or merge if the key exists)
      di_touch/1            -- +Key           (mark a record used again)
      di_compress/3         -- +Name, +Sequence, -Composite  (reify a run as one unit)
      di_record/4           -- ?Key, ?Value, ?Uses, ?Recency
      di_forget/3           -- +MinUses, +GraceCutoff, -Dropped   (prune, count dropped)
      di_time/1             -- -Now           (the current recency stamp)
      di_count/1            -- -N
      di_stats/1            -- -stats(Count, TotalUses)
*/

% Declare this module and its exported predicates.
:- module(co_distill, [
    % di_reset/0: empty the store and restart the clock.
    di_reset/0,
    % di_add/2: insert a record, merging on a repeated key.
    di_add/2,
    % di_touch/1: mark an existing record used again.
    di_touch/1,
    % di_compress/3: reify a repeated sequence as a single composite record.
    di_compress/3,
    % di_record/4: query the stored records.
    di_record/4,
    % di_forget/3: prune stale, low-value records past the grace period.
    di_forget/3,
    % di_time/1: the current recency stamp.
    di_time/1,
    % di_count/1: how many records are stored.
    di_count/1,
    % di_stats/1: a small summary of the store.
    di_stats/1
]).

% Use the list library.
:- use_module(library(lists)).

% rec/4 is one stored record; it changes at runtime, so it is dynamic.
:- dynamic rec/4.
% di_clock/1 is the rising recency counter.
:- dynamic di_clock/1.

% di_reset/0: forget every record and restart the recency clock at zero.
di_reset :-
    % Remove all records.
    retractall(rec(_,_,_,_)),
    % Remove any clock.
    retractall(di_clock(_)),
    % Seed the clock at zero.
    assertz(di_clock(0)).

% di_tick/1: consume the next recency stamp, advancing the clock.
di_tick(Next) :-
    % Read and advance the clock, seeding it if absent.
    ( retract(di_clock(Now)) -> true ; Now = 0 ),
    Next is Now + 1,
    assertz(di_clock(Next)).

% di_add/2: insert a record; a repeated key merges (bumps uses, refreshes value).
di_add(Key, Value) :-
    % If the key exists, take its use count and increment; else start at one.
    ( retract(rec(Key, _OldValue, U0, _)) -> U is U0 + 1 ; U = 1 ),
    % Stamp it fresh.
    di_tick(R),
    % Store the merged or new record.
    assertz(rec(Key, Value, U, R)).

% di_touch/1: mark an existing record used again without changing its value.
di_touch(Key) :-
    % Retract the current record for the key.
    retract(rec(Key, Value, U0, _)),
    % Increment its use count.
    U is U0 + 1,
    % Refresh its recency.
    di_tick(R),
    % Re-assert it.
    assertz(rec(Key, Value, U, R)).

% di_compress/3: reify a repeated sequence into one composite record and term.
di_compress(Name, Sequence, composite(Name, Sequence)) :-
    % Store the composite as a single record keyed by its name.
    di_add(Name, sequence(Sequence)).

% di_record/4: expose the stored records.
di_record(Key, Value, Uses, Recency) :-
    % Read the stored record.
    rec(Key, Value, Uses, Recency).

% di_forget/3: drop records that are both low-value and stale; count the drops.
di_forget(MinUses, GraceCutoff, Dropped) :-
    % Find every record below the use floor AND below the grace cutoff.
    findall(Key,
            ( rec(Key, _, U, R),
              U < MinUses,
              R < GraceCutoff ),
            Keys),
    % Retract each doomed record.
    forall(member(K, Keys), retract(rec(K, _, _, _))),
    % Report how many were forgotten.
    length(Keys, Dropped).

% di_time/1: the current recency stamp, so a caller can set a grace cutoff.
di_time(Now) :-
    % Read the clock, defaulting to zero.
    ( di_clock(Now) -> true ; Now = 0 ).

% di_count/1: how many records are stored.
di_count(N) :-
    % Count the records.
    aggregate_all(count, rec(_,_,_,_), N).

% di_stats/1: a small summary — the record count and the total use count.
di_stats(stats(Count, TotalUses)) :-
    % Count the records.
    di_count(Count),
    % Sum every record's use count.
    aggregate_all(sum(U), rec(_, _, U, _), TotalUses).
