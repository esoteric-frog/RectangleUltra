# Changelog

All notable changes to this project are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.1.0]

First public release of Rectangle Ultra, a fork of [Rectangle](https://github.com/rxhanson/Rectangle) by Ryan Hanson (MIT).

### Changed from upstream

- Builds with SwiftPM and the Command Line Tools only. No Xcode or Xcode project files; `make app`, `make install` and `make test`.
- Removed the Sparkle auto-updater. The app makes no update checks.
- Own bundle identifier and config folder, so it can sit beside Rectangle.
- URL scheme is `rectangle-ultra://`.
- Vendored MASShortcut, with a fix so it finds its resource bundle outside an Xcode build.
- Added a small XCTest shim so the test suite runs on the Command Line Tools alone.
- Renamed to Rectangle Ultra.
