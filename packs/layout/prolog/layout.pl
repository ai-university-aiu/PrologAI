% layout.pl - Layer 159: Multi-Object Layout Analysis (lt_* prefix).
% Analyzes the collective spatial arrangement of a list of obj(Color, Cells)
% terms. Provides global bounding box, centroid aggregation, row/column range
% and count, line and diagonal detection, grid arrangement detection, and
% uniform-spacing checks. All centroid computations use integer truncation.
:- module(layout, [
    % layout_global_bbox/5: bounding box over ALL cells of all objects combined.
    layout_global_bbox/5,
    % layout_bbox_area/2: area (rows * cols) of the global bounding box.
    layout_bbox_area/2,
    % layout_row_range/3: min and max topmost-row among all objects.
    layout_row_range/3,
    % layout_col_range/3: min and max leftmost-col among all objects.
    layout_col_range/3,
    % layout_all_same_row/1: succeed iff all objects share the same topmost row.
    layout_all_same_row/1,
    % layout_all_same_col/1: succeed iff all objects share the same leftmost column.
    layout_all_same_col/1,
    % layout_centroid_of_all/3: integer-truncated centroid of all object centroids.
    layout_centroid_of_all/3,
    % layout_row_count/2: number of distinct topmost rows across all objects.
    layout_row_count/2,
    % layout_col_count/2: number of distinct leftmost columns across all objects.
    layout_col_count/2,
    % layout_is_grid/3: objects form an R x C grid by centroid position (R*C=|Objs|).
    layout_is_grid/3,
    % layout_is_diagonal_dr/1: all centroids on the same downward-right diagonal (R-C constant).
    layout_is_diagonal_dr/1,
    % layout_is_diagonal_dl/1: all centroids on the same downward-left diagonal (R+C constant).
    layout_is_diagonal_dl/1,
    % layout_gap_h/2: uniform horizontal gap between centroid-col-sorted objects; fails if not uniform.
    layout_gap_h/2,
    % layout_gap_v/2: uniform vertical gap between centroid-row-sorted objects; fails if not uniform.
    layout_gap_v/2
]).

% Import list utilities; msort/2, length/2, sort/2, findall/3 are built-ins.
:- use_module(library(lists), [member/2, min_list/2, max_list/2, sum_list/2]).

% layout_global_bbox(+Objs, -R1, -C1, -R2, -C2): bounding box over ALL cells of all objects.
% R1,C1 is the top-left corner (min row, min col); R2,C2 is the bottom-right.
layout_global_bbox(Objs, R1, C1, R2, C2) :-
% Collect every cell from every object.
    findall(R, (member(obj(_,Cells), Objs), member(r(R,_), Cells)), Rs),
    findall(C, (member(obj(_,Cells), Objs), member(r(_,C), Cells)), Cs),
% Global bounding box spans min to max in each dimension.
    min_list(Rs, R1),
    max_list(Rs, R2),
    min_list(Cs, C1),
    max_list(Cs, C2).

% layout_bbox_area(+Objs, -Area): number of cells in the global bounding box.
% Area = (R2-R1+1) * (C2-C1+1).
layout_bbox_area(Objs, Area) :-
% Compute the global bounding box.
    layout_global_bbox(Objs, R1, C1, R2, C2),
% Area is width times height.
    Area is (R2 - R1 + 1) * (C2 - C1 + 1).

% layout_row_range(+Objs, -MinTopR, -MaxTopR): range of topmost rows (min-row of each object).
layout_row_range(Objs, MinTopR, MaxTopR) :-
% Compute the topmost row of each object (minimum row in its cell list).
    findall(MinR, (
        member(obj(_,Cells), Objs),
        findall(R, member(r(R,_), Cells), Rs),
        min_list(Rs, MinR)
    ), TopRows),
    min_list(TopRows, MinTopR),
    max_list(TopRows, MaxTopR).

% layout_col_range(+Objs, -MinLeftC, -MaxLeftC): range of leftmost columns.
layout_col_range(Objs, MinLeftC, MaxLeftC) :-
% Compute the leftmost column of each object (minimum col in its cell list).
    findall(MinC, (
        member(obj(_,Cells), Objs),
        findall(C, member(r(_,C), Cells), Cs),
        min_list(Cs, MinC)
    ), LeftCols),
    min_list(LeftCols, MinLeftC),
    max_list(LeftCols, MaxLeftC).

% layout_all_same_row(+Objs): succeed iff all objects share the same topmost row.
% Vacuously true for empty list.
layout_all_same_row([]) :- !.
layout_all_same_row(Objs) :-
% Collect topmost rows; after sort, exactly one distinct value must remain.
    findall(MinR, (
        member(obj(_,Cells), Objs),
        findall(R, member(r(R,_), Cells), Rs),
        min_list(Rs, MinR)
    ), TopRows),
    sort(TopRows, [_]).

% layout_all_same_col(+Objs): succeed iff all objects share the same leftmost column.
layout_all_same_col([]) :- !.
layout_all_same_col(Objs) :-
% Collect leftmost columns; after sort, exactly one distinct value must remain.
    findall(MinC, (
        member(obj(_,Cells), Objs),
        findall(C, member(r(_,C), Cells), Cs),
        min_list(Cs, MinC)
    ), LeftCols),
    sort(LeftCols, [_]).

% layout_centroid_of_all(+Objs, -R, -C): integer-truncated centroid of all obj centroids.
% Averages the individual centroid row values and the individual centroid col values.
layout_centroid_of_all(Objs, R, C) :-
% Compute centroid of each object.
    findall(Rc-Cc, (member(O, Objs), layout_centroid_(O, Rc, Cc)), Pairs),
% Collect all centroid rows and cols.
    findall(Rc, member(Rc-_, Pairs), Rs),
    findall(Cc, member(_-Cc, Pairs), Cs),
    length(Objs, N),
    sum_list(Rs, SumR),
    sum_list(Cs, SumC),
% Integer-truncate the average.
    R is SumR // N,
    C is SumC // N.

% layout_centroid_(+Obj, -R, -C): private centroid helper.
layout_centroid_(obj(_,Cells), R, C) :-
    findall(Rr, member(r(Rr,_), Cells), Rs),
    sum_list(Rs, SumR),
    findall(Cc, member(r(_,Cc), Cells), Cs),
    sum_list(Cs, SumC),
    length(Cells, N),
    R is SumR // N,
    C is SumC // N.

% layout_row_count(+Objs, -N): number of distinct topmost rows across all objects.
layout_row_count(Objs, N) :-
% Collect and deduplicate topmost rows.
    findall(MinR, (
        member(obj(_,Cells), Objs),
        findall(R, member(r(R,_), Cells), Rs),
        min_list(Rs, MinR)
    ), TopRows),
    sort(TopRows, Unique),
    length(Unique, N).

% layout_col_count(+Objs, -N): number of distinct leftmost columns.
layout_col_count(Objs, N) :-
% Collect and deduplicate leftmost columns.
    findall(MinC, (
        member(obj(_,Cells), Objs),
        findall(C, member(r(_,C), Cells), Cs),
        min_list(Cs, MinC)
    ), LeftCols),
    sort(LeftCols, Unique),
    length(Unique, N).

% layout_is_grid(+Objs, -Rows, -Cols): objects form a Rows x Cols grid by centroid position.
% Rows is the number of distinct centroid row values; Cols is distinct centroid col values.
% Grid condition: |Objs| = Rows * Cols AND every (row, col) centroid combination is occupied.
layout_is_grid(Objs, Rows, Cols) :-
% Collect all centroid positions.
    findall(Rc-Cc, (member(O, Objs), layout_centroid_(O, Rc, Cc)), CentroidPairs),
% Get distinct centroid rows and distinct centroid cols.
    findall(Rc, member(Rc-_, CentroidPairs), CRows0),
    sort(CRows0, CRows),
    findall(Cc, member(_-Cc, CentroidPairs), CCols0),
    sort(CCols0, CCols),
    length(CRows, Rows),
    length(CCols, Cols),
% Every row-col combination must appear in the centroid pairs.
    \+ (member(R, CRows), member(C, CCols), \+ member(R-C, CentroidPairs)),
% Total count must equal Rows * Cols (no duplicate centroids).
    length(Objs, N),
    N =:= Rows * Cols.

% layout_is_diagonal_dr(+Objs): all obj centroids lie on the same downward-right diagonal.
% Downward-right diagonal: R - C is constant for all centroids.
layout_is_diagonal_dr([]) :- !.
layout_is_diagonal_dr(Objs) :-
% Compute R-C for each centroid; after sort, exactly one distinct value remains.
    findall(D, (member(O, Objs), layout_centroid_(O, R, C), D is R - C), Ds),
    sort(Ds, [_]).

% layout_is_diagonal_dl(+Objs): all obj centroids lie on the same downward-left diagonal.
% Downward-left diagonal: R + C is constant for all centroids.
layout_is_diagonal_dl([]) :- !.
layout_is_diagonal_dl(Objs) :-
% Compute R+C for each centroid; after sort, exactly one distinct value remains.
    findall(S, (member(O, Objs), layout_centroid_(O, R, C), S is R + C), Ss),
    sort(Ss, [_]).

% layout_gap_h(+Objs, -Gap): uniform horizontal gap between objects sorted by centroid column.
% Gap is the common column difference between consecutive sorted centroids.
% Fails if gaps are non-uniform, Objs has fewer than 2 objects, or all at same col.
layout_gap_h(Objs, Gap) :-
% Collect centroid col values.
    findall(Cc-O, (member(O, Objs), layout_centroid_(O, _, Cc)), Pairs),
% Stable sort by centroid col ascending.
    msort(Pairs, SortedPairs),
% Extract col values in sorted order.
    findall(Cc, member(Cc-_, SortedPairs), Cols),
% Compute consecutive differences.
    layout_diffs_(Cols, Gaps),
% All gaps must be equal and positive.
    Gaps = [Gap|_],
    Gap > 0,
    \+ (member(G, Gaps), G =\= Gap).

% layout_gap_v(+Objs, -Gap): uniform vertical gap between objects sorted by centroid row.
layout_gap_v(Objs, Gap) :-
% Collect centroid row values.
    findall(Rc-O, (member(O, Objs), layout_centroid_(O, Rc, _)), Pairs),
% Stable sort by centroid row ascending.
    msort(Pairs, SortedPairs),
    findall(Rc, member(Rc-_, SortedPairs), Rows),
% Compute consecutive differences.
    layout_diffs_(Rows, Gaps),
    Gaps = [Gap|_],
    Gap > 0,
    \+ (member(G, Gaps), G =\= Gap).

% layout_diffs_(+List, -Diffs): consecutive differences of a list of numbers.
% Requires at least 2 elements.
layout_diffs_([_], []) :- !.
layout_diffs_([A, B | T], [D|Ds]) :-
% Difference between consecutive elements.
    D is B - A,
    layout_diffs_([B|T], Ds).
