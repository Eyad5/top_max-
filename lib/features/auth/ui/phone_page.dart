import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:country_flags/country_flags.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? selectedCountryIso;

  static const int maxPhoneDigits = 9;

  bool _loading = false;
  String? _error;

  // ===== Countries cache/offline =====
  static const String _countriesCacheKey = 'countries_cache_v1';
  List<Map<String, dynamic>> _countries = [];
  bool _countriesLoading = false;

  late final AuthRepo _repo = AuthRepo(
    api: AuthApi(DioClient.dio),
    tokenStorage: DioClient.tokenStorage,
  );

  static const String _illustrationAsset =
      'lib/app/assets/images/illustration.png';

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  /// PRODUCTION-GRADE country loading with multi-tier fallback
  Future<void> _loadCountries({int retryCount = 0}) async {
    setState(() => _countriesLoading = true);

    // TIER 1: Load from bundled assets (ultimate fallback - always works)
    if (_countries.isEmpty) {
      try {
        debugPrint('📦 [TIER 1] Loading countries from bundled assets...');
        final String jsonString = await rootBundle.loadString('assets/countries.json');
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final List<Map<String, dynamic>> assetCountries = jsonList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        setState(() {
          _countries = assetCountries;
        });
        debugPrint('✓ [TIER 1] Loaded ${_countries.length} countries from assets (FALLBACK)');
      } catch (e) {
        debugPrint('✗ [TIER 1] Asset loading failed: $e');
      }
    }

    // TIER 2: Load from cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_countriesCacheKey);
      if (cached != null && cached.isNotEmpty) {
        final decoded = (jsonDecode(cached) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        // Only update if cache has more/different data
        if (decoded.length >= _countries.length) {
          setState(() {
            _countries = decoded;
          });
          debugPrint('✓ [TIER 2] Loaded ${_countries.length} countries from cache');
        }
      }
    } catch (e) {
      debugPrint('✗ [TIER 2] Cache read error: $e');
    }

    // TIER 3: Check connectivity
    bool hasConnectivity = false;
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      hasConnectivity = connectivityResults.any((result) => result != ConnectivityResult.none);
      debugPrint('🌐 [TIER 3] Connectivity check: ${hasConnectivity ? "CONNECTED" : "NO CONNECTION"}');
    } catch (e) {
      debugPrint('✗ [TIER 3] Connectivity check failed: $e');
    }

    if (!hasConnectivity) {
      debugPrint('⚠️ No network connectivity. Using existing ${_countries.length} countries.');
      setState(() {
        _countriesLoading = false;
        if (_countries.isEmpty) {
          _error = 'No internet connection. Using offline data.';
        }
      });
      return;
    }

    // TIER 4: Reachability check (can we reach the specific host?)
    bool isReachable = false;
    try {
      debugPrint('🔍 [TIER 4] Checking reachability to flutter.topmax.ae...');
      final lookup = await InternetAddress.lookup('flutter.topmax.ae').timeout(
        const Duration(seconds: 5),
      );
      isReachable = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
      debugPrint('✓ [TIER 4] Host reachable: $isReachable (IP: ${lookup.isNotEmpty ? lookup[0].address : "N/A"})');
    } catch (e) {
      debugPrint('✗ [TIER 4] Reachability check failed: $e');
      debugPrint('[COUNTRIES_ERROR_TYPE]: DNS - Cannot resolve flutter.topmax.ae');
    }

    if (!isReachable) {
      debugPrint('⚠️ Host unreachable. Using existing ${_countries.length} countries.');
      setState(() {
        _countriesLoading = false;
        if (_countries.isEmpty) {
          _error = 'Cannot reach server. Using offline data.';
        }
      });
      return;
    }

    // TIER 5: Fetch from API with exponential backoff retry
    try {
      debugPrint('🌍 [TIER 5] Fetching countries from API (attempt ${retryCount + 1}/3)...');

      final res = await DioClient.dio.get(
        'location/countries',
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Countries fetch timed out after 20s');
        },
      );

      final list = (res.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        _countries = list;
        _error = null; // Clear any previous errors
      });

      debugPrint('✅ [TIER 5] Loaded ${list.length} countries from API');

      // Save to cache for next time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_countriesCacheKey, jsonEncode(list));
      debugPrint('✓ Saved countries to cache');
    } on DioException catch (e) {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('✗ [TIER 5] DioException Details:');
      debugPrint('  Type: ${e.type}');
      debugPrint('  Message: ${e.message}');
      debugPrint('  Error: ${e.error}');
      debugPrint('  Status Code: ${e.response?.statusCode}');
      debugPrint('  URL: ${e.requestOptions.uri}');
      debugPrint('═══════════════════════════════════════════════════════════');

      // Retry with exponential backoff (0.5s, 1s, 2s)
      if (retryCount < 2) {
        final delay = Duration(milliseconds: 500 * (1 << retryCount)); // 500ms, 1s, 2s
        debugPrint('⏳ Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        if (mounted) {
          return _loadCountries(retryCount: retryCount + 1);
        }
      }

      // After all retries, user has fallback data so don't show error
      debugPrint('⚠️ API failed after ${retryCount + 1} attempts. Using ${_countries.length} fallback countries.');
    } catch (e) {
      debugPrint('✗ [TIER 5] Unknown error: $e');
    } finally {
      if (mounted) {
        setState(() => _countriesLoading = false);
      }
    }
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

    // If countries list is empty (should never happen with fallback assets)
    if (_countries.isEmpty) {
      if (!_countriesLoading) {
        debugPrint('⚠️ Countries empty (unexpected), loading with fallback...');
        await _loadCountries();
      } else {
        // Wait for loading to complete
        debugPrint('⏳ Waiting for countries to load...');
        while (_countriesLoading && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    }

    // With bundled assets fallback, we should ALWAYS have countries
    if (_countries.isEmpty) {
      setState(() => _error = 'Critical error: Unable to load country data. Please restart the app.');
      return;
    }

    // Check mounted before showing dialog
    if (!mounted) return;

    // Show compact dropdown menu (not full screen)
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (BuildContext context) {
        return Dialog(
          alignment: Alignment.centerLeft,
          insetPadding: const EdgeInsets.only(left: 24, right: 240, top: 150, bottom: 150),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 320,
              maxWidth: 140,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              itemCount: _countries.length,
              itemBuilder: (_, i) {
                final c = _countries[i];
                return InkWell(
                  onTap: () {
                    final old = selectedDialCode;

                    // Normalize dial code: remove leading '+' if present
                    final rawCode = c['code']?.toString() ?? '';
                    final normalizedCode = rawCode.startsWith('+') ? rawCode.substring(1) : rawCode;

                    setState(() {
                      selectedCountryId = (c['id'] as num).toInt();
                      selectedCountryName = c['name'].toString();
                      selectedDialCode = normalizedCode;
                      selectedCountryIso = c['iso']?.toString();
                      _error = null;
                    });

                    _stripAnyDialCodeFromControllerEnsureMax(oldDialCode: old);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        // Flag
                        CountryFlag.fromCountryCode(
                          c['iso'].toString(),
                          height: 18,
                          width: 26,
                          borderRadius: 3,
                        ),
                        const SizedBox(width: 10),
                        // Country code with + prefix
                        Text(
                          '+${c['code']?.toString().replaceAll('+', '') ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
      // Check internet connectivity first
      final connectivityResults = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResults.any((result) => result != ConnectivityResult.none);

      if (!hasConnection) {
        setState(() => _error = 'No internet connection. Please check your connection and try again.');
        return;
      }

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
    } on SocketException catch (_) {
      setState(() => _error = 'Unable to connect to the server. Please try again.');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        setState(() => _error = 'Unable to connect to the server. Please try again.');
      } else {
        setState(() => _error = AuthRepo.friendlyDioError(e));
      }
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('failed host lookup') ||
          errorString.contains('socketexception') ||
          errorString.contains('timeout')) {
        setState(() => _error = 'Unable to connect to the server. Please try again.');
      } else {
        setState(() => _error = AuthRepo.friendlyDioError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = _normalizePhone(phoneController.text);

    final canContinue = !_loading &&
        !_countriesLoading &&
        selectedCountryId != null &&
        digits.length == maxPhoneDigits;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;

            // Responsive illustration height
            final illustrationHeight = (screenHeight * 0.55).clamp(300.0, 550.0);

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // ===== Illustration =====
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: SizedBox(
                          height: illustrationHeight,
                          child: Align(
                            alignment: const Alignment(0, 0.55),
                            child: Transform.scale(
                              scale: 1.12,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.048,
                        ),
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
                              mainAxisSize: MainAxisSize.min,
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

                                // Phone input with integrated country selector on the left
                                Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                    borderRadius: BorderRadius.circular(14),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      // Country selector button (left side inside input)
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _loading ? null : openCountries,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(14),
                                            bottomLeft: Radius.circular(14),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (_countriesLoading && _countries.isEmpty)
                                                  const SizedBox(
                                                    height: 18,
                                                    width: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                else if (selectedDialCode != null && selectedCountryIso != null) ...[
                                                  // Real country flag
                                                  CountryFlag.fromCountryCode(
                                                    selectedCountryIso!,
                                                    height: 18,
                                                    width: 28,
                                                    borderRadius: 3,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '+$selectedDialCode',
                                                    style: const TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFF111827),
                                                    ),
                                                  ),
                                                ] else ...[
                                                  const Icon(
                                                    Icons.public,
                                                    size: 20,
                                                    color: Color(0xFF9CA3AF),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Text(
                                                    '+00',
                                                    style: TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFF9CA3AF),
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.keyboard_arrow_down_rounded,
                                                  size: 20,
                                                  color: _loading
                                                      ? const Color(0xFF9CA3AF)
                                                      : const Color(0xFF111827),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Vertical divider
                                      Container(
                                        width: 1,
                                        height: 32,
                                        color: const Color(0xFFE5E7EB),
                                      ),

                                      // Phone number input
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          child: TextField(
                                            controller: phoneController,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                              LengthLimitingTextInputFormatter(maxPhoneDigits),
                                            ],
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: phoneController.text.isEmpty ? '* * * * * * *' : '',
                                              hintStyle: const TextStyle(
                                                color: Color(0xFFD1D5DB),
                                                fontWeight: FontWeight.w400,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF111827),
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

                                // Continue button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: canContinue ? requestOtp : null,
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
          },
        ),
      ),
    );
  }
}
