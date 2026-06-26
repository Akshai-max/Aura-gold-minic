/// Whether the person using the app is a standard end-user or staff/admin.
enum AppAudience {
  endUser,
  staffAdmin,
}

extension AppAudienceLabel on AppAudience {
  String get displayName => switch (this) {
    AppAudience.endUser => 'User',
    AppAudience.staffAdmin => 'Staff / Admin',
  };
}
