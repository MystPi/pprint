import * as $gleam from './gleam.mjs';
import * as $decoder from './pprint/decoder.mjs';

export function decode_custom_type(value) {
  if (value instanceof $gleam.CustomType) {
    const name = value.constructor.name;
    const fields = Object.keys(value).map((label) => {
      return isNaN(parseInt(label))
        ? new $decoder.Labelled(label, value[label])
        : new $decoder.Positional(value[label]);
    });

    return new $gleam.Ok(new $decoder.TCustom(name, $gleam.toList(fields)));
  }

  return new $gleam.Error(undefined);
}

export function decode_tuple(value) {
  if (Array.isArray(value)) return new $gleam.Ok($gleam.toList(value));
  return new $gleam.Error(undefined);
}

export function decode_nil(value) {
  if (value === undefined) return new $gleam.Ok(undefined);
  return new $gleam.Error(undefined);
}

export function from(value) {
  return value
}