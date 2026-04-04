import 'package:curren_see/main.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curren_see/Constants/Constants.dart';

//Pre-calculated opacity colors
//(withOpacity errors )
const Color _goldOp08  = Color(0x14C7A729);
const Color _goldOp10  = Color(0x1AC7A729);
const Color _goldOp25  = Color(0x40C7A729);
const Color _goldOp35  = Color(0x59C7A729);
const Color _goldLOp07 = Color(0x12D4B84A);
const Color _blackOp06 = Color(0x0F000000);
const Color _whiteOp70 = Color(0xB3FFFFFF);

class OnScreen extends StatefulWidget {
  const OnScreen({super.key});

  @override
  State<OnScreen> createState() => _OnScreenState();
}

class _OnScreenState extends State<OnScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _floatController;
  late AnimationController _fadeController;
  late Animation<double> _floatAnim;
  late Animation<double> _fadeAnim;

  final List<OnboardData> _pages = [
    OnboardData(
      title: 'Live Exchange Rates',
      subtitle: 'Get real-time currency rates from\naround the world instantly',
      icon: Icons.currency_exchange_rounded,
      extraIcon1: Icons.attach_money,
      extraIcon2: Icons.euro,
      extraIcon3: Icons.currency_pound,
      bgShapeLight: Color(0xFFFFF8DC),
      bgShapeDark: Color(0xFF2A2510),
      tag1: 'USD',
      tag2: 'PKR',
      tag3: 'EUR',
    ),
    OnboardData(
      title: 'Instant Converter',
      subtitle: 'Convert any currency in seconds\nwith just a few taps',
      icon: Icons.swap_horiz_rounded,
      extraIcon1: Icons.trending_up,
      extraIcon2: Icons.bar_chart,
      extraIcon3: Icons.show_chart,
      bgShapeLight: Color(0xFFF0FFF0),
      bgShapeDark: Color(0xFF1A2A1A),
      tag1: 'Fast',
      tag2: '150+',
      tag3: 'Accurate',
    ),
    OnboardData(
      title: 'Track & Compare',
      subtitle: 'Monitor trends and compare rates\nacross multiple currencies',
      icon: Icons.analytics_rounded,
      extraIcon1: Icons.notifications_active,
      extraIcon2: Icons.star,
      extraIcon3: Icons.history,
      bgShapeLight: Color(0xFFFFF5E6),
      bgShapeDark: Color(0xFF2A2210),
      tag1: 'Alerts',
      tag2: 'History',
      tag3: 'Charts',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..forward();

    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _fadeController.reset();
      _fadeController.forward();
      _pageController.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AuthWrapper(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    // ── Pre-calculate colors ──
    final Color scaffoldBg = isDark ? darkBgOnboard : lightBgOnboard;
    final Color blobColor1 = isDark ? _goldOp10 : _goldOp08;
    final Color blobColor2 = isDark ? _goldOp08 : _goldLOp07;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          //Background blobs
          Positioned(
            top: -width * 0.2,
            right: -width * 0.15,
            child: _buildBlob(width * 0.55, blobColor1),
          ),
          Positioned(
            bottom: height * 0.18,
            left: -width * 0.2,
            child: _buildBlob(width * 0.45, blobColor2),
          ),

          //Pages
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _fadeController.reset();
              _fadeController.forward();
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index], width, height, isDark);
            },
          ),

          //Bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(width, height, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }


  //Page Builder
    Widget _buildPage(
      OnboardData data, double width, double height, bool isDark) {
    final Color titleColor = isDark ? darkTextPrimary : lightTextPrimary;
    final Color subtitleColor = isDark ? darkTextGrey : lightTextGrey;
    final Color tagBg = isDark ? goldBorder15 : _goldOp10;
    final Color tagBorder = isDark ? goldBorder30 : goldBorder30;
    final Color tagText = isDark ? gold : goldDark;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          SizedBox(height: height * 0.06),

          //Logo
          Text(
            'Curren',
            style: TextStyle(
              fontSize: width * 0.055,
              fontWeight: FontWeight.w900,
              color: goldDark,
              letterSpacing: 1,
            ),
          ).withSuffix(
            Text(
              'See',
              style: TextStyle(
                fontSize: width * 0.055,
                fontWeight: FontWeight.w900,
                color: gold,
              ),
            ),
          ),

          SizedBox(height: height * 0.045),

          //Floating illustration
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: child,
              );
            },
            child: _buildIllustration(data, width, isDark),
          ),

          SizedBox(height: height * 0.05),

          //Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.08),
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: width * 0.07,
                fontWeight: FontWeight.w900,
                color: titleColor,
                height: 1.2,
              ),
            ),
          ),

          SizedBox(height: height * 0.018),

          //Subtitle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.1),
            child: Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: width * 0.038,
                color: subtitleColor,
                height: 1.6,
              ),
            ),
          ),

          SizedBox(height: height * 0.035),

          //Tags
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTag(data.tag1, width, tagBg, tagBorder, tagText),
              SizedBox(width: width * 0.03),
              _buildTag(data.tag2, width, tagBg, tagBorder, tagText),
              SizedBox(width: width * 0.03),
              _buildTag(data.tag3, width, tagBg, tagBorder, tagText),
            ],
          ),
        ],
      ),
    );
  }

  //Illustration
    Widget _buildIllustration(OnboardData data, double width, bool isDark) {
    final Color shapeBg = isDark ? data.bgShapeDark : data.bgShapeLight;
    final Color shapeShadow = isDark ? darkShadow : goldBorder15;
    final Color orbitBorder1 = isDark ? goldBorder30 : goldBorder15;
    final Color orbitBorder2 = isDark ? goldBorder15 : _goldOp10;
    final Color coinBg = isDark ? darkCard : lightCard;
    final Color coinShadow = isDark ? darkShadow : goldBorder30;

    return Container(
      width: width * 0.75,
      height: width * 0.75,
      decoration: BoxDecoration(
        color: shapeBg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: shapeShadow,
            blurRadius: 40,
            spreadRadius: 5,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          //Orbit ring 1
          AnimatedBuilder(
            animation: _floatController,
            builder: (_, __) => Transform.rotate(
              angle: _floatController.value * 2 * math.pi,
              child: Container(
                width: width * 0.68,
                height: width * 0.68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: orbitBorder1, width: 1.5),
                ),
              ),
            ),
          ),

          //Orbit ring 2
          AnimatedBuilder(
            animation: _floatController,
            builder: (_, __) => Transform.rotate(
              angle: -_floatController.value * 2 * math.pi * 0.7,
              child: Container(
                width: width * 0.55,
                height: width * 0.55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: orbitBorder2,
                    width: 1,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
              ),
            ),
          ),

          //Orbiting mini coins
          AnimatedBuilder(
            animation: _floatController,
            builder: (_, __) {
              final angle = _floatController.value * 2 * math.pi;
              final r = width * 0.28;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset:
                    Offset(r * math.cos(angle), r * math.sin(angle)),
                    child: _miniCoin(
                        data.extraIcon1, width * 0.09, coinBg, coinShadow),
                  ),
                  Transform.translate(
                    offset: Offset(
                      r * math.cos(angle + 2 * math.pi / 3),
                      r * math.sin(angle + 2 * math.pi / 3),
                    ),
                    child: _miniCoin(
                        data.extraIcon2, width * 0.09, coinBg, coinShadow),
                  ),
                  Transform.translate(
                    offset: Offset(
                      r * math.cos(angle + 4 * math.pi / 3),
                      r * math.sin(angle + 4 * math.pi / 3),
                    ),
                    child: _miniCoin(
                        data.extraIcon3, width * 0.09, coinBg, coinShadow),
                  ),
                ],
              );
            },
          ),

          //Center icon
          Container(
            width: width * 0.28,
            height: width * 0.28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [goldLight, gold, goldDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: goldShadow40,
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(data.icon, color: Colors.white, size: width * 0.13),
          ),
        ],
      ),
    );
  }

  Widget _miniCoin(
      IconData icon, double size, Color bg, Color shadow) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: gold, size: size * 0.55),
    );
  }

  //Tag Widget
    Widget _buildTag(
      String label, double width, Color bg, Color border, Color text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.015,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(width * 0.05),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: width * 0.03,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  //Bottom Bar
    Widget _buildBottomBar(double width, double height, bool isDark) {
    final isLast = _currentPage == _pages.length - 1;

    final Color barBg = isDark ? darkCard : lightCard;
    final Color barShadow = isDark ? darkShadow : _blackOp06;
    final Color dotInactive = isDark ? _goldOp25 : _goldOp25;

    return Container(
      padding: EdgeInsets.fromLTRB(
          width * 0.07, height * 0.025, width * 0.07, height * 0.04),
      decoration: BoxDecoration(
        color: barBg,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(width * 0.08)),
        boxShadow: [
          BoxShadow(
            color: barShadow,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: width * 0.01),
                width: isActive ? width * 0.08 : width * 0.025,
                height: width * 0.025,
                decoration: BoxDecoration(
                  color: isActive ? gold : dotInactive,
                  borderRadius: BorderRadius.circular(width * 0.05),
                ),
              );
            }),
          ),

          SizedBox(height: height * 0.025),

          //Buttons
          isLast
              ? SizedBox(
            width: double.infinity,
            height: height * 0.065,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [goldLight, gold, goldDark],
                ),
                borderRadius: BorderRadius.circular(width * 0.04),
                boxShadow: [
                  BoxShadow(
                    color: goldShadow40,
                    blurRadius: 15,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _goToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(width * 0.04),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Let's Go!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white),
                  ],
                ),
              ),
            ),
          )
              : Row(
            children: [
              //Skip
              Expanded(
                child: SizedBox(
                  height: height * 0.065,
                  child: OutlinedButton(
                    onPressed: _goToLogin,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: gold, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(width * 0.04),
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: gold,
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: width * 0.04),

              //Next
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: height * 0.065,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [goldLight, gold, goldDark],
                      ),
                      borderRadius:
                      BorderRadius.circular(width * 0.04),
                      boxShadow: [
                        BoxShadow(
                          color: _goldOp35,
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(width * 0.04),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: width * 0.02),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


//Data Model
class OnboardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData extraIcon1;
  final IconData extraIcon2;
  final IconData extraIcon3;
  final Color bgShapeLight;
  final Color bgShapeDark;
  final String tag1;
  final String tag2;
  final String tag3;

  const OnboardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.extraIcon1,
    required this.extraIcon2,
    required this.extraIcon3,
    required this.bgShapeLight,
    required this.bgShapeDark,
    required this.tag1,
    required this.tag2,
    required this.tag3,
  });
}


//Extension

extension WidgetSuffix on Widget {
  Widget withSuffix(Widget suffix) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [this, suffix],
    );
  }
}