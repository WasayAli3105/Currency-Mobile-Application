import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:curren_see/Module/NewsArticleModel.dart';
import 'package:curren_see/Constants/Constants.dart';
import 'package:curren_see/Screens/NewsDetail_Screen.dart';

class MarketTrend {
  final String pair, fromCode, toCode;
  final double rate, change;
  MarketTrend({required this.pair, required this.fromCode,
    required this.toCode, required this.rate, required this.change});
}

class CurrencynewsMarkettrendsScreen extends StatefulWidget {
  CurrencynewsMarkettrendsScreen({super.key});
  @override
  State<CurrencynewsMarkettrendsScreen> createState() =>
      _CurrencynewsMarkettrendsScreenState();
}

class _CurrencynewsMarkettrendsScreenState
    extends State<CurrencynewsMarkettrendsScreen> {

  // news api use
  static final String _newsApiKey = 'pub_a061b3d37c6649bea083c8237a9ef536';

  List<MarketTrend> _trends = [];
  bool _loading = true;
  int? _touchedIdx;

  String _newsCategory = 'All';
  final List<String> _categories = ['All','Forex','Crypto','Economy'];
  Future<List<NewsArticleModel>>? _newsFuture;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final List<Map<String,String>> _majorPairs = [
    {'from':'usd','to':'eur','label':'USD/EUR'},
    {'from':'usd','to':'gbp','label':'USD/GBP'},
    {'from':'usd','to':'jpy','label':'USD/JPY'},
    {'from':'usd','to':'pkr','label':'USD/PKR'},
    {'from':'usd','to':'inr','label':'USD/INR'},
    {'from':'eur','to':'gbp','label':'EUR/GBP'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchTrends();
    _newsFuture = _fetchNews(_newsCategory);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTrends() async {
    setState(() => _loading = true);
    List<MarketTrend> result = [];
    try {
      final todayRes = await http.get(Uri.parse(
          'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json'));
      final yestRes = await http.get(Uri.parse(
          'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@${_dateStr(1)}/v1/currencies/usd.json'));
      if (todayRes.statusCode == 200) {
        final today = json.decode(todayRes.body);
        final yest = yestRes.statusCode == 200 ? json.decode(yestRes.body) : null;
        final todayRates = today['usd'] as Map<String,dynamic>?;
        for (int i = 0; i < _majorPairs.length; i++) {
          final p = _majorPairs[i]; final to = p['to']!;
          if (todayRates == null || !todayRates.containsKey(to)) continue;
          final rate = (todayRates[to] as num).toDouble();
          double change = 0;
          if (yest != null) {
            final yr = (yest['usd'] as Map?)?[to];
            if (yr != null)
              change = ((rate - (yr as num).toDouble()) / (yr as num).toDouble()) * 100;
          }
          result.add(MarketTrend(
            pair: p['label']!, fromCode: p['from']!, toCode: to,
            rate: rate, change: change,
          ));
        }
      }
    } catch (_) {}
    if (mounted) setState(() { _trends = result; _loading = false; });
  }

  Future<List<NewsArticleModel>> _fetchNews(String cat, {String? query}) async {
    final q = query != null && query.isNotEmpty ? query
        : {'All':'currency forex','Forex':'forex dollar euro exchange',
      'Crypto':'bitcoin crypto ethereum','Economy':'inflation GDP central bank'}[cat] ?? 'currency';
    final url = 'https://newsdata.io/api/1/news?apikey=$_newsApiKey'
        '&q=${Uri.encodeComponent(q)}&language=en&image=1&size=10';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final list = (json.decode(res.body)['results'] as List?) ?? [];
      return list.map((e) => NewsArticleModel.fromJson(e as Map<String,dynamic>))
          .where((a) => a.title != null && a.title!.isNotEmpty && a.title != '[Removed]'
          && a.imageUrl != null && a.imageUrl!.startsWith('http')).toList();
    }
    throw Exception('failed');
  }

  String _dateStr(int ago) {
    final d = DateTime.now().subtract(Duration(days: ago));
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }
  String _timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso).toLocal());
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }
  String _fmtRate(double r) {
    if (r >= 100) return r.toStringAsFixed(2);
    if (r >= 1)   return r.toStringAsFixed(4);
    return r.toStringAsFixed(5);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(children: [
          _buildChartCard(w, h, isDark),
          SizedBox(height: 20),
          _buildSearchBar(w, h, isDark),
          SizedBox(height: 20),
          Padding(padding: EdgeInsets.symmetric(horizontal: w * 0.04),
              child: _sectionTitle('Currency News', Icons.newspaper_rounded, isDark)),
          SizedBox(height: 10),
          _buildCategoryChips(w, h, isDark),
          SizedBox(height: 12),
          _buildNewsList(w, h, isDark),
          SizedBox(height: 30),
        ]),
      ),
    );
  }

  //Chart Card
  Widget _buildChartCard(double w, double h, bool isDark) {
    return Container(
      margin: EdgeInsets.fromLTRB(w*0.04, h*0.018, w*0.04, 0),
      decoration: BoxDecoration(
        color: isDark ? darkCard : lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? goldBorder15 : Color(0xFFE8D88A), width: 1),
        boxShadow: [BoxShadow(
            color: isDark ? goldShadow40.withAlpha(15) : gold.withAlpha(31),
            blurRadius: 12, offset: Offset(0,4))],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w*0.045),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: h * 0.018),
          Row(children: [
            Container(width: 3, height: 18,
                decoration: BoxDecoration(color: goldDark, borderRadius: BorderRadius.circular(3))),
            SizedBox(width: 8),
            Text('Market Trends',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                    color: isDark ? gold : Color(0xFF5A4400))),
          ]),
          SizedBox(height: 4),
          Text('Touch any point to inspect',
              style: TextStyle(fontSize: 9.5,
                  color: isDark ? darkTextGrey : Colors.grey.shade400)),
          SizedBox(height: h * 0.014),

          _loading
              ? SizedBox(height: h*0.28,
              child: Center(child: CircularProgressIndicator(color: gold, strokeWidth: 2)))
              : _trends.isEmpty
              ? SizedBox(height: h*0.28,
              child: Center(child: Text('No data',
                  style: TextStyle(color: isDark ? darkTextGrey : Colors.grey.shade400))))
              : LayoutBuilder(builder: (ctx, box) {
            final cw = box.maxWidth;
            final double padL = 46, padR = 8;
            final double innerW = cw - padL - padR;
            final int n = _trends.length;

            return GestureDetector(
              onPanStart:  (d) => _onTouch(d.localPosition.dx, padL, innerW, n),
              onPanUpdate: (d) => _onTouch(d.localPosition.dx, padL, innerW, n),
              onPanEnd:    (_) => setState(() => _touchedIdx = null),
              onTapDown:   (d) => _onTouch(d.localPosition.dx, padL, innerW, n),
              onTapUp:     (_) => setState(() => _touchedIdx = null),
              onTapCancel: ()  => setState(() => _touchedIdx = null),
              child: Column(children: [
                SizedBox(
                  width: cw,
                  height: h * 0.24,
                  child: CustomPaint(
                    painter: _SimpleCurrencyChart(
                      trends: _trends,
                      touchedIdx: _touchedIdx,
                      isDark: isDark,
                    ),
                  ),
                ),
                SizedBox(
                  height: 22,
                  child: Row(
                    children: [
                      SizedBox(width: padL),
                      ...List.generate(n, (i) {
                        final active = i == _touchedIdx;
                        return Expanded(
                          flex: i == n-1 ? 0 : 1,
                          child: Text(
                            _trends[i].toCode.toUpperCase(),
                            style: TextStyle(
                                fontSize: active ? 10 : 9,
                                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                                color: active
                                    ? (isDark ? gold : goldDark)
                                    : (isDark ? darkTextGrey : Colors.grey.shade500)),
                            textAlign: i == n-1 ? TextAlign.right : TextAlign.left,
                          ),
                        );
                      }),
                      SizedBox(width: padR),
                    ],
                  ),
                ),
              ]),
            );
          }),

          SizedBox(height: h * 0.010),
        ]),
      ),
    );
  }

  void _onTouch(double dx, double padL, double innerW, int n) {
    if (n < 2) return;
    final step = innerW / (n - 1);
    final idx  = ((dx - padL) / step).round().clamp(0, n - 1);
    setState(() => _touchedIdx = idx);
  }

  //Search Bar
  Widget _buildSearchBar(double w, double h, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? darkCard : lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? goldBorder30 : gold,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? goldShadow40.withAlpha(15)
                  : gold.withAlpha(25),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          cursorOpacityAnimates: true,
          cursorColor: gold,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? darkTextPrimary : Colors.black87,
          ),
          textInputAction: TextInputAction.search,
          onChanged: (val) {
            _debounce?.cancel();
            if (val.trim().isEmpty) {
              setState(() => _newsFuture = _fetchNews(_newsCategory));
              return;
            }
            _debounce = Timer(
              Duration(milliseconds: 600),
                  () => setState(
                    () => _newsFuture = _fetchNews(
                    _newsCategory, query: val.trim()),
              ),
            );
          },
          onSubmitted: (val) {
            _debounce?.cancel();
            FocusScope.of(context).unfocus();
            if (val.trim().isNotEmpty) {
              setState(
                    () => _newsFuture = _fetchNews(
                    _newsCategory, query: val.trim()),
              );
            }
          },
          decoration: InputDecoration(
            hintText: 'Search currency news...',
            hintStyle: TextStyle(
              color: isDark ? darkTextGrey : Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: gold),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear,
                  color: isDark ? darkTextGrey : Colors.grey,
                  size: 20),
              onPressed: () {
                _debounce?.cancel();
                _searchController.clear();
                FocusScope.of(context).unfocus();
                setState(
                        () => _newsFuture = _fetchNews(_newsCategory));
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding:
            EdgeInsets.symmetric(vertical: h * 0.018),
          ),
        ),
      ),
    );
  }

  //Category Chips
  Widget _buildCategoryChips(double w, double h, bool isDark) {
    return SizedBox(height: h*0.04,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: w*0.04),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i]; final sel = _newsCategory == cat;
          return GestureDetector(
            onTap: () {
              _searchController.clear(); FocusScope.of(context).unfocus();
              setState(() { _newsCategory = cat; _newsFuture = _fetchNews(cat); });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: w*0.025),
              padding: EdgeInsets.symmetric(horizontal: w*0.04, vertical: 6),
              decoration: BoxDecoration(
                  color: sel ? gold : (isDark ? darkCard : lightCard),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? gold : (isDark ? goldBorder30 : goldLight),
                      width: 1.2)),
              child: Text(cat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : (isDark ? darkTextGrey : Colors.grey.shade600))),
            ),
          );
        },
      ),
    );
  }

  //News List
  Widget _buildNewsList(double w, double h, bool isDark) {
    return FutureBuilder<List<NewsArticleModel>>(
      future: _newsFuture,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return Padding(padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator(color: gold, strokeWidth: 2.5)));
        if (snap.hasError || snap.data == null || snap.data!.isEmpty)
          return _emptyState('News unavailable', Icons.wifi_off_rounded, isDark);
        return ListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: w*0.04), itemCount: snap.data!.length,
            itemBuilder: (_, i) => _newsCard(snap.data![i], w, h, i == 0, isDark));
      },
    );
  }

  //UPDATED: News Card with onTap Navigation
  Widget _newsCard(NewsArticleModel a, double w, double h, bool featured, bool isDark) {

    if (featured) {
      return GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => NewsDetailScreen(article: a))),
        child: Container(
          margin: EdgeInsets.only(bottom: h*0.016),
          decoration: BoxDecoration(
              color: isDark ? darkCard : lightCard,
              borderRadius: BorderRadius.circular(18),
              border: isDark ? Border.all(color: goldBorder15) : null,
              boxShadow: [BoxShadow(
                  color: isDark ? Colors.transparent : Colors.black.withAlpha(20),
                  blurRadius: 12, offset: Offset(0,4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                child: _networkImage(a.imageUrl, width: double.infinity, height: h*0.22, isDark: isDark)),
            Padding(padding: EdgeInsets.all(w*0.045),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [goldLight, goldDark]),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('Top Story', style: TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
                  Spacer(),
                  Text(a.sourceName ?? '', style: TextStyle(fontSize: 11,
                      color: isDark ? darkTextGrey : Colors.grey.shade500)),
                ]),
                SizedBox(height: h*0.010),
                Text(a.title ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: isDark ? darkTextPrimary : Colors.black87, height: 1.35),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
                SizedBox(height: h*0.007),
                Text(a.description ?? '', style: TextStyle(fontSize: 12,
                    color: isDark ? darkTextGrey : Colors.grey.shade500, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: h*0.010),

                Row(children: [
                  Icon(Icons.access_time_rounded, color: gold, size: 12),
                  SizedBox(width: 4),
                  Text(_timeAgo(a.publishedAt), style: TextStyle(fontSize: 11,
                      color: isDark ? darkTextGrey : Colors.grey.shade400)),
                  Spacer(),
                  Text('Read more', style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w700, color: gold)),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_ios, color: gold, size: 10),
                ]),
              ]),
            ),
          ]),
        ),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => NewsDetailScreen(article: a))),
      child: Container(
        margin: EdgeInsets.only(bottom: h*0.012),
        decoration: BoxDecoration(
            color: isDark ? darkCard : lightCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? goldBorder15 : Color(0xFFEEE4B8), width: 1),
            boxShadow: [BoxShadow(
                color: isDark ? Colors.transparent : Colors.black.withAlpha(9),
                blurRadius: 6, offset: Offset(0,2))]),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
              child: _networkImage(a.imageUrl, width: w*0.28, height: w*0.22, isDark: isDark)),
          Expanded(child: Padding(padding: EdgeInsets.all(w*0.03),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(a.sourceName ?? 'News',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                        color: isDark ? gold : goldDark),
                    overflow: TextOverflow.ellipsis)),
                Spacer(),
                Text(_timeAgo(a.publishedAt), style: TextStyle(fontSize: 9,
                    color: isDark ? darkTextGrey : Colors.grey.shade400)),
              ]),
              SizedBox(height: h*0.006),
              Text(a.title ?? '', style: TextStyle(fontWeight: FontWeight.w700,
                  fontSize: 12, color: isDark ? darkTextPrimary : Colors.black87, height: 1.3),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              SizedBox(height: h*0.004),
              Text(a.description ?? '', style: TextStyle(fontSize: 10,
                  color: isDark ? darkTextGrey : Colors.grey.shade500, height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _networkImage(String? url, {required double width, required double height, required bool isDark}) {
    if (url == null || url.isEmpty || !url.startsWith('http')) return _imagePlaceholder(width, height, isDark);
    return Image.network(url, width: width, height: height, fit: BoxFit.cover,
      headers: {'User-Agent': 'Mozilla/5.0', 'Referer': 'https://newsdata.io/'},
      loadingBuilder: (_, child, p) => p == null ? child : _shimmerPlaceholder(width, height, isDark),
      errorBuilder: (_, __, ___) {
        final proxied = 'https://images.weserv.nl/?url=${Uri.encodeComponent(url)}&w=400&output=jpg';
        return Image.network(proxied, width: width, height: height, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imagePlaceholder(width, height, isDark));
      },
    );
  }

  Widget _imagePlaceholder(double w, double h, bool isDark) => Container(width: w, height: h,
      color: isDark ? darkCard : Color(0xFFFFF8E1),
      child: Center(child: Icon(Icons.article_rounded, color: goldLight, size: 28)));

  Widget _shimmerPlaceholder(double w, double h, bool isDark) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.4, end: 1.0), duration: Duration(milliseconds: 800),
    builder: (_, val, __) => Container(width: w, height: h,
        color: isDark
            ? Color.lerp(darkCard, darkBg, val)
            : Color.lerp(Color(0xFFFFF8E1), Color(0xFFFFEDC0), val)),
    onEnd: () {},
  );

  Widget _sectionTitle(String title, IconData icon, bool isDark) => Row(children: [
    Container(width: 3, height: 17,
        decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(3))),
    SizedBox(width: 9),
    Icon(icon, color: isDark ? gold : goldDark, size: 17),
    SizedBox(width: 7),
    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
        color: isDark ? gold : Colors.black87)),
  ]);

  Widget _emptyState(String msg, IconData icon, bool isDark) => Padding(
    padding: EdgeInsets.all(28),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 44, color: isDark ? darkTextGrey : Colors.grey.shade300),
      SizedBox(height: 10),
      Text(msg, style: TextStyle(fontSize: 13,
          color: isDark ? darkTextGrey : Colors.grey.shade400)),
    ])),
  );
}

class _SimpleCurrencyChart extends CustomPainter {
  final List<MarketTrend> trends;
  final int?              touchedIdx;
  final bool              isDark;
  _SimpleCurrencyChart({required this.trends, this.touchedIdx, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (trends.length < 2) return;

    final double padL = 46, padR = 8, padT = 16, padB = 8;
    final double cW = size.width  - padL - padR;
    final double cH = size.height - padT - padB;
    final int    n  = trends.length;

    final rates    = trends.map((t) => t.rate).toList();
    final logRates = rates.map((r) => log(r + 1)).toList();
    final minV     = logRates.reduce(min);
    final maxV     = logRates.reduce(max);
    final range    = (maxV - minV) == 0 ? 1.0 : maxV - minV;

    double px(int i) => padL + i * cW / (n - 1);
    double py(double v) {
      final norm = (log(v + 1) - minV) / range;
      return padT + cH - norm * cH * 0.80 - cH * 0.10;
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int g = 0; g <= 3; g++) {
      final val   = rates.reduce(min) + (rates.reduce(max) - rates.reduce(min)) * g / 3;
      final label = val >= 100 ? val.toStringAsFixed(0)
          : val >= 1   ? val.toStringAsFixed(2)
          : val.toStringAsFixed(3);
      tp.text = TextSpan(text: label,
          style: TextStyle(fontSize: 8,
              color: isDark ? Color(0xFF888888) : Colors.grey.shade400));
      tp.layout();
      final gy = padT + cH - (g / 3) * cH * 0.80 - cH * 0.10;
      tp.paint(canvas, Offset(padL - tp.width - 4, gy - tp.height / 2));
    }

    final gp = Paint()
      ..color = isDark ? Color(0x33C7A729) : Color(0xFFD4B84A).withAlpha(51)
      ..strokeWidth = 0.7;
    for (int g = 1; g <= 3; g++) {
      final gy = padT + cH * g / 3;
      double x = padL;
      while (x < padL + cW) { canvas.drawLine(Offset(x,gy), Offset(x+5,gy), gp); x += 9; }
    }

    final fill = Path()..moveTo(px(0), py(rates[0]));
    for (int i = 1; i < n; i++) {
      final cx = (px(i-1)+px(i))/2;
      fill.cubicTo(cx, py(rates[i-1]), cx, py(rates[i]), px(i), py(rates[i]));
    }
    fill.lineTo(px(n-1), padT + cH);
    fill.lineTo(padL,    padT + cH);
    fill.close();
    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: isDark
            ? [Color(0xFFC7A729).withAlpha(51), Colors.transparent]
            : [Color(0xFFC7A729).withAlpha(51), Colors.white.withAlpha(0)],
      ).createShader(Rect.fromLTWH(padL, padT, cW, cH))
      ..style = PaintingStyle.fill);

    final line = Path()..moveTo(px(0), py(rates[0]));
    for (int i = 1; i < n; i++) {
      final cx = (px(i-1)+px(i))/2;
      line.cubicTo(cx, py(rates[i-1]), cx, py(rates[i]), px(i), py(rates[i]));
    }
    canvas.drawPath(line, Paint()
      ..color       = Color(0xFFC7A729)
      ..strokeWidth = 2.2
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round);

    for (int i = 0; i < n; i++) {
      final cx     = px(i);
      final cy     = py(rates[i]);
      final active = i == touchedIdx;

      if (active) {
        final vp = Paint()..color = Color(0xFFC7A729).withAlpha(115)..strokeWidth = 1.2;
        double yy = padT;
        while (yy < padT + cH) {
          canvas.drawLine(Offset(cx,yy), Offset(cx,min(yy+5,padT+cH)), vp); yy+=9;
        }
        canvas.drawCircle(Offset(cx,cy), 10, Paint()..color = Color(0xFFC7A729).withAlpha(31));
        canvas.drawCircle(Offset(cx,cy), 7,  Paint()..color = isDark ? Color(0xFF1E1E1E) : Colors.white);
        canvas.drawCircle(Offset(cx,cy), 5,  Paint()..color = Color(0xFFC7A729));

        final t       = trends[i];
        final rateTxt = t.rate >= 100 ? t.rate.toStringAsFixed(2) : t.rate >= 1   ? t.rate.toStringAsFixed(4) : t.rate.toStringAsFixed(5);
        final up      = t.change >= 0;
        final chgTxt  = '${up?'+':''}${t.change.toStringAsFixed(3)}%';
        final pairTxt = t.pair;

        final tooltipTextColor = isDark ? Color(0xFFFFFFFF) : Color(0xFF5A4400);
        final tooltipBg = isDark ? Color(0xFF2A2A2A) : Colors.white;
        final tooltipBorder = isDark ? Color(0xFFC7A729) : Color(0xFFD4B84A).withAlpha(153);

        final tpPair = TextPainter(textDirection: TextDirection.ltr)..text = TextSpan(text: pairTxt, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tooltipTextColor))..layout();
        final tpRate = TextPainter(textDirection: TextDirection.ltr)..text = TextSpan(text: rateTxt, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: tooltipTextColor))..layout();
        final tpChg = TextPainter(textDirection: TextDirection.ltr)..text = TextSpan(text: chgTxt, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: up ? Color(0xFF2E7D32) : Color(0xFFC62828)))..layout();

        final bw = [tpPair.width, tpRate.width, tpChg.width].reduce(max) + 18;
        final bh = tpPair.height + tpRate.height + tpChg.height + 14;
        double bx = (cx - bw/2).clamp(padL, padL + cW - bw);
        double by = cy - bh - 12;
        if (by < padT) by = cy + 12;
        final rr = RRect.fromRectAndRadius(Rect.fromLTWH(bx,by,bw,bh), Radius.circular(8));
        canvas.drawRRect(rr, Paint()..color = tooltipBg);
        canvas.drawRRect(rr, Paint()..color = tooltipBorder..style = PaintingStyle.stroke..strokeWidth = 1);

        tpPair.paint(canvas, Offset(bx+(bw-tpPair.width)/2, by+5));
        tpRate.paint(canvas, Offset(bx+(bw-tpRate.width)/2, by+5+tpPair.height+2));
        tpChg.paint(canvas,  Offset(bx+(bw-tpChg.width)/2,  by+5+tpPair.height+tpRate.height+4));

      } else {
        canvas.drawCircle(Offset(cx,cy), 4.5, Paint()..color = isDark ? Color(0xFF1E1E1E) : Colors.white);
        canvas.drawCircle(Offset(cx,cy), 3,   Paint()..color = Color(0xFFC7A729));

        final t = trends[i];
        final rateTxt = t.rate >= 100 ? t.rate.toStringAsFixed(2) : t.rate >= 1   ? t.rate.toStringAsFixed(2) : t.rate.toStringAsFixed(3);
        final tpLabel = TextPainter(textDirection: TextDirection.ltr)..text = TextSpan(text: rateTxt, style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, color: isDark ? darkTextGrey : Colors.grey.shade500))..layout();

        double lx = (cx - tpLabel.width / 2).clamp(padL, padL + cW - tpLabel.width);
        double ly = cy - tpLabel.height - 6;
        if (ly < padT) ly = cy + 7;
        tpLabel.paint(canvas, Offset(lx, ly));
      }
    }
  }

  @override
  bool shouldRepaint(_SimpleCurrencyChart old) =>
      old.trends != trends || old.touchedIdx != touchedIdx || old.isDark != isDark;
}