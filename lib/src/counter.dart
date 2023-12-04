import 'package:shared_preferences/shared_preferences.dart';
import 'package:tklocation/src/date.dart';
import 'tk_database.dart';

class Counter {
  static increaseCounterOnce(CounterName counterName, String appShort) async {
    final name = counterName.name;
    final shared = await SharedPreferences.getInstance();
    final hasBeenCounted = shared.getBool(name) ?? false;
    if (hasBeenCounted) return;
    shared.setBool(name, true);
    increaseCounter(counterName, appShort);
  }

  static increaseCounter(CounterName counterName, String appShort) async {
    final name = counterName.name;
    final todayString = Date().toYYMMDD();
    final ref = TKDatabase.analytics().ref('stats').child('$appShort/$todayString/$name');
    final snapshot = await ref.get();
    int counter = 1;
    if (snapshot.value != null) counter = (snapshot.value as int) + 1;
    ref.set(counter);
  }
}

enum CounterName {
  msgsend,
  rooc,
  warning,
  corrupt_profiles,
  local_position_unknown,
  heic_execption,
  suppressed_exec,
  iap,
  iap_cancelled,
  iapp,
  location_access_denied,
  location_service_enabled,
  photo_access_denied,
  gpp,
  prf_deleted,
  deviceids,
  uid_created,
  prf_created,
  prf_viewed,
  blocker_presented,
  root,
  errorLogged,
  main_aync,
  restarts,
  iapp_plate_change,
  tkuuids,
  app_start_with_user_no_tkuuid
}
