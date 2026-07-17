/*
  Configures a project's name and description across all relevant web files.
  Can be run at initial setup or any time the app name/description needs to
  change. Reads the current values from pubspec.yaml and replaces them in:
    - pubspec.yaml       name (package identifier, underscores required)
                         description
    - web/manifest.json  name, short_name (display names, spaces allowed)
                         description
    - web/index.html     <title>, apple-mobile-web-app-title (display names)
                         meta description

  Usage:
    dart run tool/rename_project.dart
*/
import 'dart:io' show File, exitCode, stderr, stdin, stdout;

const _pubspecPath = 'pubspec.yaml';
const _manifestPath = 'web/manifest.json';
const _indexPath = 'web/index.html';

Future<void> main() async {
  stdout.writeln('=== Flutter Project Rename ===\n');

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

  final (currentPackageName, currentDescription) = currentValues;
  final currentDisplayName = _toDisplayName(currentPackageName);

  stdout
    ..writeln('Current package name: $currentPackageName')
    ..writeln('Current display name: $currentDisplayName')
    ..writeln('Current description:  $currentDescription\n');

  final newPackageName = _prompt(
    'Enter new package name (lowercase, underscores only)'
    ' [$currentPackageName]: ',
    defaultValue: currentPackageName,
    validate: _isValidDartPackageName,
    validationMessage:
        'Name must be lowercase letters, digits, and underscores only, '
        'and must not start with a digit.',
  );

  final defaultDisplayName = _toDisplayName(newPackageName);
  final newDisplayName = _prompt(
    'Enter display name (shown in browser/PWA) [$defaultDisplayName]: ',
    defaultValue: defaultDisplayName,
  );

  final newDescription = _prompt(
    'Enter description [$currentDescription]: ',
    defaultValue: currentDescription,
  );

  final nameUnchanged =
      newPackageName == currentPackageName &&
      newDisplayName == currentDisplayName;
  if (nameUnchanged && newDescription == currentDescription) {
    stdout.writeln('\nNo changes made (values are unchanged).');
    return;
  }

  stdout.writeln('\nUpdating files...');

  var allSucceeded = true;

  allSucceeded &= await _updatePubspec(
    oldPackageName: currentPackageName,
    newPackageName: newPackageName,
    oldDescription: currentDescription,
    newDescription: newDescription,
  );

  allSucceeded &= await _updateManifest(
    oldDisplayName: currentDisplayName,
    newDisplayName: newDisplayName,
    oldDescription: currentDescription,
    newDescription: newDescription,
  );

  allSucceeded &= await _updateIndexHtml(
    oldDisplayName: currentDisplayName,
    newDisplayName: newDisplayName,
    oldDescription: currentDescription,
    newDescription: newDescription,
  );

  if (allSucceeded) {
    stdout
      ..writeln('\nDone! Project updated successfully.')
      ..writeln('  Package name: $newPackageName')
      ..writeln('  Display name: $newDisplayName')
      ..writeln('  Description:  $newDescription');
  } else {
    stderr.writeln('\nRename completed with errors. See above for details.');
    exitCode = 1;
  }
}

/// Converts a package name (underscores) to a title-cased display name.
/// Example: "my_cool_app" → "My Cool App"
String _toDisplayName(final String packageName) {
  return packageName
      .split('_')
      .map(
        (word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
      )
      .join(' ');
}

/// Reads the current package name and description from [_pubspecPath].
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

/// Updates [_pubspecPath] with the new package name and description.
Future<bool> _updatePubspec({
  required final String oldPackageName,
  required final String newPackageName,
  required final String oldDescription,
  required final String newDescription,
}) async {
  return _replaceInFile(
    path: _pubspecPath,
    replacements: [
      (
        RegExp('^name: ${RegExp.escape(oldPackageName)}', multiLine: true),
        'name: $newPackageName',
      ),
      (
        RegExp(
          '^description: ${RegExp.escape(oldDescription)}',
          multiLine: true,
        ),
        'description: $newDescription',
      ),
    ],
  );
}

/// Updates [_manifestPath] with the new display name and description.
Future<bool> _updateManifest({
  required final String oldDisplayName,
  required final String newDisplayName,
  required final String oldDescription,
  required final String newDescription,
}) async {
  return _replaceInFile(
    path: _manifestPath,
    replacements: [
      (
        RegExp('"name":\\s*"${RegExp.escape(oldDisplayName)}"'),
        '"name": "$newDisplayName"',
      ),
      (
        RegExp('"short_name":\\s*"${RegExp.escape(oldDisplayName)}"'),
        '"short_name": "$newDisplayName"',
      ),
      (
        RegExp('"description":\\s*"${RegExp.escape(oldDescription)}"'),
        '"description": "$newDescription"',
      ),
    ],
  );
}

/// Updates [_indexPath] with the new display name and description.
Future<bool> _updateIndexHtml({
  required final String oldDisplayName,
  required final String newDisplayName,
  required final String oldDescription,
  required final String newDescription,
}) async {
  return _replaceInFile(
    path: _indexPath,
    replacements: [
      (
        RegExp(
          'content="${RegExp.escape(oldDisplayName)}"',
        ),
        'content="$newDisplayName"',
      ),
      (
        RegExp('<title>${RegExp.escape(oldDisplayName)}</title>'),
        '<title>$newDisplayName</title>',
      ),
      (
        RegExp(
          'name="description" content="${RegExp.escape(oldDescription)}"',
        ),
        'name="description" content="$newDescription"',
      ),
    ],
  );
}

/// Applies a list of regex [replacements] to the file at [path].
/// Returns true on success.
Future<bool> _replaceInFile({
  required final String path,
  required final List<(RegExp, String)> replacements,
}) async {
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('  [SKIP] $path — file not found.');
    return true; // Not a hard failure; file may not exist in all forks.
  }

  try {
    var contents = await file.readAsString();
    for (final (pattern, replacement) in replacements) {
      contents = contents.replaceAll(pattern, replacement);
    }
    await file.writeAsString(contents);
    stdout.writeln('  [OK]   $path');
    return true;
  } on Exception catch (e) {
    stderr.writeln('  [ERR]  $path — $e');
    return false;
  }
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
