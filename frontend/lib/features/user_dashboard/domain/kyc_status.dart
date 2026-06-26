class KycGovernmentProfile {
  final String? fullName;
  final String? dateOfBirth;
  final String? gender;
  final String? careOf;
  final String? fullAddress;
  final String? state;
  final String? district;
  final String? pincode;
  final String? aadhaarLast4;
  final String? aadhaarLinkedMobileMasked;
  final String? panNumberMasked;
  final String? panCategory;
  final String? panStatus;
  final bool? nameAsPerPanMatch;
  final bool? dateOfBirthMatch;
  final String? aadhaarSeedingStatus;
  final String? verifiedAt;

  const KycGovernmentProfile({
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.careOf,
    this.fullAddress,
    this.state,
    this.district,
    this.pincode,
    this.aadhaarLast4,
    this.aadhaarLinkedMobileMasked,
    this.panNumberMasked,
    this.panCategory,
    this.panStatus,
    this.nameAsPerPanMatch,
    this.dateOfBirthMatch,
    this.aadhaarSeedingStatus,
    this.verifiedAt,
  });

  factory KycGovernmentProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const KycGovernmentProfile();
    return KycGovernmentProfile(
      fullName: json['full_name'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      careOf: json['care_of'] as String?,
      fullAddress: json['full_address'] as String?,
      state: json['state'] as String?,
      district: json['district'] as String?,
      pincode: json['pincode'] as String?,
      aadhaarLast4: json['aadhaar_last4'] as String?,
      aadhaarLinkedMobileMasked:
          json['aadhaar_linked_mobile_masked'] as String?,
      panNumberMasked: json['pan_number_masked'] as String?,
      panCategory: json['pan_category'] as String?,
      panStatus: json['pan_status'] as String?,
      nameAsPerPanMatch: json['name_as_per_pan_match'] as bool?,
      dateOfBirthMatch: json['date_of_birth_match'] as bool?,
      aadhaarSeedingStatus: json['aadhaar_seeding_status'] as String?,
      verifiedAt: json['verified_at'] as String?,
    );
  }

  bool get hasIdentity => fullName != null && fullName!.isNotEmpty;

  bool get hasAadhaarMobile =>
      aadhaarLinkedMobileMasked != null &&
      aadhaarLinkedMobileMasked!.isNotEmpty;
}

enum KycStatus {
  notStarted('not_started'),
  aadhaarVerified('aadhaar_verified'),
  pending('pending'),
  verified('verified'),
  rejected('rejected');

  final String value;
  const KycStatus(this.value);

  static KycStatus fromValue(String? raw) {
    return KycStatus.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => KycStatus.notStarted,
    );
  }

  bool get needsAction =>
      this == KycStatus.notStarted ||
      this == KycStatus.rejected ||
      this == KycStatus.aadhaarVerified;

  bool get isComplete => this == KycStatus.verified;

  bool get aadhaarComplete =>
      this == KycStatus.aadhaarVerified || this == KycStatus.verified;
}

class KycStatusDetails {
  final KycStatus status;
  final String? aadhaarLast4;
  final String? panLast4;
  final String? registeredMobileMasked;
  final String? message;
  final KycGovernmentProfile? profile;

  const KycStatusDetails({
    required this.status,
    this.aadhaarLast4,
    this.panLast4,
    this.registeredMobileMasked,
    this.message,
    this.profile,
  });

  factory KycStatusDetails.fromJson(Map<String, dynamic> json) {
    return KycStatusDetails(
      status: KycStatus.fromValue(json['kyc_status'] as String?),
      aadhaarLast4: json['aadhaar_last4'] as String?,
      panLast4: json['pan_last4'] as String?,
      registeredMobileMasked: json['registered_mobile_masked'] as String?,
      message: json['message'] as String?,
      profile: KycGovernmentProfile.fromJson(
        json['profile'] as Map<String, dynamic>?,
      ),
    );
  }
}
