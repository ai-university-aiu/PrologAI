:- module(periodfix, [
    % ppf_list_period/2: smallest exact period of a list with no violations.
    ppf_list_period/2,
    % ppf_majority/2: most common element in a non-empty list.
    ppf_majority/2,
    % ppf_tile_from_list/3: majority-vote tile of length P from a list.
    ppf_tile_from_list/3,
    % ppf_violations_list/4: find indices where list disagrees with periodic tile.
    ppf_violations_list/4,
    % ppf_repair_list/4: repair list by replacing violations with tile values.
    ppf_repair_list/4,
    % ppf_best_period_list/3: period P (1..N) that minimizes violation count.
    ppf_best_period_list/3,
    % ppf_tile_2d/4: majority-vote 2D tile (PH rows x PW cols) for a grid.
    ppf_tile_2d/4,
    % ppf_violations_2d/5: find (R,C,Actual,Expected) violations in a grid.
    ppf_violations_2d/5,
    % ppf_repair_grid/5: repair grid by replacing 2D violations with tile values.
    ppf_repair_grid/5,
    % ppf_best_periods/3: (PH, PW) pair that minimizes total 2D violations.
    ppf_best_periods/3,
    % ppf_single_violation_list/4: true if list has exactly one mismatch with period P.
    ppf_single_violation_list/4,
    % ppf_repair_single_list/4: repair the unique mismatch in list with period P.
    ppf_repair_single_list/4,
    % ppf_single_violation_2d/5: true if grid has exactly one 2D mismatch.
    ppf_single_violation_2d/5,
    % ppf_repair_single_grid/5: repair the unique 2D mismatch in grid.
    ppf_repair_single_grid/5
]).
% periodfix.pl - Layer 253: Periodic Pattern Repair (ppf_* prefix).
% Fourteen predicates for detecting majority-vote tiles, finding violations
% in periodic patterns, and repairing exactly one corrupted cell.
% A list has period P if List[i] = List[i mod P] for all i.
% A majority-vote tile is built by taking the modal value at each phase.
% A violation is a position where the value differs from the tile at that phase.
% Raw grid format: list of rows, each a list of atoms or integers.
% No cross-pack dependencies.
:- use_module(library(lists), [nth0/3, member/2]).
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- PRIVATE HELPERS ---

% ppf_list_len_/2: length of a list.
ppf_list_len_(List, N) :-
%   Delegate to built-in length.
    length(List, N).

% ppf_nth_/3: 0-based element access.
ppf_nth_(I, List, V) :-
%   nth0/3 is the standard 0-based accessor.
    nth0(I, List, V).

% ppf_phases_/3: split List into P sublists by phase (i mod P).
ppf_phases_(List, P, Phases) :-
%   Build one sublist per phase index 0..P-1.
    ppf_list_len_(List, N),
%   Last index is N-1.
    N1 is N - 1,
%   For each phase p, collect all elements at indices congruent to p mod P.
    findall(Phase,
        (between(0, N1, P0),
         P0 < P,
         findall(V, (between(0, N1, I), I mod P =:= P0,
                     ppf_nth_(I, List, V)), Phase)),
        Phases).

% ppf_mode_/2: most frequent element in a non-empty list.
ppf_mode_([H|T], Mode) :-
%   Sort to group equal elements.
    msort([H|T], Sorted),
%   Scan runs to find the maximum-count element.
    ppf_run_mode_(Sorted, H, 1, H, 1, Mode).

% ppf_run_mode_/6: scan sorted list, tracking current run and best run.
ppf_run_mode_([], Cur, CN, Best, BN, Mode) :-
%   End of list: emit whichever run was larger.
    (CN > BN -> Mode = Cur ; Mode = Best).
ppf_run_mode_([H|T], H, CN, Best, BN, Mode) :- !,
%   Continuing current run; cut removes ambiguity with the next clause.
    CN1 is CN + 1,
    ppf_run_mode_(T, H, CN1, Best, BN, Mode).
ppf_run_mode_([H|T], Cur, CN, Best, BN, Mode) :-
%   New element; start new run. Update best if current beat it.
    H \= Cur,
    (CN > BN -> NB = Cur, NBN = CN ; NB = Best, NBN = BN),
    ppf_run_mode_(T, H, 1, NB, NBN, Mode).

% ppf_list_matches_period_/2: true if List[i] = List[i mod P] for all i.
ppf_list_matches_period_(List, P) :-
%   Compute length.
    ppf_list_len_(List, N), N1 is N - 1,
%   Fail if any index has a mismatch.
    \+ (between(0, N1, I), I2 is I mod P,
        ppf_nth_(I, List, V1), ppf_nth_(I2, List, V2),
        V1 \= V2).

% --- PUBLIC PREDICATES ---

% ppf_list_period/2: smallest exact period P of List with no violations.
ppf_list_period(List, P) :-
%   Period must be at least 1 and at most the list length.
    ppf_list_len_(List, N), N > 0,
    between(1, N, P),
%   Check every element matches its modular position.
    ppf_list_matches_period_(List, P), !.

% ppf_majority/2: most common element in a non-empty list.
ppf_majority([H|T], Mode) :-
%   Delegate to the internal mode-finder.
    ppf_mode_([H|T], Mode).

% ppf_tile_from_list/3: majority-vote tile of length P from List.
ppf_tile_from_list(List, P, Tile) :-
%   Split into P phase-groups.
    ppf_phases_(List, P, Phases),
%   Compute mode of each phase-group.
    maplist([Phase, Mode]>>(ppf_mode_(Phase, Mode)), Phases, Tile).

% ppf_violations_list/4: indices where List[i] differs from Tile[i mod P].
% Returns list of viol(Index, Actual, Expected) terms.
ppf_violations_list(List, P, Tile, Violations) :-
%   Compute length.
    ppf_list_len_(List, N), N1 is N - 1,
%   Collect mismatches.
    findall(viol(I, Actual, Exp),
        (between(0, N1, I),
         ppf_nth_(I, List, Actual),
         Ph is I mod P,
         ppf_nth_(Ph, Tile, Exp),
         Actual \= Exp),
        Violations).

% ppf_repair_list/4: repair List by replacing each violation with Tile value.
ppf_repair_list(List, P, Tile, Repaired) :-
%   Compute length.
    ppf_list_len_(List, N), N1 is N - 1,
%   Build repaired list: for each index, use Tile if violation else keep original.
    findall(V,
        (between(0, N1, I),
         ppf_nth_(I, List, Orig),
         Ph is I mod P, ppf_nth_(Ph, Tile, Exp),
         (Orig = Exp -> V = Orig ; V = Exp)),
        Repaired).

% ppf_best_period_list/3: find period P minimizing violation count.
% Searches periods 1..max(1, N//2) to avoid the trivial P=N (zero-violation) winner.
% Returns the smallest P among those tied at minimum violation count.
ppf_best_period_list(List, P, NViol) :-
%   Compute length; cap search at half-length so trivial P=N does not dominate.
    ppf_list_len_(List, N), N > 0,
    Pmax is max(1, N // 2),
%   Enumerate (ViolCount, Period) pairs up to Pmax.
    findall(NV-Pd,
        (between(1, Pmax, Pd),
         ppf_tile_from_list(List, Pd, Tile),
         ppf_violations_list(List, Pd, Tile, Viols),
         length(Viols, NV)),
        Pairs),
%   Sort ascending; smallest NV (then smallest Pd) is first.
    msort(Pairs, [NViol-P|_]).

% ppf_tile_2d/4: majority-vote 2D tile (PH rows x PW cols) for Grid.
% Tile is a PH x PW grid where Tile[r][c] is mode of Grid[r mod PH][c mod PW].
ppf_tile_2d(Grid, PH, PW, Tile) :-
%   Grid dimensions.
    length(Grid, H), H > 0, Grid = [FR|_], length(FR, W),
%   Build tile row by row.
    H1 is H - 1, W1 is W - 1,
    PH1 is PH - 1, PW1 is PW - 1,
    findall(TileRow,
        (between(0, PH1, TR),
         findall(Mode,
             (between(0, PW1, TC),
              findall(V,
                  (between(0, H1, R), R mod PH =:= TR,
                   between(0, W1, C), C mod PW =:= TC,
                   nth0(R, Grid, Row), nth0(C, Row, V)),
                  Vals),
              ppf_mode_(Vals, Mode)),
             TileRow)),
        Tile).

% ppf_violations_2d/4: find all (R,C,Actual,Expected) mismatches in Grid.
ppf_violations_2d(Grid, Tile, PH, PW, Violations) :-
%   Grid dimensions.
    length(Grid, H), H > 0, Grid = [FR|_], length(FR, W),
    H1 is H - 1, W1 is W - 1,
%   Collect (R,C) positions where Grid value differs from Tile value.
    findall(viol(R,C,Actual,Exp),
        (between(0, H1, R), between(0, W1, C),
         nth0(R, Grid, Row), nth0(C, Row, Actual),
         TR is R mod PH, TC is C mod PW,
         nth0(TR, Tile, TileRow), nth0(TC, TileRow, Exp),
         Actual \= Exp),
        Violations).

% ppf_repair_grid/4: repair Grid by replacing 2D violations with Tile values.
ppf_repair_grid(Grid, Tile, PH, PW, Repaired) :-
%   Grid dimensions.
    length(Grid, H), H > 0, Grid = [FR|_], length(FR, W),
    H1 is H - 1, W1 is W - 1,
%   Build repaired grid row by row, cell by cell.
    findall(Row,
        (between(0, H1, R),
         findall(V,
             (between(0, W1, C),
              nth0(R, Grid, GRow), nth0(C, GRow, Orig),
              TR is R mod PH, TC is C mod PW,
              nth0(TR, Tile, TileRow), nth0(TC, TileRow, Exp),
              (Orig = Exp -> V = Orig ; V = Exp)),
             Row)),
        Repaired).

% ppf_best_periods/3: (PH, PW) minimizing total 2D violation count.
% Searches PH in 1..max(1,H//2) and PW in 1..max(1,W//2) to avoid the
% trivial (H,W) period that always gives zero violations.
% Returns smallest PH among minima, then smallest PW.
ppf_best_periods(Grid, PH, PW) :-
%   Grid dimensions; cap search at half each dimension.
    length(Grid, H), H > 0, Grid = [FR|_], length(FR, W),
    PHmax is max(1, H // 2),
    PWmax is max(1, W // 2),
%   Enumerate candidate period pairs within capped range.
    findall(NV-PH0-PW0,
        (between(1, PHmax, PH0), between(1, PWmax, PW0),
         ppf_tile_2d(Grid, PH0, PW0, Tile),
         ppf_violations_2d(Grid, Tile, PH0, PW0, Viols),
         length(Viols, NV)),
        Triples),
%   Sort by (NV, PH, PW); first entry is best.
    msort(Triples, [_-PH-PW|_]).

% ppf_single_violation_list/4: true if List has exactly one mismatch with period P.
% Returns the violation as viol(Index, Actual, Expected).
ppf_single_violation_list(List, P, Tile, Violation) :-
%   Find violations.
    ppf_violations_list(List, P, Tile, [Violation]).

% ppf_repair_single_list/4: repair the unique mismatch in List with period P.
ppf_repair_single_list(List, P, Tile, Repaired) :-
%   Confirm exactly one violation.
    ppf_single_violation_list(List, P, Tile, _),
%   Delegate to the general repair predicate.
    ppf_repair_list(List, P, Tile, Repaired).

% ppf_single_violation_2d/5: true if Grid has exactly one 2D mismatch.
% Returns the violation as viol(R, C, Actual, Expected).
ppf_single_violation_2d(Grid, Tile, PH, PW, Violation) :-
%   Find 2D violations.
    ppf_violations_2d(Grid, Tile, PH, PW, [Violation]).

% ppf_repair_single_grid/4: repair the unique 2D mismatch in Grid.
ppf_repair_single_grid(Grid, Tile, PH, PW, Repaired) :-
%   Confirm exactly one 2D violation.
    ppf_single_violation_2d(Grid, Tile, PH, PW, _),
%   Delegate to the general repair predicate.
    ppf_repair_grid(Grid, Tile, PH, PW, Repaired).
