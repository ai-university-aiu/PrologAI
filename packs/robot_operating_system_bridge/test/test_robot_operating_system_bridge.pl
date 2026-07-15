%% Declare this file as the 'test_robot_operating_system_bridge' module, exporting nothing.
:- module(test_robot_operating_system_bridge, []).
%% Load the built-in 'plunit' library so its test predicates are available here.
:- use_module(library(plunit)).
%% Import member/2 from the built-in 'lists' library for list membership checks.
:- use_module(library(lists), [member/2]).
%% Load the 'robot_operating_system_bridge' pack under test from the library path.
:- use_module(library(robot_operating_system_bridge)).

%% Open the PLUnit test block named 'robot_operating_system_bridge'.
:- begin_tests(robot_operating_system_bridge).

%% Define the shared setup that resets the bridge's dynamic state before each test.
test_robot_operating_system_bridge_reset :-
    %% Remove every enrolled robot-body fact from the runtime knowledge base.
    retractall(robot_operating_system_bridge:robot_operating_system_bridge_robot_body(_, _, _)),
    %% Remove every body-counter fact from the runtime knowledge base.
    retractall(robot_operating_system_bridge:robot_operating_system_bridge_body_counter(_)),
    %% Remove every buffered-percept fact from the runtime knowledge base.
    retractall(robot_operating_system_bridge:robot_operating_system_bridge_bridge_percept(_, _, _)),
    %% Remove every percept-counter fact from the runtime knowledge base.
    retractall(robot_operating_system_bridge:robot_operating_system_bridge_percept_counter(_)),
    %% Remove every action-log fact from the runtime knowledge base.
    retractall(robot_operating_system_bridge:robot_operating_system_bridge_act_log(_, _, _)),
    %% Remove every action-counter fact from the runtime knowledge base.
    retractall(robot_operating_system_bridge:robot_operating_system_bridge_action_counter(_)),
    %% Remove every capability-level fact from the runtime knowledge base.
    retractall(robot_operating_system_bridge:robot_operating_system_bridge_capability_level(_)),
    %% Remove every registered-topic fact from the runtime knowledge base.
    retractall(robot_operating_system_bridge:robot_operating_system_bridge_topic(_, _, _)),
    %% Reseed the body counter at zero so body ids start fresh.
    assertz(robot_operating_system_bridge:robot_operating_system_bridge_body_counter(0)),
    %% Reseed the percept counter at zero so percept ids start fresh.
    assertz(robot_operating_system_bridge:robot_operating_system_bridge_percept_counter(0)),
    %% Reseed the action counter at zero so action ids start fresh.
    assertz(robot_operating_system_bridge:robot_operating_system_bridge_action_counter(0)),
    %% Restore the default simulation-only capability level.
    assertz(robot_operating_system_bridge:robot_operating_system_bridge_capability_level(simulation_only)).

%% Test that enrolling a robot registers its body fact and its sensor topics.
test(enroll_registers_body_and_topics, [setup(test_robot_operating_system_bridge_reset)]) :-
    %% Describe a robot with a camera, lidar, and odometry.
    Robot = robot(bot, [camera, lidar, odometry], urdf(bot)),
    %% Enroll the robot into a Webots simulator, binding its body id.
    once(robot_operating_system_bridge_enroll(Robot, webots, BodyId)),
    %% Assert the robot-body fact was recorded with the Webots simulator.
    assertion(robot_operating_system_bridge:robot_operating_system_bridge_robot_body(BodyId, Robot, webots)),
    %% Assert the camera capability registered the raw-image topic.
    assertion(robot_operating_system_bridge:robot_operating_system_bridge_topic(BodyId, '/camera/image_raw', sensor_msgs_image)),
    %% Assert the lidar capability registered the laser-scan topic.
    assertion(robot_operating_system_bridge:robot_operating_system_bridge_topic(BodyId, '/scan', sensor_msgs_laser_scan)).

%% Test that a camera message is relayed as a visual percept.
test(camera_maps_to_visual_percept, [setup(test_robot_operating_system_bridge_reset)]) :-
    %% Describe a camera-only robot.
    Robot = robot(cam_bot, [camera], urdf(cam_bot)),
    %% Enroll the robot into a Gazebo simulator, binding its body id.
    once(robot_operating_system_bridge_enroll(Robot, gazebo, BodyId)),
    %% Relay a camera image message and capture the produced percept.
    once(robot_operating_system_bridge(message(BodyId, '/camera/image_raw', img_data), Percept)),
    %% Assert the percept is a visual_percept carrying the image payload.
    assertion(Percept = perception_signal(_, BodyId, visual_percept(image, img_data))).

%% Test that a laser-scan message is relayed as a spatial percept.
test(lidar_maps_to_spatial_percept, [setup(test_robot_operating_system_bridge_reset)]) :-
    %% Describe a lidar-only robot.
    Robot = robot(lidar_bot, [lidar], urdf(lidar_bot)),
    %% Enroll the robot into an Isaac Sim simulator, binding its body id.
    once(robot_operating_system_bridge_enroll(Robot, isaac_sim, BodyId)),
    %% Relay a laser-scan message and capture the produced percept.
    once(robot_operating_system_bridge(message(BodyId, '/scan', scan_data), Percept)),
    %% Assert the percept is a spatial_percept carrying the scan payload.
    assertion(Percept = perception_signal(_, BodyId, spatial_percept(lidar, scan_data))).

%% Test that observe returns the buffered percepts once and then clears the buffer.
test(observe_returns_then_clears_buffer, [setup(test_robot_operating_system_bridge_reset)]) :-
    %% Describe a camera-only robot.
    Robot = robot(buf_bot, [camera], urdf(buf_bot)),
    %% Enroll the robot into a Webots simulator, binding its body id.
    once(robot_operating_system_bridge_enroll(Robot, webots, BodyId)),
    %% Relay one camera message so a single percept is buffered.
    once(robot_operating_system_bridge(message(BodyId, '/camera/image_raw', frame), _)),
    %% Observe the buffer, capturing the first snapshot.
    once(robot_operating_system_bridge_observe(First)),
    %% Assert the first snapshot contains exactly one percept.
    assertion(First = [perception_signal(_, BodyId, visual_percept(image, frame))]),
    %% Observe the buffer again, capturing the second snapshot.
    once(robot_operating_system_bridge_observe(Second)),
    %% Assert the second snapshot is empty because observe cleared the buffer.
    assertion(Second == []).

%% Test that a lawful drive command in simulation is confirmed.
test(drive_confirmed_in_simulation, [setup(test_robot_operating_system_bridge_reset)]) :-
    %% Describe a drive-base robot.
    Robot = robot(drive_bot, [drive_base], urdf(drive_bot)),
    %% Enroll the robot into a Gazebo simulator, binding its body id.
    once(robot_operating_system_bridge_enroll(Robot, gazebo, BodyId)),
    %% Issue a within-limit drive command and capture the confirmation.
    once(robot_operating_system_bridge_act(drive(BodyId, 1.0, 0.5), Conf)),
    %% Assert the command was confirmed with a matching drove result.
    assertion(Conf = confirmed(_, drive(BodyId, 1.0, 0.5), drove(BodyId, 1.0, 0.5))).

%% Test that an over-speed drive command is denied by the constitutional gate.
test(excessive_speed_vetoed, [setup(test_robot_operating_system_bridge_reset)]) :-
    %% Describe a drive-base robot.
    Robot = robot(fast_bot, [drive_base], urdf(fast_bot)),
    %% Enroll the robot into a Gazebo simulator, binding its body id.
    once(robot_operating_system_bridge_enroll(Robot, gazebo, BodyId)),
    %% Issue a drive command whose 10.0 m/s speed exceeds the 2.0 limit.
    once(robot_operating_system_bridge_act(drive(BodyId, 10.0, 0.0), Conf)),
    %% Assert the command was denied with a constitutional veto.
    assertion(Conf = denied(drive(BodyId, 10.0, 0.0), constitutional_veto)).

%% Close the PLUnit test block named 'robot_operating_system_bridge'.
:- end_tests(robot_operating_system_bridge).
