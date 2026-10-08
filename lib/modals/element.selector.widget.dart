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
  List<SaleElement> parents = [];
  List<SaleElement> children = [];
  SaleElement? currentParentElement;
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();

  _initAsync({String? search, int? parentId}) async {
    if (widget.mode == SaleMode.product) {
      if (parentId != null) {
        children = await Products.get(search: search, parentId: parentId);
      } else {
        parents = await Products.get(search: search);
      }
    }

    if (widget.mode == SaleMode.service) {
      parents = await Services.get(search: search);
    }
    setState(() {});
  }

  @override
  void initState() {
    setState(() {
      future = _initAsync();
    });
    super.initState();
  }

  @override
  dispose(){
    parents = [];
    children = [];
    _pageController.dispose();
    _searchController.clear();
    super.dispose();
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
              padding: EdgeInsets.all(kDefaultPadding / 2),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text('Elegir Articulo...',
                              style: TextStyle(
                                  fontSize: 22,
                                  color: Theme.of(context).primaryColor))),
                      currentParentElement != null
                          ? IconButton(
                              onPressed: () {
                                if (currentParentElement != null) {
                                  _pageController.jumpToPage(0);
                                  currentParentElement = null;
                                  setState(() {});
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                              icon: Icon(Icons.arrow_left))
                          : SizedBox(),
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close))
                    ],
                  ),
                  SizedBox(height: kDefaultPadding / 2),
                  TextFormField(
                    controller: _searchController,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    onChanged: (values) {
                      setState(() {
                        future = _initAsync(search: values,parentId: currentParentElement?.id);
                      });
                    },
                    decoration: InputDecoration(
                        suffixIcon: Icon(Icons.search),
                        labelText: 'BUSCAR',
                        hintText: 'Escribir algo...'),
                  ),
                  SizedBox(height: kDefaultPadding / 2)
                ],
              ),
            ),
            Expanded(
                child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                if (page == 1) {
               
                  setState(() {
                    future = _initAsync(parentId: currentParentElement?.id);
                  });
                } else {
                  currentParentElement = null;
                  children = [];
                }
              },
              children: [
                SizedBox(
                    child: FutureBuilder(
                        future: future,
                        builder: (ctx, s) {
                          if (s.connectionState == ConnectionState.waiting &&
                              parents.isEmpty) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (s.hasError) {
                            return Container();
                          }

                          if(parents.isEmpty){
                             return SizedBox(child: Center(
                              child: Icon(Icons.list_alt_outlined,size: 90, color: Theme.of(context).primaryColor),
                            ));
                          }
                          return ListView.separated(
                              itemBuilder: (ctx, i) {
                                var el = parents[i];
                                return ListTile(
                                  title: Text(el.name ?? ''),
                                  subtitle: el.code != null
                                      ? Text(el.code ?? '')
                                      : null,
                                  trailing: Wrap(
                                    children: [
                                      Text(el.price?.toCoin() ?? ''),
                                    el is Products ?  IconButton(
                                          onPressed: () {
                                            currentParentElement = el;
                                            _pageController.jumpToPage(1);

                                            setState(() {});
                                          },
                                          icon: Icon(Icons.arrow_right)):SizedBox()
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.pop(context, el);
                                  },
                                );
                              },
                              separatorBuilder: (ctx, i) => const Divider(),
                              itemCount: parents.length);
                        })),
                SizedBox(
                    child: FutureBuilder(
                        future: future,
                        builder: (ctx, s) {
                          if (s.connectionState == ConnectionState.waiting &&
                              children.isEmpty) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (s.hasError) {
                            return Container();
                          }

                            if(children.isEmpty){
                             return SizedBox(child: Center(
                              child: Icon(Icons.list_alt_outlined,size: 90, color: Theme.of(context).primaryColor),
                            ));
                          }
                          return ListView.separated(
                              itemBuilder: (ctx, i) {
                                var el = children[i];
                                return ListTile(
                                  title: Text(el.name ?? ''),
                                  subtitle: el.code != null
                                      ? Text(el.code ?? '')
                                      : null,
                                  trailing: Wrap(
                                    children: [Text(el.price?.toCoin() ?? '')],
                                  ),
                                  onTap: () {
                                    Navigator.pop(context, el);
                                  },
                                );
                              },
                              separatorBuilder: (ctx, i) => const Divider(),
                              itemCount: children.length);
                        })),
              ],
            ))
          ],
        ),
      ),
    );
  }
}
