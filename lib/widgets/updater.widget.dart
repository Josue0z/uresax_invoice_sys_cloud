

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';


class UpdaterWidget extends StatefulWidget {
  BuildContext context;
  Widget child;
  UpdaterWidget({super.key, required this.context, required this.child});

  @override
  State<UpdaterWidget> createState() => _UpdaterWidgetState();
}

class _UpdaterWidgetState extends State<UpdaterWidget> {

  
  _downloadNewVersion() async {
    showLoader(context);
    try {
      var res = await http.get(Uri.parse(
          'https://api.github.com/repos/Josue0z/uresax_invoice_sys_cloud/releases/latest'));
      var json = jsonDecode(res.body);
      var assets = json['assets'];
      var asset = assets[0];
      var downloadUrl = asset['browser_download_url'];
      var setupRes = await http.get(Uri.parse(downloadUrl));
      var bytes = setupRes.bodyBytes;
      var fileUpdater = File(path.join(
          Directory.systemTemp.path, 'uresax_invoice_sys_cloud', 'updater.exe'));
      await fileUpdater.create(recursive: true);
      await fileUpdater.writeAsBytes(bytes);
      Navigator.pop(context);
      await launchFile(fileUpdater.path);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
      await LogHandler.printError(e.toString());
    }
  }

  
void _showUpdateSnackBar() {
  rootScaffoldMessengerKey.currentState?.clearSnackBars();

  final snackBar = SnackBar(
    duration: Duration(days: 1), // Prácticamente persistente
    behavior: SnackBarBehavior.floating,
    content: Text(
      'Nueva versión disponible ($remoteVersion)'.toUpperCase(),
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    action: SnackBarAction(
      label: 'DESCARGAR',
      onPressed: _downloadNewVersion,
    ),
  );

  rootScaffoldMessengerKey.currentState?.showSnackBar(snackBar);
}



  @override
  void initState() {
     WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        var res = await http.get(Uri.parse(
            'https://api.github.com/repos/Josue0z/uresax_invoice_sys_cloud/releases/latest'));

        
    
        if (res.statusCode == 200) {
          var json = jsonDecode(res.body);

          remoteVersion = json['tag_name'] as String;

          versionChanged =
              isRemoteVersionGreater(localVersion,remoteVersion);


        }
        if (versionChanged) {
          await Future.delayed(const Duration(seconds: 4));
          _showUpdateSnackBar();
        }
      }
    });

    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return   widget.child;
  }
}