/*
  Configures a Flutter web project's name and description.

  Updates only web application metadata and the package metadata used to
  generate it:
    - pubspec.yaml: name and description
    - web/manifest.json: name, short_name, and description
    - web/index.html: title, Apple web-app title, and description meta tag

  Native platform files and SDK/plugin versions are intentionally out of scope.

  Usage:
    dart run tool/rename_project.dart
*/
import 'dart:convert' show JsonEncoder, jsonDecode;
import 'dart:io' show File, exitCode, stderr, stdin, stdout;

const _pubspecPath = 'pubspec.yaml';
const _manifestPath = 'web/manifest.json';
const _indexPath = 'web/index.html';

class _PreparedFile {
  const _PreparedFile(this.path, this.contents);

  final String path;
  final String contents;
}

class _PreparationResult {
  const _PreparationResult.success([this.file]) : succeeded = true;
  const _PreparationResult.failure() : succeeded = false, file = null;

  final bool succeeded;
  final _PreparedFile? file;
}

Future<void> main() async {
  stdout.writeln('=== Flutter Web Project Rename ===\n');

  final currentValues = await _readCurrentValues();
  if (currentValues == null) {
    stderr.writeln(
      'Could not parse current name/description from $_pubspecPath. '
      'Ensure the file contains string "name" and "description" fields.',
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
    validate: (value) => value.isNotEmpty && !value.contains('\n'),
    validationMessage: 'Display name must be a non-empty single line.',
  );
  final newDescription = _prompt(
    'Enter description [$currentDescription]: ',
    defaultValue: currentDescription,
    validate: (value) => !value.contains('\n'),
    validationMessage: 'Description must be a single line.',
  );

  if (newPackageName == currentPackageName &&
      newDisplayName == currentDisplayName &&
      newDescription == currentDescription) {
    stdout.writeln('\nNo changes made (values are unchanged).');
    return;
  }

  stdout.writeln('\nUpdating files...');
  final files = <String, String>{};
  var allSucceeded = true;

  final results = [
    await _preparePubspec(
      newPackageName: newPackageName,
      newDescription: newDescription,
    ),
    await _prepareManifest(
      newDisplayName: newDisplayName,
      newDescription: newDescription,
    ),
    await _prepareIndexHtml(
      newDisplayName: newDisplayName,
      newDescription: newDescription,
    ),
  ];
  for (final result in results) {
    allSucceeded = allSucceeded && result.succeeded;
    final file = result.file;
    if (file != null) files[file.path] = file.contents;
  }

  if (!allSucceeded) {
    stderr.writeln('\nRename aborted; no files were changed.');
    exitCode = 1;
    return;
  }

  try {
    for (final entry in files.entries) {
      await File(entry.key).writeAsString(entry.value);
      stdout.writeln('  [OK]   ${entry.key}');
    }
  } on Exception catch (error) {
    stderr.writeln('  [ERR]  Could not write files — $error');
    exitCode = 1;
    return;
  }

  stdout
    ..writeln('\nDone! Flutter web project updated successfully.')
    ..writeln('  Package name: $newPackageName')
    ..writeln('  Display name: $newDisplayName')
    ..writeln('  Description:  $newDescription');
}

String _toDisplayName(String packageName) => packageName
    .split('_')
    .map(
      (word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
    )
    .join(' ');

Future<(String, String)?> _readCurrentValues() async {
  final file = File(_pubspecPath);
  if (!file.existsSync()) return null;

  final contents = await file.readAsString();
  final name = _readTopLevelScalar(contents, 'name');
  final description = _readTopLevelScalar(contents, 'description');
  if (name == null || description == null || name.isEmpty) return null;
  return (name, description);
}

/// Reads the single-line scalar fields owned by this tool without adding a
/// YAML package dependency to every application generated from the template.
String? _readTopLevelScalar(String contents, String key) {
  final match = RegExp(
    '^$key:'
    r'\s*(.+?)\s*\r?$',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) return null;

  final value = match.group(1)!.trim();
  if (value.length >= 2 && value.startsWith("'") && value.endsWith("'")) {
    return value.substring(1, value.length - 1).replaceAll("''", "'");
  }
  if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
    try {
      final decoded = jsonDecode(value);
      return decoded is String ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  // A # begins a YAML comment only when preceded by whitespace.
  final commentStart = RegExp(r'\s#').firstMatch(value)?.start;
  return (commentStart == null ? value : value.substring(0, commentStart))
      .trim();
}

Future<_PreparationResult> _preparePubspec({
  required String newPackageName,
  required String newDescription,
}) async {
  final file = File(_pubspecPath);
  if (!file.existsSync()) {
    _reportError(_pubspecPath, 'file not found');
    return const _PreparationResult.failure();
  }
  try {
    final contents = await file.readAsString();
    final namePattern = RegExp(r'^name:\s*.*$', multiLine: true);
    final descriptionPattern = RegExp(r'^description:\s*.*$', multiLine: true);
    if (!namePattern.hasMatch(contents) ||
        !descriptionPattern.hasMatch(contents)) {
      _reportError(_pubspecPath, 'expected name/description field not found');
      return const _PreparationResult.failure();
    }
    final updated = contents
        .replaceFirst(namePattern, 'name: $newPackageName')
        .replaceFirst(
          descriptionPattern,
          'description: ${yamlSingleQuoted(newDescription)}',
        );
    return _PreparationResult.success(_PreparedFile(_pubspecPath, updated));
  } on Exception catch (error) {
    _reportError(_pubspecPath, error.toString());
    return const _PreparationResult.failure();
  }
}

Future<_PreparationResult> _prepareManifest({
  required String newDisplayName,
  required String newDescription,
}) async {
  final file = File(_manifestPath);
  if (!file.existsSync()) {
    stdout.writeln('  [SKIP] $_manifestPath — file not found.');
    return const _PreparationResult.success();
  }
  try {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('root must be an object');
    }
    for (final key in ['name', 'short_name', 'description']) {
      if (!decoded.containsKey(key)) {
        _reportError(_manifestPath, 'required field "$key" not found');
        return const _PreparationResult.failure();
      }
    }
    decoded['name'] = newDisplayName;
    decoded['short_name'] = newDisplayName;
    decoded['description'] = newDescription;
    final encoded = const JsonEncoder.withIndent('    ').convert(decoded);
    return _PreparationResult.success(
      _PreparedFile(_manifestPath, '$encoded\n'),
    );
  } on Exception catch (error) {
    _reportError(_manifestPath, 'invalid JSON — $error');
    return const _PreparationResult.failure();
  }
}

Future<_PreparationResult> _prepareIndexHtml({
  required String newDisplayName,
  required String newDescription,
}) async {
  final file = File(_indexPath);
  if (!file.existsSync()) {
    stdout.writeln('  [SKIP] $_indexPath — file not found.');
    return const _PreparationResult.success();
  }
  try {
    var contents = await file.readAsString();
    final titlePattern = RegExp('<title>[^<]*</title>', caseSensitive: false);
    final appleTitlePattern = RegExp(
      r'''(<meta\s+name=["']apple-mobile-web-app-title["']\s+content=["'])[^"']*(["'])''',
      caseSensitive: false,
    );
    final descriptionPattern = RegExp(
      r'''(<meta\s+name=["']description["']\s+content=["'])[^"']*(["'])''',
      caseSensitive: false,
    );

    if (!titlePattern.hasMatch(contents)) {
      _reportError(_indexPath, 'title element not found');
      return const _PreparationResult.failure();
    }
    contents = contents.replaceFirst(
      titlePattern,
      '<title>${htmlEscape(newDisplayName)}</title>',
    );
    for (final (pattern, value) in [
      (appleTitlePattern, newDisplayName),
      (descriptionPattern, newDescription),
    ]) {
      if (!pattern.hasMatch(contents)) {
        _reportError(_indexPath, 'expected metadata field not found');
        return const _PreparationResult.failure();
      }
      contents = contents.replaceFirstMapped(
        pattern,
        (match) => '${match.group(1)}${htmlEscape(value)}${match.group(2)}',
      );
    }
    return _PreparationResult.success(_PreparedFile(_indexPath, contents));
  } on Exception catch (error) {
    _reportError(_indexPath, error.toString());
    return const _PreparationResult.failure();
  }
}

/// Encodes a single-line YAML value without allowing punctuation to change its
/// meaning.
String yamlSingleQuoted(String value) => "'${value.replaceAll("'", "''")}'";

/// Escapes text for use in HTML text and attribute contexts.
String htmlEscape(String value) => value
    .replaceAll('&', String.fromCharCodes([38, 97, 109, 112, 59]))
    .replaceAll('<', String.fromCharCodes([38, 108, 116, 59]))
    .replaceAll('>', String.fromCharCodes([38, 103, 116, 59]))
    .replaceAll(
      '"',
      String.fromCharCodes([38, 113, 117, 111, 116, 59]),
    )
    .replaceAll("'", String.fromCharCodes([38, 35, 51, 57, 59]));

void _reportError(String path, String message) {
  stderr.writeln('  [ERR]  $path — $message');
}

String _prompt(
  String message, {
  required String defaultValue,
  bool Function(String)? validate,
  String? validationMessage,
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

bool _isValidDartPackageName(String name) =>
    RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);
