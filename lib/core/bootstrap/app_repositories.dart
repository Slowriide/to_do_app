import 'package:to_do_app/core/bootstrap/app_repositories_base.dart';
import 'package:to_do_app/core/bootstrap/app_repositories_io.dart'
    if (dart.library.html) 'package:to_do_app/core/bootstrap/app_repositories_web.dart'
    as impl;

Future<AppRepositories> createAppRepositories() {
  return impl.createAppRepositories();
}
