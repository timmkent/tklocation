import 'package:shared_preferences/shared_preferences.dart';

class TKLocation {
  static final TKLocation _singleton = TKLocation._internal();
  TKLocation._internal();
  factory TKLocation() {
    return _singleton;
  }
  SharedPreferences? shared;

  // Wenn wir eine location bekommen koennen, sollten wir diese erstmal speichern, den Ort holen und
  // alles im UserObject orderntlich registrieren.

  static initialize({required String appShort, required String uid}) async {
    final shared = await SharedPreferences.getInstance();
    print("TKLocation initialized!");
  }
}
