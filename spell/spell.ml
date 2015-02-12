open Batteries

let uu_look s i =
  let rec loop d c_i =
    match Uutf.decode d with
    | `Uchar u -> if c_i = i then u else loop d (c_i + 1)
    | `End -> raise Not_found
    | `Malformed _ -> if c_i = i then Uutf.u_rep else loop d (c_i + 1)
    | `Await -> assert false
  in
  loop (Uutf.decoder (`String s)) 0

let uu_any pred s =
  let rec loop d = match Uutf.decode d with
    | `Uchar u -> if pred u then true else loop d
    | `End -> false
    | `Malformed _ -> loop d
    | `Await -> assert false
  in
  loop (Uutf.decoder (`String s))

let uu_explode_rev =
  Uutf.String.fold_utf_8 (fun a i c -> match c with `Uchar u -> u::a |_-> a) []

let vowels =
  uu_explode_rev "aeiouyæøåïáéýüïœäöàAEIOUYÆØÅÏÁÉÝÜÏŒÄÖÀ"
  |> Set.of_list
let j =
  uu_explode_rev "j"
  |> Set.of_list
let consonants =
  uu_explode_rev "qwrtpsdfghklzxcvbnmšžčŋđŧǧǩçǯʒþǥßðQWRTPSDFGHKLZXCVBNMŠŽČŊĐŦǦǨÇǮƷÞǤßÐ"
  |> Set.of_list

type vc = J | Cons | Vow | Other
let firstvc s =
  let first = uu_look s 0 in
  if Set.mem first j then J
  else if Set.mem first vowels then Vow
  else if Set.mem first consonants then Cons
  else Other



let has_upper s =
  uu_any Uucp.Case.is_upper s

let same_upper input_has_upper sugg =
  input_has_upper = has_upper sugg

let same_firstvc input_firstvc sugg =
  let sugg_firstvc = firstvc sugg in
  input_firstvc = J || sugg_firstvc = J || input_firstvc = firstvc sugg

let compose f g x = f (g x)

let good_suggs input suggs =
  let input_has_upper = has_upper input in
  let input_firstvc = firstvc input in
  Set.filter (compose ((<) 2) UTF8.length) suggs
  |> Set.filter (same_upper input_has_upper)
  |> Set.filter (same_firstvc input_firstvc)
  |> Set.remove input


let () =
  if not !Sys.interactive then
    match Sys.argv with
    | [| _; max_edits; max_decomp; path |] ->
      let d = Dawg.unserialise_file path in
      let max_edits = Int.of_string max_edits in
      let max_decomp = Int.of_string max_decomp in
      let decomp_minlen = 5 in
      IO.lines_of stdin |> Enum.iter (fun l' ->
          let l = (String.trim l') in
          let suggs = Dawg.lookup_edit_decomp d ~max_edits ~max_decomp ~decomp_minlen l in
          Printf.printf "%s" l;
          if Set.mem l suggs then Printf.printf "\tIN_CORPUS" else
            Set.iter (fun res -> Printf.printf "\t%s" res) (good_suggs l suggs);
          Printf.printf "\n"
      )
    | _ ->
      print_endline "Expects two argument: MAX_EDITS SERIALISED_DAWG";
      print_endline "where MAX_EDITS is an integer, and SERIALISED_DAWG a file";
      print_endline "(created by comp)";
      exit 2
