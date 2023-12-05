import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tklocation/src/counter.dart';

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
  SharedPreferences? shared;
  bool? _serviceEnabled;

  static initialize({required String appShort}) async {
    final shared = await SharedPreferences.getInstance();
    print("TKLocation initialized!");
    // nur beim restart haben wir eine UID, sonst nicht. Wir muessen diese also immer wieder erneut pruefen.

    // Zum testen erstaml rausnehmen
    final uid = FirebaseAuth.instance.currentUser?.uid;
    print("Current User:$uid");

    // Check if location service is available
    final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
    _singleton._serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    Counter.increaseCounterOnce(CounterName.location_service_enabled, appShort);

    final permissions = await _geolocatorPlatform.checkPermission();

    if (permissions == LocationPermission.denied) {
      // User has not yet granted permissions.
    }
//   _determinePosition()
// COUNTER: location_aquired
  }

  Timer? timer;
  bool timerIsRunning = false;
  Position? position;
// TODO: Get last known position from my own user profile
// TODO: Get City
// TODO: Write data to user profile.
// TODO: Send some message to potential observers that want to reload

  static startLocationObservation() {
    // TODO: Make sure you dont start this more than once!
    print("TKLocation: starting Userlocation Observation");
    _singleton.timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      print("TKLocation: getting user location");
      const timeLimit = Duration(seconds: 7);
      const desiredAccuracy = LocationAccuracy.medium;
      try {
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: desiredAccuracy, timeLimit: timeLimit);
        _singleton.position = position;
      } catch (e) {
        print("Location aquisition error");
        print(e);
      }
    });
  }

  static stopLocationObservation() {
    print("TKLocation: stopping Userlocation Observation");
    _singleton.timer?.cancel();
    _singleton.timer = null;
  }

  static double get latitude {
    assert(!_singleton.timerIsRunning, "TKLocation Userlocation observation has not started.");
    assert(_singleton.position != null, "Position has not been aquired correctly.");
    return _singleton.position!.latitude;
  }

  static double get longitue {
    assert(!_singleton.timerIsRunning, "TKLocation Userlocation observation has not started.");
    assert(_singleton.position != null, "Position has not been aquired correctly.");
    return _singleton.position!.longitude;
  }

  static bool get serviceEnabled {
    assert(_singleton._serviceEnabled != null, "TKLocation not initialized (or not with await).");
    return _singleton._serviceEnabled!;
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
