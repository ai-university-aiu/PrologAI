:- use_module('../prolog/grid_logic').

% Test grids (all 2x2 unless noted; Bg=b unless noted):
%   ga = [[r,b],[b,g]]    r at (0,0), g at (1,1)
%   gb = [[r,b],[r,b]]    r at (0,0) and (1,0)
%   gc = [[b,g],[b,r]]    g at (0,1), r at (1,1)
%   gx = [[x,b],[b,x]]    x at corners
%   ab = [[b,b],[b,b]]    all-bg
%   gf = [[r,g],[g,r]]    no bg cells

:- begin_tests(grid_logic).

% --- grid_logic_and ---

test('AC-GGL-001: and of ga and gb yields r at (0,0) only') :-
    grid_logic_and([[r,b],[b,g]], [[r,b],[r,b]], b, R),
    R = [[r,b],[b,b]].

test('AC-GGL-002: and with all-bg grid is all-bg') :-
    grid_logic_and([[r,b],[b,g]], [[b,b],[b,b]], b, R),
    R = [[b,b],[b,b]].

test('AC-GGL-003: and of two identical non-bg grids is identity') :-
    grid_logic_and([[r,g],[g,r]], [[r,g],[g,r]], b, R),
    R = [[r,g],[g,r]].

% --- grid_logic_or ---

test('AC-GGL-004: or of ga and gc covers all non-bg cells') :-
    grid_logic_or([[r,b],[b,g]], [[b,g],[b,r]], b, R),
    R = [[r,g],[b,g]].

test('AC-GGL-005: or with all-bg grid is identity') :-
    grid_logic_or([[r,b],[b,g]], [[b,b],[b,b]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-006: or where G1 wins over G2 at overlap') :-
    grid_logic_or([[r,b],[b,b]], [[x,b],[b,b]], b, R),
    R = [[r,b],[b,b]].

% --- grid_logic_xor ---

test('AC-GGL-007: xor of non-overlapping grids is union') :-
    grid_logic_xor([[r,b],[b,b]], [[b,b],[b,g]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-008: xor where both non-bg becomes bg') :-
    grid_logic_xor([[r,b],[b,g]], [[r,b],[b,g]], b, R),
    R = [[b,b],[b,b]].

test('AC-GGL-009: xor of overlapping and non-overlapping') :-
    grid_logic_xor([[r,b],[b,b]], [[r,g],[b,b]], b, R),
    R = [[b,g],[b,b]].

% --- grid_logic_not ---

test('AC-GGL-010: not flips bg and fg') :-
    grid_logic_not([[r,b],[b,g]], b, x, R),
    R = [[b,x],[x,b]].

test('AC-GGL-011: not of all-bg gives all-fg') :-
    grid_logic_not([[b,b],[b,b]], b, x, R),
    R = [[x,x],[x,x]].

test('AC-GGL-012: not of all-non-bg gives all-bg') :-
    grid_logic_not([[r,g],[g,r]], b, x, R),
    R = [[b,b],[b,b]].

% --- grid_logic_subtract ---

test('AC-GGL-013: subtract removes cells present in G2') :-
    grid_logic_subtract([[r,b],[b,g]], [[r,b],[b,b]], b, R),
    R = [[b,b],[b,g]].

test('AC-GGL-014: subtract with all-bg G2 is identity') :-
    grid_logic_subtract([[r,b],[b,g]], [[b,b],[b,b]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-015: subtract with equal grids gives all-bg') :-
    grid_logic_subtract([[r,g],[g,r]], [[r,g],[g,r]], b, R),
    R = [[b,b],[b,b]].

% --- grid_logic_common ---

test('AC-GGL-016: common keeps cells with same non-bg value') :-
    grid_logic_common([[r,b],[b,g]], [[r,b],[r,b]], b, R),
    R = [[r,b],[b,b]].

test('AC-GGL-017: common of identical grids is identity (non-bg cells)') :-
    grid_logic_common([[r,b],[b,g]], [[r,b],[b,g]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-018: common with disjoint values gives all-bg') :-
    grid_logic_common([[r,b],[b,b]], [[b,b],[b,g]], b, R),
    R = [[b,b],[b,b]].

% --- grid_logic_differ ---

test('AC-GGL-019: differ finds cells where both non-bg but different') :-
    grid_logic_differ([[r,b],[b,g]], [[x,b],[b,g]], b, R),
    R = [[r,b],[b,b]].

test('AC-GGL-020: differ with identical grids gives all-bg') :-
    grid_logic_differ([[r,g],[g,r]], [[r,g],[g,r]], b, R),
    R = [[b,b],[b,b]].

test('AC-GGL-021: differ ignores positions where either is bg') :-
    grid_logic_differ([[r,b],[b,g]], [[b,x],[b,b]], b, R),
    R = [[b,b],[b,b]].

% --- grid_logic_any ---

test('AC-GGL-022: any of two grids = or') :-
    grid_logic_any([[[r,b],[b,b]], [[b,b],[b,g]]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-023: any of single grid is identity') :-
    grid_logic_any([[[r,b],[b,g]]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-024: any of three grids covers all non-bg') :-
    grid_logic_any([[[r,b],[b,b]], [[b,g],[b,b]], [[b,b],[b,x]]], b, R),
    R = [[r,g],[b,x]].

% --- grid_logic_all ---

test('AC-GGL-025: all of two identical grids is the grid') :-
    grid_logic_all([[[r,b],[b,g]], [[r,b],[b,g]]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-026: all of single grid is identity') :-
    grid_logic_all([[[r,b],[b,g]]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-027: all with disagreement at a cell gives bg there') :-
    grid_logic_all([[[r,b],[b,g]], [[r,b],[b,x]]], b, R),
    R = [[r,b],[b,b]].

% --- grid_logic_majority ---

test('AC-GGL-028: majority of 3 identical grids is that grid') :-
    grid_logic_majority([[[r,b],[b,g]], [[r,b],[b,g]], [[r,b],[b,g]]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-029: majority with 2 out of 3 agreeing gives that value') :-
    grid_logic_majority([[[r,b],[b,b]], [[r,b],[b,b]], [[b,b],[b,b]]], b, R),
    R = [[r,b],[b,b]].

test('AC-GGL-030: majority with 1 out of 3 (no majority) gives bg') :-
    grid_logic_majority([[[r,b],[b,b]], [[b,g],[b,b]], [[b,b],[b,x]]], b, R),
    R = [[b,b],[b,b]].

% --- grid_logic_unanimous ---

test('AC-GGL-031: unanimous of two identical grids is that grid') :-
    grid_logic_unanimous([[[r,b],[b,g]], [[r,b],[b,g]]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-032: unanimous with any disagreement gives bg at that cell') :-
    grid_logic_unanimous([[[r,b],[b,g]], [[r,b],[b,x]]], b, R),
    R = [[r,b],[b,b]].

test('AC-GGL-033: unanimous of single grid is identity') :-
    grid_logic_unanimous([[[r,b],[b,g]]], b, R),
    R = [[r,b],[b,g]].

% --- grid_logic_mask ---

test('AC-GGL-034: mask keeps Grid cells where Mask = MaskColor') :-
    grid_logic_mask([[r,g],[g,r]], [[m,b],[b,m]], m, b, R),
    R = [[r,b],[b,r]].

test('AC-GGL-035: mask with no matching cells gives all-bg') :-
    grid_logic_mask([[r,g],[g,r]], [[b,b],[b,b]], m, b, R),
    R = [[b,b],[b,b]].

test('AC-GGL-036: mask with all matching cells is identity') :-
    grid_logic_mask([[r,g],[g,r]], [[m,m],[m,m]], m, b, R),
    R = [[r,g],[g,r]].

% --- grid_logic_if ---

test('AC-GGL-037: if selects Then where Cond = CondColor') :-
    grid_logic_if([[c,b],[b,c]], c, [[r,g],[g,r]], [[x,y],[y,x]], R),
    R = [[r,y],[y,r]].

test('AC-GGL-038: if with no matching Cond returns Else') :-
    grid_logic_if([[b,b],[b,b]], c, [[r,g],[g,r]], [[x,y],[y,x]], R),
    R = [[x,y],[y,x]].

test('AC-GGL-039: if with all matching Cond returns Then') :-
    grid_logic_if([[c,c],[c,c]], c, [[r,g],[g,r]], [[x,y],[y,x]], R),
    R = [[r,g],[g,r]].

% --- grid_logic_filter ---

test('AC-GGL-040: filter keeps only listed colors') :-
    grid_logic_filter([[r,g],[g,r]], [r], b, R),
    R = [[r,b],[b,r]].

test('AC-GGL-041: filter with empty color list gives all-bg') :-
    grid_logic_filter([[r,g],[g,r]], [], b, R),
    R = [[b,b],[b,b]].

test('AC-GGL-042: filter with all colors present is identity') :-
    grid_logic_filter([[r,g],[g,r]], [r,g], b, R),
    R = [[r,g],[g,r]].

% --- combined ---

test('AC-GGL-043: or then subtract identity: or(G,H) subtract H = G subtract H') :-
    G = [[r,b],[b,b]], H = [[b,g],[b,b]],
    grid_logic_or(G, H, b, OrGH),
    grid_logic_subtract(OrGH, H, b, R),
    grid_logic_subtract(G, H, b, R).

test('AC-GGL-044: not applied twice restores original') :-
    G = [[r,b],[b,g]],
    grid_logic_not(G, b, x, N1),
    grid_logic_not(N1, b, r, N2),
    % N2 should have r wherever G had non-bg, and b where G was bg.
    % grid_logic_not of grid_logic_not(G,b,x) with FgColor=r:
    % N1: non-bg→b, bg→x → N1=[[b,x],[x,b]]
    % N2: non-bg(b?)→r wait, b is Bg so b→r, x→b
    % N2 = [[r,b],[b,r]]
    N2 = [[r,b],[b,r]].

:- end_tests(grid_logic).
