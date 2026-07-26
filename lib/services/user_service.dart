import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService extends ChangeNotifier {
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
    notifyListeners();
  }

  Future<void> logout() async {
    await _prefs.remove(_userNameKey);
    notifyListeners();
  }

  bool isLoggedIn() {
    return getCurrentUser() != null;
  }
}
