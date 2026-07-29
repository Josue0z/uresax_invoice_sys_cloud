
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:printing/printing.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:pdf/widgets.dart' as pw;

class PDFScreen extends StatefulWidget {
  final List<int> bytes;
  final String fileName;
  final pw.Document document;

  PDFScreen({Key? key, required this.bytes, required this.document, required this.fileName})
      : super(key: key);

  @override
  PDFScreenState createState() => PDFScreenState();
}

class PDFScreenState extends State<PDFScreen> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 231, 229, 229),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.fileName),
          actions: [
            IconButton(
                onPressed: () async {
                await Printing.layoutPdf(
                  name: widget.fileName,
      onLayout: (PdfPageFormat format) async => widget.document.save());
                },
                icon: Icon(Icons.print)),
                  SizedBox(
              width: kDefaultPadding,
            ),
            IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.close)),
            SizedBox(
              width: kDefaultPadding,
            )
          ],
        ),
        body: Center(
          child: SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: PdfViewer.data(Uint8List.fromList(widget.bytes),
                  params: PdfViewerParams(
                      backgroundColor: Colors.transparent, scaleEnabled: true),
                  sourceName: widget.fileName)),
        ));
  }
}
