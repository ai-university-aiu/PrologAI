% Module declaration with all fourteen public predicates.
:- module(taskcat, [
% Classify a task from its training pairs into a category atom.
    taskcat_categorize/2,
% Succeed if training pairs are consistent with a single-rule explanation.
    taskcat_is_single_rule/1,
% Succeed if training pairs require 2 or more sequential steps.
    taskcat_is_multi_step/1,
% Succeed if some input feature modulates which rule variant applies.
    taskcat_has_context_gate/1,
% Succeed if some objects appear to function as task-defined symbols.
    taskcat_has_symbol_table/1,
% Given a category, return an ordered list of solving strategies to try.
    taskcat_suggest_strategies/2,
% Succeed if every training pair preserves grid dimensions.
    taskcat_preserves_dims/1,
% Succeed if every training pair preserves the input color set.
    taskcat_preserves_colors/1,
% Succeed if the number of changed cells is the same across all training pairs.
    taskcat_consistent_change_count/1,
% Return the maximum number of cells changed in any single training pair.
    taskcat_max_change_count/2,
% Return the number of distinct change patterns across all training pairs.
    taskcat_distinct_change_patterns/2,
% Succeed if all training pairs change ONLY background-to-color (no color-to-color).
    taskcat_is_fill_task/1,
% Succeed if the output is a strict subset of the input cells (deletion-only task).
    taskcat_is_deletion_task/1,
% Compute a confidence score (0.0-1.0) for the suggested primary category.
    taskcat_confidence/2
]).
% taskcat.pl - Layer 252: Task Type Classifier (tc_* prefix).
% Fourteen predicates for classifying a grid transformation task by type and
% selecting the appropriate solving strategy. This implements the "Chain of
% Responsibility" solving pattern: try single_rule, then multi_step, then
% context_gated, then symbol_table. Each category maps to a strategy list.
% Training pairs are pair(InputGrid, OutputGrid) terms.
% Categories: single_rule, multi_step, context_gated, symbol_table.
% Strategies: [simple_rule_search, seqinfer_2step, seqinfer_3step,
%              context_gate_search, symbol_table_learning].
:- use_module(library(lists), [member/2, subtract/3, numlist/3, last/2]).
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% --- PRIVATE HELPERS ---

% taskcat_grid_dims_/3: grid dimensions.
taskcat_grid_dims_(Grid, Rows, Cols) :-
    length(Grid, Rows),
    (Grid = [Row|_] -> length(Row, Cols) ; Cols = 0).

% taskcat_cell_diff_/3: list of r(R,C) positions where In and Out differ.
taskcat_cell_diff_(In, Out, Changed) :-
    length(In, Rows), Rows1 is Rows - 1,
    numlist(0, Rows1, RowIdxs),
    findall(r(R,C),
        (member(R, RowIdxs),
         nth0(R, In, InRow), nth0(R, Out, OutRow),
         length(InRow, Cols), Cols1 is Cols - 1,
         numlist(0, Cols1, ColIdxs),
         member(C, ColIdxs),
         nth0(C, InRow, IV), nth0(C, OutRow, OV),
         IV \= OV),
        Changed).

% taskcat_pair_change_count_/2: number of changed cells in a pair.
taskcat_pair_change_count_(pair(In, Out), N) :-
    taskcat_cell_diff_(In, Out, Changed), length(Changed, N).

% taskcat_pair_dims_preserved_/1: succeed if pair preserves grid dimensions.
taskcat_pair_dims_preserved_(pair(In, Out)) :-
    taskcat_grid_dims_(In, R, C), taskcat_grid_dims_(Out, R, C).

% taskcat_grid_colors_/3: sorted non-bg colors in a grid.
taskcat_grid_colors_(Grid, BgColor, Colors) :-
    findall(V, (member(Row, Grid), member(V, Row), V \= BgColor), All),
    sort(All, Colors).

% taskcat_pair_colors_preserved_/1: succeed if pair preserves color set.
taskcat_pair_colors_preserved_(pair(In, Out)) :-
    taskcat_grid_colors_(In, 0, CI), taskcat_grid_colors_(Out, 0, CO),
    CI = CO.

% taskcat_change_pattern_/2: abstract change pattern for a pair (sorted changed cell colors).
taskcat_change_pattern_(pair(In, Out), Pattern) :-
    taskcat_cell_diff_(In, Out, Changed),
    findall(V, (member(r(R,C), Changed), nth0(R, In, InRow), nth0(C, InRow, V)), Colors),
    msort(Colors, Pattern).

% taskcat_color_covariation_/2: succeed if some input color covaries with output changes.
taskcat_color_covariation_(Pairs, GateColor) :-
    findall(C, (member(pair(In, _), Pairs),
                member(Row, In), member(C, Row), C \= 0), InColors),
    sort(InColors, AllInColors),
    member(GateColor, AllInColors),
    include(taskcat_input_has_color_(GateColor), Pairs, WithColor),
    subtract(Pairs, WithColor, WithoutColor),
    WithColor \= [],
    WithoutColor \= [],
    findall(N, (member(P, WithColor), taskcat_pair_change_count_(P, N)), NWith),
    findall(N, (member(P, WithoutColor), taskcat_pair_change_count_(P, N)), NWithout),
    msort(NWith, SWith), msort(NWithout, SWithout),
    SWith \= SWithout.

% taskcat_input_has_color_/2: succeed if Color appears in pair's input.
taskcat_input_has_color_(Color, pair(In, _)) :-
    member(Row, In), member(Color, Row), !.

% --- PUBLIC PREDICATES ---

% taskcat_categorize(+Pairs, -Category)
% Classify the task as: single_rule, multi_step, context_gated, or symbol_table.
% Uses an ordered chain: simplest hypothesis that fits wins.
taskcat_categorize(Pairs, Category) :-
    (taskcat_is_single_rule(Pairs) -> Category = single_rule ;
     taskcat_is_multi_step(Pairs) -> Category = multi_step ;
     taskcat_has_context_gate(Pairs) -> Category = context_gated ;
     Category = symbol_table).

% taskcat_is_single_rule(+Pairs)
% Succeed if all pairs show the same change count AND the same change pattern
% AND dims are preserved. This suggests a single rule applies uniformly.
taskcat_is_single_rule(Pairs) :-
    Pairs \= [],
    maplist(taskcat_pair_dims_preserved_, Pairs),
    taskcat_consistent_change_count(Pairs),
    findall(Pat, (member(P, Pairs), taskcat_change_pattern_(P, Pat)), Patterns),
    sort(Patterns, Sorted),
    length(Sorted, 1).

% taskcat_is_multi_step(+Pairs)
% Succeed if taskcat_max_change_count exceeds 4x the average for some pair
% OR if there are 3 or more distinct change patterns (suggesting staged transforms).
taskcat_is_multi_step(Pairs) :-
    Pairs \= [],
    taskcat_max_change_count(Pairs, MaxN),
    MaxN >= 4,
    findall(N, (member(P, Pairs), taskcat_pair_change_count_(P, N)), Counts),
    length(Counts, TotalPairs),
    TotalPairs > 0,
    sumlist(Counts, Sum),
    Avg is Sum / TotalPairs,
    (MaxN > Avg * 1.5 ;
     taskcat_distinct_change_patterns(Pairs, NPatterns), NPatterns >= 2).

% taskcat_has_context_gate(+Pairs)
% Succeed if some input color consistently separates pairs by change count.
% This indicates a context gate (a feature that switches which rule fires).
taskcat_has_context_gate(Pairs) :-
    Pairs \= [],
    taskcat_color_covariation_(Pairs, _).

% taskcat_has_symbol_table(+Pairs)
% Succeed if the number of distinct non-bg input colors > output non-bg colors
% consistently across pairs (suggesting some input colors are symbols, not content).
taskcat_has_symbol_table(Pairs) :-
    Pairs \= [],
    findall(Diff,
        (member(pair(In, Out), Pairs),
         taskcat_grid_colors_(In, 0, CI), length(CI, NI),
         taskcat_grid_colors_(Out, 0, CO), length(CO, NO),
         Diff is NI - NO),
        Diffs),
    Diffs \= [],
    include([D]>>(D > 0), Diffs, Positive),
    length(Diffs, Total), length(Positive, NPos),
    NPos * 2 > Total.

% taskcat_suggest_strategies(+Category, -Strategies)
% Return an ordered list of solving strategies for the given category.
% Strategies are tried in order; later entries are fallbacks.
taskcat_suggest_strategies(single_rule, [simple_rule_search, seqinfer_2step]).
taskcat_suggest_strategies(multi_step, [seqinfer_2step, seqinfer_3step, simple_rule_search]).
taskcat_suggest_strategies(context_gated, [context_gate_search, seqinfer_2step, simple_rule_search]).
taskcat_suggest_strategies(symbol_table, [symbol_table_learning, context_gate_search, seqinfer_2step]).
taskcat_suggest_strategies(_, [simple_rule_search, seqinfer_2step, seqinfer_3step]).

% taskcat_preserves_dims(+Pairs)
% Succeed if every training pair preserves grid dimensions.
taskcat_preserves_dims(Pairs) :-
    maplist(taskcat_pair_dims_preserved_, Pairs).

% taskcat_preserves_colors(+Pairs)
% Succeed if every training pair preserves the non-background color set.
taskcat_preserves_colors(Pairs) :-
    maplist(taskcat_pair_colors_preserved_, Pairs).

% taskcat_consistent_change_count(+Pairs)
% Succeed if the number of changed cells is the same in every training pair.
taskcat_consistent_change_count(Pairs) :-
    findall(N, (member(P, Pairs), taskcat_pair_change_count_(P, N)), Counts),
    sort(Counts, Sorted),
    Sorted = [_].

% taskcat_max_change_count(+Pairs, -MaxN)
% MaxN is the maximum number of cells changed in any single training pair.
taskcat_max_change_count(Pairs, MaxN) :-
    findall(N, (member(P, Pairs), taskcat_pair_change_count_(P, N)), Counts),
    (Counts = [] -> MaxN = 0 ; max_list(Counts, MaxN)).

% taskcat_distinct_change_patterns(+Pairs, -N)
% N is the number of distinct change patterns across all training pairs.
taskcat_distinct_change_patterns(Pairs, N) :-
    findall(Pat, (member(P, Pairs), taskcat_change_pattern_(P, Pat)), Patterns),
    sort(Patterns, Sorted),
    length(Sorted, N).

% taskcat_is_fill_task(+Pairs)
% Succeed if all training pairs change cells from 0 (background) to some other color.
% A pure "fill" task adds color to empty cells but never removes existing color.
taskcat_is_fill_task(Pairs) :-
    Pairs \= [],
    forall(member(pair(In, Out), Pairs),
        forall(
            (taskcat_cell_diff_(In, Out, Changed), member(r(R,C), Changed),
             nth0(R, Out, OutRow), nth0(C, OutRow, OutV)),
            (nth0(R, In, InRow), nth0(C, InRow, 0), OutV \= 0)
        )
    ).

% taskcat_is_deletion_task(+Pairs)
% Succeed if all training pairs only remove cells (color to background).
% A pure "deletion" task converts color cells to background (0) but never adds color.
taskcat_is_deletion_task(Pairs) :-
    Pairs \= [],
    forall(member(pair(In, Out), Pairs),
        forall(
            (taskcat_cell_diff_(In, Out, Changed), member(r(R,C), Changed),
             nth0(R, Out, OutRow), nth0(C, OutRow, OutV)),
            (OutV =:= 0)
        )
    ).

% taskcat_confidence(+Pairs, -Score)
% Score is a 0.0-1.0 confidence estimate for the primary category.
% Based on: dims_preserved, consistent_count, distinct_patterns.
taskcat_confidence(Pairs, Score) :-
    Pairs \= [],
    (taskcat_preserves_dims(Pairs) -> D = 1 ; D = 0),
    (taskcat_consistent_change_count(Pairs) -> C = 1 ; C = 0),
    taskcat_distinct_change_patterns(Pairs, NP),
    (NP =:= 1 -> P = 1 ; NP =< 3 -> P = 0 ; P = -1),
    RawScore is (D + C + P) / 3,
    Score is max(0.0, min(1.0, RawScore)).
