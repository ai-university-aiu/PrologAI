% Module declaration: scene exports all sc_* predicates.
:- module(scene, [
    scene_bg_color/2,
    scene_objects/2,
    scene_grid_to_scene/2,
    scene_obj_color/2,
    scene_obj_cells/2,
    scene_obj_size/2,
    scene_obj_bbox/3,
    scene_obj_shape/2,
    scene_obj_centroid/3,
    scene_objects_of_color/3,
    scene_sort_by_size/3,
    scene_largest/2,
    scene_smallest/2,
    scene_count/2,
    scene_count_of_color/3,
    scene_above/2,
    scene_below/2,
    scene_left_of/2,
    scene_right_of/2,
    scene_cells_touching/2,
    scene_contained_in/2,
    scene_same_shape/2,
    scene_same_color/2,
    scene_normalize_cells/2
]).

% Import list utilities.
:- use_module(library(lists),
    [member/2, nth0/3, append/3, delete/3,
     flatten/2, numlist/3, last/2,
     min_list/2, max_list/2, sum_list/2]).
% Import pairs utilities.
:- use_module(library(pairs), [pairs_values/2]).
% Import higher-order utilities.
:- use_module(library(apply), [maplist/2, maplist/3, foldl/4]).
% Import grid pack for all gd_* operations.
:- use_module(library(grid)).


% BACKGROUND COLOR
% scene_bg_color(+Grid, -BgColor): the most frequently occurring color in Grid.
scene_bg_color(Grid, BgColor) :-
% Get sorted unique color set from the grid.
    gd_colors(Grid, Colors),
% Build Count-Color pairs for all colors.
    findall(Count-Color,
            (member(Color, Colors), gd_color_count(Grid, Color, Count)),
            Pairs),
% max_member selects the pair with the greatest standard-order key (numeric max).
    max_member(_MaxCount-BgColor, Pairs).


% OBJECT EXTRACTION
% scene_objects(+Grid, -Objects): all foreground objects as obj(Color, Cells) terms.
scene_objects(Grid, Objects) :-
% Find the background color to exclude it from object extraction.
    scene_bg_color(Grid, BgColor),
% Get all colors in the grid.
    gd_colors(Grid, AllColors),
% Remove the background color so only foreground colors remain.
    delete(AllColors, BgColor, FgColors),
% For each foreground color collect its connected components, accumulate all.
    foldl(collect_color_objects(Grid), FgColors, [], Objects).

% collect_color_objects(+Grid, +Color, +Acc, -NewAcc): helper for foldl.
collect_color_objects(Grid, Color, Acc, NewAcc) :-
% Get all maximal 4-connected components for this color.
    gd_objects(Grid, Color, CellSets),
% Wrap each cell set as obj(Color, Cells).
    maplist(make_obj(Color), CellSets, ColorObjs),
% Append new objects to the accumulator.
    append(Acc, ColorObjs, NewAcc).

% make_obj(+Color, +Cells, -Obj): named constructor avoids YALL sharing bug.
make_obj(Color, Cells, obj(Color, Cells)).


% SCENE CONSTRUCTION
% scene_grid_to_scene(+Grid, -Scene): build scene(Rows, Cols, BgColor, Objects).
scene_grid_to_scene(Grid, scene(Rows, Cols, BgColor, Objects)) :-
% Get grid dimensions.
    gd_size(Grid, Rows, Cols),
% Identify the background color.
    scene_bg_color(Grid, BgColor),
% Extract all foreground objects.
    scene_objects(Grid, Objects).


% OBJECT PROPERTY ACCESSORS
% scene_obj_color(+Obj, -Color): extract the color from an obj term.
scene_obj_color(obj(Color, _), Color).

% scene_obj_cells(+Obj, -Cells): extract the cell list from an obj term.
scene_obj_cells(obj(_, Cells), Cells).

% scene_obj_size(+Obj, -Size): number of cells in the object.
scene_obj_size(obj(_, Cells), Size) :-
% Count the cells.
    length(Cells, Size).

% scene_obj_bbox(+Obj, -TL, -BR): axis-aligned bounding box of the object.
scene_obj_bbox(obj(_, Cells), TL, BR) :-
% Delegate to grid pack bounding box predicate.
    gd_bounding_box(Cells, TL, BR).

% scene_obj_shape(+Obj, -Shape): normalized cell set (translated to (0,0), sorted).
scene_obj_shape(obj(_, Cells), Shape) :-
% Normalize the cell set to canonical position.
    scene_normalize_cells(Cells, Shape).

% scene_obj_centroid(+Obj, -R, -C): center of mass of the object, rounded.
scene_obj_centroid(obj(_, Cells), R, C) :-
% Extract all row coordinates.
    findall(RI, member(r(RI, _), Cells), Rs),
% Extract all column coordinates.
    findall(CI, member(r(_, CI), Cells), Cs),
% Sum all row coordinates.
    sum_list(Rs, RSum),
% Sum all column coordinates.
    sum_list(Cs, CSum),
% Count cells.
    length(Cells, N),
% N > 0 guard: centroid undefined for empty objects.
    N > 0,
% Compute rounded mean row.
    R is round(RSum / N),
% Compute rounded mean column.
    C is round(CSum / N).


% CELL NORMALIZATION
% scene_normalize_cells(+Cells, -Normalized): translate to (0,0) top-left, sort.
scene_normalize_cells(Cells, Normalized) :-
% Extract all row values.
    findall(RI, member(r(RI, _), Cells), Rs),
% Extract all column values.
    findall(CI, member(r(_, CI), Cells), Cs),
% Find the minimum row.
    min_list(Rs, MinR),
% Find the minimum column.
    min_list(Cs, MinC),
% Translate each cell so top-left becomes r(0,0).
    maplist(translate_cell(MinR, MinC), Cells, Translated),
% Sort for canonical ordering.
    sort(Translated, Normalized).

% translate_cell(+MinR, +MinC, +r(R,C), -r(R2,C2)): subtract offsets from cell.
translate_cell(MinR, MinC, r(R, C), r(R2, C2)) :-
% Subtract minimum row offset.
    R2 is R - MinR,
% Subtract minimum column offset.
    C2 is C - MinC.


% FILTERING
% scene_objects_of_color(+Objects, +Color, -Filtered): keep only objects of Color.
scene_objects_of_color(Objects, Color, Filtered) :-
% Include only objects whose color matches.
    include(has_color(Color), Objects, Filtered).

% has_color(+Color, +Obj): succeeds if Obj has the given Color.
has_color(Color, obj(Color, _)).


% SORTING AND SELECTION
% scene_sort_by_size(+Objects, +Order, -Sorted): Order is asc or desc.
scene_sort_by_size(Objects, asc, Sorted) :-
% Build Size-Obj pairs.
    maplist(make_size_pair, Objects, Pairs),
% Sort pairs by key (size).
    keysort(Pairs, KSorted),
% Extract just the objects in sorted order.
    pairs_values(KSorted, Sorted).
% scene_sort_by_size with desc order: sort ascending then reverse.
scene_sort_by_size(Objects, desc, Sorted) :-
% Sort ascending first.
    scene_sort_by_size(Objects, asc, Asc),
% Reverse to get descending order.
    reverse(Asc, Sorted).

% make_size_pair(+Obj, -Size-Obj): builds a keysort-compatible pair.
make_size_pair(Obj, Size-Obj) :-
% Compute object size as the key.
    scene_obj_size(Obj, Size).

% scene_largest(+Objects, -Largest): the object with the most cells.
scene_largest(Objects, Largest) :-
% Sort ascending, largest is last.
    scene_sort_by_size(Objects, asc, Sorted),
% Get the last element.
    last(Sorted, Largest).

% scene_smallest(+Objects, -Smallest): the object with the fewest cells.
scene_smallest(Objects, Smallest) :-
% Sort ascending, smallest is first.
    scene_sort_by_size(Objects, asc, [Smallest|_]).


% COUNTING
% scene_count(+Objects, -Count): total number of objects.
scene_count(Objects, Count) :-
% Count all elements in the list.
    length(Objects, Count).

% scene_count_of_color(+Objects, +Color, -Count): count objects with given color.
scene_count_of_color(Objects, Color, Count) :-
% Filter to just objects of the given color.
    scene_objects_of_color(Objects, Color, Filtered),
% Count the filtered list.
    length(Filtered, Count).


% SPATIAL RELATIONS (use bounding box top-left for directional comparison)
% scene_above(+Obj1, +Obj2): Obj1 is above Obj2 (lower row index).
scene_above(Obj1, Obj2) :-
% Get top-left of Obj1.
    scene_obj_bbox(Obj1, r(R1, _), _),
% Get top-left of Obj2.
    scene_obj_bbox(Obj2, r(R2, _), _),
% Obj1 is above if its min row is strictly less.
    R1 < R2.

% scene_below(+Obj1, +Obj2): Obj1 is below Obj2 (greater row index).
scene_below(Obj1, Obj2) :-
% Obj1 is below if Obj2 is above Obj1.
    scene_above(Obj2, Obj1).

% scene_left_of(+Obj1, +Obj2): Obj1 is to the left of Obj2 (lower col index).
scene_left_of(Obj1, Obj2) :-
% Get top-left of Obj1.
    scene_obj_bbox(Obj1, r(_, C1), _),
% Get top-left of Obj2.
    scene_obj_bbox(Obj2, r(_, C2), _),
% Obj1 is left-of if its min col is strictly less.
    C1 < C2.

% scene_right_of(+Obj1, +Obj2): Obj1 is to the right of Obj2 (greater col index).
scene_right_of(Obj1, Obj2) :-
% Obj1 is right-of if Obj2 is left-of Obj1.
    scene_left_of(Obj2, Obj1).

% scene_cells_touching(+Obj1, +Obj2): any cell of Obj1 is 4-connected to any cell of Obj2.
scene_cells_touching(obj(_, Cells1), obj(_, Cells2)) :-
% Find a cell in Obj1 and a cell in Obj2 that are 4-connected neighbors.
    member(r(R1, C1), Cells1),
    member(r(R2, C2), Cells2),
% Manhattan distance of exactly 1 means 4-connected adjacency.
    abs(R1 - R2) + abs(C1 - C2) =:= 1,
% Cut: first witness is sufficient.
    !.

% scene_contained_in(+Obj1, +Obj2): bbox of Obj1 is inside bbox of Obj2.
scene_contained_in(Obj1, Obj2) :-
% Get bounding box of Obj1.
    scene_obj_bbox(Obj1, r(R1min, C1min), r(R1max, C1max)),
% Get bounding box of Obj2.
    scene_obj_bbox(Obj2, r(R2min, C2min), r(R2max, C2max)),
% Obj1 min row must be at least Obj2 min row.
    R1min >= R2min,
% Obj1 min col must be at least Obj2 min col.
    C1min >= C2min,
% Obj1 max row must be at most Obj2 max row.
    R1max =< R2max,
% Obj1 max col must be at most Obj2 max col.
    C1max =< C2max.


% SHAPE AND COLOR COMPARISON
% scene_same_shape(+Obj1, +Obj2): true if both objects have equal normalized shapes.
scene_same_shape(Obj1, Obj2) :-
% Get normalized shape of Obj1.
    scene_obj_shape(Obj1, Shape1),
% Get normalized shape of Obj2.
    scene_obj_shape(Obj2, Shape2),
% Compare shapes for identity.
    Shape1 == Shape2.

% scene_same_color(+Obj1, +Obj2): true if both objects have the same color.
scene_same_color(obj(Color, _), obj(Color, _)).
