import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { ro, en }

/// Țara selectată de utilizator controlează atât limba interfeței cât și
/// denumirile documentelor (RCA/CASCO/ITP/Rovinietă pentru România, sau
/// denumiri generice în engleză pentru restul lumii). România păstrează
/// exact comportamentul original al aplicației.
class RegionService {
  RegionService._internal();
  static final RegionService instance = RegionService._internal();

  static const _prefsKey = 'country_code';
  static const defaultCountryCode = 'RO';

  final ValueNotifier<String> countryCode = ValueNotifier<String>(defaultCountryCode);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    countryCode.value = prefs.getString(_prefsKey) ?? defaultCountryCode;
  }

  Future<void> setCountryCode(String code) async {
    countryCode.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }

  bool get isRomania => countryCode.value == 'RO';

  AppLanguage get language => isRomania ? AppLanguage.ro : AppLanguage.en;
}
