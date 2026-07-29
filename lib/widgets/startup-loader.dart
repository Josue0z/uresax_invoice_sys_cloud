import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class StartupLoader extends StatefulWidget {
  const StartupLoader({super.key});

  @override
  State<StartupLoader> createState() => _StartupLoaderState();
}

class _StartupLoaderState extends State<StartupLoader> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/logos/uresax-invoice-logo.png', width: 250),
          SizedBox(height: kDefaultPadding),
          CircularProgressIndicator(color: Colors.white)
        ],
      )),
    );
  }
}
