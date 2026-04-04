import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:curren_see/Constants/Constants.dart';

class FeedbackScreen extends StatefulWidget {
  FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() => setState(() {}));
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() => _userName = doc.data()?['name'] ?? '');
    }
  }

  @override
  void dispose() { _messageController.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please Select a Rating Before Submitting.'),
          backgroundColor: Color(0xFFE53935)));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'uid': user?.uid ?? '',
        'name': _userName.isNotEmpty ? _userName : (user?.email ?? 'Anonymous'),
        'rating': _rating,
        'message': _messageController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() { _rating = 0; _messageController.clear(); });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Feedback submitted successfully!'),
          backgroundColor: Color(0xFF2E7D32)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Color(0xFFE53935)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cancel() { setState(() { _rating = 0; _messageController.clear(); }); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildRatingSection(isDark),
              SizedBox(height: 28),
              _buildMessageSection(isDark),
              SizedBox(height: 32),
              _buildSubmitButton(isDark),
              SizedBox(height: 12),
              _buildCancelButton(isDark),
            ]),
          ),
        ),
      ]),
    );
  }

  // Header
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24, bottom: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [goldLight, gold, goldDark],
        ),
      ),
      child: Column(children: [
        Text('Feedback', style: TextStyle(color: Colors.white, fontSize: 20,
            fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        SizedBox(height: 18),
        Container(
          width: 62, height: 62,
          decoration: BoxDecoration(
            color: Colors.white, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Icon(Icons.rate_review_rounded, color: gold, size: 28),
        ),
        SizedBox(height: 12),
        Text('Share your experience',
            style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.3)),
      ]),
    );
  }

  // Rating Section
  Widget _buildRatingSection(bool isDark) {
    final labels = ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Rate Your Experience', isDark),
      SizedBox(height: 18),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final star = i + 1;
          final active = star <= _rating;
          return GestureDetector(
            onTap: () => setState(() => _rating = star),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: Icon(
                  active ? Icons.star_rounded : Icons.star_outline_rounded,
                  key: ValueKey('$star$active'),
                  size: 42,
                  color: active ? gold : (isDark ? darkTextGrey : Colors.grey.shade400),
                  shadows: active
                      ? [Shadow(color: gold.withAlpha(115), blurRadius: 10)]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
      SizedBox(height: 10),
      Center(
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 200),
          child: Text(
            _rating == 0 ? 'Tap to rate' : labels[_rating],
            key: ValueKey(_rating),
            style: TextStyle(
              color: _rating == 0
                  ? (isDark ? darkTextGrey : Colors.grey.shade500)
                  : gold,
              fontSize: 13,
              fontStyle: _rating == 0 ? FontStyle.normal : FontStyle.italic,
              fontWeight: _rating == 0 ? FontWeight.normal : FontWeight.w600,
            ),
          ),
        ),
      ),
    ]);
  }

  // Message Section
  Widget _buildMessageSection(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Your Message', isDark),
      SizedBox(height: 14),
      Container(
        decoration: BoxDecoration(
          color: isDark ? darkCard : lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? goldBorder30 : Colors.grey.shade200),
          boxShadow: [BoxShadow(
              color: isDark ? Colors.transparent : Colors.black.withAlpha(10),
              blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(children: [
          TextField(
            controller: _messageController,
            maxLines: 6, maxLength: 500, cursorColor: gold,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? darkTextPrimary : lightTextPrimary,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: 'Tell us what you think, what went wrong, or what you would love to see...',
              hintStyle: TextStyle(
                  color: isDark ? darkTextGrey : Colors.grey.shade400,
                  fontSize: 13, height: 1.6),
              border: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              counterText: '',
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_messageController.text.length}/500',
                style: TextStyle(fontSize: 12,
                    color: isDark ? darkTextGrey : lightTextGrey),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  // Submit Button
  Widget _buildSubmitButton(bool isDark) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submit,
        icon: _isLoading
            ? SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(Icons.send_rounded, size: 18),
        label: Text(_isLoading ? 'Submitting...' : 'Submit Feedback',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: isDark ? Colors.black : Colors.white,
          disabledBackgroundColor: gold.withAlpha(153),
          elevation: 3,
          shadowColor: goldShadow40,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // Cancel Button
  Widget _buildCancelButton(bool isDark) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _cancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side: BorderSide(color: isDark ? goldBorder30 : gold.withAlpha(166), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text('Cancel',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                color: isDark ? goldLight : gold)),
      ),
    );
  }

  // Section Title
  Widget _sectionTitle(String text, bool isDark) {
    return Row(children: [
      Container(width: 4, height: 18,
          decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(2))),
      SizedBox(width: 10),
      Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
          color: isDark ? gold : lightTextPrimary, letterSpacing: 0.2)),
    ]);
  }
}