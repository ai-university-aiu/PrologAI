/*  PrologAI — Causalontology Whole-Grid Perception  (WP-403, Layer 378)

    An agent that must play an unseen interactive environment cannot just poke at
    one spot; it has to SEE the whole grid — take stock of every object on it,
    guess what each one is, notice the counters and life-bars along the edges, and
    tell which object it is steering. This pack is that perception layer. It never
    ablates any part of the grid: a status band or a shrinking bar is not thrown
    away, it is read and reported so a caller can feed it into a resource model.

    The measured priority of priors for playing games puts OBJECTNESS first, so
    everything here is object-first: the frame is segmented into connected
    components, each becomes an inventory item with its colour, size, centroid,
    bounding box, and a shape-based role guess (a dot, a bar/meter, a wide field,
    or a piece). Bars and meters (a thin, long run of one colour, usually at an
    edge) are singled out because that is what a life-bar, timer, or counter looks
    like. The avatar — the thing the player controls — is found the way a person
    finds it: it is whatever moved on the grid after an action, so cs_avatar_move
    reports the centroid of the region that changed between two frames.

    Predicates:
      cs_background/2   -- +Frame, -Bg        (the most common colour = background)
      cs_objects/2      -- +Frame, -Objects   (obj(Colour,Size,Centroid,BBox), big first)
      cs_object_count/2 -- +Frame, -N
      cs_inventory/2    -- +Frame, -Items     (seen(Id,Colour,Size,Centroid,Role))
      cs_salient_cells/2-- +Frame, -Cells     (object centroids, largest object first)
      cs_bars/2         -- +Frame, -Bars      (bar(Colour,Orient,Length,Centroid))
      cs_changed_cells/3-- +Frame0,+Frame1,-Cells (cells that differ)
      cs_avatar_move/3  -- +Frame0,+Frame1,-Centroid (what moved = the avatar)
*/

% Declare this module and its whole-grid perception interface.
:- module(co_see, [
    % cs_background/2: the background colour (the most common one).
    cs_background/2,
    % cs_objects/2: every object with its colour, size, centroid, and box.
    cs_objects/2,
    % cs_object_count/2: how many objects are on the grid.
    cs_object_count/2,
    % cs_inventory/2: the inventory, each object tagged with a role guess.
    cs_inventory/2,
    % cs_salient_cells/2: object centroids, largest object first.
    cs_salient_cells/2,
    % cs_bars/2: the bar/meter-like objects (life-bars, timers, counters).
    cs_bars/2,
    % cs_changed_cells/3: the cells that differ between two frames.
    cs_changed_cells/3,
    % cs_avatar_move/3: the centroid of what moved — the avatar.
    cs_avatar_move/3
]).

% Import grid measurement and reading.
:- use_module(library(grid), [gd_size/3, gd_cell/4, gd_colors/2, gd_color_count/3]).
% Import connected-component object detection.
:- use_module(library(gridobj), [gob_all_objects/3]).
% Import list helpers.
:- use_module(library(lists), [member/2, max_list/2, min_list/2, sum_list/2]).
% Import aggregation.
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% Background
% ---------------------------------------------------------------------------

% Define cs_background: the background is the colour that covers the most cells.
cs_background(Frame, Bg) :-
    % The colours present.
    gd_colors(Frame, Colours),
    % Pair each colour with how many cells carry it.
    findall(N - Colour,
        ( member(Colour, Colours), gd_color_count(Frame, Colour, N) ),
        Counts),
    % There must be at least one colour.
    Counts \== [],
    % Sort ascending by count; the last (largest) is the background.
    keysort(Counts, Sorted),
    % Take the most common colour.
    last(Sorted, _ - Bg).

% ---------------------------------------------------------------------------
% Objects and the inventory
% ---------------------------------------------------------------------------

% Define cs_objects: every non-background object as obj(Colour, Size, Centroid,
% BBox), ordered largest object first.
cs_objects(Frame, Objects) :-
    % The background to segment against.
    ( cs_background(Frame, Bg) -> true ; Bg = 0 ),
    % Connected components over every non-background colour.
    catch(gob_all_objects(Frame, Bg, Raw), _, Raw = []),
    % Summarise each component: colour, size, centroid, and bounding box.
    findall(NegSize - obj(Colour, Size, cell(CR, CC), bbox(R0, C0, R1, C1)),
        ( member(ob(Colour, Cells, _), Raw),
          length(Cells, Size),
          Size > 0,
          NegSize is -Size,
          cs_centroid(Cells, CR, CC),
          cs_bbox(Cells, R0, C0, R1, C1) ),
        Keyed),
    % Largest object first.
    keysort(Keyed, Sorted),
    % Drop the sort keys.
    findall(O, member(_ - O, Sorted), Objects).

% cs_centroid(+Cells, -R, -C): the rounded centroid of a list of r(R,C) cells.
cs_centroid(Cells, R, C) :-
    % The row coordinates.
    findall(RR, member(r(RR, _), Cells), Rows),
    % The column coordinates.
    findall(CC, member(r(_, CC), Cells), Cols),
    % How many cells.
    length(Cells, N),
    % Guard against an empty object.
    N > 0,
    % Sum the rows and columns.
    sum_list(Rows, SumR), sum_list(Cols, SumC),
    % Round the means.
    R is round(SumR / N), C is round(SumC / N).

% cs_bbox(+Cells, -R0, -C0, -R1, -C1): the bounding box of a cell list.
cs_bbox(Cells, R0, C0, R1, C1) :-
    % The rows and columns.
    findall(RR, member(r(RR, _), Cells), Rows),
    findall(CC, member(r(_, CC), Cells), Cols),
    % The extremes.
    min_list(Rows, R0), max_list(Rows, R1),
    min_list(Cols, C0), max_list(Cols, C1).

% Define cs_object_count: how many objects the grid holds.
cs_object_count(Frame, N) :-
    % Count the segmented objects.
    cs_objects(Frame, Objects),
    length(Objects, N).

% Define cs_inventory: the objects, each tagged with a shape-based role guess, in
% salience order (largest first). Roles: meter (a bar), dot (a single cell),
% field (a large block), or piece (anything else).
cs_inventory(Frame, Items) :-
    % The objects, largest first.
    cs_objects(Frame, Objects),
    % The grid area, to judge "large".
    ( gd_size(Frame, H, W) -> Area is H * W ; Area = 4096 ),
    % Tag each object with an id and a role.
    findall(seen(Id, Colour, Size, cell(CR, CC), Role),
        ( nth1(Id, Objects, obj(Colour, Size, cell(CR, CC), bbox(R0, C0, R1, C1))),
          cs_role(Size, R0, C0, R1, C1, Area, Role) ),
        Items).

% cs_role(+Size,+R0,+C0,+R1,+C1,+Area,-Role): a shape-based role guess.
% A thin, long object is a meter (life-bar / timer / counter).
cs_role(_, R0, C0, R1, C1, _, meter) :-
    Height is R1 - R0 + 1, Width is C1 - C0 + 1,
    min_list([Height, Width], Thin), max_list([Height, Width], Long),
    Thin =< 2, Long >= 5, !.
% A single cell is a dot (often a target or collectible).
cs_role(1, _, _, _, _, _, dot) :- !.
% A block covering a large share of the grid is a field/wall.
cs_role(Size, _, _, _, _, Area, field) :- Size * 5 >= Area, !.
% Anything else is a piece.
cs_role(_, _, _, _, _, _, piece).

% Define cs_salient_cells: the object centroids, largest object first — the
% "what should I look at / go touch" list.
cs_salient_cells(Frame, Cells) :-
    % The objects, largest first.
    cs_objects(Frame, Objects),
    % Their centroids in order.
    findall(cell(R, C), member(obj(_, _, cell(R, C), _), Objects), Cells).

% ---------------------------------------------------------------------------
% Bars and meters — never ablate a counter; report it
% ---------------------------------------------------------------------------

% Define cs_bars: the bar/meter-like objects — a thin, long run of one colour,
% which is what a life-bar, timer, or progress counter looks like.
cs_bars(Frame, Bars) :-
    % Every object.
    cs_objects(Frame, Objects),
    % Keep the thin, long ones and describe them.
    findall(bar(Colour, Orient, Length, cell(CR, CC)),
        ( member(obj(Colour, _, cell(CR, CC), bbox(R0, C0, R1, C1)), Objects),
          Height is R1 - R0 + 1, Width is C1 - C0 + 1,
          min_list([Height, Width], Thin), max_list([Height, Width], Long),
          Thin =< 2, Long >= 5,
          ( Width >= Height -> Orient = horizontal ; Orient = vertical ),
          Length = Long ),
        Bars).

% ---------------------------------------------------------------------------
% Change and the avatar
% ---------------------------------------------------------------------------

% Define cs_changed_cells: the cells whose colour differs between two frames.
cs_changed_cells(Frame0, Frame1, Cells) :-
    % The dimensions (assume the two frames share them).
    gd_size(Frame0, H, W),
    H1 is H - 1, W1 is W - 1,
    % Every cell whose value changed.
    findall(cell(R, C),
        ( between(0, H1, R), between(0, W1, C),
          gd_cell(Frame0, R, C, V0),
          gd_cell(Frame1, R, C, V1),
          V0 \== V1 ),
        Cells).

% Define cs_avatar_move: the centroid of what moved between two frames — the
% avatar. A person spots the avatar as the thing that answered the controller;
% this reports the centre of the region that changed, biased to the cells the
% avatar moved INTO (non-background in the new frame).
cs_avatar_move(Frame0, Frame1, cell(R, C)) :-
    % Everything that changed.
    cs_changed_cells(Frame0, Frame1, Changed),
    % There must be a change to locate.
    Changed \== [],
    % The new frame's background.
    ( cs_background(Frame1, Bg1) -> true ; Bg1 = 0 ),
    % The changed cells that are now non-background — where the avatar moved to.
    findall(cell(RR, CC),
        ( member(cell(RR, CC), Changed),
          gd_cell(Frame1, RR, CC, V), V \== Bg1 ),
        NewCells),
    % Prefer the moved-into cells; fall back to all changed cells.
    ( NewCells \== [] -> Pick = NewCells ; Pick = Changed ),
    % The centroid of those cells.
    cs_centroid_cells(Pick, R, C).

% cs_centroid_cells(+Cells, -R, -C): the rounded centroid of a cell(R,C) list.
cs_centroid_cells(Cells, R, C) :-
    % The rows and columns.
    findall(RR, member(cell(RR, _), Cells), Rows),
    findall(CC, member(cell(_, CC), Cells), Cols),
    % How many.
    length(Cells, N), N > 0,
    % The rounded means.
    sum_list(Rows, SumR), sum_list(Cols, SumC),
    R is round(SumR / N), C is round(SumC / N).

% Import nth1/nth0 for the inventory ids.
:- use_module(library(lists), [nth1/3, last/2]).
