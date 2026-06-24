import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String apkUrl;
  final String ipaUrl;
  final String changelog;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    required this.ipaUrl,
    required this.changelog,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] ?? '1.0.0',
      buildNumber: json['build_number'] ?? 0,
      apkUrl: json['apk_url'] ?? '',
      ipaUrl: json['ipa_url'] ?? '',
      changelog: json['changelog'] ?? '',
    );
  }
}

class UpdateCheckerService {
  static const String _updateUrl =
      'https://raw.githubusercontent.com/bbjbvkhb-ship-it/m/main/version.json';

  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      final response = await http.get(Uri.parse(_updateUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to fetch update info: Status code ${response.statusCode}');
        return null;
      }

      final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      final remoteUpdate = UpdateInfo.fromJson(data);

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      final isNewer = _isNewerVersion(currentVersion, remoteUpdate.version) ||
          (remoteUpdate.buildNumber > currentBuildNumber);

      if (isNewer) {
        return remoteUpdate;
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
    return null;
  }

  static bool _isNewerVersion(String current, String remote) {
    try {
      List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> remoteParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      int maxLen = currentParts.length > remoteParts.length ? currentParts.length : remoteParts.length;
      while (currentParts.length < maxLen) {
        currentParts.add(0);
      }
      while (remoteParts.length < maxLen) {
        remoteParts.add(0);
      }

      for (int i = 0; i < maxLen; i++) {
        if (remoteParts[i] > currentParts[i]) return true;
        if (remoteParts[i] < currentParts[i]) return false;
      }
    } catch (e) {
      debugPrint('Error parsing version: $e');
    }
    return false;
  }
}
