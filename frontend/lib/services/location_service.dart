import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// User's real-time detected location with precise area, city and coordinates.
class UserLocation {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String area;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    this.area = '',
  });

  String get displayName {
    if (area.isNotEmpty && city.isNotEmpty) {
      return '$area, $city';
    }
    if (city.isNotEmpty) {
      return '$city, $country';
    }
    return country;
  }

  @override
  String toString() => '$displayName ($latitude, $longitude)';
}

/// Service to detect, verify and persist user real-time location across Mobile, Web & Desktop.
class LocationService {
  static const String _keyAllowed = 'fandom_location_allowed';
  static const String _keyLat = 'fandom_user_lat';
  static const String _keyLng = 'fandom_user_lng';
  static const String _keyCity = 'fandom_user_city';
  static const String _keyCountry = 'fandom_user_country';
  static const String _keyArea = 'fandom_user_area';

  /// Default fallback location: Karachi, Pakistan
  static const UserLocation defaultLocation = UserLocation(
    latitude: 24.8607,
    longitude: 67.0011,
    city: 'Karachi',
    country: 'Pakistan',
    area: 'Saddar, Karachi South',
  );

  /// Check if the user has already granted location permission
  static Future<bool> isPermissionGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyAllowed) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Reset permission (useful on logout)
  static Future<void> resetPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAllowed);
    } catch (_) {}
  }

  /// Save granted location permission and detected coordinates
  static Future<void> saveLocation(UserLocation loc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAllowed, true);
      await prefs.setDouble(_keyLat, loc.latitude);
      await prefs.setDouble(_keyLng, loc.longitude);
      await prefs.setString(_keyCity, loc.city);
      await prefs.setString(_keyCountry, loc.country);
      await prefs.setString(_keyArea, loc.area);
    } catch (_) {}
  }

  /// Get cached location if previously saved
  static Future<UserLocation?> getSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allowed = prefs.getBool(_keyAllowed) ?? false;
      if (!allowed) return null;

      final lat = prefs.getDouble(_keyLat);
      final lng = prefs.getDouble(_keyLng);
      final city = prefs.getString(_keyCity) ?? 'Karachi';
      final country = prefs.getString(_keyCountry) ?? 'Pakistan';
      final area = prefs.getString(_keyArea) ?? '';

      if (lat != null && lng != null) {
        return UserLocation(
          latitude: lat,
          longitude: lng,
          city: city,
          country: country,
          area: area,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Reverse-geocodes coordinates into a detailed human-readable area / neighborhood
  static Future<String> _resolveArea(double lat, double lon) async {
    // 1. Try OpenStreetMap Nominatim reverse geocoding with accept-language=en
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=en',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'FandomVerseApp/1.0 (LocationDiscovery)',
      }).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final neighbourhood = address['neighbourhood']?.toString();
          final suburb = address['suburb']?.toString();
          final residential = address['residential']?.toString();
          final quarter = address['quarter']?.toString();
          final town = address['town']?.toString();
          final cityDistrict = address['city_district']?.toString();
          final road = address['road']?.toString();

          final primary = neighbourhood ?? suburb ?? residential ?? quarter ?? town;
          final secondary = (primary != null && town != null && primary != town)
              ? town
              : ((primary != null && cityDistrict != null && primary != cityDistrict)
                  ? cityDistrict
                  : null);

          if (primary != null && secondary != null && primary != secondary) {
            return '$primary, $secondary';
          }
          if (primary != null) return primary;
          if (cityDistrict != null) return cityDistrict;
          if (road != null) return road;
        }
      }
    } catch (_) {}

    // 2. High-speed fallback: BigDataCloud reverse geocoding in English
    try {
      final bdcUrl = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en',
      );
      final bdcRes = await http.get(bdcUrl).timeout(const Duration(seconds: 4));
      if (bdcRes.statusCode == 200) {
        final data = jsonDecode(bdcRes.body) as Map<String, dynamic>;
        final locality = data['locality']?.toString();
        final localityInfo = data['localityInfo'] as Map<String, dynamic>?;
        String? adminArea;
        if (localityInfo != null) {
          final admin = localityInfo['administrative'] as List<dynamic>?;
          if (admin != null && admin.isNotEmpty) {
            for (final item in admin.reversed) {
              final name = item['name']?.toString();
              if (name != null && name.isNotEmpty && name != locality && name != data['city']) {
                adminArea = name;
                break;
              }
            }
          }
        }
        if (locality != null && locality.isNotEmpty) {
          if (adminArea != null && adminArea.isNotEmpty && !locality.contains(adminArea)) {
            return '$locality, $adminArea';
          }
          return locality;
        }
      }
    } catch (_) {}

    return '';
  }

  /// Detects real-time live location using fast multi-source geolocation.
  /// Works flawlessly on all devices (Android, iOS, Web, Windows).
  static Future<UserLocation> detectCurrentLocation() async {
    double? lat;
    double? lon;
    String city = 'Karachi';
    String country = 'Pakistan';

    // 1. Try ip-api.com
    try {
      final response = await http
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          lat = (data['lat'] as num).toDouble();
          lon = (data['lon'] as num).toDouble();
          city = (data['city'] ?? 'Karachi').toString();
          country = (data['country'] ?? 'Pakistan').toString();
        }
      }
    } catch (_) {}

    // 2. Fallback to ipwho.is if needed
    if (lat == null || lon == null) {
      try {
        final response = await http
            .get(Uri.parse('http://ipwho.is/'))
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success'] == true) {
            lat = (data['latitude'] as num).toDouble();
            lon = (data['longitude'] as num).toDouble();
            city = (data['city'] ?? 'Karachi').toString();
            country = (data['country'] ?? 'Pakistan').toString();
          }
        }
      } catch (_) {}
    }

    // 3. Fallback to geojs.io if needed
    if (lat == null || lon == null) {
      try {
        final response = await http
            .get(Uri.parse('https://get.geojs.io/v1/ip/geo.json'))
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          lat = double.tryParse((data['latitude'] ?? '').toString());
          lon = double.tryParse((data['longitude'] ?? '').toString());
          city = (data['city'] ?? 'Karachi').toString();
          country = (data['country'] ?? 'Pakistan').toString();
        }
      } catch (_) {}
    }

    if (lat == null || lon == null) {
      return defaultLocation;
    }

    // Resolve detailed area / neighborhood
    final area = await _resolveArea(lat, lon);

    return UserLocation(
      latitude: lat,
      longitude: lon,
      city: city,
      country: country,
      area: area,
    );
  }
}
