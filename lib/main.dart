import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:quickmeet/SplashScreen/splash_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'DashboardScreen/dashboard_screen.dart';
import 'clients/calendar_client.dart';
import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

void prompt(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: SplashScreen(),
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _storage = new FlutterSecureStorage();

  void signIn() async {
    var _clientID = ClientId(Config.getId(), "");
    const _scopes = [cal.CalendarApi.calendarScope];

    await clientViaUserConsent(_clientID, _scopes, prompt)
        .then((AuthClient client) async {
      CalendarClient.calendar = cal.CalendarApi(client);
      await _storage.write(
          key: 'accessToken', value: client.credentials.accessToken.data);
      await _storage.write(
          key: 'type', value: client.credentials.accessToken.type);
      await _storage.write(
          key: 'expiry',
          value: client.credentials.accessToken.expiry.toString());

      await _storage.write(
          key: 'refreshToken', value: client.credentials.refreshToken);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to QuickMeet'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/quickmeet.png'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                signIn();
              },
              child: Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
