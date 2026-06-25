% Module declaration: run pack, Layer 67.
:- module(run, [
    % rn_encode/2: run-length encode a flat list to Value-Count pairs.
    rn_encode/2,
    % rn_decode/2: run-length decode Value-Count pairs to a flat list.
    rn_decode/2,
    % rn_row_encode/3: run-length encode a single grid row.
    rn_row_encode/3,
    % rn_col_encode/3: run-length encode a single grid column.
    rn_col_encode/3,
    % rn_grid_rows/2: run-length encode every row of a grid.
    rn_grid_rows/2,
    % rn_grid_cols/2: run-length encode every column of a grid.
    rn_grid_cols/2,
    % rn_length/2: total number of elements represented by a run list.
    rn_length/2,
    % rn_at/3: value at a 0-indexed position within a run list.
    rn_at/3,
    % rn_max_run/3: length of the longest run of a given value.
    rn_max_run/3,
    % rn_count_runs/3: number of distinct runs of a given value.
    rn_count_runs/3,
    % rn_uniform/1: true when all values in a run list are the same.
    rn_uniform/1,
    % rn_trim/3: remove leading and trailing occurrences of a value.
    rn_trim/3,
    % rn_repeat/3: repeat the encoded pattern N times and merge adjacent runs.
    rn_repeat/3,
    % rn_positions/3: 0-indexed positions of all cells with a given value.
    rn_positions/3
]).

% Import list utilities; msort/length/forall are built-ins, not imported.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, reverse/2,
                                append/3, max_list/2]).
% Import higher-order apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% rn_encode(+List, -Runs).
% Run-length encode a flat list of values into a list of Value-Count pairs.
% Consecutive equal values are collapsed: [1,1,2,1] -> [1-2, 2-1, 1-1].
rn_encode([], []).
rn_encode([V|Vs], [V-N|Runs]) :-
    % Count how many consecutive values equal V starting from the head.
    rn_take_same_(V, Vs, N1, Tail),
    % The head contributes 1, plus the count from rn_take_same_.
    N is N1 + 1,
    % Encode the remainder of the list.
    rn_encode(Tail, Runs).

% rn_take_same_(+V, +List, -Count, -Tail).
% Count how many leading elements of List equal V; Tail is the remainder.
rn_take_same_(_, [], 0, []) :- !.
rn_take_same_(V, [H|T], N, Tail) :-
    % Use if-then-else to avoid choicepoint on integer comparison.
    ( V =:= H ->
        rn_take_same_(V, T, N1, Tail),
        N is N1 + 1
    ;   N = 0, Tail = [H|T]
    ).

% rn_decode(+Runs, -List).
% Run-length decode a list of Value-Count pairs into a flat list.
% [1-2, 2-3] -> [1,1,2,2,2].
rn_decode([], []).
rn_decode([V-N|Rest], List) :-
    % Build a segment of N copies of V.
    length(Segment, N),
    maplist(=(V), Segment),
    % Decode the remaining runs.
    rn_decode(Rest, Tail),
    % Concatenate this segment with the decoded tail.
    append(Segment, Tail, List).

% rn_row_encode(+Grid, +R, -Runs).
% Run-length encode row R (0-indexed) of Grid.
rn_row_encode(Grid, R, Runs) :-
    % Extract row R by 0-indexed lookup.
    nth0(R, Grid, Row),
    % Encode the row as a run-length list.
    rn_encode(Row, Runs).

% rn_col_encode(+Grid, +C, -Runs).
% Run-length encode column C (0-indexed) of Grid.
rn_col_encode(Grid, C, Runs) :-
    % Extract the C-th element from each row to form the column list.
    maplist(nth0(C), Grid, Col),
    % Encode the column as a run-length list.
    rn_encode(Col, Runs).

% rn_grid_rows(+Grid, -RowRuns).
% Produce the run-length encoding of every row in Grid.
% RowRuns[i] is the run-length encoding of row i.
rn_grid_rows(Grid, RowRuns) :-
    % Map rn_encode over each row.
    maplist(rn_encode, Grid, RowRuns).

% rn_grid_cols(+Grid, -ColRuns).
% Produce the run-length encoding of every column in Grid.
% ColRuns[j] is the run-length encoding of column j.
rn_grid_cols(Grid, ColRuns) :-
    % Compute the number of columns from the first row.
    ( Grid = [FR|_] -> length(FR, Cols) ; Cols = 0 ),
    Cols1 is Cols - 1,
    % Build the list of column indices.
    numlist(0, Cols1, Cs),
    % Encode each column.
    maplist(rn_col_encode(Grid), Cs, ColRuns).

% rn_length(+Runs, -N).
% N is the total number of elements represented by Runs.
rn_length([], 0).
rn_length([_-N|Rest], Total) :-
    % Recurse on the tail and add this run's count.
    rn_length(Rest, RestTotal),
    Total is RestTotal + N.

% rn_at(+Runs, +I, -V).
% V is the value at 0-indexed position I in the run-length sequence.
rn_at([Val-N|Rest], I, V) :-
    % Use if-then-else to avoid choicepoint on integer comparison.
    ( I < N ->
        V = Val
    ;   I2 is I - N,
        rn_at(Rest, I2, V)
    ).

% rn_max_run(+Runs, +Color, -MaxLen).
% MaxLen is the length of the longest single run of Color in Runs.
% MaxLen = 0 if Color does not appear.
rn_max_run(Runs, Color, MaxLen) :-
    % Collect all run lengths for Color.
    findall(N, member(Color-N, Runs), Ns),
    % Take the maximum; 0 if empty.
    ( Ns = [] -> MaxLen = 0 ; max_list(Ns, MaxLen) ).

% rn_count_runs(+Runs, +Color, -N).
% N is the number of distinct runs of Color in Runs.
rn_count_runs(Runs, Color, N) :-
    % Count all entries in Runs whose value equals Color.
    findall(L, member(Color-L, Runs), Ls),
    length(Ls, N).

% rn_uniform(+Runs).
% True when every run in Runs has the same value (the sequence is all one color).
% Succeeds vacuously for an empty run list.
rn_uniform([]).
rn_uniform([_-_]) :- !.
rn_uniform([V-_, V-N2|Rest]) :-
    % Both the first and second run must share the same value V.
    rn_uniform([V-N2|Rest]).

% rn_trim(+List, +BG, -Trimmed).
% Remove all leading and trailing occurrences of BG from List.
% Interior BG values are left unchanged.
rn_trim(List, BG, Trimmed) :-
    % Drop leading BG values.
    rn_drop_while_(List, BG, Middle),
    % Reverse, drop leading BG values again (= trailing from original), reverse back.
    reverse(Middle, Rev),
    rn_drop_while_(Rev, BG, RevTrimmed),
    reverse(RevTrimmed, Trimmed).

% rn_drop_while_(+List, +V, -Rest).
% Drop elements equal to V from the front of List; Rest is what remains.
rn_drop_while_([], _, []) :- !.
rn_drop_while_([H|T], V, Rest) :-
    % Use if-then-else on integer comparison to avoid choicepoint.
    ( H =:= V ->
        rn_drop_while_(T, V, Rest)
    ;   Rest = [H|T]
    ).

% rn_repeat(+Runs, +N, -Runs2).
% Repeat the encoded sequence N times.
% Adjacent same-value runs at repetition boundaries are merged.
% Example: rn_repeat([1-2,2-1], 2, [1-2,2-1,1-2,2-1]).
rn_repeat(Runs, N, Runs2) :-
    % Build a flat list of all run pairs repeated N times.
    findall(V-C, (between(1, N, _), member(V-C, Runs)), AllRuns),
    % Merge adjacent runs that share the same value.
    rn_merge_adjacent_(AllRuns, Runs2).

% rn_merge_adjacent_(+Runs, -Merged).
% Merge consecutive runs with the same value into a single run.
rn_merge_adjacent_([], []) :- !.
rn_merge_adjacent_([Run], [Run]) :- !.
rn_merge_adjacent_([V-N1, W-N2|Rest], Merged) :-
    % Use if-then-else on integer comparison to avoid choicepoint.
    ( V =:= W ->
        N12 is N1 + N2,
        rn_merge_adjacent_([V-N12|Rest], Merged)
    ;   rn_merge_adjacent_([W-N2|Rest], RestMerged),
        Merged = [V-N1|RestMerged]
    ).

% rn_positions(+Runs, +Color, -Positions).
% Positions is the sorted list of 0-indexed positions where Color appears.
rn_positions(Runs, Color, Positions) :-
    % Accumulate positions by scanning runs from offset 0.
    rn_positions_(Runs, Color, 0, Positions).

% rn_positions_(+Runs, +Color, +Offset, -Positions).
% Internal: enumerate positions starting at Offset.
rn_positions_([], _, _, []).
rn_positions_([V-N|Rest], Color, Offset, Positions) :-
    % Compute the offset for the next run.
    Next is Offset + N,
    ( V =:= Color ->
        % This run contributes positions Offset, Offset+1, ..., Offset+N-1.
        Last is Offset + N - 1,
        numlist(Offset, Last, Ps),
        rn_positions_(Rest, Color, Next, RestPs),
        append(Ps, RestPs, Positions)
    ;   % This run contributes no positions for Color.
        rn_positions_(Rest, Color, Next, Positions)
    ).
