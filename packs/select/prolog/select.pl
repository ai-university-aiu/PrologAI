% Module declaration: select pack, Layer 53.
:- module(select, [
    % select_largest/2: region with the most cells.
    select_largest/2,
    % select_smallest/2: region with the fewest cells.
    select_smallest/2,
    % select_sort_by_area/2: sort regions by cell count ascending.
    select_sort_by_area/2,
    % select_filter_area/3: keep regions with exactly N cells.
    select_filter_area/3,
    % select_filter_area_min/3: keep regions with at least Min cells.
    select_filter_area_min/3,
    % select_filter_area_max/3: keep regions with at most Max cells.
    select_filter_area_max/3,
    % select_touches_border/3: test whether a region touches the grid border.
    select_touches_border/3,
    % select_filter_border/4: keep regions that touch the grid border.
    select_filter_border/4,
    % select_filter_interior/4: keep regions that do not touch the grid border.
    select_filter_interior/4,
    % select_above_row/3: keep regions with all cells strictly above a row index.
    select_above_row/3,
    % select_below_row/3: keep regions with all cells at or below a row index.
    select_below_row/3,
    % select_left_of_col/3: keep regions with all cells strictly left of a column.
    select_left_of_col/3,
    % select_right_of_col/3: keep regions with all cells at or right of a column.
    select_right_of_col/3,
    % select_unique_area/2: keep regions whose cell count is unique in the list.
    select_unique_area/2
]).

% Import list utilities; length/2, msort/2, keysort/2 are built-ins.
:- use_module(library(lists),  [member/2, nth0/3, max_list/2, min_list/2]).
:- use_module(library(apply),  [maplist/2, maplist/3, include/3, exclude/3]).

% select_area_(+Region, -N): area of a region is its cell count.
select_area_(Region, N) :-
    % Delegate to the built-in length predicate.
    length(Region, N).

% select_areas_(+Regions, -Areas): collect areas of all regions.
select_areas_([], []).
select_areas_([R|Rs], [N|Ns]) :-
    % Measure the head region.
    select_area_(R, N),
    % Recurse on the tail.
    select_areas_(Rs, Ns).

% select_strip_keys_(+Pairs, -Values): extract values from key-value pairs.
select_strip_keys_([], []).
select_strip_keys_([_-V|T], [V|Vs]) :-
    % Discard the key, keep the value.
    select_strip_keys_(T, Vs).

% select_largest(+Regions, -Largest): the region with the maximum cell count.
select_largest(Regions, Largest) :-
    % Require at least one region.
    Regions = [_|_],
    % Compute all areas.
    select_areas_(Regions, Areas),
    % Find the maximum area.
    max_list(Areas, MaxArea),
    % Locate the first region with that area.
    nth0(Idx, Areas, MaxArea), !,
    % Return it.
    nth0(Idx, Regions, Largest).

% select_smallest(+Regions, -Smallest): the region with the minimum cell count.
select_smallest(Regions, Smallest) :-
    % Require at least one region.
    Regions = [_|_],
    % Compute all areas.
    select_areas_(Regions, Areas),
    % Find the minimum area.
    min_list(Areas, MinArea),
    % Locate the first region with that area.
    nth0(Idx, Areas, MinArea), !,
    % Return it.
    nth0(Idx, Regions, Smallest).

% select_sort_by_area(+Regions, -Sorted): regions sorted by cell count ascending.
select_sort_by_area(Regions, Sorted) :-
    % Pair each region with its area as the sort key.
    maplist([R, N-R]>>(length(R, N)), Regions, Keyed),
    % Sort by key (area) using the built-in stable keysort.
    keysort(Keyed, SortedKeyed),
    % Strip keys to produce the sorted region list.
    select_strip_keys_(SortedKeyed, Sorted).

% select_filter_area(+Regions, +N, -Filtered): keep regions with exactly N cells.
select_filter_area(Regions, N, Filtered) :-
    % Retain only regions whose area equals N.
    include([R]>>(length(R, A), A =:= N), Regions, Filtered).

% select_filter_area_min(+Regions, +Min, -Filtered): keep regions with area >= Min.
select_filter_area_min(Regions, Min, Filtered) :-
    % Retain only regions meeting the minimum area constraint.
    include([R]>>(length(R, A), A >= Min), Regions, Filtered).

% select_filter_area_max(+Regions, +Max, -Filtered): keep regions with area <= Max.
select_filter_area_max(Regions, Max, Filtered) :-
    % Retain only regions meeting the maximum area constraint.
    include([R]>>(length(R, A), A =< Max), Regions, Filtered).

% select_on_border_(+Rows, +Cols, +Cell): test whether a cell is on the grid border.
select_on_border_(Rows, Cols, r(R, C)) :-
    % Compute the maximum valid row and column indices.
    MaxR is Rows - 1,
    MaxC is Cols - 1,
    % Succeed if the cell is on any of the four edges.
    ( R =:= 0 ; R =:= MaxR ; C =:= 0 ; C =:= MaxC ).

% select_touches_border(+Region, +Rows, +Cols): true when any cell is on the border.
select_touches_border(Region, Rows, Cols) :-
    % Grid must be non-empty.
    Rows > 0, Cols > 0,
    % Find the first border cell (cut after first success).
    member(Cell, Region),
    select_on_border_(Rows, Cols, Cell), !.

% select_filter_border(+Regions, +Rows, +Cols, -Filtered): keep border-touching regions.
select_filter_border(Regions, Rows, Cols, Filtered) :-
    % Retain regions that have at least one border cell.
    include([R]>>(select_touches_border(R, Rows, Cols)), Regions, Filtered).

% select_filter_interior(+Regions, +Rows, +Cols, -Filtered): keep non-border regions.
select_filter_interior(Regions, Rows, Cols, Filtered) :-
    % Retain regions with no cell on the border.
    exclude([R]>>(select_touches_border(R, Rows, Cols)), Regions, Filtered).

% select_all_above_(+Row, +Region): all cells in Region have row index < Row.
select_all_above_(Row, Region) :-
    % Fail if any cell has row >= Row.
    \+ (member(r(Ri, _), Region), Ri >= Row).

% select_above_row(+Regions, +Row, -Filtered): keep regions entirely above Row.
select_above_row(Regions, Row, Filtered) :-
    % Retain regions where every cell is strictly above Row.
    include(select_all_above_(Row), Regions, Filtered).

% select_all_below_(+Row, +Region): all cells in Region have row index >= Row.
select_all_below_(Row, Region) :-
    % Fail if any cell has row < Row.
    \+ (member(r(Ri, _), Region), Ri < Row).

% select_below_row(+Regions, +Row, -Filtered): keep regions at or below Row.
select_below_row(Regions, Row, Filtered) :-
    % Retain regions where every cell is at or below Row.
    include(select_all_below_(Row), Regions, Filtered).

% select_all_left_(+Col, +Region): all cells in Region have col index < Col.
select_all_left_(Col, Region) :-
    % Fail if any cell has col >= Col.
    \+ (member(r(_, Ci), Region), Ci >= Col).

% select_left_of_col(+Regions, +Col, -Filtered): keep regions entirely left of Col.
select_left_of_col(Regions, Col, Filtered) :-
    % Retain regions where every cell is strictly left of Col.
    include(select_all_left_(Col), Regions, Filtered).

% select_all_right_(+Col, +Region): all cells in Region have col index >= Col.
select_all_right_(Col, Region) :-
    % Fail if any cell has col < Col.
    \+ (member(r(_, Ci), Region), Ci < Col).

% select_right_of_col(+Regions, +Col, -Filtered): keep regions at or right of Col.
select_right_of_col(Regions, Col, Filtered) :-
    % Retain regions where every cell is at or right of Col.
    include(select_all_right_(Col), Regions, Filtered).

% select_appears_once_(+Areas, +Area): Area appears exactly once in the Areas list.
select_appears_once_(Areas, Area) :-
    % Count occurrences by filtering to exact matches.
    include(=(Area), Areas, Matches),
    % Exactly one match means unique area.
    length(Matches, 1).

% select_unique_area(+Regions, -Unique): keep regions whose area appears only once.
select_unique_area(Regions, Unique) :-
    % Collect all areas.
    select_areas_(Regions, Areas),
    % Keep only regions whose area is unique in the list.
    include([R]>>(length(R, N), select_appears_once_(Areas, N)), Regions, Unique).
