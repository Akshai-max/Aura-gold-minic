import 'package:ags_gold/features/profile/domain/profile.dart';

/// Returns true when [profile] has [permission] or a matching wildcard.
bool hasPermission(UserProfile profile, String permission) {
  if (profile.isSuperuser) return true;

  final perms = profile.effectivePermissions;
  if (perms.contains('*')) return true;
  if (perms.contains(permission)) return true;

  final dotPrefix = permission.contains('.')
      ? permission.split('.').first
      : permission.split(':').first;
  if (perms.contains('$dotPrefix.*') || perms.contains('$dotPrefix:*')) {
    return true;
  }

  return false;
}
