:- use_module('../prolog/gridchain').

:- begin_tests(gridchain).

% --- gch_pairs/2 ---

test('AC-GCH-001: gch_pairs on three-element sequence yields two consecutive pairs') :-
    G1 = [[r,b],[b,r]], G2 = [[b,g],[g,b]], G3 = [[r,r],[b,b]],
    gch_pairs([G1,G2,G3], Pairs),
    Pairs = [[G1,G2],[G2,G3]].

test('AC-GCH-002: gch_pairs on two-element sequence yields one pair') :-
    G1 = [[a,b]], G2 = [[c,d]],
    gch_pairs([G1,G2], [[G1,G2]]).

test('AC-GCH-003: gch_pairs on single-element sequence yields empty list') :-
    gch_pairs([[[r,b]]], []).

% --- gch_window/3 ---

test('AC-GCH-004: gch_window of width 2 on four-element sequence yields three windows') :-
    G1=[[r]], G2=[[g]], G3=[[b]], G4=[[y]],
    gch_window([G1,G2,G3,G4], 2, W),
    W = [[G1,G2],[G2,G3],[G3,G4]].

test('AC-GCH-005: gch_window of width 3 on three-element sequence yields one window') :-
    G1=[[a]], G2=[[b]], G3=[[c]],
    gch_window([G1,G2,G3], 3, [[G1,G2,G3]]).

test('AC-GCH-006: gch_window width exceeds sequence length yields empty list') :-
    gch_window([[[r]],[[g]]], 5, []).

% --- gch_zip/3 ---

test('AC-GCH-007: gch_zip of two equal-length sequences') :-
    G1=[[r,b]], G2=[[b,g]], G3=[[g,r]], G4=[[y,y]],
    gch_zip([G1,G2], [G3,G4], [[G1,G3],[G2,G4]]).

test('AC-GCH-008: gch_zip truncates to shorter sequence') :-
    G1=[[a]], G2=[[b]], G3=[[c]],
    gch_zip([G1,G2,G3], [G2], [[G1,G2]]).

test('AC-GCH-009: gch_zip with empty first list yields empty') :-
    gch_zip([], [[[r]]], []).

% --- gch_take/3 ---

test('AC-GCH-010: gch_take first 2 of 3 grids') :-
    G1=[[r]], G2=[[g]], G3=[[b]],
    gch_take([G1,G2,G3], 2, [G1,G2]).

test('AC-GCH-011: gch_take all grids when N equals length') :-
    G1=[[a]], G2=[[b]],
    gch_take([G1,G2], 2, [G1,G2]).

test('AC-GCH-012: gch_take clamps when N exceeds length') :-
    G1=[[r]], G2=[[g]],
    gch_take([G1,G2], 10, [G1,G2]).

% --- gch_drop/3 ---

test('AC-GCH-013: gch_drop first 1 of 3 grids') :-
    G1=[[r]], G2=[[g]], G3=[[b]],
    gch_drop([G1,G2,G3], 1, [G2,G3]).

test('AC-GCH-014: gch_drop all grids when N equals length') :-
    G1=[[a]], G2=[[b]],
    gch_drop([G1,G2], 2, []).

test('AC-GCH-015: gch_drop clamps when N exceeds length') :-
    G1=[[r]], G2=[[g]],
    gch_drop([G1,G2], 10, []).

% --- gch_nth/3 ---

test('AC-GCH-016: gch_nth index 0 returns first grid') :-
    G1=[[r,b]], G2=[[b,r]],
    gch_nth([G1,G2], 0, G1).

test('AC-GCH-017: gch_nth index 1 returns second grid') :-
    G1=[[a]], G2=[[b]], G3=[[c]],
    gch_nth([G1,G2,G3], 1, G2).

test('AC-GCH-018: gch_nth index 2 returns third grid') :-
    G1=[[r]], G2=[[g]], G3=[[b]],
    gch_nth([G1,G2,G3], 2, G3).

% --- gch_all_same/1 ---

test('AC-GCH-019: gch_all_same succeeds for three identical grids') :-
    G = [[r,b],[b,r]],
    gch_all_same([G,G,G]).

test('AC-GCH-020: gch_all_same succeeds for single grid') :-
    gch_all_same([[[a,b]]]).

test('AC-GCH-021: gch_all_same fails when grids differ', [fail]) :-
    G1 = [[r]], G2 = [[g]],
    gch_all_same([G1,G2]).

% --- gch_dedup/2 ---

test('AC-GCH-022: gch_dedup removes consecutive duplicate') :-
    G1=[[r]], G2=[[g]],
    gch_dedup([G1,G1,G2], [G1,G2]).

test('AC-GCH-023: gch_dedup removes non-consecutive duplicate preserving order') :-
    G1=[[r]], G2=[[g]], G3=[[b]],
    gch_dedup([G1,G2,G1,G3], [G1,G2,G3]).

test('AC-GCH-024: gch_dedup on all-same list returns singleton') :-
    G = [[r,b]],
    gch_dedup([G,G,G], [G]).

% --- gch_cycle/3 ---

test('AC-GCH-025: gch_cycle repeats grid 3 times') :-
    G = [[r,b],[b,r]],
    gch_cycle(G, 3, [G,G,G]).

test('AC-GCH-026: gch_cycle of 1 yields singleton list') :-
    G = [[a,b]],
    gch_cycle(G, 1, [G]).

test('AC-GCH-027: gch_cycle of 0 yields empty list') :-
    gch_cycle([[r]], 0, []).

% --- gch_interleave/3 ---

test('AC-GCH-028: gch_interleave two equal-length sequences') :-
    G1=[[r]], G2=[[g]], G3=[[b]], G4=[[y]],
    gch_interleave([G1,G2], [G3,G4], [G1,G3,G2,G4]).

test('AC-GCH-029: gch_interleave truncates to shorter sequence') :-
    G1=[[a]], G2=[[b]], G3=[[c]],
    gch_interleave([G1,G2,G3], [G2], [G1,G2]).

test('AC-GCH-030: gch_interleave with empty first list yields empty') :-
    gch_interleave([], [[[r]]], []).

% --- gch_split_at/4 ---

test('AC-GCH-031: gch_split_at index 2 of 4-element sequence') :-
    G1=[[r]], G2=[[g]], G3=[[b]], G4=[[y]],
    gch_split_at([G1,G2,G3,G4], 2, [G1,G2], [G3,G4]).

test('AC-GCH-032: gch_split_at index 0 yields empty before list') :-
    G1=[[a]], G2=[[b]],
    gch_split_at([G1,G2], 0, [], [G1,G2]).

test('AC-GCH-033: gch_split_at at full length yields empty after list') :-
    G1=[[r]], G2=[[g]],
    gch_split_at([G1,G2], 2, [G1,G2], []).

% --- gch_reverse/2 ---

test('AC-GCH-034: gch_reverse three-element sequence') :-
    G1=[[r]], G2=[[g]], G3=[[b]],
    gch_reverse([G1,G2,G3], [G3,G2,G1]).

test('AC-GCH-035: gch_reverse single-element sequence') :-
    G = [[a,b]],
    gch_reverse([G], [G]).

test('AC-GCH-036: gch_reverse empty sequence') :-
    gch_reverse([], []).

% --- gch_diff_counts/3 ---

test('AC-GCH-037: gch_diff_counts one pair zero differences') :-
    G = [[r,b],[b,r]],
    gch_diff_counts([G,G], b, [0]).

test('AC-GCH-038: gch_diff_counts one pair all cells differ') :-
    G1 = [[r,r],[r,r]], G2 = [[b,b],[b,b]],
    gch_diff_counts([G1,G2], b, [4]).

test('AC-GCH-039: gch_diff_counts two pairs with mixed differences') :-
    G1 = [[r,b]], G2 = [[b,b]], G3 = [[b,r]],
    gch_diff_counts([G1,G2,G3], b, [1,1]).

% --- gch_changes_mask/4 ---

test('AC-GCH-040: gch_changes_mask marks single changed cell') :-
    G1 = [[r,b],[b,b]],
    G2 = [[r,b],[b,r]],
    G3 = [[r,b],[b,r]],
    gch_changes_mask([G1,G2,G3], b, m, [[b,b],[b,m]]).

test('AC-GCH-041: gch_changes_mask with no changes yields all-bg mask') :-
    G = [[r,b],[b,r]],
    gch_changes_mask([G,G,G], b, m, [[b,b],[b,b]]).

test('AC-GCH-042: gch_changes_mask on single-grid input returns all-bg mask') :-
    G = [[r,b],[b,r]],
    gch_changes_mask([G], b, m, [[b,b],[b,b]]).

% --- combined/integration tests ---

test('AC-GCH-043: window + diff_counts tracks per-window change counts') :-
    G1=[[r,b]], G2=[[b,r]], G3=[[r,r]], G4=[[b,b]],
    gch_window([G1,G2,G3,G4], 2, Windows),
    findall(C, (member([Ga,Gb], Windows), gch_diff_counts([Ga,Gb], b, [C])), Counts),
    Counts = [2,1,2].

test('AC-GCH-044: cycle then dedup returns singleton') :-
    G = [[a,b],[c,d]],
    gch_cycle(G, 5, Seq),
    gch_dedup(Seq, [G]).

:- end_tests(gridchain).
