% Module declaration: score pack, Layer 72.
:- module(score, [
    % score_exact/2: succeed if two grids are identical.
    score_exact/2,
    % score_cell_match/3: count matching cells between two grids.
    score_cell_match/3,
    % score_cell_total/2: total number of cells in a grid.
    score_cell_total/2,
    % score_accuracy/3: fraction of matching cells as a float in [0.0, 1.0].
    score_accuracy/3,
    % score_color_recall/4: fraction of target-color cells correctly produced.
    score_color_recall/4,
    % score_color_precision/4: fraction of produced target-color cells that are correct.
    score_color_precision/4,
    % score_color_f1/4: harmonic mean of color recall and precision (F1 score).
    score_color_f1/4,
    % score_pair_score/3: accuracy on a single training pair (In, Expected, Actual).
    score_pair_score/3,
    % score_pairs_score/3: mean accuracy over a list of training pairs.
    score_pairs_score/3,
    % score_perfect/3: succeed if Actual matches Expected on the training pair.
    score_perfect/3,
    % score_pairs_perfect/2: succeed if all training pairs are solved perfectly.
    score_pairs_perfect/2,
    % score_rank/3: rank a list of candidate grids by accuracy against Expected.
    score_rank/3,
    % score_best/3: pick the candidate grid with the highest accuracy.
    score_best/3,
    % score_threshold/4: filter candidates whose accuracy >= a threshold.
    score_threshold/4
]).

% Import list utilities; msort/length/forall are built-ins, not imported.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3,
                                max_list/2]).
% Import higher-order apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, foldl/4]).

% score_exact(+Grid1, +Grid2).
% Succeed if Grid1 and Grid2 are structurally identical.
score_exact(Grid, Grid).

% score_cell_match(+Grid1, +Grid2, -N).
% N is the number of cells where Grid1 and Grid2 have the same value.
score_cell_match(Grid1, Grid2, N) :-
    % Flatten both grids to compare cell by cell.
    append(Grid1, Flat1),
    append(Grid2, Flat2),
    % Count matching positions.
    score_count_matches_(Flat1, Flat2, N).

% score_count_matches_(+List1, +List2, -N): count positions where both lists agree.
score_count_matches_([], [], 0).
score_count_matches_([H1|T1], [H2|T2], N) :-
    % Recurse then add 1 if the heads match.
    score_count_matches_(T1, T2, Rest),
    ( H1 =:= H2 ->
        N is Rest + 1
    ;   N = Rest
    ).

% score_cell_total(+Grid, -N).
% N is the total number of cells in Grid (Rows * Cols).
score_cell_total(Grid, N) :-
    % Get the number of rows.
    length(Grid, Rows),
    % Get the number of columns from the first row.
    ( Grid = [FR|_] -> length(FR, Cols) ; Cols = 0 ),
    % Total cells = Rows * Cols.
    N is Rows * Cols.

% score_accuracy(+Grid1, +Grid2, -Acc).
% Acc is the fraction of cells that match (a float in [0.0, 1.0]).
% 1.0 means perfect match; 0.0 means no cell matches.
score_accuracy(Grid1, Grid2, Acc) :-
    % Count matching cells.
    score_cell_match(Grid1, Grid2, Match),
    % Count total cells.
    score_cell_total(Grid1, Total),
    % Compute fraction as float; guard against division by zero.
    ( Total > 0 ->
        Acc is float(Match) / float(Total)
    ;   Acc = 1.0
    ).

% score_color_recall(+Produced, +Expected, +Color, -Recall).
% Recall is the fraction of cells with Color in Expected that also appear in Produced.
% Recall = TP / (TP + FN) where TP = correctly produced, FN = missed.
score_color_recall(Produced, Expected, Color, Recall) :-
    % Flatten both grids.
    append(Expected, ExpFlat),
    append(Produced, ProdFlat),
    % Count target cells in Expected.
    score_count_color_(ExpFlat, Color, ExpCount),
    % Count correctly produced target cells (zip and count TP).
    score_count_tp_(ProdFlat, ExpFlat, Color, TP),
    % Recall = TP / ExpCount; 1.0 if no target cells in Expected.
    ( ExpCount > 0 ->
        Recall is TP / ExpCount
    ;   Recall = 1.0
    ).

% score_color_precision(+Produced, +Expected, +Color, -Precision).
% Precision is the fraction of Color cells in Produced that match Expected.
% Precision = TP / (TP + FP) where FP = produced but incorrect.
score_color_precision(Produced, Expected, Color, Precision) :-
    % Flatten both grids.
    append(Produced, ProdFlat),
    append(Expected, ExpFlat),
    % Count produced target cells.
    score_count_color_(ProdFlat, Color, ProdCount),
    % Count true positives.
    score_count_tp_(ProdFlat, ExpFlat, Color, TP),
    % Precision = TP / ProdCount; 1.0 if no Color cells produced.
    ( ProdCount > 0 ->
        Precision is TP / ProdCount
    ;   Precision = 1.0
    ).

% score_color_f1(+Produced, +Expected, +Color, -F1).
% F1 is the harmonic mean of color precision and recall.
% F1 = 2 * (P * R) / (P + R); 0.0 if P + R = 0.
score_color_f1(Produced, Expected, Color, F1) :-
    % Compute precision and recall.
    score_color_precision(Produced, Expected, Color, P),
    score_color_recall(Produced, Expected, Color, R),
    % Compute harmonic mean.
    ( (P + R) > 0.0 ->
        F1 is 2.0 * P * R / (P + R)
    ;   F1 = 0.0
    ).

% score_count_color_(+Flat, +Color, -N): count occurrences of Color in a flat list.
score_count_color_([], _, 0).
score_count_color_([H|T], Color, N) :-
    score_count_color_(T, Color, Rest),
    ( H =:= Color ->
        N is Rest + 1
    ;   N = Rest
    ).

% score_count_tp_(+ProdFlat, +ExpFlat, +Color, -TP).
% TP is the number of positions where both ProdFlat and ExpFlat equal Color.
score_count_tp_([], [], _, 0).
score_count_tp_([P|PT], [E|ET], Color, TP) :-
    score_count_tp_(PT, ET, Color, Rest),
    ( P =:= Color, E =:= Color ->
        TP is Rest + 1
    ;   TP = Rest
    ).

% score_pair_score(+Pair, +Goal, -Acc).
% Apply Goal to the input of Pair and measure accuracy against the expected output.
% Pair is in-out (Input-Expected) or Input-Expected format.
% Goal is a 2-argument callable: Goal(Input, Actual).
:- meta_predicate score_pair_score(+, 2, -).
score_pair_score(Input-Expected, Goal, Acc) :-
    % Apply the rule to produce Actual.
    call(Goal, Input, Actual),
    % Measure accuracy.
    score_accuracy(Actual, Expected, Acc).

% score_pairs_score(+Pairs, +Goal, -MeanAcc).
% MeanAcc is the mean accuracy over all Pairs.
% Pairs is a list of Input-Expected pairs.
:- meta_predicate score_pairs_score(+, 2, -).
score_pairs_score(Pairs, Goal, MeanAcc) :-
    % Score each pair.
    maplist(score_pair_score_goal_(Goal), Pairs, Accs),
    % Compute the mean.
    score_mean_(Accs, MeanAcc).

% score_pair_score_goal_(+Goal, +Pair, -Acc): helper to thread Goal into maplist.
:- meta_predicate score_pair_score_goal_(2, +, -).
score_pair_score_goal_(Goal, Pair, Acc) :-
    score_pair_score(Pair, Goal, Acc).

% score_mean_(+Floats, -Mean): arithmetic mean of a list of floats.
score_mean_([], 1.0).
score_mean_(Floats, Mean) :-
    Floats \= [],
    foldl([V, Acc, Acc2]>>(Acc2 is Acc + V), Floats, 0.0, Sum),
    length(Floats, N),
    Mean is Sum / N.

% score_perfect(+Input, +Expected, +Goal).
% Succeed if Goal(Input, Actual) produces Actual = Expected exactly.
:- meta_predicate score_perfect(+, +, 2).
score_perfect(Input, Expected, Goal) :-
    call(Goal, Input, Actual),
    score_exact(Actual, Expected).

% score_pairs_perfect(+Pairs, +Goal).
% Succeed if all Pairs are solved perfectly by Goal.
:- meta_predicate score_pairs_perfect(+, 2).
score_pairs_perfect(Pairs, Goal) :-
    % Check every pair.
    forall(member(In-Ex, Pairs), score_perfect(In, Ex, Goal)).

% score_rank(+Candidates, +Expected, -Ranked).
% Ranked is the list of candidate grids sorted by accuracy descending.
% Each element of Ranked is Acc-Grid.
score_rank(Candidates, Expected, Ranked) :-
    % Score each candidate.
    maplist(score_rank_one_(Expected), Candidates, Scored),
    % Sort ascending by Acc (first arg).
    msort(Scored, Ascending),
    % Reverse for descending order (best first).
    reverse(Ascending, Ranked).

% score_rank_one_(+Expected, +Grid, -Acc-Grid): score one candidate.
score_rank_one_(Expected, Grid, Acc-Grid) :-
    score_accuracy(Grid, Expected, Acc).

% score_best(+Candidates, +Expected, -Best).
% Best is the candidate grid with the highest accuracy against Expected.
score_best(Candidates, Expected, Best) :-
    % Rank all candidates.
    score_rank(Candidates, Expected, [_Acc-Best|_]).

% score_threshold(+Candidates, +Expected, +MinAcc, -Filtered).
% Filtered is the list of candidates whose accuracy >= MinAcc.
score_threshold(Candidates, Expected, MinAcc, Filtered) :-
    % Score and filter.
    findall(Grid,
        (member(Grid, Candidates),
         score_accuracy(Grid, Expected, Acc),
         Acc >= MinAcc),
        Filtered).
