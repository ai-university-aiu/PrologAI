% PLUnit tests for the score pack (sc_* predicates).
:- use_module(library(plunit)).
:- use_module('../prolog/score').

% Helper rules for pair scoring tests.
identity_rule_(Grid, Grid).
all_zeros_rule_(Grid, Grid2) :-
    length(Grid, R),
    ( Grid = [FR|_] -> length(FR, C) ; C = 0 ),
    numlist(0, R, Rs0), length(Rs0, R),
    findall(Row, (between(1, R, _), findall(0, between(1, C, _), Row)), Grid2).

:- begin_tests(sc_exact).

test(exact_same) :-
    % Two identical grids.
    sc_exact([[1,2],[3,4]], [[1,2],[3,4]]).

test(exact_single) :-
    % Single-cell grid.
    sc_exact([[5]], [[5]]).

test(exact_fail) :-
    % Different grids: must fail.
    \+ sc_exact([[1,2],[3,4]], [[1,2],[3,5]]).

:- end_tests(sc_exact).

:- begin_tests(sc_cell_match).

test(match_all) :-
    % All cells match.
    sc_cell_match([[1,2],[3,4]], [[1,2],[3,4]], N),
    N =:= 4.

test(match_none) :-
    % No cells match.
    sc_cell_match([[1,2],[3,4]], [[5,6],[7,8]], N),
    N =:= 0.

test(match_half) :-
    % Half the cells match.
    sc_cell_match([[1,2],[3,4]], [[1,9],[3,9]], N),
    N =:= 2.

test(match_single) :-
    % Single cell.
    sc_cell_match([[7]], [[7]], N),
    N =:= 1.

:- end_tests(sc_cell_match).

:- begin_tests(sc_cell_total).

test(total_2x2) :-
    sc_cell_total([[1,2],[3,4]], N),
    N =:= 4.

test(total_3x3) :-
    sc_cell_total([[1,2,3],[4,5,6],[7,8,9]], N),
    N =:= 9.

test(total_1x1) :-
    sc_cell_total([[5]], N),
    N =:= 1.

test(total_1x4) :-
    sc_cell_total([[1,2,3,4]], N),
    N =:= 4.

:- end_tests(sc_cell_total).

:- begin_tests(sc_accuracy).

test(accuracy_perfect) :-
    % Perfect match: accuracy = 1.0.
    sc_accuracy([[1,2],[3,4]], [[1,2],[3,4]], Acc),
    Acc =:= 1.0.

test(accuracy_zero) :-
    % No match: accuracy = 0.0.
    sc_accuracy([[1,2],[3,4]], [[5,6],[7,8]], Acc),
    Acc =:= 0.0.

test(accuracy_half) :-
    % Two of four cells match: accuracy = 0.5.
    sc_accuracy([[1,9],[3,9]], [[1,2],[3,4]], Acc),
    Acc =:= 0.5.

test(accuracy_three_quarters) :-
    % Three of four cells match.
    sc_accuracy([[1,2],[3,9]], [[1,2],[3,4]], Acc),
    Acc =:= 0.75.

:- end_tests(sc_accuracy).

:- begin_tests(sc_color_recall).

test(recall_perfect) :-
    % All color-1 cells in Expected are also in Produced.
    sc_color_recall([[1,0],[0,1]], [[1,0],[0,1]], 1, R),
    R =:= 1.0.

test(recall_zero) :-
    % None of the color-1 cells in Expected appear in Produced.
    sc_color_recall([[0,0],[0,0]], [[1,1],[1,1]], 1, R),
    R =:= 0.0.

test(recall_half) :-
    % Half of the color-1 cells in Expected appear in Produced.
    sc_color_recall([[1,0],[0,0]], [[1,0],[1,0]], 1, R),
    R =:= 0.5.

test(recall_no_target) :-
    % Color not in Expected: recall = 1.0 (vacuously true).
    sc_color_recall([[1,2],[3,4]], [[0,0],[0,0]], 9, R),
    R =:= 1.0.

:- end_tests(sc_color_recall).

:- begin_tests(sc_color_precision).

test(precision_perfect) :-
    % All color-1 cells produced are correct.
    sc_color_precision([[1,0],[0,1]], [[1,0],[0,1]], 1, P),
    P =:= 1.0.

test(precision_zero) :-
    % All color-1 cells produced are wrong (Expected has none).
    sc_color_precision([[1,1],[1,1]], [[0,0],[0,0]], 1, P),
    P =:= 0.0.

test(precision_no_produced) :-
    % No color-1 cells produced: precision = 1.0 (vacuously true).
    sc_color_precision([[0,0],[0,0]], [[1,1],[1,1]], 1, P),
    P =:= 1.0.

:- end_tests(sc_color_precision).

:- begin_tests(sc_color_f1).

test(f1_perfect) :-
    % Perfect precision and recall: F1 = 1.0.
    sc_color_f1([[1,0],[0,1]], [[1,0],[0,1]], 1, F1),
    F1 =:= 1.0.

test(f1_zero) :-
    % Produced has color-1 nowhere, Expected has it everywhere: P=1.0, R=0.0.
    % F1 = 2*1.0*0.0/(1.0+0.0) = 0.0.
    sc_color_f1([[0,0],[0,0]], [[1,1],[1,1]], 1, F1),
    F1 =:= 0.0.

test(f1_balanced) :-
    % P = 1.0, R = 0.5: F1 = 2*1.0*0.5/(1.5) = 0.666...
    sc_color_f1([[1,0],[0,0]], [[1,0],[1,0]], 1, F1),
    abs(F1 - (2.0/3.0)) < 0.0001.

:- end_tests(sc_color_f1).

:- begin_tests(sc_pair_score).

test(pair_score_perfect) :-
    % Identity rule: Actual = Input. Expected = Input. Accuracy = 1.0.
    sc_pair_score([[1,2],[3,4]]-[[1,2],[3,4]], identity_rule_, Acc),
    Acc =:= 1.0.

test(pair_score_zero) :-
    % Rule produces wrong grid.
    sc_pair_score([[1,2]]-[[0,0]],
                  [In, Out]>>(Out = In),
                  Acc),
    Acc =:= 0.0.

:- end_tests(sc_pair_score).

:- begin_tests(sc_pairs_score).

test(pairs_score_all_perfect) :-
    % Identity rule on all pairs: mean = 1.0.
    Pairs = [[[1,2]]-[[1,2]], [[3,4]]-[[3,4]]],
    sc_pairs_score(Pairs, identity_rule_, Mean),
    Mean =:= 1.0.

test(pairs_score_mixed) :-
    % One perfect, one zero: mean = 0.5.
    Pairs = [[[1,2]]-[[1,2]], [[1,2]]-[[0,0]]],
    sc_pairs_score(Pairs, identity_rule_, Mean),
    Mean =:= 0.5.

:- end_tests(sc_pairs_score).

:- begin_tests(sc_perfect).

test(perfect_yes) :-
    % Identity rule produces exact match.
    sc_perfect([[1,2],[3,4]], [[1,2],[3,4]], identity_rule_).

test(perfect_no) :-
    % Rule produces wrong output.
    \+ sc_perfect([[1,2]], [[0,0]], identity_rule_).

:- end_tests(sc_perfect).

:- begin_tests(sc_pairs_perfect).

test(pairs_perfect_all) :-
    % Identity rule: all pairs perfect.
    Pairs = [[[1,2]]-[[1,2]], [[3,4]]-[[3,4]]],
    sc_pairs_perfect(Pairs, identity_rule_).

test(pairs_perfect_fail) :-
    % One pair wrong: not all perfect.
    Pairs = [[[1,2]]-[[1,2]], [[1,2]]-[[0,0]]],
    \+ sc_pairs_perfect(Pairs, identity_rule_).

:- end_tests(sc_pairs_perfect).

:- begin_tests(sc_rank).

test(rank_basic) :-
    % Three candidates; best is the exact match.
    Expected = [[1,2],[3,4]],
    Candidates = [[[1,2],[3,4]], [[1,9],[3,4]], [[5,6],[7,8]]],
    sc_rank(Candidates, Expected, Ranked),
    Ranked = [1.0-[[1,2],[3,4]]|_].

test(rank_all_same) :-
    % All candidates identical: all accuracy = 1.0.
    Expected = [[1,2]],
    sc_rank([[[1,2]], [[1,2]]], Expected, Ranked),
    length(Ranked, 2),
    Ranked = [1.0-_|_].

:- end_tests(sc_rank).

:- begin_tests(sc_best).

test(best_basic) :-
    % Best candidate is the exact match.
    Expected = [[1,2],[3,4]],
    Candidates = [[[5,6],[7,8]], [[1,2],[3,4]], [[1,9],[3,4]]],
    sc_best(Candidates, Expected, Best),
    Best = [[1,2],[3,4]].

:- end_tests(sc_best).

:- begin_tests(sc_threshold).

test(threshold_all_pass) :-
    % All candidates pass 0.5 threshold.
    Expected = [[1,2]],
    sc_threshold([[[1,2]], [[1,9]]], Expected, 0.5, Filtered),
    length(Filtered, 2).

test(threshold_none_pass) :-
    % No candidate meets 1.0 threshold when none is perfect.
    Expected = [[1,2]],
    sc_threshold([[[5,6]], [[7,8]]], Expected, 1.0, Filtered),
    Filtered = [].

test(threshold_some_pass) :-
    % Only exact matches pass 1.0 threshold.
    Expected = [[1,2]],
    sc_threshold([[[1,2]], [[0,0]]], Expected, 1.0, Filtered),
    length(Filtered, 1).

:- end_tests(sc_threshold).
