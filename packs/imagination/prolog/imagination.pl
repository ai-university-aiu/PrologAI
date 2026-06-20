/*  PrologAI — Imaginative Memory: Mindscapes, Tableaux, Reveries  (Specification PR 50)

    The Building Sentient Beings vision (section 3.2.2.2) describes imaginative
    memory as a set of compartmentalized mental canvases on which specialized
    mechanisms render two- and three-dimensional animations.  PrologAI gives
    these structures original names so the faculty is native to the platform:

        mindscape  — a compartmentalized imaginative canvas, always held in a
                     non-observed reality so imagined content can never be
                     mistaken for perceived fact.
        tableau    — an arrangement of bound elements placed on a mindscape.
        element    — one bound item of a tableau, of three kinds:
                       vantage (a perspective camera angle),
                       figure  (a mesh or object, possibly grounded to a percept),
                       motif   (a multimedia or animation resource).
        reverie    — the rendered animation produced from a mindscape's tableaux,
                     a finite ordered list of frames.

    Figures may be invented outright or grounded to objects taken from
    perception (pai_tableau_ground/3), exactly as the vision requires.  A figure
    carries an optional pos(X,Y) starting position and an optional vel(DX,DY)
    per-frame velocity; rendering advances each figure kinematically so a reverie
    is a deterministic, inspectable forward animation suitable for mental
    simulation (for example, imagining how a grid object would move or transform).

    GUARD: a mindscape is rejected if asked to live in the observed reality;
    imaginative content is sandboxed away from observed fact.

    Predicates:
        pai_mindscape_new/2      — +Reality, -MindscapeId
        pai_mindscape_reality/2  — +MindscapeId, -Reality
        pai_tableau_add/3        — +MindscapeId, +Elements, -TableauId
        pai_tableau_ground/3     — +TableauId, +Percept, -FigureRef
        pai_reverie_render/3     — +MindscapeId, +Steps, -ReverieId
        pai_reverie_frames/2     — +ReverieId, -Frames
        pai_mindscape_clear/1    — +MindscapeId
        pai_imagine_fresh/4      — +Reality, +Elements, +Steps, -ReverieId
*/

% Declare this file as the 'imagination' module and list its exported predicates.
:- module(imagination, [
    % Continue the multi-line expression started above.
    pai_mindscape_new/2,        % +Reality, -MindscapeId
    % Continue the multi-line expression started above.
    pai_mindscape_reality/2,    % +MindscapeId, -Reality
    % Continue the multi-line expression started above.
    pai_tableau_add/3,          % +MindscapeId, +Elements, -TableauId
    % Continue the multi-line expression started above.
    pai_tableau_ground/3,       % +TableauId, +Percept, -FigureRef
    % Continue the multi-line expression started above.
    pai_reverie_render/3,       % +MindscapeId, +Steps, -ReverieId
    % Continue the multi-line expression started above.
    pai_reverie_frames/2,       % +ReverieId, -Frames
    % Continue the multi-line expression started above.
    pai_mindscape_clear/1,      % +MindscapeId
    % Supply 'pai_imagine_fresh/4' as the next argument to the expression above.
    pai_imagine_fresh/4         % +Reality, +Elements, +Steps, -ReverieId
% Close the expression opened above.
]).

% Import [member/2, numlist/3] helpers from the 'lists' library.
:- use_module(library(lists), [member/2, numlist/3]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% Declare 'mindscape/2' as dynamic — MindscapeId, Reality.
:- dynamic mindscape/2.
% Declare 'tableau/2' as dynamic — TableauId, MindscapeId.
:- dynamic tableau/2.
% Declare 'tableau_element/4' as dynamic — TableauId, Kind, Ref, Props.
:- dynamic tableau_element/4.
% Declare 'reverie/3' as dynamic — ReverieId, MindscapeId, Frames.
:- dynamic reverie/3.
% Declare 'id_counter/1' as dynamic — the monotonic unique-id source.
:- dynamic id_counter/1.

% State the fact: the imaginative realities allowed for a mindscape.
imaginative_reality(imagined).
% State the fact: a hypothetical reality is also imaginative (sandboxed).
imaginative_reality(hypothetical).
% State the fact: a recalled reality is imaginative for replay purposes.
imaginative_reality(recalled).

% Define a clause for 'valid_kind': vantage is a legal element kind.
valid_kind(vantage).
% Define a clause for 'valid_kind': figure is a legal element kind.
valid_kind(figure).
% Define a clause for 'valid_kind': motif is a legal element kind.
valid_kind(motif).

% ---------------------------------------------------------------------------
% next_id/1 — allocate a fresh unique id (guarded critical section)
% ---------------------------------------------------------------------------

% Define 'next_id': produce the next integer id, advancing the counter.
next_id(Id) :-
    % Use a mutex so concurrent mechanisms never receive duplicate ids.
    with_mutex(imagination_ids, next_id_unlocked(Id)).

% Define 'next_id_unlocked' for the case where a counter already exists.
next_id_unlocked(Id) :-
    % Check that a current counter value is present.
    retract(id_counter(N)),
    % Compute the next value by adding one.
    Id is N + 1,
    % Store the advanced counter back.
    assertz(id_counter(Id)),
    % Cut to commit to this clause.
    !.
% Define 'next_id_unlocked' for the first allocation when no counter exists.
next_id_unlocked(1) :-
    % Seed the counter at one.
    assertz(id_counter(1)).

% ---------------------------------------------------------------------------
% pai_mindscape_new/2 — create a compartmentalized canvas in a sandboxed reality
% ---------------------------------------------------------------------------

% Define 'pai_mindscape_new': create a new mindscape held in Reality.
pai_mindscape_new(Reality, MindscapeId) :-
    % GUARD — accept the reality only if it is an imaginative (non-observed) one.
    imaginative_reality(Reality),
    % Allocate a fresh id for the mindscape.
    next_id(N),
    % Build a readable identifier atom for the mindscape.
    atom_concat(mindscape_, N, MindscapeId),
    % Record the new mindscape and its reality.
    assertz(mindscape(MindscapeId, Reality)),
    % Commit to this mindscape deterministically.
    !.

% ---------------------------------------------------------------------------
% pai_mindscape_reality/2 — query the sandbox reality of a mindscape
% ---------------------------------------------------------------------------

% Define 'pai_mindscape_reality': look up the reality a mindscape lives in.
pai_mindscape_reality(MindscapeId, Reality) :-
    % Retrieve the stored mindscape fact.
    mindscape(MindscapeId, Reality),
    % Commit to the single stored reality deterministically.
    !.

% ---------------------------------------------------------------------------
% pai_tableau_add/3 — bind a list of elements into a tableau on a mindscape
% ---------------------------------------------------------------------------

% Define 'pai_tableau_add': place a tableau of Elements onto MindscapeId.
pai_tableau_add(MindscapeId, Elements, TableauId) :-
    % Confirm the target mindscape exists before binding anything.
    mindscape(MindscapeId, _),
    % Confirm every element is well-formed before committing.
    forall(member(El, Elements), valid_element(El)),
    % Allocate a fresh id for the tableau.
    next_id(N),
    % Build a readable identifier atom for the tableau.
    atom_concat(tableau_, N, TableauId),
    % Record the tableau and its owning mindscape.
    assertz(tableau(TableauId, MindscapeId)),
    % Store each element of the tableau as its own fact.
    store_elements(TableauId, Elements),
    % Commit to this tableau deterministically.
    !.

% Define 'valid_element': an element is element(Kind, Ref, Props) with a legal kind.
valid_element(element(Kind, _Ref, Props)) :-
    % Check the kind is one of vantage, figure, or motif.
    valid_kind(Kind),
    % Check the properties form a proper list.
    is_list(Props),
    % Commit deterministically.
    !.

% Define 'store_elements' for the empty list — nothing left to store.
store_elements(_TableauId, []).
% Define 'store_elements' for a non-empty list — store the head, recurse on the tail.
store_elements(TableauId, [element(Kind, Ref, Props) | Rest]) :-
    % Assert this element under its tableau.
    assertz(tableau_element(TableauId, Kind, Ref, Props)),
    % Continue with the remaining elements.
    store_elements(TableauId, Rest).

% ---------------------------------------------------------------------------
% pai_tableau_ground/3 — reuse a perceived object as a figure on a tableau
% ---------------------------------------------------------------------------

% Define 'pai_tableau_ground': add a grounded figure referencing a percept.
pai_tableau_ground(TableauId, Percept, Percept) :-
    % Confirm the tableau exists before grounding into it.
    tableau(TableauId, _),
    % Record a figure element that references the perceived object.
    assertz(tableau_element(TableauId, figure, Percept, [grounded(true), pos(0, 0)])),
    % Commit to this grounding deterministically.
    !.

% ---------------------------------------------------------------------------
% pai_reverie_render/3 — render a mindscape's tableaux into a Steps-frame reverie
% ---------------------------------------------------------------------------

% Define 'pai_reverie_render': produce a reverie of Steps frames for a mindscape.
pai_reverie_render(MindscapeId, Steps, ReverieId) :-
    % Confirm the mindscape exists.
    mindscape(MindscapeId, Reality),
    % GUARD — never render into the observed reality (defensive; impossible by construction).
    Reality \== observed,
    % Require at least one frame.
    integer(Steps),
    % Require the step count to be positive.
    Steps >= 1,
    % Collect the vantage (camera) for this mindscape, defaulting if absent.
    mindscape_vantage(MindscapeId, Vantage),
    % Collect all figure elements belonging to this mindscape.
    mindscape_figures(MindscapeId, Figures),
    % Compute the last frame index.
    Last is Steps - 1,
    % Build the list of frame indices from 0 to Last.
    numlist(0, Last, Indices),
    % Render every frame index into a frame term.
    render_frames(Indices, Vantage, Figures, Frames),
    % Allocate a fresh id for the reverie.
    next_id(N),
    % Build a readable identifier atom for the reverie.
    atom_concat(reverie_, N, ReverieId),
    % Store the rendered reverie.
    assertz(reverie(ReverieId, MindscapeId, Frames)),
    % Commit to this reverie deterministically.
    !.

% Define 'mindscape_vantage' — find the first vantage across the mindscape's tableaux.
mindscape_vantage(MindscapeId, Vantage) :-
    % Succeed if some tableau of this mindscape carries a vantage element.
    tableau(TableauId, MindscapeId),
    % Read that vantage's reference as the camera angle.
    tableau_element(TableauId, vantage, Vantage, _Props),
    % Commit to the first vantage found.
    !.
% Define 'mindscape_vantage' fallback — no vantage was placed, so use a default.
mindscape_vantage(_MindscapeId, default_vantage).

% Define 'mindscape_figures' — gather every figure element across the mindscape.
mindscape_figures(MindscapeId, Figures) :-
    % Collect figure(Ref, Props) for each figure element under each tableau.
    findall(figure(Ref, Props),
            % For each tableau of this mindscape that carries a figure element.
            ( tableau(TableauId, MindscapeId),
              % Read the figure element's reference and properties.
              tableau_element(TableauId, figure, Ref, Props)
            ),
            % Bind the assembled list of figures.
            Figures).

% Define 'render_frames' for the empty index list — no more frames.
render_frames([], _Vantage, _Figures, []).
% Define 'render_frames' for a non-empty index list — render head frame, recurse.
render_frames([F | Rest], Vantage, Figures, [frame(F, Vantage, States) | More]) :-
    % Compute every figure's state at frame index F.
    figure_states_at(Figures, F, States),
    % Render the remaining frames.
    render_frames(Rest, Vantage, Figures, More).

% Define 'figure_states_at' for the empty figure list — no states.
figure_states_at([], _F, []).
% Define 'figure_states_at' for a non-empty figure list — state head, recurse.
figure_states_at([figure(Ref, Props) | Rest], F, [figure(Ref, pos(Xf, Yf)) | More]) :-
    % Read the starting X position from the figure's properties, default 0.
    prop_value(Props, pos_x, 0, X0),
    % Read the starting Y position from the figure's properties, default 0.
    prop_value(Props, pos_y, 0, Y0),
    % Read the X velocity from the figure's properties, default 0.
    prop_value(Props, vel_x, 0, Dx),
    % Read the Y velocity from the figure's properties, default 0.
    prop_value(Props, vel_y, 0, Dy),
    % Advance the X position kinematically by velocity times frame index.
    Xf is X0 + Dx * F,
    % Advance the Y position kinematically by velocity times frame index.
    Yf is Y0 + Dy * F,
    % Compute the remaining figure states.
    figure_states_at(Rest, F, More).

% Define 'prop_value' — read a scalar from a property list with named accessors.
prop_value(Props, pos_x, Default, V) :-
    % If the props carry pos(X,_), take X; otherwise the default.
    ( member(pos(X, _), Props) -> V = X ; V = Default ), !.
% Define 'prop_value' for pos_y — read the Y of a pos(_,Y) term.
prop_value(Props, pos_y, Default, V) :-
    % If the props carry pos(_,Y), take Y; otherwise the default.
    ( member(pos(_, Y), Props) -> V = Y ; V = Default ), !.
% Define 'prop_value' for vel_x — read the DX of a vel(DX,_) term.
prop_value(Props, vel_x, Default, V) :-
    % If the props carry vel(DX,_), take DX; otherwise the default.
    ( member(vel(Dx, _), Props) -> V = Dx ; V = Default ), !.
% Define 'prop_value' for vel_y — read the DY of a vel(_,DY) term.
prop_value(Props, vel_y, Default, V) :-
    % If the props carry vel(_,DY), take DY; otherwise the default.
    ( member(vel(_, Dy), Props) -> V = Dy ; V = Default ), !.

% ---------------------------------------------------------------------------
% pai_reverie_frames/2 — query the frames of a rendered reverie
% ---------------------------------------------------------------------------

% Define 'pai_reverie_frames': retrieve the frame list of a reverie.
pai_reverie_frames(ReverieId, Frames) :-
    % Look up the stored reverie record.
    reverie(ReverieId, _MindscapeId, Frames),
    % Commit to the single stored reverie deterministically.
    !.

% ---------------------------------------------------------------------------
% pai_mindscape_clear/1 — empty a canvas of its tableaux, elements, and reveries
% ---------------------------------------------------------------------------

% Define 'pai_mindscape_clear': remove everything drawn on a mindscape.
pai_mindscape_clear(MindscapeId) :-
    % Confirm the mindscape exists.
    mindscape(MindscapeId, _),
    % Remove each tableau's elements, then the tableau itself.
    forall(tableau(TableauId, MindscapeId),
           % Retract the elements of this tableau and the tableau fact.
           ( retractall(tableau_element(TableauId, _, _, _)),
             % Retract the tableau itself.
             retractall(tableau(TableauId, MindscapeId))
           )),
    % Remove any reveries rendered from this mindscape.
    retractall(reverie(_, MindscapeId, _)),
    % Commit deterministically.
    !.

% ---------------------------------------------------------------------------
% pai_imagine_fresh/4 — convenience: new mindscape + one tableau + render
% ---------------------------------------------------------------------------

% Define 'pai_imagine_fresh': imagine an entirely new scene end to end.
pai_imagine_fresh(Reality, Elements, Steps, ReverieId) :-
    % Create a fresh compartmentalized mindscape in the given reality.
    pai_mindscape_new(Reality, MindscapeId),
    % Bind the supplied elements into a single tableau on it.
    pai_tableau_add(MindscapeId, Elements, _TableauId),
    % Render the mindscape into a reverie of the requested length.
    pai_reverie_render(MindscapeId, Steps, ReverieId),
    % Commit deterministically.
    !.
