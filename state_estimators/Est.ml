open! Core
open Src

(* TODO: decrease duplication *)

module type W_state = sig
  type t

  val current_sds_required : Sd.Packed.t Hash_set.t
  val past_sds_required : Sd.Packed.t Hash_set.t
  val sds_estimating : Sd.Packed.t Hash_set.t
  val est : t -> Robot_state_history.t -> Robot_state.t

  (* TODO: should allow more types of uncertainty, as well as a function that gives covariance *)
  val uncertainty : t -> Robot_state_history.t -> float Sd.t -> Uncertianty.t option
end

module type Wo_state = sig
  type t = unit

  val current_sds_required : Sd.Packed.t Hash_set.t
  val past_sds_required : Sd.Packed.t Hash_set.t
  val sds_estimating : Sd.Packed.t Hash_set.t
  val est : t -> Robot_state_history.t -> Robot_state.t
  val est_stateless : Robot_state_history.t -> Robot_state.t

  (* TODO: should allow more types of uncertainty, as well as a function that gives covariance *)
  val uncertainty : t -> Robot_state_history.t -> float Sd.t -> Uncertianty.t option
  val uncertainty_stateless : Robot_state_history.t -> float Sd.t -> Uncertianty.t option
end

module Applicable = struct
  type t = P : (module W_state with type t = 'a) * 'a -> t
  type model = t list

  let create (type a) (module W_state : W_state with type t = a) (w_t : a) =
    P ((module W_state), w_t)
  ;;

  let apply (state_history : Robot_state_history.t) (model : model) =
    List.fold_left model ~init:state_history ~f:(fun state_history t ->
        match t with
        | P ((module W_state), t) ->
          Robot_state_history.use state_history (W_state.est t state_history))
  ;;

  type check_status =
    | Passed
    | Failed

  let check model =
    ignore model;
    Passed
  ;;
end