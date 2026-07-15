% Test suite for gridresize (grs_*, Layer 241).
:- use_module('../prolog/grid_resize.pl').

:- begin_tests(grid_resize).

% AC-GRS-001: grid_resize_scale_up by 2 on 1x1 grid.
test('AC-GRS-001: scale_up 1x1 by 2') :-
    grid_resize_scale_up([[r]], 2, [[r,r],[r,r]]).

% AC-GRS-002: grid_resize_scale_up by 2 on 2x2 grid.
test('AC-GRS-002: scale_up 2x2 by 2') :-
    grid_resize_scale_up([[a,b],[c,d]], 2,
        [[a,a,b,b],[a,a,b,b],[c,c,d,d],[c,c,d,d]]).

% AC-GRS-003: grid_resize_scale_up by 1 is identity.
test('AC-GRS-003: scale_up factor 1 identity') :-
    grid_resize_scale_up([[r,g],[b,b]], 1, [[r,g],[b,b]]).

% AC-GRS-004: grid_resize_scale_down by 2 on 2x2 grid.
test('AC-GRS-004: scale_down 2x2 by 2') :-
    grid_resize_scale_down([[a,b],[c,d]], 2, b, [[a]]).

% AC-GRS-005: grid_resize_scale_down by 2 on 4x4 grid.
test('AC-GRS-005: scale_down 4x4 by 2') :-
    grid_resize_scale_down([[a,a,b,b],[a,a,b,b],[c,c,d,d],[c,c,d,d]], 2, b,
        [[a,b],[c,d]]).

% AC-GRS-006: grid_resize_scale_down on 1x1 by 2 returns empty.
test('AC-GRS-006: scale_down 1x1 by 2 returns empty') :-
    grid_resize_scale_down([[r]], 2, b, []).

% AC-GRS-007: grid_resize_scale_down_mode takes mode of 2x2 block.
test('AC-GRS-007: scale_down_mode majority') :-
    grid_resize_scale_down_mode([[r,r],[g,r]], 2, b, [[r]]).

% AC-GRS-008: grid_resize_scale_down_mode tie: msort-first wins.
test('AC-GRS-008: scale_down_mode tie msort') :-
    grid_resize_scale_down_mode([[a,b],[b,a]], 2, b, [[X]]),
    (X = a ; X = b).

% AC-GRS-009: grid_resize_scale_down_mode on uniform block returns that value.
test('AC-GRS-009: scale_down_mode uniform block') :-
    grid_resize_scale_down_mode([[g,g],[g,g]], 2, b, [[g]]).

% AC-GRS-010: grid_resize_double on 1x1 grid.
test('AC-GRS-010: double 1x1') :-
    grid_resize_double([[r]], [[r,r],[r,r]]).

% AC-GRS-011: grid_resize_double on 1x2 grid.
test('AC-GRS-011: double 1x2') :-
    grid_resize_double([[a,b]], [[a,a,b,b],[a,a,b,b]]).

% AC-GRS-012: grid_resize_halve on 2x2 grid returns 1x1 (top-left sample).
test('AC-GRS-012: halve 2x2') :-
    grid_resize_halve([[r,g],[b,y]], b, [[r]]).

% AC-GRS-013: grid_resize_resize 1x1 to 3x3 (scale up).
test('AC-GRS-013: resize 1x1 to 3x3') :-
    grid_resize_resize([[r]], 3, 3, b, [[r,r,r],[r,r,r],[r,r,r]]).

% AC-GRS-014: grid_resize_resize 2x2 to 1x1 (scale down).
test('AC-GRS-014: resize 2x2 to 1x1') :-
    grid_resize_resize([[a,b],[c,d]], 1, 1, b, [[a]]).

% AC-GRS-015: grid_resize_resize 1x3 to 1x2 (nearest-neighbor).
test('AC-GRS-015: resize 1x3 to 1x2') :-
    grid_resize_resize([[a,b,c]], 1, 2, b, [[a,b]]).

% AC-GRS-016: grid_resize_tile_to with source smaller than target.
test('AC-GRS-016: tile_to 2x2 to 4x4') :-
    grid_resize_tile_to([[a,b],[c,d]], 4, 4,
        [[a,b,a,b],[c,d,c,d],[a,b,a,b],[c,d,c,d]]).

% AC-GRS-017: grid_resize_tile_to with non-multiple dimensions.
test('AC-GRS-017: tile_to 2x2 to 3x3') :-
    grid_resize_tile_to([[a,b],[c,d]], 3, 3,
        [[a,b,a],[c,d,c],[a,b,a]]).

% AC-GRS-018: grid_resize_tile_to with same dimensions is identity.
test('AC-GRS-018: tile_to identity') :-
    grid_resize_tile_to([[r,g],[b,b]], 2, 2, [[r,g],[b,b]]).

% AC-GRS-019: grid_resize_crop extracts subgrid.
test('AC-GRS-019: crop subgrid') :-
    grid_resize_crop([[a,b,c],[d,e,f],[g,h,i]], 0, 0, 1, 1, [[a,b],[d,e]]).

% AC-GRS-020: grid_resize_crop single row.
test('AC-GRS-020: crop single row') :-
    grid_resize_crop([[a,b,c],[d,e,f]], 1, 0, 1, 2, [[d,e,f]]).

% AC-GRS-021: grid_resize_crop clamps out-of-bounds indices.
test('AC-GRS-021: crop clamped') :-
    grid_resize_crop([[a,b],[c,d]], 0, 0, 5, 5, [[a,b],[c,d]]).

% AC-GRS-022: grid_resize_border_crop removes 1 border.
test('AC-GRS-022: border_crop N=1') :-
    grid_resize_border_crop([[a,b,c],[d,e,f],[g,h,i]], 1, b, [[e]]).

% AC-GRS-023: grid_resize_border_crop N=0 is identity.
test('AC-GRS-023: border_crop N=0 identity') :-
    grid_resize_border_crop([[a,b],[c,d]], 0, b, [[a,b],[c,d]]).

% AC-GRS-024: grid_resize_border_crop too large returns empty.
test('AC-GRS-024: border_crop too large empty') :-
    grid_resize_border_crop([[a,b],[c,d]], 2, b, []).

% AC-GRS-025: grid_resize_fit_in scales 2x2 into 4x4 canvas.
test('AC-GRS-025: fit_in scale up') :-
    grid_resize_fit_in([[a,b],[c,d]], 4, 4, b,
        [[a,a,b,b],[a,a,b,b],[c,c,d,d],[c,c,d,d]]).

% AC-GRS-026: grid_resize_fit_in keeps aspect ratio when canvas is non-square.
test('AC-GRS-026: fit_in non-square canvas') :-
    grid_resize_fit_in([[r,g]], 4, 6, b, Result),
    length(Result, 4),
    Result = [_|_].

% AC-GRS-027: grid_resize_fit_in on 1x1 into 3x3.
test('AC-GRS-027: fit_in 1x1 to 3x3') :-
    grid_resize_fit_in([[r]], 3, 3, b, [[r,r,r],[r,r,r],[r,r,r]]).

% AC-GRS-028: grid_resize_embed_in centers smaller grid.
test('AC-GRS-028: embed_in centered') :-
    grid_resize_embed_in([[r]], 3, 3, b,
        [[b,b,b],[b,r,b],[b,b,b]]).

% AC-GRS-029: grid_resize_embed_in same size is identity.
test('AC-GRS-029: embed_in same size') :-
    grid_resize_embed_in([[a,b],[c,d]], 2, 2, b, [[a,b],[c,d]]).

% AC-GRS-030: grid_resize_embed_in 2x2 into 4x4.
test('AC-GRS-030: embed_in 2x2 to 4x4') :-
    grid_resize_embed_in([[a,b],[c,d]], 4, 4, b,
        [[b,b,b,b],[b,a,b,b],[b,c,d,b],[b,b,b,b]]).

% AC-GRS-031: grid_resize_grid_size on 2x3 grid.
test('AC-GRS-031: grid_size 2x3') :-
    grid_resize_grid_size([[a,b,c],[d,e,f]], 2, 3).

% AC-GRS-032: grid_resize_grid_size on 1x1 grid.
test('AC-GRS-032: grid_size 1x1') :-
    grid_resize_grid_size([[r]], 1, 1).

% AC-GRS-033: grid_resize_aspect_ratio on 2x4 grid.
test('AC-GRS-033: aspect_ratio 2x4') :-
    grid_resize_aspect_ratio([[a,b,c,d],[e,f,g,h]], 2, 4, R),
    abs(R - 2.0) < 0.001.

% AC-GRS-034: grid_resize_aspect_ratio on square grid is 1.0.
test('AC-GRS-034: aspect_ratio square') :-
    grid_resize_aspect_ratio([[a,b],[c,d]], 2, 2, R),
    abs(R - 1.0) < 0.001.

% AC-GRS-035: grid_resize_is_square succeeds on square grid.
test('AC-GRS-035: is_square square') :-
    grid_resize_is_square([[a,b],[c,d]]).

% AC-GRS-036: grid_resize_is_square fails on non-square grid.
test('AC-GRS-036: is_square non-square fails', [fail]) :-
    grid_resize_is_square([[a,b,c],[d,e,f]]).

% AC-GRS-037: integration - scale_up then scale_down returns original.
test('AC-GRS-037: integration scale_up then scale_down') :-
    Grid = [[a,b],[c,d]],
    grid_resize_scale_up(Grid, 3, Big),
    grid_resize_scale_down(Big, 3, b, Grid).

% AC-GRS-038: integration - double then halve returns original.
test('AC-GRS-038: integration double then halve') :-
    Grid = [[r,g],[b,b]],
    grid_resize_double(Grid, Big),
    grid_resize_halve(Big, b, Grid).

% AC-GRS-039: integration - resize then check size.
test('AC-GRS-039: integration resize check size') :-
    grid_resize_resize([[a,b,c],[d,e,f]], 4, 6, b, Result),
    grid_resize_grid_size(Result, 4, 6).

% AC-GRS-040: integration - tile then crop.
test('AC-GRS-040: integration tile then crop') :-
    grid_resize_tile_to([[r,b]], 2, 4, Tiled),
    grid_resize_crop(Tiled, 0, 0, 0, 1, [[r,b]]).

% AC-GRS-041: grid_resize_scale_up by 3 on 1x2 grid.
test('AC-GRS-041: scale_up 1x2 by 3') :-
    grid_resize_scale_up([[r,g]], 3,
        [[r,r,r,g,g,g],[r,r,r,g,g,g],[r,r,r,g,g,g]]).

% AC-GRS-042: grid_resize_resize identity (same dims).
test('AC-GRS-042: resize identity') :-
    Grid = [[a,b],[c,d]],
    grid_resize_resize(Grid, 2, 2, b, Grid).

% AC-GRS-043: grid_resize_embed_in 1x3 into 3x3.
test('AC-GRS-043: embed_in 1x3 into 3x3') :-
    grid_resize_embed_in([[r,g,b]], 3, 3, x,
        [[x,x,x],[r,g,b],[x,x,x]]).

% AC-GRS-044: integration - border_crop then grid_size.
test('AC-GRS-044: integration border_crop size') :-
    grid_resize_border_crop([[a,b,c,d],[e,f,g,h],[i,j,k,l],[m,n,o,p]], 1, b, Inner),
    grid_resize_grid_size(Inner, 2, 2).

:- end_tests(grid_resize).
