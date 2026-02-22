import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../shell/app_shell.dart';
import '../../../core/network/dio_client.dart';
import '../data/auth_api.dart';
import '../data/auth_repo.dart';

class OtpVerifyPage extends StatefulWidget {
  final String phone;
  final int countryId;

  const OtpVerifyPage({
    super.key,
    required this.phone,
    required this.countryId,
  });

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  late final AuthRepo _repo;

  static const int _otpLength = 6;

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  bool _loading = false;
  String? _error;

  int _resendSecondsLeft = 0;
  Timer? _timer;

  // ✅ Assets paths (لازم تكون موجودة بالمسار نفسه)
  static const String _illustrationAsset =
      'lib/app/assets/images/illustration.png';
  static const String _otpBubbleAsset = 'lib/app/assets/images/otp_bubble.svg';

  @override
  void initState() {
    super.initState();

    _repo = AuthRepo(
      api: AuthApi(DioClient.dio),
      tokenStorage: DioClient.tokenStorage,
    );

    _startResendCooldown(10);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _resendSecondsLeft = seconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendSecondsLeft <= 1) {
        t.cancel();
        setState(() => _resendSecondsLeft = 0);
      } else {
        setState(() => _resendSecondsLeft--);
      }
    });
  }

  String _getOtp() => _controllers.map((c) => c.text.trim()).join();
  bool get _canVerify => !_loading && _getOtp().length == _otpLength;

  String _phoneEnding() {
    final digits = widget.phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= 4) return digits;
    return digits.substring(digits.length - 4);
  }

  String _humanizeOtpError(Object e) {
    final raw = AuthRepo.friendlyDioError(e);
    final lower = raw.toLowerCase();

    // OTP invalid/expired / 422
    if (lower.contains('422') ||
        lower.contains('invalid') ||
        lower.contains('expired') ||
        lower.contains('otp')) {
      return 'The verification code is incorrect or has expired.';
    }

    // Network/timeout
    if (lower.contains('socket') ||
        lower.contains('timeout') ||
        lower.contains('network') ||
        lower.contains('connection')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  void _clearOtpAndFocusFirst() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() {});
  }

  Future<void> _verify() async {
    final otp = _getOtp();
    if (otp.length != _otpLength) {
      setState(() => _error = 'Please enter the full verification code (6 digits).');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ✅ التحقق من صحة رقم OTP من السيرفر
      // التوكن يتم حفظه تلقائيًا داخل verifyOtp
      await _repo.verifyOtp(widget.phone, otp, widget.countryId);

      if (!mounted) return;

      // الآن ننتقل إلى الصفحة الرئيسية
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    } catch (e) {
      final msg = _humanizeOtpError(e);
      setState(() => _error = msg);

      if (msg.contains('incorrect') || msg.contains('expired')) {
        _clearOtpAndFocusFirst();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendSecondsLeft > 0) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _repo.resendOtp(widget.phone, widget.countryId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The code has been sent again.')),
      );
      _startResendCooldown(30);
    } catch (e) {
      setState(() => _error = _humanizeOtpError(e));
      _startResendCooldown(60);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setOtpFromDigits(String digits, {int startIndex = 0}) {
    final clean = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;

    for (int i = startIndex; i < _otpLength; i++) {
      final srcIndex = i - startIndex;
      _controllers[i].text = (srcIndex < clean.length) ? clean[srcIndex] : '';
    }

    final nextEmpty = _controllers.indexWhere((c) => c.text.trim().isEmpty);
    if (nextEmpty == -1) {
      FocusScope.of(context).unfocus();
    } else {
      _focusNodes[nextEmpty].requestFocus();
    }

    setState(() {});
  }

  Widget _otpCircleField(int i) {
    final filled = _controllers[i].text.trim().isNotEmpty;

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: filled ? const Color(0xFF2F6FDB) : const Color(0xFFCBD5E1),
          width: 2,
        ),
      ),
      child: TextField(
        controller: _controllers[i],
        focusNode: _focusNodes[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textInputAction:
            i == _otpLength - 1 ? TextInputAction.done : TextInputAction.next,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2F6FDB),
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          setState(() => _error = null);

          // paste
          if (value.length > 1) {
            _setOtpFromDigits(value, startIndex: i);
            return;
          }

          final v = value.replaceAll(RegExp(r'[^0-9]'), '');

          // مسح الرقم -> رجوع للخانة السابقة
          if (v.isEmpty) {
            _controllers[i].text = '';
            if (i > 0) {
              _focusNodes[i - 1].requestFocus();
              _controllers[i - 1].selection = TextSelection.fromPosition(
                TextPosition(offset: _controllers[i - 1].text.length),
              );
            }
            setState(() {});
            return;
          }

          _controllers[i].text = v.substring(v.length - 1);

          if (i < _otpLength - 1) {
            _focusNodes[i + 1].requestFocus();
          } else {
            FocusScope.of(context).unfocus();
          }

          setState(() {});
        },
      ),
    );
  }

  /// ✅ Illustration with OTP bubble over it (مثل الفيجما)
  Widget _buildIllustrationWithBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 550,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
  child: Align(
    alignment: const Alignment(0, 0.55), 
    child: Transform.scale(
      scale: 1.20, 
      child: Image.asset(
        _illustrationAsset,
        fit: BoxFit.contain,
      ),
    ),
  ),
),


                // OTP Bubble (SVG)
                Positioned(
                  left: w * 0.64,
                  top: h * 0.29,
                  child: SvgPicture.asset(
                    _otpBubbleAsset,
                    width: w * 0.18,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 1),

              // ===== Illustration + Bubble =====
              _buildIllustrationWithBubble(),

              const SizedBox(height: 1),

              // ===== Card =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 20,
                        offset: Offset(0, 10),
                        color: Color(0x14000000),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'Verify Your Phone Number',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Enter the verification code sent to your phone\nnumber ending in ***${_phoneEnding()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.4,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ===== OTP circles =====
                        SizedBox(
                          height: 60,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                                _otpLength, (i) => _otpCircleField(i)),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),

                        // ===== Verify button =====
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _canVerify ? _verify : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F6FDB),
                              disabledBackgroundColor:
                                  const Color(0xFF2F6FDB).withOpacity(0.35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Verify',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ===== Resend =====
                        TextButton(
                          onPressed: (_loading || _resendSecondsLeft > 0)
                              ? null
                              : _resend,
                          child: Text(
                            _resendSecondsLeft > 0
                                ? 'Resend in $_resendSecondsLeft s'
                                : "Didn't receive a code?",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
