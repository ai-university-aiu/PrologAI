/*  PrologAI — MCP Gateway Test Suite  (WP-014)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/model_context_protocol_gateway/test/test_model_context_protocol_gateway.pl

    Exercises the four exported predicates behaviourally: the API-key
    store (default, set, get, overwrite) and the server lifecycle
    (start, idempotent start, stop, no-op stop). The lifecycle binds a
    local loopback port only; no external server or network is needed.
*/

% Declare this file as a test module.
:- module(test_model_context_protocol_gateway, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(model_context_protocol_gateway)).

% Pick a distinctive loopback port for the lifecycle test.
test_port(7491).

% Open the test block for model_context_protocol_gateway.
:- begin_tests(model_context_protocol_gateway).

% AC-001: the shipped default API key is the dev key.
test(default_api_key_is_dev_key) :-
    % Read the currently stored API key.
    model_context_protocol_gateway_get_api_key(Key),
    % Before any mutation it is the built-in development key.
    assertion(Key == 'prologai-dev-key').

% AC-002: a key that is set is the key that is read back.
test(set_then_get_roundtrip) :-
    % Store a custom API key.
    model_context_protocol_gateway_set_api_key('roundtrip-key-abc'),
    % Read the stored API key back out.
    model_context_protocol_gateway_get_api_key(Key),
    % The value read matches the value written.
    assertion(Key == 'roundtrip-key-abc').

% AC-003: setting a key replaces the previous one — exactly one is stored.
test(set_overwrites_previous_key) :-
    % Store a first API key.
    model_context_protocol_gateway_set_api_key('first-key'),
    % Store a second API key, which should replace the first.
    model_context_protocol_gateway_set_api_key('second-key'),
    % Collect every stored key value.
    findall(K, model_context_protocol_gateway_get_api_key(K), Keys),
    % Only the most recently set key remains.
    assertion(Keys == ['second-key']).

% AC-004: start binds the port, a second start is idempotent, and stop is a no-op when stopped.
test(start_idempotent_then_stop, [cleanup(catch(model_context_protocol_gateway_stop, _, true))]) :-
    % Choose the loopback test port.
    test_port(Port),
    % Ensure a clean starting state with nothing bound.
    catch(model_context_protocol_gateway_stop, _, true),
    % Start the gateway HTTP server on the chosen port.
    assertion(model_context_protocol_gateway_start(Port)),
    % A second start on the same port succeeds without rebinding.
    assertion(model_context_protocol_gateway_start(Port)),
    % Stopping the running server succeeds.
    assertion(model_context_protocol_gateway_stop),
    % Stopping again when nothing is running is a safe no-op.
    assertion(model_context_protocol_gateway_stop).

% Close the test block for model_context_protocol_gateway.
:- end_tests(model_context_protocol_gateway).
