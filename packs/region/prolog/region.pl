% region.pl - Layer 92: Grid Region Extraction by Separator Lines (rg_* prefix).
% Divides a grid into sections using rows or columns where every cell equals a
% separator value (Sep). Provides predicates for finding separators, computing
% section spans, cutting grids into lists of sub-grids, assembling 2D section
% matrices, and extracting the region containing a given cell.
:- module(region, [
    rg_sep_rows/3,
    rg_sep_cols/3,
    rg_is_sep_row/3,
    rg_is_sep_col/3,
    rg_spans_h/3,
    rg_spans_v/3,
    rg_cut_h/3,
    rg_cut_v/3,
    rg_sections/3,
    rg_section_h/4,
    rg_section_v/4,
    rg_count_h/3,
    rg_count_v/3,
    rg_region/5
]).
% Import list utilities; length/2 is a built-in, not imported.
:- use_module(library(lists), [nth0/3, numlist/3]).
% Import higher-order utilities.
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% rg_spans_from_seps_: compute non-separator spans from a sorted separator index list.
% Spans is a list of R0-R1 inclusive bounds for each section in [Lo..MaxIdx].
rg_spans_from_seps_([], Lo, MaxIdx, Spans) :-
% Base: if Lo is within bounds, one final span covers Lo to MaxIdx.
    (Lo =< MaxIdx -> Spans = [Lo-MaxIdx] ; Spans = []).
rg_spans_from_seps_([S|Rest], Lo, MaxIdx, Spans) :-
% Compute the last non-separator row/col before this separator.
    PrevEnd is S - 1,
% Compute the first row/col after this separator.
    NextLo is S + 1,
% Recursively find spans for the tail separators.
    rg_spans_from_seps_(Rest, NextLo, MaxIdx, RestSpans),
% If there is a non-empty section before this separator, prepend it.
    (Lo =< PrevEnd ->
        Spans = [Lo-PrevEnd|RestSpans]
    ;
        Spans = RestSpans
    ).

% rg_find_span_: find the span (S0-S1) in Spans that contains Idx.
% Uses first-match with cut; fails if Idx is in a separator position.
rg_find_span_([S0-S1|_], Idx, S0-S1) :- Idx >= S0, Idx =< S1, !.
rg_find_span_([_|Rest], Idx, Span) :-
% Continue searching the rest of the spans.
    rg_find_span_(Rest, Idx, Span).

% rg_extract_subgrid_: extract rows R0..R1 and cols C0..C1 inclusive from Grid.
rg_extract_subgrid_(Grid, R0, R1, C0, C1, Region) :-
% Build inclusive row index list.
    numlist(R0, R1, RowIdxs),
% Build inclusive column index list.
    numlist(C0, C1, ColIdxs),
% For each row, extract only the columns in ColIdxs.
    maplist([R, Row]>>(
        nth0(R, Grid, GRow),
        maplist([C, V]>>(nth0(C, GRow, V)), ColIdxs, Row)
    ), RowIdxs, Region).

% rg_is_sep_row(+Grid, +R, +Sep): succeed if every cell in row R equals Sep.
rg_is_sep_row(Grid, R, Sep) :-
% Extract the specified row.
    nth0(R, Grid, Row),
% Every element in the row must equal Sep.
    maplist(=(Sep), Row).

% rg_is_sep_col(+Grid, +C, +Sep): succeed if every cell in column C equals Sep.
rg_is_sep_col(Grid, C, Sep) :-
% For every row, the Cth cell must equal Sep.
    maplist([Row]>>(nth0(C, Row, Sep)), Grid).

% rg_sep_rows(+Grid, +Sep, -IdxList): sorted list of row indices where every cell equals Sep.
rg_sep_rows(Grid, Sep, IdxList) :-
% Count grid rows to build the index range.
    length(Grid, NR),
    NR1 is NR - 1,
    numlist(0, NR1, AllRows),
% Keep only rows that are entirely Sep.
    include([R]>>(rg_is_sep_row(Grid, R, Sep)), AllRows, IdxList).

% rg_sep_cols(+Grid, +Sep, -IdxList): sorted list of column indices where every cell equals Sep.
rg_sep_cols(Grid, Sep, IdxList) :-
% Get column count from the first row.
    Grid = [FirstRow|_],
    length(FirstRow, NC),
    NC1 is NC - 1,
    numlist(0, NC1, AllCols),
% Keep only columns that are entirely Sep.
    include([C]>>(rg_is_sep_col(Grid, C, Sep)), AllCols, IdxList).

% rg_spans_h(+Grid, +Sep, -Spans): row spans of non-separator horizontal sections.
% Spans is a list of R0-R1 inclusive pairs, one per section, in order.
rg_spans_h(Grid, Sep, Spans) :-
% Get the maximum row index.
    length(Grid, NR),
    NR1 is NR - 1,
% Find all separator rows.
    rg_sep_rows(Grid, Sep, SepRows),
% Compute the non-separator spans.
    rg_spans_from_seps_(SepRows, 0, NR1, Spans).

% rg_spans_v(+Grid, +Sep, -Spans): column spans of non-separator vertical sections.
rg_spans_v(Grid, Sep, Spans) :-
% Get the maximum column index from the first row.
    Grid = [FirstRow|_],
    length(FirstRow, NC),
    NC1 is NC - 1,
% Find all separator columns.
    rg_sep_cols(Grid, Sep, SepCols),
% Compute the non-separator spans.
    rg_spans_from_seps_(SepCols, 0, NC1, Spans).

% rg_cut_h(+Grid, +Sep, -Parts): split Grid at separator rows.
% Parts is a list of sub-grids, one per horizontal section. Separator rows are excluded.
rg_cut_h(Grid, Sep, Parts) :-
% Find horizontal section spans.
    rg_spans_h(Grid, Sep, Spans),
% Extract each row span as a sub-grid.
    maplist([R0-R1, Part]>>(
        numlist(R0, R1, RowIdxs),
        maplist([R, Row]>>(nth0(R, Grid, Row)), RowIdxs, Part)
    ), Spans, Parts).

% rg_cut_v(+Grid, +Sep, -Parts): split Grid at separator columns.
% Parts is a list of sub-grids, one per vertical section. Separator columns are excluded.
rg_cut_v(Grid, Sep, Parts) :-
% Find vertical section spans.
    rg_spans_v(Grid, Sep, Spans),
% Get row count for iterating.
    length(Grid, NR),
    NR1 is NR - 1,
    numlist(0, NR1, RowIdxs),
% Extract each column span as a sub-grid.
    maplist([C0-C1, Part]>>(
        numlist(C0, C1, ColIdxs),
        maplist([R, PartRow]>>(
            nth0(R, Grid, GRow),
            maplist([C, V]>>(nth0(C, GRow, V)), ColIdxs, PartRow)
        ), RowIdxs, Part)
    ), Spans, Parts).

% rg_sections(+Grid, +Sep, -Matrix): split Grid at both separator rows and separator columns.
% Matrix is a list of rows of sub-grids: Matrix[I][J] is the sub-grid at row-section I, col-section J.
rg_sections(Grid, Sep, Matrix) :-
% First cut horizontally to get horizontal strips.
    rg_cut_h(Grid, Sep, HStrips),
% Then cut each strip vertically to get the column sections.
    maplist([Strip, VSections]>>(rg_cut_v(Strip, Sep, VSections)), HStrips, Matrix).

% rg_section_h(+Grid, +Sep, +N, -Section): N-th horizontal section (1-indexed).
% Fails if N is out of range.
rg_section_h(Grid, Sep, N, Section) :-
% Get all horizontal sections.
    rg_cut_h(Grid, Sep, Parts),
% Convert to 0-indexed.
    Idx is N - 1,
% Retrieve the section.
    nth0(Idx, Parts, Section).

% rg_section_v(+Grid, +Sep, +N, -Section): N-th vertical section (1-indexed).
rg_section_v(Grid, Sep, N, Section) :-
% Get all vertical sections.
    rg_cut_v(Grid, Sep, Parts),
% Convert to 0-indexed.
    Idx is N - 1,
    nth0(Idx, Parts, Section).

% rg_count_h(+Grid, +Sep, -N): number of horizontal sections in Grid.
rg_count_h(Grid, Sep, N) :-
% Compute spans; count equals number of spans.
    rg_spans_h(Grid, Sep, Spans),
    length(Spans, N).

% rg_count_v(+Grid, +Sep, -N): number of vertical sections in Grid.
rg_count_v(Grid, Sep, N) :-
% Compute spans; count equals number of spans.
    rg_spans_v(Grid, Sep, Spans),
    length(Spans, N).

% rg_region(+Grid, +Sep, +R, +C, -Region): sub-grid of the section containing cell (R,C).
% The region is bounded by the nearest separator rows above/below and separator columns left/right.
% Fails if (R,C) is itself a separator row or column.
rg_region(Grid, Sep, R, C, Region) :-
% Find all horizontal section spans.
    rg_spans_h(Grid, Sep, HSpans),
% Find all vertical section spans.
    rg_spans_v(Grid, Sep, VSpans),
% Find which horizontal span contains row R.
    rg_find_span_(HSpans, R, R0-R1),
% Find which vertical span contains column C.
    rg_find_span_(VSpans, C, C0-C1),
% Extract the sub-grid at the resolved bounds.
    rg_extract_subgrid_(Grid, R0, R1, C0, C1, Region).
