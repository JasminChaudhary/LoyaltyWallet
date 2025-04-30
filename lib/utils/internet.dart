import 'dart:io';
import 'package:flutter/foundation.dart';

Future<bool> checkInternet() async {
  if (kIsWeb) {
    // Web platform always returns true as it requires internet to load the app
    return true;
  }
  
  try {
    await InternetAddress.lookup('stash.blitzapp.ro');
    return true;
  } on SocketException {
    return false;
  }
}
