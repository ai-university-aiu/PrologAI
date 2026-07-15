:- use_module('../prolog/gridmask').

% Grid fixtures.
% 3x3 grids: bg = x (background), fg = r/b/g (foreground).
% g3x3_r: all red.
g3x3_r([[r,r,r],[r,r,r],[r,r,r]]).
% g3x3_x: all background.
g3x3_x([[x,x,x],[x,x,x],[x,x,x]]).
% g3x3_rb: top half r, bottom half b (approximately).
g3x3_rb([[r,r,r],[r,r,r],[b,b,b]]).
% g3x3_tl: top-left 2x2 = r, rest = x.
g3x3_tl([[r,r,x],[r,r,x],[x,x,x]]).
% g3x3_br: bottom-right 2x2 = b, rest = x.
g3x3_br([[x,x,x],[x,b,b],[x,b,b]]).
% g2x2_r: 2x2 all red.
g2x2_r([[r,r],[r,r]]).
% g4x4_open: 4x4 open grid.
g4x4_open([[a,a,a,a],[a,a,a,a],[a,a,a,a],[a,a,a,a]]).
% g3x3_check: checkerboard.
g3x3_check([[r,x,r],[x,r,x],[r,x,r]]).
% Stamp: 2x2 stamp.
stamp2x2([[s,s],[s,s]]).
% g3x4: 3 rows, 4 cols.
g3x4([[p,p,p,p],[p,p,p,p],[p,p,p,p]]).

:- begin_tests(gridmask).

% --- gridmask_overlay tests ---

% Overlay all-x on all-r: BgColor=x so GridB (all-x) shows nothing; Result = GridA (all-r).
test(overlay_bg_transparent) :-
    g3x3_r(GA), g3x3_x(GB),
    gridmask_overlay(GA, GB, x, r, R),
    R = [[r,r,r],[r,r,r],[r,r,r]].

% Overlay g3x3_br on g3x3_tl: non-x cells of GB replace GA.
test(overlay_top_left_br) :-
    g3x3_tl(GA), g3x3_br(GB),
    gridmask_overlay(GA, GB, x, r, R),
    R = [[r,r,x],[r,b,b],[x,b,b]].

% Overlay all-r on all-r: non-BgColor replaces all.
test(overlay_same) :-
    g3x3_r(GA), g3x3_r(GB),
    gridmask_overlay(GA, GB, x, r, R),
    R = [[r,r,r],[r,r,r],[r,r,r]].

% --- gridmask_union tests ---

% Union of tl and br: tl color wins where tl is non-bg, else br color.
% (1,1): tl=r (non-x) stays r; (1,2): tl=x so br=b wins; etc.
test(union_tl_br) :-
    g3x3_tl(GA), g3x3_br(GB),
    gridmask_union(GA, GB, x, R),
    R = [[r,r,x],[r,r,b],[x,b,b]].

% Union with empty grid: returns first.
test(union_with_empty) :-
    g3x3_tl(GA), g3x3_x(GB),
    gridmask_union(GA, GB, x, R),
    R = GA.

% Union of two empties: all background.
test(union_both_empty) :-
    g3x3_x(GA), g3x3_x(GB),
    gridmask_union(GA, GB, x, R),
    R = [[x,x,x],[x,x,x],[x,x,x]].

% --- gridmask_intersect tests ---

% Intersection of tl and br: only (1,1) is non-bg in both... wait:
% tl = [[r,r,x],[r,r,x],[x,x,x]], br = [[x,x,x],[x,b,b],[x,b,b]]
% Non-bg in both: (1,1) in tl is r, in br is b -> intersect = g.
test(intersect_overlap) :-
    g3x3_tl(GA), g3x3_br(GB),
    gridmask_intersect(GA, GB, x, g, R),
    R = [[x,x,x],[x,g,x],[x,x,x]].

% No overlap: all background.
test(intersect_no_overlap) :-
    g3x3_tl(GA), g3x3_x(GB),
    gridmask_intersect(GA, GB, x, g, R),
    R = [[x,x,x],[x,x,x],[x,x,x]].

% Full overlap (both non-bg): all fg.
test(intersect_full_overlap) :-
    g3x3_r(GA), g3x3_r(GB),
    gridmask_intersect(GA, GB, x, g, R),
    R = [[g,g,g],[g,g,g],[g,g,g]].

% --- gridmask_difference tests ---

% A minus B: tl minus br -> tl cells that are not in br keep color, rest become bg.
test(difference_tl_minus_br) :-
    g3x3_tl(GA), g3x3_br(GB),
    gridmask_difference(GA, GB, x, x, R),
    % GB non-bg at (1,1),(1,2),(2,1),(2,2); GA[1,1]=r -> becomes x; others of GA unchanged
    R = [[r,r,x],[r,x,x],[x,x,x]].

% A minus empty B: A unchanged.
test(difference_minus_empty) :-
    g3x3_tl(GA), g3x3_x(GB),
    gridmask_difference(GA, GB, x, x, R),
    R = GA.

% Empty minus A: all bg (nothing to keep).
test(difference_empty_minus_any) :-
    g3x3_x(GA), g3x3_tl(GB),
    gridmask_difference(GA, GB, x, x, R),
    R = [[x,x,x],[x,x,x],[x,x,x]].

% --- gridmask_invert tests ---

% Invert tl: r cells become x, x cells become r.
test(invert_tl) :-
    g3x3_tl(G),
    gridmask_invert(G, x, r, R),
    R = [[x,x,r],[x,x,r],[r,r,r]].

% Invert all-r with bg=x, fg=b: all r -> x... wait, r != x so r -> x; x -> b.
% g3x3_r has no x, so all r become x.
test(invert_all_fg) :-
    g3x3_r(G),
    gridmask_invert(G, x, b, R),
    R = [[x,x,x],[x,x,x],[x,x,x]].

% Invert all-x: all x become b.
test(invert_all_bg) :-
    g3x3_x(G),
    gridmask_invert(G, x, b, R),
    R = [[b,b,b],[b,b,b],[b,b,b]].

% --- gridmask_mask_apply tests ---

% Mask where Mask non-bg = show through, Mask bg = fill with x.
% Mask = g3x3_tl (non-bg at corners), Grid = g3x3_r.
% Where Mask is r (non-bg): show Grid = r. Where Mask is x (bg): fill = x.
test(mask_apply_tl_mask) :-
    g3x3_r(G), g3x3_tl(Mask),
    gridmask_mask_apply(G, Mask, x, x, R),
    R = [[r,r,x],[r,r,x],[x,x,x]].

% Full mask (all non-bg): entire Grid shows through.
test(mask_apply_full) :-
    g3x3_r(G), g3x3_r(Mask),
    gridmask_mask_apply(G, Mask, x, x, R),
    R = G.

% Empty mask (all bg): entire Grid hidden.
test(mask_apply_empty) :-
    g3x3_r(G), g3x3_x(Mask),
    gridmask_mask_apply(G, Mask, x, b, R),
    R = [[b,b,b],[b,b,b],[b,b,b]].

% --- gridmask_extract tests ---

% Extract cells [0-0, 0-1, 1-0] from g3x3_r.
test(extract_cells) :-
    g3x3_r(G),
    gridmask_extract(G, [0-0,0-1,1-0], x, R),
    R = [[r,r,x],[r,x,x],[x,x,x]].

% Extract no cells: all bg.
test(extract_empty) :-
    g3x3_r(G),
    gridmask_extract(G, [], x, R),
    R = [[x,x,x],[x,x,x],[x,x,x]].

% Extract all cells: same as original.
test(extract_all) :-
    g3x3_tl(G),
    Cells = [0-0,0-1,0-2,1-0,1-1,1-2,2-0,2-1,2-2],
    gridmask_extract(G, Cells, x, R),
    R = G.

% --- gridmask_stamp tests ---

% Stamp 2x2 [[s,s],[s,s]] at (0,0) on 3x3 all-r.
test(stamp_topleft) :-
    g3x3_r(G), stamp2x2(S),
    gridmask_stamp(G, S, 0, 0, R),
    R = [[s,s,r],[s,s,r],[r,r,r]].

% Stamp at (1,1) on 3x3 all-r.
test(stamp_center) :-
    g3x3_r(G), stamp2x2(S),
    gridmask_stamp(G, S, 1, 1, R),
    R = [[r,r,r],[r,s,s],[r,s,s]].

% Stamp partially outside (at (2,2) on 3x3): only top-left cell visible.
test(stamp_partial) :-
    g3x3_r(G), stamp2x2(S),
    gridmask_stamp(G, S, 2, 2, R),
    R = [[r,r,r],[r,r,r],[r,r,s]].

% --- gridmask_compare tests ---

% Same grids: empty diff.
test(compare_same) :-
    g3x3_r(G),
    gridmask_compare(G, G, x, Diff),
    Diff = [].

% tl vs br: diff at every non-bg cell of either.
test(compare_tl_br) :-
    g3x3_tl(GA), g3x3_br(GB),
    gridmask_compare(GA, GB, x, Diff),
    msort(Diff, S),
    msort([0-0,0-1,1-0,1-1,1-2,2-1,2-2], S).

% All-r vs all-x: every cell differs.
test(compare_r_x) :-
    g3x3_r(GA), g3x3_x(GB),
    gridmask_compare(GA, GB, x, Diff),
    length(Diff, 9).

% --- gridmask_equal tests ---

% Same grid equal.
test(equal_same) :-
    g3x3_r(G),
    gridmask_equal(G, G).

% Different grids not equal.
test(equal_different_fails, [fail]) :-
    g3x3_r(GA), g3x3_x(GB),
    gridmask_equal(GA, GB).

% --- gridmask_sub tests ---

% Sub-grid 2x2 from (0,0) in 3x3 tl.
test(sub_topleft_2x2) :-
    g3x3_tl(G),
    gridmask_sub(G, 0, 0, 2, 2, Sub),
    Sub = [[r,r],[r,r]].

% Sub-grid 1x1 from (2,2).
test(sub_bottom_right_1x1) :-
    g3x3_tl(G),
    gridmask_sub(G, 2, 2, 1, 1, Sub),
    Sub = [[x]].

% Sub-grid out of bounds fails.
test(sub_out_of_bounds_fails, [fail]) :-
    g3x3_r(G),
    gridmask_sub(G, 2, 2, 2, 2, _).

% Full 3x3 sub-grid.
test(sub_full) :-
    g3x3_r(G),
    gridmask_sub(G, 0, 0, 3, 3, Sub),
    Sub = G.

% --- gridmask_paste tests ---

% Paste g2x2_r at (0,0) on g3x3_x with bg=x: r cells appear.
test(paste_at_origin) :-
    g3x3_x(G), g2x2_r(P),
    gridmask_paste(G, P, 0, 0, x, R),
    R = [[r,r,x],[r,r,x],[x,x,x]].

% Paste at (1,1).
test(paste_at_center) :-
    g3x3_x(G), g2x2_r(P),
    gridmask_paste(G, P, 1, 1, x, R),
    R = [[x,x,x],[x,r,r],[x,r,r]].

% Paste with all-bg patch: no change.
test(paste_bg_no_change) :-
    g3x3_r(G),
    gridmask_paste(G, [[x,x],[x,x]], 0, 0, x, R),
    R = G.

% --- gridmask_border_mask tests ---

% 1-layer border on 3x3: all cells are border (3x3 has no interior at N=1).
% Actually: N=1 border = r<1 or r>=2 or c<1 or c>=2. For 3x3 rows 0-2, cols 0-2:
% row 0: border, row 2: border, col 0: border, col 2: border. Only (1,1) is interior.
test(border_mask_n1) :-
    g3x3_r(G),
    gridmask_border_mask(G, 1, Mask),
    Mask = [[border,border,border],[border,interior,border],[border,border,border]].

% 2-layer border on 4x4: all cells border (4x4 has no 2-layer interior... wait:
% interior = r >= 2 AND r < 2 (H=4, H-N=2). So r >= 2 AND r < 2 is impossible.
% All cells are border for N=2 on 4x4.
test(border_mask_4x4_n2) :-
    g4x4_open(G),
    gridmask_border_mask(G, 2, Mask),
% All cells should be border since N=2 leaves no interior (rows 0,1,2,3 -> r<2 or r>=2).
    findall(V, (member(Row, Mask), member(V, Row)), Vs),
    \+ member(interior, Vs).

% N=0 border: all interior.
test(border_mask_n0) :-
    g3x3_r(G),
    gridmask_border_mask(G, 0, Mask),
    Mask = [[interior,interior,interior],[interior,interior,interior],[interior,interior,interior]].

% --- gridmask_color_mask tests ---

% Mask for color r in g3x3_rb.
test(color_mask_r) :-
    g3x3_rb(G),
    gridmask_color_mask(G, r, sel, Mask),
    Mask = [[sel,sel,sel],[sel,sel,sel],[bg,bg,bg]].

% Mask for absent color: all bg.
test(color_mask_absent) :-
    g3x3_r(G),
    gridmask_color_mask(G, x, sel, Mask),
    Mask = [[bg,bg,bg],[bg,bg,bg],[bg,bg,bg]].

% Mask for color present everywhere: all sel.
test(color_mask_all) :-
    g3x3_r(G),
    gridmask_color_mask(G, r, sel, Mask),
    Mask = [[sel,sel,sel],[sel,sel,sel],[sel,sel,sel]].

% --- Combined tests ---

% Invert then union with original = all fg (no background cells remain).
test(invert_then_union) :-
    g3x3_tl(G),
    gridmask_invert(G, x, r, Inv),
    gridmask_union(G, Inv, x, R),
    gridmask_equal(R, [[r,r,r],[r,r,r],[r,r,r]]).

% Sub then stamp round-trip: extract sub-grid and stamp back gives original.
test(sub_then_stamp) :-
    g3x3_r(G),
    gridmask_sub(G, 0, 0, 2, 2, Sub),
    gridmask_stamp(G, Sub, 0, 0, R),
    gridmask_equal(R, G).

:- end_tests(gridmask).

:- run_tests(gridmask).
