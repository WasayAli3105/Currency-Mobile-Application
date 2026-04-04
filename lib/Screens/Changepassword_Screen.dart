import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:curren_see/Constants/Constants.dart';

class ChangepasswordScreen extends StatefulWidget {
  const ChangepasswordScreen({super.key});

  @override
  State<ChangepasswordScreen> createState() => _ChangepasswordScreenState();
}

class _ChangepasswordScreenState extends State<ChangepasswordScreen> {

  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew     = false;
  bool _showConfirm = false;
  bool _saving      = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.red,
      content: Text(
        msg,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      duration: Duration(seconds: 3),
    ));
  }

  Future<void> _changePassword() async {
    final current = _currentCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (current.isEmpty) {
      _showSnack('Please enter your current password'); return;
    }
    if (newPass.isEmpty) {
      _showSnack('Please enter a new password'); return;
    }
    if (newPass.length < 8) {
      _showSnack('New password must be at least 8 characters'); return;
    }
    if (confirm.isEmpty) {
      _showSnack('Please confirm your new password'); return;
    }
    if (newPass != confirm) {
      _showSnack('Passwords do not match'); return;
    }
    if (current == newPass) {
      _showSnack('New password must be different from current'); return;
    }

    setState(() => _saving = true);

    try {
      final user       = FirebaseAuth.instance.currentUser!;
      final credential = EmailAuthProvider.credential(
          email: user.email!, password: current);

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPass);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color(0xFF2E7D32),
            content: Text(
              'Password changed successfully!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          _showSnack('Current password is incorrect'); break;
        case 'weak-password':
          _showSnack('New password is too weak'); break;
        case 'requires-recent-login':
          _showSnack('Please log out and log in again to change password'); break;
        default:
          _showSnack('Error: ${e.message}');
      }
    } catch (_) {
      _showSnack('Something went wrong. Try again.');
    }

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width  = MediaQuery.of(context).size.width;

    //Theme values
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(children: [

        _buildHeader(height),

        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              _sectionLabel('Password Details', isDark),
              SizedBox(height: 14),

              _fieldLabel('Current Password', isDark),
              SizedBox(height: 6),
              _passField(
                controller: _currentCtrl,
                hint: 'Enter current password',
                show: _showCurrent,
                isDark: isDark,
                onToggle: () => setState(() => _showCurrent = !_showCurrent),
              ),

              SizedBox(height: 16),

              _fieldLabel('New Password', isDark),
              SizedBox(height: 6),
              _passField(
                controller: _newCtrl,
                hint: 'Enter new password (min 8 chars)',
                show: _showNew,
                isDark: isDark,
                onToggle: () => setState(() => _showNew = !_showNew),
              ),

              SizedBox(height: 16),

              _fieldLabel('Confirm New Password', isDark),
              SizedBox(height: 6),
              _passField(
                controller: _confirmCtrl,
                hint: 'Re-enter new password',
                show: _showConfirm,
                isDark: isDark,
                onToggle: () => setState(() => _showConfirm = !_showConfirm),
              ),

              SizedBox(height: 10),

              //Info box
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? gold.withAlpha(25) : Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isDark ? goldBorder30 : Color(0xFFE8D88A)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: gold, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Password must be at least 8 characters long.',
                      style: TextStyle(fontSize: 11,
                          color: isDark ? darkTextGrey : Colors.grey.shade600),
                    ),
                  ),
                ]),
              ),

              SizedBox(height: 30),

              //Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    disabledBackgroundColor: gold.withAlpha(153),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _saving
                      ? SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded,
                          color: isDark ? Colors.black : Colors.white,
                          size: 20),
                      SizedBox(width: 8),
                      Text('Update Password',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.black : Colors.white)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              //Cancel button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: gold, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Cancel',
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? goldLight : goldDark)),
                ),
              ),

              SizedBox(height: 20),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader(double height) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, height * 0.07, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [goldLight, Color(0xFFFFD700), gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(children: [
        Text('Change Password',
            style: TextStyle(color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w800)),
        SizedBox(height: 20),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(153), width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(38),
                  blurRadius: 14, offset: Offset(0, 5)),
              BoxShadow(color: gold.withAlpha(77),
                  blurRadius: 20, offset: Offset(0, 2)),
            ],
          ),
          child: Center(
            child: Icon(Icons.lock_reset_rounded, color: gold, size: 34),
          ),
        ),
        SizedBox(height: 10),
        Text('Keep your account secure',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

  //Password field with dark mode
  Widget _passField({
    required TextEditingController controller,
    required String hint,
    required bool show,
    required bool isDark,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !show,
      style: TextStyle(fontSize: 14,
          color: isDark ? darkTextPrimary : Colors.black87,
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12,
            color: isDark ? darkTextGrey : Colors.grey.shade400),
        prefixIcon: Icon(Icons.lock_outline_rounded, color: gold, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: isDark ? darkTextGrey : Colors.grey.shade400, size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: isDark ? darkCard : lightCard,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? goldBorder30 : Color(0xFFE8D88A), width: 1.2)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: isDark ? goldBorder30 : Color(0xFFE8D88A), width: 1.2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: gold, width: 1.8)),
      ),
    );
  }

  //Field label with dark mode
  Widget _fieldLabel(String label, bool isDark) => Text(label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
          color: isDark ? goldLight : Color(0xFF8A7040)));

  //Section label with dark mode
  Widget _sectionLabel(String text, bool isDark) => Row(children: [
    Container(width: 3, height: 16,
        decoration: BoxDecoration(color: gold,
            borderRadius: BorderRadius.circular(3))),
    SizedBox(width: 8),
    Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
        color: isDark ? gold : Color(0xFF5A4400))),
  ]);
}