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

% Declare this file as the 'ros_bridge' module and list its exported predicates.
:- module(ros_bridge, [
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

% Import [member/2, memberchk/2] from the built-in 'lists' library.
:- use_module(library(lists),  [member/2, memberchk/2]).
% Import [maplist/2, maplist/3] from the built-in 'apply' library.
:- use_module(library(apply),  [maplist/2, maplist/3]).

% ---------------------------------------------------------------------------
% Bridge state
% ---------------------------------------------------------------------------

% Declare 'robot_body/3.          % BodyId, RobotDesc, Simulator' as dynamic — its facts may be added or removed at runtime.
:- dynamic robot_body/3.          % BodyId, RobotDesc, Simulator
% Declare 'body_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic body_counter/1.
% Declare 'bridge_percept/3.      % BodyId, Topic, Percept' as dynamic — its facts may be added or removed at runtime.
:- dynamic bridge_percept/3.      % BodyId, Topic, Percept
% Declare 'percept_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic percept_counter/1.
% Declare 'act_log/3.             % ActionId, Action, Confirmation' as dynamic — its facts may be added or removed at runtime.
:- dynamic act_log/3.             % ActionId, Action, Confirmation
% Declare 'action_counter/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic action_counter/1.
% Declare 'simulation_mode/1.     % simulated(Simulator) | physical' as dynamic — its facts may be added or removed at runtime.
:- dynamic simulation_mode/1.     % simulated(Simulator) | physical
% Declare 'capability_level/1.    % simulation_only | real_world' as dynamic — its facts may be added or removed at runtime.
:- dynamic capability_level/1.    % simulation_only | real_world
% Declare 'ros_topic/3.           % BodyId, TopicName, TopicType' as dynamic — its facts may be added or removed at runtime.
:- dynamic ros_topic/3.           % BodyId, TopicName, TopicType

% State the fact: body counter(0).
body_counter(0).
% State the fact: percept counter(0).
percept_counter(0).
% State the fact: action counter(0).
action_counter(0).

% State a fact for 'capability level' with the arguments listed below.
capability_level(simulation_only).   % default: confined to simulation

% Define a clause for 'next body id': succeed when the following conditions hold.
next_body_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(body_counter(N)), N1 is N + 1,
    % Check that 'assertz(body_counter(N1)), Id' is unifiable with 'robot_body(N1)'.
    assertz(body_counter(N1)), Id = robot_body(N1).

% Define a clause for 'next percept id': succeed when the following conditions hold.
next_percept_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(percept_counter(N)), N1 is N + 1,
    % Check that 'assertz(percept_counter(N1)), Id' is unifiable with 'percept(N1)'.
    assertz(percept_counter(N1)), Id = percept(N1).

% Define a clause for 'next action id': succeed when the following conditions hold.
next_action_id(Id) :-
    % Remove a single matching fact or rule from the runtime knowledge base.
    retract(action_counter(N)), N1 is N + 1,
    % Check that 'assertz(action_counter(N1)), Id' is unifiable with 'act(N1)'.
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

% Define a clause for 'pai robot enroll': succeed when the following conditions hold.
pai_robot_enroll(RobotDesc, Simulator, BodyId) :-
    % Check that '( Simulator' is unifiable with 'none'.
    ( Simulator = none
    % If the condition above succeeded, perform the following action.
    ->  ( capability_level(real_world)
        % If the condition above succeeded, perform the following action.
        ->  true
        % Otherwise (else branch), perform the following action.
        ;   throw(error(physical_robot_requires_real_world_capability, pai_robot_enroll/3))
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ),
    % State a fact for 'next body id' with the arguments listed below.
    next_body_id(BodyId),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(robot_body(BodyId, RobotDesc, Simulator)),
    % State the fact: register topics(BodyId, RobotDesc).
    ros_bridge_topics(BodyId, RobotDesc).

% Define a clause for 'register topics': succeed when the following conditions hold.
ros_bridge_topics(BodyId, robot(_, Caps, _)) :-
    % State the fact: maplist(ros_bridge_cap_topic(BodyId), Caps).
    maplist(ros_bridge_cap_topic(BodyId), Caps).
% State the fact: register topics(_, _).
ros_bridge_topics(_, _).

% Define a clause for 'register cap topic': succeed when the following conditions hold.
ros_bridge_cap_topic(BodyId, camera)     :- assertz(ros_topic(BodyId, '/camera/image_raw',    sensor_msgs_image)).
% Define a clause for 'register cap topic': succeed when the following conditions hold.
ros_bridge_cap_topic(BodyId, lidar)      :- assertz(ros_topic(BodyId, '/scan',                sensor_msgs_laser_scan)).
% Define a clause for 'register cap topic': succeed when the following conditions hold.
ros_bridge_cap_topic(BodyId, imu)        :- assertz(ros_topic(BodyId, '/imu/data',            sensor_msgs_imu)).
% Define a clause for 'register cap topic': succeed when the following conditions hold.
ros_bridge_cap_topic(BodyId, odometry)   :- assertz(ros_topic(BodyId, '/odom',                nav_msgs_odometry)).
% Define a clause for 'register cap topic': succeed when the following conditions hold.
ros_bridge_cap_topic(BodyId, drive_base) :- assertz(ros_topic(BodyId, '/cmd_vel',             geometry_msgs_twist)).
% Define a clause for 'register cap topic': succeed when the following conditions hold.
ros_bridge_cap_topic(BodyId, arm)        :- assertz(ros_topic(BodyId, '/joint_states',        sensor_msgs_joint_state)).
% State a fact for 'register cap topic' with the arguments listed below.
ros_bridge_cap_topic(_, _).   % unknown capabilities silently ignored

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

% Define a clause for 'pai ros bridge': succeed when the following conditions hold.
pai_ros_bridge(message(BodyId, TopicName, Payload), Percept) :-
    % Execute: ( ros_topic(BodyId, TopicName, TopicType).
    ( ros_topic(BodyId, TopicName, TopicType)
    % If the condition above succeeded, perform the following action.
    ->  map_to_percept(TopicType, Payload, Signal)
    % Otherwise (else branch), perform the following action.
    ;   Signal = raw_percept(TopicName, Payload)
    % Close the expression opened above.
    ),
    % State a fact for 'next percept id' with the arguments listed below.
    next_percept_id(Pid),
    % Check that 'Percept' is unifiable with 'perception_signal(Pid, BodyId, Signal)'.
    Percept = perception_signal(Pid, BodyId, Signal),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(bridge_percept(BodyId, TopicName, Percept)).

% State the fact: map to percept(sensor_msgs_image,      Payload, visual_percept(image, Payload)).
map_to_percept(sensor_msgs_image,      Payload, visual_percept(image, Payload)).
% State the fact: map to percept(sensor_msgs_laser_scan, Payload, spatial_percept(lidar, Payload)).
map_to_percept(sensor_msgs_laser_scan, Payload, spatial_percept(lidar, Payload)).
% State the fact: map to percept(sensor_msgs_imu,        Payload, proprioceptive(imu, Payload)).
map_to_percept(sensor_msgs_imu,        Payload, proprioceptive(imu, Payload)).
% State the fact: map to percept(nav_msgs_odometry,      Payload, proprioceptive(odometry, Payload)).
map_to_percept(nav_msgs_odometry,      Payload, proprioceptive(odometry, Payload)).
% State the fact: map to percept(sensor_msgs_joint_state,Payload, proprioceptive(joint_state, Payload)).
map_to_percept(sensor_msgs_joint_state,Payload, proprioceptive(joint_state, Payload)).
% State the fact: map to percept(geometry_msgs_twist,    Payload, proprioceptive(velocity, Payload)).
map_to_percept(geometry_msgs_twist,    Payload, proprioceptive(velocity, Payload)).
% State the fact: map to percept(UnknownType,            Payload, raw_percept(UnknownType, Payload)).
map_to_percept(UnknownType,            Payload, raw_percept(UnknownType, Payload)).

% ---------------------------------------------------------------------------
% pai_robot_observe/1 — snapshot all pending percepts from enrolled robots
%
%   Returns a list of all perception_signal terms buffered since the last
%   observe call.  Clears the buffer so each percept is delivered once.
% ---------------------------------------------------------------------------

% Define a clause for 'pai robot observe': succeed when the following conditions hold.
pai_robot_observe(Percepts) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(P, bridge_percept(_, _, P), Percepts),
    % Remove all matching facts from the runtime knowledge base.
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

% Define a clause for 'pai robot act': succeed when the following conditions hold.
pai_robot_act(Action, Confirmation) :-
    % State a fact for 'action body' with the arguments listed below.
    action_body(Action, BodyId),
    % Execute: ( requires_real_world(Action).
    ( requires_real_world(Action)
    % If the condition above succeeded, perform the following action.
    ->  ( capability_level(real_world)
        % If the condition above succeeded, perform the following action.
        ->  gate_and_dispatch(BodyId, Action, Confirmation)
        % Otherwise (else branch), perform the following action.
        ;   Confirmation = denied(Action, simulation_only_capability)
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   gate_and_dispatch(BodyId, Action, Confirmation)
    % Close the expression opened above.
    ).

% State the fact: action body(drive(B, _, _),    B).
action_body(drive(B, _, _),    B).
% State the fact: action body(arm_move(B, _),    B).
action_body(arm_move(B, _),    B).
% State the fact: action body(navigate(B, _),    B).
action_body(navigate(B, _),    B).
% State the fact: action body(manipulate(B, _),  B).
action_body(manipulate(B, _),  B).
% State the fact: action body(stop(B),           B).
action_body(stop(B),           B).

% Define a clause for 'requires real world': succeed when the following conditions hold.
requires_real_world(drive(B, _, _))  :- robot_body(B, _, none).
% Define a clause for 'requires real world': succeed when the following conditions hold.
requires_real_world(arm_move(B, _)) :- robot_body(B, _, none).

% Define a clause for 'gate and dispatch': succeed when the following conditions hold.
gate_and_dispatch(BodyId, Action, Confirmation) :-
    % Execute: ( robot_body(BodyId, _, _).
    ( robot_body(BodyId, _, _)
    % If the condition above succeeded, perform the following action.
    ->  ( irreversible_action(Action)
        % If the condition above succeeded, perform the following action.
        ->  ( constitutional_gate(Action)
            % If the condition above succeeded, perform the following action.
            ->  dispatch_robot_action(Action, Result),
                % Continue the multi-line expression started above.
                next_action_id(AId),
                % Continue the multi-line expression started above.
                assertz(act_log(AId, Action, Result)),
                % Continue the multi-line expression started above.
                Confirmation = confirmed(AId, Action, Result)
            % Otherwise (else branch), perform the following action.
            ;   Confirmation = denied(Action, constitutional_veto)
            % Close the expression opened above.
            )
        % Otherwise (else branch), perform the following action.
        ;   dispatch_robot_action(Action, Result),
            % Continue the multi-line expression started above.
            next_action_id(AId),
            % Continue the multi-line expression started above.
            assertz(act_log(AId, Action, Result)),
            % Continue the multi-line expression started above.
            Confirmation = confirmed(AId, Action, Result)
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   Confirmation = denied(Action, body_not_enrolled)
    % Close the expression opened above.
    ).

% State the fact: irreversible action(drive(_, _, _)).
irreversible_action(drive(_, _, _)).
% State the fact: irreversible action(arm_move(_, _)).
irreversible_action(arm_move(_, _)).

% Define a clause for 'constitutional gate': succeed when the following conditions hold.
constitutional_gate(drive(_, V, W)) :-
    % Check that 'abs(V)' is less than or equal to '2.0, abs(W) =< 3.14.   % speed limits as a safety invariant'.
    abs(V) =< 2.0, abs(W) =< 3.14.   % speed limits as a safety invariant
% State the fact: constitutional gate(arm_move(_, _)).
constitutional_gate(arm_move(_, _)).
% State the fact: constitutional gate(navigate(_, _)).
constitutional_gate(navigate(_, _)).
% State the fact: constitutional gate(manipulate(_, _)).
constitutional_gate(manipulate(_, _)).
% State the fact: constitutional gate(stop(_)).
constitutional_gate(stop(_)).

% State the fact: dispatch robot action(drive(BodyId, V, W),       drove(BodyId, V, W)).
dispatch_robot_action(drive(BodyId, V, W),       drove(BodyId, V, W)).
% State the fact: dispatch robot action(arm_move(BodyId, Joints),  arm_moved(BodyId, Joints)).
dispatch_robot_action(arm_move(BodyId, Joints),  arm_moved(BodyId, Joints)).
% State the fact: dispatch robot action(navigate(BodyId, Goal),    navigating(BodyId, Goal)).
dispatch_robot_action(navigate(BodyId, Goal),    navigating(BodyId, Goal)).
% State the fact: dispatch robot action(manipulate(BodyId, Task),  manipulating(BodyId, Task)).
dispatch_robot_action(manipulate(BodyId, Task),  manipulating(BodyId, Task)).
% State the fact: dispatch robot action(stop(BodyId),              stopped(BodyId)).
dispatch_robot_action(stop(BodyId),              stopped(BodyId)).

% ---------------------------------------------------------------------------
% Helpers for tests and external callers
% ---------------------------------------------------------------------------

% Define a clause for 'simulation mode': succeed when the following conditions hold.
simulation_mode(BodyId, Sim) :-
    % State the fact: robot body(BodyId, _, Sim).
    robot_body(BodyId, _, Sim).
