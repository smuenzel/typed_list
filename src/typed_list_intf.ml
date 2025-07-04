(* SPDX-License-Identifier: MPL-2.0
 * SPDX-FileCopyrightText: (c) 2023-2025 Stefan Muenzel
 *)

open! Base

module type Pack_inner = sig
  type raw
  type _ t = private raw
  type packed = | T : _ t -> packed [@@unboxed]
end

module Lambda_higher_types = struct
  type ('inner, 'inputs) t =
    | [] : (_, Nothing.t) t
    | (::) : ('arg -> 'inner) Higher_kinded.t * ('inner, 'next_args) t -> ('inner, 'arg * 'next_args) t

  type 'inner packed =
    | L : ('inner, 'inputs) t -> 'inner packed
  [@@unboxed]

  type 'inner1 f_iter =
    { f : 'arg . ('arg -> 'inner1) Higher_kinded.t -> unit
    } [@@unboxed]

  type ('inner1, 'inner2) f_map =
    { f : 'arg . ('arg -> 'inner1) Higher_kinded.t -> ('arg -> 'inner2) Higher_kinded.t
    } [@@unboxed]

  type ('inner1, 'inner2) f_mapi =
    { f : 'arg
          . int
        -> ('arg -> 'inner1) Higher_kinded.t
        -> ('arg -> 'inner2) Higher_kinded.t
    } [@@unboxed]

  type ('inner1a, 'inner1b, 'inner2) f_map2 =
    { f : 'arg 
          . ('arg -> 'inner1a) Higher_kinded.t
        -> ('arg -> 'inner1b) Higher_kinded.t
        -> ('arg -> 'inner2) Higher_kinded.t
    } [@@unboxed]

  type ('inner1, 'out) f_to_list =
    { f : 'arg . ('arg -> 'inner1) Higher_kinded.t -> 'out
    } [@@unboxed]

  type ('inner1a, 'inner1b, 'out) f_to_list2 =
    { f : 'arg 
          . ('arg -> 'inner1a) Higher_kinded.t
        -> ('arg -> 'inner1b) Higher_kinded.t
        -> 'out
    } [@@unboxed]
end

module type Lambda_higher = sig
  include module type of struct include Lambda_higher_types end

  val length : _ t -> int

  val iter
    :  'inner1 f_iter
    -> ('inner1, 'inputs) t
    -> unit

  val map
    :  ('inner1, 'inner2) f_map
    -> ('inner1, 'inputs) t
    -> ('inner2, 'inputs) t

  val mapi
    :  ('inner1, 'inner2) f_mapi
    -> ('inner1, 'inputs) t
    -> ('inner2, 'inputs) t

  val map2
    :  ('inner1a, 'inner1b, 'inner2) f_map2
    -> ('inner1a, 'inputs) t
    -> ('inner1b, 'inputs) t
    -> ('inner2, 'inputs) t

  val to_list_map
    :  ('inner1, 'out) f_to_list
    -> ('inner1, 'inputs) t
    -> 'out list

  val to_list_map2
    :  ('inner1a, 'inner1b, 'out) f_to_list2
    -> ('inner1a, 'inputs) t
    -> ('inner1b, 'inputs) t
    -> 'out list
end

module type Lambda_lower = sig
  module Lambda_higher : Lambda_higher
  module Inner : Higher_kinded.S

  type 'inputs t =
    | [] : Nothing.t t
    | (::) : 'arg Inner.t * 'next_args t -> ('arg * 'next_args) t

  type packed = | L : _ t -> packed [@@unboxed]

  val higher : 'inputs t -> (Inner.higher_kinded, 'inputs) Lambda_higher.t
  val lower : (Inner.higher_kinded, 'inputs) Lambda_higher.t -> 'inputs t

  val length : _ t -> int
end

module type Lambda_lower2 = sig
  module Lambda_higher : Lambda_higher
  module Inner : Higher_kinded.S2

  type ('arg, 'extra) t =
    | [] : (Nothing.t, _) t
    | (::) : ('arg, 'extra) Inner.t * ('next_args, 'extra) t -> (('arg * 'next_args), 'extra) t

  type 'extra packed = | L : (_,'extra) t -> 'extra packed [@@unboxed]

  val higher : ('inputs, 'extra) t -> ('extra -> Inner.higher_kinded, 'inputs) Lambda_higher.t
  val lower : ('extra -> Inner.higher_kinded, 'inputs) Lambda_higher.t -> ('inputs, 'extra) t

  val length : _ t -> int
end


module type Typed_list = sig
  module Lambda_higher : Lambda_higher
  module type Lambda_lower = Lambda_lower
  module Make_lambda_lower(Inner : Higher_kinded.S)
    : Lambda_lower with module Inner = Inner
                    and module Lambda_higher := Lambda_higher

  module type Lambda_lower2 = Lambda_lower2
  module Make_lambda_lower2(Inner : Higher_kinded.S2)
    : Lambda_lower2 with module Inner = Inner
                     and module Lambda_higher := Lambda_higher

end
