import 'package:flutter/material.dart';
import 'package:flutter_controls_core/flutter_controls_core.dart';

// Entry point for the application. Use `runFermiApp` to initialize the
// application's environment (set themes, prepare authentication resources,
// etc.)

Future<void> main() async => runFermiApp(
  appWidget: const App(),
  authInfo:
  // Replace this info with your application's configuration. These
  // specific parameters will let you see what it's like to log in
  // using SSO, but won't give you any privileges in the control
  // system.
  const AuthInfo(
    clientId: "auth-demo",
    clientSecret: "vPL2PWccDhFfbsUJjRsv5qdzJpWAhx4K",
    realm: "acsys",
    scopes: [],
  ),
);

// This is a simple, private widget that implements one item in the body of
// the drawer. This demo creates several of these widgets to show how a drawer
// looks like with content.

class _ExampleItem extends StatelessWidget {
  final int n;

  const _ExampleItem(this.n);

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text("Item #$n"),
    dense: true,
    onTap:
        () => showDialog<()>(
          context: context,
          builder: (_) => AlertDialog(title: Text("You picked item #$n.")),
        ),
  );
}

// This widget is the root of the application.

class App extends StatelessWidget {
  const App({super.key});

  static const _title = 'Fermilab Controls Demo';

  // At the very least, the root widget should be `StandardApp`, which
  // provides a common look and feel. In this case, we wrap the
  // `StandardApp` with an `ACSysProvider`, which allows our app to
  // access the control system.
  //
  // The `-core` library has several provider widgets that expose APIs to
  // the control system. Those widgets will have factory methods to build
  // them. For example, `ACSysProvider.factory()` builds an `ACSysProvider`.
  // Pass a list of these factories to the `providers` parameter.

  @override
  Widget build(BuildContext context) => StandardApp(
    title: _title,
    providers: [ACSysProvider.factory()],
    drawerContents: const [
      _ExampleItem(1),
      _ExampleItem(2),
      _ExampleItem(3),
      _ExampleItem(4),
    ],
    appBar: AppBar(title: const Text(_title)),
    body: _BaseWidget(),
  );
}

// This is the body of the application. Typically the body will be implemented
// by widgets defined in other modules.
//
// You may wonder why, with such a simple example, this wasn't placed in the
// `App` widget. It's because, in `App's` `build` method, the 'context' points
// to where in the widget tree `App` will be mounted. But it hasn't yet been
// added to the tree so, when we call `ACSys.api(context)`, it won't find any
// `ACSysProvider` in the tree.
//
// Making a new widget means, when the `build()` method is called, the widgets
// higher in the tree will have been added and `ACSys.api(context)` will
// succeed.

class _BaseWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
      child: StreamBuilder(
          stream: ACSys.api(context).monitorDevices(["G:SCTIME@P,15H"]),
          builder: (context, snapshot) => snapshot.hasData
              ? Text(
                  'Supercycle time: ${snapshot.data!.value!.toDouble().toStringAsFixed(2)}')
              : const Text('Loading...')));
}
