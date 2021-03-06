module List = struct
  include Core_kernel.List

  let unzip4 xyzws =
    let rec aux ((xs, ys, zs, ws) as acc) = function
      | (x, y, z, w) :: rest -> aux (x :: xs, y :: ys, z :: zs, w :: ws) rest
      | _ -> acc
    in
    aux ([], [], [], []) (List.rev xyzws)

  let rec fold_left_env env l ~init ~f =
    match l with
    | [] -> (env, init)
    | x :: xs ->
      let (env, init) = f env init x in
      fold_left_env env xs ~init ~f

  let rec fold_left_env_res env l ~init ~err ~f =
    match l with
    | [] -> (env, init, err)
    | x :: xs ->
      let (env, init, err) = f env init err x in
      fold_left_env_res env xs ~init ~err ~f

  let rev_map_env env xs ~f =
    let f2 env init x =
      let (env, x) = f env x in
      (env, x :: init)
    in
    fold_left_env env xs ~init:[] ~f:f2

  let rev_map_env_res env xs ~f =
    let f2 env init errs x =
      let (env, x, err) = f env x in
      (env, x :: init, err :: errs)
    in
    fold_left_env_res env xs ~init:[] ~err:[] ~f:f2

  let map_env env xs ~f =
    let rec aux env xs counter =
      match xs with
      | [] -> (env, [])
      | [y1] ->
        let (env, z1) = f env y1 in
        (env, [z1])
      | [y1; y2] ->
        let (env, z1) = f env y1 in
        let (env, z2) = f env y2 in
        (env, [z1; z2])
      | [y1; y2; y3] ->
        let (env, z1) = f env y1 in
        let (env, z2) = f env y2 in
        let (env, z3) = f env y3 in
        (env, [z1; z2; z3])
      | [y1; y2; y3; y4] ->
        let (env, z1) = f env y1 in
        let (env, z2) = f env y2 in
        let (env, z3) = f env y3 in
        let (env, z4) = f env y4 in
        (env, [z1; z2; z3; z4])
      | [y1; y2; y3; y4; y5] ->
        let (env, z1) = f env y1 in
        let (env, z2) = f env y2 in
        let (env, z3) = f env y3 in
        let (env, z4) = f env y4 in
        let (env, z5) = f env y5 in
        (env, [z1; z2; z3; z4; z5])
      | y1 :: y2 :: y3 :: y4 :: y5 :: ys ->
        let (env, z1) = f env y1 in
        let (env, z2) = f env y2 in
        let (env, z3) = f env y3 in
        let (env, z4) = f env y4 in
        let (env, z5) = f env y5 in
        let (env, zs) =
          if counter > 1000 then
            let (env, zs) = rev_map_env env ys ~f in
            (env, rev zs)
          else
            aux env ys (counter + 1)
        in
        (env, z1 :: z2 :: z3 :: z4 :: z5 :: zs)
    in
    aux env xs 0

  let map_env_err_res env xs ~f =
    let rec aux env xs counter =
      match xs with
      | [] -> (env, [], [])
      | [y1] ->
        let (env, z1, res) = f env y1 in
        (env, [z1], [res])
      | [y1; y2] ->
        let (env, z1, res1) = f env y1 in
        let (env, z2, res2) = f env y2 in
        (env, [z1; z2], [res1; res2])
      | [y1; y2; y3] ->
        let (env, z1, res1) = f env y1 in
        let (env, z2, res2) = f env y2 in
        let (env, z3, res3) = f env y3 in
        (env, [z1; z2; z3], [res1; res2; res3])
      | [y1; y2; y3; y4] ->
        let (env, z1, res1) = f env y1 in
        let (env, z2, res2) = f env y2 in
        let (env, z3, res3) = f env y3 in
        let (env, z4, res4) = f env y4 in
        (env, [z1; z2; z3; z4], [res1; res2; res3; res4])
      | [y1; y2; y3; y4; y5] ->
        let (env, z1, res1) = f env y1 in
        let (env, z2, res2) = f env y2 in
        let (env, z3, res3) = f env y3 in
        let (env, z4, res4) = f env y4 in
        let (env, z5, res5) = f env y5 in
        (env, [z1; z2; z3; z4; z5], [res1; res2; res3; res4; res5])
      | y1 :: y2 :: y3 :: y4 :: y5 :: ys ->
        let (env, z1, res1) = f env y1 in
        let (env, z2, res2) = f env y2 in
        let (env, z3, res3) = f env y3 in
        let (env, z4, res4) = f env y4 in
        let (env, z5, res5) = f env y5 in
        let (env, zs, res6) =
          if counter > 1000 then
            let (env, zs, errs) = rev_map_env_res env ys ~f in
            (env, rev zs, rev errs)
          else
            aux env ys (counter + 1)
        in
        ( env,
          z1 :: z2 :: z3 :: z4 :: z5 :: zs,
          res1 :: res2 :: res3 :: res4 :: res5 :: res6 )
    in
    aux env xs 0

  let rec map2_env env l1 l2 ~f =
    match (l1, l2) with
    | ([], []) -> (env, [])
    | ([], _)
    | (_, []) ->
      raise @@ Invalid_argument "map2_env"
    | (x1 :: rl1, x2 :: rl2) ->
      let (env, x) = f env x1 x2 in
      let (env, rl) = map2_env env rl1 rl2 ~f in
      (env, x :: rl)

  let rec map3_env env l1 l2 l3 ~f =
    if length l1 <> length l2 || length l2 <> length l3 then
      raise @@ Invalid_argument "map3_env"
    else
      match (l1, l2, l3) with
      | ([], [], []) -> (env, [])
      | ([], _, _)
      | (_, [], _)
      | (_, _, []) ->
        raise @@ Invalid_argument "map3_env"
      | (x1 :: rl1, x2 :: rl2, x3 :: rl3) ->
        let (env, x) = f env x1 x2 x3 in
        let (env, rl) = map3_env env rl1 rl2 rl3 ~f in
        (env, x :: rl)

  let filter_map_env env xs ~f =
    let (env, l) = rev_map_env env xs ~f in
    (env, rev_filter_map l ~f:(fun x -> x))

  let rec exists_env env xs ~f =
    match xs with
    | [] -> (env, false)
    | x :: xs ->
      (match f env x with
      | (env, true) -> (env, true)
      | (env, false) -> exists_env env xs ~f)

  let rec replicate ~num x =
    match num with
    | 0 -> []
    | n when n < 0 ->
      raise
      @@ Invalid_argument
           (Printf.sprintf "List.replicate was called with %d argument" n)
    | _ -> x :: replicate ~num:(num - 1) x
end

module Result = struct
  include Core_kernel.Result

  let fold t ~ok ~error =
    match t with
    | Ok x -> ok x
    | Error err -> error err
end
