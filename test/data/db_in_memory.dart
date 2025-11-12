import 'package:drift/native.dart';
import 'package:listyb/data/db/app_database.dart';

AppDatabase makeInMemoryDb() => AppDatabase(NativeDatabase.memory());
