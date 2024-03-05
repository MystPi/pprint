import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
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
  let assert Ok(t) = decode_type(value)
  t
}

/// This decoder will always be `Ok`. It returns `Result` so that it is compatible
/// with other decoders.
///
fn decode_type(value: Dynamic) -> Result(Type, List(dynamic.DecodeError)) {
  use <- result.lazy_or(result.map(dynamic.int(value), TInt))
  use <- result.lazy_or(result.map(dynamic.float(value), TFloat))
  use <- result.lazy_or(result.map(dynamic.string(value), TString))
  use <- result.lazy_or(result.map(dynamic.bool(value), TBool))
  use <- result.lazy_or(result.map(decode_nil(value), fn(_) { TNil }))
  use <- result.lazy_or(result.map(dynamic.bit_array(value), TBitArray))
  use <- result.lazy_or(decode_custom_type(value))
  use <- result.lazy_or(result.map(decode_tuple(value), TTuple))
  use <- result.lazy_or(result.map(dynamic.shallow_list(value), TList))
  use <- result.lazy_or(result.map(
    dynamic.dict(decode_type, decode_type)(value),
    TDict,
  ))
  // Anything else we just inspect. This could be a function or an external object
  // or type from the runtime.
  Ok(TForeign(string.inspect(value)))
}

@external(erlang, "ffi", "decode_custom_type")
@external(javascript, "../ffi.mjs", "decode_custom_type")
fn decode_custom_type(value: Dynamic) -> Result(Type, List(dynamic.DecodeError))

@external(erlang, "ffi", "decode_tuple")
@external(javascript, "../ffi.mjs", "decode_tuple")
fn decode_tuple(
  value: Dynamic,
) -> Result(List(Dynamic), List(dynamic.DecodeError))

@external(erlang, "ffi", "decode_nil")
@external(javascript, "../ffi.mjs", "decode_nil")
fn decode_nil(value: Dynamic) -> Result(Nil, List(dynamic.DecodeError))
