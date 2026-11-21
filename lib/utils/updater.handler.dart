import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

const String owner = "Josue0z";
const String repo = "uresax_invoice_sys_cloud";

Future<void> checkForUpdate(BuildContext context) async {
  // Obtener versión actual del package
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = packageInfo.version;

  final url =
      Uri.parse("https://api.github.com/repos/$owner/$repo/releases/latest");

  try {

        // 1. Cargar el certificado desde assets
    final data = await rootBundle.load('assets/certs/isrgrootx1.pem');

    // 2. Guardarlo en un archivo temporal
    final tempDir = await getTemporaryDirectory();
    final certFile = File('${tempDir.path}/isrgrootx1.pem');
    await certFile.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );

    // 3. Crear SecurityContext con el certificado
    final xcontext = SecurityContext(withTrustedRoots: true);
    xcontext.setTrustedCertificates(certFile.path);

    // 4. Usar HttpClient con ese contexto
    final client = HttpClient(context: xcontext);
    final request = await client.getUrl(url);
    final response = await request.close();
    final body = await utf8.decoder
      .bind(response)
      .join();

    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      final latestTag = data["tag_name"]; // Ejemplo: "v1.2.0"
      final assets = data["assets"] as List<dynamic>;

      // Buscar el .exe en los assets
      final exeAsset = assets.firstWhere(
        (a) => (a["name"] as String).endsWith(".exe"),
        orElse: () => null,
      );

      if (_isNewerVersion(latestTag, currentVersion) && exeAsset != null) {
        _showUpdateDialog(context, latestTag, exeAsset["browser_download_url"]);
      }else{
            await LogHandler.printError('No existe nueva version disponible ultima version: $latestTag, actual version: $currentVersion');
      }
    } else {
      debugPrint("Error al consultar GitHub: ${response.statusCode}");
      await LogHandler.printError('Error al consultar GitHub: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint("Error de conexión: $e");
    await LogHandler.printError('Error de conexión: $e');
  }
}

bool _isNewerVersion(String latest, String current) {
  final latestClean = latest.replaceAll("v", "");
  final latestParts = latestClean.split(".").map(int.parse).toList();
  final currentParts =
      current.replaceAll("v", "").split(".").map(int.parse).toList();

  for (int i = 0; i < latestParts.length; i++) {
    if (latestParts[i] > currentParts[i]) return true;
    if (latestParts[i] < currentParts[i]) return false;
  }
  return false;
}

void _showUpdateDialog(
    BuildContext context, String latestVersion, String downloadUrl) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Nueva versión disponible"),
      content:
          Text("Se encontró la versión $latestVersion. ¿Deseas descargarla?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              showLoader(context);
              await _downloadAndRunExe(downloadUrl);
              Navigator.pop(context);
            } catch (e) {
              Navigator.pop(context);
              showTopSnackBar(context,
                  message: e.toString(), color: Colors.red);
            }
          },
          child: const Text("Descargar"),
        ),
      ],
    ),
  );
}

Future<void> _downloadAndRunExe(String url) async {
  try {
    // 1. Cargar el certificado desde assets
    final data = await rootBundle.load('assets/certs/isrgrootx1.pem');

    // 2. Guardarlo en un archivo temporal
    final tempDir = await getTemporaryDirectory();
    final certFile = File('${tempDir.path}/isrgrootx1.pem');
    await certFile.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );

    // 3. Crear SecurityContext con el certificado
    final context = SecurityContext(withTrustedRoots: true);
    context.setTrustedCertificates(certFile.path);

    // 4. Usar HttpClient con ese contexto
    final client = HttpClient(context: context);
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode == 200) {
      final bytes = await response.fold<List<int>>([], (prev, element) => prev..addAll(element));

      final exePath = "${tempDir.path}/update_installer.exe";
      final file = File(exePath);
      await file.writeAsBytes(bytes);

      // Ejecutar el instalador en Windows
      await Process.start(exePath, [], runInShell: true);
    } else {
      throw "Error al descargar el instalador: ${response.statusCode}";
    }
  } catch (e) {
    throw "Error al descargar/ejecutar: $e";
  }
}