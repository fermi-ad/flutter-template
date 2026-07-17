# flutter_controls_template

The template repo for a new Flutter project.

To use this template for a new project, click "Use this template" at the top
right of its GitHub page. **DON'T clone the repo and commit to it!**

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## How-to Set Up

Step-by-step instructions for how-to set up your project.

Get Dart package dependencies:

```
$ flutter pub get
```

Configure the project name, description, and web metadata (updates
`web/index.html`, `web/manifest.json`, and `pubspec.yaml`):

```
$ dart run tool/rename_project.dart
```

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

```
$ dart run tool/setup_git_hooks.dart
```

## How-to Build

Step-by-step instructions for how-to build your project.

## How-to Test

Each `.dart` file in the `test` subdirectory tree will be run. In each file,
you define tests to run against the public API of your application. You can
run the tests from the command line using:

```
$ flutter test
```

If you are using VSCode as your development environment (highly recommended!),
you can use the "Testing" tab (on the left navigation rail) to choose which
test to run.

## How-to Run

We consider web applications to be our primary target. To run this demo app
in a browser, use the following command in your system's shell:

```
$ flutter run chrome
```

### Mobile Targets

This template is only set up to create web apps as that's our primary platform.
If you want to run your app on a mobile device natively (instead of within a
browser), you can perform the following steps. _Do not commit those changes back
to the template repo!_ It's up to you if you want to commit the mobile app support
in your repo.

Once you've copied this repo (not cloned!) go in the top directory and run

```
$ flutter create --platforms ios .
```

to add iOS as a target. You can only build iOS apps if you have XCode installed.
This also implies you can only do this on a Macintosh computer.

For Android targets, run

```
$ flutter create --platforms android .
```

Mobile device manufacturers try very hard to secure their devices so applications
need to specify which services they intend to use and the user can approve their
request(s) when running it for the first time. Since our framework uses network
services, you need to request network permissions in your app's config.

For Android targets, add the following tag to your `AndroidManifest.xml` file,
immediately after the opening `manifest` tag:

```
<uses-permission android:name="android.permission.INTERNET" />
```

For iOS targets, you need to open the `.xcodeproj` file in `XCode` and add the
permissions for network access in the application's profile. The appropriate
`.xml` files will be modified.

## How-to Deploy

Step-by-step instructions for how-to deploy your project to ad-apps.
