import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/modals/product.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/product.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class ProductsChildrenPage extends StatefulWidget {
  Products product;

  ProductsChildrenPage({super.key, required this.product});

  @override
  State<ProductsChildrenPage> createState() => _ProductsChildrenPageState();
}

class _ProductsChildrenPageState extends State<ProductsChildrenPage> {
  List<Products> children = [];

  _initAsync() async {
    try {
      children = await widget.product.getProductsRelations();
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    if (!mounted) return;
    _initAsync();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.product.name}'),
        actions: [
          CircleAvatar(
              child: IconButton(
                  tooltip: 'AGREGAR RELACIÓN',
                  icon: Icon(Icons.add),
                  onPressed: () async {
                    var product = await showDialog<Products?>(context: context, builder: (ctx) => ProductEditorModal(
                      product: Products(),
                    ));

                    if (product != null) {
                      widget.product.parentproductId = widget.product.id;
                      widget.product.childproductId = product.id;
                      var res = await widget.product.createRelation();
                       await  widget.product.updateAddStockFromProductChild();
                      if (res != null) {
                        _initAsync();
                      }
                    }
                  })),
          SizedBox(
            width: 10,
          )
        ],
      ),
      body: ListView.separated(
        itemCount: children.length,
        itemBuilder: (ctx, index) {
          final child = children[index];
          return ListTile(
              minVerticalPadding: kDefaultPadding,
              leading: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(90),
                    color: Theme.of(context).primaryColor.withOpacity(0.04),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                ),
            title: Text(child.productChildName ?? ''),
            trailing: Wrap(
              runAlignment: WrapAlignment.center,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(kDefaultPadding / 2),
                  margin: EdgeInsets.only(right: kDefaultPadding),
                  decoration: BoxDecoration(
                      color: widget.product.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50)),
                  child: Text(
                  child.quantityChild == 0
                        ? 'AGOTADO'
                        : child.quantityChild.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: widget.product.color),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (ctx, index) => Divider(),
      ),
    );
  }
}
