% Module declaration: hyp pack, Layer 74.
:- module(hyp, [
    % hy_color_sub/3: apply a color substitution map to a grid.
    hy_color_sub/3,
    % hy_identity/2: return the input grid unchanged.
    hy_identity/2,
    % hy_from_map/3: build a hypothesis goal term from a color map.
    hy_from_map/3,
    % hy_test/4: test a hypothesis on one training pair, returning accuracy.
    hy_test/4,
    % hy_test_all/4: test a hypothesis on all pairs, returning mean accuracy.
    hy_test_all/4,
    % hy_verify/3: succeed if a hypothesis solves one pair exactly.
    hy_verify/3,
    % hy_verify_all/2: succeed if a hypothesis solves all pairs exactly.
    hy_verify_all/2,
    % hy_select/3: select the best hypothesis from a list for a set of pairs.
    hy_select/3,
    % hy_rank/3: rank hypotheses by mean accuracy descending.
    hy_rank/3,
    % hy_apply_map/3: apply a color substitution map to produce a new grid.
    hy_apply_map/3,
    % hy_compose/4: compose two color maps into a single substitution.
    hy_compose/4,
    % hy_invert_map/2: invert a color substitution map (swap keys and values).
    hy_invert_map/2,
    % hy_map_lookup/3: look up a color in a map with identity fallback.
    hy_map_lookup/3,
    % hy_describe/2: describe a hypothesis as a human-readable atom.
    hy_describe/2
]).

% Import list utilities; msort/length/forall are built-ins, not imported.
:- use_module(library(lists), [member/2, subtract/3, append/3,
                                max_list/2, numlist/3]).
% Import higher-order apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, foldl/4]).

% hy_color_sub(+Map, +Grid, -Grid2).
% Apply a color substitution map (list of Old-New pairs) to every cell.
% Cells whose color is not in the map are left unchanged.
hy_color_sub(Map, Grid, Grid2) :-
    % Map each row of the grid.
    maplist(hy_sub_row_(Map), Grid, Grid2).

% hy_sub_row_(+Map, +Row, -Row2): apply color substitution to one row.
hy_sub_row_(Map, Row, Row2) :-
    maplist(hy_map_lookup_(Map), Row, Row2).

% hy_map_lookup_(+Map, +Color, -NewColor): look up Color in Map; fallback = Color.
hy_map_lookup_(Map, Color, New) :-
    ( member(Color-New, Map) ->
        true
    ;   New = Color
    ).

% hy_identity(+Grid, -Grid2).
% Return the grid unchanged (identity hypothesis).
hy_identity(Grid, Grid).

% hy_from_map(+Map, +Grid, -Grid2).
% Apply the substitution Map to Grid. Alias for hy_color_sub for use
% as a 2-argument hypothesis goal via partial application.
hy_from_map(Map, Grid, Grid2) :-
    hy_color_sub(Map, Grid, Grid2).

% hy_test(+Goal, +Input, +Expected, -Acc).
% Apply Goal(Input, Actual) and measure pixel accuracy against Expected.
:- meta_predicate hy_test(2, +, +, -).
hy_test(Goal, Input, Expected, Acc) :-
    % Apply the hypothesis.
    call(Goal, Input, Actual),
    % Count matching cells.
    hy_cell_match_(Actual, Expected, Match),
    % Count total cells.
    hy_cell_total_(Expected, Total),
    % Compute accuracy as float.
    ( Total > 0 ->
        Acc is float(Match) / float(Total)
    ;   Acc = 1.0
    ).

% hy_cell_match_(+Grid1, +Grid2, -N): count cells where both grids agree.
hy_cell_match_(Grid1, Grid2, N) :-
    findall(x,
        (nth0(R, Grid1, Row1),
         nth0(R, Grid2, Row2),
         nth0(C, Row1, V),
         nth0(C, Row2, V)),
        Matches),
    length(Matches, N).

% hy_cell_total_(+Grid, -N): count total cells in the grid.
hy_cell_total_(Grid, N) :-
    length(Grid, Rows),
    ( Grid = [FR|_] -> length(FR, Cols) ; Cols = 0 ),
    N is Rows * Cols.

% hy_test_all(+Goal, +Pairs, -MeanAcc, -Accs).
% Test a hypothesis on all training pairs; return mean accuracy and per-pair list.
:- meta_predicate hy_test_all(2, +, -, -).
hy_test_all(Goal, Pairs, MeanAcc, Accs) :-
    % Score each pair.
    maplist(hy_score_pair_(Goal), Pairs, Accs),
    % Compute mean.
    hy_mean_(Accs, MeanAcc).

% hy_score_pair_(+Goal, +Pair, -Acc): score one Input-Expected pair.
hy_score_pair_(Goal, Input-Expected, Acc) :-
    hy_test(Goal, Input, Expected, Acc).

% hy_mean_(+Floats, -Mean): arithmetic mean of a float list.
hy_mean_([], 1.0).
hy_mean_(Floats, Mean) :-
    Floats \= [],
    foldl([V, A, B]>>(B is A + V), Floats, 0.0, Sum),
    length(Floats, N),
    Mean is Sum / N.

% hy_verify(+Goal, +Input, +Expected).
% Succeed if Goal produces Output equal to Expected exactly.
:- meta_predicate hy_verify(2, +, +).
hy_verify(Goal, Input, Expected) :-
    call(Goal, Input, Actual),
    Actual = Expected.

% hy_verify_all(+Goal, +Pairs).
% Succeed if Goal solves every Input-Expected pair exactly.
:- meta_predicate hy_verify_all(2, +).
hy_verify_all(Goal, Pairs) :-
    forall(member(Input-Expected, Pairs),
        hy_verify(Goal, Input, Expected)).

% hy_select(+Goals, +Pairs, -Best).
% Best is the hypothesis from Goals with the highest mean accuracy on Pairs.
hy_select(Goals, Pairs, Best) :-
    hy_rank(Goals, Pairs, [_-Best|_]).

% hy_rank(+Goals, +Pairs, -Ranked).
% Ranked is the list of MeanAcc-Goal pairs sorted by accuracy descending.
hy_rank(Goals, Pairs, Ranked) :-
    % Score each goal.
    maplist(hy_rank_one_(Pairs), Goals, Scored),
    % Sort ascending then reverse for descending.
    msort(Scored, Ascending),
    reverse(Ascending, Ranked).

% hy_rank_one_(+Pairs, +Goal, -Acc-Goal): score one hypothesis.
hy_rank_one_(Pairs, Goal, Acc-Goal) :-
    hy_test_all(Goal, Pairs, Acc, _).

% hy_apply_map(+Map, +Grid, -Grid2).
% Alias for hy_color_sub. Apply Map to every cell; unchanged if not in Map.
hy_apply_map(Map, Grid, Grid2) :-
    hy_color_sub(Map, Grid, Grid2).

% hy_compose(+Map1, +Map2, +Grid, -Grid2).
% Apply Map1 then Map2 to Grid (sequential color substitution).
hy_compose(Map1, Map2, Grid, Grid2) :-
    hy_color_sub(Map1, Grid, Intermediate),
    hy_color_sub(Map2, Intermediate, Grid2).

% hy_invert_map(+Map, -Inverted).
% Swap the keys and values of a color substitution map.
hy_invert_map(Map, Inverted) :-
    findall(New-Old, member(Old-New, Map), Inverted).

% hy_map_lookup(+Map, +Color, -New).
% Look up Color in Map; if absent, New = Color (identity fallback).
hy_map_lookup(Map, Color, New) :-
    hy_map_lookup_(Map, Color, New).

% hy_describe(+Goal, -Desc).
% Describe a hypothesis as a human-readable atom.
% Handles hy_identity, hy_color_sub/3 partial, and generic goals.
hy_describe(hy_identity, identity) :- !.
hy_describe(hy_color_sub(Map, _), Desc) :- !,
    term_to_atom(color_sub(Map), Desc).
hy_describe(Goal, Desc) :-
    term_to_atom(Goal, Desc).
