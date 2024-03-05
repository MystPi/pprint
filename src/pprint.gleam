import gleam/io
import gleam/int
import gleam/bool
import gleam/list
import gleam/float
import gleam/dict.{type Dict}
import gleam/string
import gleam/dynamic.{type Dynamic}
import gleam/bit_array
import glam/doc.{type Document}
import pprint/decoder

// --- PUBLIC API --------------------------------------------------------------

/// Configuration for the pretty printer.
///
pub type Config {
  Config(
    style_mode: StyleMode,
    bit_array_mode: BitArrayMode,
    labels_mode: LabelsMode,
  )
}

/// Styling can be configured with `StyleMode`.
///
pub type StyleMode {
  /// Data structures are styled with ANSI style codes.
  Styled
  /// Everything remains unstyled.
  Unstyled
}

/// Since Erlang handles BitArrays differently than JavaScript does, the
/// `BitArraysAsString` config option enables compatibility between the two targets.
///
/// These options only affect the JS target, which does not convert bit arrays to
/// strings by default like Erlang does.
///
pub type BitArrayMode {
  /// Bit arrays will be converted to strings when pretty printed.
  BitArraysAsString
  /// Bit arrays will be kept the same.
  KeepBitArrays
}

/// This option only affects the JavaScript target since Erlang has a different
/// runtime representation of custom types that omits labels.
///
pub type LabelsMode {
  /// Show field labels in custom types.
  /// ```
  /// Foo(42, bar: "bar", baz: "baz")
  /// ```
  Labels
  /// Leave out field labels.
  /// ```
  /// Foo(42, "bar", "baz")
  /// ```
  NoLabels
}

const max_width = 40

/// Pretty print a value with the config below to stderr for debugging purposes.
/// The value is returned back from the function so it can be used in pipelines.
///
/// ```
/// Config(Styled, KeepBitArrays, Labels)
/// ```
///
/// # Examples
///
/// ```
/// pprint.debug([1, 2, 3])
/// |> list.each(pprint.debug)
///
/// // Prints:
/// // [1, 2, 3]
/// // 1
/// // 2
/// // 3
/// ```
///
pub fn debug(value: a) -> a {
  value
  |> with_config(Config(Styled, KeepBitArrays, Labels))
  |> io.println_error

  value
}

/// Pretty print a value as a string with the following config:
/// ```
/// Config(Unstyled, BitArraysAsString, NoLabels)
/// ```
/// This function behaves identically on both targets so it can be relied upon
/// for snapshot testing.
///
pub fn format(value: a) -> String {
  with_config(value, Config(Unstyled, BitArraysAsString, NoLabels))
}

/// Pretty print a value as a string with the following config:
/// ```
/// Config(Styled, BitArraysAsString, NoLabels)
/// ```
/// This function behaves identically on both targets so it can be relied upon
/// for snapshot testing.
///
pub fn styled(value: a) -> String {
  with_config(value, Config(Styled, BitArraysAsString, NoLabels))
}

/// Pretty print a value as a string with a custom config.
///
/// # Examples
///
/// ```
/// [1, 2, 3, 4]
/// |> pprint.with_config(Config(Color, KeepBitArrays, Labels))
/// ```
///
pub fn with_config(value: a, config: Config) -> String {
  value
  |> dynamic.from
  |> pretty_dynamic(config)
  |> doc.to_string(max_width)
}

// ---- PRETTY PRINTING --------------------------------------------------------

fn pretty_type(value: decoder.Type, config: Config) -> Document {
  case value {
    decoder.TString(s) -> pretty_string(s, config)

    decoder.TInt(i) ->
      int.to_string(i)
      |> ansi(yellow, config)

    decoder.TFloat(f) ->
      float.to_string(f)
      |> ansi(yellow, config)

    decoder.TBool(b) ->
      bool.to_string(b)
      |> ansi(blue, config)

    decoder.TBitArray(b) ->
      case config.bit_array_mode {
        KeepBitArrays -> pretty_bit_array(b, config)
        BitArraysAsString ->
          case bit_array.to_string(b) {
            Ok(s) -> pretty_string(s, config)
            Error(Nil) -> pretty_bit_array(b, config)
          }
      }

    decoder.TNil -> ansi("Nil", blue, config)
    decoder.TList(items) -> pretty_list(items, config)
    decoder.TDict(d) -> pretty_dict(d, config)
    decoder.TTuple(items) -> pretty_tuple(items, config)
    decoder.TCustom(name, fields) -> pretty_custom_type(name, fields, config)
    decoder.TForeign(f) -> ansi(f, dim, config)
  }
}

fn pretty_dynamic(value: Dynamic, config: Config) -> Document {
  value
  |> decoder.classify
  |> pretty_type(config)
}

fn pretty_string(string: String, config: Config) -> Document {
  { "\"" <> string <> "\"" }
  |> ansi(green, config)
}

fn pretty_bit_array(bits: BitArray, config: Config) -> Document {
  string.inspect(bits)
  |> ansi(magenta, config)
}

fn pretty_list(items: List(Dynamic), config: Config) -> Document {
  let items = list.map(items, decoder.classify)

  // When the list consists only of numbers, the values are joined with flex spaces
  // instead of normal ones.
  let space = case items {
    [decoder.TInt(_), ..] | [decoder.TFloat(_), ..] -> doc.flex_space
    _ -> doc.space
  }

  list.map(items, pretty_type(_, config))
  |> doc.concat_join([doc.from_string(","), space])
  |> wrap(doc.from_string("["), doc.from_string("]"), trailing: ",")
}

fn pretty_dict(d: Dict(decoder.Type, decoder.Type), config: Config) -> Document {
  dict.to_list(d)
  |> list.sort(fn(one_field, other_field) {
    // We need to sort dicts so that those always have a consistent order.
    let #(one_key, _one_value) = one_field
    let #(other_key, _other_value) = other_field
    string.compare(string.inspect(one_key), string.inspect(other_key))
  })
  |> list.map(fn(field) {
    // Format the dict's items into tuple literals
    [
      pretty_type(field.0, config),
      doc.from_string(", "),
      pretty_type(field.1, config),
    ]
    |> doc.concat
    |> doc.prepend(doc.from_string("#("))
    |> doc.append(doc.from_string(")"))
  })
  |> doc.concat_join([doc.from_string(","), doc.space])
  |> wrap(
    doc.from_string("dict.from_list(["),
    doc.from_string("])"),
    trailing: ",",
  )
}

fn pretty_tuple(items: List(Dynamic), config: Config) -> Document {
  list.map(items, pretty_dynamic(_, config))
  |> doc.concat_join([doc.from_string(","), doc.space])
  |> wrap(doc.from_string("#("), doc.from_string(")"), trailing: ",")
}

fn pretty_custom_type(
  name: String,
  fields: List(decoder.Field),
  config: Config,
) -> Document {
  // Common built-in constructor names are styled
  let style = case name {
    "Ok" | "Error" | "Some" | "None" -> bold
    _ -> ""
  }

  let fields =
    list.map(fields, fn(field) {
      case field, config.labels_mode {
        decoder.Positional(value), Labels
        | decoder.Positional(value), NoLabels
        | decoder.Labelled(_, value), NoLabels -> pretty_dynamic(value, config)

        decoder.Labelled(label, value), Labels ->
          doc.concat([
            ansi(label <> ": ", dim, config),
            pretty_dynamic(value, config),
          ])
      }
    })

  let open = doc.concat([ansi(name, style, config), doc.from_string("(")])
  let close = doc.from_string(")")

  case fields {
    [] -> doc.from_string(name)
    // If the constructor has only one field, it is formatted without indenting
    // its field to improve readability. In other words, it is formatted like this
    //
    //   Ok([
    //     // ...
    //   ])
    //
    // instead of this:
    //
    //  Ok(
    //    [
    //      // ...
    //    ]
    //  )
    //
    [single] ->
      single
      |> doc.prepend(open)
      |> doc.append(close)
    // However, multiple fields are indented because they would look weird otherwise.
    _ ->
      fields
      |> doc.concat_join([doc.from_string(","), doc.space])
      |> wrap(open, close, trailing: ",")
  }
}

// ---- ANSI -------------------------------------------------------------------

// Sadly packages like `gleam_community_ansi` cannot be used with Glam since ANSI
// escape codes need to be wrapped with `doc.zero_width_string` calls.

const reset = "\u{001b}[0m"

const green = "\u{001b}[38;5;2m"

const yellow = "\u{001b}[38;5;3m"

const blue = "\u{001b}[38;5;4m"

const magenta = "\u{001b}[38;5;5m"

const bold = "\u{001b}[1m"

const dim = "\u{001b}[2m"

fn ansi(text: String, code: String, config: Config) -> Document {
  let text_doc = doc.from_string(text)

  case config.style_mode {
    Unstyled -> text_doc
    Styled ->
      doc.concat([
        doc.zero_width_string(code),
        text_doc,
        doc.zero_width_string(reset),
      ])
  }
}

// ---- UTILS ------------------------------------------------------------------

fn wrap(
  document: Document,
  open: Document,
  close: Document,
  trailing trailing: String,
) -> Document {
  document
  |> doc.prepend_docs([open, doc.soft_break])
  |> doc.nest(by: 2)
  |> doc.append_docs([doc.break("", trailing), close])
  |> doc.group
}
