:- begin_tests(pigment).
:- use_module('../prolog/pigment').

% pigment_recolor_all/3 - set every obj to a fixed color.
test(recolor_all_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    pigment_recolor_all(Objs, 5, [obj(5,[r(0,0)]), obj(5,[r(0,1)])]).

test(recolor_all_single) :-
    pigment_recolor_all([obj(3,[r(0,0)])], 7, [obj(7,[r(0,0)])]).

test(recolor_all_empty) :-
    pigment_recolor_all([], 5, []).

% pigment_recolor_one/4 - change all From to To, keep others.
test(recolor_one_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(1,[r(1,0)])],
    pigment_recolor_one(Objs, 1, 5, [obj(5,[r(0,0)]), obj(2,[r(0,1)]), obj(5,[r(1,0)])]).

test(recolor_one_no_match) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    pigment_recolor_one(Objs, 9, 5, Objs).

test(recolor_one_all_match) :-
    pigment_recolor_one([obj(3,[r(0,0)]), obj(3,[r(1,0)])], 3, 7,
                   [obj(7,[r(0,0)]), obj(7,[r(1,0)])]).

% pigment_swap/4 - exchange two colors throughout the scene.
test(swap_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(1,[r(1,0)])],
    pigment_swap(Objs, 1, 2, [obj(2,[r(0,0)]), obj(1,[r(0,1)]), obj(2,[r(1,0)])]).

test(swap_neither_present) :-
    Objs = [obj(3,[r(0,0)]), obj(4,[r(0,1)])],
    pigment_swap(Objs, 1, 2, Objs).

test(swap_one_present) :-
    pigment_swap([obj(1,[r(0,0)]), obj(3,[r(0,1)])], 1, 2,
            [obj(2,[r(0,0)]), obj(3,[r(0,1)])]).

% pigment_apply_table/3 - apply color table; keep color if not in table.
test(apply_table_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    pigment_apply_table(Objs, [1-5, 2-6], [obj(5,[r(0,0)]), obj(6,[r(0,1)])]).

test(apply_table_partial) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(3,[r(1,0)])],
    pigment_apply_table(Objs, [1-5, 2-6], [obj(5,[r(0,0)]), obj(6,[r(0,1)]), obj(3,[r(1,0)])]).

test(apply_table_identity) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    pigment_apply_table(Objs, [1-1, 2-2], Objs).

% pigment_apply_table_strict/3 - keep only objs with table entries.
test(apply_strict_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(3,[r(1,0)])],
    pigment_apply_table_strict(Objs, [1-5, 2-6], [obj(5,[r(0,0)]), obj(6,[r(0,1)])]).

test(apply_strict_all) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    pigment_apply_table_strict(Objs, [1-5, 2-6], [obj(5,[r(0,0)]), obj(6,[r(0,1)])]).

test(apply_strict_none) :-
    pigment_apply_table_strict([obj(1,[r(0,0)]), obj(2,[r(0,1)])], [3-7, 4-8], []).

% pigment_infer_table/3 - infer color map from same-cell obj pairs.
test(infer_table_basic) :-
    Objs1 = [obj(1,[r(0,0),r(0,1)]), obj(2,[r(1,0)])],
    Objs2 = [obj(3,[r(0,0),r(0,1)]), obj(4,[r(1,0)])],
    pigment_infer_table(Objs1, Objs2, [1-3, 2-4]).

test(infer_table_identity) :-
    Objs = [obj(1,[r(0,0)])],
    pigment_infer_table(Objs, Objs, [1-1]).

test(infer_table_single) :-
    pigment_infer_table([obj(5,[r(0,0),r(1,0)])], [obj(8,[r(0,0),r(1,0)])], [5-8]).

% pigment_zip_recolor/3 - recolor each obj with corresponding color.
test(zip_recolor_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(3,[r(1,0)])],
    pigment_zip_recolor(Objs, [5,6,7], [obj(5,[r(0,0)]), obj(6,[r(0,1)]), obj(7,[r(1,0)])]).

test(zip_recolor_truncate) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(3,[r(1,0)])],
    pigment_zip_recolor(Objs, [5,6], [obj(5,[r(0,0)]), obj(6,[r(0,1)])]).

test(zip_recolor_single) :-
    pigment_zip_recolor([obj(3,[r(0,0)])], [9], [obj(9,[r(0,0)])]).

% pigment_majority_to/3 - recolor most frequent color objs.
test(majority_to_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(1,[r(1,0)])],
    pigment_majority_to(Objs, 9, [obj(9,[r(0,0)]), obj(2,[r(0,1)]), obj(9,[r(1,0)])]).

test(majority_to_all_same) :-
    Objs = [obj(3,[r(0,0)]), obj(3,[r(1,0)])],
    pigment_majority_to(Objs, 7, [obj(7,[r(0,0)]), obj(7,[r(1,0)])]).

test(majority_to_tie) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    pigment_majority_to(Objs, 9, [obj(9,[r(0,0)]), obj(2,[r(0,1)])]).

% pigment_minority_to/3 - recolor least frequent color objs.
test(minority_to_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(1,[r(1,0)])],
    pigment_minority_to(Objs, 9, [obj(1,[r(0,0)]), obj(9,[r(0,1)]), obj(1,[r(1,0)])]).

test(minority_to_all_same) :-
    Objs = [obj(3,[r(0,0)]), obj(3,[r(1,0)])],
    pigment_minority_to(Objs, 7, [obj(7,[r(0,0)]), obj(7,[r(1,0)])]).

test(minority_to_tie) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    pigment_minority_to(Objs, 9, [obj(9,[r(0,0)]), obj(2,[r(0,1)])]).

% pigment_unique_to/3 - recolor uniquely-colored objs.
test(unique_to_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(1,[r(1,0)])],
    pigment_unique_to(Objs, 9, [obj(1,[r(0,0)]), obj(9,[r(0,1)]), obj(1,[r(1,0)])]).

test(unique_to_none) :-
    Objs = [obj(1,[r(0,0)]), obj(1,[r(1,0)])],
    pigment_unique_to(Objs, 9, Objs).

test(unique_to_all) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    pigment_unique_to(Objs, 9, [obj(9,[r(0,0)]), obj(9,[r(0,1)])]).

% pigment_shared_to/3 - recolor shared-color objs.
test(shared_to_basic) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)]), obj(1,[r(1,0)])],
    pigment_shared_to(Objs, 9, [obj(9,[r(0,0)]), obj(2,[r(0,1)]), obj(9,[r(1,0)])]).

test(shared_to_none) :-
    Objs = [obj(1,[r(0,0)]), obj(2,[r(0,1)])],
    pigment_shared_to(Objs, 9, Objs).

test(shared_to_all) :-
    Objs = [obj(1,[r(0,0)]), obj(1,[r(1,0)]), obj(2,[r(0,1)]), obj(2,[r(1,1)])],
    pigment_shared_to(Objs, 9, [obj(9,[r(0,0)]), obj(9,[r(1,0)]), obj(9,[r(0,1)]), obj(9,[r(1,1)])]).

% pigment_invert_table/2 - swap From and To in each pair.
test(invert_table_basic) :-
    pigment_invert_table([1-5, 2-6], [5-1, 6-2]).

test(invert_table_identity) :-
    pigment_invert_table([1-1], [1-1]).

test(invert_table_single) :-
    pigment_invert_table([3-7], [7-3]).

% pigment_table_from/2 - sorted From colors.
test(data_table_from_basic) :-
    pigment_table_from([1-5, 2-6], [1,2]).

test(data_table_from_unsorted) :-
    pigment_table_from([3-9, 1-5], [1,3]).

test(data_table_from_single) :-
    pigment_table_from([7-2], [7]).

% pigment_consistent/1 - no conflicting From mappings.
test(consistent_yes) :-
    pigment_consistent([1-5, 2-6]).

test(consistent_no, [fail]) :-
    pigment_consistent([1-5, 1-6]).

test(consistent_single) :-
    pigment_consistent([3-7]).

:- end_tests(pigment).
