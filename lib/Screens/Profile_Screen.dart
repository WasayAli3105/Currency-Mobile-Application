import 'package:curren_see/Screens/Changepassword_Screen.dart';
import 'package:curren_see/Screens/Login_Screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curren_see/Screens/EditProfile_Screen.dart';
import 'package:curren_see/Screens/AppNotifications_Screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:curren_see/theme/Theme_Provider.dart';
import 'package:curren_see/Constants/Constants.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>> fecthUser() async {
    String uId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot documentSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(uId).get();
    return documentSnapshot.data() as Map<String, dynamic>;
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    //Pre calculate all colors
    final Color scaffoldBg   = isDark ? darkBg : lightBg;
    final Color cardBg       = isDark ? darkCard : lightCard;
    final Color titleColor   = isDark ? darkTextPrimary : lightTextPrimary;
    final Color greyText     = isDark ? darkTextGrey : lightTextGrey;
    final Color dividerColor = isDark ? darkDivider : lightDivider;
    final Color iconBg       = isDark ? goldBorder15 : goldBorder15;
    final Color iconColor    = gold;

    //Header gradient
    final List<Color> headerGradient = isDark
        ? [goldDark, const Color(0xFF8B7318), const Color(0xFF6B5710)]
        : [goldLight, Color(0xFFFFD700), gold];

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Column(
        children: [
          //Gold Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 60, 16, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: headerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                //Profile Image
                FutureBuilder(
                  future: fecthUser(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return CircleAvatar(
                        radius: 45,
                        backgroundColor: cardBg,
                        child:
                        CircularProgressIndicator(color: gold),
                      );
                    } else if (snapshot.hasError ||
                        snapshot.data == null) {
                      return CircleAvatar(
                        radius: 45,
                        backgroundColor: cardBg,
                        child:
                        Icon(Icons.error, color: gold, size: 38),
                      );
                    } else {
                      final userData = snapshot.data!;
                      final profileUrl =
                      userData['profileImage'] as String?;
                      return CircleAvatar(
                        radius: 45,
                        backgroundColor: cardBg,
                        child: profileUrl != null &&
                            profileUrl.isNotEmpty
                            ? ClipOval(
                          child: Image.network(
                            profileUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Icon(
                          Icons.add_a_photo,
                          color: gold,
                          size: 38,
                        ),
                      );
                    }
                  },
                ),
                SizedBox(height: 12),

                //Name & Email
                FutureBuilder(
                  future: fecthUser(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return SizedBox();
                    } else if (snapshot.hasError ||
                        snapshot.data == null) {
                      return Text(
                        'Data Not Found!!',
                        style: TextStyle(color: Colors.white),
                      );
                    } else {
                      final userData = snapshot.data!;
                      return Column(
                        children: [
                          Text(
                            userData['name'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            userData['email'],
                            style: TextStyle(
                              color: const Color(0xB3FFFFFF),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          //Menu List
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8),
              children: [
                _profileItem(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  titleColor: titleColor,
                  iconBg: iconBg,
                  iconColor: iconColor,
                  dividerColor: dividerColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EditprofileScreen()),
                  ),
                ),
                _profileItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  titleColor: titleColor,
                  iconBg: iconBg,
                  iconColor: iconColor,
                  dividerColor: dividerColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AppnotificationsScreen()),
                  ),
                ),
                _profileItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  titleColor: titleColor,
                  iconBg: iconBg,
                  iconColor: iconColor,
                  dividerColor: dividerColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ChangepasswordScreen()),
                  ),
                ),

                //DARK LIGHT MODE TOGGLE

                _buildThemeToggle(
                  isDark: isDark,
                  themeProvider: themeProvider,
                  titleColor: titleColor,
                  iconBg: iconBg,
                  dividerColor: dividerColor,
                  cardBg: cardBg,
                  greyText: greyText,
                ),

                SizedBox(height: 20),

                //Logout Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                        );
                      },
                      icon:
                      Icon(Icons.logout, color: Colors.white),
                      label: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        padding:
                        EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }


  //Theme Toggle Widget
  Widget _buildThemeToggle({
    required bool isDark,
    required ThemeProvider themeProvider,
    required Color titleColor,
    required Color iconBg,
    required Color dividerColor,
    required Color cardBg,
    required Color greyText,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? goldBorder30 : goldBorder15,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? darkShadow : lightShadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                //Icon with animated background
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0x33C7A729) // gold 20%
                        : goldBorder15,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return RotationTransition(
                        turns: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      key: ValueKey<bool>(isDark),
                      color: gold,
                      size: 22,
                    ),
                  ),
                ),

                SizedBox(width: 14),

                //Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDark ? 'Dark Mode' : 'Light Mode',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        isDark
                            ? 'Switch to light theme'
                            : 'Switch to dark theme',
                        style: TextStyle(
                          color: greyText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                //Custom Animated Toggle
                GestureDetector(
                  onTap: () => themeProvider.toggleTheme(),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    width: 56,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                          const Color(0xFF2A2A2A),
                          const Color(0xFF1A1A1A),
                        ]
                            : [
                          const Color(0xFFFFF3C4),
                          const Color(0xFFFFE082),
                        ],
                      ),
                      border: Border.all(
                        color: isDark ? gold : goldLight,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? goldShadow40
                              : lightShadow,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        //Sliding circle
                        AnimatedPositioned(
                          duration: Duration(milliseconds: 350),
                          curve: Curves.easeInOutCubic,
                          left: isDark ? 28 : 3,
                          top: 3,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 350),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [gold, goldDark]
                                    : [
                                  const Color(0xFFFFB300),
                                  const Color(0xFFFF8F00),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? goldShadow40
                                      : const Color(0x40FFB300),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                isDark
                                    ? Icons.nightlight_round
                                    : Icons.wb_sunny_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, color: dividerColor),
        ),
      ],
    );
  }


  //Reusable Profile List Item
  Widget _profileItem({
    required IconData icon,
    required String title,
    required Color titleColor,
    required Color iconBg,
    required Color iconColor,
    required Color dividerColor,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios,
              color: gold, size: 15),
          onTap: onTap,
        ),
        Divider(height: 1, color: dividerColor),
      ],
    );
  }
}