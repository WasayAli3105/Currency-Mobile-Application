import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curren_see/Constants/Constants.dart';

class AllfeedbacksScreen extends StatelessWidget {
  const AllfeedbacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(children: [
        _buildHeader(context, isDark, w, h),
        Expanded(child: _buildList(context, isDark, w, h)),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, double w, double h) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + h * 0.03, bottom: h * 0.035),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [goldLight, gold, goldDark],
        ),
      ),
      child: Column(children: [
        Text('User Reviews',
            style: TextStyle(
                color: Colors.white,
                fontSize: w * 0.05,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
        SizedBox(height: h * 0.022),
        Container(
          width: w * 0.155, height: w * 0.155,
          decoration: BoxDecoration(
            color: Colors.white, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Icon(Icons.reviews_rounded, color: gold, size: w * 0.07),
        ),
        SizedBox(height: h * 0.015),
        Text('See what others are saying',
            style: TextStyle(color: Colors.white70, fontSize: w * 0.033, letterSpacing: 0.3)),
      ]),
    );
  }

  Widget _buildList(BuildContext context, bool isDark, double w, double h) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedbacks')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: gold));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) return _buildEmpty(isDark, w, h);

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.02, w * 0.04, h * 0.03),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildCard(data, isDark, w, h);
          },
        );
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> data, bool isDark, double w, double h) {
    final int rating = data['rating'] ?? 0;
    final String name = data['name'] ?? '';
    final String message = data['message'] ?? '';
    final Timestamp? ts = data['createdAt'];
    final String date = ts != null ? _formatDate(ts.toDate()) : 'Just now';
    final labels = ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent'];

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.015),
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: isDark ? darkCard : lightCard,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: isDark ? goldBorder30 : Colors.grey.shade200),
        boxShadow: [BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withAlpha(10),
            blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top row: avatar + name + date
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Row(children: [
              CircleAvatar(
                radius: w * 0.04,
                backgroundColor: gold.withAlpha(30),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                      fontSize: w * 0.033,
                      fontWeight: FontWeight.bold,
                      color: gold),
                ),
              ),
              SizedBox(width: w * 0.025),
              Expanded(
                child: Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: w * 0.033,
                        fontWeight: FontWeight.w500,
                        color: isDark ? darkTextPrimary : lightTextPrimary)),
              ),
            ]),
          ),
          SizedBox(width: w * 0.02),
          Text(date,
              style: TextStyle(
                  fontSize: w * 0.028,
                  color: isDark ? darkTextGrey : lightTextGrey)),
        ]),

        SizedBox(height: h * 0.012),

        // Rating label
        _sectionLabel('Rate Experience', isDark, w),
        SizedBox(height: h * 0.008),

        // Stars + label
        Row(children: [
          ...List.generate(5, (i) => Icon(
            i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: w * 0.045,
            color: i < rating ? gold : (isDark ? darkTextGrey : Colors.grey.shade300),
          )),
          SizedBox(width: w * 0.02),
          if (rating > 0)
            Text(labels[rating],
                style: TextStyle(
                    fontSize: w * 0.03,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: gold)),
        ]),

        // Message
        if (message.isNotEmpty) ...[
          SizedBox(height: h * 0.014),
          _sectionLabel('Message', isDark, w),
          SizedBox(height: h * 0.008),
          Text(message,
              style: TextStyle(
                  fontSize: w * 0.033,
                  height: 1.55,
                  color: isDark ? darkTextPrimary : lightTextPrimary)),
        ],
      ]),
    );
  }

  Widget _buildEmpty(bool isDark, double w, double h) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.reviews_outlined,
            size: w * 0.15, color: isDark ? darkTextGrey : Colors.grey.shade300),
        SizedBox(height: h * 0.018),
        Text('No reviews yet',
            style: TextStyle(
                fontSize: w * 0.038,
                fontWeight: FontWeight.w500,
                color: isDark ? darkTextGrey : Colors.grey.shade500)),
        SizedBox(height: h * 0.008),
        Text('Be the first to share your experience!',
            style: TextStyle(
                fontSize: w * 0.03,
                color: isDark ? darkTextGrey : Colors.grey.shade400)),
      ]),
    );
  }

  Widget _sectionLabel(String text, bool isDark, double w) {
    return Row(children: [
      Container(
        width: 3, height: w * 0.04,
        decoration: BoxDecoration(
            color: gold, borderRadius: BorderRadius.circular(2)),
      ),
      SizedBox(width: w * 0.02),
      Text(text,
          style: TextStyle(
              fontSize: w * 0.03,
              fontWeight: FontWeight.w600,
              color: isDark ? gold : Colors.grey.shade600,
              letterSpacing: 0.2)),
    ]);
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}