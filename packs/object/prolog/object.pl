% Module declaration: obj pack, Layer 69.
:- module(object, [
    % object_from_cells/3: construct an object term from a color and a cell list.
    object_from_cells/3,
    % object_color/2: extract the color of an object.
    object_color/2,
    % object_cells/2: extract the sorted cell list of an object.
    object_cells/2,
    % object_size/2: number of cells in an object.
    object_size/2,
    % object_bbox/5: bounding box (MinR, MinC, MaxR, MaxC) of an object.
    object_bbox/5,
    % object_center/3: integer centroid row and column of an object.
    object_center/3,
    % object_shape/2: normalized cell offsets relative to the top-left of the bounding box.
    object_shape/2,
    % object_inventory/3: all 4-connected objects of a given color in a grid.
    object_inventory/3,
    % object_all/2: all objects of all non-zero colors in a grid.
    object_all/2,
    % object_count/3: number of 4-connected objects of a given color in a grid.
    object_count/3,
    % object_largest/3: largest object (most cells) of a given color.
    object_largest/3,
    % object_smallest/3: smallest object (fewest cells) of a given color.
    object_smallest/3,
    % object_at_cell/3: find which object from a list contains a given cell.
    object_at_cell/3,
    % object_sort_size/3: sort a list of objects by size ascending or descending.
    object_sort_size/3
]).

% Import list utilities; msort/length/forall are built-ins, not imported.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3,
                                max_list/2, min_list/2, subtract/3]).
% Import higher-order apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).
% Import the connect pack for flood-fill component analysis.
:- use_module(library(connect), [connect_components4/3]).

% object_from_cells(+Color, +Cells, -Obj).
% Construct an object term obj(Color, SortedCells).
object_from_cells(Color, Cells, Obj) :-
    % Sort cells to canonical order for comparison.
    msort(Cells, Sorted),
    % Wrap in the obj/2 functor.
    Obj = obj(Color, Sorted).

% object_color(+Obj, -Color).
% Extract the color stored in the object term.
object_color(obj(Color, _), Color).

% object_cells(+Obj, -Cells).
% Extract the sorted cell list stored in the object term.
object_cells(obj(_, Cells), Cells).

% object_size(+Obj, -N).
% N is the number of cells in the object.
object_size(obj(_, Cells), N) :-
    % Count cells using length/2 built-in.
    length(Cells, N).

% object_bbox(+Obj, -MinR, -MinC, -MaxR, -MaxC).
% Compute the axis-aligned bounding box of the object.
object_bbox(obj(_, Cells), MinR, MinC, MaxR, MaxC) :-
    % Extract all row coordinates.
    maplist(object_cell_r_, Cells, Rs),
    % Extract all column coordinates.
    maplist(object_cell_c_, Cells, Cs),
    % Find extremes.
    min_list(Rs, MinR),
    max_list(Rs, MaxR),
    min_list(Cs, MinC),
    max_list(Cs, MaxC).

% object_cell_r_(+Cell, -R): extract row from r(R,C).
object_cell_r_(r(R, _), R).

% object_cell_c_(+Cell, -C): extract column from r(R,C).
object_cell_c_(r(_, C), C).

% object_center(+Obj, -CR, -CC).
% CR and CC are the integer centroids (floor of the arithmetic mean of rows/cols).
object_center(Obj, CR, CC) :-
    % Extract cells.
    object_cells(Obj, Cells),
    % Extract all row and column values.
    maplist(object_cell_r_, Cells, Rs),
    maplist(object_cell_c_, Cells, Cs),
    % Sum rows and columns.
    object_list_sum_(Rs, SumR),
    object_list_sum_(Cs, SumC),
    % Compute integer centroid by floor division.
    length(Cells, N),
    CR is SumR // N,
    CC is SumC // N.

% object_list_sum_(+List, -Sum): recursive sum of a list of numbers.
object_list_sum_([], 0).
object_list_sum_([V|Vs], Sum) :-
    % Recurse then add head.
    object_list_sum_(Vs, Rest),
    Sum is V + Rest.

% object_shape(+Obj, -Shape).
% Shape is the sorted list of r(DR, DC) offsets from the top-left corner
% of the bounding box, normalized so the minimum row and column offset are 0.
object_shape(Obj, Shape) :-
    % Get the bounding box top-left corner.
    object_bbox(Obj, MinR, MinC, _, _),
    % Get all cells.
    object_cells(Obj, Cells),
    % Subtract the top-left offset from every cell.
    maplist(object_normalize_cell_(MinR, MinC), Cells, Shape).

% object_normalize_cell_(+MinR, +MinC, +Cell, -Offset).
% Subtract (MinR, MinC) from a cell to get a relative offset.
object_normalize_cell_(MinR, MinC, r(R, C), r(DR, DC)) :-
    % Compute relative row.
    DR is R - MinR,
    % Compute relative column.
    DC is C - MinC.

% object_inventory(+Grid, +Color, -Objects).
% Objects is the list of all 4-connected objects of the given Color in Grid.
% Each element is an obj(Color, SortedCells) term.
object_inventory(Grid, Color, Objects) :-
    % Get all 4-connected components of this color from the connect pack.
    connect_components4(Grid, Color, Components),
    % Wrap each component in an obj term.
    maplist(object_wrap_(Color), Components, Objects).

% object_wrap_(+Color, +Cells, -Obj): wrap a component in an obj term.
object_wrap_(Color, Cells, Obj) :-
    % Build the canonical object.
    object_from_cells(Color, Cells, Obj).

% object_all(+Grid, -Objects).
% Objects is the list of all obj(Color, Cells) terms for every non-zero color in Grid.
% Objects from lower colors appear first; within a color, order follows connect_components4.
object_all(Grid, Objects) :-
    % Collect all cell values via findall to avoid choicepoints.
    findall(V, (member(Row, Grid), member(V, Row)), AllVals),
    % sort/2 removes duplicates and sorts ascending.
    sort(AllVals, UniqueVals),
    % Remove the background value 0.
    subtract(UniqueVals, [0], Colors),
    % Collect all objects for all non-zero colors.
    maplist(object_inventory(Grid), Colors, PerColor),
    % Flatten via findall to avoid choicepoints from append/2.
    findall(Obj, (member(ObjList, PerColor), member(Obj, ObjList)), Objects).

% object_count(+Grid, +Color, -N).
% N is the number of 4-connected objects of Color in Grid.
object_count(Grid, Color, N) :-
    % Get all objects of this color.
    object_inventory(Grid, Color, Objects),
    % Count them.
    length(Objects, N).

% object_largest(+Grid, +Color, -Obj).
% Obj is the largest (most cells) 4-connected object of Color in Grid.
% Succeeds with the first largest if there are ties.
object_largest(Grid, Color, Obj) :-
    % Get all objects.
    object_inventory(Grid, Color, Objects),
    % Find the maximum size.
    maplist(object_size, Objects, Sizes),
    max_list(Sizes, MaxSize),
    % Pick the first object with that size.
    member(Obj, Objects),
    object_size(Obj, MaxSize),
    !.

% object_smallest(+Grid, +Color, -Obj).
% Obj is the smallest (fewest cells) 4-connected object of Color in Grid.
% Succeeds with the first smallest if there are ties.
object_smallest(Grid, Color, Obj) :-
    % Get all objects.
    object_inventory(Grid, Color, Objects),
    % Find the minimum size.
    maplist(object_size, Objects, Sizes),
    min_list(Sizes, MinSize),
    % Pick the first object with that size.
    member(Obj, Objects),
    object_size(Obj, MinSize),
    !.

% object_at_cell(+Objects, +Cell, -Obj).
% Obj is the first object in Objects whose cell list contains Cell.
object_at_cell([Obj|_], Cell, Obj) :-
    % Check if Cell is in this object's cell list.
    object_cells(Obj, Cells),
    member(Cell, Cells),
    !.
object_at_cell([_|Rest], Cell, Obj) :-
    % Continue searching remaining objects.
    object_at_cell(Rest, Cell, Obj).

% object_sort_size(+Objects, +Order, -Sorted).
% Sort a list of objects by size.
% Order = asc: smallest first. Order = desc: largest first.
object_sort_size(Objects, Order, Sorted) :-
    % Pair each object with its size for keyed sorting.
    maplist(object_size_key_, Objects, Keyed),
    % Sort by the key (size).
    msort(Keyed, KeyedSorted),
    % Strip the keys.
    maplist(object_strip_key_, KeyedSorted, Ascending),
    % Reverse if descending order was requested.
    ( Order = desc ->
        reverse(Ascending, Sorted)
    ;   Sorted = Ascending
    ).

% object_size_key_(+Obj, -Key-Obj): pair an object with its size as sort key.
object_size_key_(Obj, Size-Obj) :-
    % Compute size.
    object_size(Obj, Size).

% object_strip_key_(+Key-Obj, -Obj): extract the object from a key-value pair.
object_strip_key_(_Key-Obj, Obj).
