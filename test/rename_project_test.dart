import 'dart:convert' show base64, jsonDecode;
import 'dart:io' show Directory, File, Process, ProcessResult;

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory fixture;
  late File script;

  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('rename_project_test_');
    final toolDirectory = Directory('${fixture.path}/tool')..createSync();
    script = File('${toolDirectory.path}/rename_project.dart');
    await script.writeAsString(
      await File('tool/rename_project.dart').readAsString(),
    );
  });

  tearDown(() async {
    if (fixture.existsSync()) await fixture.delete(recursive: true);
  });

  test('escapes punctuation across pubspec, manifest, and HTML', () async {
    Directory('${fixture.path}/web').createSync();
    await File('${fixture.path}/pubspec.yaml').writeAsString('''
name: old_app
description: A new Flutter project.
''');
    await File('${fixture.path}/web/manifest.json').writeAsString('''
{
  "name": "Old App",
  "short_name": "Old App",
  "description": "A new Flutter project.",
  "display": "standalone"
}
''');
    await File('${fixture.path}/web/index.html').writeAsString('''
<html><head>
<meta name="description" content="A new Flutter project.">
<meta name="apple-mobile-web-app-title" content="Old App">
<title>Old App</title>
</head></html>
''');

    final result = await _runRename(
      fixture,
      'new_app\nNew <App> & Co.\nA "special": app #1 <ready> & done\n',
    );

    expect(result.exitCode, 0, reason: result.stderr as String);
    final pubspec = await File('${fixture.path}/pubspec.yaml').readAsString();
    expect(
      pubspec,
      contains("description: 'A \"special\": app #1 <ready> & done'"),
    );

    final manifest = jsonDecode(
      await File('${fixture.path}/web/manifest.json').readAsString(),
    ) as Map<String, dynamic>;
    expect(manifest['name'], 'New <App> & Co.');
    expect(manifest['short_name'], 'New <App> & Co.');
    expect(manifest['description'], 'A "special": app #1 <ready> & done');

    final html = await File('${fixture.path}/web/index.html').readAsString();
    expect(html, contains(_entityText('<App> & Co.')));
    expect(
      html,
      contains(_entityText('New <App> & Co.')),
    );
    expect(
      html,
      contains(
        _entityText('"special": app #1 <ready> & done'),
      ),
    );
  });

  test(
    'fails without changing files when required metadata is absent',
    () async {
      Directory('${fixture.path}/web').createSync();
      await File('${fixture.path}/pubspec.yaml').writeAsString(
        'name: old_app\ndescription: A new Flutter project.\n',
      );
      final manifest = File('${fixture.path}/web/manifest.json');
      await manifest.writeAsString(
        '{"name":"Old App","description":"A new Flutter project."}\n',
      );
      final originalManifest = await manifest.readAsString();
      await File('${fixture.path}/web/index.html').writeAsString('''
<title>Old App</title>
<meta name="description" content="A new Flutter project.">
<meta name="apple-mobile-web-app-title" content="Old App">
''');

      final result = await _runRename(
        fixture,
        'new_app\nNew App\nNew description\n',
      );

      expect(result.exitCode, isNot(0));
      expect(await manifest.readAsString(), originalManifest);
    },
  );
}

String _entityText(String value) => value
    .replaceAll('&', String.fromCharCodes([38, 97, 109, 112, 59]))
    .replaceAll('<', String.fromCharCodes([38, 108, 116, 59]))
    .replaceAll('>', String.fromCharCodes([38, 103, 116, 59]))
    .replaceAll('"', String.fromCharCodes([38, 113, 117, 111, 116, 59]));

Future<ProcessResult> _runRename(Directory fixture, String input) {
  final encodedInput = base64.encode(input.codeUnits);
  final command =
      "printf '%s' '$encodedInput' | base64 -D | "
      "dart '${fixture.path}/tool/rename_project.dart'";
  return Process.run(
    '/bin/sh',
    ['-c', command],
    workingDirectory: fixture.path,
  );
}
