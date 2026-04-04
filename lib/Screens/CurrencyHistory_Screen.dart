import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:curren_see/Constants/Constants.dart';

class CurrencyhistoryScreen extends StatelessWidget {
  CurrencyhistoryScreen({super.key});

  //Single Delete
  Future<void> _deleteSingle(BuildContext context, String docId) async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('conversionHistory').doc(docId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text('Record Deleted Successfully',
            style: TextStyle(fontWeight: FontWeight.bold)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  //Confirm delete dialog
  Future<bool?> _showDeleteDialog(
      BuildContext context, double w, double h, bool isDark) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? darkCard : lightCard,
        child: Padding(
          padding: EdgeInsets.all(w * 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: w * 0.15, height: w * 0.15,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.red.withAlpha(38)
                      : Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline,
                    color: Colors.red, size: 28),
              ),
              SizedBox(height: h * 0.02),
              Text('Are You Sure?',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? darkTextPrimary : lightTextPrimary)),
              SizedBox(height: h * 0.008),
              Text('Delete this conversion history record?',
                  style: TextStyle(fontSize: 15,
                      color: isDark ? darkTextGrey : lightTextGrey)),
              SizedBox(height: h * 0.025),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: h * 0.016),
                        side: BorderSide(color: gold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel',
                          style: TextStyle(
                              color: gold, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: h * 0.016),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Delete',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double h = MediaQuery.of(context).size.height;
    final double w = MediaQuery.of(context).size.width;
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    //Theme values
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users').doc(uid)
            .collection('conversionHistory')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: gold));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong!',
                  style: TextStyle(color: Colors.red, fontSize: w * 0.04)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, color: gold, size: w * 0.18),
                  SizedBox(height: h * 0.02),
                  Text('No conversion history yet!',
                      style: TextStyle(
                        color: isDark ? darkTextGrey : lightTextGrey,
                        fontSize: w * 0.045,
                        fontWeight: FontWeight.w500,
                      )),
                  SizedBox(height: h * 0.008),
                  Text('Your past conversions will appear here.',
                      style: TextStyle(
                        color: isDark ? darkTextGrey : Colors.grey,
                        fontSize: w * 0.032,
                      )),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.04, vertical: h * 0.02),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc  = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String fromCurrency = data['fromCurrency'] ?? '-';
              final String toCurrency   = data['toCurrency'] ?? '-';
              final double amount       = (data['amount'] ?? 0).toDouble();
              final double result       = (data['result'] ?? 0).toDouble();
              final double rate         = (data['rate'] ?? 0).toDouble();
              final Timestamp? ts       = data['timestamp'];
              final String dateTime     = ts != null
                  ? DateFormat('dd MMM yyyy  •  hh:mm a').format(ts.toDate())
                  : '-';

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
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
                      SizedBox(height: 4),
                      Text('Delete',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: w * 0.03,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                confirmDismiss: (_) =>
                    _showDeleteDialog(context, w, h, isDark),
                onDismissed: (_) => _deleteSingle(context, doc.id),

                //Card with dark mode
                child: Container(
                  margin: EdgeInsets.only(bottom: h * 0.015),
                  decoration: BoxDecoration(
                    color: isDark ? darkCard : lightCard,
                    borderRadius: BorderRadius.circular(w * 0.04),
                    border: Border.all(
                        color: isDark ? goldBorder15 : gold.withAlpha(102),
                        width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? goldShadow40.withAlpha(15)
                            : gold.withAlpha(20),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(w * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        //Row 1
                        Row(
                          children: [
                            _currencyBadge(fromCurrency, w),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: w * 0.02),
                              child: Icon(Icons.arrow_forward,
                                  color: gold, size: w * 0.05),
                            ),
                            _currencyBadge(toCurrency, w),
                            Spacer(),
                            GestureDetector(
                              onTap: () async {
                                final confirm = await _showDeleteDialog(
                                    context, w, h, isDark);
                                if (confirm == true) {
                                  _deleteSingle(context, doc.id);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(w * 0.02),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.red.withAlpha(38)
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.delete_outline,
                                    color: Colors.red, size: w * 0.05),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: h * 0.012),
                        Divider(
                            color: isDark ? darkDivider : gold.withAlpha(51),
                            height: 1),
                        SizedBox(height: h * 0.012),

                        //Row 2
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _infoColumn('Amount',
                                '$amount $fromCurrency', w, isDark),
                            Icon(Icons.compare_arrows,
                                color: isDark
                                    ? goldBorder30
                                    : gold.withAlpha(128),
                                size: w * 0.05),
                            _infoColumn('Result',
                                '${result.toStringAsFixed(4)} $toCurrency',
                                w, isDark),
                          ],
                        ),

                        SizedBox(height: h * 0.01),

                        //Row 3: Rate
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              horizontal: w * 0.03, vertical: h * 0.007),
                          decoration: BoxDecoration(
                            color: isDark ? darkBg : lightBg,
                            borderRadius: BorderRadius.circular(w * 0.02),
                          ),
                          child: Text(
                            '1 $fromCurrency  =  ${rate.toStringAsFixed(4)} $toCurrency',
                            style: TextStyle(
                              color: isDark ? darkTextGrey : lightTextGrey,
                              fontSize: w * 0.03,
                            ),
                          ),
                        ),

                        SizedBox(height: h * 0.01),

                        // Row 4: Date
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                color: isDark ? darkTextGrey : Colors.grey,
                                size: w * 0.035),
                            SizedBox(width: w * 0.015),
                            Text(dateTime,
                                style: TextStyle(
                                  color: isDark ? darkTextGrey : Colors.grey,
                                  fontSize: w * 0.028,
                                )),
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

  Widget _currencyBadge(String currency, double w) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: w * 0.03, vertical: w * 0.012),
      decoration: BoxDecoration(
        color: gold,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        currency,
        style: TextStyle(
          color: Colors.white,
          fontSize: w * 0.035,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  //Info column with dark mode
  Widget _infoColumn(String label, String value, double w, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: isDark ? darkTextGrey : Colors.grey,
                fontSize: w * 0.028,
                fontWeight: FontWeight.w500)),
        SizedBox(height: w * 0.01),
        Text(value,
            style: TextStyle(
                color: isDark ? darkTextPrimary : lightTextPrimary,
                fontSize: w * 0.035,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}