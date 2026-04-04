import 'package:curren_see/Screens/Login_Screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:curren_see/Constants/Constants.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool obs = true;

  TextEditingController userNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController contactNumberController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  //NEW Password Validation Function
  String? validatePassword(String password) {
    List<String> errors = [];

    if (password.length < 8) {
      errors.add('• At least 8 characters');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('• At least one uppercase letter (A-Z)');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('• At least one lowercase letter (a-z)');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('• At least one number (0-9)');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('• At least one special character (!@#\$%^&*)');
    }

    if (errors.isEmpty) {
      return null;
    } else {
      return 'Password must contain:\n${errors.join('\n')}';
    }
  }

  //UPDATED User-Friendly Error Messages
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
    // Register Errors
      case 'email-already-in-use':
        return 'An account already exists with this email. Please login.';
      case 'weak-password':
        return 'Password is too weak. It must be at least 8 characters with uppercase, lowercase, number & special character.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'This sign-up method is not enabled. Contact support.';
      case 'password-does-not-meet-requirements':
        return 'Password must contain at least 8 characters, uppercase, lowercase, number & special character.';

    // General Errors
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';

      default:
        return 'Something went wrong. Please try again later.';
    }
  }

  //UPDATED signUp with password validation
  Future<void> signUp() async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    //Empty fields check
    if (userNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        contactNumberController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Please fill in all fields.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    //Phone number validation
    String phone = contactNumberController.text.trim();

    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Phone number must contain only digits (0-9).',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (phone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Phone number must be exactly 11 digits.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    //Password validation
    String? passwordError = validatePassword(passwordController.text);
    if (passwordError != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? darkCard : lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Weak Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? darkTextPrimary : lightTextPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            passwordError,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? darkTextGrey : lightTextGrey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(
                  color: gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    //Firebase Sign Up
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      String uID = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uID).set({
        'name': userNameController.text.trim(),
        'contactNumber': contactNumberController.text.trim(),
        'email': emailController.text.trim(),
      });

      userNameController.clear();
      emailController.clear();
      contactNumberController.clear();
      passwordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color(0xFF2E7D32),
          content: Text(
            'Account created successfully! Please login.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            getErrorMessage(e.code),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Something went wrong. Please try again later.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    //Pre-calculate colors
    final Color scaffoldBg = isDark ? darkBg : lightCard;
    final Color cardBg = isDark ? darkCard : lightCard;
    final Color titleColor = isDark ? darkTextPrimary : lightTextPrimary;
    final Color subtextColor = isDark ? darkTextGrey : lightTextGrey;
    final Color hintColor = isDark ? darkTextGrey : lightTextGrey;
    final Color inputFill = isDark ? darkInputFill : lightInputFill;
    final Color inputBorder = isDark ? darkInputBorder : lightInputBorder;
    final Color textColor = isDark ? darkTextPrimary : lightTextPrimary;
    final Color cardBorder = isDark ? goldBorder30 : gold;
    final Color cardShadow = isDark ? darkShadow : goldBorder15;
    final Color heroCircleBg = isDark ? darkCard : lightCard;
    final Color heroShadow =
    isDark ? const Color(0x40000000) : const Color(0x26000000);

    final List<Color> heroGradient = isDark
        ? [goldDark, const Color(0xFF8B7318), const Color(0xFF6B5710)]
        : [goldLight, gold, goldDark];

    return SafeArea(
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: SingleChildScrollView(
          child: Column(
            children: [
              //Gold Header
              Container(
                width: double.infinity,
                height: screenHeight * 0.30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: heroGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.025),
                    Container(
                      width: screenWidth * 0.22,
                      height: screenWidth * 0.22,
                      decoration: BoxDecoration(
                        color: heroCircleBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: heroShadow,
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '₿',
                          style: TextStyle(
                            fontSize: screenWidth * 0.105,
                            fontWeight: FontWeight.w900,
                            color: gold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Curren',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          TextSpan(
                            text: 'See',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.075,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.006),
                    Text(
                      'EXCHANGE  ·  CONVERT  ·  TRACK',
                      style: TextStyle(
                        color: const Color(0xB3FFFFFF),
                        fontSize: screenWidth * 0.022,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
              ),

              //Register Card
              Padding(
                padding: EdgeInsets.fromLTRB(
                  screenWidth * 0.06,
                  screenHeight * 0.035,
                  screenWidth * 0.06,
                  screenHeight * 0.045,
                ),
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    border: Border.all(color: cardBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: cardShadow,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: screenWidth * 0.055,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        'Join CurrenSee today',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: screenWidth * 0.032,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      //Username
                      _fieldLabel('Username', screenWidth),
                      SizedBox(height: screenHeight * 0.008),
                      _buildTextField(
                        controller: userNameController,
                        hint: 'Enter your username',
                        icon: Icons.person_outline,
                        screenWidth: screenWidth,
                        textColor: textColor,
                        hintColor: hintColor,
                        fillColor: inputFill,
                        borderColor: inputBorder,
                      ),
                      SizedBox(height: screenHeight * 0.017),

                      //Email
                      _fieldLabel('Email Address', screenWidth),
                      SizedBox(height: screenHeight * 0.008),
                      _buildTextField(
                        controller: emailController,
                        hint: 'Enter your email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        screenWidth: screenWidth,
                        textColor: textColor,
                        hintColor: hintColor,
                        fillColor: inputFill,
                        borderColor: inputBorder,
                      ),
                      SizedBox(height: screenHeight * 0.017),

                      //Contact
                      _fieldLabel('Contact Number', screenWidth),
                      SizedBox(height: screenHeight * 0.008),
                      _buildTextField(
                        controller: contactNumberController,
                        hint: 'Enter your number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        screenWidth: screenWidth,
                        textColor: textColor,
                        hintColor: hintColor,
                        fillColor: inputFill,
                        borderColor: inputBorder,
                      ),
                      SizedBox(height: screenHeight * 0.017),

                      //Password
                      _fieldLabel('Password', screenWidth),
                      SizedBox(height: screenHeight * 0.008),
                      TextField(
                        controller: passwordController,
                        obscureText: obs,
                        cursorColor: gold,
                        cursorOpacityAnimates: true,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(color: hintColor),
                          prefixIcon: Icon(Icons.lock_outline,
                              color: gold, size: screenWidth * 0.05),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => obs = !obs),
                            icon: Icon(
                              obs
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: gold,
                              size: screenWidth * 0.05,
                            ),
                          ),
                          filled: true,
                          fillColor: inputFill,
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(screenWidth * 0.03),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(screenWidth * 0.03),
                            borderSide: BorderSide(color: gold, width: 2),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      //Create Account Button
                      SizedBox(
                        width: double.infinity,
                        height: screenHeight * 0.065,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [goldLight, gold, goldDark],
                            ),
                            borderRadius:
                            BorderRadius.circular(screenWidth * 0.03),
                            boxShadow: [
                              BoxShadow(
                                color: goldShadow40,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(screenWidth * 0.03),
                              ),
                            ),
                            child: Text(
                              'CREATE ACCOUNT',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.025),

                      //Already have account
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: screenWidth * 0.032,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding:
                                EdgeInsets.only(left: screenWidth * 0.01),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  color: gold,
                                  fontSize: screenWidth * 0.032,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text, double screenWidth) {
    return Text(
      text,
      style: TextStyle(
        color: gold,
        fontSize: screenWidth * 0.032,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required double screenWidth,
    required Color textColor,
    required Color hintColor,
    required Color fillColor,
    required Color borderColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      cursorColor: gold,
      cursorOpacityAnimates: true,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(icon, color: gold, size: screenWidth * 0.05),
        filled: true,
        fillColor: fillColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: BorderSide(color: gold, width: 2),
        ),
      ),
    );
  }
}