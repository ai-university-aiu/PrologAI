:- use_module('../prolog/row_signature').
:- use_module(library(plunit)).

% Test grids used throughout:
% g3:   sequential 3x3; all rows and cols distinct.
% g_dr: 2-column grid with rows 0,2 equal to [1,2].
% g_dc: 3-column grid with cols 0,2 equal to [1,2,5].
% g_pr: 3-row grid where rows 0 and 2 are palindromes.
% g_pc: 2-column grid where column 0 is a palindrome.
% g_an: rows 0 and 1 are anagrams; row 2 is not.
% g_ac: columns 0 and 1 are anagrams.
% g_all: all rows identical.
% g_sym: all rows palindromes; cols 0 and 2 duplicate.
% g_1:  single-cell grid.

g3([[1,2,3],[4,5,6],[7,8,9]]).
g_dr([[1,2],[3,4],[1,2]]).
g_dc([[1,3,1],[2,4,2],[5,6,5]]).
g_pr([[1,2,1],[3,4,5],[6,7,6]]).
g_pc([[1,2],[3,3],[1,5]]).
g_an([[1,2,3],[3,1,2],[4,5,6]]).
g_ac([[1,2],[3,1],[2,3]]).
g_all([[1,2],[1,2],[1,2]]).
g_sym([[1,2,1],[3,4,3],[5,6,5]]).
g_1([[7]]).

:- begin_tests(row_signature).

% row_signature_col_at: extract a single column as a top-to-bottom list.
test(col_at_1) :- g3(G), row_signature_col_at(G, 0, Col), Col = [1,4,7].
test(col_at_2) :- g3(G), row_signature_col_at(G, 1, Col), Col = [2,5,8].
test(col_at_3) :- g3(G), row_signature_col_at(G, 2, Col), Col = [3,6,9].
test(col_at_4) :- g_dr(G), row_signature_col_at(G, 0, Col), Col = [1,3,1].

% row_signature_all_cols: extract all columns.
test(all_cols_1) :- g3(G), row_signature_all_cols(G, Cols), Cols = [[1,4,7],[2,5,8],[3,6,9]].
test(all_cols_2) :- g_dr(G), row_signature_all_cols(G, Cols), Cols = [[1,3,1],[2,4,2]].
test(all_cols_3) :- g_dc(G), row_signature_all_cols(G, Cols), Cols = [[1,2,5],[3,4,6],[1,2,5]].

% row_signature_row_freq: row frequency table sorted by count descending.
test(row_freq_1) :-
    g_dr(G), row_signature_row_freq(G, Freqs),
    Freqs = [[1,2]-2, [3,4]-1].
test(row_freq_2) :-
    g3(G), row_signature_row_freq(G, Freqs), length(Freqs, 3).
test(row_freq_3) :-
    g_all(G), row_signature_row_freq(G, Freqs), Freqs = [[1,2]-3].

% row_signature_col_freq: column frequency table sorted by count descending.
test(col_freq_1) :-
    g_dc(G), row_signature_col_freq(G, Freqs),
    Freqs = [[1,2,5]-2, [3,4,6]-1].
test(col_freq_2) :-
    g3(G), row_signature_col_freq(G, Freqs), length(Freqs, 3).
test(col_freq_3) :-
    g_sym(G), row_signature_col_freq(G, Freqs),
    Freqs = [[1,3,5]-2, [2,4,6]-1].

% row_signature_modal_row: most frequent row; largest row wins on tie.
test(modal_row_1) :- g_dr(G), row_signature_modal_row(G, Row), Row = [1,2].
test(modal_row_2) :- g3(G), row_signature_modal_row(G, Row), Row = [7,8,9].
test(modal_row_3) :- g_all(G), row_signature_modal_row(G, Row), Row = [1,2].

% row_signature_modal_col: most frequent column list; largest column wins on tie.
test(modal_col_1) :- g_dc(G), row_signature_modal_col(G, Col), Col = [1,2,5].
test(modal_col_2) :- g3(G), row_signature_modal_col(G, Col), Col = [3,6,9].
test(modal_col_3) :- g_sym(G), row_signature_modal_col(G, Col), Col = [1,3,5].

% row_signature_uniq_rows: rows that appear exactly once.
test(uniq_rows_1) :- g_dr(G), row_signature_uniq_rows(G, Pairs), Pairs = [1-[3,4]].
test(uniq_rows_2) :- g3(G), row_signature_uniq_rows(G, Pairs), length(Pairs, 3).
test(uniq_rows_3) :- g_all(G), row_signature_uniq_rows(G, Pairs), Pairs = [].

% row_signature_uniq_cols: columns that appear exactly once.
test(uniq_cols_1) :- g_dc(G), row_signature_uniq_cols(G, Pairs), Pairs = [1-[3,4,6]].
test(uniq_cols_2) :- g3(G), row_signature_uniq_cols(G, Pairs), length(Pairs, 3).
test(uniq_cols_3) :- g_sym(G), row_signature_uniq_cols(G, Pairs), Pairs = [1-[2,4,6]].

% row_signature_dup_row_pairs: ordered index pairs of equal rows.
test(dup_row_pairs_1) :- g_dr(G), row_signature_dup_row_pairs(G, Pairs), Pairs = [0-2].
test(dup_row_pairs_2) :- g3(G), row_signature_dup_row_pairs(G, Pairs), Pairs = [].
test(dup_row_pairs_3) :- g_all(G), row_signature_dup_row_pairs(G, Pairs), Pairs = [0-1,0-2,1-2].

% row_signature_dup_col_pairs: ordered index pairs of equal columns.
test(dup_col_pairs_1) :- g_dc(G), row_signature_dup_col_pairs(G, Pairs), Pairs = [0-2].
test(dup_col_pairs_2) :- g3(G), row_signature_dup_col_pairs(G, Pairs), Pairs = [].
test(dup_col_pairs_3) :- g_sym(G), row_signature_dup_col_pairs(G, Pairs), Pairs = [0-2].

% row_signature_row_palindrome: row reads same left-to-right and right-to-left.
test(row_palindrome_1) :- g_pr(G), row_signature_row_palindrome(G, 0).
test(row_palindrome_2) :- g_pr(G), row_signature_row_palindrome(G, 2).
test(row_palindrome_3, [fail]) :- g_pr(G), row_signature_row_palindrome(G, 1).
test(row_palindrome_4) :- g_1(G), row_signature_row_palindrome(G, 0).

% row_signature_col_palindrome: column reads same top-to-bottom and bottom-to-top.
test(col_palindrome_1) :- g_pc(G), row_signature_col_palindrome(G, 0).
test(col_palindrome_2, [fail]) :- g_pc(G), row_signature_col_palindrome(G, 1).
test(col_palindrome_3) :- G = [[3,5],[4,6],[3,7]], row_signature_col_palindrome(G, 0).
test(col_palindrome_4, [fail]) :- g3(G), row_signature_col_palindrome(G, 0).

% row_signature_rows_anagram: rows have same value multiset.
test(rows_anagram_1) :- g_an(G), row_signature_rows_anagram(G, 0, 1).
test(rows_anagram_2, [fail]) :- g_an(G), row_signature_rows_anagram(G, 0, 2).
test(rows_anagram_3) :- g3(G), row_signature_rows_anagram(G, 0, 0).
test(rows_anagram_4, [fail]) :- g3(G), row_signature_rows_anagram(G, 0, 1).

% row_signature_cols_anagram: columns have same value multiset.
test(cols_anagram_1) :- g_ac(G), row_signature_cols_anagram(G, 0, 1).
test(cols_anagram_2, [fail]) :- g3(G), row_signature_cols_anagram(G, 0, 1).
test(cols_anagram_3) :- g_dc(G), row_signature_cols_anagram(G, 0, 2).
test(cols_anagram_4) :- g3(G), row_signature_cols_anagram(G, 0, 0).

:- end_tests(row_signature).
