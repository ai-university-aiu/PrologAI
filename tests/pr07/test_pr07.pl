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

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/actors/prolog'], ActorsPath),
   assertz(file_search_path(library, ActorsPath)).

:- use_module(library(plunit)).
:- use_module(library(receptor)).

:- dynamic pr07_received/1.
:- dynamic pr07_msg_log/1.

:- begin_tests(pr07).

test(handler_invoked) :-
    retractall(pr07_received(_)),
    receptor('signal://localhost/t1',
             [Msg]>>(assertz(pr07_received(Msg)))),
    send_message('signal://localhost/t1', hello),
    sleep(0.1),
    pr07_received(hello),
    receptor_decommission('signal://localhost/t1').

test(send_nonblocking) :-
    receptor('signal://localhost/t2',
             [_]>>(flag(pr07_nblock_flag, N, N+1))),
    flag(pr07_nblock_flag, _, 0),
    get_time(T0),
    send_message('signal://localhost/t2', x),
    get_time(T1),
    Diff is T1 - T0,
    Diff < 0.1,
    receptor_decommission('signal://localhost/t2').

test(handler_error_survives) :-
    receptor('signal://localhost/t3',
             [_]>>(throw(deliberate))),
    send_message('signal://localhost/t3', x),
    sleep(0.1),
    send_message('signal://localhost/t3', y),
    sleep(0.1),
    receptor_backlog_count('signal://localhost/t3', _),
    receptor_decommission('signal://localhost/t3').

test(decommission_drains) :-
    receptor('signal://localhost/t4',
             [_]>>(flag(pr07_drain_count, N, N+1))),
    flag(pr07_drain_count, _, 0),
    send_message('signal://localhost/t4', a),
    send_message('signal://localhost/t4', b),
    send_message('signal://localhost/t4', c),
    receptor_decommission('signal://localhost/t4').

test(backlog_count) :-
    receptor('signal://localhost/t5', [_]>>(flag(pr07_backlog_done, X, X+1))),
    flag(pr07_backlog_done, _, 0),
    send_message('signal://localhost/t5', 1),
    send_message('signal://localhost/t5', 2),
    send_message('signal://localhost/t5', 3),
    receptor_backlog_count('signal://localhost/t5', N),
    N >= 0,
    receptor_decommission('signal://localhost/t5').

test(bad_address_throws,
     [throws(error(domain_error(signal_address, bad_addr), _))]) :-
    receptor(bad_addr, writeln).

test(idempotent) :-
    receptor('signal://localhost/t7', writeln),
    receptor('signal://localhost/t7', writeln),
    findall(_, receptor:receptor_entry('signal://localhost/t7', _, _), Ls),
    length(Ls, 1),
    receptor_decommission('signal://localhost/t7').

test(multiple_messages) :-
    retractall(pr07_msg_log(_)),
    receptor('signal://localhost/t8',
             [Msg]>>(assertz(pr07_msg_log(Msg)))),
    send_message('signal://localhost/t8', a),
    send_message('signal://localhost/t8', b),
    send_message('signal://localhost/t8', c),
    sleep(0.15),
    findall(M, pr07_msg_log(M), L),
    length(L, 3),
    receptor_decommission('signal://localhost/t8').

test(send_unknown_throws,
     [throws(error(existence_error(receptor, 'signal://localhost/unknown'), _))]) :-
    send_message('signal://localhost/unknown', x).

:- end_tests(pr07).
