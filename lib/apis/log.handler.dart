import 'dart:io';
import 'package:path/path.dart' as path;

class LogHandler {
  LogHandler._();

  static late File logs;
  static Future<void> init() async {
    try {
      var dir = Directory.systemTemp;
      logs = File(path.join(dir.path, 'uresax_logs', 'logs.txt'));
      await logs.create(recursive: true);
    } catch (e) {
      print(e);
    }
  }

  static Future<void> printEvent(String message) async {
    try{
          var now = DateTime.now();
    var oldData = await logs.readAsString();
    await logs.writeAsString('[${now.toIso8601String()}] - EVENT: $message\n$oldData');
    }catch(e){
      print(e);
    }
  }

  static Future<void> printError(String error) async {
    try{
       var now = DateTime.now();
    var oldData = await logs.readAsString();
    await logs.writeAsString('[${now.toIso8601String()}] - ERROR: $error\n$oldData');
    }catch(e){
      print(e);
    }
  }
}
