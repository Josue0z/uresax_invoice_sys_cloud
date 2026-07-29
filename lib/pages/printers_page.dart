import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:uresax_invoice_sys_cloud/apis/printers.handler.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';

class PrintersPage extends StatefulWidget {
  const PrintersPage({super.key});

  @override
  State<PrintersPage> createState() => _PrintersPageState();
}

class _PrintersPageState extends State<PrintersPage> {
  Future? future;

  
  Widget get contentLoading {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Future<void> startScan() async {
    printers = (await PrinterHandler.listPrinters());
    printers.sort((a, b) => a.compareTo(b));
    setState(() {});
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
       setState(() {
         future =    startScan();
       });
      }
    });
    super.initState();
  }

  stopScan() {}

  @override
  void dispose() {
   printers = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DISPOSITIVOS (${printers.length})'),
      ),
      body: FutureBuilder(future: future, builder: (ctx,s){

         if (s.connectionState == ConnectionState.waiting) {
              return contentLoading;
            }

            if (s.hasError) {
              return ContentErrorWidget(
                error: s.error.toString(),
                onRetry: () {
                  setState(() {
                    future = startScan();
                  });
                },
              );
            }
        if(s.connectionState == ConnectionState.done && printers.isNotEmpty){


          return ListView.separated(
          itemBuilder: (ctx, index) {
            final printer = printers[index];

            return ListTile(
              key: ValueKey(printer),
              title: Text(printer),
              onTap: () async {
                try {
                  localStorage.setItem('devicePos', printer);
                  Navigator.pop(context, printer);
                } catch (e) {
                  showTopSnackBar(context,
                      message: e.toString(), color: Colors.red);
                }
              },
            );
          },
          separatorBuilder: (ctx, index) => Divider(),
          itemCount: printers.length);
        }
        return Container();
      })
    );
  }
}
