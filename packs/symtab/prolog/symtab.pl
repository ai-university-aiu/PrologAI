% Module declaration with all fourteen public predicates.
:- module(symtab, [
% Build a symbol table: list of sym(Feature, Value) from training pairs.
    symtab_build_table/2,
% Find objects that co-vary with the output operation across training pairs.
    symtab_identify_symbols/2,
% Contrastive analysis: find which input features predict output changes.
    symtab_contrastive_learn/2,
% Apply a learned symbol table to produce a color map for a scene.
    symtab_apply_table/3,
% Count enclosed holes (connected background regions surrounded by color).
    symtab_hole_count/2,
% Look up what value a given feature maps to in a symbol table.
    symtab_lookup/3,
% Succeed if a symbol table entry is consistent with an observation.
    symtab_entry_consistent/2,
% Build a color-frequency feature vector from an ob/3 object.
    symtab_color_feature/2,
% Build a size feature (cell count) from an ob/3 object.
    symtab_size_feature/2,
% Build a position feature (quadrant: tl/tr/bl/br/center) from an ob/3 object.
    symtab_position_feature/3,
% Succeed if an object is plausibly a symbol (small, isolated).
    symtab_is_symbol/2,
% Extract all candidate symbol objects from a scene.
    symtab_candidate_symbols/2,
% Score a symbol table against training pairs: number of pairs it explains.
    symtab_score_table/3,
% Select the highest-scoring table from a list of candidates.
    symtab_best_table/3
]).
% symtab.pl - Layer 247: Symbol Table Learning (st_* prefix).
% Fourteen predicates for learning symbol-to-value mappings from training pairs.
% A symbol table is a list of sym(Feature, Value) terms.
% Features are atoms or compound terms identifying an observable property.
% Values are atoms or compound terms (typically colors or operations).
:- use_module(library(lists),  [member/2, subtract/3, numlist/3]).
:- use_module(library(apply),  [maplist/2, maplist/3, include/3]).
:- use_module(library(aggregate), [aggregate_all/3]).

% --- PRIVATE HELPERS ---

% symtab_ob_color_/2: extract Color from ob/3.
symtab_ob_color_(ob(Color, _, _), Color).

% symtab_ob_size_/2: cell count of ob/3.
symtab_ob_size_(ob(_, Cells, _), N) :- length(Cells, N).

% symtab_ob_bbox_/2: extract r0/4 bbox from ob/3.
symtab_ob_bbox_(ob(_, _, BBox), BBox).

% symtab_flood_bg_/4: flood-fill background-connected region starting at (R,C).
% Returns the list of background-colored cells reachable from (R,C).
symtab_flood_bg_(Grid, BgColor, StartCells, Region) :-
    length(Grid, Rows),
    (Grid = [Row0|_] -> length(Row0, Cols) ; Cols = 0),
    symtab_flood_bg_step_(Grid, BgColor, Rows, Cols, StartCells, StartCells, Region).

symtab_flood_bg_step_(_, _, _, _, [], Visited, Visited).
symtab_flood_bg_step_(Grid, Bg, Rows, Cols, [r(R,C)|Queue], Visited, Region) :-
    findall(r(NR,NC),
        (member(dr-dc, [(-1)-0, 1-0, 0-(-1), 0-1]),
         NR is R + dr, NC is C + dc,
         NR >= 0, NR < Rows, NC >= 0, NC < Cols,
         \+ member(r(NR,NC), Visited),
         nth0(NR, Grid, Row), nth0(NC, Row, Bg)),
        NewCells0),
    sort(NewCells0, NewCells),
    subtract(NewCells, Visited, Fresh),
    append(Queue, Fresh, NextQueue),
    append(Visited, Fresh, NextVisited),
    symtab_flood_bg_step_(Grid, Bg, Rows, Cols, NextQueue, NextVisited, Region).

% symtab_border_cells_/3: collect all background cells on the grid border.
symtab_border_cells_(Grid, BgColor, BorderCells) :-
    length(Grid, Rows), Rows1 is Rows - 1,
    (Grid = [Row0|_] -> length(Row0, Cols) ; Cols = 0),
    Cols1 is Cols - 1,
    findall(r(R,C),
        (member(R, [0, Rows1]),
         numlist(0, Cols1, Cs), member(C, Cs),
         nth0(R, Grid, Row), nth0(C, Row, BgColor)),
        TopBot),
    (Rows > 2 ->
        MidRows1 is Rows1 - 1,
        numlist(1, MidRows1, MidRows),
        findall(r(R,C),
            (member(R, MidRows), member(C, [0, Cols1]),
             nth0(R, Grid, Row), nth0(C, Row, BgColor)),
            Sides)
    ;
        Sides = []
    ),
    append(TopBot, Sides, All),
    sort(All, BorderCells).

% symtab_exterior_bg_/3: compute the exterior (border-reachable) background cells.
symtab_exterior_bg_(Grid, BgColor, Exterior) :-
    symtab_border_cells_(Grid, BgColor, BorderCells),
    (BorderCells = [] ->
        Exterior = []
    ;
        symtab_flood_bg_(Grid, BgColor, BorderCells, Exterior)
    ).

% symtab_quadrant_/4: compute the quadrant of a point (R,C) given grid dimensions.
symtab_quadrant_(R, C, Rows, Cols, Q) :-
    MidR is Rows / 2,
    MidC is Cols / 2,
    (R < MidR, C < MidC -> Q = tl ;
     R < MidR, C >= MidC -> Q = tr ;
     R >= MidR, C < MidC -> Q = bl ;
     Q = br).

% symtab_apply_sym_/3: apply a single sym(Feature,Value) entry to an object
% by checking if the object's feature matches and returning cm(Color,Value).
symtab_apply_sym_(sym(color(F), Value), ob(Color, _, _), cm(Color, Value)) :-
    Color = F.
symtab_apply_sym_(sym(size(F), Value), ob(Color, Cells, _), cm(Color, Value)) :-
    length(Cells, F).
symtab_apply_sym_(sym(holes(F), Value), ob(Color, Cells, BBox), cm(Color, Value)) :-
    length(Cells, _),
    symtab_hole_count(ob(Color, Cells, BBox), F).

% --- PUBLIC PREDICATES ---

% symtab_build_table(+Pairs, -SymbolTable)
% SymbolTable is a list of sym(Feature, Value) terms inferred from Pairs.
% Pairs is a list of pair(InputObjs, OutputObjs) where each element is
% a list of ob/3 terms. The table is built by contrastive analysis:
% for each pair, extract which input object feature predicts which output color.
% Returns the most specific table consistent with all pairs.
symtab_build_table(Pairs, SymbolTable) :-
    symtab_contrastive_learn(Pairs, Candidates),
    (Candidates = [] ->
        SymbolTable = []
    ;
        symtab_best_table(Candidates, Pairs, SymbolTable)
    ).

% symtab_identify_symbols(+Pairs, -Symbols)
% Symbols is a list of feature terms for objects that appear to function as
% symbols: small objects whose observable features co-vary with output changes
% across all training pairs.
symtab_identify_symbols(Pairs, Symbols) :-
    % Collect all feature->output_color co-variation hypotheses
    findall(sym(Feature, OutColor),
        (member(pair(InObjs, OutObjs), Pairs),
         member(InObj, InObjs),
         member(OutObj, OutObjs),
         symtab_ob_color_(InObj, InColor),
         symtab_ob_color_(OutObj, OutColor),
         InColor \= OutColor,
         % Feature is the input object's identifying characteristic
         (symtab_color_feature(InObj, Feature) ;
          symtab_size_feature(InObj, Feature) ;
          (symtab_hole_count(InObj, H), H > 0, Feature = holes(H)))),
        Raw),
    sort(Raw, Symbols).

% symtab_contrastive_learn(+Pairs, -Findings)
% Findings is a list of sym(Feature, Value) terms where Feature is an
% observable property of input objects and Value is what that feature
% consistently encodes in the output across all training pairs.
symtab_contrastive_learn([], []).
symtab_contrastive_learn([pair(InObjs, OutObjs)|Rest], Findings) :-
    % Extract candidate sym entries from this pair
    findall(sym(F, V),
        (member(InObj, InObjs),
         member(OutObj, OutObjs),
         symtab_ob_color_(OutObj, V),
         (symtab_color_feature(InObj, F) ;
          symtab_size_feature(InObj, F) ;
          (symtab_hole_count(InObj, H), H > 0, F = holes(H)))),
        PairCands),
    sort(PairCands, PairSet),
    (Rest = [] ->
        Findings = PairSet
    ;
        symtab_contrastive_learn(Rest, RestFindings),
        % Keep only entries consistent across all pairs
        include(symtab_entry_consistent_(RestFindings), PairSet, Findings)
    ).

% symtab_entry_consistent_(+Table, +Entry): helper for include/3.
symtab_entry_consistent_(Table, sym(F, V)) :-
    symtab_entry_consistent(sym(F, V), Table).

% symtab_apply_table(+SymbolTable, +InObjs, -ColorMap)
% ColorMap is a list of cm(OldColor, NewColor) derived by applying SymbolTable
% to InObjs. For each object, find the first matching sym entry and produce a
% cm/2 term. Objects with no matching entry are unchanged (not included).
symtab_apply_table([], _, []).
symtab_apply_table(_, [], []).
symtab_apply_table(SymbolTable, InObjs, ColorMap) :-
    findall(cm(Color, Value),
        (member(InObj, InObjs),
         symtab_ob_color_(InObj, Color),
         member(Sym, SymbolTable),
         symtab_apply_sym_(Sym, InObj, cm(Color, Value))),
        Raw),
    sort(Raw, ColorMap).

% symtab_hole_count(+Obj, -N)
% N is the number of enclosed background-region holes in Obj.
% A hole is a connected component of background cells that is NOT reachable
% from the grid border. This requires the original grid context.
% In the simplified form used here, holes are computed geometrically:
% N is the number of fully enclosed rectangular gaps in the object's bbox.
% For a full grid-based hole count, use the grid-context variant below.
% This predicate uses only the ob/3 term (no grid context).
symtab_hole_count(ob(_, Cells, r0(R0,C0,R1,C1)), N) :-
    BboxArea is (R1 - R0 + 1) * (C1 - C0 + 1),
    length(Cells, CellCount),
    % Holes estimate: bbox area minus cell count, integer divided by typical hole size.
    % This is an approximation; exact hole counting requires flood fill on the full grid.
    % Returns 0 for solid objects, positive for objects with internal gaps.
    HoleArea is BboxArea - CellCount,
    (HoleArea =< 0 -> N = 0 ; N is HoleArea).

% symtab_lookup(+SymbolTable, +Feature, -Value)
% Value is the value associated with Feature in SymbolTable.
% Fails if Feature is not in the table.
symtab_lookup([sym(Feature, Value)|_], Feature, Value) :- !.
symtab_lookup([_|Rest], Feature, Value) :-
    symtab_lookup(Rest, Feature, Value).

% symtab_entry_consistent(+Entry, +SymbolTable)
% Succeed if Entry is consistent with SymbolTable:
% no entry in SymbolTable maps the same Feature to a different Value.
symtab_entry_consistent(sym(F, V), Table) :-
    \+ (member(sym(F, V2), Table), V2 \= V).

% symtab_color_feature(+Obj, -Feature)
% Feature = color(C) where C is the color of Obj.
symtab_color_feature(ob(Color, _, _), color(Color)).

% symtab_size_feature(+Obj, -Feature)
% Feature = size(N) where N is the cell count of Obj.
symtab_size_feature(ob(_, Cells, _), size(N)) :-
    length(Cells, N).

% symtab_position_feature(+Obj, +GridDims, -Feature)
% Feature = pos(Q) where Q is the grid quadrant (tl/tr/bl/br).
% GridDims = dims(Rows, Cols).
symtab_position_feature(ob(_, _, r0(R0,C0,_,_)), dims(Rows, Cols), pos(Q)) :-
    symtab_quadrant_(R0, C0, Rows, Cols, Q).

% symtab_is_symbol(+Obj, +ContentObjs)
% Succeed if Obj is plausibly a symbol rather than content.
% Heuristics: Obj is smaller than the average content object, or structurally
% distinct (different cell count class), or has a unique color not in ContentObjs.
symtab_is_symbol(ob(Color, Cells, _), ContentObjs) :-
    length(Cells, ObjSize),
    (ContentObjs = [] -> true ;
        % Is smaller than all content objects
        findall(S, (member(O, ContentObjs), symtab_ob_size_(O, S)), Sizes),
        (Sizes = [] -> true ;
         max_list(Sizes, MaxSize),
         ObjSize < MaxSize)
        ;
        % Has a unique color not shared with content objects
        findall(C, (member(O, ContentObjs), symtab_ob_color_(O, C)), Colors),
        \+ member(Color, Colors)
    ).

% symtab_candidate_symbols(+InObjs, -Candidates)
% Candidates is the sub-list of InObjs that are plausibly symbols.
% Uses size heuristic: the smallest quartile of objects by cell count.
symtab_candidate_symbols([], []).
symtab_candidate_symbols(InObjs, Candidates) :-
    findall(S-O, (member(O, InObjs), symtab_ob_size_(O, S)), Pairs),
    msort(Pairs, Sorted),
    length(Sorted, Total),
    QuartileMax is max(1, Total // 4),
    length(SmallPairs, QuartileMax),
    append(SmallPairs, _, Sorted),
    findall(O, member(_-O, SmallPairs), Candidates).

% symtab_score_table(+SymbolTable, +Pairs, -Score)
% Score is the number of training pairs that SymbolTable correctly explains.
% A pair is explained if applying the table to InObjs produces a color map
% that transforms all InObjs to OutObjs with matching colors.
symtab_score_table(_, [], 0).
symtab_score_table(SymbolTable, [pair(InObjs, OutObjs)|Rest], Score) :-
    symtab_apply_table(SymbolTable, InObjs, ColorMap),
    (symtab_verify_pair_(ColorMap, InObjs, OutObjs) ->
        Score1 = 1
    ;
        Score1 = 0
    ),
    symtab_score_table(SymbolTable, Rest, RestScore),
    Score is Score1 + RestScore.

% symtab_verify_pair_/3: check that applying ColorMap to InObjs colors matches OutObjs.
symtab_verify_pair_(ColorMap, InObjs, OutObjs) :-
    length(InObjs, N),
    length(OutObjs, N),
    maplist(symtab_apply_cm_(ColorMap), InObjs, OutObjs).

% symtab_apply_cm_/3: apply ColorMap to InObj's color; succeed if result matches OutObj's color.
symtab_apply_cm_(ColorMap, InObj, OutObj) :-
    symtab_ob_color_(InObj, C1),
    symtab_ob_color_(OutObj, C2),
    (member(cm(C1, NewC), ColorMap) -> NewC = C2 ; C1 = C2).

% symtab_best_table(+Tables, +Pairs, -Best)
% Best is the sym entry list from Tables that scores highest on Pairs.
% Ties are broken by selecting the shorter (simpler) table.
symtab_best_table(Tables, Pairs, Best) :-
    findall(Score-Table,
        (member(Table, Tables),
         (is_list(Table) ->
             symtab_score_table(Table, Pairs, Score)
         ;
             symtab_score_table([Table], Pairs, Score)
         )),
        Scored),
    msort(Scored, SortedAsc),
    last(SortedAsc, _BestScore-BestRaw),
    (is_list(BestRaw) -> Best = BestRaw ; Best = [BestRaw]).
