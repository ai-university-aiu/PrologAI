% Test suite for invariant (iv_*, Layer 248).
:- use_module('../prolog/invariant.pl').

:- begin_tests(invariant).

% --- Shared test grids ---

% 2x2 grids with 0=background.
g2x2a([[0,1],[2,0]]).      % 2x2, colors {1,2}
g2x2b([[0,2],[1,0]]).      % 2x2, colors {1,2}
g2x2c([[1,1],[2,2]]).      % 2x2, colors {1,2}, different arrangement
g2x2r([[0,2],[3,0]]).      % 2x2, colors {2,3}, different color set
g2x2out([[0,2],[1,0]]).    % 2x2 output (swap 1↔2)

% 3x3 grids.
g3x3a([[0,1,0],[1,2,1],[0,1,0]]).   % 3x3, colors {1,2}
g3x3b([[0,2,0],[2,1,2],[0,2,0]]).   % 3x3, colors {1,2}

% Pairs.
pair_same_dims(pair([[0,1],[2,0]], [[0,2],[1,0]])).
pair_diff_dims(pair([[0,1,0],[1,0,1]], [[0,2],[1,0]])).
pair_preserves_colors(pair([[0,1],[2,0]], [[0,2],[1,0]])).
pair_changes_colors(pair([[0,1],[2,0]], [[0,3],[1,0]])).

% --- invariant_color_set ---

test('AC-IV-001: invariant_color_set extracts non-bg colors') :-
    g2x2a(G), invariant_color_set(G, 0, Colors),
    Colors = [1, 2].

test('AC-IV-002: invariant_color_set returns empty for all-bg grid') :-
    invariant_color_set([[0,0],[0,0]], 0, Colors),
    Colors = [].

test('AC-IV-003: invariant_color_set respects BgColor') :-
    invariant_color_set([[1,1],[1,2]], 1, Colors),
    Colors = [2].

% --- invariant_same_dims ---

test('AC-IV-004: invariant_same_dims succeeds for single grid') :-
    g2x2a(G), invariant_same_dims([G]).

test('AC-IV-005: invariant_same_dims succeeds for two same-size grids') :-
    g2x2a(A), g2x2b(B), invariant_same_dims([A, B]).

test('AC-IV-006: invariant_same_dims fails for different-size grids') :-
    g2x2a(A), g3x3a(B), \+ invariant_same_dims([A, B]).

test('AC-IV-007: invariant_same_dims succeeds for empty list') :-
    invariant_same_dims([]).

% --- invariant_same_color_sets ---

test('AC-IV-008: invariant_same_color_sets succeeds when all grids share colors') :-
    g2x2a(A), g2x2b(B), invariant_same_color_sets([A, B], 0).

test('AC-IV-009: invariant_same_color_sets fails when color sets differ') :-
    g2x2a(A), g2x2r(R), \+ invariant_same_color_sets([A, R], 0).

test('AC-IV-010: invariant_same_color_sets succeeds for single grid') :-
    g2x2a(G), invariant_same_color_sets([G], 0).

% --- invariant_preserves_dims ---

test('AC-IV-011: invariant_preserves_dims succeeds when all pairs same dims') :-
    pair_same_dims(P), invariant_preserves_dims([P]).

test('AC-IV-012: invariant_preserves_dims fails when any pair changes dims') :-
    pair_diff_dims(P), \+ invariant_preserves_dims([P]).

test('AC-IV-013: invariant_preserves_dims succeeds for empty list') :-
    invariant_preserves_dims([]).

% --- invariant_preserves_colors ---

test('AC-IV-014: invariant_preserves_colors succeeds when colors preserved') :-
    pair_preserves_colors(P), invariant_preserves_colors([P]).

test('AC-IV-015: invariant_preserves_colors fails when colors change') :-
    pair_changes_colors(P), \+ invariant_preserves_colors([P]).

% --- invariant_preserves_count ---

test('AC-IV-016: invariant_preserves_count succeeds when same distinct color count') :-
    % Both input and output have 2 distinct non-bg colors.
    pair_same_dims(P), invariant_preserves_count([P], 0).

test('AC-IV-017: invariant_preserves_count fails when color count changes') :-
    % Input has {1,2}, output has {1,2,3}.
    P = pair([[0,1],[2,0]], [[0,1],[2,3]]),
    \+ invariant_preserves_count([P], 0).

test('AC-IV-018: invariant_preserves_count succeeds for empty list') :-
    invariant_preserves_count([], 0).

% --- invariant_grid_invariants ---

test('AC-IV-019: invariant_grid_invariants finds dims invariant for same-size inputs') :-
    P1 = pair([[0,1],[2,0]], [[0,2],[1,0]]),
    P2 = pair([[0,2],[1,0]], [[0,1],[2,0]]),
    invariant_grid_invariants([P1, P2], Invs),
    memberchk(inv(dims(2,2)), Invs).

test('AC-IV-020: invariant_grid_invariants returns empty for empty pairs') :-
    invariant_grid_invariants([], Invs),
    Invs = [].

test('AC-IV-021: invariant_grid_invariants returns [] when dims vary') :-
    P1 = pair([[0,1],[2,0]], [[0]]),
    P2 = pair([[0,1,0],[1,0,1]], [[0]]),
    invariant_grid_invariants([P1, P2], Invs),
    \+ member(inv(dims(_,_)), Invs).

% --- invariant_output_invariants ---

test('AC-IV-022: invariant_output_invariants finds dims invariant for same-size outputs') :-
    P1 = pair([[0,1],[2,0]], [[0,2],[1,0]]),
    P2 = pair([[0,2],[1,0]], [[0,1],[2,0]]),
    invariant_output_invariants([P1, P2], Invs),
    memberchk(inv(dims(2,2)), Invs).

test('AC-IV-023: invariant_output_invariants returns [] for empty pairs') :-
    invariant_output_invariants([], Invs),
    Invs = [].

% --- invariant_object_invariants ---

test('AC-IV-024: invariant_object_invariants finds stable color set') :-
    P1 = pair([[0,1],[2,0]], [[0,2],[1,0]]),
    P2 = pair([[0,1],[1,2]], [[0,2],[2,1]]),
    invariant_object_invariants([P1, P2], Invs),
    memberchk(inv(stable_color_set([1,2])), Invs).

test('AC-IV-025: invariant_object_invariants returns [] when color set varies') :-
    P1 = pair([[0,1],[2,0]], [[0]]),
    P2 = pair([[0,1],[3,0]], [[0]]),
    invariant_object_invariants([P1, P2], Invs),
    \+ member(inv(stable_color_set(_)), Invs).

% --- invariant_variant_features ---

test('AC-IV-026: invariant_variant_features returns [] when all same dims and colors') :-
    P1 = pair([[0,1],[2,0]], [[0,2],[1,0]]),
    P2 = pair([[0,1],[2,0]], [[0,2],[1,0]]),
    invariant_variant_features([P1, P2], Feats),
    Feats = [].

test('AC-IV-027: invariant_variant_features flags dims when grids vary in size') :-
    P1 = pair([[0,1],[2,0]], [[0]]),
    P2 = pair([[0,1,0],[1,0,1]], [[0]]),
    invariant_variant_features([P1, P2], Feats),
    memberchk(feature(dims), Feats).

test('AC-IV-028: invariant_variant_features flags color_set when colors vary') :-
    P1 = pair([[0,1],[2,0]], [[0]]),
    P2 = pair([[0,3],[1,0]], [[0]]),
    invariant_variant_features([P1, P2], Feats),
    memberchk(feature(color_set), Feats).

% --- invariant_consistent_delta ---

test('AC-IV-029: invariant_consistent_delta finds dims_preserved when all pairs same dims') :-
    P1 = pair([[0,1],[2,0]], [[0,2],[1,0]]),
    P2 = pair([[0,2],[1,0]], [[0,1],[2,0]]),
    invariant_consistent_delta([P1, P2], Delta),
    memberchk(inv(dims_preserved), Delta).

test('AC-IV-030: invariant_consistent_delta finds color_set_preserved') :-
    P1 = pair([[0,1],[2,0]], [[0,2],[1,0]]),
    P2 = pair([[0,2],[1,0]], [[0,1],[2,0]]),
    invariant_consistent_delta([P1, P2], Delta),
    memberchk(inv(color_set_preserved), Delta).

test('AC-IV-031: invariant_consistent_delta returns [] for empty pairs') :-
    invariant_consistent_delta([], Delta),
    Delta = [].

test('AC-IV-032: invariant_consistent_delta excludes dims_preserved when dims change') :-
    P1 = pair([[0,1],[2,0]], [[0,1,0],[0,2,0]]),  % input 2x2, output 2x3
    invariant_consistent_delta([P1], Delta),
    \+ member(inv(dims_preserved), Delta).

% --- invariant_all_grids / invariant_no_grids ---

test('AC-IV-033: invariant_all_grids succeeds when Goal holds for all') :-
    Grids = [[[0,1],[1,0]], [[0,2],[2,0]]],
    invariant_all_grids(Grids, iv_same_dims_helper_).

% Helper module for invariant_all_grids tests.
iv_same_dims_helper_(G) :- length(G, 2).

test('AC-IV-034: invariant_all_grids fails when Goal fails for some') :-
    Grids = [[[0,1],[1,0]], [[0,0,0]]],
    \+ invariant_all_grids(Grids, iv_same_dims_helper_).

test('AC-IV-035: invariant_no_grids succeeds when Goal fails for all') :-
    Grids = [[[0,1],[1,0]], [[0,2],[2,0]]],
    invariant_no_grids(Grids, iv_three_rows_).

iv_three_rows_(G) :- length(G, 3).

test('AC-IV-036: invariant_no_grids fails when Goal holds for some') :-
    % [[0],[1],[0]] is a 3-row grid; iv_three_rows_ will succeed for it.
    Grids = [[[0,1],[1,0]], [[0],[1],[0]]],
    \+ invariant_no_grids(Grids, iv_three_rows_).

% --- invariant_stable_color_map ---

test('AC-IV-037: invariant_stable_color_map finds consistent mapping') :-
    % Both pairs: 1→2, 2→1 (color swap).
    P1 = pair([[0,1],[2,0]], [[0,2],[1,0]]),
    P2 = pair([[1,0],[0,2]], [[2,0],[0,1]]),
    invariant_stable_color_map([P1, P2], Map),
    memberchk(cm(1,2), Map),
    memberchk(cm(2,1), Map).

test('AC-IV-038: invariant_stable_color_map returns [] for empty pairs') :-
    invariant_stable_color_map([], Map),
    Map = [].

test('AC-IV-039: invariant_stable_color_map returns single pair map for one pair') :-
    P = pair([[0,1],[2,0]], [[0,2],[1,0]]),
    invariant_stable_color_map([P], Map),
    Map \= [].

% --- Integration tests ---

test('AC-IV-040: grid_invariants and preserves_dims agree') :-
    P1 = pair([[0,1],[2,0]], [[0,2],[1,0]]),
    P2 = pair([[0,2],[1,0]], [[0,1],[2,0]]),
    invariant_grid_invariants([P1, P2], Invs),
    (memberchk(inv(dims(2,2)), Invs) ->
        invariant_preserves_dims([P1, P2])
    ;
        \+ invariant_preserves_dims([P1, P2])
    ).

test('AC-IV-041: variant_features complement of grid_invariants') :-
    % If dims invariant, dims should not appear in variant features.
    P1 = pair([[0,1],[2,0]], [[0,2],[1,0]]),
    P2 = pair([[0,2],[1,0]], [[0,1],[2,0]]),
    invariant_grid_invariants([P1, P2], Invs),
    invariant_variant_features([P1, P2], Feats),
    (memberchk(inv(dims(2,2)), Invs) ->
        \+ memberchk(feature(dims), Feats)
    ;
        true
    ).

test('AC-IV-042: consistent_delta and preserves_dims agree') :-
    P1 = pair([[0,1],[2,0]], [[0,2],[1,0]]),
    invariant_consistent_delta([P1], Delta),
    (memberchk(inv(dims_preserved), Delta) ->
        invariant_preserves_dims([P1])
    ;
        true
    ).

test('AC-IV-043: color_set and object_invariants stable_color_set agree') :-
    P1 = pair([[0,1],[2,0]], [[0,2],[1,0]]),
    P2 = pair([[0,1],[2,0]], [[0,2],[1,0]]),
    invariant_color_set([[0,1],[2,0]], 0, Cs),
    invariant_object_invariants([P1, P2], Invs),
    (Invs = [] -> true ;
     memberchk(inv(stable_color_set(Cs)), Invs)).

test('AC-IV-044: full invariant pipeline on symmetric swap task') :-
    % Color swap task: 1↔2, same grid size, same color set.
    P1 = pair([[0,1],[2,0]], [[0,2],[1,0]]),
    P2 = pair([[1,0],[0,2]], [[2,0],[0,1]]),
    Pairs = [P1, P2],
    invariant_grid_invariants(Pairs, GInvs),
    invariant_consistent_delta(Pairs, Delta),
    invariant_stable_color_map(Pairs, Map),
    memberchk(inv(dims(2,2)), GInvs),
    memberchk(inv(dims_preserved), Delta),
    memberchk(inv(color_set_preserved), Delta),
    memberchk(cm(1,2), Map),
    memberchk(cm(2,1), Map).

:- end_tests(invariant).
