/*  PrologAI — Robot Operating System Bridge (Embodiment in a Robot)  (PR 46)

    Lets a PrologAI mind inhabit a physical or simulated robot by bridging
    to ROS 2, enrolling the robot as an ordinary body through the Mind-Body
    pattern (PR 10).

    A robot is an instance of the Mind-Body interface, not a new cognitive
    layer.  A small bridge node (rclpy in a real deployment) subscribes to
    the robot's sensor topics and relays them as percepts; the mind's commands
    are turned into actuator messages.  This bridge node is the robot's herald.

    Sensor messages (sensor_msgs, geometry_msgs) map to perception_signal
    percepts processed by the detector suite (PR 30).  Camera frames become
    visual percepts.  TF2 coordinate frames map onto reference frames (PR 39).

    Navigation 2 (Nav2) and MoveIt are wrapped as grounded tools (PR 44)
    rather than reimplemented.

    Embodiment is staged and contained (Part 38):
        - Simulation-only by default (Gazebo, NVIDIA Isaac Sim, or Webots).
        - No physical actuation until capability evaluation permits it.
        - Every irreversible physical action passes the constitutional check.
        - Network limited to an allowlist until staged autonomy widens it.

    Predicates:
        pai_robot_enroll/3   — +RobotDesc, +Simulator, -BodyId
        pai_ros_bridge/2     — +Topic, -Percept: relay a ROS 2 message
        pai_robot_observe/1  — -Percepts: snapshot all pending percepts
        pai_robot_act/2      — +Action, -Confirmation: gated actuation
*/

:- module(ros_bridge, [
    pai_robot_enroll/3,
    pai_ros_bridge/2,
    pai_robot_observe/1,
    pai_robot_act/2
]).

:- use_module(library(lists),  [member/2, memberchk/2]).
:- use_module(library(apply),  [maplist/2, maplist/3]).

% ---------------------------------------------------------------------------
% Bridge state
% ---------------------------------------------------------------------------

:- dynamic robot_body/3.          % BodyId, RobotDesc, Simulator
:- dynamic body_counter/1.
:- dynamic bridge_percept/3.      % BodyId, Topic, Percept
:- dynamic percept_counter/1.
:- dynamic act_log/3.             % ActionId, Action, Confirmation
:- dynamic action_counter/1.
:- dynamic simulation_mode/1.     % simulated(Simulator) | physical
:- dynamic capability_level/1.    % simulation_only | real_world
:- dynamic ros_topic/3.           % BodyId, TopicName, TopicType

body_counter(0).
percept_counter(0).
action_counter(0).

capability_level(simulation_only).   % default: confined to simulation

next_body_id(Id) :-
    retract(body_counter(N)), N1 is N + 1,
    assertz(body_counter(N1)), Id = robot_body(N1).

next_percept_id(Id) :-
    retract(percept_counter(N)), N1 is N + 1,
    assertz(percept_counter(N1)), Id = percept(N1).

next_action_id(Id) :-
    retract(action_counter(N)), N1 is N + 1,
    assertz(action_counter(N1)), Id = act(N1).

% ---------------------------------------------------------------------------
% pai_robot_enroll/3 — enroll a robot as a Mind-Body body
%
%   RobotDesc describes the robot: robot(Name, Capabilities, URDF)
%   Simulator is one of: gazebo | isaac_sim | webots | none
%       none means a real physical robot (requires capability_level real_world)
%   BodyId is the assigned body identifier
%
%   Registers sensor topics from the robot's capability list.
%   Physical robots are blocked until real_world capability is granted.
% ---------------------------------------------------------------------------

pai_robot_enroll(RobotDesc, Simulator, BodyId) :-
    ( Simulator = none
    ->  ( capability_level(real_world)
        ->  true
        ;   throw(error(physical_robot_requires_real_world_capability, pai_robot_enroll/3))
        )
    ;   true
    ),
    next_body_id(BodyId),
    assertz(robot_body(BodyId, RobotDesc, Simulator)),
    register_topics(BodyId, RobotDesc).

register_topics(BodyId, robot(_, Caps, _)) :-
    maplist(register_cap_topic(BodyId), Caps).
register_topics(_, _).

register_cap_topic(BodyId, camera)     :- assertz(ros_topic(BodyId, '/camera/image_raw',    sensor_msgs_image)).
register_cap_topic(BodyId, lidar)      :- assertz(ros_topic(BodyId, '/scan',                sensor_msgs_laser_scan)).
register_cap_topic(BodyId, imu)        :- assertz(ros_topic(BodyId, '/imu/data',            sensor_msgs_imu)).
register_cap_topic(BodyId, odometry)   :- assertz(ros_topic(BodyId, '/odom',                nav_msgs_odometry)).
register_cap_topic(BodyId, drive_base) :- assertz(ros_topic(BodyId, '/cmd_vel',             geometry_msgs_twist)).
register_cap_topic(BodyId, arm)        :- assertz(ros_topic(BodyId, '/joint_states',        sensor_msgs_joint_state)).
register_cap_topic(_, _).   % unknown capabilities silently ignored

% ---------------------------------------------------------------------------
% pai_ros_bridge/2 — relay an incoming ROS 2 message as a percept
%
%   Topic is the ROS 2 topic name (atom) or a message/3 term:
%       message(BodyId, TopicName, Payload)
%   Percept is the perception_signal term stored for pai_robot_observe/1.
%
%   Sensor message → percept mapping:
%       sensor_msgs_image      → visual_percept(image, Payload)
%       sensor_msgs_laser_scan → spatial_percept(lidar, Payload)
%       sensor_msgs_imu        → proprioceptive(imu, Payload)
%       nav_msgs_odometry      → proprioceptive(odometry, Payload)
%       geometry_msgs_*        → proprioceptive(geometry, Payload)
%       (unknown)              → raw_percept(Topic, Payload)
% ---------------------------------------------------------------------------

pai_ros_bridge(message(BodyId, TopicName, Payload), Percept) :-
    ( ros_topic(BodyId, TopicName, TopicType)
    ->  map_to_percept(TopicType, Payload, Signal)
    ;   Signal = raw_percept(TopicName, Payload)
    ),
    next_percept_id(Pid),
    Percept = perception_signal(Pid, BodyId, Signal),
    assertz(bridge_percept(BodyId, TopicName, Percept)).

map_to_percept(sensor_msgs_image,      Payload, visual_percept(image, Payload)).
map_to_percept(sensor_msgs_laser_scan, Payload, spatial_percept(lidar, Payload)).
map_to_percept(sensor_msgs_imu,        Payload, proprioceptive(imu, Payload)).
map_to_percept(nav_msgs_odometry,      Payload, proprioceptive(odometry, Payload)).
map_to_percept(sensor_msgs_joint_state,Payload, proprioceptive(joint_state, Payload)).
map_to_percept(geometry_msgs_twist,    Payload, proprioceptive(velocity, Payload)).
map_to_percept(UnknownType,            Payload, raw_percept(UnknownType, Payload)).

% ---------------------------------------------------------------------------
% pai_robot_observe/1 — snapshot all pending percepts from enrolled robots
%
%   Returns a list of all perception_signal terms buffered since the last
%   observe call.  Clears the buffer so each percept is delivered once.
% ---------------------------------------------------------------------------

pai_robot_observe(Percepts) :-
    findall(P, bridge_percept(_, _, P), Percepts),
    retractall(bridge_percept(_, _, _)).

% ---------------------------------------------------------------------------
% pai_robot_act/2 — gated actuation
%
%   Actions:
%       drive(BodyId, LinearVel, AngularVel)   — send velocity command
%       arm_move(BodyId, JointAngles)          — send joint-state command
%       navigate(BodyId, GoalPose)             — Nav2 navigation goal
%       manipulate(BodyId, Task)               — MoveIt manipulation task
%       stop(BodyId)                           — emergency stop
%
%   Irreversible physical actions (drive, arm_move) pass the constitutional
%   gate; physical-world actuation is blocked until capability_level = real_world.
%
%   Returns Confirmation = confirmed(ActionId, Action, Result)
%          or denied(Action, Reason)
% ---------------------------------------------------------------------------

pai_robot_act(Action, Confirmation) :-
    action_body(Action, BodyId),
    ( requires_real_world(Action)
    ->  ( capability_level(real_world)
        ->  gate_and_dispatch(BodyId, Action, Confirmation)
        ;   Confirmation = denied(Action, simulation_only_capability)
        )
    ;   gate_and_dispatch(BodyId, Action, Confirmation)
    ).

action_body(drive(B, _, _),    B).
action_body(arm_move(B, _),    B).
action_body(navigate(B, _),    B).
action_body(manipulate(B, _),  B).
action_body(stop(B),           B).

requires_real_world(drive(B, _, _))  :- robot_body(B, _, none).
requires_real_world(arm_move(B, _)) :- robot_body(B, _, none).

gate_and_dispatch(BodyId, Action, Confirmation) :-
    ( robot_body(BodyId, _, _)
    ->  ( irreversible_action(Action)
        ->  ( constitutional_gate(Action)
            ->  dispatch_robot_action(Action, Result),
                next_action_id(AId),
                assertz(act_log(AId, Action, Result)),
                Confirmation = confirmed(AId, Action, Result)
            ;   Confirmation = denied(Action, constitutional_veto)
            )
        ;   dispatch_robot_action(Action, Result),
            next_action_id(AId),
            assertz(act_log(AId, Action, Result)),
            Confirmation = confirmed(AId, Action, Result)
        )
    ;   Confirmation = denied(Action, body_not_enrolled)
    ).

irreversible_action(drive(_, _, _)).
irreversible_action(arm_move(_, _)).

constitutional_gate(drive(_, V, W)) :-
    abs(V) =< 2.0, abs(W) =< 3.14.   % speed limits as a safety invariant
constitutional_gate(arm_move(_, _)).
constitutional_gate(navigate(_, _)).
constitutional_gate(manipulate(_, _)).
constitutional_gate(stop(_)).

dispatch_robot_action(drive(BodyId, V, W),       drove(BodyId, V, W)).
dispatch_robot_action(arm_move(BodyId, Joints),  arm_moved(BodyId, Joints)).
dispatch_robot_action(navigate(BodyId, Goal),    navigating(BodyId, Goal)).
dispatch_robot_action(manipulate(BodyId, Task),  manipulating(BodyId, Task)).
dispatch_robot_action(stop(BodyId),              stopped(BodyId)).

% ---------------------------------------------------------------------------
% Helpers for tests and external callers
% ---------------------------------------------------------------------------

simulation_mode(BodyId, Sim) :-
    robot_body(BodyId, _, Sim).
