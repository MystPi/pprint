import gleam/io
import gleam/int
import gleam/bool
import gleam/list
import gleam/float
import gleam/dict.{type Dict}
import gleam/string
import gleam/dynamic.{type Dynamic}
import glam/doc.{type Document}
import pprint/decoder

// --- PUBLIC API --------------------------------------------------------------

const max_width = 40

/// Pretty print a value with coloring to stderr for debugging purposes. The value
/// is returned back from the function so it can be used in pipelines.
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
  |> format_colored
  |> io.println_error

  value
}

/// Prettify a value into a string, without coloring. This is useful for snapshot
/// testing with packages such as `birdie`.
///
pub fn format(value: a) -> String {
  value
  |> dynamic.from
  |> pretty_dynamic(False)
  |> doc.to_string(max_width)
}

/// Prettify a value into a string with ANSI coloring.
///
pub fn format_colored(value: a) -> String {
  value
  |> dynamic.from
  |> pretty_dynamic(True)
  |> doc.to_string(max_width)
}

// ---- PRETTY PRINTING --------------------------------------------------------

fn pretty_type(value: decoder.Type, color: Bool) -> Document {
  case value {
    decoder.TString(s) ->
      { "\"" <> s <> "\"" }
      |> ansi(green, color)

    decoder.TInt(i) ->
      int.to_string(i)
      |> ansi(yellow, color)

    decoder.TFloat(f) ->
      float.to_string(f)
      |> ansi(yellow, color)

    decoder.TBool(b) ->
      bool.to_string(b)
      |> ansi(blue, color)

    decoder.TBitArray(b) ->
      string.inspect(b)
      |> ansi(magenta, color)

    decoder.TNil -> ansi("Nil", blue, color)
    decoder.TList(items) -> pretty_list(items, color)
    decoder.TDict(d) -> pretty_dict(d, color)
    decoder.TTuple(items) -> pretty_tuple(items, color)
    decoder.TCustom(name, fields) -> pretty_custom_type(name, fields, color)
    decoder.TForeign(f) -> ansi(f, dim, color)
  }
}

fn pretty_dynamic(value: Dynamic, color: Bool) -> Document {
  value
  |> decoder.classify
  |> pretty_type(color)
}

fn pretty_list(items: List(Dynamic), color: Bool) -> Document {
  let items = list.map(items, decoder.classify)

  // When the list consists only of numbers, the values are joined with flex spaces
  // instead of normal ones.
  let space = case items {
    [decoder.TInt(_), ..] | [decoder.TFloat(_), ..] -> doc.flex_space
    _ -> doc.space
  }

  list.map(items, pretty_type(_, color))
  |> doc.concat_join([doc.from_string(","), space])
  |> wrap(doc.from_string("["), doc.from_string("]"), trailing: ",")
}

fn pretty_dict(d: Dict(decoder.Type, decoder.Type), color: Bool) -> Document {
  dict.to_list(d)
  |> list.map(fn(field) {
    // Format the dict's items into tuple literals
    [
      pretty_type(field.0, color),
      doc.from_string(", "),
      pretty_type(field.1, color),
    ]
    |> doc.concat
    |> nobreak_wrap(doc.from_string("#("), doc.from_string(")"))
  })
  |> doc.concat_join([doc.from_string(","), doc.space])
  |> wrap(
    doc.from_string("dict.from_list(["),
    doc.from_string("])"),
    trailing: ",",
  )
}

fn pretty_tuple(items: List(Dynamic), color: Bool) -> Document {
  list.map(items, pretty_dynamic(_, color))
  |> doc.concat_join([doc.from_string(","), doc.space])
  |> wrap(doc.from_string("#("), doc.from_string(")"), trailing: ",")
}

fn pretty_custom_type(
  name: String,
  fields: List(Dynamic),
  color: Bool,
) -> Document {
  // Common built-in constructor names are styled
  let style = case name {
    "Ok" | "Error" | "Some" | "None" -> bold
    _ -> ""
  }

  let fields = list.map(fields, pretty_dynamic(_, color))
  let open = doc.concat([ansi(name, style, color), doc.from_string("(")])
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
      |> nobreak_wrap(open, close)
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

fn ansi(text: String, code: String, enabled: Bool) -> Document {
  let text_doc = doc.from_string(text)

  case enabled {
    False -> text_doc
    True ->
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

fn nobreak_wrap(document: Document, open: Document, close: Document) -> Document {
  document
  |> doc.prepend(open)
  |> doc.append(close)
  |> doc.group
}
