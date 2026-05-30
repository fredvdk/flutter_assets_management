import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _userNameKey = 'user_name';
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? getCurrentUser() {
    return _prefs.getString(_userNameKey);
  }

  Future<void> setCurrentUser(String userName) async {
    await _prefs.setString(_userNameKey, userName);
  }

  Future<void> logout() async {
    await _prefs.remove(_userNameKey);
  }

  bool isLoggedIn() {
    return getCurrentUser() != null;
  }
}
