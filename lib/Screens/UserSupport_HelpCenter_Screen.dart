import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curren_see/Constants/Constants.dart';

//Pre-calculated opacity colors
const Color _goldOp08  = Color(0x14C7A729);
const Color _goldOp10  = Color(0x1AC7A729);
const Color _goldOp18  = Color(0x2EC7A729);
const Color _goldOp30  = Color(0x4DC7A729);
const Color _blackOp03 = Color(0x08000000);
const Color _blackOp04 = Color(0x0A000000);
const Color _whiteOp20 = Color(0x33FFFFFF);
const Color _whiteOp85 = Color(0xD9FFFFFF);

class UsersupportHelpcenterScreen extends StatefulWidget {
  UsersupportHelpcenterScreen({super.key});

  @override
  State<UsersupportHelpcenterScreen> createState() =>
      _UsersupportHelpcenterScreenState();
}

class _UsersupportHelpcenterScreenState
    extends State<UsersupportHelpcenterScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isSending = false;

  int? _expandedIdx;
  String _selectedSubject = 'General Inquiry';

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _subjects = [
    'General Inquiry',
    'Bug Report',
    'Feature Request',
    'Account Issue',
    'Other',
  ];

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I convert currencies?',
      'a': 'Go to the Currency Converter screen, select your source and target currencies, enter the amount, and the converted value will appear instantly.',
    },
    {
      'q': 'How often are exchange rates updated?',
      'a': 'Exchange rates are updated daily using live data from our currency API. Rates reflect the latest available market data.',
    },
    {
      'q': 'Can I set rate alerts?',
      'a': 'Yes! Go to the Alerts section, choose a currency pair, set your desired rate threshold, and you will be notified when the rate is reached.',
    },
    {
      'q': 'Which currencies are supported?',
      'a': 'CurrenSee supports 150+ world currencies including USD, EUR, GBP, JPY, PKR, INR, AED, SAR, and many more.',
    },
    {
      'q': 'Is the app available offline?',
      'a': 'Basic features work offline using the last cached rates. However, for live rates and news you need an internet connection.',
    },
    {
      'q': 'How do I read the market trend graph?',
      'a': 'The graph shows current exchange rates for major currency pairs. Touch any point on the graph to see the exact rate and daily change percentage.',
    },
    {
      'q': 'How do I add currencies to favourites?',
      'a': 'On any currency pair, tap the star icon to add it to your favourites list for quick access from the home screen.',
    },
    {
      'q': 'Why is my rate alert not triggering?',
      'a': 'Make sure notifications are enabled for CurrenSee in your device settings. Also check that your target rate is different from the current rate.',
    },
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    //Pre calculate all colors
    final Color scaffoldBg    = isDark ? darkBg : lightBg;
    final Color cardBg        = isDark ? darkCard : lightCard;
    final Color titleColor    = isDark ? darkTextPrimary : lightTextPrimary;
    final Color greyText      = isDark ? darkTextGrey : lightTextGrey;
    final Color borderColor   = isDark ? darkDivider : Color(0xFFEEE4B8);
    final Color inputFill     = isDark ? darkInputFill : Color(0xFFFFFBF0);
    final Color inputBorder   = isDark ? darkInputBorder : Color(0xFFE8D88A);
    final Color formLabelClr  = isDark ? gold : Color(0xFF5A4400);
    final Color cardShadow    = isDark ? darkShadow : _blackOp04;
    final Color iconBoxBg     = isDark ? goldBorder15 : Color(0xFFFFF8E1);
    final Color dividerClr    = isDark ? darkDivider : Color(0xFFF5EED5);
    final Color dropdownBg    = isDark ? darkInputFill : Color(0xFFFFFBF0);
    final Color dropdownBrd   = isDark ? darkInputBorder : Color(0xFFE8D88A);
    final Color dropdownText  = isDark ? darkTextPrimary : lightTextPrimary;

    final Color heroBannerShadow = isDark ? darkShadow : _goldOp30;
    final Color heroIconBg       = isDark ? const Color(0x44FFFFFF) : _whiteOp20;

    final Color faqOpenBorder    = isDark ? gold : goldLight;
    final Color faqClosedBorder  = isDark ? darkDivider : Color(0xFFEEE4B8);
    final Color faqOpenShadow    = isDark ? darkShadow : _goldOp10;
    final Color faqClosedShadow  = isDark ? darkShadow : _blackOp03;
    final Color faqOpenNumBg     = gold;
    final Color faqClosedNumBg   = isDark ? goldBorder15 : Color(0xFFFFF8E1);
    final Color faqOpenQText     = isDark ? gold : Color(0xFF5A4400);
    final Color faqClosedQText   = isDark ? darkTextPrimary : lightTextPrimary;
    final Color faqArrow         = isDark ? gold : lightTextGrey;
    final Color faqAnswerText    = isDark ? darkTextGrey : lightTextGrey;
    final Color faqDivider       = isDark ? darkDivider : Color(0xFFEEE4B8);

    final Color formCardBorder = isDark ? goldBorder30 : Color(0xFFE8D88A);
    final Color formCardShadow = isDark ? darkShadow : _goldOp08;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: w * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: h * 0.02),


            //Hero Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(w * 0.045),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: isDark
                      ? [goldDark, const Color(0xFF8B7318)]
                      : [goldLight, Color(0xFFB08A10)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: heroBannerShadow,
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: heroIconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.support_agent_rounded,
                        color: Colors.white, size: 30),
                  ),
                  SizedBox(width: w * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How can we help you?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Find answers or contact our team',
                          style: TextStyle(
                            color: _whiteOp85,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: h * 0.025),

            //Quick Contact Cards
            _sectionTitle('Quick Contact', Icons.bolt_rounded, titleColor),
            SizedBox(height: h * 0.012),
            Row(
              children: [
                Expanded(
                  child: _quickCard(Icons.email_rounded, 'Email Us',
                      'support@currensee.app', w, h,
                      cardBg, borderColor, cardShadow, titleColor,
                      greyText, iconBoxBg),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: _quickCard(Icons.phone_rounded, 'Call Us',
                      '+92 300 0000000', w, h,
                      cardBg, borderColor, cardShadow, titleColor,
                      greyText, iconBoxBg),
                ),
              ],
            ),
            SizedBox(width: w * 0.03),
            Row(
              children: [
                Expanded(
                  child: _quickCard(Icons.chat_rounded, 'Live Chat',
                      'Coming soon', w, h,
                      cardBg, borderColor, cardShadow, titleColor,
                      greyText, iconBoxBg),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: _quickCard(Icons.info, 'Application',
                      'currensee.app', w, h,
                      cardBg, borderColor, cardShadow, titleColor,
                      greyText, iconBoxBg),
                ),
              ],
            ),

            SizedBox(height: h * 0.025),

            //FAQs
            _sectionTitle(
                'Frequently Asked Questions', Icons.quiz_rounded, titleColor),
            SizedBox(height: h * 0.012),
            ...List.generate(
                _faqs.length,
                    (i) => _faqCard(
                    i, w, h, cardBg,
                    faqOpenBorder, faqClosedBorder,
                    faqOpenShadow, faqClosedShadow,
                    faqOpenNumBg, faqClosedNumBg,
                    faqOpenQText, faqClosedQText,
                    faqArrow, faqAnswerText, faqDivider)),

            SizedBox(height: h * 0.025),

            //Contact Form
            _sectionTitle(
                'Send Us a Message', Icons.edit_rounded, titleColor),
            SizedBox(height: h * 0.012),

            Container(
              padding: EdgeInsets.all(w * 0.045),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: formCardBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: formCardShadow,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _formLabel('Your Name', formLabelClr),
                    SizedBox(height: h * 0.007),
                    _formField(_nameCtrl, 'Enter your full name',
                        Icons.person_outline_rounded, (v) => null,
                        inputFill: inputFill,
                        inputBorder: inputBorder,
                        textColor: titleColor,
                        hintColor: greyText),

                    SizedBox(height: h * 0.016),
                    _formLabel('Email Address', formLabelClr),
                    SizedBox(height: h * 0.007),
                    _formField(_emailCtrl, 'Enter your email',
                        Icons.email_outlined, (v) => null,
                        keyboardType: TextInputType.emailAddress,
                        inputFill: inputFill,
                        inputBorder: inputBorder,
                        textColor: titleColor,
                        hintColor: greyText),

                    SizedBox(height: h * 0.016),
                    _formLabel('Subject', formLabelClr),
                    SizedBox(height: h * 0.007),
                    _subjectDropdown(w, dropdownBg, dropdownBrd,
                        dropdownText, cardBg),

                    SizedBox(height: h * 0.016),
                    _formLabel('Message', formLabelClr),
                    SizedBox(height: h * 0.007),
                    _formField(
                        _messageCtrl,
                        'Describe your issue or question...',
                        Icons.message_outlined,
                            (v) => null,
                        maxLines: 5,
                        inputFill: inputFill,
                        inputBorder: inputBorder,
                        textColor: titleColor,
                        hintColor: greyText),

                    SizedBox(height: h * 0.022),

                    //Send Button
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _isSending ? null : _submitForm,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding:
                          EdgeInsets.symmetric(vertical: h * 0.018),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isSending
                                  ? isDark
                                  ? [
                                const Color(0xFF555555),
                                const Color(0xFF444444)
                              ]
                                  : [
                                const Color(0xFFBDBDBD),
                                const Color(0xFF9E9E9E)
                              ]
                                  : isDark
                                  ? [
                                goldDark,
                                const Color(0xFF8B7318)
                              ]
                                  : [goldLight, Color(0xFFB08A10)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _isSending
                                    ? (isDark
                                    ? darkShadow
                                    : _blackOp04)
                                    : (isDark
                                    ? darkShadow
                                    : _goldOp30),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSending)
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2),
                                )
                              else
                                Icon(Icons.send_rounded,
                                    color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                _isSending
                                    ? 'Sending...'
                                    : 'Send Message',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: h * 0.025),


            //Response Time
            _sectionTitle(
                'Response Time', Icons.access_time_rounded, titleColor),
            SizedBox(height: h * 0.012),
            Container(
              padding: EdgeInsets.all(w * 0.04),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                children: [
                  _responseRow(Icons.email_rounded, 'Email Support',
                      'Within 24 hours', titleColor, greyText),
                  _divider(dividerClr),
                  _responseRow(Icons.chat_rounded, 'Live Chat',
                      'Coming soon', titleColor, greyText),
                  _divider(dividerClr),
                  _responseRow(Icons.phone_rounded, 'Phone Support',
                      'Mon–Fri, 9am–6pm', titleColor, greyText),
                  _divider(dividerClr),
                  _responseRow(Icons.bug_report_rounded, 'Bug Reports',
                      'Within 48 hours', titleColor, greyText),
                ],
              ),
            ),

            SizedBox(height: h * 0.04),
          ],
        ),
      ),
    );
  }

  //FAQ Card
  Widget _faqCard(
      int i,
      double w,
      double h,
      Color cardBg,
      Color openBorder,
      Color closedBorder,
      Color openShadow,
      Color closedShadow,
      Color openNumBg,
      Color closedNumBg,
      Color openQText,
      Color closedQText,
      Color arrowColor,
      Color answerText,
      Color divColor) {
    final open = _expandedIdx == i;
    return GestureDetector(
      onTap: () => setState(() => _expandedIdx = open ? null : i),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: h * 0.012),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: open ? openBorder : closedBorder,
            width: open ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: open ? openShadow : closedShadow,
              blurRadius: open ? 10 : 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(w * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: open ? openNumBg : closedNumBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: open ? Colors.white : goldDark,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Text(
                      _faqs[i]['q']!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: open ? openQText : closedQText,
                      ),
                    ),
                  ),
                  Icon(
                    open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: open ? gold : arrowColor,
                    size: 22,
                  ),
                ],
              ),
              if (open) ...[
                SizedBox(height: 10),
                Container(height: 1, color: divColor),
                SizedBox(height: 10),
                Text(
                  _faqs[i]['a']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: answerText,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  //Quick Contact Card
  Widget _quickCard(
      IconData icon,
      String title,
      String sub,
      double w,
      double h,
      Color cardBg,
      Color borderColor,
      Color shadow,
      Color titleColor,
      Color greyText,
      Color iconBg) {
    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: gold, size: 20),
          ),
          SizedBox(height: h * 0.008),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(fontSize: 10, color: greyText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  //Subject Dropdown
  Widget _subjectDropdown(double w, Color bg, Color border,
      Color textColor, Color dropdownBg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSubject,
          isExpanded: true,
          icon:
          Icon(Icons.keyboard_arrow_down_rounded, color: gold),
          style: TextStyle(fontSize: 13, color: textColor),
          dropdownColor: dropdownBg,
          items: _subjects
              .map((s) => DropdownMenuItem(
            value: s,
            child: Text(s,
                style: TextStyle(
                    fontSize: 13, color: textColor)),
          ))
              .toList(),
          onChanged: (v) =>
              setState(() => _selectedSubject = v!),
        ),
      ),
    );
  }

  //Form Label
  Widget _formLabel(String label, Color color) => Text(
    label,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: color,
    ),
  );

  //Form Field
  Widget _formField(
      TextEditingController ctrl,
      String hint,
      IconData icon,
      String? Function(String?) validator, {
        int maxLines = 1,
        TextInputType? keyboardType,
        required Color inputFill,
        required Color inputBorder,
        required Color textColor,
        required Color hintColor,
      }) {
    return TextFormField(
      cursorOpacityAnimates: true,
      cursorColor: gold,
      controller: ctrl,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: hintColor),
        prefixIcon:
        maxLines == 1 ? Icon(icon, color: gold, size: 18) : null,
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(
            horizontal: 14, vertical: maxLines > 1 ? 14 : 0),
        isDense: true,
      ),
    );
  }

  //Response Row
  Widget _responseRow(IconData icon, String label, String value,
      Color titleColor, Color greyText) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 18),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(Color color) =>
      Container(height: 1, color: color);

  // section
  Widget _sectionTitle(
      String title, IconData icon, Color titleColor) =>
      Row(
        children: [
          Container(
            width: 3,
            height: 17,
            decoration: BoxDecoration(
              color: gold,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: 9),
          Icon(icon, color: goldDark, size: 17),
          SizedBox(width: 7),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
        ],
      );


  void _submitForm() async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    FocusScope.of(context).unfocus();

    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter your name!');
      return;
    }
    if (RegExp(r'[0-9]').hasMatch(_nameCtrl.text.trim())) {
      _showSnack('Name should contain alphabets only!');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      _showSnack('Please enter your email!');
      return;
    }
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$')
        .hasMatch(_emailCtrl.text.trim())) {
      _showSnack('Please enter a valid email address!');
      return;
    }
    if (_messageCtrl.text.trim().isEmpty) {
      _showSnack('Please enter your message!');
      return;
    }

    setState(() => _isSending = true);

    try {
      await _db.collection('support_messages').add({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'subject': _selectedSubject,
        'message': _messageCtrl.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      _nameCtrl.clear();
      _emailCtrl.clear();
      _messageCtrl.clear();
      setState(() {
        _selectedSubject = 'General Inquiry';
        _isSending = false;
      });

      if (!mounted) return;

      //Dialog colors
      final Color dialogBg      = isDark ? darkCard : lightCard;
      final Color dialogTitle   = isDark ? darkTextPrimary : lightTextPrimary;
      final Color dialogSubtext = isDark ? darkTextGrey : lightTextGrey;
      final Color checkBorder   = isDark ? goldBorder30 : Color(0xFFE8D88A);
      final Color checkShadow   = isDark ? darkShadow : _goldOp18;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          final w = MediaQuery.of(context).size.width;
          return Dialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: Offset(0, -30),
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: dialogBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: checkBorder, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: checkShadow,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(Icons.check_rounded,
                            color: gold, size: 30),
                      ),
                    ),
                  ),
                  Text(
                    'Request Sent!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: dialogTitle,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Your request has been successfully submitted. We will get back to you soon.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: dialogSubtext,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: w * 0.35,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding:
                        EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                              goldDark,
                              const Color(0xFF8B7318)
                            ]
                                : [
                              goldLight,
                              Color(0xFFB08A10)
                            ],
                          ),
                          borderRadius:
                          BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? darkShadow
                                  : _goldOp30,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'Okay',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      setState(() => _isSending = false);
      _showSnack('Failed to send. Please try again.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        msg,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: Color(0xFFC62828),
      duration: Duration(seconds: 3),
      behavior: SnackBarBehavior.fixed,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ));
  }

  void _launchEmail() async {
    final uri = Uri.parse(
        'mailto:support@currensee.app?subject=Support Request');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _launchPhone() async {
    final uri = Uri.parse('tel:+923000000000');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _launchWeb() async {
    final uri = Uri.parse('https://currensee.app');
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}