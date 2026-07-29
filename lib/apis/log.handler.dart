
import 'package:uresax_invoice_sys_cloud/apis/api.uresax.dart';

class LogHandler {
  LogHandler._();

  static Future<void> printEvent(String message) async {
    /*await apiUresax.post('/logs/print-event',data:  {
      'message': message
    });*/
  }

  static Future<void> printError(String error) async {
    /* await apiUresax.post('/logs/print-error',data:  {
      'message': error
    });*/
  }
}
