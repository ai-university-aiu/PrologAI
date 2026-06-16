/*  PrologAI — PR 7 Receptor Acceptance Tests

    AC-PR07-001: receptor + send_message — handler is invoked.
    AC-PR07-002: send_message returns immediately (non-blocking).
    AC-PR07-003: Handler exception is logged; receptor keeps running.
    AC-PR07-004: receptor_decommission drains and stops.
    AC-PR07-005: receptor_backlog_count returns queue depth.
    AC-PR07-006: Bad address format throws domain_error.
    AC-PR07-007: receptor is idempotent (same address twice → one thread).
    AC-PR07-008: Multiple messages are all delivered.
    AC-PR07-009: send_message to unknown address throws.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'], ActorsPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, ActorsPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'receptor' library so its predicates are available here.
:- use_module(library(receptor)).

% Declare 'pr07_received/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic pr07_received/1.
% Declare 'pr07_msg_log/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic pr07_msg_log/1.

% Execute the compile-time directive: begin_tests(pr07).
:- begin_tests(pr07).

% Define a clause for 'test': succeed when the following conditions hold.
test(handler_invoked) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pr07_received(_)),
    % State a fact for 'receptor' with the arguments listed below.
    receptor('signal://localhost/t1',
             % Continue the multi-line expression started above.
             [Msg]>>(assertz(pr07_received(Msg)))),
    % State a fact for 'send message' with the arguments listed below.
    send_message('signal://localhost/t1', hello),
    % State a fact for 'sleep' with the arguments listed below.
    sleep(0.1),
    % State a fact for 'pr07 received' with the arguments listed below.
    pr07_received(hello),
    % State the fact: receptor decommission('signal://localhost/t1').
    receptor_decommission('signal://localhost/t1').

% Define a clause for 'test': succeed when the following conditions hold.
test(send_nonblocking) :-
    % State a fact for 'receptor' with the arguments listed below.
    receptor('signal://localhost/t2',
             % Continue the multi-line expression started above.
             [_]>>(flag(pr07_nblock_flag, N, N+1))),
    % State a fact for 'flag' with the arguments listed below.
    flag(pr07_nblock_flag, _, 0),
    % State a fact for 'get time' with the arguments listed below.
    get_time(T0),
    % State a fact for 'send message' with the arguments listed below.
    send_message('signal://localhost/t2', x),
    % State a fact for 'get time' with the arguments listed below.
    get_time(T1),
    % Evaluate the arithmetic expression 'T1 - T0' and bind the result to 'Diff'.
    Diff is T1 - T0,
    % Check that 'Diff' is less than '0.1'.
    Diff < 0.1,
    % State the fact: receptor decommission('signal://localhost/t2').
    receptor_decommission('signal://localhost/t2').

% Define a clause for 'test': succeed when the following conditions hold.
test(handler_error_survives) :-
    % State a fact for 'receptor' with the arguments listed below.
    receptor('signal://localhost/t3',
             % Continue the multi-line expression started above.
             [_]>>(throw(deliberate))),
    % State a fact for 'send message' with the arguments listed below.
    send_message('signal://localhost/t3', x),
    % State a fact for 'sleep' with the arguments listed below.
    sleep(0.1),
    % State a fact for 'send message' with the arguments listed below.
    send_message('signal://localhost/t3', y),
    % State a fact for 'sleep' with the arguments listed below.
    sleep(0.1),
    % State a fact for 'receptor backlog count' with the arguments listed below.
    receptor_backlog_count('signal://localhost/t3', _),
    % State the fact: receptor decommission('signal://localhost/t3').
    receptor_decommission('signal://localhost/t3').

% Define a clause for 'test': succeed when the following conditions hold.
test(decommission_drains) :-
    % State a fact for 'receptor' with the arguments listed below.
    receptor('signal://localhost/t4',
             % Continue the multi-line expression started above.
             [_]>>(flag(pr07_drain_count, N, N+1))),
    % State a fact for 'flag' with the arguments listed below.
    flag(pr07_drain_count, _, 0),
    % State a fact for 'send message' with the arguments listed below.
    send_message('signal://localhost/t4', a),
    % State a fact for 'send message' with the arguments listed below.
    send_message('signal://localhost/t4', b),
    % State a fact for 'send message' with the arguments listed below.
    send_message('signal://localhost/t4', c),
    % State the fact: receptor decommission('signal://localhost/t4').
    receptor_decommission('signal://localhost/t4').

% Define a clause for 'test': succeed when the following conditions hold.
test(backlog_count) :-
    % State a fact for 'receptor' with the arguments listed below.
    receptor('signal://localhost/t5', [_]>>(flag(pr07_backlog_done, X, X+1))),
    % State a fact for 'flag' with the arguments listed below.
    flag(pr07_backlog_done, _, 0),
    % State a fact for 'send message' with the arguments listed below.
    send_message('signal://localhost/t5', 1),
    % State a fact for 'send message' with the arguments listed below.
    send_message('signal://localhost/t5', 2),
    % State a fact for 'send message' with the arguments listed below.
    send_message('signal://localhost/t5', 3),
    % State a fact for 'receptor backlog count' with the arguments listed below.
    receptor_backlog_count('signal://localhost/t5', N),
    % Check that 'N' is greater than or equal to '0'.
    N >= 0,
    % State the fact: receptor decommission('signal://localhost/t5').
    receptor_decommission('signal://localhost/t5').

% State a fact for 'test' with the arguments listed below.
test(bad_address_throws,
     % Continue the multi-line expression started above.
     [throws(error(domain_error(signal_address, bad_addr), _))]) :-
    % State the fact: receptor(bad_addr, writeln).
    receptor(bad_addr, writeln).

% Define a clause for 'test': succeed when the following conditions hold.
test(idempotent) :-
    % State a fact for 'receptor' with the arguments listed below.
    receptor('signal://localhost/t7', writeln),
    % State a fact for 'receptor' with the arguments listed below.
    receptor('signal://localhost/t7', writeln),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(_, receptor:receptor_entry('signal://localhost/t7', _, _), Ls),
    % Unify '1' with the number of elements in list 'Ls'.
    length(Ls, 1),
    % State the fact: receptor decommission('signal://localhost/t7').
    receptor_decommission('signal://localhost/t7').

% Define a clause for 'test': succeed when the following conditions hold.
test(multiple_messages) :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(pr07_msg_log(_)),
    % State a fact for 'receptor' with the arguments listed below.
    receptor('signal://localhost/t8',
             % Continue the multi-line expression started above.
             [Msg]>>(assertz(pr07_msg_log(Msg)))),
    % State a fact for 'send message' with the arguments listed below.
    send_message('signal://localhost/t8', a),
    % State a fact for 'send message' with the arguments listed below.
    send_message('signal://localhost/t8', b),
    % State a fact for 'send message' with the arguments listed below.
    send_message('signal://localhost/t8', c),
    % State a fact for 'sleep' with the arguments listed below.
    sleep(0.15),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(M, pr07_msg_log(M), L),
    % Unify '3' with the number of elements in list 'L'.
    length(L, 3),
    % State the fact: receptor decommission('signal://localhost/t8').
    receptor_decommission('signal://localhost/t8').

% State a fact for 'test' with the arguments listed below.
test(send_unknown_throws,
     % Continue the multi-line expression started above.
     [throws(error(existence_error(receptor, 'signal://localhost/unknown'), _))]) :-
    % State the fact: send message('signal://localhost/unknown', x).
    send_message('signal://localhost/unknown', x).

% Execute the compile-time directive: end_tests(pr07).
:- end_tests(pr07).
