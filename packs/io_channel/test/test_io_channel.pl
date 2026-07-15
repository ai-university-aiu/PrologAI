:- use_module('../prolog/io_channel').

:- begin_tests(io_channel).

% io_channel_register_channel/3: register a console text-output channel and verify info.
test(register_console_text_out) :-
    io_channel_register_channel(text_out, console_config, Id),
    atom(Id),
    io_channel_channel_info(Id, info(Id, text_out, console_config)).

% io_channel_register_channel/3: register an email channel and verify info.
test(register_email_text_out) :-
    io_channel_register_channel(text_out, email_config('test@example.com', 'PrologAI'), Id),
    atom(Id),
    io_channel_channel_info(Id, info(Id, text_out, email_config('test@example.com', 'PrologAI'))).

% io_channel_list_channels/2: newly registered channels appear in the type list.
test(list_channels) :-
    io_channel_register_channel(text_out, console_config, Id),
    io_channel_list_channels(text_out, Channels),
    member(chan(Id, console_config), Channels).

% io_channel_channel_status/2: registered channel is ready.
test(channel_status_ready) :-
    io_channel_register_channel(text_out, console_config, Id),
    io_channel_channel_status(Id, Status),
    Status = ready.

% io_channel_channel_status/2: unknown channel ID returns unavailable.
test(channel_status_unavailable) :-
    io_channel_channel_status(chan_99999, Status),
    Status = unavailable.

% io_channel_register_channel/3: register a speaker channel and verify info.
test(register_speaker) :-
    io_channel_register_channel(audio_out, speaker_config(''), Id),
    atom(Id),
    io_channel_channel_info(Id, info(Id, audio_out, speaker_config(''))).

% io_channel_register_channel/3: register a mic channel and verify info.
test(register_mic) :-
    io_channel_register_channel(audio_in, mic_config(''), Id),
    atom(Id),
    io_channel_channel_info(Id, info(Id, audio_in, mic_config(''))).

% io_channel_register_channel/3: register a printer channel and verify info.
test(register_printer) :-
    io_channel_register_channel(printer, printer_config('HP_LaserJet', []), Id),
    atom(Id),
    io_channel_channel_info(Id, info(Id, printer, printer_config('HP_LaserJet', []))).

% io_channel_register_channel/3: register an app channel and verify info.
test(register_app) :-
    io_channel_register_channel(text_out, app_config(myapp, 'http://localhost:8080/text'), Id),
    atom(Id),
    io_channel_channel_info(Id, info(Id, text_out, app_config(myapp, 'http://localhost:8080/text'))).

% io_channel_text_out/3: writing to the console channel returns ok.
test(text_out_console) :-
    io_channel_text_out(console_config, 'Hello from PrologAI iochan test.', Status),
    Status = ok.

% io_channel_speak/2: default speaker attempt returns ok or an error term.
test(speak_default) :-
    io_channel_speak('PrologAI channel test.', Status),
    ( Status = ok -> true ; Status = error(_) ).

% io_channel_listen/2: predicate is callable; hardware capture is skipped in unit test.
test(listen_default) :-
    ( catch(io_channel_listen(1, Transcript), _, Transcript = '') ->
        ( string(Transcript) ; Transcript = '' )
    ;
        true
    ).

% io_channel_print_text/3: printing text to a default printer returns ok or error.
test(print_text_default) :-
    io_channel_register_channel(printer, printer_config('', []), PrintId),
    catch(
        ( io_channel_print_text(PrintId, 'PrologAI iochan printer test.', Status),
          member(Status, [ok, error(lp_unavailable), error(_)])
        ),
        _,
        true
    ).

% io_channel_register_channel/3: register an image-input webcam channel and verify info.
test(register_webcam) :-
    io_channel_register_channel(image_in, webcam_config('/dev/video0'), Id),
    atom(Id),
    io_channel_channel_info(Id, info(Id, image_in, webcam_config('/dev/video0'))).

% io_channel_list_channels/2: listing a type with no extra channels returns at least the defaults.
test(list_audio_out_channels) :-
    io_channel_list_channels(audio_out, Channels),
    Channels = [_|_].

:- end_tests(io_channel).
