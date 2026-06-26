% seqinfer.pl - Layer 195: Sequential Rule Inference for Multi-Step Scene Transformations
%               (sq_* prefix).
% Finds ordered rule sequences (Rule1, Rule2, ...) that, when applied in order, transform
% every Before scene into its corresponding After scene across all training pairs.
% Extends single-rule solvers (gridsolve) to handle transformations that require two or
% three successive steps. The dispatch engine is self-contained: no cross-pack imports.
% Pairs are Before-After terms where each side is a list of obj(Color, Cells).
:- module(seqinfer, [
    % sq_apply/3: apply a list of rules in sequence to a scene.
    sq_apply/3,
    % sq_verify/3: succeed if applying Rules to Before produces After (msort equality).
    sq_verify/3,
    % sq_consistent/2: Rules correctly transform every pair in the list.
    sq_consistent/2,
    % sq_coverage/3: count of pairs correctly transformed by Rules.
    sq_coverage/3,
    % sq_rank_seqs/3: sort a list of rule sequences by coverage descending.
    sq_rank_seqs/3,
    % sq_all_consistent/3: rule sequences from Seqs that fully explain all Pairs.
    sq_all_consistent/3,
    % sq_infer_2step/3: find the best 2-step rule sequence from Candidates.
    sq_infer_2step/3,
    % sq_infer_3step/3: find the best 3-step rule sequence from Candidates.
    sq_infer_3step/3,
    % sq_default_rules/1: standard single-step rule candidates.
    sq_default_rules/1,
    % sq_solve/3: infer the best single or two-step rule from default candidates.
    sq_solve/3,
    % sq_coverage_ratio/3: coverage as Num/Den (integer fraction).
    sq_coverage_ratio/3,
    % sq_n_pairs/2: number of pairs in the list.
    sq_n_pairs/2,
    % sq_explain/3: return BestSeq and its coverage count for a pair list.
    sq_explain/3,
    % sq_verify_all/2: succeed if Rules correctly transform every pair.
    sq_verify_all/2
]).

% Import list utilities.
:- use_module(library(lists), [member/2, last/2, subtract/3, nth1/3]).
% Import apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% sq_apply(+Rules, +Scene, -Result)
% Apply a list of transformation rules in order to Scene, producing Result.
% Rules is a list of rule terms (see sq_apply_one_/3 for handled forms).
sq_apply([], Scene, Scene).
sq_apply([Rule|Rest], Scene, Result) :-
% Apply the first rule to get an intermediate scene.
    sq_apply_one_(Rule, Scene, Intermediate),
% Recurse on remaining rules with the intermediate scene.
    sq_apply(Rest, Intermediate, Result).

% sq_apply_one_(+Rule, +Scene, -Result): dispatch for a single rule term.
% identity: return Scene unchanged.
sq_apply_one_(identity, Scene, Scene).
% recolor(C1, C2): change all objects of color C1 to color C2.
sq_apply_one_(recolor(C1, C2), Scene, Result) :-
    maplist(sq_recolor_obj_(C1, C2), Scene, Result).
% recolor_all(C): change every object to color C.
sq_apply_one_(recolor_all(C), Scene, Result) :-
    maplist([obj(_, Cells), obj(C, Cells)]>>true, Scene, Result).
% shift(DR, DC): translate every object by (DR, DC).
sq_apply_one_(shift(DR, DC), Scene, Result) :-
    maplist(sq_shift_obj_(DR, DC), Scene, Result).
% to_origin: translate every object so its top-left cell is at r(0,0).
sq_apply_one_(to_origin, Scene, Result) :-
    maplist(sq_to_origin_obj_, Scene, Result).
% reflect_h: reflect every object horizontally about its own horizontal axis.
sq_apply_one_(reflect_h, Scene, Result) :-
    maplist(sq_reflect_h_, Scene, Result).
% reflect_v: reflect every object vertically about its own vertical axis.
sq_apply_one_(reflect_v, Scene, Result) :-
    maplist(sq_reflect_v_, Scene, Result).
% remove_color(C): remove all objects of color C from the scene.
sq_apply_one_(remove_color(C), Scene, Result) :-
    include(sq_not_color_(C), Scene, Result).
% keep_color(C): retain only objects of color C.
sq_apply_one_(keep_color(C), Scene, Result) :-
    include(sq_is_color_(C), Scene, Result).
% sort_size_desc: sort objects from largest to smallest by cell count.
sq_apply_one_(sort_size_desc, Scene, Result) :-
    findall(NegN-Obj, (member(Obj, Scene), Obj=obj(_,Cells), length(Cells,N), NegN is -N), Keyed),
    msort(Keyed, Sorted),
    maplist([_-O, O]>>true, Sorted, Result).
% sort_size_asc: sort objects from smallest to largest by cell count.
sq_apply_one_(sort_size_asc, Scene, Result) :-
    findall(N-Obj, (member(Obj, Scene), Obj=obj(_,Cells), length(Cells,N)), Keyed),
    msort(Keyed, Sorted),
    maplist([_-O, O]>>true, Sorted, Result).
% top_n(N): keep only the N largest objects.
sq_apply_one_(top_n(N), Scene, Result) :-
    sq_apply_one_(sort_size_desc, Scene, Sorted),
    sq_take_(Sorted, N, Result).
% color_map(Map): apply a color substitution map (list of C1-C2 pairs).
sq_apply_one_(color_map(Map), Scene, Result) :-
    maplist(sq_apply_color_map_(Map), Scene, Result).

% sq_recolor_obj_(+C1, +C2, +Obj, -Out): change color C1 to C2 in one object.
sq_recolor_obj_(C1, C2, obj(C, Cells), Out) :-
% If the object has the target color, change it; otherwise leave unchanged.
    (C == C1 -> Out = obj(C2, Cells) ; Out = obj(C, Cells)).

% sq_shift_obj_(+DR, +DC, +Obj, -Out): translate Obj's cells by (DR, DC).
sq_shift_obj_(DR, DC, obj(Color, Cells), obj(Color, Shifted)) :-
    maplist([r(R,C), r(R2,C2)]>>(R2 is R+DR, C2 is C+DC), Cells, Shifted).

% sq_to_origin_obj_(+Obj, -Out): translate so minimum row and column are both 0.
sq_to_origin_obj_(obj(Color, Cells), obj(Color, Moved)) :-
    findall(R, member(r(R,_), Cells), Rs), min_list(Rs, MinR),
    findall(C, member(r(_,C), Cells), Cs), min_list(Cs, MinC),
    maplist([r(R,C), r(R2,C2)]>>(R2 is R-MinR, C2 is C-MinC), Cells, Moved).

% sq_reflect_h_(+Obj, -Out): reflect cells within the object's bounding box horizontally.
sq_reflect_h_(obj(Color, Cells), obj(Color, Reflected)) :-
    findall(R, member(r(R,_), Cells), Rs), max_list(Rs, MaxR), min_list(Rs, MinR),
    maplist([r(R,C), r(R2,C)]>>(R2 is MinR + MaxR - R), Cells, Reflected).

% sq_reflect_v_(+Obj, -Out): reflect cells within the object's bounding box vertically.
sq_reflect_v_(obj(Color, Cells), obj(Color, Reflected)) :-
    findall(C, member(r(_,C), Cells), Cs), max_list(Cs, MaxC), min_list(Cs, MinC),
    maplist([r(R,C), r(R,C2)]>>(C2 is MinC + MaxC - C), Cells, Reflected).

% sq_not_color_(+C, +Obj): succeed if Obj does NOT have color C.
sq_not_color_(C, obj(ObjC, _)) :- ObjC \== C.

% sq_is_color_(+C, +Obj): succeed if Obj has color C.
sq_is_color_(C, obj(ObjC, _)) :- ObjC == C.

% sq_take_(+List, +N, -First): take the first N elements of List.
sq_take_(_, 0, []) :- !.
sq_take_([], _, []).
sq_take_([H|T], N, [H|Rest]) :- N > 0, N1 is N-1, sq_take_(T, N1, Rest).

% sq_apply_color_map_(+Map, +Obj, -Out): apply first matching C1-C2 entry in Map.
sq_apply_color_map_(Map, obj(C, Cells), obj(C2, Cells)) :-
    (member(C-C2, Map) -> true ; C2 = C).

% min_list/2 and max_list/2 are from library(lists) (imported above via subtract's header).
:- use_module(library(lists), [min_list/2, max_list/2]).

% sq_verify(+Rules, +Before, +After)
% Succeed if applying Rules to Before produces After (comparing msorted cell lists).
sq_verify(Rules, Before, After) :-
    sq_apply(Rules, Before, Result),
    msort(Result, SortedResult),
    msort(After, SortedAfter),
    SortedResult == SortedAfter.

% sq_consistent(+Rules, +Pairs)
% Succeed if Rules correctly transforms every Before-After pair.
sq_consistent(Rules, Pairs) :-
    maplist(sq_verify_pair_(Rules), Pairs).

% sq_verify_pair_(+Rules, +Pair): verify one Before-After pair.
sq_verify_pair_(Rules, Before-After) :-
    sq_verify(Rules, Before, After).

% sq_coverage(+Rules, +Pairs, -N)
% N is the count of pairs for which Rules correctly transforms Before to After.
sq_coverage(Rules, Pairs, N) :-
    include(sq_verify_pair_(Rules), Pairs, Covered),
    length(Covered, N).

% sq_rank_seqs(+Seqs, +Pairs, -Ranked)
% Ranked is Seqs sorted by coverage descending (highest coverage first).
% Seqs is a list of rule sequences (each a list of rule terms).
sq_rank_seqs(Seqs, Pairs, Ranked) :-
    findall(NegCov-Seq,
        (member(Seq, Seqs), sq_coverage(Seq, Pairs, Cov), NegCov is -Cov),
        Keyed),
    msort(Keyed, Sorted),
    maplist([_-S, S]>>true, Sorted, Ranked).

% sq_all_consistent(+Seqs, +Pairs, -Consistent)
% Consistent is the sub-list of Seqs that fully explains all Pairs.
sq_all_consistent(Seqs, Pairs, Consistent) :-
    include(sq_consistent_seq_(Pairs), Seqs, Consistent).

% sq_consistent_seq_(+Pairs, +Seq): succeed if Seq is consistent with all Pairs.
sq_consistent_seq_(Pairs, Seq) :-
    sq_consistent(Seq, Pairs).

% sq_infer_2step(+Candidates, +Pairs, -BestSeq)
% BestSeq is the 2-element rule sequence [R1, R2] with the highest coverage on Pairs.
% Candidates is a list of single-step rule terms.
% Fails if Candidates is empty or no candidate pair has positive coverage.
sq_infer_2step(Candidates, Pairs, BestSeq) :-
    findall(Cov-[R1,R2],
        (member(R1, Candidates), member(R2, Candidates),
         sq_coverage([R1,R2], Pairs, Cov), Cov > 0),
        All),
    All \= [],
    msort(All, Sorted),
    last(Sorted, _-BestSeq).

% sq_infer_3step(+Candidates, +Pairs, -BestSeq)
% BestSeq is the 3-element rule sequence [R1, R2, R3] with the highest coverage.
sq_infer_3step(Candidates, Pairs, BestSeq) :-
    findall(Cov-[R1,R2,R3],
        (member(R1, Candidates), member(R2, Candidates), member(R3, Candidates),
         sq_coverage([R1,R2,R3], Pairs, Cov), Cov > 0),
        All),
    All \= [],
    msort(All, Sorted),
    last(Sorted, _-BestSeq).

% sq_default_rules(-Rules)
% Standard single-step rule candidates covering common transformations.
sq_default_rules([
    identity,
    recolor(r, b), recolor(r, g), recolor(r, y),
    recolor(b, r), recolor(b, g), recolor(b, y),
    recolor(g, r), recolor(g, b), recolor(g, y),
    recolor_all(r), recolor_all(b), recolor_all(g),
    shift(0, 1), shift(0, -1), shift(1, 0), shift(-1, 0),
    shift(1, 1), shift(1, -1), shift(-1, 1), shift(-1, -1),
    to_origin,
    reflect_h, reflect_v,
    remove_color(r), remove_color(b), remove_color(g),
    keep_color(r), keep_color(b), keep_color(g),
    sort_size_desc, sort_size_asc
]).

% sq_solve(+Pairs, +Candidates, -BestSeq)
% Find the best rule sequence (1-step or 2-step) from Candidates that explains Pairs.
% Tries 1-step first; if no single rule has full coverage, tries 2-step.
sq_solve(Pairs, Candidates, BestSeq) :-
    (   sq_infer_2step(Candidates, Pairs, Best2),
        sq_coverage(Best2, Pairs, Cov2),
        length(Pairs, Total),
        Cov2 =:= Total
    ->  BestSeq = Best2
    ;   findall(Cov-[R],
            (member(R, Candidates), sq_coverage([R], Pairs, Cov), Cov > 0),
            Single),
        Single \= [],
        msort(Single, Sorted),
        last(Sorted, _-BestSeq)
    ).

% sq_coverage_ratio(+Rules, +Pairs, -Num/Den)
% Coverage as an integer fraction Num/Den.
sq_coverage_ratio(Rules, Pairs, Num/Den) :-
    sq_coverage(Rules, Pairs, Num),
    length(Pairs, Den).

% sq_n_pairs(+Pairs, -N): number of pairs in the list.
sq_n_pairs(Pairs, N) :- length(Pairs, N).

% sq_explain(+Rules, +Pairs, -Coverage)
% Coverage is the number of pairs correctly explained by Rules.
sq_explain(Rules, Pairs, Coverage) :-
    sq_coverage(Rules, Pairs, Coverage).

% sq_verify_all(+Rules, +Pairs): succeed if Rules transforms every pair correctly.
sq_verify_all(Rules, Pairs) :-
    sq_consistent(Rules, Pairs).
