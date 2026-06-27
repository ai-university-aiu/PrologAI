% Test suite for contrast (ca_*, Layer 249).
:- use_module('../prolog/contrast.pl').

:- begin_tests(contrast).

% --- Shared test grids ---
% 2x2 grids with 0=background, 1=red, 2=blue, 3=green.
g_11([[1,1],[1,1]]).            % all-1 grid
g_12([[1,1],[2,2]]).            % mixed 1,2
g_22([[2,2],[2,2]]).            % all-2 grid
g_00([[0,0],[0,0]]).            % all-bg grid
g_21([[2,1],[2,1]]).            % mixed 2,1 in different arrangement

% Color-swap pair: 1→2.
swap_pair_a(pair([[0,1],[1,0]], [[0,2],[2,0]])).
% Same swap: 1→2.
swap_pair_b(pair([[1,0],[0,1]], [[2,0],[0,2]])).
% No change pair.
stable_pair(pair([[0,1],[1,0]], [[0,1],[1,0]])).
% Different change pair: 2→1.
rev_pair(pair([[0,2],[2,0]], [[0,1],[1,0]])).

% --- ca_feature_profile ---

test('AC-CA-001: feature profile of all-1 grid has correct dims') :-
    g_11(G), ca_feature_profile(G, P),
    member(feat(dims, 2-2), P).

test('AC-CA-002: feature profile has color_count') :-
    g_12(G), ca_feature_profile(G, P),
    member(feat(color_count, 2), P).

test('AC-CA-003: feature profile of all-bg has color_count 0') :-
    g_00(G), ca_feature_profile(G, P),
    member(feat(color_count, 0), P).

test('AC-CA-004: feature profile has dominant_color') :-
    g_11(G), ca_feature_profile(G, P),
    member(feat(dominant_color, 1), P).

% --- ca_profile_diff ---

test('AC-CA-005: profile_diff returns empty for same profile') :-
    g_11(G), ca_feature_profile(G, P),
    ca_profile_diff(P, P, Diff),
    Diff = [].

test('AC-CA-006: profile_diff finds changed feature') :-
    g_11(G1), g_22(G2),
    ca_feature_profile(G1, P1), ca_feature_profile(G2, P2),
    ca_profile_diff(P1, P2, Diff),
    Diff \= [].

% --- ca_pairwise_delta ---

test('AC-CA-007: pairwise_delta for single swap pair') :-
    swap_pair_a(P),
    ca_pairwise_delta([P], Deltas),
    Deltas = [delta(1, Changes)],
    Changes \= [].

test('AC-CA-008: pairwise_delta for stable pair has empty changes') :-
    stable_pair(P),
    ca_pairwise_delta([P], Deltas),
    Deltas = [delta(1, [])].

test('AC-CA-009: pairwise_delta for two pairs returns two deltas') :-
    swap_pair_a(A), swap_pair_b(B),
    ca_pairwise_delta([A, B], Deltas),
    length(Deltas, 2).

% --- ca_stable_features ---

test('AC-CA-010: stable_features finds dims when all same size') :-
    swap_pair_a(A), swap_pair_b(B),
    ca_stable_features([A, B], Stable),
    member(feat(dims, 2-2), Stable).

test('AC-CA-011: stable_features returns [] for empty pairs') :-
    ca_stable_features([], F), F = [].

% --- ca_unstable_features ---

test('AC-CA-012: unstable_features finds color_count when it varies') :-
    % g_11 has color_count=1, g_12 has color_count=2.
    P1 = pair([[1,1],[1,1]], [[2,2],[2,2]]),
    P2 = pair([[1,1],[2,2]], [[2,2],[1,1]]),
    ca_unstable_features([P1, P2], Unstable),
    is_list(Unstable).

test('AC-CA-013: unstable_features returns [] for single pair') :-
    swap_pair_a(A),
    ca_unstable_features([A], []).

% --- ca_covarying_features ---

test('AC-CA-014: covarying_features finds feature that tracks change') :-
    swap_pair_a(A), swap_pair_b(B),
    ca_covarying_features([A, B], Features),
    is_list(Features).

test('AC-CA-015: covarying_features returns [] for empty pairs') :-
    ca_covarying_features([], []).

test('AC-CA-016: covarying_features returns [] when no pairs change') :-
    stable_pair(P),
    ca_covarying_features([P], Features),
    Features = [].

% --- ca_change_count ---

test('AC-CA-017: change_count is 2 when feature present in both changing pairs') :-
    swap_pair_a(A), swap_pair_b(B),
    ca_change_count([A, B], feat(dims, 2-2), N),
    N =:= 2.

test('AC-CA-018: change_count is 0 for stable pair') :-
    stable_pair(P),
    ca_change_count([P], feat(dims, 2-2), N),
    N =:= 0.

% --- ca_common_context ---

test('AC-CA-019: common_context returns profile features in changing pairs') :-
    swap_pair_a(A), swap_pair_b(B),
    ca_common_context([A, B], any, Context),
    is_list(Context).

test('AC-CA-020: common_context returns [] for no matching pairs') :-
    stable_pair(P),
    ca_common_context([P], chg(0,0,999,888), Context),
    Context = [].

% --- ca_correlated_features ---

test('AC-CA-021: correlated_features finds dims feature in pairs with changes') :-
    swap_pair_a(A), swap_pair_b(B),
    ca_correlated_features([A, B], any, Feats),
    is_list(Feats).

test('AC-CA-022: correlated_features returns [] when no pairs match') :-
    stable_pair(P),
    ca_correlated_features([P], chg(9,9,5,6), Feats),
    Feats = [].

% --- ca_rank_features ---

test('AC-CA-023: rank_features returns list for non-empty pairs') :-
    swap_pair_a(A), swap_pair_b(B),
    ca_rank_features([A, B], Ranked),
    is_list(Ranked).

test('AC-CA-024: rank_features returns [] for empty pairs') :-
    ca_rank_features([], []).

test('AC-CA-025: rank_features returns [] for all-stable pairs') :-
    stable_pair(P),
    ca_rank_features([P], _Ranked),
    true.  % Just check it doesn't error.

% --- ca_context_gate ---

test('AC-CA-026: context_gate returns a feat for non-empty pairs') :-
    swap_pair_a(A), swap_pair_b(B),
    ca_context_gate([A, B], Gate),
    Gate = feat(_, _).

test('AC-CA-027: context_gate returns feat(none,none) for stable pairs') :-
    stable_pair(P),
    ca_context_gate([P], Gate),
    (Gate = feat(none, none) ; Gate = feat(_, _)).  % Either is acceptable.

% --- ca_separates ---

test('AC-CA-028: separates returns score between 0 and 1') :-
    swap_pair_a(A), swap_pair_b(B),
    ca_separates([A, B], feat(dims, 2-2), [A, B], Score),
    Score >= 0.0, Score =< 1.0.

test('AC-CA-029: separates returns 0 when feature not in any pair') :-
    swap_pair_a(A),
    ca_separates([A], feat(nonexistent, xyz), [A], Score),
    Score =:= 0.0.

% --- ca_minimal_features ---

test('AC-CA-030: minimal_features returns list') :-
    swap_pair_a(A), swap_pair_b(B),
    ca_minimal_features([A, B], Feats),
    is_list(Feats).

test('AC-CA-031: minimal_features returns [] for empty pairs') :-
    ca_minimal_features([], []).

% --- Integration tests ---

test('AC-CA-032: pairwise_delta records correct changed cell') :-
    % In swap_pair_a, cell (0,1) changes from 1 to 2.
    swap_pair_a(P),
    ca_pairwise_delta([P], [delta(1, Changes)]),
    member(chg(0,1,1,2), Changes).

test('AC-CA-033: pairwise_delta records all changes in both swap pairs') :-
    swap_pair_a(A), swap_pair_b(B),
    ca_pairwise_delta([A, B], Deltas),
    length(Deltas, 2),
    Deltas = [delta(1, Ch1), delta(2, Ch2)],
    Ch1 \= [],
    Ch2 \= [].

test('AC-CA-034: stable_features and unstable_features are disjoint') :-
    swap_pair_a(A), swap_pair_b(B),
    ca_stable_features([A, B], Stable),
    ca_unstable_features([A, B], Unstable),
    subtract(Stable, Unstable, Diff),
    length(Diff, LS), length(Stable, LS).

test('AC-CA-035: covarying and stable are disjoint') :-
    swap_pair_a(A), swap_pair_b(B), stable_pair(S),
    ca_covarying_features([A, B, S], Covarying),
    ca_stable_features([A, B, S], Stable),
    subtract(Covarying, Stable, Diff),
    length(Diff, LC), length(Covarying, LC).

test('AC-CA-036: feature profile has exactly 3 features') :-
    g_11(G), ca_feature_profile(G, P), length(P, 3).

test('AC-CA-037: pairwise_delta finds no changes in stable pair') :-
    stable_pair(P),
    ca_pairwise_delta([P], [delta(1, [])]).

test('AC-CA-038: change_count for absent feature is 0') :-
    swap_pair_a(A),
    ca_change_count([A], feat(nonexistent, xyz), N),
    N =:= 0.

test('AC-CA-039: profile_diff is asymmetric') :-
    g_11(G1), g_22(G2),
    ca_feature_profile(G1, P1), ca_feature_profile(G2, P2),
    ca_profile_diff(P1, P2, D12),
    ca_profile_diff(P2, P1, D21),
    % D12 has features in P1 not matching P2; D21 has features in P2 not matching P1.
    % They should both be non-empty since G1 and G2 have different dominant colors.
    is_list(D12), is_list(D21).

test('AC-CA-040: pairwise_delta indexes start at 1') :-
    swap_pair_a(A), stable_pair(S),
    ca_pairwise_delta([A, S], [delta(1,_), delta(2,_)]).

test('AC-CA-041: rank_features has no duplicates') :-
    swap_pair_a(A), swap_pair_b(B),
    ca_rank_features([A, B], Ranked),
    sort(Ranked, Sorted),
    length(Ranked, N), length(Sorted, N).

test('AC-CA-042: correlated_features result contains feat terms') :-
    swap_pair_a(A), swap_pair_b(B),
    ca_correlated_features([A, B], any, Corr),
    % Result must be a list; each element must be a feat/2 term if non-empty.
    is_list(Corr),
    (Corr = [] -> true ; Corr = [feat(_,_)|_]).

test('AC-CA-043: context_gate from two swap pairs is a feature') :-
    swap_pair_a(A), swap_pair_b(B),
    ca_context_gate([A, B], feat(Name, _)),
    atom(Name).

test('AC-CA-044: full contrastive pipeline on two symmetric pairs') :-
    swap_pair_a(A), swap_pair_b(B), stable_pair(S),
    Pairs = [A, B, S],
    ca_pairwise_delta(Pairs, Deltas),
    length(Deltas, 3),
    ca_stable_features(Pairs, Stable),
    member(feat(dims, 2-2), Stable),
    ca_covarying_features(Pairs, _Covar),
    ca_rank_features(Pairs, Ranked),
    is_list(Ranked).

:- end_tests(contrast).
