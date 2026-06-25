% recur.pl - Layer 99: Arithmetic Progression and Periodic Recurrence Detection (rc_* prefix).
% Detects arithmetic progressions, repetition cycles, and cyclic patterns in lists.
:- module(recur, [
    rc_arith/4,
    rc_arith_step/2,
    rc_is_arith/2,
    rc_repeat/3,
    rc_period/2,
    rc_is_periodic/2,
    rc_next_arith/3,
    rc_next_repeat/3,
    rc_extend_arith/4,
    rc_extend_repeat/4,
    rc_cycle_nth/3,
    rc_zip_with/4,
    rc_diff_list/2,
    rc_const_diffs/2
]).
% Import list utilities for indexing and enumeration.
:- use_module(library(lists), [nth0/3, numlist/3, append/2, append/3]).
% Import higher-order utilities for mapping over lists.
:- use_module(library(apply), [maplist/2, maplist/3]).

% rc_arith(+Start, +Step, +N, -Seq): generate arithmetic sequence of N terms.
% Seq = [Start, Start+Step, Start+2*Step, ..., Start+(N-1)*Step].
rc_arith(Start, Step, N, Seq) :-
% Build index list 0 through N-1.
    N > 0, N1 is N - 1, numlist(0, N1, Idxs),
% Each term V = Start + Idx * Step.
    maplist([I, V]>>(V is Start + I * Step), Idxs, Seq).

% rc_check_step_: verify all consecutive pairs in List differ by exactly Step.
rc_check_step_([_], _) :- !.
rc_check_step_([A,B|Rest], Step) :-
% Difference must match Step.
    D is B - A, D =:= Step,
% Continue checking from B onward.
    rc_check_step_([B|Rest], Step).

% rc_arith_step(+Seq, -Step): extract common difference of an arithmetic sequence.
% Seq must have at least 2 elements. Fails if differences are not all equal.
rc_arith_step([A,B|Rest], Step) :-
% Compute first difference.
    Step is B - A,
% Verify all subsequent differences match.
    rc_check_step_([B|Rest], Step).

% rc_is_arith(+Seq, -Step): succeed if Seq is an arithmetic sequence with difference Step.
rc_is_arith(Seq, Step) :-
% Delegate fully to rc_arith_step which checks all consecutive differences.
    rc_arith_step(Seq, Step).

% rc_repeat(+Unit, +N, -Seq): Seq is Unit repeated exactly N times end-to-end.
rc_repeat(Unit, N, Seq) :-
% Create list of N copies of Unit using built-in length/2.
    length(Copies, N),
    maplist(=(Unit), Copies),
% Flatten all copies into one list.
    append(Copies, Seq).

% rc_period(+Seq, -Unit): the minimal repeating unit of Seq.
% Tries period lengths 1, 2, ... until one that divides length(Seq) reproduces Seq.
rc_period(Seq, Unit) :-
% Total length of the sequence.
    length(Seq, L),
% Try each candidate period length P from 1 up to L.
    between(1, L, P),
% P must evenly divide L.
    0 is L mod P,
% Extract a candidate unit of length P.
    length(Unit, P),
    append(Unit, _, Seq),
% Verify repeating Unit exactly L/P times reconstructs Seq.
    Reps is L // P,
    rc_repeat(Unit, Reps, Seq), !.

% rc_is_periodic(+Seq, -Unit): succeed if Seq is an exact repetition of Unit.
% Returns the minimal period unit.
rc_is_periodic(Seq, Unit) :-
    rc_period(Seq, Unit).

% rc_last_: get the last element of a non-empty list.
rc_last_([X], X) :- !.
rc_last_([_|T], X) :-
    rc_last_(T, X).

% rc_next_arith(+Seq, +N, -Next): compute the next N terms of an arithmetic sequence.
% Detects the step from Seq and continues from the last element.
rc_next_arith(Seq, N, Next) :-
% Detect the common difference.
    rc_arith_step(Seq, Step),
% Find the last element to continue from.
    rc_last_(Seq, Last),
    Start is Last + Step,
% Generate the next N terms.
    rc_arith(Start, Step, N, Next).

% rc_next_repeat(+Seq, +N, -Next): compute the next N terms of a periodic sequence.
% Finds the minimal period of Seq and cycles from the current offset.
rc_next_repeat(Seq, N, Next) :-
% Find the minimal repeating unit.
    rc_period(Seq, Unit),
    length(Unit, P),
    length(Seq, L),
% Offset into the unit where the sequence ends.
    Offset is L mod P,
% Generate N continuation values by cycling the unit from Offset.
    numlist(1, N, Idxs),
    maplist([I, V]>>(Idx is (Offset + I - 1) mod P, nth0(Idx, Unit, V)), Idxs, Next).

% rc_extend_arith(+Seq, +N, -Extended, -Step): extend arithmetic Seq by N more terms.
% Extended is Seq followed by the N continuation terms; Step is the detected difference.
rc_extend_arith(Seq, N, Extended, Step) :-
% Extract the common difference.
    rc_arith_step(Seq, Step),
% Generate the N continuation terms.
    rc_next_arith(Seq, N, Next),
% Append continuation to original.
    append(Seq, Next, Extended).

% rc_extend_repeat(+Seq, +N, -Extended, -Unit): extend periodic Seq by N more terms.
% Extended is Seq followed by the N continuation terms; Unit is the minimal period.
rc_extend_repeat(Seq, N, Extended, Unit) :-
% Find the minimal period.
    rc_period(Seq, Unit),
% Generate the N continuation terms.
    rc_next_repeat(Seq, N, Next),
% Append continuation to original.
    append(Seq, Next, Extended).

% rc_cycle_nth(+Unit, +N, -V): the N-th term (1-based) of the infinite cycle of Unit.
% Wraps around using modular arithmetic.
rc_cycle_nth(Unit, N, V) :-
% Period length.
    length(Unit, P),
% Convert to 0-based index with wraparound.
    Idx is (N - 1) mod P,
% Look up the value.
    nth0(Idx, Unit, V).

% rc_zip_with(+List1, +List2, :Goal, -Result): pair-wise application of a 3-arg goal.
% Calls Goal(A, B, C) for each pair (A from List1, B from List2) to produce C in Result.
rc_zip_with([], [], _, []).
rc_zip_with([A|As], [B|Bs], Goal, [C|Cs]) :-
% Apply Goal to the current pair to produce C.
    call(Goal, A, B, C),
% Recurse on the remaining pairs.
    rc_zip_with(As, Bs, Goal, Cs).

% rc_diff_list(+Seq, -Diffs): consecutive element-wise differences of a numeric sequence.
% Diffs has exactly one fewer element than Seq.
rc_diff_list([_], []) :- !.
rc_diff_list([A,B|Rest], [D|Ds]) :-
% D = B - A.
    D is B - A,
% Recurse for remaining pairs.
    rc_diff_list([B|Rest], Ds).

% rc_const_diffs(+Seq, -Step): succeed if all consecutive differences in Seq equal Step.
% Equivalent to rc_is_arith but names the constant difference explicitly.
rc_const_diffs(Seq, Step) :-
% Compute all differences.
    rc_diff_list(Seq, Diffs),
% There must be at least one difference.
    Diffs = [Step|Rest],
% All differences must equal Step.
    maplist(=:=(Step), Rest).
