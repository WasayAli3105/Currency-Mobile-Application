import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curren_see/Module/currency_model.dart';
import 'package:curren_see/Constants/Constants.dart';

class UserPrefs {
  final String baseCurrency;
  final String baseCurrencyName;
  final String defaultToCurrency;
  final String defaultToCurrencyName;
  final int defaultDays;
  final bool autoRefresh;

  UserPrefs({
    this.baseCurrency = 'usd',
    this.baseCurrencyName = 'US Dollar',
    this.defaultToCurrency = 'eur',
    this.defaultToCurrencyName = 'Euro',
    this.defaultDays = 30,
    this.autoRefresh = true,
  });

  UserPrefs copyWith({
    String? baseCurrency,
    String? baseCurrencyName,
    String? defaultToCurrency,
    String? defaultToCurrencyName,
    int? defaultDays,
    bool? autoRefresh,
  }) =>
      UserPrefs(
        baseCurrency: baseCurrency ?? this.baseCurrency,
        baseCurrencyName: baseCurrencyName ?? this.baseCurrencyName,
        defaultToCurrency: defaultToCurrency ?? this.defaultToCurrency,
        defaultToCurrencyName:
        defaultToCurrencyName ?? this.defaultToCurrencyName,
        defaultDays: defaultDays ?? this.defaultDays,
        autoRefresh: autoRefresh ?? this.autoRefresh,
      );

  static String _kBase = 'pref_base_currency';
  static String _kBaseName = 'pref_base_name';
  static String _kTo = 'pref_to_currency';
  static String _kToName = 'pref_to_name';
  static String _kDays = 'pref_days';
  static String _kAutoRefresh = 'pref_auto_refresh';

  static Future<UserPrefs> load() async {
    final p = await SharedPreferences.getInstance();
    return UserPrefs(
      baseCurrency: p.getString(_kBase) ?? 'usd',
      baseCurrencyName: p.getString(_kBaseName) ?? 'US Dollar',
      defaultToCurrency: p.getString(_kTo) ?? 'eur',
      defaultToCurrencyName: p.getString(_kToName) ?? 'Euro',
      defaultDays: p.getInt(_kDays) ?? 30,
      autoRefresh: p.getBool(_kAutoRefresh) ?? true,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kBase, baseCurrency);
    await p.setString(_kBaseName, baseCurrencyName);
    await p.setString(_kTo, defaultToCurrency);
    await p.setString(_kToName, defaultToCurrencyName);
    await p.setInt(_kDays, defaultDays);
    await p.setBool(_kAutoRefresh, autoRefresh);
  }
}

class UserpreferencesScreen extends StatefulWidget {
  UserpreferencesScreen({super.key});

  @override
  State<UserpreferencesScreen> createState() =>
      _UserpreferencesScreenState();
}

class _UserpreferencesScreenState extends State<UserpreferencesScreen> {
  UserPrefs _prefs = UserPrefs();
  List<CurrencyModel> _allCurrencies = [];
  bool _loading = true;
  bool _saving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await UserPrefs.load();
    final currencies = await _fetchCurrencies();
    setState(() {
      _prefs = prefs;
      _allCurrencies = currencies;
      _loading = false;
    });
  }

  Future<List<CurrencyModel>> _fetchCurrencies() async {
    try {
      final res = await http.get(Uri.parse(
          'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies.json'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final sorted = data.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        return sorted
            .map((e) => CurrencyModel.fromJson(e))
        //ADD THIS LINE Skip codes starting with number
            .where((c) => !RegExp(r'^[0-9]').hasMatch(c.code))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  void _update(UserPrefs updated) {
    setState(() {
      _prefs = updated;
      _hasChanges = true;
    });
  }

  Future<void> _savePrefs() async {
    setState(() => _saving = true);
    await _prefs.save();
    setState(() {
      _saving = false;
      _hasChanges = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Color(0xFF2E7D32),
        content: Text(
          'Preferences Saved Successfully',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context, _prefs);
  }

  Future<void> _pickCurrency({required bool isBase}) async {
    if (_allCurrencies.isEmpty) return;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<CurrencyModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PrefCurrencyPicker(
        currencies: _allCurrencies,
        selectedCode:
        isBase ? _prefs.baseCurrency : _prefs.defaultToCurrency,
        title: isBase ? 'Base Currency' : 'Default To Currency',
        isDark: isDark,
      ),
    );
    if (result != null) {
      _update(isBase
          ? _prefs.copyWith(
          baseCurrency: result.code.toLowerCase(),
          baseCurrencyName: result.name)
          : _prefs.copyWith(
          defaultToCurrency: result.code.toLowerCase(),
          defaultToCurrencyName: result.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;

    final Color scaffoldBg  = isDark ? darkBg : lightBg;
    final Color titleColor  = isDark ? darkTextPrimary : lightTextPrimary;
    final Color greyText    = isDark ? darkTextGrey : lightTextGrey;
    final Color cardBg      = isDark ? darkCard : lightCard;
    final Color cardBorder  = isDark ? goldBorder30 : goldLight;
    final Color cardShadow  = isDark ? darkShadow : lightShadow;
    final Color sectionDiv  = isDark ? darkDivider : Color(0xFFEEE4B8);
    final Color badgeBg     = isDark ? goldBorder15 : Color(0xFFFFF8E1);
    final Color chevronClr  = isDark ? darkTextGrey : lightDivider;

    final Color daySelBg    = gold;
    final Color dayUnselBg  = Colors.transparent;
    final Color daySelText  = Colors.white;
    final Color dayUnselText = isDark ? darkTextGrey : lightTextGrey;
    final Color dayUnselBrd = isDark ? darkDivider : lightDivider;

    //Save button disabled
    final Color saveBtnDisabled = isDark ? darkCard : lightDivider;
    final Color saveBtnDisText  = isDark ? darkTextGrey : lightTextGrey;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: _loading
          ? Center(
          child: CircularProgressIndicator(
              color: gold, strokeWidth: 2.5))
          : SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: w * 0.05, vertical: h * 0.025),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(w, h, isDark),
            SizedBox(height: h * 0.025),
            _sectionHeader('Default Currencies',
                Icons.currency_exchange_rounded, titleColor),
            SizedBox(height: h * 0.012),
            _buildCurrencySection(
                w, h, isDark, cardBg, cardBorder, cardShadow,
                sectionDiv, titleColor, greyText, badgeBg, chevronClr),
            SizedBox(height: h * 0.025),
            _sectionHeader('Chart Preferences',
                Icons.show_chart_rounded, titleColor),
            SizedBox(height: h * 0.012),
            _buildChartSection(
                w, h, isDark, cardBg, cardBorder, cardShadow,
                sectionDiv, titleColor, greyText, daySelBg,
                dayUnselBg, daySelText, dayUnselText, dayUnselBrd),
            SizedBox(height: h * 0.03),
            _buildSaveButton(w, h, saveBtnDisabled, saveBtnDisText),
            SizedBox(height: h * 0.03),
          ],
        ),
      ),
    );
  }


  //Profile Card
  Widget _buildProfileCard(double w, double h, bool isDark) {
    final Color avatarBg = isDark
        ? const Color(0x44FFFFFF)
        : const Color(0x40FFFFFF);
    final Color subtextColor = isDark
        ? const Color(0xD9FFFFFF)
        : const Color(0xD9FFFFFF);
    final Color unsavedBg = isDark
        ? const Color(0x33FFFFFF)
        : const Color(0x33FFFFFF);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [goldDark, const Color(0xFF8B7318)]
              : [goldLight, goldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: goldShadow40,
              blurRadius: 12,
              offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: w * 0.08,
            backgroundColor: avatarBg,
            child: Text(
              '₿',
              style: TextStyle(
                fontSize: w * 0.07,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Preferences',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Base: ${_prefs.baseCurrency.toUpperCase()}  •  '
                      '${_prefs.baseCurrency.toUpperCase()} → ${_prefs.defaultToCurrency.toUpperCase()}',
                  style: TextStyle(color: subtextColor, fontSize: 12),
                ),
                SizedBox(height: 6),
                if (_hasChanges)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: unsavedBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Unsaved changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //Currency Section
    Widget _buildCurrencySection(
      double w, double h, bool isDark,
      Color cardBg, Color cardBorder, Color cardShadow,
      Color sectionDiv, Color titleColor, Color greyText,
      Color badgeBg, Color chevronClr) {
    //Icon backgrounds (dark-safe)
    final Color homeIconBg = isDark ? goldBorder15 : Color(0xFFFFF8E1);
    final Color swapIconBg = isDark ? const Color(0x1A1565C0) : Color(0xFFE3F2FD);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _currencyTile(
            label: 'Base Currency',
            subtitle: 'Your default starting currency',
            code: _prefs.baseCurrency,
            name: _prefs.baseCurrencyName,
            icon: Icons.home_rounded,
            iconColor: goldDark,
            iconBg: homeIconBg,
            isLast: false,
            onTap: () => _pickCurrency(isBase: true),
            w: w, h: h,
            titleColor: titleColor, greyText: greyText,
            badgeBg: badgeBg, divColor: sectionDiv,
            chevronClr: chevronClr,
          ),
          _currencyTile(
            label: 'Default "To" Currency',
            subtitle: 'Currency to convert to by default',
            code: _prefs.defaultToCurrency,
            name: _prefs.defaultToCurrencyName,
            icon: Icons.swap_horiz_rounded,
            iconColor: Color(0xFF1565C0),
            iconBg: swapIconBg,
            isLast: true,
            onTap: () => _pickCurrency(isBase: false),
            w: w, h: h,
            titleColor: titleColor, greyText: greyText,
            badgeBg: badgeBg, divColor: sectionDiv,
            chevronClr: chevronClr,
          ),
        ],
      ),
    );
  }

  Widget _currencyTile({
    required String label,
    required String subtitle,
    required String code,
    required String name,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required bool isLast,
    required VoidCallback onTap,
    required double w,
    required double h,
    required Color titleColor,
    required Color greyText,
    required Color badgeBg,
    required Color divColor,
    required Color chevronClr,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: w * 0.045, vertical: h * 0.018),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: divColor, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: w * 0.1,
              height: w * 0.1,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            SizedBox(width: w * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  SizedBox(height: h * 0.003),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: greyText),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.03, vertical: h * 0.007),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: goldLight, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_flag(code), style: TextStyle(fontSize: 16)),
                  SizedBox(width: w * 0.015),
                  Text(
                    code.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: goldDark,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: w * 0.02),
            Icon(Icons.chevron_right_rounded,
                color: chevronClr, size: 20),
          ],
        ),
      ),
    );
  }

    //Chart Section
    Widget _buildChartSection(
      double w, double h, bool isDark,
      Color cardBg, Color cardBorder, Color cardShadow,
      Color sectionDiv, Color titleColor, Color greyText,
      Color daySelBg, Color dayUnselBg, Color daySelText,
      Color dayUnselText, Color dayUnselBrd) {

    final Color dateIconBg = isDark ? const Color(0x332E7D32) : Color(0xFFE8F5E9);
    final Color autoIconBg = isDark ? const Color(0x336A1B9A) : Color(0xFFF3E5F5);
    final Color activeTrack = isDark ? goldBorder30 : Color(0xFFFFE9A0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          //Days Range
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.045, vertical: h * 0.018),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: sectionDiv, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: w * 0.1,
                  height: w * 0.1,
                  decoration: BoxDecoration(
                    color: dateIconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.date_range_rounded,
                      color: Color(0xFF2E7D32), size: 20),
                ),
                SizedBox(width: w * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default Days Range',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      SizedBox(height: h * 0.003),
                      Text(
                        'Historical chart timeframe',
                        style: TextStyle(
                            fontSize: 11, color: greyText),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [30, 60, 90].map((days) {
                    final sel = _prefs.defaultDays == days;
                    return GestureDetector(
                      onTap: () => _update(
                          _prefs.copyWith(defaultDays: days)),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 150),
                        margin: EdgeInsets.only(left: w * 0.015),
                        padding: EdgeInsets.symmetric(
                            horizontal: w * 0.025,
                            vertical: h * 0.006),
                        decoration: BoxDecoration(
                          color: sel ? daySelBg : dayUnselBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel ? gold : dayUnselBrd,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          '${days}D',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: sel ? daySelText : dayUnselText,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          //Auto Refresh Toggle
          _toggleTile(
            label: 'Auto Refresh',
            subtitle: 'Refresh rates on screen open',
            icon: Icons.autorenew_rounded,
            iconColor: Color(0xFF6A1B9A),
            iconBg: autoIconBg,
            value: _prefs.autoRefresh,
            isLast: true,
            onChanged: (v) =>
                _update(_prefs.copyWith(autoRefresh: v)),
            w: w, h: h,
            titleColor: titleColor, greyText: greyText,
            sectionDiv: sectionDiv, activeTrack: activeTrack,
          ),
        ],
      ),
    );
  }

  Widget _toggleTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required bool value,
    required bool isLast,
    required ValueChanged<bool> onChanged,
    required double w,
    required double h,
    required Color titleColor,
    required Color greyText,
    required Color sectionDiv,
    required Color activeTrack,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: w * 0.045, vertical: h * 0.015),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
            bottom: BorderSide(color: sectionDiv, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: w * 0.1,
            height: w * 0.1,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                SizedBox(height: h * 0.003),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: greyText),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: gold,
            activeTrackColor: activeTrack,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
      String title, IconData icon, Color titleColor) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: gold,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 10),
        Icon(icon, color: goldDark, size: 18),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(
      double w, double h, Color disabledBg, Color disabledText) {
    return SizedBox(
      width: double.infinity,
      height: h * 0.065,
      child: ElevatedButton.icon(
        onPressed: (_hasChanges && !_saving) ? _savePrefs : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasChanges ? gold : disabledBg,
          foregroundColor: Colors.white,
          elevation: _hasChanges ? 4 : 0,
          shadowColor: goldShadow40,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon: _saving
            ? SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Colors.white),
        )
            : Icon(Icons.save_rounded,
            color: _hasChanges ? Colors.white : disabledText,
            size: 20),
        label: Text(
          _saving ? 'Saving...' : 'Save Preferences',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _hasChanges ? Colors.white : disabledText,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  String _flag(String code) {
    final sp = {
      'eur': '🇪🇺', 'btc': '₿', 'eth': '⟠',
      'usdt': '💵', 'xau': '🥇', 'xag': '🥈',
    };
    final l = code.toLowerCase();
    if (sp.containsKey(l)) return sp[l]!;
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
}


//Currency Picker Bottom Sheet

class _PrefCurrencyPicker extends StatefulWidget {
  final List<CurrencyModel> currencies;
  final String selectedCode;
  final String title;
  final bool isDark;

  _PrefCurrencyPicker({
    required this.currencies,
    required this.selectedCode,
    required this.title,
    required this.isDark,
  });

  @override
  State<_PrefCurrencyPicker> createState() =>
      _PrefCurrencyPickerState();
}

class _PrefCurrencyPickerState extends State<_PrefCurrencyPicker> {
  final TextEditingController _ctrl = TextEditingController();
  List<CurrencyModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.currencies;
    _ctrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _ctrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? widget.currencies
          : widget.currencies
          .where((c) =>
      c.code.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q))
          .toList();
    });
  }

  String _flag(String code) {
    final sp = {
      'eur': '🇪🇺', 'btc': '₿', 'eth': '⟠',
      'usdt': '💵', 'xau': '🥇', 'xag': '🥈',
    };
    final l = code.toLowerCase();
    if (sp.containsKey(l)) return sp[l]!;
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

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final bool isDark = widget.isDark;

    // ── Colors ──
    final Color sheetBg     = isDark ? darkCard : lightCard;
    final Color handleColor = isDark ? darkDivider : lightDivider;
    final Color titleColor  = isDark ? darkTextPrimary : lightTextPrimary;
    final Color hintColor   = isDark ? darkTextGrey : lightTextGrey;
    final Color inputFill   = isDark ? darkInputFill : lightInputFill;
    final Color inputBorder = isDark ? darkInputBorder : lightInputBorder;
    final Color clearIcon   = isDark ? darkTextGrey : lightTextGrey;
    final Color countColor  = isDark ? darkTextGrey : lightTextGrey;
    final Color divColor    = isDark ? darkDivider : Color(0xFFEEE4B8);
    final Color flagBoxBg   = isDark ? darkBg : lightBg;
    final Color codeColor   = isDark ? darkTextPrimary : lightTextPrimary;
    final Color nameColor   = isDark ? darkTextGrey : lightTextGrey;
    final Color selectedBg  = isDark ? goldBorder15 : Color(0xFFFFF8E1);

    return Container(
      height: h * 0.85,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: 16),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          SizedBox(height: 14),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              cursorColor: gold,
              style: TextStyle(color: titleColor),
              decoration: InputDecoration(
                hintText: 'Search currency...',
                hintStyle: TextStyle(color: hintColor),
                prefixIcon: Icon(Icons.search, color: gold),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear,
                      color: clearIcon, size: 20),
                  onPressed: () => _ctrl.clear(),
                )
                    : null,
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: inputBorder, width: 1.5),
                ),
              ),
            ),
          ),
          SizedBox(height: 6),
          Padding(
            padding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filtered.length} currencies',
                style:
                TextStyle(fontSize: 12, color: countColor),
              ),
            ),
          ),
          Divider(height: 1, color: divColor),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                final isSel = c.code.toLowerCase() ==
                    widget.selectedCode.toLowerCase();
                return ListTile(
                  tileColor: isSel ? selectedBg : null,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: flagBoxBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _flag(c.code),
                        style: TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  title: Text(
                    c.code.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSel ? gold : codeColor,
                    ),
                  ),
                  subtitle: Text(
                    c.name,
                    overflow: TextOverflow.ellipsis,
                    style:
                    TextStyle(fontSize: 12, color: nameColor),
                  ),
                  trailing: isSel
                      ? Icon(Icons.check_circle,
                      color: gold, size: 22)
                      : null,
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}