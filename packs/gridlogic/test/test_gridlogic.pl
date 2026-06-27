:- use_module('../prolog/gridlogic').

% Test grids (all 2x2 unless noted; Bg=b unless noted):
%   ga = [[r,b],[b,g]]    r at (0,0), g at (1,1)
%   gb = [[r,b],[r,b]]    r at (0,0) and (1,0)
%   gc = [[b,g],[b,r]]    g at (0,1), r at (1,1)
%   gx = [[x,b],[b,x]]    x at corners
%   ab = [[b,b],[b,b]]    all-bg
%   gf = [[r,g],[g,r]]    no bg cells

:- begin_tests(gridlogic).

% --- ggl_and ---

test('AC-GGL-001: and of ga and gb yields r at (0,0) only') :-
    ggl_and([[r,b],[b,g]], [[r,b],[r,b]], b, R),
    R = [[r,b],[b,b]].

test('AC-GGL-002: and with all-bg grid is all-bg') :-
    ggl_and([[r,b],[b,g]], [[b,b],[b,b]], b, R),
    R = [[b,b],[b,b]].

test('AC-GGL-003: and of two identical non-bg grids is identity') :-
    ggl_and([[r,g],[g,r]], [[r,g],[g,r]], b, R),
    R = [[r,g],[g,r]].

% --- ggl_or ---

test('AC-GGL-004: or of ga and gc covers all non-bg cells') :-
    ggl_or([[r,b],[b,g]], [[b,g],[b,r]], b, R),
    R = [[r,g],[b,g]].

test('AC-GGL-005: or with all-bg grid is identity') :-
    ggl_or([[r,b],[b,g]], [[b,b],[b,b]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-006: or where G1 wins over G2 at overlap') :-
    ggl_or([[r,b],[b,b]], [[x,b],[b,b]], b, R),
    R = [[r,b],[b,b]].

% --- ggl_xor ---

test('AC-GGL-007: xor of non-overlapping grids is union') :-
    ggl_xor([[r,b],[b,b]], [[b,b],[b,g]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-008: xor where both non-bg becomes bg') :-
    ggl_xor([[r,b],[b,g]], [[r,b],[b,g]], b, R),
    R = [[b,b],[b,b]].

test('AC-GGL-009: xor of overlapping and non-overlapping') :-
    ggl_xor([[r,b],[b,b]], [[r,g],[b,b]], b, R),
    R = [[b,g],[b,b]].

% --- ggl_not ---

test('AC-GGL-010: not flips bg and fg') :-
    ggl_not([[r,b],[b,g]], b, x, R),
    R = [[b,x],[x,b]].

test('AC-GGL-011: not of all-bg gives all-fg') :-
    ggl_not([[b,b],[b,b]], b, x, R),
    R = [[x,x],[x,x]].

test('AC-GGL-012: not of all-non-bg gives all-bg') :-
    ggl_not([[r,g],[g,r]], b, x, R),
    R = [[b,b],[b,b]].

% --- ggl_subtract ---

test('AC-GGL-013: subtract removes cells present in G2') :-
    ggl_subtract([[r,b],[b,g]], [[r,b],[b,b]], b, R),
    R = [[b,b],[b,g]].

test('AC-GGL-014: subtract with all-bg G2 is identity') :-
    ggl_subtract([[r,b],[b,g]], [[b,b],[b,b]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-015: subtract with equal grids gives all-bg') :-
    ggl_subtract([[r,g],[g,r]], [[r,g],[g,r]], b, R),
    R = [[b,b],[b,b]].

% --- ggl_common ---

test('AC-GGL-016: common keeps cells with same non-bg value') :-
    ggl_common([[r,b],[b,g]], [[r,b],[r,b]], b, R),
    R = [[r,b],[b,b]].

test('AC-GGL-017: common of identical grids is identity (non-bg cells)') :-
    ggl_common([[r,b],[b,g]], [[r,b],[b,g]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-018: common with disjoint values gives all-bg') :-
    ggl_common([[r,b],[b,b]], [[b,b],[b,g]], b, R),
    R = [[b,b],[b,b]].

% --- ggl_differ ---

test('AC-GGL-019: differ finds cells where both non-bg but different') :-
    ggl_differ([[r,b],[b,g]], [[x,b],[b,g]], b, R),
    R = [[r,b],[b,b]].

test('AC-GGL-020: differ with identical grids gives all-bg') :-
    ggl_differ([[r,g],[g,r]], [[r,g],[g,r]], b, R),
    R = [[b,b],[b,b]].

test('AC-GGL-021: differ ignores positions where either is bg') :-
    ggl_differ([[r,b],[b,g]], [[b,x],[b,b]], b, R),
    R = [[b,b],[b,b]].

% --- ggl_any ---

test('AC-GGL-022: any of two grids = or') :-
    ggl_any([[[r,b],[b,b]], [[b,b],[b,g]]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-023: any of single grid is identity') :-
    ggl_any([[[r,b],[b,g]]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-024: any of three grids covers all non-bg') :-
    ggl_any([[[r,b],[b,b]], [[b,g],[b,b]], [[b,b],[b,x]]], b, R),
    R = [[r,g],[b,x]].

% --- ggl_all ---

test('AC-GGL-025: all of two identical grids is the grid') :-
    ggl_all([[[r,b],[b,g]], [[r,b],[b,g]]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-026: all of single grid is identity') :-
    ggl_all([[[r,b],[b,g]]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-027: all with disagreement at a cell gives bg there') :-
    ggl_all([[[r,b],[b,g]], [[r,b],[b,x]]], b, R),
    R = [[r,b],[b,b]].

% --- ggl_majority ---

test('AC-GGL-028: majority of 3 identical grids is that grid') :-
    ggl_majority([[[r,b],[b,g]], [[r,b],[b,g]], [[r,b],[b,g]]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-029: majority with 2 out of 3 agreeing gives that value') :-
    ggl_majority([[[r,b],[b,b]], [[r,b],[b,b]], [[b,b],[b,b]]], b, R),
    R = [[r,b],[b,b]].

test('AC-GGL-030: majority with 1 out of 3 (no majority) gives bg') :-
    ggl_majority([[[r,b],[b,b]], [[b,g],[b,b]], [[b,b],[b,x]]], b, R),
    R = [[b,b],[b,b]].

% --- ggl_unanimous ---

test('AC-GGL-031: unanimous of two identical grids is that grid') :-
    ggl_unanimous([[[r,b],[b,g]], [[r,b],[b,g]]], b, R),
    R = [[r,b],[b,g]].

test('AC-GGL-032: unanimous with any disagreement gives bg at that cell') :-
    ggl_unanimous([[[r,b],[b,g]], [[r,b],[b,x]]], b, R),
    R = [[r,b],[b,b]].

test('AC-GGL-033: unanimous of single grid is identity') :-
    ggl_unanimous([[[r,b],[b,g]]], b, R),
    R = [[r,b],[b,g]].

% --- ggl_mask ---

test('AC-GGL-034: mask keeps Grid cells where Mask = MaskColor') :-
    ggl_mask([[r,g],[g,r]], [[m,b],[b,m]], m, b, R),
    R = [[r,b],[b,r]].

test('AC-GGL-035: mask with no matching cells gives all-bg') :-
    ggl_mask([[r,g],[g,r]], [[b,b],[b,b]], m, b, R),
    R = [[b,b],[b,b]].

test('AC-GGL-036: mask with all matching cells is identity') :-
    ggl_mask([[r,g],[g,r]], [[m,m],[m,m]], m, b, R),
    R = [[r,g],[g,r]].

% --- ggl_if ---

test('AC-GGL-037: if selects Then where Cond = CondColor') :-
    ggl_if([[c,b],[b,c]], c, [[r,g],[g,r]], [[x,y],[y,x]], R),
    R = [[r,y],[y,r]].

test('AC-GGL-038: if with no matching Cond returns Else') :-
    ggl_if([[b,b],[b,b]], c, [[r,g],[g,r]], [[x,y],[y,x]], R),
    R = [[x,y],[y,x]].

test('AC-GGL-039: if with all matching Cond returns Then') :-
    ggl_if([[c,c],[c,c]], c, [[r,g],[g,r]], [[x,y],[y,x]], R),
    R = [[r,g],[g,r]].

% --- ggl_filter ---

test('AC-GGL-040: filter keeps only listed colors') :-
    ggl_filter([[r,g],[g,r]], [r], b, R),
    R = [[r,b],[b,r]].

test('AC-GGL-041: filter with empty color list gives all-bg') :-
    ggl_filter([[r,g],[g,r]], [], b, R),
    R = [[b,b],[b,b]].

test('AC-GGL-042: filter with all colors present is identity') :-
    ggl_filter([[r,g],[g,r]], [r,g], b, R),
    R = [[r,g],[g,r]].

% --- combined ---

test('AC-GGL-043: or then subtract identity: or(G,H) subtract H = G subtract H') :-
    G = [[r,b],[b,b]], H = [[b,g],[b,b]],
    ggl_or(G, H, b, OrGH),
    ggl_subtract(OrGH, H, b, R),
    ggl_subtract(G, H, b, R).

test('AC-GGL-044: not applied twice restores original') :-
    G = [[r,b],[b,g]],
    ggl_not(G, b, x, N1),
    ggl_not(N1, b, r, N2),
    % N2 should have r wherever G had non-bg, and b where G was bg.
    % ggl_not of ggl_not(G,b,x) with FgColor=r:
    % N1: non-bg→b, bg→x → N1=[[b,x],[x,b]]
    % N2: non-bg(b?)→r wait, b is Bg so b→r, x→b
    % N2 = [[r,b],[b,r]]
    N2 = [[r,b],[b,r]].

:- end_tests(gridlogic).
