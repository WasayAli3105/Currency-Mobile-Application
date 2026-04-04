import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:curren_see/Module/currency_model.dart';
import 'package:curren_see/Screens/UserPreferences_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curren_see/Constants/Constants.dart';


//Bottom Sheet Currency Picker

class CurrencyconverterScreen extends StatefulWidget {
  final List<CurrencyModel> currencies;
  final String selectedCode;
  final String Function(String) getFlagEmoji;

  const CurrencyconverterScreen({
    super.key,
    required this.currencies,
    required this.selectedCode,
    required this.getFlagEmoji,
  });

  @override
  State<CurrencyconverterScreen> createState() => _CurrencyconverterScreenState();
}

class _CurrencyconverterScreenState extends State<CurrencyconverterScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<CurrencyModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.currencies;
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = widget.currencies.where((c) {
        return c.code.toLowerCase().contains(query) ||
            c.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Theme values
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? darkCard : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: isDark ? darkDivider : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Currency',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? gold : Colors.black87),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              cursorColor: gold,
              style: TextStyle(
                  color: isDark ? darkTextPrimary : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search by name or code...',
                hintStyle: TextStyle(
                    color: isDark ? darkTextGrey : Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: gold),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear,
                      color: isDark ? darkTextGrey : Colors.grey),
                  onPressed: () => _searchCtrl.clear(),
                )
                    : null,
                filled: true,
                fillColor: isDark ? darkBg : lightBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: gold, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filtered.length} currencies',
                style: TextStyle(fontSize: 12,
                    color: isDark ? darkTextGrey : Colors.grey.shade500),
              ),
            ),
          ),
          Divider(height: 1, color: isDark ? darkDivider : null),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 48,
                      color: isDark ? darkTextGrey : Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('No currency found',
                      style: TextStyle(
                          color: isDark ? darkTextGrey : Colors.grey.shade400)),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final currency = _filtered[index];
                final bool isSelected =
                    currency.code.toLowerCase() ==
                        widget.selectedCode.toLowerCase();

                return ListTile(
                  tileColor: isSelected
                      ? (isDark ? gold.withAlpha(25) : const Color(0xFFFFF8E1))
                      : null,
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? darkBg : lightBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        widget.getFlagEmoji(currency.code),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  title: Text(
                    currency.code,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isSelected
                            ? gold
                            : (isDark ? darkTextPrimary : Colors.black87)),
                  ),
                  subtitle: Text(
                    currency.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12,
                        color: isDark ? darkTextGrey : Colors.grey.shade500),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: gold, size: 22)
                      : null,
                  onTap: () => Navigator.pop(
                      context, currency.code.toLowerCase()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


//Main Converter Screen

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountCtrl = TextEditingController();

  String _fromCurrency = 'usd';
  String _toCurrency   = 'pkr';

  late Future<List<CurrencyModel>> _currenciesFuture;
  Future<Map<String, dynamic>>? _resultFuture;

  @override
  void initState() {
    super.initState();
    _currenciesFuture = fetchCurrencies();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await UserPrefs.load();
    setState(() {
      _fromCurrency = prefs.baseCurrency;
      _toCurrency   = prefs.defaultToCurrency;
    });
  }

  Future<void> saveToHistory({
    required double amount,
    required double result,
    required double rate,
  }) async {
    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('conversionHistory')
          .add({
        'fromCurrency': _fromCurrency.toUpperCase(),
        'toCurrency'  : _toCurrency.toUpperCase(),
        'amount'      : amount,
        'result'      : result,
        'rate'        : rate,
        'timestamp'   : FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('History save error: $e');
    }
  }

  String getFlagEmoji(String currencyCode) {
    const specialFlags = {
      'eur': '🇪🇺', 'xaf': '🌍', 'xof': '🌍',
      'xcd': '🌎', 'xpf': '🌏', 'xdr': '🌐',
      'btc': '₿',  'eth': '⟠',  'usdt': '💵',
    };
    final lower = currencyCode.toLowerCase();
    if (specialFlags.containsKey(lower)) return specialFlags[lower]!;
    try {
      final countryCode = currencyCode.toUpperCase().substring(0, 2);
      return countryCode.codeUnits
          .map((c) => String.fromCharCode(c + 127397)).join();
    } catch (_) {
      return '🏳️';
    }
  }

  Future<List<CurrencyModel>> fetchCurrencies() async {
    final response = await http.get(Uri.parse(
        'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies.json'));
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonData = json.decode(response.body);
      List<MapEntry<String, dynamic>> sortedEntries =
      jsonData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      return sortedEntries
          .map((e) => CurrencyModel.fromJson(e))
      //ADD THIS LINE — Skip codes starting with number
          .where((c) => !RegExp(r'^[0-9]').hasMatch(c.code))
          .toList();
    } else {
      throw Exception('Failed To Load Currencies!!');
    }
  }

  Future<Map<String, dynamic>> fetchConversion() async {
    final response = await http.get(Uri.parse(
        'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/$_fromCurrency.json'));
    if (response.statusCode == 200) {
      final data             = json.decode(response.body);
      final double rate      = (data[_fromCurrency][_toCurrency] as num).toDouble();
      final double amount    = double.parse(_amountCtrl.text.trim());
      final double converted = amount * rate;
      await saveToHistory(amount: amount, result: converted, rate: rate);
      return {'rate': rate, 'converted': converted};
    } else {
      throw Exception('Failed To Load Rate!!');
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp    = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency   = temp;
      _resultFuture = null;
    });
  }

  Future<void> _openCurrencyPicker({
    required List<CurrencyModel> currencies,
    required bool isFrom,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CurrencyconverterScreen(
        currencies:   currencies,
        selectedCode: isFrom ? _fromCurrency : _toCurrency,
        getFlagEmoji: getFlagEmoji,
      ),
    );
    if (result != null) {
      setState(() {
        if (isFrom) _fromCurrency = result;
        else _toCurrency = result;
        _resultFuture = null;
      });
    }
  }

  //Currency card with dark mode
  Widget _buildCurrencyCard({
    required String currencyCode,
    required List<CurrencyModel> currencies,
    required bool isFrom,
    required bool isDark,
  }) {
    final currency = currencies.firstWhere(
          (c) => c.code.toLowerCase() == currencyCode.toLowerCase(),
      orElse: () => CurrencyModel.fromJson(MapEntry(currencyCode, '')),
    );

    return GestureDetector(
      onTap: () => _openCurrencyPicker(currencies: currencies, isFrom: isFrom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? darkCard : lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? goldBorder30 : goldLight, width: 1.5),
        ),
        child: Row(
          children: [
            Text(getFlagEmoji(currencyCode),
                style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency.code,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? darkTextPrimary : Colors.black87),
                  ),
                  Text(
                    currency.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12,
                        color: isDark ? darkTextGrey : Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: gold, size: 28),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double h = MediaQuery.of(context).size.height;
    final double w = MediaQuery.of(context).size.width;

    //Theme values
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<List<CurrencyModel>>(
        future: _currenciesFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: gold, strokeWidth: 3),
            );
          }

          if (snapshot.hasError || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 52,
                      color: isDark ? darkTextGrey : Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Data Not Found',
                      style: TextStyle(
                          color: isDark ? darkTextGrey : Colors.black45,
                          fontSize: 15)),
                ],
              ),
            );
          }

          final List<CurrencyModel> currencies = snapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.05, vertical: h * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                //From
                _sectionLabel('From', isDark),
                SizedBox(height: h * 0.008),
                _buildCurrencyCard(
                  currencyCode: _fromCurrency,
                  currencies: currencies,
                  isFrom: true,
                  isDark: isDark,
                ),

                //Swap Button
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: h * 0.012),
                    child: Material(
                      color: gold,
                      shape: const CircleBorder(),
                      elevation: 4,
                      shadowColor: goldShadow40,
                      child: InkWell(
                        onTap: _swapCurrencies,
                        customBorder: const CircleBorder(),
                        splashColor: Colors.white24,
                        highlightColor: Colors.white12,
                        child: SizedBox(
                          width: w * 0.12, height: w * 0.12,
                          child: const Icon(Icons.swap_vert,
                              color: Colors.white, size: 26),
                        ),
                      ),
                    ),
                  ),
                ),

                //To
                _sectionLabel('To', isDark),
                SizedBox(height: h * 0.008),
                _buildCurrencyCard(
                  currencyCode: _toCurrency,
                  currencies: currencies,
                  isFrom: false,
                  isDark: isDark,
                ),

                SizedBox(height: h * 0.02),

                //Amount
                _sectionLabel('Amount', isDark),
                SizedBox(height: h * 0.008),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? darkCard : lightCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isDark ? goldBorder30 : goldLight, width: 1.5),
                  ),
                  child: TextField(
                    cursorColor: gold,
                    cursorOpacityAnimates: true,
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? darkTextPrimary : Colors.black87),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                          color: isDark ? darkTextGrey : Colors.grey.shade400,
                          fontSize: 18),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('\$',
                            style: TextStyle(
                                fontSize: 20,
                                color: gold,
                                fontWeight: FontWeight.bold)),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: h * 0.018, horizontal: w * 0.02,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.018),

                //CONVERT Button
                SizedBox(
                  width: double.infinity, height: h * 0.065,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4B84A), Color(0xFFC7A729), Color(0xFFB8941F)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x55C7A729),
                            blurRadius: 12,
                            offset: Offset(0, 5))
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        if (_amountCtrl.text.trim().isEmpty) return;
                        setState(() {
                          _resultFuture = fetchConversion();
                        });
                      },
                      child: const Text(
                        'CONVERT',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.02),

                //Result Card
                if (_resultFuture != null)
                  FutureBuilder<Map<String, dynamic>>(
                    future: _resultFuture,
                    builder: (context, resultSnapshot) {

                      if (resultSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(color: gold));
                      }

                      if (resultSnapshot.hasError) {
                        return Center(child: Text('Data Not Found',
                            style: TextStyle(
                                color: isDark ? darkTextGrey : Colors.black45)));
                      }

                      final double rate      = resultSnapshot.data!['rate'];
                      final double converted = resultSnapshot.data!['converted'];

                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(w * 0.05),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD4B84A), Color(0xFFC7A729)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x66C7A729),
                                blurRadius: 16,
                                offset: Offset(0, 6))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(getFlagEmoji(_fromCurrency),
                                    style: const TextStyle(fontSize: 26)),
                                SizedBox(width: w * 0.025),
                                Text(
                                  '${_amountCtrl.text} ${_fromCurrency.toUpperCase()}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: h * 0.01),
                              child: const Icon(Icons.arrow_downward,
                                  color: Colors.white70, size: 20),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(getFlagEmoji(_toCurrency),
                                    style: const TextStyle(fontSize: 26)),
                                SizedBox(width: w * 0.025),
                                Flexible(
                                  child: Text(
                                    '${converted.toStringAsFixed(2)} ${_toCurrency.toUpperCase()}',
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h * 0.015),
                            Divider(color: Colors.white.withAlpha(102), thickness: 1),
                            SizedBox(height: h * 0.01),
                            Text(
                              '1 ${_fromCurrency.toUpperCase()} = $rate ${_toCurrency.toUpperCase()}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: h * 0.008),
                            Row(
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    color: Colors.white70, size: 13),
                                const SizedBox(width: 4),
                                const Text('Saved to History',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.white70)),
                                const Spacer(),
                                const Icon(Icons.access_time_rounded,
                                    color: Colors.white70, size: 13),
                                const SizedBox(width: 4),
                                const Text('Live rate · fawazahmed0 API',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.white70)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  //Section label with dark mode
  Widget _sectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: isDark ? goldLight : Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }
}