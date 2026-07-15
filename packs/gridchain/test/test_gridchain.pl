:- use_module('../prolog/gridchain').

:- begin_tests(gridchain).

% --- gridchain_pairs/2 ---

test('AC-GCH-001: gridchain_pairs on three-element sequence yields two consecutive pairs') :-
    G1 = [[r,b],[b,r]], G2 = [[b,g],[g,b]], G3 = [[r,r],[b,b]],
    gridchain_pairs([G1,G2,G3], Pairs),
    Pairs = [[G1,G2],[G2,G3]].

test('AC-GCH-002: gridchain_pairs on two-element sequence yields one pair') :-
    G1 = [[a,b]], G2 = [[c,d]],
    gridchain_pairs([G1,G2], [[G1,G2]]).

test('AC-GCH-003: gridchain_pairs on single-element sequence yields empty list') :-
    gridchain_pairs([[[r,b]]], []).

% --- gridchain_window/3 ---

test('AC-GCH-004: gridchain_window of width 2 on four-element sequence yields three windows') :-
    G1=[[r]], G2=[[g]], G3=[[b]], G4=[[y]],
    gridchain_window([G1,G2,G3,G4], 2, W),
    W = [[G1,G2],[G2,G3],[G3,G4]].

test('AC-GCH-005: gridchain_window of width 3 on three-element sequence yields one window') :-
    G1=[[a]], G2=[[b]], G3=[[c]],
    gridchain_window([G1,G2,G3], 3, [[G1,G2,G3]]).

test('AC-GCH-006: gridchain_window width exceeds sequence length yields empty list') :-
    gridchain_window([[[r]],[[g]]], 5, []).

% --- gridchain_zip/3 ---

test('AC-GCH-007: gridchain_zip of two equal-length sequences') :-
    G1=[[r,b]], G2=[[b,g]], G3=[[g,r]], G4=[[y,y]],
    gridchain_zip([G1,G2], [G3,G4], [[G1,G3],[G2,G4]]).

test('AC-GCH-008: gridchain_zip truncates to shorter sequence') :-
    G1=[[a]], G2=[[b]], G3=[[c]],
    gridchain_zip([G1,G2,G3], [G2], [[G1,G2]]).

test('AC-GCH-009: gridchain_zip with empty first list yields empty') :-
    gridchain_zip([], [[[r]]], []).

% --- gridchain_take/3 ---

test('AC-GCH-010: gridchain_take first 2 of 3 grids') :-
    G1=[[r]], G2=[[g]], G3=[[b]],
    gridchain_take([G1,G2,G3], 2, [G1,G2]).

test('AC-GCH-011: gridchain_take all grids when N equals length') :-
    G1=[[a]], G2=[[b]],
    gridchain_take([G1,G2], 2, [G1,G2]).

test('AC-GCH-012: gridchain_take clamps when N exceeds length') :-
    G1=[[r]], G2=[[g]],
    gridchain_take([G1,G2], 10, [G1,G2]).

% --- gridchain_drop/3 ---

test('AC-GCH-013: gridchain_drop first 1 of 3 grids') :-
    G1=[[r]], G2=[[g]], G3=[[b]],
    gridchain_drop([G1,G2,G3], 1, [G2,G3]).

test('AC-GCH-014: gridchain_drop all grids when N equals length') :-
    G1=[[a]], G2=[[b]],
    gridchain_drop([G1,G2], 2, []).

test('AC-GCH-015: gridchain_drop clamps when N exceeds length') :-
    G1=[[r]], G2=[[g]],
    gridchain_drop([G1,G2], 10, []).

% --- gridchain_nth/3 ---

test('AC-GCH-016: gridchain_nth index 0 returns first grid') :-
    G1=[[r,b]], G2=[[b,r]],
    gridchain_nth([G1,G2], 0, G1).

test('AC-GCH-017: gridchain_nth index 1 returns second grid') :-
    G1=[[a]], G2=[[b]], G3=[[c]],
    gridchain_nth([G1,G2,G3], 1, G2).

test('AC-GCH-018: gridchain_nth index 2 returns third grid') :-
    G1=[[r]], G2=[[g]], G3=[[b]],
    gridchain_nth([G1,G2,G3], 2, G3).

% --- gridchain_all_same/1 ---

test('AC-GCH-019: gridchain_all_same succeeds for three identical grids') :-
    G = [[r,b],[b,r]],
    gridchain_all_same([G,G,G]).

test('AC-GCH-020: gridchain_all_same succeeds for single grid') :-
    gridchain_all_same([[[a,b]]]).

test('AC-GCH-021: gridchain_all_same fails when grids differ', [fail]) :-
    G1 = [[r]], G2 = [[g]],
    gridchain_all_same([G1,G2]).

% --- gridchain_dedup/2 ---

test('AC-GCH-022: gridchain_dedup removes consecutive duplicate') :-
    G1=[[r]], G2=[[g]],
    gridchain_dedup([G1,G1,G2], [G1,G2]).

test('AC-GCH-023: gridchain_dedup removes non-consecutive duplicate preserving order') :-
    G1=[[r]], G2=[[g]], G3=[[b]],
    gridchain_dedup([G1,G2,G1,G3], [G1,G2,G3]).

test('AC-GCH-024: gridchain_dedup on all-same list returns singleton') :-
    G = [[r,b]],
    gridchain_dedup([G,G,G], [G]).

% --- gridchain_cycle/3 ---

test('AC-GCH-025: gridchain_cycle repeats grid 3 times') :-
    G = [[r,b],[b,r]],
    gridchain_cycle(G, 3, [G,G,G]).

test('AC-GCH-026: gridchain_cycle of 1 yields singleton list') :-
    G = [[a,b]],
    gridchain_cycle(G, 1, [G]).

test('AC-GCH-027: gridchain_cycle of 0 yields empty list') :-
    gridchain_cycle([[r]], 0, []).

% --- gridchain_interleave/3 ---

test('AC-GCH-028: gridchain_interleave two equal-length sequences') :-
    G1=[[r]], G2=[[g]], G3=[[b]], G4=[[y]],
    gridchain_interleave([G1,G2], [G3,G4], [G1,G3,G2,G4]).

test('AC-GCH-029: gridchain_interleave truncates to shorter sequence') :-
    G1=[[a]], G2=[[b]], G3=[[c]],
    gridchain_interleave([G1,G2,G3], [G2], [G1,G2]).

test('AC-GCH-030: gridchain_interleave with empty first list yields empty') :-
    gridchain_interleave([], [[[r]]], []).

% --- gridchain_split_at/4 ---

test('AC-GCH-031: gridchain_split_at index 2 of 4-element sequence') :-
    G1=[[r]], G2=[[g]], G3=[[b]], G4=[[y]],
    gridchain_split_at([G1,G2,G3,G4], 2, [G1,G2], [G3,G4]).

test('AC-GCH-032: gridchain_split_at index 0 yields empty before list') :-
    G1=[[a]], G2=[[b]],
    gridchain_split_at([G1,G2], 0, [], [G1,G2]).

test('AC-GCH-033: gridchain_split_at at full length yields empty after list') :-
    G1=[[r]], G2=[[g]],
    gridchain_split_at([G1,G2], 2, [G1,G2], []).

% --- gridchain_reverse/2 ---

test('AC-GCH-034: gridchain_reverse three-element sequence') :-
    G1=[[r]], G2=[[g]], G3=[[b]],
    gridchain_reverse([G1,G2,G3], [G3,G2,G1]).

test('AC-GCH-035: gridchain_reverse single-element sequence') :-
    G = [[a,b]],
    gridchain_reverse([G], [G]).

test('AC-GCH-036: gridchain_reverse empty sequence') :-
    gridchain_reverse([], []).

% --- gridchain_diff_counts/3 ---

test('AC-GCH-037: gridchain_diff_counts one pair zero differences') :-
    G = [[r,b],[b,r]],
    gridchain_diff_counts([G,G], b, [0]).

test('AC-GCH-038: gridchain_diff_counts one pair all cells differ') :-
    G1 = [[r,r],[r,r]], G2 = [[b,b],[b,b]],
    gridchain_diff_counts([G1,G2], b, [4]).

test('AC-GCH-039: gridchain_diff_counts two pairs with mixed differences') :-
    G1 = [[r,b]], G2 = [[b,b]], G3 = [[b,r]],
    gridchain_diff_counts([G1,G2,G3], b, [1,1]).

% --- gridchain_changes_mask/4 ---

test('AC-GCH-040: gridchain_changes_mask marks single changed cell') :-
    G1 = [[r,b],[b,b]],
    G2 = [[r,b],[b,r]],
    G3 = [[r,b],[b,r]],
    gridchain_changes_mask([G1,G2,G3], b, m, [[b,b],[b,m]]).

test('AC-GCH-041: gridchain_changes_mask with no changes yields all-bg mask') :-
    G = [[r,b],[b,r]],
    gridchain_changes_mask([G,G,G], b, m, [[b,b],[b,b]]).

test('AC-GCH-042: gridchain_changes_mask on single-grid input returns all-bg mask') :-
    G = [[r,b],[b,r]],
    gridchain_changes_mask([G], b, m, [[b,b],[b,b]]).

% --- combined/integration tests ---

test('AC-GCH-043: window + diff_counts tracks per-window change counts') :-
    G1=[[r,b]], G2=[[b,r]], G3=[[r,r]], G4=[[b,b]],
    gridchain_window([G1,G2,G3,G4], 2, Windows),
    findall(C, (member([Ga,Gb], Windows), gridchain_diff_counts([Ga,Gb], b, [C])), Counts),
    Counts = [2,1,2].

test('AC-GCH-044: cycle then dedup returns singleton') :-
    G = [[a,b],[c,d]],
    gridchain_cycle(G, 5, Seq),
    gridchain_dedup(Seq, [G]).

:- end_tests(gridchain).
