/*  PrologAI — ARC-AGI-3 Protocol  (WP-400, Layer 375)

    The co_arc3 harness keeps its live HTTP bridge deliberately loose because
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

    cap_env/4 packages all of this as an arc3_env(Reset, Act, Actions, Solved)
    term the co_arc3 harness can play directly. Every network call is guarded
    with catch and fails honestly when offline, so no test depends on the wire.

    Predicates:
      cap_action_command/2   -- ?ActionTerm, ?Command   (action(6) is select/2)
      cap_command_atom/1     -- ?Command                (the seven commands)
      cap_command_endpoint/2 -- ?Command, ?Path
      cap_action_endpoint/2  -- +ActionTerm, -Path
      cap_scorecard_endpoint/2 -- ?Which, ?Path         (open|close)
      cap_game_state/1       -- ?State                  (the four states)
      cap_is_terminal/1      -- +State                  (WIN or GAME_OVER)
      cap_is_win/1           -- +State                  (WIN)
      cap_max_dim/1          -- -Dim                    (64)
      cap_colour_count/1     -- -Count                  (16)
      cap_valid_frame/1      -- +Frame                  (shape and colour check)
      cap_available_actions/1 -- -Actions               (the canonical superset)
      cap_action_payload/3   -- +ActionTerm, +GameId, -Dict
      cap_env/4              -- +BaseUrl, +ApiKey, +GameId, -Env  (guarded)
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(co_arc3proto, [
    % cap_action_command/2: an action term and its wire command name.
    cap_action_command/2,
    % cap_command_atom/1: the seven wire command names.
    cap_command_atom/1,
    % cap_command_endpoint/2: a command's REST path.
    cap_command_endpoint/2,
    % cap_action_endpoint/2: an action term's REST path.
    cap_action_endpoint/2,
    % cap_scorecard_endpoint/2: the scorecard open and close paths.
    cap_scorecard_endpoint/2,
    % cap_game_state/1: the four reported game states.
    cap_game_state/1,
    % cap_is_terminal/1: a state that ends the level.
    cap_is_terminal/1,
    % cap_is_win/1: the winning state.
    cap_is_win/1,
    % cap_max_dim/1: the maximum grid dimension.
    cap_max_dim/1,
    % cap_colour_count/1: the number of distinct colours.
    cap_colour_count/1,
    % cap_valid_frame/1: a frame of legal shape and colour.
    cap_valid_frame/1,
    % cap_available_actions/1: the canonical action superset.
    cap_available_actions/1,
    % cap_action_payload/3: the JSON body an action posts.
    cap_action_payload/3,
    % cap_env/4: a guarded arc3_env speaking the live protocol.
    cap_env/4
]).

% Import grid measurement for frame validation.
:- use_module(library(grid), [gd_size/3]).
% Import list helpers.
:- use_module(library(lists), [member/2]).

% ---------------------------------------------------------------------------
% The action vocabulary
% ---------------------------------------------------------------------------

% Map simple action one to its wire command.
cap_action_command(action(1), 'ACTION1').
% Map simple action two to its wire command.
cap_action_command(action(2), 'ACTION2').
% Map simple action three to its wire command.
cap_action_command(action(3), 'ACTION3').
% Map simple action four to its wire command.
cap_action_command(action(4), 'ACTION4').
% Map simple action five to its wire command.
cap_action_command(action(5), 'ACTION5').
% Map the cell-select action to the complex command ACTION6.
cap_action_command(select(_X, _Y), 'ACTION6').
% Map the undo action to ACTION7.
cap_action_command(undo, 'ACTION7').
% Map the reset action to RESET.
cap_action_command(reset, 'RESET').

% Define cap_command_atom: enumerate the seven wire command names plus reset.
cap_command_atom('ACTION1').
% The second command.
cap_command_atom('ACTION2').
% The third command.
cap_command_atom('ACTION3').
% The fourth command.
cap_command_atom('ACTION4').
% The fifth command.
cap_command_atom('ACTION5').
% The complex cell-select command.
cap_command_atom('ACTION6').
% The undo command.
cap_command_atom('ACTION7').
% The reset command.
cap_command_atom('RESET').

% Define cap_command_endpoint: a command's REST path under /api/cmd.
cap_command_endpoint(Command, Path) :-
    % The command must be a known one.
    cap_command_atom(Command),
    % The path is the command appended to the command route.
    atom_concat('/api/cmd/', Command, Path).

% Define cap_action_endpoint: an action term's REST path.
cap_action_endpoint(Action, Path) :-
    % Resolve the action to its command name.
    cap_action_command(Action, Command),
    % Then to the command's path.
    cap_command_endpoint(Command, Path).

% Define cap_scorecard_endpoint: the scorecard open path.
cap_scorecard_endpoint(open, '/api/scorecard/open').
% The scorecard close path.
cap_scorecard_endpoint(close, '/api/scorecard/close').

% ---------------------------------------------------------------------------
% Game states
% ---------------------------------------------------------------------------

% Define cap_game_state: the level has not been played yet.
cap_game_state('NOT_PLAYED').
% The level is in progress.
cap_game_state('NOT_FINISHED').
% The level has been won.
cap_game_state('WIN').
% The level has ended in failure.
cap_game_state('GAME_OVER').

% Define cap_is_terminal: a WIN ends the level.
cap_is_terminal('WIN').
% A GAME_OVER ends the level.
cap_is_terminal('GAME_OVER').

% Define cap_is_win: only WIN is a win.
cap_is_win('WIN').

% ---------------------------------------------------------------------------
% Frames
% ---------------------------------------------------------------------------

% Define cap_max_dim: the maximum grid dimension is sixty-four.
cap_max_dim(64).

% Define cap_colour_count: there are sixteen distinct colours.
cap_colour_count(16).

% Define cap_valid_frame: a frame of legal shape and colour.
cap_valid_frame(Frame) :-
    % It must measure as a grid.
    gd_size(Frame, Rows, Cols),
    % The maximum dimension.
    cap_max_dim(Max),
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

% Define cap_available_actions: the canonical action superset a game affords.
cap_available_actions([action(1), action(2), action(3), action(4), action(5),
                       select(_X, _Y), undo]).

% Define cap_action_payload: the cell-select action carries its coordinates.
cap_action_payload(select(X, Y), GameId, _{game_id: GameId, x: X, y: Y}) :- !.
% Any other action carries only the game identifier.
cap_action_payload(_Action, GameId, _{game_id: GameId}).

% ---------------------------------------------------------------------------
% The guarded env adapter for the co_arc3 harness
% ---------------------------------------------------------------------------

% cap_last_/1: the last JSON reply the adapter received, for the win test.
:- dynamic cap_last_/1.

% Define cap_env: a guarded arc3_env speaking the live protocol.
cap_env(BaseUrl, ApiKey, GameId, arc3_env(
    % The reset goal restarts the level and returns the first frame.
    co_arc3proto:cap_reset(BaseUrl, ApiKey, GameId),
    % The act goal posts one action and returns the next frame.
    co_arc3proto:cap_act(BaseUrl, ApiKey, GameId),
    % The actions goal reports the canonical action set.
    co_arc3proto:cap_actions,
    % The solved goal reads the win flag of the last reply.
    co_arc3proto:cap_solved)).

% cap_reset(+BaseUrl, +ApiKey, +GameId, -Frame0): reset over HTTP, guarded.
cap_reset(BaseUrl, ApiKey, GameId, Frame0) :-
    % The reset command's path.
    cap_command_endpoint('RESET', Path),
    % The reset payload.
    cap_action_payload(reset, GameId, Payload),
    % Any transport failure fails honestly.
    catch(cap_post(BaseUrl, ApiKey, Path, Payload, Reply), _, fail),
    % Remember the reply for the win test.
    cap_remember(Reply),
    % The reply carries the first frame.
    Frame0 = Reply.frame.

% cap_act(+BaseUrl, +ApiKey, +GameId, +Action, -Frame1): one action, guarded.
cap_act(BaseUrl, ApiKey, GameId, Action, Frame1) :-
    % The action's command path.
    cap_action_endpoint(Action, Path),
    % The action's payload.
    cap_action_payload(Action, GameId, Payload),
    % Any transport failure fails honestly.
    catch(cap_post(BaseUrl, ApiKey, Path, Payload, Reply), _, fail),
    % Remember the reply for the win test.
    cap_remember(Reply),
    % The reply carries the next frame.
    Frame1 = Reply.frame.

% cap_actions(-Actions): the canonical action set the harness may choose from.
cap_actions(Actions) :-
    % Report the canonical superset.
    cap_available_actions(Actions).

% cap_solved(+_Frame): the last reply reported the level won.
cap_solved(_Frame) :-
    % Read the remembered reply.
    cap_last_(Reply),
    % Its state must be the winning state.
    catch(cap_is_win(Reply.state), _, fail).

% cap_remember(+Reply): store the last reply, replacing any previous.
cap_remember(Reply) :-
    % Drop the previous reply.
    retractall(cap_last_(_)),
    % Store the new one.
    assertz(cap_last_(Reply)).

% cap_post(+BaseUrl, +ApiKey, +Path, +Payload, -Reply): POST JSON, read JSON.
cap_post(BaseUrl, ApiKey, Path, Payload, Reply) :-
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
