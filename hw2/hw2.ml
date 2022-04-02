type ('nonterminal, 'terminal) parse_tree =
  | Node of 'nonterminal * ('nonterminal, 'terminal) parse_tree list
  | Leaf of 'terminal

type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

(* 1. *)
let convert_grammar gram1 =
    let production_function : 'symbol -> 'a list list = fun s ->
        let filtered_grammar =
            let pred rule = if (fst rule) = s then true else false in
            List.filter pred (snd gram1) in
        let rec get_alternative_list gram acc =
            match gram with
                | [] -> acc
                | (s, rhs)::rest_of_gram -> get_alternative_list rest_of_gram (([rhs])::acc) in
        get_alternative_list filtered_grammar [] in
    ((fst gram1), production_function)

(* 2. *)
let parse_tree_leaves tree =
    let rec process_cur node =
        match node with
            | Leaf l -> [l]
            | Node (symbol, rules) -> process_children rules
    and process_children list =
        match list with
            | [] -> []
            | h::t -> process_cur h @ process_children t in
    process_cur tree

(* 3. *)
let rec match_ruleset frag accept production_function ruleset =
    match ruleset with
        (* Means none of the rules passed *)
        | [] -> None
        | rule::r_tail ->
            let processed_rule = traverse_rule frag accept production_function rule in
            (* If rule has not passed or acceptor doesn't like suffix, try next rule *)
            if processed_rule = None
            then match_ruleset frag accept production_function r_tail
            (* Otherwise acceptor works with current rule so return result of accept on suffix *)
            else processed_rule
and traverse_rule frag accept production_function rule =
    (* If rule is empty, return result of passing frag to accept function *)
    match rule with
        | [] -> accept frag
        | _ ->
        (* Try to compare rule with fragment. But, if frag is empty, return None *)
        match frag with
            | [] -> None
            | fhd::ftl ->
                match rule with
                    (* case where rule = [] should have been caught.*)
                    | (T tsymbol)::symbols -> if tsymbol = fhd then traverse_rule ftl accept production_function symbols else None
                    | (N nsymbol)::symbols -> 
                        let nsymbol_ruleset = production_function nsymbol in
                        (* Basically anding two matchers together, where it tries the nonterminal's rules, and whatever is left over after it tries to
                           expand the nonterminal is evaluated by the original matcher such that if that passes it then is tried by the original
                           accept function*)
                        match_ruleset frag (fun frag2 -> traverse_rule frag2 accept production_function symbols) production_function nsymbol_ruleset
                    

let make_matcher gram accept frag =
    let start_symbol = fst gram in
    let production_function = snd gram in
    let start_ruleset = production_function start_symbol in
    match_ruleset frag accept production_function start_ruleset

(* 4. *)
let accept_empty_suffix saved_traversal frag =
    match frag with
        | [] -> Some saved_traversal
        | _ -> None

let rec modified_match_ruleset accept production_function start_symbol ruleset saved_traversal frag =
    match ruleset with
        | [] -> None
        | rule::r_tail ->
            let processed_rule = modified_traverse_rule accept production_function rule (saved_traversal @ [(start_symbol, rule)]) frag in
            (* If rule has not passed or acceptor doesn't like suffix, try next rule *)
            if processed_rule = None
            then modified_match_ruleset accept production_function start_symbol r_tail saved_traversal frag
            (* Otherwise acceptor works with current rule so return result of accept on suffix *)
            else processed_rule
and modified_traverse_rule accept production_function rule saved_traversal frag =
    (* If rule is empty, return result of passing frag to accept function *)
    match rule with
        | [] -> accept saved_traversal frag
        | _ ->
        (* Try to compare rule with fragment. But, if frag is empty, return None *)
        match frag with
            | [] -> None
            | fhd::ftl ->
                match rule with
                    (* case where rule = [] should have been caught.*)
                    | (T tsymbol)::symbols -> if tsymbol = fhd then modified_traverse_rule accept production_function symbols saved_traversal ftl else None
                    | (N nsymbol)::symbols -> 
                        let nsymbol_ruleset = production_function nsymbol in
                        (* Basically anding two matchers together, where it tries the nonterminal's rules, and whatever is left over after it tries to
                        expand the nonterminal is evaluated by the original matcher such that if that passes it then is tried by the original
                        accept function*)
                        modified_match_ruleset (fun accept2 frag2 -> modified_traverse_rule accept production_function symbols accept2 frag2) production_function nsymbol nsymbol_ruleset saved_traversal frag

let rec build_current_layer unprocessed_children nodes =
        match unprocessed_children with
            | [] -> nodes, []
            | current_child::remaining_children ->
                match current_child with
                    | T symbol ->
                        let remaining_nodes, processed_siblings = build_current_layer remaining_children nodes in
                        remaining_nodes, (Leaf symbol)::processed_siblings
                    | N symbol ->
                        let remaining_nodes, processed_child = recurse_down nodes in
                        let remaining_nodes2, processed_siblings = build_current_layer remaining_children remaining_nodes in
                        remaining_nodes2, processed_child::processed_siblings
and recurse_down nodes =
    match nodes with
        | current_node::remaining_nodes ->
            let symbol = fst current_node in
            let unprocessed_children = snd current_node in
            let remaining_nodes2, processed_children = build_current_layer unprocessed_children remaining_nodes
            in
            remaining_nodes2, Node (symbol, processed_children)

let build_tree option_nodes =
    match option_nodes with
        | Some nodes ->
            let root = List.hd nodes in
            let children = snd root in
            let rest_of_nodes = List.tl nodes in
            Some (Node (fst root, (snd (build_current_layer children rest_of_nodes))))
        | _ -> None

let make_parser gram = 
    let start_symbol = fst gram in
    let production_function = snd gram in
    let start_ruleset = production_function start_symbol in
	let get_path = modified_match_ruleset accept_empty_suffix production_function start_symbol start_ruleset [] in
	fun frag ->
        let path = get_path frag in
        build_tree path
