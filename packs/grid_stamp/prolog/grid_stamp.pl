% Module declaration with all fourteen public predicates.
:- module(grid_stamp, [
% Place a stamp pattern at a specific position (transparent bg).
    grid_stamp_stamp/6,
% Place a stamp at all positions in a list.
    grid_stamp_stamp_all/5,
% Place a single color at a list of positions.
    grid_stamp_scatter/5,
% Find all positions where a pattern matches the grid.
    grid_stamp_find_matches/4,
% Count how many times a pattern appears in the grid.
    grid_stamp_stamp_count/4,
% Pad grid to a target height and width.
    grid_stamp_pad/5,
% Trim all-bg border rows and columns.
    grid_stamp_unpad/3,
% Repeat grid N times horizontally.
    grid_stamp_replicate_h/4,
% Repeat grid N times vertically.
    grid_stamp_replicate_v/4,
% Add a colored border of given thickness.
    grid_stamp_border/5,
% Center grid on a bg canvas of given size.
    grid_stamp_center/5,
% Extract a subgrid of given size at a position.
    grid_stamp_extract/6,
% Replace a rectangle in the grid with a patch (opaque).
    grid_stamp_replace/5,
% Create a blank all-bg canvas.
    grid_stamp_canvas/4
]).
% gridstamp.pl - Layer 238: Grid Stamping and Canvas Operations (gst_* prefix).
% Fourteen predicates for placing patterns on grids, finding pattern matches,
% manipulating grid borders and dimensions, and creating canvases.
% No cross-pack dependencies.
:- use_module(library(lists), [member/2]).

% --- PRIVATE HELPERS ---

% grid_stamp_min_list_/2: minimum value in a non-empty list.
grid_stamp_min_list_([H|T], Min) :- grid_stamp_min_acc_(T, H, Min).
% Base: accumulator holds the minimum.
grid_stamp_min_acc_([], M, M).
% Recursive: update accumulator if new element is smaller.
grid_stamp_min_acc_([H|T], Cur, Min) :-
    (H < Cur -> grid_stamp_min_acc_(T, H, Min) ; grid_stamp_min_acc_(T, Cur, Min)).

% grid_stamp_max_list_/2: maximum value in a non-empty list.
grid_stamp_max_list_([H|T], Max) :- grid_stamp_max_acc_(T, H, Max).
% Base: accumulator holds the maximum.
grid_stamp_max_acc_([], M, M).
% Recursive: update accumulator if new element is larger.
grid_stamp_max_acc_([H|T], Cur, Max) :-
    (H > Cur -> grid_stamp_max_acc_(T, H, Max) ; grid_stamp_max_acc_(T, Cur, Max)).

% grid_stamp_matches_at_/5: succeeds if Pattern exactly matches Grid subgrid at (R0,C0).
% Fails immediately if any cell in Pattern differs from the corresponding Grid cell.
grid_stamp_matches_at_(Grid, Pattern, R0, C0, _Bg) :-
    length(Pattern, PH), PH1 is PH - 1,
% Use \+ to check that no cell differs.
    \+ (between(0, PH1, PR),
        nth0(PR, Pattern, PRow),
        length(PRow, PW), PW1 is PW - 1,
        between(0, PW1, PC),
        nth0(PC, PRow, PV),
        GR is R0 + PR, GC is C0 + PC,
        nth0(GR, Grid, GRow),
        nth0(GC, GRow, GV),
        PV \= GV).

% --- PUBLIC PREDICATES ---

% grid_stamp_canvas(+H, +W, +Bg, -Canvas)
% Create an H-row by W-column grid filled entirely with Bg.
% Canvas is a list of H rows, each a list of W copies of Bg.
grid_stamp_canvas(H, W, Bg, Canvas) :-
% Each row is W copies of Bg; generate H rows.
    findall(Row, (between(1, H, _), findall(Bg, between(1, W, _), Row)), Canvas).

% grid_stamp_stamp(+Grid, +Stamp, +R0, +C0, +Bg, -Result)
% Paste Stamp onto Grid with its top-left corner at row R0, column C0.
% Non-Bg cells in Stamp overwrite the corresponding Grid cells.
% Bg cells in Stamp are transparent: the original Grid cell shows through.
% Stamp cells that fall outside Grid boundaries are silently ignored.
grid_stamp_stamp(Grid, Stamp, R0, C0, Bg, Result) :-
% Determine Grid dimensions.
    length(Grid, GH), GH1 is GH - 1,
    Grid = [GRow0|_], length(GRow0, GW), GW1 is GW - 1,
% Collect all non-bg Stamp cells that land within Grid bounds.
    length(Stamp, SH), SH1 is SH - 1,
    findall(gr(GR,GC,V),
        (between(0, SH1, SR),
         nth0(SR, Stamp, SRow),
         length(SRow, SW), SW1 is SW - 1,
         between(0, SW1, SC),
         nth0(SC, SRow, V), V \= Bg,
         GR is R0 + SR, GC is C0 + SC,
         GR >= 0, GR =< GH1, GC >= 0, GC =< GW1),
        Mods),
% Reconstruct Grid: apply modifications at the noted positions.
    findall(NewRow,
        (between(0, GH1, GR),
         nth0(GR, Grid, OldRow),
         findall(NewV,
             (between(0, GW1, GC),
              nth0(GC, OldRow, OldV),
              (member(gr(GR,GC,MV), Mods) -> NewV = MV ; NewV = OldV)),
             NewRow)),
        Result).

% grid_stamp_stamp_all(+Grid, +Stamp, +Positions, +Bg, -Result)
% Paste Stamp at each r(R,C) position in Positions, left to right.
% Each stamp is applied to the result of the previous stamp.
% Base case: no positions, return Grid unchanged.
grid_stamp_stamp_all(Grid, _, [], _, Grid) :- !.
% Recursive case: stamp at the first position, then recurse.
grid_stamp_stamp_all(Grid, Stamp, [r(R,C)|Rest], Bg, Result) :-
    grid_stamp_stamp(Grid, Stamp, R, C, Bg, Grid1),
    grid_stamp_stamp_all(Grid1, Stamp, Rest, Bg, Result).

% grid_stamp_scatter(+Grid, +Color, +Positions, +Bg, -Result)
% Place Color at every r(R,C) position in Positions.
% Overwrites whatever was at each position (including Bg).
% Positions outside Grid boundaries are silently ignored.
grid_stamp_scatter(Grid, Color, Positions, _Bg, Result) :-
% Determine Grid dimensions.
    length(Grid, GH), GH1 is GH - 1,
    Grid = [GRow0|_], length(GRow0, GW), GW1 is GW - 1,
% Reconstruct grid: replace cell with Color if it appears in Positions.
    findall(NewRow,
        (between(0, GH1, R),
         nth0(R, Grid, OldRow),
         findall(NewV,
             (between(0, GW1, C),
              nth0(C, OldRow, OldV),
              (member(r(R,C), Positions) -> NewV = Color ; NewV = OldV)),
             NewRow)),
        Result).

% grid_stamp_find_matches(+Grid, +Pattern, +Bg, -Matches)
% Matches is the list of r(R,C) positions where Pattern exactly matches
% the Grid subgrid of the same size, with the top-left at (R,C).
% Pattern must be non-empty and fit within Grid.
grid_stamp_find_matches(Grid, Pattern, Bg, Matches) :-
    length(Grid, GH),
    Grid = [GRow0|_], length(GRow0, GW),
    length(Pattern, PH),
    Pattern = [PRow0|_], length(PRow0, PW),
    MaxR is GH - PH, MaxC is GW - PW,
    (MaxR < 0 -> Matches = [] ;
     MaxC < 0 -> Matches = [] ;
% Collect all top-left positions where the pattern matches.
     findall(r(R,C),
         (between(0, MaxR, R),
          between(0, MaxC, C),
          grid_stamp_matches_at_(Grid, Pattern, R, C, Bg)),
         Matches)).

% grid_stamp_stamp_count(+Grid, +Pattern, +Bg, -Count)
% Count the number of positions where Pattern matches in Grid.
grid_stamp_stamp_count(Grid, Pattern, Bg, Count) :-
% Find all matches, then count them.
    grid_stamp_find_matches(Grid, Pattern, Bg, Matches),
    length(Matches, Count).

% grid_stamp_pad(+Grid, +H, +W, +Bg, -Result)
% Pad Grid with Bg to reach at least H rows and W columns.
% Grid is anchored at the top-left; extra rows appended below, extra cols to right.
% If Grid already meets or exceeds the target, it is returned unchanged.
grid_stamp_pad(Grid, H, W, Bg, Result) :-
    length(Grid, GH),
    (GH > 0 -> Grid = [GRow0|_], length(GRow0, GW) ; GW = 0),
    ExtraRows is max(0, H - GH),
    ExtraCols is max(0, W - GW),
% Pad each existing row with ExtraCols bg cells to the right.
    findall(NewRow,
        (member(Row, Grid),
         findall(Bg, between(1, ExtraCols, _), ColPad),
         append(Row, ColPad, NewRow)),
        PaddedRows),
% Build ExtraRows new rows each of width max(W, GW).
    TotalW is max(W, GW),
    findall(Row,
        (between(1, ExtraRows, _),
         findall(Bg, between(1, TotalW, _), Row)),
        ExtraRowsList),
    append(PaddedRows, ExtraRowsList, Result).

% grid_stamp_unpad(+Grid, +Bg, -Result)
% Remove all-Bg border rows and columns from Grid.
% Result is the tightest bounding box containing all non-Bg cells.
% If Grid is all-Bg or empty, Result is [].
grid_stamp_unpad(Grid, Bg, Result) :-
    (Grid = [] -> Result = [] ;
     length(Grid, H), H1 is H - 1,
     Grid = [GRow0|_], length(GRow0, W), W1 is W - 1,
% Collect rows and cols of all non-bg cells.
     findall(R,
         (between(0, H1, R), nth0(R, Grid, Row), member(V, Row), V \= Bg),
         Rs),
     (Rs = [] -> Result = [] ;
      findall(C,
          (between(0, H1, R), nth0(R, Grid, Row),
           between(0, W1, C), nth0(C, Row, V), V \= Bg),
          Cs),
      grid_stamp_min_list_(Rs, MinR), grid_stamp_max_list_(Rs, MaxR),
      grid_stamp_min_list_(Cs, MinC), grid_stamp_max_list_(Cs, MaxC),
% Extract the bounding rectangle.
      findall(CRow,
          (between(MinR, MaxR, R),
           nth0(R, Grid, Row),
           findall(V, (between(MinC, MaxC, C), nth0(C, Row, V)), CRow)),
          Result))).

% grid_stamp_replicate_h(+Grid, +N, +Bg, -Result)
% Repeat Grid N times side by side horizontally.
% Each row of Result is the concatenation of N copies of the corresponding Grid row.
grid_stamp_replicate_h(Grid, N, _Bg, Result) :-
    length(Grid, H), H1 is H - 1,
% For each row, build N repetitions by iterating N times through the row elements.
    findall(Row,
        (between(0, H1, R),
         nth0(R, Grid, GRow),
         findall(V, (between(1, N, _), member(V, GRow)), Row)),
        Result).

% grid_stamp_replicate_v(+Grid, +N, +Bg, -Result)
% Repeat Grid N times stacked vertically.
% Result is N copies of Grid appended top to bottom.
grid_stamp_replicate_v(Grid, N, _Bg, Result) :-
% Each copy of Grid contributes all its rows; N repetitions stacked.
    findall(Row, (between(1, N, _), member(Row, Grid)), Result).

% grid_stamp_border(+Grid, +BorderColor, +T, +Bg, -Result)
% Add a border of BorderColor cells of thickness T around Grid.
% Result has height GH+2*T and width GW+2*T.
grid_stamp_border(Grid, BorderColor, T, _Bg, Result) :-
    Grid = [GRow0|_], length(GRow0, GW),
    NewW is GW + 2*T,
% Build T top border rows of NewW BorderColor cells each.
    findall(Row, (between(1, T, _), findall(BorderColor, between(1, NewW, _), Row)), TopRows),
% Build middle rows: each Grid row padded with T BorderColor on each side.
    findall(Row,
        (member(GR, Grid),
         findall(BorderColor, between(1, T, _), LeftPad),
         findall(BorderColor, between(1, T, _), RightPad),
         append(LeftPad, GR, Tmp), append(Tmp, RightPad, Row)),
        MiddleRows),
% Build T bottom border rows.
    findall(Row, (between(1, T, _), findall(BorderColor, between(1, NewW, _), Row)), BottomRows),
% Assemble: top + middle + bottom.
    append(TopRows, MiddleRows, Tmp2), append(Tmp2, BottomRows, Result).

% grid_stamp_center(+Grid, +H, +W, +Bg, -Result)
% Place Grid on a H x W canvas of Bg, centered.
% If Grid is smaller than H x W, the surplus is filled with Bg.
% Integer division determines the top-left position of Grid.
grid_stamp_center(Grid, H, W, Bg, Result) :-
    length(Grid, GH),
    Grid = [GRow0|_], length(GRow0, GW),
% Compute top-left insertion point using integer division.
    R0 is (H - GH) // 2,
    C0 is (W - GW) // 2,
    H1 is H - 1, W1 is W - 1,
% Build result: each cell comes from Grid if in bounds, else Bg.
    findall(NewRow,
        (between(0, H1, R),
         findall(NewV,
             (between(0, W1, C),
              SR is R - R0, SC is C - C0,
              (SR >= 0, SR < GH, SC >= 0, SC < GW ->
                  nth0(SR, Grid, GRow), nth0(SC, GRow, NewV)
              ;
                  NewV = Bg
              )),
             NewRow)),
        Result).

% grid_stamp_extract(+Grid, +R0, +C0, +H, +W, -Subgrid)
% Extract an H x W subgrid from Grid with its top-left at (R0, C0).
% Rows and columns outside Grid bounds return Bg (not implemented here: assumes in bounds).
grid_stamp_extract(Grid, R0, C0, H, W, Subgrid) :-
    R1 is R0 + H - 1, C1 is C0 + W - 1,
% Collect rows R0..R1, columns C0..C1 from Grid.
    findall(SubRow,
        (between(R0, R1, R),
         nth0(R, Grid, Row),
         findall(V, (between(C0, C1, C), nth0(C, Row, V)), SubRow)),
        Subgrid).

% grid_stamp_replace(+Grid, +R0, +C0, +Patch, -Result)
% Replace the rectangle at (R0,C0) in Grid with Patch (opaque: all cells overwritten).
% Patch cells that fall outside Grid bounds are silently ignored.
grid_stamp_replace(Grid, R0, C0, Patch, Result) :-
    length(Grid, GH), GH1 is GH - 1,
    Grid = [GRow0|_], length(GRow0, GW), GW1 is GW - 1,
    length(Patch, PH), PH1 is PH - 1,
% Build result: for rows/cols in Patch range, use Patch values; else keep original.
    findall(NewRow,
        (between(0, GH1, R),
         nth0(R, Grid, OldRow),
         PR is R - R0,
         (PR >= 0, PR =< PH1 ->
             nth0(PR, Patch, PRow),
             length(PRow, PW), PW1 is PW - 1,
             findall(NewV,
                 (between(0, GW1, C),
                  nth0(C, OldRow, OldV),
                  PC is C - C0,
                  (PC >= 0, PC =< PW1 ->
                      nth0(PC, PRow, NewV)
                  ;
                      NewV = OldV
                  )),
                 NewRow)
         ;
             NewRow = OldRow
         )),
        Result).
