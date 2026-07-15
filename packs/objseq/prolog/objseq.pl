% objseq.pl - Layer 175: Object Sequence and Progression Analysis (oq_* prefix).
% Analyses ordered sequences of obj(Color, Cells) terms for patterns in color,
% size, and spatial position. Detects growing/shrinking size progressions, equal
% centroid spacing, periodic color and size cycles, and collinear arrangements.
% No cross-pack dependencies.
:- module(objseq, [
    % objseq_color_seq/2: extract the color list from an obj sequence in list order.
    objseq_color_seq/2,
    % objseq_size_seq/2: extract the cell-count list from an obj sequence in list order.
    objseq_size_seq/2,
    % objseq_centroid_seq/2: extract the centroid sequence as a list of r(R,C) terms.
    objseq_centroid_seq/2,
    % objseq_step_seq/2: consecutive centroid deltas as a list of dr(DR,DC) terms.
    objseq_step_seq/2,
    % objseq_is_growing/1: sizes are strictly increasing in list order.
    objseq_is_growing/1,
    % objseq_is_shrinking/1: sizes are strictly decreasing in list order.
    objseq_is_shrinking/1,
    % objseq_const_step/3: all consecutive centroid steps are the same DR and DC.
    objseq_const_step/3,
    % objseq_const_row_step/2: all consecutive centroid row differences equal DR.
    objseq_const_row_step/2,
    % objseq_const_col_step/2: all consecutive centroid col differences equal DC.
    objseq_const_col_step/2,
    % objseq_color_period/3: minimal period P and unit cycle of the color sequence.
    objseq_color_period/3,
    % objseq_size_period/3: minimal period P and unit cycle of the size sequence.
    objseq_size_period/3,
    % objseq_collinear/1: all centroids lie on a straight line (requires at least 1 obj).
    objseq_collinear/1,
    % objseq_next_centroid/2: predict the next centroid by projecting the constant step.
    objseq_next_centroid/2,
    % objseq_zip_colors/3: zip two obj lists into a list of Color1-Color2 pairs.
    objseq_zip_colors/3
]).

% Load list utilities.
:- use_module(library(lists), [member/2, append/3, last/2, sum_list/2]).
% Load apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).

% --- Private helpers ---------------------------------------------------------

% objseq_color_(+Obj, -Color): extract the color atom from an obj term.
objseq_color_(obj(C, _), C).

% objseq_size_(+Obj, -N): number of cells in an obj term.
objseq_size_(obj(_, Cells), N) :-
% Count cells in the cell list.
    length(Cells, N).

% objseq_centroid_(+Obj, -r(CR,CC)): floor-average row and column centroid of an obj.
objseq_centroid_(obj(_, Cells), r(CR, CC)) :-
% Collect all row indices from the cell list.
    findall(R, member(r(R,_), Cells), Rs),
% Collect all column indices from the cell list.
    findall(C, member(r(_,C), Cells), Cs),
% Denominator is the number of cells.
    length(Rs, N),
% Sum of row indices.
    sum_list(Rs, SR),
% Sum of column indices.
    sum_list(Cs, SC),
% Floor-average row.
    CR is SR // N,
% Floor-average column.
    CC is SC // N.

% objseq_steps_(+Centroids, -Steps): consecutive dr(DR,DC) deltas between centroids.
objseq_steps_([], []).
objseq_steps_([_], []).
objseq_steps_([r(R1,C1), r(R2,C2)|Rest], [dr(DR,DC)|Steps]) :-
% Row delta between consecutive centroids.
    DR is R2 - R1,
% Column delta between consecutive centroids.
    DC is C2 - C1,
% Recurse starting at the second centroid.
    objseq_steps_([r(R2,C2)|Rest], Steps).

% objseq_strictly_inc_(+List): every consecutive pair satisfies A < B.
objseq_strictly_inc_([]).
objseq_strictly_inc_([_]).
objseq_strictly_inc_([A,B|T]) :-
% Current pair must be strictly increasing.
    B > A,
% Recurse on the tail.
    objseq_strictly_inc_([B|T]).

% objseq_strictly_dec_(+List): every consecutive pair satisfies A > B.
objseq_strictly_dec_([]).
objseq_strictly_dec_([_]).
objseq_strictly_dec_([A,B|T]) :-
% Current pair must be strictly decreasing.
    B < A,
% Recurse on the tail.
    objseq_strictly_dec_([B|T]).

% objseq_period_(+List, -P, -Cycle): smallest P such that Cycle tiles List exactly.
% N must be divisible by P; tries P=1,2,... via between/3 (cut after first).
objseq_period_(List, P, Cycle) :-
% Length of the full list.
    length(List, N),
% Non-empty list required.
    N > 0,
% Try each candidate period length in ascending order.
    between(1, N, P),
% Only consider divisors of N.
    0 =:= N mod P,
% Extract the candidate unit cycle.
    length(Cycle, P),
    append(Cycle, _, List),
% Verify Cycle tiles List completely.
    objseq_tiles_(Cycle, List), !.

% objseq_tiles_(+Cycle, +List): List is exactly Cycle repeated to cover length(List).
objseq_tiles_(_, []) :- !.
objseq_tiles_(Cycle, List) :-
% Consume one copy of Cycle from the front.
    append(Cycle, Rest, List),
% Recurse on the remainder.
    objseq_tiles_(Cycle, Rest).

% objseq_cross2d_(+P1, +P2, +P3, -X): 2D cross product of vectors (P2-P1) and (P3-P1).
% X = 0 if and only if P1, P2, P3 are collinear.
objseq_cross2d_(r(R1,C1), r(R2,C2), r(R3,C3), X) :-
% Row component of first vector.
    DR2 is R2 - R1,
% Col component of first vector.
    DC2 is C2 - C1,
% Row component of second vector.
    DR3 is R3 - R1,
% Col component of second vector.
    DC3 is C3 - C1,
% Cross product is the 2D determinant.
    X is DR2 * DC3 - DC2 * DR3.

% objseq_collinear_with_(+P1, +P2, +Rest): all points in Rest are on the P1-P2 line.
objseq_collinear_with_(_, _, []).
objseq_collinear_with_(P1, P2, [P3|Rest]) :-
% Cross product must be zero for P3 to lie on the P1-P2 line.
    objseq_cross2d_(P1, P2, P3, 0),
% Check remaining points against the same baseline.
    objseq_collinear_with_(P1, P2, Rest).

% objseq_row_of_(+DR, +Step): Step's row component equals DR.
objseq_row_of_(DR, dr(DR, _)).

% objseq_col_of_(+DC, +Step): Step's col component equals DC.
objseq_col_of_(DC, dr(_, DC)).

% --- Exported predicates -----------------------------------------------------

% objseq_color_seq(+Objs, -Colors): color list from obj sequence in list order.
objseq_color_seq(Objs, Colors) :-
% Extract the color from each obj term in order.
    maplist(objseq_color_, Objs, Colors).

% objseq_size_seq(+Objs, -Sizes): cell-count list from obj sequence in list order.
objseq_size_seq(Objs, Sizes) :-
% Extract the cell count from each obj term in order.
    maplist(objseq_size_, Objs, Sizes).

% objseq_centroid_seq(+Objs, -Centroids): centroid sequence as a list of r(R,C) terms.
objseq_centroid_seq(Objs, Centroids) :-
% Compute the floor-average centroid of each obj term in order.
    maplist(objseq_centroid_, Objs, Centroids).

% objseq_step_seq(+Objs, -Steps): consecutive centroid deltas as a list of dr(DR,DC) terms.
% Empty or single-element Objs produces an empty step list.
objseq_step_seq(Objs, Steps) :-
% Compute the centroid of each obj.
    maplist(objseq_centroid_, Objs, Centroids),
% Compute consecutive deltas from the centroid list.
    objseq_steps_(Centroids, Steps).

% objseq_is_growing(+Objs): succeeds if sizes are strictly increasing in list order.
% Trivially succeeds for 0 or 1 objects.
objseq_is_growing(Objs) :-
% Extract the size sequence.
    maplist(objseq_size_, Objs, Sizes),
% Test strict monotone increase.
    objseq_strictly_inc_(Sizes).

% objseq_is_shrinking(+Objs): succeeds if sizes are strictly decreasing in list order.
% Trivially succeeds for 0 or 1 objects.
objseq_is_shrinking(Objs) :-
% Extract the size sequence.
    maplist(objseq_size_, Objs, Sizes),
% Test strict monotone decrease.
    objseq_strictly_dec_(Sizes).

% objseq_const_step(+Objs, -DR, -DC): all consecutive centroid steps equal DR and DC.
% Requires at least 2 objects; fails if steps differ or fewer than 2 objects.
objseq_const_step(Objs, DR, DC) :-
% Require at least two objects.
    Objs = [_,_|_],
% Compute centroid for each obj.
    maplist(objseq_centroid_, Objs, Centroids),
% Compute consecutive deltas.
    objseq_steps_(Centroids, [dr(DR,DC)|Rest]),
% All remaining steps must equal the first.
    maplist(=(dr(DR,DC)), Rest).

% objseq_const_row_step(+Objs, -DR): all consecutive centroid row differences equal DR.
% Requires at least 2 objects; col differences may vary.
objseq_const_row_step(Objs, DR) :-
% Require at least two objects.
    Objs = [_,_|_],
% Compute centroid sequence.
    maplist(objseq_centroid_, Objs, Centroids),
% Compute consecutive deltas.
    objseq_steps_(Centroids, Steps),
% Verify every step's row component equals DR.
    maplist(objseq_row_of_(DR), Steps).

% objseq_const_col_step(+Objs, -DC): all consecutive centroid col differences equal DC.
% Requires at least 2 objects; row differences may vary.
objseq_const_col_step(Objs, DC) :-
% Require at least two objects.
    Objs = [_,_|_],
% Compute centroid sequence.
    maplist(objseq_centroid_, Objs, Centroids),
% Compute consecutive deltas.
    objseq_steps_(Centroids, Steps),
% Verify every step's col component equals DC.
    maplist(objseq_col_of_(DC), Steps).

% objseq_color_period(+Objs, -P, -Cycle): minimal period P of the color sequence.
% Cycle is the unit list of length P that tiles the full color sequence.
% P = length(Objs) if no proper sub-period exists. Fails if Objs is empty.
objseq_color_period(Objs, P, Cycle) :-
% Extract color sequence.
    maplist(objseq_color_, Objs, Colors),
% Find the minimal tiling period.
    objseq_period_(Colors, P, Cycle).

% objseq_size_period(+Objs, -P, -Cycle): minimal period P of the size sequence.
% Cycle is the unit list of length P that tiles the full size sequence.
% P = length(Objs) if no proper sub-period exists. Fails if Objs is empty.
objseq_size_period(Objs, P, Cycle) :-
% Extract size sequence.
    maplist(objseq_size_, Objs, Sizes),
% Find the minimal tiling period.
    objseq_period_(Sizes, P, Cycle).

% objseq_collinear(+Objs): all centroids lie on a single straight line.
% Trivially succeeds for 1 or 2 objects. Fails for empty list.
objseq_collinear(Objs) :-
% Need at least one object.
    Objs = [_|_],
% Compute centroid sequence.
    maplist(objseq_centroid_, Objs, Centroids),
% 0-2 centroids are trivially collinear; 3+ require cross-product check.
    (   Centroids = [P1, P2 | Rest]
    ->  objseq_collinear_with_(P1, P2, Rest)
    ;   true
    ).

% objseq_next_centroid(+Objs, -r(NR,NC)): predict the next centroid by constant step.
% Requires objseq_const_step to succeed; fails if the step is not consistent.
objseq_next_centroid(Objs, r(NR, NC)) :-
% Derive the constant step (fails if inconsistent or < 2 objs).
    objseq_const_step(Objs, DR, DC),
% Compute the centroid of each obj.
    maplist(objseq_centroid_, Objs, Centroids),
% Get the last centroid in the sequence.
    last(Centroids, r(LR, LC)),
% Project one step beyond the last centroid.
    NR is LR + DR,
    NC is LC + DC.

% objseq_zip_colors(+Objs1, +Objs2, -Pairs): zip two obj lists into Color1-Color2 pairs.
% Both lists must have the same length. Useful for recording input-to-output color maps.
objseq_zip_colors([], [], []).
objseq_zip_colors([obj(C1,_)|T1], [obj(C2,_)|T2], [C1-C2|Pairs]) :-
% Pair the head colors and recurse on the tails.
    objseq_zip_colors(T1, T2, Pairs).
