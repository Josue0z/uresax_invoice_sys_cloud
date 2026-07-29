import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/models/subscription.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  _init() async {}
  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 380,
        child: SingleChildScrollView(
            padding: EdgeInsets.all(kDefaultPadding),
            child: Center(
              child: Column(
                children: [
                 SizedBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text('COMENZAR TU PLAN',
                                      style: TextStyle(
                                          fontSize: 20,
                                          color:
                                              Theme.of(context).primaryColor))),
                              IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: Icon(Icons.close))
                            ],
                          ),
                          SizedBox(
                            height: kDefaultPadding,
                          ),
                          Text(
                            '\$10.00/Mensual',
                            style: TextStyle(fontSize: 24),
                          ),
                          SizedBox(
                            height: kDefaultPadding,
                          ),
                          Text('PLAN PROFESIONAL',  textAlign: TextAlign.center, style: TextStyle(fontSize: 20,
                          color: Theme.of(context).primaryColor)),
                          SizedBox(
                            height: kDefaultPadding,
                          ),
                          Text(
                            'PROGRAMA DE FACTURACION ELECTRONICA Y CONTROL DE INVENTARIO',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(
                            height: kDefaultPadding,
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await SubscriptionModel.createSubscription(
                                        context: context, xplanId: kDebugMode ? 'P-97R960555F377894YNHA3NKY':'P-2GJ86069K95472402NHAVNBY');
                                  } catch (e) {
                                       Navigator.pop(context);
                                    showTopSnackBar(context,
                                        message: e.toString(),
                                        color: Colors.red);
                                  }
                                },
                                child: Text('SUBSCRIBIRSE')),
                          )
                        ],
                      ),
                    )
                  
                ],
              ),
            )),
      ),
    );
  }
}
