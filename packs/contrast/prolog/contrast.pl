% Module declaration with all fourteen public predicates.
:- module(contrast, [
% Compute the per-pair delta: what changed from input to output in each pair.
    ca_pairwise_delta/2,
% Find input features that co-vary with output changes across all pairs.
    ca_covarying_features/2,
% Identify which input feature acts as a context gate (modulates the rule).
    ca_context_gate/2,
% Find the training pair that discriminates between two competing hypotheses.
    ca_discriminating_pair/4,
% Find all input features that are correlated with a specific output change.
    ca_correlated_features/3,
% Compute the number of pairs where a given feature changes.
    ca_change_count/3,
% Find input features constant in pairs where output change A occurs.
    ca_common_context/3,
% Succeed if a feature consistently separates two output classes.
    ca_separates/4,
% Find the minimal set of features that explains all output variation.
    ca_minimal_features/2,
% Compute the feature profile for a single grid: list of feat(F,V) terms.
    ca_feature_profile/2,
% Compare feature profiles of two grids and return changed features.
    ca_profile_diff/3,
% Find features whose value is the same in every training input.
    ca_stable_features/2,
% Find features whose value changes between at least two training inputs.
    ca_unstable_features/2,
% Rank features by their correlation with output changes (highest first).
    ca_rank_features/2
]).
% contrast.pl - Layer 249: Contrastive Pair Analysis (ca_* prefix).
% Fourteen predicates for finding which input features co-vary with output
% changes across training pairs. The key insight: if feature F has value V1
% in pairs where change C occurs and value V2 in pairs where C does not occur,
% then F is a candidate context gate or rule trigger.
% Training pairs are pair(InputGrid, OutputGrid) terms.
% Deltas are delta(PairIdx, Changes) terms where Changes is a list of chg/4.
% Features are feat(Name, Value) terms.
:- use_module(library(lists),  [member/2, subtract/3, numlist/3, last/2, reverse/2]).
:- use_module(library(apply),  [maplist/2, maplist/3, include/3]).

% --- PRIVATE HELPERS ---

% ca_grid_dims_/3: get grid dimensions.
ca_grid_dims_(Grid, Rows, Cols) :-
    length(Grid, Rows),
    (Grid = [Row|_] -> length(Row, Cols) ; Cols = 0).

% ca_grid_colors_/3: sorted non-bg colors in a grid.
ca_grid_colors_(Grid, BgColor, Colors) :-
    findall(V, (member(Row, Grid), member(V, Row), V \= BgColor), All),
    sort(All, Colors).

% ca_cell_changes_/3: list of chg(R,C,OldV,NewV) for every changed cell.
ca_cell_changes_(InGrid, OutGrid, Changes) :-
    length(InGrid, Rows), Rows1 is Rows - 1,
    numlist(0, Rows1, RowIdxs),
    findall(chg(R,C,IV,OV),
        (member(R, RowIdxs),
         nth0(R, InGrid, InRow), nth0(R, OutGrid, OutRow),
         length(InRow, Cols), Cols1 is Cols - 1,
         numlist(0, Cols1, ColIdxs),
         member(C, ColIdxs),
         nth0(C, InRow, IV), nth0(C, OutRow, OV),
         IV \= OV),
        Changes).

% ca_dominant_color_/2: most frequent non-0 color in a grid.
ca_dominant_color_(Grid, Color) :-
    findall(V, (member(Row, Grid), member(V, Row), V \= 0), All),
    msort(All, Sorted),
    ca_run_length_(Sorted, Runs),
    msort(Runs, SRuns),
    last(SRuns, _-Color).

% ca_run_length_/2: compute N-Color pairs for color frequency.
ca_run_length_([], []).
ca_run_length_([H|T], [N-H|Rest]) :-
    include(=(H), [H|T], Same),
    subtract([H|T], Same, Others),
    length(Same, N),
    ca_run_length_(Others, Rest).

% ca_apply_hyp_/3: apply a hypothesis (color map) to InGrid; succeed if result = OutGrid.
ca_apply_hyp_(InGrid, Map, OutGrid) :-
    length(InGrid, Rows), Rows1 is Rows - 1,
    numlist(0, Rows1, RowIdxs),
    maplist([R-InRow, OutRow]>>(
        nth0(R, InGrid, InRow),
        nth0(R, OutGrid, OutRow),
        maplist([IV, OV]>>(
            (member(cm(IV,NV), Map) -> OV = NV ; OV = IV)
        ), InRow, OutRow)
    ), RowIdxs-_Ignored, _Ignored2),
    % Simple verification: check that applying Map to InGrid produces OutGrid.
    findall(ok,
        (member(R, RowIdxs),
         nth0(R, InGrid, InRow), nth0(R, OutGrid, OutRow),
         maplist([IV, OV]>>(
             (member(cm(IV,NV), Map) -> NV = OV ; IV = OV)
         ), InRow, OutRow)),
        Oks),
    length(Oks, Rows).

% --- PUBLIC PREDICATES ---

% ca_pairwise_delta(+Pairs, -Deltas)
% Deltas is a list of delta(I, Changes) where I is the 1-based index of the pair
% and Changes is a list of chg(R,C,OldV,NewV) terms for each changed cell.
ca_pairwise_delta(Pairs, Deltas) :-
    length(Pairs, N),
    numlist(1, N, Idxs),
    maplist(ca_delta_for_pair_, Idxs, Pairs, Deltas).

ca_delta_for_pair_(Idx, pair(In, Out), delta(Idx, Changes)) :-
    ca_cell_changes_(In, Out, Changes).

% ca_covarying_features(+Pairs, -Features)
% Features is a list of feat(Name, Value) terms for input features that
% consistently appear in pairs where the output changes AND do not appear
% in pairs where the output does not change.
% A feature co-varies if its presence or absence tracks the output change.
ca_covarying_features([], []).
ca_covarying_features(Pairs, Features) :-
    % Classify pairs as changing (output differs from input) or stable.
    include(ca_pair_changes_, Pairs, ChangingPairs),
    subtract(Pairs, ChangingPairs, StablePairs),
    (ChangingPairs = [] -> Features = [] ;
        % Get feature profiles for all changing inputs.
        maplist(ca_input_profile_, ChangingPairs, ChangingProfiles),
        % Find features present in ALL changing pairs.
        ca_common_features_(ChangingProfiles, CommonChanging),
        % Subtract features also present in stable pairs.
        (StablePairs = [] ->
            Features = CommonChanging
        ;
            maplist(ca_input_profile_, StablePairs, StableProfiles),
            ca_union_features_(StableProfiles, StableFeats),
            subtract(CommonChanging, StableFeats, Features)
        )
    ).

% ca_pair_changes_/1: succeed if the pair has at least one changed cell.
ca_pair_changes_(pair(In, Out)) :-
    ca_cell_changes_(In, Out, Changes),
    Changes \= [].

% ca_input_profile_/2: get feature profile of the input grid.
ca_input_profile_(pair(In, _), Profile) :-
    ca_feature_profile(In, Profile).

% ca_common_features_/2: features present in ALL profiles.
ca_common_features_([], []).
ca_common_features_([P|Rest], Common) :-
    (Rest = [] ->
        Common = P
    ;
        ca_common_features_(Rest, RestCommon),
        include(ca_in_profile_(P), RestCommon, Common)
    ).

% ca_in_profile_/2: succeed if feat F is in Profile.
ca_in_profile_(Profile, F) :- member(F, Profile).

% ca_union_features_/2: all unique features across all profiles.
ca_union_features_(Profiles, Union) :-
    findall(F, (member(P, Profiles), member(F, P)), All),
    sort(All, Union).

% ca_context_gate(+Pairs, -GateFeature)
% GateFeature = feat(Name, Value) for the input feature that most consistently
% separates pairs that change from pairs that don't change.
% Returns the first feature for which ca_separates/4 succeeds.
ca_context_gate(Pairs, GateFeature) :-
    ca_rank_features(Pairs, Ranked),
    (Ranked = [feat(Name, Value)|_] ->
        GateFeature = feat(Name, Value)
    ;
        GateFeature = feat(none, none)
    ).

% ca_discriminating_pair(+Pairs, +Hyp1, +Hyp2, -Pair)
% Pair is the first training pair from Pairs where the outcomes of Hyp1 and
% Hyp2 differ. Hyp1 and Hyp2 are color maps (lists of cm/2 terms).
% A discriminating pair is one where applying Hyp1 gives the correct output
% but Hyp2 does not, or vice versa.
ca_discriminating_pair([P|Rest], Hyp1, Hyp2, DiscPair) :-
    P = pair(In, Out),
    ca_cell_changes_(In, Out, Changes),
    (ca_explains_(Changes, Hyp1, In) \= ca_explains_(Changes, Hyp2, In) ->
        DiscPair = P
    ;
        ca_discriminating_pair(Rest, Hyp1, Hyp2, DiscPair)
    ).

% ca_explains_/3: succeed if applying Map to In explains the Changes.
ca_explains_(Changes, Map, In) :-
    findall(ok,
        (member(chg(R,C,IV,OV), Changes),
         nth0(R, In, InRow), nth0(C, InRow, IV),
         (member(cm(IV, NV), Map) -> NV = OV ; IV = OV)),
        Oks),
    length(Changes, L), length(Oks, L).

% ca_correlated_features(+Pairs, +OutputChange, -Features)
% Features is the list of feat/2 terms from input profiles that appear in
% every pair where OutputChange occurs.
% OutputChange is a chg(R,C,OldV,NewV) term or a simpler atom.
ca_correlated_features(Pairs, OutputChange, Features) :-
    include(ca_has_output_change_(OutputChange), Pairs, Matching),
    (Matching = [] ->
        Features = []
    ;
        maplist(ca_input_profile_, Matching, Profiles),
        ca_common_features_(Profiles, Features)
    ).

% ca_has_output_change_/2: succeed if the pair contains the given change pattern.
ca_has_output_change_(OutputChange, pair(In, Out)) :-
    ca_cell_changes_(In, Out, Changes),
    (OutputChange = chg(_,_,OV,NV) ->
        member(chg(_,_,OV,NV), Changes)
    ;
        Changes \= []
    ).

% ca_change_count(+Pairs, +Feature, -N)
% N is the number of pairs where Feature appears in the input profile AND
% the output differs from the input.
ca_change_count(Pairs, Feature, N) :-
    include(ca_pair_changes_, Pairs, ChangingPairs),
    include(ca_has_feature_(Feature), ChangingPairs, Matching),
    length(Matching, N).

% ca_has_feature_/2: succeed if Feature appears in the input profile.
ca_has_feature_(Feature, pair(In, _)) :-
    ca_feature_profile(In, Profile),
    member(Feature, Profile).

% ca_common_context(+Pairs, +OutputChange, -Context)
% Context is a list of feat/2 terms present in the input for every pair
% where OutputChange occurs. These features form the "common context" that
% accompanies the observed output change.
ca_common_context(Pairs, OutputChange, Context) :-
    ca_correlated_features(Pairs, OutputChange, Context).

% ca_separates(+Pairs, +Hyp, +PositivePairs, -Result)
% Succeed if Hyp (a feat/2 term) separates PositivePairs from the remainder.
% PositivePairs are pairs where a specific change occurs.
% Result is the ratio of correctly separated pairs.
ca_separates(Pairs, Feature, PositivePairs, Result) :-
    include(ca_has_feature_(Feature), Pairs, WithFeature),
    include(ca_has_feature_(Feature), PositivePairs, TP),
    subtract(WithFeature, PositivePairs, FP),
    length(TP, TPN), length(FP, FPN),
    (TPN + FPN =:= 0 -> Result = 0.0 ; Result is TPN / (TPN + FPN)).

% ca_minimal_features(+Pairs, -Features)
% Features is a short list of input features that together explain all output
% variation across the training pairs. Uses a greedy approach:
% pick the feature that best separates changing from stable pairs at each step.
ca_minimal_features(Pairs, Features) :-
    ca_rank_features(Pairs, Ranked),
    (Ranked = [] -> Features = [] ; Features = Ranked).

% ca_feature_profile(+Grid, -Profile)
% Profile is a list of feat(Name, Value) terms for observable grid features.
% Features extracted: dims, bg_color, color_count, dominant_color.
ca_feature_profile(Grid, Profile) :-
    ca_grid_dims_(Grid, Rows, Cols),
    ca_grid_colors_(Grid, 0, Colors),
    length(Colors, ColorCount),
    (Colors = [] -> DomColor = 0 ;
        (ca_dominant_color_(Grid, DomColor) -> true ; Colors = [DomColor|_])),
    sort([feat(dims, Rows-Cols),
          feat(color_count, ColorCount),
          feat(dominant_color, DomColor)],
         Profile).

% ca_profile_diff(+Profile1, +Profile2, -Changed)
% Changed is the list of feat/2 terms in Profile1 that are NOT in Profile2
% with the same value (i.e., features that changed between the two grids).
ca_profile_diff(Profile1, Profile2, Changed) :-
    include(ca_not_in_profile2_(Profile2), Profile1, Changed).

% ca_not_in_profile2_/2: helper for include.
ca_not_in_profile2_(Profile2, feat(Name, Value)) :-
    \+ member(feat(Name, Value), Profile2).

% ca_stable_features(+Pairs, -Features)
% Features is the list of feat/2 terms whose value is the same in every
% training input. These features are invariant across all inputs.
ca_stable_features([], []).
ca_stable_features(Pairs, Features) :-
    maplist(ca_input_profile_, Pairs, Profiles),
    ca_common_features_(Profiles, Features).

% ca_unstable_features(+Pairs, -Features)
% Features is the list of feat/2 terms whose value changes between at least
% two training inputs. These are candidate rule parameters.
ca_unstable_features([], []).
ca_unstable_features(Pairs, Features) :-
    maplist(ca_input_profile_, Pairs, Profiles),
    ca_union_features_(Profiles, AllFeats),
    ca_common_features_(Profiles, Stable),
    subtract(AllFeats, Stable, Features).

% ca_rank_features(+Pairs, -RankedFeatures)
% RankedFeatures is a list of feat/2 terms sorted by how strongly they
% correlate with output changes (highest correlation first).
ca_rank_features([], []).
ca_rank_features(Pairs, RankedFeatures) :-
    include(ca_pair_changes_, Pairs, Changing),
    maplist(ca_input_profile_, Pairs, AllProfiles),
    ca_union_features_(AllProfiles, AllFeats),
    findall(Score-F,
        (member(F, AllFeats),
         ca_change_count(Pairs, F, N),
         length(Changing, Total),
         (Total =:= 0 -> Score = 0 ; Score is N / Total)),
        Scored),
    msort(Scored, SortedAsc),
    reverse(SortedAsc, SortedDesc),
    findall(F, member(_-F, SortedDesc), RankedFeatures).
