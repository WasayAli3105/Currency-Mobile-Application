import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'package:curren_see/Constants/Constants.dart';

// demo button
import 'dart:convert';

class AppnotificationsScreen extends StatefulWidget {
  const AppnotificationsScreen({super.key});

  @override
  State<AppnotificationsScreen> createState() => _AppnotificationsScreenState();
}

class _AppnotificationsScreenState extends State<AppnotificationsScreen> {
  bool _loading           = true;
  bool _saving            = false;
  bool _masterSwitch      = true;
  bool _rateAlerts        = true;
  bool _appUpdates        = true;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _initFCM();
  }

  Future<void> _initFCM() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (mounted) setState(() => _permissionGranted = status.isGranted);
      if (!status.isGranted) return;
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (Platform.isIOS) {
      if (mounted) setState(() => _permissionGranted = granted);
      if (!granted) return;
    }

    await _saveFCMToken();
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToFirestore);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;
      final notification = message.notification;
      if (notification == null) return;

      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title ?? 'Notification',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Currency rate alerts and app updates',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped: ${message.data}');
    });
  }

  Future<void> _saveFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveTokenToFirestore(token);
      }
    } catch (_) {}
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _loadPrefs() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) { setState(() => _loading = false); return; }
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('settings').doc('notifications').get();
      if (snap.exists) {
        final d = snap.data()!;
        _masterSwitch = d['masterSwitch'] ?? true;
        _rateAlerts   = d['rateAlerts']   ?? true;
        _appUpdates   = d['appUpdates']   ?? true;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _savePrefs() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users').doc(uid)
            .collection('settings').doc('notifications')
            .set({
          'masterSwitch': _masterSwitch,
          'rateAlerts':   _rateAlerts,
          'appUpdates':   _appUpdates,
          'updatedAt':    FieldValue.serverTimestamp(),
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('master_switch_on', _masterSwitch);
        await prefs.setBool('rate_alerts_on', _rateAlerts);
        await prefs.setBool('app_updates_on', _appUpdates);

        if (_masterSwitch && _rateAlerts) {
          try {
            await RateCheckService.checkRatesOnce();
            RateCheckService.startPeriodicCheck();
          } catch (e) {
            debugPrint('RateCheckService error: $e');
          }
        } else {
          RateCheckService.stopPeriodicCheck();
        }

        if (_masterSwitch && _appUpdates) {
          await FirebaseMessaging.instance.subscribeToTopic('app_updates');
        } else {
          await FirebaseMessaging.instance.unsubscribeFromTopic('app_updates');
        }

        if (!_masterSwitch) {
          RateCheckService.stopPeriodicCheck();
          await FirebaseMessaging.instance.unsubscribeFromTopic('app_updates');
        }
      }

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Notification preferences saved!'),
          backgroundColor: Color(0xFF2E7D32),
        ));
      }

    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Something went wrong. Try again.'),
          backgroundColor: Color(0xFFE53935),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width  = MediaQuery.of(context).size.width;

    //Theme values
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : Column(children: [

        _buildHeader(height),

        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: width * 0.045, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                if (!_permissionGranted) ...[
                  _buildPermissionBanner(isDark),
                  SizedBox(height: 16),
                ],

                _buildMasterCard(isDark),
                SizedBox(height: 20),

                AnimatedOpacity(
                  opacity: _masterSwitch ? 1.0 : 0.4,
                  duration: Duration(milliseconds: 250),
                  child: _buildCard(isDark: isDark, children: [
                    _toggleTile(
                      icon: Icons.show_chart_rounded,
                      iconBg: isDark ? gold.withAlpha(38) : Color(0xFFFFF8E1),
                      title: 'Rate Alerts',
                      subtitle: 'Notify when currency rates change significantly',
                      value: _rateAlerts,
                      isDark: isDark,
                      onChanged: _masterSwitch
                          ? (v) => setState(() => _rateAlerts = v)
                          : null,
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? darkDivider : Color(0xFFF0E8C0),
                    ),
                    _toggleTile(
                      icon: Icons.system_update_rounded,
                      iconBg: isDark ? gold.withAlpha(38) : Color(0xFFE8F5E9),
                      title: 'App Updates',
                      subtitle: 'New features, improvements & version updates',
                      value: _appUpdates,
                      isDark: isDark,
                      onChanged: _masterSwitch
                          ? (v) => setState(() => _appUpdates = v)
                          : null,
                    ),
                  ]),
                ),

                SizedBox(height: 28),

                // TEST BUTTON is here for testing purposes
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final fakeOldRates = {
                        'usd': 0.001000, 'eur': 0.001000,
                        'gbp': 0.001000, 'sar': 0.005000,
                        'aed': 0.005000, 'cny': 0.010000,
                      };
                      await prefs.setString('previous_rates', jsonEncode(fakeOldRates));
                      await RateCheckService.checkRatesOnce();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Test Notification Sent!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.bug_report_rounded, color: Colors.white, size: 20),
                    label: Text('Test Rate Alert',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                SizedBox(height: 12),

                // SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _savePrefs,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      disabledBackgroundColor: gold.withAlpha(153),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_rounded,
                            color: isDark ? Colors.black : Colors.white,
                            size: 20),
                        SizedBox(width: 8),
                        Text('Save Preferences',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.black : Colors.white)),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // CANCEL BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: gold, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Cancel',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? goldLight : goldDark)),
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  //HEADER same for both modes
  Widget _buildHeader(double height) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, height * 0.07, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [goldLight, Color(0xFFFFD700), gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(children: [
        Text('Notifications',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        SizedBox(height: 20),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(153), width: 3),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(38),
                  blurRadius: 14,
                  offset: Offset(0, 5)),
            ],
          ),
          child: Center(
            child: Icon(Icons.notifications_active_rounded, color: gold, size: 34),
          ),
        ),
        SizedBox(height: 10),
        Text('Manage your alerts & updates',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

  //PERMISSION BANNER
  Widget _buildPermissionBanner(bool isDark) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.orange.withAlpha(38) : Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFFB300), width: 1.2),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB300), size: 22),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Notifications blocked. Enable from phone settings.',
            style: TextStyle(
                fontSize: 11.5,
                color: isDark ? darkTextGrey : Color(0xFF5D4037)),
          ),
        ),
        TextButton(
          onPressed: () => openAppSettings(),
          child: Text('Enable',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFB300))),
        ),
      ]),
    );
  }

  //MASTER CARD
  Widget _buildMasterCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _masterSwitch
              ? (isDark
              ? [gold.withAlpha(51), gold.withAlpha(25)]
              : [Color(0xFFFFD700).withAlpha(38), gold.withAlpha(20)])
              : (isDark
              ? [darkCard, darkCard]
              : [Colors.grey.shade100, Colors.grey.shade50]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _masterSwitch
                ? goldLight
                : (isDark ? darkDivider : Colors.grey.shade300),
            width: 1.3),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _masterSwitch
                  ? gold.withAlpha(38)
                  : (isDark ? darkCard : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _masterSwitch
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: _masterSwitch
                  ? gold
                  : (isDark ? darkTextGrey : Colors.grey.shade400),
              size: 24,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All Notifications',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _masterSwitch
                            ? (isDark ? gold : Color(0xFF5A4400))
                            : (isDark ? darkTextGrey : Colors.grey.shade600))),
                SizedBox(height: 3),
                Text(
                    _masterSwitch
                        ? 'Notifications are enabled'
                        : 'All notifications muted',
                    style: TextStyle(
                        fontSize: 11,
                        color: _masterSwitch
                            ? (isDark ? goldLight : goldDark)
                            : (isDark ? darkTextGrey : Colors.grey.shade400))),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _masterSwitch,
            activeTrackColor: gold,
            onChanged: (v) => setState(() => _masterSwitch = v),
          ),
        ]),
      ),
    );
  }

  //CARD WRAPPER
  Widget _buildCard({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? darkCard : lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? goldBorder15 : Color(0xFFE8D88A),
            width: 1),
        boxShadow: [
          BoxShadow(
              color: isDark ? goldShadow40 : gold.withAlpha(20),
              blurRadius: 10,
              offset: Offset(0, 3)),
        ],
      ),
      child: Column(children: children),
    );
  }

  //TOGGLE TILE
  Widget _toggleTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool>? onChanged,
  }) {
    final enabled = onChanged != null;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: enabled
                  ? iconBg
                  : (isDark ? darkCard : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon,
              color: enabled
                  ? gold
                  : (isDark ? darkTextGrey : Colors.grey.shade300),
              size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? (isDark ? darkTextPrimary : Colors.black87)
                          : (isDark ? darkTextGrey : Colors.grey.shade400))),
              SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 10.5,
                      color: enabled
                          ? (isDark ? darkTextGrey : Colors.grey.shade500)
                          : (isDark
                          ? darkTextGrey.withAlpha(128)
                          : Colors.grey.shade300))),
            ],
          ),
        ),
        SizedBox(width: 8),
        CupertinoSwitch(
            value: value,
            activeTrackColor: gold,
            onChanged: onChanged),
      ]),
    );
  }
}