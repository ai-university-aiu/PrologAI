/*  PrologAI — PR 50 Imaginative Memory: Mindscapes, Tableaux, Reveries Acceptance Tests

    AC-PR50-001: imagination_mindscape_new creates a mindscape held in the imagined reality.
    AC-PR50-002: imagination_mindscape_new rejects the observed reality (sandbox guard).
    AC-PR50-003: imagination_tableau_add binds elements and returns a tableau on the mindscape.
    AC-PR50-004: imagination_tableau_add rejects an element of an unknown kind.
    AC-PR50-005: imagination_tableau_ground reuses a percept as a grounded figure.
    AC-PR50-006: imagination_reverie_render produces exactly Steps frames.
    AC-PR50-007: a moving figure's position advances across frames per its vel(DX,DY).
    AC-PR50-008: each frame records the vantage (camera angle).
    AC-PR50-009: imagination_mindscape_clear empties the canvas of tableaux and reveries.
    AC-PR50-010: imagination_imagine_fresh creates, binds, and renders in one call.
*/

% Execute the compile-time directive: resolve the imagination pack path and register it.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/imagination/prolog'], PackPath),
   % Add the pack's prolog directory to the library search path.
   assertz(file_search_path(library, PackPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the 'imagination' module under test.
:- use_module(library(imagination), [
    % Supply 'imagination_mindscape_new/2' as the next argument to the expression above.
    imagination_mindscape_new/2,
    % Supply 'imagination_mindscape_reality/2' as the next argument to the expression above.
    imagination_mindscape_reality/2,
    % Supply 'imagination_tableau_add/3' as the next argument to the expression above.
    imagination_tableau_add/3,
    % Supply 'imagination_tableau_ground/3' as the next argument to the expression above.
    imagination_tableau_ground/3,
    % Supply 'imagination_reverie_render/3' as the next argument to the expression above.
    imagination_reverie_render/3,
    % Supply 'imagination_reverie_frames/2' as the next argument to the expression above.
    imagination_reverie_frames/2,
    % Supply 'imagination_mindscape_clear/1' as the next argument to the expression above.
    imagination_mindscape_clear/1,
    % Supply 'imagination_imagine_fresh/4' as the next argument to the expression above.
    imagination_imagine_fresh/4
% Close the import list opened above.
]).

% Open the test unit named 'imagination'.
:- begin_tests(imagination).

% AC-PR50-001 — a new mindscape lives in the imagined reality.
test(mindscape_new_imagined) :-
    % Create a mindscape in the imagined reality.
    imagination_mindscape_new(imagined, M),
    % Confirm its reality reads back as imagined.
    imagination_mindscape_reality(M, imagined).

% AC-PR50-002 — the observed reality is rejected by the sandbox guard.
test(mindscape_rejects_observed, [fail]) :-
    % Attempt to create a mindscape in the observed reality; this must fail.
    imagination_mindscape_new(observed, _M).

% AC-PR50-003 — a tableau binds onto its mindscape.
test(tableau_add) :-
    % Create a mindscape to draw on.
    imagination_mindscape_new(imagined, M),
    % Add a tableau holding a vantage and a figure.
    imagination_tableau_add(M, [element(vantage, eye_level, []),
                        element(figure, ball, [pos(0,0)])], T),
    % Confirm the returned tableau identifier is bound to an atom.
    atom(T).

% AC-PR50-004 — an unknown element kind is rejected.
test(tableau_rejects_bad_kind, [fail]) :-
    % Create a mindscape.
    imagination_mindscape_new(imagined, M),
    % Attempt to add an element of an illegal kind; this must fail.
    imagination_tableau_add(M, [element(sprite, ball, [])], _T).

% AC-PR50-005 — a percept can be grounded as a figure.
test(tableau_ground) :-
    % Create a mindscape and an empty tableau.
    imagination_mindscape_new(imagined, M),
    % Add a tableau with just a vantage.
    imagination_tableau_add(M, [element(vantage, eye_level, [])], T),
    % Ground a perceived object 'cup_07' as a figure on the tableau.
    imagination_tableau_ground(T, cup_07, Ref),
    % Confirm the returned figure reference is the percept itself.
    Ref == cup_07.

% AC-PR50-006 — rendering yields exactly Steps frames.
test(reverie_frame_count) :-
    % Create a mindscape with one static figure.
    imagination_mindscape_new(imagined, M),
    % Add a tableau with a vantage and a figure.
    imagination_tableau_add(M, [element(vantage, eye_level, []),
                        element(figure, ball, [pos(0,0)])], _T),
    % Render five frames.
    imagination_reverie_render(M, 5, R),
    % Retrieve the frames.
    imagination_reverie_frames(R, Frames),
    % Confirm exactly five frames were produced.
    length(Frames, 5).

% AC-PR50-007 — a moving figure advances by its velocity each frame.
test(reverie_motion) :-
    % Create a mindscape with a figure moving +2 in X and +1 in Y each frame.
    imagination_mindscape_new(imagined, M),
    % Add a tableau with a vantage and a moving figure starting at (1,1).
    imagination_tableau_add(M, [element(vantage, eye_level, []),
                        element(figure, ball, [pos(1,1), vel(2,1)])], _T),
    % Render three frames.
    imagination_reverie_render(M, 3, R),
    % Retrieve the frames.
    imagination_reverie_frames(R, Frames),
    % The last frame is index 2; the figure should be at (1+2*2, 1+1*2) = (5,3).
    last(Frames, frame(2, _Vantage, States)),
    % Confirm the figure reached the expected advanced position.
    member(figure(ball, pos(5, 3)), States).

% AC-PR50-008 — every frame records the vantage.
test(reverie_vantage) :-
    % Create a mindscape with a named vantage.
    imagination_mindscape_new(imagined, M),
    % Add a tableau with a 'birds_eye' vantage and a figure.
    imagination_tableau_add(M, [element(vantage, birds_eye, []),
                        element(figure, ball, [pos(0,0)])], _T),
    % Render two frames.
    imagination_reverie_render(M, 2, R),
    % Retrieve the frames.
    imagination_reverie_frames(R, Frames),
    % Confirm the first frame carries the birds_eye vantage.
    Frames = [frame(0, birds_eye, _) | _].

% AC-PR50-009 — clearing a mindscape removes its tableaux and reveries.
test(mindscape_clear) :-
    % Create and populate a mindscape.
    imagination_mindscape_new(imagined, M),
    % Add a tableau.
    imagination_tableau_add(M, [element(figure, ball, [pos(0,0)])], _T),
    % Render a reverie from it.
    imagination_reverie_render(M, 2, R),
    % Clear the mindscape.
    imagination_mindscape_clear(M),
    % Confirm the reverie is gone (its frames can no longer be retrieved).
    \+ imagination_reverie_frames(R, _Frames).

% AC-PR50-010 — the one-call fresh-imagination convenience works end to end.
test(imagine_fresh) :-
    % Imagine an entirely new scene with a moving figure over four frames.
    imagination_imagine_fresh(hypothetical,
                      [element(vantage, eye_level, []),
                       element(figure, kite, [pos(0,0), vel(1,0)])],
                      4, R),
    % Retrieve the frames.
    imagination_reverie_frames(R, Frames),
    % Confirm four frames were produced.
    length(Frames, 4).

% Close the test unit named 'imagination'.
:- end_tests(imagination).
