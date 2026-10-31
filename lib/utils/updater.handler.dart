import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const String owner = "Josue0z";
const String repo = "uresax_invoice_sys_cloud";

Future<void> checkForUpdate(BuildContext context) async {
  // Obtener versión actual del package
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = packageInfo.version;

  final url = Uri.parse("https://api.github.com/repos/$owner/$repo/releases/latest");

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final latestTag = data["tag_name"]; // Ejemplo: "v1.2.0"
      final assets = data["assets"] as List<dynamic>;

      // Buscar el .exe en los assets
      final exeAsset = assets.firstWhere(
        (a) => (a["name"] as String).endsWith(".exe"),
        orElse: () => null,
      );

      if (_isNewerVersion(latestTag, currentVersion) && exeAsset != null) {
        _showUpdateDialog(context, latestTag, exeAsset["browser_download_url"]);
      }
    } else {
      debugPrint("Error al consultar GitHub: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("Error de conexión: $e");
  }
}

bool _isNewerVersion(String latest, String current) {
  final latestClean = latest.replaceAll("v", "");
  final latestParts = latestClean.split(".").map(int.parse).toList();
  final currentParts = current.replaceAll("v", "").split(".").map(int.parse).toList();

  for (int i = 0; i < latestParts.length; i++) {
    if (latestParts[i] > currentParts[i]) return true;
    if (latestParts[i] < currentParts[i]) return false;
  }
  return false;
}

void _showUpdateDialog(BuildContext context, String latestVersion, String downloadUrl) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Nueva versión disponible"),
      content: Text("Se encontró la versión $latestVersion. ¿Deseas descargarla?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(ctx).pop();
            if (await canLaunchUrl(Uri.parse(downloadUrl))) {
              await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
            }
          },
          child: const Text("Descargar"),
        ),
      ],
    ),
  );
}
