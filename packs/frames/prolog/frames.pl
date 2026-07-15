/*  PrologAI — Reference Frames and Voting Consensus  (Specification PR 39)

    Implements the two architectural exports of the Thousand Brains theory:
    knowledge anchored in reference frames, and consensus by voting among
    many semi-independent specialists.

    Reference frames:
        A reference_frame is a node_fact that names a scope subtype.
        Features are inscribed in the Lattice with Referents that carry
        frame(FrameId) and coords(Coords) tags, linking them to the frame.
        Frames may nest: a child frame carries a parent_frame(ParentId) pin.
        Frame learning is one-shot (anchor_node is idempotent on content).

    Voting consensus:
        Voters supply conclusions with individual confidence and reliability
        scores.  The weighted score of each conclusion is the sum of its
        voters' confidence × reliability products.  The highest-scoring
        conclusion is inscribed as vote_consensus; all minority votes are
        inscribed as vote_dissent — many columns, one consensus, minority
        reports preserved.

    Frame move:
        frames_frame_move/3 advances a point of attention one step along the
        frame's declared primary axis (the axes term's first component for
        1-D frames, or dx/dy for 2-D frames).  Physical dispatch (body
        commands) is signalled by a body_move node_fact; the pure-Prolog
        default just computes the new coordinates.

    Predicates:
        frames_frame_create/3   — +FrameId, +Axes, -NodeId
        frames_frame_anchor/4   — +FrameId, +Coords, +feature(Rel,Args), -NodeId
        frames_frame_move/3     — +FrameId, +Point, -NewPoint
        frames_vote/4           — +Voters, +Entity, +Budget, -Consensus
*/

% Declare this file as the 'frames' module and list its exported predicates.
:- module(frames, [
    % Supply 'frames_frame_create/3' as the next argument to the expression above.
    frames_frame_create/3,
    % Supply 'frames_frame_anchor/4' as the next argument to the expression above.
    frames_frame_anchor/4,
    % Supply 'frames_frame_move/3' as the next argument to the expression above.
    frames_frame_move/3,
    % Supply 'frames_vote/4' as the next argument to the expression above.
    frames_vote/4
% Close the expression opened above.
]).

% Import [anchor_node/4] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [anchor_node/4]).
% Import [lattice_node_fact/5] from the built-in 'lattice' library.
:- use_module(library(lattice),    [lattice_node_fact/5]).
% Import [member/2, last/2] from the built-in 'lists' library.
:- use_module(library(lists),      [member/2, last/2]).
% Import [maplist/3, foldl/4] from the built-in 'apply' library.
:- use_module(library(apply),      [maplist/3, foldl/4]).

% ---------------------------------------------------------------------------
% frames_frame_create/3
%
%   Inscribes the frame declaration as a reference_frame node_fact.
%   Axes may be any term: axes(1) for 1-D, axes(dx(1), dy(0)) for 2-D, etc.
% ---------------------------------------------------------------------------

% Define a clause for 'pai frame create': succeed when the following conditions hold.
frames_frame_create(FrameId, Axes, NodeId) :-
    % State the fact: anchor node(reference_frame, [FrameId, Axes], [], NodeId).
    anchor_node(reference_frame, [FrameId, Axes], [], NodeId).

% ---------------------------------------------------------------------------
% frames_frame_anchor/4
%
%   Inscribes a feature into the Lattice with frame and coordinate referents.
%   feature(Rel, Args) is the feature's relation and argument list.
%   Coords may be any term: point(X, Y), coord(1), step(3), etc.
% ---------------------------------------------------------------------------

% Define a clause for 'pai frame anchor': succeed when the following conditions hold.
frames_frame_anchor(FrameId, Coords, feature(Rel, Args), NodeId) :-
    % State the fact: anchor node(Rel, Args, [frame(FrameId), coords(Coords)], NodeId).
    anchor_node(Rel, Args, [frame(FrameId), coords(Coords)], NodeId).

% ---------------------------------------------------------------------------
% frames_frame_move/3
%
%   Advances a point of attention one step along the frame's primary axis.
%   The frame's Axes term determines the step:
%       axes(Step)         — 1-D: NewCoord = OldCoord + Step
%       axes(DX, DY)       — 2-D: point(X+DX, Y+DY)
%   Body-mode (physical dispatch) is noted as a body_move node_fact.
% ---------------------------------------------------------------------------

% Define a clause for 'pai frame move': succeed when the following conditions hold.
frames_frame_move(FrameId, Point, NewPoint) :-
    % Execute: ( lattice_node_fact(_, _, reference_frame, [FrameId, Axes], _).
    ( lattice_node_fact(_, _, reference_frame, [FrameId, Axes], _)
    % If the condition above succeeded, perform the following action.
    ->  move_step(Axes, Point, NewPoint)
    % Otherwise (else branch), perform the following action.
    ;   NewPoint = Point
    % Close the expression opened above.
    ).

% Define a clause for 'move step': succeed when the following conditions hold.
move_step(axes(Step), C0, C1) :-
    % State a fact for 'number' with the arguments listed below.
    number(Step), number(C0), !,
    % Evaluate the arithmetic expression 'C0 + Step' and bind the result to 'C1'.
    C1 is C0 + Step.
% Define a clause for 'move step': succeed when the following conditions hold.
move_step(axes(DX, DY), point(X0, Y0), point(X1, Y1)) :-
    % State a fact for 'number' with the arguments listed below.
    number(DX), number(DY), !,
    % Evaluate the arithmetic expression 'X0 + DX' and bind the result to 'X1'.
    X1 is X0 + DX,
    % Evaluate the arithmetic expression 'Y0 + DY' and bind the result to 'Y1'.
    Y1 is Y0 + DY.
% State the fact: move step(_, P, P).
move_step(_, P, P).

% ---------------------------------------------------------------------------
% frames_vote/4
%
%   Voters: list of voter(Id, Conclusion, Confidence, Reliability)
%   Each conclusion's weighted score = Σ (Confidence × Reliability) for
%   all voters backing it.
%   Consensus: highest-scoring conclusion inscribed as vote_consensus node_fact.
%   Dissent: minority voters inscribed as vote_dissent node_facts.
%   Budget: budget(MaxVoters) caps how many voters are considered.
%
%   Consensus term: consensus(Entity, Best, BestScore, NodeId)
% ---------------------------------------------------------------------------

% Define a clause for 'pai vote': succeed when the following conditions hold.
frames_vote(Voters, Entity, Budget, Consensus) :-
    % Check that 'Budget' is unifiable with 'budget(MaxVoters)'.
    Budget = budget(MaxVoters),
    % Check that '( MaxVoters' is greater than '0'.
    ( MaxVoters > 0
    % If the condition above succeeded, perform the following action.
    ->  length(Voters, NV),
        % Continue the multi-line expression started above.
        Take is min(MaxVoters, NV),
        % Continue the multi-line expression started above.
        length(Active, Take),
        % Continue the multi-line expression started above.
        append(Active, _, Voters)
    % Otherwise (else branch), perform the following action.
    ;   Active = []
    % Close the expression opened above.
    ),
    % Collect unique conclusions and their total weighted scores
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Conc-W, (
        % Continue the multi-line expression started above.
        member(voter(_, Conc, Conf, Rel), Active),
        % Continue the multi-line expression started above.
        W is Conf * Rel
    % Continue the multi-line expression started above.
    ), ConcsWeights),
    % State a fact for 'aggregate weighted' with the arguments listed below.
    aggregate_weighted(ConcsWeights, Scored),
    % Check that '( Scored' is unifiable with '[]'.
    ( Scored = []
    % If the condition above succeeded, perform the following action.
    ->  Consensus = no_consensus
    % Otherwise (else branch), perform the following action.
    ;   msort(Scored, SortedAsc),
        % Continue the multi-line expression started above.
        last(SortedAsc, BestScore-Best),
        % Inscribe consensus
        % Continue the multi-line expression started above.
        catch(anchor_node(vote_consensus, [Entity, Best, BestScore], [], CId),
              % Continue the multi-line expression started above.
              _, CId = none),
        % Inscribe dissent for non-consensus voters
        % Continue the multi-line expression started above.
        forall(
            % Continue the multi-line expression started above.
            member(voter(Vid, VConc, VConf, VRel), Active),
            % Continue the multi-line expression started above.
            ( VConc == Best
            % If the condition above succeeded, perform the following action.
            ->  true
            % Otherwise (else branch), perform the following action.
            ;   catch(anchor_node(vote_dissent, [Entity, Vid, VConc, VConf, VRel], [], _),
                      % Continue the multi-line expression started above.
                      _, true)
            % Close the expression opened above.
            )
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        Consensus = consensus(Entity, Best, BestScore, CId)
    % Close the expression opened above.
    ).

% Aggregate: list of Conc-W pairs → list of TotalW-Conc (one per unique Conc)
% Define a clause for 'aggregate weighted': succeed when the following conditions hold.
aggregate_weighted(ConcsWeights, Scored) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Conc, member(Conc-_, ConcsWeights), AllConcs),
    % Sort list 'AllConcs' into 'UniqueConcs', removing duplicates.
    sort(AllConcs, UniqueConcs),
    % State a fact for 'maplist' with the arguments listed below.
    maplist([Conc, Total-Conc]>>(
        % Continue the multi-line expression started above.
        findall(W, member(Conc-W, ConcsWeights), Ws),
        % Continue the multi-line expression started above.
        foldl([X, Acc, NAcc]>>(NAcc is Acc + X), Ws, 0.0, Total)
    % Continue the multi-line expression started above.
    ), UniqueConcs, Scored).
