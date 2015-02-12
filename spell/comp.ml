open Batteries

let () =
  if not !Sys.interactive then
    match Sys.argv with
    | [| _; wordlist; outfile |] ->
      let ser = Dawg.of_file_comp wordlist |> Dawg.serialise in
      File.with_file_out outfile (fun out -> Printf.fprintf out "%s" ser)
    | _ -> print_endline "Expects two file arguments: wordlist serialised_output"
