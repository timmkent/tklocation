// ignore_for_file: avoid_print

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tklocation/src/counter.dart';
import 'package:tklocation/src/date.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tklogger/tklogger.dart';
// Use Case 1:

// Location Service is enabled
// Permissions are granted
// Network and GPS is avaibale

class TKLocation {
  static final TKLocation _singleton = TKLocation._internal();
  TKLocation._internal();
  factory TKLocation() {
    return _singleton;
  }

  String _lastResult = "ERROR:Service not started up";
  String _city = "N/A";
  String _country = "N/A";

  SharedPreferences? shared;
  bool? _serviceEnabled;
  bool _debugMode = false;

  static enableDebugMode(bool debugOnOff) {
    _singleton._debugMode = debugOnOff;
  }

  static getLastResult() {
    return _singleton._lastResult;
  }

  static getCity() {
    return _singleton._city;
  }

  static getCountry() {
    return _singleton._country;
  }

// TODO: Log how long it took to get the location

  String? tkuuid;

  static initialize({required String appShort, required String? tkuuid, required String appVersion}) async {
    Logger.initialize(appName: appShort, apiKey: "3202151",  tkuuid: tkuuid ?? "unknown");
    _singleton.tkuuid = tkuuid;
    getUserLocation();
    _singleton.timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      getUserLocation();
    });
  }

  static String? _getCurrentUserId() {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        log("We have an authenticated user $uid.");
        return uid;
      } else {
        log("No user authenticated.");
        return null;
      }
    } catch (e) {
      _singleton._lastResult = "ERROR: Firebase not initialized";
      return null;
    }
  }

  Timer? timer;
  bool timerIsRunning = false;
  TKCoordinates? position;

// TODO: Get last known position from my own user profile
// TODO: Get City
// TODO: Write data to user profile.
// TODO: Send some message to potential observers that want to reload

  static Future<TKCoordinates?> getUserLocation() async {
    // How can we internally update the position but externally rapidly return something...?
    var position = await _determinePosition();
    final uid = _getCurrentUserId();
    if (position == null) {
      if (uid != null) {
        log("Trying to get fallback Location");
        position = await _tryToGetFallBackLocation(uid);
        if (position != null) {
          log("OK. But using fallback location.");
          return position;
        } else {
          log("INFO: Could retrieve fallback location");
          return null;
        }
      } else {
        log("Giving up. No fallback possible.");
      }
    } else {
      log("OK. fresh location received.");
      if (uid != null) {
        log("We also have a user authenticated so we will save the position.");
        _savePositionTo(position, uid);
        log("Trying to get the city & country");
        final cityCountry = await _tryToGetCityAndCountry(position);
        if (cityCountry != null) {
          log("City & Country received. We are now saving it to the user object as well.");
          _saveCountryCityTo(cityCountry, uid);
        }
      } else {
        log("No user authenticated. So we cannot save information to database.");
      }
      return position;
    }
  }

  static double get latitude {
    assert(!_singleton.timerIsRunning, "TKLocation Userlocation observation has not started.");
    assert(_singleton.position != null, "Position has not been aquired correctly.");
    return _singleton.position!.lat;
  }

  static double get longitue {
    assert(!_singleton.timerIsRunning, "TKLocation Userlocation observation has not started.");
    assert(_singleton.position != null, "Position has not been aquired correctly.");
    return _singleton.position!.lon;
  }

  static bool get serviceEnabled {
    assert(_singleton._serviceEnabled != null, "TKLocation not initialized (or not with await).");
    return _singleton._serviceEnabled!;
  }

  static Future<TKCoordinates?> _tryToGetFallBackLocation(String uid) async {
    try {
      final snap = await FirebaseDatabase.instance.ref('users').child(uid).get();
      final map = snap.value as Map<Object?, Object?>?;
      if (map == null) {
        print("No user object in database");
        return null;
      }
      final lat = map['lat'] as double?;
      final lon = map['lon'] as double?;
      if (lat == null || lon == null) {
        log("User object ok, but lat/lon not set.");
        return null;
      }

      return TKCoordinates(lat: lat, lon: lon);
    } catch (e) {
      log(e.toString());
      log("Network error - Firebase could not access User Object");
      return null;
    }
  }

// we return different results
  static Future<TKCoordinates?> _determinePosition() async {
    log("Determining position...");
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      _singleton._lastResult = "Error: Location services are disabled.";
      return Future.error('Location services are disabled.');
    }
    log("Service is enabled");
    try {
      const timeLimit = Duration(seconds: 7);
      const desiredAccuracy = LocationAccuracy.medium;
      log("Awating Geolocator Result...");
      final startTime = DateTime.now().millisecondsSinceEpoch;
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: desiredAccuracy, timeLimit: timeLimit);
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final difference = endTime - startTime;
      log("Geolocator result was: ${position.latitude} received in $difference milliseconds.");
      _singleton._lastResult = "Position successfully received in $difference milliseconds.";
      return TKCoordinates(lat: position.latitude, lon: position.longitude);
      // try to get city
    } catch (e) {
      log(e.toString());
      _singleton._lastResult = e.toString();
      return null;
    }
  }

  static Future<CityCountry?> _tryToGetCityAndCountry(TKCoordinates position) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    try {
      final placemarks = await GeocodingPlatform.instance.placemarkFromCoordinates(position.lat, position.lon);
      if (placemarks.isNotEmpty) {
        final locality = placemarks.first.locality;
        final countryCode = placemarks.first.isoCountryCode;
        if (locality != null && countryCode != null) {
          final entTime = DateTime.now().millisecondsSinceEpoch;
          final millisPassed = entTime - startTime;
          log('📍 City: $locality, Country: $countryCode');
          return CityCountry(city: locality, country: countryCode, timepassed: millisPassed);
        } else {
          return null;
        }
// TODO: Logging
// hier sehe ich, ich wuerde das schon sehr gerne im logger haben. Also bitte: Diese App soll in den Logger schreiben.
// Dafuer brauchen wir die TKUUID
        // Logger.info('📍 City: $city, Country: $country');
      } else {
        return null;
      }
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  static Future<void> _saveCountryCityTo(CityCountry cityCountry, String uid) {
    return FirebaseDatabase.instance.ref('users').child(uid).update({'city': cityCountry.city, 'country': cityCountry.country});
  }

  static Future<void> _savePositionTo(TKCoordinates position, String uid) {
    return FirebaseDatabase.instance.ref('users').child(uid).update({'lat': position.lat, 'lon': position.lon});
  }

  static log(String rawMessage) {
    // debugPrint("[TKLocation] $rawMessage");
    Logger.info("[TKLocation] $rawMessage");
  }
}

class CityCountry {
  final String city;
  final String country;
  final int timepassed;
  CityCountry({required this.city, required this.country, required this.timepassed});
}

class TKCoordinates {
  final double lat;
  final double lon;

  TKCoordinates({required this.lat, required this.lon});
}
