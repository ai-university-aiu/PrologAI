% Module declaration: obj pack, Layer 69.
:- module(obj, [
    % obj_from_cells/3: construct an object term from a color and a cell list.
    obj_from_cells/3,
    % obj_color/2: extract the color of an object.
    obj_color/2,
    % obj_cells/2: extract the sorted cell list of an object.
    obj_cells/2,
    % obj_size/2: number of cells in an object.
    obj_size/2,
    % obj_bbox/5: bounding box (MinR, MinC, MaxR, MaxC) of an object.
    obj_bbox/5,
    % obj_center/3: integer centroid row and column of an object.
    obj_center/3,
    % obj_shape/2: normalized cell offsets relative to the top-left of the bounding box.
    obj_shape/2,
    % obj_inventory/3: all 4-connected objects of a given color in a grid.
    obj_inventory/3,
    % obj_all/2: all objects of all non-zero colors in a grid.
    obj_all/2,
    % obj_count/3: number of 4-connected objects of a given color in a grid.
    obj_count/3,
    % obj_largest/3: largest object (most cells) of a given color.
    obj_largest/3,
    % obj_smallest/3: smallest object (fewest cells) of a given color.
    obj_smallest/3,
    % obj_at_cell/3: find which object from a list contains a given cell.
    obj_at_cell/3,
    % obj_sort_size/3: sort a list of objects by size ascending or descending.
    obj_sort_size/3
]).

% Import list utilities; msort/length/forall are built-ins, not imported.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3,
                                max_list/2, min_list/2, subtract/3]).
% Import higher-order apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).
% Import the connect pack for flood-fill component analysis.
:- use_module(library(connect), [connect_components4/3]).

% obj_from_cells(+Color, +Cells, -Obj).
% Construct an object term obj(Color, SortedCells).
obj_from_cells(Color, Cells, Obj) :-
    % Sort cells to canonical order for comparison.
    msort(Cells, Sorted),
    % Wrap in the obj/2 functor.
    Obj = obj(Color, Sorted).

% obj_color(+Obj, -Color).
% Extract the color stored in the object term.
obj_color(obj(Color, _), Color).

% obj_cells(+Obj, -Cells).
% Extract the sorted cell list stored in the object term.
obj_cells(obj(_, Cells), Cells).

% obj_size(+Obj, -N).
% N is the number of cells in the object.
obj_size(obj(_, Cells), N) :-
    % Count cells using length/2 built-in.
    length(Cells, N).

% obj_bbox(+Obj, -MinR, -MinC, -MaxR, -MaxC).
% Compute the axis-aligned bounding box of the object.
obj_bbox(obj(_, Cells), MinR, MinC, MaxR, MaxC) :-
    % Extract all row coordinates.
    maplist(obj_cell_r_, Cells, Rs),
    % Extract all column coordinates.
    maplist(obj_cell_c_, Cells, Cs),
    % Find extremes.
    min_list(Rs, MinR),
    max_list(Rs, MaxR),
    min_list(Cs, MinC),
    max_list(Cs, MaxC).

% obj_cell_r_(+Cell, -R): extract row from r(R,C).
obj_cell_r_(r(R, _), R).

% obj_cell_c_(+Cell, -C): extract column from r(R,C).
obj_cell_c_(r(_, C), C).

% obj_center(+Obj, -CR, -CC).
% CR and CC are the integer centroids (floor of the arithmetic mean of rows/cols).
obj_center(Obj, CR, CC) :-
    % Extract cells.
    obj_cells(Obj, Cells),
    % Extract all row and column values.
    maplist(obj_cell_r_, Cells, Rs),
    maplist(obj_cell_c_, Cells, Cs),
    % Sum rows and columns.
    obj_list_sum_(Rs, SumR),
    obj_list_sum_(Cs, SumC),
    % Compute integer centroid by floor division.
    length(Cells, N),
    CR is SumR // N,
    CC is SumC // N.

% obj_list_sum_(+List, -Sum): recursive sum of a list of numbers.
obj_list_sum_([], 0).
obj_list_sum_([V|Vs], Sum) :-
    % Recurse then add head.
    obj_list_sum_(Vs, Rest),
    Sum is V + Rest.

% obj_shape(+Obj, -Shape).
% Shape is the sorted list of r(DR, DC) offsets from the top-left corner
% of the bounding box, normalized so the minimum row and column offset are 0.
obj_shape(Obj, Shape) :-
    % Get the bounding box top-left corner.
    obj_bbox(Obj, MinR, MinC, _, _),
    % Get all cells.
    obj_cells(Obj, Cells),
    % Subtract the top-left offset from every cell.
    maplist(obj_normalize_cell_(MinR, MinC), Cells, Shape).

% obj_normalize_cell_(+MinR, +MinC, +Cell, -Offset).
% Subtract (MinR, MinC) from a cell to get a relative offset.
obj_normalize_cell_(MinR, MinC, r(R, C), r(DR, DC)) :-
    % Compute relative row.
    DR is R - MinR,
    % Compute relative column.
    DC is C - MinC.

% obj_inventory(+Grid, +Color, -Objects).
% Objects is the list of all 4-connected objects of the given Color in Grid.
% Each element is an obj(Color, SortedCells) term.
obj_inventory(Grid, Color, Objects) :-
    % Get all 4-connected components of this color from the connect pack.
    connect_components4(Grid, Color, Components),
    % Wrap each component in an obj term.
    maplist(obj_wrap_(Color), Components, Objects).

% obj_wrap_(+Color, +Cells, -Obj): wrap a component in an obj term.
obj_wrap_(Color, Cells, Obj) :-
    % Build the canonical object.
    obj_from_cells(Color, Cells, Obj).

% obj_all(+Grid, -Objects).
% Objects is the list of all obj(Color, Cells) terms for every non-zero color in Grid.
% Objects from lower colors appear first; within a color, order follows connect_components4.
obj_all(Grid, Objects) :-
    % Collect all cell values via findall to avoid choicepoints.
    findall(V, (member(Row, Grid), member(V, Row)), AllVals),
    % sort/2 removes duplicates and sorts ascending.
    sort(AllVals, UniqueVals),
    % Remove the background value 0.
    subtract(UniqueVals, [0], Colors),
    % Collect all objects for all non-zero colors.
    maplist(obj_inventory(Grid), Colors, PerColor),
    % Flatten via findall to avoid choicepoints from append/2.
    findall(Obj, (member(ObjList, PerColor), member(Obj, ObjList)), Objects).

% obj_count(+Grid, +Color, -N).
% N is the number of 4-connected objects of Color in Grid.
obj_count(Grid, Color, N) :-
    % Get all objects of this color.
    obj_inventory(Grid, Color, Objects),
    % Count them.
    length(Objects, N).

% obj_largest(+Grid, +Color, -Obj).
% Obj is the largest (most cells) 4-connected object of Color in Grid.
% Succeeds with the first largest if there are ties.
obj_largest(Grid, Color, Obj) :-
    % Get all objects.
    obj_inventory(Grid, Color, Objects),
    % Find the maximum size.
    maplist(obj_size, Objects, Sizes),
    max_list(Sizes, MaxSize),
    % Pick the first object with that size.
    member(Obj, Objects),
    obj_size(Obj, MaxSize),
    !.

% obj_smallest(+Grid, +Color, -Obj).
% Obj is the smallest (fewest cells) 4-connected object of Color in Grid.
% Succeeds with the first smallest if there are ties.
obj_smallest(Grid, Color, Obj) :-
    % Get all objects.
    obj_inventory(Grid, Color, Objects),
    % Find the minimum size.
    maplist(obj_size, Objects, Sizes),
    min_list(Sizes, MinSize),
    % Pick the first object with that size.
    member(Obj, Objects),
    obj_size(Obj, MinSize),
    !.

% obj_at_cell(+Objects, +Cell, -Obj).
% Obj is the first object in Objects whose cell list contains Cell.
obj_at_cell([Obj|_], Cell, Obj) :-
    % Check if Cell is in this object's cell list.
    obj_cells(Obj, Cells),
    member(Cell, Cells),
    !.
obj_at_cell([_|Rest], Cell, Obj) :-
    % Continue searching remaining objects.
    obj_at_cell(Rest, Cell, Obj).

% obj_sort_size(+Objects, +Order, -Sorted).
% Sort a list of objects by size.
% Order = asc: smallest first. Order = desc: largest first.
obj_sort_size(Objects, Order, Sorted) :-
    % Pair each object with its size for keyed sorting.
    maplist(obj_size_key_, Objects, Keyed),
    % Sort by the key (size).
    msort(Keyed, KeyedSorted),
    % Strip the keys.
    maplist(obj_strip_key_, KeyedSorted, Ascending),
    % Reverse if descending order was requested.
    ( Order = desc ->
        reverse(Ascending, Sorted)
    ;   Sorted = Ascending
    ).

% obj_size_key_(+Obj, -Key-Obj): pair an object with its size as sort key.
obj_size_key_(Obj, Size-Obj) :-
    % Compute size.
    obj_size(Obj, Size).

% obj_strip_key_(+Key-Obj, -Obj): extract the object from a key-value pair.
obj_strip_key_(_Key-Obj, Obj).
