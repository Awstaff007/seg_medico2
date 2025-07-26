import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:seg_medico/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileManager {
  static const _profilesKey = 'user_profiles';
  static const _defaultProfileKey = 'default_profile_id';
  static const _settingsKey = 'app_settings';
  
  late SharedPreferences _prefs;
  final _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Gestione Profili ---

  List<Profile> getProfiles() {
    final profilesJson = _prefs.getStringList(_profilesKey) ?? [];
    return profilesJson.map((jsonString) => Profile.fromJson(jsonDecode(jsonString))).toList();
  }

  Future<void> saveProfile(Profile profile) async {
    final profiles = getProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      profiles[index] = profile; // Aggiorna
    } else {
      profiles.add(profile); // Aggiungi
    }
    await _saveProfilesList(profiles);
  }

  Future<void> deleteProfile(String profileId) async {
    final profiles = getProfiles();
    profiles.removeWhere((p) => p.id == profileId);
    await _saveProfilesList(profiles);
    await deleteToken(profileId); // Rimuovi anche il token associato
    if (await getDefaultProfileId() == profileId) {
      await _prefs.remove(_defaultProfileKey);
    }
  }

  Future<void> _saveProfilesList(List<Profile> profiles) async {
    final profilesJson = profiles.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList(_profilesKey, profilesJson);
  }

  Future<Profile?> getProfile(String profileId) async {
    final profiles = getProfiles();
    try {
      return profiles.firstWhere((p) => p.id == profileId);
    } catch (e) {
      return null;
    }
  }

  // --- Profilo di Default ---
  
  Future<String?> getDefaultProfileId() async {
    return _prefs.getString(_defaultProfileKey);
  }

  Future<void> setDefaultProfile(String profileId) async {
    await _prefs.setString(_defaultProfileKey, profileId);
  }

  Future<Profile?> getDefaultProfile() async {
    final defaultId = await getDefaultProfileId();
    if (defaultId != null) {
      return getProfile(defaultId);
    }
    final allProfiles = getProfiles();
    if (allProfiles.isNotEmpty) {
      await setDefaultProfile(allProfiles.first.id);
      return allProfiles.first;
    }
    return null;
  }

  // --- Gestione Token ---

  Future<void> saveToken(String profileId, String token) async {
    await _secureStorage.write(key: 'auth_token_$profileId', value: token);
  }

  Future<String?> getToken(String profileId) async {
    return await _secureStorage.read(key: 'auth_token_$profileId');
  }

  Future<void> deleteToken(String profileId) async {
    await _secureStorage.delete(key: 'auth_token_$profileId');
  }

  // --- Gestione Impostazioni ---

  Future<void> saveSettings(Settings settings) async {
    final settingsJson = jsonEncode(settings.toJson());
    await _prefs.setString(_settingsKey, settingsJson);
  }

  Future<Settings> loadSettings() async {
    final settingsJson = _prefs.getString(_settingsKey);
    if (settingsJson != null) {
      return Settings.fromJson(jsonDecode(settingsJson));
    }
    return Settings(); // Ritorna impostazioni di default
  }
}
