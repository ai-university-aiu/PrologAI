:- module(gridchain, [
    gridchain_pairs/2,
    gridchain_window/3,
    gridchain_zip/3,
    gridchain_take/3,
    gridchain_drop/3,
    gridchain_nth/3,
    gridchain_all_same/1,
    gridchain_dedup/2,
    gridchain_cycle/3,
    gridchain_interleave/3,
    gridchain_split_at/4,
    gridchain_reverse/2,
    gridchain_diff_counts/3,
    gridchain_changes_mask/4
]).
% gridchain.pl - Layer 234: Grid Sequence Utilities (gch_* prefix).
% Fourteen predicates for structural manipulation of sequences (lists) of grids.
% Covers consecutive pairing, sliding windows, zip, take, drop, 0-indexed access,
% sameness testing, deduplication, repetition, interleaving, splitting, reversal,
% pairwise diff counts, and first-vs-last change mask.
% Grids in a sequence need not share dimensions unless explicitly required.
% No cross-pack dependencies.
:- use_module(library(lists), [member/2, nth0/3, reverse/2, last/2, append/3, length/2]).

% --- PRIVATE HELPERS ---

% gridchain_sublist_/4: extract Len elements starting at index Start from List.
gridchain_sublist_(List, Start, Len, SubList) :-
% Skip the first Start elements.
    length(Prefix, Start),
    append(Prefix, Rest, List),
% Take the next Len elements.
    length(SubList, Len),
    append(SubList, _, Rest).

% gridchain_count_cell_diffs_/3: count positions where two same-length rows differ.
gridchain_count_cell_diffs_([], [], 0).
gridchain_count_cell_diffs_([V|T1], [V|T2], N) :- !,
% Matching values contribute zero to the count.
    gridchain_count_cell_diffs_(T1, T2, N).
gridchain_count_cell_diffs_([_|T1], [_|T2], N) :-
% Non-matching values increment count by one.
    gridchain_count_cell_diffs_(T1, T2, N1),
    N is N1 + 1.

% gridchain_count_row_diffs_/3: total count of differing cells across two same-shaped grids.
gridchain_count_row_diffs_([], [], 0).
gridchain_count_row_diffs_([R1|T1], [R2|T2], N) :-
    gridchain_count_cell_diffs_(R1, R2, N1),
    gridchain_count_row_diffs_(T1, T2, N2),
    N is N1 + N2.

% gridchain_diff_mask_cells_/5: build a row marking differing positions with MarkColor.
gridchain_diff_mask_cells_([], [], _, _, []).
gridchain_diff_mask_cells_([V1|T1], [V2|T2], Bg, MC, [V|Vs]) :-
% Mark differing positions; unchanged positions become Bg.
    (V1 \= V2 -> V = MC ; V = Bg),
    gridchain_diff_mask_cells_(T1, T2, Bg, MC, Vs).

% gridchain_diff_mask_rows_/5: build a grid marking all differing positions.
gridchain_diff_mask_rows_([], [], _, _, []).
gridchain_diff_mask_rows_([R1|T1], [R2|T2], Bg, MC, [NR|Rest]) :-
    gridchain_diff_mask_cells_(R1, R2, Bg, MC, NR),
    gridchain_diff_mask_rows_(T1, T2, Bg, MC, Rest).

% --- PUBLIC PREDICATES ---

% gridchain_pairs(+Grids, -Pairs)
% Produce the list of consecutive two-element sublists: [[G1,G2],[G2,G3],...].
% An empty or single-element sequence produces an empty Pairs list.
gridchain_pairs(Grids, Pairs) :-
    length(Grids, N),
    (N >= 2 ->
        Last is N - 2,
        findall([G1,G2],
            (between(0, Last, I),
             nth0(I, Grids, G1),
             I1 is I + 1,
             nth0(I1, Grids, G2)),
            Pairs)
    ;
        Pairs = []
    ).

% gridchain_window(+Grids, +W, -Windows)
% Produce all consecutive sublists of length W (sliding window).
% Windows = [[G1,...,GW], [G2,...,GW+1], ...].
gridchain_window(Grids, W, Windows) :-
    length(Grids, N),
    (W =< N ->
        Last is N - W,
        findall(Window,
            (between(0, Last, I), gridchain_sublist_(Grids, I, W, Window)),
            Windows)
    ;
        Windows = []
    ).

% gridchain_zip(+Grids1, +Grids2, -ZippedPairs)
% Zip two sequences element-wise: ZippedPairs = [[G1a,G1b],[G2a,G2b],...].
% Terminates at the shorter sequence.
gridchain_zip([], _, []) :- !.
gridchain_zip(_, [], []) :- !.
gridchain_zip([G1|T1], [G2|T2], [[G1,G2]|Rest]) :-
    gridchain_zip(T1, T2, Rest).

% gridchain_take(+Grids, +N, -Taken)
% Return the first N grids from the sequence.
% If N >= length(Grids), returns all grids.
gridchain_take(Grids, N, Taken) :-
    length(Grids, Len),
    N2 is min(N, Len),
    length(Taken, N2),
    append(Taken, _, Grids).

% gridchain_drop(+Grids, +N, -Rest)
% Drop the first N grids and return the remainder.
% If N >= length(Grids), returns [].
gridchain_drop(Grids, N, Rest) :-
    length(Grids, Len),
    N2 is min(N, Len),
    length(Prefix, N2),
    append(Prefix, Rest, Grids).

% gridchain_nth(+Grids, +N, -Grid)
% Return the 0-indexed N-th grid from the sequence.
gridchain_nth(Grids, N, Grid) :-
    nth0(N, Grids, Grid).

% gridchain_all_same(+Grids)
% Succeed if all grids in the sequence are identical (by unification).
% An empty sequence trivially succeeds; a single-element sequence succeeds.
gridchain_all_same([]) :- !.
gridchain_all_same([_]) :- !.
gridchain_all_same([G, G | Rest]) :-
    gridchain_all_same([G | Rest]).

% gridchain_dedup(+Grids, -Unique)
% Remove duplicate grids, preserving first occurrence.
% Two grids are duplicates if they are identical by unification.
gridchain_dedup(Grids, Unique) :-
    gridchain_dedup_(Grids, [], Unique).

% gridchain_dedup_/3: accumulate seen grids and filter duplicates.
gridchain_dedup_([], _, []).
gridchain_dedup_([H|T], Seen, Result) :-
    (member(H, Seen) ->
        gridchain_dedup_(T, Seen, Result)
    ;
        Result = [H|Rest],
        gridchain_dedup_(T, [H|Seen], Rest)
    ).

% gridchain_cycle(+Grid, +N, -Sequence)
% Build a sequence of N copies of Grid.
gridchain_cycle(Grid, N, Sequence) :-
    findall(Grid, between(1, N, _), Sequence).

% gridchain_interleave(+Grids1, +Grids2, -Interleaved)
% Interleave two sequences: [G1a, G1b, G2a, G2b, ...].
% Terminates when the shorter sequence is exhausted.
gridchain_interleave([], _, []) :- !.
gridchain_interleave(_, [], []) :- !.
gridchain_interleave([G1|T1], [G2|T2], [G1, G2 | Rest]) :-
    gridchain_interleave(T1, T2, Rest).

% gridchain_split_at(+Grids, +N, -Before, -After)
% Split the sequence at index N: Before has the first N grids; After has the rest.
gridchain_split_at(Grids, N, Before, After) :-
    length(Before, N),
    append(Before, After, Grids).

% gridchain_reverse(+Grids, -Reversed)
% Reverse the sequence of grids.
gridchain_reverse(Grids, Reversed) :-
    reverse(Grids, Reversed).

% gridchain_diff_counts(+Grids, +BgColor, -Counts)
% For each consecutive pair of grids, count the number of positions where they differ.
% Counts is a list of non-negative integers, one per consecutive pair.
% BgColor is accepted but not used in counting (all differences count regardless of color).
gridchain_diff_counts(Grids, _Bg, Counts) :-
    gridchain_pairs(Grids, Pairs),
    findall(N, (member([G1,G2], Pairs), gridchain_count_row_diffs_(G1, G2, N)), Counts).

% gridchain_changes_mask(+Grids, +BgColor, +MarkColor, -Mask)
% Compare the first and last grids in the sequence.
% Mask has MarkColor at positions where first \= last; BgColor at unchanged positions.
% Requires at least two grids; single-element sequence returns all-BgColor mask.
gridchain_changes_mask([G], Bg, _MC, Mask) :- !,
% Single grid: no changes → all-bg mask with same dimensions as G.
    findall(Row, (member(GRow, G), findall(Bg, member(_, GRow), Row)), Mask).
gridchain_changes_mask([First|Rest], Bg, MC, Mask) :-
    last([First|Rest], LastG),
    gridchain_diff_mask_rows_(First, LastG, Bg, MC, Mask).
