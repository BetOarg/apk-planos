import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/scan_notifier.dart';
import 'screens/scan_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RoomScannerApp());
}

class RoomScannerApp extends StatelessWidget {
  const RoomScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScanNotifier(),
      child: MaterialApp(
        title: 'Room Scanner AR',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const ScanScreen(),
      ),
    );
  }
}
