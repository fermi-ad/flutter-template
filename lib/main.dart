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
      const AuthInfo(),
);

// This is a simple, private widget that implements one item in the body of
// the drawer. This demo creates several of these widgets to show how a drawer
// looks like with content.

class _ExampleItem extends StatelessWidget {
  final int n;

  const _ExampleItem(this.n);

  @override
  Widget build(final BuildContext context) => ListTile(
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
  Widget build(final BuildContext context) => StandardApp(
    title: _title,
    providers: [ACSysProvider.factoryUsingPort(port: 8001)],

    // Add a requirement that the user is in the "accelprgmmer" role. We will
    // adjust the UI to reflect that the session has been granted the proper
    // authorization.
    neededRoles: ["accelprgmmer"],
    drawerContent: Column(
      children: [
        _ExampleItem(1),
        _ExampleItem(2),
        _ExampleItem(3),
        _ExampleItem(4),
      ],
    ),
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
//
// Since this widget uses Futures and Streams, we don't want them created over
// and over when the widget gets rebuilt. So we use a StatefulWidget which
// creates the Future and Stream in in the State<> object and only updates them
// when the user's authorization status changes.

class _BaseWidget extends StatefulWidget {
  @override
  State<_BaseWidget> createState() => _BaseWidgetState();
}

class _BaseWidgetState extends State<_BaseWidget> {
  Future<List<Reading>>? _tempFuture;
  Stream<Reading>? _monitorStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final api = ACSys.api(context);

    // Cache the future so it doesn't get re-run on every rebuild of this
    // widget.

    _tempFuture ??= api.readDevices(["M:OUTTMP"]);

    // AuthService.inRole(context, ...) registers the calling widget to be
    // rebuilt when the user's role status changes (e.g., after logging in).

    final bool nowAuthorized = AuthService.inRole(context, "accelprgmmer");

    if (nowAuthorized != (_monitorStream != null)) {
      setState(() {
        _monitorStream =
            nowAuthorized ? api.monitorDevices(["G:SCTIME"]) : null;
      });
    }
  }

  @override
  Widget build(final BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FutureBuilder(
          future: _tempFuture,
          builder: (final context, final snapshot) {
            if (snapshot.hasData) {
              return Text(
                "Outdoor Temperature: ${snapshot.data![0].value!.toDouble()!.toStringAsFixed(1)} °F",
              );
            } else {
              return const Text('Loading...');
            }
          },
        ),
        if (_monitorStream != null)
          StreamBuilder(
            stream: _monitorStream,
            builder:
                (final context, final snapshot) =>
                    snapshot.hasData
                        ? Text(
                          'Supercycle time: ${snapshot.data!.value!.toDouble()!.toStringAsFixed(2)}',
                        )
                        : const Text('Loading...'),
          )
        else
          const Text("Not authorized to see G:SCTIME."),
      ],
    ),
  );
}
