import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class ContentErrorWidget extends StatefulWidget {
  String error = 'OCURRIO UN ERROR DESCONOCIDO';
  VoidCallback onRetry;
  ContentErrorWidget({super.key, required this.error, required this.onRetry});

  @override
  State<ContentErrorWidget> createState() => _ContentErrorWidgetState();
}

class _ContentErrorWidgetState extends State<ContentErrorWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/svgs/undraw_cancel_7zdh.svg', width: 270),
            SizedBox(
              height: kDefaultPadding,
            ),
            Text(widget.error.toString()),
            SizedBox(
              height: kDefaultPadding * 2,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 50,
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('IR A INICIO')),
                ),
                SizedBox(width: kDefaultPadding),
                SizedBox(
                  width: 150,
                  height: 50,
                  child: ElevatedButton(
                      onPressed: () {
                        widget.onRetry();
                      },
                      child: Text('REINTENTAR')),
                )
              ],
            )
          ],
        ),
      )),
    );
  }
}
