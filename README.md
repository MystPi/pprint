# pprint

[![Package Version](https://img.shields.io/hexpm/v/pprint)](https://hex.pm/packages/pprint)
[![Erlang-compatible](https://img.shields.io/badge/target-erlang-b83998)](https://www.erlang.org/)
[![JavaScript Compatible](https://img.shields.io/badge/target-javascript-f3e155)](https://en.wikipedia.org/wiki/JavaScript)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/pprint/)
[![CI Test](https://github.com/MystPi/pprint/actions/workflows/test.yml/badge.svg?branch=master&amp;event=push)](https://github.com/MystPi/pprint/actions/workflows/test.yml)

💄 Pretty print values with style!

```sh
gleam add pprint@1 --dev
```

```gleam
import pprint

pub fn main() {
  Ok(["my", "super", "awesome", "useless", "list"])
  |> pprint.debug
}

// Prints (with color!):
// Ok([
//   "my",
//   "super",
//   "awesome",
//   "useless",
//   "list",
// ])
```

Further documentation can be found at <https://hexdocs.pm/pprint>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
