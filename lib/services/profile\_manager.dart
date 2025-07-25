// lib/services/profile\_manager.dart

import 'dart:convert';
import 'package:flutter\_secure\_storage/flutter\_secure\_storage.dart';
import '../models/models.dart';

class ProfileManager {
final FlutterSecureStorage \_secureStorage = const FlutterSecureStorage();
static const String \_profilesKey = 'user\_profiles';
static const String \_defaultProfileKey = 'default\_profile\_name';

Future\<List\<Profile\>\> getProfiles() async {
final String? profilesJson = await \_secureStorage.read(key: \_profilesKey);
if (profilesJson \!= null) {
final List\<dynamic\> decoded = json.decode(profilesJson);
return decoded.map((e) =\> Profile.fromJson(e)).toList();
}
return [];
}

Future\<void\> saveProfiles(List\<Profile\> profiles) async {
final String encoded = json.encode(profiles.map((e) =\> e.toJson()).toList());
await \_secureStorage.write(key: \_profilesKey, value: encoded);
}

Future\<void\> addProfile(Profile profile) async {
List\<Profile\> profiles = await getProfiles();
profiles.add(profile);
await saveProfiles(profiles);
}

Future\<void\> updateProfile(Profile updatedProfile) async {
List\<Profile\> profiles = await getProfiles();
int index = profiles.indexWhere((p) =\> p.codFis == updatedProfile.codFis);
if (index \!= -1) {
profiles[index] = updatedProfile;
await saveProfiles(profiles);
}
}

Future\<void\> deleteProfile(String codFis) async {
List\<Profile\> profiles = await getProfiles();
profiles.removeWhere((p) =\> p.codFis == codFis);
await saveProfiles(profiles);
}

Future\<Profile?\> getDefaultProfile() async {
final String? defaultProfileName = await \_secureStorage.read(key: \_defaultProfileKey);
if (defaultProfileName \!= null) {
List\<Profile\> profiles = await getProfiles();
return profiles.firstWhere((p) =\> p.name == defaultProfileName, orElse: () =\> throw Exception('Default profile not found'));
}
return null;
}

Future\<void\> setDefaultProfile(String profileName) async {
await \_secureStorage.write(key: \_defaultProfileKey, value: profileName);
}

Future\<void\> clearDefaultProfile() async {
await \_secureStorage.delete(key: \_defaultProfileKey);
}
}