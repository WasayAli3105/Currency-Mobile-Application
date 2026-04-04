import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:curren_see/Module/currency_model.dart';
import 'package:curren_see/Constants/Constants.dart';

class CurrencyListscreen extends StatefulWidget {
  const CurrencyListscreen({super.key});

  @override
  State<CurrencyListscreen> createState() => _CurrencyListscreenState();
}

class _CurrencyListscreenState extends State<CurrencyListscreen> {
  late Future<List<CurrencyModel>> _currenciesFuture;

  final TextEditingController _searchCtrl = TextEditingController();
  List<CurrencyModel> _allCurrencies = [];
  List<CurrencyModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _currenciesFuture = _fetchCurrencies();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<CurrencyModel>> _fetchCurrencies() async {
    final response = await http.get(Uri.parse(
        'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies.json'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final sorted = jsonData.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final currencies = sorted
          .map((e) => CurrencyModel.fromJson(e))
      // Skip "1inch" and any code starting with number
          .where((c) => !RegExp(r'^[0-9]').hasMatch(c.code))
          .toList();
      setState(() {
        _allCurrencies = currencies;
        _filtered = currencies;
      });
      return currencies;
    } else {
      throw Exception('Failed to load currencies');
    }
  }

  void _onSearch() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filtered = _allCurrencies;
      } else {
        _filtered = _allCurrencies.where((c) {
          return c.code.toLowerCase().contains(query) ||
              c.name.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  String _flag(String code) {
    const special = {
      'eur': '🇪🇺', 'xaf': '🌍', 'xof': '🌍',
      'xcd': '🌎', 'xpf': '🌏', 'xdr': '🌐',
      'btc': '₿', 'eth': '⟠', 'usdt': '💵',
      'xau': '🥇', 'xag': '🥈', 'xpt': '⚪', 'xpd': '🔵',
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

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    //NO SCAFFOLD, NO APPBAR
    return Column(
      children: [
        //SEARCH BAR
        Container(
          width: double.infinity,
          color: gold,
          padding: EdgeInsets.fromLTRB(
              width * 0.04, height * 0.012, width * 0.04, height * 0.018),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? darkCard : lightCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              cursorOpacityAnimates: true,
              cursorColor: gold,
              style: TextStyle(
                  fontSize: 15,
                  color: isDark ? darkTextPrimary : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search by name or code...',
                hintStyle: TextStyle(
                    color: isDark ? darkTextGrey : Colors.grey.shade400,
                    fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: gold),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear,
                      color: isDark ? darkTextGrey : Colors.grey,
                      size: 20),
                  onPressed: () => _searchCtrl.clear(),
                )
                    : null,
                border: InputBorder.none,
                contentPadding:
                EdgeInsets.symmetric(vertical: height * 0.018),
              ),
            ),
          ),
        ),


        // BODY CONTENT
        Expanded(
          child: FutureBuilder<List<CurrencyModel>>(
            future: _currenciesFuture,
            builder: (context, snapshot) {
              // Loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                          color: gold, strokeWidth: 3),
                      SizedBox(height: 14),
                      Text('Loading currencies...',
                          style: TextStyle(
                              color:
                              isDark ? darkTextGrey : Colors.black38,
                              fontSize: 13)),
                    ],
                  ),
                );
              }

              // Error
              if (snapshot.hasError || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          size: 52,
                          color: isDark
                              ? darkTextGrey
                              : Colors.grey.shade300),
                      SizedBox(height: 12),
                      Text('Failed to load currencies',
                          style: TextStyle(
                              color: isDark
                                  ? darkTextGrey
                                  : Colors.black45,
                              fontSize: 15)),
                    ],
                  ),
                );
              }

              // Data loaded
              return Column(
                children: [
                  // Count bar
                  Container(
                    width: double.infinity,
                    color: theme.scaffoldBackgroundColor,
                    padding: EdgeInsets.fromLTRB(width * 0.05,
                        height * 0.012, width * 0.05, height * 0.008),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: width * 0.03,
                              vertical: height * 0.005),
                          decoration: BoxDecoration(
                            color: isDark
                                ? gold.withAlpha(38)
                                : Color(0xFFF0E8C8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.monetization_on_outlined,
                                  color: isDark ? gold : goldDark,
                                  size: 14),
                              SizedBox(width: 5),
                              Text(
                                '${_filtered.length} found',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? gold : goldDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Text(
                          'Total: ${_allCurrencies.length}',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? darkTextGrey
                                  : Colors.grey.shade400,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                      height: 1,
                      color:
                      isDark ? darkDivider : Color(0xFFEEE4B8)),

                  // List
                  Expanded(
                    child: _filtered.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 52,
                              color: isDark
                                  ? darkTextGrey
                                  : Colors.grey.shade300),
                          SizedBox(height: 12),
                          Text(
                            '"${_searchCtrl.text}" nahi mila',
                            style: TextStyle(
                                color: isDark
                                    ? darkTextGrey
                                    : Colors.grey.shade400,
                                fontSize: 14),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.04,
                        vertical: height * 0.01,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final currency = _filtered[index];
                        return _buildCurrencyTile(currency,
                            index, width, height, isDark);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // Currency tile (Same as before no changes)
  Widget _buildCurrencyTile(CurrencyModel currency, int index,
      double width, double height, bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + (index % 15) * 40),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
            offset: Offset(0, 16 * (1 - val)), child: child),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: height * 0.011),
        decoration: BoxDecoration(
          color: isDark ? darkCard : lightCard,
          borderRadius: BorderRadius.circular(16),
          border:
          isDark ? Border.all(color: goldBorder15, width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? goldShadow40.withAlpha(15)
                  : Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
              horizontal: width * 0.04, vertical: height * 0.008),
          leading: Container(
            width: width * 0.12,
            height: width * 0.12,
            decoration: BoxDecoration(
              color: isDark ? darkBg : lightBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? goldBorder15 : Color(0xFFEEE4B8),
                  width: 1),
            ),
            child: Center(
              child: Text(_flag(currency.code),
                  style: TextStyle(fontSize: 22)),
            ),
          ),
          title: Text(
            currency.code,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: isDark ? gold : Colors.black87,
              letterSpacing: 0.3,
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: height * 0.004),
            child: Text(
              currency.name.isEmpty ? currency.code : currency.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? darkTextGrey : Colors.grey.shade500,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.03, vertical: height * 0.008),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [gold.withAlpha(38), gold.withAlpha(25)]
                    : [Color(0xFFFAF3D6), Color(0xFFF5ECC0)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isDark
                      ? goldBorder30
                      : Color(0xFFE8D080).withAlpha(153),
                  width: 1),
            ),
            child: Text(
              currency.code,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isDark ? gold : goldDark,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}