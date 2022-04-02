(* MY TEST CASES *)

let accept_all string = Some string

type classy_nonterminals =
  | Sentence | NP | VP | Adjective | Noun | Adverb | Verb

let classy_grammar =
  (Sentence,
    function
      | Sentence ->
          [[N NP; N VP]];
      | NP -> [[N Noun];
                [N Adjective; N Noun]]
      | VP -> [[N Verb];
                [N Adverb; N Verb]]
      | Adverb -> [[T "happily"];
                  [T "quickly"]]
      | Verb -> [[T "lived"];
                  [T "laughed"];
                  [T "loved"]]
      | Noun -> [[T "Boss"];
                  [T "El Presidente"]]
      | Adjective -> [[T "hot"]])

let accept_all string = Some string
let accept_empty_suffix = function
   | _::_ -> None
   | x -> Some x

let frag = ["El Presidente"; "happily"; "lived"]

let make_matcher_test = ((make_matcher classy_grammar accept_all frag) = Some [])

let make_parser_test =
  let result = make_parser classy_grammar frag in
  match result with
    | Some tree -> (parse_tree_leaves tree) = frag
    | _ -> false
  