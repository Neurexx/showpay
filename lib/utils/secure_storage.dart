import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:showpay/utils/constants.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> storeToken(String token) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
  }

  static Future<void> storeUserData(String userData) async {
    await _storage.write(key: AppConstants.userDataKey, value: userData);
  }

  static Future<String?> getUserData() async {
    return await _storage.read(key: AppConstants.userDataKey);
  }

  static Future<void> deleteUserData() async {
    await _storage.delete(key: AppConstants.userDataKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}