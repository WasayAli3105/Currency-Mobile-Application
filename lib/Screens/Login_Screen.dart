import 'package:curren_see/Screens/Home_Screen.dart';
import 'package:curren_see/Screens/Register_Screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curren_see/Constants/Constants.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obs = true;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();


  String getErrorMessage(String errorCode) {
    switch (errorCode) {
    // Login Errors
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-not-found':
        return 'No account found with this email. Please register first.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';

    // Register Errors
      case 'email-already-in-use':
        return 'An account already exists with this email. Please login.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';

    // General Errors
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'requires-recent-login':
        return 'Please login again and retry.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';

      default:
        return 'Something went wrong. Please try again later.';
    }
  }

  Future<void> signIn() async {
    // Empty field check
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Please enter both email and password.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color(0xFF2E7D32),
          content: Text(
            'Login Successful! Welcome back.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 3),
        ),
      );

      //Firebase Error User Friendly Message
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
    emailController.clear();
    passwordController.clear();
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      User? user = userCredential.user;

      if (user != null) {
        DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

        DocumentSnapshot snapshot = await userDoc.get();

        if (!snapshot.exists) {
          await userDoc.set({
            "name": user.displayName,
            "email": user.email,
            "profileImage": user.photoURL,
            "uid": user.uid,
          });
        }
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color(0xFF2E7D32),
          content: Text(
            'Google Login Successful!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
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
            'Google Sign-In failed. Please try again.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }


  // Forgot Password Dialog
  void forgetPassword() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;

    //Auto-fill login form ka email
    TextEditingController forgotEmailController = TextEditingController(
      text: emailController.text.trim(),
    );

    final Color dialogBg = isDark ? darkCard : lightCard;
    final Color titleColor = isDark ? darkTextPrimary : lightTextPrimary;
    final Color subtitleColor = isDark ? darkTextGrey : lightTextGrey;
    final Color hintColor = isDark ? darkTextGrey : lightTextGrey;
    final Color inputFill = isDark ? darkInputFill : lightInputFill;
    final Color inputBorder = isDark ? darkInputBorder : lightInputBorder;
    final Color textColor = isDark ? darkTextPrimary : lightTextPrimary;
    final Color circleBg = isDark ? darkCard : lightCard;
    final Color circleBorder = isDark ? darkDivider : lightDivider;
    final Color circleShadow = isDark ? darkShadow : lightShadow;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(w * 0.06)),
        backgroundColor: dialogBg,
        insetPadding: EdgeInsets.symmetric(horizontal: w * 0.07),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding:
              EdgeInsets.fromLTRB(w * 0.05, h * 0.065, w * 0.05, h * 0.025),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: w * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: h * 0.012),
                  Center(
                    child: Text(
                      'Enter your email address to receive a password reset link in your Gmail.',
                      textAlign: TextAlign.center,
                      style:
                      TextStyle(color: subtitleColor, fontSize: w * 0.032),
                    ),
                  ),
                  SizedBox(height: h * 0.025),
                  Text(
                    'Email Address',
                    style: TextStyle(
                        color: gold,
                        fontSize: w * 0.032,
                        fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: h * 0.008),
                  TextField(
                    controller: forgotEmailController,
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: gold,
                    cursorOpacityAnimates: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      hintStyle: TextStyle(color: hintColor),
                      prefixIcon: Icon(Icons.email_outlined,
                          color: gold, size: w * 0.05),
                      filled: true,
                      fillColor: inputFill,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(w * 0.03),
                          borderSide: BorderSide(color: inputBorder)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(w * 0.03),
                          borderSide: BorderSide(color: gold, width: 2)),
                    ),
                  ),
                  SizedBox(height: h * 0.028),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: h * 0.065,
                          child: OutlinedButton(
                            onPressed: () {
                              forgotEmailController.clear();
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: gold, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(w * 0.03)),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                  color: gold,
                                  fontWeight: FontWeight.w700,
                                  fontSize: w * 0.038),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: w * 0.03),
                      Expanded(
                        child: SizedBox(
                          height: h * 0.065,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [goldLight, gold, goldDark],
                              ),
                              borderRadius: BorderRadius.circular(w * 0.03),
                              boxShadow: [
                                BoxShadow(
                                  color: goldShadow40,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                if (forgotEmailController.text
                                    .trim()
                                    .isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(
                                        'Please enter your email address.',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                String email = forgotEmailController.text.trim();
                                if (!email.contains('@') || !email.contains('.')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(
                                        'Please enter a valid email address.',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  await FirebaseAuth.instance
                                      .sendPasswordResetEmail(
                                      email: email);
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Color(0xFF2E7D32),
                                      content: Text(
                                        'Reset link sent to $email! Check your inbox.',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                } on FirebaseAuthException catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(
                                        getErrorMessage(e.code),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(
                                        'Something went wrong. Please try again.',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(w * 0.03)),
                              ),
                              child: Text(
                                'Send',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: w * 0.038),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: -h * 0.05,
              child: Container(
                width: w * 0.2,
                height: w * 0.2,
                decoration: BoxDecoration(
                  color: circleBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: circleBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: circleShadow,
                      blurRadius: 20,
                      spreadRadius: 1,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '₿',
                    style: TextStyle(
                      fontSize: w * 0.095,
                      fontWeight: FontWeight.w900,
                      color: gold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //BUILD METHOD NO CHANGES NEEDED
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    final Color scaffoldBg = isDark ? darkBg : lightCard;
    final Color cardBg = isDark ? darkCard : lightCard;
    final Color titleColor = isDark ? darkTextPrimary : lightTextPrimary;
    final Color subtitleColor = isDark ? darkTextGrey : lightTextGrey;
    final Color hintColor = isDark ? darkTextGrey : lightTextGrey;
    final Color inputFill = isDark ? darkInputFill : lightInputFill;
    final Color inputBorder = isDark ? darkInputBorder : lightInputBorder;
    final Color textColor = isDark ? darkTextPrimary : lightTextPrimary;
    final Color cardBorder = isDark ? goldBorder30 : gold;
    final Color cardShadow = isDark ? darkShadow : goldBorder15;
    final Color heroBtnShadow =
    isDark ? const Color(0x40000000) : const Color(0x26000000);
    final Color heroCircleBg = isDark ? darkCard : lightCard;

    final List<Color> heroGradient = isDark
        ? [goldDark, const Color(0xFF8B7318), const Color(0xFF6B5710)]
        : [goldLight, gold, goldDark];

    return SafeArea(
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: screenHeight * 0.32,
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
                      width: screenWidth * 0.25,
                      height: screenWidth * 0.25,
                      decoration: BoxDecoration(
                        color: heroCircleBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: heroBtnShadow,
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
                            fontSize: screenWidth * 0.115,
                            fontWeight: FontWeight.w900,
                            color: gold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.017),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Curren',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.065,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          TextSpan(
                            text: 'See',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.007),
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
              Padding(
                padding: EdgeInsets.fromLTRB(
                  screenWidth * 0.06,
                  screenHeight * 0.037,
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
                        'Welcome Back',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: screenWidth * 0.055,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        'Login to your account',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: screenWidth * 0.032,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      Text(
                        'Email Address',
                        style: TextStyle(
                          color: gold,
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.008),
                      TextField(
                        controller: emailController,
                        cursorColor: gold,
                        cursorOpacityAnimates: true,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Email Address',
                          hintStyle: TextStyle(color: hintColor),
                          prefixIcon: Icon(Icons.email_outlined,
                              color: gold, size: screenWidth * 0.05),
                          filled: true,
                          fillColor: inputFill,
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(screenWidth * 0.03),
                              borderSide: BorderSide(color: inputBorder)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(screenWidth * 0.03),
                              borderSide: BorderSide(color: gold, width: 2)),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.017),
                      Text(
                        'Password',
                        style: TextStyle(
                          color: gold,
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.008),
                      TextField(
                        controller: passwordController,
                        obscureText: obs,
                        cursorColor: gold,
                        cursorOpacityAnimates: true,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Password',
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
                              borderSide: BorderSide(color: inputBorder)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(screenWidth * 0.03),
                              borderSide: BorderSide(color: gold, width: 2)),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: forgetPassword,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: gold,
                              fontSize: screenWidth * 0.032,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.008),
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
                            onPressed: signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      screenWidth * 0.03)),
                            ),
                            child: Text(
                              'LOGIN',
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
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: screenWidth * 0.032,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => RegisterScreen()),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Register',
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
                      SizedBox(height: screenHeight * 0.03),
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: isDark ? goldBorder30 : gold,
                                  thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.025),
                            child: Text(
                              'Or continue with',
                              style: TextStyle(
                                color: isDark ? darkTextGrey : gold,
                                fontSize: screenWidth * 0.027,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: isDark ? goldBorder30 : gold,
                                  thickness: 1)),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.025),
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
                            onPressed: signInWithGoogle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(screenWidth * 0.03),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: screenWidth * 0.07,
                                  height: screenWidth * 0.07,
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'G',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFDB4437),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Text(
                                  'Google',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.038,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}