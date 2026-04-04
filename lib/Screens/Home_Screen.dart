import 'package:curren_see/Screens/AppNotifications_Screen.dart';
import 'package:curren_see/Screens/CurrencyConverter_Screen.dart';
import 'package:curren_see/Screens/CurrencyHistory_Screen.dart';
import 'package:curren_see/Screens/CurrencyNews_MarketTrends_Screen.dart';
import 'package:curren_see/Screens/Currency_ListScreen.dart';
import 'package:curren_see/Screens/ExchangeRate_InformationScreen.dart';
import 'package:curren_see/Screens/FeedBack_Screen.dart';
import 'package:curren_see/Screens/HomeTab_Screen.dart';
import 'package:curren_see/Screens/Login_Screen.dart';
import 'package:curren_see/Screens/Profile_Screen.dart';
import 'package:curren_see/Screens/RateAlerts_Screen.dart';
import 'package:curren_see/Screens/UserPreferences_Screen.dart';
import 'package:curren_see/Screens/UserSupport_HelpCenter_Screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:curren_see/Constants/Constants.dart';
import 'package:curren_see/Screens/AllFeedbacks_Screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Widget? _drawerScreen;
  String _drawerTitle = '';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    HomeTabScreen(),
    FeedbackScreen(),
    AllfeedbacksScreen(),
    ProfileScreen(),
  ];

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  //NEW: Drawer item select handler
  void _onDrawerItemTap(Widget screen, String title) {
    setState(() {
      _drawerScreen = screen;
      _drawerTitle = title;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    bool isDrawerScreenActive = _drawerScreen != null;

    return Scaffold(
      key: _scaffoldKey,

      appBar: (_selectedIndex == 2 || _selectedIndex == 1) && !isDrawerScreenActive
          ? null
          : AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: gold,
        toolbarHeight: h * 0.07,

        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),

        title: isDrawerScreenActive
            ? Text(
          _drawerTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        )
        //Normal CurrenSee title
            : RichText(
          text: TextSpan(children: [
            TextSpan(
              text: 'Curren',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: 'See',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ]),
        ),
      ),

      //Drawer Same as before sirf onTap changed)
      drawer: Drawer(
        width: w * 0.80,
        backgroundColor: isDark ? darkCard : lightCard,
        child: Column(children: [
          //Drawer Header
          Container(
            height: h * 0.22,
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                w * 0.04, h * 0.06, w * 0.04, h * 0.025),
            decoration: BoxDecoration(
              gradient:
              LinearGradient(colors: [gold, Color(0xFFFFD700), gold]),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: w * 0.09,
                backgroundColor: Colors.white,
                child: Text('₿',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: gold)),
              ),
              SizedBox(width: w * 0.04),
              RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: 'Curren',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    TextSpan(
                        text: 'See',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ])),
            ]),
          ),

          //Scrollable Menu
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                SizedBox(height: h * 0.025),

                //CHANGED: Navigator.push onDrawerItemTap
                _drawerItem(
                  icon: Icons.calculate_outlined,
                  title: 'Currency Conversion',
                  w: w,
                  isDark: isDark,
                  onTap: () => _onDrawerItemTap(
                      CurrencyConverterScreen(), 'Currency Conversion'),
                ),

                _drawerItem(
                  icon: Icons.list_alt_outlined,
                  title: 'Currency List',
                  w: w,
                  isDark: isDark,
                  onTap: () => _onDrawerItemTap(
                      CurrencyListscreen(), 'Currency List'),
                ),

                _drawerItem(
                  icon: Icons.bar_chart,
                  title: 'Exchange Rate Information',
                  w: w,
                  isDark: isDark,
                  onTap: () => _onDrawerItemTap(
                      ExchangerateInformationscreen(),
                      'Exchange Rate Info'),
                ),

                _drawerItem(
                  icon: Icons.history,
                  title: 'Currency Conversion History',
                  w: w,
                  isDark: isDark,
                  onTap: () => _onDrawerItemTap(
                      CurrencyhistoryScreen(), 'Conversion History'),
                ),

                _drawerItem(
                  icon: Icons.notifications_outlined,
                  title: 'Rate Alerts',
                  w: w,
                  isDark: isDark,
                  onTap: () =>
                      _onDrawerItemTap(RateAlertsScreen(), 'Rate Alerts'),
                ),

                _drawerItem(
                  icon: Icons.tune,
                  title: 'User Preferences',
                  w: w,
                  isDark: isDark,
                  onTap: () => _onDrawerItemTap(
                      UserpreferencesScreen(), 'User Preferences'),
                ),

                _drawerItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  w: w,
                  isDark: isDark,
                  onTap: () => _onDrawerItemTap(
                      AppnotificationsScreen(), 'Notifications'),
                ),

                _drawerItem(
                  icon: Icons.newspaper,
                  title: 'Currency News and Market Trends',
                  w: w,
                  isDark: isDark,
                  onTap: () => _onDrawerItemTap(
                      CurrencynewsMarkettrendsScreen(),
                      'News & Trends'),
                ),

                _drawerItem(
                  icon: Icons.help_outline,
                  title: 'User Support and Help Center',
                  w: w,
                  isDark: isDark,
                  onTap: () => _onDrawerItemTap(
                      UsersupportHelpcenterScreen(),
                      'Help & Support'),
                ),

                Divider(color: isDark ? darkDivider : null),
                SizedBox(height: h * 0.012),

                // Logout Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.03),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        signOut();
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => LoginScreen()));
                      },
                      icon: Icon(Icons.logout, color: Colors.white),
                      label: Text('Logout',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        padding:
                        EdgeInsets.symmetric(vertical: h * 0.022),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: h * 0.02),
              ]),
            ),
          ),
        ]),
      ),

      body: isDrawerScreenActive
          ? _drawerScreen!
          : _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: gold,
        unselectedItemColor: isDark ? darkTextGrey : Colors.grey,
        backgroundColor: isDark ? darkCard : lightCard,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _drawerScreen = null;
            _drawerTitle = '';
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.feedback), label: 'FeedBack'),
          BottomNavigationBarItem(
              icon: Icon(Icons.rate_review), label: 'Reviews'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  //Drawer Item Widget Same as before
  Widget _drawerItem({
    required IconData icon,
    required String title,
    required double w,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: w * 0.04),
      leading: Icon(icon, color: gold),
      title: Text(title,
          style: TextStyle(
              color: isDark ? darkTextPrimary : lightTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios,
          color: isDark ? goldBorder30 : gold, size: 16),
      onTap: onTap,
    );
  }
}