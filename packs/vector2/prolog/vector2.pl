% vec2.pl - Layer 104: 2D Integer Vector Arithmetic and Geometry (vv_* prefix).
% Provides arithmetic and geometric operations on 2D displacement vectors
% represented as (DR, DC) pairs. Supports offset computation, addition,
% scaling, negation, magnitude in three norms, rotation by multiples of 90
% degrees, dot and cross products, parallelism testing, and region translation.
:- module(vector2, [
    vector2_offset/6,
    vector2_add/6,
    vector2_scale/5,
    vector2_neg/4,
    vector2_len_sq/3,
    vector2_manhattan/3,
    vector2_chebyshev/3,
    vector2_rot90_cw/4,
    vector2_rot90_ccw/4,
    vector2_rot180/4,
    vector2_dot/5,
    vector2_cross/5,
    vector2_parallel/4,
    vector2_translate_region/4
]).
% Import higher-order utilities for list transformation.
:- use_module(library(apply), [maplist/3]).

% vector2_offset(+R1, +C1, +R2, +C2, -DR, -DC): displacement vector from (R1,C1)
% to (R2,C2). DR = R2 - R1, DC = C2 - C1.
vector2_offset(R1, C1, R2, C2, DR, DC) :-
% Compute the row component of the displacement.
    DR is R2 - R1,
% Compute the column component of the displacement.
    DC is C2 - C1.

% vector2_add(+R, +C, +DR, +DC, -NR, -NC): apply vector (DR,DC) to point (R,C).
% NR = R + DR, NC = C + DC.
vector2_add(R, C, DR, DC, NR, NC) :-
% Translate the row coordinate.
    NR is R + DR,
% Translate the column coordinate.
    NC is C + DC.

% vector2_scale(+DR, +DC, +K, -SDR, -SDC): scale vector (DR,DC) by integer K.
% SDR = K * DR, SDC = K * DC.
vector2_scale(DR, DC, K, SDR, SDC) :-
% Scale the row component.
    SDR is K * DR,
% Scale the column component.
    SDC is K * DC.

% vector2_neg(+DR, +DC, -NDR, -NDC): negate a vector. NDR = -DR, NDC = -DC.
% The negation points in the opposite direction at the same magnitude.
vector2_neg(DR, DC, NDR, NDC) :-
% Negate the row component.
    NDR is -DR,
% Negate the column component.
    NDC is -DC.

% vector2_len_sq(+DR, +DC, -LSq): squared Euclidean length of a vector.
% LSq = DR^2 + DC^2. Integer arithmetic; avoids floating-point square root.
vector2_len_sq(DR, DC, LSq) :-
% Sum the squares of both components.
    LSq is DR * DR + DC * DC.

% vector2_manhattan(+DR, +DC, -M): L1 (Manhattan) magnitude of a vector.
% M = |DR| + |DC|.
vector2_manhattan(DR, DC, M) :-
% Sum the absolute values of both components.
    M is abs(DR) + abs(DC).

% vector2_chebyshev(+DR, +DC, -D): L-infinity (Chebyshev) magnitude of a vector.
% D = max(|DR|, |DC|). The number of king moves to travel this vector.
vector2_chebyshev(DR, DC, D) :-
% Take the maximum of the absolute row and column components.
    D is max(abs(DR), abs(DC)).

% vector2_rot90_cw(+DR, +DC, -RDR, -RDC): rotate vector 90 degrees clockwise.
% In row-column grid coordinates: RDR = DC, RDC = -DR.
vector2_rot90_cw(DR, DC, RDR, RDC) :-
% New row component is the old column component.
    RDR = DC,
% New column component is the negation of the old row component.
    RDC is -DR.

% vector2_rot90_ccw(+DR, +DC, -RDR, -RDC): rotate vector 90 degrees counter-clockwise.
% In row-column grid coordinates: RDR = -DC, RDC = DR.
vector2_rot90_ccw(DR, DC, RDR, RDC) :-
% New row component is the negation of the old column component.
    RDR is -DC,
% New column component is the old row component.
    RDC = DR.

% vector2_rot180(+DR, +DC, -RDR, -RDC): rotate vector 180 degrees.
% Equivalent to vector2_neg: RDR = -DR, RDC = -DC.
vector2_rot180(DR, DC, RDR, RDC) :-
% Negate both components.
    RDR is -DR,
% Negate the column component.
    RDC is -DC.

% vector2_dot(+DR1, +DC1, +DR2, +DC2, -D): dot product of two 2D vectors.
% D = DR1 * DR2 + DC1 * DC2.
% Positive when vectors point in the same general direction; zero when orthogonal.
vector2_dot(DR1, DC1, DR2, DC2, D) :-
% Compute and sum the products of corresponding components.
    D is DR1 * DR2 + DC1 * DC2.

% vector2_cross(+DR1, +DC1, +DR2, +DC2, -C): z-component of 2D cross product.
% C = DR1 * DC2 - DC1 * DR2.
% Positive if V2 is counter-clockwise from V1; negative if clockwise.
vector2_cross(DR1, DC1, DR2, DC2, C) :-
% Compute the 2D cross product as the determinant of the 2x2 matrix.
    C is DR1 * DC2 - DC1 * DR2.

% vector2_parallel(+DR1, +DC1, +DR2, +DC2): succeed if two vectors are parallel.
% Two vectors are parallel when their 2D cross product is zero.
vector2_parallel(DR1, DC1, DR2, DC2) :-
% Test that the cross product is zero.
    vector2_cross(DR1, DC1, DR2, DC2, C),
% Zero cross product means vectors are collinear.
    C =:= 0.

% vector2_translate_cell_: translate one R-C cell by a displacement (DR,DC).
vector2_translate_cell_(DR, DC, R-C, NR-NC) :-
% Add the displacement to the cell coordinates.
    NR is R + DR,
% Translate the column.
    NC is C + DC.

% vector2_translate_region(+Cells, +DR, +DC, -NewCells): translate a list of R-C
% cells by displacement vector (DR,DC). Each cell R-C becomes (R+DR)-(C+DC).
vector2_translate_region(Cells, DR, DC, NewCells) :-
% Apply the translation to every cell in the list.
    maplist(vector2_translate_cell_(DR, DC), Cells, NewCells).
