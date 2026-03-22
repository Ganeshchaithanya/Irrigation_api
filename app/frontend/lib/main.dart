import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:postgres/postgres.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String _status = 'Initializing...';
  bool _isLoading = false;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Connecting...';
    });

    try {
      final connectionString = dotenv.get('postgresql_Connect_ID');
      final uri = Uri.parse(connectionString);
      
      final conn = await Connection.open(
        Endpoint(
          host: uri.host,
          database: uri.pathSegments.first,
          username: uri.userInfo.split(':').first,
          password: uri.userInfo.split(':').last,
        ),
        settings: const ConnectionSettings(sslMode: SslMode.require),
      );

      await conn.execute('SELECT 1');
      await conn.close();

      setState(() {
        _status = 'Connection Successful!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Connection Failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('Irrigation API Connection Test')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Status: $_status',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _testConnection,
                  child: const Text('Test Connection'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
