[[1,2,3,4],[3,4,2,1],[4,3,1,2],[2,1,4,3]]
+(6, [[1|1], [1|2], [2|1]])

[[5,6,3,4,1,2], [6,1,4,5,2,3], [4,5,2,3,6,1], [3,4,1,2,5,6], [2,3,6,1,4,5], [1,2,5,6,3,4]]

fd_add([[1,2,3,4],[3,4,2,1],[4,3,1,2],[2,1,4,3]], +(6, [[1|1], [1|2], [2|1]]), 6).

kenken_repeated_testcase(N,C),kenken(N,C,T).
plain_kenken_testcase(N,C), kenken(N,C,T).

plain_kenken_testcase(N,C), plain_kenken(N,C,T).

fd_mult([[1,2,3,4],[3,4,2,1],[4,3,1,2],[2,1,4,3]], *(6, [[1|2], [2|1]]), 6).
fd_mult([[1,2,3,4],[3,4,2,1],[4,3,1,2],[2,1,4,3]], *(0, []), 0).

fd_div([[1,2,3,4],[3,4,2,1],[4,3,1,2],[2,1,4,3]], /(0, [[1|1], [1|2]])).
fd_div([[1,2,3,4],[3,4,2,1],[4,3,1,2],[2,1,4,3]], /(2, [[1|1], [1|2]])).


statistics(user_time, [SinceStart|_]),
kenken_repeated_testcase(N,C), plain_kenken(N,C,T),
statistics(user_time, [SinceLast|_]).

statistics(system_time, [SinceStart|_]),
kenken_repeated_testcase(N,C), plain_kenken(N,C,T),
statistics(system_time, [SinceLast|_]).

statistics(cpu_time, [SinceStart|_]),
kenken_repeated_testcase(N,C), plain_kenken(N,C,T),
statistics(cpu_time, [SinceLast|_]).

statistics(real_time, [SinceStart|_]),
kenken_repeated_testcase(N,C), plain_kenken(N,C,T),
statistics(real_time, [SinceLast|_]).

statistics(local_stack, [SinceStart|_]),
kenken_repeated_testcase(N,C), plain_kenken(N,C,T),
statistics(local_stack, [SinceLast|_]).

statistics(global_stack, [SinceStart|_]),
kenken_repeated_testcase(N,C), plain_kenken(N,C,T),
statistics(global_stack, [SinceLast|_]).

statistics(trail_stack, [SinceStart|_]),
kenken_repeated_testcase(N,C), plain_kenken(N,C,T),
statistics(trail_stack, [SinceLast|_]).

statistics(cstr_stack, [SinceStart|_]),
kenken_repeated_testcase(N,C), plain_kenken(N,C,T),
statistics(cstr_stack, [SinceLast|_]).

statistics(atoms, [SinceStart|_]),
kenken_repeated_testcase(N,C), plain_kenken(N,C,T),
statistics(atoms, [SinceLast|_]).


statistics(user_time, [SinceStart|_]),
kenken_repeated_testcase(N,C), kenken(N,C,T),
statistics(user_time, [SinceLast|_]).

statistics(system_time, [SinceStart|_]),
kenken_repeated_testcase(N,C), kenken(N,C,T),
statistics(system_time, [SinceLast|_]).

statistics(cpu_time, [SinceStart|_]),
kenken_repeated_testcase(N,C), kenken(N,C,T),
statistics(cpu_time, [SinceLast|_]).

statistics(real_time, [SinceStart|_]),
kenken_repeated_testcase(N,C), kenken(N,C,T),
statistics(real_time, [SinceLast|_]).

statistics(local_stack, [SinceStart|_]),
kenken_repeated_testcase(N,C), kenken(N,C,T),
statistics(local_stack, [SinceLast|_]).

statistics(global_stack, [SinceStart|_]),
kenken_repeated_testcase(N,C), kenken(N,C,T),
statistics(global_stack, [SinceLast|_]).

statistics(trail_stack, [SinceStart|_]),
kenken_repeated_testcase(N,C), kenken(N,C,T),
statistics(trail_stack, [SinceLast|_]).

statistics(cstr_stack, [SinceStart|_]),
kenken_repeated_testcase(N,C), kenken(N,C,T),
statistics(cstr_stack, [SinceLast|_]).

statistics(atoms, [SinceStart|_]),
kenken_repeated_testcase(N,C), kenken(N,C,T),
statistics(atoms, [SinceLast|_]).