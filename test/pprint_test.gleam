import gleam/dict
import gleeunit
import birdie
import pprint

pub fn main() {
  gleeunit.main()
}

pub fn pretty_list_test() {
  ["This", "is", "a", "very", "long", "list", "that", "should", "be", "wrapped"]
  |> pprint.format
  |> birdie.snap("long lists are wrapped and indented")
}

pub fn alt_list_test() {
  [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  |> pprint.format
  |> birdie.snap("lists of only numbers are formatted differently")
}

pub fn complex_data_test() {
  Ok([
    [[[#("foo", 42, fn(x) { x }, [[1, 2], [3, 4]], Error("Help, an error!"))]]],
  ])
  |> pprint.format
  |> birdie.snap("complex, nested data is formatted nicely")
}

@target(javascript)
pub fn javascript_coloring_test() {
  #(Ok(1234), "blah", True, Nil, fn(a) { a }, 3.14, <<1, 2, 3>>)
  |> pprint.format_colored
  |> birdie.snap("(js) data is colored depending on its type")
}

// 🚨 On the erlang target strings are encoded as bit arrays so if we pass it a
// bit array we'll get out a string. This is a behaviour that will inevitably
// differ from target to target so we have to write two different tests to
// make sure it doesn't result in problems.
//
// TODO: we could be smarter and ensure we get the exact same behaviour on all
//       targets by turning bitarrays into strings on the JS target though!
//       This would ensure that people get consisten outputs most of the times
//       without having to rely on the `@target` annotation like we're doing.
@target(erlang)
pub fn erlang_coloring_test() {
  #(Ok(1234), "blah", True, Nil, fn(a) { a }, 3.14, <<65>>)
  |> pprint.format_colored
  |> birdie.snap("(erlang) data is colored depending on its type")
}

pub fn dict_test() {
  dict.from_list([#("foo", 1), #("bar", 2), #("baz", 3)])
  |> pprint.format
  |> birdie.snap("dictionaries use the dict.from_list function when formatted")
}

pub fn functions_test() {
  #(fn(a) { a }, fn(a) { a }, fn(a) { a })
  |> pprint.format
  |> birdie.snap("functions are formatted with string.inspect")
}
