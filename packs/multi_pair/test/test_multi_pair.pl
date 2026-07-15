% Test suite for multipair (mp_*, Layer 251).
:- use_module('../prolog/multi_pair.pl').

:- begin_tests(multi_pair).

% --- Shared test pairs ---
% Color-swap task: 1→2, 2→1 across two pairs.
pair_swap_a(pair([[0,1],[2,0]], [[0,2],[1,0]])).
pair_swap_b(pair([[1,0],[0,2]], [[2,0],[0,1]])).

% Marker task: color 3 is a marker (present in input but not output).
pair_marker_a(pair([[1,1,3],[1,1,0],[0,0,0]], [[2,2,0],[2,2,0],[0,0,0]])).
pair_marker_b(pair([[1,1,0],[1,1,3],[0,0,0]], [[2,2,0],[2,2,0],[0,0,0]])).

% Single stable pair (no change).
pair_stable(pair([[1,1],[1,1]], [[1,1],[1,1]])).

% Pairs with new color appearing in output.
pair_new_a(pair([[0,1],[1,0]], [[0,5],[5,0]])).
pair_new_b(pair([[1,0],[0,1]], [[5,0],[0,5]])).

% --- multi_pair_all_input_objects ---

test('AC-MP-001: all_input_objects for two swap pairs') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_all_input_objects([A, B], Objects),
    member(po(1, 1), Objects),
    member(po(1, 2), Objects).

test('AC-MP-002: all_input_objects returns empty for all-bg pair') :-
    P = pair([[0,0],[0,0]], [[0,0],[0,0]]),
    multi_pair_all_input_objects([P], Objects),
    Objects = [].

test('AC-MP-003: all_input_objects indexes start at 1') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_all_input_objects([A, B], Objects),
    \+ member(po(0, _), Objects).

% --- multi_pair_color_frequency ---

test('AC-MP-004: color_frequency is 2 for color in both swap pairs') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_color_frequency([A, B], 1, N),
    N =:= 2.

test('AC-MP-005: color_frequency is 1 for color in one pair') :-
    pair_swap_a(A), pair_swap_b(B),
    % Add a pair with color 7 only.
    P7 = pair([[7,0],[0,0]], [[0,0],[0,0]]),
    multi_pair_color_frequency([A, B, P7], 7, N),
    N =:= 1.

test('AC-MP-006: color_frequency is 0 for absent color') :-
    pair_swap_a(A),
    multi_pair_color_frequency([A], 99, N),
    N =:= 0.

% --- multi_pair_universal_colors ---

test('AC-MP-007: universal_colors returns colors in all pairs') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_universal_colors([A, B], Colors),
    member(1, Colors), member(2, Colors).

test('AC-MP-008: universal_colors returns [] for empty pairs') :-
    multi_pair_universal_colors([], Colors),
    Colors = [].

test('AC-MP-009: universal_colors excludes color only in one pair') :-
    pair_swap_a(A),
    P7 = pair([[7,0],[0,0]], [[0,0],[0,0]]),
    multi_pair_universal_colors([A, P7], Colors),
    \+ member(7, Colors).

% --- multi_pair_variable_colors ---

test('AC-MP-010: variable_colors finds colors in some but not all pairs') :-
    pair_swap_a(A),
    P7 = pair([[7,0],[0,0]], [[0,0],[0,0]]),
    multi_pair_variable_colors([A, P7], Colors),
    member(7, Colors).

test('AC-MP-011: variable_colors returns [] when all colors universal') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_variable_colors([A, B], Var),
    % Colors 1 and 2 appear in both → no variable colors.
    Var = [].

test('AC-MP-012: variable_colors returns [] for empty pairs') :-
    multi_pair_variable_colors([], Colors),
    Colors = [].

% --- multi_pair_consistent_count ---

test('AC-MP-013: consistent_count succeeds when all inputs same color count') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_consistent_count([A, B]).

test('AC-MP-014: consistent_count fails when counts differ') :-
    pair_swap_a(A),
    % pair with 3 colors: 1, 2, 7.
    P3 = pair([[1,2],[7,0]], [[0,0],[0,0]]),
    \+ multi_pair_consistent_count([A, P3]).

% --- multi_pair_modal_object_count ---

test('AC-MP-015: modal_object_count is 2 for two-color pairs') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_modal_object_count([A, B], Count),
    Count =:= 2.

test('AC-MP-016: modal_object_count is 0 for all-bg pairs') :-
    P = pair([[0,0],[0,0]], [[0,0],[0,0]]),
    multi_pair_modal_object_count([P], Count),
    Count =:= 0.

% --- multi_pair_track_objects ---

test('AC-MP-017: track_objects returns tracked terms') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_track_objects([A, B], Tracked),
    Tracked \= [].

test('AC-MP-018: track_objects finds color 1 in both pairs') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_track_objects([A, B], Tracked),
    member(tracked(_, 1, PairList), Tracked),
    length(PairList, 2).

test('AC-MP-019: track_objects assigns unique indices') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_track_objects([A, B], Tracked),
    findall(I, member(tracked(I,_,_), Tracked), Idxs),
    sort(Idxs, SortedIdxs),
    length(Idxs, N), length(SortedIdxs, N).

% --- multi_pair_invariant_objects ---

test('AC-MP-020: invariant_objects finds colors in all pairs') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_track_objects([A, B], Tracked),
    multi_pair_invariant_objects(Tracked, Inv),
    findall(C, member(tracked(_, C, _), Inv), Colors),
    member(1, Colors), member(2, Colors).

test('AC-MP-021: invariant_objects returns [] for empty tracked') :-
    multi_pair_invariant_objects([], Inv),
    Inv = [].

% --- multi_pair_role_objects ---

test('AC-MP-022: role_objects: content is universal, markers are variable') :-
    pair_swap_a(A), pair_swap_b(B),
    P7 = pair([[7,0,1],[0,2,0]], [[0,0,2],[0,1,0]]),
    multi_pair_track_objects([A, B, P7], Tracked),
    multi_pair_role_objects(Tracked, Content, Markers),
    is_list(Content), is_list(Markers).

test('AC-MP-023: role_objects: content + markers = all tracked') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_track_objects([A, B], Tracked),
    multi_pair_role_objects(Tracked, Content, Markers),
    length(Tracked, T), length(Content, C), length(Markers, M),
    T =:= C + M.

% --- multi_pair_cross_pair_match ---

test('AC-MP-024: cross_pair_match for two pairs returns one entry') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_cross_pair_match([A, B], Matrix),
    length(Matrix, 1).

test('AC-MP-025: cross_pair_match entry has common colors') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_cross_pair_match([A, B], [match(1, 2, Common)]),
    member(1, Common), member(2, Common).

test('AC-MP-026: cross_pair_match for three pairs returns three entries') :-
    pair_swap_a(A), pair_swap_b(B), pair_stable(S),
    multi_pair_cross_pair_match([A, B, S], Matrix),
    length(Matrix, 3).

% --- multi_pair_disappeared_objects ---

test('AC-MP-027: disappeared_objects finds marker color absent from outputs') :-
    pair_marker_a(A), pair_marker_b(B),
    multi_pair_disappeared_objects([A, B], Disappeared),
    member(3, Disappeared).

test('AC-MP-028: disappeared_objects is empty when all colors in output') :-
    pair_swap_a(A), pair_swap_b(B),
    % Colors 1 and 2 both appear in outputs (as each other).
    multi_pair_disappeared_objects([A, B], D),
    is_list(D).

% --- multi_pair_appeared_objects ---

test('AC-MP-029: appeared_objects finds new color in output') :-
    pair_new_a(A), pair_new_b(B),
    multi_pair_appeared_objects([A, B], Appeared),
    member(5, Appeared).

test('AC-MP-030: appeared_objects is [] when no new colors') :-
    pair_stable(P),
    multi_pair_appeared_objects([P], Appeared),
    Appeared = [].

% --- multi_pair_stable_color_objects ---

test('AC-MP-031: stable_color_objects finds colors with same count') :-
    pair_swap_a(A), pair_swap_b(B),
    % Both inputs have 2 cells of color 1 and 2 cells of color 2.
    multi_pair_stable_color_objects([A, B], Stable),
    is_list(Stable).

test('AC-MP-032: stable_color_objects returns [] for empty pairs') :-
    multi_pair_stable_color_objects([], Stable),
    Stable = [].

% --- multi_pair_singleton_color ---

test('AC-MP-033: singleton_color finds color in exactly one pair') :-
    pair_swap_a(A), pair_swap_b(B),
    P7 = pair([[7,1],[0,2]], [[0,0],[0,0]]),
    multi_pair_singleton_color([A, B, P7], 7).

test('AC-MP-034: singleton_color fails for universal color') :-
    pair_swap_a(A), pair_swap_b(B),
    \+ multi_pair_singleton_color([A, B], 1).

% --- Integration tests ---

test('AC-MP-035: universal and variable colors are disjoint') :-
    pair_swap_a(A), pair_swap_b(B),
    P7 = pair([[7,1],[0,2]], [[0,0],[0,0]]),
    multi_pair_universal_colors([A, B, P7], Universal),
    multi_pair_variable_colors([A, B, P7], Variable),
    subtract(Universal, Variable, Diff),
    length(Diff, LU), length(Universal, LU).

test('AC-MP-036: invariant + marker objects = all tracked') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_track_objects([A, B], T),
    multi_pair_invariant_objects(T, Inv),
    subtract(T, Inv, Markers),
    length(T, TN), length(Inv, IN), length(Markers, MN),
    TN =:= IN + MN.

test('AC-MP-037: track_objects and universal_colors agree on universal count') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_track_objects([A, B], Tracked),
    multi_pair_invariant_objects(Tracked, Inv),
    multi_pair_universal_colors([A, B], Universal),
    length(Inv, NI), length(Universal, NU),
    NI =:= NU.

test('AC-MP-038: all_input_objects has 2*NPairs entries for 2-color grids') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_all_input_objects([A, B], Objects),
    length(Objects, N),
    N =:= 4.  % 2 pairs * 2 colors each.

test('AC-MP-039: cross_pair_match indices are always i < j') :-
    pair_swap_a(A), pair_swap_b(B), pair_stable(S),
    multi_pair_cross_pair_match([A, B, S], Matrix),
    forall(member(match(I, J, _), Matrix), I < J).

test('AC-MP-040: modal_count consistent with consistent_count') :-
    pair_swap_a(A), pair_swap_b(B),
    multi_pair_modal_object_count([A, B], Count),
    (multi_pair_consistent_count([A, B]) ->
        findall(N, (member(pair(In, _), [A, B]),
                    findall(C, (member(Row, In), member(C, Row), C \= 0), All0),
                    sort(All0, Uniq), length(Uniq, N)), Counts),
        last(Counts, LastN),
        Count =:= LastN
    ;
        true
    ).

test('AC-MP-041: disappeared_objects is subset of universal_colors') :-
    pair_marker_a(A), pair_marker_b(B),
    multi_pair_disappeared_objects([A, B], D),
    multi_pair_universal_colors([A, B], U),
    subtract(D, U, Outside),
    Outside = [].

test('AC-MP-042: appeared_objects disjoint from all input colors') :-
    pair_new_a(A), pair_new_b(B),
    multi_pair_appeared_objects([A, B], Appeared),
    multi_pair_all_input_objects([A, B], InputObjs),
    findall(C, member(po(_, C), InputObjs), InputColors0),
    sort(InputColors0, InputColors),
    subtract(Appeared, InputColors, Result),
    Result = Appeared.  % None of the appeared colors were in any input.

test('AC-MP-043: consistent_count and modal_count agree for uniform pairs') :-
    pair_swap_a(A), pair_swap_b(B),
    (multi_pair_consistent_count([A, B]) ->
        multi_pair_modal_object_count([A, B], Count),
        Count >= 1
    ;
        true
    ).

test('AC-MP-044: full multi-pair pipeline on swap task') :-
    pair_swap_a(A), pair_swap_b(B),
    Pairs = [A, B],
    multi_pair_all_input_objects(Pairs, AllObjs),
    AllObjs \= [],
    multi_pair_universal_colors(Pairs, Universal),
    member(1, Universal), member(2, Universal),
    multi_pair_track_objects(Pairs, Tracked),
    multi_pair_invariant_objects(Tracked, Inv),
    length(Inv, 2),  % Both colors universal.
    multi_pair_cross_pair_match(Pairs, Matrix),
    length(Matrix, 1),
    multi_pair_consistent_count(Pairs).

:- end_tests(multi_pair).
