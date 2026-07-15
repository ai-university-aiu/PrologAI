% patch.pl - Layer 108: Sub-Grid Extraction and Template Matching (pa_* prefix).
% Provides predicates for extracting rectangular patches from grids, matching
% a small pattern inside a larger grid (template matching), enumerating all
% overlapping sub-grids, computing patch differences, testing uniformity, and
% performing 2D geometric operations (flip, rotate) on patches.
:- module(patch, [
    patch_extract/6,
    patch_dims/3,
    patch_match/4,
    patch_match_all/3,
    patch_match_count/3,
    patch_match_bg/4,
    patch_slides/4,
    patch_unique_patches/4,
    patch_most_common_patch/5,
    patch_diff/3,
    patch_is_uniform/2,
    patch_flip_h/2,
    patch_flip_v/2,
    patch_rot90/2
]).
% Import list utilities needed by the patch predicates.
:- use_module(library(lists), [member/2, nth0/3, append/3, reverse/2, last/2]).
% Import higher-order utilities.
:- use_module(library(apply), [maplist/3]).

% patch_take_cols_: extract W consecutive values from Row starting at column C0.
patch_take_cols_(Row, C0, W, SubRow) :-
% Build a prefix list of length C0 to skip the leading columns.
    length(Skip, C0),
% Split Row into the skipped prefix and the remaining suffix.
    append(Skip, Suffix, Row),
% Take exactly W elements from the suffix as the sub-row.
    length(SubRow, W),
    append(SubRow, _, Suffix).

% patch_extract(+Grid, +R0, +C0, +H, +W, -Patch): Patch is the H x W sub-grid
% of Grid starting at row R0 (0-based) and column C0. Fails if R0+H or C0+W
% exceeds the grid dimensions.
patch_extract(Grid, R0, C0, H, W, Patch) :-
% Compute the last row index inclusive.
    R1 is R0 + H - 1,
% Collect sub-rows for each row in the range.
    findall(SubRow, (
        between(R0, R1, R),
        nth0(R, Grid, FullRow),
        patch_take_cols_(FullRow, C0, W, SubRow)
    ), Patch).

% patch_dims(+Patch, -H, -W): H is the number of rows and W is the number of
% columns in Patch. An empty patch has H=0, W=0.
patch_dims(Patch, H, W) :-
% Length of the outer list gives the row count.
    length(Patch, H),
    (Patch = [Row | _] -> length(Row, W) ; W = 0).

% patch_match(+Grid, +Patch, -R0, -C0): non-deterministically enumerate all
% 0-based positions (R0, C0) where Patch occurs exactly in Grid. Backtracks
% over all matching positions.
patch_match(Grid, Patch, R0, C0) :-
% Get grid and patch dimensions to compute the valid starting range.
    patch_dims(Grid, NR, NC),
    patch_dims(Patch, H, W),
    MaxR0 is NR - H,
    MaxC0 is NC - W,
% Enumerate all candidate top-left corners.
    between(0, MaxR0, R0),
    between(0, MaxC0, C0),
% Succeed only if the extracted sub-grid equals Patch exactly.
    patch_extract(Grid, R0, C0, H, W, Patch).

% patch_match_all(+Grid, +Patch, -Positions): Positions is the list of all R0-C0
% pairs (in row-major enumeration order) where Patch occurs exactly in Grid.
patch_match_all(Grid, Patch, Positions) :-
    findall(R0-C0, patch_match(Grid, Patch, R0, C0), Positions).

% patch_match_count(+Grid, +Patch, -N): N is the number of positions in Grid
% where Patch occurs exactly.
patch_match_count(Grid, Patch, N) :-
    patch_match_all(Grid, Patch, Positions),
    length(Positions, N).

% patch_cell_bg_match_: test that a patch cell PV matches a grid cell SV with
% background wildcard semantics: if PV equals Bg it matches any SV; otherwise
% PV must equal SV exactly.
patch_cell_bg_match_(PV, SV, Bg) :-
    (PV =:= Bg -> true ; PV =:= SV).

% patch_row_bg_match_: test that all corresponding cells in a patch row and a
% grid row satisfy the background wildcard match.
patch_row_bg_match_([], [], _Bg).
patch_row_bg_match_([PV | PRest], [SV | SRest], Bg) :-
    patch_cell_bg_match_(PV, SV, Bg),
    patch_row_bg_match_(PRest, SRest, Bg).

% patch_patch_bg_match_: test that all rows of Patch match the corresponding rows
% of Sub under the background wildcard rule.
patch_patch_bg_match_([], [], _Bg).
patch_patch_bg_match_([PR | PRest], [SR | SRest], Bg) :-
    patch_row_bg_match_(PR, SR, Bg),
    patch_patch_bg_match_(PRest, SRest, Bg).

% patch_match_bg(+Grid, +Patch, +Bg, -Positions): Positions is the list of all
% R0-C0 pairs where Patch matches Grid with Bg treated as a wildcard: a Bg
% cell in Patch matches any cell value in Grid. Non-Bg cells must match exactly.
patch_match_bg(Grid, Patch, Bg, Positions) :-
    patch_dims(Grid, NR, NC),
    patch_dims(Patch, H, W),
    MaxR0 is NR - H,
    MaxC0 is NC - W,
    findall(R0-C0, (
        between(0, MaxR0, R0),
        between(0, MaxC0, C0),
        patch_extract(Grid, R0, C0, H, W, Sub),
        patch_patch_bg_match_(Patch, Sub, Bg)
    ), Positions).

% patch_slides(+Grid, +H, +W, -Patches): Patches is the list of all overlapping
% H x W sub-patches in row-major order, each represented as R0-C0-Patch.
patch_slides(Grid, H, W, Patches) :-
    patch_dims(Grid, NR, NC),
    MaxR0 is NR - H,
    MaxC0 is NC - W,
    findall(R0-C0-Patch, (
        between(0, MaxR0, R0),
        between(0, MaxC0, C0),
        patch_extract(Grid, R0, C0, H, W, Patch)
    ), Patches).

% patch_unique_patches(+Grid, +H, +W, -Unique): Unique is the sorted list of
% all distinct H x W patches that appear at least once in Grid.
patch_unique_patches(Grid, H, W, Unique) :-
    patch_slides(Grid, H, W, Slides),
% Extract just the patch part from each R0-C0-Patch triple.
    findall(P, member(_-_-P, Slides), All),
% Sort removes duplicates (structural equality).
    sort(All, Unique).

% patch_run_count_: count consecutive occurrences of P at the head of a sorted
% list; Rest is the list tail after the run ends.
patch_run_count_([], _, 0, []).
patch_run_count_([Q | Rest], P, N, Remaining) :-
% Use structural equality for comparing list-of-list patch terms.
    (Q == P ->
        patch_run_count_(Rest, P, N1, Remaining),
        N is N1 + 1
    ;
        N = 0, Remaining = [Q | Rest]
    ).

% patch_count_groups_: convert a sorted list into a list of Count-Element pairs.
patch_count_groups_([], []).
patch_count_groups_([P | Rest], [N-P | Groups]) :-
% Count occurrences of P at the head of the sorted list.
    patch_run_count_(Rest, P, N1, Remaining),
    N is N1 + 1,
    patch_count_groups_(Remaining, Groups).

% patch_most_common_patch(+Grid, +H, +W, -Patch, -Count): Patch is the H x W
% sub-patch that appears most often in Grid; Count is its occurrence count.
% On ties the patch that is first in sort order wins. Fails if no patches exist.
patch_most_common_patch(Grid, H, W, Patch, Count) :-
    patch_slides(Grid, H, W, Slides),
    Slides = [_ | _],
    findall(P, member(_-_-P, Slides), All),
% msort preserves duplicates; equal patches end up adjacent.
    msort(All, Sorted),
    patch_count_groups_(Sorted, Groups),
% Sort Count-Patch pairs: highest count comes last.
    msort(Groups, SortedGroups),
    last(SortedGroups, Count-Patch).

% patch_diff(+PatchA, +PatchB, -Cells): Cells is the sorted list of R-C pairs
% where PatchA and PatchB have different values. Both patches must be the same
% size. Returns [] if the patches are identical.
patch_diff(PatchA, PatchB, Cells) :-
    patch_dims(PatchA, H, W),
    H1 is H - 1,
    W1 is W - 1,
    findall(R-C, (
        between(0, H1, R),
        between(0, W1, C),
        nth0(R, PatchA, RowA), nth0(C, RowA, VA),
        nth0(R, PatchB, RowB), nth0(C, RowB, VB),
        VA =\= VB
    ), Cells).

% patch_is_uniform(+Patch, -Color): succeed if every cell in Patch has the same
% value Color. Fails if Patch is empty or contains more than one value.
patch_is_uniform(Patch, Color) :-
    Patch = [[Color | _] | _],
% Verify every row has every cell equal to Color.
    forall(member(Row, Patch),
           forall(member(V, Row), V =:= Color)).

% patch_flip_h(+Patch, -Flipped): Flipped is Patch with each row reversed
% (horizontal/left-right mirror).
patch_flip_h(Patch, Flipped) :-
% reverse/2 called on each row: maplist applies reverse(Row, FlippedRow).
    maplist(reverse, Patch, Flipped).

% patch_flip_v(+Patch, -Flipped): Flipped is Patch with the row order reversed
% (vertical/top-bottom mirror).
patch_flip_v(Patch, Flipped) :-
% Reverse the list of rows.
    reverse(Patch, Flipped).

% patch_rot90(+Patch, -Rotated): Rotated is Patch rotated 90 degrees clockwise.
% For an H x W input, the output is W x H.
% Formula: Rotated(r', c') = Patch(H-1-c', r').
patch_rot90(Patch, Rotated) :-
    patch_dims(Patch, H, W),
    H1 is H - 1,
    W1 is W - 1,
% Each new row r' (0..W-1) is built from column r' of the reversed-row Patch.
    findall(NewRow, (
        between(0, W1, NewR),
        findall(V, (
            between(0, H1, NewC),
            OldR is H1 - NewC,
            OldC is NewR,
            nth0(OldR, Patch, OldRow),
            nth0(OldC, OldRow, V)
        ), NewRow)
    ), Rotated).
