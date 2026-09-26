/// In-memory session state model storing authenticated user details.
class UserSession {
  static final UserSession _instance = UserSession._internal();

  factory UserSession() {
    return _instance;
  }

  UserSession._internal();

  String? _userId;
  String? _role;
  String? _name;
  String? _email;

  String? get userId => _userId;
  String? get role => _role;
  String? get name => _name;
  String? get email => _email;

  bool get isLoggedIn => _userId != null && _userId!.isNotEmpty;

  void setSession({
    required String userId,
    required String role,
    String? name,
    String? email,
  }) {
    _userId = userId;
    _role = role;
    _name = name;
    _email = email;
  }

  void clearSession() {
    _userId = null;
    _role = null;
    _name = null;
    _email = null;
  }
}
