
open OUnit
(* open Syntax *)

let test1 _ = assert_equal "x" "x"
let test2 _ = assert_equal 1 2

let test_test = "Proto" >:::
  [
    "foo1" >:: test1;
    "foo2" >:: test2;
  ]

let _ = run_test_tt test_test

