import 'dart:io';
import 'package:path/path.dart' as path;

class LogHandler {
  LogHandler._();

  static late File logs;
  static Future<void> init() async {
    try {
      var dir = Directory.current;
      logs = File(path.join(dir.path, 'logs', 'logs.txt'));
      await logs.create(recursive: true);
    } catch (e) {
      print(e);
    }
  }

  static Future<void> printEvent(String message) async {
    var now = DateTime.now();
    var oldData = await logs.readAsString();
    logs.writeAsString('[${now.toIso8601String()}] - EVENT: $message\n$oldData');
  }

  static Future<void> printError(String error) async {
    var now = DateTime.now();
    var oldData = await logs.readAsString();
    logs.writeAsString('[${now.toIso8601String()}] - ERROR: $error\n$oldData');
  }
}
