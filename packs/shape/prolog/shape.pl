% Module shape: normalized shape extraction, comparison, transformation, and placement.
% Layer 46. Prefix: sh_. Depends on grid pack only.
% A shape is a sorted list of r(R,C) cells with min(R)=0 and min(C)=0.
:- module(shape, [
    % Build a normalized shape from a raw list of r(R,C) cells.
    sh_from_cells/2,
    % Extract all cells of a given color from a grid and normalize to a shape.
    sh_from_grid/3,
    % Number of cells in a shape.
    sh_area/2,
    % Bounding box size (Rows x Cols) of a shape.
    sh_bounding_size/3,
    % Test whether a cell r(R,C) is a member of a shape.
    sh_contains_cell/2,
    % Test whether two shapes are identical.
    sh_equal/2,
    % Translate all cells of a shape by (DR, DC) without renormalizing.
    sh_translate/4,
    % Rotate a shape 90 degrees clockwise, then renormalize.
    sh_rotate90/2,
    % Reflect a shape horizontally (flip columns), then renormalize.
    sh_reflect_h/2,
    % Reflect a shape vertically (flip rows), then renormalize.
    sh_reflect_v/2,
    % All distinct D4 orientations of a shape (1 to 8 elements).
    sh_orbit/2,
    % Lexicographically smallest element of the D4 orbit.
    sh_canonical/2,
    % Succeed if two shapes have the same D4 canonical form.
    sh_equivalent/2,
    % Place a shape on a grid at offset (DR,DC) with a given color.
    sh_to_grid/6
]).

% Load list utilities.
:- use_module(library(lists), [member/2, max_member/2, min_member/2,
                                max_list/2, min_list/2, append/2, append/3]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, exclude/3]).
% Load grid pack.
:- use_module(library(grid)).

% sh_row_(+Cell, -R)
% Extract the row index from a r(R,C) cell.
sh_row_(r(R,_), R).

% sh_col_(+Cell, -C)
% Extract the column index from a r(R,C) cell.
sh_col_(r(_,C), C).

% sh_translate_cell_(+MinR, +MinC, +Cell, -Cell2)
% Subtract (MinR, MinC) from a cell to shift it toward the origin.
sh_translate_cell_(MinR, MinC, r(R,C), r(R2,C2)) :-
    R2 is R - MinR,
    C2 is C - MinC.

% sh_from_cells(+Cells, -Shape)
% Shape is the normalized (origin-translated, sorted) form of Cells.
% Normalization translates so that min row = 0 and min col = 0.
sh_from_cells(Cells, Shape) :-
    Cells = [_|_],
    maplist(sh_row_, Cells, Rs),
    maplist(sh_col_, Cells, Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC),
    maplist(sh_translate_cell_(MinR, MinC), Cells, Shifted),
    msort(Shifted, Shape).

% sh_from_grid(+Grid, +Color, -Shape)
% Extract all cells of Color from Grid and normalize to a shape.
sh_from_grid(Grid, Color, Shape) :-
    gd_size(Grid, Rows, Cols),
    R1 is Rows - 1,
    C1 is Cols - 1,
    findall(r(R,C),
        (   between(0, R1, R),
            between(0, C1, C),
            gd_cell(Grid, R, C, Color)
        ),
        Cells),
    Cells = [_|_],
    sh_from_cells(Cells, Shape).

% sh_area(+Shape, -N)
% N is the number of cells in Shape.
sh_area(Shape, N) :-
    length(Shape, N).

% sh_bounding_size(+Shape, -Rows, -Cols)
% Rows x Cols is the bounding box of Shape.
% Because Shape is normalized (min R = 0, min C = 0), Rows = max R + 1.
sh_bounding_size(Shape, Rows, Cols) :-
    Shape = [_|_],
    maplist(sh_row_, Shape, Rs),
    maplist(sh_col_, Shape, Cs),
    max_list(Rs, MaxR),
    max_list(Cs, MaxC),
    Rows is MaxR + 1,
    Cols is MaxC + 1.

% sh_contains_cell(+Shape, +Cell)
% Succeed if Cell r(R,C) is a member of Shape.
sh_contains_cell(Shape, Cell) :-
    member(Cell, Shape),
    !.

% sh_equal(+Shape1, +Shape2)
% Succeed if Shape1 and Shape2 are identical normalized shapes.
sh_equal(Shape, Shape).

% sh_shift_cell_(+DR, +DC, +Cell, -Cell2)
% Add (DR, DC) to a cell.
sh_shift_cell_(DR, DC, r(R,C), r(R2,C2)) :-
    R2 is R + DR,
    C2 is C + DC.

% sh_translate(+Shape, +DR, +DC, -Shape2)
% Add (DR, DC) offset to all cells in Shape. Does NOT renormalize.
sh_translate(Shape, DR, DC, Shape2) :-
    maplist(sh_shift_cell_(DR, DC), Shape, Shape2).

% sh_rot90_cell_(+MaxR, +Cell, -Cell2)
% Apply 90-degree CW rotation to one cell: r(R,C) -> r(C, MaxR-R).
sh_rot90_cell_(MaxR, r(R,C), r(C,R2)) :-
    R2 is MaxR - R.

% sh_rotate90(+Shape, -Shape2)
% Rotate Shape 90 degrees clockwise, then renormalize.
sh_rotate90(Shape, Shape2) :-
    Shape = [_|_],
    maplist(sh_row_, Shape, Rs),
    max_list(Rs, MaxR),
    maplist(sh_rot90_cell_(MaxR), Shape, Rotated),
    sh_from_cells(Rotated, Shape2).

% sh_refh_cell_(+MaxC, +Cell, -Cell2)
% Apply horizontal reflection to one cell: r(R,C) -> r(R, MaxC-C).
sh_refh_cell_(MaxC, r(R,C), r(R,C2)) :-
    C2 is MaxC - C.

% sh_reflect_h(+Shape, -Shape2)
% Reflect Shape horizontally (flip columns), then renormalize.
sh_reflect_h(Shape, Shape2) :-
    Shape = [_|_],
    maplist(sh_col_, Shape, Cs),
    max_list(Cs, MaxC),
    maplist(sh_refh_cell_(MaxC), Shape, Reflected),
    sh_from_cells(Reflected, Shape2).

% sh_refv_cell_(+MaxR, +Cell, -Cell2)
% Apply vertical reflection to one cell: r(R,C) -> r(MaxR-R, C).
sh_refv_cell_(MaxR, r(R,C), r(R2,C)) :-
    R2 is MaxR - R.

% sh_reflect_v(+Shape, -Shape2)
% Reflect Shape vertically (flip rows), then renormalize.
sh_reflect_v(Shape, Shape2) :-
    Shape = [_|_],
    maplist(sh_row_, Shape, Rs),
    max_list(Rs, MaxR),
    maplist(sh_refv_cell_(MaxR), Shape, Reflected),
    sh_from_cells(Reflected, Shape2).

% sh_orbit_rotations_(+Shape, -Rotations)
% Collect all four rotations (0, 90, 180, 270) of Shape.
sh_orbit_rotations_(S, [S, R90, R180, R270]) :-
    sh_rotate90(S, R90),
    sh_rotate90(R90, R180),
    sh_rotate90(R180, R270).

% sh_shape_neq_(+A, +B)
% Succeed if shapes A and B are NOT identical. Used with exclude.
sh_shape_neq_(A, B) :- A == B.

% sh_unique_shapes_(+Shapes, -Unique)
% Remove duplicate shapes from a list, preserving order of first occurrence.
sh_unique_shapes_([], []).
sh_unique_shapes_([H|T], [H|Uniq]) :-
    exclude(sh_shape_neq_(H), T, T2),
    sh_unique_shapes_(T2, Uniq).

% sh_orbit(+Shape, -Orbit)
% Orbit is the list of distinct D4 orientations of Shape.
sh_orbit(Shape, Orbit) :-
    sh_reflect_h(Shape, HFlip),
    sh_orbit_rotations_(Shape, Rs1),
    sh_orbit_rotations_(HFlip, Rs2),
    append(Rs1, Rs2, All),
    sh_unique_shapes_(All, Orbit).

% sh_canonical(+Shape, -Canon)
% Canon is the lex-min element of the D4 orbit of Shape.
sh_canonical(Shape, Canon) :-
    sh_orbit(Shape, Orbit),
    min_member(Canon, Orbit).

% sh_equivalent(+Shape1, +Shape2)
% Succeed if Shape1 and Shape2 have the same D4 canonical form.
sh_equivalent(Shape1, Shape2) :-
    sh_canonical(Shape1, C1),
    sh_canonical(Shape2, C2),
    C1 == C2.

% sh_to_grid(+Shape, +DR, +DC, +Color, +Grid, -Grid2)
% Place each cell of Shape on Grid at offset (DR, DC) with Color.
sh_to_grid([], _DR, _DC, _Color, Grid, Grid).
sh_to_grid([r(R,C)|T], DR, DC, Color, Grid, Grid2) :-
    R2 is R + DR,
    C2 is C + DC,
    gd_set_cell(Grid, R2, C2, Color, Grid1),
    sh_to_grid(T, DR, DC, Color, Grid1, Grid2).
