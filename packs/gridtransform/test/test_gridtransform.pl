% Test suite for gridtransform (gtr_*, Layer 245).
:- use_module('../prolog/gridtransform.pl').

:- begin_tests(gridtransform).

% AC-GTR-001: gtr_color_map: identity map (no changes).
test('AC-GTR-001: color_map identity') :-
    Grid = [[r,b],[g,r]],
    gtr_color_map(Grid, Grid, Map),
    member(cm(r,r), Map),
    member(cm(b,b), Map),
    member(cm(g,g), Map).

% AC-GTR-002: gtr_color_map: simple swap.
test('AC-GTR-002: color_map swap') :-
    A = [[r,b],[r,b]],
    B = [[b,r],[b,r]],
    gtr_color_map(A, B, Map),
    member(cm(r,b), Map),
    member(cm(b,r), Map),
    length(Map, 2).

% AC-GTR-003: gtr_color_map: fails when inconsistent.
test('AC-GTR-003: color_map inconsistent fails', [fail]) :-
    % r maps to both b and g at different positions
    A = [[r,r],[b,b]],
    B = [[b,g],[b,b]],
    gtr_color_map(A, B, _).

% AC-GTR-004: gtr_apply_color_map: applies swap map.
test('AC-GTR-004: apply_color_map swap') :-
    Grid = [[r,b],[r,r]],
    Map = [cm(b,g), cm(r,b)],
    gtr_apply_color_map(Grid, Map, Result),
    Result = [[b,g],[b,b]].

% AC-GTR-005: gtr_apply_color_map: unmapped colors pass through.
test('AC-GTR-005: apply_color_map passthrough') :-
    Grid = [[r,x],[x,r]],
    Map = [cm(r,b)],
    gtr_apply_color_map(Grid, Map, Result),
    Result = [[b,x],[x,b]].

% AC-GTR-006: gtr_diff_cells: two identical grids have no differences.
test('AC-GTR-006: diff_cells identical') :-
    Grid = [[r,b],[g,r]],
    gtr_diff_cells(Grid, Grid, []).

% AC-GTR-007: gtr_diff_cells: one cell differs.
test('AC-GTR-007: diff_cells one cell') :-
    A = [[r,b],[g,r]],
    B = [[r,b],[x,r]],
    gtr_diff_cells(A, B, Cells),
    Cells = [r(1,0)].

% AC-GTR-008: gtr_diff_cells: all cells differ.
test('AC-GTR-008: diff_cells all differ') :-
    A = [[r,r],[r,r]],
    B = [[b,b],[b,b]],
    gtr_diff_cells(A, B, Cells),
    length(Cells, 4).

% AC-GTR-009: gtr_diff_count: zero for identical grids.
test('AC-GTR-009: diff_count zero') :-
    gtr_diff_count([[r,b],[b,r]], [[r,b],[b,r]], 0).

% AC-GTR-010: gtr_diff_count: correct count for partial difference.
test('AC-GTR-010: diff_count partial') :-
    A = [[r,b],[g,r]],
    B = [[r,b],[g,b]],
    gtr_diff_count(A, B, 1).

% AC-GTR-011: gtr_same_cells: all same for identical grids.
test('AC-GTR-011: same_cells identical') :-
    Grid = [[r,b],[b,r]],
    gtr_same_cells(Grid, Grid, Cells),
    length(Cells, 4).

% AC-GTR-012: gtr_same_cells: no same cells when all differ.
test('AC-GTR-012: same_cells none') :-
    A = [[r,r],[r,r]],
    B = [[b,b],[b,b]],
    gtr_same_cells(A, B, []).

% AC-GTR-013: gtr_changed_colors: empty for identical grids.
test('AC-GTR-013: changed_colors identical') :-
    Grid = [[r,b],[b,r]],
    gtr_changed_colors(Grid, Grid, []).

% AC-GTR-014: gtr_changed_colors: records old and new color.
test('AC-GTR-014: changed_colors records change') :-
    A = [[r,b],[b,r]],
    B = [[r,b],[g,r]],
    gtr_changed_colors(A, B, Changes),
    Changes = [chg(1,0,b,g)].

% AC-GTR-015: gtr_invert_map: inverts a swap map.
test('AC-GTR-015: invert_map swap') :-
    Map = [cm(r,b), cm(b,r)],
    gtr_invert_map(Map, InvMap),
    member(cm(b,r), InvMap),
    member(cm(r,b), InvMap).

% AC-GTR-016: gtr_invert_map: fails for non-injective map.
test('AC-GTR-016: invert_map non-injective fails', [fail]) :-
    Map = [cm(r,b), cm(g,b)],
    gtr_invert_map(Map, _).

% AC-GTR-017: gtr_compose_maps: compose two maps.
test('AC-GTR-017: compose_maps basic') :-
    MapAB = [cm(r,b), cm(b,g)],
    MapBC = [cm(b,x), cm(g,y)],
    gtr_compose_maps(MapAB, MapBC, MapAC),
    member(cm(r,x), MapAC),
    member(cm(b,y), MapAC).

% AC-GTR-018: gtr_compose_maps: only matched colors appear.
test('AC-GTR-018: compose_maps partial') :-
    MapAB = [cm(r,b), cm(g,z)],
    MapBC = [cm(b,x)],
    gtr_compose_maps(MapAB, MapBC, MapAC),
    MapAC = [cm(r,x)].

% AC-GTR-019: gtr_is_identity_map: empty map is identity.
test('AC-GTR-019: is_identity_map empty') :-
    gtr_is_identity_map([]).

% AC-GTR-020: gtr_is_identity_map: all same entries is identity.
test('AC-GTR-020: is_identity_map same') :-
    gtr_is_identity_map([cm(r,r), cm(b,b)]).

% AC-GTR-021: gtr_is_identity_map: fails for non-identity.
test('AC-GTR-021: is_identity_map fails', [fail]) :-
    gtr_is_identity_map([cm(r,b)]).

% AC-GTR-022: gtr_apply_changes: applies changes to grid.
test('AC-GTR-022: apply_changes basic') :-
    Grid = [[r,b],[b,r]],
    Changes = [chg(0,0,r,g)],
    gtr_apply_changes(Grid, Changes, Result),
    Result = [[g,b],[b,r]].

% AC-GTR-023: gtr_apply_changes: empty changes returns original.
test('AC-GTR-023: apply_changes empty') :-
    Grid = [[r,b],[b,r]],
    gtr_apply_changes(Grid, [], Grid).

% AC-GTR-024: gtr_delta_grid: identical grids produce all-Bg delta.
test('AC-GTR-024: delta_grid identical') :-
    Grid = [[r,b],[b,r]],
    gtr_delta_grid(Grid, Grid, x, Delta),
    Delta = [[x,x],[x,x]].

% AC-GTR-025: gtr_delta_grid: changed cells show B value.
test('AC-GTR-025: delta_grid changed cells') :-
    A = [[r,b],[b,r]],
    B = [[r,g],[b,r]],
    gtr_delta_grid(A, B, x, Delta),
    Delta = [[x,g],[x,x]].

% AC-GTR-026: gtr_overlay: non-Bg delta cells overwrite base.
test('AC-GTR-026: overlay basic') :-
    Base = [[r,r],[r,r]],
    Delta = [[b,x],[x,x]],
    gtr_overlay(Base, Delta, x, Result),
    Result = [[b,r],[r,r]].

% AC-GTR-027: gtr_overlay: all-Bg delta returns base unchanged.
test('AC-GTR-027: overlay all bg') :-
    Base = [[r,b],[b,r]],
    Delta = [[x,x],[x,x]],
    gtr_overlay(Base, Delta, x, Result),
    Result = Base.

% AC-GTR-028: gtr_common_grid: identical grids return same grid.
test('AC-GTR-028: common_grid identical') :-
    Grid = [[r,b],[b,r]],
    gtr_common_grid(Grid, Grid, x, Result),
    Result = Grid.

% AC-GTR-029: gtr_common_grid: no matching cells return all-Bg.
test('AC-GTR-029: common_grid no match') :-
    A = [[r,r],[r,r]],
    B = [[b,b],[b,b]],
    gtr_common_grid(A, B, x, [[x,x],[x,x]]).

% AC-GTR-030: gtr_common_grid: partial match.
test('AC-GTR-030: common_grid partial') :-
    A = [[r,b],[b,r]],
    B = [[r,g],[g,r]],
    gtr_common_grid(A, B, x, Result),
    Result = [[r,x],[x,r]].

% AC-GTR-031: gtr_is_color_permutation: identical grids are permutation.
test('AC-GTR-031: is_color_permutation identical') :-
    Grid = [[r,b],[g,r]],
    gtr_is_color_permutation(Grid, Grid).

% AC-GTR-032: gtr_is_color_permutation: bijective swap succeeds.
test('AC-GTR-032: is_color_permutation swap') :-
    A = [[r,b],[r,b]],
    B = [[b,r],[b,r]],
    gtr_is_color_permutation(A, B).

% AC-GTR-033: gtr_is_color_permutation: fails if inconsistent.
test('AC-GTR-033: is_color_permutation inconsistent fails', [fail]) :-
    A = [[r,r],[b,b]],
    B = [[b,g],[b,b]],
    gtr_is_color_permutation(A, B).

% AC-GTR-034: gtr_is_color_permutation: fails if not bijective.
test('AC-GTR-034: is_color_permutation not bijective fails', [fail]) :-
    % Both r and b map to g (two sources, one target)
    A = [[r,b],[r,b]],
    B = [[g,g],[g,g]],
    gtr_is_color_permutation(A, B).

% AC-GTR-035: integration - color_map and apply_color_map round-trip.
test('AC-GTR-035: integration color map round trip') :-
    A = [[r,b,g],[g,r,b]],
    B = [[b,g,r],[r,b,g]],
    gtr_color_map(A, B, Map),
    gtr_apply_color_map(A, Map, B).

% AC-GTR-036: integration - delta_grid and overlay reconstruct B.
test('AC-GTR-036: integration delta and overlay') :-
    A = [[r,b],[b,r]],
    B = [[r,g],[b,r]],
    gtr_delta_grid(A, B, x, Delta),
    gtr_overlay(A, Delta, x, Result),
    Result = B.

% AC-GTR-037: integration - changed_colors and apply_changes.
test('AC-GTR-037: integration changes round trip') :-
    A = [[r,b],[b,r]],
    B = [[r,g],[b,r]],
    gtr_changed_colors(A, B, Changes),
    gtr_apply_changes(A, Changes, Result),
    Result = B.

% AC-GTR-038: integration - invert_map composes to identity.
test('AC-GTR-038: integration invert composes identity') :-
    Map = [cm(r,b), cm(b,g), cm(g,r)],
    gtr_invert_map(Map, InvMap),
    gtr_compose_maps(Map, InvMap, Composed),
    gtr_is_identity_map(Composed).

% AC-GTR-039: integration - diff_count + same_cells total = grid size.
test('AC-GTR-039: integration diff plus same equals size') :-
    A = [[r,b,g],[g,r,b]],
    B = [[r,g,g],[g,r,b]],
    gtr_diff_count(A, B, D),
    gtr_same_cells(A, B, Same),
    length(Same, S),
    Total is D + S,
    Total =:= 6.

% AC-GTR-040: integration - common_grid matches same_cells.
test('AC-GTR-040: integration common matches same_cells') :-
    A = [[r,b],[g,r]],
    B = [[r,g],[g,b]],
    gtr_common_grid(A, B, x, Common),
    gtr_same_cells(A, B, SameCells),
    length(SameCells, 2),
    gtr_diff_cells(A, Common, DiffFromCommon),
    length(DiffFromCommon, 2).

% AC-GTR-041: integration - apply_color_map then invert returns original.
test('AC-GTR-041: integration apply then invert') :-
    Grid = [[r,b],[g,r]],
    Map = [cm(b,x), cm(g,y), cm(r,z)],
    gtr_apply_color_map(Grid, Map, Mapped),
    gtr_invert_map(Map, InvMap),
    gtr_apply_color_map(Mapped, InvMap, Restored),
    Restored = Grid.

% AC-GTR-042: integration - compose_maps associativity.
test('AC-GTR-042: integration compose associativity') :-
    MapAB = [cm(r,b), cm(b,g)],
    MapBC = [cm(b,x), cm(g,y)],
    MapCD = [cm(x,p), cm(y,q)],
    gtr_compose_maps(MapAB, MapBC, MapAC),
    gtr_compose_maps(MapAC, MapCD, MapAD1),
    gtr_compose_maps(MapBC, MapCD, MapBD),
    gtr_compose_maps(MapAB, MapBD, MapAD2),
    MapAD1 = MapAD2.

% AC-GTR-043: integration - delta_grid then overlay on different base.
test('AC-GTR-043: integration overlay on different base') :-
    A = [[r,r],[r,r]],
    B = [[r,b],[r,r]],
    gtr_delta_grid(A, B, x, Delta),
    Base2 = [[g,g],[g,g]],
    gtr_overlay(Base2, Delta, x, Result),
    Result = [[g,b],[g,g]].

% AC-GTR-044: integration - is_color_permutation and invert.
test('AC-GTR-044: integration permutation and invert') :-
    A = [[r,b,g],[g,r,b]],
    B = [[b,g,r],[r,b,g]],
    gtr_is_color_permutation(A, B),
    gtr_color_map(A, B, Map),
    gtr_invert_map(Map, InvMap),
    gtr_apply_color_map(B, InvMap, A).

:- end_tests(gridtransform).
