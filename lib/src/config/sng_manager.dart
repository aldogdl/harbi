import 'package:get_it/get_it.dart';

import 'globals.dart';

GetIt getSngOf = GetIt.instance;

void sngManager() {

  getSngOf.registerLazySingleton(() => Globals());
}