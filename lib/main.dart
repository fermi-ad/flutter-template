import 'package:flutter/material.dart';
import 'package:flutter_controls_core/flutter_controls_core.dart';

Future<void> main() async {
  await runFermiApp(appWidget: MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  static const _title = 'Fermilab Controls Demo';
  final service = ACSysService();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StandardApp(
      title: _title,
      appBar: AppBar(
        title: const Text(_title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: StreamBuilder(
          stream: service.monitorDevices(["G:SCTIME@P,15H"]),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                  'Supercycle time: ${snapshot.data!.value!.toStringAsFixed(2)}');
            }

            return const Text('Loading...');
          },
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
