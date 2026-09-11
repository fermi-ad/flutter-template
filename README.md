# flutter_controls_template

The template repo for a new Flutter web application.

To use this template for a new project, click "Use this template" at the top
right of its GitHub page. **DON'T clone the repo and commit to it!**

## Getting Started

This project is a starting point for a Flutter web application.

A few resources to get started with Flutter:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter documentation](https://docs.flutter.dev/)

## Prerequisites

- Flutter installed from the [official installation guide](https://docs.flutter.dev/get-started/install).
- Flutter on the stable channel.
- A Flutter SDK compatible with the `environment` constraints in `pubspec.yaml`.
- A supported browser, such as Chrome or Edge.

Verify the local installation before setup:

```shell
flutter --version
flutter doctor
```

This template targets **Flutter web applications**. Native platform metadata and
native plugin configuration for iOS, Android, Windows, macOS, and Linux are
intentionally outside the scope of this template and its rename tool. If native
platforms are added later, configure their application identifiers and display
metadata separately using Flutter's platform documentation.

## How-to Set Up

Get Dart package dependencies:

```shell
flutter pub get
```

Configure the project name and description across the supported web metadata
files. The script prompts for a **package name** (lowercase with underscores,
used in `pubspec.yaml`) and a **display name** (human-readable, used in the
browser title bar and PWA name — auto-derived from the package name but
customizable). It can be re-run at any time to rename the project.

```shell
dart run tool/rename_project.dart
```

The rename tool updates only:

- `pubspec.yaml`: package name and description;
- `web/manifest.json`: PWA name, short name, and description;
- `web/index.html`: browser title, Apple web-app title, and description meta tag.

Values are escaped for YAML, JSON, and HTML. The tool validates the expected
metadata fields before writing, and aborts without writing if a required field
is missing or a target file is malformed. It does not upgrade SDKs, plugins, or
other dependencies. If dependency resolution fails, use `flutter pub outdated`
and the official Flutter/package documentation to resolve that separately.

By default, this template uses the Fermilab logo for the favicon. To replace the icons with your own desired images:

| File                              | Size       | Purpose                       |
| --------------------------------- | ---------- | ----------------------------- |
| `web/favicon.png`                 | 32×32 px   | Browser tab icon              |
| `web/icons/Icon-192.png`          | 192×192 px | PWA / home screen icon        |
| `web/icons/Icon-512.png`          | 512×512 px | PWA splash / large icon       |
| `web/icons/Icon-maskable-192.png` | 192×192 px | Android adaptive icon         |
| `web/icons/Icon-maskable-512.png` | 512×512 px | Android adaptive icon (large) |

All icons must be **PNG** files. A 512×512 master image is sufficient to
downscale from. For maskable icons, keep the logo within the central 80%
"safe zone" — the outer 10% on each edge may be cropped by the OS.

Set up the [pre-commit hook](https://pub.dev/packages/dart_pre_commit):

```shell
dart run tool/setup_git_hooks.dart
```

## How-to Build

Step-by-step instructions for how-to build your project.

## How-to Test

Each `.dart` file in the `test` subdirectory tree will be run. Run the tests with:

```shell
flutter test
```

## How-to Run

We consider web applications to be our primary target. To run this app in a browser:

```shell
flutter run chrome
```

For help getting started with Flutter web, view the
[Flutter web documentation](https://docs.flutter.dev/platform-integration/web).
