# pprint

[![Package Version](https://img.shields.io/hexpm/v/pprint)](https://hex.pm/packages/pprint)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/pprint/)

💄 Pretty print values with style!

```sh
gleam add pprint --dev
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
