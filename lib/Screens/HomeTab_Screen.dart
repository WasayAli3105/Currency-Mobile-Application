import 'dart:convert';
import 'package:curren_see/Screens/CurrencyConverter_Screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:curren_see/Module/currency_model.dart';
import 'package:curren_see/Constants/Constants.dart';

class HomeTabScreen extends StatefulWidget {
  HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen>
    with SingleTickerProviderStateMixin {
  Map<String, double> _rates = {};
  List<CurrencyModel> _currencies = [];
  bool _loading = true;
  bool _hasError = false;

  String _baseCurrency = 'usd';
  String _baseCurrencyName = 'US Dollar';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final List<String> _displayCurrencies = [
    'eur', 'gbp', 'pkr', 'sar', 'aed',
    'cad', 'aud', 'jpy', 'cny', 'inr',
    'chf', 'try', 'myr', 'sgd', 'kwd',
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData({String? base}) async {
    final selectedBase = base ?? _baseCurrency;
    try {
      setState(() {
        _loading = true;
        _hasError = false;
      });
      _fadeCtrl.reset();

      final results = await Future.wait([
        http.get(Uri.parse(
            'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies.json')),
        http.get(Uri.parse(
            'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/$selectedBase.json')),
      ]);

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final namesJson = json.decode(results[0].body) as Map<String, dynamic>;
        final sorted = namesJson.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        final currencies = sorted
            .map((e) => CurrencyModel.fromJson(e))
        //ADD THIS LINE Skip codes starting with number
            .where((c) => !RegExp(r'^[0-9]').hasMatch(c.code))
            .toList();

        final ratesJson = json.decode(results[1].body) as Map<String, dynamic>;
        final Map<String, double> rates =
        (ratesJson[selectedBase] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));

        final baseName = namesJson[selectedBase] ?? selectedBase.toUpperCase();

        setState(() {
          _currencies = currencies;
          _rates = rates;
          _baseCurrency = selectedBase;
          _baseCurrencyName = baseName.toString();
          _loading = false;
        });
        _fadeCtrl.forward();
      } else {
        setState(() {
          _hasError = true;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  //Currency Picker Bottom Sheet
  void _showCurrencyPicker() {
    final TextEditingController searchCtrl = TextEditingController();
    List<CurrencyModel> filtered = List.from(_currencies);

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;

    //Pre-calculate all colors for the sheet
    final Color sheetBg       = isDark ? darkCard : lightCard;
    final Color handleColor   = isDark ? darkDivider : lightDivider;
    final Color titleColor    = isDark ? darkTextPrimary : lightTextPrimary;
    final Color closeBtnBg    = isDark ? darkBg : lightBg;
    final Color closeBtnIcon  = isDark ? darkTextGrey : lightTextGrey;
    final Color searchBg      = isDark ? darkInputFill : lightInputFill;
    final Color searchBorder  = isDark ? darkInputBorder : lightInputBorder;
    final Color hintColor     = isDark ? darkTextGrey : lightTextGrey;
    final Color selectedBg    = isDark ? goldBorder15 : Color(0xFFFAF3D6);
    final Color selectedBrd   = isDark ? gold : Color(0xFFE8D080);
    final Color unselectedBg  = isDark ? darkCard : lightCard;
    final Color unselectedBrd = isDark ? darkDivider : lightDivider;
    final Color codeColor     = isDark ? darkTextPrimary : lightTextPrimary;
    final Color nameColor     = isDark ? darkTextGrey : lightTextGrey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: h * 0.75,
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  //Handle bar
                  Container(
                    margin: EdgeInsets.only(top: h * 0.015),
                    width: w * 0.10,
                    height: 4,
                    decoration: BoxDecoration(
                      color: handleColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  //Title row
                  Padding(
                    padding:
                    EdgeInsets.fromLTRB(w * 0.05, h * 0.02, w * 0.05, 0),
                    child: Row(
                      children: [
                        Text(
                          'Select Base Currency',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: w * 0.08,
                            height: w * 0.08,
                            decoration: BoxDecoration(
                              color: closeBtnBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.close_rounded,
                                size: 18, color: closeBtnIcon),
                          ),
                        ),
                      ],
                    ),
                  ),

                  //Search
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        w * 0.05, h * 0.018, w * 0.05, h * 0.01),
                    child: Container(
                      decoration: BoxDecoration(
                        color: searchBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: goldDark, width: 1.2),
                      ),
                      child: TextField(
                        controller: searchCtrl,
                        cursorOpacityAnimates: true,
                        style: TextStyle(color: titleColor, fontSize: 14),
                        onChanged: (q) {
                          setModalState(() {
                            filtered = _currencies
                                .where((c) =>
                            c.code
                                .toLowerCase()
                                .contains(q.toLowerCase()) ||
                                c.name
                                    .toLowerCase()
                                    .contains(q.toLowerCase()))
                                .toList();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search currency...',
                          hintStyle:
                          TextStyle(color: hintColor, fontSize: 14),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: gold, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: h * 0.015, horizontal: w * 0.02),
                        ),
                      ),
                    ),
                  ),

                  //List
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final isSelected =
                            c.code.toLowerCase() == _baseCurrency;
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _loadData(base: c.code.toLowerCase());
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: h * 0.01),
                            padding: EdgeInsets.symmetric(
                                horizontal: w * 0.035, vertical: h * 0.015),
                            decoration: BoxDecoration(
                              color:
                              isSelected ? selectedBg : unselectedBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? selectedBrd
                                    : unselectedBrd,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(_flag(c.code),
                                    style: TextStyle(fontSize: 22)),
                                SizedBox(width: w * 0.03),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.code.toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: codeColor,
                                        ),
                                      ),
                                      Text(
                                        c.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: nameColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded,
                                      color: gold, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  //Helper Methods
  String _flag(String code) {
    final special = {
      'eur': '🇪🇺', 'xaf': '🌍', 'xof': '🌍',
      'xcd': '🌎', 'xpf': '🌏', 'xdr': '🌐',
      'btc': '₿', 'eth': '⟠', 'usdt': '💵',
    };
    final l = code.toLowerCase();
    if (special.containsKey(l)) return special[l]!;
    try {
      return code
          .toUpperCase()
          .substring(0, 2)
          .codeUnits
          .map((c) => String.fromCharCode(c + 127397))
          .join();
    } catch (_) {
      return '🏳️';
    }
  }

  String _fmt(double rate) {
    if (rate >= 1000) return rate.toStringAsFixed(0);
    if (rate >= 1) return rate.toStringAsFixed(2);
    return rate.toStringAsFixed(4);
  }

  String _name(String code) {
    try {
      return _currencies
          .firstWhere((c) => c.code.toLowerCase() == code.toLowerCase())
          .name;
    } catch (_) {
      return code.toUpperCase();
    }
  }

  //BUILD

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? darkBg : lightBg,
      body: _loading
          ? _buildLoader(isDark)
          : _hasError
          ? _buildError(isDark)
          : FadeTransition(opacity: _fadeAnim, child: _buildMain(isDark)),
      floatingActionButton: _buildFAB(),
    );
  }

  //Loader
  Widget _buildLoader(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: gold, strokeWidth: 2.5),
          SizedBox(height: 16),
          Text(
            'Loading rates...',
            style: TextStyle(
              color: isDark ? darkTextGrey : lightTextGrey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  //FAB
  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: goldShadow40,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CurrencyConverterScreen()),
        ),
        backgroundColor: gold,
        elevation: 0,
        icon:
        Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 22),
        label: Text(
          'Convert',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  //Main Content
  Widget _buildMain(bool isDark) {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;

    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        // Welcome Banner
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.027, w * 0.05, 0),
              child: _buildWelcomeBanner(w, h, isDark),
            ),
          ),
        ),

        //Hero card
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.02, w * 0.05, 0),
            child: _buildHeroCard(w, h, isDark),
          ),
        ),

        //Section title
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                w * 0.05, h * 0.035, w * 0.05, h * 0.017),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: h * 0.025,
                  decoration: BoxDecoration(
                    color: gold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: w * 0.025),
                Text(
                  'Live Rates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? darkTextPrimary : lightTextPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: w * 0.025, vertical: h * 0.005),
                  decoration: BoxDecoration(
                    color: isDark ? goldBorder15 : Color(0xFFF0E8C8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'vs ${_baseCurrency.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? gold : goldDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        //Rates list
        SliverPadding(
          padding: EdgeInsets.fromLTRB(w * 0.05, 0, w * 0.05, h * 0.14),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (_, i) {
                final code = _displayCurrencies[i];
                if (code == _baseCurrency) return SizedBox.shrink();
                return _buildRateRow(code, i, w, h, isDark);
              },
              childCount: _displayCurrencies.length,
            ),
          ),
        ),
      ],
    );
  }


  //Welcome Banner

  Widget _buildWelcomeBanner(double w, double h, bool isDark) {
    return Container(
      width: double.infinity,
      padding:
      EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.022),
      decoration: BoxDecoration(
        color: isDark ? darkCard : lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? goldBorder30 : Color(0xFFEEE4B8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? darkShadow : lightShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: w * 0.025, vertical: h * 0.005),
                  decoration: BoxDecoration(
                    color: isDark ? goldBorder15 : Color(0xFFF5ECC0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Currency App',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? gold : goldDark,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                SizedBox(height: h * 0.012),
                Text(
                  'Welcome to\nCurrenSee!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? darkTextPrimary : lightTextPrimary,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: h * 0.01),
                Text(
                  'Live rates • Instant conversion\nAlways accurate',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? darkTextGrey : lightTextGrey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: w * 0.04),
          Container(
            width: w * 0.20,
            height: w * 0.20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [goldLight, goldDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: goldShadow40,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text('💱', style: TextStyle(fontSize: 36)),
            ),
          ),
        ],
      ),
    );
  }


  //Hero Card Gold Gradient
  Widget _buildHeroCard(double w, double h, bool isDark) {
    final quickCodes = ['pkr', 'eur', 'gbp', 'aed', 'usd']
        .where((c) => c != _baseCurrency)
        .take(4)
        .toList();

    //Hero card overlay colors
    // Dark mode slightly brighter overlays for visibility
    final Color overlayCircleLarge =
    isDark ? const Color(0x33FFFFFF) : const Color(0x1FFFFFFF);
    final Color overlayCircleSmall =
    isDark ? const Color(0x1AFFFFFF) : const Color(0x14FFFFFF);
    final Color badgeBg =
    isDark ? const Color(0x44FFFFFF) : const Color(0x38FFFFFF);
    final Color badgeBorder =
    isDark ? const Color(0x88FFFFFF) : const Color(0x73FFFFFF);
    final Color liveBg =
    isDark ? const Color(0x33FFFFFF) : const Color(0x26FFFFFF);
    final Color subtitleColor =
    isDark ? const Color(0xAAFFFFFF) : const Color(0x8CFFFFFF);
    final Color dividerLine =
    isDark ? const Color(0x55FFFFFF) : const Color(0x40FFFFFF);
    final Color quickCodeLabel =
    isDark ? const Color(0xAAFFFFFF) : const Color(0x8CFFFFFF);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [goldDark, const Color(0xFF8B7318), const Color(0xFF6B5710)]
              : [goldLight, gold, goldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: goldShadow40,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          //Decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: w * 0.33,
              height: w * 0.33,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: overlayCircleLarge,
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: 20,
            child: Container(
              width: w * 0.20,
              height: w * 0.20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: overlayCircleSmall,
              ),
            ),
          ),

          //Content
          Padding(
            padding: EdgeInsets.all(w * 0.065),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Tappable badge live indicator
                Row(
                  children: [
                    GestureDetector(
                      onTap: _showCurrencyPicker,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: w * 0.035, vertical: h * 0.011),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: badgeBorder, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_flag(_baseCurrency),
                                style: TextStyle(fontSize: 16)),
                            SizedBox(width: w * 0.02),
                            Text(
                              _baseCurrency.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: w * 0.015),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: w * 0.025, vertical: h * 0.006),
                      decoration: BoxDecoration(
                        color: liveBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: w * 0.012),
                          Text(
                            'Live',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: h * 0.025),

                Text(
                  _baseCurrencyName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: h * 0.005),
                Text(
                  'Base rate · 1 ${_baseCurrency.toUpperCase()}',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
                  ),
                ),

                SizedBox(height: h * 0.025),
                Container(height: 1, color: dividerLine),
                SizedBox(height: h * 0.025),

                //Quick 4 rates
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: quickCodes.map((code) {
                    final rate = _rates[code];
                    return Expanded(
                      child: Column(
                        children: [
                          Text(_flag(code), style: TextStyle(fontSize: 22)),
                          SizedBox(height: h * 0.007),
                          Text(
                            code.toUpperCase(),
                            style: TextStyle(
                              color: quickCodeLabel,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: h * 0.005),
                          Text(
                            rate != null ? _fmt(rate) : '—',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //Rate Row
  Widget _buildRateRow(
      String code, int index, double w, double h, bool isDark) {
    final rate = _rates[code];
    final name = _name(code);

    //Rate badge colors
    final Color rateBadgeBg =
    isDark ? goldBorder15 : Color(0xFFFAF3D6);
    final Color rateBadgeBorder =
    isDark ? goldBorder30 : Color(0xFFE8D080);
    final Color rateBadgeText = isDark ? gold : goldDark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 60)),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - val)), child: child),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: h * 0.012),
        padding: EdgeInsets.symmetric(
            horizontal: w * 0.04, vertical: h * 0.016),
        decoration: BoxDecoration(
          color: isDark ? darkCard : lightCard,
          borderRadius: BorderRadius.circular(18),
          border: isDark
              ? Border.all(color: darkDivider, width: 0.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: isDark ? darkShadow : lightShadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: w * 0.125,
              height: w * 0.125,
              decoration: BoxDecoration(
                color: isDark ? darkBg : lightBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(_flag(code), style: TextStyle(fontSize: 24)),
              ),
            ),
            SizedBox(width: w * 0.035),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isDark ? darkTextPrimary : lightTextPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: h * 0.004),
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? darkTextGrey : lightTextGrey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.035, vertical: h * 0.01),
              decoration: BoxDecoration(
                color: rateBadgeBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: rateBadgeBorder, width: 1),
              ),
              child: Text(
                rate != null ? _fmt(rate) : '—',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: rateBadgeText,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  //Error Screen
  Widget _buildError(bool isDark) {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(w * 0.10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: w * 0.20,
              height: w * 0.20,
              decoration: BoxDecoration(
                color: isDark ? darkCard : lightBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 38,
                  color: isDark ? darkTextGrey : lightTextGrey),
            ),
            SizedBox(height: h * 0.025),
            Text(
              'No Connection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? darkTextPrimary : lightTextPrimary,
              ),
            ),
            SizedBox(height: h * 0.01),
            Text(
              'Internet check karen\naur dobara try karen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? darkTextGrey : lightTextGrey,
                height: 1.5,
              ),
            ),
            SizedBox(height: h * 0.035),
            GestureDetector(
              onTap: () => _loadData(),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.07, vertical: h * 0.017),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [goldLight, goldDark]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: goldShadow40,
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}