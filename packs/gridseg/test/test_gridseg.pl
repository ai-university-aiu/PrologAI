:- use_module('../prolog/gridseg').

% Grid fixtures
% 3-row grid with one separator row at position 1 (color s)
g_row1sep([[a,b,c],[s,s,s],[d,e,f]]).
% 4-row grid with separator rows at positions 0 and 2
g_rows02sep([[s,s,s],[a,b,c],[s,s,s],[d,e,f]]).
% 3-row grid with two consecutive separator rows then content
g_consec_sep([[s,s,s],[s,s,s],[a,b,c]]).
% 3x3 grid with no separators
g3x3([[a,b,c],[d,e,f],[g,h,i]]).
% 3x3 grid with separator columns at positions 0 and 2 (color s)
g_cols02sep([[s,a,s],[s,b,s],[s,c,s]]).
% Grid with both separator row and separator column (color s):
% rows 1 is sep; cols 1 is sep; gives 4 panels
g_both_sep([[r,s,r],[s,s,s],[r,s,r]]).
% Grid with separator at top and bottom only
g_border_sep([[s,s,s],[a,b,c],[d,e,f],[s,s,s]]).
% Grid with separator cols at left and right
g_border_cols([[s,a,b,s],[s,c,d,s],[s,e,f,s]]).
% 1x1 grid with the separator color
g1x1_sep([[s]]).
% 5-row grid with two separator rows creating three segments
g_three_segs([[a,a],[s,s],[b,b],[s,s],[c,c]]).

:- begin_tests(gridseg).

% --- gridseg_is_sep_row ---
test(is_sep_row_yes, []) :-
    g_row1sep(G), gridseg_is_sep_row(G, 1, s).

test(is_sep_row_no, []) :-
    g3x3(G), \+ gridseg_is_sep_row(G, 0, _).

test(is_sep_row_binds_color, []) :-
    g_row1sep(G), gridseg_is_sep_row(G, 1, C), C = s.

% --- gridseg_is_sep_col ---
test(is_sep_col_yes, []) :-
    g_cols02sep(G), gridseg_is_sep_col(G, 0, s).

test(is_sep_col_no, []) :-
    g3x3(G), \+ gridseg_is_sep_col(G, 0, _).

test(is_sep_col_binds_color, []) :-
    g_cols02sep(G), gridseg_is_sep_col(G, 2, C), C = s.

% --- gridseg_sep_rows ---
test(sep_rows_one, []) :-
    g_row1sep(G), gridseg_sep_rows(G, s, [1]).

test(sep_rows_none, []) :-
    g3x3(G), gridseg_sep_rows(G, s, []).

test(sep_rows_two, []) :-
    g_rows02sep(G), gridseg_sep_rows(G, s, [0,2]).

% --- gridseg_sep_cols ---
test(sep_cols_two, []) :-
    g_cols02sep(G), gridseg_sep_cols(G, s, [0,2]).

test(sep_cols_none, []) :-
    g3x3(G), gridseg_sep_cols(G, s, []).

test(sep_cols_one_1x1, []) :-
    g1x1_sep(G), gridseg_sep_cols(G, s, [0]).

% --- gridseg_split_h ---
test(split_h_two_segs, []) :-
    g_row1sep(G), gridseg_split_h(G, s, [[[a,b,c]],[[d,e,f]]]).

test(split_h_no_sep, []) :-
    g3x3(G), gridseg_split_h(G, s, [G]).

test(split_h_border_sep, []) :-
    % Sep at top and bottom: one segment in the middle
    g_border_sep(G), gridseg_split_h(G, s, [[[a,b,c],[d,e,f]]]).

test(split_h_consecutive_sep, []) :-
    % Two consecutive sep rows at top: one segment at bottom
    g_consec_sep(G), gridseg_split_h(G, s, [[[a,b,c]]]).

% --- gridseg_split_v ---
test(split_v_two_segs, []) :-
    g_cols02sep(G), gridseg_split_v(G, s, [[[a],[b],[c]]]).

test(split_v_no_sep, []) :-
    g3x3(G), gridseg_split_v(G, s, [G]).

test(split_v_border_cols, []) :-
    % Sep at left and right: one segment in the middle
    g_border_cols(G), gridseg_split_v(G, s, [[[a,b],[c,d],[e,f]]]).

% --- gridseg_segment_count_h ---
test(segment_count_h_two, []) :-
    g_row1sep(G), gridseg_segment_count_h(G, s, 2).

test(segment_count_h_one, []) :-
    g3x3(G), gridseg_segment_count_h(G, s, 1).

% --- gridseg_segment_count_v ---
test(segment_count_v_one, []) :-
    % g_cols02sep has sep at 0 and 2, content in middle col: 1 segment
    g_cols02sep(G), gridseg_segment_count_v(G, s, 1).

test(segment_count_v_one_nosep, []) :-
    g3x3(G), gridseg_segment_count_v(G, s, 1).

% --- gridseg_panels ---
test(panels_four, []) :-
    % g_both_sep: row 1 is [s,s,s]; col 1 is [s,s,s]
    % split_h gives: [[[r,s,r]]] and [[[r,s,r]]] -- row 0 and row 2
    % each then split_v at col 1 gives panels [[r]] and [[r]]
    g_both_sep(G), gridseg_panels(G, s, Panels), length(Panels, 4).

test(panels_two, []) :-
    % g_row1sep: only horizontal sep → 2 row segs, each 1 col seg
    g_row1sep(G), gridseg_panels(G, s, Panels), length(Panels, 2).

test(panels_one, []) :-
    g3x3(G), gridseg_panels(G, s, [G]).

% --- gridseg_panel_count ---
test(panel_count_four, []) :-
    g_both_sep(G), gridseg_panel_count(G, s, 4).

test(panel_count_two, []) :-
    g_row1sep(G), gridseg_panel_count(G, s, 2).

test(panel_count_one, []) :-
    g3x3(G), gridseg_panel_count(G, s, 1).

% --- gridseg_trim_h ---
test(trim_h_removes_borders, []) :-
    g_border_sep(G), gridseg_trim_h(G, s, [[a,b,c],[d,e,f]]).

test(trim_h_noop, []) :-
    g3x3(G), gridseg_trim_h(G, s, G).

test(trim_h_consecutive, []) :-
    % Two sep rows at top removed, content at bottom kept
    g_consec_sep(G), gridseg_trim_h(G, s, [[a,b,c]]).

% --- gridseg_trim_v ---
test(trim_v_removes_borders, []) :-
    g_border_cols(G), gridseg_trim_v(G, s, [[a,b],[c,d],[e,f]]).

test(trim_v_noop, []) :-
    g3x3(G), gridseg_trim_v(G, s, G).

% --- gridseg_trim ---
test(trim_both, []) :-
    % g_both_sep: row 0 and 2 are sep, col 0 and 2 are sep
    % After trim_h: [[r,s,r]] removed ... wait let me check g_both_sep
    % g_both_sep = [[r,s,r],[s,s,s],[r,s,r]]
    % row 0: [r,s,r] -- not uniform (r and s differ)
    % row 1: [s,s,s] -- uniform s (separator)
    % row 2: [r,s,r] -- not uniform
    % So trim_h removes nothing from top (row 0 is not sep)
    % trim_h removes nothing from bottom (row 2 is not sep)
    % Result: same grid
    % col 1: [s,s,s] -- uniform s (separator)
    % trim_v removes nothing (col 0 = [r,s,r] not sep, col 2 = [r,s,r] not sep)
    % So trim(g_both_sep, s) = g_both_sep
    g_both_sep(G), gridseg_trim(G, s, G).

test(trim_noop, []) :-
    g3x3(G), gridseg_trim(G, s, G).

% --- gridseg_sep_color ---
test(sep_color_row, []) :-
    % g_row1sep has only s as separator color
    g_row1sep(G), gridseg_sep_color(G, s).

test(sep_color_col, []) :-
    % g_cols02sep has only s as separator color
    g_cols02sep(G), gridseg_sep_color(G, s).

% --- Combined tests ---
test(combined_split_count, []) :-
    % segment_count_h equals length of split_h result
    g_three_segs(G),
    gridseg_split_h(G, s, Segs),
    gridseg_segment_count_h(G, s, N),
    length(Segs, N).

test(combined_panel_count_matches, []) :-
    % panel_count equals length of panels
    g_both_sep(G),
    gridseg_panels(G, s, Panels),
    gridseg_panel_count(G, s, N),
    length(Panels, N).

test(combined_three_segs, []) :-
    % g_three_segs has 3 segments
    g_three_segs(G), gridseg_segment_count_h(G, s, 3).

test(combined_trim_then_count, []) :-
    % Trimming border seps then counting gives same content
    g_border_sep(G),
    gridseg_trim_h(G, s, Trimmed),
    length(Trimmed, 2).

test(sep_rows_border, []) :-
    % g_border_sep has sep at rows 0 and 3
    g_border_sep(G), gridseg_sep_rows(G, s, [0,3]).

test(split_h_three_segments, []) :-
    % g_three_segs: sep at rows 1 and 3, giving 3 segments
    g_three_segs(G), gridseg_split_h(G, s, Segs), length(Segs, 3).

:- end_tests(gridseg).
