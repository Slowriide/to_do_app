import 'package:to_do_app/common/utils/local_file_exists_stub.dart'
    if (dart.library.io) 'package:to_do_app/common/utils/local_file_exists_io.dart'
    if (dart.library.html) 'package:to_do_app/common/utils/local_file_exists_web.dart'
    as impl;

bool localFileExists(String path) => impl.localFileExists(path);
