class JobModel {
  final int id;
  final int? companyId;

  final String jobTitle;
  final String? jobDescription;

  // search
  final int? applicationsCount;
  final String? status;
  final String? createdAt;

  // home / details
  final num? minSalary;
  final num? maxSalary;
  final bool? salaryToBeDiscussed;
  final String? experienceLevel;
  final String? education;
  final String? jobType;
  final String? locationPriority;
  final String? officeLocation;
  final bool? isMultipleHires;
  final bool? isUrgent;
  final bool? isFeatured;

  // saved-items extra fields
  final String? companyName;
  final String? companyLogo;
  final bool isSaved;
  final String? activeSince;
  final String? formattedSalary;
  final String? appStatus;
  final String? type;

  // job-details extra fields
  final String? responsibilities;
  final String? requirements;
  final String? qualifications;
  final String? benefits;
  final int? yearsOfExperience;
  final bool? hasApplied;

  JobModel({
    required this.id,
    required this.jobTitle,
    this.companyId,
    this.jobDescription,
    this.applicationsCount,
    this.status,
    this.createdAt,
    this.minSalary,
    this.maxSalary,
    this.salaryToBeDiscussed,
    this.experienceLevel,
    this.education,
    this.jobType,
    this.locationPriority,
    this.officeLocation,
    this.isMultipleHires,
    this.isUrgent,
    this.isFeatured,
    this.companyName,
    this.companyLogo,
    required this.isSaved,
    this.activeSince,
    this.formattedSalary,
    this.appStatus,
    this.type,
    this.responsibilities,
    this.requirements,
    this.qualifications,
    this.benefits,
    this.yearsOfExperience,
    this.hasApplied,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    num? asNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }

    bool? asBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
      return null;
    }

    // Unwrap nested payloads (API may nest job data under 'job', 'opening', or 'item')
    final Map<String, dynamic> src =
        (json['job'] is Map) ? Map<String, dynamic>.from(json['job'] as Map)
        : (json['opening'] is Map) ? Map<String, dynamic>.from(json['opening'] as Map)
        : (json['item'] is Map) ? Map<String, dynamic>.from(json['item'] as Map)
        : json;

    // Preserve top-level fields that might not be in nested object
    if (src != json) {
      src['id'] ??= json['id'];
      src['is_saved'] ??= json['is_saved'];
      src['company_name'] ??= json['company_name'];
      src['company_logo'] ??= json['company_logo'];
    }

    // 🔍 TEMP DEBUG: Print shape for first few items
    final debugId = asInt(src['id'] ?? json['id']);
    if (debugId != null && debugId <= 3) {
      // ignore: avoid_print
      print('JOB SHAPE keys=${json.keys.toList()} | srcKeys=${src.keys.toList()} | rawMin=${src['min_salary']} rawMax=${src['max_salary']}');
    }

    // company can be nested object or flat fields
    String? companyName = src['company_name'] as String?;
    String? companyLogo = src['company_logo'] as String?;
    if (src['company'] is Map) {
      final company = Map<String, dynamic>.from(src['company'] as Map);
      companyName ??= company['name'] as String?;
      companyLogo ??= company['logo'] as String?;
    }

    // Parse salary fields with fallback for multiple naming conventions
    final parsedMinSalary = asNum(
      src['min_salary'] ??
      src['minSalary'] ??
      src['salary_min'] ??
      src['salaryMin']
    );
    final parsedMaxSalary = asNum(
      src['max_salary'] ??
      src['maxSalary'] ??
      src['salary_max'] ??
      src['salaryMax']
    );
    final parsedSalaryDiscussed = asBool(
      src['salary_to_be_discussed'] ??
      src['salaryToBeDiscussed'] ??
      src['to_be_discussed']
    );

    // Safely parse formatted_salary (handle non-string types from API)
    // Reject malformed template strings like "From AED  to  / month"
    String? parsedFormattedSalary;
    final rawFormatted = src['formatted_salary'];
    if (rawFormatted != null) {
      String str = '';
      if (rawFormatted is String && rawFormatted.isNotEmpty) {
        str = rawFormatted;
      } else {
        // API sent non-string type, convert it
        str = rawFormatted.toString().trim();
      }

      // ⚠️ VALIDATION: Only use if it contains at least one digit AND not a broken template
      // Valid: "From AED 5000 / month", "AED 3000-8000 / month"
      // Invalid: "From AED  to  / month" (missing numbers between placeholders)
      final hasDigits = str.contains(RegExp(r'\d'));
      final isBrokenTemplate = str.contains(RegExp(r'(AED\s+to\s+/)|(AED\s{2,})'));

      if (str.isNotEmpty && hasDigits && !isBrokenTemplate) {
        parsedFormattedSalary = str;
      } else if (isBrokenTemplate) {
        // Log malformed salary strings for debugging
        print('⚠️ JobModel #${asInt(src['id'] ?? json['id'])}: Rejected malformed formatted_salary: "$str"');
      }
    }

    return JobModel(
      id: asInt(src['id'] ?? json['id']) ?? 0,
      companyId: asInt(src['company_id']),
      jobTitle: (src['job_title'] ?? '') as String,
      jobDescription: src['job_description'] as String?,

      applicationsCount: asInt(src['applications_count']),
      status: src['status'] as String?,
      createdAt: src['created_at'] as String?,

      minSalary: parsedMinSalary,
      maxSalary: parsedMaxSalary,
      salaryToBeDiscussed: parsedSalaryDiscussed,
      experienceLevel: src['experience_level'] as String?,
      education: src['education'] as String?,
      jobType: src['job_type'] as String?,
      locationPriority: src['location_priority'] as String?,
      officeLocation: src['office_location'] as String?,
      isMultipleHires: asBool(src['is_multiple_hires']),
      isUrgent: asBool(src['is_urgent']),
      isFeatured: asBool(src['is_featured']),

      companyName: companyName,
      companyLogo: companyLogo,
      isSaved: asBool(json['is_saved'] ?? src['is_saved']) ?? false,
      activeSince: src['active_since'] as String?,
      formattedSalary: parsedFormattedSalary,
      appStatus: src['app_status'] as String?,
      type: src['type'] as String?,

      responsibilities: src['responsibilities'] as String?,
      requirements: src['requirements'] as String?,
      qualifications: src['qualifications'] as String?,
      benefits: src['benefits'] as String?,
      yearsOfExperience: asInt(src['years_of_experience']),
      hasApplied: asBool(src['has_applied']),
    );
  }

  JobModel copyWith({bool? isSaved}) {
    return JobModel(
      id: id,
      companyId: companyId,
      jobTitle: jobTitle,
      jobDescription: jobDescription,
      applicationsCount: applicationsCount,
      status: status,
      createdAt: createdAt,
      minSalary: minSalary,
      maxSalary: maxSalary,
      salaryToBeDiscussed: salaryToBeDiscussed,
      experienceLevel: experienceLevel,
      education: education,
      jobType: jobType,
      locationPriority: locationPriority,
      officeLocation: officeLocation,
      isMultipleHires: isMultipleHires,
      isUrgent: isUrgent,
      isFeatured: isFeatured,
      companyName: companyName,
      companyLogo: companyLogo,
      isSaved: isSaved ?? this.isSaved,
      activeSince: activeSince,
      formattedSalary: formattedSalary,
      appStatus: appStatus,
      type: type,
      responsibilities: responsibilities,
      requirements: requirements,
      qualifications: qualifications,
      benefits: benefits,
      yearsOfExperience: yearsOfExperience,
      hasApplied: hasApplied,
    );
  }

  JobModel copyWithSalary({
    num? minSalary,
    num? maxSalary,
    bool? salaryToBeDiscussed,
    String? formattedSalary,
  }) {
    return JobModel(
      id: id,
      companyId: companyId,
      jobTitle: jobTitle,
      jobDescription: jobDescription,
      applicationsCount: applicationsCount,
      status: status,
      createdAt: createdAt,
      minSalary: minSalary ?? this.minSalary,
      maxSalary: maxSalary ?? this.maxSalary,
      salaryToBeDiscussed: salaryToBeDiscussed ?? this.salaryToBeDiscussed,
      experienceLevel: experienceLevel,
      education: education,
      jobType: jobType,
      locationPriority: locationPriority,
      officeLocation: officeLocation,
      isMultipleHires: isMultipleHires,
      isUrgent: isUrgent,
      isFeatured: isFeatured,
      companyName: companyName,
      companyLogo: companyLogo,
      isSaved: isSaved,
      activeSince: activeSince,
      formattedSalary: formattedSalary ?? this.formattedSalary,
      appStatus: appStatus,
      type: type,
      responsibilities: responsibilities,
      requirements: requirements,
      qualifications: qualifications,
      benefits: benefits,
      yearsOfExperience: yearsOfExperience,
      hasApplied: hasApplied,
    );
  }

  // Format number with thousands separator (helper)
  static String _formatSalary(num salary) {
    final int amount = salary.toInt();
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join('');
  }

  /// Helper: Extract first number from salary text and format to "From AED X,XXX / month"
  static String _formatToFromSalary(String text) {
    // Extract first numeric value (with or without commas)
    final match = RegExp(r'\d[\d,]*').firstMatch(text);
    if (match == null) {
      return 'From AED 2,000 / month'; // Fallback if no number found
    }

    // Remove commas, parse to int, then re-format with commas
    final numStr = match.group(0)!.replaceAll(',', '');
    final amount = int.tryParse(numStr);
    if (amount == null || amount <= 0) {
      return 'From AED 2,000 / month';
    }

    return 'From AED ${_formatSalary(amount)} / month';
  }

  /// Returns computed salary display string, or null if salary data is missing
  /// Used by Salary Resolution Pipeline to determine if details fetch is needed
  String? get salaryDisplayResolved {
    String? result;

    // Priority 1: Use formatted_salary from API if available
    if (formattedSalary != null && formattedSalary!.isNotEmpty) {
      result = formattedSalary;
    }
    // Priority 2: Check salary_to_be_discussed flag
    else if (salaryToBeDiscussed == true) {
      result = 'Salary to be discussed';
    }
    // Priority 3: Compute from min_salary/max_salary
    else if (minSalary != null && minSalary! > 0 && maxSalary != null && maxSalary! > 0) {
      if (minSalary == maxSalary) {
        result = 'AED ${_formatSalary(minSalary!)} / month';
      } else {
        result = 'AED ${_formatSalary(minSalary!)}-${_formatSalary(maxSalary!)} / month';
      }
    }
    else if (minSalary != null && minSalary! > 0) {
      result = 'From AED ${_formatSalary(minSalary!)} / month';
    }
    else if (maxSalary != null && maxSalary! > 0) {
      result = 'Up to AED ${_formatSalary(maxSalary!)} / month';
    }

    // 💰 DEBUG: Log salary resolution for jobs with missing data
    if (result == null && (id <= 5 || id % 10 == 0)) {
      print('💰 Job #$id salary resolution:');
      print('   - formattedSalary: ${formattedSalary ?? "NULL"}');
      print('   - minSalary: ${minSalary ?? "NULL"}, maxSalary: ${maxSalary ?? "NULL"}');
      print('   - salaryToBeDiscussed: ${salaryToBeDiscussed ?? "NULL"}');
      print('   - RESULT: NULL (no valid salary data)');
    }

    // Return null to signal that salary data is missing (needs resolution)
    return result;
  }

  /// Backward compatible getter - always returns a string
  String get salaryDisplay => salaryDisplayResolved ?? 'Salary not specified';

  /// UI-only getter for Home page - always returns salary in "From AED X,XXX / month" format
  /// Extracts first number from API data or uses demo salary
  String get salaryDisplayForUi {
    // If API provides salary data, extract first number and format
    if (salaryDisplayResolved != null && salaryDisplayResolved!.isNotEmpty) {
      final resolved = salaryDisplayResolved!;

      // Ignore "Salary to be discussed" - treat as missing
      if (resolved.toLowerCase().contains('discussed')) {
        // Fall through to demo salary
      } else {
        // Extract first number and format
        return _formatToFromSalary(resolved);
      }
    }

    // Demo salary amounts (base numbers only, will be formatted)
    const demoAmounts = [2000, 5000, 15000, 3500, 8000, 12000, 4000, 10000];
    final amount = demoAmounts[id % demoAmounts.length];

    return 'From AED ${_formatSalary(amount)} / month';
  }
}
