# Contributing

Thanks for helping. Rectangle Ultra is a small fork of [Rectangle](https://github.com/rxhanson/Rectangle), and small, focused changes are the easiest to review.

## Build and test

You need macOS 14 or later and the Command Line Tools (`xcode-select --install`). You do not need Xcode.

```bash
make app        # builds build/Rectangle Ultra.app
make install    # builds and copies it to /Applications
make test       # runs the test suite
```

Run `make test` before you open a pull request. CI runs the same command.

## Pull requests

- Keep each pull request small and about one thing.
- Match the existing code style.
- Add or update a test when you change behavior.
- Do not add Xcode project files (`.xcodeproj`, `.xcworkspace`). The project builds with SwiftPM and `make` only.
- Describe what you changed and how you checked it.

## Bugs and ideas

Search the existing issues first, open and closed. For a bug, include the Rectangle Ultra version, your macOS version, and what you expected versus what happened. For a feature, open an issue before you write code so we can agree on the idea first.

## Security

Do not open a public issue for a vulnerability. See [SECURITY.md](SECURITY.md).

## License

By contributing you agree that your contributions are licensed under the MIT license in [LICENSE](LICENSE). Rectangle Ultra builds on Rectangle by Ryan Hanson (MIT); keep that credit intact.
