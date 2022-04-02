(* subset tests *)
let subset_test0 = subset [] []
let subset_test1 = subset [1;2] [1;2]
let subset_test2 = subset [1;2] [2;1]
let subset_test3 = subset [1;2] [1;2;3;5]

(* equal tests *)
let equal_sets_test0 = equal_sets [] []
let equal_sets_test1 = equal_sets [1;3] [1;3]
let equal_sets_test2 = not (equal_sets [1;2] [1;3])
let equal_sets_test3 = not (equal_sets [1] [])
let equal_sets_test4 = equal_sets [1] [1]
let equal_sets_test5 = not (equal_sets [] [1])

(* set union tests *)
let set_union_test0 = equal_sets (set_union [] []) []
let set_union_test1 = equal_sets (set_union [1] []) [1]
let set_union_test2 = equal_sets (set_union [] [1]) [1]
let set_union_test3 = equal_sets (set_union [1;2] [1]) [1;2;1]
let set_union_test4 = equal_sets (set_union [1;2] [1;3;4]) [1;2;1;3;4]
let set_union_test5 = equal_sets (set_union [1;2] [1;5]) [1;2;1;5]

(* set all union tests *)
let set_all_union_test0 = equal_sets (set_all_union []) []
let set_all_union_test1 = equal_sets (set_all_union []) [] 
let set_all_union_test2 = equal_sets (set_all_union [[]]) []
let set_all_union_test3 = equal_sets (set_all_union [[1];[2]]) [1;2]
let set_all_union_test4 =
    equal_sets (set_all_union [[1;2];[5;6]]) [1;2;5;6]
let set_all_union_test5 =
    equal_sets (set_all_union [[1]]) [1]
let set_all_union_test6 =
    equal_sets (set_all_union [[1];[]]) [1]
let set_all_union_test7 =
    equal_sets (set_all_union [[1;2;3];[1;2];[9;9;9]]) [1;2;3;9]

(* computed fixed point tests *)
let computed_fixed_point_test0 =
  computed_fixed_point (=) (fun x -> x *. 5.) 1. = infinity
let computed_fixed_point_test1 =
  computed_fixed_point (=) (fun x -> x / 5) 100 = 0
let computed_fixed_point_test2 =
  computed_fixed_point (=) (fun x -> x /. 5.) 100. = 0.
let computed_fixed_point_test3 =
  ((computed_fixed_point (fun x y -> x * y > 10)
			 (fun x -> x * 2)
			 1)
   = 4)
let computed_fixed_point_test4 =
  ((computed_fixed_point (fun x y -> equal_sets x y)
			 (fun x -> if (List.length x = 5)
             then x
             else set_union x [(List.length x)])
			 [])
   = [0;1;2;3;4])

(* computed periodic point tests *)
let computed_periodic_point_test0 =
  computed_periodic_point (=) (fun x -> x) 0 (99) = 99
let computed_periodic_point_test1 =
  computed_periodic_point (=) (fun x -> x * 50) 0 (99) = 99
let computed_periodic_point_test2 =
  computed_periodic_point (=) (fun x -> x * -1) 2 1 = 1
let computed_periodic_point_test3 =
  computed_periodic_point (=) (fun x -> x *. x -. 1.) 2 0.76 = -1.
let computed_periodic_point_test4 =
  computed_periodic_point (fun x y -> equal_sets x y)
  (fun x -> if (List.length x = 5)
  then [99]
  else set_union x [1]) 5 [] = [99]

(* whileseq tests *)
let whileseq_test0 =
    whileseq ((+) 3) ((>) 10) 0 = [0;3;6;9]
let whileseq_test1 =
    whileseq ((-) 1) ((>) 0) 5 = []
let whileseq_test2 =
    whileseq ((+) 1) ((<) 5) 0 = []
let whileseq_test3 =
    whileseq ((-) 1) ((<) 0) 10 = [10]
let whileseq_test4 =
    whileseq ((+) 1) ((>) 5) 0 = [0;1;2;3;4]

(* filter blind alley tests *)
(* Grammar similar to the one in
https://web.cs.ucla.edu/classes/winter22/cs131/hw/hw1.html *)
type awksub_nonterminals =
  | Expr | Lvalue | Incrop | Binop | Num

let awksub_rules =
    [Expr, [T"("; N Expr; T")"];
    Expr, [N Num];
    Expr, [N Num];
    Expr, [N Expr; N Expr; N Expr];
    Expr, [N Expr; N Binop; N Expr];
    Expr, [N Lvalue; N Binop; N Expr];
    Expr, [N Incrop; N Lvalue];
    Expr, [N Lvalue; N Incrop];
    Lvalue, [T"$"; N Expr];
    Incrop, [T"++"];
    Incrop, [T"--"];
    Binop, [T"+"];
    Binop, [T"-"];
    Num, [T"0"];
    Num, [T"1"];
    Num, [T"2"]]

let awksub_rules_with_blind_alleys =
    [Expr, [T"("; N Expr; T")"];
    Expr, [N Num];
    Expr, [N Num];
    Expr, [N Expr; N Expr; N Expr];
    Expr, [N Expr; N Binop; N Expr];
    Expr, [N Lvalue; N Binop; N Expr];
    Expr, [N Incrop; N Lvalue];
    Expr, [N Lvalue; N Incrop];
    Lvalue, [T"$"; N Expr];
    Binop, [T"+"];
    Binop, [T"-"];
    Num, [T"0"];
    Num, [T"1"];
    Num, [T"2"]]

let awksub_grammar = Expr, awksub_rules
let filter_blind_alleys_test0 =
  filter_blind_alleys awksub_grammar = awksub_grammar

let filter_blind_alleys_test1 =
  filter_blind_alleys (Expr, List.tl awksub_rules) = (Expr, List.tl awksub_rules)

let filter_blind_alleys_test2 =
  filter_blind_alleys (Expr, List.tl (List.tl (List.tl (List.tl (List.tl (List.tl awksub_rules))))))
  = (Expr, List.tl (List.tl (List.tl (List.tl (List.tl (List.tl
  (List.tl (List.tl (List.tl awksub_rules)))))))))

let awksub_wba_grammar = Expr, awksub_rules_with_blind_alleys
let filter_blind_alleys_test3 =
    filter_blind_alleys awksub_wba_grammar
    = (Expr, [Expr, [T"("; N Expr; T")"];
    Expr, [N Num];
    Expr, [N Num];
    Expr, [N Expr; N Expr; N Expr];
    Expr, [N Expr; N Binop; N Expr];
    Expr, [N Lvalue; N Binop; N Expr];
    Lvalue, [T"$"; N Expr];
    Binop, [T"+"];
    Binop, [T"-"];
    Num, [T"0"];
    Num, [T"1"];
    Num, [T"2"]])

type alt_nonterminals =
  | Live | Laugh | Love | Smiley | Face

let alt_grammar =
  Live,
  [Live, [T"Living Well"];
   Laugh, [];
   Laugh, [T"Ha HA"];
   Laugh, [T"he he he"];
   Love, [N Love];
   Love, [N Live];
   Love, [N Laugh];
   Face, [N Smiley];
   Smiley, [N Live; T","; T":)"]]

let filter_blind_alleys_test4 =
  filter_blind_alleys alt_grammar = alt_grammar

let filter_blind_alleys_test5 =
  filter_blind_alleys (Laugh, List.tl (snd alt_grammar)) =
    (Laugh,
     [Laugh, [];
     Laugh, [T"Ha HA"];
     Laugh, [T"he he he"];
     Love, [N Love];
     Love, [N Laugh];])

let filter_blind_alleys_test6 =
  filter_blind_alleys (Love, List.tl (List.tl (List.tl( (snd alt_grammar))))) =
    (Love,
     [Laugh, [T"he he he"];
     Love, [N Love];
     Love, [N Laugh]])
