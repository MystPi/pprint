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

pub fn coloring_test() {
  #(Ok(1234), "blah", True, Nil, fn(a) { a }, 3.14, <<1, 2, 3>>)
  |> pprint.format_colored
  |> birdie.snap("data is colored depending on its type")
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
