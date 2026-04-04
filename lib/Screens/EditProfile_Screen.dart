import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:curren_see/Constants/Constants.dart';

class EditprofileScreen extends StatefulWidget {
  EditprofileScreen({super.key});
  @override
  State<EditprofileScreen> createState() => _EditprofileScreenState();
}

class _EditprofileScreenState extends State<EditprofileScreen> {
  String? profileImageUrl;
  Uint8List? selectedImage;
  final ImagePicker picker = ImagePicker();
  String cloudName = 'dddpbbjtv';
  String uploadPreset = 'my_image_picker';

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (mounted) setState(() => selectedImage = bytes);
    }
  }

  Future<String?> uploadToCloudinary(Uint8List imageBytes) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    var request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'profile.jpg'));
    var response = await request.send();
    var data = await response.stream.bytesToString();
    if (response.statusCode == 200) return jsonDecode(data)['secure_url'];
    return null;
  }

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String _initials = '';

  @override
  void initState() { super.initState(); _loadUser(); }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  Future<void> _loadUser() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snap.data() ?? {};
      _nameCtrl.text = data['name'] ?? '';
      _emailCtrl.text = data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
      profileImageUrl = data['profileImage'];
      _updateInitials(_nameCtrl.text);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _updateInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) { _initials = '?'; return; }
    _initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : parts.first[0].toUpperCase();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) { _showError('Name cannot be empty'); return; }
    if (_emailCtrl.text.trim().isEmpty) { _showError('Email cannot be empty'); return; }
    if (!_emailCtrl.text.trim().contains('@')) { _showError('Enter a valid email address'); return; }

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final user = FirebaseAuth.instance.currentUser!;
      final Map<String, dynamic> updates = {'name': _nameCtrl.text.trim()};

      if (selectedImage != null) {
        String? imageUrl = await uploadToCloudinary(selectedImage!);
        if (imageUrl != null) { updates['profileImage'] = imageUrl; if (mounted) setState(() => profileImageUrl = imageUrl); }
      }

      final newEmail = _emailCtrl.text.trim();
      if (newEmail != user.email && newEmail.isNotEmpty) { await user.updateEmail(newEmail); updates['email'] = newEmail; }
      await FirebaseFirestore.instance.collection('users').doc(uid).update(updates);
      _updateInitials(_nameCtrl.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Profile updated successfully!'), backgroundColor: Color(0xFF2E7D32)));
        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      _showError(_authError(e.code));
    } catch (e) {
      _showError('Something went wrong. Try again.');
    }
    if (mounted) setState(() => _saving = false);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Color(0xFFE53935)));
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'This email is already in use.';
      case 'invalid-email': return 'Invalid email address.';
      case 'requires-recent-login': return 'Please log out and log in again to change email.';
      default: return 'Error: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    //Theme
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: gold))
          : Column(children: [
        //Gold header
        GestureDetector(
          onTap: pickImage,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, h * 0.07, 16, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [goldLight, Color(0xFFFFD700), gold],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Column(children: [
              Text('Edit Profile', style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 20),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _nameCtrl,
                builder: (_, val, __) {
                  _updateInitials(val.text);
                  return Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(38),
                          blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: ClipOval(
                      child: selectedImage != null
                          ? Image.memory(selectedImage!, width: 80, height: 80, fit: BoxFit.cover)
                          : profileImageUrl != null && profileImageUrl!.isNotEmpty
                          ? Image.network(profileImageUrl!, width: 80, height: 80, fit: BoxFit.cover)
                          : Center(child: Icon(Icons.add_a_photo, size: 38, color: gold)),
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
              Text('Your profile picture', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
        ),

        //Form
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sectionLabel('Personal Information', isDark),
              SizedBox(height: 12),
              _field(controller: _nameCtrl, label: 'Full Name',
                  hint: 'Enter your full name', icon: Icons.person_outline_rounded, isDark: isDark),
              SizedBox(height: 14),
              _field(controller: _emailCtrl, label: 'Email Address',
                  hint: 'Enter your email', icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress, isDark: isDark),
              SizedBox(height: 32),

              //Save button
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    disabledBackgroundColor: gold.withAlpha(153),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _saving
                      ? SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_rounded,
                        color: isDark ? Colors.black : Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Save Changes', style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.black : Colors.white)),
                  ]),
                ),
              ),
              SizedBox(height: 14),

              //Cancel
              SizedBox(
                width: double.infinity, height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: gold, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Cancel', style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? goldLight : goldDark)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  //Field with dark mode
  Widget _field({
    required TextEditingController controller, required String label,
    required String hint, required IconData icon, required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
          color: isDark ? goldLight : Color(0xFF8A7040))),
      SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14,
            color: isDark ? darkTextPrimary : Colors.black87,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13,
              color: isDark ? darkTextGrey : Colors.grey.shade400),
          prefixIcon: Icon(icon, color: gold, size: 20),
          filled: true,
          fillColor: isDark ? darkCard : lightCard,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? goldBorder30 : Color(0xFFE8D88A), width: 1.2)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? goldBorder30 : Color(0xFFE8D88A), width: 1.2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: gold, width: 1.8)),
        ),
      ),
    ]);
  }

  Widget _sectionLabel(String text, bool isDark) => Row(children: [
    Container(width: 3, height: 16,
        decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(3))),
    SizedBox(width: 8),
    Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
        color: isDark ? gold : Color(0xFF5A4400))),
  ]);
}