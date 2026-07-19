% Test suite for the realization pack — binding a grounded structure record to the
% native dynamical law or Lattice signal that realizes it, by identity.
% These tests confirm bidirectional query, the REAL existence check (a defined
% predicate; an open nexus) that turns a dangling label into a finding, the unbound
% case, the glass-box trace, and the P4 typed Lattice signal.
% Load the realization module under test.
:- use_module(library(realization)).
% Load the Lattice store the typed signals live in.
:- use_module(library(lattice)).
% Load the PLUnit testing framework.
:- use_module(library(plunit)).

% A stand-in native dynamical law (the suppression law a structure record realizes).
test_realization_law(_Input, _Output).

% Open the test block for the realization pack.
:- begin_tests(realization).

% Before each test, clear the binding registry so tests do not leak into one another.
setup_clean_bindings :-
    forall(realization_realized_by(S, R), retract_binding(S, R)).
% Retract one binding (unbind removes all of a structure; here remove them one structure at a time).
retract_binding(S, _) :- realization_unbind(S).

% A structure bound to an EXISTING native law checks ok, and the trace shows it exists.
test(bound_to_existing_law_is_ok, setup(setup_clean_bindings)) :-
    realization_bind(cortisol_skip_record, native_law(user:test_realization_law/2)),
    realization_check(cortisol_skip_record, Result),
    assertion(Result = ok([native_law(user:test_realization_law/2)])),
    realization_trace(cortisol_skip_record, Trace),
    get_dict(realized_by, Trace, [Step]),
    assertion(get_dict(exists, Step, true)).

% A structure bound to a MISSING native law is a finding (dangling), not a crash.
% This is the whole point: the binding must be REAL, not a shared English word.
test(bound_to_missing_law_is_dangling, setup(setup_clean_bindings)) :-
    realization_bind(phantom_record, native_law(user:test_realization_absent/9)),
    realization_check(phantom_record, Result),
    assertion(Result = invalid(dangling([native_law(user:test_realization_absent/9)]))),
    realization_trace(phantom_record, Trace),
    get_dict(realized_by, Trace, [Step]),
    assertion(get_dict(exists, Step, false)).

% The binding is queryable in BOTH directions — structure to realizer and back.
test(binding_is_bidirectional, setup(setup_clean_bindings)) :-
    realization_bind(plasticity_conduit, native_law(user:test_realization_law/2)),
    realization_realized_by(plasticity_conduit, R),
    assertion(R == native_law(user:test_realization_law/2)),
    realization_realizes(native_law(user:test_realization_law/2), S),
    assertion(S == plasticity_conduit).

% An unbound structure is reported unbound — it has no dynamics to trace to.
test(unbound_structure_is_reported, setup(setup_clean_bindings)) :-
    realization_check(never_bound_record, Result),
    assertion(Result == invalid(unbound(never_bound_record))).

% An ill-formed realizer is refused at bind time.
test(illformed_realizer_is_refused, [setup(setup_clean_bindings),
     throws(error(domain_error(realization_realizer, _), _))]) :-
    realization_bind(some_record, not_a_realizer).

% check_all reports one line per bound structure, mixing ok and dangling honestly.
test(check_all_reports_every_binding, setup(setup_clean_bindings)) :-
    realization_bind(good_record, native_law(user:test_realization_law/2)),
    realization_bind(bad_record, native_law(user:test_realization_absent/9)),
    realization_check_all(Report),
    assertion(memberchk(good_record-ok(_), Report)),
    assertion(memberchk(bad_record-invalid(dangling(_)), Report)).

% P4: a structure bound to a typed Lattice signal — the signal is emitted and read back,
% and the binding checks ok because the nexus (the signal's home) is open.
test(typed_lattice_signal_is_bound_emitted_and_read, setup(setup_clean_bindings)) :-
    lattice_open('locus://realization_signal', Nexus),
    realization_bind(dopamine_conduit, lattice_signal(Nexus, dopamine_signal)),
    % The dynamics writes a typed signal: value, source port, timestamp.
    realization_emit_signal(Nexus, dopamine_signal, 0.7, ventral_tegmental_port, 12),
    realization_signal(Nexus, dopamine_signal, Value, Port, Time),
    assertion(Value == 0.7), assertion(Port == ventral_tegmental_port), assertion(Time == 12),
    % The binding is real because the nexus carrying the signal is open.
    realization_check(dopamine_conduit, Result),
    assertion(Result = ok([lattice_signal(Nexus, dopamine_signal)])).

% STRATA-5: the binding ties a stratified structure to UNGROUNDED native dynamics with
% NO shared stratum — the realization pack itself declares no stratum, and the binding
% works across the seam all the same.
test(binding_heals_the_seam_without_a_shared_stratum, setup(setup_clean_bindings)) :-
    % The structure record is grounded (it would sit at a stratum); the native law is not.
    realization_bind(synapse_transform_record, native_law(user:test_realization_law/2)),
    realization_check(synapse_transform_record, Result),
    assertion(Result = ok(_)).

% Close the test block.
:- end_tests(realization).
