% Test suite for gridtransform (gtr_*, Layer 245).
:- use_module('../prolog/grid_color_transform.pl').

:- begin_tests(grid_color_transform).

% AC-GTR-001: grid_color_transform_color_map: identity map (no changes).
test('AC-GTR-001: color_map identity') :-
    Grid = [[r,b],[g,r]],
    grid_color_transform_color_map(Grid, Grid, Map),
    member(cm(r,r), Map),
    member(cm(b,b), Map),
    member(cm(g,g), Map).

% AC-GTR-002: grid_color_transform_color_map: simple swap.
test('AC-GTR-002: color_map swap') :-
    A = [[r,b],[r,b]],
    B = [[b,r],[b,r]],
    grid_color_transform_color_map(A, B, Map),
    member(cm(r,b), Map),
    member(cm(b,r), Map),
    length(Map, 2).

% AC-GTR-003: grid_color_transform_color_map: fails when inconsistent.
test('AC-GTR-003: color_map inconsistent fails', [fail]) :-
    % r maps to both b and g at different positions
    A = [[r,r],[b,b]],
    B = [[b,g],[b,b]],
    grid_color_transform_color_map(A, B, _).

% AC-GTR-004: grid_color_transform_apply_color_map: applies swap map.
test('AC-GTR-004: apply_color_map swap') :-
    Grid = [[r,b],[r,r]],
    Map = [cm(b,g), cm(r,b)],
    grid_color_transform_apply_color_map(Grid, Map, Result),
    Result = [[b,g],[b,b]].

% AC-GTR-005: grid_color_transform_apply_color_map: unmapped colors pass through.
test('AC-GTR-005: apply_color_map passthrough') :-
    Grid = [[r,x],[x,r]],
    Map = [cm(r,b)],
    grid_color_transform_apply_color_map(Grid, Map, Result),
    Result = [[b,x],[x,b]].

% AC-GTR-006: grid_color_transform_diff_cells: two identical grids have no differences.
test('AC-GTR-006: difference_cells identical') :-
    Grid = [[r,b],[g,r]],
    grid_color_transform_diff_cells(Grid, Grid, []).

% AC-GTR-007: grid_color_transform_diff_cells: one cell differs.
test('AC-GTR-007: difference_cells one cell') :-
    A = [[r,b],[g,r]],
    B = [[r,b],[x,r]],
    grid_color_transform_diff_cells(A, B, Cells),
    Cells = [r(1,0)].

% AC-GTR-008: grid_color_transform_diff_cells: all cells differ.
test('AC-GTR-008: difference_cells all differ') :-
    A = [[r,r],[r,r]],
    B = [[b,b],[b,b]],
    grid_color_transform_diff_cells(A, B, Cells),
    length(Cells, 4).

% AC-GTR-009: grid_color_transform_diff_count: zero for identical grids.
test('AC-GTR-009: difference_count zero') :-
    grid_color_transform_diff_count([[r,b],[b,r]], [[r,b],[b,r]], 0).

% AC-GTR-010: grid_color_transform_diff_count: correct count for partial difference.
test('AC-GTR-010: difference_count partial') :-
    A = [[r,b],[g,r]],
    B = [[r,b],[g,b]],
    grid_color_transform_diff_count(A, B, 1).

% AC-GTR-011: grid_color_transform_same_cells: all same for identical grids.
test('AC-GTR-011: same_cells identical') :-
    Grid = [[r,b],[b,r]],
    grid_color_transform_same_cells(Grid, Grid, Cells),
    length(Cells, 4).

% AC-GTR-012: grid_color_transform_same_cells: no same cells when all differ.
test('AC-GTR-012: same_cells none') :-
    A = [[r,r],[r,r]],
    B = [[b,b],[b,b]],
    grid_color_transform_same_cells(A, B, []).

% AC-GTR-013: grid_color_transform_changed_colors: empty for identical grids.
test('AC-GTR-013: changed_colors identical') :-
    Grid = [[r,b],[b,r]],
    grid_color_transform_changed_colors(Grid, Grid, []).

% AC-GTR-014: grid_color_transform_changed_colors: records old and new color.
test('AC-GTR-014: changed_colors records change') :-
    A = [[r,b],[b,r]],
    B = [[r,b],[g,r]],
    grid_color_transform_changed_colors(A, B, Changes),
    Changes = [chg(1,0,b,g)].

% AC-GTR-015: grid_color_transform_invert_map: inverts a swap map.
test('AC-GTR-015: invert_map swap') :-
    Map = [cm(r,b), cm(b,r)],
    grid_color_transform_invert_map(Map, InvMap),
    member(cm(b,r), InvMap),
    member(cm(r,b), InvMap).

% AC-GTR-016: grid_color_transform_invert_map: fails for non-injective map.
test('AC-GTR-016: invert_map non-injective fails', [fail]) :-
    Map = [cm(r,b), cm(g,b)],
    grid_color_transform_invert_map(Map, _).

% AC-GTR-017: grid_color_transform_compose_maps: compose two maps.
test('AC-GTR-017: compose_maps basic') :-
    MapAB = [cm(r,b), cm(b,g)],
    MapBC = [cm(b,x), cm(g,y)],
    grid_color_transform_compose_maps(MapAB, MapBC, MapAC),
    member(cm(r,x), MapAC),
    member(cm(b,y), MapAC).

% AC-GTR-018: grid_color_transform_compose_maps: only matched colors appear.
test('AC-GTR-018: compose_maps partial') :-
    MapAB = [cm(r,b), cm(g,z)],
    MapBC = [cm(b,x)],
    grid_color_transform_compose_maps(MapAB, MapBC, MapAC),
    MapAC = [cm(r,x)].

% AC-GTR-019: grid_color_transform_is_identity_map: empty map is identity.
test('AC-GTR-019: is_identity_map empty') :-
    grid_color_transform_is_identity_map([]).

% AC-GTR-020: grid_color_transform_is_identity_map: all same entries is identity.
test('AC-GTR-020: is_identity_map same') :-
    grid_color_transform_is_identity_map([cm(r,r), cm(b,b)]).

% AC-GTR-021: grid_color_transform_is_identity_map: fails for non-identity.
test('AC-GTR-021: is_identity_map fails', [fail]) :-
    grid_color_transform_is_identity_map([cm(r,b)]).

% AC-GTR-022: grid_color_transform_apply_changes: applies changes to grid.
test('AC-GTR-022: apply_changes basic') :-
    Grid = [[r,b],[b,r]],
    Changes = [chg(0,0,r,g)],
    grid_color_transform_apply_changes(Grid, Changes, Result),
    Result = [[g,b],[b,r]].

% AC-GTR-023: grid_color_transform_apply_changes: empty changes returns original.
test('AC-GTR-023: apply_changes empty') :-
    Grid = [[r,b],[b,r]],
    grid_color_transform_apply_changes(Grid, [], Grid).

% AC-GTR-024: grid_color_transform_delta_grid: identical grids produce all-Bg delta.
test('AC-GTR-024: delta_grid identical') :-
    Grid = [[r,b],[b,r]],
    grid_color_transform_delta_grid(Grid, Grid, x, Delta),
    Delta = [[x,x],[x,x]].

% AC-GTR-025: grid_color_transform_delta_grid: changed cells show B value.
test('AC-GTR-025: delta_grid changed cells') :-
    A = [[r,b],[b,r]],
    B = [[r,g],[b,r]],
    grid_color_transform_delta_grid(A, B, x, Delta),
    Delta = [[x,g],[x,x]].

% AC-GTR-026: grid_color_transform_overlay: non-Bg delta cells overwrite base.
test('AC-GTR-026: overlay basic') :-
    Base = [[r,r],[r,r]],
    Delta = [[b,x],[x,x]],
    grid_color_transform_overlay(Base, Delta, x, Result),
    Result = [[b,r],[r,r]].

% AC-GTR-027: grid_color_transform_overlay: all-Bg delta returns base unchanged.
test('AC-GTR-027: overlay all bg') :-
    Base = [[r,b],[b,r]],
    Delta = [[x,x],[x,x]],
    grid_color_transform_overlay(Base, Delta, x, Result),
    Result = Base.

% AC-GTR-028: grid_color_transform_common_grid: identical grids return same grid.
test('AC-GTR-028: common_grid identical') :-
    Grid = [[r,b],[b,r]],
    grid_color_transform_common_grid(Grid, Grid, x, Result),
    Result = Grid.

% AC-GTR-029: grid_color_transform_common_grid: no matching cells return all-Bg.
test('AC-GTR-029: common_grid no match') :-
    A = [[r,r],[r,r]],
    B = [[b,b],[b,b]],
    grid_color_transform_common_grid(A, B, x, [[x,x],[x,x]]).

% AC-GTR-030: grid_color_transform_common_grid: partial match.
test('AC-GTR-030: common_grid partial') :-
    A = [[r,b],[b,r]],
    B = [[r,g],[g,r]],
    grid_color_transform_common_grid(A, B, x, Result),
    Result = [[r,x],[x,r]].

% AC-GTR-031: grid_color_transform_is_color_permutation: identical grids are permutation.
test('AC-GTR-031: is_color_permutation identical') :-
    Grid = [[r,b],[g,r]],
    grid_color_transform_is_color_permutation(Grid, Grid).

% AC-GTR-032: grid_color_transform_is_color_permutation: bijective swap succeeds.
test('AC-GTR-032: is_color_permutation swap') :-
    A = [[r,b],[r,b]],
    B = [[b,r],[b,r]],
    grid_color_transform_is_color_permutation(A, B).

% AC-GTR-033: grid_color_transform_is_color_permutation: fails if inconsistent.
test('AC-GTR-033: is_color_permutation inconsistent fails', [fail]) :-
    A = [[r,r],[b,b]],
    B = [[b,g],[b,b]],
    grid_color_transform_is_color_permutation(A, B).

% AC-GTR-034: grid_color_transform_is_color_permutation: fails if not bijective.
test('AC-GTR-034: is_color_permutation not bijective fails', [fail]) :-
    % Both r and b map to g (two sources, one target)
    A = [[r,b],[r,b]],
    B = [[g,g],[g,g]],
    grid_color_transform_is_color_permutation(A, B).

% AC-GTR-035: integration - color_map and apply_color_map round-trip.
test('AC-GTR-035: integration color map round trip') :-
    A = [[r,b,g],[g,r,b]],
    B = [[b,g,r],[r,b,g]],
    grid_color_transform_color_map(A, B, Map),
    grid_color_transform_apply_color_map(A, Map, B).

% AC-GTR-036: integration - delta_grid and overlay reconstruct B.
test('AC-GTR-036: integration delta and overlay') :-
    A = [[r,b],[b,r]],
    B = [[r,g],[b,r]],
    grid_color_transform_delta_grid(A, B, x, Delta),
    grid_color_transform_overlay(A, Delta, x, Result),
    Result = B.

% AC-GTR-037: integration - changed_colors and apply_changes.
test('AC-GTR-037: integration changes round trip') :-
    A = [[r,b],[b,r]],
    B = [[r,g],[b,r]],
    grid_color_transform_changed_colors(A, B, Changes),
    grid_color_transform_apply_changes(A, Changes, Result),
    Result = B.

% AC-GTR-038: integration - invert_map composes to identity.
test('AC-GTR-038: integration invert composes identity') :-
    Map = [cm(r,b), cm(b,g), cm(g,r)],
    grid_color_transform_invert_map(Map, InvMap),
    grid_color_transform_compose_maps(Map, InvMap, Composed),
    grid_color_transform_is_identity_map(Composed).

% AC-GTR-039: integration - difference_count + same_cells total = grid size.
test('AC-GTR-039: integration diff plus same equals size') :-
    A = [[r,b,g],[g,r,b]],
    B = [[r,g,g],[g,r,b]],
    grid_color_transform_diff_count(A, B, D),
    grid_color_transform_same_cells(A, B, Same),
    length(Same, S),
    Total is D + S,
    Total =:= 6.

% AC-GTR-040: integration - common_grid matches same_cells.
test('AC-GTR-040: integration common matches same_cells') :-
    A = [[r,b],[g,r]],
    B = [[r,g],[g,b]],
    grid_color_transform_common_grid(A, B, x, Common),
    grid_color_transform_same_cells(A, B, SameCells),
    length(SameCells, 2),
    grid_color_transform_diff_cells(A, Common, DiffFromCommon),
    length(DiffFromCommon, 2).

% AC-GTR-041: integration - apply_color_map then invert returns original.
test('AC-GTR-041: integration apply then invert') :-
    Grid = [[r,b],[g,r]],
    Map = [cm(b,x), cm(g,y), cm(r,z)],
    grid_color_transform_apply_color_map(Grid, Map, Mapped),
    grid_color_transform_invert_map(Map, InvMap),
    grid_color_transform_apply_color_map(Mapped, InvMap, Restored),
    Restored = Grid.

% AC-GTR-042: integration - compose_maps associativity.
test('AC-GTR-042: integration compose associativity') :-
    MapAB = [cm(r,b), cm(b,g)],
    MapBC = [cm(b,x), cm(g,y)],
    MapCD = [cm(x,p), cm(y,q)],
    grid_color_transform_compose_maps(MapAB, MapBC, MapAC),
    grid_color_transform_compose_maps(MapAC, MapCD, MapAD1),
    grid_color_transform_compose_maps(MapBC, MapCD, MapBD),
    grid_color_transform_compose_maps(MapAB, MapBD, MapAD2),
    MapAD1 = MapAD2.

% AC-GTR-043: integration - delta_grid then overlay on different base.
test('AC-GTR-043: integration overlay on different base') :-
    A = [[r,r],[r,r]],
    B = [[r,b],[r,r]],
    grid_color_transform_delta_grid(A, B, x, Delta),
    Base2 = [[g,g],[g,g]],
    grid_color_transform_overlay(Base2, Delta, x, Result),
    Result = [[g,b],[g,g]].

% AC-GTR-044: integration - is_color_permutation and invert.
test('AC-GTR-044: integration permutation and invert') :-
    A = [[r,b,g],[g,r,b]],
    B = [[b,g,r],[r,b,g]],
    grid_color_transform_is_color_permutation(A, B),
    grid_color_transform_color_map(A, B, Map),
    grid_color_transform_invert_map(Map, InvMap),
    grid_color_transform_apply_color_map(B, InvMap, A).

:- end_tests(grid_color_transform).
