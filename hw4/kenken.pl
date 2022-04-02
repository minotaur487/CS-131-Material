kenken(N, C, T) :-
    fd_grid_size(N, T),
    maplist(fd_all_different, T),
    transpose(T, Transposed_T),
    maplist(fd_all_different, Transposed_T),
    fd_apply_constraints(T, C),
    labeling(T).

kenken_testcase(
  6,
  [
   +(11, [[1|1], [2|1]]),
   /(2, [[1|2], [1|3]]),
   *(20, [[1|4], [2|4]]),
   *(6, [[1|5], [1|6], [2|6], [3|6]]),
   -(3, [[2|2], [2|3]]),
   /(3, [[2|5], [3|5]]),
   *(240, [[3|1], [3|2], [4|1], [4|2]]),
   *(6, [[3|3], [3|4]]),
   *(6, [[4|3], [5|3]]),
   +(7, [[4|4], [5|4], [5|5]]),
   *(30, [[4|5], [4|6]]),
   *(6, [[5|1], [5|2]]),
   +(9, [[5|6], [6|6]]),
   +(8, [[6|1], [6|2], [6|3]]),
   /(2, [[6|4], [6|5]])
  ]
).

kenken_repeated_testcase(
    4, [
   +(6, [[1|1], [1|2], [2|1]]),
   *(96, [[1|3], [1|4], [2|2], [2|3], [2|4]]),
   -(1, [[3|1], [3|2]]),
   -(1, [[4|1], [4|2]]),
   +(8, [[3|3], [4|3], [4|4]]),
   *(2, [[3|4]])
  ]).

plain_kenken_testcase(
  4,
  [
   +(10, [[1|1], [1|2], [2|2], [3|2]]),
   *(24, [[2|1], [3|1], [4|1]]),
   -(1, [[1|3], [1|4]]),
   /(4, [[2|3], [2|4]]),
   +(3, [[4|2], [4|3]]),
   +(6, [[3|3], [3|4], [4|4]])
  ]).

% % % % % % % % % % % % % % % % % % % % % % % %
    % Set grid boundaries
% % % % % % % % % % % % % % % % % % % % % % % %
labeling([]).
labeling([H|T]) :-
    fd_labeling(H),
    labeling(T).

% % % % % % % % % % % % % % % % % % % % % % % %
    % Grid constraints with FD
% % % % % % % % % % % % % % % % % % % % % % % %
fd_apply_constraints(G, []).
fd_apply_constraints(G, [H|T]) :-
    fd_apply_constraints(G, T),
    fd_constraint(G, H).

fd_constraint(G, +(S, L)) :-
    fd_sum(G, +(S, L), S).
fd_constraint(G, *(M, L)) :-
    fd_mult(G, *(M, L), M).
fd_constraint(G, -(D, L)) :-
    fd_diff(G, -(D, L)).
fd_constraint(G, /(Div, L)) :-
    fd_div(G, /(Div, L)).

fd_sum(G, +(S, []), 0).
fd_sum(G, +(S, [[I|J]|T]), Sum) :-
    access_index(G, I, J, Val),
    fd_sum(G, +(S, T), Running_sum),
    Sum #= Val + Running_sum.

fd_mult(G, *(M, [[I|J]|[]]), Result) :-
    access_index(G, I, J, Val),
    Result #= Val.
fd_mult(G, *(M, []), 0).
fd_mult(G, *(M, [[I|J]|T]), Result) :-
    access_index(G, I, J, Val),
    fd_mult(G, *(M, T), Running_result),
    Result #= Val * Running_result.

fd_diff(G, -(D, [[I1|J1], [I2|J2]])) :-
    access_index(G, I1, J1, Val1),
    access_index(G, I2, J2, Val2),
    (D #= Val2 - Val1; D #= Val1 - Val2).

fd_div(G, /(Q, [[I1|J1], [I2|J2]])) :-
    access_index(G, I1, J1, Val1),
    access_index(G, I2, J2, Val2),
    (Q #= Val2 / Val1; Q #= Val1 / Val2).

access_index(G, I, J, Val) :-
    nth(I, G, Row),
    nth(J, Row, Val).

% % % % % % % % % % % % % % % % % % % % % % % %
    % Checks if the rows of the grid
    % are the right length
% % % % % % % % % % % % % % % % % % % % % % % %
fd_grid_size(N, T) :-
    length(T, N),
    maplist(fd_row_length(N), T).

fd_row_length(N, Row) :-
    length(Row, N),
    fd_domain(Row, 1, N).

% https://github.com/CS131-TA-team/UCLA_CS131_CodeHelp/blob/master/Prolog/sudoku_cell.pl#L28-L34
% This is SWI-prolog's old implementation
% https://stackoverflow.com/questions/4280986/how-to-transpose-a-matrix-in-prolog
transpose([], []).
transpose([F|Fs], Ts) :-
    transpose(F, [F|Fs], Ts).
transpose([], _, []).
transpose([_|Rs], Ms, [Ts|Tss]) :-
        lists_firsts_rests(Ms, Ts, Ms1),
        transpose(Rs, Ms1, Tss).
lists_firsts_rests([], [], []).
lists_firsts_rests([[F|Os]|Rest], [F|Fs], [Os|Oss]) :-
        lists_firsts_rests(Rest, Fs, Oss).

% Plain Implementation
plain_kenken(N, C, T) :-
    grid_size(N, T),
    maplist(is_unique(N), T),
    transpose(T, Transposed_T),
    maplist(is_unique(N), Transposed_T),
    apply_constraints(T, C).

grid_size(N, T) :-
    length(T, N),
    maplist(row_length(N), T).
row_length(N, Row) :-
    length(Row, N).

% % % % % % % % % % % % % % % % % % % % % % % %
    % Make sure list is unique
% % % % % % % % % % % % % % % % % % % % % % % %

is_unique(N, List) :-
    length(List, N),
    element_between(N, List),
    list_unique(List).

element_between(N, List) :-
    maplist(between(1, N), List).

list_unique([]).
list_unique([H|T]) :-
    member(H, T), !, false.
list_unique([H|T]) :-
    list_unique(T).

% % % % % % % % % % % % % % % % % % % % % % % %
    % Grid constraints
% % % % % % % % % % % % % % % % % % % % % % % %
apply_constraints(G, []).
apply_constraints(G, [H|T]) :-
    constraint(G, H),
    apply_constraints(G, T).

constraint(G, +(S, L)) :-
    sum(G, +(S, L), S).
constraint(G, *(M, L)) :-
    mult(G, *(M, L), M).
constraint(G, -(D, L)) :-
    diff(G, -(D, L)).
constraint(G, /(Div, L)) :-
    div(G, /(Div, L)).

sum(G, +(S, []), 0).
sum(G, +(S, [[I|J]|T]), Sum) :-
    access_index(G, I, J, Val),
    sum(G, +(S, T), Running_sum),
    Sum is Val + Running_sum.

mult(G, *(M, [[I|J]|[]]), Result) :-
    access_index(G, I, J, Val),
    Result is Val.
mult(G, *(M, []), 0).
mult(G, *(M, [[I|J]|T]), Result) :-
    access_index(G, I, J, Val),
    mult(G, *(M, T), Running_result),
    Result is Val * Running_result.

diff(G, -(D, [[I1|J1], [I2|J2]])) :-
    access_index(G, I1, J1, Val1),
    access_index(G, I2, J2, Val2),
    (D is Val2 - Val1; D is Val1 - Val2).

div(G, /(Q, [[I1|J1], [I2|J2]])) :-
    access_index(G, I1, J1, Val1),
    access_index(G, I2, J2, Val2),
    % (Q is Val2 / Val1; Q is Val1 / Val2).
    (Q =:= Val1 / Val2 ; Q =:= Val2 / Val1).

%                   Performance Comparison
% I used kenken_repeated_testcase, the 4x4 testcase provided on the site, to test the performance of kenken
% and plain_kenken, using statistics/0 and statistics/2 to get memory usage and times.
% The condensed results are shown below.

% Performance of plain_kenken
% Memory                in use 
%    trail  stack        0 Kb   
%    cstr   stack        0 Kb   
%    global stack        2 Kb   
%    local  stack        0 Kb   
%    atom   table     1809 atoms

% Times                 Time Elapsed
%    user   time       1.554 sec
%    system time       0.001 sec
%    cpu    time       1.614 sec
%    real   time       2.627 sec

% Performance of kenken
% Memory                in use
%    trail  stack      0 Kb
%    cstr   stack      0 Kb
%    global stack      2 Kb
%    local  stack      0 Kb
%    atom   table   1809 atoms

% Times              Time Elapsed
%    user   time       0.000 sec
%    system time       0.000 sec
%    cpu    time       0.000 sec
%    real   time       1.545 sec

% Noop Kenken
% API: noop_kenken(N, C_mod, T, C).
% N = The integer that defines the length and width of the kenken grid.
% C_mod = This is like the constaints list C for kenken and plain_kenken except it doesn't have the
% operations. Specifically, the format would be [(N1, [[I1|J1], [I2|J3]]),...,(NX, [[I5|J5], [I3|I5]])]
% T = The answer grid(s) that get produced by noop_kenken. It is a list of lists that has the answers filled in
% for the puzzle. The format would be the same as those produced by kenken and plain_kenken.
% C = This is the complete constraints list C and it has the same format as the C for kenken and plain_kenken.
% It has the correct operation associated with the right set of cells.

% noop_kenken is like kenken except that it needs to solve for the operations that happen, as well.
% When it succeeds, C and T should be filled out. A high level overview of noop_kenken is very similar
% to kenken. Like kenken, noop_kenken will define the dimensions the same and make sure that the
% integers filled in are unique in their respective rows and columns. Where it differs is that to solve
% the puzzle, noop_kenken must figure out the operations in addition to the values of the cells. The
% simplest approach is to try all four operations on each constraint and see which works. Once that is
% done, answer grids for T and constraints with operations for C can be produced. When it is unsuccessful,
% Prolog just says no.

% Example call:
% noop_kenken_testcase(
%     4,
%     [
%         (5, [[1|1], [1|2], [2|1]]),
%         (1, [[1|3], [1|4]]),
%         (1, [[3|1], [4|1]]),
%         (4, [[4|2], [4|3]]),
%         ([[4|4], [3|4]]),
%         [[2|2], [2|3], [2|4], [3|2], [3|3]])
%     ]
% ).
% Expected Results:
% T:  [
%         [1,2,3,4],
%         [2,3,4,1],
%         [3,4,1,2],
%         [4,1,2,3]
%     ]
% C:  [
%         +(5, [[1|1], [1|2], [2|1]]),
%         -(1, [[1|3], [1|4]]),
%         +(7, [[3|1], [4|1]]),
%         /(4, [[4|2], [4|3]]),
%         -(1, [[4|4], [3|4]]),
%         *(48, [[2|2], [2|3], [2|4], [3|2], [3|3]])
%     ]
