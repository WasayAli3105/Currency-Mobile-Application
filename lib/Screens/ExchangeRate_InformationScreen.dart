import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:curren_see/Module/currency_model.dart';
import 'package:curren_see/Screens/UserPreferences_Screen.dart';
import 'package:curren_see/Constants/Constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RateHistory {
  final String date;
  final double rate;
  RateHistory({required this.date, required this.rate});
}

class ExchangerateInformationscreen extends StatefulWidget {
  ExchangerateInformationscreen({super.key});
  @override
  State<ExchangerateInformationscreen> createState() =>
      _ExchangerateInformationscreenState();
}

class _ExchangerateInformationscreenState
    extends State<ExchangerateInformationscreen> {

  List<CurrencyModel> _allCurrencies = [];
  bool _currenciesLoaded = false;

  String _fromCode = 'inr';
  String _fromName = 'Indian Rupee';
  String _toCode   = 'eur';
  String _toName   = 'Euro';

  final TextEditingController _searchCtrl = TextEditingController();
  List<CurrencyModel> _searchResults      = [];
  bool _showResults                       = false;
  String _searchFor                       = 'from';

  int _selectedDays   = 30;
  List<RateHistory> _history = [];
  bool _chartLoading  = false;
  bool _chartError    = false;
  double _currentRate = 0;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadPrefsAndInit();
  }

  Future<void> _loadPrefsAndInit() async {
    final prefs = await UserPrefs.load();
    setState(() {
      _fromCode     = prefs.baseCurrency;
      _fromName     = prefs.baseCurrencyName;
      _toCode       = prefs.defaultToCurrency;
      _toName       = prefs.defaultToCurrencyName;
      _selectedDays = prefs.defaultDays;
    });
    _fetchCurrencies();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _fetchCurrencies() async {
    try {
      final res = await http.get(Uri.parse(
          'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies.json'));
      if (res.statusCode == 200) {
        final data   = json.decode(res.body) as Map<String, dynamic>;
        final sorted = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
        setState(() {
          _allCurrencies = sorted
              .map((e) => CurrencyModel.fromJson(e))
          //ADD THIS LINE — Skip codes starting with number
              .where((c) => !RegExp(r'^[0-9]').hasMatch(c.code))
              .toList();
          _currenciesLoaded = true;
        });
        _fetchChart();
      }
    } catch (_) {}
  }

  Future<void> _fetchChart() async {
    setState(() { _chartLoading = true; _chartError = false; _history = []; });
    try {
      final base = _fromCode.toLowerCase();
      final to   = _toCode.toLowerCase();

      final curRes = await http.get(Uri.parse(
          'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/$base.json'));
      if (curRes.statusCode == 200) {
        final d = json.decode(curRes.body);
        _currentRate = (d[base][to] as num).toDouble();
      }

      final futures = List.generate(_selectedDays, (i) {
        final date = _dateStr(i + 1);
        return http.get(Uri.parse(
            'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@$date/v1/currencies/$base.json'))
            .then((res) {
          if (res.statusCode == 200) {
            final d   = json.decode(res.body);
            final map = d[base] as Map<String, dynamic>?;
            if (map != null && map.containsKey(to))
              return RateHistory(date: date, rate: (map[to] as num).toDouble());
          }
          return null;
        }).catchError((_) => null);
      });

      final results = await Future.wait(futures);
      final history = results.whereType<RateHistory>().toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      setState(() { _history = history; _chartLoading = false; });
    } catch (_) {
      setState(() { _chartError = true; _chartLoading = false; });
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) { _searchResults = []; _showResults = false; }
      else {
        _searchResults = _allCurrencies.where((c) =>
        c.code.toLowerCase().contains(q) ||
            c.name.toLowerCase().contains(q)).take(8).toList();
        _showResults = true;
      }
    });
  }

  void _selectFromSearch(CurrencyModel c) {
    setState(() {
      if (_searchFor == 'from') { _fromCode = c.code.toLowerCase(); _fromName = c.name; }
      else { _toCode = c.code.toLowerCase(); _toName = c.name; }
      _searchCtrl.clear(); _showResults = false;
    });
    FocusScope.of(context).unfocus();
    _fetchChart();
  }

  void _dismissSearch() {
    setState(() { _searchCtrl.clear(); _showResults = false; });
    FocusScope.of(context).unfocus();
  }

  Future<void> _openCurrencyPicker({required bool isFrom}) async {
    if (!_currenciesLoaded) return;
    final result = await showModalBottomSheet<CurrencyModel>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _CurrencyPickerSheet(
        currencies: _allCurrencies,
        selectedCode: isFrom ? _fromCode : _toCode,
        label: isFrom ? 'From' : 'To',
        getFlagEmoji: _flag,
      ),
    );
    if (result != null) {
      setState(() {
        if (isFrom) { _fromCode = result.code.toLowerCase(); _fromName = result.name; }
        else { _toCode = result.code.toLowerCase(); _toName = result.name; }
      });
      _fetchChart();
    }
  }

  Future<void> _showExportDialog() async {
    if (_history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No Data To Export'), backgroundColor: Colors.red));
      return;
    }
    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _ExportDialogSheet(
        history: _history, fromCode: _fromCode, toCode: _toCode,
        fromName: _fromName, toName: _toName, currentRate: _currentRate,
        selectedDays: _selectedDays, fmtRate: _fmtRate, shortDate: _shortDate,
        flag: _flag, high: _high, low: _low, changePct: _changePct,
        onDownloadPDF: _downloadPDF,
      ),
    );
  }

  // ── PDF (unchanged — PDF has its own colors) ──
  static final PdfColor _pGold       = PdfColor.fromHex('C7A729');
  static final PdfColor _pGoldDark   = PdfColor.fromHex('B8941F');
  static final PdfColor _pGoldLight  = PdfColor.fromHex('D4B84A');
  static final PdfColor _pBgCream    = PdfColor.fromHex('F5F0E8');
  static final PdfColor _pRowAlt     = PdfColor.fromHex('FAF8F2');
  static final PdfColor _pHeaderBg   = PdfColor.fromHex('FFF8E1');
  static final PdfColor _pBorderGold = PdfColor.fromHex('EEE4B8');
  static final PdfColor _pGrey666    = PdfColor.fromHex('666666');
  static final PdfColor _pGrey999    = PdfColor.fromHex('999999');
  static final PdfColor _pText       = PdfColor.fromHex('333333');
  static final PdfColor _pGreen      = PdfColor.fromHex('2E7D32');
  static final PdfColor _pRed        = PdfColor.fromHex('C62828');
  static final PdfColor _pGreenLight = PdfColor.fromHex('E8F5E9');
  static final PdfColor _pRedLight   = PdfColor.fromHex('FFEBEE');

  Future<void> _downloadPDF() async {
    if (_history.isEmpty) return;
    try {
      final pdf  = pw.Document();
      final pair = '${_fromCode.toUpperCase()} / ${_toCode.toUpperCase()}';
      final isUp = _changePct >= 0;

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.all(32),
        header: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('Exchange Rate History', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _pGoldDark)), pw.SizedBox(height: 4), pw.Text(pair, style: pw.TextStyle(fontSize: 14, color: _pGrey666)),]), pw.Container(padding: pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: pw.BoxDecoration(color: _pHeaderBg, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)), border: pw.Border.all(color: _pGoldLight, width: 1.5)), child: pw.Text('$_selectedDays Days', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _pGoldDark, fontSize: 13)),),]), pw.SizedBox(height: 8), pw.Divider(color: _pGoldLight, thickness: 2), pw.SizedBox(height: 8),]),
        build: (_) => [pw.Container(padding: pw.EdgeInsets.all(16), decoration: pw.BoxDecoration(color: _pGold, borderRadius: pw.BorderRadius.all(pw.Radius.circular(12))), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('Current Rate', style: pw.TextStyle(color: PdfColors.white, fontSize: 11)), pw.SizedBox(height: 4), pw.Text('1 ${_fromCode.toUpperCase()} = ${_fmtRate(_currentRate)} ${_toCode.toUpperCase()}', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 18)),]), pw.Container(padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: pw.BoxDecoration(color: isUp ? _pGreenLight : _pRedLight, borderRadius: pw.BorderRadius.all(pw.Radius.circular(20))), child: pw.Text('${isUp ? '+' : ''}${_changePct.toStringAsFixed(2)}%', style: pw.TextStyle(color: isUp ? _pGreen : _pRed, fontWeight: pw.FontWeight.bold, fontSize: 13)),),]),),
          pw.SizedBox(height: 16),
          pw.Row(children: [
            _pdfStatBox('${_selectedDays}D High', _fmtRate(_high), _pGreen),
            pw.SizedBox(width: 12),
            _pdfStatBox('${_selectedDays}D Low', _fmtRate(_low), _pRed),
            pw.SizedBox(width: 12),
            _pdfStatBox('Data Points', '${_history.length} days', _pGoldDark),]),
          pw.SizedBox(height: 20),
          pw.Text('Rate History', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _pText)),
          pw.SizedBox(height: 10),
          pw.Table(border: pw.TableBorder.all(color: _pBorderGold, width: 0.8), columnWidths: {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(2.5), 2: pw.FlexColumnWidth(2), 3: pw.FlexColumnWidth(1.5)},
            children: [
              pw.TableRow(decoration: pw.BoxDecoration(color: _pHeaderBg), children: [_pdfCell('Date', bold: true), _pdfCell('Rate', bold: true), _pdfCell('Change %', bold: true), _pdfCell('Trend', bold: true),]),
              ..._history.asMap().entries.map((entry) {
                final i = entry.key; final h = entry.value; final isFirst = i == 0;
                final prevRate = isFirst ? h.rate : _history[i - 1].rate;
                final diff = h.rate - prevRate;
                final diffPct = isFirst ? 0.0 : (diff / prevRate) * 100;
                final up = diff >= 0;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: i.isEven ? PdfColors.white : _pRowAlt),
                  children: [_pdfCell(_shortDate(h.date)), _pdfCell(_fmtRate(h.rate)), _pdfCell(isFirst ? '-' : '${up ? '+' : ''}${diffPct.toStringAsFixed(3)}%', color: isFirst ? _pGrey999 : up ? _pGreen : _pRed), _pdfCell(isFirst ? 'Start' : (up ? 'UP' : 'DOWN'), color: isFirst ? _pGrey999 : up ? _pGreen : _pRed, bold: !isFirst),],);}).toList(),],),
          pw.SizedBox(height: 24),
          pw.Container(padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: _pBgCream, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
            child: pw.Text('Generated by CurrenSee  •  $_fromName to $_toName  •  ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(fontSize: 9, color: _pGrey999)),),],));
      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes,
          filename: '${_fromCode.toUpperCase()}_${_toCode.toUpperCase()}_RateHistory.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF error: $e'), backgroundColor: Colors.red));
    }
  }

  pw.Widget _pdfStatBox(String label, String value, PdfColor color) {
    return pw.Expanded(child: pw.Container(padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _pBorderGold, width: 1), borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: color, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _pText)),
      ]),
    ));
  }

  pw.Widget _pdfCell(String text, {bool bold = false, PdfColor? color}) {
    return pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? _pText)));
  }

  // ── Helpers ──
  String _dateStr(int daysAgo) { final d = DateTime.now().subtract(Duration(days: daysAgo)); return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'; }
  String _shortDate(String s) { final p = s.split('-'); if (p.length < 3) return s; final m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; return '${m[int.tryParse(p[1]) ?? 1]} ${p[2]}'; }
  String _flag(String code) { final sp = {'eur':'🇪🇺','xaf':'🌍','xof':'🌍','xcd':'🌎','xpf':'🌏','xdr':'🌐','btc':'₿','eth':'⟠','usdt':'💵','xau':'🥇','xag':'🥈'}; final l = code.toLowerCase(); if (sp.containsKey(l)) return sp[l]!; try { return code.toUpperCase().substring(0,2).codeUnits.map((c) => String.fromCharCode(c+127397)).join(); } catch (_) { return '🏳️'; } }
  String _fmtRate(double r) { if (r >= 1000) return r.toStringAsFixed(0); if (r >= 1) return r.toStringAsFixed(5); return r.toStringAsFixed(6); }
  double get _high => _history.isEmpty ? 0 : _history.map((h) => h.rate).reduce(max);
  double get _low  => _history.isEmpty ? 0 : _history.map((h) => h.rate).reduce(min);
  double get _changePct { if (_history.length < 2) return 0; return ((_currentRate - _history.first.rate) / _history.first.rate) * 100; }
  bool get _isUp => _changePct >= 0;

  //BUILD
  @override
  Widget build(BuildContext context) {
    final double h = MediaQuery.of(context).size.height;
    final double w = MediaQuery.of(context).size.width;
    //Theme
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: _dismissSearch,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,

        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.025),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildCurrencySelectors(w, h, isDark),
            SizedBox(height: h * 0.02),
            _buildSearchBar(w, h, isDark),
            if (_showResults) _buildSearchResults(w, h, isDark),
            SizedBox(height: h * 0.018),
            _buildDaysToggle(w, h, isDark),
            SizedBox(height: h * 0.018),
            _buildCurrentRate(w, h),
            SizedBox(height: h * 0.018),
            _buildChart(w, h, isDark),
            SizedBox(height: h * 0.018),
            if (_history.isNotEmpty) _buildStatsRow(w, h, isDark),
            SizedBox(height: h * 0.025),
            _buildExportButton(w, h, isDark),
            SizedBox(height: h * 0.03),
          ]),
        ),
      ),
    );
  }

  //Currency Selectors
  Widget _buildCurrencySelectors(double w, double h, bool isDark) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child: GestureDetector(
        onTap: () => _openCurrencyPicker(isFrom: true),
        child: _currencyBox(label: 'From', code: _fromCode, name: _fromName, w: w, h: h, isDark: isDark),
      )),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.03),
        child: ElevatedButton(
          onPressed: () { setState(() { final tc = _fromCode; final tn = _fromName; _fromCode = _toCode; _fromName = _toName; _toCode = tc; _toName = tn; }); _fetchChart(); },
          style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.white, elevation: 6,
              shadowColor: goldShadow40, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.008), minimumSize: Size(w * 0.13, h * 0.042)),
          child: Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 26),
        ),
      ),
      Expanded(child: GestureDetector(
        onTap: () => _openCurrencyPicker(isFrom: false),
        child: _currencyBox(label: 'To', code: _toCode, name: _toName, w: w, h: h, isDark: isDark),
      )),
    ]);
  }

  Widget _currencyBox({required String label, required String code,
    required String name, required double w, required double h, required bool isDark}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.004),
      decoration: BoxDecoration(
        color: isDark ? darkCard : lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? goldBorder30 : goldLight, width: 1.5),
        boxShadow: [BoxShadow(color: isDark ? Colors.transparent : Colors.black.withAlpha(10),
            blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10,
            color: isDark ? darkTextGrey : Colors.grey.shade400, fontWeight: FontWeight.w600)),
        SizedBox(height: h * 0.002),
        Row(children: [
          Text(_flag(code), style: TextStyle(fontSize: 18)),
          SizedBox(width: w * 0.02),
          Expanded(child: Text(code.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w800,
              fontSize: 15, color: isDark ? darkTextPrimary : Colors.black87))),
          Icon(Icons.keyboard_arrow_down_rounded, color: gold, size: 18),
        ]),
        SizedBox(height: h * 0.001),
        Text(name, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: isDark ? darkTextGrey : Colors.grey.shade500)),
      ]),
    );
  }

  //Search Bar
  Widget _buildSearchBar(double w, double h, bool isDark) {
    return Column(children: [
      Container(
        decoration: BoxDecoration(
          color: isDark ? darkCard : lightCard,
          borderRadius: _showResults ? BorderRadius.vertical(top: Radius.circular(14)) : BorderRadius.circular(14),
          border: Border.all(color: _showResults ? gold : (isDark ? goldBorder30 : goldLight), width: 1.5),
          boxShadow: [BoxShadow(color: isDark ? Colors.transparent : Colors.black.withAlpha(10), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: TextField(
          controller: _searchCtrl, cursorOpacityAnimates: true, cursorColor: gold,
          style: TextStyle(fontSize: 14, color: isDark ? darkTextPrimary : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Search From Currency...',
            hintStyle: TextStyle(color: isDark ? darkTextGrey : Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: gold),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(icon: Icon(Icons.clear, color: isDark ? darkTextGrey : Colors.grey, size: 20), onPressed: _dismissSearch) : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: h * 0.018),
          ),
        ),
      ),
      if (_searchCtrl.text.isNotEmpty || _showResults)
        Container(
          decoration: BoxDecoration(
            color: isDark ? darkBg : lightBg,
            border: Border(
              left: BorderSide(color: _showResults ? gold : (isDark ? goldBorder30 : goldLight), width: 1.5),
              right: BorderSide(color: _showResults ? gold : (isDark ? goldBorder30 : goldLight), width: 1.5),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.009),
          child: Row(children: [
            Text('Search for:', style: TextStyle(fontSize: 11,
                color: isDark ? darkTextGrey : Colors.grey.shade500, fontWeight: FontWeight.w500)),
            SizedBox(width: w * 0.025),
            ...[
              {'key': 'from', 'label': 'From', 'flag': _flag(_fromCode)},
              {'key': 'to', 'label': 'To', 'flag': _flag(_toCode)},
            ].map((item) {
              final sel = _searchFor == item['key'];
              return Padding(
                padding: EdgeInsets.only(right: w * 0.02),
                child: GestureDetector(
                  onTap: () => setState(() => _searchFor = item['key']!),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.005),
                    decoration: BoxDecoration(
                      color: sel ? gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? gold : (isDark ? darkDivider : Colors.grey.shade300), width: 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(item['flag']!, style: TextStyle(fontSize: 12)),
                      SizedBox(width: w * 0.01),
                      Text(item['label']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : (isDark ? darkTextGrey : Colors.grey.shade500))),
                    ]),
                  ),
                ),
              );
            }),
          ]),
        ),
    ]);
  }

  //Search Results
  Widget _buildSearchResults(double w, double h, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? darkCard : lightCard,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
        border: Border.all(color: gold, width: 1.5),
        boxShadow: [BoxShadow(color: isDark ? Colors.transparent : Colors.black.withAlpha(20), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: _searchResults.isEmpty
          ? Padding(padding: EdgeInsets.all(h * 0.02),
          child: Center(child: Text('No currency found',
              style: TextStyle(color: isDark ? darkTextGrey : Colors.grey.shade400, fontSize: 13))))
          : Column(children: _searchResults.map((c) {
        final isSel = _searchFor == 'from' ? c.code.toLowerCase() == _fromCode : c.code.toLowerCase() == _toCode;
        return GestureDetector(
          onTap: () => _selectFromSearch(c),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.012),
            decoration: BoxDecoration(
              color: isSel ? (isDark ? gold.withAlpha(25) : Color(0xFFFFF8E1)) : Colors.transparent,
              border: Border(bottom: BorderSide(
                  color: c == _searchResults.last ? Colors.transparent : (isDark ? darkDivider : Color(0xFFEEE4B8)), width: 1)),
            ),
            child: Row(children: [
              Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: isDark ? darkBg : lightBg, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text(_flag(c.code), style: TextStyle(fontSize: 18)))),
              SizedBox(width: w * 0.03),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.code.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                    color: isSel ? gold : (isDark ? darkTextPrimary : Colors.black87))),
                Text(c.name, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: isDark ? darkTextGrey : Colors.grey.shade500)),
              ])),
              if (isSel) Icon(Icons.check_circle, color: gold, size: 18),
            ]),
          ),
        );
      }).toList()),
    );
  }

  //Days Toggle
  Widget _buildDaysToggle(double w, double h, bool isDark) {
    return Container(
      padding: EdgeInsets.all(w * 0.015),
      decoration: BoxDecoration(
        color: isDark ? darkCard : lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? goldBorder30 : goldLight, width: 1.5),
      ),
      child: Row(children: [30, 60, 90].map((days) {
        final sel = _selectedDays == days;
        return Expanded(child: GestureDetector(
          onTap: () { if (_selectedDays != days) { setState(() => _selectedDays = days); _fetchChart(); } },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(vertical: h * 0.012),
            decoration: BoxDecoration(color: sel ? gold : Colors.transparent, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (sel) Padding(padding: EdgeInsets.only(right: w * 0.015),
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 14)),
              Text('$days Days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : (isDark ? darkTextGrey : Colors.grey.shade500))),
            ]),
          ),
        ));
      }).toList()),
    );
  }

  // Current Rate (Gold gradient same both modes)
  Widget _buildCurrentRate(double w, double h) {
    if (_chartLoading || _currentRate == 0) return SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.018),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [goldLight, goldDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Color(0x44C7A729), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(children: [
        Expanded(child: RichText(text: TextSpan(children: [
          TextSpan(text: '1 ${_fromCode.toUpperCase()} = ', style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 14, fontWeight: FontWeight.w500)),
          TextSpan(text: _fmtRate(_currentRate), style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          TextSpan(text: ' ${_toCode.toUpperCase()}', style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 15, fontWeight: FontWeight.w700)),
        ]))),
        if (_history.isNotEmpty) Container(
          padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: h * 0.006),
          decoration: BoxDecoration(color: _isUp ? Colors.green.withAlpha(64) : Colors.red.withAlpha(64), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: _isUp ? Color(0xFF69F0AE) : Color(0xFFFF5252), size: 14),
            SizedBox(width: 4),
            Text('${_isUp ? '+' : ''}${_changePct.toStringAsFixed(2)}%',
                style: TextStyle(color: _isUp ? Color(0xFF69F0AE) : Color(0xFFFF5252), fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  //Chart
  Widget _buildChart(double w, double h, bool isDark) {
    return Container(
      width: double.infinity, padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: isDark ? darkCard : lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? goldBorder15 : Color(0xFFEEE4B8), width: 1),
        boxShadow: [BoxShadow(color: isDark ? Colors.transparent : Colors.black.withAlpha(10), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 3, height: h * 0.02,
              decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(4))),
          SizedBox(width: w * 0.025),
          Text('${_fromCode.toUpperCase()} → ${_toCode.toUpperCase()}  |  $_selectedDays Day Trend',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: isDark ? gold : Colors.black87)),
        ]),
        SizedBox(height: h * 0.018),
        SizedBox(height: h * 0.28,
          child: _chartLoading
              ? Center(child: CircularProgressIndicator(color: gold, strokeWidth: 2.5))
              : _chartError
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bar_chart_rounded, size: 40, color: isDark ? darkTextGrey : Colors.grey.shade300),
            SizedBox(height: 8),
            Text('Chart data unavailable', style: TextStyle(color: isDark ? darkTextGrey : Colors.grey.shade400, fontSize: 13)),
          ]))
              : _history.isEmpty
              ? Center(child: Text('No data', style: TextStyle(color: isDark ? darkTextGrey : Colors.grey.shade400)))
              : _RateChart(history: _history, hoveredIndex: _hoveredIndex,
              onHover: (i) => setState(() => _hoveredIndex = i), isDark: isDark),
        ),
        if (_history.isNotEmpty && !_chartLoading) ...[
          SizedBox(height: h * 0.01),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_shortDate(_history.first.date), style: TextStyle(fontSize: 10, color: isDark ? darkTextGrey : Colors.grey.shade400)),
            if (_history.length > 2) Text(_shortDate(_history[_history.length ~/ 2].date),
                style: TextStyle(fontSize: 10, color: isDark ? darkTextGrey : Colors.grey.shade400)),
            Text(_shortDate(_history.last.date), style: TextStyle(fontSize: 10, color: isDark ? darkTextGrey : Colors.grey.shade400)),
          ]),
        ],
      ]),
    );
  }

  //Stats Row
  Widget _buildStatsRow(double w, double h, bool isDark) {
    return Row(children: [
      Expanded(child: _statTile('${_selectedDays}D High', _fmtRate(_high), Icons.arrow_upward_rounded,
          Color(0xFF2E7D32), isDark ? Color(0xFF2E7D32).withAlpha(25) : Color(0xFFE8F5E9), w, h, isDark)),
      SizedBox(width: w * 0.03),
      Expanded(child: _statTile('${_selectedDays}D Low', _fmtRate(_low), Icons.arrow_downward_rounded,
          Color(0xFFC62828), isDark ? Color(0xFFC62828).withAlpha(25) : Color(0xFFFFEBEE), w, h, isDark)),
      SizedBox(width: w * 0.03),
      Expanded(child: _statTile('Data Points', '${_history.length} days', Icons.show_chart_rounded,
          goldDark, isDark ? gold.withAlpha(25) : Color(0xFFFFF8E1), w, h, isDark)),
    ]);
  }

  Widget _statTile(String label, String value, IconData icon,
      Color iconColor, Color iconBg, double w, double h, bool isDark) {
    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: isDark ? darkCard : lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? goldBorder15 : Color(0xFFEEE4B8), width: 1),
        boxShadow: [BoxShadow(color: isDark ? Colors.transparent : Colors.black.withAlpha(10), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: w * 0.08, height: w * 0.08,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 16)),
        SizedBox(height: h * 0.009),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12,
            color: isDark ? darkTextPrimary : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: h * 0.003),
        Text(label, style: TextStyle(fontSize: 10,
            color: isDark ? darkTextGrey : Colors.grey.shade500, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  //Export Button
  Widget _buildExportButton(double w, double h, bool isDark) {
    return SizedBox(width: double.infinity, height: h * 0.065,
      child: ElevatedButton.icon(
        onPressed: _history.isNotEmpty ? _showExportDialog : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _history.isNotEmpty ? gold : (isDark ? darkCard : Colors.grey.shade200),
          foregroundColor: Colors.white, elevation: _history.isNotEmpty ? 4 : 0,
          shadowColor: goldShadow40,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: Icon(Icons.file_present_rounded,
            color: _history.isNotEmpty ? (isDark ? Colors.black : Colors.white) : (isDark ? darkTextGrey : Colors.grey.shade400), size: 20),
        label: Text('Export Data', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
            color: _history.isNotEmpty ? (isDark ? Colors.black : Colors.white) : (isDark ? darkTextGrey : Colors.grey.shade400), letterSpacing: 0.3)),
      ),
    );
  }
}


//Export Dialog (Dark Mode)

class _ExportDialogSheet extends StatelessWidget {
  final List<RateHistory> history;
  final String fromCode, toCode, fromName, toName;
  final double currentRate, high, low, changePct;
  final int selectedDays;
  final String Function(double) fmtRate;
  final String Function(String) shortDate;
  final String Function(String) flag;
  final VoidCallback onDownloadPDF;

  _ExportDialogSheet({required this.history, required this.fromCode, required this.toCode,
    required this.fromName, required this.toName, required this.currentRate,
    required this.selectedDays, required this.fmtRate, required this.shortDate,
    required this.flag, required this.high, required this.low,
    required this.changePct, required this.onDownloadPDF});

  bool get isUp => changePct >= 0;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: h * 0.88,
      decoration: BoxDecoration(
        color: isDark ? darkBg : lightBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [
        SizedBox(height: 12),
        Container(width: 44, height: 4,
            decoration: BoxDecoration(color: isDark ? darkDivider : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10))),
        SizedBox(height: 16),

        // Header
        Padding(padding: EdgeInsets.symmetric(horizontal: w * 0.05),
            child: Row(children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: isDark ? gold.withAlpha(25) : Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? goldBorder30 : goldLight, width: 1.5)),
                  child: Icon(Icons.file_present_rounded, color: gold, size: 22)),
              SizedBox(width: w * 0.04),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Rate History Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: isDark ? gold : Colors.black87)),
                Text('${fromCode.toUpperCase()} → ${toCode.toUpperCase()}  •  $selectedDays Days',
                    style: TextStyle(fontSize: 12, color: isDark ? darkTextGrey : Colors.grey.shade500)),
              ])),
              GestureDetector(onTap: () => Navigator.pop(context),
                  child: Container(padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(color: isDark ? darkCard : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.close, size: 18, color: isDark ? darkTextGrey : Colors.grey))),
            ])),

        SizedBox(height: h * 0.018),

        // Current Rate Banner (Gold — same)
        Padding(padding: EdgeInsets.symmetric(horizontal: w * 0.05),
            child: Container(width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.016),
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [goldLight, goldDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Color(0x44C7A729), blurRadius: 10, offset: Offset(0, 4))]),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Current Rate', style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 11, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    Text('1 ${fromCode.toUpperCase()} = ${fmtRate(currentRate)} ${toCode.toUpperCase()}',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: isUp ? Colors.green.withAlpha(64) : Colors.red.withAlpha(64), borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(isUp ? Icons.trending_up : Icons.trending_down, color: isUp ? Color(0xFF69F0AE) : Color(0xFFFF5252), size: 14),
                          SizedBox(width: 4),
                          Text('${isUp ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                              style: TextStyle(color: isUp ? Color(0xFF69F0AE) : Color(0xFFFF5252), fontWeight: FontWeight.w800, fontSize: 12)),
                        ])),
                    SizedBox(height: 6),
                    Text('vs ${selectedDays}d ago', style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 10)),
                  ]),
                ]))),

        SizedBox(height: h * 0.014),

        // Mini Stats
        Padding(padding: EdgeInsets.symmetric(horizontal: w * 0.05),
            child: Row(children: [
              _miniStat('${selectedDays}D High', fmtRate(high), Color(0xFF2E7D32), w, isDark),
              SizedBox(width: w * 0.025),
              _miniStat('${selectedDays}D Low', fmtRate(low), Color(0xFFC62828), w, isDark),
              SizedBox(width: w * 0.025),
              _miniStat('Data Points', '${history.length}d', goldDark, w, isDark),
            ])),

        SizedBox(height: h * 0.016),

        // Daily Rates Header
        Padding(padding: EdgeInsets.symmetric(horizontal: w * 0.05),
            child: Row(children: [
              Container(width: 3, height: 16, decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(4))),
              SizedBox(width: w * 0.025),
              Text('Daily Rates', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                  color: isDark ? gold : Colors.black87)),
              Spacer(),
              Text('${history.length} entries', style: TextStyle(fontSize: 11,
                  color: isDark ? darkTextGrey : Colors.grey.shade500)),
            ])),

        SizedBox(height: h * 0.01),

        // History List
        Expanded(child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05),
          itemCount: history.length,
          itemBuilder: (_, i) {
            final reverseIdx = history.length - 1 - i;
            final item = history[reverseIdx]; final isFirst = reverseIdx == 0;
            final prevRate = isFirst ? item.rate : history[reverseIdx - 1].rate;
            final diff = item.rate - prevRate;
            final diffPct = isFirst ? 0.0 : (diff / prevRate) * 100;
            final itemUp = diff >= 0;

            return Container(
              margin: EdgeInsets.only(bottom: 6),
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.012),
              decoration: BoxDecoration(
                color: isDark ? darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isFirst ? (isDark ? goldBorder15 : Color(0xFFEEE4B8))
                        : itemUp ? Color(0xFFDFF3E4) : Color(0xFFFFE5E5), width: 1),
              ),
              child: Row(children: [
                SizedBox(width: w * 0.18,
                    child: Text(shortDate(item.date), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: isDark ? darkTextGrey : Colors.grey.shade700))),
                Expanded(child: Text(fmtRate(item.rate), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                    color: isDark ? darkTextPrimary : Colors.black87))),
                if (!isFirst) Container(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: 4),
                    decoration: BoxDecoration(
                        color: itemUp ? (isDark ? Color(0xFF2E7D32).withAlpha(38) : Color(0xFFE8F5E9))
                            : (isDark ? Color(0xFFC62828).withAlpha(38) : Color(0xFFFFEBEE)),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(itemUp ? Icons.arrow_upward : Icons.arrow_downward, size: 10,
                          color: itemUp ? Color(0xFF2E7D32) : Color(0xFFC62828)),
                      SizedBox(width: 2),
                      Text('${itemUp ? '+' : ''}${diffPct.toStringAsFixed(3)}%',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: itemUp ? Color(0xFF2E7D32) : Color(0xFFC62828))),
                    ])),
                if (isFirst) Container(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: 4),
                    decoration: BoxDecoration(color: isDark ? darkBg : lightBg, borderRadius: BorderRadius.circular(20)),
                    child: Text('Start', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: isDark ? darkTextGrey : Colors.grey.shade500))),
              ]),
            );
          },
        )),

        // PDF Button
        Container(
          padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.016, w * 0.05, h * 0.035),
          decoration: BoxDecoration(
              color: isDark ? darkCard : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: isDark ? Colors.transparent : Colors.black.withAlpha(15), blurRadius: 12, offset: Offset(0, -4))]),
          child: SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); onDownloadPDF(); },
                style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: h * 0.016),
                    backgroundColor: gold, foregroundColor: Colors.white, elevation: 4,
                    shadowColor: goldShadow40,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                icon: Icon(Icons.picture_as_pdf_rounded, color: isDark ? Colors.black : Colors.white, size: 20),
                label: Text('Download PDF', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                    color: isDark ? Colors.black : Colors.white, letterSpacing: 0.3)),
              )),
        ),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color iconColor, double w, bool isDark) {
    return Expanded(child: Container(
      padding: EdgeInsets.all(w * 0.03),
      decoration: BoxDecoration(
          color: isDark ? darkCard : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? goldBorder15 : Color(0xFFEEE4B8), width: 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 9,
            color: isDark ? darkTextGrey : Colors.grey.shade500, fontWeight: FontWeight.w500)),
        SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: iconColor),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ));
  }
}


//Currency Picker (Dark Mode)
class _CurrencyPickerSheet extends StatefulWidget {
  final List<CurrencyModel> currencies;
  final String selectedCode, label;
  final String Function(String) getFlagEmoji;
  _CurrencyPickerSheet({required this.currencies, required this.selectedCode,
    required this.label, required this.getFlagEmoji});
  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final TextEditingController _ctrl = TextEditingController();
  List<CurrencyModel> _filtered = [];

  @override
  void initState() { super.initState(); _filtered = widget.currencies; _ctrl.addListener(_onSearch); }
  void _onSearch() { final q = _ctrl.text.toLowerCase().trim();
  setState(() { _filtered = q.isEmpty ? widget.currencies : widget.currencies.where((c) =>
  c.code.toLowerCase().contains(q) || c.name.toLowerCase().contains(q)).toList(); }); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: h * 0.85,
      decoration: BoxDecoration(
          color: isDark ? darkCard : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: isDark ? darkDivider : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10))),
        SizedBox(height: 16),
        Text('Select ${widget.label} Currency', style: TextStyle(fontSize: 18,
            fontWeight: FontWeight.w800, color: isDark ? gold : Colors.black87)),
        SizedBox(height: 14),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(controller: _ctrl, autofocus: true, cursorColor: gold,
                style: TextStyle(color: isDark ? darkTextPrimary : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search by name or code...',
                  hintStyle: TextStyle(color: isDark ? darkTextGrey : Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: gold),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(icon: Icon(Icons.clear, color: isDark ? darkTextGrey : Colors.grey, size: 20),
                      onPressed: () => _ctrl.clear()) : null,
                  filled: true, fillColor: isDark ? darkBg : lightBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: gold, width: 1.5)),
                ))),
        SizedBox(height: 6),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(alignment: Alignment.centerLeft,
                child: Text('${_filtered.length} currencies',
                    style: TextStyle(fontSize: 12, color: isDark ? darkTextGrey : Colors.grey.shade500)))),
        Divider(height: 1, color: isDark ? darkDivider : Color(0xFFEEE4B8)),
        Expanded(
          child: _filtered.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.search_off, size: 48, color: isDark ? darkTextGrey : Colors.grey.shade300),
            SizedBox(height: 8),
            Text('No currency found', style: TextStyle(color: isDark ? darkTextGrey : Colors.grey.shade400)),
          ]))
              : ListView.builder(itemCount: _filtered.length, itemBuilder: (_, i) {
            final c = _filtered[i];
            final isSel = c.code.toLowerCase() == widget.selectedCode.toLowerCase();
            return ListTile(
              tileColor: isSel ? (isDark ? gold.withAlpha(25) : Color(0xFFFFF8E1)) : null,
              leading: Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: isDark ? darkBg : lightBg,
                      borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(widget.getFlagEmoji(c.code), style: TextStyle(fontSize: 22)))),
              title: Text(c.code.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                  color: isSel ? gold : (isDark ? darkTextPrimary : Colors.black87))),
              subtitle: Text(c.name, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: isDark ? darkTextGrey : Colors.grey.shade500)),
              trailing: isSel ? Icon(Icons.check_circle, color: gold, size: 22) : null,
              onTap: () => Navigator.pop(context, c),
            );
          }),
        ),
      ]),
    );
  }
}

//Chart Widget Dark Mode
class _RateChart extends StatelessWidget {
  final List<RateHistory> history;
  final int? hoveredIndex;
  final ValueChanged<int?> onHover;
  final bool isDark;
  _RateChart({required this.history, required this.hoveredIndex, required this.onHover, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final idx = ((details.localPosition.dx / box.size.width) * history.length).clamp(0, history.length - 1).round();
        onHover(idx);
      },
      onPanEnd: (_) => onHover(null),
      child: CustomPaint(
          painter: _ChartPainter(history: history, hoveredIndex: hoveredIndex, isDark: isDark),
          child: SizedBox.expand()),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<RateHistory> history;
  final int? hoveredIndex;
  final bool isDark;
  _ChartPainter({required this.history, this.hoveredIndex, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;
    final rates = history.map((h) => h.rate).toList();
    final minRate = rates.reduce(min); final maxRate = rates.reduce(max);
    final range = maxRate - minRate == 0 ? 1.0 : maxRate - minRate;

    final double padTop = 24, padBottom = 12, padLeft = 48, padRight = 12;
    final cW = size.width - padLeft - padRight;
    final cH = size.height - padTop - padBottom;

    Offset pt(int i, double r) => Offset(padLeft + (i / (history.length - 1)) * cW, padTop + (1 - (r - minRate) / range) * cH);
    final points = List.generate(history.length, (i) => pt(i, rates[i]));

    // Grid
    final gPaint = Paint()..color = isDark ? Color(0x33C7A729) : Color(0xFFE8D9A0)..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = padTop + (i / 4) * cH; double x = padLeft;
      while (x < size.width - padRight) { canvas.drawLine(Offset(x, y), Offset(min(x + 5, size.width - padRight), y), gPaint); x += 10; }
    }

    // Fill
    final fillPath = Path()..moveTo(points.first.dx, padTop + cH);
    for (final p in points) fillPath.lineTo(p.dx, p.dy);
    fillPath..lineTo(points.last.dx, padTop + cH)..close();
    canvas.drawPath(fillPath, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [gold.withAlpha(isDark ? 51 : 102), gold.withAlpha(0)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1]; final curr = points[i];
      linePath.cubicTo((prev.dx + curr.dx) / 2, prev.dy, (prev.dx + curr.dx) / 2, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(linePath, Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);

    // Y labels
    final lStyle = TextStyle(fontSize: 9, color: isDark ? Color(0xFF888888) : Color(0xFF999070), fontWeight: FontWeight.w500);
    for (int i = 0; i <= 4; i++) {
      final r = minRate + (1 - i / 4) * range; final y = padTop + (i / 4) * cH;
      String lbl = r >= 1000 ? r.toStringAsFixed(0) : r >= 1 ? r.toStringAsFixed(2) : r.toStringAsFixed(4);
      final tp = TextPainter(text: TextSpan(text: lbl, style: lStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }

    // Hover
    if (hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < history.length) {
      final idx = hoveredIndex!; final p = points[idx]; final r = rates[idx];
      final d = history[idx].date.split('-');
      final m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final lbl = '${d.length >= 3 ? d[2] : ''} ${m[int.tryParse(d.length >= 2 ? d[1] : '1') ?? 1]}';
      canvas.drawLine(Offset(p.dx, padTop), Offset(p.dx, padTop + cH), Paint()..color = gold.withAlpha(128)..strokeWidth = 1);
      canvas.drawCircle(p, 6, Paint()..color = gold.withAlpha(77));
      canvas.drawCircle(p, 4, Paint()..color = gold);
      String rStr = r >= 1000 ? r.toStringAsFixed(0) : r >= 1 ? r.toStringAsFixed(4) : r.toStringAsFixed(6);
      final ttP = TextPainter(text: TextSpan(text: '$lbl: $rStr',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
          textDirection: TextDirection.ltr)..layout();
      final pad = 6.0; final bw = ttP.width + pad * 2; final bh = ttP.height + pad * 2;
      double bx = (p.dx - bw / 2).clamp(padLeft, size.width - padRight - bw);
      final by = p.dy - bh - 10;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), Radius.circular(6)),
          Paint()..color = isDark ? Color(0xFF2A2A2A) : goldDark);
      ttP.paint(canvas, Offset(bx + pad, by + pad));
    } else {
      final last = points.last;
      canvas.drawCircle(last, 6, Paint()..color = gold.withAlpha(77));
      canvas.drawCircle(last, 4, Paint()..color = gold);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.hoveredIndex != hoveredIndex || old.history != history || old.isDark != isDark;
}