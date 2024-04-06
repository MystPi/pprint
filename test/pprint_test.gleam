import gleam/dict
import gleam/dynamic
import gleam/option.{None}
import gleeunit
import gleeunit/should
import birdie
import pprint
import pprint/decoder

type Foo {
  Foo(Int, bar: String, baz: String)
  Wibble
}

pub fn main() {
  gleeunit.main()
}

// https://github.com/MystPi/pprint/issues/2
pub fn custom_type_with_no_fields_decoding_test() {
  Wibble
  |> dynamic.from
  |> decoder.classify
  |> should.equal(decoder.TCustom("Wibble", []))
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
  #(
    Ok(1234),
    "blah",
    True,
    Nil,
    None,
    fn(a) { a },
    3.14,
    <<65>>,
    Foo(1, "2", "3"),
  )
  |> pprint.styled
  |> birdie.snap("data is styled depending on its type")
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

const labels_config = pprint.Config(
  pprint.Styled,
  pprint.BitArraysAsString,
  pprint.Labels,
)

@target(javascript)
pub fn javascript_labels_test() {
  Foo(42, "bar", "baz")
  |> pprint.with_config(labels_config)
  |> birdie.snap("(javascript) labels are shown")
}

@target(erlang)
pub fn erlang_labels_test() {
  Foo(42, "bar", "baz")
  |> pprint.with_config(labels_config)
  |> birdie.snap("(erlang) labels are not shown")
}
