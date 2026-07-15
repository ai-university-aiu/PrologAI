% Module declaration: sym pack, Layer 75.
% Provides symmetry transforms and symmetry testing for grids.
% Useful for any task requiring spatial symmetry analysis
% (used in ARC-AGI-2 reasoning for historical reference).
:- module(symmetry_transform, [
    % symmetry_transform_reflect_h/2: reflect a grid left-right (horizontal flip).
    symmetry_transform_reflect_h/2,
    % symmetry_transform_reflect_v/2: reflect a grid top-bottom (vertical flip).
    symmetry_transform_reflect_v/2,
    % symmetry_transform_transpose/2: reflect across the main diagonal (swap rows and columns).
    symmetry_transform_transpose/2,
    % symmetry_transform_rotate90/2: rotate 90 degrees clockwise.
    symmetry_transform_rotate90/2,
    % symmetry_transform_rotate180/2: rotate 180 degrees.
    symmetry_transform_rotate180/2,
    % symmetry_transform_rotate270/2: rotate 270 degrees clockwise (= 90 counter-clockwise).
    symmetry_transform_rotate270/2,
    % symmetry_transform_has_h_symm/1: succeed if the grid is symmetric left-right.
    symmetry_transform_has_h_symm/1,
    % symmetry_transform_has_v_symm/1: succeed if the grid is symmetric top-bottom.
    symmetry_transform_has_v_symm/1,
    % symmetry_transform_has_rot2_symm/1: succeed if the grid has 2-fold rotational symmetry.
    symmetry_transform_has_rot2_symm/1,
    % symmetry_transform_has_rot4_symm/1: succeed if the grid has 4-fold rotational symmetry.
    symmetry_transform_has_rot4_symm/1,
    % symmetry_transform_symmetries/2: list all symmetries present in a grid.
    symmetry_transform_symmetries/2,
    % symmetry_transform_make_h_symm/2: make a grid horizontally symmetric by mirroring the left half.
    symmetry_transform_make_h_symm/2,
    % symmetry_transform_make_v_symm/2: make a grid vertically symmetric by mirroring the top half.
    symmetry_transform_make_v_symm/2,
    % symmetry_transform_d4_orbit/2: compute all distinct D4 transforms of a grid.
    symmetry_transform_d4_orbit/2
]).

% Import list utilities; msort/length/forall are built-ins, not imported.
:- use_module(library(lists), [member/2, append/3, numlist/3, reverse/2]).
% Import higher-order apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% symmetry_transform_reflect_h(+Grid, -Grid2).
% Grid2 is Grid with each row reversed (left-right mirror).
symmetry_transform_reflect_h(Grid, Grid2) :-
    % Reverse each row independently.
    maplist(reverse, Grid, Grid2).

% symmetry_transform_reflect_v(+Grid, -Grid2).
% Grid2 is Grid with the row order reversed (top-bottom mirror).
symmetry_transform_reflect_v(Grid, Grid2) :-
    % Reverse the list of rows.
    reverse(Grid, Grid2).

% symmetry_transform_transpose(+Grid, -Grid2).
% Grid2 is Grid reflected across the main diagonal (rows become columns).
% For an empty grid or empty rows, returns the empty grid.
symmetry_transform_transpose([], []) :- !.
symmetry_transform_transpose(Grid, Grid2) :-
    % Get column count from the first row.
    Grid = [FR|_],
    length(FR, Cols),
    % Extract each column as a new row.
    Cols > 0,
    ColsM1 is Cols - 1,
    numlist(0, ColsM1, ColIdxs),
    maplist(symmetry_transform_extract_col_(Grid), ColIdxs, Grid2).

% symmetry_transform_extract_col_(+Grid, +ColIdx, -Row): build one row of the transpose.
symmetry_transform_extract_col_(Grid, ColIdx, Row) :-
    % For each grid row, pick the cell at ColIdx.
    maplist([GRow, V]>>(nth0(ColIdx, GRow, V)), Grid, Row).

% symmetry_transform_rotate90(+Grid, -Grid2).
% Grid2 is Grid rotated 90 degrees clockwise.
% Implemented as transpose followed by horizontal reflection.
symmetry_transform_rotate90(Grid, Grid2) :-
    symmetry_transform_transpose(Grid, T),
    symmetry_transform_reflect_h(T, Grid2).

% symmetry_transform_rotate180(+Grid, -Grid2).
% Grid2 is Grid rotated 180 degrees.
% Implemented as vertical reflection followed by horizontal reflection.
symmetry_transform_rotate180(Grid, Grid2) :-
    symmetry_transform_reflect_v(Grid, V),
    symmetry_transform_reflect_h(V, Grid2).

% symmetry_transform_rotate270(+Grid, -Grid2).
% Grid2 is Grid rotated 270 degrees clockwise (= 90 degrees counter-clockwise).
% Implemented as horizontal reflection followed by transpose.
symmetry_transform_rotate270(Grid, Grid2) :-
    symmetry_transform_reflect_h(Grid, H),
    symmetry_transform_transpose(H, Grid2).

% symmetry_transform_has_h_symm(+Grid).
% Succeed if Grid is identical to its horizontal reflection (left-right mirror).
symmetry_transform_has_h_symm(Grid) :-
    symmetry_transform_reflect_h(Grid, Grid).

% symmetry_transform_has_v_symm(+Grid).
% Succeed if Grid is identical to its vertical reflection (top-bottom mirror).
symmetry_transform_has_v_symm(Grid) :-
    symmetry_transform_reflect_v(Grid, Grid).

% symmetry_transform_has_rot2_symm(+Grid).
% Succeed if Grid is identical after 180-degree rotation (2-fold symmetry).
symmetry_transform_has_rot2_symm(Grid) :-
    symmetry_transform_rotate180(Grid, Grid).

% symmetry_transform_has_rot4_symm(+Grid).
% Succeed if Grid is identical after 90-degree rotation (4-fold symmetry).
% Only possible for square grids.
symmetry_transform_has_rot4_symm(Grid) :-
    symmetry_transform_rotate90(Grid, Grid).

% symmetry_transform_symmetries(+Grid, -Symms).
% Symms is the list of symmetry names present in Grid.
% Names: h (horizontal), v (vertical), rot2 (2-fold), rot4 (4-fold).
symmetry_transform_symmetries(Grid, Symms) :-
    findall(S, symmetry_transform_symmetry_name_(Grid, S), Symms).

% symmetry_transform_symmetry_name_(+Grid, -Name): enumerate symmetries via backtracking.
symmetry_transform_symmetry_name_(Grid, h)    :- symmetry_transform_has_h_symm(Grid).
symmetry_transform_symmetry_name_(Grid, v)    :- symmetry_transform_has_v_symm(Grid).
symmetry_transform_symmetry_name_(Grid, rot2) :- symmetry_transform_has_rot2_symm(Grid).
symmetry_transform_symmetry_name_(Grid, rot4) :- symmetry_transform_has_rot4_symm(Grid).

% symmetry_transform_make_h_symm(+Grid, -Grid2).
% Grid2 is Grid made horizontally symmetric by mirroring the left half to the right.
% For even-width rows: [L1,L2 | L2,L1]. For odd-width: [L1,L2,C | L2,L1].
symmetry_transform_make_h_symm(Grid, Grid2) :-
    maplist(symmetry_transform_symm_row_h_, Grid, Grid2).

% symmetry_transform_symm_row_h_(+Row, -Row2): make one row horizontally symmetric.
symmetry_transform_symm_row_h_(Row, Row2) :-
    % Split into left half and remainder.
    length(Row, N),
    Half is N // 2,
    length(Left, Half),
    append(Left, Rest, Row),
    % Mirror the left half.
    reverse(Left, RLeft),
    % Assemble: for odd N keep the center element.
    ( N mod 2 =:= 1 ->
        Rest = [Mid|_],
        append(Left, [Mid|RLeft], Row2)
    ;   append(Left, RLeft, Row2)
    ).

% symmetry_transform_make_v_symm(+Grid, -Grid2).
% Grid2 is Grid made vertically symmetric by mirroring the top half to the bottom.
% For even-height: top rows then reversed top rows.
% For odd-height: top rows, center row, then reversed top rows.
symmetry_transform_make_v_symm(Grid, Grid2) :-
    % Split into top half and remainder.
    length(Grid, N),
    Half is N // 2,
    length(Top, Half),
    append(Top, Rest, Grid),
    % Mirror the top half.
    reverse(Top, RTop),
    % Assemble.
    ( N mod 2 =:= 1 ->
        Rest = [Mid|_],
        append(Top, [Mid|RTop], Grid2)
    ;   append(Top, RTop, Grid2)
    ).

% symmetry_transform_d4_orbit(+Grid, -Orbit).
% Orbit is the sorted list of all distinct grids reachable by D4 transforms.
% D4 = {identity, rot90, rot180, rot270, reflect_h, reflect_v,
%        transpose, anti-diagonal reflection}.
% For non-square grids some transforms change dimensions; all are included.
symmetry_transform_d4_orbit(Grid, Orbit) :-
    % Compute all 8 D4 group elements.
    symmetry_transform_rotate90(Grid, R90),
    symmetry_transform_rotate180(Grid, R180),
    symmetry_transform_rotate270(Grid, R270),
    symmetry_transform_reflect_h(Grid, RH),
    symmetry_transform_reflect_v(Grid, RV),
    symmetry_transform_transpose(Grid, T),
    % Anti-diagonal reflection = rotate90 then reflect_v.
    symmetry_transform_reflect_v(R90, RA),
    % Deduplicate with sort (equal grids become one entry).
    sort([Grid, R90, R180, R270, RH, RV, T, RA], Orbit).
