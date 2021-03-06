(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the "hack" directory of this source tree.
 *
 *)

external hh_fanout_build_main :
  bool -> string option -> string option -> string option -> string -> unit
  = "hh_fanout_build_main"

let go ~allow_empty ~incremental ~edges_dir ~delta_file ~output =
  hh_fanout_build_main allow_empty incremental edges_dir delta_file output;
  Lwt.return_unit
