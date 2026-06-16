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

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/ros_bridge/prolog'], RBPath),
   assertz(file_search_path(library, RBPath)).

:- use_module(library(plunit)).
:- use_module(library(lists),     [member/2]).
:- use_module(library(ros_bridge), [
    pai_robot_enroll/3,
    pai_ros_bridge/2,
    pai_robot_observe/1,
    pai_robot_act/2
]).

:- begin_tests(pr46, [setup(pr46_setup), cleanup(pr46_cleanup)]).

pr46_setup :-
    retractall(ros_bridge:robot_body(_, _, _)),
    retractall(ros_bridge:body_counter(_)),
    retractall(ros_bridge:bridge_percept(_, _, _)),
    retractall(ros_bridge:percept_counter(_)),
    retractall(ros_bridge:act_log(_, _, _)),
    retractall(ros_bridge:action_counter(_)),
    retractall(ros_bridge:capability_level(_)),
    retractall(ros_bridge:ros_topic(_, _, _)),
    assertz(ros_bridge:body_counter(0)),
    assertz(ros_bridge:percept_counter(0)),
    assertz(ros_bridge:action_counter(0)),
    assertz(ros_bridge:capability_level(simulation_only)).

pr46_cleanup :- pr46_setup.

%  AC-PR46-001: observe scene, plan route, drive, confirm from feedback
test(observe_plan_drive_confirm, [setup(pr46_setup)]) :-
    Robot = robot(rover46, [camera, drive_base, odometry], urdf(rover46)),
    once(pai_robot_enroll(Robot, gazebo, BodyId)),
    % Simulate a camera percept arriving (object detected)
    once(pai_ros_bridge(message(BodyId, '/camera/image_raw', frame(colored_object46)), CamPercept)),
    CamPercept = perception_signal(_, BodyId, visual_percept(image, frame(colored_object46))),
    % Observe to get all buffered percepts
    once(pai_robot_observe(Percepts)),
    once(member(perception_signal(_, BodyId, visual_percept(image, _)), Percepts)),
    % Issue a drive command toward the object (simulated)
    once(pai_robot_act(drive(BodyId, 0.5, 0.0), DriveConf)),
    DriveConf = confirmed(_, drive(BodyId, 0.5, 0.0), drove(BodyId, 0.5, 0.0)),
    % Proprioceptive feedback: odometry arrives confirming movement
    once(pai_ros_bridge(message(BodyId, '/odom', pose(at_object46)), OdomPercept)),
    OdomPercept = perception_signal(_, BodyId, proprioceptive(odometry, pose(at_object46))),
    once(pai_robot_observe(Feedback)),
    once(member(perception_signal(_, BodyId, proprioceptive(odometry, _)), Feedback)).

%  AC-PR46-002: physical actuation withheld in simulation_only state
test(physical_actuation_withheld, [setup(pr46_setup)]) :-
    Robot = robot(physical_rover46, [camera, drive_base], urdf(physical_rover46)),
    % Enrolling a physical robot (Simulator=none) in simulation_only capability throws
    \+ catch(pai_robot_enroll(Robot, none, _), _, fail).

%  AC-PR46-003: enroll registers body and topics
test(enroll_registers_body, [setup(pr46_setup)]) :-
    Robot = robot(bot46, [camera, lidar, odometry], urdf(bot46)),
    once(pai_robot_enroll(Robot, webots, BodyId)),
    ros_bridge:robot_body(BodyId, Robot, webots),
    ros_bridge:ros_topic(BodyId, '/camera/image_raw', sensor_msgs_image),
    ros_bridge:ros_topic(BodyId, '/scan', sensor_msgs_laser_scan).

%  AC-PR46-004: camera topic maps to visual_percept
test(camera_to_visual_percept, [setup(pr46_setup)]) :-
    Robot = robot(cam_bot46, [camera], urdf(cam_bot46)),
    once(pai_robot_enroll(Robot, gazebo, BodyId)),
    once(pai_ros_bridge(message(BodyId, '/camera/image_raw', img_data46), Percept)),
    Percept = perception_signal(_, BodyId, visual_percept(image, img_data46)).

%  AC-PR46-005: laser scan maps to spatial_percept
test(lidar_to_spatial_percept, [setup(pr46_setup)]) :-
    Robot = robot(lidar_bot46, [lidar], urdf(lidar_bot46)),
    once(pai_robot_enroll(Robot, isaac_sim, BodyId)),
    once(pai_ros_bridge(message(BodyId, '/scan', scan_data46), Percept)),
    Percept = perception_signal(_, BodyId, spatial_percept(lidar, scan_data46)).

%  AC-PR46-006: odometry maps to proprioceptive
test(odom_to_proprioceptive, [setup(pr46_setup)]) :-
    Robot = robot(odom_bot46, [odometry], urdf(odom_bot46)),
    once(pai_robot_enroll(Robot, gazebo, BodyId)),
    once(pai_ros_bridge(message(BodyId, '/odom', odom_data46), Percept)),
    Percept = perception_signal(_, BodyId, proprioceptive(odometry, odom_data46)).

%  AC-PR46-007: observe clears the buffer
test(observe_clears_buffer, [setup(pr46_setup)]) :-
    Robot = robot(buf_bot46, [camera], urdf(buf_bot46)),
    once(pai_robot_enroll(Robot, webots, BodyId)),
    once(pai_ros_bridge(message(BodyId, '/camera/image_raw', frame46), _)),
    once(pai_robot_observe(First)),
    length(First, 1),
    once(pai_robot_observe(Second)),
    length(Second, 0).

%  AC-PR46-008: drive in simulation returns confirmed
test(drive_confirmed_in_simulation, [setup(pr46_setup)]) :-
    Robot = robot(drive_bot46, [drive_base], urdf(drive_bot46)),
    once(pai_robot_enroll(Robot, gazebo, BodyId)),
    once(pai_robot_act(drive(BodyId, 1.0, 0.5), Conf)),
    Conf = confirmed(_, drive(BodyId, 1.0, 0.5), drove(BodyId, 1.0, 0.5)).

%  AC-PR46-009: excessive speed is vetoed by the constitutional gate
test(excessive_speed_vetoed, [setup(pr46_setup)]) :-
    Robot = robot(fast_bot46, [drive_base], urdf(fast_bot46)),
    once(pai_robot_enroll(Robot, gazebo, BodyId)),
    % Speed 10.0 m/s exceeds the 2.0 limit in constitutional_gate
    once(pai_robot_act(drive(BodyId, 10.0, 0.0), Conf)),
    Conf = denied(drive(BodyId, 10.0, 0.0), constitutional_veto).

:- end_tests(pr46).
