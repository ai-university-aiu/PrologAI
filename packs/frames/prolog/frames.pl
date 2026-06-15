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
        pai_frame_move/3 advances a point of attention one step along the
        frame's declared primary axis (the axes term's first component for
        1-D frames, or dx/dy for 2-D frames).  Physical dispatch (body
        commands) is signalled by a body_move node_fact; the pure-Prolog
        default just computes the new coordinates.

    Predicates:
        pai_frame_create/3   — +FrameId, +Axes, -NodeId
        pai_frame_anchor/4   — +FrameId, +Coords, +feature(Rel,Args), -NodeId
        pai_frame_move/3     — +FrameId, +Point, -NewPoint
        pai_vote/4           — +Voters, +Entity, +Budget, -Consensus
*/

:- module(frames, [
    pai_frame_create/3,
    pai_frame_anchor/4,
    pai_frame_move/3,
    pai_vote/4
]).

:- use_module(library(node_facts), [anchor_node/4]).
:- use_module(library(lattice),    [lattice_node_fact/5]).
:- use_module(library(lists),      [member/2, last/2]).
:- use_module(library(apply),      [maplist/3, foldl/4]).

% ---------------------------------------------------------------------------
% pai_frame_create/3
%
%   Inscribes the frame declaration as a reference_frame node_fact.
%   Axes may be any term: axes(1) for 1-D, axes(dx(1), dy(0)) for 2-D, etc.
% ---------------------------------------------------------------------------

pai_frame_create(FrameId, Axes, NodeId) :-
    anchor_node(reference_frame, [FrameId, Axes], [], NodeId).

% ---------------------------------------------------------------------------
% pai_frame_anchor/4
%
%   Inscribes a feature into the Lattice with frame and coordinate referents.
%   feature(Rel, Args) is the feature's relation and argument list.
%   Coords may be any term: point(X, Y), coord(1), step(3), etc.
% ---------------------------------------------------------------------------

pai_frame_anchor(FrameId, Coords, feature(Rel, Args), NodeId) :-
    anchor_node(Rel, Args, [frame(FrameId), coords(Coords)], NodeId).

% ---------------------------------------------------------------------------
% pai_frame_move/3
%
%   Advances a point of attention one step along the frame's primary axis.
%   The frame's Axes term determines the step:
%       axes(Step)         — 1-D: NewCoord = OldCoord + Step
%       axes(DX, DY)       — 2-D: point(X+DX, Y+DY)
%   Body-mode (physical dispatch) is noted as a body_move node_fact.
% ---------------------------------------------------------------------------

pai_frame_move(FrameId, Point, NewPoint) :-
    ( lattice_node_fact(_, _, reference_frame, [FrameId, Axes], _)
    ->  move_step(Axes, Point, NewPoint)
    ;   NewPoint = Point
    ).

move_step(axes(Step), C0, C1) :-
    number(Step), number(C0), !,
    C1 is C0 + Step.
move_step(axes(DX, DY), point(X0, Y0), point(X1, Y1)) :-
    number(DX), number(DY), !,
    X1 is X0 + DX,
    Y1 is Y0 + DY.
move_step(_, P, P).

% ---------------------------------------------------------------------------
% pai_vote/4
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

pai_vote(Voters, Entity, Budget, Consensus) :-
    Budget = budget(MaxVoters),
    ( MaxVoters > 0
    ->  length(Voters, NV),
        Take is min(MaxVoters, NV),
        length(Active, Take),
        append(Active, _, Voters)
    ;   Active = []
    ),
    % Collect unique conclusions and their total weighted scores
    findall(Conc-W, (
        member(voter(_, Conc, Conf, Rel), Active),
        W is Conf * Rel
    ), ConcsWeights),
    aggregate_weighted(ConcsWeights, Scored),
    ( Scored = []
    ->  Consensus = no_consensus
    ;   msort(Scored, SortedAsc),
        last(SortedAsc, BestScore-Best),
        % Inscribe consensus
        catch(anchor_node(vote_consensus, [Entity, Best, BestScore], [], CId),
              _, CId = none),
        % Inscribe dissent for non-consensus voters
        forall(
            member(voter(Vid, VConc, VConf, VRel), Active),
            ( VConc == Best
            ->  true
            ;   catch(anchor_node(vote_dissent, [Entity, Vid, VConc, VConf, VRel], [], _),
                      _, true)
            )
        ),
        Consensus = consensus(Entity, Best, BestScore, CId)
    ).

% Aggregate: list of Conc-W pairs → list of TotalW-Conc (one per unique Conc)
aggregate_weighted(ConcsWeights, Scored) :-
    findall(Conc, member(Conc-_, ConcsWeights), AllConcs),
    sort(AllConcs, UniqueConcs),
    maplist([Conc, Total-Conc]>>(
        findall(W, member(Conc-W, ConcsWeights), Ws),
        foldl([X, Acc, NAcc]>>(NAcc is Acc + X), Ws, 0.0, Total)
    ), UniqueConcs, Scored).
