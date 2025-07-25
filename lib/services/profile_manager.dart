// lib/services/profile_manager.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:seg_medico/models/models.dart'; // Assicurati che il percorso sia corretto

class ProfileManager {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _profilesKey = 'user_profiles'; // Corretto: rimosso backslash
  static const String _defaultProfileKey = 'default_profile_name'; // Corretto: rimosso backslash

  Future<List<Profile>> getProfiles() async { // Corretto: rimossi backslash
    try {
      final String? profilesJson = await _secureStorage.read(key: _profilesKey);
      if (profilesJson != null) {
        final List<dynamic> jsonList = json.decode(profilesJson);
        return jsonList.map((json) => Profile.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting profiles: $e');
      return [];
    }
  }

  Future<void> saveProfiles(List<Profile> profiles) async { // Corretto: rimossi backslash
    try {
      final String profilesJson = json.encode(profiles.map((p) => p.toJson()).toList());
      await _secureStorage.write(key: _profilesKey, value: profilesJson);
    } catch (e) {
      print('Error saving profiles: $e');
    }
  }

  Future<void> addProfile(Profile profile) async { // Corretto: rimossi backslash
    List<Profile> profiles = await getProfiles();
    // Evita duplicati basandosi sul codFis
    profiles.removeWhere((p) => p.codFis == profile.codFis);
    profiles.add(profile);
    await saveProfiles(profiles);
  }

  Future<void> updateProfile(Profile updatedProfile) async { // Corretto: rimossi backslash
    List<Profile> profiles = await getProfiles();
    int index = profiles.indexWhere((p) => p.codFis == updatedProfile.codFis);
    if (index != -1) {
      profiles[index] = updatedProfile;
      await saveProfiles(profiles);
    }
  }

  Future<void> deleteProfile(String codFis) async { // Corretto: rimossi backslash
    List<Profile> profiles = await getProfiles();
    profiles.removeWhere((p) => p.codFis == codFis);
    await saveProfiles(profiles);
    // Se il profilo cancellato era quello di default, pulisci la chiave di default
    final String? defaultProfileName = await _secureStorage.read(key: _defaultProfileKey);
    if (defaultProfileName == codFis) { // Se il codFis è stato usato come nome
      await clearDefaultProfile();
    }
  }

  Future<Profile?> getDefaultProfile() async { // Corretto: rimossi backslash
    try {
      final String? defaultProfileName = await _secureStorage.read(key: _defaultProfileKey);
      if (defaultProfileName != null) {
        List<Profile> profiles = await getProfiles();
        return profiles.firstWhere((p) => p.name == defaultProfileName || p.codFis == defaultProfileName);
      }
      return null;
    } catch (e) {
      print('Error getting default profile: $e');
      return null;
    }
  }

  Future<void> setDefaultProfile(String profileName) async { // Corretto: rimossi backslash
    await _secureStorage.write(key: _defaultProfileKey, value: profileName);
  }

  Future<void> clearDefaultProfile() async { // Corretto: rimossi backslash
    await _secureStorage.delete(key: _defaultProfileKey);
  }
}