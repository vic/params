# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [2.3.0] - 2025-02-27

### Documentation

* Miscellaneous documentation changes, including updates for HexDocs.pm. (#37 by @kianmeng)
* Add example typecasting of atoms using `Ecto.Enum`. (#38 by @Ziinc)

### Fixed

* Add `:logger` to `extra_applications` in `mix.exs` to fix Elixir 1.11 compiler warnings. (#35 by @greg-rychlewski)
* Fix compile-time warnings in Elixir 1.14.3. (#43 by @tiagopog)
* Suppress warnings in Elixir 1.17 and 1.18. (#46 by @k-asm)

## [2.2.0] - 2020-06-06

### Added

* Add reusable embeds schemas with `defparams`. (#30 by @nirev)

## [2.1.1] - 2019-01-07

### Changed

* Upgrade `ex_doc` to `~> 0.19`.

## [2.0.6] - 2019-01-07

### Changed

* Scope modules created by `defparams` to defining module namespace. (#24 by @jgautsch)

### Fixed

* Fix typo. (#26 by @accua)

### Added

* Adds compatibility with Ecto 3.0. (#29 by @lasseebert)

## [2.0.5] - 2017-07-26

### Fixed

* Fix Elixir 1.5 warnings. (#23 by @take-five)

## [2.0.4] - 2017-07-24

### Fixed

* Fix incorrect `Params.Behaviour.data/2` typespec. (#22 by @take-five)

## [2.0.3] - 2017-07-17

### Fixed

* Make defaults work with plain `use Params.Schema` in `to_map` function. (#17 by @astery)
* Fixed Elixir 1.4 warnings. (#18 by @astery)
* Fix Dialyzer warnings for Elixir 1.4/OTP 20. (#21 by @take-five)

## [2.0.2] - 2016-12-18

### Added

* This changelog.

### Changed

* Relaxed ecto dependency to 2.0 and elixir >=1.3 (#16 by @lasseebert)

## [2.0.1] - 2016-07-11

### Added

* Support for ecto 2.0

### Changed

* to_map now only returns the submitted keys and keys with default values. (#10 by @lasseebert)

[Unreleased]: https://github.com/vic/params/compare/v2.3.0...HEAD
[2.3.0]: https://github.com/vic/params/compare/v2.1.1...v2.3.0
[2.2.0]: https://github.com/vic/params/compare/v2.1.1...v2.2.0
[2.1.1]: https://github.com/vic/params/compare/v2.0.6...v2.1.1
[2.0.6]: https://github.com/vic/params/compare/v2.0.5...v2.0.6
[2.0.5]: https://github.com/vic/params/compare/v2.0.4...v2.0.5
[2.0.4]: https://github.com/vic/params/compare/v2.0.3...v2.0.4
[2.0.3]: https://github.com/vic/params/compare/v2.0.2...v2.0.3
[2.0.2]: https://github.com/vic/params/compare/v2.0.1...v2.0.2
[2.0.1]: https://github.com/vic/params/compare/c9fea01594...v2.0.1
[issues]: https://github.com/vic/issues
