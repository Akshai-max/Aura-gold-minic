class AndroidAppRelease {
  final String versionName;
  final int versionCode;
  final String apkUrl;
  final String releaseNotes;
  final bool forceUpdate;

  const AndroidAppRelease({
    required this.versionName,
    required this.versionCode,
    required this.apkUrl,
    this.releaseNotes = '',
    this.forceUpdate = false,
  });

  factory AndroidAppRelease.fromJson(Map<String, dynamic> json) {
    return AndroidAppRelease(
      versionName: json['version_name'] as String? ?? '0.0.0',
      versionCode: (json['version_code'] as num?)?.toInt() ?? 0,
      apkUrl: json['apk_url'] as String? ?? '',
      releaseNotes: json['release_notes'] as String? ?? '',
      forceUpdate: json['force_update'] as bool? ?? false,
    );
  }
}
