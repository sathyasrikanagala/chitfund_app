class SessionManager {
  static final SessionManager instance = SessionManager._internal();
  SessionManager._internal();

  Map<String, dynamic>? currentUser;

  bool get isLoggedIn => currentUser != null;

  String get role => (currentUser?['role'] ?? 'guest').toLowerCase();
  String get fullName => currentUser?['full_name'] ?? 'Guest';
  String? get memberId => currentUser?['member_id'];

  bool get isAgent => role == 'agent';
  bool get isMember => role == 'member';

  // Permissions — Agent has full control, Member has read-only self-service access
  bool get canManageGroups => isAgent;
  bool get canManageMembers => isAgent;
  bool get canCollectPayments => isAgent;
  bool get canRecordPrizes => isAgent;
  bool get canAccessSettings => isAgent;
  bool get canDeleteRecords => isAgent;
  bool get canApproveJoinRequests => isAgent;

  void login(Map<String, dynamic> user) {
    currentUser = user;
  }

  void logout() {
    currentUser = null;
  }
}