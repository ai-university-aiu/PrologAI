% objchain.pl - Layer 169: Linear Chain Analysis for obj(Color, Cells) Sequences (ch_* prefix).
% Predicates for detecting, linearizing, traversing, and querying linear chains
% of obj(Color, Cells) terms that are connected through 4-adjacency touching.
% A chain is a sequence of objects where the touching graph is a simple path:
% exactly two objects have touch-degree 1 (endpoints), all others have degree 2.
% Distinct from objcomp (which handles arbitrary connected components).
:- module(object_chain, [
    object_chain_touches/2,
    object_chain_degree/3,
    object_chain_is_chain/1,
    object_chain_has_cycle/1,
    object_chain_endpoints/3,
    object_chain_linearize/2,
    object_chain_from_endpoint/3,
    object_chain_nth/3,
    object_chain_color_seq/2,
    object_chain_sub/4,
    object_chain_reverse/2,
    object_chain_length/2,
    object_chain_is_linear_path/1,
    object_chain_direction/2
]).
% member/2, nth0/3, append/3, reverse/2, min_list/2 from library(lists).
:- use_module(library(lists), [member/2, nth0/3, append/3, reverse/2, min_list/2]).

% object_chain_4adj_(+R, +C, -NR, -NC): enumerate four orthogonal neighbors of r(R,C).
object_chain_4adj_(R, C, NR, C)  :- NR is R - 1.
% Step downward by one row.
object_chain_4adj_(R, C, NR, C)  :- NR is R + 1.
% Step left by one column.
object_chain_4adj_(R, C, R,  NC) :- NC is C - 1.
% Step right by one column.
object_chain_4adj_(R, C, R,  NC) :- NC is C + 1.

% object_chain_touches(+Obj1, +Obj2): true if any cell of Obj1 is 4-adjacent to any cell
% of Obj2. Succeeds on the first found adjacent pair (cut for efficiency).
object_chain_touches(obj(_, Cells1), obj(_, Cells2)) :-
% Iterate all cell pairs across the two objects; cut on first success.
    member(r(R1,C1), Cells1),
    member(r(R2,C2), Cells2),
    (R1 =:= R2, D is abs(C1-C2), D =:= 1 ;
     C1 =:= C2, D is abs(R1-R2), D =:= 1), !.

% object_chain_degree(+Obj, +Objs, -N): N is the number of objects in Objs (excluding Obj)
% that 4-touch Obj. The touch-degree of Obj within the chain universe Objs.
object_chain_degree(Obj, Objs, N) :-
% Collect all objects in Objs (other than Obj itself) that touch Obj.
    findall(Other, (member(Other, Objs), Other \== Obj, object_chain_touches(Obj, Other)), Others),
% The degree is the count of touching neighbors.
    length(Others, N).

% object_chain_is_chain(+Objs): true when the objects in Objs form a simple linear path
% in the touching graph. Empty and singleton lists are trivially chains.
% Two objects form a chain iff they touch. Three or more objects form a chain
% iff exactly two have degree 1 (endpoints) and all others have degree 2.
object_chain_is_chain([]) :- !.
% A single object is always a (trivial) chain.
object_chain_is_chain([_]) :- !.
% Two objects form a chain iff they touch each other.
object_chain_is_chain([O1,O2]) :- !, object_chain_touches(O1, O2).
% Three or more objects: check path structure via degree constraints.
object_chain_is_chain(Objs) :-
% Compute the touch-degree of every object in Objs.
    findall(D, (member(O, Objs), object_chain_degree(O, Objs, D)), Degs),
% A valid chain has no object with degree > 2 (no branching nodes).
    \+ (member(D, Degs), D > 2),
% A valid chain has no object with degree 0 (all objects are connected).
    \+ member(0, Degs),
% A valid chain has exactly two endpoints (objects with degree 1).
    findall(x, member(1, Degs), Ones),
    length(Ones, 2).

% object_chain_has_cycle(+Objs): true when Objs forms a closed cycle in the touching graph.
% A cycle requires at least 3 objects and every object must have degree 2.
object_chain_has_cycle(Objs) :-
% Cycles require at least 3 objects to be non-degenerate.
    length(Objs, N), N >= 3,
% In a cycle every object has exactly two touching neighbors.
    findall(D, (member(O, Objs), object_chain_degree(O, Objs, D)), Degs),
% Fail if any object has a degree other than 2 (=\= is arithmetic not-equal).
    \+ (member(D, Degs), D =\= 2).

% object_chain_endpoints(+Objs, -E1, -E2): E1 and E2 are the two degree-1 objects in
% the chain Objs. Objs must form a valid chain (object_chain_is_chain/1 must hold).
object_chain_endpoints(Objs, E1, E2) :-
% Collect objects with exactly one touching neighbor (the two endpoints).
    findall(O, (member(O, Objs), object_chain_degree(O, Objs, 1)), [E1,E2]).

% object_chain_walk_(+Current, +Objs, +Visited, -Path): DFS walk along the chain.
% Extends the path from Current, following the unique unvisited touching neighbor.
% Stops when no unvisited touching neighbor exists (at the other endpoint).
object_chain_walk_(Current, Objs, Visited, [Current|Rest]) :-
% Find all unvisited touching neighbors of Current within Objs.
    findall(N,
            (member(N, Objs), N \== Current, \+ memberchk(N, Visited), object_chain_touches(Current, N)),
            Neighbors),
% Dispatch to next step or terminal case depending on neighbor count.
    object_chain_next_(Neighbors, Current, Objs, Visited, Rest).

% object_chain_next_(+Neighbors, +Current, +Objs, +Visited, -Rest): handle BFS step.
% If no neighbors remain, the walk ends (current is the last object).
object_chain_next_([], _, _, _, []) :- !.
% If exactly one unvisited neighbor, continue walking from it.
object_chain_next_([Next|[]], Current, Objs, Visited, Rest) :-
    object_chain_walk_(Next, Objs, [Current|Visited], Rest).

% object_chain_linearize(+Objs, -Ordered): put the chain objects in linear order from
% one endpoint to the other. Objs must form a valid chain.
object_chain_linearize(Objs, Ordered) :-
% Find the two endpoints; start linearization from E1.
    object_chain_endpoints(Objs, E1, _),
    object_chain_walk_(E1, Objs, [], Ordered).

% object_chain_from_endpoint(+Objs, +Start, -Ordered): put chain objects in linear order
% beginning from Start. Start should be an endpoint for a full traversal.
object_chain_from_endpoint(Objs, Start, Ordered) :-
% Verify Start is a member of Objs before beginning the walk.
    memberchk(Start, Objs),
    object_chain_walk_(Start, Objs, [], Ordered).

% object_chain_nth(+Ordered, +N, -Obj): Obj is the Nth element (0-based) of the ordered chain.
object_chain_nth(Ordered, N, Obj) :-
% Delegate to nth0/3 for 0-based indexing.
    nth0(N, Ordered, Obj).

% object_chain_color_seq(+Ordered, -Colors): Colors is the list of colors of each object
% in the ordered chain, preserving the chain order.
object_chain_color_seq(Ordered, Colors) :-
% Extract the first argument (color) from every obj(Color, Cells) term.
    findall(C, member(obj(C,_), Ordered), Colors).

% object_chain_sub(+Ordered, +I, +J, -Sub): Sub is the sub-chain from index I to J
% (0-based, inclusive on both ends). Fails if indices are out of range.
object_chain_sub(Ordered, I, J, Sub) :-
% Skip the first I objects to reach the start of the sub-chain.
    length(Prefix, I),
    append(Prefix, Suffix, Ordered),
% Take exactly J-I+1 objects starting from the sub-chain start.
    Len is J - I + 1,
    length(Sub, Len),
    append(Sub, _, Suffix).

% object_chain_reverse(+Ordered, -Rev): Rev is Ordered traversed in reverse order.
object_chain_reverse(Ordered, Rev) :-
% Delegate to reverse/2 for list reversal.
    reverse(Ordered, Rev).

% object_chain_length(+Objs, -N): N is the number of objects in the chain.
object_chain_length(Objs, N) :-
% Delegate to length/2 for list length.
    length(Objs, N).

% object_chain_is_linear_path(+Ordered): true when each consecutive pair of objects in
% Ordered touches. Verifies a GIVEN ordered sequence is a valid chain path.
% Distinct from object_chain_is_chain/1 which checks an UNORDERED set.
object_chain_is_linear_path([]) :- !.
% A single-object path is trivially valid.
object_chain_is_linear_path([_]) :- !.
% Two or more objects: head must touch its successor; recurse.
object_chain_is_linear_path([O1, O2|Rest]) :-
% Require O1 and O2 to be 4-adjacent.
    object_chain_touches(O1, O2),
    object_chain_is_linear_path([O2|Rest]).

% object_chain_min_row_(+obj(_, Cells), -MinR): minimum row index among the cells of Obj.
object_chain_min_row_(obj(_, Cells), MinR) :-
    findall(R, member(r(R,_), Cells), Rs), min_list(Rs, MinR).

% object_chain_min_col_(+obj(_, Cells), -MinC): minimum column index among the cells of Obj.
object_chain_min_col_(obj(_, Cells), MinC) :-
    findall(C, member(r(_,C), Cells), Cs), min_list(Cs, MinC).

% object_chain_direction(+Ordered, -Dir): Dir is h (horizontal), v (vertical), or other.
% h: all objects have the same minimum row (aligned along a row).
% v: all objects have the same minimum column (aligned along a column).
% other: neither all same row nor all same column.
object_chain_direction(Ordered, h) :-
% Collect the minimum row of every object in the chain.
    findall(MinR, (member(O, Ordered), object_chain_min_row_(O, MinR)), AllRs),
% Unify the first row value; verify every other entry equals it.
    AllRs = [R0|_],
    forall(member(R, AllRs), R =:= R0), !.
% If horizontal fails, try vertical.
object_chain_direction(Ordered, v) :-
% Collect the minimum column of every object in the chain.
    findall(MinC, (member(O, Ordered), object_chain_min_col_(O, MinC)), AllCs),
% Unify the first column value; verify every other entry equals it.
    AllCs = [C0|_],
    forall(member(C, AllCs), C =:= C0), !.
% If neither horizontal nor vertical, the direction is other (e.g., L-shape).
object_chain_direction(_, other).
