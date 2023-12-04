import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tklocation/src/counter.dart';

class TKLocation {
  static final TKLocation _singleton = TKLocation._internal();
  TKLocation._internal();
  factory TKLocation() {
    return _singleton;
  }
  SharedPreferences? shared;
  bool? _serviceEnabled;
  // Wenn wir eine location bekommen koennen, sollten wir diese erstmal speichern, den Ort holen und
  // alles im UserObject orderntlich registrieren.

  static initialize({required String appShort, required String uid}) async {
    final shared = await SharedPreferences.getInstance();
    print("TKLocation initialized!");
    final uid = FirebaseAuth.instance.currentUser?.uid;
    print("Current User:$uid");

    // Check if location service is available
    final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
    _singleton._serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    Counter.increaseCounter(CounterName.location_service_enabled,appShort);
//   _determinePosition()
// COUNTER: location_aquired


  }

  static bool get serviceEnabled  {
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
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.');
  } 

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}
}
