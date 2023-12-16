import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class TKDatabase {
  
  static FirebaseDatabase analytics() => FirebaseDatabase.instanceFor(app: Firebase.app('analytics'));
}
