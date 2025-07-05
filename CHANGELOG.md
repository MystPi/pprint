# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## v1.0.6 - 2025-07-05

### Fixed

- Upgraded dependencies to fix recent `gleam_stdlib` compatibility.

## v1.0.5 - 2025-04-03

### Fixed

- Update to use new decoder API. ([#7](https://github.com/MystPi/pprint/pull/7))

## v1.0.4 - 2024-10-25

### Fixed

- A bug where dictionaries were not being broken the right way. ([#5](https://github.com/MystPi/pprint/issues/5))

## v1.0.3 - 2024-04-26

### Changed

- Upgraded dependencies and Glam to fix recursion depth errors on the JavaScript target.

## v1.0.2 - 2024-04-22

### Fixed

- FFI module name clashing with other packages
- The `None` type not being bolded

## v1.0.1 - 2024-04-06

### Fixed

- A bug where custom types with no fields were decoded incorrectly on the Erlang target

## v1.0.0 - 2024-03-05

- Initial release
