import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/result
import gleam/string

// ---- TYPES ------------------------------------------------------------------

pub type Type {
  TString(String)
  TInt(Int)
  TFloat(Float)
  TBool(Bool)
  TNil
  TBitArray(BitArray)
  TList(List(Dynamic))
  TDict(Dict(Type, Type))
  TTuple(List(Dynamic))
  TCustom(name: String, fields: List(Field))
  TForeign(String)
}

pub type Field {
  Labelled(label: String, value: Dynamic)
  Positional(value: Dynamic)
}

// ---- DECODERS ---------------------------------------------------------------

pub fn classify(value: Dynamic) -> Type {
  let assert Ok(t) = decode.run(value, type_decoder())
  t
}

/// This decoder will always return `Ok`, as it ends with a catch-all
/// pattern returning a `TForeign`.
/// 
fn type_decoder() -> decode.Decoder(Type) {
  use <- decode.recursive
  decode.one_of(decode.map(decode.int, TInt), [
    decode.map(decode.float, TFloat),
    decode.map(decode.float, TFloat),
    decode.map(decode.string, TString),
    decode.map(decode.bool, TBool),
    decode.map(nil(), fn(_) { TNil }),
    decode.map(decode.bit_array, TBitArray),
    custom_type(),
    decode.map(tuple(), TTuple),
    decode.map(decode.list(decode.dynamic), TList),
    decode.map(decode.dict(type_decoder(), type_decoder()), TDict),
    decode.map(decode.dynamic, fn(value) { TForeign(string.inspect(value)) }),
  ])
}

fn tuple() -> decode.Decoder(List(Dynamic)) {
  decode.new_primitive_decoder("Tuple", fn(dynamic) {
    result.replace_error(decode_tuple(dynamic), [])
  })
}

fn custom_type() -> decode.Decoder(Type) {
  decode.new_primitive_decoder("CustomType", fn(dynamic) {
    result.replace_error(decode_custom_type(dynamic), TCustom("", []))
  })
}

fn nil() -> decode.Decoder(Nil) {
  decode.new_primitive_decoder("Nil", decode_nil)
}

@external(erlang, "pprint_ffi", "decode_custom_type")
@external(javascript, "../pprint_ffi.mjs", "decode_custom_type")
fn decode_custom_type(value: Dynamic) -> Result(Type, Nil)

@external(erlang, "pprint_ffi", "decode_tuple")
@external(javascript, "../pprint_ffi.mjs", "decode_tuple")
fn decode_tuple(value: Dynamic) -> Result(List(Dynamic), Nil)

@external(erlang, "pprint_ffi", "decode_nil")
@external(javascript, "../pprint_ffi.mjs", "decode_nil")
fn decode_nil(value: Dynamic) -> Result(Nil, Nil)
