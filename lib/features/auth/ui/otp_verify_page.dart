import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
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

    // Check for connectivity issues first
    if (e is SocketException ||
        lower.contains('socket') ||
        lower.contains('timeout') ||
        lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('failed host lookup')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }

    // OTP invalid/expired / 422
    if (lower.contains('422') ||
        lower.contains('invalid') ||
        lower.contains('expired') ||
        lower.contains('otp')) {
      return 'The verification code is incorrect or has expired.';
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
      // Check internet connectivity first
      final connectivityResults = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResults.any((result) => result != ConnectivityResult.none);

      if (!hasConnection) {
        setState(() => _error = 'No internet connection. Please check your connection and try again.');
        return;
      }

      await _repo.verifyOtp(widget.phone, otp, widget.countryId);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    } on SocketException catch (_) {
      setState(() => _error = 'Unable to connect. Please check your internet connection and try again.');
      _clearOtpAndFocusFirst();
    } on DioException catch (e) {
      final msg = _humanizeOtpError(e);
      setState(() => _error = msg);
      if (msg.contains('incorrect') || msg.contains('expired')) {
        _clearOtpAndFocusFirst();
      }
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
      // Check internet connectivity first
      final connectivityResults = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResults.any((result) => result != ConnectivityResult.none);

      if (!hasConnection) {
        setState(() => _error = 'No internet connection. Please check your connection and try again.');
        return;
      }

      await _repo.resendOtp(widget.phone, widget.countryId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The code has been sent again.')),
      );
      _startResendCooldown(30);
    } on SocketException catch (_) {
      setState(() => _error = 'Unable to connect. Please check your internet connection and try again.');
      _startResendCooldown(60);
    } on DioException catch (e) {
      setState(() => _error = _humanizeOtpError(e));
      _startResendCooldown(60);
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

  Widget _otpCircleField(int i, double size) {
    final filled = _controllers[i].text.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
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
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF2F6FDB),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;

            // Calculate all dimensions at the top level to avoid nested LayoutBuilders
            final illustrationHeight = (screenHeight * 0.55).clamp(320.0, 550.0);
            final horizontalPadding = screenWidth * 0.048;
            final cardInnerPadding = 40.0; // 20 left + 20 right padding inside card
            final cardWidth = screenWidth - (horizontalPadding * 2);
            final otpCirclesAvailableWidth = cardWidth - cardInnerPadding;

            // Calculate OTP circle size with conservative gap
            const gap = 8.0; // Reduced from 10 to prevent overflow
            final totalGaps = gap * (_otpLength - 1);
            final calculatedCircleSize = (otpCirclesAvailableWidth - totalGaps - 4) / _otpLength; // Extra 4px safety margin
            final circleSize = calculatedCircleSize.clamp(40.0, 54.0); // Reduced max from 58 to 54

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 1),

                      // ===== Illustration + Bubble =====
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          height: illustrationHeight,
                          width: screenWidth - 48,
                          child: Stack(
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

                              // OTP Bubble (SVG) - positioned responsively
                              Positioned(
                                left: (screenWidth - 48) * 0.64,
                                top: illustrationHeight * 0.29,
                                child: SvgPicture.asset(
                                  _otpBubbleAsset,
                                  width: (screenWidth - 48) * 0.18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 1),

                      // ===== Card =====
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                              mainAxisSize: MainAxisSize.min,
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

                                // ===== OTP circles - using pre-calculated size =====
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(_otpLength, (i) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: i == _otpLength - 1 ? 0 : gap,
                                      ),
                                      child: _otpCircleField(i, circleSize),
                                    );
                                  }),
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
                                          const Color(0xFF2F6FDB).withValues(alpha: 0.35),
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
          },
        ),
      ),
    );
  }
}
