:- module(io_channel, [
    % io_channel_text_out/3: write text to a registered text-output channel.
    io_channel_text_out/3,
    % io_channel_text_in/2: read text from a registered text-input channel.
    io_channel_text_in/2,
    % io_channel_image_out/3: send an image (file path) to a registered image-output channel.
    io_channel_image_out/3,
    % io_channel_image_in/2: capture an image from a registered image-input channel into a file path.
    io_channel_image_in/2,
    % io_channel_speak/2: synthesize speech from text and play through the default audio-output channel.
    io_channel_speak/2,
    % io_channel_speak_to/3: synthesize speech and send to a named audio-output channel.
    io_channel_speak_to/3,
    % io_channel_listen/2: record audio for DurationSecs from the default mic and return a text transcript.
    io_channel_listen/2,
    % io_channel_listen_from/3: record audio from a named mic channel and return a text transcript.
    io_channel_listen_from/3,
    % io_channel_print_text/3: send text to a registered printer channel.
    io_channel_print_text/3,
    % io_channel_print_image/3: send an image (file path) to a registered printer channel.
    io_channel_print_image/3,
    % io_channel_register_channel/3: register a channel configuration under a type.
    io_channel_register_channel/3,
    % io_channel_channel_info/2: retrieve the configuration of a registered channel.
    io_channel_channel_info/2,
    % io_channel_list_channels/2: list all registered channels of a given type.
    io_channel_list_channels/2,
    % io_channel_channel_status/2: check whether a channel is available (ready or unavailable).
    io_channel_channel_status/2
]).

% iochan.pl - Layer 254: I/O Channel Integration (ic_* prefix).
% Fourteen predicates for dispatching text, images, audio, and print jobs
% through named channels: console, email, screen, app, speaker, microphone, printer.
% Channel configurations are stored as dynamic facts and dispatched via the
% ic_dispatch_* family of private helpers.
% Channel config terms:
%   console_config              - system console (stdout/stdin)
%   email_config(Addr, Subject) - SMTP email via sendmail subprocess
%   screen_config(WinId)        - X11 window or display target
%   app_config(AppId, Endpoint) - HTTP POST to an application endpoint
%   speaker_config(DevId)       - audio playback device (empty atom = default)
%   mic_config(DevId)           - audio capture device (empty atom = default)
%   printer_config(Name, Opts)  - CUPS printer name and option list

:- use_module(library(lists),   [member/2, last/2]).
:- use_module(library(process), [process_create/3, process_wait/2]).
:- use_module(library(readutil), [read_line_to_string/2, read_file_to_string/3,
                                   read_file_to_codes/3]).
:- ( catch(use_module(library(http/http_client), [http_post/4, http_get/3]),
           _, true) ).

% --- CHANNEL REGISTRY ---

% io_channel_channel/3: ChannelId, ChannelType, Config - runtime channel registry.
:- dynamic io_channel_channel/3.

% io_channel_chan_counter/1: monotonic counter for channel ID generation.
:- dynamic io_channel_chan_counter/1.
% Seed the counter at 0.
io_channel_chan_counter(0).

% io_channel_next_id_/1: generate the next unique channel ID atom.
io_channel_next_id_(Id) :-
%   Retrieve and retract the current counter value.
    retract(io_channel_chan_counter(N)),
%   Increment the counter by one.
    N1 is N + 1,
%   Assert the updated counter value.
    assertz(io_channel_chan_counter(N1)),
%   Build a channel ID atom from the counter value.
    atomic_list_concat([chan, N1], '_', Id).

% io_channel_register_channel/3: +ChannelType, +Config, -ChannelId
% Register a channel configuration under the given type and return its ID.
io_channel_register_channel(Type, Config, ChannelId) :-
%   Generate a fresh unique ID for this channel.
    io_channel_next_id_(ChannelId),
%   Record the channel in the runtime registry.
    assertz(io_channel_channel(ChannelId, Type, Config)).

% io_channel_channel_info/2: +ChannelId, -Info
% Retrieve the stored configuration for a channel ID.
io_channel_channel_info(ChannelId, info(ChannelId, Type, Config)) :-
%   Look up the channel in the registry.
    io_channel_channel(ChannelId, Type, Config).

% io_channel_list_channels/2: +ChannelType, -Channels
% List all registered channels of the given type as [chan(Id, Config), ...].
io_channel_list_channels(Type, Channels) :-
%   Collect all channels whose type matches.
    findall(chan(Id, Config),
            io_channel_channel(Id, Type, Config),
            Channels).

% io_channel_channel_status/2: +ChannelId, -Status
% Return ready if the channel exists, unavailable otherwise.
io_channel_channel_status(ChannelId, Status) :-
%   Check existence; if found, status is ready.
    ( io_channel_channel(ChannelId, _, _) ->
        Status = ready
    ;
        Status = unavailable
    ).

% --- DEFAULT CHANNEL SEEDS ---

% Register the console as the default text-output and text-input channel.
:- io_channel_register_channel(text_out, console_config, _).
:- io_channel_register_channel(text_in,  console_config, _).

% Register the console as the default image-output channel.
:- io_channel_register_channel(image_out, console_config, _).

% Register default speaker and microphone channels.
:- io_channel_register_channel(audio_out, speaker_config(''),  _).
:- io_channel_register_channel(audio_in,  mic_config(''),      _).

% --- TEXT OUTPUT ---

% io_channel_text_out/3: +Channel, +Text, -Status
% Dispatch Text to the named channel.
% Channel may be a registered ChannelId atom or a config term.
io_channel_text_out(Channel, Text, Status) :-
%   Resolve channel config from ID or direct config term.
    io_channel_resolve_(text_out, Channel, Config),
%   Dispatch text to the resolved config.
    io_channel_dispatch_text_out_(Config, Text, Status).

% io_channel_dispatch_text_out_/3: +Config, +Text, -Status
% Write text to the console.
io_channel_dispatch_text_out_(console_config, Text, ok) :-
%   Write text followed by a newline.
    writeln(Text).

% Send text via sendmail subprocess.
io_channel_dispatch_text_out_(email_config(Addr, Subject), Text, Status) :-
%   Build a simple email message in a temporary file.
    tmp_file_name_(tmp_email, TmpPath),
%   Write the message text to the temp file.
    setup_call_cleanup(
        open(TmpPath, write, Stream),
        ( format(Stream, "To: ~w~nSubject: ~w~n~n~w~n", [Addr, Subject, Text]) ),
        close(Stream)
    ),
%   Launch sendmail to deliver the message and capture exit code.
    catch(
        ( process_create(path(sendmail),
                         ['-t', file(TmpPath)],
                         [process(Pid)]),
          process_wait(Pid, exit(Code)),
          ( Code =:= 0 -> Status = ok ; Status = error(Code) )
        ),
        _Err,
        Status = error(sendmail_unavailable)
    ).

% Send text to an X11 window using xdotool type.
io_channel_dispatch_text_out_(screen_config(WinId), Text, Status) :-
%   Build the window ID argument as an atom.
    atom_string(WinId, WinStr),
%   Use xdotool to type text into the target window.
    catch(
        ( process_create(path(xdotool),
                         [type, '--window', WinStr, Text],
                         [process(Pid)]),
          process_wait(Pid, exit(Code)),
          ( Code =:= 0 -> Status = ok ; Status = error(Code) )
        ),
        _Err,
        Status = error(xdotool_unavailable)
    ).

% POST text to an application HTTP endpoint.
io_channel_dispatch_text_out_(app_config(_AppId, Endpoint), Text, Status) :-
%   Use library(http/http_client) http_post to send text as a string body.
    catch(
        ( atom_string(Text, TextStr),
          http_post(Endpoint,
                    string(TextStr),
                    _Response,
                    [status_code(Code)]),
          ( Code >= 200, Code < 300 -> Status = ok ; Status = error(Code) )
        ),
        _Err,
        Status = error(http_unavailable)
    ).

% --- TEXT INPUT ---

% io_channel_text_in/2: +Channel, -Text
% Read text from the named channel.
io_channel_text_in(Channel, Text) :-
%   Resolve channel config.
    io_channel_resolve_(text_in, Channel, Config),
%   Dispatch text input from the resolved config.
    io_channel_dispatch_text_in_(Config, Text).

% Read a line from the console.
io_channel_dispatch_text_in_(console_config, Text) :-
%   Read a full line from standard input into Text.
    read_line_to_string(user_input, Text).

% Fetch the most recent unread email via fetchmail shell script.
io_channel_dispatch_text_in_(email_config(_Addr, _Subject), Text) :-
%   Write a shell snippet to fetch latest email body.
    tmp_file_name_(tmp_email_in, TmpPath),
%   Call fetchmail in one-shot mode writing to tmp file.
    catch(
        ( process_create(path(fetchmail),
                         ['--limit', '1', '--output', TmpPath],
                         [process(Pid)]),
          process_wait(Pid, _),
          read_file_to_string(TmpPath, Text, [])
        ),
        _Err,
        Text = ''
    ).

% Read text typed into an X11 window via xdotool.
io_channel_dispatch_text_in_(screen_config(_WinId), Text) :-
%   Fall back to console read: no generalized screen capture defined.
    read_line_to_string(user_input, Text).

% Poll an application HTTP endpoint for text.
io_channel_dispatch_text_in_(app_config(_AppId, Endpoint), Text) :-
%   Perform an HTTP GET to retrieve text.
    catch(
        http_get(Endpoint, Text, []),
        _Err,
        Text = ''
    ).

% --- IMAGE OUTPUT ---

% io_channel_image_out/3: +Channel, +ImagePath, -Status
% Send the image at ImagePath to the named channel.
io_channel_image_out(Channel, ImagePath, Status) :-
%   Resolve channel config.
    io_channel_resolve_(image_out, Channel, Config),
%   Dispatch image output to the resolved config.
    io_channel_dispatch_image_out_(Config, ImagePath, Status).

% Display an image in the console using img2txt or write the path.
io_channel_dispatch_image_out_(console_config, ImagePath, ok) :-
%   Attempt img2txt for terminal rendering; fall back to printing the path.
    catch(
        ( process_create(path(img2txt),
                         [ImagePath],
                         [process(Pid)]),
          process_wait(Pid, _)
        ),
        _,
        format("Image: ~w~n", [ImagePath])
    ).

% Email an image as an attachment.
io_channel_dispatch_image_out_(email_config(Addr, Subject), ImagePath, Status) :-
%   Use mutt or mail -a for attachment.
    catch(
        ( process_create(path(mutt),
                         ['-s', Subject, '-a', ImagePath, '--', Addr],
                         [process(Pid), stdin(null)]),
          process_wait(Pid, exit(Code)),
          ( Code =:= 0 -> Status = ok ; Status = error(Code) )
        ),
        _Err,
        Status = error(mutt_unavailable)
    ).

% Display an image on an X11 screen using eog or display.
io_channel_dispatch_image_out_(screen_config(_WinId), ImagePath, Status) :-
%   Try display (ImageMagick) first, then eog.
    catch(
        ( process_create(path(display),
                         [ImagePath],
                         [process(Pid)]),
          process_wait(Pid, exit(Code)),
          ( Code =:= 0 -> Status = ok ; Status = error(Code) )
        ),
        _Err,
        Status = error(display_unavailable)
    ).

% POST an image to an application endpoint.
io_channel_dispatch_image_out_(app_config(_AppId, Endpoint), ImagePath, Status) :-
%   Read image bytes and POST as application/octet-stream.
    catch(
        ( read_file_to_codes(ImagePath, Codes, []),
          atom_codes(ImageAtom, Codes),
          http_post(Endpoint,
                    atom('application/octet-stream', ImageAtom),
                    _Response,
                    [status_code(Code)]),
          ( Code >= 200, Code < 300 -> Status = ok ; Status = error(Code) )
        ),
        _Err,
        Status = error(http_unavailable)
    ).

% --- IMAGE INPUT ---

% io_channel_image_in/2: +Channel, -ImagePath
% Capture an image from the named channel, returning the file path.
io_channel_image_in(Channel, ImagePath) :-
%   Resolve channel config.
    io_channel_resolve_(image_in, Channel, Config),
%   Dispatch image capture to the resolved config.
    io_channel_dispatch_image_in_(Config, ImagePath).

% Read an image from a file path channel config.
io_channel_dispatch_image_in_(file_config(Path), Path) :-
%   Verify the image file exists.
    exists_file(Path).

% Capture from a webcam using fswebcam.
io_channel_dispatch_image_in_(webcam_config(DevId), ImagePath) :-
%   Build a temporary image file path.
    tmp_file_name_(webcam_capture, ImagePath),
%   Capture one frame from the device.
    catch(
        ( process_create(path(fswebcam),
                         ['-d', DevId, '-F', '1', ImagePath],
                         [process(Pid)]),
          process_wait(Pid, _)
        ),
        _Err,
        true
    ).

% Download an image from a URL.
io_channel_dispatch_image_in_(url_config(URL), ImagePath) :-
%   Build a temporary file path.
    tmp_file_name_(url_image, ImagePath),
%   Use wget to download the image.
    catch(
        ( process_create(path(wget),
                         ['-q', '-O', ImagePath, URL],
                         [process(Pid)]),
          process_wait(Pid, _)
        ),
        _Err,
        true
    ).

% --- SPEAKER OUTPUT ---

% io_channel_speak/2: +Text, -Status
% Synthesize speech from Text and play through the default speaker channel.
io_channel_speak(Text, Status) :-
%   Dispatch to default speaker config.
    io_channel_dispatch_speak_(speaker_config(''), Text, Status).

% io_channel_speak_to/3: +Channel, +Text, -Status
% Synthesize speech and send to the named audio-output channel.
io_channel_speak_to(Channel, Text, Status) :-
%   Resolve channel config.
    io_channel_resolve_(audio_out, Channel, Config),
%   Dispatch speech synthesis to the resolved config.
    io_channel_dispatch_speak_(Config, Text, Status).

% io_channel_dispatch_speak_/3: +Config, +Text, -Status
% Use espeak-ng to synthesize speech; empty DevId uses the default device.
io_channel_dispatch_speak_(speaker_config(DevId), Text, Status) :-
%   Build espeak-ng argument list with optional device flag.
    ( DevId = '' ->
        Args = [Text]
    ;
        Args = ['-a', DevId, Text]
    ),
%   Call espeak-ng subprocess; fall back to festival if unavailable.
    ( catch(
          ( process_create(path('espeak-ng'), Args, [process(Pid)]),
            process_wait(Pid, exit(Code)),
            ( Code =:= 0 -> Status = ok ; Status = error(Code) )
          ),
          _Err,
          fail
      ) ->
        true
    ;
        io_channel_dispatch_speak_festival_(Text, Status)
    ).

% io_channel_dispatch_speak_festival_/2: fall back to festival if espeak-ng is absent.
io_channel_dispatch_speak_festival_(Text, Status) :-
%   Write text to a temp file for festival.
    tmp_file_name_(festival_tts, TmpPath),
%   Write the text content to the temp file.
    setup_call_cleanup(
        open(TmpPath, write, Stream),
        format(Stream, "~w", [Text]),
        close(Stream)
    ),
%   Run festival in text2wave mode.
    catch(
        ( process_create(path(festival),
                         ['--tts', TmpPath],
                         [process(Pid)]),
          process_wait(Pid, exit(Code)),
          ( Code =:= 0 -> Status = ok ; Status = error(Code) )
        ),
        _Err,
        Status = error(tts_unavailable)
    ).

% --- MICROPHONE INPUT ---

% io_channel_listen/2: +DurationSecs, -Transcript
% Record audio for DurationSecs from the default mic and transcribe via Whisper.
io_channel_listen(DurationSecs, Transcript) :-
%   Dispatch to default mic config.
    io_channel_dispatch_listen_(mic_config(''), DurationSecs, Transcript).

% io_channel_listen_from/3: +Channel, +DurationSecs, -Transcript
% Record audio from the named mic channel and transcribe.
io_channel_listen_from(Channel, DurationSecs, Transcript) :-
%   Resolve channel config.
    io_channel_resolve_(audio_in, Channel, Config),
%   Dispatch audio capture to the resolved config.
    io_channel_dispatch_listen_(Config, DurationSecs, Transcript).

% io_channel_dispatch_listen_/3: +Config, +DurationSecs, -Transcript
% Record with arecord for DurationSecs, then transcribe with whisper-cli.
io_channel_dispatch_listen_(mic_config(DevId), DurationSecs, Transcript) :-
%   Return empty transcript immediately for zero-duration requests.
    ( DurationSecs =:= 0 ->
        Transcript = ''
    ;
%       Build a temporary WAV file path.
        tmp_file_name_(mic_recording, WavPath),
%       Build arecord argument list with optional device flag.
        ( DevId = '' ->
            RecArgs = ['-d', DurationSecs, '-f', 'cd', WavPath]
        ;
            RecArgs = ['-D', DevId, '-d', DurationSecs, '-f', 'cd', WavPath]
        ),
%       Record audio using arecord; bind Transcript to empty on failure.
        ( catch(
              ( process_create(path(arecord), RecArgs, [process(RecPid)]),
                process_wait(RecPid, _)
              ),
              _RecErr,
              fail
          ) ->
%           Transcribe the captured WAV with whisper-cli.
            tmp_file_name_(whisper_out, TxtPath),
            catch(
                ( process_create(path('whisper-cli'),
                                 [WavPath, '--output-txt',
                                  '--output-file', TxtPath],
                                 [process(WhisperPid)]),
                  process_wait(WhisperPid, _),
                  read_file_to_string(TxtPath, Transcript, [encoding(utf8)])
                ),
                _WhisperErr,
                Transcript = ''
            )
        ;
            Transcript = ''
        )
    ).

% --- PRINTER OUTPUT ---

% io_channel_print_text/3: +Channel, +Text, -Status
% Send text to a registered printer channel.
io_channel_print_text(Channel, Text, Status) :-
%   Resolve channel config.
    io_channel_resolve_(printer, Channel, Config),
%   Dispatch to the resolved printer config.
    io_channel_dispatch_print_text_(Config, Text, Status).

% io_channel_dispatch_print_text_/3: +Config, +Text, -Status
% Write text to a temp file and submit via lp.
io_channel_dispatch_print_text_(printer_config(Name, Opts), Text, Status) :-
%   Build a temporary text file for the print job.
    tmp_file_name_(print_job, TmpPath),
%   Write the text content to the temp file.
    setup_call_cleanup(
        open(TmpPath, write, Stream),
        format(Stream, "~w", [Text]),
        close(Stream)
    ),
%   Build lp argument list; include printer name if not empty.
    io_channel_lp_args_(Name, Opts, TmpPath, Args),
%   Submit the print job.
    catch(
        ( process_create(path(lp), Args, [process(Pid)]),
          process_wait(Pid, exit(Code)),
          ( Code =:= 0 -> Status = ok ; Status = error(Code) )
        ),
        _Err,
        Status = error(lp_unavailable)
    ).

% io_channel_print_image/3: +Channel, +ImagePath, -Status
% Send an image to a registered printer channel.
io_channel_print_image(Channel, ImagePath, Status) :-
%   Resolve channel config.
    io_channel_resolve_(printer, Channel, Config),
%   Dispatch to the resolved printer config.
    io_channel_dispatch_print_image_(Config, ImagePath, Status).

% io_channel_dispatch_print_image_/3: +Config, +ImagePath, -Status
% Submit image directly to lp.
io_channel_dispatch_print_image_(printer_config(Name, Opts), ImagePath, Status) :-
%   Build lp argument list with the image file.
    io_channel_lp_args_(Name, Opts, ImagePath, Args),
%   Submit the print job.
    catch(
        ( process_create(path(lp), Args, [process(Pid)]),
          process_wait(Pid, exit(Code)),
          ( Code =:= 0 -> Status = ok ; Status = error(Code) )
        ),
        _Err,
        Status = error(lp_unavailable)
    ).

% io_channel_lp_args_/4: +Name, +Opts, +FilePath, -Args
% Build the lp argument list. If Name is empty, use the default printer.
io_channel_lp_args_('', _Opts, FilePath, [FilePath]) :- !.
io_channel_lp_args_(Name, [], FilePath, ['-d', Name, FilePath]) :- !.
io_channel_lp_args_(Name, [Opt|Opts], FilePath, ['-d', Name, '-o', Opt | Rest]) :-
%   Recurse for additional options (simplified: only first opt is applied here).
    io_channel_lp_args_(Name, Opts, FilePath, PartialArgs),
%   Remove the duplication of name/file arguments from recursion.
    last(PartialArgs, _),
    Rest = [FilePath].

% --- CHANNEL RESOLUTION HELPER ---

% io_channel_resolve_/3: +ChannelType, +ChannelOrConfig, -Config
% If given a registered ChannelId atom, look up its config.
% If given a config term directly, use it as-is.
io_channel_resolve_(Type, Channel, Config) :-
%   If Channel is a registered ID, retrieve its config.
    ( io_channel_channel(Channel, Type, Config) ->
        true
    ;
%   Otherwise treat Channel as the config term directly.
        Config = Channel
    ).

% --- TEMPORARY FILE HELPER ---

% tmp_file_name_/2: +Base, -Path
% Generate a unique temporary file path under /tmp.
tmp_file_name_(Base, Path) :-
%   Get the current time in milliseconds as a unique suffix.
    get_time(T),
    Suffix is round(T * 1000) mod 1000000,
%   Concatenate base name and suffix.
    atomic_list_concat(['/tmp/io_channel_', Base, '_', Suffix], Path).
