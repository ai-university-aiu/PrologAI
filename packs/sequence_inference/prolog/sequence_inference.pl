% seqinfer.pl - Layer 195: Sequential Rule Inference for Multi-Step Scene Transformations
%               (sq_* prefix).
% Finds ordered rule sequences (Rule1, Rule2, ...) that, when applied in order, transform
% every Before scene into its corresponding After scene across all training pairs.
% Extends single-rule solvers (gridsolve) to handle transformations that require two or
% three successive steps. The dispatch engine is self-contained: no cross-pack imports.
% Pairs are Before-After terms where each side is a list of obj(Color, Cells).
:- module(sequence_inference, [
    % sequence_inference_apply/3: apply a list of rules in sequence to a scene.
    sequence_inference_apply/3,
    % sequence_inference_verify/3: succeed if applying Rules to Before produces After (msort equality).
    sequence_inference_verify/3,
    % sequence_inference_consistent/2: Rules correctly transform every pair in the list.
    sequence_inference_consistent/2,
    % sequence_inference_coverage/3: count of pairs correctly transformed by Rules.
    sequence_inference_coverage/3,
    % sequence_inference_rank_seqs/3: sort a list of rule sequences by coverage descending.
    sequence_inference_rank_seqs/3,
    % sequence_inference_all_consistent/3: rule sequences from Seqs that fully explain all Pairs.
    sequence_inference_all_consistent/3,
    % sequence_inference_infer_2step/3: find the best 2-step rule sequence from Candidates.
    sequence_inference_infer_2step/3,
    % sequence_inference_infer_3step/3: find the best 3-step rule sequence from Candidates.
    sequence_inference_infer_3step/3,
    % sequence_inference_default_rules/1: standard single-step rule candidates.
    sequence_inference_default_rules/1,
    % sequence_inference_solve/3: infer the best single or two-step rule from default candidates.
    sequence_inference_solve/3,
    % sequence_inference_coverage_ratio/3: coverage as Num/Den (integer fraction).
    sequence_inference_coverage_ratio/3,
    % sequence_inference_n_pairs/2: number of pairs in the list.
    sequence_inference_n_pairs/2,
    % sequence_inference_explain/3: return BestSeq and its coverage count for a pair list.
    sequence_inference_explain/3,
    % sequence_inference_verify_all/2: succeed if Rules correctly transform every pair.
    sequence_inference_verify_all/2,
    % sequence_inference_arc2_candidates/1: ARC-AGI-2-relevant extended primitive rule candidates.
    sequence_inference_arc2_candidates/1
]).

% Import list utilities.
:- use_module(library(lists), [member/2, last/2, subtract/3, nth1/3]).
% Import apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3, include/3]).

% sequence_inference_apply(+Rules, +Scene, -Result)
% Apply a list of transformation rules in order to Scene, producing Result.
% Rules is a list of rule terms (see sequence_inference_apply_one_/3 for handled forms).
sequence_inference_apply([], Scene, Scene).
sequence_inference_apply([Rule|Rest], Scene, Result) :-
% Apply the first rule to get an intermediate scene.
    sequence_inference_apply_one_(Rule, Scene, Intermediate),
% Recurse on remaining rules with the intermediate scene.
    sequence_inference_apply(Rest, Intermediate, Result).

% sequence_inference_apply_one_(+Rule, +Scene, -Result): dispatch for a single rule term.
% identity: return Scene unchanged.
sequence_inference_apply_one_(identity, Scene, Scene).
% recolor(C1, C2): change all objects of color C1 to color C2.
sequence_inference_apply_one_(recolor(C1, C2), Scene, Result) :-
    maplist(sequence_inference_recolor_obj_(C1, C2), Scene, Result).
% recolor_all(C): change every object to color C.
sequence_inference_apply_one_(recolor_all(C), Scene, Result) :-
    maplist([obj(_, Cells), obj(C, Cells)]>>true, Scene, Result).
% shift(DR, DC): translate every object by (DR, DC).
sequence_inference_apply_one_(shift(DR, DC), Scene, Result) :-
    maplist(sequence_inference_shift_obj_(DR, DC), Scene, Result).
% to_origin: translate every object so its top-left cell is at r(0,0).
sequence_inference_apply_one_(to_origin, Scene, Result) :-
    maplist(sequence_inference_to_origin_obj_, Scene, Result).
% reflect_h: reflect every object horizontally about its own horizontal axis.
sequence_inference_apply_one_(reflect_h, Scene, Result) :-
    maplist(sequence_inference_reflect_h_, Scene, Result).
% reflect_v: reflect every object vertically about its own vertical axis.
sequence_inference_apply_one_(reflect_v, Scene, Result) :-
    maplist(sequence_inference_reflect_v_, Scene, Result).
% remove_color(C): remove all objects of color C from the scene.
sequence_inference_apply_one_(remove_color(C), Scene, Result) :-
    include(sequence_inference_not_color_(C), Scene, Result).
% keep_color(C): retain only objects of color C.
sequence_inference_apply_one_(keep_color(C), Scene, Result) :-
    include(sequence_inference_is_color_(C), Scene, Result).
% sorting_size_desc: sort objects from largest to smallest by cell count.
sequence_inference_apply_one_(sorting_size_desc, Scene, Result) :-
    findall(NegN-Obj, (member(Obj, Scene), Obj=obj(_,Cells), length(Cells,N), NegN is -N), Keyed),
    msort(Keyed, Sorted),
    maplist([_-O, O]>>true, Sorted, Result).
% sorting_size_asc: sort objects from smallest to largest by cell count.
sequence_inference_apply_one_(sorting_size_asc, Scene, Result) :-
    findall(N-Obj, (member(Obj, Scene), Obj=obj(_,Cells), length(Cells,N)), Keyed),
    msort(Keyed, Sorted),
    maplist([_-O, O]>>true, Sorted, Result).
% top_n(N): keep only the N largest objects.
sequence_inference_apply_one_(top_n(N), Scene, Result) :-
    sequence_inference_apply_one_(sorting_size_desc, Scene, Sorted),
    sequence_inference_take_(Sorted, N, Result).
% color_map(Map): apply a color substitution map (list of C1-C2 pairs).
sequence_inference_apply_one_(color_map(Map), Scene, Result) :-
    maplist(sequence_inference_apply_color_map_(Map), Scene, Result).

% sequence_inference_recolor_obj_(+C1, +C2, +Obj, -Out): change color C1 to C2 in one object.
sequence_inference_recolor_obj_(C1, C2, obj(C, Cells), Out) :-
% If the object has the target color, change it; otherwise leave unchanged.
    (C == C1 -> Out = obj(C2, Cells) ; Out = obj(C, Cells)).

% sequence_inference_shift_obj_(+DR, +DC, +Obj, -Out): translate Obj's cells by (DR, DC).
sequence_inference_shift_obj_(DR, DC, obj(Color, Cells), obj(Color, Shifted)) :-
    maplist([r(R,C), r(R2,C2)]>>(R2 is R+DR, C2 is C+DC), Cells, Shifted).

% sequence_inference_to_origin_obj_(+Obj, -Out): translate so minimum row and column are both 0.
sequence_inference_to_origin_obj_(obj(Color, Cells), obj(Color, Moved)) :-
    findall(R, member(r(R,_), Cells), Rs), min_list(Rs, MinR),
    findall(C, member(r(_,C), Cells), Cs), min_list(Cs, MinC),
    maplist([r(R,C), r(R2,C2)]>>(R2 is R-MinR, C2 is C-MinC), Cells, Moved).

% sequence_inference_reflect_h_(+Obj, -Out): reflect cells within the object's bounding box horizontally.
sequence_inference_reflect_h_(obj(Color, Cells), obj(Color, Reflected)) :-
    findall(R, member(r(R,_), Cells), Rs), max_list(Rs, MaxR), min_list(Rs, MinR),
    maplist([r(R,C), r(R2,C)]>>(R2 is MinR + MaxR - R), Cells, Reflected).

% sequence_inference_reflect_v_(+Obj, -Out): reflect cells within the object's bounding box vertically.
sequence_inference_reflect_v_(obj(Color, Cells), obj(Color, Reflected)) :-
    findall(C, member(r(_,C), Cells), Cs), max_list(Cs, MaxC), min_list(Cs, MinC),
    maplist([r(R,C), r(R,C2)]>>(C2 is MinC + MaxC - C), Cells, Reflected).

% sequence_inference_not_color_(+C, +Obj): succeed if Obj does NOT have color C.
sequence_inference_not_color_(C, obj(ObjC, _)) :- ObjC \== C.

% sequence_inference_is_color_(+C, +Obj): succeed if Obj has color C.
sequence_inference_is_color_(C, obj(ObjC, _)) :- ObjC == C.

% sequence_inference_take_(+List, +N, -First): take the first N elements of List.
sequence_inference_take_(_, 0, []) :- !.
sequence_inference_take_([], _, []).
sequence_inference_take_([H|T], N, [H|Rest]) :- N > 0, N1 is N-1, sequence_inference_take_(T, N1, Rest).

% sequence_inference_apply_color_map_(+Map, +Obj, -Out): apply first matching C1-C2 entry in Map.
sequence_inference_apply_color_map_(Map, obj(C, Cells), obj(C2, Cells)) :-
    (member(C-C2, Map) -> true ; C2 = C).

% min_list/2 and max_list/2 are from library(lists) (imported above via subtract's header).
:- use_module(library(lists), [min_list/2, max_list/2]).

% sequence_inference_verify(+Rules, +Before, +After)
% Succeed if applying Rules to Before produces After (comparing msorted cell lists).
sequence_inference_verify(Rules, Before, After) :-
    sequence_inference_apply(Rules, Before, Result),
    msort(Result, SortedResult),
    msort(After, SortedAfter),
    SortedResult == SortedAfter.

% sequence_inference_consistent(+Rules, +Pairs)
% Succeed if Rules correctly transforms every Before-After pair.
sequence_inference_consistent(Rules, Pairs) :-
    maplist(sequence_inference_verify_pair_(Rules), Pairs).

% sequence_inference_verify_pair_(+Rules, +Pair): verify one Before-After pair.
sequence_inference_verify_pair_(Rules, Before-After) :-
    sequence_inference_verify(Rules, Before, After).

% sequence_inference_coverage(+Rules, +Pairs, -N)
% N is the count of pairs for which Rules correctly transforms Before to After.
sequence_inference_coverage(Rules, Pairs, N) :-
    include(sequence_inference_verify_pair_(Rules), Pairs, Covered),
    length(Covered, N).

% sequence_inference_rank_seqs(+Seqs, +Pairs, -Ranked)
% Ranked is Seqs sorted by coverage descending (highest coverage first).
% Seqs is a list of rule sequences (each a list of rule terms).
sequence_inference_rank_seqs(Seqs, Pairs, Ranked) :-
    findall(NegCov-Seq,
        (member(Seq, Seqs), sequence_inference_coverage(Seq, Pairs, Cov), NegCov is -Cov),
        Keyed),
    msort(Keyed, Sorted),
    maplist([_-S, S]>>true, Sorted, Ranked).

% sequence_inference_all_consistent(+Seqs, +Pairs, -Consistent)
% Consistent is the sub-list of Seqs that fully explains all Pairs.
sequence_inference_all_consistent(Seqs, Pairs, Consistent) :-
    include(sequence_inference_consistent_seq_(Pairs), Seqs, Consistent).

% sequence_inference_consistent_seq_(+Pairs, +Seq): succeed if Seq is consistent with all Pairs.
sequence_inference_consistent_seq_(Pairs, Seq) :-
    sequence_inference_consistent(Seq, Pairs).

% sequence_inference_infer_2step(+Candidates, +Pairs, -BestSeq)
% BestSeq is the 2-element rule sequence [R1, R2] with the highest coverage on Pairs.
% Candidates is a list of single-step rule terms.
% Fails if Candidates is empty or no candidate pair has positive coverage.
sequence_inference_infer_2step(Candidates, Pairs, BestSeq) :-
    findall(Cov-[R1,R2],
        (member(R1, Candidates), member(R2, Candidates),
         sequence_inference_coverage([R1,R2], Pairs, Cov), Cov > 0),
        All),
    All \= [],
    msort(All, Sorted),
    last(Sorted, _-BestSeq).

% sequence_inference_infer_3step(+Candidates, +Pairs, -BestSeq)
% BestSeq is the 3-element rule sequence [R1, R2, R3] with the highest coverage.
sequence_inference_infer_3step(Candidates, Pairs, BestSeq) :-
    findall(Cov-[R1,R2,R3],
        (member(R1, Candidates), member(R2, Candidates), member(R3, Candidates),
         sequence_inference_coverage([R1,R2,R3], Pairs, Cov), Cov > 0),
        All),
    All \= [],
    msort(All, Sorted),
    last(Sorted, _-BestSeq).

% sequence_inference_default_rules(-Rules)
% Standard single-step rule candidates covering common transformations.
sequence_inference_default_rules([
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
    sorting_size_desc, sorting_size_asc
]).

% sequence_inference_solve(+Pairs, +Candidates, -BestSeq)
% Find the best rule sequence (1-step or 2-step) from Candidates that explains Pairs.
% Tries 1-step first; if no single rule has full coverage, tries 2-step.
sequence_inference_solve(Pairs, Candidates, BestSeq) :-
    (   sequence_inference_infer_2step(Candidates, Pairs, Best2),
        sequence_inference_coverage(Best2, Pairs, Cov2),
        length(Pairs, Total),
        Cov2 =:= Total
    ->  BestSeq = Best2
    ;   findall(Cov-[R],
            (member(R, Candidates), sequence_inference_coverage([R], Pairs, Cov), Cov > 0),
            Single),
        Single \= [],
        msort(Single, Sorted),
        last(Sorted, _-BestSeq)
    ).

% sequence_inference_coverage_ratio(+Rules, +Pairs, -Num/Den)
% Coverage as an integer fraction Num/Den.
sequence_inference_coverage_ratio(Rules, Pairs, Num/Den) :-
    sequence_inference_coverage(Rules, Pairs, Num),
    length(Pairs, Den).

% sequence_inference_n_pairs(+Pairs, -N): number of pairs in the list.
sequence_inference_n_pairs(Pairs, N) :- length(Pairs, N).

% sequence_inference_explain(+Rules, +Pairs, -Coverage)
% Coverage is the number of pairs correctly explained by Rules.
sequence_inference_explain(Rules, Pairs, Coverage) :-
    sequence_inference_coverage(Rules, Pairs, Coverage).

% sequence_inference_verify_all(+Rules, +Pairs): succeed if Rules transforms every pair correctly.
sequence_inference_verify_all(Rules, Pairs) :-
    sequence_inference_consistent(Rules, Pairs).

% sequence_inference_arc2_candidates(-Rules)
% Extended rule candidate list for multi-step search on harder compositional tasks.
% Uses integer colors 0-9 (standard ARC encoding) instead of atom colors.
% Superset of sequence_inference_default_rules tuned for the four ARC-AGI-2 difficulty flavours:
% multi-rule compositional, multi-step sequential, context-gated, symbol-defined.
sequence_inference_arc2_candidates([
    identity,
    recolor(1, 2), recolor(2, 1), recolor(1, 3), recolor(3, 1),
    recolor(1, 4), recolor(4, 1), recolor(1, 5), recolor(5, 1),
    recolor(1, 6), recolor(6, 1), recolor(2, 3), recolor(3, 2),
    recolor(2, 4), recolor(4, 2), recolor(2, 5), recolor(5, 2),
    recolor(3, 4), recolor(4, 3), recolor(3, 5), recolor(5, 3),
    recolor(4, 5), recolor(5, 4), recolor(4, 6), recolor(6, 4),
    recolor(5, 6), recolor(6, 5),
    recolor_all(1), recolor_all(2), recolor_all(3),
    recolor_all(4), recolor_all(5), recolor_all(6),
    shift(0, 1), shift(0, -1), shift(1, 0), shift(-1, 0),
    shift(1, 1), shift(1, -1), shift(-1, 1), shift(-1, -1),
    shift(2, 0), shift(-2, 0), shift(0, 2), shift(0, -2),
    shift(3, 0), shift(-3, 0), shift(0, 3), shift(0, -3),
    to_origin,
    reflect_h, reflect_v,
    remove_color(1), remove_color(2), remove_color(3),
    remove_color(4), remove_color(5), remove_color(6),
    keep_color(1), keep_color(2), keep_color(3),
    keep_color(4), keep_color(5), keep_color(6),
    sorting_size_desc, sorting_size_asc,
    top_n(1), top_n(2), top_n(3)
]).
