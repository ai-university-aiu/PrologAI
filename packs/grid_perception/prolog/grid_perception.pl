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
    finds it: it is whatever moved on the grid after an action, so grid_perception_avatar_move
    reports the centroid of the region that changed between two frames.

    Predicates:
      grid_perception_background/2   -- +Frame, -Bg        (the most common colour = background)
      grid_perception_objects/2      -- +Frame, -Objects   (obj(Colour,Size,Centroid,BBox), big first)
      grid_perception_object_count/2 -- +Frame, -N
      grid_perception_inventory/2    -- +Frame, -Items     (seen(Id,Colour,Size,Centroid,Role))
      grid_perception_salient_cells/2-- +Frame, -Cells     (object centroids, largest object first)
      grid_perception_bars/2         -- +Frame, -Bars      (bar(Colour,Orient,Length,Centroid))
      grid_perception_changed_cells/3-- +Frame0,+Frame1,-Cells (cells that differ)
      grid_perception_avatar_move/3  -- +Frame0,+Frame1,-Centroid (what moved = the avatar)
*/

% Declare this module and its whole-grid perception interface.
:- module(grid_perception, [
    % grid_perception_background/2: the background colour (the most common one).
    grid_perception_background/2,
    % grid_perception_objects/2: every object with its colour, size, centroid, and box.
    grid_perception_objects/2,
    % grid_perception_object_count/2: how many objects are on the grid.
    grid_perception_object_count/2,
    % grid_perception_inventory/2: the inventory, each object tagged with a role guess.
    grid_perception_inventory/2,
    % grid_perception_salient_cells/2: object centroids, largest object first.
    grid_perception_salient_cells/2,
    % grid_perception_bars/2: the bar/meter-like objects (life-bars, timers, counters).
    grid_perception_bars/2,
    % grid_perception_changed_cells/3: the cells that differ between two frames.
    grid_perception_changed_cells/3,
    % grid_perception_avatar_move/3: the centroid of what moved — the avatar.
    grid_perception_avatar_move/3
]).

% Import grid measurement and reading.
:- use_module(library(grid), [gd_size/3, gd_cell/4, gd_colors/2, gd_color_count/3]).
% Import connected-component object detection.
:- use_module(library(gridobj), [gridobj_all_objects/3]).
% Import list helpers.
:- use_module(library(lists), [member/2, max_list/2, min_list/2, sum_list/2]).
% Import aggregation.
:- use_module(library(aggregate), [aggregate_all/3]).
% Import term hashing for the per-frame perception cache.
:- use_module(library(terms), [term_hash/2]).

% ---------------------------------------------------------------------------
% Per-frame segmentation cache — segment a frame once, not once per caller
% ---------------------------------------------------------------------------
%
% A connected-component segmentation of a 64x64 grid is the expensive part of
% whole-grid perception, and grid_perception_inventory, grid_perception_bars, grid_perception_object_count, and
% grid_perception_salient_cells ALL derive from grid_perception_objects — so a single choice that reads the
% inventory, the meters, and the salient cells would segment the same frame three
% times. This cache computes each whole-grid perception once per frame and hands
% the stored answer to every later caller. It is keyed by a cheap hash of the
% frame and keeps only the latest frame's entry per kind, so it stays tiny and
% never serves a stale frame: a new frame's hash misses and evicts the old one.

% grid_perception_cache_/3: (Kind, FrameHash, Value) — one memoised perception for one frame.
:- dynamic grid_perception_cache_/3.

% grid_perception_cache_clear/0: drop the whole perception cache. The keep-latest policy
% already bounds the cache to the current frame, so this is only for a caller
% that wants to release the memory explicitly (e.g. between games).
grid_perception_cache_clear :-
    % Forget every cached perception.
    retractall(grid_perception_cache_(_, _, _)).

% grid_perception_cached(+Kind, +Frame, :Compute, -Value): return Kind's value for this exact
% frame, computing it once via Compute(Frame, Value) on a miss and storing it.
% Only the latest frame's entry per kind is kept, so the cache never grows.
:- meta_predicate grid_perception_cached(+, +, 2, -).
grid_perception_cached(Kind, Frame, Compute, Value) :-
    % A cheap hash of the frame is the cache key.
    term_hash(Frame, H),
    (   % Hit: the value for this exact frame is already stored.
        grid_perception_cache_(Kind, H, V0)
    ->  Value = V0
    ;   % Miss: compute once (Compute must succeed, as the direct predicate did),
        % drop any stale entry of this kind, store the fresh one, and return it.
        call(Compute, Frame, V1),
        retractall(grid_perception_cache_(Kind, _, _)),
        assertz(grid_perception_cache_(Kind, H, V1)),
        Value = V1
    ).

% ---------------------------------------------------------------------------
% Background
% ---------------------------------------------------------------------------

% Define grid_perception_background: the background is the colour that covers the most cells.
% Cached per frame — the object segmentation and the avatar locator both need it.
grid_perception_background(Frame, Bg) :-
    % Serve the cached background, computing it once per frame.
    grid_perception_cached(background, Frame, grid_perception_background_compute, Bg).

% grid_perception_background_compute(+Frame, -Bg): the uncached background computation.
grid_perception_background_compute(Frame, Bg) :-
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

% Define grid_perception_objects: every non-background object as obj(Colour, Size, Centroid,
% BBox), ordered largest object first. Cached per frame so the inventory, meters,
% object count, and salient cells all share ONE segmentation of the same frame.
grid_perception_objects(Frame, Objects) :-
    % Serve the cached segmentation, computing it once per frame.
    grid_perception_cached(objects, Frame, grid_perception_objects_compute, Objects).

% grid_perception_objects_compute(+Frame, -Objects): the uncached connected-component
% segmentation — the expensive full-grid pass the cache above amortises.
grid_perception_objects_compute(Frame, Objects) :-
    % The background to segment against.
    ( grid_perception_background(Frame, Bg) -> true ; Bg = 0 ),
    % Connected components over every non-background colour.
    catch(gridobj_all_objects(Frame, Bg, Raw), _, Raw = []),
    % Summarise each component: colour, size, centroid, and bounding box.
    findall(NegSize - obj(Colour, Size, cell(CR, CC), bbox(R0, C0, R1, C1)),
        ( member(ob(Colour, Cells, _), Raw),
          length(Cells, Size),
          Size > 0,
          NegSize is -Size,
          grid_perception_centroid(Cells, CR, CC),
          grid_perception_bbox(Cells, R0, C0, R1, C1) ),
        Keyed),
    % Largest object first.
    keysort(Keyed, Sorted),
    % Drop the sort keys.
    findall(O, member(_ - O, Sorted), Objects).

% grid_perception_centroid(+Cells, -R, -C): the rounded centroid of a list of r(R,C) cells.
grid_perception_centroid(Cells, R, C) :-
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

% grid_perception_bbox(+Cells, -R0, -C0, -R1, -C1): the bounding box of a cell list.
grid_perception_bbox(Cells, R0, C0, R1, C1) :-
    % The row coordinates.
    findall(RR, member(r(RR, _), Cells), Rows),
    % The column coordinates.
    findall(CC, member(r(_, CC), Cells), Cols),
    % The extreme rows.
    min_list(Rows, R0), max_list(Rows, R1),
    % The extreme columns.
    min_list(Cols, C0), max_list(Cols, C1).

% Define grid_perception_object_count: how many objects the grid holds.
grid_perception_object_count(Frame, N) :-
    % Count the segmented objects.
    grid_perception_objects(Frame, Objects),
    length(Objects, N).

% Define grid_perception_inventory: the objects, each tagged with a shape-based role guess, in
% salience order (largest first). Roles: meter (a bar), dot (a single cell),
% field (a large block), or piece (anything else).
grid_perception_inventory(Frame, Items) :-
    % The objects, largest first.
    grid_perception_objects(Frame, Objects),
    % The grid area, to judge "large".
    ( gd_size(Frame, H, W) -> Area is H * W ; Area = 4096 ),
    % Tag each object with an id and a role.
    findall(seen(Id, Colour, Size, cell(CR, CC), Role),
        ( nth1(Id, Objects, obj(Colour, Size, cell(CR, CC), bbox(R0, C0, R1, C1))),
          grid_perception_role(Size, R0, C0, R1, C1, Area, Role) ),
        Items).

% grid_perception_role(+Size,+R0,+C0,+R1,+C1,+Area,-Role): a shape-based role guess.
% A thin, long object is a meter (life-bar / timer / counter).
grid_perception_role(_, R0, C0, R1, C1, _, meter) :-
    % The object's height and width.
    Height is R1 - R0 + 1, Width is C1 - C0 + 1,
    % Its thin side and its long side.
    min_list([Height, Width], Thin), max_list([Height, Width], Long),
    % Thin (at most two) and long (at least five) makes it a meter.
    Thin =< 2, Long >= 5, !.
% A single cell is a dot (often a target or collectible).
grid_perception_role(1, _, _, _, _, _, dot) :- !.
% A block covering a large share of the grid is a field/wall.
grid_perception_role(Size, _, _, _, _, Area, field) :- Size * 5 >= Area, !.
% Anything else is a piece.
grid_perception_role(_, _, _, _, _, _, piece).

% Define grid_perception_salient_cells: the object centroids, largest object first — the
% "what should I look at / go touch" list.
grid_perception_salient_cells(Frame, Cells) :-
    % The objects, largest first.
    grid_perception_objects(Frame, Objects),
    % Their centroids in order.
    findall(cell(R, C), member(obj(_, _, cell(R, C), _), Objects), Cells).

% ---------------------------------------------------------------------------
% Bars and meters — never ablate a counter; report it
% ---------------------------------------------------------------------------

% Define grid_perception_bars: the bar/meter-like objects — a thin, long run of one colour,
% which is what a life-bar, timer, or progress counter looks like.
grid_perception_bars(Frame, Bars) :-
    % Every object.
    grid_perception_objects(Frame, Objects),
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

% Define grid_perception_changed_cells: the cells whose colour differs between two frames.
grid_perception_changed_cells(Frame0, Frame1, Cells) :-
    % The dimensions (assume the two frames share them).
    gd_size(Frame0, H, W),
    % The last row and column indices.
    H1 is H - 1, W1 is W - 1,
    % Every cell whose value changed.
    findall(cell(R, C),
        ( between(0, H1, R), between(0, W1, C),
          gd_cell(Frame0, R, C, V0),
          gd_cell(Frame1, R, C, V1),
          V0 \== V1 ),
        Cells).

% Define grid_perception_avatar_move: the centroid of what moved between two frames — the
% avatar. A person spots the avatar as the thing that answered the controller;
% this reports the centre of the region that changed, biased to the cells the
% avatar moved INTO (non-background in the new frame).
grid_perception_avatar_move(Frame0, Frame1, cell(R, C)) :-
    % Everything that changed.
    grid_perception_changed_cells(Frame0, Frame1, Changed),
    % There must be a change to locate.
    Changed \== [],
    % The new frame's background.
    ( grid_perception_background(Frame1, Bg1) -> true ; Bg1 = 0 ),
    % The changed cells that are now non-background — where the avatar moved to.
    findall(cell(RR, CC),
        ( member(cell(RR, CC), Changed),
          gd_cell(Frame1, RR, CC, V), V \== Bg1 ),
        NewCells),
    % Prefer the moved-into cells; fall back to all changed cells.
    ( NewCells \== [] -> Pick = NewCells ; Pick = Changed ),
    % The centroid of those cells.
    grid_perception_centroid_cells(Pick, R, C).

% grid_perception_centroid_cells(+Cells, -R, -C): the rounded centroid of a cell(R,C) list.
grid_perception_centroid_cells(Cells, R, C) :-
    % The row coordinates.
    findall(RR, member(cell(RR, _), Cells), Rows),
    % The column coordinates.
    findall(CC, member(cell(_, CC), Cells), Cols),
    % How many.
    length(Cells, N), N > 0,
    % Sum the rows and columns.
    sum_list(Rows, SumR), sum_list(Cols, SumC),
    % The rounded means.
    R is round(SumR / N), C is round(SumC / N).

% Import nth1/nth0 for the inventory ids.
:- use_module(library(lists), [nth1/3, last/2]).
