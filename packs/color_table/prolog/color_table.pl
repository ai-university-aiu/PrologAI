% colortable: color substitution table learning and application (ct_*, Layer 190)
:- module(color_table, [
    color_table_infer_from_pair/3,
    color_table_merge_maps/3,
    color_table_learn_map/3,
    color_table_consistent_map/1,
    color_table_apply_map/3,
    color_table_apply_to_scene/3,
    color_table_map_covers/2,
    color_table_complete_map/3,
    color_table_invert_map/2,
    color_table_identity_map/2,
    color_table_restrict_map/3,
    color_table_map_colors/2,
    color_table_mapped_color/3,
    color_table_extend_map/3
]).

% Load list utilities for member, subtract, append, sort
:- use_module(library(lists), [member/2, subtract/3, append/3, list_to_set/2]).
% Load apply utilities for maplist
:- use_module(library(apply), [maplist/3]).

% color_table_infer_from_pair(+Before, +After, -Map)
% Derive the color-to-color mapping from one Before-After scene pair.
% Before and After are lists of obj(Color, Cells) of the same length.
% Map is a list of From-To pairs where From \== To (changed colors only).
% Fails if the same source color maps to two different target colors.
color_table_infer_from_pair(Before, After, Map) :-
    % Collect changed color pairs positionally (n-th Before object vs n-th After)
    color_table_collect_pairs_(Before, After, Pairs),
    % Remove duplicate pairs, keeping set semantics
    list_to_set(Pairs, Map),
    % Verify consistency: no source color maps to two different targets
    color_table_consistent_map(Map).

% color_table_collect_pairs_(+Before, +After, -Pairs)
% Extract changed color pairs by positional correspondence.
% The n-th Before object is paired with the n-th After object.
color_table_collect_pairs_([], [], []).
color_table_collect_pairs_([obj(CB, _) | RestB], [obj(CA, _) | RestA], Pairs) :-
    color_table_collect_pairs_(RestB, RestA, RestPairs),
    (   CB == CA
    ->  Pairs = RestPairs
    ;   Pairs = [CB-CA | RestPairs]
    ).

% color_table_consistent_map(+Map)
% Succeed if no source color appears with two different targets.
color_table_consistent_map(Map) :-
    \+ (
        member(From-To1, Map),
        member(From-To2, Map),
        To1 \== To2
    ).

% color_table_merge_maps(+Map1, +Map2, -Merged)
% Combine two color maps. Fails if the same source color maps to different targets.
color_table_merge_maps(Map1, Map2, Merged) :-
    append(Map1, Map2, Combined),
    list_to_set(Combined, Merged),
    color_table_consistent_map(Merged).

% color_table_extend_map(+Base, +Extra, -Extended)
% Add new mappings from Extra to Base, skipping duplicates, failing on conflict.
color_table_extend_map(Base, Extra, Extended) :-
    color_table_merge_maps(Base, Extra, Extended).

% color_table_learn_map(+Pairs, -Map, -Inconsistent)
% Learn a color map from a list of Before-After pairs.
% Pairs is a list of Before-After terms.
% Map is the merged mapping from all consistent pairs.
% Inconsistent is the list of pairs that conflicted with the accumulated map.
color_table_learn_map(Pairs, Map, Inconsistent) :-
    color_table_learn_acc_(Pairs, [], Map, [], Inconsistent).

% color_table_learn_acc_(+Remaining, +AccMap, -FinalMap, +AccBad, -FinalBad)
color_table_learn_acc_([], Map, Map, Bad, Bad).
color_table_learn_acc_([Before-After | Rest], Acc, Map, BadAcc, Bad) :-
    % Infer mapping from this pair
    (   color_table_infer_from_pair(Before, After, PairMap),
        color_table_merge_maps(Acc, PairMap, Merged)
    ->  % Consistent with accumulated map; keep it
        color_table_learn_acc_(Rest, Merged, Map, BadAcc, Bad)
    ;   % Inconsistent; record pair as bad and continue with old acc
        color_table_learn_acc_(Rest, Acc, Map, [Before-After | BadAcc], Bad)
    ).

% color_table_mapped_color(+Map, +Color, -Mapped)
% Look up Color in Map. Returns Mapped target color.
% If Color is not in Map, returns Color unchanged (identity).
color_table_mapped_color(Map, Color, Mapped) :-
    (   member(Color-Target, Map)
    ->  Mapped = Target
    ;   Mapped = Color
    ).

% color_table_apply_map(+Map, +obj(Color,Cells), -obj(MappedColor,Cells))
% Apply a color map to a single obj term.
color_table_apply_map(Map, obj(C, Cells), obj(MC, Cells)) :-
    color_table_mapped_color(Map, C, MC).

% color_table_apply_to_scene(+Map, +Scene, -MappedScene)
% Apply a color map to every object in a scene list.
color_table_apply_to_scene(Map, Scene, MappedScene) :-
    maplist(color_table_apply_map(Map), Scene, MappedScene).

% color_table_map_covers(+Map, +Scene)
% Succeed if Map has an explicit entry for every color in Scene.
color_table_map_covers(Map, Scene) :-
    \+ (
        member(obj(C, _), Scene),
        \+ member(C-_, Map)
    ).

% color_table_complete_map(+Map, +Scene, -Complete)
% Extend Map with identity entries for any colors in Scene not already covered.
color_table_complete_map(Map, Scene, Complete) :-
    findall(C, (member(obj(C, _), Scene), \+ member(C-_, Map)), Missing),
    list_to_set(Missing, Unique),
    findall(C-C, member(C, Unique), IdentityEntries),
    append(Map, IdentityEntries, Complete).

% color_table_invert_map(+Map, -Inverted)
% Swap the From and To in each entry.
% Fails if the inversion is inconsistent (two sources map to same target in original).
color_table_invert_map(Map, Inverted) :-
    maplist(color_table_swap_pair_, Map, Inverted),
    color_table_consistent_map(Inverted).

% color_table_swap_pair_(+From-To, -To-From)
color_table_swap_pair_(F-T, T-F).

% color_table_identity_map(+Colors, -Map)
% Build a map where every color maps to itself.
color_table_identity_map(Colors, Map) :-
    list_to_set(Colors, Unique),
    findall(C-C, member(C, Unique), Map).

% color_table_restrict_map(+Map, +Colors, -Restricted)
% Keep only map entries whose source color appears in Colors.
color_table_restrict_map(Map, Colors, Restricted) :-
    include(color_table_color_in_(Colors), Map, Restricted).

% color_table_color_in_(+Colors, +From-_To)
color_table_color_in_(Colors, From-_) :-
    member(From, Colors).

% color_table_map_colors(+Map, -Colors)
% List all source (From) colors in the map.
color_table_map_colors(Map, Colors) :-
    findall(From, member(From-_, Map), All),
    list_to_set(All, Colors).
