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
// COOOL: Ich kann auf Counter zu greifen!!

  static initialize({required String appShort}) async {
    // starte Timer
    startLocationObservation();
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

  static Future<Position?> getUserLocation() async {
    const timeLimit = Duration(seconds: 7);
    const desiredAccuracy = LocationAccuracy.medium;
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: desiredAccuracy, timeLimit: timeLimit);
    } catch (e) {
      print("Location aquisition error");
      print(e);
      return null;
    }
  }

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

/*
// const geoPointSF = GeoPoint(37.76924, -122.41906);
// const geoPointLA = GeoPoint(34.07238228752573, -118.29917759003277);
// const geoPointMountainView = GeoPoint(37.39967066210587, -122.08504684853969);

final userLocationRepositoryProvider = Provider((ref) => UserLocationRepository(
      FirebaseDatabase.instance,
      FirebaseAuth.instance,
    ));

StreamSubscription<Position>? positionStream;

@Deprecated('dont use this anymore')
class UserLocationRepository {
  final FirebaseAuth firebaseAuth;
  final FirebaseDatabase firebaseDatabase;
  UserLocationRepository(this.firebaseDatabase, this.firebaseAuth);
// TODO: Why do we have Queue Overflows?
// TODO: All Logs: Search
// TODO: Jump from Main Log to TKUUID Specific log
// TODO: Status bar in white on MainFrame People!
  observeUserLocation() async {
    return;
    final uid = firebaseAuth.currentUser!.uid;
    FirebaseCrashlytics.instance.setUserIdentifier(uid);
    FirebaseAnalytics.instance.setUserId(id: uid);
    firebaseDatabase.ref('users').child(uid).update({'lat': defaultLat, 'lon': defaultLon});
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: kMinimumDistanceInMeterChangeToTriggerLocationUpdate,
    );

    final permissionStatus = await Geolocator.checkPermission();
    if (permissionStatus == LocationPermission.denied) {
      try {
        await Geolocator.requestPermission();
      } catch (e) {
        debugPrint('we can ignore this.');
      }
    }
    if (permissionStatus == LocationPermission.whileInUse || permissionStatus == LocationPermission.always) {
      try {
        positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((event) async {
          Logger.info('(UserLocationDataSourceImpl.dart) Real User Location update received');

          // How to set location to GeoLoc???? Have we EVER done this in Flutter? OF COURSE!!!!!
          if (firebaseAuth.currentUser == null) return; // this is to prevent further updates after user has logged out or deleted profile.
          firebaseDatabase.ref('users').child(uid).update({'lat': event.latitude, 'lon': event.longitude});

          final geopoint = GeoPoint(event.latitude, event.longitude);
          final geohash = MyGeoHash().geoHashForLocation(geopoint); // 9q8yywd7v

          // Vermutung: How to save this into the database:
          firebaseDatabase.ref(geolocpath).child(uid).update({
            'g': geohash,
            'l': [event.latitude, event.longitude]
          });
// testSF@madetk.com
// flutter: [DEBUG] 2.5.34 📍 GeoHash set for TLHWyX3Z1CeA1h9L011z2uQsVN83, hash: 9q8yywdq7v, lat: 37.785834
// flutter: [DEBUG] 2.5.34 📍 City: San Francisco
          Logger.info('📍 GeoHash set for $uid, hash: $geohash, lat: ${event.latitude}');
          localPosition = GeoPoint(event.latitude, event.longitude);
          // this can throw if we have network problems.
          try {
            final placemarks = await GeocodingPlatform.instance.placemarkFromCoordinates(event.latitude, event.longitude);
            if (placemarks.isNotEmpty) {
              final city = placemarks.first.locality;
              final country = placemarks.first.isoCountryCode;

              Logger.info('📍 City: $city, Country: $country');

              firebaseDatabase.ref('users').child(uid).update({'city': city, 'country': country});
            }
          } catch (e) {
            debugPrint(e.toString());
          }
        });
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }
}
*/