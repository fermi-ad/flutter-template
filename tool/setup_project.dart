/*
  Configures a new project created from the flutter-template by replacing
  the template's placeholder app name and description across all relevant
  files:
    - web/index.html  (title, apple-mobile-web-app-title, meta description)
    - web/manifest.json (name, short_name, description)
    - pubspec.yaml (name, description)

  Usage:
    dart run tool/setup_project.dart
*/
import 'dart:io' show File, exitCode, stderr, stdin, stdout;

const _templateName = 'flutter_controls_template';
const _templateDescription = 'A new Flutter project.';

const _filesToUpdate = [
  'web/index.html',
  'web/manifest.json',
  'pubspec.yaml',
];

Future<void> main() async {
  stdout.writeln('=== Flutter Template Project Setup ===\n');

  final appName = _prompt(
    'Enter the app name (lowercase, underscores only, e.g. my_app): ',
    validate: _isValidDartPackageName,
    validationMessage:
        'Name must be lowercase letters, digits, and underscores only, '
        'and must not start with a digit.',
  );

  final appDescription = _prompt(
    'Enter a short description of the app: ',
  );

  stdout.writeln('\nUpdating files...');

  var allSucceeded = true;
  for (final path in _filesToUpdate) {
    final success = await _updateFile(
      path: path,
      appName: appName,
      appDescription: appDescription,
    );
    if (!success) allSucceeded = false;
  }

  if (allSucceeded) {
    stdout
      ..writeln('\nDone! Project configured successfully.')
      ..writeln('  App name:        $appName')
      ..writeln('  Description:     $appDescription')
      ..writeln(
        '\nRemember to replace the placeholder icons in web/icons/ and '
        'web/favicon.png with your own branded images.',
      );
  } else {
    stderr.writeln('\nSetup completed with errors. See above for details.');
    exitCode = 1;
  }
}

/// Prompts the user for input, repeating until [validate] passes (if provided).
String _prompt(
  final String message, {
  final bool Function(String)? validate,
  final String? validationMessage,
}) {
  while (true) {
    stdout.write(message);
    final input = stdin.readLineSync()?.trim() ?? '';
    if (input.isEmpty) {
      stderr.writeln('Input cannot be empty. Please try again.');
      continue;
    }
    if (validate != null && !validate(input)) {
      stderr.writeln(validationMessage ?? 'Invalid input. Please try again.');
      continue;
    }
    return input;
  }
}

/// Returns true if [name] is a valid Dart package identifier:
/// lowercase letters, digits, and underscores; must not start with a digit.
bool _isValidDartPackageName(final String name) {
  return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);
}

/// Reads [path], replaces the template name and description with the provided
/// values, and writes the result back. Returns true on success.
Future<bool> _updateFile({
  required final String path,
  required final String appName,
  required final String appDescription,
}) async {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('  [SKIP] $path — file not found.');
    return true; // Not a hard failure; file may not exist in all forks.
  }

  try {
    var contents = await file.readAsString();
    contents = contents
        .replaceAll(_templateName, appName)
        .replaceAll(_templateDescription, appDescription);
    await file.writeAsString(contents);
    stdout.writeln('  [OK]   $path');
    return true;
  } on Exception catch (e) {
    stderr.writeln('  [ERR]  $path — $e');
    return false;
  }
}
