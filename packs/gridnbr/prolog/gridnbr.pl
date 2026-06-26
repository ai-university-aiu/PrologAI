:- module(gridnbr, [
    gn_nbr4/4,
    gn_nbr8/4,
    gn_count4/5,
    gn_count8/5,
    gn_count4_grid/3,
    gn_count8_grid/3,
    gn_any4/4,
    gn_all4/4,
    gn_mark_border/3,
    gn_mark_isolated/3,
    gn_expand_color/3,
    gn_shrink_color/3,
    gn_majority_nbr4/4,
    gn_conway_step/4
]).
% gridnbr.pl - Layer 199: Grid Neighbor Analysis (gn_* prefix).
% All predicates operate on raw grid format: list of rows, each a list of
% color atoms, 0-indexed (row 0 = top, col 0 = left).
% Neighbor queries use the grid boundary as the limit; out-of-bounds positions
% are simply omitted from the neighbor list (they do not contribute a value).
:- use_module(library(lists), [
    member/2, memberchk/2, nth0/3, append/3, list_to_set/2
]).
:- use_module(library(apply), [maplist/3]).

% --- PRIVATE HELPERS ---

% Get H (rows) and W (cols) of a raw grid.
gn_dims_(Grid, H, W) :-
% Bind H to row count.
    length(Grid, H),
% Bind W to column count of the first row; W=0 if empty.
    (H > 0 -> Grid = [Row|_], length(Row, W) ; W = 0).

% Succeed iff position (R,C) is within an H-by-W grid.
gn_in_bounds_(R, C, H, W) :-
% Check row and column bounds.
    R >= 0, R < H, C >= 0, C < W.

% Read the cell value at (R,C) from Grid.
gn_cell_(Grid, R, C, V) :-
% Access row then cell.
    nth0(R, Grid, Row),
    nth0(C, Row, V).

% Write value V at (R,C) in Grid, returning NewGrid.
gn_set_cell_(Grid, R, C, V, NewGrid) :-
% Get dimensions.
    gn_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Rebuild the grid row by row, cell by cell.
    findall(NewRow,
        (between(0, H1, R2),
         findall(NV,
             (between(0, W1, C2),
              gn_cell_(Grid, R2, C2, OldV),
              (R2 =:= R, C2 =:= C -> NV = V ; NV = OldV)),
             NewRow)),
        NewGrid).

% The four 4-connected deltas: up, down, left, right.
gn_delta4_([-1,0]).
gn_delta4_([1,0]).
gn_delta4_([0,-1]).
gn_delta4_([0,1]).

% The eight 8-connected deltas: cardinal + diagonal.
gn_delta8_([-1,-1]).
gn_delta8_([-1, 0]).
gn_delta8_([-1, 1]).
gn_delta8_([ 0,-1]).
gn_delta8_([ 0, 1]).
gn_delta8_([ 1,-1]).
gn_delta8_([ 1, 0]).
gn_delta8_([ 1, 1]).

% Collect neighbor values using a delta predicate.
gn_nbrs_(Grid, R, C, DeltaPred, Vals) :-
% Get grid dimensions.
    gn_dims_(Grid, H, W),
% For each delta, check bounds and read cell value.
    findall(V,
        (call(DeltaPred, [DR, DC]),
         R2 is R + DR,
         C2 is C + DC,
         gn_in_bounds_(R2, C2, H, W),
         gn_cell_(Grid, R2, C2, V)),
        Vals).

% Count occurrences of Value in a list.
gn_count_val_([], _, 0).
gn_count_val_([H|T], V, N) :-
% Increment if head matches value.
    gn_count_val_(T, V, N0),
    (H = V -> N is N0 + 1 ; N = N0).

% Find the most frequent value in a list; fail on empty list.
gn_majority_val_(Vals, Maj) :-
% Require non-empty.
    Vals \= [],
% Get distinct values.
    list_to_set(Vals, Distinct),
% Build NegCount-Val pairs for sort.
    findall(NegN-Val,
        (member(Val, Distinct),
         gn_count_val_(Vals, Val, N),
         NegN is -N),
        Keyed),
% Sort ascending by negative count; head has most frequent value.
    msort(Keyed, [_-Maj | _]).

% --- EXPORTED PREDICATES ---

% gn_nbr4(+Grid, +R, +C, -Vals)
% Vals is the list of cell values at 4-connected neighbors of (R,C).
% Out-of-bounds positions are omitted; list length is 2, 3, or 4.
gn_nbr4(Grid, R, C, Vals) :-
% Collect values from four cardinal directions.
    gn_nbrs_(Grid, R, C, gn_delta4_, Vals).

% gn_nbr8(+Grid, +R, +C, -Vals)
% Vals is the list of cell values at 8-connected neighbors of (R,C).
% Out-of-bounds positions are omitted; list length is 3, 5, or 8.
gn_nbr8(Grid, R, C, Vals) :-
% Collect values from all eight directions.
    gn_nbrs_(Grid, R, C, gn_delta8_, Vals).

% gn_count4(+Grid, +R, +C, +Color, -N)
% N is the count of 4-connected neighbors of (R,C) whose value equals Color.
gn_count4(Grid, R, C, Color, N) :-
% Get 4-neighbor values then count matches.
    gn_nbr4(Grid, R, C, Vals),
    gn_count_val_(Vals, Color, N).

% gn_count8(+Grid, +R, +C, +Color, -N)
% N is the count of 8-connected neighbors of (R,C) whose value equals Color.
gn_count8(Grid, R, C, Color, N) :-
% Get 8-neighbor values then count matches.
    gn_nbr8(Grid, R, C, Vals),
    gn_count_val_(Vals, Color, N).

% gn_count4_grid(+Grid, +Color, -CountGrid)
% CountGrid is a raw grid where each cell value is the count of Color
% in the 4-connected neighbors of that cell position.
gn_count4_grid(Grid, Color, CountGrid) :-
% Get dimensions.
    gn_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Build count grid row by row.
    findall(Row,
        (between(0, H1, R),
         findall(N,
             (between(0, W1, C),
              gn_count4(Grid, R, C, Color, N)),
             Row)),
        CountGrid).

% gn_count8_grid(+Grid, +Color, -CountGrid)
% CountGrid is a raw grid where each cell value is the count of Color
% in the 8-connected neighbors of that cell position.
gn_count8_grid(Grid, Color, CountGrid) :-
% Get dimensions.
    gn_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Build count grid row by row.
    findall(Row,
        (between(0, H1, R),
         findall(N,
             (between(0, W1, C),
              gn_count8(Grid, R, C, Color, N)),
             Row)),
        CountGrid).

% gn_any4(+Grid, +R, +C, +Color)
% Succeed if at least one 4-connected neighbor of (R,C) has value Color.
gn_any4(Grid, R, C, Color) :-
% Use memberchk to avoid choicepoints.
    gn_nbr4(Grid, R, C, Vals),
    memberchk(Color, Vals).

% gn_all4(+Grid, +R, +C, +Color)
% Succeed if every 4-connected neighbor of (R,C) has value Color.
% Vacuously false for a cell with no 4-neighbors (impossible in practice).
gn_all4(Grid, R, C, Color) :-
% All neighbors match; require at least one.
    gn_nbr4(Grid, R, C, Vals),
    Vals \= [],
    \+ (member(V, Vals), V \= Color).

% gn_mark_border(+Grid, +Bg, -MarkedGrid)
% MarkedGrid is Grid with every non-background cell that has at least one
% background 4-neighbor replaced by the atom border.
% All other cells are left unchanged.
gn_mark_border(Grid, Bg, MarkedGrid) :-
% Get dimensions.
    gn_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Rebuild grid: mark foreground cells touching the background.
    findall(Row,
        (between(0, H1, R),
         findall(NV,
             (between(0, W1, C),
              gn_cell_(Grid, R, C, V),
              (V \= Bg, gn_any4(Grid, R, C, Bg)
              -> NV = border
              ;  NV = V)),
             Row)),
        MarkedGrid).

% gn_mark_isolated(+Grid, +Bg, -MarkedGrid)
% MarkedGrid is Grid with every non-background cell that has NO same-color
% 4-neighbor replaced by the atom isolated.
% All other cells are left unchanged.
gn_mark_isolated(Grid, Bg, MarkedGrid) :-
% Get dimensions.
    gn_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Rebuild grid: mark non-background cells with no same-color 4-neighbor.
    findall(Row,
        (between(0, H1, R),
         findall(NV,
             (between(0, W1, C),
              gn_cell_(Grid, R, C, V),
              (V \= Bg, \+ gn_any4(Grid, R, C, V)
              -> NV = isolated
              ;  NV = V)),
             Row)),
        MarkedGrid).

% gn_expand_color(+Grid, +Color, -Expanded)
% Expanded is Grid with every background cell that has at least one Color
% 4-neighbor filled with Color (morphological dilation of Color regions).
% Background is defined as the most frequent color; Color cells stay as Color.
gn_expand_color(Grid, Color, Expanded) :-
% Find the background as the most frequent color.
    gn_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Collect all cell values to find background.
    findall(V,
        (between(0, H1, R2),
         between(0, W1, C2),
         gn_cell_(Grid, R2, C2, V)),
        Vals),
    list_to_set(Vals, Colors),
    findall(NegN-BgC,
        (member(BgC, Colors),
         gn_count_val_(Vals, BgC, N),
         NegN is -N),
        Keyed),
    msort(Keyed, [_-Bg | _]),
% Expand Color into background cells that neighbor Color.
    findall(Row,
        (between(0, H1, R),
         findall(NV,
             (between(0, W1, C),
              gn_cell_(Grid, R, C, V),
              (V = Bg, gn_any4(Grid, R, C, Color)
              -> NV = Color
              ;  NV = V)),
             Row)),
        Expanded).

% gn_shrink_color(+Grid, +Color, -Shrunk)
% Shrunk is Grid with every Color cell that has at least one non-Color
% 4-neighbor replaced by the background color (morphological erosion).
% Background is the most frequent color; it serves as the fill for eroded cells.
gn_shrink_color(Grid, Color, Shrunk) :-
% Find background.
    gn_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
    findall(V,
        (between(0, H1, R2),
         between(0, W1, C2),
         gn_cell_(Grid, R2, C2, V)),
        Vals),
    list_to_set(Vals, Colors),
    findall(NegN-BgC,
        (member(BgC, Colors),
         gn_count_val_(Vals, BgC, N),
         NegN is -N),
        Keyed),
    msort(Keyed, [_-Bg | _]),
% Erode Color: remove Color cells that touch a non-Color neighbor.
    findall(Row,
        (between(0, H1, R),
         findall(NV,
             (between(0, W1, C),
              gn_cell_(Grid, R, C, V),
              (V = Color,
               gn_nbr4(Grid, R, C, Nbrs),
               member(Other, Nbrs), Other \= Color
              -> NV = Bg
              ;  NV = V)),
             Row)),
        Shrunk).

% gn_majority_nbr4(+Grid, +R, +C, -Maj)
% Maj is the most frequently occurring color among the 4-connected neighbors
% of (R,C). Ties broken by standard term order (smallest atom wins). Fails
% if (R,C) has no 4-connected neighbors (unreachable for H>=1, W>=1).
gn_majority_nbr4(Grid, R, C, Maj) :-
% Get 4-neighbor values.
    gn_nbr4(Grid, R, C, Vals),
% Find the most frequent.
    gn_majority_val_(Vals, Maj).

% gn_conway_step(+Grid, +Color, +N, -NewGrid)
% NewGrid is Grid after one Conway-like step: every cell whose value equals
% Color and whose count of Color 4-neighbors equals exactly N is replaced
% by the background color. All other cells are unchanged.
% Background is the most frequent color. This models "cell dies if it has
% exactly N same-color neighbors."
gn_conway_step(Grid, Color, N, NewGrid) :-
% Find background.
    gn_dims_(Grid, H, W),
    H1 is H - 1,
    W1 is W - 1,
    findall(V,
        (between(0, H1, R2),
         between(0, W1, C2),
         gn_cell_(Grid, R2, C2, V)),
        Vals),
    list_to_set(Vals, Colors),
    findall(NegNV-BgC,
        (member(BgC, Colors),
         gn_count_val_(Vals, BgC, NV),
         NegNV is -NV),
        Keyed),
    msort(Keyed, [_-Bg | _]),
% Apply the rule: Color cells with exactly N Color 4-neighbors die to Bg.
    findall(Row,
        (between(0, H1, R),
         findall(NVal,
             (between(0, W1, C),
              gn_cell_(Grid, R, C, V),
              (V = Color,
               gn_count4(Grid, R, C, Color, CN),
               CN =:= N
              -> NVal = Bg
              ;  NVal = V)),
             Row)),
        NewGrid).
