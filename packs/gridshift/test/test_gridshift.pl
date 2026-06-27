:- use_module('../prolog/gridshift').

% Test grids used throughout.
% g5: 3x3 alphabet grid.
%   Row 0: a b c
%   Row 1: d e f
%   Row 2: g h i
% g1: 3x3 sparse grid with two non-bg cells.
%   Row 0: x b b
%   Row 1: b b b
%   Row 2: b b y
% ab3: 3x3 all-bg grid (all b).

g5([[a,b,c],[d,e,f],[g,h,i]]).
g1([[x,b,b],[b,b,b],[b,b,y]]).
ab3([[b,b,b],[b,b,b],[b,b,b]]).

:- begin_tests(gsh_shift_right).

% AC-GSH-001: shift right by 1: first cell of each row becomes bg.
test(right1) :-
    g5(G), gsh_shift_right(G, 1, z, R),
    R = [[z,a,b],[z,d,e],[z,g,h]].

% AC-GSH-002: shift right by W (= 3): all rows become all-bg.
test(right_full) :-
    g5(G), gsh_shift_right(G, 3, z, R),
    R = [[z,z,z],[z,z,z],[z,z,z]].

% AC-GSH-003: shift right by 0: grid unchanged.
test(right_zero) :-
    g5(G), gsh_shift_right(G, 0, z, R),
    R = [[a,b,c],[d,e,f],[g,h,i]].

:- end_tests(gsh_shift_right).

:- begin_tests(gsh_shift_left).

% AC-GSH-004: shift left by 1: last cell of each row becomes bg.
test(left1) :-
    g5(G), gsh_shift_left(G, 1, z, R),
    R = [[b,c,z],[e,f,z],[h,i,z]].

% AC-GSH-005: shift left by W: all rows become all-bg.
test(left_full) :-
    g5(G), gsh_shift_left(G, 3, z, R),
    R = [[z,z,z],[z,z,z],[z,z,z]].

% AC-GSH-006: shift left by 0: grid unchanged.
test(left_zero) :-
    g5(G), gsh_shift_left(G, 0, z, R),
    R = [[a,b,c],[d,e,f],[g,h,i]].

:- end_tests(gsh_shift_left).

:- begin_tests(gsh_shift_down).

% AC-GSH-007: shift down by 1: top row becomes all-bg; bottom row falls off.
test(down1) :-
    g5(G), gsh_shift_down(G, 1, z, R),
    R = [[z,z,z],[a,b,c],[d,e,f]].

% AC-GSH-008: shift down by H: all rows become all-bg.
test(down_full) :-
    g5(G), gsh_shift_down(G, 3, z, R),
    R = [[z,z,z],[z,z,z],[z,z,z]].

% AC-GSH-009: shift down by 0: grid unchanged.
test(down_zero) :-
    g5(G), gsh_shift_down(G, 0, z, R),
    R = [[a,b,c],[d,e,f],[g,h,i]].

:- end_tests(gsh_shift_down).

:- begin_tests(gsh_shift_up).

% AC-GSH-010: shift up by 1: top row falls off; bottom row becomes all-bg.
test(up1) :-
    g5(G), gsh_shift_up(G, 1, z, R),
    R = [[d,e,f],[g,h,i],[z,z,z]].

% AC-GSH-011: shift up by H: all rows become all-bg.
test(up_full) :-
    g5(G), gsh_shift_up(G, 3, z, R),
    R = [[z,z,z],[z,z,z],[z,z,z]].

% AC-GSH-012: shift up by 0: grid unchanged.
test(up_zero) :-
    g5(G), gsh_shift_up(G, 0, z, R),
    R = [[a,b,c],[d,e,f],[g,h,i]].

:- end_tests(gsh_shift_up).

:- begin_tests(gsh_roll_right).

% AC-GSH-013: roll right by 1: last cell of each row wraps to front.
test(roll_right1) :-
    g5(G), gsh_roll_right(G, 1, R),
    R = [[c,a,b],[f,d,e],[i,g,h]].

% AC-GSH-014: roll right by W (= 3): identity (full rotation).
test(roll_right_full) :-
    g5(G), gsh_roll_right(G, 3, R),
    R = [[a,b,c],[d,e,f],[g,h,i]].

% AC-GSH-015: roll right on all-bg: result is all-bg.
test(roll_right_all_bg) :-
    ab3(G), gsh_roll_right(G, 1, R),
    R = [[b,b,b],[b,b,b],[b,b,b]].

:- end_tests(gsh_roll_right).

:- begin_tests(gsh_roll_left).

% AC-GSH-016: roll left by 1: first cell of each row wraps to back.
test(roll_left1) :-
    g5(G), gsh_roll_left(G, 1, R),
    R = [[b,c,a],[e,f,d],[h,i,g]].

% AC-GSH-017: roll right then roll left by same N returns original.
test(roll_left_inverse) :-
    g5(G), gsh_roll_right(G, 2, R1), gsh_roll_left(R1, 2, R2),
    R2 = [[a,b,c],[d,e,f],[g,h,i]].

% AC-GSH-018: roll left on all-bg: result is all-bg.
test(roll_left_all_bg) :-
    ab3(G), gsh_roll_left(G, 1, R),
    R = [[b,b,b],[b,b,b],[b,b,b]].

:- end_tests(gsh_roll_left).

:- begin_tests(gsh_roll_down).

% AC-GSH-019: roll down by 1: last row wraps to top.
test(roll_down1) :-
    g5(G), gsh_roll_down(G, 1, R),
    R = [[g,h,i],[a,b,c],[d,e,f]].

% AC-GSH-020: roll down by H: identity.
test(roll_down_full) :-
    g5(G), gsh_roll_down(G, 3, R),
    R = [[a,b,c],[d,e,f],[g,h,i]].

% AC-GSH-021: roll down on all-bg: result is all-bg.
test(roll_down_all_bg) :-
    ab3(G), gsh_roll_down(G, 1, R),
    R = [[b,b,b],[b,b,b],[b,b,b]].

:- end_tests(gsh_roll_down).

:- begin_tests(gsh_roll_up).

% AC-GSH-022: roll up by 1: first row wraps to bottom.
test(roll_up1) :-
    g5(G), gsh_roll_up(G, 1, R),
    R = [[d,e,f],[g,h,i],[a,b,c]].

% AC-GSH-023: roll down then roll up by same N returns original.
test(roll_up_inverse) :-
    g5(G), gsh_roll_down(G, 2, R1), gsh_roll_up(R1, 2, R2),
    R2 = [[a,b,c],[d,e,f],[g,h,i]].

% AC-GSH-024: roll up on all-bg: result is all-bg.
test(roll_up_all_bg) :-
    ab3(G), gsh_roll_up(G, 1, R),
    R = [[b,b,b],[b,b,b],[b,b,b]].

:- end_tests(gsh_roll_up).

:- begin_tests(gsh_roll_row).

% AC-GSH-025: roll row 0 right by 1: row 0 wraps, other rows unchanged.
test(roll_row0_right1) :-
    g5(G), gsh_roll_row(G, 0, 1, R),
    R = [[c,a,b],[d,e,f],[g,h,i]].

% AC-GSH-026: roll row 1 right by W (= 3): full rotation = identity row.
test(roll_row_full) :-
    g5(G), gsh_roll_row(G, 1, 3, R),
    R = [[a,b,c],[d,e,f],[g,h,i]].

% AC-GSH-027: roll row on all-bg: result is all-bg.
test(roll_row_all_bg) :-
    ab3(G), gsh_roll_row(G, 1, 1, R),
    R = [[b,b,b],[b,b,b],[b,b,b]].

:- end_tests(gsh_roll_row).

:- begin_tests(gsh_roll_col).

% AC-GSH-028: roll col 0 down by 1: col 0 bottom wraps to top, other cols unchanged.
test(roll_col0_down1) :-
    g5(G), gsh_roll_col(G, 0, 1, R),
    R = [[g,b,c],[a,e,f],[d,h,i]].

% AC-GSH-029: roll col 1 down by H (= 3): full rotation = identity.
test(roll_col_full) :-
    g5(G), gsh_roll_col(G, 1, 3, R),
    R = [[a,b,c],[d,e,f],[g,h,i]].

% AC-GSH-030: roll col on all-bg: result is all-bg.
test(roll_col_all_bg) :-
    ab3(G), gsh_roll_col(G, 1, 1, R),
    R = [[b,b,b],[b,b,b],[b,b,b]].

:- end_tests(gsh_roll_col).

:- begin_tests(gsh_shift_color).

% AC-GSH-031: shift x right by DC=1 in g1: x moves from (0,0) to (0,1).
test(color_shift_right) :-
    g1(G), gsh_shift_color(G, x, 0, 1, b, R),
    R = [[b,x,b],[b,b,b],[b,b,y]].

% AC-GSH-032: shift x up by DR=-1: x at (0,0) moves to (-1,0) which is OOB — disappears.
test(color_shift_oob) :-
    g1(G), gsh_shift_color(G, x, -1, 0, b, R),
    R = [[b,b,b],[b,b,b],[b,b,y]].

% AC-GSH-033: shift x by (0,0): no movement; grid unchanged.
test(color_shift_identity) :-
    g1(G), gsh_shift_color(G, x, 0, 0, b, R),
    R = [[x,b,b],[b,b,b],[b,b,y]].

:- end_tests(gsh_shift_color).

:- begin_tests(gsh_offset).

% AC-GSH-034: offset g1 by (1,1): entire grid shifts right+down by 1; x moves to (1,1).
test(offset_1_1) :-
    g1(G), gsh_offset(G, 1, 1, b, R),
    R = [[b,b,b],[b,x,b],[b,b,b]].

% AC-GSH-035: offset by (0,0): identity — grid unchanged.
test(offset_identity) :-
    g1(G), gsh_offset(G, 0, 0, b, R),
    R = [[x,b,b],[b,b,b],[b,b,y]].

% AC-GSH-036: offset all-bg by any amount: result is all-bg.
test(offset_all_bg) :-
    ab3(G), gsh_offset(G, 1, 0, b, R),
    R = [[b,b,b],[b,b,b],[b,b,b]].

:- end_tests(gsh_offset).

:- begin_tests(gsh_shift_row).

% AC-GSH-037: shift row 1 right by 1: row 1 shifts right, others unchanged.
test(shift_row_right1) :-
    g5(G), gsh_shift_row(G, 1, 1, z, R),
    R = [[a,b,c],[z,d,e],[g,h,i]].

% AC-GSH-038: shift row 0 right by W (= 3): row 0 becomes all-bg, others unchanged.
test(shift_row_full) :-
    g5(G), gsh_shift_row(G, 0, 3, z, R),
    R = [[z,z,z],[d,e,f],[g,h,i]].

% AC-GSH-039: shift row 2 by 0: grid unchanged.
test(shift_row_zero) :-
    g5(G), gsh_shift_row(G, 2, 0, z, R),
    R = [[a,b,c],[d,e,f],[g,h,i]].

:- end_tests(gsh_shift_row).

:- begin_tests(gsh_shift_col).

% AC-GSH-040: shift col 1 down by 1: col 1 shifts down, others unchanged.
test(shift_col_down1) :-
    g5(G), gsh_shift_col(G, 1, 1, z, R),
    R = [[a,z,c],[d,b,f],[g,e,i]].

% AC-GSH-041: shift col 0 down by H (= 3): col 0 becomes all-bg, others unchanged.
test(shift_col_full) :-
    g5(G), gsh_shift_col(G, 0, 3, z, R),
    R = [[z,b,c],[z,e,f],[z,h,i]].

% AC-GSH-042: shift col 0 by 0: grid unchanged.
test(shift_col_zero) :-
    g5(G), gsh_shift_col(G, 0, 0, z, R),
    R = [[a,b,c],[d,e,f],[g,h,i]].

:- end_tests(gsh_shift_col).

:- begin_tests(gsh_combined).

% AC-GSH-043: roll right then roll left by 2 is identity round-trip.
test(roll_roundtrip) :-
    g5(G),
    gsh_roll_right(G, 2, R1),
    gsh_roll_left(R1, 2, R2),
    R2 = [[a,b,c],[d,e,f],[g,h,i]].

% AC-GSH-044: shift_right by 1 equals offset by (DR=0, DC=1) with same bg.
test(shift_vs_offset) :-
    g5(G),
    gsh_shift_right(G, 1, z, SR),
    gsh_offset(G, 0, 1, z, OFF),
    SR = OFF.

:- end_tests(gsh_combined).
