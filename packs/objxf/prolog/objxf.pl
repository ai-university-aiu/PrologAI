% objxf.pl - Layer 163: Spatial and Color Transformations for obj(Color, Cells) Terms
%             (ox_* prefix).
% General-purpose predicates that transform individual obj(Color, Cells) terms.
% "Cells" is a list of r(Row, Col) coordinates. All operations preserve the Color
% field unless explicitly replacing it (ox_recolor). Transformations include:
% bounding box queries, translation, normalization to origin, rotation (90/180/270),
% reflection (horizontal/vertical), color replacement, cell-set algebra (merge,
% difference, intersection), and integer scale-up.
:- module(objxf, [
    ox_bbox/5,
    ox_size/3,
    ox_translate/4,
    ox_to_origin/2,
    ox_recolor/3,
    ox_rot90/2,
    ox_rot180/2,
    ox_rot270/2,
    ox_reflect_h/2,
    ox_reflect_v/2,
    ox_merge/3,
    ox_diff/3,
    ox_intersect/3,
    ox_scale_up/3
]).
% min_list/2 and max_list/2 and member/2 are from library(lists); sort/2 is built-in.
:- use_module(library(lists), [member/2, min_list/2, max_list/2]).

% ox_bbox(+Obj, -R0, -C0, -R1, -C1): bounding box of Obj's cells.
% R0=min row, C0=min col, R1=max row, C1=max col.
ox_bbox(obj(_, Cells), R0, C0, R1, C1) :-
% Collect all row indices from r(R,C) cell terms.
    findall(R, member(r(R,_), Cells), Rs),
% Collect all column indices.
    findall(C, member(r(_,C), Cells), Cs),
% Compute min and max for both axes.
    min_list(Rs, R0), max_list(Rs, R1),
    min_list(Cs, C0), max_list(Cs, C1).

% ox_size(+Obj, -H, -W): bounding box dimensions.
% H = height (number of rows), W = width (number of columns).
ox_size(Obj, H, W) :-
% Compute bounding box then derive H and W from extents.
    ox_bbox(Obj, R0, C0, R1, C1),
    H is R1 - R0 + 1,
    W is C1 - C0 + 1.

% ox_translate(+Obj, +DR, +DC, -Result): shift all cells by (DR, DC).
% DR is the row delta; DC is the column delta. May be negative.
ox_translate(obj(Color, Cells), DR, DC, obj(Color, Shifted)) :-
% Add DR to every row and DC to every column in each cell.
    findall(r(NR, NC),
            (member(r(R, C), Cells), NR is R + DR, NC is C + DC),
            Shifted).

% ox_to_origin(+Obj, -Result): shift so the topmost row = 0 and leftmost col = 0.
% The object's bounding box is anchored at r(0,0) in the result.
ox_to_origin(Obj, Result) :-
% Find the current minimum row and column.
    ox_bbox(Obj, R0, C0, _, _),
% Translate by negated minimums to bring the anchor to the origin.
    ox_translate(Obj, -R0, -C0, Result).

% ox_recolor(+Obj, +NewColor, -Result): replace the color field with NewColor.
% Cells are unchanged.
ox_recolor(obj(_, Cells), NewColor, obj(NewColor, Cells)).

% ox_rot90(+Obj, -Result): rotate Obj 90 degrees clockwise within its bounding box.
% Each cell r(R,C) -> r(R0 + Lc, C0 + (H-1) - Lr) where Lr = R-R0, Lc = C-C0.
% After rotation the bounding box is W x H (dimensions swap).
ox_rot90(obj(Color, Cells), obj(Color, Rotated)) :-
% Compute the bounding box to determine rotation parameters.
    findall(R, member(r(R,_), Cells), Rs), min_list(Rs, R0), max_list(Rs, R1),
    findall(C, member(r(_,C), Cells), Cs), min_list(Cs, C0),
% H is the height of the bounding box; drives the column offset after rotation.
    H is R1 - R0 + 1,
% Apply 90 CW rotation formula: local row becomes local col, local col maps to (H-1)-local_row.
    findall(r(NR, NC),
            (member(r(R, C), Cells),
             Lr is R - R0, Lc is C - C0,
             NR is R0 + Lc, NC is C0 + (H - 1) - Lr),
            Rotated).

% ox_rot180(+Obj, -Result): rotate Obj 180 degrees within its bounding box.
% Each cell r(R,C) -> r(R0+R1-R, C0+C1-C). Bounding box dimensions unchanged.
ox_rot180(obj(Color, Cells), obj(Color, Rotated)) :-
% Compute full bounding box for both axes.
    findall(R, member(r(R,_), Cells), Rs), min_list(Rs, R0), max_list(Rs, R1),
    findall(C, member(r(_,C), Cells), Cs), min_list(Cs, C0), max_list(Cs, C1),
% 180 rotation maps each cell to its diagonally opposite point in the bbox.
    findall(r(NR, NC),
            (member(r(R, C), Cells), NR is R0 + R1 - R, NC is C0 + C1 - C),
            Rotated).

% ox_rot270(+Obj, -Result): rotate Obj 270 degrees clockwise (= 90 degrees CCW).
% Each cell r(R,C) -> r(R0+(W-1)-Lc, C0+Lr) where Lr = R-R0, Lc = C-C0.
% After rotation the bounding box is W x H (dimensions swap).
ox_rot270(obj(Color, Cells), obj(Color, Rotated)) :-
% Compute bounding box; W drives the row offset after rotation.
    findall(R, member(r(R,_), Cells), Rs), min_list(Rs, R0),
    findall(C, member(r(_,C), Cells), Cs), min_list(Cs, C0), max_list(Cs, C1),
    W is C1 - C0 + 1,
% Apply 270 CW rotation formula: local col maps to (W-1)-lc in new row; local row becomes new col.
    findall(r(NR, NC),
            (member(r(R, C), Cells),
             Lr is R - R0, Lc is C - C0,
             NR is R0 + (W - 1) - Lc, NC is C0 + Lr),
            Rotated).

% ox_reflect_h(+Obj, -Result): reflect horizontally (flip upside-down) within the bounding box.
% Each cell r(R,C) -> r(R0+H-1-(R-R0), C) = r(R0+R1-R, C). Columns unchanged.
ox_reflect_h(obj(Color, Cells), obj(Color, Reflected)) :-
% Need the min and max row to compute the flip axis.
    findall(R, member(r(R,_), Cells), Rs), min_list(Rs, R0), max_list(Rs, R1),
% Mirror each row about the horizontal midpoint of the bounding box.
    findall(r(NR, C),
            (member(r(R, C), Cells), NR is R0 + R1 - R),
            Reflected).

% ox_reflect_v(+Obj, -Result): reflect vertically (flip left-right) within the bounding box.
% Each cell r(R,C) -> r(R, C0+W-1-(C-C0)) = r(R, C0+C1-C). Rows unchanged.
ox_reflect_v(obj(Color, Cells), obj(Color, Reflected)) :-
% Need the min and max column to compute the flip axis.
    findall(C, member(r(_,C), Cells), Cs), min_list(Cs, C0), max_list(Cs, C1),
% Mirror each column about the vertical midpoint of the bounding box.
    findall(r(R, NC),
            (member(r(R, C), Cells), NC is C0 + C1 - C),
            Reflected).

% ox_merge(+Obj1, +Obj2, -Result): merge two objects into one.
% Result has Obj1's color. Cells = sorted union of both cell lists (deduplication via sort/2).
ox_merge(obj(Color, Cells1), obj(_, Cells2), obj(Color, Merged)) :-
% Concatenate both cell lists then sort/2 deduplicates and orders canonically.
    append(Cells1, Cells2, All),
    sort(All, Merged).

% ox_diff(+Obj1, +Obj2, -Result): set difference of Obj1 minus Obj2 cells.
% Result has Obj1's color. Cells = cells in Obj1 not present in Obj2.
ox_diff(obj(Color, Cells1), obj(_, Cells2), obj(Color, Diff)) :-
% Keep only cells from Obj1 that are not in Obj2.
    findall(r(R, C), (member(r(R, C), Cells1), \+ member(r(R, C), Cells2)), Diff).

% ox_intersect(+Obj1, +Obj2, -Result): intersection of Obj1 and Obj2 cells.
% Result has Obj1's color. Cells = cells present in both Obj1 and Obj2.
ox_intersect(obj(Color, Cells1), obj(_, Cells2), obj(Color, Intersection)) :-
% Keep only cells from Obj1 that also appear in Obj2.
    findall(r(R, C), (member(r(R, C), Cells1), member(r(R, C), Cells2)), Intersection).

% ox_scale_up(+Obj, +Factor, -Result): scale Obj by a positive integer Factor.
% Each cell r(R,C) expands to a Factor x Factor block of cells.
% r(R,C) -> {r(R*F+DR, C*F+DC) | DR in [0,F-1], DC in [0,F-1]}.
ox_scale_up(obj(Color, Cells), Factor, obj(Color, Scaled)) :-
% Factor must be a positive integer.
    Factor > 0,
% Precompute the maximum offset for between/3.
    Fmax is Factor - 1,
% Expand each cell to a Factor x Factor block using between/3 for each offset.
    findall(r(NR, NC),
            (member(r(R, C), Cells),
             between(0, Fmax, DR), between(0, Fmax, DC),
             NR is R * Factor + DR, NC is C * Factor + DC),
            Scaled).
