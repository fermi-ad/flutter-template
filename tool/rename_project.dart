/*
  Configures a project's name and description across all relevant web files.
  Can be run at initial setup or any time the app name/description needs to
  change. Reads the current values from pubspec.yaml and replaces them in:
    - web/index.html  (title, apple-mobile-web-app-title, meta description)
    - web/manifest.json (name, short_name, description)
    - pubspec.yaml (name, description)

  Usage:
    dart run tool/setup_project.dart
*/
import 'dart:io' show File, exitCode, stderr, stdin, stdout;

const _pubspecPath = 'pubspec.yaml';

const List<String> _filesToUpdate = [
  'web/index.html',
  'web/manifest.json',
  _pubspecPath,
];

Future<void> main() async {
  stdout.writeln('=== Flutter Project Name & Description Setup ===\n');

  // Read current values from pubspec.yaml as the source of truth.
  final currentValues = await _readCurrentValues();
  if (currentValues == null) {
    stderr.writeln(
      'Could not parse current name/description from $_pubspecPath. '
      'Ensure the file exists and contains "name:" and "description:" fields.',
    );
    exitCode = 1;
    return;
  }

  final (currentName, currentDescription) = currentValues;
  stdout
    ..writeln('Current name:        $currentName')
    ..writeln('Current description: $currentDescription\n');

  final newName = _prompt(
    'Enter new app name (lowercase, underscores only) [$currentName]: ',
    defaultValue: currentName,
    validate: _isValidDartPackageName,
    validationMessage:
        'Name must be lowercase letters, digits, and underscores only, '
        'and must not start with a digit.',
  );

  final newDescription = _prompt(
    'Enter new description [$currentDescription]: ',
    defaultValue: currentDescription,
  );

  if (newName == currentName && newDescription == currentDescription) {
    stdout.writeln('\nNo changes made (values are unchanged).');
    return;
  }

  stdout.writeln('\nUpdating files...');

  var allSucceeded = true;
  for (final path in _filesToUpdate) {
    final success = await _updateFile(
      path: path,
      oldName: currentName,
      newName: newName,
      oldDescription: currentDescription,
      newDescription: newDescription,
    );
    if (!success) allSucceeded = false;
  }

  if (allSucceeded) {
    stdout
      ..writeln('\nDone! Project updated successfully.')
      ..writeln('  App name:    $newName')
      ..writeln('  Description: $newDescription');
  } else {
    stderr.writeln('\nSetup completed with errors. See above for details.');
    exitCode = 1;
  }
}

/// Reads the current name and description fields from [_pubspecPath].
/// Returns null if either field cannot be found.
Future<(String, String)?> _readCurrentValues() async {
  final file = File(_pubspecPath);
  if (!file.existsSync()) return null;

  final contents = await file.readAsString();

  final nameMatch = RegExp(
    r'^name:\s*(\S+)',
    multiLine: true,
  ).firstMatch(contents);
  final descMatch = RegExp(
    r'^description:\s*(.+)',
    multiLine: true,
  ).firstMatch(contents);

  if (nameMatch == null || descMatch == null) return null;

  return (nameMatch.group(1)!.trim(), descMatch.group(1)!.trim());
}

/// Prompts the user for input. Pressing Enter with no input returns
/// [defaultValue]. Repeats until [validate] passes (if provided).
String _prompt(
  final String message, {
  required final String defaultValue,
  final bool Function(String)? validate,
  final String? validationMessage,
}) {
  while (true) {
    stdout.write(message);
    final raw = stdin.readLineSync()?.trim() ?? '';
    final input = raw.isEmpty ? defaultValue : raw;

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

/// Reads [path], replaces old name/description with new values, and writes
/// the result back. Returns true on success.
Future<bool> _updateFile({
  required final String path,
  required final String oldName,
  required final String newName,
  required final String oldDescription,
  required final String newDescription,
}) async {
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('  [SKIP] $path — file not found.');
    return true; // Not a hard failure; file may not exist in all forks.
  }

  try {
    var contents = await file.readAsString();
    contents = contents
        .replaceAll(oldName, newName)
        .replaceAll(oldDescription, newDescription);
    await file.writeAsString(contents);
    stdout.writeln('  [OK]   $path');
    return true;
  } on Exception catch (e) {
    stderr.writeln('  [ERR]  $path — $e');
    return false;
  }
}
