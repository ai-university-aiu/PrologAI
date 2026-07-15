:- module(gridtask, [
    gridtask_diff_cells/3,
    gridtask_n_changed/3,
    gridtask_unchanged_cells/3,
    gridtask_bg_color/2,
    gridtask_infer_color_map/3,
    gridtask_test_color_map/3,
    gridtask_apply_color_map/3,
    gridtask_color_map_pairs/2,
    gridtask_is_color_sub/1,
    gridtask_is_identity/2,
    gridtask_is_scale/3,
    gridtask_infer_shift/4,
    gridtask_pair_score/4,
    gridtask_solve/4
]).
% Grid Task: raw-grid rule inference and application without scene conversion.
% All predicates operate directly on raw grid format: list of rows,
% each row a list of color atoms, 0-indexed (row 0 = top, col 0 = left).
% Training pairs are expressed as Before-After terms.
:- use_module(library(lists), [
    list_to_set/2, member/2, nth0/3, append/3
]).
:- use_module(library(apply), [maplist/3, maplist/2]).

% --- PRIVATE HELPERS ---

% Get the H x W dimensions of a raw grid.
gridtask_dims_(Grid, H, W) :-
% Bind H to the number of rows.
    length(Grid, H),
% Bind W to the number of columns in the first row; W=0 for empty grids.
    (H > 0 -> Grid = [Row|_], length(Row, W) ; W = 0).

% Succeed if the color map has no key mapping to two different values.
gridtask_consistent_map_(Map) :-
% Fail if any key K maps to both V1 and V2 where V1 != V2.
    \+ (member(K-V1, Map), member(K-V2, Map), V1 \= V2).

% Apply one color map entry to a single cell value V, yielding NV.
gridtask_apply_cell_(Map, V, NV) :-
% Use the map entry if one exists; otherwise keep V unchanged.
    (member(V-NV, Map) -> true ; NV = V).

% Apply a color map to a single row.
gridtask_apply_row_(Map, Row, NewRow) :-
% Map each cell in Row through gridtask_apply_cell_.
    maplist(gridtask_apply_cell_(Map), Row, NewRow).

% Apply a shift of (DR, DC) to Grid using Bg as background fill.
% Output[R][C] = Grid[R-DR][C-DC], or Bg if the source position is out of bounds.
gridtask_apply_shift_(Grid, Bg, DR, DC, Shifted) :-
% Get grid dimensions.
    gridtask_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Build each output row.
    findall(Row,
        (between(0, H1, R),
% Build each output cell in the row.
         findall(V,
             (between(0, W1, C),
              RS is R - DR,
              CS is C - DC,
% Use grid value if source is in bounds; use Bg otherwise.
              (RS >= 0, RS < H, CS >= 0, CS < W
              ->  nth0(RS, Grid, GRow), nth0(CS, GRow, V)
              ;   V = Bg)),
             Row)),
        Shifted).

% Scale up Grid by integer factor N (each cell becomes an N x N block).
gridtask_scale_up_(Grid, N, Scaled) :-
% Get grid dimensions.
    gridtask_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
    N1 is N - 1,
% Each original row R produces N output rows; each column C produces N values.
    findall(SRow,
        (between(0, H1, R),
         between(0, N1, _DR),
         findall(V,
             (between(0, W1, C),
              between(0, N1, _DC),
              nth0(R, Grid, GRow),
              nth0(C, GRow, V)),
             SRow)),
        Scaled).

% Succeed if all Before-After pairs in Pairs are identical grids.
gridtask_pairs_identity_([]).
gridtask_pairs_identity_([B-A | Rest]) :-
% Each pair must unify.
    B == A,
    gridtask_pairs_identity_(Rest).

% Test that applying Map to Before yields After exactly.
gridtask_test_pair_map_(Map, Before-After) :-
    gridtask_test_color_map(Map, Before, After).

% Test that scaling Before by N yields After exactly.
gridtask_test_scale_(N, Before-After) :-
    gridtask_scale_up_(Before, N, Predicted),
    Predicted == After.

% Test that shifting Before by (DR,DC) with background Bg yields After.
gridtask_test_shift_(Bg, DR, DC, Before-After) :-
    gridtask_apply_shift_(Before, Bg, DR, DC, Shifted),
    Shifted == After.

% Apply a rule term to Grid and return the result.
gridtask_apply_rule_(identity, Grid, Grid).
gridtask_apply_rule_(color_map(Map), Grid, NewGrid) :-
    gridtask_apply_color_map(Map, Grid, NewGrid).
gridtask_apply_rule_(scale(N), Grid, Scaled) :-
    gridtask_scale_up_(Grid, N, Scaled).
gridtask_apply_rule_(shift(DR, DC, Bg), Grid, Shifted) :-
    gridtask_apply_shift_(Grid, Bg, DR, DC, Shifted).

% --- EXPORTED PREDICATES ---

% gridtask_diff_cells(+Before, +After, -Cells)
% Cells is the sorted list of r(R,C) positions where Before and After differ.
% Both grids must have the same dimensions.
gridtask_diff_cells(Before, After, Cells) :-
% Get grid dimensions from Before.
    gridtask_dims_(Before, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Collect all positions where values differ.
    findall(r(R, C),
        (between(0, H1, R),
         between(0, W1, C),
         nth0(R, Before, BRow),
         nth0(C, BRow, BV),
         nth0(R, After, ARow),
         nth0(C, ARow, AV),
         BV \= AV),
        Cells).

% gridtask_n_changed(+Before, +After, -N)
% N is the count of positions where Before and After have different values.
gridtask_n_changed(Before, After, N) :-
% Delegate to gridtask_diff_cells and take the length.
    gridtask_diff_cells(Before, After, Cells),
    length(Cells, N).

% gridtask_unchanged_cells(+Before, +After, -Cells)
% Cells is the list of r(R,C) positions where Before and After agree.
gridtask_unchanged_cells(Before, After, Cells) :-
% Get dimensions.
    gridtask_dims_(Before, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Collect positions where values are equal.
    findall(r(R, C),
        (between(0, H1, R),
         between(0, W1, C),
         nth0(R, Before, BRow),
         nth0(C, BRow, V),
         nth0(R, After, ARow),
         nth0(C, ARow, V)),
        Cells).

% gridtask_bg_color(+Grid, -BgColor)
% BgColor is the most frequently occurring color in Grid.
% Ties broken by standard term order (smallest color atom wins).
gridtask_bg_color(Grid, BgColor) :-
% Flatten the grid into a value list.
    gridtask_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
    findall(V,
        (between(0, H1, R),
         between(0, W1, C),
         nth0(R, Grid, Row),
         nth0(C, Row, V)),
        Vals),
% Get the distinct set of colors.
    list_to_set(Vals, Colors),
% Compute negative count per color for descending sort.
    findall(NegN-C,
        (member(C, Colors),
         findall(_, member(C, Vals), Matches),
         length(Matches, N),
         NegN is -N),
        Keyed),
% Sort ascending by negative count; head is most frequent color.
    msort(Keyed, [_-BgColor | _]).

% gridtask_infer_color_map(+Before, +After, -Map)
% Map is a list of From-To pairs covering every cell alignment in Before/After.
% Fails if the same From color maps to two different To colors.
gridtask_infer_color_map(Before, After, Map) :-
% Get grid dimensions.
    gridtask_dims_(Before, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Collect all From-To pairs (including identity pairs like r-r).
    findall(BV-AV,
        (between(0, H1, R),
         between(0, W1, C),
         nth0(R, Before, BRow),
         nth0(C, BRow, BV),
         nth0(R, After, ARow),
         nth0(C, ARow, AV)),
        Pairs0),
% Deduplicate via list_to_set.
    list_to_set(Pairs0, Map),
% Fail if inconsistent (same source maps to two targets).
    gridtask_consistent_map_(Map).

% gridtask_test_color_map(+Map, +Before, +After)
% Succeed iff applying Map to Before yields After exactly.
gridtask_test_color_map(Map, Before, After) :-
% Apply the map and compare.
    gridtask_apply_color_map(Map, Before, Predicted),
    Predicted == After.

% gridtask_apply_color_map(+Map, +Grid, -NewGrid)
% NewGrid is Grid with each cell recolored via Map.
% Cells whose color is not in Map are left unchanged.
gridtask_apply_color_map(Map, Grid, NewGrid) :-
% Apply the map row by row.
    maplist(gridtask_apply_row_(Map), Grid, NewGrid).

% gridtask_color_map_pairs(+Pairs, -Map)
% Map is the consistent color substitution table derived from all Before-After
% raw grid pairs in Pairs. Collects From-To evidence from every cell of every
% pair and deduplicates. Fails if any source color maps to two different targets.
gridtask_color_map_pairs(Pairs, Map) :-
% Collect From-To pairs from every cell of every training pair.
    findall(BV-AV,
        (member(Before-After, Pairs),
         gridtask_dims_(Before, H, W),
         H1 is H - 1,
         W1 is W - 1,
         between(0, H1, R),
         between(0, W1, C),
         nth0(R, Before, BRow),
         nth0(C, BRow, BV),
         nth0(R, After, ARow),
         nth0(C, ARow, AV)),
        AllPairs),
% Deduplicate.
    list_to_set(AllPairs, Map),
% Fail if inconsistent.
    gridtask_consistent_map_(Map).

% gridtask_is_color_sub(+Pairs)
% Succeed if there exists a consistent color substitution map that exactly
% explains every Before-After pair in Pairs.
gridtask_is_color_sub(Pairs) :-
% Infer the map.
    gridtask_color_map_pairs(Pairs, Map),
% Verify the map explains every pair.
    maplist(gridtask_test_pair_map_(Map), Pairs).

% gridtask_is_identity(+Before, +After)
% Succeed if Before and After are identical grids.
gridtask_is_identity(Before, After) :-
% Structural equality.
    Before == After.

% gridtask_is_scale(+Before, +After, -N)
% Succeed if After is obtained by scaling each cell of Before into an N x N block.
% N must be an integer >= 2. Fails for non-integer or N=1 scale.
gridtask_is_scale(Before, After, N) :-
% Get both grid sizes.
    gridtask_dims_(Before, BH, BW),
    gridtask_dims_(After, AH, AW),
% Both must be non-empty.
    BH > 0,
    BW > 0,
% After dimensions must be exact integer multiples of Before dimensions.
    0 is AH mod BH,
    0 is AW mod BW,
    N is AH // BH,
% Row and column scale factors must be equal.
    N =:= AW // BW,
% Scale factor must be at least 2.
    N > 1,
    BH1 is BH - 1,
    BW1 is BW - 1,
    N1 is N - 1,
% Every N x N block in After must equal the corresponding Before cell.
    forall(
        (between(0, BH1, R), between(0, BW1, C)),
        (nth0(R, Before, BRow),
         nth0(C, BRow, V),
         forall(
             (between(0, N1, DR), between(0, N1, DC)),
             (AR is R * N + DR,
              AC is C * N + DC,
              nth0(AR, After, ARow),
              nth0(AC, ARow, V))
         ))
    ).

% gridtask_infer_shift(+Before, +After, +BgColor, -dr(DR,DC))
% DR and DC are the row and column translation offsets such that shifting
% Before by (DR,DC) with BgColor fill exactly reproduces After.
% Tries candidate offsets derived from the first non-background cell in Before
% matched against same-color cells in After.
gridtask_infer_shift(Before, After, Bg, dr(DR, DC)) :-
% Get grid dimensions.
    gridtask_dims_(Before, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Collect non-background cells in Before; take the first one.
    findall(r(R, C, V),
        (between(0, H1, R),
         between(0, W1, C),
         nth0(R, Before, BRow),
         nth0(C, BRow, V),
         V \= Bg),
        [r(R1, C1, V1) | _]),
% Find candidate matching cells in After with the same color.
    findall(r(R2, C2),
        (between(0, H1, R2),
         between(0, W1, C2),
         nth0(R2, After, ARow),
         nth0(C2, ARow, V1)),
        Candidates),
% Try each candidate to find the correct shift.
    member(r(R2, C2), Candidates),
    DR is R2 - R1,
    DC is C2 - C1,
% Verify: applying the shift to Before gives After exactly.
    gridtask_apply_shift_(Before, Bg, DR, DC, Shifted),
    Shifted == After.

% gridtask_pair_score(+Rule, +Before, +After, -Score)
% Score is the pixel accuracy of Rule applied to Before versus the expected After.
% Score is a float in [0.0, 1.0]; 1.0 means exact match.
gridtask_pair_score(Rule, Before, After, Score) :-
% Apply the rule to Before to get a prediction.
    gridtask_apply_rule_(Rule, Before, Predicted),
% Count differing cells.
    gridtask_n_changed(Predicted, After, Wrong),
% Compute total cells.
    gridtask_dims_(Before, H, W),
    Total is H * W,
% Pixel accuracy = correct / total; handle empty grids.
    (Total > 0 -> Score is (Total - Wrong) / Total ; Score is 1.0).

% gridtask_solve(+Pairs, +TestBefore, -TestAfter, -Rule)
% Tries strategies in order: identity, color substitution, integer scale,
% and translation. Applies the first strategy that explains all training pairs
% to TestBefore to yield TestAfter and Rule. Falls back to identity if no
% strategy succeeds.
gridtask_solve(Pairs, TestBefore, TestAfter, Rule) :-
% Strategy 1: all pairs are identity (input unchanged).
    (   gridtask_pairs_identity_(Pairs)
    ->  Rule = identity,
        TestAfter = TestBefore
% Strategy 2: a consistent color substitution explains all pairs.
    ;   gridtask_color_map_pairs(Pairs, Map),
        maplist(gridtask_test_pair_map_(Map), Pairs)
    ->  Rule = color_map(Map),
        gridtask_apply_color_map(Map, TestBefore, TestAfter)
% Strategy 3: integer upscaling explains all pairs.
    ;   Pairs = [B1-A1 | _],
        gridtask_is_scale(B1, A1, N),
        maplist(gridtask_test_scale_(N), Pairs)
    ->  Rule = scale(N),
        gridtask_scale_up_(TestBefore, N, TestAfter)
% Strategy 4: a constant translation with background fill explains all pairs.
    ;   Pairs = [B1-A1 | _],
        gridtask_bg_color(B1, Bg),
        gridtask_infer_shift(B1, A1, Bg, dr(DR, DC)),
        maplist(gridtask_test_shift_(Bg, DR, DC), Pairs)
    ->  Rule = shift(DR, DC, Bg),
        gridtask_apply_shift_(TestBefore, Bg, DR, DC, TestAfter)
% Fallback: return the test input unchanged.
    ;   Rule = identity,
        TestAfter = TestBefore
    ).
