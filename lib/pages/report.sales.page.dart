import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uresax_invoice_sys_cloud/apis/log.handler.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:path/path.dart' as path;

class ReportSalesPage extends StatefulWidget {
  String title;

  int reportTypeId;

  List<Map<String, dynamic>> data;

  DateTime startDate;

  DateTime endDate;

  pw.Document document;

  Uint8List bytes;

  ReportSalesPage(
      {super.key,
      required this.title,
      required this.reportTypeId,
      required this.data,
      required this.startDate,
      required this.endDate,
      required this.document,
      required this.bytes});

  @override
  State<ReportSalesPage> createState() => _ReportSalesPageState();
}

class _ReportSalesPageState extends State<ReportSalesPage> {
  List<String> get columns {
    if (widget.data.isEmpty) return [];
    var items = widget.data[0].keys.toList();
    return items;
  }

  Widget get contentEmpty {
    return Expanded(
        child: Center(
      child: Column(
        children: [
          SvgPicture.asset('assets/svgs/undraw_printing-invoices_osgs.svg',
              width: 320)
        ],
      ),
    ));
  }

  Widget get contentFilled {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Table(
                      defaultColumnWidth: FixedColumnWidth(150),
                      children: [
                        TableRow(
                            children: List.generate(columns.length, (index) {
                          var col = columns[index];
                          return Padding(
                              padding: EdgeInsets.all(kDefaultPadding),
                              child: Text(col,
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Theme.of(context).primaryColor)));
                        }))
                      ],
                    ),
                    Table(
                      defaultColumnWidth: FixedColumnWidth(150),
                      children: [
                        ...List.generate(widget.data.length, (index) {
                          var item = widget.data[index];
                          var values = item.values.toList();
                          return TableRow(
                              children: List.generate(values.length, (i) {
                            var val = values[i];
                            return Padding(
                                padding: EdgeInsets.all(kDefaultPadding),
                                child: Text(val.toString(),
                                    style:
                                        Theme.of(context).textTheme.bodySmall));
                          }));
                        })
                      ],
                    )
                  ],
                ),
              )),
        )
      ],
    );
  }

  Widget get content {
    if (widget.data.isEmpty) return contentEmpty;
    return contentFilled;
  }

  String get reportLabel {
    return widget.reportTypeId == 1
        ? 'REPORTE_POR_TIPO_NCF'
        : 'REPORTE_POR_TIPO_INGRESO';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('${company?.name} - ${widget.title}'),
          actions: [
            IconButton(
                onPressed: () async {
                  try {
                    var dir = await getUresaxInvoiceDir();
                    var period = widget.endDate.format(payload: 'YYYYMM');
                    var start = widget.startDate.format(payload: 'DD-MM-YYYY');
                    var end = widget.endDate.format(payload: 'DD-MM-YYYY');
                    var file = File(path.join(
                        dir.path,
                        'REPORTES',
                        'PDFS',
                        period,
                        '${reportLabel}_${company?.name}_$start - $end.PDF'));

                    await file.create(recursive: true);

                    await file.writeAsBytes(widget.bytes);

                    await OpenFile.open(file.path);
                  } catch (e) {
                    await LogHandler.printError(e.toString());
                    showTopSnackBar(context, message: e.toString());
                  }
                },
                icon: Icon(Icons.picture_as_pdf)),
            SizedBox(
              width: kDefaultPadding,
            )
          ],
        ),
        body: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: DesktopTextSelectionControls(),
            child: Padding(
                padding: EdgeInsets.all(kDefaultPadding), child: content)));
  }
}
