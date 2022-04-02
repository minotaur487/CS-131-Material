(* 1. checks if a is a subset of b *)
let rec subset a b = match a with
                        | [] -> true
                        | h::t -> List.mem h b && (subset t b)

(* 2. checks if a and b are equal sets *)
let equal_sets a b = subset a b && subset b a

(* 3. performs a union on a and b *)
let set_union a b = a @ b

(* 4. performs a union on all of a's elements *)
let rec set_all_union a = match a with
                        | [] -> []
                        | h::t -> h @ (set_all_union t)

(* 5. You can't write a function that determines if a given set is a member
of itself in OCaml because the set s itself would go infinitely deep, so
the recursion would go on forever. Also using functions like List.mem
doesn't work because referencing a list to itself doesn't fit its interface.
And manually checking the sets won't work because the set will infinitely
contain itself. Also, you can't mix types with lists.
Moreover, the paradox implies that the set s would keep nesting
into itself since each s would have to have itself as an element.
This would mean that the type of this would be type
`a list list ... list which can't be represented in OCaml. *)

(* 6. computes the fixed point of function f with starting point x *)
let rec computed_fixed_point eq f x = 
    let current_val = f x in
    let bool_val = eq x current_val in
    if bool_val then x
    else (computed_fixed_point eq f current_val)

(* 7. computes the periodic point of function x on starting point x for a given cycle p *)
let rec computed_periodic_point eq f p x =
    (* Helper function to see if the current value is a periodic point *)
    let rec calculate_current_iteration i current_val =
        let next_val = f current_val in
        let bool_val = eq current_val x in
        match i with
            | 0 -> bool_val
            | a -> calculate_current_iteration (i-1) next_val in
    let bool_val = calculate_current_iteration p x in
    if bool_val = true then x
    else computed_periodic_point eq f p (f x)
    
(* 8. generates a sequence based on p with function s and starting value x *)
let rec whileseq s p x = match (p x) with
    | false -> []
    | true -> [x] @ whileseq s p (s x)

(* 9. filter out the blind alley rules *)
type ('nonterminal, 'terminal) symbol =
    | N of 'nonterminal
    | T of 'terminal;;

(* helper functions *)
(* is a given symbol terminable *)
let is_terminable = function
    | T term -> true
    | N nonterm -> false;;

(* are two rulesets equal *)
let blind_alley_equal_fun a b = equal_sets (snd a) (snd b)

(* are all the symbols in a rule terminable *)
let rec is_all_terminable = function
    | [] -> true
    | h::t -> is_terminable h && is_all_terminable t

(* get the rules that are guaranteed terminal, ie has only terminal symbols in rule *)
let get_guaranteed_terminal rules =
    List.filter (fun x -> is_all_terminable (snd x)) rules;;

(* is the element in the given set *)
let is_in e set = List.exists (fun x -> x = e) set

(* strip the rules from a ruleset and return their symbols *)
let rec strip_rules set acc =
    match set with
        | [] -> acc
        | pair::rules -> if not (is_in (fst pair) acc)
        then (fst pair)::(strip_rules rules acc)
        else strip_rules rules acc

(* get all rules that are not in the non blind alley rule set *)
let get_non_g_set g_set rule_set =
    let is_in_g_set rule = List.exists (fun y -> y = rule) g_set in
    List.filter (fun x -> not (is_in_g_set x)) rule_set;;

(* check if the given rule is a non blind alley *)
let rec is_valid_rule rule g_set =
    let stripped = strip_rules g_set [] in
    let aux sym =
        match sym with
            | N e -> is_in e stripped
            | T _ -> true in
    match rule with
        | [] -> true
        | h::t -> aux h && is_valid_rule t g_set

(* remove all blind alley rules from the rule set *)
let rec process_rule_set rule_set good_set =
    let unseen_rules = get_non_g_set good_set rule_set in
    match unseen_rules with
        | [] -> good_set
        | h::t -> if (is_valid_rule (snd h) good_set) && (not (is_in h good_set))
        then process_rule_set t (h::good_set)
        else process_rule_set t good_set

(* helper function to take care of data types/shape *)
let process_rule_set_unpacked a =
    fst a, (process_rule_set (fst a) (snd a))

(* primary function that returns the grammar with the blind alley rules removed *)
let rec filter_blind_alleys g =
    let starting_symbol = fst g in
    let rule_set = snd g in
    let g_set = get_guaranteed_terminal rule_set in
    let good_rule_set = snd (computed_fixed_point (blind_alley_equal_fun) (process_rule_set_unpacked) (rule_set, g_set)) in
    (starting_symbol, List.filter (fun x -> subset [x] good_rule_set) rule_set)
