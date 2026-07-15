% Module shape: normalized shape extraction, comparison, transformation, and placement.
% Layer 46. Prefix: sh_. Depends on grid pack only.
% A shape is a sorted list of r(R,C) cells with min(R)=0 and min(C)=0.
:- module(shape, [
    % Build a normalized shape from a raw list of r(R,C) cells.
    shape_from_cells/2,
    % Extract all cells of a given color from a grid and normalize to a shape.
    shape_from_grid/3,
    % Number of cells in a shape.
    shape_area/2,
    % Bounding box size (Rows x Cols) of a shape.
    shape_bounding_size/3,
    % Test whether a cell r(R,C) is a member of a shape.
    shape_contains_cell/2,
    % Test whether two shapes are identical.
    shape_equal/2,
    % Translate all cells of a shape by (DR, DC) without renormalizing.
    shape_translate/4,
    % Rotate a shape 90 degrees clockwise, then renormalize.
    shape_rotate90/2,
    % Reflect a shape horizontally (flip columns), then renormalize.
    shape_reflect_h/2,
    % Reflect a shape vertically (flip rows), then renormalize.
    shape_reflect_v/2,
    % All distinct D4 orientations of a shape (1 to 8 elements).
    shape_orbit/2,
    % Lexicographically smallest element of the D4 orbit.
    shape_canonical/2,
    % Succeed if two shapes have the same D4 canonical form.
    shape_equivalent/2,
    % Place a shape on a grid at offset (DR,DC) with a given color.
    shape_to_grid/6
]).

% Load list utilities.
:- use_module(library(lists), [member/2, max_member/2, min_member/2,
                                max_list/2, min_list/2, append/2, append/3]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, exclude/3]).
% Load grid pack.
:- use_module(library(grid)).

% shape_row_(+Cell, -R)
% Extract the row index from a r(R,C) cell.
shape_row_(r(R,_), R).

% shape_col_(+Cell, -C)
% Extract the column index from a r(R,C) cell.
shape_col_(r(_,C), C).

% shape_translate_cell_(+MinR, +MinC, +Cell, -Cell2)
% Subtract (MinR, MinC) from a cell to shift it toward the origin.
shape_translate_cell_(MinR, MinC, r(R,C), r(R2,C2)) :-
    R2 is R - MinR,
    C2 is C - MinC.

% shape_from_cells(+Cells, -Shape)
% Shape is the normalized (origin-translated, sorted) form of Cells.
% Normalization translates so that min row = 0 and min col = 0.
shape_from_cells(Cells, Shape) :-
    Cells = [_|_],
    maplist(shape_row_, Cells, Rs),
    maplist(shape_col_, Cells, Cs),
    min_list(Rs, MinR),
    min_list(Cs, MinC),
    maplist(shape_translate_cell_(MinR, MinC), Cells, Shifted),
    msort(Shifted, Shape).

% shape_from_grid(+Grid, +Color, -Shape)
% Extract all cells of Color from Grid and normalize to a shape.
shape_from_grid(Grid, Color, Shape) :-
    grid_size(Grid, Rows, Cols),
    R1 is Rows - 1,
    C1 is Cols - 1,
    findall(r(R,C),
        (   between(0, R1, R),
            between(0, C1, C),
            grid_cell(Grid, R, C, Color)
        ),
        Cells),
    Cells = [_|_],
    shape_from_cells(Cells, Shape).

% shape_area(+Shape, -N)
% N is the number of cells in Shape.
shape_area(Shape, N) :-
    length(Shape, N).

% shape_bounding_size(+Shape, -Rows, -Cols)
% Rows x Cols is the bounding box of Shape.
% Because Shape is normalized (min R = 0, min C = 0), Rows = max R + 1.
shape_bounding_size(Shape, Rows, Cols) :-
    Shape = [_|_],
    maplist(shape_row_, Shape, Rs),
    maplist(shape_col_, Shape, Cs),
    max_list(Rs, MaxR),
    max_list(Cs, MaxC),
    Rows is MaxR + 1,
    Cols is MaxC + 1.

% shape_contains_cell(+Shape, +Cell)
% Succeed if Cell r(R,C) is a member of Shape.
shape_contains_cell(Shape, Cell) :-
    member(Cell, Shape),
    !.

% shape_equal(+Shape1, +Shape2)
% Succeed if Shape1 and Shape2 are identical normalized shapes.
shape_equal(Shape, Shape).

% shape_shift_cell_(+DR, +DC, +Cell, -Cell2)
% Add (DR, DC) to a cell.
shape_shift_cell_(DR, DC, r(R,C), r(R2,C2)) :-
    R2 is R + DR,
    C2 is C + DC.

% shape_translate(+Shape, +DR, +DC, -Shape2)
% Add (DR, DC) offset to all cells in Shape. Does NOT renormalize.
shape_translate(Shape, DR, DC, Shape2) :-
    maplist(shape_shift_cell_(DR, DC), Shape, Shape2).

% shape_rot90_cell_(+MaxR, +Cell, -Cell2)
% Apply 90-degree CW rotation to one cell: r(R,C) -> r(C, MaxR-R).
shape_rot90_cell_(MaxR, r(R,C), r(C,R2)) :-
    R2 is MaxR - R.

% shape_rotate90(+Shape, -Shape2)
% Rotate Shape 90 degrees clockwise, then renormalize.
shape_rotate90(Shape, Shape2) :-
    Shape = [_|_],
    maplist(shape_row_, Shape, Rs),
    max_list(Rs, MaxR),
    maplist(shape_rot90_cell_(MaxR), Shape, Rotated),
    shape_from_cells(Rotated, Shape2).

% shape_refh_cell_(+MaxC, +Cell, -Cell2)
% Apply horizontal reflection to one cell: r(R,C) -> r(R, MaxC-C).
shape_refh_cell_(MaxC, r(R,C), r(R,C2)) :-
    C2 is MaxC - C.

% shape_reflect_h(+Shape, -Shape2)
% Reflect Shape horizontally (flip columns), then renormalize.
shape_reflect_h(Shape, Shape2) :-
    Shape = [_|_],
    maplist(shape_col_, Shape, Cs),
    max_list(Cs, MaxC),
    maplist(shape_refh_cell_(MaxC), Shape, Reflected),
    shape_from_cells(Reflected, Shape2).

% shape_refv_cell_(+MaxR, +Cell, -Cell2)
% Apply vertical reflection to one cell: r(R,C) -> r(MaxR-R, C).
shape_refv_cell_(MaxR, r(R,C), r(R2,C)) :-
    R2 is MaxR - R.

% shape_reflect_v(+Shape, -Shape2)
% Reflect Shape vertically (flip rows), then renormalize.
shape_reflect_v(Shape, Shape2) :-
    Shape = [_|_],
    maplist(shape_row_, Shape, Rs),
    max_list(Rs, MaxR),
    maplist(shape_refv_cell_(MaxR), Shape, Reflected),
    shape_from_cells(Reflected, Shape2).

% shape_orbit_rotations_(+Shape, -Rotations)
% Collect all four rotations (0, 90, 180, 270) of Shape.
shape_orbit_rotations_(S, [S, R90, R180, R270]) :-
    shape_rotate90(S, R90),
    shape_rotate90(R90, R180),
    shape_rotate90(R180, R270).

% shape_shape_neq_(+A, +B)
% Succeed if shapes A and B are NOT identical. Used with exclude.
shape_shape_neq_(A, B) :- A == B.

% shape_unique_shapes_(+Shapes, -Unique)
% Remove duplicate shapes from a list, preserving order of first occurrence.
shape_unique_shapes_([], []).
shape_unique_shapes_([H|T], [H|Uniq]) :-
    exclude(shape_shape_neq_(H), T, T2),
    shape_unique_shapes_(T2, Uniq).

% shape_orbit(+Shape, -Orbit)
% Orbit is the list of distinct D4 orientations of Shape.
shape_orbit(Shape, Orbit) :-
    shape_reflect_h(Shape, HFlip),
    shape_orbit_rotations_(Shape, Rs1),
    shape_orbit_rotations_(HFlip, Rs2),
    append(Rs1, Rs2, All),
    shape_unique_shapes_(All, Orbit).

% shape_canonical(+Shape, -Canon)
% Canon is the lex-min element of the D4 orbit of Shape.
shape_canonical(Shape, Canon) :-
    shape_orbit(Shape, Orbit),
    min_member(Canon, Orbit).

% shape_equivalent(+Shape1, +Shape2)
% Succeed if Shape1 and Shape2 have the same D4 canonical form.
shape_equivalent(Shape1, Shape2) :-
    shape_canonical(Shape1, C1),
    shape_canonical(Shape2, C2),
    C1 == C2.

% shape_to_grid(+Shape, +DR, +DC, +Color, +Grid, -Grid2)
% Place each cell of Shape on Grid at offset (DR, DC) with Color.
shape_to_grid([], _DR, _DC, _Color, Grid, Grid).
shape_to_grid([r(R,C)|T], DR, DC, Color, Grid, Grid2) :-
    R2 is R + DR,
    C2 is C + DC,
    grid_set_cell(Grid, R2, C2, Color, Grid1),
    shape_to_grid(T, DR, DC, Color, Grid1, Grid2).
