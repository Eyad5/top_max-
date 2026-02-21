import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/dio_client.dart';
import '../data/auth_api.dart';
import '../data/auth_repo.dart';
import 'otp_verify_page.dart';

class PhonePage extends StatefulWidget {
  const PhonePage({super.key});

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  final phoneController = TextEditingController();

  int? selectedCountryId;
  String selectedCountryName = 'Choose Country';
  String? selectedDialCode;

  static const int maxPhoneDigits = 9;

  bool _loading = false;
  String? _error;

  late final AuthRepo _repo = AuthRepo(
    api: AuthApi(DioClient.dio),
    tokenStorage: DioClient.tokenStorage,
  );

  // ✅ عدّل المسار حسب مكان الصورة عندك
  static const String _illustrationAsset =
      'lib/app/assets/images/illustration.png';

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void _stripAnyDialCodeFromControllerEnsureMax({String? oldDialCode}) {
    var digits = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('00')) digits = digits.substring(2);

    if (oldDialCode != null) {
      final dc = oldDialCode.replaceAll(RegExp(r'[^0-9]'), '');
      if (dc.isNotEmpty && digits.startsWith(dc)) {
        digits = digits.substring(dc.length);
      }
    }

    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length > maxPhoneDigits) {
      digits = digits.substring(0, maxPhoneDigits);
    }

    phoneController.text = digits;
    phoneController.selection = TextSelection.collapsed(offset: digits.length);
  }

  Future<void> openCountries() async {
    setState(() => _error = null);

    final res = await DioClient.dio.get('location/countries');
    final countries = res.data['data'] as List;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return ListView.builder(
          itemCount: countries.length,
          itemBuilder: (_, i) {
            final c = countries[i] as Map<String, dynamic>;
            return ListTile(
              title: Text(c['name'].toString()),
              subtitle: Text('${c['iso']}  ${c['code']}'),
              onTap: () {
                final old = selectedDialCode;

                setState(() {
                  selectedCountryId = (c['id'] as num).toInt();
                  selectedCountryName = c['name'].toString();
                  selectedDialCode = c['code']?.toString();
                  _error = null;
                });

                _stripAnyDialCodeFromControllerEnsureMax(oldDialCode: old);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  String _normalizePhone(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('00')) digits = digits.substring(2);

    if (selectedDialCode != null) {
      final dc = selectedDialCode!.replaceAll(RegExp(r'[^0-9]'), '');
      if (dc.isNotEmpty && digits.startsWith(dc)) {
        digits = digits.substring(dc.length);
      }
    }

    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length > maxPhoneDigits) {
      digits = digits.substring(0, maxPhoneDigits);
    }

    return digits;
  }

  Future<void> requestOtp() async {
    if (selectedCountryId == null) {
      setState(() => _error = 'اختر الدولة أولًا');
      return;
    }

    final phone = _normalizePhone(phoneController.text.trim());

    if (phone.length != maxPhoneDigits) {
      setState(() => _error = 'رقم الهاتف لازم يكون $maxPhoneDigits أرقام');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _repo.requestOtp(phone, selectedCountryId!);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerifyPage(
            phone: phone,
            countryId: selectedCountryId!,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = AuthRepo.friendlyDioError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = _normalizePhone(phoneController.text);
    final canContinue = !_loading &&
        selectedCountryId != null &&
        digits.length == maxPhoneDigits;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ===== Illustration =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: 
                SizedBox(
  height: 519, // خليها مثل ما هي (أو خفف/زود شوي لاحقًا)
  child: Align(
    alignment: const Alignment(0, 0.55), // نزّل الصورة لتحت
    child: Transform.scale(
      scale: 1.12, // كبّرها
      child: Image.asset(
        _illustrationAsset,
        fit: BoxFit.contain,
      ),
    ),
  ),
),

              ),


              const SizedBox(height: 12),
              

              

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
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        const Text(
                          "Let's Get Started",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Continue with your phone number to access\nyour personalized Himma experience.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.4,
                            color: Color(0xFF6B7280),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Country selector (styled)
                        InkWell(
                          onTap: _loading ? null : openCountries,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedCountryName,
                                    style: TextStyle(
                                      color: selectedCountryId == null
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF111827),
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Phone input (styled)
                        Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              if (selectedDialCode != null) ...[
                                Text(
                                  '+$selectedDialCode ',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                              Expanded(
                                child: TextField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(maxPhoneDigits),
                                  ],
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Phone number',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onChanged: (_) {
                                    if (_error != null) setState(() => _error = null);
                                    _stripAnyDialCodeFromControllerEnsureMax(
                                      oldDialCode: selectedDialCode,
                                    );
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Continue button (styled)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: canContinue ? requestOtp : null,
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
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'By continue, you agree to Terms of Use and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF6B7280),
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
