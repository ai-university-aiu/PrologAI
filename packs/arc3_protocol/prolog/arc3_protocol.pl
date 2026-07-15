/*  PrologAI — ARC-AGI-3 Protocol  (WP-400, Layer 375)

    The arc3_harness harness keeps its live HTTP bridge deliberately loose because
    the exact API routes drift between releases. This pack pins down the
    vocabulary of the March-2026 ARC-AGI-3 agents API as inspectable facts, so
    that the loop can speak the current protocol precisely and a later drift is
    a one-file change rather than a scattered edit.

    The action vocabulary (six simple commands plus reset):
        action(1)..action(5)  the five simple actions -> ACTION1..ACTION5
        select(X, Y)          the complex cell-select action -> ACTION6, x,y in 0..63
        undo                  the revert-a-turn action       -> ACTION7
        reset                 restart the level              -> RESET
    Each command is issued to /api/cmd/<COMMAND>; the scorecard is opened and
    closed at /api/scorecard/open and /api/scorecard/close.

    A frame is a grid of up to 64 by 64 cells, each an integer colour 0..15.
    A reply reports its state as one of NOT_PLAYED, NOT_FINISHED, WIN or
    GAME_OVER; WIN and GAME_OVER are terminal, and WIN is the win.

    arc3_protocol_env/4 packages all of this as an arc3_env(Reset, Act, Actions, Solved)
    term the arc3_harness harness can play directly. Every network call is guarded
    with catch and fails honestly when offline, so no test depends on the wire.

    Predicates:
      arc3_protocol_action_command/2   -- ?ActionTerm, ?Command   (action(6) is select/2)
      arc3_protocol_command_atom/1     -- ?Command                (the seven commands)
      arc3_protocol_command_endpoint/2 -- ?Command, ?Path
      arc3_protocol_action_endpoint/2  -- +ActionTerm, -Path
      arc3_protocol_scorecard_endpoint/2 -- ?Which, ?Path         (open|close)
      arc3_protocol_game_state/1       -- ?State                  (the four states)
      arc3_protocol_is_terminal/1      -- +State                  (WIN or GAME_OVER)
      arc3_protocol_is_win/1           -- +State                  (WIN)
      arc3_protocol_max_dim/1          -- -Dim                    (64)
      arc3_protocol_colour_count/1     -- -Count                  (16)
      arc3_protocol_valid_frame/1      -- +Frame                  (shape and colour check)
      arc3_protocol_available_actions/1 -- -Actions               (the canonical superset)
      arc3_protocol_action_payload/3   -- +ActionTerm, +GameId, -Dict
      arc3_protocol_env/4              -- +BaseUrl, +ApiKey, +GameId, -Env  (guarded)
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(arc3_protocol, [
    % arc3_protocol_action_command/2: an action term and its wire command name.
    arc3_protocol_action_command/2,
    % arc3_protocol_command_atom/1: the seven wire command names.
    arc3_protocol_command_atom/1,
    % arc3_protocol_command_endpoint/2: a command's REST path.
    arc3_protocol_command_endpoint/2,
    % arc3_protocol_action_endpoint/2: an action term's REST path.
    arc3_protocol_action_endpoint/2,
    % arc3_protocol_scorecard_endpoint/2: the scorecard open and close paths.
    arc3_protocol_scorecard_endpoint/2,
    % arc3_protocol_game_state/1: the four reported game states.
    arc3_protocol_game_state/1,
    % arc3_protocol_is_terminal/1: a state that ends the level.
    arc3_protocol_is_terminal/1,
    % arc3_protocol_is_win/1: the winning state.
    arc3_protocol_is_win/1,
    % arc3_protocol_max_dim/1: the maximum grid dimension.
    arc3_protocol_max_dim/1,
    % arc3_protocol_colour_count/1: the number of distinct colours.
    arc3_protocol_colour_count/1,
    % arc3_protocol_valid_frame/1: a frame of legal shape and colour.
    arc3_protocol_valid_frame/1,
    % arc3_protocol_available_actions/1: the canonical action superset.
    arc3_protocol_available_actions/1,
    % arc3_protocol_action_payload/3: the JSON body an action posts.
    arc3_protocol_action_payload/3,
    % arc3_protocol_env/4: a guarded arc3_env speaking the live protocol.
    arc3_protocol_env/4
]).

% Import grid measurement for frame validation.
:- use_module(library(grid), [grid_size/3]).
% Import list helpers.
:- use_module(library(lists), [member/2]).

% ---------------------------------------------------------------------------
% The action vocabulary
% ---------------------------------------------------------------------------

% Map simple action one to its wire command.
arc3_protocol_action_command(action(1), 'ACTION1').
% Map simple action two to its wire command.
arc3_protocol_action_command(action(2), 'ACTION2').
% Map simple action three to its wire command.
arc3_protocol_action_command(action(3), 'ACTION3').
% Map simple action four to its wire command.
arc3_protocol_action_command(action(4), 'ACTION4').
% Map simple action five to its wire command.
arc3_protocol_action_command(action(5), 'ACTION5').
% Map the cell-select action to the complex command ACTION6.
arc3_protocol_action_command(select(_X, _Y), 'ACTION6').
% Map the undo action to ACTION7.
arc3_protocol_action_command(undo, 'ACTION7').
% Map the reset action to RESET.
arc3_protocol_action_command(reset, 'RESET').

% Define arc3_protocol_command_atom: enumerate the seven wire command names plus reset.
arc3_protocol_command_atom('ACTION1').
% The second command.
arc3_protocol_command_atom('ACTION2').
% The third command.
arc3_protocol_command_atom('ACTION3').
% The fourth command.
arc3_protocol_command_atom('ACTION4').
% The fifth command.
arc3_protocol_command_atom('ACTION5').
% The complex cell-select command.
arc3_protocol_command_atom('ACTION6').
% The undo command.
arc3_protocol_command_atom('ACTION7').
% The reset command.
arc3_protocol_command_atom('RESET').

% Define arc3_protocol_command_endpoint: a command's REST path under /api/cmd.
arc3_protocol_command_endpoint(Command, Path) :-
    % The command must be a known one.
    arc3_protocol_command_atom(Command),
    % The path is the command appended to the command route.
    atom_concat('/api/cmd/', Command, Path).

% Define arc3_protocol_action_endpoint: an action term's REST path.
arc3_protocol_action_endpoint(Action, Path) :-
    % Resolve the action to its command name.
    arc3_protocol_action_command(Action, Command),
    % Then to the command's path.
    arc3_protocol_command_endpoint(Command, Path).

% Define arc3_protocol_scorecard_endpoint: the scorecard open path.
arc3_protocol_scorecard_endpoint(open, '/api/scorecard/open').
% The scorecard close path.
arc3_protocol_scorecard_endpoint(close, '/api/scorecard/close').

% ---------------------------------------------------------------------------
% Game states
% ---------------------------------------------------------------------------

% Define arc3_protocol_game_state: the level has not been played yet.
arc3_protocol_game_state('NOT_PLAYED').
% The level is in progress.
arc3_protocol_game_state('NOT_FINISHED').
% The level has been won.
arc3_protocol_game_state('WIN').
% The level has ended in failure.
arc3_protocol_game_state('GAME_OVER').

% Define arc3_protocol_is_terminal: a WIN ends the level.
arc3_protocol_is_terminal('WIN').
% A GAME_OVER ends the level.
arc3_protocol_is_terminal('GAME_OVER').

% Define arc3_protocol_is_win: only WIN is a win.
arc3_protocol_is_win('WIN').

% ---------------------------------------------------------------------------
% Frames
% ---------------------------------------------------------------------------

% Define arc3_protocol_max_dim: the maximum grid dimension is sixty-four.
arc3_protocol_max_dim(64).

% Define arc3_protocol_colour_count: there are sixteen distinct colours.
arc3_protocol_colour_count(16).

% Define arc3_protocol_valid_frame: a frame of legal shape and colour.
arc3_protocol_valid_frame(Frame) :-
    % It must measure as a grid.
    grid_size(Frame, Rows, Cols),
    % The maximum dimension.
    arc3_protocol_max_dim(Max),
    % Rows must be within bounds and positive.
    Rows > 0, Rows =< Max,
    % Columns must be within bounds and positive.
    Cols > 0, Cols =< Max,
    % Every cell must be a legal colour integer.
    forall(member(Row, Frame),
        % Every value in the row.
        forall(member(V, Row),
            % A colour is an integer in zero to fifteen.
            ( integer(V), V >= 0, V =< 15 ))).

% ---------------------------------------------------------------------------
% Actions and their payloads
% ---------------------------------------------------------------------------

% Define arc3_protocol_available_actions: the canonical action superset a game affords.
arc3_protocol_available_actions([action(1), action(2), action(3), action(4), action(5),
                       select(_X, _Y), undo]).

% Define arc3_protocol_action_payload: the cell-select action carries its coordinates.
arc3_protocol_action_payload(select(X, Y), GameId, _{game_id: GameId, x: X, y: Y}) :- !.
% Any other action carries only the game identifier.
arc3_protocol_action_payload(_Action, GameId, _{game_id: GameId}).

% ---------------------------------------------------------------------------
% The guarded env adapter for the arc3_harness harness
% ---------------------------------------------------------------------------

% arc3_protocol_last_/1: the last JSON reply the adapter received, for the win test.
:- dynamic arc3_protocol_last_/1.

% Define arc3_protocol_env: a guarded arc3_env speaking the live protocol.
arc3_protocol_env(BaseUrl, ApiKey, GameId, arc3_env(
    % The reset goal restarts the level and returns the first frame.
    arc3_protocol:arc3_protocol_reset(BaseUrl, ApiKey, GameId),
    % The act goal posts one action and returns the next frame.
    arc3_protocol:arc3_protocol_act(BaseUrl, ApiKey, GameId),
    % The actions goal reports the canonical action set.
    arc3_protocol:arc3_protocol_actions,
    % The solved goal reads the win flag of the last reply.
    arc3_protocol:arc3_protocol_solved)).

% arc3_protocol_reset(+BaseUrl, +ApiKey, +GameId, -Frame0): reset over HTTP, guarded.
arc3_protocol_reset(BaseUrl, ApiKey, GameId, Frame0) :-
    % The reset command's path.
    arc3_protocol_command_endpoint('RESET', Path),
    % The reset payload.
    arc3_protocol_action_payload(reset, GameId, Payload),
    % Any transport failure fails honestly.
    catch(arc3_protocol_post(BaseUrl, ApiKey, Path, Payload, Reply), _, fail),
    % Remember the reply for the win test.
    arc3_protocol_remember(Reply),
    % The reply carries the first frame.
    Frame0 = Reply.frame.

% arc3_protocol_act(+BaseUrl, +ApiKey, +GameId, +Action, -Frame1): one action, guarded.
arc3_protocol_act(BaseUrl, ApiKey, GameId, Action, Frame1) :-
    % The action's command path.
    arc3_protocol_action_endpoint(Action, Path),
    % The action's payload.
    arc3_protocol_action_payload(Action, GameId, Payload),
    % Any transport failure fails honestly.
    catch(arc3_protocol_post(BaseUrl, ApiKey, Path, Payload, Reply), _, fail),
    % Remember the reply for the win test.
    arc3_protocol_remember(Reply),
    % The reply carries the next frame.
    Frame1 = Reply.frame.

% arc3_protocol_actions(-Actions): the canonical action set the harness may choose from.
arc3_protocol_actions(Actions) :-
    % Report the canonical superset.
    arc3_protocol_available_actions(Actions).

% arc3_protocol_solved(+_Frame): the last reply reported the level won.
arc3_protocol_solved(_Frame) :-
    % Read the remembered reply.
    arc3_protocol_last_(Reply),
    % Its state must be the winning state.
    catch(arc3_protocol_is_win(Reply.state), _, fail).

% arc3_protocol_remember(+Reply): store the last reply, replacing any previous.
arc3_protocol_remember(Reply) :-
    % Drop the previous reply.
    retractall(arc3_protocol_last_(_)),
    % Store the new one.
    assertz(arc3_protocol_last_(Reply)).

% arc3_protocol_post(+BaseUrl, +ApiKey, +Path, +Payload, -Reply): POST JSON, read JSON.
arc3_protocol_post(BaseUrl, ApiKey, Path, Payload, Reply) :-
    % Load the HTTP client lazily so the pack works offline.
    use_module(library(http/http_open)),
    % Load the JSON codec lazily too.
    use_module(library(http/json)),
    % Compose the full request URL.
    atom_concat(BaseUrl, Path, Url),
    % Encode the payload as a JSON string.
    with_output_to(string(Body), json_write_dict(current_output, Payload)),
    % Post it and read the JSON reply, always closing the stream.
    setup_call_cleanup(
        % Open the request with the API key header.
        http_open(Url, Stream,
                  [ post(string('application/json', Body)),
                    request_header('X-API-Key' = ApiKey) ]),
        % Read the reply as a dict.
        json_read_dict(Stream, Reply),
        % Close the stream.
        close(Stream)).
