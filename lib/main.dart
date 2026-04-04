import 'package:curren_see/Screens/Home_Screen.dart';
import 'package:curren_see/Screens/Login_Screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:curren_see/Screens/on_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:provider/provider.dart';
import 'package:curren_see/theme/App_Theme.dart';
import 'package:curren_see/theme/Theme_Provider.dart';


//Global Local Notification Plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

//Background FCM Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Background FCM: ${message.notification?.title}');
}

//Local Notification Show Function
Future<void> showLocalNotification({
  required String title,
  required String body,
}) async {
  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'Currency rate alerts and app updates',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    icon: '@mipmap/ic_launcher',
  );

  DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  NotificationDetails details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    details,
  );
}

//Rate Check Service
class RateCheckService {
  static Timer? _timer;

  static Future<void> checkRatesOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool masterOn = prefs.getBool('master_switch_on') ?? true;
      final bool rateAlertsOn = prefs.getBool('rate_alerts_on') ?? true;

      if (!masterOn || !rateAlertsOn) {
        debugPrint('⏭️ Rate alerts disabled');
        return;
      }

      final response = await http.get(Uri.parse(
          'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/pkr.json'));

      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      final currentRates = data['pkr'] as Map<String, dynamic>?;
      if (currentRates == null) return;

      final List<String> currencies = [
        'usd', 'eur', 'gbp', 'sar', 'aed', 'cny'
      ];

      final String? prevRatesJson = prefs.getString('previous_rates');
      Map<String, dynamic> previousRates = {};
      if (prevRatesJson != null) {
        previousRates = json.decode(prevRatesJson);
      }

      List<String> changes = [];

      for (final currency in currencies) {
        final currentRate = currentRates[currency];
        final prevRate = previousRates[currency];

        if (currentRate != null && prevRate != null) {
          final double curr = (currentRate as num).toDouble();
          final double prev = (prevRate as num).toDouble();
          final double changePercent = ((curr - prev).abs() / prev) * 100;

          if (changePercent >= 0.0) {
            final String direction = curr > prev ? "📈 UP" : "📉 DOWN";
            changes.add(
              '$direction ${currency.toUpperCase()}: ${prev.toStringAsFixed(4)} → ${curr.toStringAsFixed(4)} (${changePercent.toStringAsFixed(2)}%)',
            );
          }
        }
      }

      if (changes.isNotEmpty) {
        for (final change in changes) {
          await showLocalNotification(
            title: 'Currency Rate Changed!',
            body: change,
          );
        }
        debugPrint('Rate alert sent: ${changes.length} changes');
      } else {
        debugPrint('No significant rate changes');
      }

      final Map<String, dynamic> ratesToSave = {};
      for (final currency in currencies) {
        if (currentRates[currency] != null) {
          ratesToSave[currency] = currentRates[currency];
        }
      }
      await prefs.setString('previous_rates', json.encode(ratesToSave));
      debugPrint('Rates saved for next comparison');
    } catch (e) {
      debugPrint('Rate check error: $e');
    }
  }

  static void startPeriodicCheck() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(minutes: 15), (timer) {
      debugPrint('Periodic rate check...');
      checkRatesOnce();
    });
    debugPrint('Periodic rate check started (every 15 min)');
  }

  static void stopPeriodicCheck() {
    _timer?.cancel();
    _timer = null;
    debugPrint('Periodic rate check stopped');
  }
}

//Local Notifications Initialize
Future<void> _initLocalNotifications() async {
  AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  DarwinInitializationSettings iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint('Notification tapped: ${response.payload}');
    },
  );

  AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Currency rate alerts and app updates',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final bool seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await _initLocalNotifications();

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  RateCheckService.checkRatesOnce();
  RateCheckService.startPeriodicCheck();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(showOnboarding: !seenOnboarding),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,

      home: showOnboarding ? OnScreen() : AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              //Gold color loading indicator
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
          );
        }
        if (snapshot.hasData) return HomeScreen();
        return LoginScreen();
      },
    );
  }
}