import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../features/alerts/domain/entities/user_preferences.dart';

@lazySingleton
class SharedPrefsService {
  late SharedPreferences _prefs;

  @factoryMethod
  static Future<SharedPrefsService> create() async {
    final service = SharedPrefsService();
    service._prefs = await SharedPreferences.getInstance();
    return service;
  }

  bool get onboardingComplete =>
      _prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;

  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool(AppConstants.keyOnboardingComplete, value);

  UserPreferences getPreferences() {
    final json = _prefs.getString('user_preferences');
    if (json == null) return const UserPreferences();
    return UserPreferences.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> savePreferences(UserPreferences prefs) =>
      _prefs.setString('user_preferences', jsonEncode(prefs.toJson()));

  bool get isDarkMode => _prefs.getBool(AppConstants.keyDarkMode) ?? false;
  Future<void> setDarkMode(bool value) =>
      _prefs.setBool(AppConstants.keyDarkMode, value);
}
