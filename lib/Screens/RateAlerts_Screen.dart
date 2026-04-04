import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:curren_see/Constants/Constants.dart';

//Pre calculated opacity colors
const Color _goldOp07     = Color(0x12C7A729);
const Color _goldOp15     = Color(0x26C7A729);
const Color _goldOp30     = Color(0x4DC7A729);
const Color _goldOp40     = Color(0x66C7A729);
const Color _greenOp50    = Color(0x804CAF50);
const Color _greyOp30     = Color(0x4D9E9E9E);
const Color _redOp30      = Color(0x4DE53935);
const Color _redOp50Dark  = Color(0x80E53935);

class RateAlertsScreen extends StatefulWidget {
  RateAlertsScreen({super.key});

  @override
  State<RateAlertsScreen> createState() => _RateAlertsScreenState();
}

class _RateAlertsScreenState extends State<RateAlertsScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  List<Map<String, String>> _allCurrencies = [];
  bool _currenciesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final res = await http.get(Uri.parse(
          'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies.json'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final sorted = data.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        setState(() {
          _allCurrencies = sorted
              .map((e) => {
            'code': e.key.toUpperCase(),
            'name': e.value.toString(),
          })
              .where((c) => !RegExp(r'^[0-9]').hasMatch(c['code']!))
              .toList();
          _currenciesLoaded = true;
        });
      }
    } catch (_) {}
  }


  //Currency Picker
  Future<Map<String, String>?> _showCurrencyPicker({
    required String title,
    required String selectedCode,
  }) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController searchCtrl = TextEditingController();
    List<Map<String, String>> filtered = List.from(_allCurrencies);

    // ── Colors ──
    final Color sheetBg      = isDark ? darkCard : lightCard;
    final Color handleColor  = isDark ? darkDivider : lightDivider;
    final Color titleColor   = isDark ? darkTextPrimary : lightTextPrimary;
    final Color searchFill   = isDark ? darkInputFill : lightInputFill;
    final Color searchBorder = isDark ? darkInputBorder : lightInputBorder;
    final Color hintColor    = isDark ? darkTextGrey : lightTextGrey;
    final Color countColor   = isDark ? darkTextGrey : lightTextGrey;
    final Color divColor     = isDark ? darkDivider : Color(0xFFEEE4B8);
    final Color flagBoxBg    = isDark ? darkBg : lightBg;
    final Color codeColor    = isDark ? darkTextPrimary : lightTextPrimary;
    final Color nameColor    = isDark ? darkTextGrey : lightTextGrey;
    final Color selectedBg   = isDark ? goldBorder15 : Color(0xFFFFF8E1);
    final Color clearIcon    = isDark ? darkTextGrey : lightTextGrey;

    return await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final h = MediaQuery.of(ctx).size.height;
        final w = MediaQuery.of(ctx).size.width;
        return StatefulBuilder(
          builder: (ctx, setPickerState) {
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
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: handleColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(height: h * 0.02),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: w * 0.05,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  SizedBox(height: h * 0.015),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                    child: TextField(
                      controller: searchCtrl,
                      cursorOpacityAnimates: true,
                      cursorColor: gold,
                      autofocus: true,
                      style: TextStyle(color: titleColor),
                      decoration: InputDecoration(
                        hintText: 'Search currency...',
                        hintStyle: TextStyle(color: hintColor),
                        prefixIcon: Icon(Icons.search, color: gold),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, color: clearIcon),
                          onPressed: () {
                            searchCtrl.clear();
                            setPickerState(() =>
                            filtered = List.from(_allCurrencies));
                          },
                        )
                            : null,
                        filled: true,
                        fillColor: searchFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          BorderSide(color: searchBorder, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        final q = val.toLowerCase().trim();
                        setPickerState(() {
                          filtered = q.isEmpty
                              ? List.from(_allCurrencies)
                              : _allCurrencies
                              .where((c) =>
                          c['code']!
                              .toLowerCase()
                              .contains(q) ||
                              c['name']!
                                  .toLowerCase()
                                  .contains(q))
                              .toList();
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: w * 0.05, vertical: h * 0.008),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${filtered.length} currencies',
                        style:
                        TextStyle(fontSize: w * 0.03, color: countColor),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: divColor),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                      child: Text(
                        'No currency found',
                        style: TextStyle(color: hintColor),
                      ),
                    )
                        : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final isSel = c['code'] == selectedCode;
                        return ListTile(
                          tileColor: isSel ? selectedBg : null,
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: flagBoxBg,
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                _getFlagEmoji(c['code']!),
                                style: TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                          title: Text(
                            c['code']!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: w * 0.038,
                              color: isSel ? gold : codeColor,
                            ),
                          ),
                          subtitle: Text(
                            c['name']!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: w * 0.03,
                              color: nameColor,
                            ),
                          ),
                          trailing: isSel
                              ? Icon(Icons.check_circle,
                              color: gold, size: 22)
                              : null,
                          onTap: () => Navigator.pop(ctx, c),
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

  String _getFlagEmoji(String code) {
    final special = {
      'EUR': '🇪🇺', 'XAF': '🌍', 'XOF': '🌍',
      'XCD': '🌎', 'XPF': '🌏', 'XDR': '🌐',
      'BTC': '₿', 'ETH': '⟠', 'USDT': '💵',
      'XAU': '🥇', 'XAG': '🥈',
    };
    if (special.containsKey(code)) return special[code]!;
    try {
      return code
          .substring(0, 2)
          .codeUnits
          .map((c) => String.fromCharCode(c + 127397))
          .join();
    } catch (_) {
      return '🏳️';
    }
  }

  //Add/Edit Alert Sheet
  void _showAlertSheet({
    double? h,
    double? w,
    String? docId,
    String? initFrom,
    String? initFromName,
    String? initTo,
    String? initToName,
    double? initTarget,
    String? initCondition,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final buildH = h ?? MediaQuery.of(context).size.height;
    final buildW = w ?? MediaQuery.of(context).size.width;

    //Sheet colors
    final Color sheetBg     = isDark ? darkCard : lightCard;
    final Color handleColor = isDark ? darkDivider : lightDivider;
    final Color titleColor  = isDark ? darkTextPrimary : lightTextPrimary;
    final Color hintColor   = isDark ? darkTextGrey : lightTextGrey;
    final Color inputFill   = isDark ? darkInputFill : lightInputFill;
    final Color inputBorder = isDark ? darkInputBorder : lightInputBorder;
    final Color textColor   = isDark ? darkTextPrimary : lightTextPrimary;
    final Color iconBoxBg   = isDark ? goldBorder15 : Color(0xFFFFF8E1);
    final Color iconBoxBrd  = isDark ? goldBorder30 : goldBorder30;
    final Color swapBg      = isDark ? goldBorder15 : Color(0xFFFFF8E1);
    final Color inactiveBg  = isDark ? darkInputFill : lightBg;
    final Color inactiveBrd = isDark ? darkDivider : lightDivider;
    final Color inactiveText = isDark ? darkTextGrey : lightTextGrey;
    final Color inactiveIcon = isDark ? darkTextGrey : lightTextGrey;

    String fromCode = initFrom ?? 'USD';
    String fromName = initFromName ?? 'US Dollar';
    String toCode = initTo ?? 'PKR';
    String toName = initToName ?? 'Pakistani Rupee';
    final TextEditingController targetCtrl =
    TextEditingController(text: initTarget?.toString() ?? '');
    String condition = initCondition ?? 'above';
    double? liveRate;
    bool fetchingRate = false;
    bool isSaving = false;

    final bool isEdit = docId != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> fetchLiveRate() async {
              final from = fromCode.toLowerCase();
              final to = toCode.toLowerCase();
              setModalState(() => fetchingRate = true);
              try {
                final res = await http.get(Uri.parse(
                    'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/$from.json'));
                if (res.statusCode == 200) {
                  final data = json.decode(res.body);
                  final rate = (data[from][to] as num).toDouble();
                  setModalState(() {
                    liveRate = rate;
                    fetchingRate = false;
                  });
                }
              } catch (_) {
                setModalState(() => fetchingRate = false);
              }
            }

            Future<void> saveAlert() async {
              if (targetCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(
                      'Please Enter The Target Exchange Rate',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
                return;
              }
              setModalState(() => isSaving = true);
              final Map<String, dynamic> payload = {
                'fromCurrency': fromCode,
                'toCurrency': toCode,
                'targetRate': double.parse(targetCtrl.text.trim()),
                'condition': condition,
                'isActive': true,
              };

              if (isEdit) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('rateAlerts')
                    .doc(docId)
                    .update(payload);
              } else {
                payload['createdAt'] = FieldValue.serverTimestamp();
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('rateAlerts')
                    .add(payload);
              }

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Color(0xFF2E7D32),
                  content: Text(
                    isEdit
                        ? 'Rate Alert Updated Successfully.'
                        : 'Rate Alert Added Successfully.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }

            return Container(
              height: buildH * 0.9,
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(buildW * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: handleColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: buildH * 0.02),

                    //Title
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(buildW * 0.025),
                          decoration: BoxDecoration(
                            color: iconBoxBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: iconBoxBrd),
                          ),
                          child: Icon(
                            isEdit
                                ? Icons.edit_notifications_outlined
                                : Icons.notifications_active_outlined,
                            color: gold,
                            size: 22,
                          ),
                        ),
                        SizedBox(width: buildW * 0.03),
                        Text(
                          isEdit ? 'Edit Alert' : 'Set Rate Alert',
                          style: TextStyle(
                            fontSize: buildW * 0.055,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: buildH * 0.03),

                    //From Currency
                    Text(
                      'From Currency',
                      style: TextStyle(
                        color: gold,
                        fontSize: buildW * 0.032,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: buildH * 0.008),
                    GestureDetector(
                      onTap: () async {
                        final result = await _showCurrencyPicker(
                          title: 'Select From Currency',
                          selectedCode: fromCode,
                        );
                        if (result != null) {
                          setModalState(() {
                            fromCode = result['code']!;
                            fromName = result['name']!;
                            liveRate = null;
                          });
                        }
                      },
                      child: _currencyBox(
                          fromCode, fromName, buildW, buildH, isDark),
                    ),

                    SizedBox(height: buildH * 0.015),

                    //Swap Button
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setModalState(() {
                            final tc = fromCode;
                            final tn = fromName;
                            fromCode = toCode;
                            fromName = toName;
                            toCode = tc;
                            toName = tn;
                            liveRate = null;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(buildW * 0.025),
                          decoration: BoxDecoration(
                            color: swapBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: gold),
                          ),
                          child: Icon(Icons.swap_vert,
                              color: gold, size: 22),
                        ),
                      ),
                    ),

                    SizedBox(height: buildH * 0.015),

                    //To Currency
                    Text(
                      'To Currency',
                      style: TextStyle(
                        color: gold,
                        fontSize: buildW * 0.032,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: buildH * 0.008),
                    GestureDetector(
                      onTap: () async {
                        final result = await _showCurrencyPicker(
                          title: 'Select To Currency',
                          selectedCode: toCode,
                        );
                        if (result != null) {
                          setModalState(() {
                            toCode = result['code']!;
                            toName = result['name']!;
                            liveRate = null;
                          });
                        }
                      },
                      child: _currencyBox(
                          toCode, toName, buildW, buildH, isDark),
                    ),

                    SizedBox(height: buildH * 0.02),

                    //Fetch Live Rate
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: fetchLiveRate,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: buildH * 0.015),
                          side: BorderSide(color: gold),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: fetchingRate
                            ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: gold, strokeWidth: 2),
                        )
                            : Icon(Icons.refresh_rounded, color: gold),
                        label: Text(
                          fetchingRate
                              ? 'Fetching...'
                              : liveRate != null
                              ? '📊 Live: $liveRate'
                              : 'Fetch Live Rate',
                          style: TextStyle(
                              color: gold, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    SizedBox(height: buildH * 0.02),

                    //Target Rate
                    Text(
                      'Target Rate',
                      style: TextStyle(
                        color: gold,
                        fontSize: buildW * 0.032,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: buildH * 0.008),
                    TextField(
                      controller: targetCtrl,
                      cursorOpacityAnimates: true,
                      keyboardType: TextInputType.numberWithOptions(
                          decimal: true),
                      cursorColor: gold,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: buildW * 0.04,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: liveRate != null
                            ? 'Live: $liveRate'
                            : 'e.g. 285.00',
                        hintStyle: TextStyle(color: hintColor),
                        prefixIcon:
                        Icon(Icons.flag_outlined, color: gold),
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

                    SizedBox(height: buildH * 0.02),

                    //Condition Toggle
                    Text(
                      'Alert Condition',
                      style: TextStyle(
                        color: gold,
                        fontSize: buildW * 0.032,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: buildH * 0.01),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(
                                    () => condition = 'above'),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                  vertical: buildH * 0.015),
                              decoration: BoxDecoration(
                                color: condition == 'above'
                                    ? Color(0xFF2E7D32)
                                    : inactiveBg,
                                borderRadius:
                                BorderRadius.circular(12),
                                border: Border.all(
                                  color: condition == 'above'
                                      ? Color(0xFF2E7D32)
                                      : inactiveBrd,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    color: condition == 'above'
                                        ? Colors.white
                                        : inactiveIcon,
                                    size: 22,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Above',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: condition == 'above'
                                          ? Colors.white
                                          : inactiveText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: buildW * 0.03),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(
                                    () => condition = 'below'),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                  vertical: buildH * 0.015),
                              decoration: BoxDecoration(
                                color: condition == 'below'
                                    ? Color(0xFFC62828)
                                    : inactiveBg,
                                borderRadius:
                                BorderRadius.circular(12),
                                border: Border.all(
                                  color: condition == 'below'
                                      ? Color(0xFFC62828)
                                      : inactiveBrd,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    color: condition == 'below'
                                        ? Colors.white
                                        : inactiveIcon,
                                    size: 22,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Below',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: condition == 'below'
                                          ? Colors.white
                                          : inactiveText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: buildH * 0.03),

                    //Save Button
                    SizedBox(
                      width: double.infinity,
                      height: buildH * 0.065,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [goldLight, gold, goldDark],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: goldShadow40,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: isSaving ? null : saveAlert,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(14)),
                          ),
                          icon: isSaving
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2),
                          )
                              : Icon(
                            isEdit
                                ? Icons.save_outlined
                                : Icons.notifications_active,
                            color: Colors.white,
                          ),
                          label: Text(
                            isSaving
                                ? 'Saving...'
                                : isEdit
                                ? 'Update Alert'
                                : 'Set Alert',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: buildH * 0.02),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  //Currency Box Widget
  Widget _currencyBox(
      String code, String name, double w, double h, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: w * 0.04, vertical: h * 0.018),
      decoration: BoxDecoration(
        color: isDark ? darkInputFill : lightInputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? darkInputBorder : gold),
      ),
      child: Row(
        children: [
          Text(_getFlagEmoji(code), style: TextStyle(fontSize: 24)),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: w * 0.04,
                    color: isDark ? darkTextPrimary : lightTextPrimary,
                  ),
                ),
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: w * 0.028,
                      color: isDark ? darkTextGrey : lightTextGrey),
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: gold),
        ],
      ),
    );
  }


  //Delete Confirmation Dialog
  Future<void> _confirmDelete(
      String docId, String from, String to) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final Color dialogBg    = isDark ? darkCard : lightCard;
    final Color titleColor  = isDark ? darkTextPrimary : lightTextPrimary;
    final Color subtextColor = isDark ? darkTextGrey : lightTextGrey;
    final Color redCircleBg = isDark ? const Color(0x33E53935) : Colors.red.shade50;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        backgroundColor: dialogBg,
        child: Padding(
          padding: EdgeInsets.all(w * 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: w * 0.16,
                height: w * 0.16,
                decoration: BoxDecoration(
                  color: redCircleBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline_rounded,
                    color: Colors.red, size: 32),
              ),
              SizedBox(height: h * 0.02),
              Text(
                'Are you sure?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              SizedBox(height: h * 0.008),
              Text(
                'This rate alert will be permanently deleted and cannot be recovered.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: subtextColor,
                ),
              ),
              SizedBox(height: h * 0.025),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: h * 0.015),
                        side: BorderSide(color: gold),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: h * 0.015),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('rateAlerts')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Rate Alert Deleted Successfully.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleAlert(String docId, bool current) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('rateAlerts')
        .doc(docId)
        .update({'isActive': !current});
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;

    final Color scaffoldBg   = isDark ? darkBg : lightBg;
    final Color titleColor   = isDark ? darkTextPrimary : lightTextPrimary;
    final Color emptyText    = isDark ? darkTextGrey : lightTextGrey;
    final Color cardBg       = isDark ? darkCard : lightCard;
    final Color cardShadow   = isDark ? darkShadow : _goldOp07;

    final Color greenBg  = isDark ? const Color(0x332E7D32) : Color(0xFFE8F5E9);
    final Color redBg    = isDark ? const Color(0x33C62828) : Color(0xFFFFEBEE);

    final Color triggeredBrd = isDark ? _greenOp50 : _greenOp50;
    final Color activeBrd    = isDark ? _goldOp40 : _goldOp40;
    final Color inactiveBrd  = isDark ? _greyOp30 : _greyOp30;

    final Color editBtnBg    = isDark ? goldBorder15 : Color(0xFFFFF8E1);
    final Color editBtnBrd   = isDark ? goldBorder30 : _goldOp40;
    final Color deleteBtnBg  = isDark ? const Color(0x1AE53935) : Colors.red.shade50;
    final Color deleteBtnBrd = isDark ? _redOp30 : _redOp30;

    final Color cardDivider = isDark ? goldBorder15 : _goldOp15;

    return Scaffold(
      backgroundColor: scaffoldBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _currenciesLoaded
            ? () => _showAlertSheet(h: h, w: w)
            : null,
        backgroundColor: gold,
        icon: _currenciesLoaded
            ? Icon(Icons.add, color: Colors.white)
            : SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        ),
        label: Text(
          _currenciesLoaded ? 'Add Alert' : 'Loading...',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('rateAlerts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: gold));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      color: gold, size: w * 0.18),
                  SizedBox(height: h * 0.02),
                  Text(
                    'No Rate Alerts Set Yet!',
                    style: TextStyle(
                      color: emptyText,
                      fontSize: w * 0.045,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: h * 0.008),
                  Text(
                    '+ Tap \'Add Alert\' To Create One.',
                    style: TextStyle(
                        color: isDark ? darkTextGrey : lightTextGrey,
                        fontSize: w * 0.032),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
                w * 0.04, h * 0.02, w * 0.04, h * 0.1),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              String from = data['fromCurrency'] ?? '-';
              String to = data['toCurrency'] ?? '-';
              double target = (data['targetRate'] ?? 0).toDouble();
              String condition = data['condition'] ?? 'above';
              bool isActive = data['isActive'] ?? true;
              bool triggered = !(data['isActive'] ?? true) &&
                  data.containsKey('triggeredAt');
              bool isAbove = condition == 'above';

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  await _confirmDelete(doc.id, from, to);
                  return false;
                },
                background: Container(
                  margin: EdgeInsets.only(bottom: h * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(w * 0.04),
                  ),
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: w * 0.05),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_rounded,
                          color: Colors.white, size: 28),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.03,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                child: Container(
                  margin: EdgeInsets.only(bottom: h * 0.015),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(w * 0.04),
                    border: Border.all(
                      color: triggered
                          ? triggeredBrd
                          : isActive
                          ? activeBrd
                          : inactiveBrd,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cardShadow,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(w * 0.04),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            //Condition Icon
                            Container(
                              width: w * 0.12,
                              height: w * 0.12,
                              decoration: BoxDecoration(
                                color: isAbove ? greenBg : redBg,
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isAbove
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                color: isAbove
                                    ? Color(0xFF2E7D32)
                                    : Color(0xFFC62828),
                                size: w * 0.06,
                              ),
                            ),
                            SizedBox(width: w * 0.03),

                            //Currency Pair
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(_getFlagEmoji(from),
                                          style: TextStyle(
                                              fontSize: 18)),
                                      SizedBox(width: w * 0.015),
                                      Text(
                                        from,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: w * 0.042,
                                          color: titleColor,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: w * 0.02),
                                        child: Icon(
                                            Icons.arrow_forward,
                                            color: gold,
                                            size: w * 0.04),
                                      ),
                                      Text(_getFlagEmoji(to),
                                          style: TextStyle(
                                              fontSize: 18)),
                                      SizedBox(width: w * 0.015),
                                      Text(
                                        to,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: w * 0.042,
                                          color: titleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: h * 0.005),
                                  Row(
                                    children: [
                                      Container(
                                        padding:
                                        EdgeInsets.symmetric(
                                          horizontal: w * 0.02,
                                          vertical: h * 0.003,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isAbove
                                              ? greenBg
                                              : redBg,
                                          borderRadius:
                                          BorderRadius.circular(
                                              20),
                                        ),
                                        child: Text(
                                          isAbove
                                              ? '↑ Above $target'
                                              : '↓ Below $target',
                                          style: TextStyle(
                                            fontSize: w * 0.028,
                                            fontWeight:
                                            FontWeight.bold,
                                            color: isAbove
                                                ? Color(0xFF2E7D32)
                                                : Color(0xFFC62828),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: w * 0.02),
                                      if (triggered)
                                        Container(
                                          padding:
                                          EdgeInsets.symmetric(
                                            horizontal: w * 0.02,
                                            vertical: h * 0.003,
                                          ),
                                          decoration: BoxDecoration(
                                            color: greenBg,
                                            borderRadius:
                                            BorderRadius.circular(
                                                20),
                                          ),
                                          child: Text(
                                            'Triggered',
                                            style: TextStyle(
                                              fontSize: w * 0.025,
                                              fontWeight:
                                              FontWeight.bold,
                                              color: Colors
                                                  .green.shade700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            //Toggle
                            Column(
                              children: [
                                Switch(
                                  value: isActive,
                                  onChanged: (_) => _toggleAlert(
                                      doc.id, isActive),
                                  activeColor: gold,
                                  inactiveThumbColor:
                                  isDark
                                      ? darkTextGrey
                                      : lightTextGrey,
                                ),
                                Text(
                                  isActive ? 'Active' : 'Off',
                                  style: TextStyle(
                                    fontSize: w * 0.025,
                                    color: isActive
                                        ? gold
                                        : (isDark
                                        ? darkTextGrey
                                        : lightTextGrey),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: h * 0.012),
                        Divider(color: cardDivider, height: 1),
                        SizedBox(height: h * 0.01),

                        //Edit  Delete
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  _showAlertSheet(
                                    h: h,
                                    w: w,
                                    docId: doc.id,
                                    initFrom: from,
                                    initTo: to,
                                    initTarget: target,
                                    initCondition: condition,
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: h * 0.012),
                                  decoration: BoxDecoration(
                                    color: editBtnBg,
                                    borderRadius:
                                    BorderRadius.circular(10),
                                    border: Border.all(
                                        color: editBtnBrd),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.edit_outlined,
                                          color: gold,
                                          size: w * 0.04),
                                      SizedBox(width: w * 0.015),
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: gold,
                                          fontSize: w * 0.032,
                                          fontWeight:
                                          FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: w * 0.03),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _confirmDelete(
                                    doc.id, from, to),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: h * 0.012),
                                  decoration: BoxDecoration(
                                    color: deleteBtnBg,
                                    borderRadius:
                                    BorderRadius.circular(10),
                                    border: Border.all(
                                        color: deleteBtnBrd),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.delete_outline,
                                          color: Colors.red,
                                          size: w * 0.04),
                                      SizedBox(width: w * 0.015),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: w * 0.032,
                                          fontWeight:
                                          FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}