% vec2.pl - Layer 104: 2D Integer Vector Arithmetic and Geometry (vv_* prefix).
% Provides arithmetic and geometric operations on 2D displacement vectors
% represented as (DR, DC) pairs. Supports offset computation, addition,
% scaling, negation, magnitude in three norms, rotation by multiples of 90
% degrees, dot and cross products, parallelism testing, and region translation.
:- module(vec2, [
    vv_offset/6,
    vv_add/6,
    vv_scale/5,
    vv_neg/4,
    vv_len_sq/3,
    vv_manhattan/3,
    vv_chebyshev/3,
    vv_rot90_cw/4,
    vv_rot90_ccw/4,
    vv_rot180/4,
    vv_dot/5,
    vv_cross/5,
    vv_parallel/4,
    vv_translate_region/4
]).
% Import higher-order utilities for list transformation.
:- use_module(library(apply), [maplist/3]).

% vv_offset(+R1, +C1, +R2, +C2, -DR, -DC): displacement vector from (R1,C1)
% to (R2,C2). DR = R2 - R1, DC = C2 - C1.
vv_offset(R1, C1, R2, C2, DR, DC) :-
% Compute the row component of the displacement.
    DR is R2 - R1,
% Compute the column component of the displacement.
    DC is C2 - C1.

% vv_add(+R, +C, +DR, +DC, -NR, -NC): apply vector (DR,DC) to point (R,C).
% NR = R + DR, NC = C + DC.
vv_add(R, C, DR, DC, NR, NC) :-
% Translate the row coordinate.
    NR is R + DR,
% Translate the column coordinate.
    NC is C + DC.

% vv_scale(+DR, +DC, +K, -SDR, -SDC): scale vector (DR,DC) by integer K.
% SDR = K * DR, SDC = K * DC.
vv_scale(DR, DC, K, SDR, SDC) :-
% Scale the row component.
    SDR is K * DR,
% Scale the column component.
    SDC is K * DC.

% vv_neg(+DR, +DC, -NDR, -NDC): negate a vector. NDR = -DR, NDC = -DC.
% The negation points in the opposite direction at the same magnitude.
vv_neg(DR, DC, NDR, NDC) :-
% Negate the row component.
    NDR is -DR,
% Negate the column component.
    NDC is -DC.

% vv_len_sq(+DR, +DC, -LSq): squared Euclidean length of a vector.
% LSq = DR^2 + DC^2. Integer arithmetic; avoids floating-point square root.
vv_len_sq(DR, DC, LSq) :-
% Sum the squares of both components.
    LSq is DR * DR + DC * DC.

% vv_manhattan(+DR, +DC, -M): L1 (Manhattan) magnitude of a vector.
% M = |DR| + |DC|.
vv_manhattan(DR, DC, M) :-
% Sum the absolute values of both components.
    M is abs(DR) + abs(DC).

% vv_chebyshev(+DR, +DC, -D): L-infinity (Chebyshev) magnitude of a vector.
% D = max(|DR|, |DC|). The number of king moves to travel this vector.
vv_chebyshev(DR, DC, D) :-
% Take the maximum of the absolute row and column components.
    D is max(abs(DR), abs(DC)).

% vv_rot90_cw(+DR, +DC, -RDR, -RDC): rotate vector 90 degrees clockwise.
% In row-column grid coordinates: RDR = DC, RDC = -DR.
vv_rot90_cw(DR, DC, RDR, RDC) :-
% New row component is the old column component.
    RDR = DC,
% New column component is the negation of the old row component.
    RDC is -DR.

% vv_rot90_ccw(+DR, +DC, -RDR, -RDC): rotate vector 90 degrees counter-clockwise.
% In row-column grid coordinates: RDR = -DC, RDC = DR.
vv_rot90_ccw(DR, DC, RDR, RDC) :-
% New row component is the negation of the old column component.
    RDR is -DC,
% New column component is the old row component.
    RDC = DR.

% vv_rot180(+DR, +DC, -RDR, -RDC): rotate vector 180 degrees.
% Equivalent to vv_neg: RDR = -DR, RDC = -DC.
vv_rot180(DR, DC, RDR, RDC) :-
% Negate both components.
    RDR is -DR,
% Negate the column component.
    RDC is -DC.

% vv_dot(+DR1, +DC1, +DR2, +DC2, -D): dot product of two 2D vectors.
% D = DR1 * DR2 + DC1 * DC2.
% Positive when vectors point in the same general direction; zero when orthogonal.
vv_dot(DR1, DC1, DR2, DC2, D) :-
% Compute and sum the products of corresponding components.
    D is DR1 * DR2 + DC1 * DC2.

% vv_cross(+DR1, +DC1, +DR2, +DC2, -C): z-component of 2D cross product.
% C = DR1 * DC2 - DC1 * DR2.
% Positive if V2 is counter-clockwise from V1; negative if clockwise.
vv_cross(DR1, DC1, DR2, DC2, C) :-
% Compute the 2D cross product as the determinant of the 2x2 matrix.
    C is DR1 * DC2 - DC1 * DR2.

% vv_parallel(+DR1, +DC1, +DR2, +DC2): succeed if two vectors are parallel.
% Two vectors are parallel when their 2D cross product is zero.
vv_parallel(DR1, DC1, DR2, DC2) :-
% Test that the cross product is zero.
    vv_cross(DR1, DC1, DR2, DC2, C),
% Zero cross product means vectors are collinear.
    C =:= 0.

% vv_translate_cell_: translate one R-C cell by a displacement (DR,DC).
vv_translate_cell_(DR, DC, R-C, NR-NC) :-
% Add the displacement to the cell coordinates.
    NR is R + DR,
% Translate the column.
    NC is C + DC.

% vv_translate_region(+Cells, +DR, +DC, -NewCells): translate a list of R-C
% cells by displacement vector (DR,DC). Each cell R-C becomes (R+DR)-(C+DC).
vv_translate_region(Cells, DR, DC, NewCells) :-
% Apply the translation to every cell in the list.
    maplist(vv_translate_cell_(DR, DC), Cells, NewCells).
