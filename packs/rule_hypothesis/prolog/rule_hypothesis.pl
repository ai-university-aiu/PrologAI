% Module declaration: hyp pack, Layer 74.
:- module(rule_hypothesis, [
    % rule_hypothesis_color_sub/3: apply a color substitution map to a grid.
    rule_hypothesis_color_sub/3,
    % rule_hypothesis_identity/2: return the input grid unchanged.
    rule_hypothesis_identity/2,
    % rule_hypothesis_from_map/3: build a hypothesis goal term from a color map.
    rule_hypothesis_from_map/3,
    % rule_hypothesis_test/4: test a hypothesis on one training pair, returning accuracy.
    rule_hypothesis_test/4,
    % rule_hypothesis_test_all/4: test a hypothesis on all pairs, returning mean accuracy.
    rule_hypothesis_test_all/4,
    % rule_hypothesis_verify/3: succeed if a hypothesis solves one pair exactly.
    rule_hypothesis_verify/3,
    % rule_hypothesis_verify_all/2: succeed if a hypothesis solves all pairs exactly.
    rule_hypothesis_verify_all/2,
    % rule_hypothesis_select/3: select the best hypothesis from a list for a set of pairs.
    rule_hypothesis_select/3,
    % rule_hypothesis_rank/3: rank hypotheses by mean accuracy descending.
    rule_hypothesis_rank/3,
    % rule_hypothesis_apply_map/3: apply a color substitution map to produce a new grid.
    rule_hypothesis_apply_map/3,
    % rule_hypothesis_compose/4: compose two color maps into a single substitution.
    rule_hypothesis_compose/4,
    % rule_hypothesis_invert_map/2: invert a color substitution map (swap keys and values).
    rule_hypothesis_invert_map/2,
    % rule_hypothesis_map_lookup/3: look up a color in a map with identity fallback.
    rule_hypothesis_map_lookup/3,
    % rule_hypothesis_describe/2: describe a hypothesis as a human-readable atom.
    rule_hypothesis_describe/2,
    % rule_hypothesis_spatial_hyp/3: find the shift hypothesis that explains all grid pairs.
    rule_hypothesis_spatial_hyp/3,
    % rule_hypothesis_structural_hyp/3: find the named structural pattern that fits all pairs.
    rule_hypothesis_structural_hyp/3,
    % rule_hypothesis_sequence_hyp/4: find a two-step color-map hypothesis for all pairs.
    rule_hypothesis_sequence_hyp/4
]).

% Import list utilities; msort/length/forall are built-ins, not imported.
:- use_module(library(lists), [member/2, subtract/3, append/3,
                                max_list/2, numlist/3]).
% Import higher-order apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, foldl/4]).

% rule_hypothesis_color_sub(+Map, +Grid, -Grid2).
% Apply a color substitution map (list of Old-New pairs) to every cell.
% Cells whose color is not in the map are left unchanged.
rule_hypothesis_color_sub(Map, Grid, Grid2) :-
    % Map each row of the grid.
    maplist(rule_hypothesis_sub_row_(Map), Grid, Grid2).

% rule_hypothesis_sub_row_(+Map, +Row, -Row2): apply color substitution to one row.
rule_hypothesis_sub_row_(Map, Row, Row2) :-
    maplist(rule_hypothesis_map_lookup_(Map), Row, Row2).

% rule_hypothesis_map_lookup_(+Map, +Color, -NewColor): look up Color in Map; fallback = Color.
rule_hypothesis_map_lookup_(Map, Color, New) :-
    ( member(Color-New, Map) ->
        true
    ;   New = Color
    ).

% rule_hypothesis_identity(+Grid, -Grid2).
% Return the grid unchanged (identity hypothesis).
rule_hypothesis_identity(Grid, Grid).

% rule_hypothesis_from_map(+Map, +Grid, -Grid2).
% Apply the substitution Map to Grid. Alias for rule_hypothesis_color_sub for use
% as a 2-argument hypothesis goal via partial application.
rule_hypothesis_from_map(Map, Grid, Grid2) :-
    rule_hypothesis_color_sub(Map, Grid, Grid2).

% rule_hypothesis_test(+Goal, +Input, +Expected, -Acc).
% Apply Goal(Input, Actual) and measure pixel accuracy against Expected.
:- meta_predicate rule_hypothesis_test(2, +, +, -).
rule_hypothesis_test(Goal, Input, Expected, Acc) :-
    % Apply the hypothesis.
    call(Goal, Input, Actual),
    % Count matching cells.
    rule_hypothesis_cell_match_(Actual, Expected, Match),
    % Count total cells.
    rule_hypothesis_cell_total_(Expected, Total),
    % Compute accuracy as float.
    ( Total > 0 ->
        Acc is float(Match) / float(Total)
    ;   Acc = 1.0
    ).

% rule_hypothesis_cell_match_(+Grid1, +Grid2, -N): count cells where both grids agree.
rule_hypothesis_cell_match_(Grid1, Grid2, N) :-
    findall(x,
        (nth0(R, Grid1, Row1),
         nth0(R, Grid2, Row2),
         nth0(C, Row1, V),
         nth0(C, Row2, V)),
        Matches),
    length(Matches, N).

% rule_hypothesis_cell_total_(+Grid, -N): count total cells in the grid.
rule_hypothesis_cell_total_(Grid, N) :-
    length(Grid, Rows),
    ( Grid = [FR|_] -> length(FR, Cols) ; Cols = 0 ),
    N is Rows * Cols.

% rule_hypothesis_test_all(+Goal, +Pairs, -MeanAcc, -Accs).
% Test a hypothesis on all training pairs; return mean accuracy and per-pair list.
:- meta_predicate rule_hypothesis_test_all(2, +, -, -).
rule_hypothesis_test_all(Goal, Pairs, MeanAcc, Accs) :-
    % Score each pair.
    maplist(rule_hypothesis_score_pair_(Goal), Pairs, Accs),
    % Compute mean.
    rule_hypothesis_mean_(Accs, MeanAcc).

% rule_hypothesis_score_pair_(+Goal, +Pair, -Acc): score one Input-Expected pair.
rule_hypothesis_score_pair_(Goal, Input-Expected, Acc) :-
    rule_hypothesis_test(Goal, Input, Expected, Acc).

% rule_hypothesis_mean_(+Floats, -Mean): arithmetic mean of a float list.
rule_hypothesis_mean_([], 1.0).
rule_hypothesis_mean_(Floats, Mean) :-
    Floats \= [],
    foldl([V, A, B]>>(B is A + V), Floats, 0.0, Sum),
    length(Floats, N),
    Mean is Sum / N.

% rule_hypothesis_verify(+Goal, +Input, +Expected).
% Succeed if Goal produces Output equal to Expected exactly.
:- meta_predicate rule_hypothesis_verify(2, +, +).
rule_hypothesis_verify(Goal, Input, Expected) :-
    call(Goal, Input, Actual),
    Actual = Expected.

% rule_hypothesis_verify_all(+Goal, +Pairs).
% Succeed if Goal solves every Input-Expected pair exactly.
:- meta_predicate rule_hypothesis_verify_all(2, +).
rule_hypothesis_verify_all(Goal, Pairs) :-
    forall(member(Input-Expected, Pairs),
        rule_hypothesis_verify(Goal, Input, Expected)).

% rule_hypothesis_select(+Goals, +Pairs, -Best).
% Best is the hypothesis from Goals with the highest mean accuracy on Pairs.
rule_hypothesis_select(Goals, Pairs, Best) :-
    rule_hypothesis_rank(Goals, Pairs, [_-Best|_]).

% rule_hypothesis_rank(+Goals, +Pairs, -Ranked).
% Ranked is the list of MeanAcc-Goal pairs sorted by accuracy descending.
rule_hypothesis_rank(Goals, Pairs, Ranked) :-
    % Score each goal.
    maplist(rule_hypothesis_rank_one_(Pairs), Goals, Scored),
    % Sort ascending then reverse for descending.
    msort(Scored, Ascending),
    reverse(Ascending, Ranked).

% rule_hypothesis_rank_one_(+Pairs, +Goal, -Acc-Goal): score one hypothesis.
rule_hypothesis_rank_one_(Pairs, Goal, Acc-Goal) :-
    rule_hypothesis_test_all(Goal, Pairs, Acc, _).

% rule_hypothesis_apply_map(+Map, +Grid, -Grid2).
% Alias for rule_hypothesis_color_sub. Apply Map to every cell; unchanged if not in Map.
rule_hypothesis_apply_map(Map, Grid, Grid2) :-
    rule_hypothesis_color_sub(Map, Grid, Grid2).

% rule_hypothesis_compose(+Map1, +Map2, +Grid, -Grid2).
% Apply Map1 then Map2 to Grid (sequential color substitution).
rule_hypothesis_compose(Map1, Map2, Grid, Grid2) :-
    rule_hypothesis_color_sub(Map1, Grid, Intermediate),
    rule_hypothesis_color_sub(Map2, Intermediate, Grid2).

% rule_hypothesis_invert_map(+Map, -Inverted).
% Swap the keys and values of a color substitution map.
rule_hypothesis_invert_map(Map, Inverted) :-
    findall(New-Old, member(Old-New, Map), Inverted).

% rule_hypothesis_map_lookup(+Map, +Color, -New).
% Look up Color in Map; if absent, New = Color (identity fallback).
rule_hypothesis_map_lookup(Map, Color, New) :-
    rule_hypothesis_map_lookup_(Map, Color, New).

% rule_hypothesis_describe(+Goal, -Desc).
% Describe a hypothesis as a human-readable atom.
% Handles rule_hypothesis_identity, rule_hypothesis_color_sub/3 partial, and generic goals.
rule_hypothesis_describe(rule_hypothesis_identity, identity) :- !.
rule_hypothesis_describe(rule_hypothesis_color_sub(Map, _), Desc) :- !,
    term_to_atom(color_sub(Map), Desc).
rule_hypothesis_describe(Goal, Desc) :-
    term_to_atom(Goal, Desc).

% rule_hypothesis_spatial_hyp(+Pairs, +Moves, -Hyp)
% Find the first shift in Moves that, when applied to each pair's input grid
% (moving every non-background cell by DR-DC), exactly reproduces the output.
% Pairs is a list of pair(InGrid, OutGrid) where grids are 2D integer lists.
% Moves is a list of DR-DC integer delta pairs to try in order.
% Hyp is shift(DR, DC) for the first move that verifies all pairs.
rule_hypothesis_spatial_hyp(Pairs, Moves, Hyp) :-
    member(DR-DC, Moves),
    forall(member(pair(In, Out), Pairs),
           rule_hypothesis_spatial_verify_(In, Out, DR, DC)),
    !,
    Hyp = shift(DR, DC).

% rule_hypothesis_spatial_verify_(+In, +Out, +DR, +DC)
% Succeed if shifting all non-zero cells of In by (DR, DC) matches Out.
rule_hypothesis_spatial_verify_(In, Out, DR, DC) :-
    length(In, NR),
    ( In = [FR|_] -> length(FR, NC) ; NC = 0 ),
    findall(R2-C2-V,
        (nth0(R, In, Row), nth0(C, Row, V), V \= 0,
         R2 is R + DR, C2 is C + DC,
         R2 >= 0, R2 < NR, C2 >= 0, C2 < NC),
        ShiftedIn),
    findall(R-C-V2,
        (nth0(R, Out, Row2), nth0(C, Row2, V2), V2 \= 0),
        OutCells),
    msort(ShiftedIn, S1), msort(OutCells, S2),
    S1 = S2.

% rule_hypothesis_structural_hyp(+Pairs, +Patterns, -Hyp)
% Find the first pattern name in Patterns that is consistent with all training pairs.
% Patterns is a list of atoms drawn from:
%   dims_preserved, colors_preserved, total_nonzero_preserved,
%   monotone_output, output_subset_of_input, input_subset_of_output.
% Hyp is structural(Pattern) for the first matching pattern.
rule_hypothesis_structural_hyp(Pairs, Patterns, Hyp) :-
    member(Pattern, Patterns),
    forall(member(pair(In, Out), Pairs),
           rule_hypothesis_struct_check_(Pattern, In, Out)),
    !,
    Hyp = structural(Pattern).

% rule_hypothesis_struct_check_(+Pattern, +In, +Out): test one structural property for a pair.
rule_hypothesis_struct_check_(dims_preserved, In, Out) :-
    length(In, R), ( In=[FR|_] -> length(FR,C) ; C=0 ),
    length(Out, R), ( Out=[OR|_] -> length(OR,C) ; C=0 ).
rule_hypothesis_struct_check_(colors_preserved, In, Out) :-
    findall(V, (member(Row, In), member(V, Row)), FI), sort(FI, SI),
    findall(V, (member(Row, Out), member(V, Row)), FO), sort(FO, SO),
    SI = SO.
rule_hypothesis_struct_check_(total_nonzero_preserved, In, Out) :-
    findall(V, (member(Row, In), member(V, Row), V \= 0), NZI),
    findall(V, (member(Row, Out), member(V, Row), V \= 0), NZO),
    length(NZI, N), length(NZO, N).
rule_hypothesis_struct_check_(monotone_output, _, Out) :-
    findall(V, (member(Row, Out), member(V, Row), V \= 0), NZO),
    sort(NZO, Uniq),
    length(Uniq, 1).
rule_hypothesis_struct_check_(output_subset_of_input, In, Out) :-
    findall(V, (member(Row, Out), member(V, Row), V \= 0), NZO),
    findall(V, (member(Row, In), member(V, Row), V \= 0), NZI),
    sort(NZO, SO), sort(NZI, SI),
    subtract(SO, SI, Extra),
    Extra = [].
rule_hypothesis_struct_check_(input_subset_of_output, In, Out) :-
    findall(V, (member(Row, In), member(V, Row), V \= 0), NZI),
    findall(V, (member(Row, Out), member(V, Row), V \= 0), NZO),
    sort(NZI, SI), sort(NZO, SO),
    subtract(SI, SO, Missing),
    Missing = [].

% rule_hypothesis_sequence_hyp(+Pairs, +Maps1, +Maps2, -Hyp)
% Find a two-step color-substitution hypothesis seq(Map1, Map2) such that
% applying Map1 then Map2 to each input grid produces the output.
% Maps1 and Maps2 are lists of color substitution maps (lists of Old-New pairs).
% Hyp is seq(Map1, Map2) for the first combination that verifies all pairs.
rule_hypothesis_sequence_hyp(Pairs, Maps1, Maps2, Hyp) :-
    member(Map1, Maps1),
    member(Map2, Maps2),
    forall(member(pair(In, Out), Pairs),
           (rule_hypothesis_color_sub(Map1, In, Mid),
            rule_hypothesis_color_sub(Map2, Mid, Out))),
    !,
    Hyp = seq(Map1, Map2).
