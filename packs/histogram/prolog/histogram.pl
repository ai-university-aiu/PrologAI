% histogram.pl - Layer 110: Value Frequency Analysis (hi_* prefix).
% Provides predicates for counting occurrences, computing frequency tables,
% finding the most and least common values, sorting values by frequency,
% testing uniformity, extracting top-N values, ranking by frequency, and
% computing frequency tables and modal colors from 2D integer grids.
:- module(histogram, [
    hi_count/3,
    hi_freq/2,
    hi_mode/3,
    hi_rare/3,
    hi_unique_vals/2,
    hi_unique_count/2,
    hi_sorted_by_freq/2,
    hi_top_n/3,
    hi_has_value/2,
    hi_all_equal/2,
    hi_grid_freq/2,
    hi_grid_mode/3,
    hi_grid_rare/3,
    hi_rank/3
]).
% Import list utilities.
:- use_module(library(lists), [member/2, memberchk/2, append/2, nth1/3, last/2]).
% Import higher-order filtering.
:- use_module(library(apply), [include/3]).

% hi_count(+List, +V, -N): N is the number of times value V appears in List.
% Uses include/3 with ==(V) to collect matching elements, then counts them.
hi_count(List, V, N) :-
% Keep only elements structurally equal to V.
    include(==(V), List, Matches),
% Count the matching elements.
    length(Matches, N).

% hi_freq(+List, -Pairs): Pairs is the list of V-Count pairs for every distinct
% value in List, sorted by value ascending. Empty list gives [].
hi_freq(List, Pairs) :-
% Compute the sorted list of distinct values.
    sort(List, Unique),
% For each unique value, count occurrences and build a V-N pair.
    findall(V-N, (member(V, Unique), hi_count(List, V, N)), Pairs).

% hi_mode(+List, -V, -N): V is the most frequent value in List; N is its count.
% On ties the value with the smallest sort order wins (from hi_sorted_by_freq).
% Fails if List is empty.
hi_mode(List, V, N) :-
% Take the first element of the sorted-by-frequency list.
    hi_sorted_by_freq(List, [V-N|_]).

% hi_rare(+List, -V, -N): V is the least frequent value in List; N is its count.
% On ties the value with the largest sort order wins (last element of sorted list).
% Fails if List is empty.
hi_rare(List, V, N) :-
% Sort by frequency descending then take the last element.
    hi_sorted_by_freq(List, Pairs),
    last(Pairs, V-N).

% hi_unique_vals(+List, -Vals): Vals is the sorted list of distinct values in List.
hi_unique_vals(List, Vals) :-
% sort/2 removes duplicates and sorts ascending.
    sort(List, Vals).

% hi_unique_count(+List, -N): N is the number of distinct values in List.
hi_unique_count(List, N) :-
% Compute distinct values, then count them.
    sort(List, Unique),
    length(Unique, N).

% hi_sorted_by_freq(+List, -Pairs): Pairs is the list of V-Count pairs sorted
% by Count descending. Ties in count are broken by value ascending.
hi_sorted_by_freq(List, Pairs) :-
% Get the V-Count pairs sorted by value.
    hi_freq(List, FreqPairs),
% Build NegCount-V pairs so keysort (ascending) gives count-descending order.
    findall(NegN-V, (member(V-N, FreqPairs), NegN is -N), Keyed),
% Sort by NegCount ascending (= Count descending); stable preserves V order on ties.
    keysort(Keyed, Sorted),
% Recover V-Count pairs from the sorted NegCount-V list.
    findall(V-N, (member(NegN-V, Sorted), N is -NegN), Pairs).

% hi_top_n(+List, +N, -TopN): TopN is the list of the N most frequent V-Count
% pairs from List. Fails if List has fewer than N distinct values.
hi_top_n(List, N, TopN) :-
% Sort all values by frequency.
    hi_sorted_by_freq(List, Pairs),
% Take the first N pairs as a prefix of Pairs.
    length(TopN, N),
    append(TopN, _, Pairs).

% hi_has_value(+List, +V): succeed if V appears at least once in List.
hi_has_value(List, V) :-
% memberchk is deterministic: succeeds on first match, no choicepoint.
    memberchk(V, List).

% hi_all_equal(+List, -V): succeed if every element of List equals V.
% V is unified with the first element. Fails for empty lists.
hi_all_equal([H|T], H) :-
% Verify every remaining element equals H by arithmetic equality.
    forall(member(X, T), X =:= H).

% hi_grid_freq(+Grid, -Pairs): Pairs is the frequency table of all cell values
% in Grid (a list of rows), sorted by value ascending.
hi_grid_freq(Grid, Pairs) :-
% Flatten the grid (list of rows) into a single cell list.
    append(Grid, Flat),
% Compute the frequency table of the flattened list.
    hi_freq(Flat, Pairs).

% hi_grid_mode(+Grid, -Color, -Count): Color is the most frequent cell value
% in Grid; Count is its occurrence count.
hi_grid_mode(Grid, Color, Count) :-
% Flatten the grid and find the mode of the resulting list.
    append(Grid, Flat),
    hi_mode(Flat, Color, Count).

% hi_grid_rare(+Grid, -Color, -Count): Color is the least frequent cell value
% in Grid; Count is its occurrence count.
hi_grid_rare(Grid, Color, Count) :-
% Flatten the grid and find the rarest value of the resulting list.
    append(Grid, Flat),
    hi_rare(Flat, Color, Count).

% hi_rank(+List, +V, -Rank): Rank is the 1-based rank of value V by frequency
% in List, where Rank 1 is the most frequent. Fails if V does not appear.
hi_rank(List, V, Rank) :-
% Sort by frequency descending to get the rank ordering.
    hi_sorted_by_freq(List, Pairs),
% Find the 1-based position of V-_ in the ordered list.
    nth1(Rank, Pairs, V-_),
% Cut after first match: each distinct value appears exactly once.
    !.
