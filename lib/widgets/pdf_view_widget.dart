import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:path/path.dart' as path;
import 'package:uresax_invoice_sys_cloud/settings.dart';

Future<T> showPdfView<T>(
    {required File file, required BuildContext context}) async {
  
  return await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (ctx) => PdfViewWidget(file: file)));
}

class PdfViewWidget extends StatefulWidget {
  final File file;
  const PdfViewWidget({super.key,required this.file});

  @override
  State<PdfViewWidget> createState() => _PdfViewWidgetState();
}

class _PdfViewWidgetState extends State<PdfViewWidget> {
       final PdfViewerController _pdfViewerController = PdfViewerController();


 @override
  void initState() {
      super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ajusta el zoom para que se vea más pequeño
      _pdfViewerController.zoomLevel = 0.5; 
      setState(() {
        
      });
      // prueba con 0.5, 0.6 o 0.7 hasta que la factura se vea completa
    });
  }

  @override
  Widget build(BuildContext context) {
      Size size = MediaQuery.of(context).size;
   return Scaffold(
              appBar: AppBar(
                title: Text(path.basenameWithoutExtension(widget.file.path)),
                actions: [
                  IconButton(onPressed: () {}, icon: Icon(Icons.print_rounded)),
                  SizedBox(width: kDefaultPadding)
                ],
              ),
              body: Center(
                child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(kDefaultPadding),
                width: size.width /3,
                height: size.height,
                child: SfPdfViewer.file(controller: _pdfViewerController, widget.file),
              )
                ),
              )
              ;
  }
}