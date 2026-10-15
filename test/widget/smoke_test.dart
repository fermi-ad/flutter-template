import 'package:flutter/material.dart';
import 'package:flutter_controls_core/flutter_controls_core.dart'
    show StandardApp;
import 'package:flutter_controls_template/main.dart' show App;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app bar shows the demo title', (tester) async {
    const app = App();
    final configuration = app.build(app.createElement()) as StandardApp;

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(appBar: configuration.appBar)),
    );

    expect(find.text('Fermilab Controls Demo'), findsOneWidget);
  });
}
