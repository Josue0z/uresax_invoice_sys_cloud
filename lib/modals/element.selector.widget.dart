import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/models/product.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.element.abs.dart';
import 'package:uresax_invoice_sys_cloud/models/service.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/extensions.dart';

class SaleElementSelectorWidget extends StatefulWidget {
  SaleMode mode;
  SaleElementSelectorWidget({super.key, this.mode = SaleMode.product});

  @override
  State<SaleElementSelectorWidget> createState() =>
      _SaleElementSelectorWidgetState();
}

class _SaleElementSelectorWidgetState extends State<SaleElementSelectorWidget> {
  Future? future;
  List<SaleElement> elements = [];

  _initAsync([String? search]) async {
    if (widget.mode == SaleMode.product) {
      elements = await Products.get(search: search);
    }

    if (widget.mode == SaleMode.service) {
      elements = await Services.get(search: search);
    }
    setState(() {});
  }

  @override
  void initState() {
     setState(() {
       future =  _initAsync();
     });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 350,
        height: 450,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(kDefaultPadding/2),
              child: Column(
                children: [
           
                  Row(
                    children: [
                      Expanded(
                          child: Text('Elegir Articulo...',
                              style: TextStyle(
                                  fontSize: 22,
                                  color: Theme.of(context).primaryColor))),
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close))
                    ],
                  ),
                          SizedBox(
                    height: kDefaultPadding/2
                  ),
                  TextFormField(
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    onChanged: (values){
                     setState(() {
                       future =  _initAsync(values);
                     });
                    },
                    decoration: InputDecoration(
                         suffixIcon: Icon(Icons.search),
                        labelText: 'BUSCAR', hintText: 'Escribir algo...'),
                  ),
                  SizedBox(
                    height: kDefaultPadding/2
                  )
                ],
              ),
            ),
            Expanded(
                child: FutureBuilder(
                    future: future,
                    builder: (ctx, s) {
                      if (s.connectionState == ConnectionState.waiting && elements.isEmpty) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (s.hasError) {
                        return Container();
                      }

                      return ListView.separated(
                          itemBuilder: (ctx, i) {
                            var el = elements[i];
                            return ListTile(
                              title: Text(el.name ?? ''),
                              subtitle: el.code != null ?  Text(el.code ?? '') : null,
                              trailing: Wrap(
                                children: [
                                  Text(el.price?.toCoin() ??'')
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context, el);
                              },
                            );
                          },
                          separatorBuilder: (ctx, i) => const Divider(),
                          itemCount: elements.length);
                    }))
          ],
        ),
      ),
    );
  }
}
