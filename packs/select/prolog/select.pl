% Module declaration: select pack, Layer 53.
:- module(select, [
    % sl_largest/2: region with the most cells.
    sl_largest/2,
    % sl_smallest/2: region with the fewest cells.
    sl_smallest/2,
    % sl_sort_by_area/2: sort regions by cell count ascending.
    sl_sort_by_area/2,
    % sl_filter_area/3: keep regions with exactly N cells.
    sl_filter_area/3,
    % sl_filter_area_min/3: keep regions with at least Min cells.
    sl_filter_area_min/3,
    % sl_filter_area_max/3: keep regions with at most Max cells.
    sl_filter_area_max/3,
    % sl_touches_border/3: test whether a region touches the grid border.
    sl_touches_border/3,
    % sl_filter_border/4: keep regions that touch the grid border.
    sl_filter_border/4,
    % sl_filter_interior/4: keep regions that do not touch the grid border.
    sl_filter_interior/4,
    % sl_above_row/3: keep regions with all cells strictly above a row index.
    sl_above_row/3,
    % sl_below_row/3: keep regions with all cells at or below a row index.
    sl_below_row/3,
    % sl_left_of_col/3: keep regions with all cells strictly left of a column.
    sl_left_of_col/3,
    % sl_right_of_col/3: keep regions with all cells at or right of a column.
    sl_right_of_col/3,
    % sl_unique_area/2: keep regions whose cell count is unique in the list.
    sl_unique_area/2
]).

% Import list utilities; length/2, msort/2, keysort/2 are built-ins.
:- use_module(library(lists),  [member/2, nth0/3, max_list/2, min_list/2]).
:- use_module(library(apply),  [maplist/2, maplist/3, include/3, exclude/3]).

% sl_area_(+Region, -N): area of a region is its cell count.
sl_area_(Region, N) :-
    % Delegate to the built-in length predicate.
    length(Region, N).

% sl_areas_(+Regions, -Areas): collect areas of all regions.
sl_areas_([], []).
sl_areas_([R|Rs], [N|Ns]) :-
    % Measure the head region.
    sl_area_(R, N),
    % Recurse on the tail.
    sl_areas_(Rs, Ns).

% sl_strip_keys_(+Pairs, -Values): extract values from key-value pairs.
sl_strip_keys_([], []).
sl_strip_keys_([_-V|T], [V|Vs]) :-
    % Discard the key, keep the value.
    sl_strip_keys_(T, Vs).

% sl_largest(+Regions, -Largest): the region with the maximum cell count.
sl_largest(Regions, Largest) :-
    % Require at least one region.
    Regions = [_|_],
    % Compute all areas.
    sl_areas_(Regions, Areas),
    % Find the maximum area.
    max_list(Areas, MaxArea),
    % Locate the first region with that area.
    nth0(Idx, Areas, MaxArea), !,
    % Return it.
    nth0(Idx, Regions, Largest).

% sl_smallest(+Regions, -Smallest): the region with the minimum cell count.
sl_smallest(Regions, Smallest) :-
    % Require at least one region.
    Regions = [_|_],
    % Compute all areas.
    sl_areas_(Regions, Areas),
    % Find the minimum area.
    min_list(Areas, MinArea),
    % Locate the first region with that area.
    nth0(Idx, Areas, MinArea), !,
    % Return it.
    nth0(Idx, Regions, Smallest).

% sl_sort_by_area(+Regions, -Sorted): regions sorted by cell count ascending.
sl_sort_by_area(Regions, Sorted) :-
    % Pair each region with its area as the sort key.
    maplist([R, N-R]>>(length(R, N)), Regions, Keyed),
    % Sort by key (area) using the built-in stable keysort.
    keysort(Keyed, SortedKeyed),
    % Strip keys to produce the sorted region list.
    sl_strip_keys_(SortedKeyed, Sorted).

% sl_filter_area(+Regions, +N, -Filtered): keep regions with exactly N cells.
sl_filter_area(Regions, N, Filtered) :-
    % Retain only regions whose area equals N.
    include([R]>>(length(R, A), A =:= N), Regions, Filtered).

% sl_filter_area_min(+Regions, +Min, -Filtered): keep regions with area >= Min.
sl_filter_area_min(Regions, Min, Filtered) :-
    % Retain only regions meeting the minimum area constraint.
    include([R]>>(length(R, A), A >= Min), Regions, Filtered).

% sl_filter_area_max(+Regions, +Max, -Filtered): keep regions with area <= Max.
sl_filter_area_max(Regions, Max, Filtered) :-
    % Retain only regions meeting the maximum area constraint.
    include([R]>>(length(R, A), A =< Max), Regions, Filtered).

% sl_on_border_(+Rows, +Cols, +Cell): test whether a cell is on the grid border.
sl_on_border_(Rows, Cols, r(R, C)) :-
    % Compute the maximum valid row and column indices.
    MaxR is Rows - 1,
    MaxC is Cols - 1,
    % Succeed if the cell is on any of the four edges.
    ( R =:= 0 ; R =:= MaxR ; C =:= 0 ; C =:= MaxC ).

% sl_touches_border(+Region, +Rows, +Cols): true when any cell is on the border.
sl_touches_border(Region, Rows, Cols) :-
    % Grid must be non-empty.
    Rows > 0, Cols > 0,
    % Find the first border cell (cut after first success).
    member(Cell, Region),
    sl_on_border_(Rows, Cols, Cell), !.

% sl_filter_border(+Regions, +Rows, +Cols, -Filtered): keep border-touching regions.
sl_filter_border(Regions, Rows, Cols, Filtered) :-
    % Retain regions that have at least one border cell.
    include([R]>>(sl_touches_border(R, Rows, Cols)), Regions, Filtered).

% sl_filter_interior(+Regions, +Rows, +Cols, -Filtered): keep non-border regions.
sl_filter_interior(Regions, Rows, Cols, Filtered) :-
    % Retain regions with no cell on the border.
    exclude([R]>>(sl_touches_border(R, Rows, Cols)), Regions, Filtered).

% sl_all_above_(+Row, +Region): all cells in Region have row index < Row.
sl_all_above_(Row, Region) :-
    % Fail if any cell has row >= Row.
    \+ (member(r(Ri, _), Region), Ri >= Row).

% sl_above_row(+Regions, +Row, -Filtered): keep regions entirely above Row.
sl_above_row(Regions, Row, Filtered) :-
    % Retain regions where every cell is strictly above Row.
    include(sl_all_above_(Row), Regions, Filtered).

% sl_all_below_(+Row, +Region): all cells in Region have row index >= Row.
sl_all_below_(Row, Region) :-
    % Fail if any cell has row < Row.
    \+ (member(r(Ri, _), Region), Ri < Row).

% sl_below_row(+Regions, +Row, -Filtered): keep regions at or below Row.
sl_below_row(Regions, Row, Filtered) :-
    % Retain regions where every cell is at or below Row.
    include(sl_all_below_(Row), Regions, Filtered).

% sl_all_left_(+Col, +Region): all cells in Region have col index < Col.
sl_all_left_(Col, Region) :-
    % Fail if any cell has col >= Col.
    \+ (member(r(_, Ci), Region), Ci >= Col).

% sl_left_of_col(+Regions, +Col, -Filtered): keep regions entirely left of Col.
sl_left_of_col(Regions, Col, Filtered) :-
    % Retain regions where every cell is strictly left of Col.
    include(sl_all_left_(Col), Regions, Filtered).

% sl_all_right_(+Col, +Region): all cells in Region have col index >= Col.
sl_all_right_(Col, Region) :-
    % Fail if any cell has col < Col.
    \+ (member(r(_, Ci), Region), Ci < Col).

% sl_right_of_col(+Regions, +Col, -Filtered): keep regions at or right of Col.
sl_right_of_col(Regions, Col, Filtered) :-
    % Retain regions where every cell is at or right of Col.
    include(sl_all_right_(Col), Regions, Filtered).

% sl_appears_once_(+Areas, +Area): Area appears exactly once in the Areas list.
sl_appears_once_(Areas, Area) :-
    % Count occurrences by filtering to exact matches.
    include(=(Area), Areas, Matches),
    % Exactly one match means unique area.
    length(Matches, 1).

% sl_unique_area(+Regions, -Unique): keep regions whose area appears only once.
sl_unique_area(Regions, Unique) :-
    % Collect all areas.
    sl_areas_(Regions, Areas),
    % Keep only regions whose area is unique in the list.
    include([R]>>(length(R, N), sl_appears_once_(Areas, N)), Regions, Unique).
