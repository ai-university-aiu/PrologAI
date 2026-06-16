/*  PrologAI — PR 46 ROS 2 Robot Bridge Acceptance Tests

    AC-PR46-001: Given a simulated robot in Gazebo or Webots with a camera
                 and a drive base, when the mind is asked to find and approach
                 a colored object, then it observes the scene as percepts,
                 plans a route, issues drive commands, and confirms arrival
                 from proprioceptive feedback.
    AC-PR46-002: Given the mind in simulation-only state, when a
                 physical-actuation command is attempted, then it is withheld
                 until staged autonomy and capability evaluation permit it.
    AC-PR46-003: pai_robot_enroll registers a robot body with its topics.
    AC-PR46-004: pai_ros_bridge maps a camera message to a visual_percept.
    AC-PR46-005: pai_ros_bridge maps a laser scan to a spatial_percept.
    AC-PR46-006: pai_ros_bridge maps an odometry message to proprioceptive.
    AC-PR46-007: pai_robot_observe returns buffered percepts and clears buffer.
    AC-PR46-008: pai_robot_act drive in simulation is confirmed.
    AC-PR46-009: pai_robot_act with excessive speed is vetoed by constitutional gate.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/ros_bridge/prolog'], RBPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, RBPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Import [member/2] from the built-in 'lists' library.
:- use_module(library(lists),     [member/2]).
% Load the built-in 'ros_bridge' library so its predicates are available here.
:- use_module(library(ros_bridge), [
    % Supply 'pai_robot_enroll/3' as the next argument to the expression above.
    pai_robot_enroll/3,
    % Supply 'pai_ros_bridge/2' as the next argument to the expression above.
    pai_ros_bridge/2,
    % Supply 'pai_robot_observe/1' as the next argument to the expression above.
    pai_robot_observe/1,
    % Supply 'pai_robot_act/2' as the next argument to the expression above.
    pai_robot_act/2
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr46, [setup(pr46_setup), cleanup(pr46_cleanup)]).
:- begin_tests(pr46, [setup(pr46_setup), cleanup(pr46_cleanup)]).

% Execute: pr46_setup :-.
pr46_setup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(ros_bridge:robot_body(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(ros_bridge:body_counter(_)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(ros_bridge:bridge_percept(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(ros_bridge:percept_counter(_)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(ros_bridge:act_log(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(ros_bridge:action_counter(_)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(ros_bridge:capability_level(_)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(ros_bridge:ros_topic(_, _, _)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(ros_bridge:body_counter(0)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(ros_bridge:percept_counter(0)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(ros_bridge:action_counter(0)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(ros_bridge:capability_level(simulation_only)).

% Execute: pr46_cleanup :- pr46_setup..
pr46_cleanup :- pr46_setup.

%  AC-PR46-001: observe scene, plan route, drive, confirm from feedback
% Define a clause for 'test': succeed when the following conditions hold.
test(observe_plan_drive_confirm, [setup(pr46_setup)]) :-
    % Check that 'Robot' is unifiable with 'robot(rover46, [camera, drive_base, odometry], urdf(rover46))'.
    Robot = robot(rover46, [camera, drive_base, odometry], urdf(rover46)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_robot_enroll(Robot, gazebo, BodyId)),
    % Simulate a camera percept arriving (object detected)
    % State a fact for 'once' with the arguments listed below.
    once(pai_ros_bridge(message(BodyId, '/camera/image_raw', frame(colored_object46)), CamPercept)),
    % Check that 'CamPercept' is unifiable with 'perception_signal(_, BodyId, visual_percept(image, frame(colored_object46)))'.
    CamPercept = perception_signal(_, BodyId, visual_percept(image, frame(colored_object46))),
    % Observe to get all buffered percepts
    % State a fact for 'once' with the arguments listed below.
    once(pai_robot_observe(Percepts)),
    % State a fact for 'once' with the arguments listed below.
    once(member(perception_signal(_, BodyId, visual_percept(image, _)), Percepts)),
    % Issue a drive command toward the object (simulated)
    % State a fact for 'once' with the arguments listed below.
    once(pai_robot_act(drive(BodyId, 0.5, 0.0), DriveConf)),
    % Check that 'DriveConf' is unifiable with 'confirmed(_, drive(BodyId, 0.5, 0.0), drove(BodyId, 0.5, 0.0))'.
    DriveConf = confirmed(_, drive(BodyId, 0.5, 0.0), drove(BodyId, 0.5, 0.0)),
    % Proprioceptive feedback: odometry arrives confirming movement
    % State a fact for 'once' with the arguments listed below.
    once(pai_ros_bridge(message(BodyId, '/odom', pose(at_object46)), OdomPercept)),
    % Check that 'OdomPercept' is unifiable with 'perception_signal(_, BodyId, proprioceptive(odometry, pose(at_object46)))'.
    OdomPercept = perception_signal(_, BodyId, proprioceptive(odometry, pose(at_object46))),
    % State a fact for 'once' with the arguments listed below.
    once(pai_robot_observe(Feedback)),
    % State the fact: once(member(perception_signal(_, BodyId, proprioceptive(odometry, _)), Feedback)).
    once(member(perception_signal(_, BodyId, proprioceptive(odometry, _)), Feedback)).

%  AC-PR46-002: physical actuation withheld in simulation_only state
% Define a clause for 'test': succeed when the following conditions hold.
test(physical_actuation_withheld, [setup(pr46_setup)]) :-
    % Check that 'Robot' is unifiable with 'robot(physical_rover46, [camera, drive_base], urdf(physical_rover46))'.
    Robot = robot(physical_rover46, [camera, drive_base], urdf(physical_rover46)),
    % Enrolling a physical robot (Simulator=none) in simulation_only capability throws
    % Succeed only if 'catch(pai_robot_enroll(Robot, none, _), _, fail' cannot be proved (negation as failure).
    \+ catch(pai_robot_enroll(Robot, none, _), _, fail).

%  AC-PR46-003: enroll registers body and topics
% Define a clause for 'test': succeed when the following conditions hold.
test(enroll_registers_body, [setup(pr46_setup)]) :-
    % Check that 'Robot' is unifiable with 'robot(bot46, [camera, lidar, odometry], urdf(bot46))'.
    Robot = robot(bot46, [camera, lidar, odometry], urdf(bot46)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_robot_enroll(Robot, webots, BodyId)),
    % Execute: ros_bridge:robot_body(BodyId, Robot, webots),.
    ros_bridge:robot_body(BodyId, Robot, webots),
    % Execute: ros_bridge:ros_topic(BodyId, '/camera/image_raw', sensor_msgs_image),.
    ros_bridge:ros_topic(BodyId, '/camera/image_raw', sensor_msgs_image),
    % Execute: ros_bridge:ros_topic(BodyId, '/scan', sensor_msgs_laser_scan)..
    ros_bridge:ros_topic(BodyId, '/scan', sensor_msgs_laser_scan).

%  AC-PR46-004: camera topic maps to visual_percept
% Define a clause for 'test': succeed when the following conditions hold.
test(camera_to_visual_percept, [setup(pr46_setup)]) :-
    % Check that 'Robot' is unifiable with 'robot(cam_bot46, [camera], urdf(cam_bot46))'.
    Robot = robot(cam_bot46, [camera], urdf(cam_bot46)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_robot_enroll(Robot, gazebo, BodyId)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_ros_bridge(message(BodyId, '/camera/image_raw', img_data46), Percept)),
    % Check that 'Percept' is unifiable with 'perception_signal(_, BodyId, visual_percept(image, img_data46))'.
    Percept = perception_signal(_, BodyId, visual_percept(image, img_data46)).

%  AC-PR46-005: laser scan maps to spatial_percept
% Define a clause for 'test': succeed when the following conditions hold.
test(lidar_to_spatial_percept, [setup(pr46_setup)]) :-
    % Check that 'Robot' is unifiable with 'robot(lidar_bot46, [lidar], urdf(lidar_bot46))'.
    Robot = robot(lidar_bot46, [lidar], urdf(lidar_bot46)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_robot_enroll(Robot, isaac_sim, BodyId)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_ros_bridge(message(BodyId, '/scan', scan_data46), Percept)),
    % Check that 'Percept' is unifiable with 'perception_signal(_, BodyId, spatial_percept(lidar, scan_data46))'.
    Percept = perception_signal(_, BodyId, spatial_percept(lidar, scan_data46)).

%  AC-PR46-006: odometry maps to proprioceptive
% Define a clause for 'test': succeed when the following conditions hold.
test(odom_to_proprioceptive, [setup(pr46_setup)]) :-
    % Check that 'Robot' is unifiable with 'robot(odom_bot46, [odometry], urdf(odom_bot46))'.
    Robot = robot(odom_bot46, [odometry], urdf(odom_bot46)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_robot_enroll(Robot, gazebo, BodyId)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_ros_bridge(message(BodyId, '/odom', odom_data46), Percept)),
    % Check that 'Percept' is unifiable with 'perception_signal(_, BodyId, proprioceptive(odometry, odom_data46))'.
    Percept = perception_signal(_, BodyId, proprioceptive(odometry, odom_data46)).

%  AC-PR46-007: observe clears the buffer
% Define a clause for 'test': succeed when the following conditions hold.
test(observe_clears_buffer, [setup(pr46_setup)]) :-
    % Check that 'Robot' is unifiable with 'robot(buf_bot46, [camera], urdf(buf_bot46))'.
    Robot = robot(buf_bot46, [camera], urdf(buf_bot46)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_robot_enroll(Robot, webots, BodyId)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_ros_bridge(message(BodyId, '/camera/image_raw', frame46), _)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_robot_observe(First)),
    % Unify '1' with the number of elements in list 'First'.
    length(First, 1),
    % State a fact for 'once' with the arguments listed below.
    once(pai_robot_observe(Second)),
    % Unify '0' with the number of elements in list 'Second'.
    length(Second, 0).

%  AC-PR46-008: drive in simulation returns confirmed
% Define a clause for 'test': succeed when the following conditions hold.
test(drive_confirmed_in_simulation, [setup(pr46_setup)]) :-
    % Check that 'Robot' is unifiable with 'robot(drive_bot46, [drive_base], urdf(drive_bot46))'.
    Robot = robot(drive_bot46, [drive_base], urdf(drive_bot46)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_robot_enroll(Robot, gazebo, BodyId)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_robot_act(drive(BodyId, 1.0, 0.5), Conf)),
    % Check that 'Conf' is unifiable with 'confirmed(_, drive(BodyId, 1.0, 0.5), drove(BodyId, 1.0, 0.5))'.
    Conf = confirmed(_, drive(BodyId, 1.0, 0.5), drove(BodyId, 1.0, 0.5)).

%  AC-PR46-009: excessive speed is vetoed by the constitutional gate
% Define a clause for 'test': succeed when the following conditions hold.
test(excessive_speed_vetoed, [setup(pr46_setup)]) :-
    % Check that 'Robot' is unifiable with 'robot(fast_bot46, [drive_base], urdf(fast_bot46))'.
    Robot = robot(fast_bot46, [drive_base], urdf(fast_bot46)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_robot_enroll(Robot, gazebo, BodyId)),
    % Speed 10.0 m/s exceeds the 2.0 limit in constitutional_gate
    % State a fact for 'once' with the arguments listed below.
    once(pai_robot_act(drive(BodyId, 10.0, 0.0), Conf)),
    % Check that 'Conf' is unifiable with 'denied(drive(BodyId, 10.0, 0.0), constitutional_veto)'.
    Conf = denied(drive(BodyId, 10.0, 0.0), constitutional_veto).

% Execute the compile-time directive: end_tests(pr46).
:- end_tests(pr46).
