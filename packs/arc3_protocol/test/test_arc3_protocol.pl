/*  PrologAI — ARC-AGI-3 Protocol Test Suite  (WP-400)

    Verifies the vocabulary is exactly the March-2026 protocol: the cell-select
    action maps to ACTION6 (not the older action-five encoding), commands route
    under /api/cmd, the four game states are present with WIN and GAME_OVER
    terminal, frames are validated for shape and colour, and arc3_protocol_env yields a
    well-formed arc3_env term the co_arc3 harness can consume. No test touches
    the network.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/arc3_protocol/test/test_arc3_protocol.pl
*/

% Declare this file as a test module.
:- module(test_arc3_protocol, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(arc3_protocol)).

% Open the test unit for the protocol.
:- begin_tests(arc3_protocol).

% The cell-select action maps to ACTION6, the current complex command.
test(select_is_action6, [true(Cmd == 'ACTION6')]) :-
    % Resolve a click at (7,9) to its wire command.
    arc3_protocol_action_command(select(7, 9), Cmd).

% The undo action maps to ACTION7.
test(undo_is_action7, [true(Cmd == 'ACTION7')]) :-
    % Resolve the undo action.
    arc3_protocol_action_command(undo, Cmd).

% Commands route under the /api/cmd path.
test(command_endpoint, [true(Path == '/api/cmd/ACTION6')]) :-
    % The complex command's endpoint.
    arc3_protocol_command_endpoint('ACTION6', Path).

% The scorecard open and close endpoints are present.
test(scorecard_endpoints) :-
    % Open path.
    arc3_protocol_scorecard_endpoint(open, '/api/scorecard/open'),
    % Close path.
    arc3_protocol_scorecard_endpoint(close, '/api/scorecard/close').

% There are exactly four game states.
test(four_states, [true(N == 4)]) :-
    % Count the enumerated states.
    findall(S, arc3_protocol_game_state(S), States),
    % How many there are.
    length(States, N).

% WIN and GAME_OVER are terminal; NOT_FINISHED is not.
test(terminality) :-
    % WIN ends the level.
    arc3_protocol_is_terminal('WIN'),
    % GAME_OVER ends the level.
    arc3_protocol_is_terminal('GAME_OVER'),
    % An in-progress state does not.
    \+ arc3_protocol_is_terminal('NOT_FINISHED'),
    % Only WIN is a win.
    arc3_protocol_is_win('WIN'),
    % GAME_OVER is not a win.
    \+ arc3_protocol_is_win('GAME_OVER').

% A small legal frame validates; an out-of-range colour does not.
test(frame_validation) :-
    % A two-by-two frame of legal colours passes.
    arc3_protocol_valid_frame([[0, 15], [3, 8]]),
    % A frame with colour sixteen (out of range) fails.
    \+ arc3_protocol_valid_frame([[0, 16]]).

% The cell-select payload carries the coordinates and the game identifier.
test(select_payload) :-
    % Build the payload for a click at (4,5) in game g1.
    arc3_protocol_action_payload(select(4, 5), g1, D),
    % The x coordinate is carried.
    D.x =:= 4,
    % The y coordinate is carried.
    D.y =:= 5,
    % The game identifier is carried.
    D.game_id == g1.

% arc3_protocol_env yields a well-formed arc3_env term for the harness.
test(env_shape) :-
    % Build an env for a fictitious endpoint.
    arc3_protocol_env('https://example.invalid', 'k', g1, Env),
    % It has the four-goal shape the harness expects.
    Env = arc3_env(_Reset, _Act, _Actions, _Solved).

% Close the test unit.
:- end_tests(arc3_protocol).
