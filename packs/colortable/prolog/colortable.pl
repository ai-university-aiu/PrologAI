% colortable: color substitution table learning and application (ct_*, Layer 190)
:- module(colortable, [
    colortable_infer_from_pair/3,
    colortable_merge_maps/3,
    colortable_learn_map/3,
    colortable_consistent_map/1,
    colortable_apply_map/3,
    colortable_apply_to_scene/3,
    colortable_map_covers/2,
    colortable_complete_map/3,
    colortable_invert_map/2,
    colortable_identity_map/2,
    colortable_restrict_map/3,
    colortable_map_colors/2,
    colortable_mapped_color/3,
    colortable_extend_map/3
]).

% Load list utilities for member, subtract, append, sort
:- use_module(library(lists), [member/2, subtract/3, append/3, list_to_set/2]).
% Load apply utilities for maplist
:- use_module(library(apply), [maplist/3]).

% colortable_infer_from_pair(+Before, +After, -Map)
% Derive the color-to-color mapping from one Before-After scene pair.
% Before and After are lists of obj(Color, Cells) of the same length.
% Map is a list of From-To pairs where From \== To (changed colors only).
% Fails if the same source color maps to two different target colors.
colortable_infer_from_pair(Before, After, Map) :-
    % Collect changed color pairs positionally (n-th Before object vs n-th After)
    colortable_collect_pairs_(Before, After, Pairs),
    % Remove duplicate pairs, keeping set semantics
    list_to_set(Pairs, Map),
    % Verify consistency: no source color maps to two different targets
    colortable_consistent_map(Map).

% colortable_collect_pairs_(+Before, +After, -Pairs)
% Extract changed color pairs by positional correspondence.
% The n-th Before object is paired with the n-th After object.
colortable_collect_pairs_([], [], []).
colortable_collect_pairs_([obj(CB, _) | RestB], [obj(CA, _) | RestA], Pairs) :-
    colortable_collect_pairs_(RestB, RestA, RestPairs),
    (   CB == CA
    ->  Pairs = RestPairs
    ;   Pairs = [CB-CA | RestPairs]
    ).

% colortable_consistent_map(+Map)
% Succeed if no source color appears with two different targets.
colortable_consistent_map(Map) :-
    \+ (
        member(From-To1, Map),
        member(From-To2, Map),
        To1 \== To2
    ).

% colortable_merge_maps(+Map1, +Map2, -Merged)
% Combine two color maps. Fails if the same source color maps to different targets.
colortable_merge_maps(Map1, Map2, Merged) :-
    append(Map1, Map2, Combined),
    list_to_set(Combined, Merged),
    colortable_consistent_map(Merged).

% colortable_extend_map(+Base, +Extra, -Extended)
% Add new mappings from Extra to Base, skipping duplicates, failing on conflict.
colortable_extend_map(Base, Extra, Extended) :-
    colortable_merge_maps(Base, Extra, Extended).

% colortable_learn_map(+Pairs, -Map, -Inconsistent)
% Learn a color map from a list of Before-After pairs.
% Pairs is a list of Before-After terms.
% Map is the merged mapping from all consistent pairs.
% Inconsistent is the list of pairs that conflicted with the accumulated map.
colortable_learn_map(Pairs, Map, Inconsistent) :-
    colortable_learn_acc_(Pairs, [], Map, [], Inconsistent).

% colortable_learn_acc_(+Remaining, +AccMap, -FinalMap, +AccBad, -FinalBad)
colortable_learn_acc_([], Map, Map, Bad, Bad).
colortable_learn_acc_([Before-After | Rest], Acc, Map, BadAcc, Bad) :-
    % Infer mapping from this pair
    (   colortable_infer_from_pair(Before, After, PairMap),
        colortable_merge_maps(Acc, PairMap, Merged)
    ->  % Consistent with accumulated map; keep it
        colortable_learn_acc_(Rest, Merged, Map, BadAcc, Bad)
    ;   % Inconsistent; record pair as bad and continue with old acc
        colortable_learn_acc_(Rest, Acc, Map, [Before-After | BadAcc], Bad)
    ).

% colortable_mapped_color(+Map, +Color, -Mapped)
% Look up Color in Map. Returns Mapped target color.
% If Color is not in Map, returns Color unchanged (identity).
colortable_mapped_color(Map, Color, Mapped) :-
    (   member(Color-Target, Map)
    ->  Mapped = Target
    ;   Mapped = Color
    ).

% colortable_apply_map(+Map, +obj(Color,Cells), -obj(MappedColor,Cells))
% Apply a color map to a single obj term.
colortable_apply_map(Map, obj(C, Cells), obj(MC, Cells)) :-
    colortable_mapped_color(Map, C, MC).

% colortable_apply_to_scene(+Map, +Scene, -MappedScene)
% Apply a color map to every object in a scene list.
colortable_apply_to_scene(Map, Scene, MappedScene) :-
    maplist(colortable_apply_map(Map), Scene, MappedScene).

% colortable_map_covers(+Map, +Scene)
% Succeed if Map has an explicit entry for every color in Scene.
colortable_map_covers(Map, Scene) :-
    \+ (
        member(obj(C, _), Scene),
        \+ member(C-_, Map)
    ).

% colortable_complete_map(+Map, +Scene, -Complete)
% Extend Map with identity entries for any colors in Scene not already covered.
colortable_complete_map(Map, Scene, Complete) :-
    findall(C, (member(obj(C, _), Scene), \+ member(C-_, Map)), Missing),
    list_to_set(Missing, Unique),
    findall(C-C, member(C, Unique), IdentityEntries),
    append(Map, IdentityEntries, Complete).

% colortable_invert_map(+Map, -Inverted)
% Swap the From and To in each entry.
% Fails if the inversion is inconsistent (two sources map to same target in original).
colortable_invert_map(Map, Inverted) :-
    maplist(colortable_swap_pair_, Map, Inverted),
    colortable_consistent_map(Inverted).

% colortable_swap_pair_(+From-To, -To-From)
colortable_swap_pair_(F-T, T-F).

% colortable_identity_map(+Colors, -Map)
% Build a map where every color maps to itself.
colortable_identity_map(Colors, Map) :-
    list_to_set(Colors, Unique),
    findall(C-C, member(C, Unique), Map).

% colortable_restrict_map(+Map, +Colors, -Restricted)
% Keep only map entries whose source color appears in Colors.
colortable_restrict_map(Map, Colors, Restricted) :-
    include(colortable_color_in_(Colors), Map, Restricted).

% colortable_color_in_(+Colors, +From-_To)
colortable_color_in_(Colors, From-_) :-
    member(From, Colors).

% colortable_map_colors(+Map, -Colors)
% List all source (From) colors in the map.
colortable_map_colors(Map, Colors) :-
    findall(From, member(From-_, Map), All),
    list_to_set(All, Colors).
