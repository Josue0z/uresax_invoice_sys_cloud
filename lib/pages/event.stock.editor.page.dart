import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:uresax_invoice_sys_cloud/models/event.stock.model.dart';
import 'package:uresax_invoice_sys_cloud/models/product.dart';
import 'package:uresax_invoice_sys_cloud/pages/products_page.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class EventStockEditorPage extends StatefulWidget {

  final String eventType;
  EventStockEditorPage({Key? key,this.eventType = 'input'}) : super(key: key);

  @override
  State<EventStockEditorPage> createState() => _EventStockPageState();
}

class _EventStockPageState extends State<EventStockEditorPage> {

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final List<Products> _selectedProducts = [];
  
  
  Widget get contentFilled {
    return ListView.separated(
              itemCount: _selectedProducts.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (context, index) {
                final product = _selectedProducts[index];
                final controller = TextEditingController(
                    text: product.quantity?.toStringAsFixed(2) ?? '');

                return ListTile(
                    title: Text(product.name ?? ''),
                    minVerticalPadding: kDefaultPadding,
                    subtitle: Text('${product.code}/${product.unitName}'),
                    trailing: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          child: TextFormField(
                            controller: controller,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            validator: (val) => val!.isEmpty ? 'CAMPO OBLIGATORIO': null, 
                            decoration: InputDecoration(
                                labelText: 'CANTIDAD', hintText: '0.00'),
                            onChanged: (val) {
                              product.quantity = double.tryParse(val) ?? 0;
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _selectedProducts.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ));
              },
            );
  }

  Widget get contentEmpty {
    return Center(
      child:SvgPicture.asset('assets/svgs/undraw_product-iteration_r2wg.svg',width: 200),
    );
  }
  Widget get content {
      if(_selectedProducts.isEmpty){
        return contentEmpty;
      }
      return contentFilled;
  }
  void _addProduct(Products product) {
    setState(() {
      _selectedProducts.add(product);
    });
  }

  void _sendEventStock() async {
    if(formKey.currentState!.validate() && _selectedProducts.isNotEmpty){

     var isCorrect = await showUserValidator(context);
      if(isCorrect == true){
         try {
      final event = EventStockModel(
        eventTypeName:widget.eventType,
        createdAt: DateTime.now(),
        items: _selectedProducts.map((p) {
          return EventStockChild(
            productId: p.id,
            productName: p.name,
            quantity: p.quantity,
            conversionFactor: p.conversionFactor,
            unitCode: p.unitCode,
            unitName: p.unitName,
            unitSymbol: p.unitSymbol,
            createdAt: DateTime.now(),
          );
        }).toList(),
      );

      showLoader(context);
      await event.create();

      Navigator.pop(context);

      Navigator.pop(context, 'CREATE');

    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
      }
    }
  }
  
  String get label{
    if(widget.eventType == 'input'){
      return 'ENTRADAS';
    }
    return 'SALIDAS';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("$label DE INVENTARIO (${_selectedProducts.length})"),
          toolbarHeight: kToolbarHeight + 50,
          actions: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runAlignment: WrapAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _sendEventStock,
                    style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.white)),
                    child: Text(
                      "Enviar evento",
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
                SizedBox(width: kDefaultPadding)
              ],
            )
          ]),
      body: Form(
        key: formKey,
        child:Column(
        children: [
          Expanded(
            child: content
          ),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Aquí simulas seleccionar un producto desde tu paleta
          final newProduct = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (ctx) => ProductsPage(selectedMode: true)));

          if (newProduct is Products) {
            newProduct.quantity = null;
            _addProduct(newProduct);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
