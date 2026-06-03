class Permissions {
  const Permissions._();

  static const userCreate = 'user.create';
  static const userRead = 'user.read';
  static const userUpdate = 'user.update';
  static const userDelete = 'user.delete';
  static const roleManage = 'role.manage';
  static const settingsManage = 'settings.manage';
  static const auditRead = 'audit.read';
  static const dashboardRead = 'dashboard.read';
  static const profileManage = 'profile.manage';
  static const reportRead = 'report.read';
  static const analyticsRead = 'analytics.read';
}

class AppRoles {
  const AppRoles._();

  static const admin = 'ADMIN';
  static const shareholder = 'SHAREHOLDER';
  static const user = 'USER';
}
