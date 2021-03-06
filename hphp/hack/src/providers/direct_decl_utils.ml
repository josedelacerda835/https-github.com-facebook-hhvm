(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the "hack" directory of this source tree.
 *
 *)

open Hh_prelude

(* If any decls in the list have the same name, retain only the first
   declaration of each symbol in the sequence. *)
let dedup_decls decls =
  let open Shallow_decl_defs in
  let seen_types = String.Table.create () in
  let seen_funs = String.Table.create () in
  let seen_consts = String.Table.create () in
  Sequence.filter decls ~f:(fun decl ->
      match decl with
      | (name, Class _)
      | (name, Record _)
      | (name, Typedef _) ->
        if String.Table.mem seen_types name then
          false
        else
          let () = String.Table.add_exn seen_types ~key:name ~data:() in
          true
      | (name, Fun _) ->
        if String.Table.mem seen_funs name then
          false
        else
          let () = String.Table.add_exn seen_funs ~key:name ~data:() in
          true
      | (name, Const _) ->
        if String.Table.mem seen_consts name then
          false
        else
          let () = String.Table.add_exn seen_consts ~key:name ~data:() in
          true)

(* If a symbol was also declared in another file, and that file was determined
   to be the winner in the naming table, remove its decl from the list.

   Do not remove decls if there is no entry for them in the naming table. This
   ensures that this path can populate the decl heap during full inits. This may
   result in the decl heap containing an incorrect decl in the event of a naming
   conflict, which might be confusing. But the user will be obligated to fix the
   naming conflict, and this behavior is limited to full inits, so maybe we can
   live with it. *)
let remove_naming_conflict_losers ctx file decls =
  let open Shallow_decl_defs in
  Sequence.filter decls ~f:(fun decl ->
      match decl with
      | (name, Class _)
      | (name, Record _)
      | (name, Typedef _) ->
        (match Naming_provider.get_type_path ctx name with
        | Some nfile -> Relative_path.equal nfile file
        | None -> true)
      | (name, Fun _) ->
        (match Naming_provider.get_fun_path ctx name with
        | Some nfile -> Relative_path.equal nfile file
        | None -> true)
      | (name, Const _) ->
        (match Naming_provider.get_const_path ctx name with
        | Some nfile -> Relative_path.equal nfile file
        | None -> true))

let cache_decls ctx file decls =
  let open Shallow_decl_defs in
  let open Typing_defs in
  let decls =
    decls
    |> List.rev (* direct decl parser produces reverse of syntactic order *)
    |> Sequence.of_list
    |> dedup_decls
    |> remove_naming_conflict_losers ctx file
  in
  match Provider_context.get_backend ctx with
  | Provider_backend.Analysis -> failwith "invalid"
  | Provider_backend.Shared_memory ->
    Sequence.iter decls ~f:(function
        | (name, Class decl) ->
          Shallow_classes_heap.Classes.add name decl;
          if
            TypecheckerOptions.shallow_class_decl
              (Provider_context.get_tcopt ctx)
          then
            Shallow_classes_heap.MemberFilters.add decl
        | (name, Fun decl) -> Decl_store.((get ()).add_fun name decl)
        | (name, Record decl) -> Decl_store.((get ()).add_recorddef name decl)
        | (name, Typedef decl) -> Decl_store.((get ()).add_typedef name decl)
        | (name, Const decl) -> Decl_store.((get ()).add_gconst name decl))
  | Provider_backend.(Local_memory { decl_cache; shallow_decl_cache; _ }) ->
    Sequence.iter decls ~f:(function
        | (name, Class decl) ->
          let (_ : shallow_class option) =
            Provider_backend.Shallow_decl_cache.find_or_add
              shallow_decl_cache
              ~key:
                (Provider_backend.Shallow_decl_cache_entry.Shallow_class_decl
                   name)
              ~default:(fun () -> Some decl)
          in
          ()
        | (name, Fun decl) ->
          let (_ : fun_elt option) =
            Provider_backend.Decl_cache.find_or_add
              decl_cache
              ~key:(Provider_backend.Decl_cache_entry.Fun_decl name)
              ~default:(fun () -> Some decl)
          in
          ()
        | (name, Record decl) ->
          let (_ : record_def_type option) =
            Provider_backend.Decl_cache.find_or_add
              decl_cache
              ~key:(Provider_backend.Decl_cache_entry.Record_decl name)
              ~default:(fun () -> Some decl)
          in
          ()
        | (name, Typedef decl) ->
          let (_ : typedef_type option) =
            Provider_backend.Decl_cache.find_or_add
              decl_cache
              ~key:(Provider_backend.Decl_cache_entry.Typedef_decl name)
              ~default:(fun () -> Some decl)
          in
          ()
        | (name, Const decl) ->
          let (_ : const_decl option) =
            Provider_backend.Decl_cache.find_or_add
              decl_cache
              ~key:(Provider_backend.Decl_cache_entry.Gconst_decl name)
              ~default:(fun () -> Some decl)
          in
          ())
  | Provider_backend.Decl_service _ ->
    failwith
      "Direct_decl_utils.cache_file_decls not implemented for Decl_service"

let get_file_contents ctx filename =
  match
    Relative_path.Map.find_opt (Provider_context.get_entries ctx) filename
  with
  | Some entry ->
    let source_text = Ast_provider.compute_source_text ~entry in
    Some (Full_fidelity_source_text.text source_text)
  | None ->
    let enable_disk_heap =
      TypecheckerOptions.enable_disk_heap (Provider_context.get_tcopt ctx)
    in
    File_provider.get_contents
      filename
      ~writeback_disk_contents_in_shmem_provider:enable_disk_heap

let direct_decl_parse ~file_decl_hash ~symbol_decl_hashes ctx file =
  match get_file_contents ctx file with
  | None -> None
  | Some contents ->
    let popt = Provider_context.get_popt ctx in
    let opts = DeclParserOptions.from_parser_options popt in
    let (decls, mode, file_decl_hash, symbol_decl_hashes) =
      Direct_decl_parser.parse_decls_and_mode_ffi
        opts
        file
        contents
        file_decl_hash
        symbol_decl_hashes
    in
    let deregister_php_stdlib =
      Relative_path.is_hhi (Relative_path.prefix file)
      && ParserOptions.deregister_php_stdlib popt
    in
    let is_stdlib_fun fun_decl = fun_decl.Typing_defs.fe_php_std_lib in
    let is_stdlib_class c =
      List.exists c.Shallow_decl_defs.sc_user_attributes ~f:(fun a ->
          String.equal
            Naming_special_names.UserAttributes.uaPHPStdLib
            (snd a.Typing_defs_core.ua_name))
    in
    let symbol_decl_hashes =
      match symbol_decl_hashes with
      | Some hashes -> List.map ~f:(fun hash -> Some hash) hashes
      | None -> List.map ~f:(fun _ -> None) decls
    in
    let (decls, symbol_decl_hashes) =
      if not deregister_php_stdlib then
        (decls, symbol_decl_hashes)
      else
        let open Shallow_decl_defs in
        let (decls, symbol_decl_hashes) =
          List.filter_map (List.zip_exn decls symbol_decl_hashes) ~f:(function
              | ((_, Fun f), _) when is_stdlib_fun f -> None
              | ((_, Class c), _) when is_stdlib_class c -> None
              | ((name, Class c), hash) ->
                let keep_prop sp = not (sp_php_std_lib sp) in
                let keep_meth sm = not (sm_php_std_lib sm) in
                let c =
                  {
                    c with
                    sc_props = List.filter c.sc_props ~f:keep_prop;
                    sc_sprops = List.filter c.sc_sprops ~f:keep_prop;
                    sc_methods = List.filter c.sc_methods ~f:keep_meth;
                    sc_static_methods =
                      List.filter c.sc_static_methods ~f:keep_meth;
                  }
                in
                Some ((name, Class c), hash)
              | (name_and_decl, hash) -> Some (name_and_decl, hash))
          |> List.unzip
        in
        (decls, symbol_decl_hashes)
    in
    Some (decls, mode, file_decl_hash, symbol_decl_hashes)

let direct_decl_parse_and_cache ~file_decl_hash ~symbol_decl_hashes ctx file =
  let result = direct_decl_parse ~file_decl_hash ~symbol_decl_hashes ctx file in
  (match result with
  | Some (decls, _, _, _) -> cache_decls ctx file decls
  | None -> ());
  result

let decls_to_fileinfo fn (decls, file_mode, hash, symbol_decl_hashes) =
  List.zip_exn decls symbol_decl_hashes
  |> List.fold
       ~init:FileInfo.{ empty_t with hash; file_mode }
       ~f:(fun acc ((name, decl), decl_hash) ->
         let pos p = FileInfo.Full (Pos_or_decl.fill_in_filename fn p) in
         match decl with
         | Shallow_decl_defs.Class c ->
           let info =
             (pos (fst c.Shallow_decl_defs.sc_name), name, decl_hash)
           in
           FileInfo.{ acc with classes = info :: acc.classes }
         | Shallow_decl_defs.Fun f ->
           let info = (pos f.Typing_defs.fe_pos, name, decl_hash) in
           FileInfo.{ acc with funs = info :: acc.funs }
         | Shallow_decl_defs.Typedef tf ->
           let info = (pos tf.Typing_defs.td_pos, name, decl_hash) in
           FileInfo.{ acc with typedefs = info :: acc.typedefs }
         | Shallow_decl_defs.Const c ->
           let info = (pos c.Typing_defs.cd_pos, name, decl_hash) in
           FileInfo.{ acc with consts = info :: acc.consts }
         | Shallow_decl_defs.Record r ->
           let info = (pos (fst r.Typing_defs.rdt_name), name, decl_hash) in
           FileInfo.{ acc with record_defs = info :: acc.record_defs })
