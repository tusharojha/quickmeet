import 'package:flutter/material.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:http/http.dart' as http;

import '../clients/calendar_client.dart';
import '../config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = FlutterSecureStorage();

  Future<void> fetchUser() async {
    var _clientID = ClientId(Config.getId(), "");
    const _scopes = [cal.CalendarApi.calendarScope];

    //pull data out of secure storage
    var data = await _storage.read(key: 'accessToken');
    var type = await _storage.read(key: 'type');
    var expiry = await _storage.read(key: 'expiry');
    var refreshToken = await _storage.read(key: 'refreshToken');

    if (data != null &&
        type != null &&
        expiry != null &&
        refreshToken != null) {
      //if we have data, we're already signed in
      print('already signed in');

      //create the access token (even if it's expired)
      AccessToken accessToken =
          AccessToken(type, data, DateTime.tryParse(expiry)!);
      //use the refresh token here. Refresh tokens do not expire (for the most part).
      AccessCredentials creds = await refreshCredentials(_clientID,
          AccessCredentials(accessToken, refreshToken, _scopes), http.Client());

      http.Client c = http.Client();
      //create the AutoRefreshingAuthClient using previous
      //credentials
      AuthClient authClient = autoRefreshingClient(_clientID, creds, c);
      CalendarClient.calendar = cal.CalendarApi(authClient);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
      return;
    }

    // Navigate to the login screen.
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/quickmeet.png'),
      ),
    );
  }
}
