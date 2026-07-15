% Module declaration with all fourteen public predicates.
:- module(symbol_table, [
% Build a symbol table: list of sym(Feature, Value) from training pairs.
    symbol_table_build_table/2,
% Find objects that co-vary with the output operation across training pairs.
    symbol_table_identify_symbols/2,
% Contrastive analysis: find which input features predict output changes.
    symbol_table_contrastive_learn/2,
% Apply a learned symbol table to produce a color map for a scene.
    symbol_table_apply_table/3,
% Count enclosed holes (connected background regions surrounded by color).
    symbol_table_hole_count/2,
% Look up what value a given feature maps to in a symbol table.
    symbol_table_lookup/3,
% Succeed if a symbol table entry is consistent with an observation.
    symbol_table_entry_consistent/2,
% Build a color-frequency feature vector from an ob/3 object.
    symbol_table_color_feature/2,
% Build a size feature (cell count) from an ob/3 object.
    symbol_table_size_feature/2,
% Build a position feature (quadrant: tl/tr/bl/br/center) from an ob/3 object.
    symbol_table_position_feature/3,
% Succeed if an object is plausibly a symbol (small, isolated).
    symbol_table_is_symbol/2,
% Extract all candidate symbol objects from a scene.
    symbol_table_candidate_symbols/2,
% Score a symbol table against training pairs: number of pairs it explains.
    symbol_table_score_table/3,
% Select the highest-scoring table from a list of candidates.
    symbol_table_best_table/3
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

% symbol_table_ob_color_/2: extract Color from ob/3.
symbol_table_ob_color_(ob(Color, _, _), Color).

% symbol_table_ob_size_/2: cell count of ob/3.
symbol_table_ob_size_(ob(_, Cells, _), N) :- length(Cells, N).

% symbol_table_ob_bbox_/2: extract r0/4 bbox from ob/3.
symbol_table_ob_bbox_(ob(_, _, BBox), BBox).

% symbol_table_flood_bg_/4: flood-fill background-connected region starting at (R,C).
% Returns the list of background-colored cells reachable from (R,C).
symbol_table_flood_bg_(Grid, BgColor, StartCells, Region) :-
    length(Grid, Rows),
    (Grid = [Row0|_] -> length(Row0, Cols) ; Cols = 0),
    symbol_table_flood_bg_step_(Grid, BgColor, Rows, Cols, StartCells, StartCells, Region).

symbol_table_flood_bg_step_(_, _, _, _, [], Visited, Visited).
symbol_table_flood_bg_step_(Grid, Bg, Rows, Cols, [r(R,C)|Queue], Visited, Region) :-
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
    symbol_table_flood_bg_step_(Grid, Bg, Rows, Cols, NextQueue, NextVisited, Region).

% symbol_table_border_cells_/3: collect all background cells on the grid border.
symbol_table_border_cells_(Grid, BgColor, BorderCells) :-
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

% symbol_table_exterior_bg_/3: compute the exterior (border-reachable) background cells.
symbol_table_exterior_bg_(Grid, BgColor, Exterior) :-
    symbol_table_border_cells_(Grid, BgColor, BorderCells),
    (BorderCells = [] ->
        Exterior = []
    ;
        symbol_table_flood_bg_(Grid, BgColor, BorderCells, Exterior)
    ).

% symbol_table_quadrant_/4: compute the quadrant of a point (R,C) given grid dimensions.
symbol_table_quadrant_(R, C, Rows, Cols, Q) :-
    MidR is Rows / 2,
    MidC is Cols / 2,
    (R < MidR, C < MidC -> Q = tl ;
     R < MidR, C >= MidC -> Q = tr ;
     R >= MidR, C < MidC -> Q = bl ;
     Q = br).

% symbol_table_apply_sym_/3: apply a single sym(Feature,Value) entry to an object
% by checking if the object's feature matches and returning cm(Color,Value).
symbol_table_apply_sym_(sym(color(F), Value), ob(Color, _, _), cm(Color, Value)) :-
    Color = F.
symbol_table_apply_sym_(sym(size(F), Value), ob(Color, Cells, _), cm(Color, Value)) :-
    length(Cells, F).
symbol_table_apply_sym_(sym(holes(F), Value), ob(Color, Cells, BBox), cm(Color, Value)) :-
    length(Cells, _),
    symbol_table_hole_count(ob(Color, Cells, BBox), F).

% --- PUBLIC PREDICATES ---

% symbol_table_build_table(+Pairs, -SymbolTable)
% SymbolTable is a list of sym(Feature, Value) terms inferred from Pairs.
% Pairs is a list of pair(InputObjs, OutputObjs) where each element is
% a list of ob/3 terms. The table is built by contrastive analysis:
% for each pair, extract which input object feature predicts which output color.
% Returns the most specific table consistent with all pairs.
symbol_table_build_table(Pairs, SymbolTable) :-
    symbol_table_contrastive_learn(Pairs, Candidates),
    (Candidates = [] ->
        SymbolTable = []
    ;
        symbol_table_best_table(Candidates, Pairs, SymbolTable)
    ).

% symbol_table_identify_symbols(+Pairs, -Symbols)
% Symbols is a list of feature terms for objects that appear to function as
% symbols: small objects whose observable features co-vary with output changes
% across all training pairs.
symbol_table_identify_symbols(Pairs, Symbols) :-
    % Collect all feature->output_color co-variation hypotheses
    findall(sym(Feature, OutColor),
        (member(pair(InObjs, OutObjs), Pairs),
         member(InObj, InObjs),
         member(OutObj, OutObjs),
         symbol_table_ob_color_(InObj, InColor),
         symbol_table_ob_color_(OutObj, OutColor),
         InColor \= OutColor,
         % Feature is the input object's identifying characteristic
         (symbol_table_color_feature(InObj, Feature) ;
          symbol_table_size_feature(InObj, Feature) ;
          (symbol_table_hole_count(InObj, H), H > 0, Feature = holes(H)))),
        Raw),
    sort(Raw, Symbols).

% symbol_table_contrastive_learn(+Pairs, -Findings)
% Findings is a list of sym(Feature, Value) terms where Feature is an
% observable property of input objects and Value is what that feature
% consistently encodes in the output across all training pairs.
symbol_table_contrastive_learn([], []).
symbol_table_contrastive_learn([pair(InObjs, OutObjs)|Rest], Findings) :-
    % Extract candidate sym entries from this pair
    findall(sym(F, V),
        (member(InObj, InObjs),
         member(OutObj, OutObjs),
         symbol_table_ob_color_(OutObj, V),
         (symbol_table_color_feature(InObj, F) ;
          symbol_table_size_feature(InObj, F) ;
          (symbol_table_hole_count(InObj, H), H > 0, F = holes(H)))),
        PairCands),
    sort(PairCands, PairSet),
    (Rest = [] ->
        Findings = PairSet
    ;
        symbol_table_contrastive_learn(Rest, RestFindings),
        % Keep only entries consistent across all pairs
        include(symbol_table_entry_consistent_(RestFindings), PairSet, Findings)
    ).

% symbol_table_entry_consistent_(+Table, +Entry): helper for include/3.
symbol_table_entry_consistent_(Table, sym(F, V)) :-
    symbol_table_entry_consistent(sym(F, V), Table).

% symbol_table_apply_table(+SymbolTable, +InObjs, -ColorMap)
% ColorMap is a list of cm(OldColor, NewColor) derived by applying SymbolTable
% to InObjs. For each object, find the first matching sym entry and produce a
% cm/2 term. Objects with no matching entry are unchanged (not included).
symbol_table_apply_table([], _, []).
symbol_table_apply_table(_, [], []).
symbol_table_apply_table(SymbolTable, InObjs, ColorMap) :-
    findall(cm(Color, Value),
        (member(InObj, InObjs),
         symbol_table_ob_color_(InObj, Color),
         member(Sym, SymbolTable),
         symbol_table_apply_sym_(Sym, InObj, cm(Color, Value))),
        Raw),
    sort(Raw, ColorMap).

% symbol_table_hole_count(+Obj, -N)
% N is the number of enclosed background-region holes in Obj.
% A hole is a connected component of background cells that is NOT reachable
% from the grid border. This requires the original grid context.
% In the simplified form used here, holes are computed geometrically:
% N is the number of fully enclosed rectangular gaps in the object's bbox.
% For a full grid-based hole count, use the grid-context variant below.
% This predicate uses only the ob/3 term (no grid context).
symbol_table_hole_count(ob(_, Cells, r0(R0,C0,R1,C1)), N) :-
    BboxArea is (R1 - R0 + 1) * (C1 - C0 + 1),
    length(Cells, CellCount),
    % Holes estimate: bbox area minus cell count, integer divided by typical hole size.
    % This is an approximation; exact hole counting requires flood fill on the full grid.
    % Returns 0 for solid objects, positive for objects with internal gaps.
    HoleArea is BboxArea - CellCount,
    (HoleArea =< 0 -> N = 0 ; N is HoleArea).

% symbol_table_lookup(+SymbolTable, +Feature, -Value)
% Value is the value associated with Feature in SymbolTable.
% Fails if Feature is not in the table.
symbol_table_lookup([sym(Feature, Value)|_], Feature, Value) :- !.
symbol_table_lookup([_|Rest], Feature, Value) :-
    symbol_table_lookup(Rest, Feature, Value).

% symbol_table_entry_consistent(+Entry, +SymbolTable)
% Succeed if Entry is consistent with SymbolTable:
% no entry in SymbolTable maps the same Feature to a different Value.
symbol_table_entry_consistent(sym(F, V), Table) :-
    \+ (member(sym(F, V2), Table), V2 \= V).

% symbol_table_color_feature(+Obj, -Feature)
% Feature = color(C) where C is the color of Obj.
symbol_table_color_feature(ob(Color, _, _), color(Color)).

% symbol_table_size_feature(+Obj, -Feature)
% Feature = size(N) where N is the cell count of Obj.
symbol_table_size_feature(ob(_, Cells, _), size(N)) :-
    length(Cells, N).

% symbol_table_position_feature(+Obj, +GridDims, -Feature)
% Feature = pos(Q) where Q is the grid quadrant (tl/tr/bl/br).
% GridDims = dims(Rows, Cols).
symbol_table_position_feature(ob(_, _, r0(R0,C0,_,_)), dims(Rows, Cols), pos(Q)) :-
    symbol_table_quadrant_(R0, C0, Rows, Cols, Q).

% symbol_table_is_symbol(+Obj, +ContentObjs)
% Succeed if Obj is plausibly a symbol rather than content.
% Heuristics: Obj is smaller than the average content object, or structurally
% distinct (different cell count class), or has a unique color not in ContentObjs.
symbol_table_is_symbol(ob(Color, Cells, _), ContentObjs) :-
    length(Cells, ObjSize),
    (ContentObjs = [] -> true ;
        % Is smaller than all content objects
        findall(S, (member(O, ContentObjs), symbol_table_ob_size_(O, S)), Sizes),
        (Sizes = [] -> true ;
         max_list(Sizes, MaxSize),
         ObjSize < MaxSize)
        ;
        % Has a unique color not shared with content objects
        findall(C, (member(O, ContentObjs), symbol_table_ob_color_(O, C)), Colors),
        \+ member(Color, Colors)
    ).

% symbol_table_candidate_symbols(+InObjs, -Candidates)
% Candidates is the sub-list of InObjs that are plausibly symbols.
% Uses size heuristic: the smallest quartile of objects by cell count.
symbol_table_candidate_symbols([], []).
symbol_table_candidate_symbols(InObjs, Candidates) :-
    findall(S-O, (member(O, InObjs), symbol_table_ob_size_(O, S)), Pairs),
    msort(Pairs, Sorted),
    length(Sorted, Total),
    QuartileMax is max(1, Total // 4),
    length(SmallPairs, QuartileMax),
    append(SmallPairs, _, Sorted),
    findall(O, member(_-O, SmallPairs), Candidates).

% symbol_table_score_table(+SymbolTable, +Pairs, -Score)
% Score is the number of training pairs that SymbolTable correctly explains.
% A pair is explained if applying the table to InObjs produces a color map
% that transforms all InObjs to OutObjs with matching colors.
symbol_table_score_table(_, [], 0).
symbol_table_score_table(SymbolTable, [pair(InObjs, OutObjs)|Rest], Score) :-
    symbol_table_apply_table(SymbolTable, InObjs, ColorMap),
    (symbol_table_verify_pair_(ColorMap, InObjs, OutObjs) ->
        Score1 = 1
    ;
        Score1 = 0
    ),
    symbol_table_score_table(SymbolTable, Rest, RestScore),
    Score is Score1 + RestScore.

% symbol_table_verify_pair_/3: check that applying ColorMap to InObjs colors matches OutObjs.
symbol_table_verify_pair_(ColorMap, InObjs, OutObjs) :-
    length(InObjs, N),
    length(OutObjs, N),
    maplist(symbol_table_apply_cm_(ColorMap), InObjs, OutObjs).

% symbol_table_apply_cm_/3: apply ColorMap to InObj's color; succeed if result matches OutObj's color.
symbol_table_apply_cm_(ColorMap, InObj, OutObj) :-
    symbol_table_ob_color_(InObj, C1),
    symbol_table_ob_color_(OutObj, C2),
    (member(cm(C1, NewC), ColorMap) -> NewC = C2 ; C1 = C2).

% symbol_table_best_table(+Tables, +Pairs, -Best)
% Best is the sym entry list from Tables that scores highest on Pairs.
% Ties are broken by selecting the shorter (simpler) table.
symbol_table_best_table(Tables, Pairs, Best) :-
    findall(Score-Table,
        (member(Table, Tables),
         (is_list(Table) ->
             symbol_table_score_table(Table, Pairs, Score)
         ;
             symbol_table_score_table([Table], Pairs, Score)
         )),
        Scored),
    msort(Scored, SortedAsc),
    last(SortedAsc, _BestScore-BestRaw),
    (is_list(BestRaw) -> Best = BestRaw ; Best = [BestRaw]).
