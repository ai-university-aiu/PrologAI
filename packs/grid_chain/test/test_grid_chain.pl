:- use_module('../prolog/grid_chain').

:- begin_tests(grid_chain).

% --- grid_chain_pairs/2 ---

test('AC-GCH-001: grid_chain_pairs on three-element sequence yields two consecutive pairs') :-
    G1 = [[r,b],[b,r]], G2 = [[b,g],[g,b]], G3 = [[r,r],[b,b]],
    grid_chain_pairs([G1,G2,G3], Pairs),
    Pairs = [[G1,G2],[G2,G3]].

test('AC-GCH-002: grid_chain_pairs on two-element sequence yields one pair') :-
    G1 = [[a,b]], G2 = [[c,d]],
    grid_chain_pairs([G1,G2], [[G1,G2]]).

test('AC-GCH-003: grid_chain_pairs on single-element sequence yields empty list') :-
    grid_chain_pairs([[[r,b]]], []).

% --- grid_chain_window/3 ---

test('AC-GCH-004: grid_chain_window of width 2 on four-element sequence yields three windows') :-
    G1=[[r]], G2=[[g]], G3=[[b]], G4=[[y]],
    grid_chain_window([G1,G2,G3,G4], 2, W),
    W = [[G1,G2],[G2,G3],[G3,G4]].

test('AC-GCH-005: grid_chain_window of width 3 on three-element sequence yields one window') :-
    G1=[[a]], G2=[[b]], G3=[[c]],
    grid_chain_window([G1,G2,G3], 3, [[G1,G2,G3]]).

test('AC-GCH-006: grid_chain_window width exceeds sequence length yields empty list') :-
    grid_chain_window([[[r]],[[g]]], 5, []).

% --- grid_chain_zip/3 ---

test('AC-GCH-007: grid_chain_zip of two equal-length sequences') :-
    G1=[[r,b]], G2=[[b,g]], G3=[[g,r]], G4=[[y,y]],
    grid_chain_zip([G1,G2], [G3,G4], [[G1,G3],[G2,G4]]).

test('AC-GCH-008: grid_chain_zip truncates to shorter sequence') :-
    G1=[[a]], G2=[[b]], G3=[[c]],
    grid_chain_zip([G1,G2,G3], [G2], [[G1,G2]]).

test('AC-GCH-009: grid_chain_zip with empty first list yields empty') :-
    grid_chain_zip([], [[[r]]], []).

% --- grid_chain_take/3 ---

test('AC-GCH-010: grid_chain_take first 2 of 3 grids') :-
    G1=[[r]], G2=[[g]], G3=[[b]],
    grid_chain_take([G1,G2,G3], 2, [G1,G2]).

test('AC-GCH-011: grid_chain_take all grids when N equals length') :-
    G1=[[a]], G2=[[b]],
    grid_chain_take([G1,G2], 2, [G1,G2]).

test('AC-GCH-012: grid_chain_take clamps when N exceeds length') :-
    G1=[[r]], G2=[[g]],
    grid_chain_take([G1,G2], 10, [G1,G2]).

% --- grid_chain_drop/3 ---

test('AC-GCH-013: grid_chain_drop first 1 of 3 grids') :-
    G1=[[r]], G2=[[g]], G3=[[b]],
    grid_chain_drop([G1,G2,G3], 1, [G2,G3]).

test('AC-GCH-014: grid_chain_drop all grids when N equals length') :-
    G1=[[a]], G2=[[b]],
    grid_chain_drop([G1,G2], 2, []).

test('AC-GCH-015: grid_chain_drop clamps when N exceeds length') :-
    G1=[[r]], G2=[[g]],
    grid_chain_drop([G1,G2], 10, []).

% --- grid_chain_nth/3 ---

test('AC-GCH-016: grid_chain_nth index 0 returns first grid') :-
    G1=[[r,b]], G2=[[b,r]],
    grid_chain_nth([G1,G2], 0, G1).

test('AC-GCH-017: grid_chain_nth index 1 returns second grid') :-
    G1=[[a]], G2=[[b]], G3=[[c]],
    grid_chain_nth([G1,G2,G3], 1, G2).

test('AC-GCH-018: grid_chain_nth index 2 returns third grid') :-
    G1=[[r]], G2=[[g]], G3=[[b]],
    grid_chain_nth([G1,G2,G3], 2, G3).

% --- grid_chain_all_same/1 ---

test('AC-GCH-019: grid_chain_all_same succeeds for three identical grids') :-
    G = [[r,b],[b,r]],
    grid_chain_all_same([G,G,G]).

test('AC-GCH-020: grid_chain_all_same succeeds for single grid') :-
    grid_chain_all_same([[[a,b]]]).

test('AC-GCH-021: grid_chain_all_same fails when grids differ', [fail]) :-
    G1 = [[r]], G2 = [[g]],
    grid_chain_all_same([G1,G2]).

% --- grid_chain_dedup/2 ---

test('AC-GCH-022: grid_chain_dedup removes consecutive duplicate') :-
    G1=[[r]], G2=[[g]],
    grid_chain_dedup([G1,G1,G2], [G1,G2]).

test('AC-GCH-023: grid_chain_dedup removes non-consecutive duplicate preserving order') :-
    G1=[[r]], G2=[[g]], G3=[[b]],
    grid_chain_dedup([G1,G2,G1,G3], [G1,G2,G3]).

test('AC-GCH-024: grid_chain_dedup on all-same list returns singleton') :-
    G = [[r,b]],
    grid_chain_dedup([G,G,G], [G]).

% --- grid_chain_cycle/3 ---

test('AC-GCH-025: grid_chain_cycle repeats grid 3 times') :-
    G = [[r,b],[b,r]],
    grid_chain_cycle(G, 3, [G,G,G]).

test('AC-GCH-026: grid_chain_cycle of 1 yields singleton list') :-
    G = [[a,b]],
    grid_chain_cycle(G, 1, [G]).

test('AC-GCH-027: grid_chain_cycle of 0 yields empty list') :-
    grid_chain_cycle([[r]], 0, []).

% --- grid_chain_interleave/3 ---

test('AC-GCH-028: grid_chain_interleave two equal-length sequences') :-
    G1=[[r]], G2=[[g]], G3=[[b]], G4=[[y]],
    grid_chain_interleave([G1,G2], [G3,G4], [G1,G3,G2,G4]).

test('AC-GCH-029: grid_chain_interleave truncates to shorter sequence') :-
    G1=[[a]], G2=[[b]], G3=[[c]],
    grid_chain_interleave([G1,G2,G3], [G2], [G1,G2]).

test('AC-GCH-030: grid_chain_interleave with empty first list yields empty') :-
    grid_chain_interleave([], [[[r]]], []).

% --- grid_chain_split_at/4 ---

test('AC-GCH-031: grid_chain_split_at index 2 of 4-element sequence') :-
    G1=[[r]], G2=[[g]], G3=[[b]], G4=[[y]],
    grid_chain_split_at([G1,G2,G3,G4], 2, [G1,G2], [G3,G4]).

test('AC-GCH-032: grid_chain_split_at index 0 yields empty before list') :-
    G1=[[a]], G2=[[b]],
    grid_chain_split_at([G1,G2], 0, [], [G1,G2]).

test('AC-GCH-033: grid_chain_split_at at full length yields empty after list') :-
    G1=[[r]], G2=[[g]],
    grid_chain_split_at([G1,G2], 2, [G1,G2], []).

% --- grid_chain_reverse/2 ---

test('AC-GCH-034: grid_chain_reverse three-element sequence') :-
    G1=[[r]], G2=[[g]], G3=[[b]],
    grid_chain_reverse([G1,G2,G3], [G3,G2,G1]).

test('AC-GCH-035: grid_chain_reverse single-element sequence') :-
    G = [[a,b]],
    grid_chain_reverse([G], [G]).

test('AC-GCH-036: grid_chain_reverse empty sequence') :-
    grid_chain_reverse([], []).

% --- grid_chain_diff_counts/3 ---

test('AC-GCH-037: grid_chain_diff_counts one pair zero differences') :-
    G = [[r,b],[b,r]],
    grid_chain_diff_counts([G,G], b, [0]).

test('AC-GCH-038: grid_chain_diff_counts one pair all cells differ') :-
    G1 = [[r,r],[r,r]], G2 = [[b,b],[b,b]],
    grid_chain_diff_counts([G1,G2], b, [4]).

test('AC-GCH-039: grid_chain_diff_counts two pairs with mixed differences') :-
    G1 = [[r,b]], G2 = [[b,b]], G3 = [[b,r]],
    grid_chain_diff_counts([G1,G2,G3], b, [1,1]).

% --- grid_chain_changes_mask/4 ---

test('AC-GCH-040: grid_chain_changes_mask marks single changed cell') :-
    G1 = [[r,b],[b,b]],
    G2 = [[r,b],[b,r]],
    G3 = [[r,b],[b,r]],
    grid_chain_changes_mask([G1,G2,G3], b, m, [[b,b],[b,m]]).

test('AC-GCH-041: grid_chain_changes_mask with no changes yields all-bg mask') :-
    G = [[r,b],[b,r]],
    grid_chain_changes_mask([G,G,G], b, m, [[b,b],[b,b]]).

test('AC-GCH-042: grid_chain_changes_mask on single-grid input returns all-bg mask') :-
    G = [[r,b],[b,r]],
    grid_chain_changes_mask([G], b, m, [[b,b],[b,b]]).

% --- combined/integration tests ---

test('AC-GCH-043: window + difference_counts tracks per-window change counts') :-
    G1=[[r,b]], G2=[[b,r]], G3=[[r,r]], G4=[[b,b]],
    grid_chain_window([G1,G2,G3,G4], 2, Windows),
    findall(C, (member([Ga,Gb], Windows), grid_chain_diff_counts([Ga,Gb], b, [C])), Counts),
    Counts = [2,1,2].

test('AC-GCH-044: cycle then dedup returns singleton') :-
    G = [[a,b],[c,d]],
    grid_chain_cycle(G, 5, Seq),
    grid_chain_dedup(Seq, [G]).

:- end_tests(grid_chain).
